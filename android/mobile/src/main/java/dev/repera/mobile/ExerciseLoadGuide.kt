package dev.repera.mobile

import dev.repera.domain.LoadSuggestion
import org.json.JSONArray
import org.json.JSONObject

/**
 * Guía de carga del editor/registro de series (port 1:1 de
 * ExerciseLoadGuideCard.swift iOS): última sesión de trabajo del ejercicio
 * + kg sugeridos para el RIR objetivo. Solo lectura del snapshot.
 */
data class LoadGuideSet(
    val weightKg: Double?,
    val reps: Int,
    val rir: Double?,
    val durationSeconds: Int?,
    val unit: String?,
    val deficitCm: Int? = null
)

data class LoadGuideLastSession(
    val sessionId: String,
    val dateEpochMillis: Long,
    val sets: List<LoadGuideSet>
) {
    /** Serie top = la de mayor peso (iOS topSet). */
    val topSet: LoadGuideSet? get() = sets.maxByOrNull { it.weightKg ?: 0.0 }
}

data class LoadGuide(
    val lastSession: LoadGuideLastSession?,
    val suggestedKg: Double?,
    /** "1RM" (testeado), "e1RM" (estimado del historial) o "última". */
    val suggestionSource: String?,
    val assumedRir: Boolean,
    val targetReps: Int,
    val effectiveRir: Double,
    /** Paso de redondeo (settings.weightIncrementKg; defecto 2.5). */
    val incrementKg: Double = 2.5
)

object ExerciseLoadGuide {

    private const val DEFAULT_INCREMENT_KG = 2.5
    private const val DEFAULT_RIR = 2.0

    /** Última sesión con series de trabajo (más reciente primero).
     *  Port de StatsEngine.lastWorkingSession (iOS). */
    fun lastWorkingSession(
        exerciseId: String,
        workouts: List<JSONObject>,
        catalog: JSONArray? = null
    ): LoadGuideLastSession? {
        val anchorName: String? = catalog?.let { array ->
            (0 until array.length()).map { array.getJSONObject(it) }
                .firstOrNull { it.optString("id") == exerciseId }
                ?.optString("name")
        }
        val sorted = workouts.sortedByDescending { ExerciseSessionAppearances.epochOf(it) }
        for (session in sorted) {
            val finished = session.optString("phase") == "finished" ||
                session.optString("finishedAt").isNotBlank()
            if (!finished) continue
            val entry = ExerciseSessionAppearances.matchEntry(session, exerciseId, anchorName)
                ?: continue
            val work = WorkoutHistorySets.effectiveWorkSets(session, entry)
            if (work.isEmpty()) continue
            return LoadGuideLastSession(
                sessionId = session.optString("id"),
                dateEpochMillis = ExerciseSessionAppearances.epochOf(session),
                sets = work.map { s ->
                    LoadGuideSet(
                        weightKg = s.weightKg,
                        reps = s.reps,
                        rir = s.rir,
                        durationSeconds = s.durationSeconds,
                        unit = s.unit,
                        deficitCm = s.deficitCm
                    )
                }
            )
        }
        return null
    }

    /** Mejor e1RM del historial (Epley, mismas reglas que
     *  StatsEngine.estimatedOneRM: solo reps con peso > 0). */
    fun estimatedOneRM(
        exerciseId: String,
        workouts: List<JSONObject>,
        catalog: JSONArray? = null
    ): Double? {
        val anchorName: String? = catalog?.let { array ->
            (0 until array.length()).map { array.getJSONObject(it) }
                .firstOrNull { it.optString("id") == exerciseId }
                ?.optString("name")
        }
        var best = 0.0
        for (session in workouts) {
            val entry = ExerciseSessionAppearances.matchEntry(session, exerciseId, anchorName)
                ?: continue
            for (set in WorkoutHistorySets.effectiveWorkSets(session, entry)) {
                val w = set.weightKg ?: continue
                if (w <= 0 || set.unit != "reps" || set.reps <= 0) continue
                val e1 = w * (1 + set.reps / 30.0)
                if (e1 > best) best = e1
            }
        }
        return if (best > 0) best else null
    }

