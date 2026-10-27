package dev.repera.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.TransformingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberTransformingLazyColumnState
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.IconButton
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.TextButton
import org.json.JSONObject

/** Estado visible de la pantalla principal del reloj (extraído de
 * WearMainActivity para pruebas visuales instrumentadas). */
internal data class WearHomeState(
    val session: WatchSessionSummary?,
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
    val warmup:Boolean=false,val toFailure:Boolean=false
)

internal class WearHomeCallbacks(
    val onDismissFinished: (FinishedSummary) -> Unit = {},
    val onStartTodayPlan: () -> Unit = {},
    val onStartTodayPlanAt: (Int) -> Unit = {},
    val onTogglePause: () -> Unit = {},
    val onSelectBlock: (WatchSessionSummary, Int) -> Unit = { _, _ -> },
    val onFinishSession: (WatchSessionSummary) -> Unit = {},
    val onSkipRest: () -> Unit = {},
    val onRepsMinus: () -> Unit = {},
    val onRepsPlus: () -> Unit = {},
    val onWeightDelta: (Double) -> Unit = {},
    val onRirMinus: () -> Unit = {},
    val onRirPlus: () -> Unit = {},
    val onRirClear: () -> Unit = {},
    val onToggleWarmup:()->Unit = {},val onToggleFailure:()->Unit = {},
    val onDurationDelta: (Int) -> Unit = {},
    val onCycleUnit: () -> Unit = {},
    val onDeficitDelta: (Int) -> Unit = {},
    val onQueueSet: (WatchSessionSummary) -> Unit = {},
    val onResendPending: () -> Unit = {},
    val onDiscardConfirm: (Boolean) -> Unit = {},
    val onDiscardPending: () -> Unit = {}
)

