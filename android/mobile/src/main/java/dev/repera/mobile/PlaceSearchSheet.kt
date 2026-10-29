package dev.repera.mobile

import androidx.compose.foundation.layout.imePadding

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material.icons.Icons
import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Looper
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.MyLocation
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Place
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.core.content.ContextCompat
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.compose.ui.window.DialogWindowProvider
import androidx.core.view.WindowInsetsControllerCompat
import dev.repera.domain.PlaceSearchPolicy
import dev.repera.domain.WorkoutLocationPin
import kotlinx.coroutines.delay
import org.maplibre.android.MapLibre
import org.maplibre.android.camera.CameraUpdateFactory
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.maps.MapView
import org.maplibre.android.style.layers.CircleLayer
import org.maplibre.android.style.layers.PropertyFactory
import org.maplibre.android.style.sources.GeoJsonSource
import org.maplibre.geojson.Point

private const val PIN_SOURCE = "place-pin-source"
private const val PIN_LAYER = "place-pin-layer"

/** Mapa no interactivo con un único pin (preview de la fila y confirmación).
 *  Paridad WorkoutLocationPinMap iOS; teselas OpenFreeMap como RouteMapView. */
@Composable
internal fun PlacePinMap(
    latitude: Double,
    longitude: Double,
    isInteractive: Boolean,
    modifier: Modifier = Modifier,
    /** Solo verificación: avisa cuando el estilo del mapa terminó de cargar. */
    onStyleLoaded: (() -> Unit)? = null,
    /** iOS: tocar el mapa cierra la búsqueda presentada (dismissSearch). */
    onMapClick: (() -> Unit)? = null,
    /** Solo verificación: cámara en reposo tras cada gesto (zoom, lat, lon). */
    onCameraIdle: ((Double, Double, Double) -> Unit)? = null
) {
    val hasPremiumAccess = dev.repera.mobile.monetization.LocalSubscriptions.current?.isPro == true
    if (AndroidMapProviderChoice.useGoogle(hasPremiumAccess, BuildConfig.GOOGLE_MAPS_API_KEY.isNotBlank()) &&
        com.google.android.gms.common.GoogleApiAvailability.getInstance()
            .isGooglePlayServicesAvailable(androidx.compose.ui.platform.LocalContext.current) ==
        com.google.android.gms.common.ConnectionResult.SUCCESS) {
        GooglePlacePinMap(latitude, longitude, isInteractive, modifier,
            onStyleLoaded, onMapClick, onCameraIdle)
        return
    }
    val lifecycleOwner = androidx.compose.ui.platform.LocalLifecycleOwner.current
    var mapView by remember { mutableStateOf<MapView?>(null) }
    DisposableEffect(lifecycleOwner) {
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
        // testTagsAsResourceId: expone el tag como resource-id para que
        // UiAutomator (tests) pueda localizar el nodo; sin efecto en UI.
        modifier = modifier.semantics { testTagsAsResourceId = true }
            .testTag("place_pin_map"),
        factory = { context ->
            MapLibre.getInstance(context)
            // TextureView participa en la composición del Dialog; evita que una
            // superficie GL separada tape la barra de confirmación (API30).
            MapView(context, org.maplibre.android.maps.MapLibreMapOptions.createFromAttributes(context)
                .textureMode(true)).also { mapView = it }.apply {
                onCreate(null)
                if (onMapClick != null) {
                    // Tap a nivel de vista, NO listener MapLibre: getMapAsync
                    // es asíncrono y un toque temprano (mapa aún no entregado)
                    // se perdía en silencio. Devuelve siempre false: el pan /
                    // zoom del mapa sigue llegando intacto a MapLibre.
                    var downX = 0f
                    var downY = 0f
                    var downAt = 0L
                    val slop = android.view.ViewConfiguration.get(context).scaledTouchSlop
                    setOnTouchListener { _, ev ->
                        when (ev.actionMasked) {
                            android.view.MotionEvent.ACTION_DOWN -> {
                                downX = ev.x; downY = ev.y; downAt = ev.eventTime
                            }
                            android.view.MotionEvent.ACTION_UP -> {
                                val quick = ev.eventTime - downAt <=
                                    android.view.ViewConfiguration.getTapTimeout() * 2
                                val still = kotlin.math.abs(ev.x - downX) <= slop &&
                                    kotlin.math.abs(ev.y - downY) <= slop
                                if (quick && still) onMapClick.invoke()
                            }
                        }
                        false
                    }
                }
                getMapAsync { map ->
                    if (onCameraIdle != null) {
                        map.addOnCameraIdleListener {
                            val pos = map.cameraPosition
                            onCameraIdle.invoke(pos.zoom,
                                pos.target?.latitude ?: 0.0,
                                pos.target?.longitude ?: 0.0)
                        }
                    }
                    map.uiSettings.apply {
                        isLogoEnabled = true
                        isAttributionEnabled = true
                        setAllGesturesEnabled(isInteractive)
                        isCompassEnabled = isInteractive
                    }
                    val dark = (context.resources.configuration.uiMode and
                        android.content.res.Configuration.UI_MODE_NIGHT_MASK) ==
                        android.content.res.Configuration.UI_MODE_NIGHT_YES
                    map.setStyle(ReperaMapAppearance.styleUrl(dark)) { style ->
                        ReperaMapAppearance.apply(style,dark,navigation3D=false)
                        val point = Point.fromLngLat(longitude, latitude)
                        style.addSource(GeoJsonSource(PIN_SOURCE, point))
                        style.addLayer(
                            CircleLayer(PIN_LAYER, PIN_SOURCE).withProperties(
                                PropertyFactory.circleRadius(7f),
                                PropertyFactory.circleColor(android.graphics.Color.parseColor("#E2543E")),
                                PropertyFactory.circleStrokeWidth(2.5f),
                                PropertyFactory.circleStrokeColor(android.graphics.Color.WHITE)
                            )
                        )
                        map.moveCamera(CameraUpdateFactory.newLatLngZoom(
                            LatLng(latitude, longitude), 15.5))
                        onStyleLoaded?.invoke()
                    }
                }
            }
        }
    )
}

