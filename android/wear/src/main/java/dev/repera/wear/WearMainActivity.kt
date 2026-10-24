package dev.repera.wear

import android.os.Bundle
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.text.style.TextAlign
import androidx.wear.compose.material3.AppScaffold
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.TextButton
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import org.json.JSONObject
import org.json.JSONArray
import dev.repera.domain.ExerciseInput
import dev.repera.domain.ExerciseInputMode
import dev.repera.domain.WodFormat
import dev.repera.domain.ResultCapture

/**
 * This first native screen renders only genuine phone-delivered data.
 * Do not simulate workout tracking or recorded sets until SessionController is ported.
 */
class WearMainActivity : ComponentActivity(), DataClient.OnDataChangedListener,
    MessageClient.OnMessageReceivedListener {
    private val dataClient by lazy { Wearable.getDataClient(this) }
    private val messageClient by lazy { Wearable.getMessageClient(this) }
    private val pendingStore by lazy { WearPendingSetStore(this) }
    private var repsInput by mutableStateOf(0)
    private var weightInput by mutableStateOf<Double?>(null)
    private var rirInput by mutableStateOf<Double?>(null)
    private var finishedSummary by mutableStateOf<FinishedSummary?>(null)
    private var restRemaining by mutableStateOf(0)
    private var restJob: kotlinx.coroutines.Job? = null
    private var confirmDiscardPending by mutableStateOf(false)
    private var pendingCount by mutableStateOf(0)
    private var sendStatus by mutableStateOf<String?>(null)
    private var visibleSession by mutableStateOf<WatchSessionSummary?>(null)
    private var syncProblem by mutableStateOf(false)
    private var showingCachedSession by mutableStateOf(false)
    private val sessionCache by lazy { getSharedPreferences("repera.wear.session", MODE_PRIVATE) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingCount = runCatching { pendingStore.count() }.getOrElse {
            sendStatus = "Error leyendo las series pendientes; no se han eliminado"
            0
        }
        // Read-only recovery: no locally confirmed set is written to the phone.
        sessionCache.getString("snapshot", null)?.let { cached ->
            val restored = runCatching { WatchSessionSummary.fromJson(JSONObject(cached)) }.getOrNull()
            if (restored != null) {
                visibleSession = restored
                showingCachedSession = true
            } else {
                sessionCache.edit().remove("snapshot").apply()
            }
        }
        setContent {
            MaterialTheme(colorScheme = MaterialTheme.colorScheme.copy(
                primary = Color(0xFF30D158), onPrimary = Color.Black
            )) {
                AppScaffold {
                    ScreenScaffold { insets ->
                        Column(
                            modifier = Modifier.fillMaxSize().padding(insets)
                                .verticalScroll(rememberScrollState())
                                .padding(horizontal = 16.dp),
                            verticalArrangement = Arrangement.Center,
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text("repera", style = MaterialTheme.typography.titleMedium)
                            Spacer(Modifier.height(6.dp))
                            val session = visibleSession
                            if (session == null) {
                                val finishedNow = finishedSummary
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
                                    Button(onClick = {
                                        sessionCache.edit().putString(
                                            "finishedDismissed", finishedNow.sessionId).apply()
                                        finishedSummary = null
                                    }) { Text("Cerrar") }
                                } else {
                                Text(if (syncProblem) "No se pudo leer la sesión del teléfono" else "Sin entrenamiento recibido",
                                    textAlign = TextAlign.Center)
                                }
                            } else {
                                if (showingCachedSession) {
                                    Text("Última sesión recibida · sin conexión confirmada",
                                        textAlign = TextAlign.Center,
                                        style = MaterialTheme.typography.labelSmall)
                                }
                                Text(session.title, textAlign = TextAlign.Center,
                                    style = MaterialTheme.typography.labelMedium)
                                Spacer(Modifier.height(6.dp))
                                if (session.wodFormatLabel != null) {
                                    Text(session.wodFormatLabel,
                                        style = MaterialTheme.typography.titleMedium)
                                    session.wodMovements.forEach { movement ->
                                        Text(movement, textAlign = TextAlign.Center,
                                            style = MaterialTheme.typography.labelSmall)
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
                                    if (!session.canLogOnWatch) {
                                        Text("Este ejercicio requiere registrar cal, metros o tiempo en el móvil",
                                            textAlign = TextAlign.Center,
                                            style = MaterialTheme.typography.labelSmall)
                                    } else {
                                    if (restRemaining > 0) {
                                        Text("Descanso: ${restRemaining}s",
                                            style = MaterialTheme.typography.titleLarge)
                                        TextButton(onClick = { skipRest() }) {
                                            Text("Saltar descanso",
                                                style = MaterialTheme.typography.labelSmall)
                                        }
                                    }
                                    Text("Registrar serie", style = MaterialTheme.typography.titleMedium)
                                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                                        verticalAlignment = Alignment.CenterVertically) {
                                        Button(onClick = { repsInput = (repsInput - 1).coerceAtLeast(0) }) {
                                            Text("−")
                                        }
                                        Text("$repsInput reps", style = MaterialTheme.typography.titleMedium)
                                        Button(onClick = { repsInput = (repsInput + 1).coerceAtMost(10000) }) {
                                            Text("+")
                                        }
                                    }
                                    if (session.allowsWeight) {
                                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                                            verticalAlignment = Alignment.CenterVertically) {
                                            Button(onClick = {
                                                weightInput = ((weightInput ?: 0.0) - 0.5)
                                                    .coerceAtLeast(0.0)
                                            }) { Text("−") }
                                            Text("${weightInput ?: 0.0} kg",
                                                style = MaterialTheme.typography.titleMedium)
                                            Button(onClick = {
                                                weightInput = ((weightInput ?: 0.0) + 0.5)
                                                    .coerceAtMost(2000.0)
                                            }) { Text("+") }
                                        }
                                    }
                                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                                        verticalAlignment = Alignment.CenterVertically) {
                                        Button(onClick = {
                                            rirInput = ((rirInput ?: 3.0) - 1).coerceAtLeast(0.0)
                                        }) { Text("−") }
                                        Text(rirInput?.let { "RIR ${it.toInt()}" } ?: "RIR —",
                                            style = MaterialTheme.typography.titleMedium)
                                        Button(onClick = {
                                            rirInput = ((rirInput ?: 1.0) + 1).coerceAtMost(5.0)
                                        }) { Text("+") }
                                    }
                                    TextButton(onClick = { rirInput = null }) {
                                        Text("Sin RIR", style = MaterialTheme.typography.labelSmall)
                                    }
                                    Button(onClick = { queueSet(session) },
                                        enabled = repsInput > 0,
                                        modifier = Modifier.fillMaxWidth()) {
                                        Text("Confirmar serie")
                                    }
                                    }
                                }
                            }
                            if (pendingCount > 0) {
                                Text("$pendingCount series pendientes de confirmar",
                                    style = MaterialTheme.typography.labelSmall)
                                Button(onClick = { resendPending() },
                                    modifier = Modifier.fillMaxWidth()) {
                                    Text("Reintentar sincronización")
                                }
                                if (confirmDiscardPending) {
                                    Text("Descartar las series no sincronizadas?",
                                        textAlign = TextAlign.Center,
                                        style = MaterialTheme.typography.labelSmall)
                                    Button(onClick = {
                                        val dropped = runCatching {
                                            pendingStore.clear()
                                            pendingCount = 0
                                        }.isSuccess
                                        confirmDiscardPending = false
                                        sendStatus = if (dropped) "Series pendientes descartadas"
                                            else "No se pudieron descartar los registros"
                                    }) { Text("Sí, descartar") }
                                    Button(onClick = { confirmDiscardPending = false }) {
                                        Text("Cancelar")
                                    }
                                } else {
                                    Button(onClick = { confirmDiscardPending = true }) {
                                        Text("Descartar pendientes")
                                    }
                                }
                            }
                            sendStatus?.let {
                                Text(it, style = MaterialTheme.typography.labelSmall,
                                    textAlign = TextAlign.Center)
                            }
                        }
                    }
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()
        dataClient.addListener(this)
        messageClient.addListener(this)
        resendPending()
        dataClient.dataItems.addOnSuccessListener { items ->
            try {
                for (item in items) {
                    if (item.uri.path == "/repera/active-session") {
                        val data = DataMapItem.fromDataItem(item).dataMap
                        val bytes = data.getByteArray("session")
                        val finished = data.getByteArray("finished")
                        val signedOut = data.getBoolean("signedOut")
                        runOnUiThread { showSession(bytes, signedOut, finished) }
                    }
                }
            } finally {
                items.release()
            }
        }
    }

    override fun onStop() {
        messageClient.removeListener(this)
        dataClient.removeListener(this)
        super.onStop()
    }

    override fun onDataChanged(events: DataEventBuffer) {
        for (event in events) {
            if (event.dataItem.uri.path == "/repera/active-session") {
                val data = DataMapItem.fromDataItem(event.dataItem).dataMap
                val bytes = data.getByteArray("session")
                val finished = data.getByteArray("finished")
                val signedOut = data.getBoolean("signedOut")
                runOnUiThread { showSession(bytes, signedOut, finished) }
            }
        }
    }

    override fun onMessageReceived(event: MessageEvent) {
        if (event.path != "/repera/log-set-ack") return
        val ack = runCatching { JSONObject(String(event.data, Charsets.UTF_8)) }.getOrNull()
            ?: return
        runOnUiThread {
            val id = ack.optString("id")
            when (ack.optString("status")) {
                "saved" -> {
                    val cleared = runCatching {
                        pendingStore.remove(id)
                        pendingCount = pendingStore.count()
                    }.isSuccess
                    sendStatus = when {
                        !cleared -> "No se pudo confirmar la serie; permanece en el reloj"
                        pendingCount == 0 -> "Series sincronizadas"
                        else -> "$pendingCount series pendientes"
                    }
                }
                "rejected" -> sendStatus =
                    "La sesión del teléfono cambió; revisa las series pendientes"
                else -> sendStatus = "Sin conexión confirmada; las series siguen guardadas"
            }
        }
    }

    private fun queueSet(session: WatchSessionSummary) {
        if (!session.canLogOnWatch || session.wodFormatLabel != null ||
            repsInput !in 1..10000) return
        val queued = runCatching {
            pendingStore.append(session.sessionId, session.exerciseIndex - 1,
                repsInput, weightInput, rirInput)
            pendingCount = pendingStore.count()
        }
        if (queued.isFailure) {
            sendStatus = "No se pudo guardar la serie en el reloj: " +
                (queued.exceptionOrNull()?.localizedMessage ?: "revisa el almacenamiento")
            return
        }
        sendStatus = "Serie guardada en el reloj; esperando confirmación"
        if (session.restSeconds > 0 &&
            session.recordedSets + 1 < session.plannedWorkSets) {
            startRest(session.restSeconds)
        }
        resendPending()
    }

    private fun startRest(seconds: Int) {
        restJob?.cancel()
        restJob = lifecycleScope.launch {
            restRemaining = seconds
            while (restRemaining > 0) {
                kotlinx.coroutines.delay(1000)
                restRemaining -= 1
            }
        }
    }

    private fun skipRest() {
        restJob?.cancel()
        restRemaining = 0
    }

    private fun resendPending() {
        val commands = runCatching { pendingStore.all() }.getOrElse {
            sendStatus = "No se puede leer la cola; los datos siguen guardados"
            return
        }
        if (commands.isEmpty()) return
        Wearable.getNodeClient(this).connectedNodes
            .addOnSuccessListener { nodes ->
                if (nodes.isEmpty()) {
                    runOnUiThread { sendStatus = "Sin teléfono conectado · serie conservada" }
                } else {
                    for (node in nodes) for (command in commands) {
                        messageClient.sendMessage(node.id, "/repera/log-set",
                            command.toString().toByteArray(Charsets.UTF_8))
                    }
                }
            }.addOnFailureListener {
                runOnUiThread { sendStatus = "Pendiente de conexión con el teléfono" }
            }
    }

    private fun showSession(bytes: ByteArray?, signedOut: Boolean = false,
                            finished: ByteArray? = null) {
        if (signedOut) {
            finishedSummary = null
            sessionCache.edit().remove("finishedDismissed").apply()
            clearSession(erasePending = true)
            return
        }
        finishedSummary = FinishedSummary.fromBytes(finished)
            ?.takeIf { it.sessionId != sessionCache.getString("finishedDismissed", null) }
        if (bytes == null || bytes.isEmpty()) {
            // A finished workout is NOT account logout. Never discard unacknowledged
            // sets because the phone has completed the active session.
            clearSession(erasePending = false)
            return
        }
        val raw = String(bytes, Charsets.UTF_8)
        val parsed = runCatching { WatchSessionSummary.fromJson(JSONObject(raw)) }
        val summary = parsed.getOrNull()
        if (summary != null) {
            // Persist only a validated session; a malformed update cannot corrupt recovery.
            sessionCache.edit().putString("snapshot", raw).apply()
            if (visibleSession?.sessionId != summary.sessionId ||
                visibleSession?.exerciseIndex != summary.exerciseIndex) {
                repsInput = summary.prescribedReps ?: 0
                weightInput = summary.prescribedWeightKg
            }
            visibleSession = summary
            resendPending()
            showingCachedSession = false
            syncProblem = false
        } else {
            syncProblem = true
            // Keep the last valid summary but never claim the corrupted update succeeded.
        }
    }

    private fun clearSession(erasePending: Boolean) {
        sessionCache.edit().remove("snapshot").apply()
        val outboxCleared = if (erasePending) runCatching {
            pendingStore.clear()
        }.isSuccess else true
        if (erasePending && outboxCleared) pendingCount = 0
        repsInput = 0
        weightInput = null
        confirmDiscardPending = false
        sendStatus = if (outboxCleared) null
            else "No se pudo borrar la cola privada; revisa el reloj"
        visibleSession = null
        syncProblem = false
        showingCachedSession = false
        skipRest()
    }
}

