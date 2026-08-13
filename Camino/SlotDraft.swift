import Foundation

struct SlotDraft: Identifiable, Equatable {
    var id: UUID
    var amountMg: Double
    var hour: Int
    var minute: Int
    var weekdays: Set<Int>

    init(
        id: UUID = UUID(),
        amountMg: Double = Tablet.halfMg,
        hour: Int = 22,
        minute: Int = 0,
        weekdays: Set<Int> = []
    ) {
        self.id = id
        self.amountMg = amountMg
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
    }

    init(_ slot: DoseSlot) {
        id = slot.id
        amountMg = slot.amountMg
        hour = slot.hour
        minute = slot.minute
        weekdays = slot.weekdays
    }

    var isValid: Bool {
        amountMg > Tablet.epsilon && !weekdays.isEmpty
    }

    var weekdayBits: Int {
        weekdays.reduce(0) { $0 | (1 << ($1 - 1)) }
    }

    static func == (lhs: SlotDraft, rhs: SlotDraft) -> Bool {
        lhs.id == rhs.id
            && mgEqual(lhs.amountMg, rhs.amountMg)
            && lhs.hour == rhs.hour
            && lhs.minute == rhs.minute
            && lhs.weekdays == rhs.weekdays
    }
}

enum WeekdayOrder {
    static func localeWeekdays(calendar: Calendar) -> [Int] {
        let first = calendar.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    static func shortLetters(calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        return localeWeekdays(calendar: calendar).map { weekday in
            let index = weekday - 1
            guard index >= 0, index < symbols.count else { return "?" }
            return symbols[index]
        }
    }

    static func shortNames(weekdays: Set<Int>, calendar: Calendar) -> String {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let ordered = localeWeekdays(calendar: calendar).filter { weekdays.contains($0) }
        return ordered.compactMap { weekday -> String? in
            let index = weekday - 1
            guard index >= 0, index < symbols.count else { return nil }
            return symbols[index]
        }
        .joined(separator: " ")
    }
}

enum CaminoFormat {
    private static func locale(for calendar: Calendar) -> Locale {
        calendar.locale ?? .current
    }

    static func time(hour: Int, minute: Int, calendar: Calendar) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = calendar.date(from: components) ?? Date()
        return date.formatted(
            Date.FormatStyle(date: .omitted, time: .shortened, locale: locale(for: calendar), calendar: calendar)
        )
    }

    static func pathAmount(hour: Int, minute: Int, amount: Double, calendar: Calendar) -> String {
        "\(time(hour: hour, minute: minute, calendar: calendar)) · \(formatMg(amount))"
    }

    static func weekdayDate(_ date: Date, calendar: Calendar) -> String {
        date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted, locale: locale(for: calendar), calendar: calendar)
                .weekday(.abbreviated)
        )
    }

    static func caminoDate(_ date: Date, calendar: Calendar) -> String {
        date.formatted(
            Date.FormatStyle()
                .weekday(.abbreviated)
                .day()
                .month(.abbreviated)
                .locale(locale(for: calendar))
        )
    }

    static func range(started: Date, ended: Date?, calendar: Calendar) -> String {
        let loc = locale(for: calendar)
        let start = started.formatted(Date.FormatStyle().day().month(.abbreviated).locale(loc))
        if let ended {
            let end = ended.formatted(Date.FormatStyle().day().month(.abbreviated).locale(loc))
            return "\(start) – \(end)"
        }
        return "\(start) – now"
    }
}