/** Fila «lugar del entreno»: sin pin → CTA «Añadir lugar»; con pin → mapa
 *  full-bleed en card (sin padding) y chip del lugar sobre el mapa. */
@Composable
fun WorkoutPlacePickerRow(
    pin: WorkoutLocationPin?,
    accountId: String,
    onPinChange: (WorkoutLocationPin?) -> Unit,
    modifier: Modifier = Modifier,
    /** Solo verificación: avisa cuando el estilo del preview terminó de cargar. */
    onMapStyleLoaded: (() -> Unit)? = null,
    /** Historial solo lectura: mapa+chip sin abrir buscador. */
    readOnly: Boolean = false
) {
    var showSearch by remember { mutableStateOf(false) }
    Column(modifier = modifier.fillMaxWidth()) {
        if (pin == null) {
            if (!readOnly) Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .clickable { showSearch = true }
                    .padding(vertical = 4.dp)
                    .testTag("place_picker_row")
            ) {
                Icon(
                    imageVector = Icons.Outlined.Place,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(32.dp)
                )
                Spacer(Modifier.width(12.dp))
                Text(
                    text = "Añadir lugar",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.weight(1f)
                )
                Icon(
                    imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        } else {
            // Paridad iOS: 220 dp, chip abajo con nombre + categoría + icono.
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(220.dp)
                    .clip(RoundedCornerShape(16.dp))
                    .then(if (readOnly) Modifier else Modifier.clickable { showSearch = true })
                    .testTag("place_picker_map")
            ) {
                PlacePinMap(pin.latitude, pin.longitude, isInteractive = false,
                    modifier = Modifier.fillMaxSize(), onStyleLoaded = onMapStyleLoaded)
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    color = MaterialTheme.colorScheme.surface.copy(alpha = 0.92f),
                    tonalElevation = 2.dp,
                    shadowElevation = 2.dp,
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(horizontal = 12.dp, vertical = 12.dp)
                        .fillMaxWidth()
                        .testTag("place_picker_chip")
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp)
                    ) {
                        Column(Modifier.weight(1f)) {
                            Text(
                                pin.name?.takeIf { it.isNotBlank() } ?: "Lugar en el mapa",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onSurface,
                                maxLines = 2
                            )
                            pin.pointOfInterestCategory?.takeIf { it.isNotBlank() }?.let { cat ->
                                Text(
                                    cat,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    maxLines = 1
                                )
                            }
                        }
                        Spacer(Modifier.width(12.dp))
                        Icon(
                            Icons.Outlined.LocationOn,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(22.dp)
                        )
                    }
                }
            }
        }
    }
    if (showSearch) {
        PlaceSearchSheet(
            initialPin = pin,
            accountId = accountId,
            onSelect = { onPinChange(it) },
            onDismiss = { showSearch = false }
        )
    }
}

