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
}
