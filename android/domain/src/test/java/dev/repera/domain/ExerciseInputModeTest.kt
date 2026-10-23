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

    @Test fun otherLoggingStylesNeedTheirFullEditor() {
        assertEquals(ExerciseInputMode.MACHINE_WORK,
            ExerciseInput.mode("Carrera", "Peso corporal", "cardiovascular system", "Cardio"))
        assertEquals(ExerciseInputMode.REPS_AND_TIME,
            ExerciseInput.mode("Double under", "Comba", null, "Cardio"))
        assertEquals(ExerciseInputMode.HSPU_DEFICIT,
            ExerciseInput.mode("HSPU", "Peso corporal", null, "Hombros"))
    }
}
