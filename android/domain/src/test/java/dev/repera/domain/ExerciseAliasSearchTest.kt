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
}
