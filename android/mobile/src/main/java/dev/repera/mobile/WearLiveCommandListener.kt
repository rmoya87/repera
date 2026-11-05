package dev.repera.mobile

import android.os.Handler
import android.os.Looper
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import com.google.android.gms.wearable.Wearable
import dev.repera.domain.LiveSport
import dev.repera.mobile.analytics.ReperaAnalytics
import org.json.JSONObject

/**
 * Receives the few watch controls that must work when MainActivity is stopped
 * (screen locked, phone in pocket). En companion phone-owned, LiveActivityService
 * sigue siendo el GPS; en live-save watch-owned el reloj ya cerró su propio registro.
 *
 * The authenticated account is recovered exclusively from encrypted device
 * storage and every command is checked against the ACTIVE workout UUID.
 */
internal object WearUiPresence {
    @Volatile var active: Boolean = false
}

class WearLiveCommandListener : WearableListenerService() {
    override fun onMessageReceived(event: MessageEvent) {
        // Misma cota que WearPayload en el reloj: rechazar antes de JSONObject.
        if (!WearMessageBounds.withinLimit(event.data)) return
        if (event.path == "/repera/analytics-event") {
            handleAnalyticsEvent(event)
            return
        }
        if (event.path == "/repera/live-heart-rate") {
            if (!WearUiPresence.active) handleBackgroundLiveHeartRate(event)
            return
        }
        if (event.path == "/repera/timer-state") {
            if (!WearUiPresence.active) handleTimerState(event)
            return
        }
        if (event.path == "/repera/timer-save") {
            if (!WearUiPresence.active) handleTimerSave(event)
            return
        }
        if (event.path == "/repera/live-save") {
            if (!WearUiPresence.active) handleLiveSave(event)
            return
        }
        if (event.path in setOf("/repera/log-set", "/repera/session-finish")) {
            if (!WearUiPresence.active) handleBackgroundWorkout(event)
            return
        }
        if (event.path == "/repera/session-start") {
            handleWearPlannedStart(event)
            return
        }
        if (event.path == "/repera/live-start") {
            // MainActivity atiende la petición cuando está visible. Este listener
            // cubre el inicio desde Wear mientras el móvil está bloqueado.
            if (!WearUiPresence.active) handleBackgroundLiveStart(event)
            return
        }
        if (event.path != "/repera/live-command") return
        val command = runCatching {
            JSONObject(String(event.data, Charsets.UTF_8))
        }.getOrNull() ?: return
        val sessionId = command.optString("sessionId")
        val action = command.optString("command")
        if (sessionId.isBlank() || action !in setOf("pause", "resume", "finish")) return
        val owner = SessionStore(this).load()?.uniqueId ?: return
        Handler(Looper.getMainLooper()).post {
            // Do not start a new activity or sensor from a background command.
            val runtime = LiveActivityRuntime.forAccount(this, owner)
            if (SessionStore(this).load()?.uniqueId != owner ||
                runtime.state.gpsSessionID != sessionId) return@post
            when (action) {
                "pause" -> runtime.pause()
                "resume" -> runtime.resume()
                "finish" -> {
                    runtime.finish() // Review/Save remains on the phone.
                    if (runtime.state.phase == dev.repera.domain.LiveActivityState.Phase.REVIEW) {
                        WearLiveReviewNotification.show(this, owner, sessionId)
                    }
                }
            }
        }
    }

    private fun handleBackgroundLiveHeartRate(event: MessageEvent) {
        val owner = SessionStore(this).load()?.uniqueId ?: return
        val payload = runCatching {
            JSONObject(String(event.data, Charsets.UTF_8))
        }.getOrNull() ?: return
        Handler(Looper.getMainLooper()).post {
            if (SessionStore(this).load()?.uniqueId != owner) return@post
            WearLiveMetricsReceiver.accept(this, owner, payload)
        }
    }

    private fun handleTimerState(event: MessageEvent) {
        val owner = SessionStore(this).load()?.uniqueId ?: return
        val payload = runCatching {
            JSONObject(String(event.data, Charsets.UTF_8))
        }.getOrNull() ?: return
        WearTimerMirrorStore(this, owner).accept(payload)
    }

