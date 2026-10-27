package dev.repera.domain

import java.text.Normalizer
import java.util.Locale

/**
 * Apple (live main, bd4d7637) Exercise.disciplineTags + ExerciseDisciplineRules
 * (Packages/ReperaDomain/Sources/ReperaDomain/Models.swift).
 * Una misma variante pertenece a varias disciplinas sin duplicar su id ni su
 * historial; sportTag sigue siendo el origen persistido.
 */
object ExerciseDisciplineTags {

    /** Apple ExerciseDisciplineRules.normalized: trim + fold diacríticos/caso,
     *  minúsculas. Conserva puntuación (p.ej. "double-under" mantiene el guion),
     *  a diferencia de ExerciseAliasSearch.normalize. */
    internal fun normalized(name: String): String {
        val stripped = Normalizer.normalize(name.trim(), Normalizer.Form.NFD)
            .replace(Regex("\\p{Mn}+"), "")
        return stripped.lowercase(Locale("es", "ES"))
    }

    private val crossFitGeneral = setOf(
        // Básicos de fuerza y acondicionamiento habituales en un box.
        "press banca", "press banca inclinada", "press militar", "remo con barra",
        "peso muerto", "peso muerto rumano", "peso muerto sumo",
        "sentadilla", "sentadilla frontal", "zancadas", "plancha",
        "fondos", "dominadas", "remo invertido", "ab wheel",
        "farmer walk", "remo maquina", "bici estatica",
        "paso lateral con banda"
    )

    private val crossFitGymnastics = setOf(
        // Peso corporal usado como movimiento gimnástico en un WOD.
        "burpee", "burpee box jump over", "burpee box jump",
        "burpee al cajon", "burpee pull-up", "bar facing burpee",
        "box jump", "salto al cajon", "box jump over",
        "box step-up", "step-up al cajon", "broad jump", "bear crawl",
        "walking lunge", "fondos", "dominadas", "remo invertido",
        "plancha", "ab wheel"
    )

    private val hyroxAlsoCrossFit = setOf(
        "burpee broad jump", "sandbag lunges"
    )

    private val cardioNames = setOf(
        "run", "carrera", "cinta / carrera", "running", "shuttle run",
        "ski erg", "skierg", "rowerg", "remo maquina", "remoergometro",
        "air bike", "echo bike", "bici estatica",
        "double-under", "single-under", "triple-under",
        "dobles de comba", "simples de comba", "triples de comba"
    )

    /** Apple Exercise.disciplineTags (Models.swift). isHyroxMovement equivale a
     *  HyroxExercises.isMovement(named:) resuelto por el llamador. */
    fun forExercise(name: String, sportTag: String?, muscleGroup: String, isHyroxMovement: Boolean): List<String> {
        val tags = mutableListOf<String>()
        fun include(tag: String) { if (tag !in tags) tags += tag }
        if (!sportTag.isNullOrEmpty()) include(sportTag)
        val n = normalized(name)
        if (sportTag == "Halterofilia" || sportTag == "Gimnasia"
            || n in crossFitGeneral
            || (sportTag == "HYROX" && n in hyroxAlsoCrossFit)) {
            include("CrossFit")
        }
        if (sportTag == "Gimnasia" || n in crossFitGymnastics) include("Gimnasia")
        if (isHyroxMovement) include("HYROX")
        if (muscleGroup == "Cardio" || n in cardioNames) include("Cardio")
        return tags
    }
}
