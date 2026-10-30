package dev.repera.wear

import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.rotary.onRotaryScrollEvent
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.TransformingLazyColumn
import androidx.wear.compose.foundation.lazy.TransformingLazyColumnScope
import androidx.wear.compose.foundation.lazy.rememberTransformingLazyColumnState
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.TextButton
import dev.repera.domain.Effort
import dev.repera.domain.ReperaNumberFormat
import dev.repera.domain.WeightUnit
import dev.repera.domain.WodClock
import dev.repera.domain.WodClockSpec
import dev.repera.domain.WodFormat
import org.json.JSONObject

/** Estado visible de la pantalla principal del reloj (extraído de
 * WearMainActivity para pruebas visuales instrumentadas). */
internal data class WearHomeState(
    val session: WatchSessionSummary?,
    val liveActivity: JSONObject? = null,
    val showingCachedSession: Boolean,
    val finishedSummary: FinishedSummary?,
    val todayPlan: JSONObject?,
    val syncProblem: Boolean,
    val health: Pair<Int?, Double?>?,
    val wodTimerJson: JSONObject?,
    val wodTickSeconds: Int,
    val sessionPaused: Boolean,
    val restRemaining: Int,
    val repsInput: Int,
    val weightInput: Double?,
    val rirInput: Double?,
    val durationInput: Int,
    val unitInput: String,
    val deficitInput: Int,
    val pendingCount: Int,
    val confirmDiscardPending: Boolean,
    val sendStatus: String?,
    val warmup: Boolean = false,
    val toFailure: Boolean = false,
    val effortUnit: String = "rir",
    val weightUnit: String = "kg",
    val setKind: String = "straight",
    val drops: List<Pair<Int, Double?>> = emptyList(),
    val clusters: List<Pair<Int, Int>> = emptyList(),
    val showOutline: Boolean = false,
    val showSetDetails: Boolean = false,
    val reviewingBlock: Boolean = false,
    val elapsedSeconds: Int = 0,
    val reviewRounds: Int = 0,
    val reviewExtraReps: Int = 0,
    val reviewElapsedSeconds: Int = 0,
    val setReviewIndex: Int? = null
)

internal class WearHomeCallbacks(
    val onDismissFinished: (FinishedSummary) -> Unit = {},
    val onLiveCommand: (String) -> Unit = {},
    val onStartTodayPlan: () -> Unit = {},
    val onStartTodayPlanAt: (Int) -> Unit = {},
    val onTogglePause: () -> Unit = {},
    val onPlayReady: () -> Unit = {},
    val onSelectBlock: (WatchSessionSummary, Int) -> Unit = { _, _ -> },
    val onFinishSession: (WatchSessionSummary) -> Unit = {},
    val onDiscardSession: (WatchSessionSummary) -> Unit = {},
    val onSkipRest: () -> Unit = {},
    val onSyncRequest: () -> Unit = {},
    val onRepsMinus: () -> Unit = {},
    val onRepsPlus: () -> Unit = {},
    val onWeightDelta: (Double) -> Unit = {},
    val onRirMinus: () -> Unit = {},
    val onRirPlus: () -> Unit = {},
    val onRirClear: () -> Unit = {},
    val onToggleWarmup: () -> Unit = {},
    val onToggleFailure: () -> Unit = {},
    val onDurationDelta: (Int) -> Unit = {},
    val onCycleUnit: () -> Unit = {},
    val onDeficitDelta: (Int) -> Unit = {},
    val onSetKind: (String) -> Unit = {},
    val onAddDrop: () -> Unit = {},
    val onAdjustDrop: (Int, Int, Double) -> Unit = { _, _, _ -> },
    val onRemoveDrop: (Int) -> Unit = {},
    val onAddCluster: () -> Unit = {},
    val onAdjustCluster: (Int, Int, Int) -> Unit = { _, _, _ -> },
    val onRemoveCluster: (Int) -> Unit = {},
    val onWodTimerStart: () -> Unit = {},
    val onWodTimerPause: () -> Unit = {},
    val onWodTimerReset: () -> Unit = {},
    val onQueueSet: (WatchSessionSummary) -> Unit = {},
    val onResendPending: () -> Unit = {},
    val onDiscardConfirm: (Boolean) -> Unit = {},
    val onDiscardPending: () -> Unit = {},
    val onShowOutline: (Boolean) -> Unit = {},
    val onShowSetDetails: (Boolean) -> Unit = {},
    val onReviewBlock: () -> Unit = {},
    val onConfirmBlock: () -> Unit = {},
    val onAdjustReviewRounds: (Int) -> Unit = {},
    val onAdjustReviewExtraReps: (Int) -> Unit = {},
    val onAdjustReviewElapsed: (Int) -> Unit = {},
    val onSwipeSet: (Int) -> Unit = {}
)