@Composable
internal fun WearHomeContent(
    state: WearHomeState,
    callbacks: WearHomeCallbacks,
    modifier: Modifier = Modifier
) {
    // Viewport redondo: TransformingLazyColumn aplica el padding del primer/
    // último item para centrar en el círculo y la transformación (escala) de
    // cada item según su posición, para que cabecera y controles no queden
    // recortados ni fuera del borde curvo.
    TransformingLazyColumn(
        state = rememberTransformingLazyColumnState(),
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        item { Text("repera", style = MaterialTheme.typography.titleMedium) }
        val session = state.session
        if (session == null) {
            val finishedNow = state.finishedSummary
            if (finishedNow != null) {
                item { Text("Sesión completada",
                    style = MaterialTheme.typography.titleMedium) }
                item { Text(finishedNow.title, textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.labelMedium) }
                item { Text("${finishedNow.minutes} min · " +
                    "${finishedNow.exercises} ejercicios · ${finishedNow.sets} series",
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.labelSmall) }
                item { Button(onClick = { callbacks.onDismissFinished(finishedNow) }) {
                    Text("Cerrar") } }
            } else {
                val plan = state.todayPlan
                if (plan != null) {
                    item { Text("Entreno de hoy",
                        style = MaterialTheme.typography.titleMedium) }
                    item { Text(plan.optString("title"), textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.labelMedium) }
                    item { Text("${plan.optJSONArray("exercises")?.length() ?: 0} ejercicios",
                        style = MaterialTheme.typography.labelSmall) }
                    item { Button(onClick = { callbacks.onStartTodayPlan() }) {
                        Text("Empezar") } }
                    plan.optJSONArray("exercises")?.let { WatchSessionSummary.blocksOf(it) }
                        ?.takeIf { it.size > 1 }?.let { blocks ->
                            item { Text("Empezar en", style = MaterialTheme.typography.labelSmall) }
                            blocks.forEach { (start, header) ->
                                item { TextButton(onClick = { callbacks.onStartTodayPlanAt(start) },
                                    modifier = Modifier.fillMaxWidth()) {
                                    Text(header, style = MaterialTheme.typography.labelSmall, maxLines = 1) } }
                            }
                        }
                } else {
                    item { Text(if (state.syncProblem)
                        "No se pudo leer la sesión del teléfono"
                        else "Sin entrenamiento recibido",
                        textAlign = TextAlign.Center) }
                }
            }
        } else {
            if (state.showingCachedSession) {
                item { Text("Última sesión recibida · sin conexión confirmada",
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.labelSmall) }
            }
            item { Text(session.title, textAlign = TextAlign.Center,
                style = MaterialTheme.typography.labelMedium) }
            state.health?.let { (bpm, kcal) ->
                val text = listOfNotNull(
                    bpm?.let { "$it ppm" },
                    kcal?.let { "${it.toInt()} kcal" }
                ).joinToString(" · ")
                if (text.isNotEmpty()) {
                    item { Text(text, style = MaterialTheme.typography.labelSmall) }
                }
            }
            if (session.wodFormatLabel != null) {
                item { Text(session.wodFormatLabel,
                    style = MaterialTheme.typography.titleMedium) }
                session.wodMovements.forEach { movement ->
                    item { Text(movement, textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.labelSmall) }
                }
                state.wodTimerJson?.takeIf {wearTimerMatches(it,session.sessionId,session.exerciseIndex)}?.let { timer ->
                    val spec = dev.repera.domain.WodClockSpec(
                        format = dev.repera.domain.WodFormat
                            .fromWire(timer.optString("format"))
                            ?: return@let,
                        blockTimeCapMinutes = timer.optInt("timeCapMinutes")
                            .takeIf { timer.has("timeCapMinutes") &&
                                !timer.isNull("timeCapMinutes") },
                        intervalSeconds = timer.optInt("intervalSeconds")
                            .takeIf { timer.has("intervalSeconds") &&
                                !timer.isNull("intervalSeconds") },
                        rounds = timer.optInt("rounds")
                            .takeIf { timer.has("rounds") && !timer.isNull("rounds") },
                        workSeconds = timer.optInt("workSeconds")
                            .takeIf { timer.has("workSeconds") &&
                                !timer.isNull("workSeconds") },
                        restSeconds = timer.optInt("restSeconds")
                            .takeIf { timer.has("restSeconds") &&
                                !timer.isNull("restSeconds") },
                        restBetweenRoundsSeconds = timer.optInt("restBetweenRoundsSeconds")
                            .takeIf { timer.has("restBetweenRoundsSeconds") &&
                                !timer.isNull("restBetweenRoundsSeconds") }
                    )
                    val face = dev.repera.domain.WodClock.face(
                        spec, state.wodTickSeconds)
                    val mins = face.primarySeconds / 60
                    val secs = face.primarySeconds % 60
                    item { Text("%d:%02d".format(mins, secs),
                        style = MaterialTheme.typography.displayMedium) }
                    face.label?.let { label ->
                        item { Text(label, style = MaterialTheme.typography.labelSmall) }
                    }
                }
                item { Button(onClick = { callbacks.onTogglePause() }) {
                    Text(if (state.sessionPaused) "Reanudar" else "Pausar") } }
                item { Text(if (session.globalScore)
                    "Resultado por bloque en el teléfono"
                    else "${session.recordedSets} series registradas",
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.labelSmall) }
            } else {
                item { Text(session.exerciseName,
                    style = MaterialTheme.typography.titleMedium,
                    textAlign = TextAlign.Center) }
                item { Text("Ejercicio ${session.exerciseIndex}/${session.exerciseCount}",
                    style = MaterialTheme.typography.labelSmall) }
                if (session.prescribedReps != null) {
                    item { Text("${session.prescribedReps} ${when(session.quantityUnit) { "meters" -> "m"; "calories" -> "cal"; else -> "reps" }}" +
                        (session.prescribedWeightKg?.let { " · $it kg" }
                            ?: session.prescribedDeficitCm?.let { " · $it cm" } ?: ""),
                        style = MaterialTheme.typography.titleLarge) }
                }
                item { Text("${session.recordedSets} series registradas",
                    style = MaterialTheme.typography.labelSmall) }
                item { Button(onClick = { callbacks.onTogglePause() }) {
                    Text(if (state.sessionPaused) "Reanudar" else "Pausar") } }
                if (session.blocks.size > 1) {
                    item { Text("Ir a", style = MaterialTheme.typography.labelSmall) }
                    session.blocks.forEach { (start, name) ->
                        item { TextButton(enabled = start != session.exerciseIndex - 1,
                            onClick = { callbacks.onSelectBlock(session, start) },
                            modifier = Modifier.fillMaxWidth()) {
                            Text(name, style = MaterialTheme.typography.labelSmall, maxLines = 1) } }
                    }
                }
                if (!session.canLogOnWatch) {
                    item { Text("Este ejercicio solo se registra en el móvil",
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.labelSmall) }
                } else {
                    if (state.restRemaining > 0) {
                        item { Text("Descanso: ${state.restRemaining}s",
                            style = MaterialTheme.typography.titleLarge) }
                        item { TextButton(onClick = { callbacks.onSkipRest() },
                            modifier = Modifier.fillMaxWidth()) {
                            Text("Saltar descanso",
                                style = MaterialTheme.typography.labelSmall) } }
                    }
                    item { Text("Registrar serie",
                        style = MaterialTheme.typography.titleMedium) }
                    if(!session.mobilityHold) item {
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                            verticalAlignment = Alignment.CenterVertically) {
                            IconButton(onClick = { callbacks.onRepsMinus() }) {
                                Text("−") }
                            Text("${state.repsInput} ${if(session.inputMode in setOf("machineWork","loadDistance")) (if(state.unitInput=="meters") "m" else "cal") else "reps"}",
                                style = MaterialTheme.typography.titleMedium)
                            IconButton(onClick = { callbacks.onRepsPlus() }) {
                                Text("+") }
                        }
                    }
                    if (session.allowsWeight) {
                        item {
                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                                verticalAlignment = Alignment.CenterVertically) {
                                IconButton(onClick = { callbacks.onWeightDelta(-0.1) }) {
                                    Text("−") }
                                Text("${state.weightInput ?: 0.0} kg",
                                    style = MaterialTheme.typography.titleMedium)
                                IconButton(onClick = { callbacks.onWeightDelta(0.1) }) {
                                    Text("+") }
                            }
                        }
                    }
                    if(session.inputMode in setOf("strength","hspuDeficit","repsOnly")) {
                        item {TextButton(onClick={callbacks.onToggleWarmup()}) {Text(if(state.warmup) "Calentamiento ✓" else "Serie de trabajo")}}
                        if(!state.warmup) {
                    item {
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                            verticalAlignment = Alignment.CenterVertically) {
                            IconButton(onClick = { callbacks.onRirMinus() }) { Text("−") }
                            Text(state.rirInput?.let { "RIR ${it.toInt()}" } ?: "RIR —",
                                style = MaterialTheme.typography.titleMedium)
                            IconButton(onClick = { callbacks.onRirPlus() }) { Text("+") }
                        }
                    }
                    item {
                        TextButton(onClick = { callbacks.onRirClear() },
                            modifier = Modifier.fillMaxWidth()) {
                            Text("Sin RIR", style = MaterialTheme.typography.labelSmall)
                        }
                    }
                            item {TextButton(onClick={callbacks.onToggleFailure()}) {Text(if(state.toFailure) "Al fallo ✓" else "Al fallo: no")}}
                        }
                    }
                    if (session.inputMode in setOf("repsAndTime","machineWork")) {
                        item {
                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                                verticalAlignment = Alignment.CenterVertically) {
                                IconButton(onClick = { callbacks.onDurationDelta(-5) }) {
                                    Text("−") }
                                Text("${state.durationInput} s",
                                    style = MaterialTheme.typography.titleMedium)
                                IconButton(onClick = { callbacks.onDurationDelta(5) }) {
                                    Text("+") }
                            }
                        }
                    }
                    if (session.inputMode == "machineWork") {
                        val label = when (state.unitInput) {
                            "calories" -> "kcal"
                            "meters" -> "m"
                            else -> "reps"
                        }
                        if(session.allowsUnitToggle) item { Button(onClick = { callbacks.onCycleUnit() }) {
                            Text("Unidad: $label") } }
                    }
                    if (session.inputMode == "hspuDeficit") {
                        item {
                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                                verticalAlignment = Alignment.CenterVertically) {
                                IconButton(onClick = { callbacks.onDeficitDelta(-1) }) {
                                    Text("−") }
                                Text("${state.deficitInput} cm",
                                    style = MaterialTheme.typography.titleMedium)
                                IconButton(onClick = { callbacks.onDeficitDelta(1) }) {
                                    Text("+") }
                            }
                        }
                    }
                    item {
                        Button(onClick = { callbacks.onQueueSet(session) },
                            enabled = state.repsInput > 0 && !state.sessionPaused,
                            modifier = Modifier.fillMaxWidth()) {
                            Text("Confirmar serie")
                        }
                    }
                }
            }
        }
        if(session!=null) item {
            TextButton(onClick={callbacks.onFinishSession(session)},modifier=Modifier.fillMaxWidth()) {
                Text("Terminar sesión",style=MaterialTheme.typography.labelSmall)
            }
        }
        if (state.pendingCount > 0) {
            item { Text(if (state.pendingCount == 1)
                "1 serie pendiente de confirmar"
            else
                "${state.pendingCount} series pendientes de confirmar",
                style = MaterialTheme.typography.labelSmall) }
            item { Button(onClick = { callbacks.onResendPending() },
                modifier = Modifier.fillMaxWidth()) {
                Text("Reintentar sincronización") } }
            if (state.confirmDiscardPending) {
                item { Text("Descartar las series no sincronizadas?",
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.labelSmall) }
                item { Button(onClick = { callbacks.onDiscardPending() }) {
                    Text("Sí, descartar") } }
                item { Button(onClick = { callbacks.onDiscardConfirm(false) }) {
                    Text("Cancelar") } }
            } else {
                item { Button(onClick = { callbacks.onDiscardConfirm(true) }) {
                    Text("Descartar pendientes") } }
            }
        }
        state.sendStatus?.let {
            item { Text(it, style = MaterialTheme.typography.labelSmall,
                textAlign = TextAlign.Center) }
        }
    }
}
