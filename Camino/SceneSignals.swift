import Foundation

struct SceneSignals: Equatable {
    /// 0 = trailhead (house far), 1 = home (house here). Moves only when the promise is cut.
    var distance: Double
    /// 0 = deepest night, 1 = held daylight. Follows what was actually swallowed.
    var brightness: Double
    /// 0 = clear, 1 = full weather. Follows rescue in the window.
    var weather: Double
    var rescueCount: Int

    static let trailhead = SceneSignals(distance: 0, brightness: 0, weather: 0, rescueCount: 0)
    static let heldDaylight = SceneSignals(distance: 1, brightness: 1, weather: 0, rescueCount: 0)

    static func clamp01(_ value: Double) -> Double {
        min(1, max(0, value))
    }

    /// Distance from current weekly planned `P` versus trailhead weekly planned `T`.
    static func distance(plannedWeeklyMg p: Double, trailheadWeeklyMg t: Double) -> Double {
        if t <= Tablet.epsilon { return 1 }
        return clamp01(1 - p / t)
    }

    /// Brightness from actual swallowed in the window.
    ///
    /// Open events are not zeros. If there are no facts yet, the sky stays at night —
    /// silence is not a light week. A window shorter than 7 days is scaled to the
    /// trailhead week so one kept night does not read as morning.
    static func brightness(
        actualMg a: Double,
        trailheadWeeklyMg t: Double,
        windowDays: Int,
        hasFacts: Bool
    ) -> Double {
        if t <= Tablet.epsilon { return 1 }
        if !hasFacts { return 0 }
        let days = max(1, windowDays)
        let scaled = days < 7 ? a * 7.0 / Double(days) : a
        return clamp01(1 - scaled / t)
    }

    /// Weather from rescue milligrams. A quarter-trailhead-week fills the sky;
    /// a single 0.125 still registers. Count thickens the same weather.
    static func weather(rescueMg r: Double, rescueCount: Int, trailheadWeeklyMg t: Double) -> Double {
        let fill = max(t * 0.25, Tablet.halfMg)
        var w = fill <= Tablet.epsilon ? 0 : clamp01(r / fill)
        if rescueCount > 1 {
            let extra = 0.06 * Double(min(rescueCount - 1, 6))
            w = clamp01(w + extra * (1 - w))
        }
        return w
    }

    static func compute(
        plannedWeeklyMg: Double,
        trailheadWeeklyMg: Double,
        actualMg: Double,
        rescueMg: Double,
        rescueCount: Int,
        windowDays: Int,
        hasFacts: Bool,
        arrived: Bool
    ) -> SceneSignals {
        if arrived {
            return .heldDaylight
        }
        return SceneSignals(
            distance: distance(plannedWeeklyMg: plannedWeeklyMg, trailheadWeeklyMg: trailheadWeeklyMg),
            brightness: brightness(
                actualMg: actualMg,
                trailheadWeeklyMg: trailheadWeeklyMg,
                windowDays: windowDays,
                hasFacts: hasFacts
            ),
            weather: weather(rescueMg: rescueMg, rescueCount: rescueCount, trailheadWeeklyMg: trailheadWeeklyMg),
            rescueCount: rescueCount
        )
    }
}

struct WeekLoad: Equatable {
    var weekStart: Date
    var plannedMg: Double
    var actualMg: Double
    var rescueMg: Double
    var rescueCount: Int
}

enum PlannedMath {
    static func weeklyPlannedMg(slots: [SlotDraft]) -> Double {
        slots.reduce(0) { $0 + $1.amountMg * Double($1.weekdays.count) }
    }
}
