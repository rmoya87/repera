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
import androidx.wear.compose.material3.Button
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
    val sendStatus: String?
)

internal class WearHomeCallbacks(
    val onDismissFinished: (FinishedSummary) -> Unit = {},
    val onStartTodayPlan: () -> Unit = {},
    val onTogglePause: () -> Unit = {},
    val onFinishSession: (WatchSessionSummary) -> Unit = {},
    val onSkipRest: () -> Unit = {},
    val onRepsMinus: () -> Unit = {},
    val onRepsPlus: () -> Unit = {},
    val onWeightDelta: (Double) -> Unit = {},
    val onRirMinus: () -> Unit = {},
    val onRirPlus: () -> Unit = {},
    val onRirClear: () -> Unit = {},
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
Column(
        modifier = modifier
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp),
                            verticalArrangement = Arrangement.Center,
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text("repera", style = MaterialTheme.typography.titleMedium)
                            Spacer(Modifier.height(6.dp))
                            val session = state.session
                            if (session == null) {
                                val finishedNow = state.finishedSummary
                                if (finishedNow != null) {
                                    Text("Sesión completada",
                                        style = MaterialTheme.typography.titleMedium)
                                    Text(finishedNow.title, textAlign = TextAlign.Center,
                                        style = MaterialTheme.typography.labelMedium)
                                    Text("${finishedNow.minutes} min · " +
                                        "${finishedNow.exercises} ejercicios · " +
                                        "${finishedNow.sets} series",
                                        textAlign = TextAlign.Center,
                                        style = MaterialTheme.typography.labelSmall)
                                    Button(onClick = { callbacks.onDismissFinished(finishedNow) }) { Text("Cerrar") }
                                } else {
                                val plan = state.todayPlan
                                if (plan != null) {
                                    Text("Entreno de hoy",
                                        style = MaterialTheme.typography.titleMedium)
                                    Text(plan.optString("title"),
                                        textAlign = TextAlign.Center,
                                        style = MaterialTheme.typography.labelMedium)
                                    Text("${plan.optJSONArray("exercises")?.length() ?: 0} ejercicios",
                                        style = MaterialTheme.typography.labelSmall)
                                    Button(onClick = { callbacks.onStartTodayPlan() }) {
                                        Text("Empezar")
                                    }
                                } else {
                                Text(if (state.syncProblem) "No se pudo leer la sesión del teléfono" else "Sin entrenamiento recibido",
                                    textAlign = TextAlign.Center)
                                }
                                }
                            } else {
                                if (state.showingCachedSession) {
                                    Text("Última sesión recibida · sin conexión confirmada",
                                        textAlign = TextAlign.Center,
                                        style = MaterialTheme.typography.labelSmall)
                                }
                                Text(session.title, textAlign = TextAlign.Center,
                                    style = MaterialTheme.typography.labelMedium)
                                state.health?.let { (bpm, kcal) ->
                                    Text(
                                        listOfNotNull(
                                            bpm?.let { "$it ppm" },
                                            kcal?.let { "${it.toInt()} kcal" }
                                        ).joinToString(" · "),
                                        style = MaterialTheme.typography.labelSmall)
                                }
                                Spacer(Modifier.height(6.dp))
                                if (session.wodFormatLabel != null) {
                                    Text(session.wodFormatLabel,
                                        style = MaterialTheme.typography.titleMedium)
                                    session.wodMovements.forEach { movement ->
                                        Text(movement, textAlign = TextAlign.Center,
                                            style = MaterialTheme.typography.labelSmall)
                                    }
                                    state.wodTimerJson?.let { timer ->
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
                                                .takeIf { timer.has("rounds") &&
                                                    !timer.isNull("rounds") },
                                            workSeconds = timer.optInt("workSeconds")
                                                .takeIf { timer.has("workSeconds") &&
                                                    !timer.isNull("workSeconds") },
                                            restSeconds = timer.optInt("restSeconds")
                                                .takeIf { timer.has("restSeconds") &&
                                                    !timer.isNull("restSeconds") },
                                            restBetweenRoundsSeconds = timer
                                                .optInt("restBetweenRoundsSeconds")
                                                .takeIf { timer.has("restBetweenRoundsSeconds") &&
                                                    !timer.isNull("restBetweenRoundsSeconds") }
                                        )
                                        val face = dev.repera.domain.WodClock.face(
                                            spec, state.wodTickSeconds)
                                        val mins = face.primarySeconds / 60
                                        val secs = face.primarySeconds % 60
                                        Text("%d:%02d".format(mins, secs),
                                            style = MaterialTheme.typography.displayMedium)
                                        face.label?.let {
                                            Text(it,
                                                style = MaterialTheme.typography.labelSmall)
                                        }
                                    }
                                    Button(onClick = { callbacks.onTogglePause() }) {
                                        Text(if (state.sessionPaused) "Reanudar" else "Pausar")
                                    }
                                    if (session.globalScore) {
                                        Text("Resultado por bloque en el teléfono",
                                            textAlign = TextAlign.Center,
                                            style = MaterialTheme.typography.labelSmall)
                                    } else {
                                        Text("${session.recordedSets} series registradas",
                                            style = MaterialTheme.typography.labelSmall)
                                    }
                                } else {
                                    Text(session.exerciseName,
                                        style = MaterialTheme.typography.titleMedium,
                                        textAlign = TextAlign.Center)
                                    Text("Ejercicio ${session.exerciseIndex}/${session.exerciseCount}")
                                    if (session.prescribedReps != null) {
                                        Text("${session.prescribedReps} reps" +
                                            (session.prescribedWeightKg?.let { " · $it kg" } ?: ""),
                                            style = MaterialTheme.typography.titleLarge)
                                    }
                                    Text("${session.recordedSets} series registradas",
                                        style = MaterialTheme.typography.labelSmall)
                                    Button(onClick = { callbacks.onTogglePause() }) {
                                        Text(if (state.sessionPaused) "Reanudar" else "Pausar")
                                    }
                                    TextButton(onClick = { callbacks.onFinishSession(session) }) {
                                        Text("Terminar sesión",
                                            style = MaterialTheme.typography.labelSmall)
                                    }
                                    if (!session.canLogOnWatch) {
                                        Text("Este ejercicio solo se registra en el móvil",
                                            textAlign = TextAlign.Center,
                                            style = MaterialTheme.typography.labelSmall)
                                    } else {
                                    if (state.restRemaining > 0) {
                                        Text("Descanso: ${state.restRemaining}s",
                                            style = MaterialTheme.typography.titleLarge)
                                        TextButton(onClick = { callbacks.onSkipRest() }) {
                                            Text("Saltar descanso",
                                                style = MaterialTheme.typography.labelSmall)
                                        }
                                    }
                                    Text("Registrar serie", style = MaterialTheme.typography.titleMedium)
                                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                                        verticalAlignment = Alignment.CenterVertically) {
                                        Button(onClick = { callbacks.onRepsMinus() }) {
                                            Text("−")
                                        }
                                        Text("${state.repsInput} reps", style = MaterialTheme.typography.titleMedium)
                                        Button(onClick = { callbacks.onRepsPlus() }) {
                                            Text("+")
                                        }
                                    }
                                    if (session.allowsWeight) {
                                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                                            verticalAlignment = Alignment.CenterVertically) {
                                            Button(onClick = { callbacks.onWeightDelta(-0.5) }) { Text("−") }
                                            Text("${state.weightInput ?: 0.0} kg",
                                                style = MaterialTheme.typography.titleMedium)
                                            Button(onClick = { callbacks.onWeightDelta(0.5) }) { Text("+") }
                                        }
                                    }
                                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                                        verticalAlignment = Alignment.CenterVertically) {
                                        Button(onClick = { callbacks.onRirMinus() }) { Text("−") }
                                        Text(state.rirInput?.let { "RIR ${it.toInt()}" } ?: "RIR —",
                                            style = MaterialTheme.typography.titleMedium)
                                        Button(onClick = { callbacks.onRirPlus() }) { Text("+") }
                                    }
                                    TextButton(onClick = { callbacks.onRirClear() }) {
                                        Text("Sin RIR", style = MaterialTheme.typography.labelSmall)
                                    }
                                    if (session.inputMode == "repsAndTime") {
                                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                                            verticalAlignment = Alignment.CenterVertically) {
                                            Button(onClick = { callbacks.onDurationDelta(-5) }) { Text("−") }
                                            Text("${state.durationInput} s",
                                                style = MaterialTheme.typography.titleMedium)
                                            Button(onClick = { callbacks.onDurationDelta(5) }) {
                                                Text("+")
                                            }
                                        }
                                    }
                                    if (session.inputMode == "machineWork") {
                                        val label = when (state.unitInput) {
                                            "calories" -> "kcal"
                                            "meters" -> "m"
                                            else -> "reps"
                                        }
                                        Button(onClick = { callbacks.onCycleUnit() }) { Text("Unidad: $label") }
                                    }
                                    if (session.inputMode == "hspuDeficit") {
                                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                                            verticalAlignment = Alignment.CenterVertically) {
                                            Button(onClick = { callbacks.onDeficitDelta(-1) }) { Text("−") }
                                            Text("${state.deficitInput} cm",
                                                style = MaterialTheme.typography.titleMedium)
                                            Button(onClick = { callbacks.onDeficitDelta(1) }) {
                                                Text("+")
                                            }
                                        }
                                    }
                                    Button(onClick = { callbacks.onQueueSet(session) },
                                        enabled = state.repsInput > 0,
                                        modifier = Modifier.fillMaxWidth()) {
                                        Text("Confirmar serie")
                                    }
                                    }
                                }
                            }
                            if (state.pendingCount > 0) {
                                Text(if (state.pendingCount == 1)
                                    "1 serie pendiente de confirmar"
                                else
                                    "${state.pendingCount} series pendientes de confirmar",
                                    style = MaterialTheme.typography.labelSmall)
                                Button(onClick = { callbacks.onResendPending() },
                                    modifier = Modifier.fillMaxWidth()) {
                                    Text("Reintentar sincronización")
                                }
                                if (state.confirmDiscardPending) {
                                    Text("Descartar las series no sincronizadas?",
                                        textAlign = TextAlign.Center,
                                        style = MaterialTheme.typography.labelSmall)
                                    Button(onClick = { callbacks.onDiscardPending() }) { Text("Sí, descartar") }
                                    Button(onClick = { callbacks.onDiscardConfirm(false) }) {
                                        Text("Cancelar")
                                    }
                                } else {
                                    Button(onClick = { callbacks.onDiscardConfirm(true) }) {
                                        Text("Descartar pendientes")
                                    }
                                }
                            }
                            state.sendStatus?.let {
                                Text(it, style = MaterialTheme.typography.labelSmall,
                                    textAlign = TextAlign.Center)
                            }
                        }
}
