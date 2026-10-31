package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Air
import androidx.compose.material.icons.outlined.Place
import androidx.compose.material.icons.outlined.WaterDrop
import androidx.compose.material.icons.outlined.WbSunny
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.repera.domain.HistoricalWeatherReading
import dev.repera.domain.WorkoutLocationPin
import java.time.Instant

/**
 * Franja Tiempo / Humedad / Viento bajo el mapa (paridad RouteWeatherStrip iOS).
 * Consulta Open-Meteo al abrir; no se persiste.
 */
@Composable
internal fun RouteWeatherStrip(
    latitude: Double,
    longitude: Double,
    workoutEpochMs: Long,
    modifier: Modifier = Modifier,
    liveSportId: String? = null,
    persistedConditions: dev.repera.domain.ActivityConditionsSnapshot? = null
) {
    var loading by remember(latitude, longitude, workoutEpochMs) { mutableStateOf(true) }
    var reading by remember(latitude, longitude, workoutEpochMs) {
        mutableStateOf<HistoricalWeatherReading?>(null)
    }
    var failure by remember(latitude, longitude, workoutEpochMs) { mutableStateOf<String?>(null) }
    var conditions by remember(latitude, longitude, workoutEpochMs, liveSportId) {
        mutableStateOf(persistedConditions)
    }
    LaunchedEffect(latitude, longitude, workoutEpochMs, liveSportId, persistedConditions) {
        loading = true
        failure = null
        reading = null
        conditions = persistedConditions
        OpenMeteoWeatherClient.fetch(latitude, longitude, workoutEpochMs)
            .onSuccess { reading = it; failure = null }
            .onFailure {
                reading = null
                failure = it.message?.takeIf { m -> m.isNotBlank() }
                    ?: "Datos meteorológicos no disponibles."
            }
        if (persistedConditions == null && liveSportId != null) {
            OpenMeteoWeatherClient.fetchConditions(latitude, longitude, liveSportId, workoutEpochMs)
                .onSuccess { conditions = it }
        }
        loading = false
    }
    val uriHandler = LocalUriHandler.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 12.dp)
            .testTag("route_weather_strip")
    ) {
        Row(
            Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            WeatherStat(
                icon = Icons.Outlined.WbSunny,
                title = "Tiempo",
                value = reading?.temperatureLabel,
                loading = loading,
                modifier = Modifier.weight(1f)
            )
            HorizontalDivider(
                Modifier
                    .height(46.dp)
                    .width(1.dp)
                    .padding(horizontal = 4.dp)
            )
            WeatherStat(
                icon = Icons.Outlined.WaterDrop,
                title = "Humedad",
                value = reading?.humidityLabel,
                loading = loading,
                modifier = Modifier.weight(1f)
            )
            HorizontalDivider(
                Modifier
                    .height(46.dp)
                    .width(1.dp)
                    .padding(horizontal = 4.dp)
            )
            WeatherStat(
                icon = Icons.Outlined.Air,
                title = "Viento",
                value = reading?.windLabel,
                loading = loading,
                modifier = Modifier.weight(1f)
            )
        }
        conditions?.let { snap ->
            if (snap.family == dev.repera.domain.ActivityConditionsFamily.WATER ||
                snap.family == dev.repera.domain.ActivityConditionsFamily.SNOW
            ) {
                HorizontalDivider(Modifier.padding(vertical = 8.dp))
                ConditionsLayout(items = conditionItems(snap))
                // Disclaimer + atribución en la fila unificada debajo.
            }
        }
        // Una línea: aviso (izq.) · Fuente · Open-Meteo (der.). Sin WeatherKit en Android.
        if (reading != null || conditions != null) {
            val showDisclaimer = conditions?.family ==
                dev.repera.domain.ActivityConditionsFamily.WATER ||
                conditions?.disclaimer != null
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(top = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                if (showDisclaimer) {
                    Text(
                        "No usar para navegar",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontSize = 10.sp,
                        maxLines = 1,
                        softWrap = false,
                        modifier = Modifier.weight(1f, fill = false)
                    )
                }
                androidx.compose.foundation.layout.Spacer(Modifier.weight(1f))
                Text(
                    "Fuente",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontSize = 10.sp,
                    maxLines = 1,
                    softWrap = false
                )
                TextButton(
                    onClick = { uriHandler.openUri(OpenMeteoWeatherClient.ATTRIBUTION_URL) },
                    modifier = Modifier.testTag("weather_attribution"),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 4.dp, vertical = 0.dp)
                ) {
                    Text(
                        OpenMeteoWeatherClient.ATTRIBUTION_LABEL,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontSize = 10.sp,
                        maxLines = 1,
                        softWrap = false
                    )
                }
            }
        } else if (failure != null) {
            Text(
                failure!!,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        } else if (loading) {
            Text(
                "Consultando tiempo histórico…",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

private data class ConditionItem(val title: String, val value: String?)

private fun conditionItems(snap: dev.repera.domain.ActivityConditionsSnapshot): List<ConditionItem> {
    val items = mutableListOf<ConditionItem>()
    if (snap.family == dev.repera.domain.ActivityConditionsFamily.WATER) {
        val tide = snap.tideHeightMeters?.let { h ->
            val t = snap.tideTrendLabel?.let { " · $it" }.orEmpty()
            String.format("%.2f m%s", h, t)
        }
        items += ConditionItem("Marea", tide)
        snap.nextTideLabel?.let { items += ConditionItem("Próxima", it) }
        items += ConditionItem(
            "Oleaje",
            snap.waveHeightMeters?.let { String.format("%.1f m", it) }
        )
    }
    if (snap.family == dev.repera.domain.ActivityConditionsFamily.SNOW) {
        items += ConditionItem(
            "Nevada",
            snap.snowfallCm?.let { String.format("%.1f cm/h", it) }
        )
        items += ConditionItem(
            "Nieve",
            snap.snowDepthMeters?.let { String.format("%.0f cm", it * 100) }
        )
    }
    return items
}

/** Par: dos columnas; impar: listado vertical. */
@Composable
private fun ConditionsLayout(items: List<ConditionItem>) {
    if (items.isEmpty()) return
    if (items.size % 2 == 0) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            for (i in items.indices step 2) {
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    ConditionLine(
                        items[i].title,
                        items[i].value,
                        Modifier.weight(1f)
                    )
                    ConditionLine(
                        items[i + 1].title,
                        items[i + 1].value,
                        Modifier.weight(1f)
                    )
                }
            }
        }
    } else {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items.forEach { ConditionLine(it.title, it.value) }
        }
    }
}

