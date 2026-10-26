import Foundation
import XCTest
@testable import ReperaDomain

final class RemoteExerciseCatalogTests: XCTestCase {
    func testRemoteAliasesPersistAndOldExercisePayloadStillDecodes() throws {
        let entry = Exercise(
            name: "Burpee to target",
            muscleGroup: "Cardio",
            searchAliases: ["BTT", "Burpee a diana"]
        )
        let encoded = try JSONEncoder().encode(entry)
        let restored = try JSONDecoder().decode(Exercise.self, from: encoded)
        XCTAssertEqual(restored.searchAliases, ["BTT", "Burpee a diana"])
        var old = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        old.removeValue(forKey: "searchAliases")
        let oldData = try JSONSerialization.data(withJSONObject: old)
        let oldExercise = try JSONDecoder().decode(Exercise.self, from: oldData)
        XCTAssertEqual(oldExercise.searchAliases, [])
    }

    func testArchivedExerciseRoundTripsWithoutChangingIdentity() throws {
        let stableID = UUID()
        let archived = Exercise(
            id: stableID,
            name: "Press banca",
            muscleGroup: "Pecho",
            equipment: "Barra",
            isFavorite: true,
            isCatalogArchived: true
        )
        let restored = try JSONDecoder().decode(Exercise.self, from: JSONEncoder().encode(archived))
        XCTAssertEqual(restored.id, stableID)
        XCTAssertEqual(restored.isCatalogArchived, true)
        XCTAssertEqual(restored.isFavorite, true)
    }

    func testOldExercisePayloadRemainsDecodable() throws {
        let original = Exercise(name: "Dominadas", muscleGroup: "Espalda")
        let encoded = try JSONEncoder().encode(original)
        var payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        payload.removeValue(forKey: "isCatalogArchived")
        let legacy = try JSONSerialization.data(withJSONObject: payload)
        let restored = try JSONDecoder().decode(Exercise.self, from: legacy)
        XCTAssertEqual(restored.id, original.id)
        XCTAssertFalse(restored.isCatalogArchived)
        XCTAssertFalse(restored.isCustom)
    }
}
