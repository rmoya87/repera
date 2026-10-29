package dev.repera.mobile

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color as NativeColor
import android.graphics.Paint
import android.graphics.Path
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.Dash
import com.google.android.gms.maps.model.Gap
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.LatLngBounds
import com.google.android.gms.maps.model.MapColorScheme
import com.google.android.gms.maps.model.Marker
import com.google.android.gms.maps.model.MarkerOptions
import com.google.android.gms.maps.model.PolylineOptions
import dev.repera.domain.AdaptiveRoutePace
import dev.repera.domain.WorkoutRoutePoint

/** Aplica esquema claro/oscuro de Google Maps al instante (R8 / Ramón). */
internal fun GoogleMap.applyReperaColorScheme(dark: Boolean) {
    mapColorScheme = if (dark) MapColorScheme.DARK else MapColorScheme.LIGHT
}

/** Google Maps se habilita con la clave restringida presente, en Gratis y Pro.
 * La navegacion 3D sigue reservada a Pro (FeatureAccessPolicy.canUse3DNavigation). */
internal object AndroidMapProviderChoice {
    fun useGoogle(hasMapsKey: Boolean): Boolean = hasMapsKey
}

@Composable
private fun rememberManagedGoogleMapView(): MapView {
    val context = LocalContext.current
    val owner = LocalLifecycleOwner.current
    val view = remember(context) { MapView(context) }
    DisposableEffect(owner, view) {
        view.onCreate(null)
        if (owner.lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) view.onStart()
        if (owner.lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED)) view.onResume()
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START -> view.onStart()
                Lifecycle.Event.ON_RESUME -> view.onResume()
                Lifecycle.Event.ON_PAUSE -> view.onPause()
                Lifecycle.Event.ON_STOP -> view.onStop()
                else -> Unit
            }
        }
        owner.lifecycle.addObserver(observer)
        onDispose {
            owner.lifecycle.removeObserver(observer)
            if (owner.lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED)) view.onPause()
            if (owner.lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) view.onStop()
            view.onDestroy()
        }
    }
    return view
}

