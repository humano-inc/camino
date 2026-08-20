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
                    Text(Copy.rhythm.uppercased())
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .tracking(0.4)
                    Picker("", selection: cadenceIsInterval) {
                        Text(Copy.weekdays).tag(false)
                        Text(Copy.everyFewNights).tag(true)
                    }
                    .pickerStyle(.segmented)

                    if draft.usesInterval {
                        intervalEditor
                    } else {
                        weekdayRow
                    }
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

    private var cadenceIsInterval: Binding<Bool> {
        Binding(
            get: { draft.usesInterval },
            set: { interval in
                if interval {
                    draft.weekdays = []
                    if draft.intervalDays < 2 { draft.intervalDays = 3 }
                    if draft.firstNight == nil {
                        draft.firstNight = calendar.startOfDay(for: Date())
                    }
                } else {
                    draft.intervalDays = 0
                    draft.firstNight = nil
                }
            }
        )
    }

    private var intervalEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper(value: intervalBinding, in: 2...10) {
                Text(Copy.everyNNights(max(2, draft.intervalDays)))
            }
            Text(Copy.nightsOffAfterTake(max(1, draft.intervalDays - 1)))
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(Copy.firstNight.uppercased())
                .font(.footnote)
                .foregroundStyle(.secondary)
                .tracking(0.4)
                .padding(.top, 4)

            HStack(spacing: 7) {
                firstNightPill(Copy.tonight, selected: isTonight) {
                    draft.firstNight = todayStart
                }
                firstNightPill(Copy.tomorrow, selected: isTomorrow) {
                    draft.firstNight = tomorrowStart
                }
            }

            DatePicker(
                Copy.firstNight,
                selection: firstNightBinding,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var intervalBinding: Binding<Int> {
        Binding(
            get: { max(2, draft.intervalDays) },
            set: { draft.intervalDays = $0 }
        )
    }

    private var firstNightBinding: Binding<Date> {
        Binding(
            get: { draft.firstNight ?? todayStart },
            set: { draft.firstNight = calendar.startOfDay(for: $0) }
        )
    }

    private var todayStart: Date { calendar.startOfDay(for: Date()) }
    private var tomorrowStart: Date {
        calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart
    }

    private var isTonight: Bool {
        guard let first = draft.firstNight else { return false }
        return calendar.isDate(first, inSameDayAs: todayStart)
    }

    private var isTomorrow: Bool {
        guard let first = draft.firstNight else { return false }
        return calendar.isDate(first, inSameDayAs: tomorrowStart)
    }

    private func firstNightPill(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? CaminoTheme.ink : Color.secondary)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(
                    selected ? CaminoTheme.amber : Color(uiColor: .tertiarySystemFill),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
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
