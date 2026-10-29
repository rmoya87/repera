package dev.repera.mobile

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color as NativeColor
import android.graphics.Paint
import android.graphics.Path
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
import com.google.android.gms.maps.model.MarkerOptions
import com.google.android.gms.maps.model.PolylineOptions
import dev.repera.domain.AdaptiveRoutePace
import dev.repera.domain.WorkoutRoutePoint

/** Solo el estado comercial verificado habilita el proveedor premium. */
internal object AndroidMapProviderChoice {
    fun useGoogle(hasVerifiedPremiumAccess: Boolean, hasMapsKey: Boolean): Boolean =
        hasVerifiedPremiumAccess && hasMapsKey
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
    LaunchedEffect(view) {
        view.getMapAsync { ready ->
            ready.mapType = GoogleMap.MAP_TYPE_NORMAL
            ready.isBuildingsEnabled = true
            ready.uiSettings.apply {
                isCompassEnabled = isInteractive
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
    LaunchedEffect(map, points, plannedRoute, plannedPoints, waterSport, paceMode, userPosition, userHeadingDegrees) {
        val ready = map ?: return@LaunchedEffect
        ready.clear()
        if (plannedPoints.size >= 2) drawGoogleRoute(ready, plannedPoints, true, waterSport, paceMode, emptyList())
        drawGoogleRoute(ready, points, plannedRoute, waterSport, paceMode, plannedPoints)
        userPosition?.let { p ->
            ready.addMarker(MarkerOptions().position(LatLng(p.latitude, p.longitude))
                .anchor(0.5f, 0.5f).flat(true)
                .icon(BitmapDescriptorFactory.fromBitmap(directionBitmap()))
                .rotation((userHeadingDegrees ?: 0.0).toFloat())
                .zIndex(100f))
        }
        if (!controlsOverlay && cameraCenter == null) fitGoogleRoute(ready, points)
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
    LaunchedEffect(view, latitude, longitude) {
        view.getMapAsync { map ->
            map.mapType = GoogleMap.MAP_TYPE_NORMAL
            map.isBuildingsEnabled = true
            map.uiSettings.apply {
                isCompassEnabled = isInteractive
                isScrollGesturesEnabled = isInteractive
                isZoomGesturesEnabled = isInteractive
                isRotateGesturesEnabled = isInteractive
                isTiltGesturesEnabled = isInteractive
                isMapToolbarEnabled = false
            }
            map.clear()
            map.addMarker(MarkerOptions().position(LatLng(latitude, longitude))
                .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_RED)))
            map.setOnMapClickListener { click?.invoke() }
            map.setOnCameraIdleListener {
                val cp = map.cameraPosition
                idle?.invoke(cp.zoom.toDouble(), cp.target.latitude, cp.target.longitude)
            }
            map.setOnMapLoadedCallback { loaded?.invoke() }
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(LatLng(latitude, longitude), 15.5f))
        }
    }
}
