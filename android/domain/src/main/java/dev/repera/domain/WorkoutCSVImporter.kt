package dev.repera.domain

import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.UUID

/**
 * Importador de históricos CSV de Strong/Hevy.
 * Port 1:1 de WorkoutCSVImporter.swift (iOS): misma detección de formato,
 * columnas, alias de ejercicios, reglas de descarte y agrupación por sesión.
 */
object WorkoutCSVImporter {

    enum class Source { STRONG, HEVY, UNKNOWN }

    data class ImportedSet(
        val reps: Int,
        val weightKg: Double?,
        val epochSeconds: Long
    )

    data class ImportedExercise(
        val id: String,
        val name: String,
        val muscleGroup: String,
        val isNew: Boolean
    )

    data class ImportedExerciseSets(
        val exercise: ImportedExercise,
        val sets: List<ImportedSet>
    )

    data class ImportedWorkout(
        val title: String,
        val epochSeconds: Long,
        val exercises: List<ImportedExerciseSets>
    )

    data class Result(
        val source: Source,
        val workouts: List<ImportedWorkout>,
        val createdExercises: List<ImportedExercise>,
        val matchedSets: Int,
        val skippedRows: Int
    )

    fun detectSource(headerLine: String): Source {
        val h = headerLine.lowercase().replace("_", " ")
        if (h.contains("exercise title") && h.contains("set index"))
            return Source.HEVY
        if (h.contains("exercise name") && h.contains("set order"))
            return Source.STRONG
        return Source.UNKNOWN
    }

    /** [existingExercises] = pares (id, nombre) del catálogo actual. */
    fun parse(
        csv: String,
        existingExercises: List<Pair<String, String>>,
        zone: ZoneId = ZoneId.systemDefault(),
        idGenerator: () -> String = { UUID.randomUUID().toString() }
    ): Result {
        val rows = parseRows(csv)
        val header = rows.firstOrNull()
            ?: return Result(Source.UNKNOWN, emptyList(), emptyList(), 0, 0)
        val source = detectSource(header.joinToString(","))
        val map = columnMap(header, source)

        val exercises = existingExercises.toMutableList()
        val created = mutableListOf<ImportedExercise>()
        data class Bucket(val title: String, val epochSeconds: Long,
                          val items: LinkedHashMap<String, ImportedExerciseSets>)
        val buckets = LinkedHashMap<String, Bucket>()
        var matched = 0
        var skipped = 0

        for (row in rows.drop(1)) {
            if (row.size < header.size / 2) { skipped += 1; continue }
            fun col(key: String): String {
                val idx = map[key] ?: return ""
                return if (idx < row.size) row[idx].trim() else ""
            }
            val name = col("exercise")
            if (name.isEmpty()) { skipped += 1; continue }
            val reps = col("reps").replace(",", ".").toDoubleOrNull()?.toInt() ?: 0
            val weightRaw = col("weight").replace(",", ".").toDoubleOrNull()
            val seconds = col("seconds").replace(",", ".")
                .toDoubleOrNull()?.toInt() ?: 0
            if (reps <= 0 && seconds <= 0) { skipped += 1; continue }

            val instant = parseDate(col("date"), zone) ?: Instant.now()
            val title = col("workout").ifEmpty { "Importado" }
            val sessionKey = "$title|${instant.epochSecond}"

            val exercise = matchOrCreate(name, exercises, created, idGenerator)
            val weight = weightRaw?.takeIf { it > 0 }
            val logged = ImportedSet(
                reps = if (reps > 0) reps else maxOf(seconds, 1),
                weightKg = weight,
                epochSeconds = instant.epochSecond)

            val bucket = buckets.getOrPut(sessionKey) {
                Bucket(title, instant.epochSecond, LinkedHashMap())
            }
            val current = bucket.items[exercise.id]
            val sets = (current?.sets ?: emptyList()) + logged
            bucket.items[exercise.id] = ImportedExerciseSets(exercise, sets)
            matched += 1
        }

        val workouts = buckets.values.map { bucket ->
            ImportedWorkout(bucket.title, bucket.epochSeconds,
                bucket.items.values.toList())
        }.sortedByDescending { it.epochSeconds }

        return Result(source, workouts, created, matched, skipped)
    }

    // MARK: - Matching (mismos alias y heurísticas que iOS)

    private val aliases = mapOf(
        "bench press" to "Press banca",
        "bench press (barbell)" to "Press banca",
        "incline bench press" to "Press banca inclinada",
        "dumbbell bench press" to "Press mancuernas",
        "bent over row" to "Remo con barra",
        "bent over row (barbell)" to "Remo con barra",
        "pull up" to "Dominadas",
        "pull-up" to "Dominadas",
        "lat pulldown" to "Jalón al pecho",
        "squat" to "Sentadilla",
        "squat (barbell)" to "Sentadilla",
        "deadlift" to "Peso muerto",
        "romanian deadlift" to "Peso muerto rumano",
        "overhead press" to "Press militar",
        "military press" to "Press militar",
        "lateral raise" to "Elevaciones laterales",
        "lateral raise (dumbbell)" to "Elevaciones laterales",
        "barbell curl" to "Curl barra",
        "dumbbell curl" to "Curl mancuernas",
        "triceps pushdown" to "Extensión tríceps polea",
        "leg press" to "Prensa",
        "plank" to "Plancha",
        "hip thrust" to "Hip thrust",
        "face pull" to "Face pull",
        "running" to "Cinta / carrera",
        "running (treadmill)" to "Cinta / carrera"
    )

