package dev.repera.mobile

import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONObject
import java.util.UUID
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

/**
 * Escucha en vivo los INSERT de ai_training_plans vía Supabase Realtime
 * (protocolo Phoenix sobre WebSocket). Port de AITrainingInboxStore.startRealtime:
 * canal por usuario (owner_id), solo en foreground, resync completo tras cada
 * suscripción para cerrar la carrera entre el último sync y el socket activo,
 * y guardas de generación ante cambios de cuenta.
 *
 * Reconexión con backoff exponencial (1s..30s); cada rejoin dispara un resync.
 */
class AIPlansRealtimeListener(
    private val sessionProvider: () -> SupabaseIdentity.Session?,
    private val onPlansChanged: () -> Unit,
    private val http: OkHttpClient = OkHttpClient()
) {
    sealed interface ServerEvent {
        data object InsertedPlan : ServerEvent
        data object JoinAccepted : ServerEvent
        data class JoinRejected(val reason: String) : ServerEvent
        data object HeartbeatAck : ServerEvent
    }

    @Volatile private var running = false
    private var worker: Thread? = null
    private var socket: WebSocket? = null
    private var generation = UUID.randomUUID()

    @Synchronized fun start() {
        if (running) return
        running = true
        generation = UUID.randomUUID()
        worker = Thread({ runLoop(generation) }, "ai-plans-realtime").apply {
            isDaemon = true
            start()
        }
    }

    @Synchronized fun stop() {
        running = false
        generation = UUID.randomUUID()
        socket?.close(1000, null)
        socket = null
        worker?.interrupt()
        worker = null
    }

    private fun runLoop(gen: UUID) {
        var backoffMs = 1000L
        while (running && generation == gen) {
            val session = sessionProvider()
            if (session == null || !running || generation != gen) break
            val clean = connectOnce(session, gen)
            if (!running || generation != gen) break
            if (clean) {
                backoffMs = 1000L
            } else {
                try { Thread.sleep(backoffMs) } catch (_: InterruptedException) { break }
                backoffMs = minOf(30_000L, backoffMs * 2)
            }
        }
    }

    /** Una conexión completa: join -> resync -> eventos hasta cierre/error. */
    private fun connectOnce(session: SupabaseIdentity.Session, gen: UUID): Boolean {
        val topic = "realtime:public:ai_training_plans:owner_id=eq." + session.userId
        val events = LinkedBlockingQueue<ServerEvent?>()
        val closed = java.util.concurrent.atomic.AtomicBoolean(false)
        val url = BuildConfig.SUPABASE_URL.replace("https://", "wss://") +
            "/realtime/v1/websocket?apikey=" + BuildConfig.SUPABASE_PUBLISHABLE_KEY +
            "&vsn=1.0.0"
        val listener = object : WebSocketListener() {
            override fun onMessage(webSocket: WebSocket, text: String) {
                events.offer(parseServerEvent(text, topic))
            }
            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                closed.set(true); events.offer(null)
            }
            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                closed.set(true); events.offer(null)
            }
            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                closed.set(true); events.offer(null)
            }
        }
        val ws = http.newWebSocket(Request.Builder().url(url).build(), listener)
        socket = ws
        var ref = 0
        ws.send(joinMessage(topic, session.accessToken, ++ref))
        var joined = false
        var heartbeatsMissed = 0
        while (running && generation == gen && !closed.get()) {
            val event = try {
                events.poll(HEARTBEAT_INTERVAL_SECONDS, TimeUnit.SECONDS)
            } catch (_: InterruptedException) { break }
            if (closed.get()) break
            if (event == null) {
                // Tick: heartbeat; si el servidor no contesta dos seguidos, reconecta.
                if (joined) {
                    ws.send(heartbeatMessage(++ref))
                    heartbeatsMissed += 1
                    if (heartbeatsMissed > 2) break
                }
                continue
            }
            when (event) {
                is ServerEvent.JoinAccepted -> {
                    joined = true
                    // Cierra la carrera: resync completo tras suscribirse (igual que iOS).
                    onPlansChanged()
                }
                is ServerEvent.InsertedPlan -> onPlansChanged()
                is ServerEvent.HeartbeatAck -> heartbeatsMissed = 0
                is ServerEvent.JoinRejected -> {
                    ws.close(1000, null)
                    return false
                }
            }
        }
        ws.close(1000, null)
        return closed.get().not()
    }

    companion object {
        private const val HEARTBEAT_INTERVAL_SECONDS = 25L

        internal fun joinMessage(topic: String, accessToken: String, ref: Int): String {
            val change = JSONObject()
                .put("event", "INSERT")
                .put("schema", "public")
                .put("table", "ai_training_plans")
                .put("filter", topic.substringAfter("owner_id="))
            val config = JSONObject()
                .put("postgres_changes", org.json.JSONArray().put(change))
                .put("broadcast", JSONObject().put("ack", false).put("self", false))
                .put("presence", JSONObject().put("key", ""))
            val payload = JSONObject()
                .put("config", config)
                .put("access_token", accessToken)
            return JSONObject()
                .put("topic", topic)
                .put("event", "phx_join")
                .put("payload", payload)
                .put("ref", ref.toString())
                .put("join_ref", ref.toString())
                .toString()
        }

        internal fun heartbeatMessage(ref: Int): String =
            JSONObject()
                .put("topic", "phoenix")
                .put("event", "heartbeat")
                .put("payload", JSONObject())
                .put("ref", ref.toString())
                .toString()

        /** Parseo tolerante: mensajes ajenos al canal o sin tipo se ignoran. */
        internal fun parseServerEvent(text: String, expectedTopic: String): ServerEvent? {
            val message = runCatching { JSONObject(text) }.getOrNull() ?: return null
            return when (message.optString("event")) {
                "phx_reply" -> {
                    val payload = message.optJSONObject("payload") ?: return null
                    val status = payload.optString("status")
                    val topic = message.optString("topic")
                    if (topic == "phoenix" && status == "ok") ServerEvent.HeartbeatAck
                    else if (topic == expectedTopic && status == "ok") ServerEvent.JoinAccepted
                    else if (topic == expectedTopic) {
                        val response = payload.optJSONObject("response")
                        ServerEvent.JoinRejected(response?.optString("reason") ?: status)
                    } else null
                }
                "postgres_changes" -> {
                    if (message.optString("topic") != expectedTopic) return null
                    val data = message.optJSONObject("payload")?.optJSONObject("data")
                    if (data?.optString("type") == "INSERT") ServerEvent.InsertedPlan else null
                }
                else -> null
            }
        }
    }
}