/** Google solo pinta el mapa: la grabación GPS, los GPX y los avisos son de Repera. */
@Composable
internal fun GoogleRouteMapView(
    points: List<WorkoutRoutePoint>,
    modifier: Modifier,
    isInteractive: Boolean,
    plannedRoute: Boolean,
    plannedPoints: List<WorkoutRoutePoint>,
    controlsOverlay: Boolean,
    waterSport: Boolean,
    paceMode: AdaptiveRoutePace.Mode,
    navigationMode: Boolean,
    cameraCenter: WorkoutRoutePoint?,
    cameraTrace: List<WorkoutRoutePoint>,
    userPosition: WorkoutRoutePoint?,
    userHeadingDegrees: Double?,
    recenterToken: Int,
    onCameraGesture: (() -> Unit)?,
    onStyleLoaded: (() -> Unit)?,
    onMapRendered: (() -> Unit)?
) {
    val view = rememberManagedGoogleMapView()
    var map by remember(view) { mutableStateOf<GoogleMap?>(null) }
    val gestureCallback by rememberUpdatedState(onCameraGesture)
    val renderedCallback by rememberUpdatedState(onMapRendered)
    val loadedCallback by rememberUpdatedState(onStyleLoaded)
    AndroidView(factory = { view }, modifier = modifier.testTag("route_map"))
    val darkTheme = isSystemInDarkTheme()
    LaunchedEffect(view) {
        view.getMapAsync { ready ->
            ready.mapType = GoogleMap.MAP_TYPE_NORMAL
            ready.applyReperaColorScheme(darkTheme)
            ready.isBuildingsEnabled = true
            if (controlsOverlay) {
                // Logo y avisos legales visibles sobre los controles inferiores.
                val bottom = (view.resources.displayMetrics.density * 140).toInt()
                ready.setPadding(0, 0, 0, bottom)
            }
            ready.uiSettings.apply {
                // R7 P1: sin brújula nativa sobre la status bar.
                isCompassEnabled = false
                isRotateGesturesEnabled = isInteractive
                isScrollGesturesEnabled = isInteractive
                isTiltGesturesEnabled = isInteractive
                isZoomGesturesEnabled = isInteractive
                isMapToolbarEnabled = false
                isMyLocationButtonEnabled = false
            }
            var movingByUser = false
            ready.setOnCameraMoveStartedListener { reason ->
                movingByUser = reason == GoogleMap.OnCameraMoveStartedListener.REASON_GESTURE
                if (movingByUser) gestureCallback?.invoke()
            }
            ready.setOnCameraMoveListener { if (movingByUser) gestureCallback?.invoke() }
            ready.setOnCameraIdleListener {
                if (movingByUser) gestureCallback?.invoke()
                movingByUser = false
                renderedCallback?.invoke()
            }
            ready.setOnMapLoadedCallback { loadedCallback?.invoke(); renderedCallback?.invoke() }
            map = ready
        }
    }
    // R8: tema claro/oscuro al instante (sin recrear MapView).
    LaunchedEffect(map, darkTheme) {
        map?.applyReperaColorScheme(darkTheme)
    }
    // 2D no permite inclinar con los dedos: la perspectiva solo se activa
    // desde el modo 3D de Repera Pro, incluso con Google como proveedor.
    LaunchedEffect(map, navigationMode, isInteractive) {
        map?.uiSettings?.setTiltGesturesEnabled(isInteractive && navigationMode)
    }
    var positionMarker by remember(view) { mutableStateOf<Marker?>(null) }
    // La ruta se recalcula al recibir puntos, no con cada cambio del rumbo.
    LaunchedEffect(map, points, plannedRoute, plannedPoints, waterSport, paceMode) {
        val ready = map ?: return@LaunchedEffect
        ready.clear()
        positionMarker = null
        if (plannedPoints.size >= 2) drawGoogleRoute(ready, plannedPoints, true, waterSport, paceMode, emptyList())
        drawGoogleRoute(ready, points, plannedRoute, waterSport, paceMode, plannedPoints)
        if (!controlsOverlay && cameraCenter == null) {
            view.post { if (map === ready) fitGoogleRoute(ready, points) }
        }
    }
    LaunchedEffect(map, points, plannedRoute, plannedPoints, userPosition, userHeadingDegrees) {
        val ready = map ?: return@LaunchedEffect
        val p = userPosition
        if (p == null) {
            positionMarker?.remove()
            positionMarker = null
        } else {
            val coordinate = LatLng(p.latitude, p.longitude)
            val existing = positionMarker
            if (existing == null) {
                positionMarker = ready.addMarker(MarkerOptions().position(coordinate)
                    .anchor(0.5f, 0.5f).flat(true)
                    .icon(BitmapDescriptorFactory.fromBitmap(directionBitmap()))
                    .rotation((userHeadingDegrees ?: 0.0).toFloat())
                    .zIndex(100f))
            } else {
                existing.position = coordinate
                existing.rotation = (userHeadingDegrees ?: 0.0).toFloat()
            }
        }
    }
    LaunchedEffect(map, cameraCenter, cameraTrace, navigationMode, userHeadingDegrees, recenterToken) {
        val ready = map ?: return@LaunchedEffect
        val center = cameraCenter ?: return@LaunchedEffect
        val target = LiveMapCamera.target(center, cameraTrace, navigationMode, userHeadingDegrees)
        ready.animateCamera(CameraUpdateFactory.newCameraPosition(CameraPosition.Builder()
            .target(LatLng(target.latitude, target.longitude))
            .zoom(target.zoom.toFloat())
            .bearing(target.bearing.toFloat())
            .tilt(target.pitch.toFloat()).build()), 550, null)
    }
}

private fun drawGoogleRoute(
    map: GoogleMap, points: List<WorkoutRoutePoint>, isPlanned: Boolean,
    water: Boolean, mode: AdaptiveRoutePace.Mode, reference: List<WorkoutRoutePoint>
) {
    if (points.size < 2) return
    val displayed = if (!isPlanned && points.size > 450) {
        val stride = kotlin.math.ceil((points.size - 1) / 449.0).toInt().coerceAtLeast(1)
        (points.indices step stride).map { points[it] }.let { sample ->
            if (sample.last() === points.last()) sample else sample + points.last()
        }
    } else points
    val segments = if (isPlanned) displayed.zipWithNext().map { (a, b) ->
        RouteMapModel.Segment(a, b, 0xFF0A84FF)
    } else RouteMapModel.segments(displayed, water, reference = reference, mode = mode)
    segments.forEach { segment ->
        val opts = PolylineOptions()
            .add(LatLng(segment.a.latitude, segment.a.longitude),
                LatLng(segment.b.latitude, segment.b.longitude))
            .width(if (isPlanned) 6f else 5f)
            .color(segment.argb.toInt()).zIndex(if (isPlanned) 1f else 2f)
        if (segment.estimated) opts.pattern(listOf(Dash(14f), Gap(8f)))
        map.addPolyline(opts)
    }
    displayed.firstOrNull()?.let {
        map.addMarker(MarkerOptions().position(LatLng(it.latitude, it.longitude))
            .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_GREEN)))
    }
    displayed.lastOrNull()?.takeIf { displayed.size > 1 }?.let {
        map.addMarker(MarkerOptions().position(LatLng(it.latitude, it.longitude))
            .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_RED)))
    }
}

