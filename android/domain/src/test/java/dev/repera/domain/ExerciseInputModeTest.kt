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

    @Test fun hyroxLoadedDistanceUsesMetresWithoutCalorieToggle() {
        val sled = ExerciseInput.mode("Sled push", "Trineo", null, "Piernas")
        assertEquals(ExerciseInputMode.LOAD_DISTANCE, sled)
        assertTrue(sled.showsWeight)
        assertEquals("meters", ExerciseInput.defaultQuantityUnit("Sled push", "Trineo"))
        assertFalse(ExerciseInput.supportsCaloriesAndMeters("Sled push", "Trineo"))
        assertEquals(ExerciseInputMode.LOAD_DISTANCE,
            ExerciseInput.mode("Sandbag Lunges", "Saco", "quads", "Piernas", "HYROX"))
        assertEquals("meters", ExerciseInput.defaultQuantityUnit("Sandbag Lunges", "Saco"))
        assertEquals(ExerciseInputMode.MACHINE_WORK,
            ExerciseInput.mode("Burpee Broad Jump", "Peso corporal", null, "Cardio", "HYROX"))
        assertEquals("meters", ExerciseInput.defaultQuantityUnit("Burpee Broad Jump", "Peso corporal"))
        assertFalse(ExerciseInput.supportsCaloriesAndMeters("Burpee Broad Jump", "Peso corporal"))
        assertEquals("meters", ExerciseInput.defaultQuantityUnit("Farmer carry", "Mancuernas"))
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
    @Test fun appleSupportAndBandRulesNeverInventExternalLoad() {
        listOf("Burpee over bar" to "Barra", "Remo con banda" to "Banda elástica",
            "GHD sit-up" to "GHD", "Fondos" to "Paralelas", "Step-up" to "Cajón",
            "Flexiones" to "Anillas").forEach {(name,equipment) ->
            assertEquals(name,ExerciseInputMode.REPS_ONLY,ExerciseInput.mode(name,equipment,null,null))
        }
        assertEquals(ExerciseInputMode.LOAD_REPS,ExerciseInput.mode("Step-up","Cajón, mancuernas",null,null))
        assertEquals(ExerciseInputMode.LOAD_REPS,ExerciseInput.mode("Dominadas","Barra de dominadas",null,null))
        assertEquals(ExerciseInputMode.HSPU_DEFICIT,ExerciseInput.mode("HSPU","Pared",null,null))
        assertEquals(ExerciseInputMode.REPS_ONLY,ExerciseInput.mode("Custom",null,null,"cardio"))
    }

    @Test fun jumpRopeCoversTripleAndSuPrefixLikeApple() {
        // Apple Models.isJumpRope (bd4d7637): triples de comba y prefijo "su " también son comba.
        assertEquals(ExerciseInputMode.REPS_AND_TIME, ExerciseInput.mode("Triples de comba", null, null, null))
        assertEquals(ExerciseInputMode.REPS_AND_TIME, ExerciseInput.mode("SU x50", null, null, null))
        assertEquals(ExerciseInputMode.REPS_AND_TIME, ExerciseInput.mode("Single-Under", null, null, null))
        assertEquals(ExerciseInputMode.REPS_AND_TIME, ExerciseInput.mode("Triple under", null, null, null))
    }
}
