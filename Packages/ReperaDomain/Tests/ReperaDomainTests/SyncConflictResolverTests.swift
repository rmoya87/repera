import XCTest
@testable import ReperaDomain

final class SyncConflictResolverTests: XCTestCase {
    private func state(
        revision: Int,
        updatedAt: Date,
        writer: String
    ) -> AppState {
        AppState(
            exercises: [],
            routines: [],
            workouts: [],
            bodyWeights: [],
            updatedAt: updatedAt,
            syncRevision: revision,
            lastWriterDeviceId: writer
        )
    }

    func testHigherRevisionWinsOverNewerDate() {
        let olderStamp = Date(timeIntervalSince1970: 1_000)
        let newerStamp = Date(timeIntervalSince1970: 2_000)
        let local = state(revision: 5, updatedAt: newerStamp, writer: "A")
        let remote = state(revision: 6, updatedAt: olderStamp, writer: "B")
        XCTAssertEqual(SyncConflictResolver.winner(local: local, remote: remote), .remote)
        XCTAssertEqual(SyncConflictResolver.pickNewest(local: local, remote: remote)?.syncRevision, 6)
    }

    func testSameRevisionPrefersNewerUpdatedAt() {
        let local = state(revision: 3, updatedAt: Date(timeIntervalSince1970: 10), writer: "A")
        let remote = state(revision: 3, updatedAt: Date(timeIntervalSince1970: 20), writer: "B")
        XCTAssertEqual(SyncConflictResolver.winner(local: local, remote: remote), .remote)
    }

    func testTieBreakUsesWriterIdDeterministically() {
        let stamp = Date(timeIntervalSince1970: 42)
        let local = state(revision: 2, updatedAt: stamp, writer: "device-a")
        let remote = state(revision: 2, updatedAt: stamp, writer: "device-z")
        XCTAssertEqual(SyncConflictResolver.winner(local: local, remote: remote), .remote)
        XCTAssertEqual(SyncConflictResolver.winner(local: remote, remote: local), .local)
    }

    func testEqualDocuments() {
        let stamp = Date(timeIntervalSince1970: 7)
        let local = state(revision: 1, updatedAt: stamp, writer: "same")
        let remote = state(revision: 1, updatedAt: stamp, writer: "same")
        XCTAssertEqual(SyncConflictResolver.winner(local: local, remote: remote), .equal)
    }

    func testPickNewestNilCases() {
        let only = state(revision: 1, updatedAt: Date(), writer: "A")
        XCTAssertNil(SyncConflictResolver.pickNewest(local: nil, remote: nil))
        XCTAssertEqual(SyncConflictResolver.pickNewest(local: only, remote: nil)?.lastWriterDeviceId, "A")
        XCTAssertEqual(SyncConflictResolver.pickNewest(local: nil, remote: only)?.lastWriterDeviceId, "A")
    }

    func testHistoricalBlockBackfillRequiresExactOriginalWorkout() {
        let started = Date(timeIntervalSince1970: 1_729_000_000)
        let finished = started.addingTimeInterval(1_800)
        let remote = WorkoutSession(
            title: "AMRAP histórico",
            exercises: [],
            phase: .finished,
            startedAt: started,
            finishedAt: finished
        )
        var local = remote
        local.routineBlocks = [.wod(format: .amrap)]
        XCTAssertTrue(SyncConflictResolver.canRestoreMissingBlockSnapshot(
            local: local, remote: remote
        ))

        var changedRemote = remote
        changedRemote.title = "Editado en otro dispositivo"
        XCTAssertFalse(SyncConflictResolver.canRestoreMissingBlockSnapshot(
            local: local, remote: changedRemote
        ))

        changedRemote = remote
        changedRemote.finishedAt = finished.addingTimeInterval(10)
        XCTAssertFalse(SyncConflictResolver.canRestoreMissingBlockSnapshot(
            local: local, remote: changedRemote
        ))

        var alreadyStructured = remote
        alreadyStructured.routineBlocks = [.wod(format: .forTime)]
        XCTAssertFalse(SyncConflictResolver.canRestoreMissingBlockSnapshot(
            local: local, remote: alreadyStructured
        ))

        XCTAssertFalse(SyncConflictResolver.canRestoreMissingBlockSnapshot(
            local: remote, remote: remote
        ))
    }

