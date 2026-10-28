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
        val settings = json?.optJSONObject("settings")
        val effortUnit = settings?.optString("effortUnit")?.takeIf { it in setOf("rir", "rpe") } ?: "rir"
        val weightUnit = settings?.optString("weightUnit")?.takeIf { it in setOf("kg", "lb") } ?: "kg"
        val request = PutDataMapRequest.create("/repera/active-session").apply {
            dataMap.putByteArray(
                "session", activeSession?.toString()?.toByteArray(Charsets.UTF_8) ?: byteArrayOf()
            )
            dataMap.putByteArray(
                "finished", finished?.toString()?.toByteArray(Charsets.UTF_8) ?: byteArrayOf()
            )
            dataMap.putString("effortUnit", effortUnit)
            dataMap.putString("weightUnit", weightUnit)
            dataMap.putBoolean("signedOut", signedOut)
            dataMap.putLong("updatedAtMillis", System.currentTimeMillis())
        }.asPutDataRequest().setUrgent()
        Wearable.getDataClient(context).putDataItem(request)
    }

    /**
     * Estado del cronómetro WOD para la cara del reloj. `zeroAtWallMs` es el
     * instante (reloj de pared) en el que el cronómetro marcaba 0 cuando iba
     * en marcha; con él el reloj calcula el elapsed local sin depender de
     * deltas de uptime entre dispositivos (la hora del reloj va sincronizada
     * con la del teléfono). null cuando no hay bloque WOD activo.
     */
    fun publishWodTimer(context: Context, sessionId: String?, index: Int,
                        execution: WodExecution?, state: WodTimerState?) {
        val json = if (sessionId == null || execution == null || state == null) null
        else JSONObject()
            .put("sessionId", sessionId)
            .put("blockIndex", index)
            .put("format", execution.format)
            .put("title", execution.title)
            .put("timeCapMinutes", execution.timeCapMinutes ?: JSONObject.NULL)
            .put("intervalSeconds", execution.intervalSeconds ?: JSONObject.NULL)
            .put("rounds", execution.rounds ?: JSONObject.NULL)
            .put("workSeconds", execution.workSeconds ?: JSONObject.NULL)
            .put("restSeconds", execution.restSeconds ?: JSONObject.NULL)
            .put("restBetweenRoundsSeconds",
                execution.restBetweenRoundsSeconds ?: JSONObject.NULL)
            .put("stations", execution.stations.coerceAtLeast(1))
            .put("plannedIntervals", execution.plannedIntervals ?: JSONObject.NULL)
            .put("running", state.running)
            .put("elapsedSeconds", state.elapsedSeconds)
            .put("zeroAtWallMs", if (state.running)
                System.currentTimeMillis() - state.elapsedSeconds * 1000L
                else JSONObject.NULL)
        val request = PutDataMapRequest.create("/repera/wod-timer").apply {
            dataMap.putByteArray("timer",
                json?.toString()?.toByteArray(Charsets.UTF_8) ?: byteArrayOf())
            dataMap.putLong("updatedAtMillis", System.currentTimeMillis())
        }.asPutDataRequest().setUrgent()
        Wearable.getDataClient(context).putDataItem(request)
    }

    /**
     * Plan del día (sesión montada, sin persistir) para ejecución autónoma
     * offline del reloj: equivale al todayPlan que el iPhone envía por
     * WatchConnectivity. null limpia el plan en el reloj.
     */
    fun publishTodayPlan(context: Context, plan: JSONObject?) {
        val request = PutDataMapRequest.create("/repera/today-plan").apply {
            dataMap.putByteArray("plan",
                plan?.toString()?.toByteArray(Charsets.UTF_8) ?: byteArrayOf())
            dataMap.putLong("updatedAtMillis", System.currentTimeMillis())
        }.asPutDataRequest().setUrgent()
        Wearable.getDataClient(context).putDataItem(request)
    }

    /** Explicit account logout: revoke cached identity and pending commands on the watch. */
    fun signOut(context: Context) {
        publish(context, null, signedOut = true)
        publishTodayPlan(context,null)
        publishWodTimer(context,null,0,null,null)
    }
}