@Composable
internal fun WearHomeContent(
    state: WearHomeState,
    callbacks: WearHomeCallbacks,
    modifier: Modifier = Modifier
) {
    TransformingLazyColumn(
        state = rememberTransformingLazyColumnState(),
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        when {
            state.finishedSummary != null && state.session == null ->
                finishedItems(state.finishedSummary, callbacks)
            state.session != null && state.showOutline ->
                outlineItems(state.session, callbacks)
            state.session != null && state.showSetDetails ->
                setDetailsItems(state, callbacks)
            state.session != null && state.reviewingBlock ->
                blockReviewItems(state, callbacks)
            state.session != null && state.session.phase == "ready" ->
                readyItems(state.session, callbacks)
            state.session != null ->
                runningItems(state, callbacks)
            state.liveActivity != null ->
                liveActivityItems(state.liveActivity, callbacks)
            state.todayPlan != null ->
                todayItems(state.todayPlan, callbacks)
            else ->
                emptyItems(state, callbacks)
        }
        pendingItems(state, callbacks)
        state.sendStatus?.let {
            item {
                Text(it, style = MaterialTheme.typography.labelSmall, textAlign = TextAlign.Center)
            }
        }
    }
}

/** Phone owns GPS/Health and the watch only displays aggregate real metrics. */
private fun TransformingLazyColumnScope.liveActivityItems(live: JSONObject, callbacks: WearHomeCallbacks) {
    val phase = live.optString("phase")
    item {
        Text(live.optString("sportTitle", "Actividad"),
            style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center)
    }
    item {
        val now = remember(live.optString("sessionId")) {
            androidx.compose.runtime.mutableLongStateOf(System.currentTimeMillis())
        }
        LaunchedEffect(live.optString("sessionId"), phase) {
            while (true) {
                kotlinx.coroutines.delay(1_000)
                now.longValue = System.currentTimeMillis()
            }
        }
        val extra = if (phase == "recording")
            ((now.longValue - live.optLong("capturedAtMillis")) / 1000.0).coerceAtLeast(0.0)
        else 0.0
        Text(dev.repera.domain.LiveSportHistory.formatDuration(
            live.optDouble("elapsedSeconds", 0.0) + extra),
            style = MaterialTheme.typography.displaySmall, textAlign = TextAlign.Center)
        Text("Tiempo activo", style = MaterialTheme.typography.labelSmall)
    }
    item {
        Text(ReperaNumberFormat.decimal(live.optDouble("distanceMeters", 0.0) / 1000.0) + " km",
            style = MaterialTheme.typography.titleMedium)
    }
    if (!live.isNull("averageSpeedKmh")) {
        item {
            Text(ReperaNumberFormat.decimal(live.optDouble("averageSpeedKmh")) + " km/h media",
                style = MaterialTheme.typography.labelMedium)
        }
    }
    if (!live.isNull("nextTurn") && phase != "review") {
        item { Text(live.optString("nextTurn"), textAlign = TextAlign.Center) }
    }
    if (phase == "review") {
        item { Text("Finalizada · revisa y guarda en el teléfono",
            textAlign = TextAlign.Center) }
    } else {
        item {
            val confirm = remember(live.optString("sessionId")) {
                androidx.compose.runtime.mutableStateOf(false)
            }
            if (confirm.value) {
                Text("¿Finalizar actividad?", style = MaterialTheme.typography.labelMedium)
                Row {
                    TextButton(onClick = { confirm.value = false }) { Text("Cancelar") }
                    TextButton(onClick = {
                        confirm.value = false
                        callbacks.onLiveCommand("finish")
                    }) { Text("Finalizar") }
                }
            } else {
                Row {
                    TextButton(onClick = {
                        callbacks.onLiveCommand(if (phase == "paused") "resume" else "pause")
                    }) { Text(if (phase == "paused") "Reanudar" else "Pausar") }
                    TextButton(onClick = { confirm.value = true }) { Text("Terminar") }
                }
            }
        }
    }
}