data class WatchSessionSummary(
    val sessionId: String,
    val title: String,
    val canLogOnWatch: Boolean,
    val allowsWeight: Boolean,
    val exerciseName: String,
    val exerciseIndex: Int,
    val exerciseCount: Int,
    val recordedSets: Int,
    val prescribedReps: Int?,
    val prescribedWeightKg: Double?,
    val wodFormatLabel: String?,
    val globalScore: Boolean,
    val wodMovements: List<String>,
    val plannedWorkSets: Int = 0,
    val restSeconds: Int = 0
) {
    companion object {
        fun fromJson(session: JSONObject): WatchSessionSummary {
            val exercises = session.getJSONArray("exercises")
            require(exercises.length() > 0)
            val index = session.getInt("currentIndex")
            require(index in 0 until exercises.length()) { "Invalid active exercise index" }
            val exercise = exercises.getJSONObject(index)
            val sourceExercise = exercise.getJSONObject("exercise")
            val mode = ExerciseInput.mode(sourceExercise.getString("name"),
                sourceExercise.optString("equipment"), sourceExercise.optString("targetMuscle"),
                sourceExercise.optString("muscleGroup"),
                sourceExercise.optString("sportTag"))
            val recorded = exercise.optJSONArray("loggedSets") ?: JSONArray()
            val done = (0 until recorded.length()).count {
                recorded.getJSONObject(it).optString("phase", "work") == "work"
            }
            val plan = exercise.optJSONArray("plannedSets")
            val target = plan?.takeIf { it.length() > 0 }?.getJSONObject(
                minOf(done, plan.length() - 1)
            )
            val wodFormat = WodFormat.fromWire(exercise.optString("wodFormat"))
            val globalScore = wodFormat?.capture?.let {
                it != ResultCapture.PER_MOVEMENT_SETS
            } ?: false
            val blockId = exercise.optString("blockId")
            val sourceBlocks = session.optJSONArray("routineBlocks") ?: JSONArray()
            val original = (0 until sourceBlocks.length())
                .map { sourceBlocks.getJSONObject(it) }
                .firstOrNull { it.optString("id") == blockId }
            val sourceMoves = original?.optJSONArray("movements") ?: JSONArray()
            val movementLines = (0 until sourceMoves.length()).map { n ->
                val item = sourceMoves.getJSONObject(n)
                val prefix = when {
                    item.optBoolean("isRest") ->
                        "${item.optInt("restSeconds", 60)}s descanso"
                    (item.optJSONArray("repScheme")?.length() ?: 0) > 0 -> {
                        val scheme = item.getJSONArray("repScheme")
                        (0 until scheme.length()).joinToString("-") { scheme.getInt(it).toString() }
                    }
                    item.has("calories") -> "${item.optInt("calories")} cal"
                    item.has("distanceMeters") -> "${item.optInt("distanceMeters")} m"
                    item.has("reps") -> "${item.optInt("reps")} reps"
                    else -> ""
                }
                (prefix + " " + item.optString("name")).trim()
            }
            return WatchSessionSummary(
                sessionId = session.getString("id"),
                title = session.getString("title"),
                canLogOnWatch = mode in setOf(
                    ExerciseInputMode.LOAD_REPS, ExerciseInputMode.REPS_ONLY) &&
                    exercise.optString("blockKind") != "wod",
                allowsWeight = mode.showsWeight,
                exerciseName = exercise.getJSONObject("exercise").getString("name"),
                exerciseIndex = index + 1,
                exerciseCount = exercises.length(),
                recordedSets = done,
                prescribedReps = if (globalScore) null else target?.optInt("targetReps"),
                prescribedWeightKg = if (globalScore) null else target?.takeIf {
                    it.has("targetWeightKg") && !it.isNull("targetWeightKg")
                }?.getDouble("targetWeightKg"),
                wodFormatLabel = wodFormat?.displayName,
                globalScore = globalScore,
                wodMovements = movementLines,
                plannedWorkSets = plan?.length() ?: 0,
                restSeconds = exercise.optInt("restSeconds",
                    exercise.optInt("blockRestSeconds", 0))
            )
        }
    }
}

internal data class FinishedSummary(
    val sessionId: String,
    val title: String,
    val minutes: Int,
    val exercises: Int,
    val sets: Int
) {
    companion object {
        fun fromBytes(bytes: ByteArray?): FinishedSummary? {
            if (bytes == null || bytes.isEmpty()) return null
            val w = runCatching {
                JSONObject(String(bytes, Charsets.UTF_8))
            }.getOrNull() ?: return null
            val id = w.optString("id").takeIf { it.isNotBlank() } ?: return null
            val start = w.optString("startedAt")
            val end = w.optString("finishedAt")
            val minutes = runCatching {
                ((java.time.Instant.parse(end).toEpochMilli() -
                    java.time.Instant.parse(start).toEpochMilli()) / 60000).toInt()
            }.getOrDefault(0)
            val exercises = w.optJSONArray("exercises")
            val sets = if (exercises == null) 0 else (0 until exercises.length()).sumOf { i ->
                val logged = exercises.optJSONObject(i)?.optJSONArray("loggedSets")
                logged?.length() ?: 0
            }
            return FinishedSummary(id, w.optString("title").ifBlank { "Entrenamiento" },
                minutes, exercises?.length() ?: 0, sets)
        }
    }
}
