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

    func testScheduledRoutineStoresReusableFavoriteIDAcrossReload() throws {
        let favoriteId = UUID()
        let day = Calendar.current.startOfDay(for: Date())
        let scheduled = Routine(
            title: "Fuerza · Martes",
            scheduledDate: day,
            blocks: [.strength(title: "Fuerza")],
            isFavorite: true,
            favoriteTemplateId: favoriteId
        )
        let bytes = try JSONEncoder().encode(scheduled)
        let decoded = try JSONDecoder().decode(Routine.self, from: bytes)
        XCTAssertEqual(decoded.id, scheduled.id)
        XCTAssertEqual(decoded.scheduledDate, day)
        XCTAssertEqual(decoded.favoriteTemplateId, favoriteId)
        XCTAssertTrue(decoded.isFavorite)
        XCTAssertEqual(decoded.blocks.count, 1)
    }

    func testOlderScheduledRoutinesWithoutFavoriteLinkRemainReadable() throws {
        let dated = Routine(title: "Entreno antiguo", scheduledDate: Date(), isFavorite: true)
        let original = try JSONEncoder().encode(dated)
        var legacy = try XCTUnwrap(
            JSONSerialization.jsonObject(with: original) as? [String: Any]
        )
        legacy.removeValue(forKey: "favoriteTemplateId")
        let restored = try JSONDecoder().decode(
            Routine.self, from: JSONSerialization.data(withJSONObject: legacy)
        )
        XCTAssertTrue(restored.isFavorite)
        XCTAssertNil(restored.favoriteTemplateId)
        XCTAssertNotNil(restored.scheduledDate)
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
