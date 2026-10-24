package dev.repera.mobile

import android.accounts.Account
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.IntentSenderRequest
import android.net.Uri
import dev.repera.domain.ExerciseInput
import dev.repera.domain.WodFormat
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.lifecycle.lifecycleScope
import androidx.health.connect.client.PermissionController
import com.google.android.gms.auth.api.identity.AuthorizationRequest
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.common.api.Scope
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.foundation.layout.Box
import dev.repera.mobile.monetization.FreeUsageStore
import dev.repera.mobile.monetization.LocalSubscriptions
import dev.repera.mobile.monetization.PaywallMode
import dev.repera.mobile.monetization.PaywallScreen
import dev.repera.mobile.monetization.SubscriptionManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.security.SecureRandom

/**
 * Native Google identity, separate consent for private appDataFolder.
 * The Google ID token is never accepted as Supabase authorization: backend token
 * verification and Google provider setup must be completed before business login.
 */
class MainActivity : ComponentActivity(), MessageClient.OnMessageReceivedListener {
    private companion object {
        const val SESSION_REFRESH_MARGIN_SECONDS = 60L
    }
    private val wearMessages by lazy { Wearable.getMessageClient(this) }
    private data class GoogleProfile(
        val uniqueId: String, val email: String, val displayName: String
    )

    private var profile by mutableStateOf<GoogleProfile?>(null)
    private var busy by mutableStateOf(false)
    private var syncing by mutableStateOf(false)
    private var status by mutableStateOf<String?>(null)
    private var snapshot by mutableStateOf<StateOverview?>(null)
    private var activeWorkout by mutableStateOf<ActiveWorkout?>(null)
    private var pendingReview by mutableStateOf<dev.repera.domain.SessionReview?>(null)
    private var wodTimer by mutableStateOf<WodTimerState?>(null)
    private var todayHealth by mutableStateOf<TodayHealth?>(null)
    private var healthSamples by mutableStateOf<HealthSamples?>(null)
    private var recoveryRead by mutableStateOf<RecoveryRead?>(null)
    private val credentialManager by lazy { CredentialManager.create(this) }
    private var verifiedSupabase: SupabaseIdentity.Session? = null
    private var centerSnapshot by mutableStateOf<BusinessCenterStore.Snapshot?>(null)
    private var centerLoading by mutableStateOf(false)
    private var centerSubmitting by mutableStateOf(false)
    private var centerError by mutableStateOf<String?>(null)
    private val sessionStore by lazy { SessionStore(this) }
    /** Wizard obligatorio de primer acceso (port OnboardingStore iOS). */
    private val onboarding by lazy { OnboardingStore.create(this) }
    /** Pin de gym + ruta GPS outdoor (port WorkoutLocationTracker iOS). */
    private val locationTracker by lazy { WorkoutLocationTracker(this) }
    /** Petición de ubicación al dar Play (ensureWhenInUseAuthorized iOS). */
    private val requestLocationPermissions = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { grants ->
        if (grants.values.any { it }) beginLocationCapture()
    }
    /** Estado comercial (Pro/Gratis) + cuotas + paywall. Port del entorno iOS. */
    private val subscriptions by lazy {
        SubscriptionManager(
            freeUsage = FreeUsageStore.forAccount(java.io.File(filesDir, "monetization"))
        )
    }
    /** Espejo Supabase de entrenos terminados (port BusinessWorkoutSyncStore). */
    private fun syncWorkoutMirror() {
        val session = verifiedSupabase ?: return
        val uniqueId = profile?.uniqueId ?: return
        lifecycleScope.launch {
            // El espejo nunca bloquea la app: un fallo se reintenta en el
            // siguiente arranque/refresco y no se muestra en la UI.
            withContext(Dispatchers.IO) {
                WorkoutMirrorStore(this@MainActivity, session.userId)
                    .sync(session, WorkoutRepository(this@MainActivity, uniqueId))
            }
        }
    }

    /** Espejo del calendario de planificación para la IA (contexto). */
    private fun syncAITrainingContext() {
        val session = verifiedSupabase ?: return
        val uniqueId = profile?.uniqueId ?: return
        lifecycleScope.launch {
            withContext(Dispatchers.IO) {
                AITrainingContextStore(this@MainActivity, session.userId)
                    .sync(session, WorkoutRepository(this@MainActivity, uniqueId))
            }
        }
    }

    /** Espejo IA + bandeja: tras establecer sesión o refrescar. */
    private fun syncSupabaseMirrors() {
        syncAITrainingInbox()
        syncWorkoutMirror()
        syncAITrainingContext()
        refreshSharing()
        refreshAIPrograms()
    }

    // ---- Programas IA (port AITrainingProgramsView) ----
    private var aiPrograms by mutableStateOf<List<AITrainingProgramsStore.Program>?>(
        null)
    private var aiProgramsLoading by mutableStateOf(false)
    private var aiProgramsUpdatingId by mutableStateOf<String?>(null)
    private var aiProgramsError by mutableStateOf<String?>(null)

