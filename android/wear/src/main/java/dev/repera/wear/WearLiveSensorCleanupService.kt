package dev.repera.wear

import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONObject

/**
 * A suspended Wear UI must not leave an old Health Services workout running
 * indefinitely after its companion phone session has finished.
 *
 * This background listener only clears an EXISTING sensor owner. Starting a
 * new health foreground service from background requires an allowed user
 * gesture/foreground context and stays in WearMainActivity.
 */
class WearLiveSensorCleanupService : WearableListenerService() {
    override fun onDataChanged(events: DataEventBuffer) {
        val prefs = getSharedPreferences("repera.wear.session", MODE_PRIVATE)
        val current = prefs.getString("companionLiveSensor", null) ?: return
        for (event in events) {
            if (event.dataItem.uri.path != "/repera/live-activity") continue
            val payload = if (event.type == DataEvent.TYPE_CHANGED) {
                runCatching {
                    DataMapItem.fromDataItem(event.dataItem).dataMap.getByteArray("live")
                        ?.takeIf { it.isNotEmpty() }
                        ?.let { JSONObject(String(it, Charsets.UTF_8)) }
                }.getOrNull()
            } else null
            val id = payload?.optString("sessionId")
            val phase = payload?.optString("phase")
            val stillActive = phase in setOf("recording", "paused")
            // A newer session must not be stopped by a late older terminal.
            if (id == current && stillActive) continue
            if (id != null && id != current) continue
            prefs.edit().remove("companionLiveSensor").remove("companionLiveSport").commit()
            break
        }
    }
}
