package dev.repera.mobile

import android.content.Context
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import org.json.JSONObject

/** Sends genuine active-session state; clearing it on logout avoids cross-account disclosure. */
object WearActiveSessionBridge {
    fun publish(context: Context, snapshot: ByteArray?, signedOut: Boolean = false) {
        require(!signedOut || snapshot == null) { "Sign-out cannot include session data" }
        val activeSession = runCatching {
            snapshot?.let { JSONObject(String(it, Charsets.UTF_8)).optJSONObject("activeSession") }
        }.getOrNull()
        val request = PutDataMapRequest.create("/repera/active-session").apply {
            dataMap.putByteArray(
                "session", activeSession?.toString()?.toByteArray(Charsets.UTF_8) ?: byteArrayOf()
            )
            dataMap.putBoolean("signedOut", signedOut)
            dataMap.putLong("updatedAtMillis", System.currentTimeMillis())
        }.asPutDataRequest().setUrgent()
        Wearable.getDataClient(context).putDataItem(request)
    }

    /** Explicit account logout: revoke cached identity and pending commands on the watch. */
    fun signOut(context: Context) = publish(context, null, signedOut = true)
}
