import SwiftUI
import SwiftData

struct RescueSheet: View {
    var journey: Journey
    var calendar: Calendar
    var onFinished: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var amount: Double = 0
    @State private var takenAt: Date = .now
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Copy.amount.uppercased())
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .tracking(0.4)
                        PiecePicker(amountMg: $amount)
                    }

                    DatePicker(Copy.time, selection: $takenAt, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    RescueNoteField(text: $note)
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(Copy.rescue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Copy.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Copy.save) { save() }
                        .fontWeight(.semibold)
                        .disabled(amount <= Tablet.epsilon)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .onAppear {
            amount = 0
            takenAt = .now
            note = ""
        }
    }

    private func save() {
        do {
            try Ledger.logRescue(journey: journey, amountMg: amount, takenAt: takenAt, note: note, in: context)
            onFinished()
            dismiss()
        } catch {}
    }
}

struct RescueNoteField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Copy.note.uppercased())
                .font(.footnote)
                .foregroundStyle(.secondary)
                .tracking(0.4)
            TextField("", text: $text, axis: .vertical)
                .accessibilityLabel(Copy.note)
                .lineLimit(1...3)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onChange(of: text) { _, new in
                    if new.count > RescueDose.noteLimit {
                        text = String(new.prefix(RescueDose.noteLimit))
                    }
                }
        }
    }
}

struct RescueNoteEditor: View {
    var rescue: RescueDose
    var calendar: Calendar

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(formatMg(rescue.amountMg)) · \(rescue.takenAt.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 22, weight: .semibold))
                    Text(CaminoFormat.weekdayDate(rescue.takenAt, calendar: calendar))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    RescueNoteField(text: $note)
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(Copy.rescue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Copy.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Copy.save) { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { note = rescue.note ?? "" }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }

    private func save() {
        do {
            try Ledger.setRescueNote(note, on: rescue, in: context)
            dismiss()
        } catch {}
    }
}