    private fun refreshAIPrograms() {
        val session = verifiedSupabase ?: return
        if (aiProgramsLoading) return
        aiProgramsLoading = true
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                AITrainingProgramsStore().refresh(session)
            }
            when (result) {
                is AITrainingProgramsStore.LoadResult.Loaded -> {
                    aiPrograms = result.programs; aiProgramsError = null
                }
                is AITrainingProgramsStore.LoadResult.Failed ->
                    aiProgramsError = result.message
            }
            aiProgramsLoading = false
        }
    }

    private fun changeAIProgramStatus(program: AITrainingProgramsStore.Program,
                                      status: String) {
        val session = verifiedSupabase ?: return
        if (aiProgramsUpdatingId != null) return
        aiProgramsUpdatingId = program.id
        lifecycleScope.launch {
            val failure = withContext(Dispatchers.IO) {
                AITrainingProgramsStore().changeStatus(session, program, status)
            }
            if (failure != null) aiProgramsError = failure
            aiProgramsUpdatingId = null
            refreshAIPrograms()
        }
    }

    // ---- Compartir resultados por centro (athlete_workout_sharing) ----
    private var sharingByCenter by mutableStateOf<Map<String, Boolean>>(
        emptyMap())
    private var sharingUpdating by mutableStateOf(false)

    private fun refreshSharing() {
        val session = verifiedSupabase ?: return
        lifecycleScope.launch {
            val map = withContext(Dispatchers.IO) {
                runCatching {
                    WorkoutMirrorStore(this@MainActivity, session.userId)
                        .refreshSharing(session)
                }.getOrNull()
            }
            if (map != null) sharingByCenter = map
        }
    }

    private fun setSharing(orgId: String, enabled: Boolean) {
        val session = verifiedSupabase ?: return
        if (sharingUpdating) return
        sharingUpdating = true
        val linked = centerSnapshot?.athleteCenterIds ?: emptySet()
        lifecycleScope.launch {
            val failure = withContext(Dispatchers.IO) {
                WorkoutMirrorStore(this@MainActivity, session.userId)
                    .setSharing(session, orgId, enabled, linked)
            }
            if (failure == null) {
                sharingByCenter = sharingByCenter + (orgId to enabled)
            } else {
                centerError = failure
            }
            sharingUpdating = false
        }
    }

    // ---- Acceso IA (port AIAccessView): tokens + cambios + bandeja ----
    private var aiTokens by mutableStateOf<List<AIAccessStore.TokenInfo>?>(null)
    private var aiBusy by mutableStateOf(false)
    private var aiError by mutableStateOf<String?>(null)
    private var aiSuccess by mutableStateOf<String?>(null)
    private var aiCreatedToken by mutableStateOf<String?>(null)
    private var aiChanges by mutableStateOf<List<AIChangeRequestStore.Change>>(
        emptyList())
    private var aiChangeBusy by mutableStateOf(false)
    private var aiChangeError by mutableStateOf<String?>(null)
    private var aiInboxPending by mutableStateOf(0)
    private var aiInboxConflicts by mutableStateOf<List<String>>(emptyList())

    private fun clearAIAccessState() {
        aiPrograms = null; aiProgramsLoading = false
        aiProgramsUpdatingId = null; aiProgramsError = null
        sharingByCenter = emptyMap(); sharingUpdating = false
        aiTokens = null; aiBusy = false; aiError = null; aiSuccess = null
        aiCreatedToken = null; aiChanges = emptyList(); aiChangeBusy = false
        aiChangeError = null; aiInboxPending = 0; aiInboxConflicts = emptyList()
    }

    private fun refreshAIAccess() {
        val session = verifiedSupabase ?: return
        val uniqueId = profile?.uniqueId ?: return
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                val repository = WorkoutRepository(this@MainActivity, uniqueId)
                val store = AIChangeRequestStore(this@MainActivity, session.userId)
                store.syncCustomExercises(session, repository)
                AIAccessStore().refresh(session) to store.refresh(session)
            }
            when (val tokens = result.first) {
                is AIAccessStore.LoadResult.Loaded -> {
                    aiTokens = tokens.tokens; aiError = null
                }
                is AIAccessStore.LoadResult.Failed -> aiError = tokens.message
            }
            when (val changes = result.second) {
                is AIChangeRequestStore.RefreshResult.Loaded ->
                    aiChanges = changes.pending
                is AIChangeRequestStore.RefreshResult.Failed ->
                    aiChangeError = changes.message
            }
        }
    }

    private fun createAIToken(label: String, expiry: String, canWrite: Boolean) {
        val session = verifiedSupabase ?: return
        if (aiBusy) return
        aiBusy = true; aiError = null; aiSuccess = null
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                AIAccessStore().create(session, label, expiry, canWrite)
            }
            when (result) {
                is AIAccessStore.CreateResult.Created -> {
                    // El plano solo vive en este estado hasta cerrar el diálogo.
                    aiCreatedToken = result.token
                    refreshAIAccess()
                }
                is AIAccessStore.CreateResult.Failed -> aiError = result.message
            }
            aiBusy = false
        }
    }

    private fun revokeAIToken(tokenId: String) {
        val session = verifiedSupabase ?: return
        if (aiBusy) return
        aiBusy = true; aiError = null; aiSuccess = null
        lifecycleScope.launch {
            val failure = withContext(Dispatchers.IO) {
                AIAccessStore().revoke(session, tokenId)
            }
            if (failure == null) {
                aiSuccess = "Token revocado. Ya no permite acceder a Repera."
                refreshAIAccess()
            } else aiError = failure
            aiBusy = false
        }
    }

    private fun decideAIChange(change: AIChangeRequestStore.Change,
                               approve: Boolean) {
        val session = verifiedSupabase ?: return
        val uniqueId = profile?.uniqueId ?: return
        if (aiChangeBusy) return
        aiChangeBusy = true; aiChangeError = null
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                AIChangeRequestStore(this@MainActivity, session.userId).decide(
                    session, change, approve,
                    WorkoutRepository(this@MainActivity, uniqueId),
                    WorkoutMirrorStore(this@MainActivity, session.userId))
            }
            when (result) {
                is AIChangeRequestStore.DecideResult.Applied -> {
                    aiSuccess = "Cambio aplicado."
                    reloadFor(uniqueId)
                }
                is AIChangeRequestStore.DecideResult.Rejected ->
                    aiSuccess = "Solicitud rechazada."
                is AIChangeRequestStore.DecideResult.Failed ->
                    aiChangeError = result.message
            }
            aiChangeBusy = false
            refreshAIAccess()
        }
    }

    private fun copyCreatedAIToken() {
        val token = aiCreatedToken ?: return
        val clip = android.content.ClipData.newPlainText("Token de acceso IA",
            token)
        // Marca sensible: la vista previa del portapapeles no lo muestra.
        if (android.os.Build.VERSION.SDK_INT >= 33) {
            clip.description.extras = android.os.PersistableBundle().apply {
                putBoolean(android.content.ClipDescription.EXTRA_IS_SENSITIVE,
                    true)
            }
        }
        (getSystemService(CLIPBOARD_SERVICE) as android.content.ClipboardManager)
            .setPrimaryClip(clip)
        aiSuccess = "Token copiado al portapapeles."
    }

    /** Realtime de planes IA: vivo solo en foreground, resync al suscribirse. */
    private val aiPlansRealtime by lazy {
        AIPlansRealtimeListener(
            sessionProvider = { verifiedSupabase },
            onPlansChanged = {
                runOnUiThread {
                    if (verifiedSupabase != null && profile != null) syncAITrainingInbox()
                }
            })
    }

    private val requestHealthPermissions = registerForActivityResult(
        PermissionController.createRequestPermissionResultContract()
    ) { granted ->
        if (granted.containsAll(HealthConnectReader.permissions)) {
            loadHealthToday()
        } else {
            todayHealth = null
            status = "No se ha autorizado la lectura de Salud"
        }
    }

    private val driveConsent = registerForActivityResult(
        ActivityResultContracts.StartIntentSenderForResult()
    ) { result ->
        val resultIntent = result.data
        if (result.resultCode == RESULT_OK && resultIntent != null) {
            runCatching {
                Identity.getAuthorizationClient(this)
                    .getAuthorizationResultFromIntent(resultIntent)
                    .accessToken
            }.onSuccess { token ->
                if (!token.isNullOrBlank()) syncWithDrive(token)
                else { status = "No se recibió acceso a Drive"; busy = false; syncing = false }
            }.onFailure {
                status = "No se pudo autorizar Drive: " + it.localizedMessage
                busy = false
                syncing = false
            }
        } else {
            status = "Acceso a Drive cancelado"
            busy = false
            syncing = false
        }
    }

    private val importCsv = registerForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri: Uri? ->
        if (uri == null) return@registerForActivityResult
        val signedIn = profile ?: return@registerForActivityResult
        busy = true
        lifecycleScope.launch {
            try {
                val summary = withContext(Dispatchers.IO) {
                    val bytes = contentResolver.openInputStream(uri)?.use { input ->
                        input.readBytes()
                    } ?: error("No se pudo abrir el archivo")
                    // iOS acepta UTF-8 con repliegue a ISO-Latin-1.
                    val text = runCatching {
                        String(bytes, Charsets.UTF_8)
                    }.getOrElse { String(bytes, Charsets.ISO_8859_1) }
                    WorkoutRepository(this@MainActivity, signedIn.uniqueId)
                        .importCSV(text)
                }
                reloadFor(signedIn.uniqueId)
                status = "CSV importado: " + summary.label
            } catch (error: Exception) {
                status = "Importación CSV no realizada: " + error.localizedMessage
            } finally {
                busy = false
            }
        }
    }

    private val importJson = registerForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri: Uri? ->
        if (uri == null) return@registerForActivityResult
        val signedIn = profile ?: return@registerForActivityResult
        busy = true
        lifecycleScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    val store = LocalSnapshotStore(this@MainActivity, signedIn.uniqueId)
                    check(store.read() == null) {
                        "Importación bloqueada: ya hay datos locales. Exporta una copia antes de reemplazarlos."
                    }
                    val bytes = contentResolver.openInputStream(uri)?.use { input ->
                        input.readBytes()
                    } ?: error("No se pudo abrir el archivo")
                    // El JSON exportado por Apple cumple este contrato
                    // (workouts/routines/exercises + syncRevision); validar
                    // antes de reemplazar el estado vacío.
                    LocalSnapshotStore.validate(bytes)
                    store.write(bytes)
                }
                reloadFor(signedIn.uniqueId)
                status = "Datos de Repera importados. Ya puedes sincronizarlos con Drive."
            } catch (error: Exception) {
                status = "Importación no realizada: " + error.localizedMessage
            } finally {
                busy = false
            }
        }
    }

    private val exportJson = registerForActivityResult(
        ActivityResultContracts.CreateDocument("application/json")
    ) { uri: Uri? ->
        if (uri == null) return@registerForActivityResult
        val signedIn = profile ?: return@registerForActivityResult
        busy = true
        lifecycleScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    val bytes = LocalSnapshotStore(this@MainActivity, signedIn.uniqueId).read()
                        ?: error("No hay entrenamientos para exportar")
                    LocalSnapshotStore.validate(bytes)
                    contentResolver.openOutputStream(uri, "w")?.use { out ->
                        out.write(bytes)
                        out.flush()
                    } ?: error("No se pudo abrir el documento")
                }
                status = "Copia de Repera exportada correctamente"
            } catch (error: Exception) {
                status = "No se pudo exportar: " + (error.localizedMessage ?: "error de archivo")
            } finally {
                busy = false
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        restoreStoredSession()
        lifecycleScope.launch { subscriptions.start() }
        setContent {
            CompositionLocalProvider(LocalSubscriptions provides subscriptions) {
            if (profile == null || !onboarding.isComplete) {
                OnboardingFlow(
                    store = onboarding,
                    subscriptions = subscriptions,
                    isSignedIn = profile != null,
                    signInBusy = busy,
                    signInError = status,
                    onGoogleSignIn = ::signInWithGoogle
                )
            } else {
            ReperaMobileScreen(
                isAuthenticated = profile != null,
                displayName = profile?.displayName,
                busy = busy,
                syncing = syncing,
                status = status,
                overview = snapshot,
                exerciseSeries = { exerciseId, metric, range ->
                    val uid = profile?.uniqueId
                    val bytes = uid?.let { LocalSnapshotStore(this, it).read() }
                    if (bytes == null) emptyList() else ExerciseProgressSeries.compute(
                        org.json.JSONObject(String(bytes, Charsets.UTF_8))
                            .optJSONArray("workouts") ?: org.json.JSONArray(),
                        exerciseId, metric, range)
                },
                sessionAppearances = { exerciseId, highlightSessionId, instanceId ->
                    val uid = profile?.uniqueId
                    val bytes = uid?.let { LocalSnapshotStore(this, it).read() }
                    if (bytes == null) {
                        null to null
                    } else {
                        val root = org.json.JSONObject(String(bytes, Charsets.UTF_8))
                        val workouts = root.optJSONArray("workouts")
                            ?: org.json.JSONArray()
                        val catalog = root.optJSONArray("exercises")
                        val all = (0 until workouts.length())
                            .map { workouts.getJSONObject(it) }
                        val highlight = all.firstOrNull {
                            it.optString("id") == highlightSessionId
                        }
                        // Scoping por instancia (iOS highlightExerciseInstanceId):
                        // sin él, dos bloques con el mismo ejercicio mezclarían
                        // series y scores en «Esta sesión».
                        val scoped = highlight?.let { session ->
                            if (instanceId.isNullOrBlank()) session
                            else ExerciseSessionAppearances.scopedForInstance(
                                session, instanceId)
                        }
                        val thisAppearance = scoped?.let {
                            ExerciseSessionAppearances.appearance(exerciseId, it, catalog)
                        }
                        val prior = ExerciseSessionAppearances.priorAppearances(
                            exerciseId, all, catalog,
                            excludingSessionId = highlightSessionId, limit = 1
                        ).firstOrNull()
                        thisAppearance to prior
                    }
                },
                loadGuideProvider = { exerciseId, targetReps, targetRir ->
                    val uid = profile?.uniqueId
                    val bytes = uid?.let { LocalSnapshotStore(this, it).read() }
                    if (bytes == null) null else ExerciseLoadGuide.guide(
                        org.json.JSONObject(String(bytes, Charsets.UTF_8)),
                        exerciseId, targetReps, targetRir)
                },
                todayHealth = todayHealth,
                onHealthConnect = ::connectHealth,
                activeWorkout = activeWorkout,
                wodTimer = wodTimer,
                onWodTimerAction = ::changeWodTimer,
                onWodTimerTick = ::refreshWodTimer,
                onStartRoutine = { id ->
                    runWorkoutAction(onSuccess = { beginLocationCapture() }) { startRoutine(id) }
                },
                onEditRoutine = { id, title, schedule ->
                    runWorkoutAction { updateRoutineDetails(id, title, schedule) }
                },
                onDeleteRoutine = { id -> runWorkoutAction { deleteRoutine(id) } },
                onReplaceRoutineBlocks = { id, drafts ->
                    runWorkoutAction { replaceRoutineBlocks(id, drafts) }
                },
                onCreateRoutine = { title, format, entries, minutes, rounds, schedule, interval, work, rest, ladder ->
                    runWorkoutAction { createRoutine(title, format, entries, minutes, rounds,
                        schedule, interval, work, rest, ladder) }
                },
                onCreateRoutineFromScan = { title, blocks ->
                    runWorkoutAction { createRoutineFromScan(title, blocks) }
                },
                onSaveOneOffRoutine = { title, drafts, dayIso ->
                    runWorkoutAction {
                        createRoutineFromDrafts(title, drafts,
                            RoutineSchedule(scheduledDate = dayIso))
                    }
                },
                centerConnected = verifiedSupabase != null,
                centerLoading = centerLoading,
                centerSubmitting = centerSubmitting,
                centerError = centerError,
                centerSnapshot = centerSnapshot,
                onCenterRefresh = {
                    refreshCenter()
                    syncSupabaseMirrors()
                },
                onCenterAccept = { invitation ->
                    centerAction { s -> accept(s, invitation) }
                },
                onCenterBook = { occurrence, pass ->
                    centerAction { s -> book(s, occurrence, pass) }
                },
                onCenterCancel = { booking ->
                    centerAction { s -> cancel(s, booking) }
                },
                sharingByCenter = sharingByCenter,
                sharingUpdating = sharingUpdating,
                onSetSharing = ::setSharing,
                aiPrograms = aiPrograms,
                aiProgramsLoading = aiProgramsLoading,
                aiProgramsUpdatingId = aiProgramsUpdatingId,
                aiProgramsError = aiProgramsError,
                onAIProgramsRefresh = ::refreshAIPrograms,
                onAIProgramStatus = ::changeAIProgramStatus,
                aiConnected = verifiedSupabase != null,
                aiTokens = aiTokens,
                aiBusy = aiBusy,
                aiError = aiError,
                aiSuccess = aiSuccess,
                aiCreatedToken = aiCreatedToken,
                aiChanges = aiChanges,
                aiChangeBusy = aiChangeBusy,
                aiChangeError = aiChangeError,
                aiInboxPending = aiInboxPending,
                aiInboxConflicts = aiInboxConflicts,
                onAIRefresh = ::refreshAIAccess,
                onAICreate = ::createAIToken,
                onAIRevoke = ::revokeAIToken,
                onAIDecide = ::decideAIChange,
                onAIDismissCreated = { aiCreatedToken = null },
                onAICopyCreated = ::copyCreatedAIToken,
                onAddWodTemplate = { templateId ->
                    val template = dev.repera.domain.CatalogWods.template(templateId)
                    if (template != null) runWorkoutAction { createWodRoutine(template) }
                },
                onWodScore = { rounds, reps, seconds ->
                    runWorkoutAction { recordWodScore(rounds, reps, seconds) }
                },
                onWodMovement = { movementIndex, interval, quantity, weight ->
                    runWorkoutAction { recordWodMovement(movementIndex, interval, quantity, weight) }
                },
                onCompleteWodBlock = {
                    runWorkoutAction { completeWodMovementBlock() }
                },
                onReviseWodMovement = { id, quantity, weight ->
                    runWorkoutAction { reviseWodMovementSet(id, quantity, weight) }
                },
                onDeleteWodMovement = { id ->
                    runWorkoutAction { deleteWodMovementSet(id) }
                },
                onQuickLog = { id ->
                    runWorkoutAction(onSuccess = { beginLocationCapture() }) { startQuickLog(id) }
                },
                onInitializeLocal = ::initializeLocalCatalog,
                onLogSet = { quantity, weight, rir, warmup, unit, duration, deficit ->
                    val rest = currentRestInfo()
                    runWorkoutAction(onSuccess = {
                        rest?.let { (name, seconds) ->
                            StrengthRestService.start(this, name, seconds)
                        }
                    }) { logCurrentSet(quantity, weight, rir, warmup,
                        quantityUnit = unit, durationSeconds = duration, deficitCm = deficit) }
                },
                onLogDropSet = { quantity, weight, drops ->
                    val rest = currentRestInfo()
                    runWorkoutAction(onSuccess = {
                        rest?.let { (name, seconds) ->
                            StrengthRestService.start(this, name, seconds)
                        }
                    }) { logDropSet(quantity, weight, drops) }
                },
                onLogRestPauseSet = { clusters, weight ->
                    val rest = currentRestInfo()
                    runWorkoutAction(onSuccess = {
                        rest?.let { (name, seconds) ->
                            StrengthRestService.start(this, name, seconds)
                        }
                    }) { logRestPauseSet(clusters, weight) }
                },
                onReviseSet = { id, quantity, weight, unit, duration, deficit ->
                    runWorkoutAction { reviseCurrentSet(id, quantity, weight, unit, duration, deficit) }
                },
                onDeleteSet = { id -> runWorkoutAction { deleteCurrentSet(id) } },
                onReviseFinishedSet = { workoutId, entryId, setId, quantity, weight, duration ->
                    runWorkoutAction {
                        reviseFinishedSet(workoutId, entryId, setId, quantity, weight, duration)
                    }
                },
                onDeleteFinishedSet = { workoutId, entryId, setId ->
                    runWorkoutAction { deleteFinishedSet(workoutId, entryId, setId) }
                },
                onDeleteWorkout = { workoutId ->
                    runWorkoutAction { deleteWorkout(workoutId) }
                },
                onLogBodyWeight = { kg ->
                    runWorkoutAction { logBodyWeight(kg) }
                },
                onSetRoutineProgression = { id, policy ->
                    runWorkoutAction { setRoutineProgression(id, policy) }
                },
                onSetRoutineFavorite = { id, favorite ->
                    runWorkoutAction { setRoutineFavorite(id, favorite) }
                },
                onSetExerciseFavorite = { id, favorite ->
                    runWorkoutAction { setExerciseFavorite(id, favorite) }
                },
                onNext = { runWorkoutAction { next() } },
                onFinish = {
                    StrengthRestService.cancel(this)
                    val finishedSessionId = activeWorkout?.id
                    val route = locationTracker.stopRouteTracking()
                    runWorkoutAction {
                        finish()
                        if (finishedSessionId != null && route.isNotEmpty()) {
                            attachRoutePoints(finishedSessionId, route)
                        }
                    }
                },
                // endActiveSession(save: false) iOS: borra la sesión en curso
                // sin guardarla y detiene la captura de ubicación.
                onDiscardSession = {
                    StrengthRestService.cancel(this)
                    locationTracker.stopRouteTracking()
                    runWorkoutAction { discardActiveSession() }
                },
                onImportJson = { importJson.launch(arrayOf("application/json", "text/plain", "application/octet-stream")) },
                onImportCsv = { importCsv.launch(arrayOf("text/*", "text/comma-separated-values", "application/octet-stream")) },
                onExportJson = { exportJson.launch("repera-entrenamientos.json") },
                onGoogleSignIn = ::signInWithGoogle,
                onDriveSync = ::authorizeDrive,
                onSignOut = ::signOut
            )
            // Hoja post-entreno (SessionReviewSheet iOS): se presenta una vez
            // al terminar una sesión con valoración verificable.
            pendingReview?.let { review ->
                SessionReviewSheet(review) { pendingReview = null }
            }
            if (subscriptions.paywall.isPresented) {
                @OptIn(ExperimentalMaterial3Api::class)
                ModalBottomSheet(onDismissRequest = { subscriptions.dismissPaywall() }) {
                    PaywallScreen(subscriptions = subscriptions, mode = PaywallMode.SHEET)
                }
            }
            }
            }
        }
    }

    override fun onStart() {
        super.onStart()
        wearMessages.addListener(this)
        if (verifiedSupabase != null && profile != null) aiPlansRealtime.start()
    }

    override fun onStop() {
        aiPlansRealtime.stop()
        wearMessages.removeListener(this)
        super.onStop()
    }

    override fun onMessageReceived(event: MessageEvent) {
        if (event.path == "/repera/session-finish") {
            val sessionId = runCatching {
                JSONObject(String(event.data, Charsets.UTF_8)).optString("sessionId")
            }.getOrNull().orEmpty()
            if (sessionId.isBlank()) return
            runOnUiThread {
                val signedIn = profile
                if (signedIn == null || verifiedSupabase == null || busy) return@runOnUiThread
                lifecycleScope.launch {
                    val finished = withContext(Dispatchers.IO) {
                        runCatching {
                            val repo = WorkoutRepository(this@MainActivity, signedIn.uniqueId)
                            if (repo.active()?.id == sessionId) {
                                StrengthRestService.cancel(this@MainActivity)
                                val route = locationTracker.stopRouteTracking()
                                repo.finish()
                                if (route.isNotEmpty()) repo.attachRoutePoints(sessionId, route)
                                true
                            } else false
                        }.getOrDefault(false)
                    }
                    if (finished) reloadFor(signedIn.uniqueId)
                }
            }
            return
        }
        if (event.path == "/repera/session-pause") {
            val paused = runCatching {
                JSONObject(String(event.data, Charsets.UTF_8)).optBoolean("paused", true)
            }.getOrDefault(true)
            runOnUiThread {
                if (activeWorkout?.wod != null && !busy) {
                    changeWodTimer(if (paused) "pause" else "start")
                    refreshWodTimer()
                }
            }
            return
        }
        if (event.path != "/repera/log-set") return
        val payload = runCatching { JSONObject(String(event.data, Charsets.UTF_8)) }.getOrNull()
            ?: return
        val id = payload.optString("id")
        if (id.isBlank()) return
        runOnUiThread {
            val signedIn = profile
            if (signedIn == null || verifiedSupabase == null) {
                sendWearAck(event.sourceNodeId, id, "retry")
                return@runOnUiThread
            }
            if (busy) {
                sendWearAck(event.sourceNodeId, id, "retry")
                return@runOnUiThread
            }
            val sessionId = payload.optString("sessionId")
            val exerciseIndex = payload.optInt("exerciseIndex", -1)
            val quantity = payload.optInt("quantity", -1)
            val weight = if (payload.has("weightKg") && !payload.isNull("weightKg"))
                payload.optDouble("weightKg", Double.NaN) else null
            val rir = if (payload.has("rir") && !payload.isNull("rir"))
                payload.optDouble("rir", Double.NaN) else null
            val duration = if (payload.has("durationSeconds") &&
                !payload.isNull("durationSeconds"))
                payload.optInt("durationSeconds") else null
            val unit = payload.optString("quantityUnit")
                .takeIf { it in setOf("reps", "calories", "meters") }
            val deficit = if (payload.has("deficitCm") && !payload.isNull("deficitCm"))
                payload.optInt("deficitCm") else null
            val sessionPayload = payload.optJSONObject("session")
            if (sessionId.isBlank() || exerciseIndex < 0 || quantity !in 1..10000 ||
                (weight != null && (!weight.isFinite() || weight < 0)) ||
                (rir != null && (!rir.isFinite() || rir < 0 || rir > 5)) ||
                (duration != null && duration !in 1..86400) ||
                (deficit != null && deficit !in 0..100)) {
                sendWearAck(event.sourceNodeId, id, "rejected")
                return@runOnUiThread
            }
            busy = true
            lifecycleScope.launch {
                val result = runCatching {
                    withContext(Dispatchers.IO) {
                        val wearRest = runCatching {
                            WorkoutRepository(this@MainActivity, signedIn.uniqueId)
                                .restInfoForExercise(exerciseIndex)
                        }.getOrNull()
                        WorkoutRepository(this@MainActivity, signedIn.uniqueId).logWearSet(
                            sessionId, exerciseIndex, id, quantity, weight, rir,
                            durationSeconds = duration, quantityUnit = unit,
                            deficitCm = deficit, sessionPayload = sessionPayload
                        )
                        wearRest?.let { (name, seconds) ->
                            StrengthRestService.start(this@MainActivity, name, seconds)
                        }
                    }
                    reloadFor(signedIn.uniqueId)
                }
                if (result.isSuccess) {
                    sendWearAck(event.sourceNodeId, id, "saved")
                    DriveSyncWorker.syncNow(this@MainActivity)
                    status = null
                } else {
                    sendWearAck(event.sourceNodeId, id, "rejected")
                    status = "Registro Wear: " + (result.exceptionOrNull()?.localizedMessage
                        ?: "no se pudo confirmar")
                }
                busy = false
            }
        }
    }

    private fun sendWearAck(node: String, id: String, result: String) {
        val body = JSONObject().put("id", id).put("status", result)
            .toString().toByteArray(Charsets.UTF_8)
        wearMessages.sendMessage(node, "/repera/log-set-ack", body)
    }

    /**
     * Restores a durable session on process start: uses the stored access token
     * while valid, rotates it through Supabase Auth when expired, and clears the
     * store when the refresh token is no longer accepted. Only a refresh round
     * trip decides validity; the stored access token is never trusted blindly.
     */
    /**
     * Bandeja de planes IA (port AITrainingInboxStore): traduce planes
     * pendientes del servidor a rutinas nativas. iOS usa Realtime; Android
     * sincroniza al restaurar/iniciar sesión y al refrescar Center.
     */
    private fun syncAITrainingInbox() {
        val session = verifiedSupabase ?: return
        val uniqueId = profile?.uniqueId ?: return
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                AITrainingInbox().sync(session, WorkoutRepository(this@MainActivity, uniqueId))
            }
            aiInboxPending = result.pending
            aiInboxConflicts = result.conflicts
            if (result.error != null) {
                status = result.error
            } else if (result.imported > 0) {
                status = "Plan de IA aplicado: " + (result.lastImportedTitle ?: "entreno")
                reloadFor(uniqueId)
            }
        }
    }

    private fun refreshCenter() {
        val session = verifiedSupabase ?: return
        if (centerLoading) return
        centerLoading = true
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                BusinessCenterStore().refresh(session)
            }
            when (result) {
                is BusinessCenterStore.LoadResult.Loaded -> {
                    centerSnapshot = result.snapshot
                    centerError = null
                }
                is BusinessCenterStore.LoadResult.Failed -> {
                    centerError = result.message
                }
            }
            centerLoading = false
        }
    }

    private fun centerAction(
        action: BusinessCenterStore.(SupabaseIdentity.Session) -> Unit
    ) {
        val session = verifiedSupabase ?: return
        if (centerSubmitting) return
        centerSubmitting = true
        lifecycleScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    BusinessCenterStore().action(session)
                }
                centerError = null
            } catch (error: Exception) {
                centerError = error.localizedMessage ?: "Operación no completada"
            } finally {
                centerSubmitting = false
            }
            refreshCenter()
        }
    }

    private fun restoreStoredSession() {
        val stored = sessionStore.load() ?: return
        if (busy) return
        busy = true
        lifecycleScope.launch {
            try {
                val session = withContext(Dispatchers.IO) {
                    if (stored.expiresWithin(SESSION_REFRESH_MARGIN_SECONDS)) {
                        SupabaseIdentity().refresh(stored.refreshToken)
                    } else {
                        SupabaseIdentity.Session(
                            userId = stored.userId,
                            accessToken = stored.accessToken,
                            refreshToken = stored.refreshToken,
                            expiresIn = stored.expiresAtEpochSeconds - System.currentTimeMillis() / 1000,
                            issuedAtEpochSeconds = System.currentTimeMillis() / 1000
                        )
                    }
                }
                verifiedSupabase = session
                refreshCenter()
                sessionStore.save(
                    SessionStore.StoredSession(
                        uniqueId = stored.uniqueId,
                        email = stored.email,
                        displayName = stored.displayName,
                        userId = session.userId,
                        accessToken = session.accessToken,
                        refreshToken = session.refreshToken,
                        expiresAtEpochSeconds = session.expiresAtEpochSeconds
                    )
                )
                profile = GoogleProfile(stored.uniqueId, stored.email, stored.displayName)
                DriveSyncWorker.schedulePeriodic(this@MainActivity)
                aiPlansRealtime.start()
                syncSupabaseMirrors()
                reloadFor(stored.uniqueId)
            } catch (_: Exception) {
                // Expired or revoked refresh token: back to the login screen.
                sessionStore.clear()
                aiPlansRealtime.stop()
                verifiedSupabase = null
                clearAIAccessState()
                centerSnapshot = null
                centerError = null
                profile = null
            } finally {
                busy = false
            }
        }
    }

    private fun persistSession(session: SupabaseIdentity.Session, signedIn: GoogleProfile) {
        sessionStore.save(
            SessionStore.StoredSession(
                uniqueId = signedIn.uniqueId,
                email = signedIn.email,
                displayName = signedIn.displayName,
                userId = session.userId,
                accessToken = session.accessToken,
                refreshToken = session.refreshToken,
                expiresAtEpochSeconds = session.expiresAtEpochSeconds
            )
        )
    }

    private fun signInWithGoogle() {
        if (busy) return
        if (BuildConfig.GOOGLE_WEB_CLIENT_ID.isBlank()) {
            status = "Falta configurar REPERA_GOOGLE_WEB_CLIENT_ID en Gradle"
            return
        }
        busy = true
        status = null
        lifecycleScope.launch {
            try {
                val nonceBytes = ByteArray(32).also { SecureRandom().nextBytes(it) }
                val nonce = nonceBytes.joinToString("") { "%02x".format(it) }
                val option = GetSignInWithGoogleOption.Builder(
                    BuildConfig.GOOGLE_WEB_CLIENT_ID
                ).setNonce(nonce).build()
                val request = GetCredentialRequest.Builder().addCredentialOption(option).build()
                val result = credentialManager.getCredential(context = this@MainActivity, request = request)
                val credential = result.credential as? CustomCredential
                    ?: error("Tipo de credencial no reconocido")
                check(credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL)
                val google = GoogleIdTokenCredential.createFrom(credential.data)
                val id = google.uniqueId
                check(id.isNotBlank() && google.idToken.isNotBlank())
                // The native Google identity must be verified by GoTrue before any login.
                val session = withContext(Dispatchers.IO) {
                    SupabaseIdentity().signInWithGoogle(google.idToken, nonce)
                }
                verifiedSupabase = session
                refreshCenter()
                val signedIn = GoogleProfile(
                    uniqueId = id,
                    email = google.email ?: "",
                    displayName = google.displayName ?: "Deportista"
                )
                profile = signedIn
                persistSession(session, signedIn)
                DriveSyncWorker.schedulePeriodic(this@MainActivity)
                aiPlansRealtime.start()
                syncSupabaseMirrors()
                reloadFor(id)
                status = if (snapshot == null) "No hay datos locales. Sincroniza Google Drive." else null
            } catch (error: Exception) {
                aiPlansRealtime.stop()
                verifiedSupabase = null
                clearAIAccessState()
                centerSnapshot = null
                centerError = null
                profile = null
                snapshot = null
                activeWorkout = null
                status = "Google/Supabase: " + (error.localizedMessage ?: "no se ha podido autenticar")
            } finally {
                busy = false
            }
        }
    }

    private fun connectHealth() {
        if (profile == null || busy) return
        val reader = HealthConnectReader(this)
        if (!reader.available()) {
            status = "Health Connect no está disponible"
            return
        }
        lifecycleScope.launch {
            try {
                if (reader.hasPermissions()) loadHealthToday()
                else requestHealthPermissions.launch(HealthConnectReader.permissions)
            } catch (error: Exception) {
                todayHealth = null
                status = "No se pudo conectar Salud: " + error.localizedMessage
            }
        }
    }

    private fun loadHealthToday() {
        lifecycleScope.launch {
            try {
                val reader = HealthConnectReader(this@MainActivity)
                todayHealth = withContext(Dispatchers.IO) { reader.readToday() }
                // Ventana amplia: cubre el rango más largo de Progreso (370).
                healthSamples = withContext(Dispatchers.IO) {
                    runCatching { reader.readSamples(370) }.getOrNull()
                }
                recoveryRead = withContext(Dispatchers.IO) {
                    runCatching { reader.readRecovery(45) }.getOrNull()
                }
                // Sincronización bidireccional de peso como iOS:
                // Salud → local y días solo locales → Salud.
                withContext(Dispatchers.IO) {
                    runCatching {
                        val samples = reader.readBodyMass()
                        if (samples.isNotEmpty()) {
                            val repo = WorkoutRepository(
                                this@MainActivity, profile?.uniqueId ?: return@runCatching)
                            val localOnly = repo.mergeHealthBodyWeights(samples)
                            localOnly.forEach { (millis, kg) ->
                                runCatching { reader.saveBodyMass(kg, millis) }
                            }
                        }
                    }
                }
                profile?.let { reloadFor(it.uniqueId) }
                status = null
            } catch (error: Exception) {
                todayHealth = null
                status = "No se pudo leer Salud: " + error.localizedMessage
            }
        }
    }

    private fun authorizeDrive() {
        val signedIn = profile ?: return
        if (busy) return
        busy = true
        syncing = true
        status = "Solicitando acceso a Drive…"
        val builder = AuthorizationRequest.builder()
            .setRequestedScopes(listOf(Scope("https://www.googleapis.com/auth/drive.appdata")))
        // Never silently synchronize a different Google account from the signed-in identity.
        if (signedIn.email.isNotBlank()) {
            builder.setAccount(Account(signedIn.email, "com.google"))
        }
        Identity.getAuthorizationClient(this).authorize(builder.build())
            .addOnSuccessListener { result ->
                if (result.hasResolution()) {
                    val pending = result.pendingIntent
                    if (pending == null) {
                        busy = false
                        syncing = false
                        status = "Drive requiere consentimiento"
                    } else {
                        driveConsent.launch(IntentSenderRequest.Builder(pending.intentSender).build())
                    }
                } else {
                    val token = result.accessToken
                    if (token.isNullOrBlank()) {
                        busy = false
                        syncing = false
                        status = "No se recibió acceso a Drive"
                    } else syncWithDrive(token)
                }
            }
            .addOnFailureListener {
                busy = false
                syncing = false
                status = "No se pudo conectar Drive: " + it.localizedMessage
            }
    }

    private fun syncWithDrive(oneTimeToken: String) {
        val signedIn = profile ?: run { busy = false; syncing = false; return }
        syncing = true
        status = "Sincronizando…"
        lifecycleScope.launch {
            try {
                val result = withContext(Dispatchers.IO) {
                    val store = LocalSnapshotStore(this@MainActivity, signedIn.uniqueId)
                    val outcome = DriveSnapshotService(oneTimeToken, store).synchronize()
                    outcome to StateOverview.fromBytes(store.read(), healthSamples, recoveryRead)
                }
                reloadFor(signedIn.uniqueId)
                status = when (result.first) {
                    DriveSnapshotService.Outcome.Empty -> "Drive no tiene aún datos de Repera"
                    DriveSnapshotService.Outcome.Unchanged -> "Datos actualizados"
                    DriveSnapshotService.Outcome.Uploaded -> "Copia guardada en Google Drive"
                    DriveSnapshotService.Outcome.Downloaded -> "Datos recuperados de Google Drive"
                    DriveSnapshotService.Outcome.Conflict ->
                        "Copias distintas: no se han sobrescrito los datos"
                }
            } catch (error: Exception) {
                status = "Sincronización incompleta: " + error.localizedMessage
            } finally {
                busy = false
                syncing = false
            }
        }
    }

    private suspend fun reloadFor(id: String) {
        val (overview, active, bytes) = withContext(Dispatchers.IO) {
            val store = LocalSnapshotStore(this@MainActivity, id)
            MobilityCatalogMigration.ensure(this@MainActivity, id)
            CatalogRefreshMigration.ensure(this@MainActivity, id)
            val repository = WorkoutRepository(this@MainActivity, id)
            // Artefactos de altas one-off interrumpidas (proceso muerto antes de
            // Guardar): iOS nunca persiste rutinas con todos los bloques vacíos.
            // Recalcula notas persistidas si subió la fórmula (iOS v11).
            runCatching { repository.refreshSessionReviewsIfNeeded() }
            val bytes = store.read()
            Triple(StateOverview.fromBytes(bytes, healthSamples, recoveryRead), repository.active(), bytes)
        }
        // Valoración pendiente tras terminar sesión (pendingSessionReview iOS).
        withContext(Dispatchers.IO) {
            WorkoutRepository(this@MainActivity, id).consumePendingReview()
        }?.let { pendingReview = it.second }
        snapshot = overview
        // Contadores que alimentan la política de límites Gratis (iOS:
        // SubscriptionManager.syncCounts). Rutinas guardadas y ejercicios
        // propios (isCustom) del estado real.
        overview?.let {
            subscriptions.syncCounts(
                libraryRoutines = it.routines,
                customExercises = it.exerciseEntries.count { e -> e.isCustom }
            )
        }
        activeWorkout = active
        refreshWodTimer()
        // Local persistence is the source of truth. A missing/disconnected watch
        // must not make a saved training action appear to have failed.
        withContext(Dispatchers.IO) {
            runCatching { WearActiveSessionBridge.publish(this@MainActivity, bytes) }
            runCatching {
                val plan = WorkoutRepository(this@MainActivity, id).todayPlanSession()
                WearActiveSessionBridge.publishTodayPlan(this@MainActivity, plan)
            }
        }
    }

    private fun refreshWodTimer() {
        val user = profile?.uniqueId
        val active = activeWorkout
        wodTimer = if (user != null && active?.wod != null)
            WodTimerStore(this, user).read(active.id, active.index)
        else null
        WodTimerService.sync(this, active, wodTimer, user)
        WearActiveSessionBridge.publishWodTimer(this, active?.id,
            active?.index ?: 0, active?.wod, wodTimer)
    }

    private fun changeWodTimer(action: String) {
        val user = profile?.uniqueId ?: return
        val active = activeWorkout ?: return
        if (active.wod == null || busy) return
        runCatching {
            wodTimer = WodTimerStore(this, user).update(active.id, active.index, action)
        }.onFailure { status = "Cronómetro: " + (it.localizedMessage ?: "error al guardar") }
        WearActiveSessionBridge.publishWodTimer(this, active.id, active.index,
            active.wod, wodTimer)
    }

    /** Tras iniciar sesión (ReperaStore.start iOS): pide el permiso si falta,
     *  captura el pin de inicio (timeout suave, nunca bloquea el Play) y
     *  arranca la ruta GPS si el entreno parece outdoor. */
    private fun beginLocationCapture() {
        if (!locationTracker.isAuthorized) {
            requestLocationPermissions.launch(arrayOf(
                android.Manifest.permission.ACCESS_FINE_LOCATION,
                android.Manifest.permission.ACCESS_COARSE_LOCATION))
            return
        }
        val signedIn = profile ?: return
        lifecycleScope.launch {
            withContext(Dispatchers.IO) {
                val repo = WorkoutRepository(this@MainActivity, signedIn.uniqueId)
                val info = repo.activeSessionOutdoorInfo() ?: return@withContext
                val pin = locationTracker.capturePin()
                if (pin != null) repo.attachLocationPin(info.sessionId, pin)
                if (locationTracker.shouldTrackRoute(info.title, info.exerciseNames)) {
                    locationTracker.startRouteTracking(info.sessionId)
                }
            }
        }
    }

    private fun runWorkoutAction(onSuccess: (() -> Unit)? = null,
                                 action: WorkoutRepository.() -> Unit) {
        val signedIn = profile ?: return
        if (busy) return
        busy = true
        lifecycleScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    WorkoutRepository(this@MainActivity, signedIn.uniqueId).action()
                }
                reloadFor(signedIn.uniqueId)
                DriveSyncWorker.syncNow(this@MainActivity)
                if (verifiedSupabase != null) syncWorkoutMirror()
                status = null
                onSuccess?.invoke()
            } catch (error: Exception) {
                status = error.localizedMessage ?: "No se pudo guardar el entrenamiento"
            } finally {
                busy = false
            }
        }
    }

    /** Descanso prescrito del ejercicio en curso antes de registrar la serie. */
    private fun currentRestInfo(): Pair<String, Int>? {
        val signedIn = profile ?: return null
        return runCatching {
            WorkoutRepository(this, signedIn.uniqueId).restInfoForExercise()
        }.getOrNull()
    }

    private fun initializeLocalCatalog() {
        val signedIn = profile ?: return
        if (busy) return
        busy = true
        lifecycleScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    CatalogBootstrap.initializeEmptyAccount(this@MainActivity, signedIn.uniqueId)
                }
                reloadFor(signedIn.uniqueId)
                status = "Biblioteca Repera preparada desde el catálogo original."
            } catch (error: Exception) {
                status = error.localizedMessage ?: "No se pudo preparar el catálogo"
            } finally {
                busy = false
            }
        }
    }

    private fun signOut() {
        if (busy) return
        busy = true
        lifecycleScope.launch {
            try {
                val session = verifiedSupabase
                if (session != null) {
                    withContext(Dispatchers.IO) { runCatching { SupabaseIdentity().signOut(session) } }
                }
                credentialManager.clearCredentialState(ClearCredentialStateRequest())
            } catch (_: Exception) {
                // UI still returns to login; existing account files stay isolated.
            } finally {
                aiPlansRealtime.stop()
                verifiedSupabase = null
                clearAIAccessState()
                sessionStore.clear()
                // Data Layer is best effort: a disconnected watch must never prevent
                // clearing the authenticated phone UI and its in-memory state.
                withContext(Dispatchers.IO) {
                    runCatching { WearActiveSessionBridge.signOut(this@MainActivity) }
                }
                profile = null
                snapshot = null
                activeWorkout = null
                wodTimer = null
                WodTimerService.sync(this@MainActivity, null, null, null)
                todayHealth = null
                status = null
                // Cerrar sesión no es crear una cuenta nueva: volver al paso
                // de login SIN olvidar permisos/precios ya vistos (port iOS).
                onboarding.resetToSignIn()
                busy = false
            }
        }
    }
}