private fun TransformingLazyColumnScope.finishedItems(
    finished: FinishedSummary,
    callbacks: WearHomeCallbacks
) {
    item {
        Text("Resultado", style = MaterialTheme.typography.titleMedium)
    }
    item {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text("✓", color = WearOg.accent, style = MaterialTheme.typography.titleLarge)
            Text("¡Bien hecho!", style = MaterialTheme.typography.titleMedium)
        }
    }
    item {
        Text(
            finished.title,
            textAlign = TextAlign.Start,
            style = MaterialTheme.typography.labelMedium,
            modifier = Modifier.fillMaxWidth()
        )
    }
    item { WearStatsLine("Tiempo", finished.durationLabel) }
    finished.kcal?.let { item { WearStatsLine("Calorías", "${it} kcal") } }
    finished.avgHr?.let { item { WearStatsLine("FC media", "$it lpm") } }
    item { WearStatsLine("Series", "${finished.sets}") }
    item { WearStatsLine("Repeticiones", "${finished.reps}") }
    item { WearStatsLine("Volumen", "${finished.volumeKg} kg") }
    finished.wodLines.forEach { (label, value) ->
        item { WearStatsLine(label, value) }
    }
    item {
        WearPrimaryButton("Volver al inicio") { callbacks.onDismissFinished(finished) }
    }
}

private fun TransformingLazyColumnScope.todayItems(
    plan: JSONObject,
    callbacks: WearHomeCallbacks
) {
    val exercises = plan.optJSONArray("exercises")
    val format = planFormat(plan)
    val duration = planDuration(plan)
    item {
        Text(plan.optString("title").ifBlank { "Entreno de hoy" },
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.labelMedium,
            maxLines = 2)
    }
    item {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(format, color = WearOg.label2, style = MaterialTheme.typography.labelSmall)
            Text(duration, color = WearOg.label2, style = MaterialTheme.typography.labelSmall)
        }
    }
    if (exercises != null) {
        WatchSessionSummary.blocksOf(exercises).forEach { (start, header) ->
            item {
                TextButton(
                    onClick = { callbacks.onStartTodayPlanAt(start) },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("$header ›", style = MaterialTheme.typography.labelSmall, maxLines = 1)
                }
            }
            blockMemberLines(exercises, start).forEach { line ->
                item {
                    Text(
                        line,
                        style = MaterialTheme.typography.labelSmall,
                        color = WearOg.label2,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 8.dp),
                        maxLines = 1
                    )
                }
            }
        }
    }
    item {
        WearPrimaryButton("▶ Iniciar entreno") { callbacks.onStartTodayPlan() }
    }
}

private fun TransformingLazyColumnScope.readyItems(
    session: WatchSessionSummary,
    callbacks: WearHomeCallbacks
) {
    item {
        Text(
            session.blockHeader.ifBlank { session.exerciseName },
            style = MaterialTheme.typography.titleMedium,
            textAlign = TextAlign.Center
        )
    }
    session.blockExerciseLines.forEach { line ->
        item {
            Text(
                line,
                style = MaterialTheme.typography.labelSmall,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 6.dp),
                maxLines = 2
            )
        }
    }
    session.blockTimeCapMinutes?.let {
        item {
            Text("🕘 $it min", color = WearOg.label2, style = MaterialTheme.typography.labelSmall)
        }
    }
    item {
        WearPrimaryButton(
            if (session.wodFormatLabel != null) "▶ Iniciar bloque" else "▶ Empezar ejercicio"
        ) { callbacks.onPlayReady() }
    }
    item {
        WearPrimaryButton("Resumen") { callbacks.onShowOutline(true) }
    }
}

private fun TransformingLazyColumnScope.outlineItems(
    session: WatchSessionSummary,
    callbacks: WearHomeCallbacks
) {
    item {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            TextButton(onClick = { callbacks.onShowOutline(false) }) {
                Text("✕", color = WearOg.accent)
            }
            Text("Resumen", style = MaterialTheme.typography.titleMedium)
        }
    }
    item {
        Text(
            session.title,
            color = WearOg.label2,
            style = MaterialTheme.typography.labelSmall,
            textAlign = TextAlign.Center
        )
    }
    session.blocks.forEach { (start, name) ->
        val current = start == session.exerciseIndex - 1 ||
            (session.exerciseIndex - 1 in start until (session.blocks
                .firstOrNull { it.first > start }?.first ?: Int.MAX_VALUE))
        item {
            TextButton(
                onClick = {
                    callbacks.onSelectBlock(session, start)
                    callbacks.onShowOutline(false)
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    if (current) "▶ $name" else "$name ›",
                    style = MaterialTheme.typography.labelSmall,
                    maxLines = 1
                )
            }
        }
    }
    item {
        WearPrimaryButton("✓ Finalizar entrenamiento") {
            callbacks.onShowOutline(false)
            callbacks.onFinishSession(session)
        }
    }
    // Ramón F-5: el Watch ofrece descartar (además de finalizar).
    item {
        TextButton(
            onClick = {
                callbacks.onShowOutline(false)
                callbacks.onDiscardSession(session)
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(
                "Descartar entreno",
                color = WearOg.red,
                style = MaterialTheme.typography.labelSmall
            )
        }
    }
}

