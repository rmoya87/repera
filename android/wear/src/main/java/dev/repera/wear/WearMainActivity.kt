package dev.repera.wear

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Bundle
import android.os.SystemClock
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
import dev.repera.domain.LiveSport
import dev.repera.domain.WearBlockHeader

/**
 * This first native screen renders only genuine phone-delivered data.
 * Do not simulate workout tracking or recorded sets until SessionController is ported.
 */
class WearMainActivity : ComponentActivity(), DataClient.OnDataChangedListener,
    SensorEventListener,
    MessageClient.OnMessageReceivedListener {
    companion object {
        /** Plan del día en caché: se invalida tras 18 h (día atlética + margen). */
        const val TODAY_PLAN_TTL_MS = 18L * 60L * 60L * 1000L
    }

    private val dataClient by lazy { Wearable.getDataClient(this) }
    private val messageClient by lazy { Wearable.getMessageClient(this) }
    private val pendingStore by lazy { WearPendingSetStore(this) }
    private val pendingFinish by lazy {WearPendingFinishStore(this)}
    private var repsInput by mutableStateOf(0)
    private var weightInput by mutableStateOf<Double?>(null)
    private var rirInput by mutableStateOf<Double?>(null)
    private var durationInput by mutableStateOf(30)
    private var deficitInput by mutableStateOf(5)
    private var unitInput by mutableStateOf("reps")
    private var finishedSummary by mutableStateOf<FinishedSummary?>(null)
    private var restRemaining by mutableStateOf(0)
    private var sessionPaused by mutableStateOf(false)
    private val repCounter = dev.repera.domain.MotionRepCounter()
    private var motionSensor: Sensor? = null
    private var sensorManager: SensorManager? = null
    private var todayPlanJson by mutableStateOf<JSONObject?>(null)
    private var watchStartedSession by mutableStateOf(false)
    private var wodTickSeconds by mutableStateOf(0)
    private var wodTickJob: kotlinx.coroutines.Job? = null
    private var restJob: kotlinx.coroutines.Job? = null
    private val restClock=dev.repera.domain.RestCountdown()
    private var health by mutableStateOf<Pair<Int?, Double?>?>(null)
    private var healthConnection:WearHealthService.Connection?=null
    private var healthBound=false
    private var pauseSensorsIntent:dev.repera.domain.WearStartPauseIntent?=null
    private val healthServiceConnection=object:android.content.ServiceConnection {
        override fun onServiceConnected(name:android.content.ComponentName,binder:android.os.IBinder) {
            healthConnection=binder as WearHealthService.Connection
            healthConnection?.observe {state ->runOnUiThread {
                health=if(state.sessionId==visibleSession?.sessionId) state.heart to state.energy else null
                // Apple startToday + selectBlock pauses HealthKit; decision logic is WearStartPauseIntent (JVM-tested).
                pauseSensorsIntent?.let {intent ->
                    when(intent.onSensorState(visibleSession?.sessionId,state.sessionId,state.recording,state.paused,sessionPaused)) {
                        dev.repera.domain.WearStartPauseIntent.Decision.PAUSE -> healthConnection?.pause(intent.sessionId,true)
                        dev.repera.domain.WearStartPauseIntent.Decision.DROP -> pauseSensorsIntent=null
                        dev.repera.domain.WearStartPauseIntent.Decision.WAIT -> {}
                    }
                }
                state.problem?.let {sendStatus=it}
            }}
            if(visibleSession!=null) ensureHealthRecording()
        }
        override fun onServiceDisconnected(name:android.content.ComponentName) {healthConnection=null;health=null}
    }

    private var sensorRevision=0L
    private val pendingSensorPermission=dev.repera.domain.PendingSessionRequest()
    private val sensorPermissions = registerForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts
            .RequestMultiplePermissions()
    ) { grants ->
        if (!pendingSensorPermission.consume(visibleSession?.sessionId,sensorRevision)) {
            sendStatus="La sesión cambió; vuelve a solicitar sensores desde el reloj"
            return@registerForActivityResult
        }
        if (visibleSession!=null && WearHealthPermissions.requested(android.os.Build.VERSION.SDK_INT).all {permission ->
            grants[permission]==true || androidx.core.content.ContextCompat.checkSelfPermission(this,permission)==android.content.pm.PackageManager.PERMISSION_GRANTED
        }) {
            startHealthForCurrentSession()
        }
    }
    private var transportRevision=0L
    private var confirmDiscardPending by mutableStateOf(false)
    private var pendingCount by mutableStateOf(0)
    private var sendStatus by mutableStateOf<String?>(null)
    private var warmupInput by mutableStateOf(false)
    private var failureInput by mutableStateOf(false)
    private var setKindInput by mutableStateOf("straight")
    private var dropsInput by mutableStateOf<List<Pair<Int, Double?>>>(emptyList())
    private var clustersInput by mutableStateOf<List<Pair<Int, Int>>>(emptyList())
    private var phoneWodTimerJson by mutableStateOf<JSONObject?>(null)
    private var localWodTimerJson by mutableStateOf<JSONObject?>(null)
    private var visibleSession by mutableStateOf<WatchSessionSummary?>(null)
    private var effortUnit by mutableStateOf("rir")
    private var weightUnit by mutableStateOf("kg")
    private var syncProblem by mutableStateOf(false)
    private var showingCachedSession by mutableStateOf(false)
    private var liveActivityJson by mutableStateOf<JSONObject?>(null)
    /** Tras finalizar companion, no reabrir la cara live con el snapshot de revisión. */
    private var suppressCompanionLive = false
    private var hubIndex by mutableStateOf(0)
    private var recentLiveSportIDs by mutableStateOf<List<String>>(emptyList())
    private var hubAudioMuted by mutableStateOf(false)
    private enum class WearHubOverlay { HOME, TIMER_CONFIG, TIMER_RUN }
    private var hubOverlay by mutableStateOf(WearHubOverlay.HOME)
    private var timerDraft by mutableStateOf(WearTimerDraft())
    private var showOutline by mutableStateOf(false)
    private var showSetDetails by mutableStateOf(false)
    private var reviewingBlock by mutableStateOf(false)
    private var elapsedSeconds by mutableStateOf(0)
    private var elapsedJob: kotlinx.coroutines.Job? = null
    private var sessionStartedAtElapsed: Long? = null
    private var pausedAccumulatedMs = 0L
    private var lastElapsedCheckpointMs = 0L
    private var pauseStartedAtElapsed: Long? = null
    private var reviewRounds by mutableStateOf(0)
    private var reviewExtraReps by mutableStateOf(0)
    private var reviewElapsedSeconds by mutableStateOf(0)
    private var setReviewIndex by mutableStateOf<Int?>(null)
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
            val discarded = sessionCache.getStringSet("discardedSessionIds", emptySet()) ?: emptySet()
            if (restored != null && restored.sessionId !in discarded) {
                visibleSession = restored
                seedDraft(restored)
                restoreDraft(restored)
                restoreRest(restored)
                showingCachedSession = true
            } else {
                sessionCache.edit().remove("snapshot").remove("inputDraft").remove("restState").apply()
            }
        }
        val cachedPlanAt = sessionCache.getLong("todayPlanAt", 0L)
        if (cachedPlanAt > 0L && System.currentTimeMillis() - cachedPlanAt > TODAY_PLAN_TTL_MS) {
            sessionCache.edit().remove("todayPlan").remove("todayPlanAt").apply()
        } else {
            sessionCache.getString("todayPlan", null)?.let { cached ->
                todayPlanJson = runCatching { JSONObject(cached) }.getOrNull()
            }
        }
        watchStartedSession = sessionCache.getBoolean("watchStarted", false)
        val restoredSessionId = visibleSession?.sessionId
        if (restoredSessionId != null &&
            restoredSessionId == sessionCache.getString("clockSessionId", null) &&
            visibleSession?.phase == "counting") {
            sessionPaused = sessionCache.getBoolean("clockPaused", false)
            val last = sessionCache.getLong("clockSavedAtMillis", System.currentTimeMillis())
            val offlineSeconds = if (sessionPaused) 0L else
                ((System.currentTimeMillis() - last) / 1000L).coerceIn(0L, 43_200L)
            elapsedSeconds = (sessionCache.getInt("clockElapsedSeconds", 0) + offlineSeconds)
                .coerceIn(0L, dev.repera.domain.WearSessionDuration.MAX_SECONDS.toLong()).toInt()
        }
        effortUnit = sessionCache.getString("effortUnit", "rir")?.takeIf { it in setOf("rir", "rpe") } ?: "rir"
        weightUnit = sessionCache.getString("weightUnit", "kg")?.takeIf { it in setOf("kg", "lb") } ?: "kg"
        hubIndex = sessionCache.getInt("hubIndex", 0)
        // Tras cargar plan/recents se re-resuelve; aquí solo semilla.
        hubAudioMuted = sessionCache.getBoolean("hubAudioMuted", false)
        sessionCache.getString("recentLiveSportIDs", null)?.let { raw ->
            recentLiveSportIDs = runCatching {
                JSONArray(raw).let { arr -> (0 until arr.length()).map { arr.getString(it) } }
            }.getOrDefault(emptyList())
        }
        sensorManager = getSystemService(SENSOR_SERVICE) as? SensorManager
        motionSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION)
        setContent {
            MaterialTheme(colorScheme = MaterialTheme.colorScheme.copy(
                primary = Color(0xFF30D158), onPrimary = Color.Black,
                background = Color.Black
            )) {
                AppScaffold {
                    ScreenScaffold { insets ->
                        when (hubOverlay) {
                            WearHubOverlay.TIMER_CONFIG -> androidx.compose.foundation.layout.Box(
                                Modifier.fillMaxSize().padding(insets)
                            ) {
                                WearTimerConfigScreen(
                                    draft = timerDraft,
                                    onDraftChange = { timerDraft = it },
                                    onStart = { hubOverlay = WearHubOverlay.TIMER_RUN },
                                    onBack = { hubOverlay = WearHubOverlay.HOME }
                                )
                            }
                            WearHubOverlay.TIMER_RUN -> androidx.compose.foundation.layout.Box(
                                Modifier.fillMaxSize().padding(insets)
                            ) {
                                WearTimerRunScreen(
                                    draft = timerDraft,
                                    audioMuted = hubAudioMuted,
                                    onFinished = { details, started, finished ->
                                        hubOverlay = WearHubOverlay.HOME
                                        sendTimerDetailsToPhone(details, started, finished)
                                    },
                                    onDiscard = { hubOverlay = WearHubOverlay.HOME }
                                )
                            }
                            WearHubOverlay.HOME -> WearHomeContent(
                            state = WearHomeState(
                                session = visibleSession,
                                liveActivity = liveActivityJson,
                                showingCachedSession = showingCachedSession,
                                finishedSummary = finishedSummary,
                                todayPlan = todayPlanJson,
                                hubIndex = resolvedHubIndex(),
                                recentLiveSportIDs = recentLiveSportIDs,
                                audioMuted = hubAudioMuted,
                                syncProblem = syncProblem,
                                health = health,
                                wodTimerJson = effectiveWodTimer(visibleSession),
                                wodTickSeconds = wodTickSeconds,
                                sessionPaused = sessionPaused,
                                restRemaining = restRemaining,
                                repsInput = repsInput,
                                weightInput = weightInput,
                                rirInput = rirInput,
                                durationInput = durationInput,
                                unitInput = unitInput,
                                deficitInput = deficitInput,
                                pendingCount = pendingCount,
                                confirmDiscardPending = confirmDiscardPending,
                                sendStatus = sendStatus,warmup=warmupInput,toFailure=failureInput,
                                effortUnit = effortUnit, weightUnit = weightUnit,
                                setKind = setKindInput, drops = dropsInput, clusters = clustersInput,
                                showOutline = showOutline,
                                showSetDetails = showSetDetails,
                                reviewingBlock = reviewingBlock,
                                elapsedSeconds = elapsedSeconds,
                                reviewRounds = reviewRounds,
                                reviewExtraReps = reviewExtraReps,
                                reviewElapsedSeconds = reviewElapsedSeconds,
                                setReviewIndex = setReviewIndex
                            ),
                            callbacks = WearHomeCallbacks(
                                onLiveCommand = { command -> requestLiveCommand(command) },
                                onDismissFinished = { finished ->
                                    sessionCache.edit().putString(
                                        "finishedDismissed", finished.sessionId).apply()
                                    finishedSummary = null
                                    suppressCompanionLive = true
                                    liveActivityJson = null
                                    hubIndex = resolvedHubIndex()
                                },
                                onStartTodayPlan = { startTodayPlan() },
                                onStartTodayPlanAt = { startTodayPlan(it) },
                                onTogglePause = { togglePause() },
                                onSelectBlock = { session, index -> requestSelectBlock(session, index) },
                                onFinishSession = { session -> finishSessionFromWatch(session) },
                                onDiscardSession = { session -> discardSessionFromWatch(session) },
                                onSkipRest = { skipRest() },
                                onSyncRequest = { requestTodayPlanSync() },
                                onRepsMinus = { adjustQuantity(-1) },
                                onRepsPlus = { adjustQuantity(1) },
                                onWeightDelta = { delta ->
                                    weightInput = (kotlin.math.round(((weightInput ?: 0.0) + delta)*10.0)/10.0)
                                        .coerceAtLeast(0.0).coerceAtMost(2000.0)
                                    persistDraft()
                                },
                                onRirMinus = {
                                    rirInput = ((rirInput ?: 3.0) - 1).coerceAtLeast(0.0);failureInput=rirInput==0.0
                                    persistDraft()
                                },
                                onRirPlus = {
                                    rirInput = ((rirInput ?: 1.0) + 1).coerceAtMost(5.0);failureInput=false
                                    persistDraft()
                                },
                                onRirClear = { rirInput = null;failureInput=false;persistDraft() },
                                onToggleWarmup={warmupInput=!warmupInput;if(warmupInput) failureInput=false;persistDraft()},
                                onToggleFailure={failureInput=!failureInput;if(failureInput) rirInput=0.0;persistDraft()},
                                onDurationDelta = { delta ->
                                    durationInput = (durationInput + delta).coerceIn(5, 86400)
                                    persistDraft()
                                },
                                onCycleUnit = {
                                    val session=visibleSession
                                    unitInput=if(session?.allowsUnitToggle==true) {if(unitInput=="calories") "meters" else "calories"} else session?.quantityUnit ?: "reps"
                                    persistDraft()
                                },
                                onDeficitDelta = { delta ->
                                    deficitInput = (deficitInput + delta).coerceIn(0, 60)
                                    persistDraft()
                                },
                                onSetKind = { kind ->
                                    setKindInput = kind
                                    if (kind != "dropset") dropsInput = emptyList()
                                    if (kind != "restpause") clustersInput = emptyList()
                                    if (kind == "dropset" && dropsInput.isEmpty()) {
                                        dropsInput = listOf(
                                            maxOf(1, repsInput) to weightInput)
                                    }
                                    if (kind == "restpause" && clustersInput.isEmpty()) {
                                        clustersInput = listOf(maxOf(1, repsInput) to 15)
                                    }
                                    persistDraft()
                                },
                                onAddDrop = {
                                    if (dropsInput.size >= 5) return@WearHomeCallbacks
                                    dropsInput = dropsInput +
                                        (maxOf(1, repsInput) to weightInput)
                                    setKindInput = "dropset"
                                    persistDraft()
                                },
                                onAdjustDrop = { idx, dReps, dKg ->
                                    dropsInput = dropsInput.mapIndexed { i, drop ->
                                        if (i != idx) drop
                                        else (drop.first + dReps).coerceIn(1, 10000) to
                                            ((drop.second ?: 0.0) + dKg).coerceIn(0.0, 2000.0)
                                    }
                                    persistDraft()
                                },
                                onRemoveDrop = { idx ->
                                    dropsInput = dropsInput.filterIndexed { i, _ -> i != idx }
                                    if (dropsInput.isEmpty()) setKindInput = "straight"
                                    persistDraft()
                                },
                                onAddCluster = {
                                    clustersInput = clustersInput +
                                        (maxOf(1, repsInput) to 15)
                                    setKindInput = "restpause"
                                    persistDraft()
                                },
                                onAdjustCluster = { idx, dReps, dRest ->
                                    clustersInput = clustersInput.mapIndexed { i, c ->
                                        if (i != idx) c
                                        else (c.first + dReps).coerceIn(1, 10000) to
                                            (c.second + dRest).coerceIn(1, 600)
                                    }
                                    persistDraft()
                                },
                                onRemoveCluster = { idx ->
                                    clustersInput = clustersInput.filterIndexed { i, _ -> i != idx }
                                    if (clustersInput.isEmpty()) setKindInput = "straight"
                                    persistDraft()
                                },
                                onWodTimerStart = { controlLocalWodTimer("start") },
                                onWodTimerPause = { controlLocalWodTimer("pause") },
                                onWodTimerReset = { controlLocalWodTimer("reset") },
                                onQueueSet = { session -> queueSet(session) },
                                onResendPending = { resendPending() },
                                onDiscardConfirm = { ask -> confirmDiscardPending = ask },
                                onDiscardPending = {
                                    val dropped = runCatching {
                                        pendingStore.clear()
                                        transportRevision++
                                        pendingCount = 0
                                    }.isSuccess
                                    confirmDiscardPending = false
                                    sendStatus = if (dropped) "Series pendientes descartadas"
                                        else "No se pudieron descartar los registros"
                                },
                                onPlayReady = { playReady() },
                                onShowOutline = { show -> showOutline = show },
                                onShowSetDetails = { show -> showSetDetails = show },
                                onReviewBlock = { beginBlockReview() },
                                onConfirmBlock = { confirmBlockReview() },
                                onAdjustReviewRounds = { d -> reviewRounds = (reviewRounds + d).coerceAtLeast(0) },
                                onAdjustReviewExtraReps = { d -> reviewExtraReps = (reviewExtraReps + d).coerceAtLeast(0) },
                                onAdjustReviewElapsed = { d ->
                                    reviewElapsedSeconds = (reviewElapsedSeconds + d).coerceAtLeast(0)
                                },
                                onSwipeSet = { delta ->
                                    val session = visibleSession ?: return@WearHomeCallbacks
                                    val planned = maxOf(1, session.plannedWorkSets)
                                    val base = setReviewIndex ?: session.recordedSets
                                    setReviewIndex = (base + delta).coerceIn(0, maxOf(0, planned - 1))
                                },
                                onHubPlay = { item -> onHubPlay(item) },
                                onHubIndexChange = { idx ->
                                    hubIndex = idx
                                    val items = wearHubCarouselItems(todayPlanJson, recentLiveSportIDs)
                                    val id = items.getOrNull(idx)?.let { carouselItemId(it) }
                                    sessionCache.edit()
                                        .putInt("hubIndex", idx)
                                        .apply {
                                            if (id != null) putString("lastHubItemID", id)
                                            else remove("lastHubItemID")
                                        }
                                        .apply()
                                },
                                onOpenTimer = { hubOverlay = WearHubOverlay.TIMER_CONFIG },
                                onToggleHubAudioMuted = {
                                    hubAudioMuted = !hubAudioMuted
                                    sessionCache.edit()
                                        .putBoolean("hubAudioMuted", hubAudioMuted)
                                        .putBoolean("hubAudioMutedTouched", true)
                                        .apply()
                                }
                            ),
                            modifier = Modifier.fillMaxSize().padding(insets)
                        )
                        }
                    }
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()
        if (visibleSession?.phase == "counting" && elapsedJob == null) resumeElapsedClock()
        healthBound=bindService(android.content.Intent(this,WearHealthService::class.java),healthServiceConnection,android.content.Context.BIND_AUTO_CREATE)
        motionSensor?.let { sensor ->
            sensorManager?.registerListener(this, sensor, 40_000)
        }
        dataClient.addListener(this)
        messageClient.addListener(this)
        resendPending()
        dataClient.dataItems.addOnSuccessListener { items ->
            try {
                for (item in items) {
                    if (item.uri.path == "/repera/session-terminal") {
                        val data = DataMapItem.fromDataItem(item).dataMap
                        runOnUiThread { receivePhoneTerminal(data.getString("sessionId"), data.getBoolean("saved")) }
                    }
                    if (item.uri.path == "/repera/active-session") {
                        val data = DataMapItem.fromDataItem(item).dataMap
                        val bytes = data.getByteArray("session")
                        val finished = data.getByteArray("finished")
                        val signedOut = data.getBoolean("signedOut")
                        val effort = data.getString("effortUnit")
                        val weight = data.getString("weightUnit")
                        val discardedId = data.getString("discardedSessionId")
                        runOnUiThread { showSession(bytes, signedOut, finished, effort, weight, discardedId) }
                    }
                    if (item.uri.path == "/repera/wod-timer") {
                        val bytes = DataMapItem.fromDataItem(item).dataMap
                            .getByteArray("timer")
                        runOnUiThread { showWodTimer(bytes) }
                    }
                    if (item.uri.path == "/repera/live-activity") {
                        val bytes = DataMapItem.fromDataItem(item).dataMap.getByteArray("live")
                        runOnUiThread { showLiveActivity(bytes) }
                    }
                    if (item.uri.path == "/repera/today-plan") {
                        val map = DataMapItem.fromDataItem(item).dataMap
                        runOnUiThread { showTodayPlanFromMap(map) }
                    }
                }
            } finally {
                items.release()
            }
        }
    }

    override fun onStop() {
        persistElapsedClock()
        elapsedJob?.cancel()
        elapsedJob = null
        persistDraft()
        persistRest()
        healthConnection?.observe(null);healthConnection=null
        if(healthBound) {unbindService(healthServiceConnection);healthBound=false}
        sensorManager?.unregisterListener(this)
        messageClient.removeListener(this)
        dataClient.removeListener(this)
        super.onStop()
    }

    override fun onDataChanged(events: DataEventBuffer) {
        for (event in events) {
            if (event.dataItem.uri.path == "/repera/session-terminal") {
                val data = DataMapItem.fromDataItem(event.dataItem).dataMap
                runOnUiThread { receivePhoneTerminal(data.getString("sessionId"), data.getBoolean("saved")) }
            }
            if (event.dataItem.uri.path == "/repera/active-session") {
                val data = DataMapItem.fromDataItem(event.dataItem).dataMap
                val bytes = data.getByteArray("session")
                val finished = data.getByteArray("finished")
                val signedOut = data.getBoolean("signedOut")
                val effort = data.getString("effortUnit")
                val weight = data.getString("weightUnit")
                val discardedId = data.getString("discardedSessionId")
                runOnUiThread { showSession(bytes, signedOut, finished, effort, weight, discardedId) }
            }
            if (event.dataItem.uri.path == "/repera/wod-timer") {
                val bytes = DataMapItem.fromDataItem(event.dataItem).dataMap
                    .getByteArray("timer")
                runOnUiThread { showWodTimer(bytes) }
            }
            if (event.dataItem.uri.path == "/repera/live-activity") {
                val bytes = DataMapItem.fromDataItem(event.dataItem).dataMap.getByteArray("live")
                runOnUiThread { showLiveActivity(bytes) }
            }
            if (event.dataItem.uri.path == "/repera/today-plan") {
                val map = DataMapItem.fromDataItem(event.dataItem).dataMap
                runOnUiThread { showTodayPlanFromMap(map) }
            }
        }
    }

    override fun onMessageReceived(event: MessageEvent) {
        if(event.path=="/repera/session-finish-ack") {
            val ack=runCatching {JSONObject(String(event.data,Charsets.UTF_8))}.getOrNull() ?: return
            if(ack.optString("status")=="saved") runOnUiThread {
                runCatching {if(pendingFinish.sessionId()==ack.optString("sessionId")) {pendingFinish.acknowledge(ack.optString("sessionId"));sendStatus="Fin confirmado por el teléfono"}}.onSuccess {}
                    .onFailure {sendStatus="No se pudo guardar la confirmación; se reintentará sin duplicar"}
            }
            return
        }
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
                    if(cleared) resendFinish()
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

    /**
     * Conteo automático de repeticiones por acelerómetro, igual que
     * WatchSessionHub.startMotion/tickMotion de watchOS: solo para estilos de
     * fuerza, sin descanso en curso, sin pausa; la magnitud se convierte a G
     * (userAcceleration de CoreMotion ya viene sin gravedad) con el mismo
     * desplazamiento +1. Nunca pisa una prescripción ni el ajuste manual.
     */
    override fun onSensorChanged(event: SensorEvent) {
        val session = visibleSession ?: return
        if (!session.canLogOnWatch || !dev.repera.domain.WatchQuantityPolicy.usesMotion(session.inputMode) ||
            session.wodFormatLabel != null || sessionPaused || restRemaining > 0) return
        val x = event.values[0]; val y = event.values[1]; val z = event.values[2]
        val magnitudeG = kotlin.math.sqrt(
            (x * x + y * y + z * z).toDouble()) / 9.80665 + 1.0
        repCounter.ingest(magnitudeG,
            SystemClock.elapsedRealtimeNanos() / 1_000_000_000.0)
        if (session.prescribedReps == null) {
            repsInput = repCounter.count
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private fun adjustQuantity(delta: Int) {
        val session = visibleSession ?: return
        if (sessionPaused) return
        // Non-motion drafts (including a hold seeded to one) must not use a
        // zero-based repCounter as their source when the user taps +/-.
        val previous = repsInput
        repsInput = dev.repera.domain.WatchQuantityPolicy.adjusted(previous, delta)
        if (session.prescribedReps == null &&
            dev.repera.domain.WatchQuantityPolicy.usesMotion(session.inputMode)) {
            repCounter.applyManualDelta(repsInput - previous)
        }
        persistDraft()
    }

    private fun seedDraft(summary:WatchSessionSummary) {
        repsInput=if(summary.mobilityHold) 1 else summary.prescribedReps ?: 0
        weightInput=summary.prescribedWeightKg.takeIf {summary.allowsWeight}
        warmupInput=false;failureInput=summary.prescribedRir==0.0
        rirInput=summary.prescribedRir;unitInput=summary.quantityUnit
        durationInput=summary.prescribedDurationSeconds ?: if(summary.mobilityHold) 30 else 60
        deficitInput=summary.prescribedDeficitCm ?: 0
        setKindInput="straight";dropsInput=emptyList();clustersInput=emptyList()
        ensureLocalWodTimer(summary)
    }

    private fun persistDraft() {
        val session=visibleSession ?: return
        val kind=if(warmupInput) "straight" else setKindInput
        val draft=runCatching { dev.repera.domain.WatchInputDraft(
            session.sessionId,session.exerciseIndex,session.recordedTotalSets,repsInput,
            weightInput,rirInput,durationInput,unitInput,deficitInput,warmupInput,failureInput,
            kind=kind,
            drops=if(kind=="dropset") dropsInput else emptyList(),
            clusters=if(kind=="restpause") clustersInput else emptyList())
        }.getOrNull() ?: return
        if(!sessionCache.edit().putString("inputDraft",draft.encode()).commit())
            sendStatus="No se pudo guardar el borrador; no se ha confirmado ninguna serie"
    }

    private fun restoreDraft(summary:WatchSessionSummary) {
        val draft=sessionCache.getString("inputDraft",null)?.let {
            dev.repera.domain.WatchInputDraft.decode(it)
        } ?: return
        if(!draft.matches(summary.sessionId,summary.exerciseIndex,summary.recordedTotalSets)) return
        repsInput=draft.quantity;weightInput=draft.weightKg.takeIf {summary.allowsWeight}
        rirInput=draft.rir;durationInput=draft.durationSeconds;unitInput=draft.unit
        deficitInput=draft.deficitCm;warmupInput=draft.warmup;failureInput=draft.toFailure
        setKindInput=draft.kind;dropsInput=draft.drops;clustersInput=draft.clusters
        if(summary.prescribedReps==null && dev.repera.domain.WatchQuantityPolicy.usesMotion(summary.inputMode))
            repCounter.applyManualDelta(draft.quantity)
    }

    private fun effectiveWodTimer(session: WatchSessionSummary?): JSONObject? {
        session ?: return null
        phoneWodTimerJson?.takeIf {
            wearTimerMatches(it, session.sessionId, session.exerciseIndex)
        }?.let { return it }
        return localWodTimerJson?.takeIf {
            wearTimerMatches(it, session.sessionId, session.exerciseIndex)
        }
    }

    private fun ensureLocalWodTimer(summary: WatchSessionSummary) {
        if (summary.wodFormatLabel == null) {
            localWodTimerJson = null
            return
        }
        phoneWodTimerJson?.takeIf {
            wearTimerMatches(it, summary.sessionId, summary.exerciseIndex)
        }?.let { return }
        if (wearTimerMatches(localWodTimerJson, summary.sessionId, summary.exerciseIndex)) return
        val snapshot = sessionCache.getString("snapshot", null)?.let {
            runCatching { JSONObject(it) }.getOrNull()
        }
        val exercise = snapshot?.optJSONArray("exercises")
            ?.optJSONObject(summary.exerciseIndex - 1)
        localWodTimerJson = exercise?.let {
            WearLocalWodClock.seed(summary.sessionId, summary.exerciseIndex - 1, it)
        }
        refreshWodTickFromEffective()
    }

    private fun controlLocalWodTimer(action: String) {
        val session = visibleSession ?: return
        ensureLocalWodTimer(session)
        val base = localWodTimerJson?.takeIf {
            wearTimerMatches(it, session.sessionId, session.exerciseIndex)
        } ?: return
        localWodTimerJson = when (action) {
            "start" -> WearLocalWodClock.start(base)
            "pause" -> WearLocalWodClock.pause(base)
            "reset" -> WearLocalWodClock.reset(base)
            else -> base
        }
        // Preferimos el local tras control manual si el teléfono no publica matching.
        if (phoneWodTimerJson != null &&
            !wearTimerMatches(phoneWodTimerJson, session.sessionId, session.exerciseIndex)) {
            phoneWodTimerJson = null
        }
        refreshWodTickFromEffective()
    }

    private fun refreshWodTickFromEffective() {
        wodTickJob?.cancel()
        val timer = effectiveWodTimer(visibleSession)
        if (timer == null) {
            wodTickSeconds = 0
            return
        }
        if (timer.optBoolean("running") &&
            timer.has("zeroAtWallMs") && !timer.isNull("zeroAtWallMs")) {
            wodTickJob = lifecycleScope.launch {
                while (true) {
                    val live = effectiveWodTimer(visibleSession) ?: break
                    wodTickSeconds = WearLocalWodClock.tickElapsed(live)
                    kotlinx.coroutines.delay(250)
                }
            }
        } else {
            wodTickSeconds = timer.optInt("elapsedSeconds", 0)
        }
    }

    private fun showLiveActivity(bytes: ByteArray?) {
        if (suppressCompanionLive) {
            if (bytes == null || bytes.isEmpty()) {
                suppressCompanionLive = false
                liveActivityJson = null
                return
            }
            val parsed = runCatching {
                JSONObject(String(bytes, Charsets.UTF_8))
            }.getOrNull()
            // Nueva grabación del teléfono: dejar de suprimir.
            if (parsed?.optString("phase") == "recording") {
                suppressCompanionLive = false
                liveActivityJson = parsed
            }
            return
        }
        liveActivityJson = bytes?.takeIf { it.isNotEmpty() }?.let {
            runCatching { JSONObject(String(it, Charsets.UTF_8)) }.getOrNull()
        }
    }

    private fun presentCompanionFinished(live: JSONObject) {
        val elapsed = live.optDouble("elapsedSeconds", 0.0)
            .takeIf { it.isFinite() }?.toInt()?.coerceAtLeast(0) ?: 0
        val meters = live.optDouble("distanceMeters", 0.0).takeIf { it.isFinite() && it > 0 }
        finishedSummary = FinishedSummary(
            sessionId = live.optString("sessionId").ifBlank { "companion" },
            title = live.optString("sportTitle").ifBlank { "Actividad" },
            durationLabel = wearClockLabel(elapsed),
            exercises = 0,
            sets = 0,
            reps = 0,
            volumeKg = 0,
            isLive = true,
            distanceLabel = meters?.let { String.format("%.2f km", it / 1000.0) }
        )
        suppressCompanionLive = true
        liveActivityJson = null
    }

    private fun requestLiveCommand(command: String) {
        if (command !in setOf("pause", "resume", "finish")) return
        val live = liveActivityJson ?: return
        val id = live.optString("sessionId").orEmpty()
        if (id.isBlank()) return
        val payload = JSONObject().put("sessionId", id).put("command", command)
            .toString().toByteArray(Charsets.UTF_8)
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            if (liveActivityJson?.optString("sessionId") != id && command != "finish") {
                return@addOnSuccessListener
            }
            if (nodes.isEmpty()) {
                sendStatus = "Móvil desconectado; actividad conservada"
                return@addOnSuccessListener
            }
            nodes.forEach { node ->
                Wearable.getMessageClient(this).sendMessage(
                    node.id, "/repera/live-command", payload
                )
            }
            if (command == "finish") {
                presentCompanionFinished(live)
                sendStatus = null
            } else {
                sendStatus = "Control enviado; esperando estado del móvil"
            }
        }
    }

    private fun showTodayPlanFromMap(map: com.google.android.gms.wearable.DataMap) {
        val bytes = map.getByteArray("plan")
        val updatedAtMillis = map.getLong("updatedAtMillis", System.currentTimeMillis())
        map.getStringArray("recentLiveSportIDs")?.toList()?.let { ids ->
            recentLiveSportIDs = ids
            sessionCache.edit()
                .putString("recentLiveSportIDs", JSONArray(ids).toString())
                .apply()
        }
        if (map.containsKey("audioMuted") &&
            !sessionCache.getBoolean("hubAudioMutedTouched", false)) {
            hubAudioMuted = map.getBoolean("audioMuted")
        }
        showTodayPlan(bytes, updatedAtMillis)
    }

    private fun showTodayPlan(bytes: ByteArray?, updatedAtMillis: Long = System.currentTimeMillis()) {
        val parsed = bytes?.takeIf { it.isNotEmpty() }?.let {
            runCatching { JSONObject(String(it, Charsets.UTF_8)) }.getOrNull()
        }
        // Plan stale (>18 h) o vacío: no ofrecer Empezar con un día viejo.
        val fresh = parsed != null &&
            updatedAtMillis > 0L &&
            System.currentTimeMillis() - updatedAtMillis <= TODAY_PLAN_TTL_MS
        todayPlanJson = parsed.takeIf { fresh }
        if (todayPlanJson != null) {
            sessionCache.edit()
                .putString("todayPlan", todayPlanJson.toString())
                .putLong("todayPlanAt", updatedAtMillis)
                .apply()
        } else {
            sessionCache.edit().remove("todayPlan").remove("todayPlanAt").apply()
        }
    }

    private fun onHubPlay(item: WearHubCarouselItem) {
        // Conservar el ítem del carrusel para restaurarlo al Volver al inicio.
        val itemId = when (item) {
            is WearHubCarouselItem.Plan ->
                "plan-${item.plan.optString("id").ifBlank { item.plan.optString("title") }}"
            is WearHubCarouselItem.Sport -> "sport-${item.sportId}"
        }
        sessionCache.edit().putString("lastHubItemID", itemId).apply()
        val items = wearHubCarouselItems(todayPlanJson, recentLiveSportIDs)
        items.indexOfFirst { carouselItemId(it) == itemId }.takeIf { it >= 0 }?.let { idx ->
            hubIndex = idx
            sessionCache.edit().putInt("hubIndex", idx).apply()
        }
        when (item) {
            is WearHubCarouselItem.Plan -> startTodayPlan()
            is WearHubCarouselItem.Sport -> requestLiveStart(item.sportId)
        }
    }

    private fun carouselItemId(item: WearHubCarouselItem): String = when (item) {
        is WearHubCarouselItem.Plan ->
            "plan-${item.plan.optString("id").ifBlank { item.plan.optString("title") }}"
        is WearHubCarouselItem.Sport -> "sport-${item.sportId}"
    }

    private fun resolvedHubIndex(): Int {
        val items = wearHubCarouselItems(todayPlanJson, recentLiveSportIDs)
        if (items.isEmpty()) return 0
        val lastId = sessionCache.getString("lastHubItemID", null)
        if (!lastId.isNullOrBlank()) {
            val idx = items.indexOfFirst { carouselItemId(it) == lastId }
            if (idx >= 0) return idx
        }
        return hubIndex.coerceIn(0, items.lastIndex)
    }

    private fun requestLiveStart(sportId: String) {
        if (sportId.isBlank()) return
        suppressCompanionLive = false
        val phase = liveActivityJson?.optString("phase")
        if (liveActivityJson != null && phase != "review") {
            sendStatus = "Actividad en curso en el teléfono"
            return
        }
        if (phase == "review") {
            liveActivityJson = null
        }
        if (visibleSession != null) {
            sendStatus = "Hay un entreno activo; termínalo antes de Comenzar"
            return
        }
        val payload = JSONObject().put("sportId", sportId)
            .toString().toByteArray(Charsets.UTF_8)
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            if (nodes.isEmpty()) {
                sendStatus = "Móvil desconectado; abre Repera en el teléfono"
                return@addOnSuccessListener
            }
            nodes.forEach { node ->
                messageClient.sendMessage(node.id, "/repera/live-start", payload)
            }
            sendStatus = "Iniciando ${LiveSport.byId(sportId)?.title ?: "actividad"}…"
        }
    }

    private fun sendTimerDetailsToPhone(
        details: dev.repera.domain.TimerCompletionDetails,
        startedAtMillis: Long,
        finishedAtMillis: Long
    ) {
        val id = java.util.UUID.randomUUID().toString()
        val payload = JSONObject()
            .put("id", id)
            .put("startedAtMillis", startedAtMillis)
            .put("finishedAtMillis", finishedAtMillis)
            .put("timerDetails", details.toJson())
            .toString().toByteArray(Charsets.UTF_8)
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            if (nodes.isEmpty()) {
                // TODO: cola local de timerDetails cuando no hay /repera/timer-save reachable.
                sendStatus = "Temporizador listo; sin teléfono para guardar"
                return@addOnSuccessListener
            }
            nodes.forEach { node ->
                messageClient.sendMessage(node.id, "/repera/timer-save", payload)
            }
            sendStatus = "Temporizador enviado al teléfono"
        }
    }

    /**
     * Ejecución autónoma offline: el reloj arranca el plan del día sin sesión
     * activa en el teléfono (startToday de watchOS). Las series se encolan con
     * la sesión adjunta y el teléfono la adopta al reconciliar.
     */
    private fun startTodayPlan(startIndex: Int = 0) {
        if(visibleSession!=null || runCatching {pendingFinish.sessionId()!=null}.getOrDefault(true)) {
            sendStatus="Hay una sesión activa o pendiente de terminar";return
        }
        val prescription = todayPlanJson ?: return
        val begun=runCatching {dev.repera.domain.WatchPlanExecution.begin(prescription)}.getOrElse {
            sendStatus="No se pudo iniciar el plan: ${it.localizedMessage}";return
        }
        // Apple startToday + selectBlock(startingAt:): jump without completing skipped work.
        val plan=if(startIndex>0) dev.repera.domain.WatchPlanExecution.select(begun,startIndex) ?: begun else begun
        val summary = runCatching { WatchSessionSummary.fromJson(plan) }.getOrNull()
            ?: return
        if(!sessionCache.edit().putString("snapshot",plan.toString()).putBoolean("watchStarted",true)
                .remove("todayPlan").remove("todayPlanAt").remove("inputDraft").remove("restState").commit()) {
            sendStatus="No se pudo guardar el inicio en el reloj";return
        }
        sensorRevision++
        sessionPaused=false
        restJob?.cancel();restClock.clear();restRemaining=0
        wodTickJob?.cancel();phoneWodTimerJson=null;localWodTimerJson=null;wodTickSeconds=0
        finishedSummary=null
        showOutline=false;showSetDetails=false;reviewingBlock=false
        warmupInput=false;failureInput=false
        visibleSession = summary
        seedDraft(summary)
        showingCachedSession = false
        watchStartedSession = true
        repCounter.reset()
        todayPlanJson = null
        resetElapsedClock()
        ensureHealthRecording()
        // begin() leaves phase=ready (Apple startOnPhone). Stay ready until Play.
        pauseSensorsIntent = dev.repera.domain.WearStartPauseIntent(summary.sessionId)
        sessionPaused = true
        restClock.pause(SystemClock.elapsedRealtime())
        persistRest()
    }

    /** Descartar sin guardar (Ramón F-5): cierra en Wear y pide lo mismo al teléfono. */
    private fun discardSessionFromWatch(session: WatchSessionSummary) {
        if (visibleSession?.sessionId != session.sessionId) return
        rememberDiscarded(session.sessionId)
        runCatching { pendingFinish.clear() }
        finishedSummary = null
        showOutline = false
        showSetDetails = false
        reviewingBlock = false
        val payload = JSONObject().put("sessionId", session.sessionId)
            .toString().toByteArray(Charsets.UTF_8)
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            nodes.forEach {
                Wearable.getMessageClient(this).sendMessage(it.id, "/repera/session-discard", payload)
            }
        }
        clearSession(erasePending = true)
        sendStatus = "Entrenamiento descartado"
    }

    private fun rememberDiscarded(sessionId: String) {
        val prev = sessionCache.getStringSet("discardedSessionIds", emptySet())?.toMutableSet()
            ?: mutableSetOf()
        prev.add(sessionId)
        // Cap set size to avoid unbounded prefs growth.
        val trimmed = prev.toList().takeLast(32).toSet()
        sessionCache.edit().putStringSet("discardedSessionIds", trimmed).apply()
    }

    /** Terminar la sesión desde el reloj (mismo resultado que finish en iOS). */
    private fun finishSessionFromWatch(session: WatchSessionSummary) {
        if(visibleSession?.sessionId!=session.sessionId) {
            sendStatus="La sesión cambió; revisa el entrenamiento antes de terminar";return
        }
        rememberDiscarded(session.sessionId)
        runCatching {pendingFinish.queue(session.sessionId)}.onFailure {
            sendStatus="No se pudo guardar la petición de terminar: ${it.localizedMessage}";return
        }
        sendStatus="Fin guardado en el reloj; esperando confirmar series y teléfono"
        resendPending()
    }

    private fun resendFinish() {
        val sessionId=runCatching {pendingFinish.sessionId()}.getOrNull() ?: return
        // Never race finish against unacknowledged sets for this session.
        if(runCatching {pendingStore.all().any {it.optString("sessionId")==sessionId}}.getOrDefault(true)) return
        val revision=transportRevision
        val payload=JSONObject().put("sessionId",sessionId).toString().toByteArray(Charsets.UTF_8)
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener {nodes ->
            if(revision!=transportRevision || runCatching {pendingFinish.sessionId()!=sessionId}.getOrDefault(true)) return@addOnSuccessListener
            if(nodes.isEmpty()) {sendStatus="Fin pendiente de conexión; conservado en el reloj";return@addOnSuccessListener}
            nodes.forEach {node ->Wearable.getMessageClient(this).sendMessage(node.id,"/repera/session-finish",payload)}
            sendStatus="Fin enviado; esperando confirmación del teléfono"
        }
    }

    private fun showWodTimer(bytes: ByteArray?) {
        val parsed = bytes?.takeIf { it.isNotEmpty() }?.let {
            runCatching { JSONObject(String(it, Charsets.UTF_8)) }.getOrNull()
        }
        phoneWodTimerJson = parsed
        // Teléfono matching gana: limpia local del mismo bloque.
        val session = visibleSession
        if (parsed != null && session != null &&
            wearTimerMatches(parsed, session.sessionId, session.exerciseIndex)) {
            localWodTimerJson = null
        }
        refreshWodTickFromEffective()
    }

    private fun queueSet(session: WatchSessionSummary) {
        if(visibleSession?.sessionId!=session.sessionId || visibleSession?.exerciseIndex!=session.exerciseIndex) return
        if(sessionPaused) {sendStatus="Reanuda la sesión antes de confirmar una serie";return}
        if(runCatching {pendingFinish.sessionId()==session.sessionId}.getOrDefault(true)) {
            sendStatus="La sesión está pendiente de terminar; no se añaden más series";return
        }
        if (!session.canLogOnWatch) return
        if (session.wodFormatLabel != null && !session.wodUsesSeries) return
        // Apple ea99a5b6/a4a5d9ce: cero reps nunca se registra; con cero la
        // acción salta el descanso activo y avanza (o termina en el último).
        if (repsInput == 0) {
            if (restRemaining > 0) skipRest()
            if (session.exerciseIndex >= session.exerciseCount) {
                finishSessionFromWatch(session)
            } else {
                requestSelectBlock(session, session.exerciseIndex)
            }
            return
        }
        if (repsInput !in 1..10000) return
        // Apple 44713457: una serie WOD confirmada pertenece al intervalo actual
        // del reloj del bloque; sin reloj activo no se deriva ni se inventa.
        val activeTimer = effectiveWodTimer(session)
        val wodInterval = if (session.wodUsesSeries) {
            val derived = wearWodIntervalIndex(activeTimer, session.sessionId,
                session.exerciseIndex, wodTickSeconds)
            if (derived == null) {
                sendStatus = "Inicia el reloj del bloque para registrar desde el reloj"
                return
            }
            derived
        } else null
        val strengthMode = !session.wodUsesSeries &&
            session.inputMode in setOf("strength", "hspuDeficit", "repsOnly")
        val kind = if (strengthMode && !warmupInput) setKindInput else "straight"
        val queued = runCatching {
            pendingStore.append(session.sessionId, session.exerciseIndex - 1,
                repsInput, weightInput, if(strengthMode && !warmupInput) rirInput else null,
                durationSeconds = if (!session.wodUsesSeries && session.inputMode in setOf("repsAndTime","machineWork"))
                    durationInput else null,
                quantityUnit = if (!session.wodUsesSeries && session.inputMode in setOf("machineWork","loadDistance"))
                    unitInput else null,
                deficitCm = if (!session.wodUsesSeries && session.inputMode == "hspuDeficit")
                    deficitInput else null,
                intervalIndex = wodInterval,
                sessionJson = if (watchStartedSession)
                    sessionCache.getString("snapshot", null) else null,
                warmup=warmupInput && strengthMode,toFailure=failureInput && !warmupInput && strengthMode,
                kind = kind,
                drops = if (kind == "dropset") dropsInput else emptyList(),
                clusters = if (kind == "restpause") clustersInput else emptyList())
            pendingCount = pendingStore.count()
        }
        if (queued.isFailure) {
            sendStatus = "No se pudo guardar la serie en el reloj: " +
                (queued.exceptionOrNull()?.localizedMessage ?: "revisa el almacenamiento")
            return
        }
        sendStatus = "Serie guardada en el reloj; esperando confirmación"
        repCounter.reset()
        if (session.prescribedReps == null) repsInput = 0
        setKindInput = "straight"; dropsInput = emptyList(); clustersInput = emptyList()
        persistDraft()
        // Apple 44713457: tras una serie WOD el descanso es del formato
        // (Tabata: blockRest; resto: lo que queda de intervalo), no el de fuerza.
        val rest = if (session.wodUsesSeries)
            wearWodRestAfterConfirmedSet(activeTimer, session.sessionId,
                session.exerciseIndex, wodTickSeconds) ?: 0
        else dev.repera.domain.WatchStrengthRest.afterConfirmedSet(session.restSeconds,
            warmupInput,session.recordedSets + if(warmupInput) 0 else 1,session.plannedWorkSets)
        if(rest>0) startRest(rest) else skipRest()
        resendPending()
    }

    private fun bootCount():Int? = runCatching {
        android.provider.Settings.Global.getInt(contentResolver,android.provider.Settings.Global.BOOT_COUNT)
    }.getOrNull()?.takeIf {it>=0}

    private fun persistRest() {
        val session=visibleSession ?: return
        val boot=bootCount() ?: return
        val now=SystemClock.elapsedRealtime()
        val checkpoint=runCatching {dev.repera.domain.WatchRestState(
            session.sessionId,sessionPaused,restClock.remainingMillis(now),now,boot)
        }.getOrNull() ?: return
        if(!sessionCache.edit().putString("restState",checkpoint.encode()).commit())
            sendStatus="No se pudo guardar la pausa o el descanso del reloj"
    }

    private fun restoreRest(summary:WatchSessionSummary) {
        val checkpoint=sessionCache.getString("restState",null)?.let {
            dev.repera.domain.WatchRestState.decode(it)
        } ?: return
        val now=SystemClock.elapsedRealtime()
        val remaining=checkpoint.remainingAt(summary.sessionId,now,bootCount())
        if(remaining==null) {
            sessionCache.edit().remove("restState").apply()
            sendStatus="No se pudo recuperar la pausa o el descanso tras reiniciar el reloj"
            return
        }
        sessionPaused=checkpoint.paused
        restClock.restore(remaining,sessionPaused,now)
        // The durable UI pause is the source of truth after a restart: recreate the intent so sensors that are
        // recording unpaused (service/process restarted) are paused again once confirmed recording.
        if(sessionPaused) pauseSensorsIntent=dev.repera.domain.WearStartPauseIntent(summary.sessionId)
        tickRest()
    }

    private fun startRest(seconds: Int) {
        restClock.start(seconds,SystemClock.elapsedRealtime())
        if(sessionPaused) restClock.pause(SystemClock.elapsedRealtime())
        tickRest()
        persistRest()
    }

    private fun tickRest() {
        restJob?.cancel()
        restRemaining=restClock.remainingSeconds(SystemClock.elapsedRealtime())
        if(sessionPaused) return
        restJob=lifecycleScope.launch {
            while(restRemaining>0) {
                kotlinx.coroutines.delay(250)
                restRemaining=restClock.remainingSeconds(SystemClock.elapsedRealtime())
            }
        }
    }

    private fun skipRest() {
        restJob?.cancel();restClock.clear();restRemaining=0
        persistRest()
    }

    private fun playReady() {
        val session = visibleSession ?: return
        if (session.phase != "ready") {
            // Already counting: Play = resume.
            if (sessionPaused) togglePause()
            return
        }
        if (watchStartedSession) {
            val snapshot = sessionCache.getString("snapshot", null)
                ?.let { runCatching { JSONObject(it) }.getOrNull() } ?: return
            val played = dev.repera.domain.WatchPlanExecution.play(snapshot) ?: return
            val summary = runCatching { WatchSessionSummary.fromJson(played) }.getOrNull() ?: return
            if (!sessionCache.edit().putString("snapshot", played.toString()).commit()) {
                sendStatus = "No se pudo iniciar el bloque en el reloj"; return
            }
            visibleSession = summary
        } else {
            // Phone-driven: local UI advances to counting; phone already has counting after start.
            visibleSession = session.copy(phase = "counting")
        }
        showOutline = false
        reviewingBlock = false
        sessionPaused = false
        pauseSensorsIntent = null
        healthConnection?.pause(session.sessionId, false)
        startElapsedClock()
        // WOD: seed local clock when starting the block offline.
        if (visibleSession?.wodFormatLabel != null) controlLocalWodTimer("start")
    }

    private fun beginBlockReview() {
        val session = visibleSession ?: return
        if (session.wodFormatLabel == null) return
        tickElapsed()
        reviewingBlock = true
        showOutline = false
        showSetDetails = false
        sessionPaused = true
        reviewRounds = 0
        reviewExtraReps = 0
        reviewElapsedSeconds = elapsedSeconds
        healthConnection?.pause(session.sessionId, true)
        restJob?.cancel()
    }

    private fun confirmBlockReview() {
        val session = visibleSession ?: return
        if (!reviewingBlock) return
        val format = WodFormat.fromWire(session.wodFormatWire.orEmpty())
        if (watchStartedSession) {
            val snapshot = sessionCache.getString("snapshot", null)
                ?.let { runCatching { JSONObject(it) }.getOrNull() } ?: return
            val exercises = snapshot.optJSONArray("exercises") ?: return
            val blockId = session.blockId
            if (!blockId.isNullOrBlank() && format != null &&
                format.capture != dev.repera.domain.ResultCapture.PER_MOVEMENT_SETS) {
                val score = JSONObject().put("id", blockId).put("format", format.wireName)
                when (format.capture) {
                    dev.repera.domain.ResultCapture.TOTAL_REPS -> {
                        if (format == WodFormat.AMRAP || format == WodFormat.DEATH_BY)
                            score.put("roundsCompleted", reviewRounds)
                        score.put("totalReps", reviewExtraReps)
                    }
                    dev.repera.domain.ResultCapture.ELAPSED_TIME ->
                        score.put("elapsedSeconds", reviewElapsedSeconds)
                    else -> {}
                }
                val previous = snapshot.optJSONArray("wodResults") ?: JSONArray()
                val revised = JSONArray()
                for (i in 0 until previous.length()) {
                    if (previous.getJSONObject(i).optString("id") != blockId)
                        revised.put(previous.getJSONObject(i))
                }
                revised.put(score)
                snapshot.put("wodResults", revised)
            }
            // Mark block exercises completed and advance, mirroring recordWodScore.
            var nextIndex = session.exerciseIndex // 1-based current → next after block
            if (!blockId.isNullOrBlank()) {
                for (i in 0 until exercises.length()) {
                    if (exercises.getJSONObject(i).optString("blockId") == blockId)
                        exercises.getJSONObject(i).put("isCompleted", true)
                }
                nextIndex = session.exerciseIndex - 1
                while (nextIndex < exercises.length() &&
                    exercises.getJSONObject(nextIndex).optString("blockId") == blockId) {
                    nextIndex++
                }
            }
            reviewingBlock = false
            if (nextIndex >= exercises.length()) {
                sessionCache.edit().putString("snapshot", snapshot.toString()).commit()
                finishSessionFromWatch(session)
                return
            }
            snapshot.put("currentIndex", nextIndex).put("phase", "ready")
            sessionCache.edit().putString("snapshot", snapshot.toString()).commit()
            val summary = runCatching { WatchSessionSummary.fromJson(snapshot) }.getOrNull() ?: return
            visibleSession = summary
            seedDraft(summary)
            sessionPaused = true
            resetElapsedClock()
            pauseSensorsIntent = dev.repera.domain.WearStartPauseIntent(summary.sessionId)
            healthConnection?.pause(summary.sessionId, true)
            return
        }
        // Phone-driven: send score then jump / finish via existing bridges.
        reviewingBlock = false
        if (format != null && format.capture != dev.repera.domain.ResultCapture.PER_MOVEMENT_SETS) {
            val payload = JSONObject()
                .put("sessionId", session.sessionId)
                .put("blockId", session.blockId)
                .put("format", format.wireName)
                .put("roundsCompleted", reviewRounds)
                .put("totalReps", reviewExtraReps)
                .put("elapsedSeconds", reviewElapsedSeconds)
                .toString().toByteArray(Charsets.UTF_8)
            Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
                nodes.forEach {
                    Wearable.getMessageClient(this).sendMessage(it.id, "/repera/wod-score", payload)
                }
            }
        }
        val blocks = session.blocks
        val currentStart = session.exerciseIndex - 1
        val nextBlock = blocks.firstOrNull { it.first > currentStart }?.first
        if (nextBlock == null) finishSessionFromWatch(session)
        else requestSelectBlock(session, nextBlock)
    }

    private fun resetElapsedClock() {
        elapsedJob?.cancel()
        elapsedJob = null
        sessionCache.edit().remove("clockSessionId").remove("clockElapsedSeconds")
            .remove("clockSavedAtMillis").remove("clockPaused").apply()
        elapsedSeconds = 0
        sessionStartedAtElapsed = null
        pausedAccumulatedMs = 0L
        pauseStartedAtElapsed = null
    }

    private fun startElapsedClock() {
        resetElapsedClock()
        sessionStartedAtElapsed = SystemClock.elapsedRealtime()
        elapsedJob = lifecycleScope.launch {
            while (true) {
                kotlinx.coroutines.delay(500)
                tickElapsed()
            }
        }
    }

    private fun resumeElapsedClock() {
        val now = SystemClock.elapsedRealtime()
        sessionStartedAtElapsed = now - elapsedSeconds * 1000L
        pausedAccumulatedMs = 0L
        pauseStartedAtElapsed = if (sessionPaused) now else null
        elapsedJob?.cancel()
        elapsedJob = lifecycleScope.launch {
            while (true) {
                kotlinx.coroutines.delay(500)
                tickElapsed()
            }
        }
    }

    private fun persistElapsedClock() {
        val session = visibleSession ?: return
        if (session.phase != "counting") return
        sessionCache.edit()
            .putString("clockSessionId", session.sessionId)
            .putInt("clockElapsedSeconds", elapsedSeconds)
            .putLong("clockSavedAtMillis", System.currentTimeMillis())
            .putBoolean("clockPaused", sessionPaused)
            .apply()
    }

    private fun tickElapsed() {
        val start = sessionStartedAtElapsed ?: return
        val now = SystemClock.elapsedRealtime()
        val pausedExtra = if (sessionPaused) {
            val pauseAt = pauseStartedAtElapsed ?: now.also { pauseStartedAtElapsed = it }
            pausedAccumulatedMs + (now - pauseAt)
        } else {
            pauseStartedAtElapsed?.let {
                pausedAccumulatedMs += now - it
                pauseStartedAtElapsed = null
            }
            pausedAccumulatedMs
        }
        elapsedSeconds = ((now - start - pausedExtra) / 1000L).toInt().coerceAtLeast(0)
            .coerceAtMost(dev.repera.domain.WearSessionDuration.MAX_SECONDS)
        if (now - lastElapsedCheckpointMs >= 5_000L) {
            lastElapsedCheckpointMs = now
            persistElapsedClock()
        }
    }

        /** Apple selectBlock: ignored while a finish is pending (awaitingHealthSave equivalent: pendingFinish). A watch-started
     *  session is changed locally; a phone session is changed by the phone, which validates session and shown index. */
    private fun requestSelectBlock(session: WatchSessionSummary, toIndex: Int) {
        if (visibleSession?.sessionId != session.sessionId || visibleSession?.exerciseIndex != session.exerciseIndex) return
        if (toIndex !in 0 until session.exerciseCount || toIndex == session.exerciseIndex - 1) return
        if (runCatching { pendingFinish.sessionId() == session.sessionId }.getOrDefault(true)) {
            sendStatus = "La sesión está pendiente de terminar; no se cambia de ejercicio"; return
        }
        if (watchStartedSession) { selectLocally(session, toIndex); return }
        val payload = JSONObject().put("sessionId", session.sessionId)
            .put("fromIndex", session.exerciseIndex - 1).put("toIndex", toIndex).toString().toByteArray(Charsets.UTF_8)
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            if (visibleSession?.sessionId != session.sessionId) return@addOnSuccessListener
            if (nodes.isEmpty()) sendStatus = "Móvil no conectado; no se cambió de ejercicio"
            nodes.forEach { Wearable.getMessageClient(this).sendMessage(it.id, "/repera/select-exercise", payload) }
        }
    }

    /** Apple 4a82b4b2/1d333b42/d350b42f: botón "Sincronizar" del reloj = petición
     *  explícita; el teléfono responde con el plan de HOY fresco por /repera/today-plan. */
    private fun requestTodayPlanSync() {
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            if (nodes.isEmpty()) { sendStatus = "Móvil no conectado; no se pudo sincronizar"; return@addOnSuccessListener }
            nodes.forEach { Wearable.getMessageClient(this).sendMessage(it.id, "/repera/request-today-plan", byteArrayOf()) }
            sendStatus = "Solicitando plan de hoy al móvil…"
        }
    }

    private fun selectLocally(session: WatchSessionSummary, toIndex: Int) {
        val snapshot = sessionCache.getString("snapshot", null)?.let { runCatching { JSONObject(it) }.getOrNull() } ?: return
        if (snapshot.optString("id") != session.sessionId) return
        val changed = dev.repera.domain.WatchPlanExecution.select(snapshot, toIndex) ?: return
        val summary = runCatching { WatchSessionSummary.fromJson(changed) }.getOrNull() ?: return
        if (!sessionCache.edit().putString("snapshot", changed.toString()).remove("inputDraft").remove("restState").commit()) {
            sendStatus = "No se pudo guardar el cambio de ejercicio en el reloj"; return
        }
        restJob?.cancel(); restClock.clear(); restRemaining = 0
        wodTickJob?.cancel(); phoneWodTimerJson = null; localWodTimerJson = null; wodTickSeconds = 0
        visibleSession = summary
        seedDraft(summary)
        repCounter.reset()
        persistDraft()
        // Apple selectBlock → phase ready until Play.
        showOutline = false
        showSetDetails = false
        reviewingBlock = false
        sessionPaused = true
        restClock.pause(SystemClock.elapsedRealtime())
        persistRest()
        pauseSensorsIntent = dev.repera.domain.WearStartPauseIntent(summary.sessionId)
        healthConnection?.pause(summary.sessionId, true)
        resetElapsedClock()
    }

    private fun togglePause() {
        val session=visibleSession ?: return
        val sessionId=session.sessionId
        val nowPaused = !sessionPaused
        sessionPaused = nowPaused
        if(!nowPaused) pauseSensorsIntent=null
        if (nowPaused) {
            restClock.pause(SystemClock.elapsedRealtime());restJob?.cancel()
            restRemaining=restClock.remainingSeconds(SystemClock.elapsedRealtime())
            if (pauseStartedAtElapsed == null) pauseStartedAtElapsed = SystemClock.elapsedRealtime()
            tickElapsed()
        } else {
            restClock.resume(SystemClock.elapsedRealtime());tickRest()
            pauseStartedAtElapsed?.let {
                pausedAccumulatedMs += SystemClock.elapsedRealtime() - it
                pauseStartedAtElapsed = null
            }
            tickElapsed()
        }
        persistRest()
        val revision=sensorRevision
        val transport=transportRevision
        fun current()=visibleSession?.sessionId==sessionId && sensorRevision==revision && transportRevision==transport
        healthConnection?.pause(sessionId,nowPaused) ?: run {sendStatus="Sensores pendientes de conexión; pausa no confirmada"}
        val payload = JSONObject().put("sessionId",sessionId).put("blockIndex",session.exerciseIndex-1).put("paused", nowPaused).toString()
            .toByteArray(Charsets.UTF_8)
        Wearable.getNodeClient(this).connectedNodes
            .addOnSuccessListener { nodes ->
                if(!current() || sessionPaused!=nowPaused) return@addOnSuccessListener
                nodes.forEach { node ->
                    Wearable.getMessageClient(this)
                        .sendMessage(node.id, "/repera/session-pause", payload)
                }
            }
    }

    private fun resendPending() {
        val revision=transportRevision
        val commands = runCatching { pendingStore.all() }.getOrElse {
            sendStatus = "No se puede leer la cola; los datos siguen guardados"
            return
        }
        if (commands.isEmpty()) {resendFinish();return}
        Wearable.getNodeClient(this).connectedNodes
            .addOnSuccessListener { nodes ->
                if(revision!=transportRevision) return@addOnSuccessListener
                val liveIds=runCatching {pendingStore.all().map {it.optString("id")}.toSet()}.getOrNull() ?: return@addOnSuccessListener
                if (nodes.isEmpty()) {
                    runOnUiThread { if(revision==transportRevision) sendStatus = "Sin teléfono conectado · serie conservada" }
                } else {
                    for (node in nodes) for (command in commands) {
                        if(command.optString("id") !in liveIds) continue
                        messageClient.sendMessage(node.id, "/repera/log-set",
                            command.toString().toByteArray(Charsets.UTF_8))
                    }
                }
            }.addOnFailureListener {
                runOnUiThread { if(revision==transportRevision) sendStatus = "Pendiente de conexión con el teléfono" }
            }
    }

    private fun showSession(
        bytes: ByteArray?,
        signedOut: Boolean = false,
        finished: ByteArray? = null,
        effortUnitWire: String? = null,
        weightUnitWire: String? = null,
        explicitlyDiscardedId: String? = null
    ) {
        if (!effortUnitWire.isNullOrBlank() && effortUnitWire in setOf("rir", "rpe")) {
            effortUnit = effortUnitWire
            sessionCache.edit().putString("effortUnit", effortUnitWire).apply()
        }
        if (!weightUnitWire.isNullOrBlank() && weightUnitWire in setOf("kg", "lb")) {
            weightUnit = weightUnitWire
            sessionCache.edit().putString("weightUnit", weightUnitWire).apply()
        }
        showSessionBody(bytes, signedOut, finished, explicitlyDiscardedId)
    }

    private fun showSessionBody(bytes: ByteArray?, signedOut: Boolean = false,
                            finished: ByteArray? = null,
                            explicitlyDiscardedId: String? = null) {
        if (signedOut) {
            liveActivityJson = null
            transportRevision++
            todayPlanJson=null
            sessionCache.edit().remove("todayPlan").remove("todayPlanAt").apply()
            runCatching {pendingFinish.clear()}
            finishedSummary = null
            sessionCache.edit().remove("finishedDismissed").apply()
            clearSession(erasePending = true)
            return
        }
        val completed=FinishedSummary.fromBytes(finished)
        val incomingId=bytes?.takeIf {it.isNotEmpty()}?.let {
            runCatching {JSONObject(String(it,Charsets.UTF_8)).getString("id")}.getOrNull()
        }
        val localId = visibleSession?.sessionId
        if(dev.repera.domain.WatchSessionReconciliation.preserveLocal(
            watchStartedSession,localId,incomingId,completed?.sessionId,explicitlyDiscardedId)) {
            sendStatus="Otra sesión está activa en el teléfono; se conserva la del reloj"
            syncProblem=true
            return
        }
        // Teléfono terminó/descartó: tumba el id local para que un relaunch no resucite.
        if (!watchStartedSession && dev.repera.domain.WatchSessionReconciliation.phoneDiscarded(
                localId, incomingId, completed?.sessionId, explicitlyDiscardedId)) {
            localId?.let { rememberDiscarded(it) }
            runCatching { pendingFinish.clear() }
            finishedSummary = null
            clearSession(erasePending = true)
            sendStatus = "Sesión cerrada desde el teléfono"
            return
        }
        completed?.let {runCatching {pendingFinish.acknowledge(it.sessionId)}}
        // ¡Bien hecho! solo si el finished es la sesión que corríamos (F-5 / w-01).
        val showFinished = completed?.takeIf {
            it.sessionId != sessionCache.getString("finishedDismissed", null) &&
                (localId == null || localId == it.sessionId)
        }
        finishedSummary = showFinished
        if (bytes == null || bytes.isEmpty()) {
            // The phone's last-known empty state is not a cancellation. Keep
            // a valid local session and its outbox until an ID-matched finish or
            // explicit discard arrives; Data Layer updates can be delayed.
            if (localId != null && completed?.sessionId != localId &&
                explicitlyDiscardedId != localId) {
                syncProblem = true
                sendStatus = "Sesión local conservada; esperando sincronización"
                return
            }
            localId?.let { rememberDiscarded(it) }
            // Terminado con resumen: conserva cola si coincide; si no, limpia.
            val erase = showFinished == null
            clearSession(erasePending = erase)
            return
        }
        val raw = String(bytes, Charsets.UTF_8)
        val parsed = runCatching { WatchSessionSummary.fromJson(JSONObject(raw)) }
        val summary = parsed.getOrNull()
        if (summary != null) {
            val previousSessionId=visibleSession?.sessionId
            val changedSession=wearSessionChanged(previousSessionId,summary.sessionId)
            if(changedSession) {
                sensorRevision++
                // Paused/rest state belongs to the old workout, never the new identity.
                sessionPaused=false
                skipRest()
                health=null
                sessionCache.edit().remove("restState").apply()
            }
            // Persist only a validated session; a malformed update cannot corrupt recovery.
            sessionCache.edit().putString("snapshot", raw).apply()
            if (watchStartedSession) {
                // El teléfono ya adoptó la sesión iniciada en el reloj.
                watchStartedSession = false
                sessionCache.edit().remove("watchStarted").apply()
            }
            // Borrador prellenado con la prescripción, como el setDraft de watchOS.
            if (visibleSession?.sessionId != summary.sessionId ||
                visibleSession?.exerciseIndex != summary.exerciseIndex ||
                visibleSession?.recordedTotalSets != summary.recordedTotalSets) {
                if(!wearTimerMatches(phoneWodTimerJson,summary.sessionId,summary.exerciseIndex)) {
                    phoneWodTimerJson=null
                }
                if(!wearTimerMatches(localWodTimerJson,summary.sessionId,summary.exerciseIndex)) {
                    localWodTimerJson=null
                }
                refreshWodTickFromEffective()
                repCounter.reset();seedDraft(summary)
                sessionCache.edit().remove("inputDraft").apply()
            }
            visibleSession = summary
            resendPending()
            showingCachedSession = false
            syncProblem = false
            ensureHealthRecording()
        } else {
            syncProblem = true
            // Keep the last valid summary but never claim the corrupted update succeeded.
        }
    }

    /** Terminal events are the only way to discard an unadopted watch-owned session.
     * A plain Data Layer snapshot with no active workout must never erase it.
     */
    private fun receivePhoneTerminal(sessionId: String?, saved: Boolean) {
        if (sessionId.isNullOrBlank() || visibleSession?.sessionId != sessionId) return
        if (saved && runCatching {
                pendingStore.all().any { it.optString("sessionId") == sessionId }
            }.getOrDefault(true)) {
            sendStatus = "El teléfono terminó; hay series sin confirmar. Se conservan en el reloj."
            syncProblem = true
            resendPending()
            return
        }
        rememberDiscarded(sessionId)
        // Saving and discarding are distinct: never erase an unsent saved set.
        clearSession(erasePending = !saved)
        sendStatus = if (saved) "Entrenamiento terminado desde el teléfono"
            else "Entrenamiento descartado desde el teléfono"
    }

    private fun clearSession(erasePending: Boolean) {
        sensorRevision++
        val sensorSessionId=visibleSession?.sessionId
        warmupInput=false;failureInput=false;rirInput=null
        setKindInput="straight";dropsInput=emptyList();clustersInput=emptyList()
        sessionPaused = false
        showOutline=false;showSetDetails=false;reviewingBlock=false
        resetElapsedClock()
        wodTickJob?.cancel();phoneWodTimerJson=null;localWodTimerJson=null;wodTickSeconds=0
        watchStartedSession = false
        sessionCache.edit().remove("watchStarted").apply()
        sessionCache.edit().remove("snapshot").remove("inputDraft").remove("restState").apply()
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
        healthConnection?.stop(sensorSessionId)
        health = null
    }

    private fun startHealthForCurrentSession() {
        val id=visibleSession?.sessionId ?: return
        if(!lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.STARTED)) {
            sendStatus="Abre Repera para iniciar o recuperar sensores";return
        }
        runCatching {WearHealthService.startFromVisibleUI(this,id)}
            .onFailure {sendStatus=it.localizedMessage ?: "No se pudo iniciar el registro de sensores"}
    }

    private fun ensureHealthRecording() {
        health=null
        val permissions=WearHealthPermissions.requested(android.os.Build.VERSION.SDK_INT)
        val granted=permissions.all {permission ->androidx.core.content.ContextCompat.checkSelfPermission(this,permission)==android.content.pm.PackageManager.PERMISSION_GRANTED}
        if (granted) {
            startHealthForCurrentSession()
        } else {
            val id=visibleSession?.sessionId ?: return
            if(pendingSensorPermission.begin(id,sensorRevision)) sensorPermissions.launch(permissions)
        }
    }
}

