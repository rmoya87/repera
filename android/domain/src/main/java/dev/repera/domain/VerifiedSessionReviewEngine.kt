package dev.repera.domain

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.abs
import kotlin.math.ln
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Port 1:1 de VerifiedSessionReviewEngine.swift (fórmula v11): niveles de
 * evidencia sin nota sintética sin historial personal. Tres indicadores
 * separados; la cobertura de registro NUNCA son puntos de forma física.
 */
object VerifiedSessionReviewEngine {
    const val MINIMUM_PRIOR_SESSIONS = 2
    const val MINIMUM_EVIDENCE_COVERAGE = 0.60
    const val HISTORY_HORIZON_DAYS = 180
    const val MINIMUM_STIMULUS_REFERENCE_DAYS = 3

    private data class Evidence(
        val score: Int,
        val weight: Double,
        val referenceCount: Int,
        val explanation: String,
        val tier: Int
    )

    fun review(
        session: ReviewWorkoutSession,
        history: List<ReviewWorkoutSession>,
        nowMillis: Long = System.currentTimeMillis(),
        zone: ZoneId = ZoneId.systemDefault()
    ): SessionReview? {
        if (!session.finished) return null
        val currentMillis = session.finishedAtMillis ?: nowMillis
        val cutoff = currentMillis - HISTORY_HORIZON_DAYS * 86_400_000L
        val prior = history.filter {
            it.id != session.id && it.finished &&
                (it.finishedAtMillis ?: Long.MIN_VALUE) < currentMillis &&
                (it.finishedAtMillis ?: Long.MIN_VALUE) >= cutoff
        }

        val movementCandidates = session.exercises.filter {
            it.wodFormat == null || it.wodFormat.capture == ResultCapture.PER_MOVEMENT_SETS
        }
        val movementEntries = movementCandidates.filter { entry ->
            entry.loggedSets.any { !it.isWarmup && it.reps > 0 }
        }
        val wodResults = session.wodResults.filter { validScore(it) }
        val plannedGlobalBlocks = session.routineBlocks?.count { block ->
            val format = block.wodFormat ?: return@count false
            format.capture != ResultCapture.PER_MOVEMENT_SETS
        } ?: 0
        // La cobertura cuenta TODAS las unidades de rendimiento prescritas,
        // incluidos bloques sin registro: un único movimiento comparable en una
        // sesión mixta larga no debe disfrazarse de nota global fiable.
        val possible = movementCandidates.size + max(plannedGlobalBlocks, wodResults.size)
        if (possible <= 0) return null

        val movementEvidence = movementEntries.mapNotNull { personalEvidence(it, prior, zone) }
        val wodEvidence = wodResults.mapNotNull { result ->
            wodEvidence(result, session, prior, zone)
                ?: calibratedStimulusEvidence(result, session, prior, zone)
        }
        val eligible = movementEvidence + wodEvidence
        if (eligible.isEmpty()) return null

        val coverage = eligible.size.toDouble() / possible
        if (coverage < MINIMUM_EVIDENCE_COVERAGE) return null
        val weighted = eligible.sumOf { it.score * it.weight }
        val totalWeight = eligible.sumOf { it.weight }
        if (totalWeight <= 0) return null
        val score = min(10, max(1, (weighted / totalWeight).roundToInt()))

        fun average(values: List<Evidence>): Int? {
            if (values.isEmpty()) return null
            return (values.sumOf { it.score }.toDouble() / values.size).roundToInt()
        }
        val personal = average(movementEvidence)
        val wod = average(wodEvidence)
        val registered = session.exercises.filter {
            it.wodFormat?.capture == ResultCapture.PER_MOVEMENT_SETS || it.wodFormat == null
        }
        val plannedSets = registered.sumOf { it.plannedSets.size }
        val actualSets = registered.sumOf { entry -> entry.loggedSets.count { !it.isWarmup } }
        val minReferences = eligible.minOfOrNull { it.referenceCount } ?: MINIMUM_PRIOR_SESSIONS
        val weakestTier = eligible.maxOfOrNull { it.tier } ?: 1
        val confidence = when {
            weakestTier == 1 && minReferences >= 5 && coverage >= 0.80 -> "Alta"
            weakestTier == 3 -> "Baja · estímulo estimado"
            weakestTier == 2 -> "Media · distinto contexto"
            else -> "En construcción"
        }
        val coveragePercent = (coverage * 100).roundToInt()

        val indicators = listOf(
            ReviewIndicator(
                dimension = ReviewDimension.PERSONAL_PROGRESS,
                score = personal,
                detail = if (personal == null)
                    "Faltan dos sesiones previas comparables de cada ejercicio."
                else movementEvidence.joinToString(" · ") { it.explanation },
                referenceSessions = movementEvidence.minOfOrNull { it.referenceCount } ?: 0,
                comparisonLevel = movementEvidence.maxOfOrNull { it.tier }
            ),
            ReviewIndicator(
                dimension = ReviewDimension.ADHERENCE,
                score = null,
                detail = if (plannedSets > 0)
                    "$actualSets de $plannedSets series registradas. No mide intensidad ni técnica."
                else "Sin series programadas evaluables; no suma ni resta puntos.",
                referenceSessions = 0
            ),
            ReviewIndicator(
                dimension = ReviewDimension.WOD_PERFORMANCE,
                score = wod,
                detail = if (wod == null)
                    "Faltan dos marcas anteriores del mismo WOD, formato y prescripción."
                else wodEvidence.joinToString(" · ") { it.explanation },
                referenceSessions = wodEvidence.minOfOrNull { it.referenceCount } ?: 0,
                comparisonLevel = wodEvidence.maxOfOrNull { it.tier }
            )
        )
        return SessionReview(
            overallScore = score,
            level = null,
            headline = "Rendimiento personal · $score/10",
            vsHistorySummary = "$coveragePercent% del rendimiento registrado tiene referencias personales comparables.",
            vsStandardSummary = "Historial personal: se prioriza la coincidencia exacta, después el mismo ejercicio en distinta sesión y por último el estímulo calibrado. No se convierten series registradas en puntos.",
            keepTips = listOf("Cada referencia muestra su nivel de comparabilidad. No se equiparan ejercicios diferentes sin calibración de resultados."),
            improveTips = listOf("Con más sesiones independientes aumentará la confianza de esta valoración."),
            movements = emptyList(),
            wodTemplateId = null,
            scoreBasis = ScoreBasis.PERSONAL_HISTORY,
            indicators = indicators,
            evidenceCoverage = coverage,
            confidenceLabel = confidence
        )
    }