private fun TransformingLazyColumnScope.blockReviewItems(
    state: WearHomeState,
    callbacks: WearHomeCallbacks
) {
    val session = state.session ?: return
    val format = WodFormat.fromWire(session.wodFormatWire.orEmpty())
    item {
        Text(
            "Resultado del bloque",
            color = WearOg.label2,
            style = MaterialTheme.typography.labelMedium
        )
    }
    if (format == WodFormat.AMRAP || format == WodFormat.DEATH_BY ||
        format == WodFormat.ROUNDS_FOR_QUALITY
    ) {
        item {
            WearMetricStepper(
                "Rondas", "${state.reviewRounds}",
                onMinus = { callbacks.onAdjustReviewRounds(-1) },
                onPlus = { callbacks.onAdjustReviewRounds(1) }
            )
        }
    }
    if (format?.capture == dev.repera.domain.ResultCapture.TOTAL_REPS) {
        val label = if (format == WodFormat.AMRAP) "Reps adicionales" else "Repeticiones totales"
        item {
            WearMetricStepper(
                label, "${state.reviewExtraReps}",
                onMinus = { callbacks.onAdjustReviewExtraReps(-1) },
                onPlus = { callbacks.onAdjustReviewExtraReps(1) }
            )
        }
    }
    if (format?.capture == dev.repera.domain.ResultCapture.ELAPSED_TIME) {
        item {
            WearMetricStepper(
                "Tiempo final",
                wearClockLabel(state.reviewElapsedSeconds),
                onMinus = { callbacks.onAdjustReviewElapsed(-1) },
                onPlus = { callbacks.onAdjustReviewElapsed(1) }
            )
        }
    } else {
        item {
            Text(
                "Tiempo: ${wearClockLabel(state.elapsedSeconds)}",
                color = WearOg.label2,
                style = MaterialTheme.typography.labelSmall
            )
        }
    }
    if (format == WodFormat.EMOM || format == WodFormat.TABATA) {
        item {
            Text(
                "Los intervalos se controlan automáticamente. No se inventan repeticiones.",
                color = WearOg.label2,
                style = MaterialTheme.typography.labelSmall,
                textAlign = TextAlign.Center
            )
        }
    }
    item {
        WearPrimaryButton("Terminar") { callbacks.onConfirmBlock() }
    }
}