    private fun matchOrCreate(
        name: String,
        exercises: MutableList<Pair<String, String>>,
        created: MutableList<ImportedExercise>,
        idGenerator: () -> String
    ): ImportedExercise {
        val normalized = normalize(name)
        aliases[normalized]?.let { alias ->
            exercises.firstOrNull { it.second.equals(alias, true) }?.let {
                return ImportedExercise(it.first, it.second, "", false)
            }
        }
        exercises.firstOrNull { normalize(it.second) == normalized }?.let {
            return ImportedExercise(it.first, it.second, "", false)
        }
        exercises.firstOrNull {
            normalized.contains(normalize(it.second)) ||
                normalize(it.second).contains(normalized)
        }?.let {
            return ImportedExercise(it.first, it.second, "", false)
        }
        val exercise = ImportedExercise(idGenerator(), name,
            guessMuscle(normalized), true)
        exercises.add(exercise.id to exercise.name)
        created.add(exercise)
        return exercise
    }

    private fun normalize(name: String): String =
        name.lowercase()
            .replace(Regex("\\([^)]*\\)"), "")
            .trim()
            .replace("  ", " ")

    private fun guessMuscle(normalized: String): String = when {
        normalized.contains("bench") || normalized.contains("chest") ||
            normalized.contains("fly") -> "Pecho"
        normalized.contains("row") || normalized.contains("pull") ||
            normalized.contains("lat") ||
            normalized.contains("deadlift") -> "Espalda"
        normalized.contains("squat") || normalized.contains("leg press") ||
            normalized.contains("lunge") -> "Piernas"
        normalized.contains("curl") -> "Bíceps"
        normalized.contains("tricep") || normalized.contains("pushdown") ||
            normalized.contains("extension") -> "Tríceps"
        normalized.contains("press") || normalized.contains("raise") ||
            normalized.contains("shoulder") -> "Hombros"
        normalized.contains("plank") || normalized.contains("crunch") ||
            normalized.contains("core") -> "Core"
        normalized.contains("run") || normalized.contains("bike") ||
            normalized.contains("cardio") -> "Cardio"
        else -> "Full body"
    }

    // MARK: - CSV helpers (mismo mapa de columnas y parser que iOS)

    private fun columnMap(header: List<String>, source: Source): Map<String, Int> {
        val map = mutableMapOf<String, Int>()
        header.forEachIndexed { idx, raw ->
            val h = raw.lowercase().trim()
            when (source) {
                Source.STRONG -> {
                    if (h == "date") map["date"] = idx
                    if (h == "workout name") map["workout"] = idx
                    if (h == "exercise name") map["exercise"] = idx
                    if (h == "weight") map["weight"] = idx
                    if (h == "reps") map["reps"] = idx
                    if (h == "seconds") map["seconds"] = idx
                }
                Source.HEVY -> {
                    if (h == "start_time" || h == "start time") map["date"] = idx
                    if (h == "title") map["workout"] = idx
                    if (h == "exercise_title" || h == "exercise title")
                        map["exercise"] = idx
                    if (h == "weight_kg" || h == "weight kg") map["weight"] = idx
                    if (h == "reps") map["reps"] = idx
                    if (h == "duration_seconds" || h == "duration seconds")
                        map["seconds"] = idx
                }
                Source.UNKNOWN -> {
                    if (h.contains("date") || h.contains("start"))
                        map["date"] = idx
                    if (h.contains("workout") || h == "title")
                        map["workout"] = idx
                    if (h.contains("exercise")) map["exercise"] = idx
                    if (h.contains("weight")) map["weight"] = idx
                    if (h == "reps") map["reps"] = idx
                    if (h.contains("second") || h.contains("duration"))
                        map["seconds"] = idx
                }
            }
        }
        return map
    }

    internal fun parseRows(csv: String): List<List<String>> {
        val rows = mutableListOf<List<String>>()
        var current = mutableListOf<String>()
        val field = StringBuilder()
        var inQuotes = false
        fun pushField() {
            current.add(field.toString())
            field.clear()
        }
        fun pushRow() {
            if (current.isNotEmpty()) rows.add(current)
            current = mutableListOf()
        }
        var i = 0
        while (i < csv.length) {
            val c = csv[i]
            if (inQuotes) {
                if (c == '"') {
                    if (i + 1 < csv.length && csv[i + 1] == '"') {
                        field.append('"'); i += 1
                    } else inQuotes = false
                } else field.append(c)
            } else when (c) {
                '"' -> inQuotes = true
                ',', ';' -> pushField()
                '\n' -> { pushField(); pushRow() }
                '\r' -> Unit
                else -> field.append(c)
            }
            i += 1
        }
        pushField(); pushRow()
        return rows.filter { row -> row.any { it.isNotEmpty() } }
    }

    internal fun parseDate(raw: String, zone: ZoneId): Instant? {
        val trimmed = raw.trim()
        if (trimmed.isEmpty()) return null
        runCatching { return Instant.parse(trimmed) }
        runCatching {
            return java.time.OffsetDateTime.parse(trimmed).toInstant()
        }
        val dateTimeFormats = listOf(
            "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm",
            "dd/MM/yyyy HH:mm", "MM/dd/yyyy HH:mm")
        for (format in dateTimeFormats) {
            runCatching {
                return LocalDateTime.parse(trimmed,
                    DateTimeFormatter.ofPattern(format))
                    .atZone(zone).toInstant()
            }
        }
        runCatching {
            return LocalDate.parse(trimmed).atStartOfDay(zone).toInstant()
        }
        return null
    }
}