    /** El registro se confirma únicamente tras persistirlo; Wear reintenta con el mismo UUID. */
    private fun handleTimerSave(event: MessageEvent) {
        val store = SessionStore(this)
        val owner = store.load() ?: return
        val revision = store.identityRevision()
        val body = runCatching {
            JSONObject(String(event.data, Charsets.UTF_8))
        }.getOrNull() ?: return
        val id = body.optString("id").takeIf {
            runCatching { java.util.UUID.fromString(it) }.isSuccess
        } ?: return
        val details = dev.repera.domain.TimerCompletionDetails
            .fromJson(body.optJSONObject("timerDetails")) ?: return
        val authorized = {
            store.identityRevision() == revision &&
                store.load()?.uniqueId == owner.uniqueId &&
                store.load()?.userId == owner.userId
        }
        val saved = runCatching {
            authorized() && WorkoutRepository(this, owner.uniqueId, stillAuthorized = authorized)
                .saveTimerSession(
                    id = id,
                    title = "Temporizador · ${details.modeTitle}",
                    startedAtMillis = body.optLong("startedAtMillis"),
                    finishedAtMillis = body.optLong("finishedAtMillis"),
                    details = details
                ).isNotBlank()
        }.getOrDefault(false)
        if (!saved) return
        val mirror = WearTimerMirrorStore(this, owner.uniqueId)
        mirror.last()?.takeIf { it.optString("id") == id }?.let {
            mirror.accept(JSONObject(it.toString())
                .put("phase", "finished").put("updatedAtMillis", System.currentTimeMillis()))
        }
        val ack = JSONObject().put("id", id).put("saved", true)
            .toString().toByteArray(Charsets.UTF_8)
        Wearable.getMessageClient(this).sendMessage(
            event.sourceNodeId, "/repera/timer-save-ack", ack
        )
        DriveSyncWorker.syncNow(this)
    }

    /** Actividad Comenzar terminada en el reloj (offline o sin companion). */
    private fun handleLiveSave(event: MessageEvent) {
        val store = SessionStore(this)
        val owner = store.load() ?: return
        val revision = store.identityRevision()
        val body = runCatching {
            JSONObject(String(event.data, Charsets.UTF_8))
        }.getOrNull() ?: return
        val id = body.optString("id").takeIf {
            runCatching { java.util.UUID.fromString(it) }.isSuccess
        } ?: return
        val sportId = body.optString("sportId")
        if (sportId.isBlank() || LiveSport.byId(sportId) == null) return
        val authorized = {
            store.identityRevision() == revision &&
                store.load()?.uniqueId == owner.uniqueId &&
                store.load()?.userId == owner.userId
        }
        val saved = runCatching {
            authorized() && WorkoutRepository(this, owner.uniqueId, stillAuthorized = authorized)
                .saveWearOwnedLiveActivity(
                    id = id,
                    sportId = sportId,
                    title = body.optString("title"),
                    startedAtMillis = body.optLong("startedAtMillis"),
                    finishedAtMillis = body.optLong("finishedAtMillis"),
                    activeSeconds = body.optDouble("activeDurationSeconds", 0.0),
                    distanceMeters = body.optDouble("distanceMeters")
                        .takeIf { body.has("distanceMeters") && !body.isNull("distanceMeters") },
                    locationPin = body.optJSONObject("locationPin"),
                    averageHeartRateBpm = body.optDouble("averageHeartRateBpm")
                        .takeIf { body.has("averageHeartRateBpm") && !body.isNull("averageHeartRateBpm") },
                    totalEnergyKcal = body.optDouble("totalEnergyKcal")
                        .takeIf { body.has("totalEnergyKcal") && !body.isNull("totalEnergyKcal") }
                        ?: body.optDouble("activeEnergyKcal")
                            .takeIf { body.has("activeEnergyKcal") && !body.isNull("activeEnergyKcal") },
                    routePoints = body.optJSONArray("routePoints")
                ).isNotBlank()
        }.getOrDefault(false)
        if (!saved) return
        Wearable.getMessageClient(this).sendMessage(
            event.sourceNodeId, "/repera/live-save-ack",
            JSONObject().put("id", id).put("saved", true)
                .toString().toByteArray(Charsets.UTF_8)
        )
        DriveSyncWorker.syncNow(this)
        // Exportar ruta a Health Connect cuando haya permiso + ≥2 puntos.
        val appContext = applicationContext
        Thread {
            runCatching {
                kotlinx.coroutines.runBlocking {
                    if (!authorized()) return@runBlocking
                    val repo = WorkoutRepository(
                        appContext, owner.uniqueId, stillAuthorized = authorized
                    )
                    val info = repo.sessionTitleAndRange(id) ?: return@runBlocking
                    val linked = HealthConnectWriter(appContext, stillAuthorized = authorized)
                        .syncFinishedSession(
                            id, info.first, info.second, info.third,
                            repo.healthRecordId(id),
                            HealthConnectWriter.exerciseTypeFor(
                                repo.sessionHealthSportId(id)?.let(LiveSport::byId)
                            ),
                            repo.sessionRoutePoints(id),
                            repo.sessionRecordedDistanceMeters(id),
                            repo.sessionWearTotalEnergyKcal(id)
                        )
                    if (authorized() && linked != null && repo.healthRecordId(id) == null) {
                        repo.setHealthRecordId(id, linked)
                    }
                }
            }
        }.start()
    }