private fun TransformingLazyColumnScope.setDetailsItems(
    state: WearHomeState,
    callbacks: WearHomeCallbacks
) {
    val session = state.session ?: return
    item {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            TextButton(onClick = { callbacks.onShowSetDetails(false) }) {
                Text("✕", color = WearOg.accent)
            }
            Text("Detalles de serie", style = MaterialTheme.typography.titleMedium)
        }
    }
    if (session.inputMode in setOf("strength", "hspuDeficit", "repsOnly")) {
        item {
            WearMetricStepper(
                Effort.displayName(state.effortUnit),
                state.rirInput?.let {
                    Effort.label(it, state.effortUnit)
                        ?: "${Effort.displayName(state.effortUnit)} ${ReperaNumberFormat.decimal(it)}"
                } ?: "—",
                onMinus = { callbacks.onRirMinus() },
                onPlus = { callbacks.onRirPlus() }
            )
        }
        item {
            TextButton(onClick = { callbacks.onToggleFailure() }) {
                Text(if (state.toFailure) "Al fallo ✓" else "Al fallo")
            }
        }
        item {
            WearPrimaryButton("Sin ${Effort.displayName(state.effortUnit)}") {
                callbacks.onRirClear()
            }
        }
        if (session.allowsWeight) {
            item {
                WearMetricStepper(
                    "Ajuste fino kg",
                    run {
                        val unit = WeightUnit.fromWire(state.weightUnit)
                        val kg = state.weightInput ?: 0.0
                        ReperaNumberFormat.decimal(unit.displayValue(kg))
                    },
                    onMinus = { callbacks.onWeightDelta(-0.1) },
                    onPlus = { callbacks.onWeightDelta(0.1) }
                )
            }
        }
        item {
            Text("Fase", color = WearOg.label2, style = MaterialTheme.typography.labelSmall)
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                TextButton(onClick = { if (state.warmup) callbacks.onToggleWarmup() }) {
                    Text(if (!state.warmup) "Trabajo ✓" else "Trabajo")
                }
                TextButton(onClick = { if (!state.warmup) callbacks.onToggleWarmup() }) {
                    Text(if (state.warmup) "Calentamiento ✓" else "Calentamiento")
                }
            }
        }
        if (!state.warmup) {
            item {
                Text("Tipo de serie", color = WearOg.label2, style = MaterialTheme.typography.labelSmall)
            }
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    TextButton(onClick = { callbacks.onSetKind("straight") }) {
                        Text(if (state.setKind == "straight") "Normal ✓" else "Normal")
                    }
                    TextButton(onClick = { callbacks.onSetKind("dropset") }) {
                        Text(if (state.setKind == "dropset") "Drop set ✓" else "Drop set")
                    }
                    TextButton(onClick = { callbacks.onSetKind("restpause") }) {
                        Text(if (state.setKind == "restpause") "Rest-pause ✓" else "Rest-pause")
                    }
                }
            }
            if (state.setKind == "dropset") {
                state.drops.forEachIndexed { idx, drop ->
                    item {
                        WearMetricStepper(
                            "Drop reps", "${drop.first}",
                            onMinus = { callbacks.onAdjustDrop(idx, -1, 0.0) },
                            onPlus = { callbacks.onAdjustDrop(idx, 1, 0.0) }
                        )
                    }
                    if (session.allowsWeight) {
                        item {
                            WearMetricStepper(
                                "Drop kg",
                                ReperaNumberFormat.decimal(drop.second ?: 0.0),
                                onMinus = { callbacks.onAdjustDrop(idx, 0, -0.5) },
                                onPlus = { callbacks.onAdjustDrop(idx, 0, 0.5) }
                            )
                        }
                    }
                    item {
                        TextButton(onClick = { callbacks.onRemoveDrop(idx) }) {
                            Text("Eliminar drop")
                        }
                    }
                }
                if (state.drops.size < 5) {
                    item {
                        WearPrimaryButton("Añadir drop") { callbacks.onAddDrop() }
                    }
                }
            }
            if (state.setKind == "restpause") {
                state.clusters.forEachIndexed { idx, cluster ->
                    item {
                        WearMetricStepper(
                            "Reps bloque", "${cluster.first}",
                            onMinus = { callbacks.onAdjustCluster(idx, -1, 0) },
                            onPlus = { callbacks.onAdjustCluster(idx, 1, 0) }
                        )
                    }
                    item {
                        WearMetricStepper(
                            "Pausa (s)", "${cluster.second}",
                            onMinus = { callbacks.onAdjustCluster(idx, 0, -5) },
                            onPlus = { callbacks.onAdjustCluster(idx, 0, 5) }
                        )
                    }
                    item {
                        TextButton(onClick = { callbacks.onRemoveCluster(idx) }) {
                            Text("Eliminar bloque")
                        }
                    }
                }
                item {
                    WearPrimaryButton("Añadir bloque") { callbacks.onAddCluster() }
                }
            }
        }
    }
    item {
        WearPrimaryButton("Listo") { callbacks.onShowSetDetails(false) }
    }
}

private fun TransformingLazyColumnScope.runningItems(
    state: WearHomeState,
    callbacks: WearHomeCallbacks
) {
    val session = state.session ?: return
    if (state.showingCachedSession) {
        item {
            Text(
                "Última sesión recibida · sin conexión confirmada",
                textAlign = TextAlign.Center,
                style = MaterialTheme.typography.labelSmall
            )
        }
    }
    item {
        Text(
            session.blockHeader.ifBlank { session.title },
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.labelMedium,
            maxLines = 1
        )
    }
    // Reloj + pausa (W-05 / W-07)
    item {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            val clockSeconds = if (session.wodFormatLabel != null) {
                state.wodTimerJson?.takeIf {
                    wearTimerMatches(it, session.sessionId, session.exerciseIndex)
                }?.let { timer ->
                    wodFaceSeconds(timer, state.wodTickSeconds)
                } ?: state.elapsedSeconds
            } else state.elapsedSeconds
            WearClockText(
                clockSeconds,
                modifier = Modifier.weight(1f),
                contentDescription = if (session.wodFormatLabel != null)
                    "Tiempo del bloque" else "Tiempo transcurrido"
            )
            WearPauseCircle(state.sessionPaused) { callbacks.onTogglePause() }
        }
    }
    state.health?.let { (bpm, kcal) ->
        item { WearHealthRow(bpm, kcal) }
    }
    if (session.wodFormatLabel != null) {
        wodRunningBody(session, state, callbacks)
    } else {
        strengthRunningBody(session, state, callbacks)
    }
    item {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            TextButton(onClick = { callbacks.onShowOutline(true) }) {
                Text("Resumen", color = WearOg.onAccent)
            }
            val zeroReps = state.repsInput == 0
            val isLast = session.exerciseIndex >= session.exerciseCount
            val finishLabel = when {
                session.wodFormatLabel != null && !session.wodUsesSeries -> "✓"
                !zeroReps -> "→"
                isLast -> "✓"
                else -> "→"
            }
            Button(
                onClick = {
                    when {
                        session.wodFormatLabel != null && !session.wodUsesSeries ->
                            callbacks.onReviewBlock()
                        else -> callbacks.onQueueSet(session)
                    }
                },
                enabled = !state.sessionPaused || state.restRemaining > 0,
                modifier = Modifier.semantics {
                    contentDescription = when {
                        session.wodFormatLabel != null && !session.wodUsesSeries -> "Terminar"
                        !zeroReps -> "Siguiente"
                        isLast -> "Terminar"
                        else -> "Siguiente"
                    }
                }
            ) {
                Text(finishLabel, color = WearOg.onAccent)
            }
        }
    }
}