    private fun validScore(result: ReviewWodBlockResult): Boolean {
        val format = result.format ?: return false
        return when (format.capture) {
            ResultCapture.ELAPSED_TIME -> (result.elapsedSeconds ?: 0) > 0
            ResultCapture.TOTAL_REPS -> (result.roundsCompleted ?: 0) > 0 || (result.totalReps ?: 0) > 0
            ResultCapture.PER_MOVEMENT_SETS -> false
        }
    }

    private fun sameExercise(a: ReviewExercise, b: ReviewExercise): Boolean {
        // La misma identidad de catálogo es necesaria pero no suficiente:
        // equipo, unidades de registro y tipo de ejecución deben coincidir.
        return ExerciseEquivalence.matchesCatalogIdentity(a, b) &&
            a.loggingStyle == b.loggingStyle &&
            a.loadField == b.loadField &&
            (a.equipment ?: "").lowercase() == (b.equipment ?: "").lowercase()
    }

    private fun bestComparableSet(
        entry: ReviewSessionExercise,
        reference: ReviewLoggedSet?
    ): ReviewLoggedSet? {
        val sets = entry.loggedSets.filter { !it.isWarmup && it.reps > 0 }
        if (sets.isEmpty()) return null
        val matched = sets.filter { set ->
            if (reference == null) return@filter true
            if (abs(set.reps - reference.reps) > 2) return@filter false
            val a = set.rir
            val b = reference.rir
            if (a != null && b != null && abs(a - b) > 1.5) return@filter false
            true
        }
        return matched.maxByOrNull { loadMetric(it, entry.exercise.loggingStyle) ?: 0.0 }
    }

