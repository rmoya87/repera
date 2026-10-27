package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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

/** Leyenda de escala de color por velocidad (Apple c04c7dd9): solo en recorridos
 *  ya guardados. Misma funcion cromatica que cada segmento del trazado; las 25
 *  muestras distribuidas compensan la curva de contraste pow 0.72. */
@Composable
internal fun RouteSpeedLegend(water: Boolean = false) {
    val colors = (0..24).map { i ->
        val position = i / 24.0
        Color(RouteMapModel.speedColor(position, 0.0, 1.0, water))
    }
    Column(modifier = Modifier.width(130.dp)) {
        Box(modifier = Modifier.fillMaxWidth().height(7.dp)
            .clip(RoundedCornerShape(3.5.dp))
            .background(androidx.compose.ui.graphics.Brush.linearGradient(colors))) {}
        Row(modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween) {
            Text("Lento", style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text("Rápido", style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

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
    /** Apple isWaterSport: water palette for the speed colors. */
    waterSport: Boolean = false,
    onMapRendered: (() -> Unit)? = null,
    navigationMode:Boolean = false,
    cameraCenter:WorkoutRoutePoint? = null,
    recenterToken:Int = 0,
    onCameraGesture:(()->Unit)? = null
) {
    var failed by remember { mutableStateOf(false) }
    val currentGesture by androidx.compose.runtime.rememberUpdatedState(onCameraGesture)
    val currentRendered by androidx.compose.runtime.rememberUpdatedState(onMapRendered)
    val currentPlanned by androidx.compose.runtime.rememberUpdatedState(plannedRoute)
    val currentPlan by androidx.compose.runtime.rememberUpdatedState(plannedPoints)
    val currentPoints by androidx.compose.runtime.rememberUpdatedState(points)
    var loadedMap by remember { mutableStateOf<MapLibreMap?>(null) }
    androidx.compose.runtime.LaunchedEffect(points, plannedRoute, plannedPoints, loadedMap) {
        val map = loadedMap ?: return@LaunchedEffect
        map.getStyle { style ->
            runCatching {
                style.removeLayer("route-line");style.removeSource("route-src")
                for (i in 0..1) {
                    style.removeLayer("route-pt-layer-$i");style.removeSource("route-pt-$i")
                }
                applyPlannedOverlay(style,plannedPoints)
                applyRoute(map, style, points, plannedRoute,fitCamera=!controlsOverlay || (cameraCenter==null && plannedRoute),water=waterSport)
            }.onFailure { failed = true }
        }
    }
    androidx.compose.runtime.LaunchedEffect(cameraCenter,navigationMode,recenterToken,loadedMap) {
        val map=loadedMap ?: return@LaunchedEffect
        val center=cameraCenter ?: return@LaunchedEffect
        val camera=LiveMapCamera.target(center,points,navigationMode)
        map.moveCamera(CameraUpdateFactory.newCameraPosition(org.maplibre.android.camera.CameraPosition.Builder()
            .target(LatLng(camera.latitude,camera.longitude)).zoom(camera.zoom)
            .bearing(camera.bearing).tilt(camera.pitch).build()))
    }
    if (failed) {
        RouteMapFallback(points, modifier, plannedRoute,plannedPoints,waterSport)
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
                // Map-level completion may fire only on initial load. Camera changes
                // need a fully-rendered FRAME, not another map-load completion.
                addOnDidFinishRenderingFrameListener { fully, _, _ -> if (fully) currentRendered?.invoke() }
                onCreate(null)
                // A newly mounted map can arrive after its owner is RESUMED.
                // Lifecycle events are not replayed to this new widget.
                if (lifecycleOwner.lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.STARTED)) onStart()
                if (lifecycleOwner.lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.RESUMED)) onResume()
                getMapAsync { map ->
                    map.addOnCameraMoveStartedListener { reason ->
                        if(reason==MapLibreMap.OnCameraMoveStartedListener.REASON_API_GESTURE) currentGesture?.invoke()
                    }
                    map.uiSettings.apply {
                        isLogoEnabled = true
                        isAttributionEnabled = true
                        if (controlsOverlay) {
                            // Keep legal attribution above bottom controls,
                            // not behind an opaque action panel.
                            val d = context.resources.displayMetrics.density
                            setLogoGravity(android.view.Gravity.TOP or android.view.Gravity.LEFT)
                            setAttributionGravity(android.view.Gravity.TOP or android.view.Gravity.LEFT)
                            setLogoMargins((8*d).toInt(),(250*d).toInt(),0,0)
                            setAttributionMargins((100*d).toInt(),(250*d).toInt(),0,0)
                        }
                        setAllGesturesEnabled(isInteractive)
                        isCompassEnabled = isInteractive
                    }
                    map.setStyle("https://tiles.openfreemap.org/styles/liberty") { style ->
                        runCatching { applyPlannedOverlay(style,currentPlan);applyRoute(map, style, currentPoints, currentPlanned,water=waterSport) }
                            .onFailure { failed = true }
                            .onSuccess { loadedMap = map;onStyleLoaded?.invoke() }
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
                       points: List<WorkoutRoutePoint>, plannedRoute: Boolean,fitCamera:Boolean = true,water:Boolean = false) {
    // Vertices enviados al mapa acotados, NUNCA los datos GPS grabados
    // (Apple f6f13169: maxVertices=450 con stride; evita presion de memoria
    // al abrir un mapa historico durante una grabacion activa).
    val rendered = if (!plannedRoute && points.size > 450) {
        val stride = Math.ceil((points.size - 1) / 449.0).toInt().coerceAtLeast(1)
        (points.indices step stride).map { points[it] }.let { l ->
            if (l.last() === points.last()) l else l + points.last()
        }
    } else points
    val segments = if (plannedRoute) rendered.zipWithNext().map { (a,b) ->
        RouteMapModel.Segment(a,b,0xFF0A84FF)
    } else RouteMapModel.segments(rendered,water)
    // Una colección y una capa: no crear miles de capas por cada muestra
    // ni reconstruir un árbol de estilos entero al llegar un punto GPS.
    val solid = segments.filter { !it.estimated }
    val dashed = segments.filter { it.estimated }
    fun featuresOf(list: List<RouteMapModel.Segment>) = list.map { seg ->
        val coords = org.json.JSONArray()
            .put(org.json.JSONArray().put(seg.a.longitude).put(seg.a.latitude))
            .put(org.json.JSONArray().put(seg.b.longitude).put(seg.b.latitude))
        org.maplibre.geojson.Feature.fromJson(JSONObject()
            .put("type", "Feature")
            .put("properties", JSONObject().put("color", "#%06X".format(seg.argb and 0xFFFFFF)))
            .put("geometry", JSONObject().put("type", "LineString").put("coordinates", coords)).toString())
    }
    if (solid.isNotEmpty() || dashed.isEmpty()) {
        style.addSource(GeoJsonSource("route-src", org.maplibre.geojson.FeatureCollection.fromFeatures(featuresOf(solid))))
        style.addLayer(LineLayer("route-line", "route-src").withProperties(
            PropertyFactory.lineColor(Expression.get("color")), PropertyFactory.lineWidth(4f),
            PropertyFactory.lineCap("round")))
    }
    if (dashed.isNotEmpty()) {
        // Tramos estimados: discontinuos, nunca como medicion GPS (Apple 9f62c49a).
        style.addSource(GeoJsonSource("route-src-est", org.maplibre.geojson.FeatureCollection.fromFeatures(featuresOf(dashed))))
        style.addLayer(LineLayer("route-line-est", "route-src-est").withProperties(
            PropertyFactory.lineColor(Expression.get("color")), PropertyFactory.lineWidth(4f),
            PropertyFactory.lineCap("round"),
            PropertyFactory.lineDasharray(arrayOf(2.0f, 2.0f))))
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
    val camera = RouteMapModel.camera(points)
    if (camera != null && fitCamera) {
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
private fun RouteMapFallback(points: List<WorkoutRoutePoint>, modifier: Modifier, plannedRoute: Boolean,
    plannedPoints:List<WorkoutRoutePoint> = emptyList(),water:Boolean = false) {
    val allPoints=points+plannedPoints
    val segments = remember(points, plannedRoute,plannedPoints,water) {
        val measured=if (plannedRoute) points.zipWithNext().map { (a,b) -> RouteMapModel.Segment(a,b,0xFF0A84FF) }
        else RouteMapModel.segments(points,water)
        plannedPoints.zipWithNext().map { (a,b) -> RouteMapModel.Segment(a,b,0xFF0A84FF) }+measured
    }
    Box(modifier = modifier.testTag("route_map_fallback")) {
        Canvas(modifier = Modifier.fillMaxWidth().height(180.dp)) {
            if (allPoints.size >= 2) {
                val minLat = allPoints.minOf { it.latitude }
                val maxLat = allPoints.maxOf { it.latitude }
                val minLon = allPoints.minOf { it.longitude }
                val maxLon = allPoints.maxOf { it.longitude }
                val spanLat = (maxLat - minLat).takeIf { it > 0 } ?: 1e-6
                val spanLon = (maxLon - minLon).takeIf { it > 0 } ?: 1e-6
                fun xy(p: WorkoutRoutePoint) = Offset(
                    (((p.longitude - minLon) / spanLon).toFloat()) * size.width,
                    (1f - ((p.latitude - minLat) / spanLat).toFloat()) * size.height)
                segments.forEach { seg ->
                    drawLine(Color(seg.argb), xy(seg.a), xy(seg.b), strokeWidth = 8f,
                        pathEffect = if (seg.estimated) androidx.compose.ui.graphics.PathEffect
                            .dashPathEffect(floatArrayOf(16f, 16f)) else null)
                }
            }
        }
        Text("Mapa no disponible · © OpenStreetMap contributors · © OpenFreeMap",
            fontSize = 11.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.align(Alignment.BottomStart))
    }
}
