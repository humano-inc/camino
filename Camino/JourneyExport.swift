import Foundation

enum JourneyExport {
    struct Snapshot: Codable {
        var exportedAt: Date
        var journeys: [JourneyJSON]
    }

    struct JourneyJSON: Codable {
        var id: UUID
        var startedAt: Date
        var arrivedAt: Date?
        var trailheadWeeklyMg: Double
        var protocols: [ProtocolJSON]
        var events: [EventJSON]
        var rescues: [RescueJSON]
    }

    struct ProtocolJSON: Codable {
        var id: UUID
        var startedAt: Date
        var endedAt: Date?
        var weeklyPlannedMg: Double
        var slots: [SlotJSON]
    }

    struct SlotJSON: Codable {
        var id: UUID
        var amountMg: Double
        var hour: Int
        var minute: Int
        var weekdays: [Int]
    }

    struct EventJSON: Codable {
        var id: UUID
        var dayStart: Date
        var slotId: UUID
        var protocolId: UUID
        var plannedAmountMg: Double
        var actualAmountMg: Double?
        var status: String
        var takenAt: Date?
        var confirmedAt: Date?
        var hour: Int
        var minute: Int
    }

    struct RescueJSON: Codable {
        var id: UUID
        var takenAt: Date
        var amountMg: Double
        var linkedScheduledId: UUID?
    }

    static func snapshot(journeys: [Journey]) -> Snapshot {
        Snapshot(
            exportedAt: Date(),
            journeys: journeys.sorted { $0.startedAt < $1.startedAt }.map { journey in
                JourneyJSON(
                    id: journey.id,
                    startedAt: journey.startedAt,
                    arrivedAt: journey.arrivedAt,
                    trailheadWeeklyMg: journey.trailheadWeeklyMg,
                    protocols: journey.protocolVersions.sorted { $0.startedAt < $1.startedAt }.map { version in
                        ProtocolJSON(
                            id: version.id,
                            startedAt: version.startedAt,
                            endedAt: version.endedAt,
                            weeklyPlannedMg: version.weeklyPlannedMg,
                            slots: version.slots.map { slot in
                                SlotJSON(
                                    id: slot.id,
                                    amountMg: slot.amountMg,
                                    hour: slot.hour,
                                    minute: slot.minute,
                                    weekdays: slot.weekdays.sorted()
                                )
                            }
                        )
                    },
                    events: journey.events.sorted { $0.dayStart < $1.dayStart }.map { event in
                        EventJSON(
                            id: event.id,
                            dayStart: event.dayStart,
                            slotId: event.slotId,
                            protocolId: event.protocolId,
                            plannedAmountMg: event.plannedAmountMg,
                            actualAmountMg: event.actualAmountMg,
                            status: event.statusRaw,
                            takenAt: event.takenAt,
                            confirmedAt: event.confirmedAt,
                            hour: event.hour,
                            minute: event.minute
                        )
                    },
                    rescues: journey.rescues.sorted { $0.takenAt < $1.takenAt }.map { rescue in
                        RescueJSON(
                            id: rescue.id,
                            takenAt: rescue.takenAt,
                            amountMg: rescue.amountMg,
                            linkedScheduledId: rescue.linkedScheduledId
                        )
                    }
                )
            }
        )
    }

    static func jsonData(journeys: [Journey]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot(journeys: journeys))
    }
}