private fun TransformingLazyColumnScope.wodRunningBody(
    session: WatchSessionSummary,
    state: WearHomeState,
    callbacks: WearHomeCallbacks
) {
    session.wodMovements.forEach { movement ->
        item {
            Text(movement, textAlign = TextAlign.Center, style = MaterialTheme.typography.labelSmall)
        }
    }
    state.wodTimerJson?.takeIf {
        wearTimerMatches(it, session.sessionId, session.exerciseIndex)
    }?.let { timer ->
        val face = wodFace(timer, state.wodTickSeconds)
        face.label?.let { label ->
            item { Text(label, style = MaterialTheme.typography.labelSmall) }
        }
        if (timer.optBoolean("local")) {
            item {
                Text("Reloj local del reloj", style = MaterialTheme.typography.labelSmall)
            }
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                if (!timer.optBoolean("running")) {
                    TextButton(onClick = { callbacks.onWodTimerStart() }) { Text("Iniciar") }
                } else {
                    TextButton(onClick = { callbacks.onWodTimerPause() }) { Text("Pausar reloj") }
                }
                TextButton(onClick = { callbacks.onWodTimerReset() }) { Text("Reiniciar") }
            }
        }
    }
    if (session.globalScore) {
        item {
            Text(
                "Resultado por bloque en el teléfono",
                textAlign = TextAlign.Center,
                style = MaterialTheme.typography.labelSmall
            )
        }
        item {
            WearPrimaryButton("Terminar bloque") { callbacks.onReviewBlock() }
        }
    } else if (session.wodUsesSeries && session.canLogOnWatch) {
        if (state.wodTimerJson == null ||
            !wearTimerMatches(state.wodTimerJson, session.sessionId, session.exerciseIndex)
        ) {
            item {
                Text(
                    "Inicia el reloj del bloque (local o teléfono) para registrar series",
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.labelSmall
                )
            }
            item {
                WearPrimaryButton("Iniciar reloj del bloque") { callbacks.onWodTimerStart() }
            }
        } else {
            restBlock(state, callbacks)
            seriesSteppers(session, state, callbacks, includeWeight = session.allowsWeight)
            item {
                WearPrimaryButton("Terminar bloque") { callbacks.onReviewBlock() }
            }
        }
    }
}

