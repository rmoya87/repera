package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

/** Espejo de ExerciseDisciplineTagsTests de Apple (bd4d7637), a nivel de regla
 *  pura; la paridad de datos del seed (sportTag incluido) está verificada en
 *  android/tools contra la extracción de bd4. */
class ExerciseDisciplineTagsTest {

    private fun tags(name: String, sportTag: String?, muscleGroup: String = "", hyrox: Boolean = false) =
        ExerciseDisciplineTags.forExercise(name, sportTag, muscleGroup, hyrox)

    @Test fun weightliftingIsCrossFitCompatible() {
        assertEquals(listOf("Halterofilia", "CrossFit"), tags("Clean and Press", "Halterofilia"))
        assertEquals(listOf("Halterofilia", "CrossFit"), tags("Clean and Jerk", "Halterofilia"))
        assertEquals(listOf("Halterofilia", "CrossFit"), tags("Snatch", "Halterofilia"))
        // Apple: "Dumbbell Snatch" (sportTag CrossFit en el seed) no es arrancada olímpica con barra.
        val db = tags("Dumbbell Snatch", "CrossFit")
        assertTrue("CrossFit" in db)
        assertFalse("Halterofilia" in db)
    }

    @Test fun gymnasticMovementsAlsoAppearInCrossFit() {
        assertEquals(listOf("Gimnasia", "CrossFit"), tags("Toes to bar", "Gimnasia"))
        assertEquals(listOf("Gimnasia", "CrossFit"), tags("Muscle-up barra", "Gimnasia"))
        assertEquals(listOf("CrossFit", "Gimnasia"), tags("Box jump over", "CrossFit"))
        assertEquals(listOf("CrossFit", "Gimnasia"), tags("Burpee", "CrossFit"))
    }

    @Test fun hyroxStationsRetainOriginalDisciplineAndAddOthers() {
        assertEquals(listOf("CrossFit", "HYROX"), tags("Wall ball", "CrossFit", hyrox = true))
        assertEquals(listOf("CrossFit", "HYROX", "Cardio"), tags("SkiErg", "CrossFit", hyrox = true))
        assertEquals(listOf("HYROX", "CrossFit"), tags("Burpee Broad Jump", "HYROX", hyrox = true))
        assertEquals(listOf("HYROX", "CrossFit"), tags("Sandbag Lunges", "HYROX", hyrox = true))
        assertEquals(listOf("CrossFit", "HYROX", "Cardio"), tags("Remo máquina", "CrossFit", hyrox = true))
    }

    @Test fun commonStrengthCrossFitButMachinesStayGymOnly() {
        assertTrue("CrossFit" in tags("Peso muerto", null, "Piernas"))
        assertEquals(listOf("CrossFit", "Gimnasia"), tags("Dominadas", null, "Espalda").let { t ->
            // Dominadas sin sportTag: entra por crossFitGeneral y crossFitGymnastics; orden CrossFit primero.
            assertEquals(listOf("CrossFit", "Gimnasia"), t); t
        })
        assertTrue(tags("Prensa", null, "Piernas").isEmpty())
        assertTrue(tags("Curl femoral", null, "Piernas").isEmpty())
    }

    @Test fun mobilityIsNotAutomaticallyCrossFit() {
        assertEquals(listOf("Movilidad"), tags("Gato-vaca", "Movilidad"))
    }

    @Test fun cardioNamesKeepHyphenAndFoldDiacritics() {
        assertTrue("Cardio" in tags("Double-Under", null))
        assertTrue("Cardio" in tags("Remo máquina", null))
        assertTrue("Cardio" in tags("Cinta / carrera", null))
        assertTrue("Cardio" in tags("Run", null))
        assertFalse("Cardio" in tags("Press banca", null))
    }

    @Test fun noDuplicateTags() {
        val t = tags("Dominadas", "Gimnasia")
        assertEquals(t.size, t.toSet().size)
    }
}
