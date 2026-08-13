import Foundation
import SwiftData

enum EventStatus: String, Codable, CaseIterable {
    case open
    case taken
    case skipped
    case less
}

@Model
final class Journey {
    var id: UUID
    var startedAt: Date
    var arrivedAt: Date?
    var arrivalDeclinedOn: Date?
    var trailheadWeeklyMg: Double

    @Relationship(deleteRule: .cascade, inverse: \ProtocolVersion.journey)
    var protocolVersions: [ProtocolVersion] = []

    @Relationship(deleteRule: .cascade, inverse: \ScheduledEvent.journey)
    var events: [ScheduledEvent] = []

    @Relationship(deleteRule: .cascade, inverse: \RescueDose.journey)
    var rescues: [RescueDose] = []

    init(
        id: UUID = UUID(),
        startedAt: Date,
        trailheadWeeklyMg: Double
    ) {
        self.id = id
        self.startedAt = startedAt
        self.trailheadWeeklyMg = trailheadWeeklyMg
    }

    var currentProtocol: ProtocolVersion? {
        protocolVersions.first { $0.endedAt == nil }
    }

    var isArrived: Bool { arrivedAt != nil }
}

@Model
final class ProtocolVersion {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \DoseSlot.protocolVersion)
    var slots: [DoseSlot] = []

    var journey: Journey?

    init(id: UUID = UUID(), startedAt: Date) {
        self.id = id
        self.startedAt = startedAt
    }

    var weeklyPlannedMg: Double {
        slots.reduce(0) { $0 + $1.weeklyPlannedMg }
    }
}

@Model
final class DoseSlot {
    var id: UUID
    var amountMg: Double
    var hour: Int
    var minute: Int
    /// Bit 0 = Sunday (Calendar weekday 1), bit 6 = Saturday.
    var weekdayBits: Int

    var protocolVersion: ProtocolVersion?

    init(
        id: UUID = UUID(),
        amountMg: Double,
        hour: Int,
        minute: Int,
        weekdayBits: Int
    ) {
        self.id = id
        self.amountMg = amountMg
        self.hour = hour
        self.minute = minute
        self.weekdayBits = weekdayBits
    }

    var weekdays: Set<Int> {
        get {
            Set((1...7).filter { weekdayBits & (1 << ($0 - 1)) != 0 })
        }
        set {
            weekdayBits = newValue.reduce(0) { $0 | (1 << ($1 - 1)) }
        }
    }

    var weeklyPlannedMg: Double {
        amountMg * Double(weekdays.count)
    }

    func includes(weekday: Int) -> Bool {
        weekdayBits & (1 << (weekday - 1)) != 0
    }

    var timeComponents: DateComponents {
        DateComponents(hour: hour, minute: minute)
    }
}

@Model
final class ScheduledEvent {
    var id: UUID
    /// Start of the local calendar day this step belongs to.
    var dayStart: Date
    var slotId: UUID
    var protocolId: UUID
    var plannedAmountMg: Double
    var actualAmountMg: Double?
    var statusRaw: String
    var takenAt: Date?
    var confirmedAt: Date?
    var hour: Int
    var minute: Int

    var journey: Journey?

    init(
        id: UUID = UUID(),
        dayStart: Date,
        slotId: UUID,
        protocolId: UUID,
        plannedAmountMg: Double,
        hour: Int,
        minute: Int
    ) {
        self.id = id
        self.dayStart = dayStart
        self.slotId = slotId
        self.protocolId = protocolId
        self.plannedAmountMg = plannedAmountMg
        self.hour = hour
        self.minute = minute
        self.statusRaw = EventStatus.open.rawValue
    }

    var status: EventStatus {
        get { EventStatus(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue }
    }

    var isOpen: Bool { status == .open }

    var isConfirmed: Bool { status != .open }
}

@Model
final class RescueDose {
    var id: UUID
    var takenAt: Date
    var amountMg: Double
    var linkedScheduledId: UUID?

    var journey: Journey?

    init(
        id: UUID = UUID(),
        takenAt: Date,
        amountMg: Double,
        linkedScheduledId: UUID? = nil
    ) {
        self.id = id
        self.takenAt = takenAt
        self.amountMg = amountMg
        self.linkedScheduledId = linkedScheduledId
    }

    var isOverflow: Bool { linkedScheduledId != nil }
}