    /** Rellena `weightMaleKg` en movimientos que solo traen % y tienen 1RM
     *  conocido (tested o e1RM). Port de LoadSuggestion.applyPercentLoads
     *  (Apple 04da40ef: DayPlusSheet review.seed): la nota conserva la fuente
     *  y no se duplica si ya hay una nota de % previa. */
    fun applyPercentLoads(
        blocks: List<dev.repera.domain.RoutineBlock>,
        root: JSONObject
    ): List<dev.repera.domain.RoutineBlock> {
        val workouts = root.optJSONArray("workouts")?.let { array ->
            (0 until array.length()).map { array.getJSONObject(it) }
        } ?: emptyList()
        val catalog = root.optJSONArray("exercises")
        val increment = root.optJSONObject("settings")
            ?.takeIf { it.has("weightIncrementKg") && !it.isNull("weightIncrementKg") }
            ?.getDouble("weightIncrementKg")?.takeIf { it > 0 }
            ?: DEFAULT_INCREMENT_KG
        val prefs = root.optJSONObject("exerciseLoadPrefs")
        fun testedFor(id: String): Double? = prefs?.optJSONObject(id)
            ?.takeIf { it.has("testedOneRMKg") && !it.isNull("testedOneRMKg") }
            ?.getDouble("testedOneRMKg")?.takeIf { it > 0 }
        return blocks.map { block ->
            block.copy(movements = block.movements.map { move ->
                if (move.isRest) return@map move
                if (move.weightMaleKg != null) return@map move
                val pct = dev.repera.domain.LoadSuggestion.percentOfOneRM(move.notes)?.value
                    ?: dev.repera.domain.LoadSuggestion.percentOfOneRM(move.name)?.value
                    ?: return@map move
                val exerciseId = move.exerciseId ?: catalog?.let { array ->
                    (0 until array.length()).map { array.getJSONObject(it) }
                        .firstOrNull {
                            dev.repera.domain.CrossFitGlossary.normalize(it.optString("name")) ==
                                dev.repera.domain.CrossFitGlossary.normalize(move.name)
                        }?.optString("id")
                } ?: return@map move
                val tested = testedFor(exerciseId)
                val oneRM = tested ?: estimatedOneRM(exerciseId, workouts, catalog)
                if (oneRM == null || oneRM <= 0) return@map move
                val sourceLabel = if (tested != null) "1RM" else "e1RM"
                val kg = dev.repera.domain.LoadSuggestion.weightKg(oneRM, pct, roundTo = increment)
                val note = "~${pct.toInt()}% $sourceLabel → " +
                    "${dev.repera.domain.ReperaNumberFormat.decimal(kg)} kg"
                val existing = move.notes
                val notes = if (!existing.isNullOrEmpty()) {
                    if (!existing.contains("% e1RM") && !existing.contains("% 1RM")) {
                        "$existing · $note"
                    } else existing
                } else note
                move.copy(weightMaleKg = kg, notes = notes)
            })
        }
    }

