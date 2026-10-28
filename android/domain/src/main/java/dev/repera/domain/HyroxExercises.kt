package dev.repera.domain

import java.text.Normalizer
import java.util.Locale

/** Apple (live main, bd4d7637) HyroxExercises (Packages/.../Catalog.swift). */
object HyroxExercises {
    val competitionStations: List<String> = listOf(
        "Run", "SkiErg", "Sled push", "Sled pull", "Burpee Broad Jump",
        "Remo máquina", "Farmer carry", "Sandbag Lunges", "Wall ball",
    )

    // Nombre del seed CrossFit y equivalencias históricas en español.
    private val matchingNames: Set<String> = listOf(
        "Run", "Carrera", "Cinta / carrera", "Running",
        "SkiErg", "Esquí ergómetro",
        "Sled push", "Empuje de trineo",
        "Sled pull", "Arrastre de trineo",
        "Burpee Broad Jump", "Burpee Broad Jumps", "Burpee con salto de longitud", "Burpees con salto de longitud",
        "Remo máquina", "Remoergómetro", "RowErg", "Rowing",
        "Farmer carry", "Farmer walk", "Farmers carry", "Paseo del granjero",
        "Sandbag Lunges", "Sandbag Lunge", "Zancadas con saco",
        "Wall ball", "Wall balls", "Lanzamiento de balón a pared",
    ).map { foldName(it) }.toSet()

    /** Apple: fold diacríticos/caso + minúsculas; conserva puntuación ("Cinta / carrera"). */
    private fun foldName(name: String): String =
        Normalizer.normalize(name, Normalizer.Form.NFD)
            .replace(Regex("\\p{Mn}+"), "")
            .lowercase(Locale("es", "ES"))

    fun isMovement(name: String): Boolean = foldName(name) in matchingNames
}
