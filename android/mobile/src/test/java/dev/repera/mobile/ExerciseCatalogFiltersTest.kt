package dev.repera.mobile

import org.junit.Assert.*
import org.junit.Test

class ExerciseCatalogFiltersTest {
    private fun e(name: String, group: String = "Piernas", sport: String? = "CrossFit") =
        ExerciseEntry(name, name, true, false,
            muscleGroup = group, sportTag = sport,
            hyroxTraining = ExerciseCatalogFilters.isHyroxTrainingMovement(name))

    @Test fun hyroxTagIsAdditiveAndDoesNotRetagCrossfit() {
        val ski = e("SkiErg", group = "Espalda")
        assertTrue(ExerciseCatalogFilters.matches(ski, "Hyrox"))
        assertTrue(ExerciseCatalogFilters.matches(ski, "CrossFit"))
        assertFalse(ExerciseCatalogFilters.matches(ski, "Cardio"))
        assertTrue(ExerciseCatalogFilters.matches(e("Wall ball"), "Hyrox"))
        assertTrue(ExerciseCatalogFilters.matches(e("Farmer carry"), "Hyrox"))
        assertFalse(ExerciseCatalogFilters.matches(e("Burpee"), "Hyrox"))
        assertFalse(ExerciseCatalogFilters.matches(e("Remo con barra"), "Hyrox"))
    }

    @Test fun filtersAreNotShownWithoutRealMatchingMovements() {
        val moves = listOf(e("Sentadilla", sport = "Halterofilia"))
        assertEquals(listOf("Todos", "Halterofilia"), ExerciseCatalogFilters.available(moves))
    }
}
