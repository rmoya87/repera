package dev.repera.mobile

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
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
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.repera.domain.LiveActivityState

/**
 * Controles Play/Pausa/Opciones/actividad.
 * Idle: el engrane pide abrir el sheet de Opciones en el host (modal), no un panel inline.
 */
@Composable
internal fun LiveStartToolbar(
    sportIcon: ImageVector,
    sportTitle: String,
    phase: LiveActivityState.Phase,
    countdown: Int,
    hasActiveWorkout: Boolean,
    locked: Boolean,
    onShowOptions: () -> Unit,
    onSport: () -> Unit,
    onPrimary: () -> Unit,
    onFinish: () -> Unit,
    onPrimaryPositioned: (Rect) -> Unit,
    modifier: Modifier = Modifier
) {
    val active = phase == LiveActivityState.Phase.RECORDING ||
        phase == LiveActivityState.Phase.PAUSED
    var dragDelta by remember { mutableFloatStateOf(0f) }
    val glassBorder = BorderStroke(
        0.7.dp,
        MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)
    )
    val sideGlass = MaterialTheme.colorScheme.surface.copy(alpha = 0.55f)
    val primarySize = if (active) 94.dp else 116.dp

    Column(
        modifier
            .fillMaxWidth()
            .widthIn(max = 570.dp)
            .pointerInput(locked, active) {
                if (!locked && !active) detectHorizontalDragGestures(
                    onDragStart = { dragDelta = 0f },
                    onHorizontalDrag = { change, delta ->
                        dragDelta += delta
                        change.consume()
                    },
                    onDragEnd = {
                        if (dragDelta < -70f) onShowOptions()
                        dragDelta = 0f
                    },
                    onDragCancel = { dragDelta = 0f }
                )
            },
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 14.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            LiveGlassCircleButton(
                onClick = { if (active) onFinish() else onShowOptions() },
                size = 64.dp,
                color = sideGlass,
                border = glassBorder,
                modifier = Modifier.testTag(if (active) "live_finish" else "live_options")
            ) {
                Icon(
                    if (active) Icons.Outlined.Flag else Icons.Outlined.Settings,
                    if (active) "Finalizar actividad" else "Opciones",
                    modifier = Modifier.size(28.dp)
                )
            }
            LiveGlassCircleButton(
                onClick = onPrimary,
                size = primarySize,
                color = if (phase == LiveActivityState.Phase.RECORDING)
                    ReperaAccents.pauseFab.copy(alpha = 0.88f) else brandGreen.copy(alpha = 0.88f),
                border = glassBorder,
                modifier = Modifier
                    .onGloballyPositioned { onPrimaryPositioned(it.boundsInRoot()) }
                    .testTag(if (active) "live_pause_resume" else "live_start")
            ) {
                if (countdown > 0) {
                    Text(
                        "$countdown",
                        color = Color.Black,
                        fontSize = (primarySize.value * 0.48f).sp,
                        fontWeight = FontWeight.Bold
                    )
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
            LiveGlassCircleButton(
                onClick = onSport,
                enabled = !active && countdown == 0 && !hasActiveWorkout,
                size = 64.dp,
                color = sideGlass,
                border = glassBorder,
                modifier = Modifier.testTag("live_sport_picker")
            ) {
                Icon(
                    sportIcon,
                    "Elegir actividad: $sportTitle",
                    tint = brandGreen,
                    modifier = Modifier.size(28.dp)
                )
            }
        }
    }
}

@Composable
private fun LiveGlassCircleButton(
    onClick: () -> Unit,
    size: Dp,
    color: Color,
    border: BorderStroke,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    content: @Composable () -> Unit
) {
    Surface(
        onClick = onClick,
        enabled = enabled,
        shape = CircleShape,
        color = color,
        border = border,
        modifier = modifier.size(size)
    ) {
        Box(contentAlignment = Alignment.Center) { content() }
    }
}
