package dev.repera.mobile

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.animation.core.tween
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Map
import androidx.compose.material.icons.outlined.Route
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.VolumeUp
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import dev.repera.domain.LiveActivityState

/** Mapa y Métricas comparten controles nativos; el deporte elegido vive a la derecha.
 * El candado sustituye al Play mediante la superposición del bloqueo táctil del host.
 */
@Composable
internal fun LiveStartToolbar(
    sportIcon: ImageVector,
    sportTitle: String,
    phase: LiveActivityState.Phase,
    countdown: Int,
    hasActiveWorkout: Boolean,
    showOptions: Boolean,
    audioEnabled: Boolean,
    showMap: Boolean,
    hasGPS: Boolean,
    locked: Boolean,
    onShowOptions: (Boolean) -> Unit,
    onAudio: () -> Unit,
    onMap: (Boolean) -> Unit,
    onSport: () -> Unit,
    onRoute: () -> Unit,
    onPrimary: () -> Unit,
    onFinish: () -> Unit,
    onLock: () -> Unit,
    onPrimaryPositioned: (Rect) -> Unit
) {
    val active = phase == LiveActivityState.Phase.RECORDING ||
        phase == LiveActivityState.Phase.PAUSED
    var dragDelta by remember { mutableFloatStateOf(0f) }

    Column(
        Modifier.fillMaxWidth().widthIn(max = 570.dp)
            .pointerInput(locked) {
                if (!locked) detectHorizontalDragGestures(
                    onDragStart = { dragDelta = 0f },
                    onHorizontalDrag = { change, delta ->
                        dragDelta += delta
                        change.consume()
                    },
                    onDragEnd = {
                        if (dragDelta < -70f) onShowOptions(true)
                        if (dragDelta > 70f) onShowOptions(false)
                        dragDelta = 0f
                    },
                    onDragCancel = { dragDelta = 0f }
                )
            }
            .padding(horizontal = 12.dp, vertical = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        AnimatedContent(
            targetState = showOptions,
            transitionSpec = {
                (slideInHorizontally(animationSpec = tween(220)) {
                    if (targetState) it else -it
                } + fadeIn()).togetherWith(
                    slideOutHorizontally(animationSpec = tween(220)) {
                        if (targetState) -it else it
                    } + fadeOut()
                )
            },
            label = "live_start_options"
        ) { options ->
            if (options) {
                Column(Modifier.fillMaxWidth().testTag("live_start_options"),
                    verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Opciones", style = MaterialTheme.typography.headlineSmall,
                            modifier = Modifier.weight(1f))
                        TextButton(onClick = { onShowOptions(false) }) { Text("Cerrar") }
                    }
                    Row(Modifier.fillMaxWidth().heightIn(min = 56.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Outlined.VolumeUp, null)
                        Spacer(Modifier.width(12.dp))
                        Text("Audio", style = MaterialTheme.typography.titleMedium,
                            modifier = Modifier.weight(1f))
                        Switch(checked = audioEnabled, onCheckedChange = { onAudio() })
                    }
                    Row(Modifier.fillMaxWidth().heightIn(min = 56.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Outlined.Map, null)
                        Spacer(Modifier.width(12.dp))
                        Text("Mapa", style = MaterialTheme.typography.titleMedium,
                            modifier = Modifier.weight(1f))
                        Switch(checked = hasGPS && showMap, enabled = hasGPS,
                            onCheckedChange = onMap)
                    }
                    if (!active) {
                        TextButton(onClick = onRoute, enabled = hasGPS,
                            modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                                .testTag("live_load_route")) {
                            Icon(Icons.Outlined.Route, null)
                            Spacer(Modifier.width(12.dp))
                            Text("Cargar ruta", style = MaterialTheme.typography.titleMedium)
                        }
                    } else {
                        TextButton(onClick = onLock,
                            modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                            Icon(Icons.Outlined.Lock, null)
                            Spacer(Modifier.width(12.dp))
                            Text("Bloquear pantalla", style = MaterialTheme.typography.titleMedium)
                        }
                    }
                }
            } else {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly,
                    verticalAlignment = Alignment.CenterVertically) {
                    Surface(
                        onClick = { if (active) onFinish() else onShowOptions(true) },
                        shape = CircleShape,
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        modifier = Modifier.size(64.dp)
                            .testTag(if (active) "live_finish" else "live_options")
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(if (active) Icons.Outlined.Flag else Icons.Outlined.Settings,
                                if (active) "Finalizar actividad" else "Opciones",
                                modifier = Modifier.size(28.dp))
                        }
                    }
                    Surface(
                        onClick = onPrimary,
                        shape = CircleShape,
                        color = if (phase == LiveActivityState.Phase.RECORDING)
                            ReperaAccents.pauseFab else brandGreen,
                        modifier = Modifier.size(if (active) 94.dp else 116.dp)
                            .onGloballyPositioned { onPrimaryPositioned(it.boundsInRoot()) }
                            .testTag(if (active) "live_pause_resume" else "live_start")
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            if (countdown > 0) {
                                Text("$countdown", color = Color.Black,
                                    style = MaterialTheme.typography.headlineLarge,
                                    fontWeight = FontWeight.Bold)
                            } else {
                                Icon(
                                    if (locked) Icons.Outlined.Lock else
                                    if (phase == LiveActivityState.Phase.RECORDING)
                                        Icons.Filled.Pause else Icons.Filled.PlayArrow,
                                    contentDescription = if (locked) "Pantalla bloqueada" else
                                        if (phase == LiveActivityState.Phase.RECORDING)
                                            "Pausar" else if (active) "Reanudar" else "Comenzar",
                                    tint = Color.Black,
                                    modifier = Modifier.size(38.dp)
                                )
                            }
                        }
                    }
                    Surface(
                        onClick = onSport,
                        enabled = !active && countdown == 0 && !hasActiveWorkout,
                        shape = CircleShape,
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        modifier = Modifier.size(64.dp).testTag("live_sport_picker")
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(sportIcon, "Elegir actividad: $sportTitle",
                                tint = brandGreen, modifier = Modifier.size(28.dp))
                        }
                    }
                }
            }
        }
    }
}
