package dev.repera.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
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
    private var activeTitle by mutableStateOf<String?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                AppScaffold {
                    ScreenScaffold { insets ->
                        Column(
                            modifier = Modifier.fillMaxSize().padding(insets).padding(horizontal = 16.dp),
                            verticalArrangement = Arrangement.Center,
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text("repera", style = MaterialTheme.typography.titleLarge)
                            Text(activeTitle ?: "Sin entrenamiento recibido")
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
                    runOnUiThread { activeTitle = null }
                } else {
                    val bytes = DataMapItem.fromDataItem(event.dataItem).dataMap.getByteArray("session")
                    runOnUiThread { showSession(bytes) }
                }
            }
        }
    }

    private fun showSession(bytes: ByteArray?) {
        activeTitle = if (bytes == null || bytes.isEmpty()) null
        else runCatching { JSONObject(String(bytes, Charsets.UTF_8)).getString("title") }.getOrNull()
    }
}