    private fun loadMetric(set: ReviewLoggedSet, style: ExerciseLoggingStyle): Double? {
        if (set.reps <= 0) return null
        return when (style) {
            ExerciseLoggingStyle.LOAD_AND_REPS -> {
                val kg = set.weightKg
                if (kg == null || kg <= 0 || set.reps > 12) null
                else PlateMath.epleyOneRM(kg, set.reps)
            }
            ExerciseLoggingStyle.REPS_ONLY -> set.reps.toDouble()
            ExerciseLoggingStyle.REPS_AND_TIME, ExerciseLoggingStyle.MACHINE_WORK -> {
                val seconds = set.durationSeconds
                if (seconds == null || seconds <= 0) null
                else set.reps.toDouble() / seconds
            }
        }
    }

    private fun personalEvidence(
        entry: ReviewSessionExercise,
        prior: List<ReviewWorkoutSession>,
        zone: ZoneId
    ): Evidence? {
        val currentSet = bestComparableSet(entry, null) ?: return null
        val currentValue = loadMetric(currentSet, entry.exercise.loggingStyle) ?: return null
        if (currentValue <= 0) return null

        // Nivel 1: mismo ejercicio y mismo contexto. Nivel 2: el mismo ejercicio
        // entre formatos de bloques diferentes (por ejemplo EMOM -> fuerza).
        // Las variantes de ejercicio JAMÁS son referencias de carga válidas.
        fun sameContext(candidate: ReviewSessionExercise): Boolean =
            candidate.wodFormat == entry.wodFormat &&
                candidate.blockIntervalSeconds == entry.blockIntervalSeconds &&
                candidate.blockTimeCapMinutes == entry.blockTimeCapMinutes

        fun readings(allowOtherContext: Boolean): List<Pair<LocalDate, Double>> {
            val perDay = mutableListOf<Pair<LocalDate, Double>>()
            for (workout in prior.sortedByDescending { it.finishedAtMillis ?: Long.MIN_VALUE }) {
                val finished = workout.finishedAtMillis ?: continue
                val day = Instant.ofEpochMilli(finished).atZone(zone).toLocalDate()
                if (perDay.any { it.first == day }) continue
                val values = workout.exercises.mapNotNull { candidate ->
                    if (!sameExercise(candidate.exercise, entry.exercise)) return@mapNotNull null
                    val same = sameContext(candidate)
                    if (!same) {
                        if (!allowOtherContext) return@mapNotNull null
                        // Comparar intervalos distintos solo tiene sentido con
                        // carga medida. Reps sueltas en circuitos variados no
                        // tienen denominador de esfuerzo equivalente.
                        if (entry.exercise.loggingStyle != ExerciseLoggingStyle.LOAD_AND_REPS)
                            return@mapNotNull null
                        // En contextos distintos solo un RIR comparable valida
                        // el esfuerzo. No se infiere de las reps programadas.
                        val a = currentSet.rir
                        val b = bestComparableSet(candidate, currentSet)?.rir
                        if (a == null || b == null || abs(a - b) > 1.5) return@mapNotNull null
                    }
                    val pastSet = bestComparableSet(candidate, currentSet) ?: return@mapNotNull null
                    val value = loadMetric(pastSet, entry.exercise.loggingStyle) ?: return@mapNotNull null
                    if (value <= 0) return@mapNotNull null
                    val currentTarget = entry.plannedSets.firstOrNull()?.targetWeightKg
                    val previousTarget = candidate.plannedSets.firstOrNull()?.targetWeightKg
                    if (currentTarget != null && previousTarget != null &&
                        currentTarget > 0 && previousTarget > 0 &&
                        currentTarget < previousTarget * 0.90) return@mapNotNull null
                    value
                }
                values.maxOrNull()?.let { perDay.add(day to it) }
                if (perDay.size == 5) break
            }
            return perDay
        }

        var days = readings(allowOtherContext = false)
        val tier: Int
        if (days.size >= MINIMUM_PRIOR_SESSIONS) {
            tier = 1
        } else {
            days = readings(allowOtherContext = true)
            if (days.size < MINIMUM_PRIOR_SESSIONS) return null
            tier = 2
        }
        val reference = median(days.map { it.second }.sorted())
        if (reference <= 0) return null
        val ratio = currentValue / reference
        val prefix = if (tier == 1) "Nivel 1 · mismo contexto"
        else "Nivel 2 · mismo ejercicio, distinto formato (RIR comparable)"
        return Evidence(
            score = points(ratio),
            weight = if (tier == 1) 5.0 else 3.0,
            referenceCount = days.size,
            explanation = "$prefix · ${entry.exercise.name}: ${signedChange(ratio)} respecto a ${days.size} días anteriores",
            tier = tier
        )
    }

