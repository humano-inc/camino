import SwiftUI
import SwiftData

struct ConfirmSheet: View {
    var event: ScheduledEvent
    var calendar: Calendar
    var onFinished: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showingDifferent = false
    @State private var amount: Double = Tablet.halfMg
    @State private var takenAt: Date = .now

    private var title: String {
        CaminoFormat.pathAmount(hour: event.hour, minute: event.minute, amount: event.plannedAmountMg, calendar: calendar)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(CaminoFormat.weekdayDate(event.dayStart, calendar: calendar))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)

                    actionList

                    if showingDifferent {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(Copy.amount.uppercased())
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .tracking(0.4)
                            PiecePicker(amountMg: $amount)
                            if overflow > Tablet.epsilon {
                                Text(Copy.overflow(formatMg(overflow)))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 4)
                    }

                    DatePicker(Copy.time, selection: $takenAt, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(Color.clear)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Copy.cancel) { dismiss() }
                }
                if showingDifferent || event.isConfirmed {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(Copy.save) { saveDifferent() }
                            .fontWeight(.semibold)
                            .disabled(showingDifferent && amount <= Tablet.epsilon)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .onAppear { preload() }
    }

    @ViewBuilder
    private var actionList: some View {
        VStack(spacing: 0) {
            row(Copy.taken, prominent: !showingDifferent && event.isOpen) {
                commit(.taken)
            }
            Divider().padding(.leading, 0)
            row(Copy.skip, prominent: false) {
                commit(.skipped)
            }
            if !showingDifferent {
                Divider()
                row(Copy.differentAmount, prominent: false) {
                    showingDifferent = true
                    if !event.isOpen, let actual = event.actualAmountMg, actual > Tablet.epsilon {
                        amount = actual + (overflowExisting)
                    } else {
                        amount = event.plannedAmountMg
                    }
                }
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func row(_ title: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: prominent ? .semibold : .regular))
                .frame(maxWidth: .infinity, minHeight: 50)
                .foregroundStyle(CaminoTheme.amber)
        }
        .buttonStyle(.plain)
    }

    private var overflow: Double {
        max(0, amount - event.plannedAmountMg)
    }

    private var overflowExisting: Double {
        event.journey.flatMap { Ledger.overflowRescue(for: event, on: $0)?.amountMg } ?? 0
    }

    private func preload() {
        takenAt = event.takenAt ?? .now
        if event.isConfirmed {
            showingDifferent = event.status == .less || overflowExisting > Tablet.epsilon
            switch event.status {
            case .less:
                amount = event.actualAmountMg ?? event.plannedAmountMg
            case .taken:
                amount = event.plannedAmountMg + overflowExisting
            case .skipped:
                amount = event.plannedAmountMg
            case .open:
                amount = event.plannedAmountMg
            }
        } else {
            amount = event.plannedAmountMg
        }
    }

    private func commit(_ entry: ConfirmEntry) {
        do {
            try Ledger.confirm(event: event, entry: entry, takenAt: takenAt, in: context)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            ReminderScheduler.cancel(event: event, calendar: calendar)
            onFinished()
            dismiss()
        } catch {
            // Stay on the sheet; the ledger did not change.
        }
    }

    private func saveDifferent() {
        commit(.amount(amount))
    }
}
