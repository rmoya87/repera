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
 *   que la mezcla se hace aquí. La fusión de todos los orígenes es la parte
 *   equivalente a HealthKit; los umbrales concretos de dedup y contienda
 *   (±2 s, buckets de 30 s, >15 lpm, ≥30% contestado) son POLÍTICA NUEVA DE
 *   ANDROID sin fuente Apple: se fusionan TODOS los orígenes (nunca se elige
 *   «el de más muestras»), se eliminan duplicados exactos (mismo instante
 *   ±2 s y mismo lpm: teléfono + reloj de la misma app, o registros externos
 *   duplicados) y si dos orígenes se contradicen en la misma ventana (señal
 *   ajena solapada) la muestra se declara ambigua y NO se refina la nota:
 *   se conserva la existente.
 */
object SessionHealthMatcher {

    // Umbrales LITERALES de HealthKitStore.overlappingWorkout (iOS).
    const val QUERY_SLACK_MS: Long = 45 * 60 * 1000
    private const val MIN_SESSION_OVERLAP_RATIO = 0.70
    private const val MIN_CANDIDATE_OVERLAP_RATIO = 0.60
    private const val MIN_CANDIDATE_OVERLAP_MS = 60_000L
    private const val AMBIGUITY_RATIO = 0.85
    // Constantes de POLÍTICA NUEVA ANDROID (sin equivalente escrito en iOS;
    // HealthKit deduplica/fusiona internamente sin exponer sus umbrales).
    private const val DUP_TOLERANCE_MS = 2_000L
    private const val BUCKET_MS = 30_000L
    private const val CONTEST_BPM = 15
    private const val CONTEST_FRACTION = 0.30

    data class CandidateSession(
        val id: String,
        val startEpochMs: Long,
        val endEpochMs: Long,
        val packageName: String,
        val clientRecordId: String? = null,
        val observedDurationMinutes:Double?=null,
        /** Clave de tipo de ejercicio (HealthConnectReader.exerciseTypeKey), solo informativa. */
        val exerciseTypeKey:String?=null
    )

