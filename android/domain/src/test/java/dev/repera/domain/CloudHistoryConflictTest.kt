package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class CloudHistoryConflictTest {
    @Test fun freshLocalBootstrapMayDownloadExistingRemoteWorkoutHistory() {
        assertFalse(CloudHistoryConflict.requiresManualResolution(
            emptySet(), setOf("old"), null, null))
    }

    @Test fun independentlyRecordedWorkoutsNeverOverwriteEachOther() {
        assertTrue(CloudHistoryConflict.requiresManualResolution(
            setOf("phone"), setOf("watch"), null, null))
    }

    @Test fun concurrentActiveSessionsNeedResolution() {
        assertTrue(CloudHistoryConflict.requiresManualResolution(
            emptySet(), emptySet(), "{sessionA}", "{sessionB}"))
    }

    @Test fun identicalWorkoutHistoryCanUseVersionResolution() {
        assertFalse(CloudHistoryConflict.requiresManualResolution(
            setOf("one", "two"), setOf("two", "one"), null, null))
    }

    // Escenario mirror-antes-que-Drive (ids con prefijo de colección, como DriveSnapshotService.divergentTraining).
    @Test fun mirrorRecoveredSubsetOfDriveHistoryDoesNotConflict() {
        assertFalse(CloudHistoryConflict.requiresManualResolution(
            setOf("workouts:a"), setOf("workouts:a", "workouts:b", "routines:r"), null, null))
    }

    @Test fun mirrorRecoveredWorkoutMissingFromDriveWhileDriveHasRoutinesConflicts() {
        assertTrue(CloudHistoryConflict.requiresManualResolution(
            setOf("workouts:new"), setOf("workouts:a", "routines:r"), null, null))
    }
}