    /** Adopta inmediatamente el entrenamiento autónomo del reloj.
     * WorkoutRepository guarda por CAS y publica su notificación de bloqueo. */
    private fun handleWearPlannedStart(event: MessageEvent) {
        val json = runCatching {
            JSONObject(String(event.data, Charsets.UTF_8))
        }.getOrNull() ?: return
        val plan = json.optJSONObject("session") ?: return
        val sessionId = plan.optString("id")
        if (sessionId.isBlank()) return
        val sessionStore = SessionStore(this)
        val owner = sessionStore.load() ?: return
        val revision = sessionStore.identityRevision()
        val authorized = {
            sessionStore.identityRevision() == revision &&
                sessionStore.load()?.uniqueId == owner.uniqueId &&
                sessionStore.load()?.userId == owner.userId
        }
        val accepted = runCatching {
            authorized() && WorkoutRepository(this, owner.uniqueId, stillAuthorized = authorized)
                .adoptWearSession(plan)
        }.getOrDefault(false)
        Wearable.getMessageClient(this).sendMessage(
            event.sourceNodeId, "/repera/session-start-ack",
            JSONObject().put("sessionId", sessionId).put("ok", accepted)
                .toString().toByteArray(Charsets.UTF_8)
        )
        if (accepted) DriveSyncWorker.syncNow(this)
    }

    private fun handleBackgroundLiveStart(event: MessageEvent) {
        val command = runCatching {
            JSONObject(String(event.data, Charsets.UTF_8))
        }.getOrNull() ?: return
        val sportId = command.optString("sportId")
        val sport = dev.repera.domain.LiveSport.byId(sportId) ?: return
        val sessions = SessionStore(this)
        val identity = sessions.load() ?: return
        val revision = sessions.identityRevision()
        val node = event.sourceNodeId
        Handler(Looper.getMainLooper()).post {
            val authorized = sessions.load()?.uniqueId == identity.uniqueId &&
                sessions.identityRevision() == revision
            if (!authorized) return@post
            val runtime = LiveActivityRuntime.forAccount(this, identity.uniqueId)
            val phase = runtime.state.phase
            if (phase == dev.repera.domain.LiveActivityState.Phase.RECORDING ||
                phase == dev.repera.domain.LiveActivityState.Phase.PAUSED) {
                ackLiveStart(node, true, null)
                return@post
            }
            if (phase != dev.repera.domain.LiveActivityState.Phase.IDLE ||
                LiveActivityRuntime.hasPendingActivity(this, identity.uniqueId) &&
                runtime.recoveryBlocked) {
                ackLiveStart(node, false, "Hay otra actividad pendiente en el móvil")
                return@post
            }
            // Android 14+ limita arrancar un FGS de ubicación en segundo plano.
            // Una excepción en GPS o en el FGS revierte el intento completo.
            val result = runCatching {
                runtime.choose(sport)
                runtime.start()
                check(runtime.state.phase == dev.repera.domain.LiveActivityState.Phase.RECORDING) {
                    "No se pudo comenzar el GPS"
                }
                LiveActivityService.startFromVisibleUI(this, identity.uniqueId)
            }
            if (result.isFailure) {
                runtime.discard()
                ackLiveStart(node, false, "Abre Repera en el móvil para iniciar GPS")
            } else {
                ackLiveStart(node, true, null)
            }
        }
    }

