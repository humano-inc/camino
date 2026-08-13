import Foundation

enum ConfirmEntry: Equatable {
    case taken
    case skipped
    case amount(Double)
}

enum EventResolution: Equatable {
    case taken(actual: Double)
    case skipped
    case less(actual: Double)
    case split(planned: Double, overflow: Double)

    var status: EventStatus {
        switch self {
        case .taken, .split: .taken
        case .skipped: .skipped
        case .less: .less
        }
    }

    var eventActualMg: Double {
        switch self {
        case .taken(let actual): actual
        case .skipped: 0
        case .less(let actual): actual
        case .split(let planned, _): planned
        }
    }

    var overflowMg: Double {
        switch self {
        case .split(_, let overflow): overflow
        default: 0
        }
    }
}

enum ConfirmMath {
    static func resolve(planned: Double, entry: ConfirmEntry) -> EventResolution {
        switch entry {
        case .taken:
            return .taken(actual: planned)
        case .skipped:
            return .skipped
        case .amount(let mg):
            if mg <= Tablet.epsilon {
                return .skipped
            }
            if mgEqual(mg, planned) {
                return .taken(actual: planned)
            }
            if mg < planned {
                return .less(actual: mg)
            }
            return .split(planned: planned, overflow: mg - planned)
        }
    }
}
