package dev.repera.mobile

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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Place
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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

private const val MAP_STYLE = "https://tiles.openfreemap.org/styles/liberty"
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
        modifier = modifier.testTag("place_pin_map"),
        factory = { context ->
            MapLibre.getInstance(context)
            MapView(context).also { mapView = it }.apply {
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
                    map.setStyle(MAP_STYLE) { style ->
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

/** Fila «lugar del entreno» (paridad WorkoutPlacePickerRow iOS): icono + nombre
 *  o «Añadir lugar», y preview de mapa de 160 dp cuando hay pin. Abre la hoja. */
@Composable
fun WorkoutPlacePickerRow(
    pin: WorkoutLocationPin?,
    accountId: String,
    onPinChange: (WorkoutLocationPin?) -> Unit,
    modifier: Modifier = Modifier,
    /** Solo verificación: avisa cuando el estilo del preview terminó de cargar. */
    onMapStyleLoaded: (() -> Unit)? = null
) {
    var showSearch by remember { mutableStateOf(false) }
    Column(modifier = modifier.fillMaxWidth()) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .clickable { showSearch = true }
                .padding(vertical = 4.dp)
                .testTag("place_picker_row")
        ) {
            Icon(
                imageVector = if (pin != null) Icons.Filled.LocationOn else Icons.Filled.Place,
                contentDescription = null,
                tint = if (pin != null) MaterialTheme.colorScheme.onSurfaceVariant
                       else MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(32.dp)
            )
            Spacer(Modifier.width(12.dp))
            Text(
                text = pin?.name?.takeIf { it.isNotBlank() }
                    ?: if (pin != null) "Lugar en el mapa" else "Añadir lugar",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
        if (pin != null) {
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(160.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .clickable { showSearch = true }
            ) {
                PlacePinMap(pin.latitude, pin.longitude, isInteractive = false,
                    modifier = Modifier.fillMaxSize(), onStyleLoaded = onMapStyleLoaded)
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

    val isTyping = query.isNotBlank()
    // iOS: showsConfirmMap = pending != null && !isTyping && !isSearchPresented
    // (mutuamente excluyente con el panel de búsqueda).
    val showsConfirmMap = pending != null && !isTyping && !searchFocused

    // Política de dominio: mínimo de caracteres + pausa, NO por tecla.
    LaunchedEffect(query) {
        if (!PlaceSearchPolicy.shouldSearch(query)) {
            results = emptyList()
            isResolving = false
            return@LaunchedEffect
        }
        delay(PlaceSearchPolicy.DEBOUNCE_MS)
        isResolving = true
        resolveError = null
        results = runCatching { provider.search(query.trim()) }
            .getOrElse {
                resolveError = "No se pudo buscar el lugar."
                emptyList()
            }
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
                WindowInsetsControllerCompat(w, dialogView).apply {
                    isAppearanceLightStatusBars = true
                    isAppearanceLightNavigationBars = true
                }
            }
        }
        Surface(modifier = Modifier.fillMaxSize()
            .statusBarsPadding().navigationBarsPadding()) {
            Column(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.surface)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 4.dp)
                ) {
                    if (showsConfirmMap) {
                        IconButton(
                            onClick = { onSelect(null); onDismiss() },
                            modifier = Modifier.testTag("place_clear")
                        ) { Icon(Icons.Filled.Delete, contentDescription = "Quitar lugar") }
                    } else {
                        IconButton(onClick = onDismiss, modifier = Modifier.testTag("place_close")) {
                            Icon(Icons.Filled.Close, contentDescription = "Cerrar")
                        }
                    }
                    Text(
                        text = if (showsConfirmMap) "Lugar" else "Buscar lugar",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.weight(1f)
                    )
                    if (showsConfirmMap) {
                        IconButton(
                            onClick = {
                                val p = pending ?: return@IconButton
                                val pin = p.toPin().copy(recordedAtEpochMs =
                                    System.currentTimeMillis())
                                recentStore.remember(pin)
                                onSelect(pin)
                                onDismiss()
                            },
                            modifier = Modifier.testTag("place_confirm")
                        ) { Icon(Icons.Filled.Check, contentDescription = "Guardar lugar") }
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
                OutlinedTextField(
                    value = query,
                    interactionSource = fieldInteraction,
                    onValueChange = { query = it },
                    // Prompt iOS (.searchable): "Buscar otro sitio…" también
                    // en la primera búsqueda; el hint largo va solo en el panel.
                    placeholder = { Text("Buscar otro sitio…") },
                    singleLine = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                        .onFocusChanged { searchFocused = it.isFocused }
                        .testTag("place_query")
                )
                if (isResolving) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(16.dp)
                    ) {
                        CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
                        Spacer(Modifier.width(10.dp))
                        Text("Buscando…", style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                if (limitedNotice && !isResolving && PlaceSearchPolicy.shouldSearch(query)) {
                    Text("La búsqueda de establecimientos no está disponible ahora: " +
                        "solo se muestran direcciones. Un resultado vacío no significa que no exista; " +
                        "puedes colocar el pin en el mapa.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                            .testTag("place_limited_notice"))
                }
                if (PlaceSearchPolicy.shouldSearch(query)) {
                    // Los geocodificadores con datos OSM deben acreditar OpenStreetMap
                    // (osmfoundation.org/wiki/Licence/Attribution_Guidelines).
                    Text("Datos de lugares © OpenStreetMap contributors",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 2.dp)
                            .testTag("place_osm_attribution"))
                }
                resolveError?.let {
                    Text(it, style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp))
                }
                val showPanel = isTyping || (searchFocused && !isTyping)
                if (showPanel) {
                    HorizontalDivider()
                    LazyColumn(
                        modifier = Modifier
                            .fillMaxWidth()
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
                                    }
                                }
                            } else if (!isResolving && resolveError == null &&
                                PlaceSearchPolicy.shouldSearch(query)) {
                                item {
                                    Text("Sin resultados cerca",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        modifier = Modifier.padding(16.dp))
                                }
                            }
                        } else {
                            if (recents.isEmpty()) {
                                item {
                                    Text("Busca un gimnasio, parque o dirección",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        modifier = Modifier.padding(16.dp))
                                }
                            } else {
                                item {
                                    Text("Recientes",
                                        style = MaterialTheme.typography.labelMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        modifier = Modifier.padding(
                                            start = 16.dp, top = 10.dp, bottom = 4.dp))
                                }
                                items(recents, key = {
                                    it.mapItemIdentifier ?: "${it.latitude},${it.longitude}"
                                }) { pin ->
                                    PlaceResultRow(pin.name?.takeIf { n -> n.isNotBlank() }
                                        ?: "Lugar", null) {
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
                    HorizontalDivider()
                }
                val p = pending
                if (p != null && !isTyping) {
                    // Mapa del lugar pendiente: MISMO composable en modo
                    // confirmar y con la búsqueda presentada (iOS mantiene el
                    // mapa y solo superpone/oculta el panel), así la vista GL
                    // no se recrea al presentar/cerrar la búsqueda y tocarlo
                    // la cierra (dismissSearch iOS). El panel inferior solo
                    // aparece en modo confirmar (showsConfirmMap iOS).
                    Box(Modifier.fillMaxSize()) {
                        PlacePinMap(p.latitude, p.longitude, isInteractive = true,
                            modifier = Modifier.fillMaxSize(),
                            onCameraIdle = onMapCameraIdle,
                            onMapClick = {
                                searchFocused = false
                                focusManager.clearFocus(force = true)
                            })
                        if (showsConfirmMap) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier
                                    .align(Alignment.BottomCenter)
                                    .fillMaxWidth()
                                    .background(MaterialTheme.colorScheme.surfaceVariant)
                                    .padding(16.dp)
                            ) {
                                Column(Modifier.weight(1f)) {
                                    Text(p.name, style = MaterialTheme.typography.titleSmall,
                                        color = MaterialTheme.colorScheme.onSurface)
                                    p.addressLine?.takeIf { it.isNotBlank() }?.let {
                                        Text(it, style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    }
                                }
                                Icon(Icons.Filled.LocationOn, contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                    modifier = Modifier.size(28.dp))
                            }
                        }
                    }
                } else {
                    // Browse map (browseMap iOS): con un lugar pendiente se
                    // centra en su pin (Marker iOS); si no, en el pin inicial o
                    // en el lugar más reciente. Así, con la búsqueda
                    // presentada, el mapa sigue visible y tocarlo la cierra
                    // (dismissSearch iOS).
                    val center = pending?.let { it.latitude to it.longitude }
                        ?: initialPin?.let { it.latitude to it.longitude }
                        ?: recents.firstOrNull()?.let { it.latitude to it.longitude }
                    if (center != null) {
                        PlacePinMap(center.first, center.second, isInteractive = true,
                            modifier = Modifier.fillMaxSize(),
                            onCameraIdle = onMapCameraIdle,
                            onMapClick = {
                                searchFocused = false
                                focusManager.clearFocus(force = true)
                            })
                    } else {
                        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Text("Busca un lugar para situar el pin",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }
        }
    }
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