    private fun ackLiveStart(node: String, ok: Boolean, reason: String?) {
        Companion.ackLiveStart(this, node, ok, reason)
    }

    companion object {
        /** Same ACK used by MainActivity (foreground) and this listener (background). */
        fun ackLiveStart(context: android.content.Context, node: String, ok: Boolean, reason: String?) {
            if (node.isBlank()) return
            val body = JSONObject().put("ok", ok).put("reason", reason ?: "")
            Wearable.getMessageClient(context.applicationContext).sendMessage(
                node, "/repera/live-start-ack", body.toString().toByteArray(Charsets.UTF_8)
            )
        }
    }

    /** The Activity listener is absent while the phone is locked. Wear keeps
     * each action in its own durable outbox until this persist-then-ACK succeeds.
     * The repository deduplicates by set UUID, including a retried message.
     */
    private fun handleBackgroundWorkout(event: MessageEvent) {
        val json = runCatching {
            JSONObject(String(event.data, Charsets.UTF_8))
        }.getOrNull() ?: return
        val sessionStore = SessionStore(this)
        val owner = sessionStore.load() ?: run {
            if (event.path == "/repera/log-set") ackSet(event.sourceNodeId, json.optString("id"), "retry")
            return
        }
        val revision = sessionStore.identityRevision()
        val authorized = {
            sessionStore.identityRevision() == revision &&
                sessionStore.load()?.uniqueId == owner.uniqueId &&
                sessionStore.load()?.userId == owner.userId
        }
        val repo = WorkoutRepository(this, owner.uniqueId, stillAuthorized = authorized)
        if (event.path == "/repera/session-finish") {
            val id = json.optString("sessionId")
            if (id.isBlank()) return
            val saved = runCatching {
                if (!authorized()) false else {
                    json.optJSONObject("locationPin")?.let { repo.attachWearStartPin(id, it) }
                    val finished = repo.finishWearSession(id)
                    if (finished) {
                        repo.mergeWearMeasuredMetrics(
                            id,
                            json.optDouble("totalEnergyKcal", Double.NaN)
                                .takeIf { it.isFinite() && it > 0 },
                            json.optDouble("averageHeartRateBpm", Double.NaN)
                                .takeIf { it.isFinite() && it in 25.0..250.0 }
                        )
                    }
                    finished
                }
            }.getOrDefault(false)
            if (saved) {
                WearWorkoutCompletionNotification.show(this, owner.uniqueId, id)
                Wearable.getMessageClient(this).sendMessage(
                    event.sourceNodeId, "/repera/session-finish-ack",
                    JSONObject().put("sessionId", id).put("status", "saved")
                        .toString().toByteArray(Charsets.UTF_8)
                )
                DriveSyncWorker.syncNow(this)
            }
            return
        }
        val id = json.optString("id")
        if (id.isBlank()) return
        val sessionId = json.optString("sessionId")
        val index = json.optInt("exerciseIndex", -1)
        val reps = json.optInt("quantity", -1)
        val weight = if (json.has("weightKg") && !json.isNull("weightKg"))
            json.optDouble("weightKg", Double.NaN) else null
        val rir = if (json.has("rir") && !json.isNull("rir"))
            json.optDouble("rir", Double.NaN) else null
        val duration = if (json.has("durationSeconds") && !json.isNull("durationSeconds"))
            json.optInt("durationSeconds", -1) else null
        val deficit = if (json.has("deficitCm") && !json.isNull("deficitCm"))
            json.optInt("deficitCm", -1) else null
        val interval = if (json.has("intervalIndex") && !json.isNull("intervalIndex"))
            json.optInt("intervalIndex", -1) else null
        val kind = json.optString("kind", "straight").ifBlank { "straight" }
        if (sessionId.isBlank() || index < 0 || reps !in 1..10000 ||
            (weight != null && (!weight.isFinite() || weight < 0)) ||
            (rir != null && (!rir.isFinite() || rir !in 0.0..5.0)) ||
            (duration != null && duration !in 1..86400) ||
            (deficit != null && deficit !in 0..100) ||
            (interval != null && interval !in 0..100000) ||
            kind !in setOf("straight", "dropset", "restpause")) {
            ackSet(event.sourceNodeId, id, "rejected")
            return
        }
        val drops = runCatching {
            val values = json.optJSONArray("drops")
            if (values == null) emptyList() else (0 until values.length()).map { n ->
                val obj = values.getJSONObject(n)
                obj.getInt("reps") to
                    if (obj.has("weightKg") && !obj.isNull("weightKg")) obj.getDouble("weightKg") else null
            }
        }.getOrDefault(emptyList())
        val clusters = runCatching {
            val values = json.optJSONArray("clusters")
            if (values == null) emptyList() else (0 until values.length()).map { n ->
                val obj = values.getJSONObject(n)
                obj.getInt("reps") to obj.getInt("restSeconds")
            }
        }.getOrDefault(emptyList())
        val saved = runCatching {
            authorized() && repo.logWearSet(
                sessionId, index, id, reps, weight, rir,
                durationSeconds = duration,
                quantityUnit = json.optString("quantityUnit").takeIf {
                    it in setOf("reps", "meters", "calories")
                },
                deficitCm = deficit, intervalIndex = interval,
                sessionPayload = json.optJSONObject("session"),
                warmup = json.optBoolean("warmup", false),
                toFailure = json.optBoolean("toFailure", false),
                kind = kind, drops = drops, clusters = clusters
            )
        }.getOrDefault(false)
        ackSet(event.sourceNodeId, id, if (saved) "saved" else "retry")
        if (saved) DriveSyncWorker.syncNow(this)
    }

