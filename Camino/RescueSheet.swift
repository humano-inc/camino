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
                }
                .padding(16)
            }
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
        }
    }

    private func save() {
        do {
            try Ledger.logRescue(journey: journey, amountMg: amount, takenAt: takenAt, in: context)
            onFinished()
            dismiss()
        } catch {}
    }
}