/** Hoja de búsqueda de lugar (paridad PlaceSearchSheet iOS): mapa browse,
 *  panel de resultados/recientes bajo el buscador, y mapa de confirmación
 *  con panel inferior, papelera (quitar) y check (guardar). */
@Composable
fun PlaceSearchSheet(
    initialPin: WorkoutLocationPin?,
    accountId: String,
    onSelect: (WorkoutLocationPin?) -> Unit,
    onDismiss: () -> Unit,
    /** Solo verificación: proveedor simulado. Producción siempre usa el compuesto. */
    providerOverride: PlaceSearchProvider? = null,
    /** Solo verificación: cámara del mapa en reposo (zoom, lat, lon). */
    onMapCameraIdle: ((Double, Double, Double) -> Unit)? = null
) {
    val context = LocalContext.current
    val focusManager = androidx.compose.ui.platform.LocalFocusManager.current
    val keyboard = androidx.compose.ui.platform.LocalSoftwareKeyboardController.current
    val scope = rememberCoroutineScope()
    val composite = remember { CompositePlaceSearchProvider(PhotonPlaceSearchProvider(), GeocoderPlaceSearchProvider(context)) }
    val provider = providerOverride ?: composite
    val recentStore = remember { RecentPlacesStore(context, accountId) }
    var query by remember { mutableStateOf("") }
    var results by remember { mutableStateOf<List<PlaceSearchResult>>(emptyList()) }
    var isResolving by remember { mutableStateOf(false) }
    var resolveError by remember { mutableStateOf<String?>(null) }
    var limitedNotice by remember { mutableStateOf(false) }
    var pending by remember { mutableStateOf(initialPin?.let {
        PlaceSearchResult(
            name = it.name ?: "Lugar",
            latitude = it.latitude,
            longitude = it.longitude,
            providerId = it.mapItemIdentifier ?: "",
            featureName = it.name
        )
    }) }
    var recents by remember { mutableStateOf(recentStore.load()) }
    var searchFocused by remember { mutableStateOf(false) }
    // GPS del usuario para centrar mapa + sesgo/cercanía (R4 #25/#26).
    var userLatLon by remember { mutableStateOf<Pair<Double, Double>?>(null) }
    var locating by remember { mutableStateOf(false) }

    suspend fun resolveUserLocation(): Pair<Double, Double>? {
        val granted = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(
                context, Manifest.permission.ACCESS_COARSE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        if (!granted) return null
        val mgr = context.getSystemService(LocationManager::class.java) ?: return null
        val last = listOf(
            LocationManager.FUSED_PROVIDER,
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER
        ).mapNotNull { runCatching { mgr.getLastKnownLocation(it) }.getOrNull() }
            .minByOrNull { System.currentTimeMillis() - it.time }
        if (last != null && System.currentTimeMillis() - last.time < 120_000) {
            return last.latitude to last.longitude
        }
        return suspendCancellableCoroutine { cont ->
            var finished = false
            lateinit var listener: LocationListener
            fun finish(loc: Location?) {
                if (finished) return
                finished = true
                runCatching { mgr.removeUpdates(listener) }
                if (cont.isActive) cont.resume(loc?.let { it.latitude to it.longitude })
            }
            listener = LocationListener { location -> finish(location) }
            try {
                val enabled = mgr.getProviders(true)
                val providerName = listOf(
                    LocationManager.FUSED_PROVIDER,
                    LocationManager.GPS_PROVIDER,
                    LocationManager.NETWORK_PROVIDER
                ).firstOrNull { it in enabled }
                if (providerName == null) finish(null)
                else mgr.requestSingleUpdate(providerName, listener, Looper.getMainLooper())
            } catch (_: SecurityException) {
                finish(null)
            } catch (_: IllegalArgumentException) {
                finish(null)
            }
            cont.invokeOnCancellation { finish(null) }
        }
    }

    fun recenterOnUser() {
        locating = true
        scope.launch {
            val fix = resolveUserLocation()
            if (fix != null) userLatLon = fix
            locating = false
        }
    }

    val locationPermission = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { grants ->
        if (grants.values.any { it }) recenterOnUser()
    }

    LaunchedEffect(Unit) {
        val fix = resolveUserLocation()
        if (fix != null) userLatLon = fix
    }

    val isTyping = query.isNotBlank()
    // iOS: showsConfirmMap = pending != null && !isTyping && !isSearchPresented
    // (mutuamente excluyente con el panel de búsqueda).
    val showsConfirmMap = pending != null && !isTyping && !searchFocused

    // R5 P1-6: al mover el mapa en browse se actualiza el pin pendiente.
    val handleCameraIdle: (Double, Double, Double) -> Unit = { zoom, lat, lon ->
        onMapCameraIdle?.invoke(zoom, lat, lon)
        if (!showsConfirmMap) {
            pending = PlaceSearchResult(
                name = "Lugar en el mapa",
                latitude = lat,
                longitude = lon,
                providerId = "map:%.5f,%.5f".format(java.util.Locale.US, lat, lon),
                featureName = "Lugar en el mapa"
            )
        }
    }

    // Política de dominio: mínimo de caracteres + pausa, NO por tecla.
    // Sesgo ±~0,25° (~25 km) alrededor del GPS (paridad setRegion iOS).
    LaunchedEffect(query, userLatLon) {
        if (!PlaceSearchPolicy.shouldSearch(query)) {
            results = emptyList()
            isResolving = false
            return@LaunchedEffect
        }
        delay(PlaceSearchPolicy.DEBOUNCE_MS)
        isResolving = true
        resolveError = null
        val bias = userLatLon
        val delta = 0.25
        val raw = runCatching {
            provider.search(
                query.trim(),
                biasMinLat = bias?.let { it.first - delta },
                biasMinLon = bias?.let { it.second - delta },
                biasMaxLat = bias?.let { it.first + delta },
                biasMaxLon = bias?.let { it.second + delta }
            )
        }.getOrElse {
            resolveError = "No se pudo buscar el lugar."
            emptyList()
        }
        results = if (bias != null) {
            raw.sortedBy { haversineKm(bias.first, bias.second, it.latitude, it.longitude) }
        } else raw
        limitedNotice = (provider as? CompositePlaceSearchProvider)?.establishmentsUnavailable == true
        isResolving = false
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        // Edge-to-edge (targetSdk 37): el Dialog de pantalla completa dibuja
        // bajo las barras del sistema; el contenido va fuera de ellas y los
        // iconos de la barra en oscuro sobre la superficie clara.
        val dialogView = LocalView.current
        LaunchedEffect(Unit) {
            (dialogView.parent as? DialogWindowProvider)?.window?.let { w ->
                // Impedir que adjustPan desplace la ventana completa y saque
                // del marco la cabecera y la acción de confirmar.
                w.setSoftInputMode(android.view.WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING)
                WindowInsetsControllerCompat(w, dialogView).apply {
                    isAppearanceLightStatusBars = true
                    isAppearanceLightNavigationBars = true
                }
            }
        }
        LaunchedEffect(showsConfirmMap) {
            if (showsConfirmMap) {
                // Usar el token del Dialog, no el del controlador de la Activity.
                dialogView.clearFocus()
                (dialogView.context.getSystemService(android.content.Context.INPUT_METHOD_SERVICE)
                    as? android.view.inputmethod.InputMethodManager)
                    ?.hideSoftInputFromWindow(dialogView.windowToken, 0)
            }
        }
        Surface(modifier = Modifier.fillMaxSize()
            .statusBarsPadding().navigationBarsPadding().imePadding()) {
            // iOS: mapa a sangre + card glass flotante arriba + chip confirmar abajo.
            Box(Modifier.fillMaxSize()) {
                val p = pending
                if (p != null && !isTyping) {
                    // Mapa del lugar pendiente: MISMO composable en modo
                    // confirmar y con la búsqueda presentada (iOS mantiene el
                    // mapa y solo superpone/oculta el panel), así la vista GL
                    // no se recrea al presentar/cerrar la búsqueda y tocarlo
                    // la cierra (dismissSearch iOS).
                    PlacePinMap(p.latitude, p.longitude, isInteractive = true,
                        modifier = Modifier.fillMaxSize(),
                        onCameraIdle = handleCameraIdle,
                        onMapClick = {
                            searchFocused = false
                            focusManager.clearFocus(force = true)
                        })
                } else {
                    // Browse map (browseMap iOS): con un lugar pendiente se
                    // centra en su pin (Marker iOS); si no, en el pin inicial o
                    // en el lugar más reciente. Así, con la búsqueda
                    // presentada, el mapa sigue visible y tocarlo la cierra
                    // (dismissSearch iOS).
                    // iOS browseMap: siempre hay mapa a sangre (nunca solo texto).
                    // Prioridad: pin → reciente → GPS usuario → Madrid (fallback).
                    val center = pending?.let { it.latitude to it.longitude }
                        ?: initialPin?.let { it.latitude to it.longitude }
                        ?: recents.firstOrNull()?.let { it.latitude to it.longitude }
                        ?: userLatLon
                        ?: (40.4168 to -3.7038)
                    // key: remonta al llegar el GPS para centrar (PlacePinMap
                    // solo mueve cámara al cargar el estilo).
                    androidx.compose.runtime.key(center.first, center.second) {
                        PlacePinMap(center.first, center.second, isInteractive = true,
                            modifier = Modifier.fillMaxSize(),
                            onCameraIdle = handleCameraIdle,
                            onMapClick = {
                                searchFocused = false
                                focusManager.clearFocus(force = true)
                            })
                    }
                }

                // Card glass flotante (paridad iOS / compare4/52).
                Surface(
                    shape = RoundedCornerShape(22.dp),
                    color = MaterialTheme.colorScheme.surface.copy(alpha = 0.92f),
                    tonalElevation = 2.dp,
                    shadowElevation = 4.dp,
                    modifier = Modifier
                        .align(Alignment.TopCenter)
                        .padding(horizontal = 12.dp, vertical = 12.dp)
                        .fillMaxWidth()
                ) {
                    Column(Modifier.fillMaxWidth()) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 4.dp, vertical = 4.dp)
                        ) {
                            if (showsConfirmMap) {
                                IconButton(
                                    onClick = { onSelect(null); onDismiss() },
                                    modifier = Modifier
                                        .size(44.dp)
                                        .background(
                                            MaterialTheme.colorScheme.surfaceVariant,
                                            CircleShape
                                        )
                                        .testTag("place_clear")
                                ) {
                                    Icon(Icons.Outlined.Delete, contentDescription = "Quitar lugar")
                                }
                            } else {
                                IconButton(
                                    onClick = onDismiss,
                                    modifier = Modifier
                                        .size(44.dp)
                                        .background(
                                            MaterialTheme.colorScheme.surfaceVariant,
                                            CircleShape
                                        )
                                        .testTag("place_close")
                                ) {
                                    Icon(Icons.Outlined.Close, contentDescription = "Cerrar")
                                }
                            }
                            Text(
                                text = if (showsConfirmMap) "Lugar" else "Buscar lugar",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.weight(1f)
                            )
                            if (!showsConfirmMap) {
                                IconButton(
                                    onClick = {
                                        val fine = ContextCompat.checkSelfPermission(
                                            context, Manifest.permission.ACCESS_FINE_LOCATION
                                        ) == PackageManager.PERMISSION_GRANTED
                                        val coarse = ContextCompat.checkSelfPermission(
                                            context, Manifest.permission.ACCESS_COARSE_LOCATION
                                        ) == PackageManager.PERMISSION_GRANTED
                                        if (fine || coarse) recenterOnUser()
                                        else locationPermission.launch(
                                            arrayOf(
                                                Manifest.permission.ACCESS_FINE_LOCATION,
                                                Manifest.permission.ACCESS_COARSE_LOCATION
                                            )
                                        )
                                    },
                                    enabled = !locating,
                                    modifier = Modifier
                                        .size(44.dp)
                                        .background(
                                            MaterialTheme.colorScheme.surfaceVariant,
                                            CircleShape
                                        )
                                        .testTag("place_my_location")
                                ) {
                                    Icon(
                                        Icons.Outlined.MyLocation,
                                        contentDescription = "Centrar en mi ubicación"
                                    )
                                }
                            }
                            if (showsConfirmMap) {
                                IconButton(
                                    onClick = {
                                        val sel = pending ?: return@IconButton
                                        val pin = sel.toPin().copy(recordedAtEpochMs =
                                            System.currentTimeMillis())
                                        recentStore.remember(pin)
                                        onSelect(pin)
                                        onDismiss()
                                    },
                                    modifier = Modifier
                                        .size(44.dp)
                                        .background(
                                            MaterialTheme.colorScheme.surfaceVariant,
                                            CircleShape
                                        )
                                        .testTag("place_confirm")
                                ) {
                                    Icon(Icons.Outlined.Check, contentDescription = "Guardar lugar")
                                }
                            }
                        }
                        // iOS .searchable: tocar el campo PRESENTA la búsqueda. La
                        // interacción de press lo garantiza aunque el evento de foco
                        // no llegue (foco visual retenido tras clearFocus en emulador).
                        val fieldInteraction = remember {
                            androidx.compose.foundation.interaction.MutableInteractionSource()
                        }
                        LaunchedEffect(fieldInteraction) {
                            fieldInteraction.interactions.collect {
                                if (it is androidx.compose.foundation.interaction.PressInteraction.Press) {
                                    searchFocused = true
                                }
                            }
                        }
                        // Cápsula: Search + campo sin borde (paridad iOS).
                        Surface(
                            shape = RoundedCornerShape(50),
                            color = MaterialTheme.colorScheme.surfaceVariant,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 12.dp, vertical = 4.dp)
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp)
                            ) {
                                Icon(
                                    Icons.Outlined.Search,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                    modifier = Modifier.size(20.dp)
                                )
                                Spacer(Modifier.width(8.dp))
                                BasicTextField(
                                    value = query,
                                    onValueChange = { query = it },
                                    interactionSource = fieldInteraction,
                                    singleLine = true,
                                    textStyle = MaterialTheme.typography.bodyLarge.copy(
                                        color = MaterialTheme.colorScheme.onSurface
                                    ),
                                    cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
                                    modifier = Modifier
                                        .weight(1f)
                                        .onFocusChanged { searchFocused = it.isFocused }
                                        .testTag("place_query"),
                                    decorationBox = { inner ->
                                        Box {
                                            if (query.isEmpty()) {
                                                Text(
                                                    // Prompt iOS (.searchable): "Buscar otro sitio…"
                                                    // también en la primera búsqueda.
                                                    "Buscar otro sitio…",
                                                    style = MaterialTheme.typography.bodyLarge,
                                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                                )
                                            }
                                            inner()
                                        }
                                    }
                                )
                            }
                        }
                        if (isResolving) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.padding(16.dp)
                            ) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(18.dp),
                                    strokeWidth = 2.dp
                                )
                                Spacer(Modifier.width(10.dp))
                                Text(
                                    "Buscando…",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                        if (limitedNotice && !isResolving && PlaceSearchPolicy.shouldSearch(query)) {
                            Text(
                                "La búsqueda de establecimientos no está disponible ahora: " +
                                    "solo se muestran direcciones. Un resultado vacío no significa que no exista; " +
                                    "puedes colocar el pin en el mapa.",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier
                                    .padding(horizontal = 16.dp, vertical = 8.dp)
                                    .testTag("place_limited_notice")
                            )
                        }
                        if (PlaceSearchPolicy.shouldSearch(query)) {
                            // Los geocodificadores con datos OSM deben acreditar OpenStreetMap
                            // (osmfoundation.org/wiki/Licence/Attribution_Guidelines).
                            Text(
                                "Datos de lugares © OpenStreetMap contributors",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier
                                    .padding(horizontal = 16.dp, vertical = 2.dp)
                                    .testTag("place_osm_attribution")
                            )
                        }
                        resolveError?.let {
                            Text(
                                it,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.error,
                                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                            )
                        }
                        val showPanel = isTyping || (searchFocused && !isTyping)
                        if (showPanel) {
                            HorizontalDivider()
                            // Altura al contenido (máx 280): no forzar panel vacío.
                            LazyColumn(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .wrapContentHeight()
                                    .heightIn(max = 280.dp)
                                    .testTag("place_results")
                            ) {
                                if (isTyping) {
                                    if (results.isNotEmpty()) {
                                        items(results, key = { it.providerId }) { r ->
                                            PlaceResultRow(r.name, r.addressLine ?: r.featureName) {
                                                query = ""
                                                results = emptyList()
                                                resolveError = null
                                                pending = r
                                                // dismissSearch iOS: el panel se cierra
                                                // al elegir y queda solo el mapa de
                                                // confirmación. La flag local se fija
                                                // DIRECTAMENTE: el evento onFocusChanged
                                                // no está garantizado tras clearFocus.
                                                searchFocused = false
                                                focusManager.clearFocus(force = true)
                                                keyboard?.hide()
                                            }
                                        }
                                    } else if (!isResolving && resolveError == null &&
                                        PlaceSearchPolicy.shouldSearch(query)
                                    ) {
                                        item {
                                            Text(
                                                "Sin resultados cerca",
                                                style = MaterialTheme.typography.bodyMedium,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                                modifier = Modifier.padding(16.dp)
                                            )
                                        }
                                    }
                                } else {
                                    if (recents.isEmpty()) {
                                        item {
                                            Text(
                                                "Busca un gimnasio, parque o dirección",
                                                style = MaterialTheme.typography.bodyMedium,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                                modifier = Modifier.padding(16.dp)
                                            )
                                        }
                                    } else {
                                        item {
                                            Text(
                                                "Recientes",
                                                style = MaterialTheme.typography.labelMedium,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                                modifier = Modifier
                                                    .padding(
                                                        start = 16.dp, top = 10.dp, bottom = 4.dp
                                                    )
                                                    .testTag("place_recents_title")
                                            )
                                        }
                                        items(recents, key = {
                                            it.mapItemIdentifier ?: "${it.latitude},${it.longitude}"
                                        }) { pin ->
                                            PlaceResultRow(
                                                pin.name?.takeIf { n -> n.isNotBlank() }
                                                    ?: "Lugar",
                                                null
                                            ) {
                                                query = ""
                                                resolveError = null
                                                pending = PlaceSearchResult(
                                                    name = pin.name ?: "Lugar",
                                                    latitude = pin.latitude,
                                                    longitude = pin.longitude,
                                                    providerId = pin.mapItemIdentifier ?: "",
                                                    featureName = pin.name
                                                )
                                                searchFocused = false
                                                focusManager.clearFocus(force = true) // dismissSearch iOS
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if (showsConfirmMap && p != null) {
                    // Chip abajo (paridad iOS): nombre + categoría/dirección + icono.
                    Surface(
                        shape = RoundedCornerShape(16.dp),
                        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.92f),
                        tonalElevation = 2.dp,
                        shadowElevation = 2.dp,
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .padding(horizontal = 12.dp, vertical = 12.dp)
                            .fillMaxWidth()
                            .testTag("place_confirm_chip")
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp)
                        ) {
                            Column(Modifier.weight(1f)) {
                                Text(
                                    p.name,
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onSurface,
                                    maxLines = 2
                                )
                                p.addressLine?.takeIf { it.isNotBlank() }?.let {
                                    Text(
                                        it,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        maxLines = 1
                                    )
                                }
                            }
                            Spacer(Modifier.width(12.dp))
                            Icon(
                                Icons.Outlined.LocationOn,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(22.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}

/** Distancia ortodrómica en km (ordenar resultados por cercanía al GPS). */
private fun haversineKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
    val r = 6371.0
    val dLat = Math.toRadians(lat2 - lat1)
    val dLon = Math.toRadians(lon2 - lon1)
    val a = sin(dLat / 2) * sin(dLat / 2) +
        cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2)
    return 2 * r * atan2(sqrt(a), sqrt(1 - a))
}

@Composable
private fun PlaceResultRow(title: String, subtitle: String?, onClick: () -> Unit) {
    Column(
        Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Text(title, style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurface)
        if (!subtitle.isNullOrBlank()) {
            Text(subtitle, style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
    HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
}