private fun localizedExerciseName(exercise: JSONObject): String {
    val base = exercise.optString("name").ifBlank { return "Ejercicio" }
    val tag = exercise.optString("sportTag").takeIf { it.isNotBlank() }
    return dev.repera.domain.SportExerciseNames.localizedSpanishName(base, tag)
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
    /** Apple 44713457: formato WOD con captura de series por movimiento. */
    val wodUsesSeries: Boolean = false,
    val globalScore: Boolean,
    val wodMovements: List<String>,
    val plannedWorkSets: Int = 0,
    val restSeconds: Int = 0,
    val inputMode: String = "strength",
    val quantityUnit:String="reps",val allowsUnitToggle:Boolean=false,
    val prescribedDurationSeconds:Int?=null,val prescribedRir:Double?=null,val mobilityHold:Boolean=false,
    val prescribedDeficitCm:Int?=null,
    val recordedTotalSets:Int=recordedSets,
    /** (exercise index 0-based, first exercise name) per block run; Apple blockStarts. */
    val blocks:List<Pair<Int,String>> = emptyList(),
    val phase: String = "counting",
    val blockHeader: String = "",
    val blockTimeCapMinutes: Int? = null,
    val wodFormatWire: String? = null,
    val blockId: String? = null,
    val blockExerciseLines: List<String> = emptyList()
) {
    companion object {
        /** (first exercise index, Apple displayBlockHeader) per consecutive block run. */
        fun blocksOf(exercises: JSONArray): List<Pair<Int, String>> =
            dev.repera.domain.WearBlockStarts.of((0 until exercises.length()).map {
                exercises.getJSONObject(it).optString("blockId").takeIf { id -> id.isNotBlank() }
            }).map { start ->
                val e = exercises.getJSONObject(start)
                fun int(k: String) = if (e.has(k) && !e.isNull(k)) e.optInt(k) else null
                start to dev.repera.domain.WearBlockHeader.display(
                    e.optString("blockKind") == "strength", dev.repera.domain.WodFormat.fromWire(e.optString("wodFormat")),
                    if (e.has("blockHeader") && !e.isNull("blockHeader")) e.optString("blockHeader") else null,
                    int("blockTimeCapMinutes"), int("blockRounds"), int("blockIntervalSeconds"),
                    int("blockWorkSeconds"), int("blockRestSeconds"))
            }
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
            val wodUsesSeries = exercise.optString("blockKind") == "wod" &&
                wodFormat?.capture == dev.repera.domain.ResultCapture.PER_MOVEMENT_SETS
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
            fun intField(k: String) = if (exercise.has(k) && !exercise.isNull(k)) exercise.optInt(k) else null
            val header = WearBlockHeader.display(
                exercise.optString("blockKind") == "strength", wodFormat,
                if (exercise.has("blockHeader") && !exercise.isNull("blockHeader"))
                    exercise.optString("blockHeader") else null,
                intField("blockTimeCapMinutes"), intField("blockRounds"),
                intField("blockIntervalSeconds"), intField("blockWorkSeconds"),
                intField("blockRestSeconds")
            )
            val members = (0 until exercises.length()).filter { i ->
                val id = exercises.getJSONObject(i).optString("blockId")
                if (blockId.isBlank()) i == index else id == blockId
            }
            val blockLines = members.map { i ->
                val e = exercises.getJSONObject(i)
                val name = localizedExerciseName(e.getJSONObject("exercise"))
                val ps = e.optJSONArray("plannedSets")
                val reps = ps?.takeIf { it.length() > 0 }?.optJSONObject(0)?.optInt("targetReps")
                if (reps != null && reps > 0) "$name · $reps reps" else name
            }
            return WatchSessionSummary(
                sessionId = session.getString("id"),
                title = session.getString("title"),
                canLogOnWatch = mode in setOf(
                    ExerciseInputMode.LOAD_REPS, ExerciseInputMode.REPS_ONLY,
                    ExerciseInputMode.REPS_AND_TIME, ExerciseInputMode.MACHINE_WORK,
                    ExerciseInputMode.HSPU_DEFICIT,ExerciseInputMode.LOAD_DISTANCE) &&
                    (exercise.optString("blockKind") != "wod" || wodUsesSeries),
                allowsWeight = mode.showsWeight,
                exerciseName = localizedExerciseName(exercise.getJSONObject("exercise")),
                exerciseIndex = index + 1,
                exerciseCount = exercises.length(),
                recordedSets = done,
                recordedTotalSets = recorded.length(),
                prescribedReps = if (globalScore) null else target?.takeIf {
                    it.has("targetReps") && !it.isNull("targetReps")
                }?.optInt("targetReps"),
                prescribedWeightKg = if (globalScore || !mode.showsWeight) null else target?.takeIf {
                    it.has("targetWeightKg") && !it.isNull("targetWeightKg")
                }?.getDouble("targetWeightKg"),
                wodUsesSeries = wodUsesSeries,
                wodFormatLabel = wodFormat?.displayName,
                globalScore = globalScore,
                wodMovements = movementLines,
                plannedWorkSets = plan?.length() ?: 0,
                restSeconds = exercise.optInt("restSeconds",
                    exercise.optInt("blockRestSeconds", 0)),
                quantityUnit=exercise.optString("quantityUnit").takeIf {it in setOf("reps","calories","meters")} ?: ExerciseInput.defaultQuantityUnit(sourceExercise.getString("name"),sourceExercise.optString("equipment")),
                allowsUnitToggle=ExerciseInput.supportsCaloriesAndMeters(sourceExercise.getString("name"),sourceExercise.optString("equipment")),
                prescribedDeficitCm=if(mode == ExerciseInputMode.HSPU_DEFICIT) target?.takeIf {
                    it.has("targetWeightKg") && !it.isNull("targetWeightKg")
                }?.optDouble("targetWeightKg")?.takeIf {it.isFinite()}?.let {
                    kotlin.math.floor(it+0.5).toInt().coerceIn(0,60)
                } else null,
                prescribedDurationSeconds=target?.takeIf {it.has("targetDurationSeconds") && !it.isNull("targetDurationSeconds")}?.optInt("targetDurationSeconds"),
                prescribedRir=target?.takeIf {it.has("targetRir") && !it.isNull("targetRir")}?.optDouble("targetRir"),
                mobilityHold=sourceExercise.optString("sportTag")=="Movilidad" && sourceExercise.optString("catalogId") in setOf("mobility-14","mobility-15","mobility-16","mobility-20","mobility-21","mobility-30","mobility-31","mobility-32","mobility-36","mobility-38","mobility-39","mobility-40","mobility-41","mobility-42","mobility-44","mobility-46","mobility-60","mobility-61","mobility-62","mobility-67","mobility-70","mobility-80"),
                blocks = blocksOf(exercises),
                inputMode = when (mode) {
                    ExerciseInputMode.MACHINE_WORK -> "machineWork"
                    ExerciseInputMode.REPS_AND_TIME -> "repsAndTime"
                    ExerciseInputMode.HSPU_DEFICIT -> "hspuDeficit"
                    ExerciseInputMode.REPS_ONLY -> "repsOnly"
                    ExerciseInputMode.LOAD_DISTANCE -> "loadDistance"
                    else -> "strength"
                },
                phase = session.optString("phase", "counting").ifBlank { "counting" },
                blockHeader = header,
                blockTimeCapMinutes = intField("blockTimeCapMinutes"),
                wodFormatWire = wodFormat?.wireName,
                blockId = blockId.takeIf { it.isNotBlank() },
                blockExerciseLines = blockLines
            )
        }
    }
}

