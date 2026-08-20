import XCTest
@testable import Camino

final class SceneSignalsTests: XCTestCase {
    func testDistanceOnlyMovesWithThePromise() {
        XCTAssertEqual(SceneSignals.distance(plannedWeeklyMg: 0.5, trailheadWeeklyMg: 0.5), 0)
        XCTAssertEqual(SceneSignals.distance(plannedWeeklyMg: 0.25, trailheadWeeklyMg: 0.5), 0.5, accuracy: 0.0001)
        XCTAssertEqual(SceneSignals.distance(plannedWeeklyMg: 0, trailheadWeeklyMg: 0.5), 1)
        XCTAssertEqual(SceneSignals.distance(plannedWeeklyMg: 0.75, trailheadWeeklyMg: 0.5), 0)
    }

    func testSilenceIsNotALightWeek() {
        let b = SceneSignals.brightness(actualMg: 0, trailheadWeeklyMg: 0.5, windowDays: 1, hasFacts: false)
        XCTAssertEqual(b, 0)
    }

    func testAKeptNightOnDayOneStaysNight() {
        let b = SceneSignals.brightness(actualMg: 0.125, trailheadWeeklyMg: 0.5, windowDays: 1, hasFacts: true)
        XCTAssertEqual(b, 0)
    }

    func testASkippedNightBrightens() {
        let b = SceneSignals.brightness(actualMg: 0, trailheadWeeklyMg: 0.5, windowDays: 1, hasFacts: true)
        XCTAssertEqual(b, 1)
    }

    func testAWeekOfThePromiseIsNight() {
        let b = SceneSignals.brightness(actualMg: 0.5, trailheadWeeklyMg: 0.5, windowDays: 7, hasFacts: true)
        XCTAssertEqual(b, 0)
    }

    func testRescueDoesNotMoveTheHouse() {
        let before = SceneSignals.compute(
            plannedWeeklyMg: 0.5,
            trailheadWeeklyMg: 0.5,
            actualMg: 0.5,
            rescueMg: 0,
            rescueCount: 0,
            windowDays: 7,
            hasFacts: true,
            arrived: false
        )
        let after = SceneSignals.compute(
            plannedWeeklyMg: 0.5,
            trailheadWeeklyMg: 0.5,
            actualMg: 0.625,
            rescueMg: 0.125,
            rescueCount: 1,
            windowDays: 7,
            hasFacts: true,
            arrived: false
        )
        XCTAssertEqual(before.distance, after.distance)
        XCTAssertGreaterThan(after.weather, before.weather)
    }

    func testSingleQuarterRescueRegisters() {
        let w = SceneSignals.weather(rescueMg: 0.125, rescueCount: 1, trailheadWeeklyMg: 0.5)
        XCTAssertEqual(w, 1)
    }

    func testArrivalHoldsDaylight() {
        let s = SceneSignals.compute(
            plannedWeeklyMg: 0,
            trailheadWeeklyMg: 0.5,
            actualMg: 0,
            rescueMg: 0,
            rescueCount: 0,
            windowDays: 7,
            hasFacts: true,
            arrived: true
        )
        XCTAssertEqual(s, .heldDaylight)
    }

    func testWeeklyPlannedCountsWeekdays() {
        let slot = SlotDraft(amountMg: 0.125, hour: 22, minute: 0, weekdays: [1, 3, 5, 7])
        XCTAssertEqual(PlannedMath.weeklyPlannedMg(slots: [slot]), 0.5, accuracy: Tablet.epsilon)
    }

    func testWeeklyPlannedAveragesAnInterval() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let slot = SlotDraft.everyFewNights(
            interval: 3,
            firstNight: Date(timeIntervalSince1970: 0),
            amountMg: 0.125,
            calendar: calendar
        )
        XCTAssertEqual(PlannedMath.weeklyPlannedMg(slots: [slot]), 0.125 * 7 / 3, accuracy: Tablet.epsilon)
    }
}
