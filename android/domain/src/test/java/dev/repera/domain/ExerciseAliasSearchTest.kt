package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class ExerciseAliasSearchTest {
    private val aliases = mapOf(
        "back squat" to "sentadilla",
        "chin ups" to "dominadas supinas",
        "rdl" to "peso muerto rumano",
        "lunges" to "zancadas",
        "bench press" to "press banca"
    )

    @Test fun englishAliasFindsSpecificSpanishMovement() {
        assertEquals(95, ExerciseAliasSearch.score("chin ups", "Dominadas supinas", aliases))
        assertEquals(-1, ExerciseAliasSearch.score("chin ups", "Dominadas estrictas", aliases))
        assertEquals(95, ExerciseAliasSearch.score("rdl", "Peso muerto rumano", aliases))
        assertEquals(95, ExerciseAliasSearch.score("lunges", "Zancadas", aliases))
    }

    @Test fun exactNameAndAccentsRankCorrectly() {
        assertEquals(100, ExerciseAliasSearch.score("bíceps", "Bíceps", aliases))
        assertEquals(100, ExerciseAliasSearch.score("SENTADILLA", "Sentadilla", aliases))
        assertEquals(95, ExerciseAliasSearch.score("back squat", "Sentadilla", aliases))
    }

    @Test
    fun `discipline extra terms match below name and alias scores`() {
        // Apple 9f89e59f: searching "hyrox" finds HYROX-discipline exercises via meta.
        val discipline = ExerciseAliasSearch.score("hyrox", "Wall ball", emptyMap(), "hyrox")
        assertEquals(40, discipline)
        val nameMatch = ExerciseAliasSearch.score("hyrox", "Hyrox simulacro", emptyMap(), "hyrox")
        assertTrue("name match must outrank discipline match", nameMatch > discipline)
        val noTerms = ExerciseAliasSearch.score("hyrox", "Press banca", emptyMap())
        assertEquals(-1, noTerms)
        val wrongDiscipline = ExerciseAliasSearch.score("hyrox", "Press banca", emptyMap(), "crossfit")
        assertEquals(-1, wrongDiscipline)
        val defaultUnchanged = ExerciseAliasSearch.score("hyrox", "Wall ball", emptyMap())
        assertEquals(-1, defaultUnchanged)
    }

    @Test
    fun `discipline extra terms normalized and multi token`() {
        assertEquals(40, ExerciseAliasSearch.score("HYROX", "Remo máquina", emptyMap(), "hyrox"))
        assertEquals(40, ExerciseAliasSearch.score("hyrox 2024", "Wall ball", emptyMap(), "hyrox 2024"))
    }
}