    private fun wodEvidence(
        result: ReviewWodBlockResult,
        session: ReviewWorkoutSession,
        prior: List<ReviewWorkoutSession>,
        zone: ZoneId
    ): Evidence? {
        val currentBlock = session.routineBlocks?.firstOrNull { it.id == result.id } ?: return null
        val format = result.format ?: return null
        val current = wodMetric(result, currentBlock, session) ?: return null
        if (current <= 0) return null
        val scaled = session.exercises.filter { it.blockId == result.id }
        val refs = mutableListOf<Pair<LocalDate, Double>>()
        for (workout in prior.sortedByDescending { it.finishedAtMillis ?: Long.MIN_VALUE }) {
            val finished = workout.finishedAtMillis ?: continue
            val day = Instant.ofEpochMilli(finished).atZone(zone).toLocalDate()
            if (refs.any { it.first == day }) continue
            val previous = workout.wodResults.firstOrNull { candidate ->
                candidate.format == format && validScore(candidate) &&
                    workout.routineBlocks?.any { block ->
                        block.id == candidate.id && samePrescription(currentBlock, block)
                    } == true
            } ?: continue
            val pastBlock = workout.routineBlocks?.firstOrNull { it.id == previous.id } ?: continue
            val value = wodMetric(previous, pastBlock, workout) ?: continue
            if (value <= 0) continue
            val previousScaled = workout.exercises.filter { it.blockId == previous.id }
            if (!sameScaling(scaled, previousScaled)) continue
            refs.add(day to value)
            if (refs.size == 5) break
        }
        if (refs.size < MINIMUM_PRIOR_SESSIONS) return null
        val reference = median(refs.map { it.second }.sorted())
        if (reference <= 0) return null
        val ratio = current / reference
        val minutes = max(1, min(90, currentBlock.timeCapMinutes ?: 8)).toDouble()
        return Evidence(
            score = points(ratio), weight = minutes,
            referenceCount = refs.size,
            explanation = "Nivel 1 · ${currentBlock.title}: ${signedChange(ratio)} frente a ${refs.size} marcas idénticas",
            tier = 1
        )
    }

    /// Nivel 3: trabajo por minuto con las MISMAS tareas motoras.
    /// Permite variar AMRAP/For Time/RFT, tiempo y repeticiones programadas
    /// sin equiparar burpees con push-ups ni kg de un movimiento con otro.
    /// Es un indicador orientativo de densidad, nunca un benchmark Rx.
    /// Solo se habilita con tres días históricos independientes.
    private fun calibratedStimulusEvidence(
        result: ReviewWodBlockResult,
        session: ReviewWorkoutSession,
        prior: List<ReviewWorkoutSession>,
        zone: ZoneId
    ): Evidence? {
        val currentBlock = session.routineBlocks?.firstOrNull { it.id == result.id } ?: return null
        val currentDensity = normalizedDensity(result, currentBlock) ?: return null
        val currentSeconds = stimulusDuration(result, currentBlock) ?: return null
        if (currentDensity <= 0) return null
        val currentScaled = session.exercises.filter { it.blockId == result.id }
        // Dosis escaladas distintas no se reducen a una unidad común.
        if (currentScaled.any { it.hasWODScaling }) return null
        val priorDays = mutableListOf<Pair<LocalDate, Double>>()
        for (workout in prior.sortedByDescending { it.finishedAtMillis ?: Long.MIN_VALUE }) {
            val finished = workout.finishedAtMillis ?: continue
            val day = Instant.ofEpochMilli(finished).atZone(zone).toLocalDate()
            if (priorDays.any { it.first == day }) continue
            val best = workout.wodResults.mapNotNull { previous ->
                if (!validScore(previous)) return@mapNotNull null
                val block = workout.routineBlocks?.firstOrNull { it.id == previous.id }
                    ?: return@mapNotNull null
                if (!comparableStimulus(currentBlock, block)) return@mapNotNull null
                if (workout.exercises.any { it.blockId == previous.id && it.hasWODScaling })
                    return@mapNotNull null
                if (!sameScaling(currentScaled, workout.exercises.filter { it.blockId == previous.id }))
                    return@mapNotNull null
                val rate = normalizedDensity(previous, block) ?: return@mapNotNull null
                if (rate <= 0) return@mapNotNull null
                // Excluye dominios de tiempo muy distintos (sprints vs WODs largos).
                val priorSeconds = stimulusDuration(previous, block) ?: return@mapNotNull null
                if (max(currentSeconds, priorSeconds) / min(currentSeconds, priorSeconds) > 1.5)
                    return@mapNotNull null
                rate
            }.maxOrNull() ?: continue
            priorDays.add(day to best)
            if (priorDays.size == 5) break
        }
        if (priorDays.size < MINIMUM_STIMULUS_REFERENCE_DAYS) return null
        val reference = median(priorDays.map { it.second }.sorted())
        if (reference <= 0) return null
        val ratio = currentDensity / reference
        val minutes = currentSeconds / 60
        return Evidence(
            score = points(ratio),
            weight = max(1.0, min(12.0, minutes)) * 0.5,
            referenceCount = priorDays.size,
            explanation = "Nivel 3 · estímulo comparable · ${signedChange(ratio)} de densidad de reps, ${priorDays.size} días calibrados (mismos movimientos y cargas)",
            tier = 3
        )
    }

