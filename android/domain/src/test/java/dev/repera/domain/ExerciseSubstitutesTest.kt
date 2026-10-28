package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ExerciseSubstitutesTest {

    private fun ex(id: String, name: String, target: String? = null,
                   group: String = "Pecho", equipment: String? = null,
                   bodyPart: String? = null) =
        ExerciseSubstitutes.Candidate(id, name, target, group, equipment, bodyPart)

    @Test
    fun `mismo target puntua sobre solo grupo`() {
        val base = ex("a", "Press banca", target = "chest", group = "Pecho")
        val catalog = listOf(
            base,
            ex("b", "Press mancuernas", target = "chest", group = "Pecho"),   // 3+2=5
            ex("c", "Aperturas", group = "Pecho"),                            // 2
            ex("d", "Fondos", target = "triceps", group = "Brazo")            // 0 → fuera
        )
        val out = ExerciseSubstitutes.substitutes(base, catalog)
        assertEquals(listOf("b", "c"), out.map { it.id })
    }

    @Test
    fun `equipo y bodyPart desempatan por encima del nombre`() {
        val base = ex("a", "Zanco", target = "quads", group = "Pierna",
            equipment = "mancuerna", bodyPart = "lower")
        val catalog = listOf(
            base,
            ex("b", "Zancada búlgara", target = "quads", group = "Pierna"),            // 5
            ex("c", "Zancada lateral", target = "quads", group = "Pierna",
                equipment = "mancuerna", bodyPart = "lower"),                          // 7
            ex("d", "Sentadilla", target = "quads", group = "Pierna",
                equipment = "mancuerna")                                               // 6
        )
        val out = ExerciseSubstitutes.substitutes(base, catalog)
        assertEquals(listOf("c", "d", "b"), out.map { it.id })
    }

    @Test
    fun `empate total ordena por nombre insensible a mayusculas`() {
        val base = ex("a", "Base", group = "Pecho")
        val catalog = listOf(
            base,
            ex("b", "zumba", group = "Pecho"),
            ex("c", "Apertura", group = "Pecho")
        )
        val out = ExerciseSubstitutes.substitutes(base, catalog)
        assertEquals(listOf("c", "b"), out.map { it.id })
    }

    @Test
    fun `excluye el propio ejercicio y respeta el limite`() {
        val base = ex("a", "Base", group = "Pecho")
        val catalog = listOf(base) + (1..20).map { ex("x$it", "Ej $it", group = "Pecho") }
        val out = ExerciseSubstitutes.substitutes(base, catalog)
        assertTrue(out.none { it.id == "a" })
        assertEquals(12, out.size)
    }

    @Test
    fun `score minimo 2 excluye coincidencias solo de equipo`() {
        val base = ex("a", "Base", group = "Pecho", equipment = "barra")
        val catalog = listOf(base, ex("b", "Otro", group = "Espalda", equipment = "barra"))
        assertTrue(ExerciseSubstitutes.substitutes(base, catalog).isEmpty())
    }
}