    func testMissingGPSRouteIsRestoredWithoutChangingRecordedWorkout() {
        let start = Date(timeIntervalSince1970: 1_729_000_000)
        let id = UUID()
        let session = WorkoutSession(
            id: id, title: "Paseo", exercises: [],
            phase: .finished, startedAt: start, finishedAt: start.addingTimeInterval(600),
            recordedDistanceMeters: 1_000
        )
        var withGPS = session
        withGPS.routePoints = [
            WorkoutRoutePoint(id: 1, latitude: 40.5, longitude: -3.8, recordedAt: start),
            WorkoutRoutePoint(id: 2, latitude: 40.501, longitude: -3.799,
                              recordedAt: start.addingTimeInterval(60))
        ]
        var newest = state(revision: 11, updatedAt: start.addingTimeInterval(100), writer: "new")
        newest.workouts = [session]
        var older = state(revision: 10, updatedAt: start, writer: "old")
        older.workouts = [withGPS]
        let recovered = SyncConflictResolver.restoringMissingWorkoutRoutes(
            in: newest, from: older
        )
        XCTAssertEqual(recovered.workouts[0].routePoints, withGPS.routePoints)
        XCTAssertEqual(recovered.workouts[0].id, id)
        XCTAssertEqual(recovered.workouts[0].recordedDistanceMeters, session.recordedDistanceMeters)
        XCTAssertEqual(recovered.syncRevision, 11)
        XCTAssertTrue(newest.workouts[0].routePoints.isEmpty)
    }

    func testNeverInventsRoutesOrRevivesDeletedWorkoutIDs() {
        let start = Date(timeIntervalSince1970: 1_729_000_000)
        var tracked = WorkoutSession(
            title: "Actividad original", exercises: [], phase: .finished,
            startedAt: start, finishedAt: start.addingTimeInterval(100)
        )
        tracked.routePoints = [
            WorkoutRoutePoint(id: 1, latitude: 40, longitude: -3),
            WorkoutRoutePoint(id: 2, latitude: 41, longitude: -3)
        ]
        var cloud = state(revision: 5, updatedAt: start, writer: "old")
        cloud.workouts = [tracked]
        let current = state(revision: 6, updatedAt: start, writer: "new")
        let recovered = SyncConflictResolver.restoringMissingWorkoutRoutes(
            in: current, from: cloud
        )
        XCTAssertTrue(recovered.workouts.isEmpty)

        let unrelated = WorkoutSession(
            title: "Otra actividad", exercises: [], phase: .finished,
            startedAt: start, finishedAt: start.addingTimeInterval(100)
        )
        var currentWithOtherID = current
        currentWithOtherID.workouts = [unrelated]
        let noCrossWorkoutRoute = SyncConflictResolver.restoringMissingWorkoutRoutes(
            in: currentWithOtherID, from: cloud
        )
        XCTAssertTrue(noCrossWorkoutRoute.workouts[0].routePoints.isEmpty)

        var currentWithRoute = current
        currentWithRoute.workouts = [tracked]
        XCTAssertEqual(
            SyncConflictResolver.restoringMissingWorkoutRoutes(
                in: currentWithRoute, from: cloud
            ).workouts[0].routePoints,
            tracked.routePoints
        )
    }

