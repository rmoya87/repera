import XCTest
@testable import ReperaDomain

final class WorkoutFavoriteCodableTests: XCTestCase {
    func testFavoriteTemplateIDSurvivesSerialization() throws {
        let favoriteID = UUID()
        let session = WorkoutSession(
            title: "WOD favorito",
            favoriteRoutineId: favoriteID,
            exercises: []
        )
        let encoded = try JSONEncoder().encode(session)
        let restored = try JSONDecoder().decode(WorkoutSession.self, from: encoded)
        XCTAssertEqual(restored.favoriteRoutineId, favoriteID)
    }

    func testLegacyWorkoutsWithoutFavoriteFieldRemainReadable() throws {
        let session = WorkoutSession(title: "Entreno antiguo", exercises: [])
        let data = try JSONEncoder().encode(session)
        var legacy = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        legacy.removeValue(forKey: "favoriteRoutineId")
        let legacyData = try JSONSerialization.data(withJSONObject: legacy)
        let restored = try JSONDecoder().decode(WorkoutSession.self, from: legacyData)
        XCTAssertNil(restored.favoriteRoutineId)
    }
}
