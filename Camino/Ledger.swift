import Foundation
import SwiftData

@MainActor
enum Ledger {
    static func begin(
        slots: [SlotDraft],
        now: Date = .now,
        calendar: Calendar = .current,
        in context: ModelContext
    ) throws -> Journey {
        let valid = slots.filter(\.isValid)
        precondition(!valid.isEmpty, "first promise needs at least one slot")

        let weekly = PlannedMath.weeklyPlannedMg(slots: valid)
        let journey = Journey(startedAt: now, trailheadWeeklyMg: weekly)
        context.insert(journey)

        let version = ProtocolVersion(startedAt: now)
        version.journey = journey
        context.insert(version)

        for draft in valid {
            insertSlot(draft, into: version, context: context)
        }

        materializeEvents(on: journey, now: now, calendar: calendar, in: context)
        try context.save()
        return journey
    }

    /// Ends the current version and starts a new one. No-op if the draft matches.
    @discardableResult
    static func saveProtocol(
        journey: Journey,
        slots: [SlotDraft],
        now: Date = .now,
        calendar: Calendar = .current,
        in context: ModelContext
    ) throws -> Bool {
        guard isDirty(journey: journey, slots: slots) else { return false }

        if let current = journey.currentProtocol {
            current.endedAt = now
        }

        let version = ProtocolVersion(startedAt: now)
        version.journey = journey
        context.insert(version)

        for draft in slots where draft.isValid {
            insertSlot(draft, into: version, context: context)
        }

        updateOpenEventsToday(journey: journey, now: now, calendar: calendar)
        materializeEvents(on: journey, now: now, calendar: calendar, in: context)
        try context.save()
        return true
    }

    static func isDirty(journey: Journey, slots: [SlotDraft]) -> Bool {
        let current = (journey.currentProtocol?.slots ?? [])
            .map(SlotDraft.init)
            .sorted { $0.id.uuidString < $1.id.uuidString }
        let draft = slots
            .filter(\.isValid)
            .sorted { $0.id.uuidString < $1.id.uuidString }
        return current != draft
    }

    static func confirm(
        event: ScheduledEvent,
        entry: ConfirmEntry,
        takenAt: Date,
        now: Date = .now,
        in context: ModelContext
    ) throws {
        let resolution = ConfirmMath.resolve(planned: event.plannedAmountMg, entry: entry)
        event.status = resolution.status
        event.actualAmountMg = resolution.eventActualMg
        event.takenAt = resolution == .skipped ? nil : takenAt
        event.confirmedAt = now

        syncOverflow(
            for: event,
            overflowMg: resolution.overflowMg,
            takenAt: takenAt,
            in: context
        )
        try context.save()
    }

    static func logRescue(
        journey: Journey,
        amountMg: Double,
        takenAt: Date,
        note: String? = nil,
        in context: ModelContext
    ) throws {
        guard amountMg > Tablet.epsilon else { return }
        let rescue = RescueDose(takenAt: takenAt, amountMg: amountMg, note: note)
        rescue.journey = journey
        context.insert(rescue)
        try context.save()
    }

    static func setRescueNote(
        _ text: String?,
        on rescue: RescueDose,
        in context: ModelContext
    ) throws {
        rescue.note = RescueDose.cleanedNote(text)
        try context.save()
    }

    static func acceptHome(journey: Journey, now: Date = .now, in context: ModelContext) throws {
        journey.arrivedAt = now
        try context.save()
    }

    static func declineHome(journey: Journey, now: Date = .now, calendar: Calendar = .current, in context: ModelContext) throws {
        journey.arrivalDeclinedOn = calendar.startOfDay(for: now)
        try context.save()
    }

    // MARK: - Events

