package dev.repera.mobile

import android.content.Context
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import org.json.JSONObject

/** Sends genuine active-session state; clearing it on logout avoids cross-account disclosure. */
object WearActiveSessionBridge {
    fun publish(context: Context, snapshot: ByteArray?, signedOut: Boolean = false) {
        require(!signedOut || snapshot == null) { "Sign-out cannot include session data" }
        val json = runCatching {
            snapshot?.let { JSONObject(String(it, Charsets.UTF_8)) }
        }.getOrNull()
        val activeSession = json?.optJSONObject("activeSession")
        // Última sesión terminada hace menos de 6 h: el reloj muestra su
        // resumen hasta descartarlo (presentedSummary de watchOS).
        val finished = if (activeSession == null && json != null) {
            val workouts = json.optJSONArray("workouts")
            val cutoff = java.time.Instant.now().minusSeconds(6 * 3600)
            var best: JSONObject? = null
            var bestMillis = Long.MIN_VALUE
            if (workouts != null) {
                for (i in 0 until workouts.length()) {
                    val w = workouts.optJSONObject(i) ?: continue
                    val finishedAt = w.optString("finishedAt")
                        .takeIf { it.isNotBlank() && it != "null" } ?: continue
                    val millis = runCatching {
                        java.time.Instant.parse(finishedAt).toEpochMilli()
                    }.getOrNull() ?: continue
                    if (millis > bestMillis) { best = w; bestMillis = millis }
                }
            }
            best?.takeIf { bestMillis >= cutoff.toEpochMilli() }
        } else null
        val request = PutDataMapRequest.create("/repera/active-session").apply {
            dataMap.putByteArray(
                "session", activeSession?.toString()?.toByteArray(Charsets.UTF_8) ?: byteArrayOf()
            )
            dataMap.putByteArray(
                "finished", finished?.toString()?.toByteArray(Charsets.UTF_8) ?: byteArrayOf()
            )
            dataMap.putBoolean("signedOut", signedOut)
            dataMap.putLong("updatedAtMillis", System.currentTimeMillis())
        }.asPutDataRequest().setUrgent()
        Wearable.getDataClient(context).putDataItem(request)
    }

    /** Explicit account logout: revoke cached identity and pending commands on the watch. */
    fun signOut(context: Context) = publish(context, null, signedOut = true)
}
