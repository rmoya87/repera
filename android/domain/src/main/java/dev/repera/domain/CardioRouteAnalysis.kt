package dev.repera.domain

import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

/** Análisis de recorridos GPS realizado exclusivamente en el dispositivo.
 *  No se serializa en el espejo de entrenamientos de Supabase.
 *  Port 1:1 de CardioRouteAnalysis.swift (iOS). */
object CardioRouteAnalysis {

    data class Sample(
        val epochSeconds: Double,
        val latitude: Double,
        val longitude: Double,
        val altitudeMeters: Double? = null
    )

    data class HeartSample(val epochSeconds: Double, val bpm: Double)

    data class ProfilePoint(
        val id: Int,
        val epochSeconds: Double,
        val distanceKm: Double,
        val altitudeMeters: Double
    )

    data class Split(
        val kilometer: Int,
        val seconds: Double,
        val paceSecondsPerKm: Double,
        val speedKmh: Double,
        val averageBpm: Double? = null
    )

    data class Result(
        val profile: List<ProfilePoint>,
        val splits: List<Split>,
        val distanceMeters: Double,
        val ascentMeters: Double,
        val descentMeters: Double
    )

    fun analyze(route: List<Sample>, heart: List<HeartSample> = emptyList()): Result {
        val samples = route
            .filter {
                it.latitude.isFinite() && it.longitude.isFinite() &&
                    it.latitude in -90.0..90.0 && it.longitude in -180.0..180.0
            }
            .sortedBy { it.epochSeconds }

        val profile = mutableListOf<ProfilePoint>()
        var distance = 0.0
        var ascent = 0.0
        var descent = 0.0
        val crossings = mutableListOf<Double>()
        var previous: Sample? = null
        var previousAltitude: Double? = null
        val hr = heart.filter { it.bpm.isFinite() && it.bpm in 30.0..240.0 }
            .sortedBy { it.epochSeconds }

        for (sample in samples) {
            val last = previous
            if (last == null) {
                previous = sample
                validAltitude(sample.altitudeMeters)?.let { altitude ->
                    previousAltitude = altitude
                    profile.add(ProfilePoint(0, sample.epochSeconds, 0.0, altitude))
                }
                continue
            }
            val dt = sample.epochSeconds - last.epochSeconds
            // Ignorar puntos duplicados, saltos GPS y velocidades imposibles.
            if (dt <= 0) continue
            val meters = haversine(last, sample)
            if (!meters.isFinite() || meters < 0 || meters / dt > 35) continue

            val priorDistance = distance
            distance += meters
            while ((crossings.size + 1) * 1000.0 <= distance && meters > 0) {
                val goal = (crossings.size + 1) * 1000.0
                val fraction = (goal - priorDistance) / meters
                crossings.add(last.epochSeconds + dt * fraction)
            }
            validAltitude(sample.altitudeMeters)?.let { altitude ->
                val earlier = previousAltitude
                if (earlier != null) {
                    // Referencia estable: acumula también ascensos graduales de
                    // 1-2 m, sin sumar oscilaciones insignificantes punto a punto.
                    val delta = altitude - earlier
                    if (abs(delta) >= 3 && abs(delta) / max(meters, 1.0) <= 1.5) {
                        if (delta > 0) ascent += delta else descent -= delta
                        previousAltitude = altitude
                    }
                } else {
                    previousAltitude = altitude
                }
                profile.add(ProfilePoint(profile.size, sample.epochSeconds,
                    distance / 1000, altitude))
            }
            previous = sample
        }

        val splits = mutableListOf<Split>()
        samples.firstOrNull()?.let { first ->
            var splitStart = first.epochSeconds
            crossings.forEachIndexed { index, end ->
                val duration = end - splitStart
                if (duration > 0) {
                    val bpm = hr.filter { it.epochSeconds >= splitStart && it.epochSeconds <= end }
                        .map { it.bpm }
                    splits.add(Split(
                        kilometer = index + 1,
                        seconds = duration,
                        paceSecondsPerKm = duration,
                        speedKmh = 3600 / duration,
                        averageBpm = if (bpm.size >= 2) bpm.average() else null
                    ))
                    splitStart = end
                }
            }
        }
        return Result(profile, splits, distance, ascent, descent)
    }

    private fun validAltitude(meters: Double?): Double? =
        meters?.takeIf { it.isFinite() && it in -500.0..9000.0 }

    private fun haversine(a: Sample, b: Sample): Double {
        val rad = PI / 180
        val p1 = a.latitude * rad
        val p2 = b.latitude * rad
        val dPhi = (b.latitude - a.latitude) * rad
        val dLon = (b.longitude - a.longitude) * rad
        val h = sin(dPhi / 2).pow(2) + cos(p1) * cos(p2) * sin(dLon / 2).pow(2)
        return 6_371_000 * 2 * atan2(sqrt(max(0.0, h)), sqrt(max(0.0, 1 - h)))
    }
}
