package dev.repera.mobile

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.KeyboardArrowDown
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.StackedLineChart
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.repera.domain.PlannedSet
import dev.repera.domain.PlannedSetSummary
import dev.repera.domain.ReperaNumberFormat
import kotlinx.coroutines.delay

object RoutinePresentationStats {
    fun counts(blocks: List<RoutineBlockInfo>): Pair<Int, Int> {
        val exercises = blocks.sumOf { it.entries.size }
        val sets = blocks.sumOf { b -> b.entries.sumOf { maxOf(it.sets, 1) } }
        return exercises to sets
    }
}

/** Metadatos tipo chip (fecha, hora, resumen). */
@Composable
fun WorkoutMetaChip(
    text: String,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
) {
    Row(
        modifier
            .height(32.dp)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(horizontal = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(5.dp)
    ) {
        if (icon != null) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(14.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Text(
            text,
            style = MaterialTheme.typography.labelLarge.copy(fontSize = 14.sp),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

/** Línea «3 × 8 · 60 kg · descanso 1:30» para listas y preview. */
fun exercisePrescriptionSummary(
    sets: List<PlannedSet>,
    restSeconds: Int? = null,
): String {
    val base = PlannedSetSummary.compactSummary(sets)
        .replace("×", " × ")
    val rest = restSeconds?.takeIf { it > 0 }?.let { sec ->
        val m = sec / 60
        val s = sec % 60
        if (m > 0 && s > 0) "descanso $m:${s.toString().padStart(2, '0')}"
        else if (m > 0) "descanso ${m}:00"
        else "descanso ${sec}s"
    }
    return if (rest != null && base != "—") "$base · $rest" else base
}

@Composable
fun WorkoutPlayProgressHeader(
    completedSets: Int,
    totalSets: Int,
    volumeKg: Double,
    elapsedSeconds: Int = 0,
    modifier: Modifier = Modifier,
) {
    val progress = if (totalSets > 0) completedSets.toFloat() / totalSets else 0f
    val setsLine = if (elapsedSeconds > 0) {
        "$completedSets de $totalSets series · ${ActiveSessionLiveStats.formatElapsed(elapsedSeconds)}"
    } else {
        "$completedSets de $totalSets series"
    }
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text(
                setsLine,
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(Modifier.weight(1f))
            Text(
                if (volumeKg > 0) "Volumen ${ReperaNumberFormat.decimal(volumeKg, 0)} kg" else "Volumen —",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.reperaColors.accentText
            )
        }
        LinearProgressIndicator(
            progress = { progress.coerceIn(0f, 1f) },
            modifier = Modifier
                .fillMaxWidth()
                .height(4.dp)
                .clip(RoundedCornerShape(2.dp)),
            color = brandGreen,
            trackColor = MaterialTheme.colorScheme.surfaceVariant,
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WorkoutFinishSummarySheet(
    visible: Boolean,
    title: String,
    elapsedSeconds: Int,
    completedSets: Int,
    totalSets: Int,
    volumeKg: Double,
    warning: String?,
    onDismiss: () -> Unit,
    onSave: () -> Unit,
    onKeepTraining: () -> Unit,
) {
    if (!visible) return
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(Icons.Outlined.Flag, contentDescription = null,
                tint = brandGreen, modifier = Modifier.size(28.dp))
            Text("¿Terminar entreno?", style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                finishSummaryTile("Tiempo", ActiveSessionLiveStats.formatElapsed(elapsedSeconds), Modifier.weight(1f))
                finishSummaryTile("Series", "$completedSets/$totalSets", Modifier.weight(1f))
                val vol = if (volumeKg > 0) "${ReperaNumberFormat.decimal(volumeKg, 0)} kg" else "—"
                finishSummaryTile("Volumen", vol, Modifier.weight(1f))
            }
            warning?.let { w ->
                Surface(
                    shape = RoundedCornerShape(14.dp),
                    color = MaterialTheme.colorScheme.surfaceVariant
                ) {
                    Text(
                        w,
                        modifier = Modifier.padding(14.dp),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            Button(
                onClick = onSave,
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = CircleShape,
                colors = ButtonDefaults.buttonColors(containerColor = brandGreen, contentColor = Color.Black)
            ) { Text("Guardar entreno", fontWeight = FontWeight.SemiBold) }
            OutlinedButton(
                onClick = onKeepTraining,
                modifier = Modifier.fillMaxWidth().height(48.dp),
                shape = CircleShape
            ) { Text("Seguir entrenando", fontWeight = FontWeight.SemiBold) }
        }
    }
}

@Composable
private fun finishSummaryTile(label: String, value: String, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Column(
            Modifier.padding(vertical = 12.dp, horizontal = 8.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(label, style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
fun DiscardChangesDialog(
    visible: Boolean,
    onDismiss: () -> Unit,
    onDiscard: () -> Unit,
) {
    if (!visible) return
    androidx.compose.material3.AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("¿Descartar cambios?") },
        text = { Text("Perderás los cambios que no hayas guardado.") },
        confirmButton = {
            TextButton(onClick = onDiscard) {
                Text("Descartar cambios", color = MaterialTheme.colorScheme.error)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Seguir editando") }
        }
    )
}

/** Confirmar borrado de bloque con más de un ejercicio (paridad iOS). */
@Composable
fun ConfirmDeleteMultiExerciseBlockDialog(
    visible: Boolean,
    onDismiss: () -> Unit,
    onConfirm: () -> Unit,
) {
    if (!visible) return
    androidx.compose.material3.AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("¿Eliminar este bloque?") },
        text = { Text("Se eliminarán todos los ejercicios del bloque.") },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text("Eliminar bloque", color = MaterialTheme.colorScheme.error)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancelar") }
        }
    )
}

/** Snackbar «Serie eliminada» + Deshacer (4 s). */
suspend fun showWorkoutUndoSnackbar(
    host: SnackbarHostState,
    message: String,
    onUndo: () -> Unit,
) {
    val result = host.showSnackbar(message = message, actionLabel = "Deshacer", duration = androidx.compose.material3.SnackbarDuration.Short)
    if (result == SnackbarResult.ActionPerformed) onUndo()
}

@Composable
fun WorkoutUndoSnackbarHost(hostState: SnackbarHostState, modifier: Modifier = Modifier) {
    SnackbarHost(hostState, modifier) { data ->
        Snackbar(
            snackbarData = data,
            actionColor = MaterialTheme.reperaColors.accentText,
            containerColor = MaterialTheme.colorScheme.inverseSurface
        )
    }
}

/** Índice de serie 44×44 (Play / editor). */
@Composable
fun SetRowIndexBadge(
    index: Int,
    completed: Boolean,
    isCurrent: Boolean,
    onToggleComplete: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val bg = when {
        completed -> brandGreen
        isCurrent -> MaterialTheme.colorScheme.surfaceVariant
        else -> MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f)
    }
    val fg = if (completed) Color.Black else MaterialTheme.colorScheme.onSurfaceVariant
    Box(
        modifier
            .size(44.dp)
            .clip(CircleShape)
            .background(bg)
            .then(
                if (onToggleComplete != null) {
                    Modifier.clickable(onClick = onToggleComplete)
                } else Modifier
            )
            .semantics { contentDescription = "Serie $index" },
        contentAlignment = Alignment.Center
    ) {
        Text("$index", fontWeight = FontWeight.Bold, color = fg)
    }
}

/** «Anterior» tocable: copia valores al pulsar. */
@Composable
fun PreviousSetValueChip(
    label: String,
    enabled: Boolean,
    onCopy: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val color = if (enabled) MaterialTheme.reperaColors.accentText
    else MaterialTheme.colorScheme.onSurfaceVariant
    Text(
        label,
        modifier = modifier
            .then(if (enabled) Modifier.clickable(onClick = onCopy) else Modifier),
        style = MaterialTheme.typography.bodySmall,
        color = color,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis
    )
}

/** Temporizador entre series en Play (−15 / +15 / Saltar). */
class PlayRestTimerState {
    var remainingSeconds by mutableIntStateOf(0)
    var isActive by mutableStateOf(false)

    fun start(seconds: Int) {
        remainingSeconds = seconds.coerceAtLeast(0)
        isActive = seconds > 0
    }

    fun adjust(by: Int) {
        remainingSeconds = (remainingSeconds + by).coerceAtLeast(0)
    }

    fun skip() {
        isActive = false
        remainingSeconds = 0
    }
}

@Composable
fun PlayRestFooter(
    timer: PlayRestTimerState,
    modifier: Modifier = Modifier,
) {
    if (!timer.isActive) return
    LaunchedEffect(timer.isActive, timer.remainingSeconds) {
        if (!timer.isActive) return@LaunchedEffect
        while (timer.isActive && timer.remainingSeconds > 0) {
            delay(1_000)
            timer.remainingSeconds -= 1
            if (timer.remainingSeconds <= 0) timer.skip()
        }
    }
    Surface(
        modifier = modifier.fillMaxWidth(),
        tonalElevation = 3.dp,
        shadowElevation = 8.dp
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(Modifier.size(44.dp), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(
                    progress = { 1f },
                    modifier = Modifier.size(40.dp),
                    color = brandGreen,
                    trackColor = MaterialTheme.colorScheme.surfaceVariant,
                    strokeWidth = 3.dp
                )
                Text(
                    "${timer.remainingSeconds}",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            Text(
                "Descanso ${timer.remainingSeconds / 60}:${(timer.remainingSeconds % 60).toString().padStart(2, '0')}",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.weight(1f)
            )
            TextButton(onClick = { timer.adjust(-15) }) { Text("-15") }
            TextButton(onClick = { timer.adjust(15) }) { Text("+15") }
            Button(
                onClick = { timer.skip() },
                colors = ButtonDefaults.buttonColors(containerColor = brandGreen, contentColor = Color.Black),
                shape = CircleShape
            ) { Text("Saltar") }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun SessionPreviewSummaryChips(
    exerciseCount: Int,
    setCount: Int,
    durationMinutes: Int?,
    modifier: Modifier = Modifier,
) {
    FlowRow(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        WorkoutMetaChip("$exerciseCount ejercicios", icon = Icons.Outlined.StackedLineChart)
        WorkoutMetaChip("$setCount series")
        durationMinutes?.let { WorkoutMetaChip("≈ $it min", icon = Icons.Outlined.Schedule) }
    }
}

/** CTA primario flotante (paridad OGFloatingPrimaryCTA iOS): sin barra surface. */
@Composable
fun FloatingPrimaryCta(
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    leadingIcon: (@Composable () -> Unit)? = null,
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 10.dp)
            .height(52.dp),
        shape = CircleShape,
        colors = ButtonDefaults.buttonColors(
            containerColor = brandGreen,
            contentColor = Color.Black,
            disabledContainerColor = brandGreen.copy(alpha = 0.45f),
            disabledContentColor = Color.Black.copy(alpha = 0.7f)
        )
    ) {
        if (leadingIcon != null) {
            leadingIcon()
            Spacer(Modifier.width(6.dp))
        }
        Text(title, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
fun SessionPreviewBottomBar(
    onStart: () -> Unit,
    startEnabled: Boolean,
    modifier: Modifier = Modifier,
    /** @Deprecated Editar/Borrar van en el menú ⋯; se ignora. */
    onEdit: () -> Unit = {},
) {
    // Solo Empezar flotante (sin fondo surface / sin Editar duplicado).
    FloatingPrimaryCta(
        title = "Empezar",
        onClick = onStart,
        enabled = startEnabled,
        modifier = modifier,
        leadingIcon = {
            Icon(Icons.Filled.PlayArrow, contentDescription = null, modifier = Modifier.size(22.dp))
        }
    )
}
