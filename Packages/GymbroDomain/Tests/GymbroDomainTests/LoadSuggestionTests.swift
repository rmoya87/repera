import XCTest
@testable import GymbroDomain

final class LoadSuggestionTests: XCTestCase {
    func testPercentFromNotes() {
        XCTAssertEqual(LoadSuggestion.percentOfOneRM(from: "#70%")?.value, 70)
        XCTAssertEqual(LoadSuggestion.percentOfOneRM(from: "#>80%")?.value, 80)
        XCTAssertEqual(LoadSuggestion.percentOfOneRM(from: "#>80%")?.isMinimum, true)
        XCTAssertNil(LoadSuggestion.percentOfOneRM(from: "sin porcentaje"))
    }

    func testWeightFromOneRM() {
        let kg = LoadSuggestion.weightKg(oneRM: 100, percent: 70, roundTo: 2.5)
        XCTAssertEqual(kg, 70)
    }
}