private fun fitGoogleRoute(map: GoogleMap, points: List<WorkoutRoutePoint>) {
    if (points.isEmpty()) return
    if (points.size == 1) {
        map.moveCamera(CameraUpdateFactory.newLatLngZoom(
            LatLng(points.first().latitude, points.first().longitude), 15f))
        return
    }
    val builder = LatLngBounds.Builder()
    points.forEach { builder.include(LatLng(it.latitude, it.longitude)) }
    runCatching { map.moveCamera(CameraUpdateFactory.newLatLngBounds(builder.build(), 42)) }
}

private fun directionBitmap(): Bitmap {
    val bitmap = Bitmap.createBitmap(72, 72, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    val path = Path().apply {
        moveTo(36f, 4f)
        lineTo(63f, 65f)
        lineTo(36f, 53f)
        lineTo(9f, 65f)
        close()
    }
    val outline = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = NativeColor.WHITE
        style = Paint.Style.STROKE
        strokeWidth = 8f
        strokeJoin = Paint.Join.ROUND
    }
    canvas.drawPath(path, outline)
    outline.style = Paint.Style.FILL
    outline.color = NativeColor.rgb(47, 168, 107)
    canvas.drawPath(path, outline)
    return bitmap
}

/** Pin preview/edición de ubicaciones: mismo contrato que el mapa Gratis. */
@Composable
internal fun GooglePlacePinMap(
    latitude: Double, longitude: Double, isInteractive: Boolean,
    modifier: Modifier, onStyleLoaded: (() -> Unit)?,
    onMapClick: (() -> Unit)?,
    onCameraIdle: ((Double, Double, Double) -> Unit)?
) {
    val view = rememberManagedGoogleMapView()
    val click by rememberUpdatedState(onMapClick)
    val idle by rememberUpdatedState(onCameraIdle)
    val loaded by rememberUpdatedState(onStyleLoaded)
    AndroidView(factory = { view }, modifier = modifier.testTag("place_pin_map"))
    var pinMap by remember(view) { mutableStateOf<GoogleMap?>(null) }
    var pinMarker by remember(view) { mutableStateOf<Marker?>(null) }
    val darkTheme = isSystemInDarkTheme()
    LaunchedEffect(view) {
        view.getMapAsync { map ->
            map.mapType = GoogleMap.MAP_TYPE_NORMAL
            map.applyReperaColorScheme(darkTheme)
            map.isBuildingsEnabled = true
            // Evitar que la ficha de confirmación tape el logo de Google.
            map.setPadding(0, 0, 0, (view.resources.displayMetrics.density * 72).toInt())
            map.uiSettings.apply {
                isCompassEnabled = false
                isScrollGesturesEnabled = isInteractive
                isZoomGesturesEnabled = isInteractive
                isRotateGesturesEnabled = isInteractive
                isTiltGesturesEnabled = isInteractive
                isMapToolbarEnabled = false
            }
            map.setOnMapClickListener { click?.invoke() }
            map.setOnCameraIdleListener {
                val cp = map.cameraPosition
                idle?.invoke(cp.zoom.toDouble(), cp.target.latitude, cp.target.longitude)
            }
            map.setOnMapLoadedCallback { loaded?.invoke() }
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(LatLng(latitude, longitude), 15.5f))
            pinMap = map
        }
    }
    LaunchedEffect(pinMap, darkTheme) {
        pinMap?.applyReperaColorScheme(darkTheme)
    }
    LaunchedEffect(pinMap, latitude, longitude) {
        val map = pinMap ?: return@LaunchedEffect
        val target = LatLng(latitude, longitude)
        val marker = pinMarker
        if (marker == null) {
            pinMarker = map.addMarker(MarkerOptions().position(target)
                .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_RED)))
        } else marker.position = target
        // Al navegar por gestos, el centro del mapa ya coincide con el pin;
        // no forzar zoom ni recentrado en cada OnCameraIdle.
        val center = map.cameraPosition.target
        if (kotlin.math.abs(center.latitude - latitude) > 0.00005 ||
            kotlin.math.abs(center.longitude - longitude) > 0.00005) {
            map.animateCamera(CameraUpdateFactory.newLatLng(target))
        }
    }
}