    private fun stimulusDuration(
        result: ReviewWodBlockResult, block: ReviewRoutineBlock
    ): Double? {
        return when (result.format) {
            WodFormat.AMRAP -> {
                val minutes = block.timeCapMinutes
                if (minutes == null || minutes <= 0) null else (minutes * 60).toDouble()
            }
            WodFormat.FOR_TIME, WodFormat.AFAP, WodFormat.CHIPPER -> {
                val seconds = result.elapsedSeconds
                if (seconds == null || seconds <= 0) null else seconds.toDouble()
            }
            else -> null
        }
    }

    private fun normalizedDensity(
        result: ReviewWodBlockResult, block: ReviewRoutineBlock
    ): Double? {
        val seconds = stimulusDuration(result, block) ?: return null
        if (block.movements.isEmpty()) return null
        val movements = block.movements
        if (!movements.all {
                !it.isRest && (it.reps ?: 0) > 0 &&
                    it.repScheme == null && it.distanceMeters == null &&
                    it.calories == null && it.scaleAlternative.isNullOrEmpty()
            }) return null
        val perCycle = movements.sumOf { it.reps ?: 0 }
        if (perCycle <= 0) return null
        val performed: Int = when (result.format) {
            WodFormat.AMRAP -> {
                val rounds = result.roundsCompleted ?: 0
                val partial = result.totalReps ?: 0
                if (rounds < 0 || partial < 0 || partial >= perCycle ||
                    (rounds <= 0 && partial <= 0)) return null
                rounds * perCycle + partial
            }
            WodFormat.FOR_TIME -> {
                val rounds = block.rounds
                if (rounds == null || rounds <= 0) return null
                rounds * perCycle
            }
            WodFormat.AFAP, WodFormat.CHIPPER -> {
                // Solo prescripciones simples de una pasada son comparables.
                if (block.rounds != null && block.rounds != 1) return null
                perCycle
            }
            else -> return null
        }
        return performed * 60.0 / seconds
    }

    private fun comparableStimulus(
        current: ReviewRoutineBlock, previous: ReviewRoutineBlock
    ): Boolean {
        val left = current.movements
        val right = previous.movements
        if (left.isEmpty() || left.size != right.size || left.size > 5) return false
        if (!left.all { !it.isRest } || !right.all { !it.isRest }) return false
        // Permite distinto orden o reps modestamente distintas, pero conserva
        // identidad, unidad de dosis, peso y equipo prescritos de cada movimiento.
        val used = mutableSetOf<Int>()
        for (move in left) {
            val index = right.indices.firstOrNull { index ->
                if (used.contains(index)) return@firstOrNull false
                val old = right[index]
                if (!ExerciseEquivalence.sameName(move.name, old.name)) return@firstOrNull false
                val a = move.reps
                val b = old.reps
                if (a == null || b == null || a <= 0 || b <= 0) return@firstOrNull false
                if (max(a, b).toDouble() / min(a, b) > 1.25) return@firstOrNull false
                if (move.repScheme != null || old.repScheme != null) return@firstOrNull false
                if (move.distanceMeters != null || old.distanceMeters != null) return@firstOrNull false
                if (move.calories != null || old.calories != null) return@firstOrNull false
                if (!move.scaleAlternative.isNullOrEmpty()) return@firstOrNull false
                if (!old.scaleAlternative.isNullOrEmpty()) return@firstOrNull false
                listOf(move.weightMaleKg to old.weightMaleKg, move.weightFemaleKg to old.weightFemaleKg)
                    .all { (aW, bW) ->
                        if (aW == null && bW == null) true
                        else if (aW == null || bW == null || aW <= 0 || bW <= 0) false
                        else abs(aW - bW) / max(aW, bW) <= 0.05
                    }
            } ?: return false
            used.add(index)
        }
        return true
    }

