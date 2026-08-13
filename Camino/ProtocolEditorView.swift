import SwiftUI
import SwiftData

struct ProtocolEditorView: View {
    var journey: Journey?
    var isFirst: Bool
    var calendar: Calendar
    var onFinished: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var slots: [SlotDraft] = []
    @State private var editing: SlotDraft?
    @State private var addingNew = false
    @State private var confirmLayDown = false
    @State private var confirmDiscard = false
    @State private var remindersOff = false
    @State private var original: [SlotDraft] = []

    private var weekly: Double { PlannedMath.weeklyPlannedMg(slots: slots.filter(\.isValid)) }
    private var dirty: Bool { slots != original }
    private var canCommit: Bool {
        if isFirst { return slots.contains(where: \.isValid) }
        return dirty
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($slots) { $slot in
                        Button {
                            editing = slot
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(CaminoFormat.pathAmount(hour: slot.hour, minute: slot.minute, amount: slot.amountMg, calendar: calendar))
                                        .foregroundStyle(.primary)
                                    Text(WeekdayOrder.shortNames(weekdays: slot.weekdays, calendar: calendar))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .tracking(0.4)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        slots.remove(atOffsets: offsets)
                    }

                    Button(Copy.addATime) {
                        let fresh = SlotDraft()
                        slots.append(fresh)
                        addingNew = true
                        editing = fresh
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(Copy.thisWeekPlanned(formatMg(weekly)))
                        if remindersOff {
                            HStack(spacing: 4) {
                                Text(Copy.notificationsOff)
                                Button(Copy.openSettings) {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        openURL(url)
                                    }
                                }
                            }
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
            }
            .navigationTitle(isFirst ? Copy.firstPromiseTitle : Copy.promise)
            .navigationBarTitleDisplayMode(isFirst ? .large : .inline)
            .toolbar {
                if !isFirst {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Copy.cancel) { attemptDismiss() }
                    }
                }
                if !isFirst {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(Copy.save) { attemptSave() }
                            .fontWeight(.semibold)
                            .disabled(!canCommit)
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if isFirst {
                    Text(Copy.firstPromiseLead)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isFirst {
                    Button(action: attemptSave) {
                        Text(Copy.begin)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(canCommit ? CaminoTheme.ink : Color.white.opacity(0.32))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(
                                canCommit ? CaminoTheme.amber : Color.white.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                    }
                    .disabled(!canCommit)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black)
                }
            }
            .navigationDestination(item: $editing) { slot in
                if let index = slots.firstIndex(where: { $0.id == slot.id }) {
                    SlotEditorView(
                        draft: $slots[index],
                        calendar: calendar,
                        canDelete: true,
                        onDelete: {
                            slots.removeAll { $0.id == slot.id }
                            editing = nil
                        },
                        onDone: { editing = nil }
                    )
                }
            }
        }
        .onAppear {
            load()
            Task { remindersOff = await ReminderScheduler.areDenied() }
        }
        .onChange(of: editing) { old, new in
            if addingNew, new == nil, let last = slots.last, !last.isValid {
                slots.removeAll { $0.id == last.id }
            }
            addingNew = false
            _ = old
        }
        .interactiveDismissDisabled(dirty && !isFirst)
        .confirmationDialog(Copy.discardTitle, isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button(Copy.discard, role: .destructive) { dismiss() }
            Button(Copy.keepEditing, role: .cancel) {}
        }
        .alert(Copy.layDownTitle, isPresented: $confirmLayDown) {
            Button(Copy.cancel, role: .cancel) {}
            Button(Copy.layDownConfirm) { commit(slots: []) }
        } message: {
            Text(Copy.layDownBody)
        }
    }

    private func load() {
        if let current = journey?.currentProtocol {
            slots = current.slots
                .map(SlotDraft.init)
                .sorted { lhs, rhs in
                    if lhs.hour != rhs.hour { return lhs.hour < rhs.hour }
                    return lhs.minute < rhs.minute
                }
        } else {
            slots = []
        }
        original = slots
    }

    private func attemptDismiss() {
        if dirty {
            confirmDiscard = true
        } else {
            dismiss()
        }
    }

    private func attemptSave() {
        let valid = slots.filter(\.isValid)
        if !isFirst, valid.isEmpty {
            confirmLayDown = true
            return
        }
        commit(slots: valid)
    }

    private func commit(slots valid: [SlotDraft]) {
        do {
            if isFirst {
                _ = try Ledger.begin(slots: valid, calendar: calendar, in: context)
                Task { await ReminderScheduler.requestAndSchedule(journey: latestJourney(), calendar: calendar) }
            } else if let journey {
                _ = try Ledger.saveProtocol(journey: journey, slots: valid, calendar: calendar, in: context)
                Task { await ReminderScheduler.reschedule(journey: journey, calendar: calendar) }
            }
            onFinished()
            if !isFirst { dismiss() }
        } catch {}
    }

    private func latestJourney() -> Journey? {
        journey ?? (try? context.fetch(FetchDescriptor<Journey>()).max(by: { $0.startedAt < $1.startedAt }))
    }
}

extension SlotDraft: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