    func testDeletionTombstonesSurviveJSONRoundTripAndLegacyState() throws {
        let exerciseID = UUID(), workoutID = UUID(), entryID = UUID()
        var state = self.state(revision: 5, updatedAt: Date(), writer: "local")
        state.deletedExerciseIDs = [exerciseID]
        state.deletedWorkoutIDs = [workoutID]
        state.deletedWorkoutExerciseIDs[workoutID.uuidString] = [entryID]

        let bytes = try JSONEncoder().encode(state)
        let restored = try JSONDecoder().decode(AppState.self, from: bytes)
        XCTAssertEqual(restored.deletedExerciseIDs, [exerciseID])
        XCTAssertEqual(restored.deletedWorkoutIDs, [workoutID])
        XCTAssertEqual(restored.deletedWorkoutExerciseIDs[workoutID.uuidString], [entryID])

        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        legacy.removeValue(forKey: "deletedExerciseIDs")
        legacy.removeValue(forKey: "deletedWorkoutIDs")
        legacy.removeValue(forKey: "deletedWorkoutExerciseIDs")
        let migrated = try JSONDecoder().decode(
            AppState.self, from: JSONSerialization.data(withJSONObject: legacy)
        )
        XCTAssertTrue(migrated.deletedExerciseIDs.isEmpty)
        XCTAssertTrue(migrated.deletedWorkoutIDs.isEmpty)
        XCTAssertTrue(migrated.deletedWorkoutExerciseIDs.isEmpty)
    }

    func testStaleCloudCannotResurrectRemovedCatalogExerciseOrWorkout() {
        let custom = Exercise(name: "Mi ejercicio", muscleGroup: "Otros", isCustom: true)
        let workout = WorkoutSession(title: "Entreno borrado", exercises: [], phase: .finished,
                                     startedAt: Date(), finishedAt: Date())
        var stale = state(revision: 20, updatedAt: Date(), writer: "remote")
        stale.exercises = [custom]
        stale.workouts = [workout]
        var deleted = state(revision: 19, updatedAt: Date(), writer: "local")
        deleted.deletedExerciseIDs = [custom.id]
        deleted.deletedWorkoutIDs = [workout.id]

        let recovered = SyncConflictResolver.reconcilingDeletionTombstones(in: stale, from: deleted)
        XCTAssertTrue(recovered.exercises.isEmpty)
        XCTAssertTrue(recovered.workouts.isEmpty)
        XCTAssertTrue(recovered.deletedExerciseIDs.contains(custom.id))
        XCTAssertTrue(recovered.deletedWorkoutIDs.contains(workout.id))
        XCTAssertEqual(recovered.syncRevision, stale.syncRevision)
    }

    func testStaleCloudCannotRestoreDeletedEntryFromFinishedWorkout() {
        let exercise = Exercise(name: "Ejercicio", muscleGroup: "Otros", isCustom: true)
        let entry = SessionExercise(exercise: exercise, plannedSets: [])
        let workout = WorkoutSession(title: "Entreno", exercises: [entry], phase: .finished,
                                     startedAt: Date(), finishedAt: Date())
        var stale = state(revision: 7, updatedAt: Date(), writer: "remote")
        stale.workouts = [workout]
        var deleted = state(revision: 6, updatedAt: Date(), writer: "local")
        deleted.deletedWorkoutExerciseIDs[workout.id.uuidString] = [entry.id]

        let recovered = SyncConflictResolver.reconcilingDeletionTombstones(in: stale, from: deleted)
        XCTAssertEqual(recovered.workouts.count, 1)
        XCTAssertTrue(recovered.workouts[0].exercises.isEmpty)
        XCTAssertEqual(recovered.deletedWorkoutExerciseIDs[workout.id.uuidString], [entry.id])
    }

    func testLegacyZeroRevisionFallsBackToUpdatedAt() {
        let local = state(revision: 0, updatedAt: Date(timeIntervalSince1970: 1), writer: "")
        let remote = state(revision: 0, updatedAt: Date(timeIntervalSince1970: 99), writer: "")
        XCTAssertEqual(SyncConflictResolver.winner(local: local, remote: remote), .remote)
    }
}
