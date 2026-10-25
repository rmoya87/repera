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
import androidx.compose.foundation.layout.padding
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
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
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
    modifier: Modifier = Modifier
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
                getMapAsync { map ->
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
    modifier: Modifier = Modifier
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
                    modifier = Modifier.fillMaxSize())
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
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val provider = remember { CompositePlaceSearchProvider(PhotonPlaceSearchProvider(), GeocoderPlaceSearchProvider(context)) }
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
    val showsConfirmMap = pending != null && !isTyping

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
        limitedNotice = provider.establishmentsUnavailable
        isResolving = false
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(modifier = Modifier.fillMaxSize()) {
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
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    placeholder = { Text("Busca un gimnasio, parque o dirección") },
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
                                    }
                                }
                            }
                        }
                    }
                    HorizontalDivider()
                }
                val p = pending
                if (showsConfirmMap && p != null) {
                    Box(Modifier.fillMaxSize()) {
                        PlacePinMap(p.latitude, p.longitude, isInteractive = true,
                            modifier = Modifier.fillMaxSize())
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
                } else {
                    // Browse map: sin resultados seleccionados (browse map iOS).
                    val center = initialPin ?: recents.firstOrNull()
                    if (center != null) {
                        PlacePinMap(center.latitude, center.longitude, isInteractive = true,
                            modifier = Modifier.fillMaxSize())
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
