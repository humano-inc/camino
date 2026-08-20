import Foundation

struct SlotDraft: Identifiable, Equatable {
    var id: UUID
    var amountMg: Double
    var hour: Int
    var minute: Int
    var weekdays: Set<Int>
    /// 0 = weekday chips. 2... = every N nights.
    var intervalDays: Int
    var firstNight: Date?

    init(
        id: UUID = UUID(),
        amountMg: Double = Tablet.halfMg,
        hour: Int = 22,
        minute: Int = 0,
        weekdays: Set<Int> = [],
        intervalDays: Int = 0,
        firstNight: Date? = nil
    ) {
        self.id = id
        self.amountMg = amountMg
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.intervalDays = intervalDays
        self.firstNight = firstNight
    }

    init(_ slot: DoseSlot) {
        id = slot.id
        amountMg = slot.amountMg
        hour = slot.hour
        minute = slot.minute
        weekdays = slot.weekdays
        intervalDays = slot.intervalDays
        firstNight = slot.anchorDayStart
    }

    /// Take tonight, then `interval - 1` nights off.
    static func everyFewNights(
        interval: Int,
        firstNight: Date,
        amountMg: Double = Tablet.halfMg,
        hour: Int = 22,
        minute: Int = 0,
        calendar: Calendar = .current
    ) -> SlotDraft {
        SlotDraft(
            amountMg: amountMg,
            hour: hour,
            minute: minute,
            intervalDays: max(2, interval),
            firstNight: calendar.startOfDay(for: firstNight)
        )
    }

    var rhythm: SlotRhythm {
        SlotRhythm(intervalDays: intervalDays, weekdays: weekdays, firstNight: firstNight)
    }

    var usesInterval: Bool { intervalDays >= 2 }

    var isValid: Bool {
        amountMg > Tablet.epsilon && rhythm.isValid
    }

    var weekdayBits: Int {
        usesInterval ? 0 : weekdays.reduce(0) { $0 | (1 << ($1 - 1)) }
    }

    var weeklyPlannedMg: Double {
        rhythm.weeklyFactor() * amountMg
    }

    func cadenceSummary(calendar: Calendar) -> String {
        rhythm.summary(calendar: calendar)
    }

    static func == (lhs: SlotDraft, rhs: SlotDraft) -> Bool {
        lhs.id == rhs.id
            && mgEqual(lhs.amountMg, rhs.amountMg)
            && lhs.hour == rhs.hour
            && lhs.minute == rhs.minute
            && lhs.weekdays == rhs.weekdays
            && lhs.intervalDays == rhs.intervalDays
            && lhs.firstNight == rhs.firstNight
    }
}

/// How a slot repeats. Weekdays lock to the same names every week;
/// an interval walks the calendar (Mon, then Thu, then Sun…) so the
/// gap stays even.
struct SlotRhythm: Equatable, Sendable {
    var intervalDays: Int
    var weekdays: Set<Int>
    var firstNight: Date?

    var usesInterval: Bool { intervalDays >= 2 }

    var isValid: Bool {
        if usesInterval { return firstNight != nil }
        return !weekdays.isEmpty
    }

    func includes(_ day: Date, calendar: Calendar) -> Bool {
        if usesInterval {
            guard let first = firstNight else { return false }
            let dayStart = calendar.startOfDay(for: day)
            let origin = calendar.startOfDay(for: first)
            let delta = calendar.dateComponents([.day], from: origin, to: dayStart).day ?? 0
            guard delta >= 0 else { return false }
            return delta % intervalDays == 0
        }
        return weekdays.contains(calendar.component(.weekday, from: day))
    }

    /// Average promised nights in a 7-day week.
    func weeklyFactor() -> Double {
        if usesInterval {
            return 7.0 / Double(intervalDays)
        }
        return Double(weekdays.count)
    }

    func summary(calendar: Calendar) -> String {
        if usesInterval {
            return Copy.everyNNights(intervalDays)
        }
        return WeekdayOrder.shortNames(weekdays: weekdays, calendar: calendar)
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
