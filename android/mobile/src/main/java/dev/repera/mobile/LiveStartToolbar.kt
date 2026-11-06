package dev.repera.mobile

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.LockOpen
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import dev.repera.domain.LiveActivityState
import kotlin.math.roundToInt
import kotlinx.coroutines.launch

/**
 * Controles Play/Pausa/Opciones/actividad (idle) o Finalizar/Play/candado (vivo).
 * En vivo el candado (glass) se fusiona con Play como gota; Play no se mueve
 * y el candado bloqueado permanece en el mismo botón (sin parpadeo).
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
    onLock: () -> Unit,
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
    val primaryGlass = brandGreen.copy(alpha = 0.88f)
    val pauseGlass = ReperaAccents.pauseFab.copy(alpha = 0.88f)
    val primarySize = if (active) 94.dp else 116.dp
    val sideSize = 64.dp
    val density = LocalDensity.current
    val scope = rememberCoroutineScope()
    var merging by remember { mutableStateOf(false) }
    val mergeProgress = remember { Animatable(0f) }
    var boxOrigin by remember { mutableStateOf(Offset.Zero) }
    var primaryCenter by remember { mutableStateOf(Offset.Zero) }
    var lockCenter by remember { mutableStateOf(Offset.Zero) }
    val showSideLock = active && !locked
    val p = if (merging) mergeProgress.value else 0f
    val showsFusedLock = locked || merging

    fun beginLockMerge() {
        if (!active || locked || merging) return
        scope.launch {
            merging = true
            mergeProgress.snapTo(0f)
            mergeProgress.animateTo(
                1f,
                tween(durationMillis = 340, easing = FastOutSlowInEasing)
            )
            onLock()
            merging = false
            mergeProgress.snapTo(0f)
        }
    }

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
        Box(
            Modifier
                .fillMaxWidth()
                .onGloballyPositioned { boxOrigin = it.boundsInRoot().topLeft }
        ) {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = if (active) 6.dp else 14.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (locked) {
                    // Hueco simétrico: Finalizar solo visible al desbloquear.
                    Box(Modifier.size(sideSize))
                } else {
                    LiveGlassCircleButton(
                        onClick = { if (active) onFinish() else onShowOptions() },
                        size = sideSize,
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
                }
                Box(
                    Modifier
                        .size(primarySize)
                        .onGloballyPositioned {
                            val b = it.boundsInRoot()
                            primaryCenter = Offset(b.center.x, b.center.y)
                            onPrimaryPositioned(b)
                        }
                        .graphicsLayer {
                            val absorb = if (merging) 0.06f * p else 0f
                            scaleX = 1f + absorb
                            scaleY = 1f + absorb
                        },
                    contentAlignment = Alignment.Center
                ) {
                    // Play: se desvanece al absorber el candado.
                    LiveGlassCircleButton(
                        onClick = onPrimary,
                        size = primarySize,
                        color = if (phase == LiveActivityState.Phase.RECORDING)
                            pauseGlass else primaryGlass,
                        border = glassBorder,
                        enabled = !showsFusedLock,
                        modifier = Modifier
                            .graphicsLayer { alpha = if (showsFusedLock) 0f else 1f }
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
                                if (phase == LiveActivityState.Phase.RECORDING)
                                    Icons.Filled.Pause else Icons.Filled.PlayArrow,
                                contentDescription =
                                    if (phase == LiveActivityState.Phase.RECORDING)
                                        "Pausar" else if (active) "Reanudar" else "Comenzar",
                                tint = Color.Black,
                                modifier = Modifier.size(38.dp)
                            )
                        }
                    }
                    // Candado fused: misma superficie en fusión y bloqueado (sin parpadeo).
                    if (showsFusedLock) {
                        LiveGlassCircleButton(
                            onClick = {},
                            size = primarySize,
                            color = primaryGlass,
                            border = glassBorder,
                            enabled = false,
                            modifier = Modifier
                                .graphicsLayer {
                                    alpha = if (locked) 1f else p
                                    val grow = 0.94f + 0.06f * (if (locked) 1f else p)
                                    scaleX = grow
                                    scaleY = grow
                                }
                                .testTag("live_touch_unlock_face")
                        ) {
                            Icon(
                                Icons.Outlined.Lock,
                                contentDescription = "Pantalla bloqueada",
                                tint = Color.Black,
                                modifier = Modifier.size(36.dp)
                            )
                        }
                    }
                }
                if (active) {
                    if (showSideLock) {
                        LiveGlassCircleButton(
                            onClick = ::beginLockMerge,
                            size = sideSize,
                            color = sideGlass,
                            border = glassBorder,
                            enabled = !merging,
                            modifier = Modifier
                                .onGloballyPositioned {
                                    val b = it.boundsInRoot()
                                    lockCenter = Offset(b.center.x, b.center.y)
                                }
                                .graphicsLayer {
                                    // Se oculta al despegar la gota voladora.
                                    alpha = if (merging) 0f else 1f
                                }
                                .testTag("live_lock")
                        ) {
                            Icon(
                                Icons.Outlined.LockOpen,
                                "Bloquear pantalla",
                                modifier = Modifier.size(28.dp)
                            )
                        }
                    } else {
                        Box(Modifier.size(sideSize))
                    }
                } else {
                    LiveGlassCircleButton(
                        onClick = onSport,
                        enabled = countdown == 0 && !hasActiveWorkout,
                        size = sideSize,
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
            // Gota voladora: glass que crece hacia Play.
            if (merging) {
                val start = lockCenter - boxOrigin
                val end = primaryCenter - boxOrigin
                val cx = start.x + (end.x - start.x) * p
                val cy = start.y + (end.y - start.y) * p
                val sidePx = with(density) { sideSize.toPx() }
                val primaryPx = with(density) { primarySize.toPx() }
                val sizePx = sidePx + (primaryPx - sidePx) * p
                Box(
                    Modifier
                        .offset {
                            IntOffset(
                                (cx - sizePx / 2f).roundToInt(),
                                (cy - sizePx / 2f).roundToInt()
                            )
                        }
                        .size(with(density) { sizePx.toDp() })
                        .zIndex(2f)
                        .graphicsLayer { alpha = 1f - 0.35f * p },
                    contentAlignment = Alignment.Center
                ) {
                    Surface(
                        shape = CircleShape,
                        color = sideGlass,
                        border = glassBorder,
                        modifier = Modifier.size(with(density) { sizePx.toDp() })
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                if (p > 0.45f) Icons.Outlined.Lock else Icons.Outlined.LockOpen,
                                contentDescription = null,
                                tint = Color.Black,
                                modifier = Modifier.size((28f + 8f * p).dp)
                            )
                        }
                    }
                }
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