private fun TransformingLazyColumnScope.strengthRunningBody(
    session: WatchSessionSummary,
    state: WearHomeState,
    callbacks: WearHomeCallbacks
) {
    item {
        TextButton(
            onClick = { callbacks.onShowSetDetails(true) },
            modifier = Modifier
                .fillMaxWidth()
                .pointerInput(Unit) {
                    detectHorizontalDragGestures { _, dragAmount ->
                        if (kotlin.math.abs(dragAmount) > 40) {
                            callbacks.onSwipeSet(if (dragAmount < 0) 1 else -1)
                        }
                    }
                }
                .semantics { contentDescription = "Editar detalles del ejercicio y serie" }
        ) {
            Text(
                buildString {
                    append(session.exerciseName)
                    append(" · ")
                    append(
                        if (state.warmup) "Calentamiento"
                        else {
                            val planned = maxOf(1, session.plannedWorkSets)
                            val n = (state.setReviewIndex ?: session.recordedSets) + 1
                            "Serie $n de $planned"
                        }
                    )
                    append(" · …")
                },
                style = MaterialTheme.typography.labelMedium,
                maxLines = 2,
                textAlign = TextAlign.Start,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
    if (!session.canLogOnWatch) {
        item {
            Text(
                "Este ejercicio solo se registra en el móvil",
                textAlign = TextAlign.Center,
                style = MaterialTheme.typography.labelSmall
            )
        }
        return
    }
    restBlock(state, callbacks)
    seriesSteppers(session, state, callbacks, includeWeight = false)
    if (session.allowsWeight && session.inputMode != "hspuDeficit") {
        item {
            WearMetricStepper(
                "Peso kg",
                run {
                    val unit = WeightUnit.fromWire(state.weightUnit)
                    val kg = state.weightInput ?: 0.0
                    ReperaNumberFormat.decimal(unit.displayValue(kg))
                },
                enabled = !state.sessionPaused,
                onMinus = { callbacks.onWeightDelta(-0.5) },
                onPlus = { callbacks.onWeightDelta(0.5) }
            )
        }
    }
    if (session.inputMode in setOf("repsAndTime", "machineWork")) {
        item {
            WearMetricStepper(
                "Tiempo serie",
                wearClockLabel(state.durationInput),
                enabled = !state.sessionPaused,
                onMinus = { callbacks.onDurationDelta(-5) },
                onPlus = { callbacks.onDurationDelta(5) }
            )
        }
    }
    if (session.inputMode == "machineWork" && session.allowsUnitToggle) {
        val label = when (state.unitInput) {
            "calories" -> "kcal"
            "meters" -> "m"
            else -> "reps"
        }
        item {
            WearPrimaryButton("Unidad: $label") { callbacks.onCycleUnit() }
        }
    }
    if (session.inputMode == "hspuDeficit") {
        item {
            WearMetricStepper(
                "Déficit (cm)",
                "${state.deficitInput}",
                enabled = !state.sessionPaused,
                onMinus = { callbacks.onDeficitDelta(-1) },
                onPlus = { callbacks.onDeficitDelta(1) }
            )
        }
    }
}

@Composable
private fun RotaryRepsHost(
    onMinus: () -> Unit,
    onPlus: () -> Unit,
    content: @Composable () -> Unit
) {
    val focus = remember { FocusRequester() }
    LaunchedEffect(Unit) { focus.requestFocus() }
    androidx.compose.foundation.layout.Box(
        modifier = Modifier
            .fillMaxWidth()
            .onRotaryScrollEvent { event ->
                if (event.verticalScrollPixels > 0) onPlus() else onMinus()
                true
            }
            .focusRequester(focus)
            .focusable()
            .semantics { contentDescription = "Repeticiones, ajustables con la corona" }
    ) { content() }
}

private fun TransformingLazyColumnScope.seriesSteppers(
    session: WatchSessionSummary,
    state: WearHomeState,
    callbacks: WearHomeCallbacks,
    includeWeight: Boolean
) {
    if (!session.mobilityHold) {
        item {
            RotaryRepsHost(
                onMinus = { callbacks.onRepsMinus() },
                onPlus = { callbacks.onRepsPlus() }
            ) {
                WearMetricStepper(
                    if (session.inputMode in setOf("machineWork", "loadDistance"))
                        (if (state.unitInput == "meters") "m" else "cal")
                    else "Reps",
                    "${state.repsInput}",
                    enabled = !state.sessionPaused,
                    onMinus = { callbacks.onRepsMinus() },
                    onPlus = { callbacks.onRepsPlus() }
                )
            }
        }
    }
    if (includeWeight && session.allowsWeight) {
        item {
            WearMetricStepper(
                "Peso kg",
                run {
                    val unit = WeightUnit.fromWire(state.weightUnit)
                    val kg = state.weightInput ?: 0.0
                    ReperaNumberFormat.decimal(unit.displayValue(kg))
                },
                enabled = !state.sessionPaused,
                onMinus = { callbacks.onWeightDelta(-0.5) },
                onPlus = { callbacks.onWeightDelta(0.5) }
            )
        }
    }
}

private fun TransformingLazyColumnScope.restBlock(
    state: WearHomeState,
    callbacks: WearHomeCallbacks
) {
    if (state.restRemaining <= 0) return
    item {
        Text("⌛", color = WearOg.yellow, style = MaterialTheme.typography.titleMedium)
    }
    item { Text("Descanso", style = MaterialTheme.typography.titleMedium) }
    item { WearClockText(state.restRemaining) }
    item {
        WearPrimaryButton("Saltar descanso", enabled = !state.sessionPaused) {
            callbacks.onSkipRest()
        }
    }
}

private fun TransformingLazyColumnScope.emptyItems(
    state: WearHomeState,
    callbacks: WearHomeCallbacks
) {
    item {
        Text(
            if (state.syncProblem) "No se pudo leer la sesión del teléfono"
            else "Sin plan descargado",
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.titleMedium
        )
    }
    item {
        androidx.compose.foundation.Image(
            painter = androidx.compose.ui.res.painterResource(R.drawable.mascot_watch),
            contentDescription = "Mascota de Repera",
            modifier = Modifier.height(72.dp)
        )
    }
    item {
        WearPrimaryButton("Sincronizar") { callbacks.onSyncRequest() }
    }
}

private fun TransformingLazyColumnScope.pendingItems(
    state: WearHomeState,
    callbacks: WearHomeCallbacks
) {
    if (state.pendingCount <= 0) return
    item {
        Text(
            if (state.pendingCount == 1) "1 serie pendiente de confirmar"
            else "${state.pendingCount} series pendientes de confirmar",
            style = MaterialTheme.typography.labelSmall
        )
    }
    item {
        WearPrimaryButton("Reintentar sincronización") { callbacks.onResendPending() }
    }
    if (state.confirmDiscardPending) {
        item {
            Text(
                "Descartar las series no sincronizadas?",
                textAlign = TextAlign.Center,
                style = MaterialTheme.typography.labelSmall
            )
        }
        item { Button(onClick = { callbacks.onDiscardPending() }) { Text("Sí, descartar") } }
        item { Button(onClick = { callbacks.onDiscardConfirm(false) }) { Text("Cancelar") } }
    } else {
        item {
            Button(onClick = { callbacks.onDiscardConfirm(true) }) { Text("Descartar pendientes") }
        }
    }
}

private fun planFormat(plan: JSONObject): String {
    val exercises = plan.optJSONArray("exercises") ?: return "Fuerza"
    var strength = false
    var wod = false
    var firstWod: String? = null
    for (i in 0 until exercises.length()) {
        val e = exercises.getJSONObject(i)
        if (e.optString("blockKind") == "wod") {
            wod = true
            if (firstWod == null) {
                firstWod = WodFormat.fromWire(e.optString("wodFormat"))?.displayName
            }
        } else strength = true
    }
    return when {
        strength && wod -> "Mixto"
        wod -> firstWod ?: "WOD"
        else -> "Fuerza"
    }
}

private fun planDuration(plan: JSONObject): String {
    val blocks = plan.optJSONArray("routineBlocks") ?: return "Sin límite"
    var cap = 0
    for (i in 0 until blocks.length()) {
        val b = blocks.getJSONObject(i)
        if (b.has("timeCapMinutes") && !b.isNull("timeCapMinutes")) {
            cap += b.optInt("timeCapMinutes")
        }
    }
    return if (cap > 0) "$cap min" else "Sin límite"
}

private fun blockMemberLines(exercises: org.json.JSONArray, start: Int): List<String> {
    if (start !in 0 until exercises.length()) return emptyList()
    val blockId = exercises.getJSONObject(start).optString("blockId").takeIf { it.isNotBlank() }
    val lines = mutableListOf<String>()
    for (i in start until exercises.length()) {
        val e = exercises.getJSONObject(i)
        val id = e.optString("blockId").takeIf { it.isNotBlank() }
        if (i != start && (blockId == null || id != blockId)) break
        val name = e.optJSONObject("exercise")?.optString("name") ?: e.optString("name")
        val plan = e.optJSONArray("plannedSets")
        val reps = plan?.takeIf { it.length() > 0 }?.optJSONObject(0)?.optInt("targetReps")
        lines += if (reps != null && reps > 0) "$name · $reps reps" else name
    }
    return lines
}

private fun wodFace(timer: JSONObject, tick: Int) = WodClock.face(
    WodClockSpec(
        format = WodFormat.fromWire(timer.optString("format")),
        blockTimeCapMinutes = timer.optInt("timeCapMinutes")
            .takeIf { timer.has("timeCapMinutes") && !timer.isNull("timeCapMinutes") },
        intervalSeconds = timer.optInt("intervalSeconds")
            .takeIf { timer.has("intervalSeconds") && !timer.isNull("intervalSeconds") },
        plannedIntervals = timer.optInt("plannedIntervals")
            .takeIf { timer.has("plannedIntervals") && !timer.isNull("plannedIntervals") },
        rounds = timer.optInt("rounds")
            .takeIf { timer.has("rounds") && !timer.isNull("rounds") },
        workSeconds = timer.optInt("workSeconds")
            .takeIf { timer.has("workSeconds") && !timer.isNull("workSeconds") },
        restSeconds = timer.optInt("restSeconds")
            .takeIf { timer.has("restSeconds") && !timer.isNull("restSeconds") },
        restBetweenRoundsSeconds = timer.optInt("restBetweenRoundsSeconds")
            .takeIf {
                timer.has("restBetweenRoundsSeconds") && !timer.isNull("restBetweenRoundsSeconds")
            },
        stations = timer.optInt("stations", 1).coerceAtLeast(1)
    ),
    tick
)

private fun wodFaceSeconds(timer: JSONObject, tick: Int): Int = wodFace(timer, tick).primarySeconds