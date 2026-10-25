package dev.repera.domain

import kotlin.math.abs
import kotlin.math.max

/** Estado puro de LiveActivityRecorder Apple 5890215d. El proveedor GPS
 * valida una vez las muestras y el odómetro; esta capa NO suma distancias
 * otra vez. El servicio Android conserva una instancia fuera de la pantalla. */
class LiveActivityState {
    enum class Phase { IDLE, RECORDING, PAUSED, REVIEW }
    data class Snapshot(
        val sportID: String, val phase: Phase, val startedMillis: Long,
        val pausedMillis: Long?, val pausedSeconds: Double,
        val distanceMeters: Double, val points: List<WorkoutRoutePoint>,
        val savedMillis: Long, val selectedRouteID: String?,
        val splitsSeconds: List<Double> = emptyList(),
        val lastBoundarySeconds: Double = 0.0,
        val gpsSessionID: String
    )
    var phase = Phase.IDLE; private set
    var sport = LiveSport.RUNNING; private set
    var startedMillis: Long? = null; private set
    var finishedMillis: Long? = null; private set
    var pausedMillis: Long? = null; private set
    var pausedSeconds = 0.0; private set
    var distanceMeters = 0.0; private set
    var points: List<WorkoutRoutePoint> = emptyList(); private set
    var splitsSeconds: List<Double> = emptyList(); private set
    var selectedRouteID: String? = null; private set
    var gpsSessionID = ""; private set
    var currentSpeedMps: Double? = null; private set
    var elevationGainMeters = 0.0; private set
    var elevationLossMeters = 0.0; private set
    private var elevationReference: Double? = null
    private var lastBoundarySeconds = 0.0
    private var previousFixActiveSeconds: Double? = null
    val hasElevationSamples: Boolean get() = elevationReference != null

