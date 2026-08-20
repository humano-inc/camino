import XCTest
@testable import Camino

final class SlotRhythmTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 1
    }

    /// Thursday 13 Aug 2026
    private var thursday: Date {
        date(2026, 8, 13)
    }

    func testEveryThreeNightsIsEvenlySpaced() {
        let rhythm = SlotRhythm(intervalDays: 3, weekdays: [], firstNight: thursday)
        let hits = (0..<14).compactMap { offset -> Int? in
            let day = calendar.date(byAdding: .day, value: offset, to: thursday)!
            return rhythm.includes(day, calendar: calendar) ? offset : nil
        }
        XCTAssertEqual(hits, [0, 3, 6, 9, 12])
    }

    func testEveryTwoNightsIsEveryOtherNight() {
        let rhythm = SlotRhythm(intervalDays: 2, weekdays: [], firstNight: thursday)
        XCTAssertTrue(rhythm.includes(thursday, calendar: calendar))
        XCTAssertFalse(rhythm.includes(date(2026, 8, 14), calendar: calendar))
        XCTAssertTrue(rhythm.includes(date(2026, 8, 15), calendar: calendar))
    }

    func testWeekdayPairCannotHoldATwoNightGap() {
        // Monday + Thursday: one gap is two nights, the wrap is three.
        let monThu = SlotRhythm(intervalDays: 0, weekdays: [2, 5], firstNight: nil)
        let monday = date(2026, 8, 10)
        var gaps: [Int] = []
        var last: Date?
        for offset in 0..<14 {
            let day = calendar.date(byAdding: .day, value: offset, to: monday)!
            guard monThu.includes(day, calendar: calendar) else { continue }
            if let last {
                gaps.append(calendar.dateComponents([.day], from: last, to: day).day ?? -1)
            }
            last = day
        }
        XCTAssertEqual(Set(gaps), [3, 4])
    }

    func testNightsBeforeTheFirstNightAreOff() {
        let rhythm = SlotRhythm(intervalDays: 3, weekdays: [], firstNight: thursday)
        XCTAssertFalse(rhythm.includes(date(2026, 8, 10), calendar: calendar))
        XCTAssertFalse(rhythm.includes(date(2026, 8, 12), calendar: calendar))
    }

    func testSummaryNamesTheInterval() {
        let rhythm = SlotRhythm(intervalDays: 3, weekdays: [], firstNight: thursday)
        XCTAssertEqual(rhythm.summary(calendar: calendar), "Every 3 nights")
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        return calendar.date(from: parts)!
    }
}
