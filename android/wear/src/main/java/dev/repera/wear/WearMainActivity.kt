package dev.repera.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.text.style.TextAlign
import androidx.wear.compose.material3.AppScaffold
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import org.json.JSONObject
import org.json.JSONArray
import dev.repera.domain.WodFormat
import dev.repera.domain.ResultCapture

/**
 * This first native screen renders only genuine phone-delivered data.
 * Do not simulate workout tracking or recorded sets until SessionController is ported.
 */
class WearMainActivity : ComponentActivity(), DataClient.OnDataChangedListener {
    private val dataClient by lazy { Wearable.getDataClient(this) }
    private var visibleSession by mutableStateOf<WatchSessionSummary?>(null)
    private var syncProblem by mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
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
                                Text(if (syncProblem) "No se pudo leer la sesión del teléfono" else "Sin entrenamiento recibido",
                                    textAlign = TextAlign.Center)
                            } else {
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
                                }
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
        dataClient.dataItems.addOnSuccessListener { items ->
            try {
                for (item in items) {
                    if (item.uri.path == "/repera/active-session") {
                        val bytes = DataMapItem.fromDataItem(item).dataMap.getByteArray("session")
                        runOnUiThread { showSession(bytes) }
                    }
                }
            } finally {
                items.release()
            }
        }
    }

    override fun onStop() {
        dataClient.removeListener(this)
        super.onStop()
    }

    override fun onDataChanged(events: DataEventBuffer) {
        for (event in events) {
            if (event.dataItem.uri.path == "/repera/active-session") {
                if (event.type == com.google.android.gms.wearable.DataEvent.TYPE_DELETED) {
                    runOnUiThread { visibleSession = null; syncProblem = false }
                } else {
                    val bytes = DataMapItem.fromDataItem(event.dataItem).dataMap.getByteArray("session")
                    runOnUiThread { showSession(bytes) }
                }
            }
        }
    }

    private fun showSession(bytes: ByteArray?) {
        if (bytes == null || bytes.isEmpty()) {
            visibleSession = null
            syncProblem = false
            return
        }
        val parsed = runCatching {
            WatchSessionSummary.fromJson(JSONObject(String(bytes, Charsets.UTF_8)))
        }
        visibleSession = parsed.getOrNull()
        syncProblem = parsed.isFailure
    }
}

data class WatchSessionSummary(
    val title: String,
    val exerciseName: String,
    val exerciseIndex: Int,
    val exerciseCount: Int,
    val recordedSets: Int,
    val prescribedReps: Int?,
    val prescribedWeightKg: Double?,
    val wodFormatLabel: String?,
    val globalScore: Boolean,
    val wodMovements: List<String>
) {
    companion object {
        fun fromJson(session: JSONObject): WatchSessionSummary {
            val exercises = session.getJSONArray("exercises")
            require(exercises.length() > 0)
            val index = session.getInt("currentIndex")
            require(index in 0 until exercises.length()) { "Invalid active exercise index" }
            val exercise = exercises.getJSONObject(index)
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
                title = session.getString("title"),
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
                wodMovements = movementLines
            )
        }
    }
}
