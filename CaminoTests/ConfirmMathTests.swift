import XCTest
@testable import Camino

final class ConfirmMathTests: XCTestCase {
    func testTakenUsesPromisedAmount() {
        let result = ConfirmMath.resolve(planned: 0.125, entry: .taken)
        XCTAssertEqual(result, .taken(actual: 0.125))
        XCTAssertEqual(result.status, .taken)
        XCTAssertEqual(result.eventActualMg, 0.125)
        XCTAssertEqual(result.overflowMg, 0)
    }

    func testSkipIsZeroAndNotAFailure() {
        let result = ConfirmMath.resolve(planned: 0.125, entry: .skipped)
        XCTAssertEqual(result, .skipped)
        XCTAssertEqual(result.eventActualMg, 0)
        XCTAssertEqual(result.overflowMg, 0)
    }

    func testLessIsQuieterNotBroken() {
        let result = ConfirmMath.resolve(planned: 0.125, entry: .amount(0.0625))
        XCTAssertEqual(result, .less(actual: 0.0625))
        XCTAssertEqual(result.status, .less)
        XCTAssertEqual(result.overflowMg, 0)
    }

    func testMoreSplitsToRescue() {
        let result = ConfirmMath.resolve(planned: 0.125, entry: .amount(0.25))
        XCTAssertEqual(result, .split(planned: 0.125, overflow: 0.125))
        XCTAssertEqual(result.status, .taken)
        XCTAssertEqual(result.eventActualMg, 0.125)
        XCTAssertEqual(result.overflowMg, 0.125, accuracy: Tablet.epsilon)
    }

    func testSameAmountAsPromiseIsTaken() {
        let result = ConfirmMath.resolve(planned: 0.125, entry: .amount(0.125))
        XCTAssertEqual(result, .taken(actual: 0.125))
    }

    func testQuarterIsPointZeroSixTwoFive() {
        XCTAssertEqual(formatMg(Tablet.quarterMg), "0.0625")
        XCTAssertNotEqual(formatMg(0.0675), "0.0625")
        XCTAssertEqual(PieceChoice.matching(0.0625), .quarter)
        XCTAssertEqual(PieceChoice.matching(0.1), .custom)
    }
}