    /** «Aplicar» del editor: escala la última sesión al kg sugerido (misma
     *  progresión, reps y RIR; port de PlanView.applySuggestedLoad iOS).
     *  Sin sesión previa devuelve null: el editor solo fija el kg en las
     *  series actuales (mismo efecto que el bucle final de iOS). */
    fun scaledPlannedSets(
        kg: Double,
        lastSets: List<LoadGuideSet>,
        step: Double,
        fallbackRir: Double
    ): List<PlannedSetDraft>? {
        if (kg <= 0 || lastSets.isEmpty()) return null
        val anchor = lastSets.maxByOrNull { it.weightKg ?: 0.0 }?.weightKg
            ?: lastSets.mapNotNull { it.weightKg }.firstOrNull()
        return if (anchor != null && anchor > 0) {
            val ratio = kg / anchor
            val safeStep = maxOf(step, 0.5)
            lastSets.map { set ->
                val scaled: Double? = run {
                    val w = set.weightKg
                    if (w == null || w <= 0) return@run kg
                    val rounded = Math.round(w * ratio / safeStep) * safeStep
                    if (rounded > 0) rounded else null
                }
                PlannedSetDraft(
                    targetReps = set.reps,
                    targetWeightKg = scaled,
                    targetRir = set.rir ?: fallbackRir,targetDurationSeconds=set.durationSeconds
                )
            }
        } else {
            lastSets.map { set ->
                PlannedSetDraft(
                    targetReps = set.reps,
                    targetWeightKg = kg,
                    targetRir = set.rir ?: fallbackRir,targetDurationSeconds=set.durationSeconds
                )
            }
        }
    }

    /** «Copiar última sesión» (port de PlanView.applyLastSession iOS). */
    fun copyLastSession(lastSets: List<LoadGuideSet>): List<PlannedSetDraft> =
        lastSets.map { set ->
            PlannedSetDraft(
                targetReps = set.reps,
                targetWeightKg = set.weightKg,
                targetRir = set.rir,targetDurationSeconds=set.durationSeconds
            )
        }

    /** Guía completa para el ejercicio (port de la lógica de
     *  ExerciseLoadGuideCard.body iOS). */
    fun guide(
        root: JSONObject,
        exerciseId: String,
        targetReps: Int,
        targetRir: Double?
    ): LoadGuide {
        val workouts = root.optJSONArray("workouts")?.let { array ->
            (0 until array.length()).map { array.getJSONObject(it) }
        } ?: emptyList()
        val catalog = root.optJSONArray("exercises")
        val last = lastWorkingSession(exerciseId, workouts, catalog)

        val prefs = root.optJSONObject("exerciseLoadPrefs")
            ?.optJSONObject(exerciseId)
        val tested = prefs?.takeIf {
            it.has("testedOneRMKg") && !it.isNull("testedOneRMKg")
        }?.getDouble("testedOneRMKg")?.takeIf { it > 0 }

        val increment = root.optJSONObject("settings")
            ?.takeIf { it.has("weightIncrementKg") && !it.isNull("weightIncrementKg") }
            ?.getDouble("weightIncrementKg")?.takeIf { it > 0 }
            ?: DEFAULT_INCREMENT_KG

        val reps = maxOf(1, targetReps)
        val effectiveRir = targetRir ?: DEFAULT_RIR

        var kg: Double? = null
        var source: String? = null
        val oneRM = tested ?: estimatedOneRM(exerciseId, workouts, catalog)
            ?.takeIf { it > 0 }
        if (oneRM != null) {
            val w = LoadSuggestion.weightKg(oneRM, reps, effectiveRir, roundTo = increment)
            if (w > 0) {
                kg = w
                source = if (tested != null) "1RM" else "e1RM"
            }
        }
        if (kg == null) {
            val lastSet = last?.topSet?.takeIf { (it.weightKg ?: 0.0) > 0 }
                ?: last?.sets?.lastOrNull()?.takeIf { (it.weightKg ?: 0.0) > 0 }
            if (lastSet != null) {
                val w = LoadSuggestion.weightKgFromLastSet(
                    lastWeightKg = lastSet.weightKg!!,
                    lastReps = lastSet.reps,
                    lastRir = lastSet.rir,
                    targetReps = reps,
                    targetRir = effectiveRir,
                    roundTo = increment
                )
                if (w > 0) {
                    kg = w
                    source = "última"
                }
            }
        }
        return LoadGuide(
            lastSession = last,
            suggestedKg = kg,
            suggestionSource = source,
            assumedRir = targetRir == null,
            targetReps = reps,
            effectiveRir = effectiveRir,
            incrementKg = increment
        )
    }
}