data class RecoveryState(
    val readiness: dev.repera.domain.RecoveryEngine.TrainingReadiness?,
    val sleepIndex: Int?,
    val lastNightHours: Double?,
    val recentAverageSleepHours: Double?
)

data class StateOverview(
    val workouts: Int,
    val workoutsThisWeek: Int,
    val routines: Int,
    val exercises: Int,
    val bodyWeights: Int,
    val activeSessionTitle: String?,
    val recentWorkoutTitles: List<String>,
    val history: List<WorkoutHistoryEntry>,
    val routineEntries: List<RoutineEntry>,
    val exerciseEntries: List<ExerciseEntry>,
    val exerciseProgress: Map<String, ExerciseProgressSummary> = emptyMap(),
    val weeklyDayTotals: List<Int> = emptyList(),
    val weeklyMuscleGroups: List<MuscleWorkloadMetrics.GroupCount> = emptyList(),
    val progressByRange: Map<String, ProgressSnapshotData> = emptyMap(),
    val exerciseSessions: Map<String, List<ExerciseSessionHistory.Visit>> = emptyMap(),
    val recovery: RecoveryState? = null,
    val favoriteTimerCount: Int = 0,
    val chartsByRange: Map<String, dev.repera.domain.ProgressPreparedCharts> = emptyMap()
) {
    companion object {
        fun fromBytes(bytes: ByteArray?, health: HealthSamples? = null,
                      recovery: RecoveryRead? = null): StateOverview? {
            if (bytes == null) return null
            LocalSnapshotStore.validate(bytes)
            val json = JSONObject(String(bytes, Charsets.UTF_8))
            fun titles(key: String): List<String> {
                val array = json.getJSONArray(key)
                return (0 until array.length()).mapNotNull { index ->
                    array.optJSONObject(index)?.optString(
                        if (key == "exercises") "name" else "title"
                    )?.takeIf { it.isNotBlank() }
                }
            }
            val workoutTitles = json.getJSONArray("workouts").let { array ->
                (0 until array.length()).map { i ->
                    val workout = array.getJSONObject(i)
                    val scores = workout.optJSONArray("wodResults") ?: org.json.JSONArray()
                    val details = (0 until scores.length()).mapNotNull { n ->
                        val score = scores.getJSONObject(n)
                        when {
                            score.has("elapsedSeconds") && !score.isNull("elapsedSeconds") -> {
                                val total = score.getInt("elapsedSeconds")
                                "%d:%02d".format(total / 60, total % 60)
                            }
                            score.has("roundsCompleted") && !score.isNull("roundsCompleted") &&
                                score.has("totalReps") && !score.isNull("totalReps") ->
                                "${score.getInt("roundsCompleted")} rondas + " +
                                    "${score.getInt("totalReps")} reps"
                            score.has("totalReps") && !score.isNull("totalReps") -> "${score.getInt("totalReps")} reps"
                            else -> null
                        }
                    }.toMutableList()
                    val exercises = workout.optJSONArray("exercises") ?: org.json.JSONArray()
                    val recordedSets = (0 until exercises.length()).sumOf { n ->
                        WorkoutHistorySets.displayLines(workout, exercises.getJSONObject(n)).size
                    }
                    if (recordedSets > 0) details += "$recordedSets series"
                    workout.optString("title") + if (details.isEmpty()) ""
                        else " · " + details.joinToString(" / ")
                }
            }
            val today = java.time.LocalDate.now()
            val monday = today.minusDays((today.dayOfWeek.value - 1).toLong())
            val weeklyDayTotals = IntArray(7)
            val workoutsThisWeek = json.getJSONArray("workouts").let { archive ->
                var total = 0
                for (index in 0 until archive.length()) {
                    val session = archive.optJSONObject(index) ?: continue
                    // A UTC training started just before midnight may belong to the
                    // next day in the athlete's device-local calendar.
                    val date = runCatching {
                        java.time.Instant.parse(session.optString("startedAt"))
                            .atZone(ZoneId.systemDefault()).toLocalDate()
                    }.getOrNull() ?: runCatching {
                        java.time.LocalDate.parse(session.optString("startedAt").take(10))
                    }.getOrNull()
                    if (date != null && !date.isBefore(monday) && !date.isAfter(today)) {
                        total += 1
                        weeklyDayTotals[date.dayOfWeek.value - 1] += 1
                    }
                }
                total
            }
            val history = json.getJSONArray("workouts").let { archive ->
                (archive.length() - 1 downTo 0).take(20).map { index ->
                    val session = archive.getJSONObject(index)
                    val saved = session.optJSONArray("exercises") ?: org.json.JSONArray()
                    val movements = (0 until saved.length()).map { i ->
                        val exercise = saved.getJSONObject(i)
                        val movement = exercise.optJSONObject("exercise")
                        WorkoutHistoryMovement(
                            name = movement?.exerciseDisplayName() ?: "Ejercicio",
                            wod = exercise.optString("blockKind") == "wod",
                            registered = WorkoutHistorySets.displayLines(session, exercise),
                            entryId = exercise.optString("id"),
                            catalogExerciseId = movement?.optString("id") ?: "",
                            editableSets = WorkoutHistorySets.loggedSetsWithLines(exercise)
                                .map { (setId, line) -> FinishedSetRef(setId, line) }
                        )
                    }
                    val wodScores = session.optJSONArray("wodResults") ?: org.json.JSONArray()
                    val results = (0 until wodScores.length()).mapNotNull { i ->
                        val score = wodScores.getJSONObject(i)
                        val value = when {
                            score.has("elapsedSeconds") && !score.isNull("elapsedSeconds") -> {
                                val seconds = score.getInt("elapsedSeconds")
                                "%d:%02d".format(seconds / 60, seconds % 60)
                            }
                            score.has("roundsCompleted") && score.has("totalReps") ->
                                "${score.getInt("roundsCompleted")} rondas + " +
                                    "${score.getInt("totalReps")} reps"
                            score.has("totalReps") -> "${score.getInt("totalReps")} reps"
                            score.has("roundsCompleted") && !score.isNull("roundsCompleted") ->
                                "${score.getInt("roundsCompleted")} rondas"
                            else -> null
                        }
                        value?.let {
                            (WodFormat.fromWire(score.optString("format"))?.displayName
                                ?: score.optString("format")) + " · " + it
                        }
                    }
                    WorkoutHistoryEntry(
                        id = session.optString("id"),
                        title = session.optString("title"),
                        review = session.optJSONObject("sessionReview")
                            ?.let { SessionReviewJson.fromJson(it) },
                        startedAt = runCatching {
                            java.time.Instant.parse(session.optString("startedAt"))
                                .atZone(java.time.ZoneId.systemDefault())
                                .toLocalDate().format(reperaDayFormatter)
                        }.getOrElse { session.optString("startedAt").take(10) },
                        results = results,
                        movements = movements,
                        routePoints = session.optJSONArray("routePoints")?.let { rp ->
                            (0 until rp.length()).mapNotNull { i ->
                                val point = rp.getJSONObject(i)
                                val lat = point.optDouble("latitude", Double.NaN)
                                val lon = point.optDouble("longitude", Double.NaN)
                                if (lat.isNaN() || lon.isNaN()) null else
                                    dev.repera.domain.WorkoutRoutePoint(
                                        id = point.optInt("id"),
                                        latitude = lat,
                                        longitude = lon,
                                        recordedAtEpochMs =
                                            point.optLong("recordedAtEpochMs"),
                                        speedMps = point.optDouble("speedMps")
                                            .takeIf { !it.isNaN() },
                                        altitudeMeters = point.optDouble("altitudeMeters")
                                            .takeIf { !it.isNaN() }
                                    )
                            }
                        } ?: emptyList()
                    )
                }
            }
            val routineEntries = json.getJSONArray("routines").let { array ->
                (0 until array.length()).map { n ->
                    val item = array.getJSONObject(n)
                    val blocks = item.optJSONArray("blocks")
                    val supported = blocks != null && blocks.length() > 0 &&
                        (0 until blocks.length()).all { index ->
                            val block = blocks.getJSONObject(index)
                            block.optString("kind") == "strength" ||
                                WodSessionAssembler.supports(block)
                        }
                    // Acepta fecha pura "yyyy-MM-dd" (formato actual) e instant
                    // ISO (snapshots escritos antes del fix de fecha).
                    val day = item.optString("scheduledDate").takeIf { it.isNotBlank() }
                        ?.let { value ->
                            runCatching {
                                Instant.parse(value).atZone(ZoneId.systemDefault())
                                    .toLocalDate().toString()
                            }.getOrNull()
                                ?: runCatching { LocalDate.parse(value.take(10)).toString() }
                                    .getOrNull()
                        }
                    val blockInfos = blocks?.let { array ->
                        (0 until array.length()).map { bi ->
                            val block = array.getJSONObject(bi)
                            val kind = block.optString("kind")
                            val entries = if (kind == "strength") {
                                block.optJSONArray("exercises")?.let { exs ->
                                    (0 until exs.length()).map { ei ->
                                        val ex = exs.getJSONObject(ei)
                                        val planned = ex.optJSONArray("plannedSets")
                                        val first = planned?.optJSONObject(0)
                                        RoutineBlockEntryInfo(
                                            exerciseId = ex.getString("exerciseId"),
                                            name = "",
                                            quantity = first?.optInt("targetReps")
                                                ?.takeIf { it > 0 } ?: 8,
                                            sets = planned?.length() ?: 1,
                                            weightKg = if (first?.has("targetWeightKg") == true)
                                                first.getDouble("targetWeightKg") else null
                                        )
                                    }
                                }.orEmpty()
                            } else {
                                block.optJSONArray("movements")?.let { mv ->
                                    (0 until mv.length()).map { mi ->
                                        val m = mv.getJSONObject(mi)
                                        RoutineBlockEntryInfo(
                                            exerciseId = m.optString("exerciseId"),
                                            name = m.optString("name"),
                                            quantity = when {
                                                m.has("reps") -> m.getInt("reps")
                                                m.has("calories") -> m.getInt("calories")
                                                m.has("distanceMeters") -> m.getInt("distanceMeters")
                                                else -> 1
                                            }
                                        )
                                    }
                                }.orEmpty()
                            }
                            val scheme = block.optJSONArray("movements")?.optJSONObject(0)
                                ?.optJSONArray("repScheme")
                                ?.let { s -> (0 until s.length()).map { s.getInt(it) } }
                            RoutineBlockInfo(
                                title = block.optString("title"),
                                format = if (kind == "strength") "strength"
                                    else block.optString("wodFormat", "strength"),
                                timeCapMinutes = block.optInt("timeCapMinutes", 12),
                                rounds = block.optInt("rounds", 1),
                                emomIntervalSeconds = block.optInt("emomIntervalSeconds", 60),
                                workSeconds = block.optInt("workSeconds", 20),
                                restSeconds = block.optInt("restBetweenRoundsSeconds",
                                    block.optInt("restSeconds", 10)),
                                ladderScheme = scheme,
                                entries = entries
                            )
                        }
                    }.orEmpty()
                    RoutineEntry(
                        id = item.getString("id"), title = item.optString("title"),
                        supported = supported, scheduledDate = day,
                        weekday = item.optInt("weekday").takeIf { item.has("weekday") && it in 1..7 },
                        timeMinutes = item.optInt("scheduledTimeMinutes")
                            .takeIf { item.has("scheduledTimeMinutes") && it in 0..1439 },
                        blocks = blockInfos,
                        progression = item.optString("progression", "off"),
                        isFavorite = item.optBoolean("isFavorite", false)
                    )
                }
            }
            val exerciseEntries = json.getJSONArray("exercises").let { array ->
                (0 until array.length()).map { n ->
                    val ex = array.getJSONObject(n)
                    val mode = ExerciseInput.mode(
                        ex.getString("name"),
                        ex.optString("equipment"),
                        ex.optString("targetMuscle"),
                        ex.optString("muscleGroup"),
                        ex.optString("sportTag")
                    )
                    ExerciseEntry(ex.getString("id"), ex.getString("name"),
                        mode.basicRecorderAvailable, mode.showsWeight,
                        muscleGroup = ex.optString("muscleGroup"),
                        sportTag = ex.optString("sportTag").takeIf { it.isNotBlank() },
                        hyroxTraining = ExerciseCatalogFilters.isHyroxTrainingMovement(
                            ex.getString("name")),
                        loggingStyle = when (mode) {
                            dev.repera.domain.ExerciseInputMode.MACHINE_WORK -> "machineWork"
                            dev.repera.domain.ExerciseInputMode.REPS_AND_TIME -> "repsAndTime"
                            else -> "strength"
                        },
                        equipment = ex.optString("equipment"),
                        targetMuscle = ex.optString("targetMuscle"),
                        secondaryMuscles = ex.optJSONArray("secondaryMuscles")?.let { arr ->
                            (0 until arr.length()).map { arr.getString(it) }
                        }.orEmpty(),
                        isFavorite = ex.optBoolean("isFavorite", false),
                        detailDescription = ex.optString("detailDescription")
                            .takeIf { it.isNotBlank() },
                        instructions = ex.optJSONArray("instructions")?.let { arr ->
                            (0 until arr.length()).map { arr.getString(it) }
                        }.orEmpty(),
                        isCustom = ex.optBoolean("isCustom"))
                }.sortedBy { it.name }
            }
            val recoveryState = recovery?.let { rec ->
                val stats = ProgressSnapshotBuilder.statsWorkouts(json)
                val lastNight = rec.nights.lastOrNull()
                val recentNights = rec.nights.takeLast(7)
                val avg = if (recentNights.isEmpty()) null
                    else recentNights.map { it.hours }.average()
                val observed = health?.externalActivities?.map {
                    dev.repera.domain.RecoveryEngine.ObservedActivity(
                        epochMillis = it.epochMillis,
                        durationMinutes = it.durationMinutes,
                        isCardio = dev.repera.domain.HealthMuscleMapper
                            .isCardio(it.type))
                } ?: emptyList()
                RecoveryState(
                    readiness = dev.repera.domain.RecoveryEngine.trainingReadiness(
                        nowMillis = System.currentTimeMillis(),
                        sleepHours = lastNight?.hours,
                        recentAverageSleepHours = avg,
                        workouts = stats,
                        vitalHistory = rec.vitals,
                        observedActivities = observed),
                    sleepIndex = dev.repera.domain.RecoveryEngine.sleepIndex(
                        lastNight?.hours, avg),
                    lastNightHours = lastNight?.hours,
                    recentAverageSleepHours = avg
                )
            }
            return StateOverview(
                recovery = recoveryState,
                favoriteTimerCount = json.optJSONArray("favoriteTimers")?.length() ?: 0,
                workouts = workoutTitles.size,
                workoutsThisWeek = workoutsThisWeek,
                routines = routineEntries.size,
                exercises = exerciseEntries.size,
                bodyWeights = json.optJSONArray("bodyWeights")?.length() ?: 0,
                activeSessionTitle = json.optJSONObject("activeSession")?.optString("title"),
                recentWorkoutTitles = workoutTitles.asReversed().take(20),
                history = history,
                routineEntries = routineEntries,
                exerciseEntries = exerciseEntries,
                exerciseProgress = ExerciseProgressMetrics.fromWorkouts(json.getJSONArray("workouts")),
                weeklyDayTotals = weeklyDayTotals.toList(),
                weeklyMuscleGroups = MuscleWorkloadMetrics.weekly(
                    json.getJSONArray("workouts"), today, ZoneId.systemDefault()),
                exerciseSessions = ExerciseSessionHistory.fromArchive(json.getJSONArray("workouts")),
                progressByRange = dev.repera.domain.ProgressTimeRange.entries.associate { range ->
                    range.wire to ProgressSnapshotBuilder.build(json, range, health = health)
                },
                chartsByRange = dev.repera.domain.ProgressTimeRange.entries.associate { range ->
                    range.wire to dev.repera.domain.ProgressChartBuilder.build(
                        range = range,
                        weekStartsOnMonday = true,
                        heartRateDays = health?.heartRateDays?.map {
                            dev.repera.domain.DailyHeartRatePoint(
                                it.date, it.minBpm, it.avgBpm, it.maxBpm)
                        } ?: emptyList(),
                        energyDays = health?.energyDays?.map {
                            dev.repera.domain.DailyActiveEnergyPoint(it.date, it.kcal)
                        } ?: emptyList(),
                        workouts = ProgressSnapshotBuilder.statsWorkouts(json),
                        external = health?.daySamples ?: emptyList(),
                        now = java.time.LocalDate.now())
                }
            )
        }
    }
}


