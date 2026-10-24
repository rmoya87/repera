package dev.repera.domain

/**
 * Asociación Salud ↔ sesión y mezcla de FC multi-origen.
 *
 * Port de las reglas de HealthKitStore iOS:
 * - `overlappingWorkout(from:to:)`: ventana expandida ±45 min; un candidato
 *   debe solapar ≥70% de la duración de la sesión Repera Y ≥60% de la suya
 *   (mínimo 60 s); se prefieren fuentes externas a las propias; el mejor
 *   candidato solo se acepta si es único o el segundo solapa <85% del mejor
 *   (si no, ambiguo → no se asocia nada).
 * - HealthKit fusiona orígenes internamente; Health Connect NO deduplica, así
 *   que la mezcla se hace aquí con reglas explícitas y conservadoras: se
 *   fusionan TODOS los orígenes (nunca se elige «el de más muestras»), se
 *   eliminan duplicados exactos (mismo instante ±2 s y mismo lpm: teléfono +
 *   reloj de la misma app, o registros externos duplicados) y si dos orígenes
 *   se contradicen en la misma ventana (señal ajena solapada) la muestra se
 *   declara ambigua y NO se refina la nota: se conserva la existente.
 */
object SessionHealthMatcher {

    const val QUERY_SLACK_MS: Long = 45 * 60 * 1000
    private const val MIN_SESSION_OVERLAP_RATIO = 0.70
    private const val MIN_CANDIDATE_OVERLAP_RATIO = 0.60
    private const val MIN_CANDIDATE_OVERLAP_MS = 60_000L
    private const val AMBIGUITY_RATIO = 0.85
    private const val DUP_TOLERANCE_MS = 2_000L
    private const val BUCKET_MS = 30_000L
    private const val CONTEST_BPM = 15
    private const val CONTEST_FRACTION = 0.30

    data class CandidateSession(
        val id: String,
        val startEpochMs: Long,
        val endEpochMs: Long,
        val packageName: String
    )

    sealed interface Association {
        data class Matched(val session: CandidateSession) : Association
        data object None : Association
        data object Ambiguous : Association
    }

    data class HeartSample(val epochMs: Long, val bpm: Int, val originPackage: String)

    sealed interface HeartMerge {
        data class Merged(val series: List<Pair<Long, Int>>) : HeartMerge
        data object Empty : HeartMerge
        data object Ambiguous : HeartMerge
    }

    /** Asocia la sesión Repera [sessionStartMs, sessionEndMs] con UN registro
     *  de actividad de Salud, o declara la asociación inexistente/ambigua. */
    fun associate(
        sessionStartMs: Long,
        sessionEndMs: Long,
        candidates: List<CandidateSession>,
        ownPackageName: String
    ): Association {
        val sessionDuration = maxOf(60_000L, sessionEndMs - sessionStartMs)
        val minSessionOverlap = (sessionDuration * MIN_SESSION_OVERLAP_RATIO).toLong()
        data class Ranked(val candidate: CandidateSession, val overlapMs: Long)
        val ranked = candidates.mapNotNull { c ->
            val overlap = maxOf(
                0L,
                minOf(c.endEpochMs, sessionEndMs) - maxOf(c.startEpochMs, sessionStartMs)
            )
            val candidateDuration = maxOf(1L, c.endEpochMs - c.startEpochMs)
            val minCandidateOverlap = maxOf(
                MIN_CANDIDATE_OVERLAP_MS,
                (candidateDuration * MIN_CANDIDATE_OVERLAP_RATIO).toLong()
            )
            if (overlap >= minSessionOverlap && overlap >= minCandidateOverlap)
                Ranked(c, overlap) else null
        }
        fun pick(list: List<Ranked>): CandidateSession? {
            if (list.isEmpty()) return null
            val sorted = list.sortedByDescending { it.overlapMs }
            val best = sorted.first()
            // Dos fuentes igual de plausibles: no escoger arbitrariamente.
            if (sorted.size > 1 && sorted[1].overlapMs >= best.overlapMs * AMBIGUITY_RATIO) {
                return null
            }
            return best.candidate
        }
        val external = ranked.filter { it.candidate.packageName != ownPackageName }
        pick(external)?.let { return Association.Matched(it) }
        val own = ranked.filter { it.candidate.packageName == ownPackageName }
        pick(own)?.let { return Association.Matched(it) }
        // Había candidatos que pasaban umbrales pero sin ganador claro.
        if (ranked.isNotEmpty()) return Association.Ambiguous
        return Association.None
    }

    /** Fusiona muestras de FC de todos los orígenes en la ventana: dedup de
     *  duplicados exactos entre orígenes y detección de señal contradictoria.
     *  Nunca elige un origen por densidad. */
    fun mergeHeartRate(samples: List<HeartSample>): HeartMerge {
        if (samples.isEmpty()) return HeartMerge.Empty
        val sorted = samples.sortedBy { it.epochMs }
        // Dedup: mismo instante (±2 s) y mismo lpm desde otro origen = la
        // misma medición escrita dos veces (teléfono+reloj, duplicado externo).
        val kept = mutableListOf<HeartSample>()
        for (s in sorted) {
            val duplicate = kept.any {
                it.originPackage != s.originPackage &&
                    kotlin.math.abs(it.epochMs - s.epochMs) <= DUP_TOLERANCE_MS &&
                    it.bpm == s.bpm
            }
            if (!duplicate) kept.add(s)
        }
        // Contienda: buckets de 30 s con ≥2 orígenes y medias separadas >15 lpm.
        val byBucket = kept.groupBy { it.epochMs / BUCKET_MS }
        var multi = 0
        var contested = 0
        for ((_, bucketSamples) in byBucket) {
            val byOrigin = bucketSamples.groupBy { it.originPackage }
            if (byOrigin.size < 2) continue
            multi++
            val means = byOrigin.values.map { list -> list.map { it.bpm }.average() }
            if ((means.max() - means.min()) > CONTEST_BPM) contested++
        }
        if (multi > 0 && contested.toDouble() / multi >= CONTEST_FRACTION) {
            return HeartMerge.Ambiguous
        }
        return HeartMerge.Merged(kept.map { it.epochMs to it.bpm })
    }
}
