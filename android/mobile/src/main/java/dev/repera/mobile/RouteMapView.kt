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
 * Privacidad: el array de puntos de la ruta NO se envía a ningún servicio,
 * pero las peticiones de teselas revelan al proveedor la ZONA visible
 * (bounding box) y la IP del dispositivo. No se registran coordenadas en
 * logs ni analytics, y los tests usan coordenadas sintéticas.
 *
 * Degradado: si el estilo/teselas fallan (servicio caído, sin red), se
 * sustituye por una polilínea en Canvas con los mismos colores y se indica
 * «Mapa no disponible», nunca un hueco en blanco.
 */
@Composable
internal fun RouteMapView(
    points: List<WorkoutRoutePoint>,
    isInteractive: Boolean,
    modifier: Modifier = Modifier,
    /** Solo verificación: avisa cuando el estilo cargó y la ruta se pintó. */
    onStyleLoaded: (() -> Unit)? = null,
    plannedRoute: Boolean = false,
    controlsOverlay: Boolean = false,
    plannedPoints: List<WorkoutRoutePoint> = emptyList(),
    onMapRendered: (() -> Unit)? = null
) {
    var failed by remember { mutableStateOf(false) }
    val currentRendered by androidx.compose.runtime.rememberUpdatedState(onMapRendered)
    val currentPlanned by androidx.compose.runtime.rememberUpdatedState(plannedRoute)
    val currentPlan by androidx.compose.runtime.rememberUpdatedState(plannedPoints)
    val currentPoints by androidx.compose.runtime.rememberUpdatedState(points)
    var loadedMap by remember { mutableStateOf<MapLibreMap?>(null) }
    var renderedPoints by remember { mutableStateOf<List<WorkoutRoutePoint>>(emptyList()) }
    androidx.compose.runtime.LaunchedEffect(points, plannedRoute, plannedPoints, loadedMap) {
        val map = loadedMap ?: return@LaunchedEffect
        if (points == renderedPoints && !plannedRoute && plannedPoints.isEmpty()) return@LaunchedEffect
        map.getStyle { style ->
            runCatching {
                style.removeLayer("route-line");style.removeSource("route-src")
                for (i in 0..1) {
                    style.removeLayer("route-pt-layer-$i");style.removeSource("route-pt-$i")
                }
                applyPlannedOverlay(style,plannedPoints)
                applyRoute(map, style, points, plannedRoute);renderedPoints = points.toList()
            }.onFailure { failed = true }
        }
    }
    if (failed) {
        RouteMapFallback(points, modifier, plannedRoute)
        return
    }
    // Lifecycle MapLibre: onStart/Resume/... atados al ciclo del composable
    // (sin ello el mapa pierde GL o gasta batería en segundo plano).
    val lifecycleOwner = androidx.compose.ui.platform.LocalLifecycleOwner.current
    var mapView by remember { mutableStateOf<MapView?>(null) }
    androidx.compose.runtime.DisposableEffect(lifecycleOwner) {
        val observer = androidx.lifecycle.LifecycleEventObserver { _, event ->
            when (event) {
                androidx.lifecycle.Lifecycle.Event.ON_START -> mapView?.onStart()
                androidx.lifecycle.Lifecycle.Event.ON_RESUME -> mapView?.onResume()
                androidx.lifecycle.Lifecycle.Event.ON_PAUSE -> mapView?.onPause()
                androidx.lifecycle.Lifecycle.Event.ON_STOP -> mapView?.onStop()
                androidx.lifecycle.Lifecycle.Event.ON_DESTROY -> mapView?.onDestroy()
                else -> {}
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
            mapView?.onDestroy()
            mapView = null
        }
    }
    AndroidView(
        modifier = modifier.testTag("route_map"),
        factory = { context ->
            MapLibre.getInstance(context)
            MapView(context, org.maplibre.android.maps.MapLibreMapOptions.createFromAttributes(context)
                .textureMode(true)).also { mapView = it }.apply {
                // El listener de fallo de carga vive en MapView (widget), no en
                // MapLibreMap (comprobado contra el AAR de MapLibre 13.7.1).
                addOnDidFailLoadingMapListener { failed = true }
                addOnDidFinishRenderingMapListener { fully -> if (fully) currentRendered?.invoke() }
                onCreate(null)
                // A newly mounted map can arrive after its owner is RESUMED.
                // Lifecycle events are not replayed to this new widget.
                if (lifecycleOwner.lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.STARTED)) onStart()
                if (lifecycleOwner.lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.RESUMED)) onResume()
                getMapAsync { map ->
                    map.uiSettings.apply {
                        isLogoEnabled = true
                        isAttributionEnabled = true
                        if (controlsOverlay) {
                            // Keep legal attribution above bottom controls,
                            // not behind an opaque action panel.
                            val d = context.resources.displayMetrics.density
                            setLogoGravity(android.view.Gravity.TOP or android.view.Gravity.LEFT)
                            setAttributionGravity(android.view.Gravity.TOP or android.view.Gravity.LEFT)
                            setLogoMargins((8*d).toInt(),(180*d).toInt(),0,0)
                            setAttributionMargins((100*d).toInt(),(180*d).toInt(),0,0)
                        }
                        setAllGesturesEnabled(isInteractive)
                        isCompassEnabled = isInteractive
                    }
                    map.setStyle("https://tiles.openfreemap.org/styles/liberty") { style ->
                        runCatching { applyPlannedOverlay(style,currentPlan);applyRoute(map, style, currentPoints, currentPlanned) }
                            .onFailure { failed = true }
                            .onSuccess { renderedPoints = currentPoints.toList();loadedMap = map;onStyleLoaded?.invoke() }
                    }
                }
            }
        }
    )
}