/** Nombre visible de un ejercicio embebido en JSON (sesiones, historial):
 * canoniza como Apple vía SportExerciseNames usando sportTag si existe,
 * sin tocar el nombre persistido. */
internal fun org.json.JSONObject.exerciseDisplayName(): String {
    val base = optString("name").ifBlank { return "Ejercicio" }
    val tag = optString("sportTag").takeIf { it.isNotBlank() }
    return dev.repera.domain.SportExerciseNames.displayName(base, tag)
}

data class RoutineEntry(
    val id: String,
    val title: String,
    val supported: Boolean,
    val scheduledDate: String? = null,
    val weekday: Int? = null,
    val timeMinutes: Int? = null,
    val blocks: List<RoutineBlockInfo> = emptyList(),
    val progression: String = "off",
    val isFavorite: Boolean = false
)

/** Bloque de una rutina tal y como se muestra en el editor de contenido. */
data class RoutineBlockInfo(
    val title: String,
    val format: String,
    val timeCapMinutes: Int = 12,
    val rounds: Int = 1,
    val emomIntervalSeconds: Int = 60,
    val workSeconds: Int = 20,
    val restSeconds: Int = 10,
    val ladderScheme: List<Int>? = null,
    val entries: List<RoutineBlockEntryInfo> = emptyList()
)

