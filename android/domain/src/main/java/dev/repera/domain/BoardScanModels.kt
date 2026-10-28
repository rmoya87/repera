package dev.repera.domain

import java.util.UUID

/**
 * Modelos de rutina que necesita el escáner de pizarra (port del subconjunto
 * de Models.swift que usa BoardScanLiteParser). Son modelos de dominio del
 * parser; la capa mobile los convierte al formato wire (RoutineBlockDraft).
 */

/** Historical spelling used by the board scanner; same type as [WodFormat]. */
typealias WODFormat = WodFormat

enum class RoutineBlockKind { STRENGTH, WOD }

data class PlannedSet(
    val id: String = UUID.randomUUID().toString(),
    val targetReps: Int,
    val targetDurationSeconds: Int? = null,
    val targetWeightKg: Double? = null,
    val targetRir: Double? = null,
    val targetPercent1RM: Double? = null,
    val targetPercent1RMIsMinimum: Boolean = false
)

data class RoutineExercise(
    val id: String = UUID.randomUUID().toString(),
    val exerciseId: String,
    val plannedSets: List<PlannedSet>,
    val restSeconds: Int? = null
)

data class WODMovement(
    val id: String = UUID.randomUUID().toString(),
    val exerciseId: String? = null,
    val name: String,
    val reps: Int? = null,
    val repScheme: List<Int>? = null,
    val distanceMeters: Int? = null,
    val calories: Int? = null,
    val weightMaleKg: Double? = null,
    val weightFemaleKg: Double? = null,
    val isRest: Boolean = false,
    val restSeconds: Int? = null,
    val scaleAlternative: String? = null,
    val notes: String? = null,
    val explicitPlannedSets: List<PlannedSet>? = null
) {
    val isAscendingRepRange: Boolean
        get() = CrossFitGlossary.isAscendingRepRange(repScheme)

    /** Series planificadas: esquema 4-3-3-2 o una serie con reps / cal / metros. */
    val plannedSetsFromReps: List<PlannedSet>
        get() {
            val weight = weightMaleKg
            val scheme = repScheme
            if (!scheme.isNullOrEmpty() && !isAscendingRepRange) {
                return scheme.map { PlannedSet(targetReps = maxOf(1, it), targetWeightKg = weight) }
            }
            val r: Int = if (scheme != null && isAscendingRepRange) {
                scheme[1] // techo del rango (5-10 → 10)
            } else {
                calories ?: distanceMeters ?: reps ?: 10
            }
            return listOf(PlannedSet(targetReps = maxOf(1, r), targetWeightKg = weight))
        }

    /** Expande un set base a `count` series idénticas (EMOM/RFT/Tabata…). */
    fun repeatingPlannedSets(count: Int): List<PlannedSet> {
        val base = plannedSetsFromReps
        if (count <= 1 || base.size != 1) return base
        val template = base.first()
        return (0 until count).map {
            PlannedSet(
                targetReps = template.targetReps,
                targetWeightKg = template.targetWeightKg,
                targetRir = template.targetRir
            )
        }
    }

    /** Si la ola tiene menos series que `count`, completa repitiendo el último. */
    fun plannedSetsPadded(count: Int): List<PlannedSet> {
        val base = plannedSetsFromReps
        if (count <= 0) return emptyList()
        if (base.isEmpty()) {
            return (0 until count).map {
                PlannedSet(targetReps = reps ?: 10, targetWeightKg = weightMaleKg)
            }
        }
        if (base.size >= count) return base.subList(0, count)
        val last = base.last()
        val pad = (0 until (count - base.size)).map {
            PlannedSet(
                targetReps = last.targetReps,
                targetWeightKg = last.targetWeightKg,
                targetRir = last.targetRir
            )
        }
        return base + pad
    }

    private fun fmt(v: Double): String =
        if (v % 1.0 == 0.0) v.toInt().toString() else v.toString()

    val summaryLine: String
        get() {
            if (isRest) {
                val sec = restSeconds ?: 60
                return if (sec >= 60) "${sec / 60}' REST" else "$sec\" REST"
            }
            val parts = mutableListOf<String>()
            val scheme = repScheme
            if (scheme != null && scheme.size >= 2) {
                parts.add(scheme.joinToString("-"))
            } else if (reps != null) {
                parts.add("$reps")
            }
            distanceMeters?.let { parts.add("${it}m") }
            calories?.let { parts.add("$it cal") }
            parts.add(name.uppercase())
            weightMaleKg?.let { male ->
                // Apple 4c9a5d10 (WODMovement.summaryLine): par H/M o carga
                // unica, siempre con sufijo kg.
                weightFemaleKg?.let { female ->
                    parts.add("${fmt(male)}/${fmt(female)} kg")
                } ?: parts.add("${fmt(male)} kg")
            }
            var line = parts.joinToString(" ")
            if (!scaleAlternative.isNullOrEmpty()) line += " / $scaleAlternative"
            return line
        }
}