    private fun ackSet(node: String, id: String, status: String) {
        if (id.isBlank()) return
        Wearable.getMessageClient(this).sendMessage(
            node, "/repera/log-set-ack",
            JSONObject().put("id", id).put("status", status)
                .toString().toByteArray(Charsets.UTF_8)
        )
        ReperaAnalytics.track(
            if (status == "saved") ReperaAnalytics.Event.WATCH_SYNC_CONFIRMED
            else ReperaAnalytics.Event.WATCH_SYNC_FAILED,
            mapOf(
                "feature_area" to "reliability",
                "action_name" to "log_set",
                "result" to if (status == "saved") "success" else "failure",
                "session_origin_platform" to "wearos"
            )
        )
    }

    private fun handleAnalyticsEvent(event: MessageEvent) {
        val payload = runCatching {
            JSONObject(String(event.data, Charsets.UTF_8))
        }.getOrNull() ?: return
        val id = payload.optString("id")
        val name = payload.optString("event")
        val eventEnum = ReperaAnalytics.Event.entries.firstOrNull { it.wire == name }
        val accepted = if (eventEnum != null) {
            val params = mutableMapOf(
                "session_origin_platform" to "wearos",
                "feature_area" to payload.optString("feature_area", "reliability"),
                "result" to payload.optString("result", "success")
            )
            payload.optString("action_name").takeIf { it.isNotBlank() }?.let {
                params["action_name"] = it
            }
            ReperaAnalytics.track(eventEnum, params)
            true
        } else false
        if (id.isNotBlank()) {
            Wearable.getMessageClient(this).sendMessage(
                event.sourceNodeId,
                "/repera/analytics-ack",
                JSONObject().put("id", id).put("status", if (accepted) "ok" else "rejected")
                    .toString().toByteArray(Charsets.UTF_8)
            )
        }
    }
}