/** Chosen GPX remains visible beneath the measured trace after recording begins. */
private fun applyPlannedOverlay(style:org.maplibre.android.maps.Style,points:List<WorkoutRoutePoint>) {
    style.removeLayer("planned-route-line");style.removeSource("planned-route-src")
    if(points.size<2) return
    val coordinates=org.json.JSONArray()
    points.forEach { coordinates.put(org.json.JSONArray().put(it.longitude).put(it.latitude)) }
    val feature=org.maplibre.geojson.Feature.fromJson(JSONObject().put("type","Feature")
        .put("geometry",JSONObject().put("type","LineString").put("coordinates",coordinates)).toString())
    style.addSource(GeoJsonSource("planned-route-src",feature))
    style.addLayer(LineLayer("planned-route-line","planned-route-src").withProperties(
        PropertyFactory.lineColor(android.graphics.Color.rgb(10,132,255)),PropertyFactory.lineWidth(4f),
        PropertyFactory.lineOpacity(0.65f),PropertyFactory.lineCap("round")))
}

private fun applyRoute(map: MapLibreMap, style: org.maplibre.android.maps.Style,
                       points: List<WorkoutRoutePoint>, plannedRoute: Boolean) {
    val segments = if (plannedRoute) points.zipWithNext().map { (a,b) ->
        RouteMapModel.Segment(a,b,0xFF0A84FF)
    } else RouteMapModel.segments(points)
    // Una colección y una capa: no crear miles de capas por cada muestra
    // ni reconstruir un árbol de estilos entero al llegar un punto GPS.
    val features = segments.map { seg ->
        val coords = org.json.JSONArray()
            .put(org.json.JSONArray().put(seg.a.longitude).put(seg.a.latitude))
            .put(org.json.JSONArray().put(seg.b.longitude).put(seg.b.latitude))
        org.maplibre.geojson.Feature.fromJson(JSONObject()
            .put("type", "Feature")
            .put("properties", JSONObject().put("color", "#%06X".format(seg.argb and 0xFFFFFF)))
            .put("geometry", JSONObject().put("type", "LineString").put("coordinates", coords)).toString())
    }
    style.addSource(GeoJsonSource("route-src", org.maplibre.geojson.FeatureCollection.fromFeatures(features)))
    style.addLayer(LineLayer("route-line", "route-src").withProperties(
        PropertyFactory.lineColor(Expression.get("color")), PropertyFactory.lineWidth(4f),
        PropertyFactory.lineCap("round")))
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
    val camera = RouteMapModel.camera(points)
    if (camera != null) {
        val bounds = LatLngBounds.from(
            (camera.centerLat + camera.spanLat / 2).coerceAtMost(85.0),
            (camera.centerLon + camera.spanLon / 2).coerceAtMost(180.0),
            (camera.centerLat - camera.spanLat / 2).coerceAtLeast(-85.0),
            (camera.centerLon - camera.spanLon / 2).coerceAtLeast(-180.0))
        map.moveCamera(CameraUpdateFactory.newLatLngBounds(bounds, 32))
    }

}

/** Degradado sin teselas: polilínea normalizada con los mismos colores. */
@Composable
private fun RouteMapFallback(points: List<WorkoutRoutePoint>, modifier: Modifier, plannedRoute: Boolean) {
    val segments = remember(points, plannedRoute) {
        if (plannedRoute) points.zipWithNext().map { (a,b) -> RouteMapModel.Segment(a,b,0xFF0A84FF) }
        else RouteMapModel.segments(points)
    }
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
        Text("Mapa no disponible · © OpenStreetMap contributors · © OpenFreeMap",
            fontSize = 11.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.align(Alignment.BottomStart))
    }
}
