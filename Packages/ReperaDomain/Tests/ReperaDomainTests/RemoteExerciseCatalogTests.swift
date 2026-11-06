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

    func testMergeAppendsRemoteOnlyExerciseWithStableUUID() {
        let key = "catalog:Ejercicio Solo Remoto"
        let remote = RemoteExerciseCatalogEntry(
            name: "Ejercicio Solo Remoto",
            category: "Fuerza",
            primaryMuscles: ["Pecho"],
            equipment: ["Mancuernas"],
            description: "Alta solo en Supabase",
            instructions: ["Paso 1", "Paso 2"],
            muscleGroup: "Pecho",
            isActive: true
        )
        let source = RemoteExerciseCatalogSnapshot(
            revision: 10,
            entries: [key: remote]
        )
        let result = RemoteExerciseCatalogMerge.apply(source: source, current: [])
        XCTAssertTrue(result.changed)
        XCTAssertEqual(result.exercises.count, 1)
        let added = result.exercises[0]
        XCTAssertEqual(added.name, "Ejercicio Solo Remoto")
        XCTAssertEqual(added.detailDescription, "Alta solo en Supabase")
        XCTAssertEqual(added.instructions, ["Paso 1", "Paso 2"])
        XCTAssertEqual(added.equipment, "Mancuernas")
        XCTAssertEqual(added.muscleGroup, "Pecho")
        XCTAssertEqual(added.id, RemoteExerciseCatalogMerge.stableUUID(for: key))
        XCTAssertEqual(result.snapshot.localIDs[key], added.id)
        XCTAssertFalse(added.isCatalogArchived)
    }

    func testMergePublishedFieldsOverwriteSeedKeepingFavoriteAndUUID() {
        let id = UUID()
        let seed = Exercise(
            id: id,
            name: "Press banca",
            muscleGroup: "Pecho",
            equipment: "Barra",
            detailDescription: "Texto seed",
            instructions: ["Seed A"],
            isFavorite: true
        )
        let key = "catalog:Press banca"
        let remote = RemoteExerciseCatalogEntry(
            name: "Press banca corregido",
            category: "Fuerza",
            aliases: ["Bench"],
            primaryMuscles: ["Pecho"],
            equipment: ["Barra", "Banco"],
            description: "Texto remoto",
            instructions: ["Remoto 1"],
            muscleGroup: "Pecho",
            skillLevel: "intermediate",
            movementPattern: "push",
            alternatives: ["Press mancuernas"],
            artKeys: ["art_press_banca", "art_press_banca_1"],
            isActive: true
        )
        let source = RemoteExerciseCatalogSnapshot(
            revision: 3,
            entries: [key: remote],
            localIDs: [key: id]
        )
        let result = RemoteExerciseCatalogMerge.apply(source: source, current: [seed])
        XCTAssertTrue(result.changed)
        XCTAssertEqual(result.exercises.count, 1)
        let next = result.exercises[0]
        XCTAssertEqual(next.id, id)
        XCTAssertTrue(next.isFavorite)
        XCTAssertEqual(next.name, "Press banca corregido")
        XCTAssertEqual(next.detailDescription, "Texto remoto")
        XCTAssertEqual(next.instructions, ["Remoto 1"])
        XCTAssertEqual(next.equipment, "Barra, Banco")
        XCTAssertEqual(next.searchAliases, ["Bench"])
        XCTAssertEqual(next.skillLevel, "intermediate")
        XCTAssertEqual(next.movementPattern, "push")
        XCTAssertEqual(next.catalogAlternatives, ["Press mancuernas"])
        XCTAssertEqual(next.artKeys, ["art_press_banca", "art_press_banca_1"])
    }

    func testPublishedAlternativesPreferredOverHeuristic() {
        let press = Exercise(id: UUID(), name: "Press banca", muscleGroup: "Pecho",
                             catalogAlternatives: ["Fondos"])
        let fondos = Exercise(id: UUID(), name: "Fondos", muscleGroup: "Pecho")
        let other = Exercise(id: UUID(), name: "Aperturas", muscleGroup: "Pecho",
                             targetMuscle: "Pecho")
        let hits = ExerciseSubstitutes.substitutes(
            for: press, in: [press, fondos, other], limit: 5
        )
        XCTAssertEqual(hits.map(\.name), ["Fondos"])
    }

    func testMergeEmptyRemoteFieldsDoNotWipeSeed() {
        let id = UUID()
        let seed = Exercise(
            id: id,
            name: "Dominadas",
            muscleGroup: "Espalda",
            equipment: "Barra de dominadas",
            detailDescription: "Descripción seed",
            instructions: ["Agarre", "Sube"],
            isFavorite: false
        )
        let key = "catalog:Dominadas"
        let remote = RemoteExerciseCatalogEntry(
            name: "Dominadas",
            category: "Fuerza",
            equipment: [],
            description: nil,
            instructions: [],
            isActive: true
        )
        let source = RemoteExerciseCatalogSnapshot(
            revision: 2,
            entries: [key: remote],
            localIDs: [key: id]
        )
        let result = RemoteExerciseCatalogMerge.apply(source: source, current: [seed])
        let next = result.exercises[0]
        XCTAssertEqual(next.id, id)
        XCTAssertEqual(next.detailDescription, "Descripción seed")
        XCTAssertEqual(next.instructions, ["Agarre", "Sube"])
        XCTAssertEqual(next.equipment, "Barra de dominadas")
    }

    func testMergeInactiveArchivesWithoutLosingIdentity() {
        let id = UUID()
        let seed = Exercise(
            id: id,
            name: "Fondos",
            muscleGroup: "Pecho",
            isFavorite: true
        )
        let key = "catalog:Fondos"
        let remote = RemoteExerciseCatalogEntry(
            name: "Fondos",
            category: "Fuerza",
            isActive: false
        )
        let source = RemoteExerciseCatalogSnapshot(
            revision: 5,
            entries: [key: remote],
            localIDs: [key: id],
            tombstones: [key]
        )
        let result = RemoteExerciseCatalogMerge.apply(source: source, current: [seed])
        XCTAssertTrue(result.changed)
        let next = result.exercises[0]
        XCTAssertEqual(next.id, id)
        XCTAssertTrue(next.isFavorite)
        XCTAssertTrue(next.isCatalogArchived)
    }

    func testAlternativesPresenceControlsClearingWithoutChangingOtherFields() throws {
        let key = "catalog:Press banca"
        let cases: [(String, Any?, [String]?)] = [
            ("absent", nil, nil),
            ("null", NSNull(), nil),
            ("empty", [String](), []),
            ("replacement", ["Press mancuernas"], ["Press mancuernas"])
        ]
        for previous in [["Press antiguo"], [String]()] {
            for (label, published, expected) in cases {
                let id = UUID()
                let seed = Exercise(
                    id: id, name: "Press banca", muscleGroup: "Pecho",
                    equipment: "Barra", instructions: ["Seed"], isFavorite: true,
                    catalogAlternatives: previous, artKeys: ["art_seed"]
                )
                var payload: [String: Any] = [
                    "name": "Press banca", "category": "Fuerza", "is_active": true,
                    "instructions": [String](), "art_keys": [String]()
                ]
                if let published { payload["alternatives"] = published }
                let remote = try JSONDecoder().decode(
                    RemoteExerciseCatalogEntry.self,
                    from: JSONSerialization.data(withJSONObject: payload)
                )
                XCTAssertEqual(remote.alternatives, expected, label)
                let source = RemoteExerciseCatalogSnapshot(
                    revision: 1, entries: [key: remote], localIDs: [key: id]
                )
                let result = RemoteExerciseCatalogMerge.apply(source: source, current: [seed])
                let next = try XCTUnwrap(result.exercises.first)
                XCTAssertEqual(next.catalogAlternatives, expected ?? previous, label)
                XCTAssertEqual(next.id, id, label)
                XCTAssertTrue(next.isFavorite, label)
                XCTAssertEqual(next.instructions, ["Seed"], label)
                XCTAssertEqual(next.artKeys, ["art_seed"], label)
                XCTAssertEqual(next.equipment, "Barra", label)
                let repeated = RemoteExerciseCatalogMerge.apply(
                    source: result.snapshot, current: result.exercises
                )
                XCTAssertFalse(repeated.changed, label)
                XCTAssertEqual(repeated.exercises, result.exercises, label)
            }
        }
    }

    func testStableUUIDIsDeterministicAcrossCalls() {
        let key = "catalog:Arrancada"
        XCTAssertEqual(
            RemoteExerciseCatalogMerge.stableUUID(for: key),
            RemoteExerciseCatalogMerge.stableUUID(for: key)
        )
        XCTAssertNotEqual(
            RemoteExerciseCatalogMerge.stableUUID(for: key),
            RemoteExerciseCatalogMerge.stableUUID(for: "catalog:Envión")
        )
    }
}
