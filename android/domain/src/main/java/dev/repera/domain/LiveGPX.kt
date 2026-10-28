package dev.repera.domain

import org.xml.sax.Attributes
import org.xml.sax.helpers.DefaultHandler
import javax.xml.parsers.SAXParserFactory
import java.io.ByteArrayInputStream
import java.time.Instant
import kotlin.math.*

/** GPX offline: trkpt/rtept, namespaces, fecha opcional, límite Apple 20.000.
 * Entidades externas/DTD prohibidas: importar un archivo no abre red ni archivos. */
object LiveGPXParser {
    fun parse(data: ByteArray, nowMillis: () -> Long = System::currentTimeMillis): List<WorkoutRoutePoint> {
        val points = mutableListOf<WorkoutRoutePoint>()
        var active: WorkoutRoutePoint? = null
        var readingTime = false
        val text = StringBuilder()
        val factory = SAXParserFactory.newInstance().apply {
            isNamespaceAware = true
            setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)
            setFeature("http://xml.org/sax/features/external-general-entities", false)
            setFeature("http://xml.org/sax/features/external-parameter-entities", false)
        }
        val handler = object : DefaultHandler() {
            override fun startElement(uri: String?, localName: String?, qName: String?, attributes: Attributes) {
                when (localName?.ifBlank { null } ?: qName?.substringAfterLast(':')) {
                    "trkpt", "rtept" -> {
                        active = null
                        val lat = attributes.getValue("lat")?.toDoubleOrNull()
                        val lon = attributes.getValue("lon")?.toDoubleOrNull()
                        if (lat != null && lon != null && lat in -90.0..90.0 && lon in -180.0..180.0)
                            active = WorkoutRoutePoint(points.size, lat, lon, nowMillis())
                    }
                    "time" -> if (active != null) { readingTime = true; text.setLength(0) }
                }
            }
            override fun characters(ch: CharArray, start: Int, length: Int) {
                if (readingTime) text.append(ch, start, length)
            }
            override fun endElement(uri: String?, localName: String?, qName: String?) {
                when (localName?.ifBlank { null } ?: qName?.substringAfterLast(':')) {
                    "time" -> {
                        val epoch = runCatching { Instant.parse(text.toString().trim()).toEpochMilli() }.getOrNull()
                        if (epoch != null) active = active?.copy(recordedAtEpochMs = epoch)
                        readingTime = false
                    }
                    "trkpt", "rtept" -> { active?.let { if (points.size < 20_000) points.add(it) }; active = null }
                }
            }
        }
        try { factory.newSAXParser().parse(ByteArrayInputStream(data), handler) }
        catch (e: Exception) { throw IllegalArgumentException("El archivo GPX está dañado o no tiene un formato válido.", e) }
        require(points.size >= 2) { "Este GPX no contiene al menos dos puntos de recorrido." }
        return points
    }
}

/** Indicaciones orientativas de polilínea, no navegación vial ni calles. */
object LiveGPXTurnDetection {
    data class Turn(val routeIndex: Int, val metersAlongRoute: Double, val angleDegrees: Double) {
        /** Spoken wording (Apple live main): lowercase verb phrase, "cambia de sentido" above 145 degrees. */
        val spokenDirection: String get() = when {
            abs(angleDegrees) > 145 -> "cambia de sentido"
            angleDegrees > 0 -> "gira a la derecha"
            else -> "gira a la izquierda"
        }
        val instruction: String get() = when {
            abs(angleDegrees) > 145 -> "Cambio de sentido"
            angleDegrees > 0 -> "Gira a la derecha"
            else -> "Gira a la izquierda"
        }
    }
    fun distance(a: WorkoutRoutePoint, b: WorkoutRoutePoint): Double =
        CardioRouteAnalysis.routeDistanceMeters(listOf(a, b).map {
            CardioRouteAnalysis.Sample(0.0, it.latitude, it.longitude)
        })

    private fun bearing(a: WorkoutRoutePoint, b: WorkoutRoutePoint): Double {
        val lat1 = Math.toRadians(a.latitude); val lat2 = Math.toRadians(b.latitude)
        val delta = Math.toRadians(b.longitude - a.longitude)
        return Math.toDegrees(atan2(sin(delta) * cos(lat2),
            cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(delta)))
    }
    fun cumulative(points: List<WorkoutRoutePoint>): List<Double> {
        if (points.isEmpty()) return emptyList()
        val result = mutableListOf(0.0)
        for (i in 1 until points.size) result.add(result.last() + distance(points[i - 1], points[i]))
        return result
    }
    fun detect(points: List<WorkoutRoutePoint>, along: List<Double> = cumulative(points)): List<Turn> {
        if (points.size < 3 || along.size != points.size) return emptyList()
        val turns = mutableListOf<Turn>()
        val step = max(1, points.size / 1200)
        for (index in 1 until points.size - 1 step step) {
            val at = along[index]
            var before = index - 1; var after = index + 1
            while (before > 0 && at - along[before] < 30) before--
            while (after < points.size - 1 && along[after] - at < 30) after++
            if (at - along[before] < 20 || along[after] - at < 20) continue
            val delta = (bearing(points[index], points[after]) - bearing(points[before], points[index]) + 540) % 360 - 180
            if (abs(delta) < 52) continue
            val turn = Turn(index, at, delta)
            val last = turns.lastOrNull()
            if (last != null && at - last.metersAlongRoute < 55) {
                if (abs(delta) > abs(last.angleDegrees)) turns[turns.lastIndex] = turn
            } else turns.add(turn)
        }
        return turns
    }
}
