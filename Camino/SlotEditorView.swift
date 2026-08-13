import SwiftUI

struct SlotEditorView: View {
    @Binding var draft: SlotDraft
    var calendar: Calendar
    var canDelete: Bool
    var onDelete: () -> Void
    var onDone: () -> Void

    @State private var time: Date = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Copy.amount.uppercased())
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .tracking(0.4)
                    PiecePicker(amountMg: $draft.amountMg)
                }

                DatePicker(
                    Copy.time,
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onChange(of: time) { _, new in
                    let parts = calendar.dateComponents([.hour, .minute], from: new)
                    draft.hour = parts.hour ?? draft.hour
                    draft.minute = parts.minute ?? draft.minute
                }

                VStack(alignment: .leading, spacing: 9) {
                    Text(Copy.days.uppercased())
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .tracking(0.4)
                    weekdayRow
                }

                if canDelete {
                    Button(role: .destructive, action: onDelete) {
                        Text(Copy.deleteThisTime)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(16)
        }
        .navigationTitle(Copy.time)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Copy.done, action: onDone)
                    .fontWeight(.semibold)
                    .disabled(!draft.isValid)
            }
        }
        .onAppear { syncTime() }
    }

    private var weekdayRow: some View {
        let days = WeekdayOrder.localeWeekdays(calendar: calendar)
        let letters = WeekdayOrder.shortLetters(calendar: calendar)
        return HStack(spacing: 7) {
            ForEach(Array(days.enumerated()), id: \.element) { index, weekday in
                let selected = draft.weekdays.contains(weekday)
                Button {
                    if selected {
                        draft.weekdays.remove(weekday)
                    } else {
                        draft.weekdays.insert(weekday)
                    }
                } label: {
                    Text(letters[index])
                        .font(.system(size: 16, weight: selected ? .semibold : .regular))
                        .foregroundStyle(selected ? CaminoTheme.ink : Color.secondary)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(
                            selected ? CaminoTheme.amber : Color(uiColor: .tertiarySystemFill),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(calendar.standaloneWeekdaySymbols[weekday - 1])
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private func syncTime() {
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = draft.hour
        components.minute = draft.minute
        time = calendar.date(from: components) ?? Date()
    }
}
