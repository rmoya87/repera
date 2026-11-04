package dev.repera.domain

import java.time.Instant
import java.time.format.DateTimeFormatter
import java.util.Locale

/** GPX 1.1 with no estimated/fabricated coordinates and no network access. */
object RouteGPXCodec {
    fun encode(points: List<WorkoutRoutePoint>): String? {
        val sorted = points.asSequence()
            .filter { it.isEstimated != true && it.latitude.isFinite() && it.longitude.isFinite() }
            .filter { it.latitude in -90.0..90.0 && it.longitude in -180.0..180.0 }
            .filter { it.recordedAtEpochMs > 0L }
            .sortedBy { it.recordedAtEpochMs }
            .toList()
        if (sorted.size < 2) return null

        fun format(value: Double) = String.format(Locale.US, "%.7f", value)
        return buildString {
            append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
            append("<gpx version=\"1.1\" creator=\"Repera\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n")
            append("  <trk><name>Recorrido Repera</name><trkseg>\n")
            var lastTime: Long? = null
            for (point in sorted) {
                val previous = lastTime
                if (previous != null && point.recordedAtEpochMs - previous > 30_000L)
                    append("  </trkseg><trkseg>\n")
                lastTime = point.recordedAtEpochMs
                append("    <trkpt lat=\"${format(point.latitude)}\" lon=\"${format(point.longitude)}\">")
                point.altitudeMeters?.takeIf(Double::isFinite)?.let {
                    append("<ele>${format(it)}</ele>")
                }
                append("<time>")
                append(DateTimeFormatter.ISO_INSTANT.format(Instant.ofEpochMilli(point.recordedAtEpochMs)))
                append("</time></trkpt>\n")
            }
            append("  </trkseg></trk>\n</gpx>\n")
        }
    }
}