@Composable
private fun ConditionLine(
    title: String,
    value: String?,
    modifier: Modifier = Modifier
) {
    Row(
        modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            title,
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1
        )
        Text(
            value ?: "—",
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1
        )
    }
}

@Composable
private fun WeatherStat(
    icon: ImageVector,
    title: String,
    value: String?,
    loading: Boolean,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(9.dp)
    ) {
        Icon(
            icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(26.dp)
        )
        Column {
            Text(
                title,
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1
            )
            if (loading && value == null) {
                CircularProgressIndicator(
                    Modifier.size(14.dp),
                    strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else {
                Text(
                    value ?: "—",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1
                )
            }
        }
    }
}

/**
 * Mapa (o vacío) + franja de clima en una sola card (SessionMapWeatherCard iOS).
 */
@Composable
internal fun SessionMapWeatherCard(
    latitude: Double?,
    longitude: Double?,
    workoutEpochMs: Long,
    placePin: WorkoutLocationPin? = null,
    modifier: Modifier = Modifier,
    liveSportId: String? = null,
    persistedConditions: dev.repera.domain.ActivityConditionsSnapshot? = null,
    map: @Composable () -> Unit
) {
    // Sin ReperaCard anidada: el contenedor del detalle ya aporta la card.
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
    ) {
        map()
        if (placePin != null && placePin.hasChosenPlace) {
            HorizontalDivider(
                color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
            )
            WorkoutPlaceSummaryRow(pin = placePin)
        }
        if (latitude != null && longitude != null) {
            HorizontalDivider(
                color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
            )
            RouteWeatherStrip(
                latitude = latitude,
                longitude = longitude,
                workoutEpochMs = workoutEpochMs,
                liveSportId = liveSportId,
                persistedConditions = persistedConditions
            )
        }
    }
}

@Composable
internal fun WorkoutPlaceSummaryRow(pin: WorkoutLocationPin) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Icon(
            Icons.Outlined.Place,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(22.dp)
        )
        Column(Modifier.weight(1f)) {
            Text(
                pin.name?.takeIf { it.isNotBlank() } ?: "Lugar en el mapa",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold
            )
            pin.pointOfInterestCategory?.takeIf { it.isNotBlank() }?.let {
                Text(
                    it,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

internal fun workoutEpochMs(workout: WorkoutHistoryEntry): Long {
    val iso = workout.startedAtIso?.takeIf { it.isNotBlank() }
        ?: workout.finishedAtIso?.takeIf { it.isNotBlank() }
    if (iso != null) {
        runCatching { Instant.parse(iso).toEpochMilli() }.getOrNull()?.let { return it }
    }
    return System.currentTimeMillis()
}