    private fun sameScaling(
        current: List<ReviewSessionExercise>, previous: List<ReviewSessionExercise>
    ): Boolean {
        val a = current.filter { it.hasWODScaling }
        val b = previous.filter { it.hasWODScaling }
        if (a.size != b.size) return false
        return a.all { item ->
            b.any { old ->
                sameExercise(item.exercise, old.exercise) &&
                    item.adaptedReps == old.adaptedReps &&
                    abs((item.adaptedWeightKg ?: 0.0) - (old.adaptedWeightKg ?: 0.0)) < 0.05
            }
        }
    }

    private fun samePrescription(a: ReviewRoutineBlock, b: ReviewRoutineBlock): Boolean {
        if (a.wodFormat != b.wodFormat ||
            a.timeCapMinutes != b.timeCapMinutes ||
            a.emomIntervalSeconds != b.emomIntervalSeconds ||
            a.rounds != b.rounds ||
            a.movements.size != b.movements.size) return false
        for ((left, right) in a.movements.zip(b.movements)) {
            if (!ExerciseEquivalence.sameName(left.name, right.name) ||
                left.reps != right.reps ||
                left.repScheme != right.repScheme ||
                left.distanceMeters != right.distanceMeters ||
                left.calories != right.calories ||
                abs((left.weightMaleKg ?: 0.0) - (right.weightMaleKg ?: 0.0)) >= 0.05 ||
                abs((left.weightFemaleKg ?: 0.0) - (right.weightFemaleKg ?: 0.0)) >= 0.05
            ) return false
        }
        return true
    }

    private fun wodMetric(
        result: ReviewWodBlockResult, block: ReviewRoutineBlock, session: ReviewWorkoutSession
    ): Double? {
        val format = result.format ?: return null
        return when (format.capture) {
            ResultCapture.ELAPSED_TIME -> {
                val seconds = result.elapsedSeconds
                if (seconds == null || seconds <= 0) null
                else 1.0 / seconds // Menos tiempo = mejor
            }
            ResultCapture.TOTAL_REPS -> {
                if (format == WodFormat.AMRAP || format == WodFormat.DEATH_BY) {
                    val registered = session.exercises.filter { it.blockId == result.id }
                    val perRound = block.movements.filter { !it.isRest }.sumOf { move ->
                        val adapted = registered.firstOrNull {
                            ExerciseEquivalence.sameName(it.exercise.name, move.name)
                        }?.adaptedReps
                        maxOf(0, adapted ?: move.reps ?: 0)
                    }
                    if (perRound <= 0) return null
                    (result.roundsCompleted ?: 0).toDouble() +
                        (result.totalReps ?: 0).toDouble() / perRound
                } else {
                    (result.totalReps ?: 0).toDouble()
                }
            }
            ResultCapture.PER_MOVEMENT_SETS -> null
        }
    }

    private fun median(sorted: List<Double>): Double {
        val mid = sorted.size / 2
        return if (sorted.size % 2 == 0) (sorted[mid - 1] + sorted[mid]) / 2
        else sorted[mid]
    }

    private fun points(ratio: Double): Int {
        // Base 7/10 para rendimiento estable; logarítmico y acotado.
        // No es una nota fisiológica ni normada por población.
        if (!ratio.isFinite() || ratio <= 0) return 1
        return min(10, max(1, (7 + 11 * ln(ratio)).roundToInt()))
    }

    private fun signedChange(ratio: Double): String {
        val change = ((ratio - 1) * 100).roundToInt()
        return if (change > 0) "+$change%" else "$change%"
    }
}