data class RoutineBlockEntryInfo(
    val exerciseId: String,
    val name: String,
    val quantity: Int,
    val sets: Int = 1,
    val weightKg: Double? = null
)

data class ExerciseEntry(
    val id: String, val name: String, val supportsBasicInput: Boolean,
    val allowsWeight: Boolean, val muscleGroup: String = "",
    val sportTag: String? = null, val hyroxTraining: Boolean = false,
    val loggingStyle: String = "strength",
    val equipment: String = "",
    val targetMuscle: String = "",
    val secondaryMuscles: List<String> = emptyList(),
    val detailDescription: String? = null,
    val instructions: List<String> = emptyList(),
    val isCustom: Boolean = false,
    val isFavorite: Boolean = false
) {
    /** Nombre visible como en Apple: SportExerciseNames.displayName canoniza
     * CrossFit/Halterofilia al inglés sin tocar el nombre persistido ni el ID. */
    val displayName: String
        get() = dev.repera.domain.SportExerciseNames.displayName(name, sportTag)
}

data class WorkoutHistoryEntry(
    val id: String,
    val title: String,
    val startedAt: String,
    val results: List<String>,
    val movements: List<WorkoutHistoryMovement>,
    val review: dev.repera.domain.SessionReview? = null,
    val routePoints: List<dev.repera.domain.WorkoutRoutePoint> = emptyList()
)
data class WorkoutHistoryMovement(
    val name: String,
    val wod: Boolean,
    val registered: List<String>,
    val entryId: String = "",
    /** Id de catálogo del ejercicio (para abrir su ficha); entryId es la
     *  instancia dentro de la sesión (para editar series). */
    val catalogExerciseId: String = "",
    val editableSets: List<FinishedSetRef> = emptyList()
)

/** Serie registrada editable de un entreno terminado (identidad real del snapshot). */
data class FinishedSetRef(
    val setId: String,
    val line: String
)
