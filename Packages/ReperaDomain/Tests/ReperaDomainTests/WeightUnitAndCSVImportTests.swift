import XCTest
@testable import ReperaDomain

final class WeightUnitAndCSVImportTests: XCTestCase {
    func testUnitRoundTripPreservesStoredKilograms() {
        let weightKg = 100.0
        let shownLb = WeightUnit.lb.displayValue(fromKilograms: weightKg)
        XCTAssertEqual(shownLb, 220.46226218, accuracy: 0.000001)
        XCTAssertEqual(
            WeightUnit.lb.kilograms(fromDisplayValue: shownLb),
            weightKg, accuracy: 0.000001
        )
        XCTAssertEqual(WeightUnit.kg.displayValue(fromKilograms: weightKg), weightKg)
    }

    func testHevyCSVWithExplicitPoundsColumnStoresKilograms() {
        let csv = """
        start_time,title,exercise_title,set_index,weight_lbs,reps
        2026-10-28 07:00:00,Entreno,Back Squat,1,220.462262,5
        """
        let result = WorkoutCSVImporter.parse(csv: csv, existingExercises: [])
        XCTAssertEqual(result.source, .hevy)
        XCTAssertEqual(result.workouts.count, 1)
        XCTAssertEqual(result.matchedSets, 1)
        let weight = result.workouts.first?.exercises.first?.loggedSets.first?.weightKg
        XCTAssertNotNil(weight)
        if let weight { XCTAssertEqual(weight, 100, accuracy: 0.01) }
    }
}