    fun choose(sport: LiveSport) {
        if (phase != Phase.IDLE) return
        this.sport = sport; selectedRouteID = null
    }
    fun selectRoute(id: String?) { if (phase == Phase.IDLE) selectedRouteID = id }
    fun start(nowMillis: Long, sessionID: String) {
        if (phase != Phase.IDLE) return
        clearMetrics()
        startedMillis = nowMillis; finishedMillis = null; pausedMillis = null
        pausedSeconds = 0.0; gpsSessionID = sessionID; phase = Phase.RECORDING
    }
    fun durationSeconds(nowMillis: Long): Double {
        val start = startedMillis ?: return 0.0
        val end = finishedMillis ?: nowMillis
        val currentPause = pausedMillis?.let { max(0.0, (end - it) / 1000.0) } ?: 0.0
        return max(0.0, (end - start) / 1000.0 - pausedSeconds - currentPause)
    }
    fun pause(nowMillis: Long) {
        if (phase != Phase.RECORDING) return
        pausedMillis = nowMillis; phase = Phase.PAUSED; currentSpeedMps = null
    }
    fun resume(nowMillis: Long) {
        if (phase != Phase.PAUSED) return
        pausedMillis?.let { pausedSeconds += max(0.0, (nowMillis - it) / 1000.0) }
        pausedMillis = null; previousFixActiveSeconds = null; phase = Phase.RECORDING
    }
    fun finish(nowMillis: Long) {
        if (phase != Phase.RECORDING && phase != Phase.PAUSED) return
        pausedMillis?.let { pausedSeconds += max(0.0, (nowMillis - it) / 1000.0) }
        pausedMillis = null; finishedMillis = nowMillis; phase = Phase.REVIEW; currentSpeedMps = null
    }
    /** Solo actualizaciones del odómetro ya filtrado; no aceptar regresiones,
     * NaN, ni sesiones antiguas que entreguen callbacks después de descartar. */
    fun receive(sessionID: String, point: WorkoutRoutePoint, totalDistanceMeters: Double): Boolean {
        if (phase != Phase.RECORDING || !sport.usesGPS || sessionID != gpsSessionID) return false
        if (!totalDistanceMeters.isFinite() || totalDistanceMeters < distanceMeters) return false
        val before = distanceMeters
        distanceMeters = totalDistanceMeters
        val active = durationSeconds(point.recordedAtEpochMs)
        if (distanceMeters > before) {
            val priorActive = previousFixActiveSeconds ?: active
            val segmentDistance = max(1.0, distanceMeters - before)
            val next = splitsSeconds.toMutableList()
            while (distanceMeters >= (next.size + 1) * 1000.0) {
                val boundary = (next.size + 1) * 1000.0
                val fraction = ((boundary - before) / segmentDistance).coerceIn(0.0, 1.0)
                val crossing = priorActive + fraction * max(0.0, active - priorActive)
                next.add(max(1.0, crossing - lastBoundarySeconds)); lastBoundarySeconds = crossing
            }
            splitsSeconds = next
        }
        previousFixActiveSeconds = active
        points = points + point
        currentSpeedMps = point.speedMps?.takeIf { it.isFinite() && it >= 0 }
        if (sport.tracksElevation && point.verticalAccuracyMeters?.let { it in 0.0..15.0 } == true)
            point.altitudeMeters?.let(::integrateElevation)
        return true
    }
    private fun integrateElevation(altitude: Double) {
        if (!altitude.isFinite() || altitude !in -500.0..9000.0) return
        elevationReference?.let { previous ->
            val delta = altitude - previous
            if (abs(delta) < 3 || abs(delta) > 120) return
            if (delta > 0) elevationGainMeters += delta else elevationLossMeters -= delta
        }
        elevationReference = altitude
    }
    fun snapshot(nowMillis: Long): Snapshot? = startedMillis?.takeIf { phase != Phase.IDLE }?.let {
        Snapshot(sport.id, phase, it, pausedMillis, pausedSeconds, distanceMeters,
            points.toList(), nowMillis, selectedRouteID, splitsSeconds.toList(), lastBoundarySeconds, gpsSessionID)
    }
    /** Restauración segura: siempre PAUSA, sin inventar tiempo/distancia en
     * la interrupción. Apple omite finishedAt en snapshot y hace lo mismo. */
    fun restore(snapshot: Snapshot): Boolean {
        val restored = LiveSport.byId(snapshot.sportID) ?: return false
        if (snapshot.phase == Phase.IDLE) return false
        clearMetrics(); sport = restored; phase = Phase.PAUSED
        startedMillis = snapshot.startedMillis; finishedMillis = null
        pausedMillis = snapshot.pausedMillis ?: snapshot.savedMillis
        pausedSeconds = snapshot.pausedSeconds; distanceMeters = snapshot.distanceMeters
        points = snapshot.points.toList(); splitsSeconds = snapshot.splitsSeconds.toList()
        lastBoundarySeconds = snapshot.lastBoundarySeconds; selectedRouteID = snapshot.selectedRouteID
        gpsSessionID = snapshot.gpsSessionID
        if (sport.tracksElevation) points.forEach { it.altitudeMeters?.let(::integrateElevation) }
        return true
    }
    val activeKilometer: Int get() = max(1, (distanceMeters / 1000).toInt() + 1)
    val activeKilometerMeters: Double get() = max(0.0, distanceMeters - (activeKilometer - 1) * 1000)
    fun currentSplitSeconds(nowMillis: Long): Double = max(0.0, durationSeconds(nowMillis) - lastBoundarySeconds)
    fun averageSpeedKmh(nowMillis: Long): Double? =
        if (sport.usesGPS && points.size >= 2 && durationSeconds(nowMillis) > 0)
            max(0.0, distanceMeters / durationSeconds(nowMillis) * 3.6) else null
    fun discard() {
        phase = Phase.IDLE; startedMillis = null; finishedMillis = null; pausedMillis = null
        pausedSeconds = 0.0; selectedRouteID = null; gpsSessionID = ""; clearMetrics()
    }
    private fun clearMetrics() {
        distanceMeters = 0.0; points = emptyList(); splitsSeconds = emptyList()
        elevationGainMeters = 0.0; elevationLossMeters = 0.0; elevationReference = null
        currentSpeedMps = null; lastBoundarySeconds = 0.0; previousFixActiveSeconds = null
    }
}