    static func materializeEvents(
        on journey: Journey,
        now: Date,
        calendar: Calendar,
        in context: ModelContext
    ) {
        let today = calendar.startOfDay(for: now)
        var day = calendar.startOfDay(for: journey.startedAt)
        if day > today { day = today }

        var existing = Set(journey.events.map { eventKey(day: calendar.startOfDay(for: $0.dayStart), slotId: $0.slotId) })

        while day <= today {
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
            for version in journey.protocolVersions {
                guard versionActive(version, on: day, until: next) else { continue }
                for slot in version.slots where slot.includes(on: day, calendar: calendar) {
                    let key = eventKey(day: day, slotId: slot.id)
                    if existing.contains(key) { continue }
                    let event = ScheduledEvent(
                        dayStart: day,
                        slotId: slot.id,
                        protocolId: version.id,
                        plannedAmountMg: slot.amountMg,
                        hour: slot.hour,
                        minute: slot.minute
                    )
                    event.journey = journey
                    context.insert(event)
                    existing.insert(key)
                }
            }
            day = next
        }
    }

    static func todayEvents(on journey: Journey, now: Date, calendar: Calendar) -> [ScheduledEvent] {
        let today = calendar.startOfDay(for: now)
        return journey.events
            .filter { calendar.isDate($0.dayStart, inSameDayAs: today) }
            .sorted(by: Self.stepOrder)
    }

    static func unresolvedEvents(on journey: Journey, now: Date, calendar: Calendar) -> [ScheduledEvent] {
        let today = calendar.startOfDay(for: now)
        return journey.events
            .filter { $0.isOpen && calendar.startOfDay(for: $0.dayStart) < today }
            .sorted { lhs, rhs in
                if lhs.dayStart != rhs.dayStart { return lhs.dayStart > rhs.dayStart }
                return stepOrder(lhs, rhs)
            }
    }

    static func arrivalIsOfferable(on journey: Journey, now: Date, calendar: Calendar) -> Bool {
        guard !journey.isArrived else { return false }
        guard (journey.currentProtocol?.slots ?? []).isEmpty else { return false }
        guard todayActualMg(on: journey, now: now, calendar: calendar) <= Tablet.epsilon else { return false }
        if let declined = journey.arrivalDeclinedOn, calendar.isDate(declined, inSameDayAs: now) {
            return false
        }
        return true
    }

    // MARK: - Loads

    static func signals(on journey: Journey, now: Date, calendar: Calendar) -> SceneSignals {
        if journey.isArrived { return .heldDaylight }
        let window = factWindow(on: journey, now: now, calendar: calendar)
        let planned = journey.currentProtocol?.weeklyPlannedMg ?? 0
        return SceneSignals.compute(
            plannedWeeklyMg: planned,
            trailheadWeeklyMg: journey.trailheadWeeklyMg,
            actualMg: window.actualMg,
            rescueMg: window.rescueMg,
            rescueCount: window.rescueCount,
            windowDays: window.days,
            hasFacts: window.hasFacts,
            arrived: false
        )
    }

    static func todayActualMg(on journey: Journey, now: Date, calendar: Calendar) -> Double {
        let today = calendar.startOfDay(for: now)
        let fromEvents = journey.events
            .filter { calendar.isDate($0.dayStart, inSameDayAs: today) && $0.isConfirmed }
            .reduce(0) { $0 + ($1.actualAmountMg ?? 0) }
        let fromRescues = journey.rescues
            .filter { calendar.isDate($0.takenAt, inSameDayAs: today) }
            .reduce(0) { $0 + $1.amountMg }
        return fromEvents + fromRescues
    }

    static func thisWeek(on journey: Journey, now: Date, calendar: Calendar) -> WeekLoad {
        let interval = calendar.dateInterval(of: .weekOfYear, for: now)
            ?? DateInterval(start: calendar.startOfDay(for: now), duration: 7 * 86_400)
        return load(on: journey, from: interval.start, to: now, calendar: calendar, includeFuturePlanned: true)
    }