internal data class FinishedSummary(
    val sessionId: String,
    val title: String,
    val durationLabel: String,
    val exercises: Int,
    val sets: Int,
    val reps: Int,
    val volumeKg: Int,
    val kcal: Int? = null,
    val avgHr: Int? = null,
    val wodLines: List<Pair<String, String>> = emptyList(),
    val isLive: Boolean = false,
    val distanceLabel: String? = null
) {
    companion object {
        fun fromBytes(bytes: ByteArray?): FinishedSummary? {
            if (bytes == null || bytes.isEmpty()) return null
            val w = runCatching {
                JSONObject(String(bytes, Charsets.UTF_8))
            }.getOrNull() ?: return null
            val id = w.optString("id").takeIf { it.isNotBlank() } ?: return null
            val measured = sequenceOf(
                "appleDurationSeconds", "activeDurationSeconds", "durationSeconds"
            ).mapNotNull { key ->
                if (w.has(key) && !w.isNull(key)) w.optDouble(key).takeIf { it.isFinite() } else null
            }.firstOrNull()
            val seconds = dev.repera.domain.WearSessionDuration.resolveSeconds(
                w.optString("startedAt").ifBlank { null },
                w.optString("finishedAt").ifBlank { null },
                measured
            )
            val exercises = w.optJSONArray("exercises")
            var sets = 0
            var reps = 0
            var volume = 0.0
            if (exercises != null) {
                for (i in 0 until exercises.length()) {
                    val logged = exercises.optJSONObject(i)?.optJSONArray("loggedSets") ?: continue
                    sets += logged.length()
                    for (s in 0 until logged.length()) {
                        val set = logged.optJSONObject(s) ?: continue
                        val r = set.optInt("reps", set.optInt("quantity", 0))
                        reps += r
                        val kg = set.optDouble("weightKg", Double.NaN)
                        if (kg.isFinite() && kg > 0) volume += kg * r
                    }
                }
            }
            val kcal = sequenceOf("appleActiveEnergyKcal", "activeEnergyKcal")
                .mapNotNull { k ->
                    if (w.has(k) && !w.isNull(k)) w.optDouble(k).takeIf { it.isFinite() && it > 0 }
                    else null
                }.firstOrNull()?.let { kotlin.math.round(it).toInt() }
            val avgHr = sequenceOf("appleAverageHeartRateBpm", "averageHeartRateBpm")
                .mapNotNull { k ->
                    if (w.has(k) && !w.isNull(k)) w.optDouble(k).takeIf { it.isFinite() && it > 0 }
                    else null
                }.firstOrNull()?.let { kotlin.math.round(it).toInt() }
            val wodLines = mutableListOf<Pair<String, String>>()
            val results = w.optJSONArray("wodResults")
            if (results != null) {
                for (i in 0 until results.length()) {
                    val r = results.optJSONObject(i) ?: continue
                    val fmt = WodFormat.fromWire(r.optString("format"))?.displayName ?: "WOD"
                    val value = when {
                        r.has("elapsedSeconds") && !r.isNull("elapsedSeconds") ->
                            wearClockLabel(r.optInt("elapsedSeconds"))
                        r.has("roundsCompleted") ->
                            "${r.optInt("roundsCompleted")} r + ${r.optInt("totalReps")} reps"
                        r.has("totalReps") -> "${r.optInt("totalReps")} reps"
                        else -> "—"
                    }
                    wodLines += fmt to value
                }
            }
            val isLive = w.optString("liveSportID").isNotBlank() ||
                (w.optJSONObject("timerDetails") != null)
            val meters = if (w.has("recordedDistanceMeters") && !w.isNull("recordedDistanceMeters")) {
                w.optDouble("recordedDistanceMeters").takeIf { it.isFinite() && it > 0 }
            } else null
            val distanceLabel = meters?.let { String.format("%.2f km", it / 1000.0) }
            return FinishedSummary(
                id,
                w.optString("title").ifBlank { "Entrenamiento" },
                dev.repera.domain.WearSessionDuration.format(seconds),
                exercises?.length() ?: 0,
                sets,
                reps,
                kotlin.math.round(volume).toInt(),
                kcal,
                avgHr,
                wodLines,
                isLive,
                distanceLabel
            )
        }
    }
}