    fun observedDurationMinutes(candidate:CandidateSession):Double? =
        candidate.observedDurationMinutes?.takeIf {it.isFinite() && it>=0}
            ?: ((candidate.endEpochMs-candidate.startEpochMs)/60000.0).takeIf {it>0}

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
        if(external.isNotEmpty()) {
            return pick(external)?.let {Association.Matched(it)} ?: Association.Ambiguous
        }
        val own = ranked.filter { it.candidate.packageName == ownPackageName }
        pick(own)?.let { return Association.Matched(it) }
        // Había candidatos que pasaban umbrales pero sin ganador claro.
        if (ranked.isNotEmpty()) return Association.Ambiguous
        return Association.None
    }

    /** Vínculo directo por id de registro (fetchWorkout(uuid) iOS): si la
     *  sesión ya tiene un registro de Salud enlazado y sigue existiendo, ese
     *  es el asociado sin pasar por umbrales de ventana. */
    fun matchById(
        candidates: List<CandidateSession>,
        linkedRecordId: String?
    ): CandidateSession? {
        if (linkedRecordId.isNullOrBlank()) return null
        return candidates.firstOrNull { it.id == linkedRecordId }
    }

    /** Decisión de vínculo/escritura de la sesión propia en Salud. */
    sealed interface LinkDecision {
        /** Reusar/adoptar un registro existente; NO se escribe nada. */
        data class UseExisting(val recordId: String) : LinkDecision
        /** Insertar (o actualizar por clientRecordId) el registro propio. */
        data object Insert : LinkDecision
        /** Asociación ambigua: ni reutilizar ni escribir (conservar local). */
        data object Skip : LinkDecision
    }

    /** Vínculo persistido reutilizable SOLO si el registro sigue existiendo Y
     *  pertenece a ESTA sesión: propio con el clientRecordId de la sesión, o
     *  supera los umbrales de asociación por ventana de associate(). Un
     *  vínculo que apunta a un registro que ya no existe o que no cumple
     *  ninguna de las dos condiciones (obsoleto, de otra sesión o corrupto)
     *  se descarta y se cae a las reglas normales. */
    fun validStoredLink(
        sessionId: String,
        sessionStartMs: Long,
        sessionEndMs: Long,
        storedRecordId: String?,
        candidates: List<CandidateSession>,
        ownPackageName: String
    ): CandidateSession? {
        if (storedRecordId.isNullOrBlank()) return null
        val rec = candidates.firstOrNull { it.id == storedRecordId } ?: return null
        val ownsIt = rec.packageName == ownPackageName &&
            rec.clientRecordId != null &&
            rec.clientRecordId == HealthSessionLink.clientRecordId(sessionId)
        if (ownsIt) return rec
        if(rec.packageName==ownPackageName && rec.clientRecordId!=null) return null
        return if (associate(sessionStartMs, sessionEndMs, listOf(rec), ownPackageName)
            is Association.Matched) rec else null
    }

    /** Result of reading the persisted link's record by id (not by the session window). */
    sealed interface LinkLookup {
        data class Found(val record: CandidateSession) : LinkLookup
        /** The provider answered and the record does not exist. */
        data object Gone : LinkLookup
        /** Permission denied or a transient failure: nothing is known about the record. */
        data object Unreadable : LinkLookup
    }

    sealed interface LinkResolution {
        /** Persisted identity wins, even when the session time was edited outside the record's window. */
        data class Use(val record: CandidateSession) : LinkResolution
        /** No link, a verified missing record, or a record owned by another session: normal window matching. */
        data object FallBackToWindow : LinkResolution
        /** Link kept; unknown right now. Do not read from or reassociate to another record. */
        data object KeepLinkUnresolved : LinkResolution
    }

    /** Apple (live main): a persisted link is fetched by id and is not replaced by a workout that merely
     *  overlaps an edited time. Only a verified absence frees the session for window matching. */
    fun resolveStoredLink(sessionId: String, storedRecordId: String?, lookup: LinkLookup, ownPackageName: String): LinkResolution {
        if (storedRecordId.isNullOrBlank()) return LinkResolution.FallBackToWindow
        return when (lookup) {
            LinkLookup.Unreadable -> LinkResolution.KeepLinkUnresolved
            LinkLookup.Gone -> LinkResolution.FallBackToWindow
            is LinkLookup.Found -> {
                val rec = lookup.record
                if (rec.id != storedRecordId) LinkResolution.KeepLinkUnresolved
                else if (rec.packageName == ownPackageName && rec.clientRecordId != null &&
                    rec.clientRecordId != HealthSessionLink.clientRecordId(sessionId)) LinkResolution.FallBackToWindow
                else LinkResolution.Use(rec)
            }
        }
    }

    /** Explicit app ownership cannot be guessed away from a coincident time window. */
    fun eligibleForSession(sessionId:String?,candidates:List<CandidateSession>,ownPackageName:String):List<CandidateSession> {
        val expected=sessionId?.let {HealthSessionLink.clientRecordId(it)}
        return candidates.filterNot {it.packageName==ownPackageName && it.clientRecordId!=null && it.clientRecordId!=expected}
    }

    /** Orden de decisión de syncWorkoutToHealth (HealthKitStore.finishWorkout
     *  iOS), con la ambigüedad excluida explícitamente ANTES de insertar:
     *  1) vínculo persistido válido (validStoredLink); 2) registro propio con
     *  el clientRecordId de la sesión (idempotencia); 3) una única sesión
     *  plausible: externa → se adopta sin escribir; propia → se reusa (iOS
     *  actualiza el registro existente; insertar crearía duplicado);
     *  Ambiguous → Skip; None → Insert. */
    fun resolveLink(
        sessionId: String,
        sessionStartMs: Long,
        sessionEndMs: Long,
        storedRecordId: String?,
        candidates: List<CandidateSession>,
        ownPackageName: String
    ): LinkDecision {
        validStoredLink(sessionId, sessionStartMs, sessionEndMs,
            storedRecordId, candidates, ownPackageName)
            ?.let { return LinkDecision.UseExisting(it.id) }
        val wantedClientId = HealthSessionLink.clientRecordId(sessionId)
        candidates.firstOrNull {
            it.packageName == ownPackageName && it.clientRecordId == wantedClientId
        }?.let { return LinkDecision.UseExisting(it.id) }
        // Explicit ownership of another Repera session cannot be overridden by a time overlap.
        val eligible=eligibleForSession(sessionId,candidates,ownPackageName)
        return when (val a = associate(
            sessionStartMs, sessionEndMs, eligible, ownPackageName)) {
            is Association.Matched -> LinkDecision.UseExisting(a.session.id)
            Association.Ambiguous -> LinkDecision.Skip
            Association.None -> LinkDecision.Insert
        }
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
