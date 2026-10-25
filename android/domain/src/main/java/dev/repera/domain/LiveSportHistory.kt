package dev.repera.domain

/**
 * Datos del histórico de deportes En vivo (LiveSportsCatalogView /
 * LiveSportHistoryView / LiveRouteEvolutionView de Apple, referencia
 * 5890215d). Los deportes NO son ejercicios del catálogo: su fuente de
 * verdad son las sesiones En vivo. Nunca se fabrican kcal, pulso ni
 * distancia: solo se muestran métricas medidas.
 */
object LiveSportHistory {

    /** Sesión En vivo terminada, adaptada desde el snapshot JSON en mobile. */
    data class LiveSession(
        val id: String,
        val title: String,
        val sportID: String,
        val startedEpochMillis: Long?,
        val finishedEpochMillis: Long?,
        val activeDurationSeconds: Double?,
        val recordedDistanceMeters: Double?,
        val averageHeartRateBpm: Double?,
        val activeEnergyKcal: Double?,
        val liveRouteID: String? = null
    )

    data class SportSummary(
        val sport: LiveSport,
        val activityCount: Int,
        val totalDurationSeconds: Double,
        val totalKilometers: Double,
        val measuredEnergyKcal: Double?,
        val measuredHeartRateBpm: Double?
    )

    /** LiveSportStatsFormat.duration: h:mm:ss si >= 1 h, si no mm:ss. */
    fun formatDuration(seconds: Double): String {
        val s = maxOf(0, seconds.toInt())
        return if (s >= 3600)
            "%d:%02d:%02d".format(s / 3600, (s / 60) % 60, s % 60)
        else
            "%02d:%02d".format(s / 60, s % 60)
    }

    /** Resumen por deporte: solo sesiones terminadas del deporte dado. */
    fun summary(sport: LiveSport, sessions: List<LiveSession>): SportSummary {
        val own = sessionsOf(sport, sessions)
        val energy = own.mapNotNull { it.activeEnergyKcal }.filter { it > 0 }
        val heart = own.mapNotNull { it.averageHeartRateBpm }.filter { it > 0 }
        return SportSummary(
            sport = sport,
            activityCount = own.size,
            totalDurationSeconds = own.sumOf { maxOf(0.0, it.activeDurationSeconds ?: 0.0) },
            totalKilometers = own.sumOf { maxOf(0.0, it.recordedDistanceMeters ?: 0.0) } / 1000.0,
            measuredEnergyKcal = if (energy.isEmpty()) null else energy.sum(),
            measuredHeartRateBpm = if (heart.isEmpty()) null else heart.sum() / heart.size
        )
    }

    /** "N actividades · X km" (GPS) o "N actividades · h:mm:ss". */
    fun activitySummaryLine(sport: LiveSport, sessions: List<LiveSession>): String {
        val own = sessionsOf(sport, sessions)
        return if (sport.usesGPS) {
            val km = own.sumOf { maxOf(0.0, it.recordedDistanceMeters ?: 0.0) } / 1000.0
            "${own.size} actividades · %.1f km".format(km)
        } else {
            val total = own.sumOf { maxOf(0.0, it.activeDurationSeconds ?: 0.0) }
            "${own.size} actividades · ${formatDuration(total)}"
        }
    }

    /** Deportes con al menos una actividad terminada (picker de Deportes). */
    fun sportsWithActivity(sessions: List<LiveSession>): List<LiveSport> =
        LiveSport.entries.filter { sport -> sessionsOf(sport, sessions).isNotEmpty() }

    /** Solo sesiones En vivo terminadas del deporte, recientes primero. */
    fun sessionsOf(sport: LiveSport, sessions: List<LiveSession>): List<LiveSession> =
        sessions.filter {
            it.sportID == sport.id && it.finishedEpochMillis != null
        }.sortedByDescending { it.startedEpochMillis ?: Long.MIN_VALUE }

    /**
     * Intentos comparables de una ruta (LiveRouteEvolutionView.eligibleAttempts):
     * solo tiempos completos, con distancia GPS dentro del 20 % del recorrido.
     * No convertir una salida cortada a mitad en un récord personal.
     * Si la ruta no supera 0,2 km, entra cualquier intento con distancia > 0.
     */
    fun eligibleAttempts(
        attempts: List<LiveSession>,
        plannedDistanceKm: Double
    ): List<LiveSession> {
        if (plannedDistanceKm <= 0.2)
            return attempts.filter { (it.recordedDistanceMeters ?: 0.0) > 0 }
        return attempts.filter {
            val actualKm = maxOf(0.0, it.recordedDistanceMeters ?: 0.0) / 1000.0
            actualKm >= plannedDistanceKm * 0.8 && actualKm <= plannedDistanceKm * 1.2
        }
    }

    /** Valor de la gráfica de evolución: duración (min), ritmo (min/km) o
     *  velocidad (km/h) según la métrica elegida y el deporte. */
    fun evolutionValue(
        session: LiveSession, metric: EvolutionMetric, sport: LiveSport
    ): Double? {
        if (session.startedEpochMillis == null) return null
        val duration = session.activeDurationSeconds?.takeIf { it.isFinite() && it > 0 } ?: return null
        val km = maxOf(0.0, session.recordedDistanceMeters ?: 0.0) / 1000.0
        if (!km.isFinite() || km <= 0) return null
        return when (metric) {
            EvolutionMetric.DURATION -> duration / 60.0
            EvolutionMetric.PACE ->
                if (duration <= 0 || km <= 0) null
                else if (sport.displaysSpeed) km / (duration / 3600.0)
                else duration / 60.0 / km
            EvolutionMetric.DISTANCE -> if (km > 0) km else null
        }
    }

    enum class EvolutionMetric(val title: String) {
        DURATION("Tiempo"), PACE("Ritmo / velocidad"), DISTANCE("Distancia")
    }
}
