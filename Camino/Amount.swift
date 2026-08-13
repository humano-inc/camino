import Foundation

enum Tablet {
    static let wholeMg = 0.25
    static let quarterMg = 0.0625
    static let halfMg = 0.125
    static let threeQuarterMg = 0.1875
    static let epsilon = 0.00005
}

func mgEqual(_ a: Double, _ b: Double) -> Bool {
    abs(a - b) < Tablet.epsilon
}

func formatMg(_ mg: Double) -> String {
    if mgEqual(mg, 0) { return "0" }
    if mgEqual(mg, Tablet.quarterMg) { return "0.0625" }
    if mgEqual(mg, Tablet.halfMg) { return "0.125" }
    if mgEqual(mg, Tablet.threeQuarterMg) { return "0.1875" }
    if mgEqual(mg, Tablet.wholeMg) { return "0.25" }

    var value = mg
    if abs(value) < Tablet.epsilon { value = 0 }
    let formatted = String(format: "%.4f", value)
    var trimmed = formatted
    while trimmed.contains(".") && (trimmed.hasSuffix("0") || trimmed.hasSuffix(".")) {
        trimmed.removeLast()
        if trimmed.hasSuffix(".") {
            trimmed.removeLast()
            break
        }
    }
    return trimmed
}

enum PieceChoice: Hashable, CaseIterable {
    case quarter
    case half
    case threeQuarter
    case one
    case custom

    var milligrams: Double? {
        switch self {
        case .quarter: Tablet.quarterMg
        case .half: Tablet.halfMg
        case .threeQuarter: Tablet.threeQuarterMg
        case .one: Tablet.wholeMg
        case .custom: nil
        }
    }

    var glyph: String {
        switch self {
        case .quarter: Copy.pieceQuarter
        case .half: Copy.pieceHalf
        case .threeQuarter: Copy.pieceThreeQuarter
        case .one: Copy.pieceOne
        case .custom: Copy.custom
        }
    }

    var secondary: String {
        switch self {
        case .quarter: "0.0625"
        case .half: "0.125"
        case .threeQuarter: "0.1875"
        case .one: "0.25"
        case .custom: "mg"
        }
    }

    static func matching(_ mg: Double) -> PieceChoice {
        for piece in [PieceChoice.quarter, .half, .threeQuarter, .one] {
            if let value = piece.milligrams, mgEqual(value, mg) {
                return piece
            }
        }
        return .custom
    }
}
