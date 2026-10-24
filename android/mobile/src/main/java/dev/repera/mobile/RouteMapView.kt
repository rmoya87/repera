package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import dev.repera.domain.WorkoutRoutePoint
import org.maplibre.android.MapLibre
import org.maplibre.android.camera.CameraUpdateFactory
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.geometry.LatLngBounds
import org.maplibre.android.maps.MapLibreMap
import org.maplibre.android.maps.MapView
import org.maplibre.android.style.expressions.Expression
import org.maplibre.android.style.layers.LineLayer
import org.maplibre.android.style.layers.PropertyFactory
import org.maplibre.android.style.sources.GeoJsonSource
import org.json.JSONObject

/**
 * Mapa nativo de la ruta GPS (paridad HealthWorkoutRouteMap iOS):
 * polilínea por segmentos coloreada por velocidad, punto verde de inicio y
 * rojo de fin, cámara ajustada a los bounds con margen 1.5×.
 *
 * Teselas: OpenFreeMap (sin key/cuenta/coste; atribución integrada del estilo
 * visible vía el botón de atribución de MapLibre, que queda habilitado).
 * Privacidad: los puntos de la ruta NUNCA salen del dispositivo — solo se
 * descargan teselas del área visible (bbox), no la ruta; los tests usan
 * coordenadas sintéticas.
 *
 * Degradado: si el estilo/teselas fallan (servicio caído, sin red), se
 * sustituye por una polilínea en Canvas con los mismos colores y se indica
 * «Mapa no disponible», nunca un hueco en blanco.
 */
@Composable
internal fun RouteMapView(
    points: List<WorkoutRoutePoint>,
    isInteractive: Boolean,
    modifier: Modifier = Modifier
) {
    var failed by remember { mutableStateOf(false) }
    if (failed) {
        RouteMapFallback(points, modifier)
        return
    }
    AndroidView(
        modifier = modifier.testTag("route_map"),
        factory = { context ->
            MapLibre.getInstance(context)
            MapView(context).apply {
                // El listener de fallo de carga vive en MapView (widget), no en
                // MapLibreMap (comprobado contra el AAR de MapLibre 13.7.1).
                addOnDidFailLoadingMapListener { failed = true }
                getMapAsync { map ->
                    map.uiSettings.apply {
                        isLogoEnabled = true
                        isAttributionEnabled = true
                        setAllGesturesEnabled(isInteractive)
                        isCompassEnabled = isInteractive
                    }
                    map.setStyle("https://tiles.openfreemap.org/styles/liberty") { style ->
                        runCatching { applyRoute(map, style, points) }
                            .onFailure { failed = true }
                    }
                }
            }
        }
    )
}

private fun applyRoute(map: MapLibreMap, style: org.maplibre.android.maps.Style,
                       points: List<WorkoutRoutePoint>) {
    val segments = RouteMapModel.segments(points)
    // Un GeoJSON por segmento con su color (paridad del stroke por segmento
    // de iOS); LineLayer por segmento mantiene el renderer simple y el número
    // de segmentos lo acota la propia grabación (1 punto ≈ 1 s de captura).
    segments.forEachIndexed { i, seg ->
        val coords = org.json.JSONArray()
            .put(org.json.JSONArray().put(seg.a.longitude).put(seg.a.latitude))
            .put(org.json.JSONArray().put(seg.b.longitude).put(seg.b.latitude))
        val feature = JSONObject()
            .put("type", "Feature")
            .put("properties", JSONObject().put("color",
                "#%06X".format(seg.argb and 0xFFFFFF)))
            .put("geometry", JSONObject()
                .put("type", "LineString")
                .put("coordinates", coords))
        val source = GeoJsonSource("route-src-$i",
            org.maplibre.geojson.Feature.fromJson(feature.toString()))
        style.addSource(source)
        style.addLayer(LineLayer("route-line-$i", "route-src-$i").withProperties(
            PropertyFactory.lineColor(Expression.get("color")),
            PropertyFactory.lineWidth(4f),
            PropertyFactory.lineCap("round")
        ))
    }
    // Inicio (acento) y fin (rojo), círculos con borde blanco como iOS.
    listOfNotNull(
        points.firstOrNull()?.let { it to "#2FA86B" },
        points.lastOrNull()?.takeIf { points.size > 1 }?.let { it to "#E5484D" }
    ).forEachIndexed { i, (point, color) ->
        val feature = JSONObject()
            .put("type", "Feature")
            .put("geometry", JSONObject()
                .put("type", "Point")
                .put("coordinates", org.json.JSONArray()
                    .put(point.longitude).put(point.latitude)))
        style.addSource(GeoJsonSource("route-pt-$i",
            org.maplibre.geojson.Feature.fromJson(feature.toString())))
        style.addLayer(org.maplibre.android.style.layers.CircleLayer(
            "route-pt-layer-$i", "route-pt-$i").withProperties(
            PropertyFactory.circleRadius(5f),
            PropertyFactory.circleColor(Expression.color(android.graphics.Color.parseColor(color))),
            PropertyFactory.circleStrokeWidth(2f),
            PropertyFactory.circleStrokeColor(Expression.color(android.graphics.Color.WHITE))
        ))
    }
    // Cámara: bounds con margen (iOS usa span ×1.5 con mínimo 0.008°).
    val builder = LatLngBounds.Builder()
    points.forEach { builder.include(LatLng(it.latitude, it.longitude)) }
    val bounds = builder.build()
    map.moveCamera(CameraUpdateFactory.newLatLngBounds(bounds, 64))
}

/** Degradado sin teselas: polilínea normalizada con los mismos colores. */
@Composable
private fun RouteMapFallback(points: List<WorkoutRoutePoint>, modifier: Modifier) {
    val segments = remember(points) { RouteMapModel.segments(points) }
    Box(modifier = modifier.testTag("route_map_fallback")) {
        Canvas(modifier = Modifier.fillMaxWidth().height(180.dp)) {
            if (points.size >= 2) {
                val minLat = points.minOf { it.latitude }
                val maxLat = points.maxOf { it.latitude }
                val minLon = points.minOf { it.longitude }
                val maxLon = points.maxOf { it.longitude }
                val spanLat = (maxLat - minLat).takeIf { it > 0 } ?: 1e-6
                val spanLon = (maxLon - minLon).takeIf { it > 0 } ?: 1e-6
                fun xy(p: WorkoutRoutePoint) = Offset(
                    (((p.longitude - minLon) / spanLon).toFloat()) * size.width,
                    (1f - ((p.latitude - minLat) / spanLat).toFloat()) * size.height)
                segments.forEach { seg ->
                    drawLine(Color(seg.argb), xy(seg.a), xy(seg.b), strokeWidth = 8f)
                }
            }
        }
        Text("Mapa no disponible", fontSize = 12.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.align(Alignment.BottomStart))
    }
}
