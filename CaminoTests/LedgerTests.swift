import XCTest
import SwiftData
@testable import Camino

@MainActor
final class LedgerTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var calendar: Calendar!

    override func setUp() async throws {
        let schema = Schema([
            Journey.self,
            ProtocolVersion.self,
            DoseSlot.self,
            ScheduledEvent.self,
            RescueDose.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 1
    }

    /// Thursday 13 Aug 2026 22:04 UTC
    private var thursday: Date {
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 8
        parts.day = 13
        parts.hour = 22
        parts.minute = 4
        return calendar.date(from: parts)!
    }

    private func nightSlot(weekdays: Set<Int> = [1, 3, 5, 7]) -> SlotDraft {
        SlotDraft(amountMg: 0.125, hour: 22, minute: 0, weekdays: weekdays)
    }

    func testBeginCreatesTrailheadAndTodaysOpenStep() throws {
        let journey = try Ledger.begin(
            slots: [nightSlot()],
            now: thursday,
            calendar: calendar,
            in: context
        )
        XCTAssertEqual(journey.trailheadWeeklyMg, 0.5, accuracy: Tablet.epsilon)
        XCTAssertNil(journey.arrivedAt)
        XCTAssertEqual(journey.currentProtocol?.slots.count, 1)
        let today = Ledger.todayEvents(on: journey, now: thursday, calendar: calendar)
        XCTAssertEqual(today.count, 1)
        XCTAssertEqual(today[0].status, .open)
        XCTAssertEqual(today[0].plannedAmountMg, 0.125, accuracy: Tablet.epsilon)
    }

    func testNothingIsAssumedTaken() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        let window = Ledger.factWindow(on: journey, now: thursday, calendar: calendar)
        XCTAssertFalse(window.hasFacts)
        XCTAssertEqual(window.actualMg, 0)
        let signals = Ledger.signals(on: journey, now: thursday, calendar: calendar)
        XCTAssertEqual(signals.distance, 0)
        XCTAssertEqual(signals.brightness, 0)
    }

    func testConfirmTaken() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        let event = Ledger.todayEvents(on: journey, now: thursday, calendar: calendar)[0]
        try Ledger.confirm(event: event, entry: .taken, takenAt: thursday, now: thursday, in: context)
        XCTAssertEqual(event.status, .taken)
        XCTAssertEqual(event.actualAmountMg ?? -1, 0.125, accuracy: Tablet.epsilon)
        XCTAssertEqual(journey.rescues.count, 0)
    }

    func testConfirmSkipStaysOpenUntilChosen() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        let event = Ledger.todayEvents(on: journey, now: thursday, calendar: calendar)[0]
        XCTAssertEqual(event.status, .open)
        try Ledger.confirm(event: event, entry: .skipped, takenAt: thursday, now: thursday, in: context)
        XCTAssertEqual(event.status, .skipped)
        XCTAssertEqual(event.actualAmountMg ?? -1, 0)
    }

    func testConfirmLess() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        let event = Ledger.todayEvents(on: journey, now: thursday, calendar: calendar)[0]
        try Ledger.confirm(event: event, entry: .amount(0.0625), takenAt: thursday, now: thursday, in: context)
        XCTAssertEqual(event.status, .less)
        XCTAssertEqual(event.actualAmountMg ?? -1, 0.0625, accuracy: Tablet.epsilon)
        XCTAssertEqual(journey.rescues.count, 0)
    }

    func testConfirmMoreSplitsToRescue() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        let event = Ledger.todayEvents(on: journey, now: thursday, calendar: calendar)[0]
        try Ledger.confirm(event: event, entry: .amount(0.25), takenAt: thursday, now: thursday, in: context)
        XCTAssertEqual(event.status, .taken)
        XCTAssertEqual(event.actualAmountMg ?? -1, 0.125, accuracy: Tablet.epsilon)
        XCTAssertEqual(journey.rescues.count, 1)
        XCTAssertEqual(journey.rescues[0].amountMg, 0.125, accuracy: Tablet.epsilon)
        XCTAssertEqual(journey.rescues[0].linkedScheduledId, event.id)
    }

    func testEditOverflowAwayRemovesRescue() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        let event = Ledger.todayEvents(on: journey, now: thursday, calendar: calendar)[0]
        try Ledger.confirm(event: event, entry: .amount(0.25), takenAt: thursday, now: thursday, in: context)
        try Ledger.confirm(event: event, entry: .amount(0.0625), takenAt: thursday, now: thursday, in: context)
        XCTAssertEqual(event.status, .less)
        XCTAssertEqual(journey.rescues.count, 0)
    }

    func testLogRescueStoresTrimmedNote() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        try Ledger.logRescue(journey: journey, amountMg: 0.125, takenAt: thursday, note: "  couldn't sleep  ", in: context)
        XCTAssertEqual(journey.rescues[0].note, "couldn't sleep")
        XCTAssertNil(journey.rescues[0].linkedScheduledId)
    }

    func testLogRescueWhitespaceNoteIsNil() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        try Ledger.logRescue(journey: journey, amountMg: 0.125, takenAt: thursday, note: "  \n", in: context)
        XCTAssertNil(journey.rescues[0].note)
    }

    func testSetRescueNoteClearsAndCaps() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        try Ledger.logRescue(journey: journey, amountMg: 0.125, takenAt: thursday, in: context)
        let rescue = journey.rescues[0]
        try Ledger.setRescueNote("  a hard hour  ", on: rescue, in: context)
        XCTAssertEqual(rescue.note, "a hard hour")
        try Ledger.setRescueNote("   ", on: rescue, in: context)
        XCTAssertNil(rescue.note)
        let long = String(repeating: "a", count: RescueDose.noteLimit + 40)
        try Ledger.setRescueNote(long, on: rescue, in: context)
        XCTAssertEqual(rescue.note?.count, RescueDose.noteLimit)
    }

    func testOverflowUpdateKeepsNote() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        let event = Ledger.todayEvents(on: journey, now: thursday, calendar: calendar)[0]
        try Ledger.confirm(event: event, entry: .amount(0.25), takenAt: thursday, now: thursday, in: context)
        try Ledger.setRescueNote("from the slot", on: journey.rescues[0], in: context)
        try Ledger.confirm(event: event, entry: .amount(0.1875), takenAt: thursday, now: thursday, in: context)
        XCTAssertEqual(journey.rescues.count, 1)
        XCTAssertEqual(journey.rescues[0].note, "from the slot")
        XCTAssertEqual(journey.rescues[0].amountMg, 0.0625, accuracy: Tablet.epsilon)
    }

    func testIndependentRescueDoesNotRewriteThePromise() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        try Ledger.logRescue(journey: journey, amountMg: 0.125, takenAt: thursday, in: context)
        XCTAssertEqual(journey.currentProtocol?.weeklyPlannedMg ?? -1, 0.5, accuracy: Tablet.epsilon)
        XCTAssertEqual(journey.rescues.count, 1)
        XCTAssertNil(journey.rescues[0].linkedScheduledId)
        let signals = Ledger.signals(on: journey, now: thursday, calendar: calendar)
        XCTAssertEqual(signals.distance, 0)
        XCTAssertGreaterThan(signals.weather, 0)
    }

    func testSaveProtocolVersionsHistory() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        var cut = nightSlot()
        cut.amountMg = 0.0625
        cut.id = journey.currentProtocol!.slots[0].id
        let later = thursday.addingTimeInterval(60)
        let changed = try Ledger.saveProtocol(journey: journey, slots: [cut], now: later, calendar: calendar, in: context)
        XCTAssertTrue(changed)
        XCTAssertEqual(journey.protocolVersions.count, 2)
        XCTAssertNotNil(journey.protocolVersions.first { $0.endedAt != nil })
        XCTAssertEqual(journey.currentProtocol?.weeklyPlannedMg ?? -1, 0.25, accuracy: Tablet.epsilon)
        let signals = Ledger.signals(on: journey, now: later, calendar: calendar)
        XCTAssertEqual(signals.distance, 0.5, accuracy: 0.0001)
    }

    func testSaveProtocolNoOpWhenClean() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        let draft = journey.currentProtocol!.slots.map(SlotDraft.init)
        let changed = try Ledger.saveProtocol(journey: journey, slots: draft, now: thursday, calendar: calendar, in: context)
        XCTAssertFalse(changed)
        XCTAssertEqual(journey.protocolVersions.count, 1)
    }

    func testDoesNotAutoSkipTheNextMorning() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        var friday = DateComponents()
        friday.year = 2026
        friday.month = 8
        friday.day = 14
        friday.hour = 9
        let morning = calendar.date(from: friday)!
        Ledger.materializeEvents(on: journey, now: morning, calendar: calendar, in: context)
        let leftover = Ledger.unresolvedEvents(on: journey, now: morning, calendar: calendar)
        XCTAssertEqual(leftover.count, 1)
        XCTAssertEqual(leftover[0].status, .open)
    }

    func testIntervalEveryThreeNightsSkipsTheTwoInBetween() throws {
        let slot = SlotDraft.everyFewNights(
            interval: 3,
            firstNight: thursday,
            amountMg: 0.125,
            calendar: calendar
        )
        let journey = try Ledger.begin(slots: [slot], now: thursday, calendar: calendar, in: context)

        var later = DateComponents()
        later.year = 2026
        later.month = 8
        later.day = 19
        later.hour = 22
        let sundayWeek = calendar.date(from: later)!
        Ledger.materializeEvents(on: journey, now: sundayWeek, calendar: calendar, in: context)

        let days = Set(journey.events.map { calendar.component(.day, from: $0.dayStart) })
        XCTAssertEqual(days, [13, 16, 19])
        XCTAssertEqual(journey.events.count, 3)
        XCTAssertEqual(Ledger.todayEvents(on: journey, now: thursday, calendar: calendar).count, 1)

        var friday = DateComponents()
        friday.year = 2026
        friday.month = 8
        friday.day = 14
        friday.hour = 22
        let fridayNight = calendar.date(from: friday)!
        XCTAssertTrue(Ledger.todayEvents(on: journey, now: fridayNight, calendar: calendar).isEmpty)
        XCTAssertEqual(
            Ledger.plannedMg(on: journey, day: fridayNight, calendar: calendar),
            0,
            accuracy: Tablet.epsilon
        )
    }

    func testIntervalStartingTomorrowLeavesTonightEmpty() throws {
        var friday = DateComponents()
        friday.year = 2026
        friday.month = 8
        friday.day = 14
        let first = calendar.date(from: friday)!
        let slot = SlotDraft.everyFewNights(interval: 3, firstNight: first, calendar: calendar)
        let journey = try Ledger.begin(slots: [slot], now: thursday, calendar: calendar, in: context)
        XCTAssertTrue(Ledger.todayEvents(on: journey, now: thursday, calendar: calendar).isEmpty)

        Ledger.materializeEvents(on: journey, now: first, calendar: calendar, in: context)
        XCTAssertEqual(Ledger.todayEvents(on: journey, now: first, calendar: calendar).count, 1)
    }

    func testArrivalNeedsEmptyPromiseAndZeroToday() throws {
        let journey = try Ledger.begin(slots: [nightSlot()], now: thursday, calendar: calendar, in: context)
        XCTAssertFalse(Ledger.arrivalIsOfferable(on: journey, now: thursday, calendar: calendar))
        _ = try Ledger.saveProtocol(journey: journey, slots: [], now: thursday, calendar: calendar, in: context)
        XCTAssertTrue(Ledger.arrivalIsOfferable(on: journey, now: thursday, calendar: calendar))
        try Ledger.logRescue(journey: journey, amountMg: 0.0625, takenAt: thursday, in: context)
        XCTAssertFalse(Ledger.arrivalIsOfferable(on: journey, now: thursday, calendar: calendar))
    }
}