data class RoutineBlock(
    val id: String = UUID.randomUUID().toString(),
    var title: String,
    val kind: RoutineBlockKind,
    var exercises: List<RoutineExercise> = emptyList(),
    var movements: List<WODMovement> = emptyList(),
    var wodFormat: WODFormat? = null,
    var timeCapMinutes: Int? = null,
    var emomIntervalSeconds: Int? = 60,
    var rounds: Int? = null,
    var workSeconds: Int? = null,
    var restSeconds: Int? = null,
    var restBetweenRoundsSeconds: Int? = null,
    var wodNotes: String? = null
) {
    companion object {
        fun strength(title: String = "Bloque 1", exercises: List<RoutineExercise> = emptyList()) =
            RoutineBlock(title = title, kind = RoutineBlockKind.STRENGTH, exercises = exercises)

        fun wod(format: WODFormat, title: String? = null): RoutineBlock {
            val isTabata = format == WODFormat.TABATA
            return RoutineBlock(
                title = title ?: format.raw,
                kind = RoutineBlockKind.WOD,
                wodFormat = format,
                timeCapMinutes = if (format == WODFormat.AMRAP || format == WODFormat.FOR_TIME) 12
                    else if (isTabata) 4 else 10,
                emomIntervalSeconds = 60,
                rounds = if (isTabata) 8 else null,
                workSeconds = if (isTabata) 20 else null,
                restSeconds = if (isTabata) 10 else null
            )
        }
    }

    val stationCount: Int get() = maxOf(1, movements.size)

    /** Intervalos de reloj EMOM (minutos del cap ÷ intervalo), no `rounds` (vueltas). */
    val emomTimerIntervals: Int?
        get() {
            if (wodFormat != WODFormat.EMOM && wodFormat != WODFormat.CIRCUIT) return null
            val interval = maxOf(1, emomIntervalSeconds ?: 60)
            val cap = timeCapMinutes
            if (cap != null && cap > 0) return maxOf(1, (cap * 60) / interval)
            return rounds
        }

    /** Deriva `rounds` en EMOM/circuito multi-estación cuando la cabecera no los fijó. */
    fun deriveEmomRoundsIfNeeded() {
        if (wodFormat != WODFormat.EMOM && wodFormat != WODFormat.CIRCUIT) return
        if (rounds != null) return
        val total = emomTimerIntervals ?: return
        if (total <= 0) return
        rounds = maxOf(1, total / stationCount)
    }

    /** Series al apuntar / sesión para un movimiento WOD según formato del bloque. */
    fun plannedSets(forMovement: WODMovement): List<PlannedSet> {
        if (forMovement.isRest) return emptyList()
        val explicit = forMovement.explicitPlannedSets
        if (!explicit.isNullOrEmpty()) return explicit
        val base = forMovement.plannedSetsFromReps
        val emomRounds = maxOf(1, rounds ?: 1)

        val scheme = forMovement.repScheme
        if (!scheme.isNullOrEmpty() && !forMovement.isAscendingRepRange) {
            if (wodFormat == WODFormat.EMOM || wodFormat == WODFormat.CIRCUIT) {
                return forMovement.plannedSetsPadded(emomRounds)
            }
            return base
        }
        val format = wodFormat ?: return base
        return when (format) {
            WODFormat.EMOM, WODFormat.CIRCUIT -> forMovement.repeatingPlannedSets(emomRounds)
            WODFormat.TABATA -> {
                val workIntervals = maxOf(1, rounds ?: 8)
                val activeStations = movements.filter { !it.isRest }
                val stationTotal = maxOf(1, activeStations.size)
                val station = activeStations.indexOfFirst { it.id == forMovement.id }
                    .takeIf { it >= 0 } ?: 0
                val count = maxOf(0, (workIntervals + stationTotal - 1 - station) / stationTotal)
                if (count > 0) forMovement.repeatingPlannedSets(count) else emptyList()
            }
            WODFormat.FOR_TIME, WODFormat.ROUNDS_FOR_QUALITY -> {
                val n = rounds
                if (n == null || n <= 1) base else forMovement.repeatingPlannedSets(n)
            }
            else -> base
        }
    }
}

/** Ejercicio de catálogo para matching del escáner (desde catalog_seed.json). */
data class CatalogExercise(
    val id: String,
    val name: String,
    /** Apple (live main) Exercise.searchAliases: alias publicados para matching. */
    val searchAliases: List<String> = emptyList(),
    val isCustom: Boolean = false,
    val isCatalogArchived: Boolean = false
)

/** Línea detectada en una pizarra / TV (OCR). Port de BoardImportLine. */
data class BoardImportLine(
    val id: String = UUID.randomUUID().toString(),
    val raw: String,
    val matchedExerciseId: String? = null,
    val matchedName: String? = null,
    val sets: Int = 3,
    val reps: Int = 8,
    val weightKg: Double? = null,
    val isIncluded: Boolean = true
)
