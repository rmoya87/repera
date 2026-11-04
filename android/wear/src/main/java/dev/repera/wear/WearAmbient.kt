package dev.repera.wear

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import dev.repera.domain.LiveSport
import dev.repera.domain.ReperaNumberFormat
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/** Capabilities reported by the system when the display enters Always-On. */
internal data class WearAmbientMode(val burnInProtection: Boolean, val lowBit: Boolean)

private val burnInOffsetsDp = listOf(0 to 0, 3 to 2, -2 to 3, 2 to -3, -3 to -2)

/** Shifts static content a few dp on every ambient update to spread pixel wear. */
internal fun wearAmbientBurnInOffset(tick: Int, enabled: Boolean): Pair<Int, Int> =
    if (!enabled) 0 to 0 else burnInOffsetsDp[Math.floorMod(tick, burnInOffsetsDp.size)]

/** Minutes only: ambient refreshes about once per minute, never per second. */
internal fun wearAmbientMinutes(elapsedSeconds: Double): Int =
    (elapsedSeconds.coerceAtLeast(0.0) / 60.0).toInt()

/** Everything the ambient face needs, resolved once per ambient update. */
internal data class WearAmbientSnapshot(
    val nowMillis: Long,
    val session: WatchSessionSummary?,
    val live: JSONObject?,
    val heartRate: Int?,
    val elapsedSeconds: Int,
    val paused: Boolean,
    val restEndsAtMillis: Long?
)

private val clockFormat = DateTimeFormatter.ofPattern("HH:mm")
private val restFormat = DateTimeFormatter.ofPattern("HH:mm:ss")

private fun format(millis: Long, formatter: DateTimeFormatter): String =
    Instant.ofEpochMilli(millis).atZone(ZoneId.systemDefault()).format(formatter)

/**
 * Always-On: black, no animation, no filled surfaces, thin type and only the
 * metrics that matter at a glance. Secondary grey collapses to white on
 * low-bit panels.
 */
@Composable
internal fun WearAmbientScreen(
    mode: WearAmbientMode,
    tick: Int,
    snapshot: WearAmbientSnapshot,
    modifier: Modifier = Modifier
) {
    val primary = Color.White
    val secondary = if (mode.lowBit) Color.White else WearOg.label2
    val (dx, dy) = wearAmbientBurnInOffset(tick, mode.burnInProtection)
    val live = snapshot.live
    val session = snapshot.session
    Box(
        modifier = modifier.fillMaxSize().background(Color.Black),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 28.dp)
                .offset(dx.dp, dy.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                format(snapshot.nowMillis, clockFormat),
                color = primary,
                style = MaterialTheme.typography.displaySmall.copy(fontWeight = FontWeight.Light)
            )
            when {
                live != null -> {
                    val title = live.optString("sportTitle").ifBlank {
                        LiveSport.byId(live.optString("sportId"))?.title.orEmpty()
                    }
                    if (title.isNotBlank()) AmbientLine(title, secondary)
                    val phase = live.optString("phase")
                    val extra = if (phase == "recording")
                        ((snapshot.nowMillis - live.optLong("capturedAtMillis")) / 1000.0).coerceAtLeast(0.0)
                    else 0.0
                    val minutes = wearAmbientMinutes(live.optDouble("elapsedSeconds", 0.0) + extra)
                    AmbientMetric(stringResource(R.string.wear_ambient_elapsed_minutes, minutes), primary)
                    val meters = live.optDouble("distanceMeters", 0.0)
                    if (LiveSport.byId(live.optString("sportId"))?.usesGPS == true && meters > 0) {
                        AmbientMetric(
                            stringResource(R.string.wear_ambient_distance,
                                ReperaNumberFormat.decimal(meters / 1000.0)),
                            primary
                        )
                    }
                    if (phase == "paused") AmbientLine(stringResource(R.string.wear_ambient_paused), secondary)
                }
                session != null -> {
                    AmbientLine(session.exerciseName, secondary)
                    if (session.plannedWorkSets > 0) {
                        AmbientLine(
                            stringResource(R.string.wear_ambient_set,
                                (session.recordedSets + 1).coerceAtMost(session.plannedWorkSets),
                                session.plannedWorkSets),
                            secondary
                        )
                    }
                    AmbientMetric(
                        stringResource(R.string.wear_ambient_elapsed_minutes,
                            wearAmbientMinutes(snapshot.elapsedSeconds.toDouble())),
                        primary
                    )
                    snapshot.restEndsAtMillis?.let {
                        AmbientLine(stringResource(R.string.wear_ambient_rest_until, format(it, restFormat)), secondary)
                    }
                    if (snapshot.paused) AmbientLine(stringResource(R.string.wear_ambient_paused), secondary)
                }
                else -> AmbientLine(stringResource(R.string.wear_app_name), secondary)
            }
            snapshot.heartRate?.takeIf { it in 25..250 }?.let {
                AmbientMetric(stringResource(R.string.wear_ambient_heart_rate, it), primary)
            }
        }
    }
}

@Composable
private fun AmbientMetric(text: String, color: Color) {
    Text(
        text,
        color = color,
        style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Normal, fontSize = 22.sp),
        maxLines = 1,
        modifier = Modifier.semantics { contentDescription = text }
    )
}

@Composable
private fun AmbientLine(text: String, color: Color) {
    Text(
        text,
        color = color,
        style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Normal),
        textAlign = TextAlign.Center,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
        modifier = Modifier.fillMaxWidth()
    )
}
