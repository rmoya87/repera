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
        for (s in LiveSport.entries) {
            val type = HealthConnectWriter.exerciseTypeFor(s)
            // OTHER se exporta como fuerza (FallbackActivityKind), no OTHER_WORKOUT.
            if (s == LiveSport.STRENGTH || s == LiveSport.OTHER) {
                assertEquals(s.id, ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING, type)
            } else {
                assertTrue(s.id, type != ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING)
            }
        }
    }

    @Test fun titleFallbackResolvesHiitAndStrength() {
        assertEquals(
            ExerciseSessionRecord.EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING,
            HealthConnectWriter.exerciseTypeFor(null, "HIIT 30'")
        )
        assertEquals(
            ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING,
            HealthConnectWriter.exerciseTypeFor(LiveSport.OTHER, "Clase de las 18:00")
        )
    }
}
