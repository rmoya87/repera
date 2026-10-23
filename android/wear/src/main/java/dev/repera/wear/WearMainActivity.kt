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
import androidx.compose.foundation.layout.widthIn
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

/**
 * This first native screen renders only genuine phone-delivered data.
 * Do not simulate workout tracking or recorded sets until SessionController is ported.
 */
class WearMainActivity : ComponentActivity(), DataClient.OnDataChangedListener {
    private val dataClient by lazy { Wearable.getDataClient(this) }
    private var visibleSession by mutableStateOf<WatchSessionSummary?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                AppScaffold {
                    ScreenScaffold { insets ->
                        Column(
                            modifier = Modifier.fillMaxSize().padding(insets)
                                .padding(horizontal = 16.dp),
                            verticalArrangement = Arrangement.Center,
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text("repera", style = MaterialTheme.typography.titleMedium)
                            Spacer(Modifier.height(6.dp))
                            val session = visibleSession
                            if (session == null) {
                                Text("Sin entrenamiento recibido",
                                    textAlign = TextAlign.Center)
                            } else {
                                Text(session.title, textAlign = TextAlign.Center,
                                    style = MaterialTheme.typography.labelMedium)
                                Spacer(Modifier.height(6.dp))
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

    override fun onStart() {
        super.onStart()
        dataClient.addListener(this)
        dataClient.dataItems.addOnSuccessListener { items ->
            try {
                for (item in items) {
                    if (item.uri.path == "/repera/active-session") {
                        val bytes = DataMapItem.fromDataItem(item).dataMap.getByteArray("session")
                        showSession(bytes)
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
                    runOnUiThread { visibleSession = null }
                } else {
                    val bytes = DataMapItem.fromDataItem(event.dataItem).dataMap.getByteArray("session")
                    runOnUiThread { showSession(bytes) }
                }
            }
        }
    }

    private fun showSession(bytes: ByteArray?) {
        visibleSession = if (bytes == null || bytes.isEmpty()) null
        else runCatching { WatchSessionSummary.fromJson(JSONObject(String(bytes, Charsets.UTF_8))) }
            .getOrNull()
    }
}

data class WatchSessionSummary(
    val title: String,
    val exerciseName: String,
    val exerciseIndex: Int,
    val exerciseCount: Int,
    val recordedSets: Int,
    val prescribedReps: Int?,
    val prescribedWeightKg: Double?
) {
    companion object {
        fun fromJson(session: JSONObject): WatchSessionSummary {
            val exercises = session.getJSONArray("exercises")
            require(exercises.length() > 0)
            val index = session.getInt("currentIndex")
            val exercise = exercises.getJSONObject(index)
            val recorded = exercise.getJSONArray("loggedSets")
            val done = (0 until recorded.length()).count {
                recorded.getJSONObject(it).optString("phase") == "work"
            }
            val plan = exercise.optJSONArray("plannedSets")
            val target = plan?.takeIf { it.length() > 0 }?.getJSONObject(
                minOf(done, plan.length() - 1)
            )
            // For global-score WODs, show no fake per-movement prescription.
            val globalScore = exercise.optString("wodFormat") in listOf(
                "amrap", "forTime", "chipper", "afap", "ladder",
                "buyInCashOut", "deathBy", "maxEffort"
            )
            return WatchSessionSummary(
                title = session.getString("title"),
                exerciseName = exercise.getJSONObject("exercise").getString("name"),
                exerciseIndex = index + 1,
                exerciseCount = exercises.length(),
                recordedSets = recorded.length(),
                prescribedReps = if (globalScore) null else target?.optInt("targetReps"),
                prescribedWeightKg = if (globalScore) null else target?.takeIf {
                    it.has("targetWeightKg") && !it.isNull("targetWeightKg")
                }?.getDouble("targetWeightKg")
            )
        }
    }
}
