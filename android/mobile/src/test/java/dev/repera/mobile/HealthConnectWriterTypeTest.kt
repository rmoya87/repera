package dev.repera.mobile

import androidx.health.connect.client.records.ExerciseSessionRecord
import dev.repera.domain.LiveSport
import org.junit.Assert.*
import org.junit.Test

/** Mapeo LiveSport -> tipo Health Connect (aproximado para CrossFit, core, pickleball, kickboxing, lucha, lacrosse). JVM only. */
class HealthConnectWriterTypeTest {
    @Test fun classicSessionStaysStrengthAndLiveSportsDriveTheType() {
        assertEquals(ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING, HealthConnectWriter.exerciseTypeFor(null))
        assertEquals(ExerciseSessionRecord.EXERCISE_TYPE_RUNNING, HealthConnectWriter.exerciseTypeFor(LiveSport.RUNNING))
        assertEquals(ExerciseSessionRecord.EXERCISE_TYPE_BOXING, HealthConnectWriter.exerciseTypeFor(LiveSport.BOXING))
        assertEquals(ExerciseSessionRecord.EXERCISE_TYPE_ELLIPTICAL, HealthConnectWriter.exerciseTypeFor(LiveSport.ELLIPTICAL))
    }
    @Test fun everyCatalogSportMapsToAKnownType() {
        for (s in LiveSport.entries) assertTrue(s.id, HealthConnectWriter.exerciseTypeFor(s) != ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING || s == LiveSport.STRENGTH)
    }
}
