package dev.repera.domain

import java.text.Normalizer

/** Port literal de Exercise.allowsCalorieOrDistanceToggle / defaultQuantityUnit (ReperaDomain Models.swift)
 *  para cardio: isBikeOrSki, isErgRow, isRunLike, isSled, isMachineCardio, isHyroxDistance. */
object AppleCardioUnits {
    private fun tok(raw: String): String = Normalizer.normalize(raw, Normalizer.Form.NFD)
        .replace(Regex("\\p{Mn}+"), "").lowercase(java.util.Locale.ROOT)

    private fun bikeOrSki(n: String) = listOf("air bike", "echo bike", "assault", "fan bike", "wattbike",
        "skierg", "ski erg", "ski-erg").any { n.contains(it) }

    private fun ergRow(n: String): Boolean {
        if (n.contains("rower") || n.contains("concept2") || n.contains("remoerg")) return true
        if (n.contains("remo")) {
            val strength = listOf("mancuern", "barra", "sentado", "menton", "invert", "anilla", "polea",
                "landmine", "seal", "pendlay", "t-bar", "t bar").any { n.contains(it) }
            if (strength) return false
            return n == "remo" || n.contains("maquina") || n.contains("erg") || n.startsWith("remo ")
        }
        return false
    }

    private fun runLike(n: String) = n.contains("cinta") || n.contains("carrera") || n.contains("shuttle") ||
        n.contains("run ") || n.endsWith(" run") || n == "run" || n.contains("running")

    private fun sled(n: String, eq: String) = eq.contains("trineo") && (n.contains("sled") || n.contains("trineo"))

    private fun hyroxDistance(n: String) = n.contains("burpee broad jump") || n.contains("sandbag lunge") ||
        n.contains("zancadas con saco") || n == "farmer carry" || n == "farmer walk" || n.contains("paseo del granjero")

    private fun machineCardio(n: String, eq: String) = bikeOrSki(n) || ergRow(n) || runLike(n) || sled(n, eq)

    fun allowsCalorieOrDistanceToggle(name: String, equipment: String?): Boolean {
        val n = tok(name); val eq = tok(equipment ?: "")
        return machineCardio(n, eq) && !runLike(n)
    }

    /** "reps" | "calories" | "meters" */
    fun defaultQuantityUnit(name: String, equipment: String?): String {
        val n = tok(name); val eq = tok(equipment ?: "")
        if (!(machineCardio(n, eq) || hyroxDistance(n))) return "reps"
        if (runLike(n) || hyroxDistance(n) || sled(n, eq)) return "meters"
        if (ergRow(n)) return "meters"
        return "calories"
    }
}