    static func weekLoads(on journey: Journey, now: Date, calendar: Calendar) -> [WeekLoad] {
        let startWeek = calendar.dateInterval(of: .weekOfYear, for: journey.startedAt)?.start
            ?? calendar.startOfDay(for: journey.startedAt)
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            ?? calendar.startOfDay(for: now)

        var cursor = startWeek
        var loads: [WeekLoad] = []
        while cursor <= thisWeek {
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor) ?? cursor
            let last = min(now, end.addingTimeInterval(-1))
            loads.append(load(on: journey, from: cursor, to: last, calendar: calendar, includeFuturePlanned: calendar.isDate(cursor, inSameDayAs: thisWeek)))
            cursor = end
        }
        return loads
    }

    struct FactWindow: Equatable {
        var actualMg: Double
        var rescueMg: Double
        var rescueCount: Int
        var days: Int
        var hasFacts: Bool
    }

    enum NightRow: Identifiable {
        case night(ScheduledEvent)
        case rescue(RescueDose)

        var id: UUID {
            switch self {
            case .night(let event): return event.id
            case .rescue(let rescue): return rescue.id
            }
        }
    }

    static func factWindow(on journey: Journey, now: Date, calendar: Calendar) -> FactWindow {
        let today = calendar.startOfDay(for: now)
        let journeyStart = calendar.startOfDay(for: journey.startedAt)
        let sevenBack = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let windowStart = max(journeyStart, sevenBack)
        let days = max(1, calendar.dateComponents([.day], from: windowStart, to: today).day ?? 0) + 1

        let eventActual = journey.events
            .filter { $0.isConfirmed && calendar.startOfDay(for: $0.dayStart) >= windowStart && calendar.startOfDay(for: $0.dayStart) <= today }
            .reduce(0) { $0 + ($1.actualAmountMg ?? 0) }

        let windowRescues = journey.rescues.filter { rescue in
            let day = calendar.startOfDay(for: rescue.takenAt)
            return day >= windowStart && day <= today
        }
        let rescueMg = windowRescues.reduce(0) { $0 + $1.amountMg }
        let hasFacts = journey.events.contains {
            $0.isConfirmed && calendar.startOfDay(for: $0.dayStart) >= windowStart && calendar.startOfDay(for: $0.dayStart) <= today
        } || !windowRescues.isEmpty

        return FactWindow(
            actualMg: eventActual + rescueMg,
            rescueMg: rescueMg,
            rescueCount: windowRescues.count,
            days: days,
            hasFacts: hasFacts
        )
    }

    static func timeline(on journey: Journey, calendar: Calendar) -> [NightRow] {
        var rows: [(moment: Date, rescueFirst: Int, row: NightRow)] = journey.events
            .filter { $0.isConfirmed }
            .map { event in
                let moment = event.takenAt
                    ?? calendar.date(bySettingHour: event.hour, minute: event.minute, second: 0, of: event.dayStart)
                    ?? event.dayStart
                return (moment, 0, .night(event))
            }
        rows += journey.rescues.map { ($0.takenAt, 1, .rescue($0)) }
        return rows
            .sorted {
                if $0.moment != $1.moment { return $0.moment > $1.moment }
                // An overflow rescue shares its event's takenAt; show it above the promise it spilled from.
                return $0.rescueFirst > $1.rescueFirst
            }
            .map(\.row)
    }

    static func overflowRescue(for event: ScheduledEvent, on journey: Journey) -> RescueDose? {
        journey.rescues.first { $0.linkedScheduledId == event.id }
    }

    // MARK: - Private

    private static func insertSlot(_ draft: SlotDraft, into version: ProtocolVersion, context: ModelContext) {
        let slot = DoseSlot(
            id: draft.id,
            amountMg: draft.amountMg,
            hour: draft.hour,
            minute: draft.minute,
            weekdayBits: draft.weekdayBits,
            intervalDays: draft.intervalDays,
            anchorDayStart: draft.firstNight
        )
        slot.protocolVersion = version
        context.insert(slot)
    }

    private static func versionActive(_ version: ProtocolVersion, on dayStart: Date, until dayEnd: Date) -> Bool {
        if version.startedAt >= dayEnd { return false }
        if let ended = version.endedAt, ended <= dayStart { return false }
        return true
    }

    private static func updateOpenEventsToday(journey: Journey, now: Date, calendar: Calendar) {
        let today = calendar.startOfDay(for: now)
        guard let current = journey.currentProtocol else { return }
        let slots = Dictionary(uniqueKeysWithValues: current.slots.map { ($0.id, $0) })
        for event in journey.events where event.isOpen && calendar.isDate(event.dayStart, inSameDayAs: today) {
            if let slot = slots[event.slotId] {
                event.plannedAmountMg = slot.amountMg
                event.hour = slot.hour
                event.minute = slot.minute
            }
        }
    }

    private static func syncOverflow(
        for event: ScheduledEvent,
        overflowMg: Double,
        takenAt: Date,
        in context: ModelContext
    ) {
        guard let journey = event.journey else { return }
        let existing = journey.rescues.first { $0.linkedScheduledId == event.id }

        if overflowMg <= Tablet.epsilon {
            if let existing {
                context.delete(existing)
            }
            return
        }

        if let existing {
            existing.amountMg = overflowMg
            existing.takenAt = takenAt
        } else {
            let rescue = RescueDose(
                takenAt: takenAt,
                amountMg: overflowMg,
                linkedScheduledId: event.id
            )
            rescue.journey = journey
            context.insert(rescue)
        }
    }

    private static func eventKey(day: Date, slotId: UUID) -> String {
        "\(day.timeIntervalSinceReferenceDate)|\(slotId.uuidString)"
    }

    private static func stepOrder(_ lhs: ScheduledEvent, _ rhs: ScheduledEvent) -> Bool {
        if lhs.hour != rhs.hour { return lhs.hour < rhs.hour }
        if lhs.minute != rhs.minute { return lhs.minute < rhs.minute }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    private static func load(
        on journey: Journey,
        from start: Date,
        to end: Date,
        calendar: Calendar,
        includeFuturePlanned: Bool
    ) -> WeekLoad {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        let lastPlannedDay: Date
        if includeFuturePlanned,
           let weekEnd = calendar.date(byAdding: .day, value: 6, to: startDay) {
            lastPlannedDay = weekEnd
        } else {
            lastPlannedDay = endDay
        }

        var planned = 0.0
        var day = startDay
        while day <= lastPlannedDay {
            planned += plannedMg(on: journey, day: day, calendar: calendar)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        let actualEvents = journey.events
            .filter { $0.isConfirmed && calendar.startOfDay(for: $0.dayStart) >= startDay && calendar.startOfDay(for: $0.dayStart) <= endDay }
            .reduce(0) { $0 + ($1.actualAmountMg ?? 0) }
        let weekRescues = journey.rescues.filter {
            let d = calendar.startOfDay(for: $0.takenAt)
            return d >= startDay && d <= endDay
        }
        let rescueMg = weekRescues.reduce(0) { $0 + $1.amountMg }

        return WeekLoad(
            weekStart: startDay,
            plannedMg: planned,
            actualMg: actualEvents + rescueMg,
            rescueMg: rescueMg,
            rescueCount: weekRescues.count
        )
    }

    /// Planned milligrams for a calendar day from the protocol that was current that day.
    /// On a cut day, both versions that were alive contribute their matching slots
    /// (materialized events already follow that rule; this matches them).
    static func plannedMg(on journey: Journey, day: Date, calendar: Calendar) -> Double {
        let dayStart = calendar.startOfDay(for: day)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86_400)
        var seen = Set<UUID>()
        var total = 0.0
        for version in journey.protocolVersions where versionActive(version, on: dayStart, until: dayEnd) {
            for slot in version.slots where slot.includes(on: dayStart, calendar: calendar) && seen.insert(slot.id).inserted {
                total += slot.amountMg
            }
        }
        return total
    }

    static func protocolCurrent(on journey: Journey, day: Date, calendar: Calendar) -> ProtocolVersion? {
        let dayStart = calendar.startOfDay(for: day)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86_400)
        let active = journey.protocolVersions
            .filter { versionActive($0, on: dayStart, until: dayEnd) }
            .sorted { $0.startedAt < $1.startedAt }
        return active.last
    }
}
