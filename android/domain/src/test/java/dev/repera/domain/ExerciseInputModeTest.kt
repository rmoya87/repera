package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class ExerciseInputModeTest {
    @Test fun strengthIsLoadAndReps() {
        assertEquals(ExerciseInputMode.LOAD_REPS,
            ExerciseInput.mode("Press banca", "Barra", "pectorals", "Pecho"))
    }

    @Test fun bodyweightDoesNotInventKilograms() {
        assertEquals(ExerciseInputMode.REPS_ONLY,
            ExerciseInput.mode("Burpee", "Peso corporal", null, "Cardio"))
        assertEquals(ExerciseInputMode.LOAD_REPS,
            ExerciseInput.mode("Dominadas", "Peso corporal", "lats", "Espalda"))
    }

    @Test fun mobilityNeverRequestsExternalLoad() {
        val hold = ExerciseInput.mode("Colgado pasivo", "Barra", "lats", "Espalda", "Movilidad")
        assertEquals(ExerciseInputMode.REPS_AND_TIME, hold)
        assertFalse(hold.showsWeight)
        val dynamic = ExerciseInput.mode("CARs de hombro", "Peso corporal",
            "delts", "Hombros", "Movilidad")
        assertEquals(ExerciseInputMode.REPS_AND_TIME, dynamic)
        assertTrue(dynamic.basicRecorderAvailable)
        assertEquals(ExerciseInputMode.LOAD_REPS,
            ExerciseInput.mode("Press banca", "Barra", "pectorals", "Pecho"))
    }

    @Test fun cardioAndJumpRopeAreRecordableWithCorrectUnits() {
        assertTrue(ExerciseInput.mode("SkiErg", null, null, "Cardio").basicRecorderAvailable)
        assertTrue(ExerciseInput.mode("Double under", "Comba", null, "Cardio").basicRecorderAvailable)
        assertEquals("calories", ExerciseInput.defaultQuantityUnit("Echo Bike", null))
        assertEquals("calories", ExerciseInput.defaultQuantityUnit("SkiErg", null))
        assertEquals("meters", ExerciseInput.defaultQuantityUnit("Remoergómetro", null))
        assertEquals("meters", ExerciseInput.defaultQuantityUnit("Carrera", null))
        assertEquals("reps", ExerciseInput.defaultQuantityUnit("Sentadilla", "Barra"))
        assertTrue(ExerciseInput.supportsCaloriesAndMeters("SkiErg", null))
        assertFalse(ExerciseInput.supportsCaloriesAndMeters("Carrera", null))
    }

    @Test fun otherLoggingStylesNeedTheirFullEditor() {
        assertEquals(ExerciseInputMode.MACHINE_WORK,
            ExerciseInput.mode("Carrera", "Peso corporal", "cardiovascular system", "Cardio"))
        assertEquals(ExerciseInputMode.REPS_AND_TIME,
            ExerciseInput.mode("Double under", "Comba", null, "Cardio"))
        assertEquals(ExerciseInputMode.HSPU_DEFICIT,
            ExerciseInput.mode("HSPU", "Peso corporal", null, "Hombros"))
    }
}
