package dev.repera.mobile

import kotlinx.coroutines.sync.withLock
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
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.foundation.layout.Box
import dev.repera.mobile.monetization.FreeUsageStore
import dev.repera.mobile.monetization.LocalSubscriptions
import dev.repera.mobile.monetization.PaywallMode
import dev.repera.mobile.monetization.PaywallScreen
import dev.repera.mobile.monetization.PlayBillingAccountIdentity
import dev.repera.mobile.monetization.PlayBillingEntitlementProvider
import dev.repera.mobile.monetization.PlayPurchaseVerifyClient
import dev.repera.mobile.monetization.SubscriptionManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
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
    private var restoringSession by mutableStateOf(false)
    private var syncing by mutableStateOf(false)
    private var status by mutableStateOf<String?>(null)
    private var snapshot by mutableStateOf<StateOverview?>(null)
    private var activeWorkout by mutableStateOf<ActiveWorkout?>(null)
    private var pendingReview by mutableStateOf<dev.repera.domain.SessionReview?>(null)
    private var pendingReviewSessionId: String? = null
    private var wodTimer by mutableStateOf<WodTimerState?>(null)
    private var todayHealth by mutableStateOf<TodayHealth?>(null)
    private var healthAccess by mutableStateOf(HealthAccessState.UNKNOWN)
    private var healthSamples by mutableStateOf<HealthSamples?>(null)
    private var recoveryRead by mutableStateOf<RecoveryRead?>(null)
    private var privateHealthRevision=0L
    private val credentialManager by lazy { CredentialManager.create(this) }
    private val centerGate=AccountRevisionGate()
    private var verifiedSupabaseState by mutableStateOf<SupabaseIdentity.Session?>(null)
    private var verifiedSupabase: SupabaseIdentity.Session?
        get() = verifiedSupabaseState
        set(value) {
            if(centerGate.update(value?.userId)) {
                centerSnapshot=null;centerError=null;centerLoading=false;centerSubmitting=false
                centerDirectory=emptyList();centerDirectorySearching=false;centerDirectoryGeneration++
                todayHealth=null;healthSamples=null;recoveryRead=null;healthAccess=HealthAccessState.UNKNOWN
                pendingReview=null;pendingReviewSessionId=null
                clearAIAccessState(); resetManualMirrorSync()
            }
            verifiedSupabaseState=value
        }
    private var lastCatalogCheckAt = 0L
    private var catalogRefreshRunning = false
    private var centerSnapshot by mutableStateOf<BusinessCenterStore.Snapshot?>(null)
    private var centerLoading by mutableStateOf(false)
    private var centerSubmitting by mutableStateOf(false)
    private var centerDirectory by mutableStateOf<List<BusinessCenterStore.Organization>>(emptyList())
    private var centerDirectorySearching by mutableStateOf(false)
    private var centerDirectoryGeneration=0L
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
    /** Estado comercial (Pro/Gratis) + cuotas + paywall. Port del entorno iOS.
     * Play Billing detecta compras; Pro solo tras verify Edge Function. */
    private val subscriptions by lazy {
        SubscriptionManager(
            provider = PlayBillingEntitlementProvider(
                this,
                billingAccountId = { verifiedSupabase?.userId?.let(PlayBillingAccountIdentity::fromUserId) }
            ) { this },
            freeUsage = FreeUsageStore.forAccount(java.io.File(filesDir, "monetization")),
            verifyClient = PlayPurchaseVerifyClient(),
            accessTokenProvider = { verifiedSupabase?.accessToken }
        )
    }
    /** Durable A-B-A identity guard for asynchronous account work. */
    private fun accountWorkGuard(owner:String,userId:String):()->Boolean {
        val store=SessionStore(this)
        val stamp=store.identityRevision()
        return {
            val current=store.load()
            store.identityRevision()==stamp && current?.uniqueId==owner && current.userId==userId
        }
    }

    /** Espejo Supabase de entrenos terminados (port BusinessWorkoutSyncStore). */
    private var manualMirrorSyncing by mutableStateOf(false)
    private var manualMirrorLastAt by mutableStateOf<String?>(null)
    private var manualMirrorCount by mutableStateOf(0)
    private var manualMirrorError by mutableStateOf<String?>(null)

    /** Apple "Sincronizar ahora": igual que el espejo automático, pero con estado y error visibles. */
    private fun resetManualMirrorSync() {
        manualMirrorSyncing = false; manualMirrorLastAt = null; manualMirrorCount = 0; manualMirrorError = null
    }

    private fun syncWorkoutMirrorNow() {
        if (manualMirrorSyncing) return
        val session = verifiedSupabase
        val uniqueId = profile?.uniqueId
        if (session == null || uniqueId == null) { manualMirrorError = ManualMirrorSyncText.NOT_CONNECTED; return }
        val authorized = accountWorkGuard(uniqueId, session.userId)
        manualMirrorError = null; manualMirrorSyncing = true
        lifecycleScope.launch {
            val result = runCatching {
                withContext(Dispatchers.IO) {
                    val session = runCatching { refreshedSessionBlocking(uniqueId) { authorized() } }.getOrNull()?.second?.also {
                        withContext(Dispatchers.Main) { if (authorized()) verifiedSupabase = it }
                    } ?: session
                    // Apple persistAndFlush before "Sincronizar ahora": rows still in the Play debounce are saved first.
                    val repo = WorkoutRepository(this@MainActivity, uniqueId, authorized)
                    pendingLiveRef.getAndSet(null)?.let { repo.persistLiveRows(it.sessionId, it.index, it.rows, it.unit) }
                    WorkoutMirrorStore(this@MainActivity, session.userId, stillAuthorized = authorized)
                        .sync(session, repo)
                }
            }
            if (profile?.uniqueId == uniqueId && verifiedSupabase?.userId == session.userId) {
                val r = result.getOrNull()
                if (r != null && r.ok) {
                    manualMirrorLastAt = java.time.format.DateTimeFormatter.ofLocalizedDateTime(java.time.format.FormatStyle.MEDIUM,java.time.format.FormatStyle.SHORT)
                        .format(java.time.ZonedDateTime.now())
                    manualMirrorCount = r.mirroredCount
                } else manualMirrorError = r?.error ?: result.exceptionOrNull()?.localizedMessage ?: "No se pudo sincronizar con Supabase."
                manualMirrorSyncing = false
            }
        }
    }

    private val sessionRefreshLock = Any()

    /** Renueva el JWT si caduca pronto, serializado entre todos los usos (Apple: un solo refresh token rotatorio a la vez).
     *  Devuelve el token válido y la sesión rotada (null si no hizo falta). Bloqueante: llamar desde IO. */
    private fun refreshedSessionBlocking(accountId: String, currentAccount: () -> Boolean): Pair<String, SupabaseIdentity.Session?> =
        synchronized(sessionRefreshLock) {
            val storedRevision = sessionStore.identityRevision()
            val current = sessionStore.load()
            check(current != null && current.uniqueId == accountId)
            if (current.expiresWithin(90)) {
                val rotated = SupabaseIdentity().refresh(current.refreshToken)
                check(currentAccount()) {"La cuenta cambió durante la renovación"}
                check(sessionStore.saveIfCurrent(storedRevision, current.uniqueId, current.userId, current.copy(
                    userId = rotated.userId,
                    accessToken = rotated.accessToken,
                    refreshToken = rotated.refreshToken,
                    expiresAtEpochSeconds = rotated.expiresAtEpochSeconds
                ))) {"La sesión cambió durante la renovación"}
                rotated.accessToken to rotated
            } else current.accessToken to null
        }

    private fun syncWorkoutMirror() {
        val session = verifiedSupabase ?: return
        val uniqueId = profile?.uniqueId ?: return
        val authorized=accountWorkGuard(uniqueId,session.userId)
        lifecycleScope.launch {
            // El espejo nunca bloquea la app: un fallo se reintenta en el
            // siguiente arranque/refresco y no se muestra en la UI.
            withContext(Dispatchers.IO) {
                val session = runCatching { refreshedSessionBlocking(uniqueId) { authorized() } }.getOrNull()?.second?.also {
                    withContext(Dispatchers.Main) { if (authorized()) verifiedSupabase = it }
                } ?: session
                WorkoutMirrorStore(this@MainActivity, session.userId,stillAuthorized=authorized)
                    .sync(session, WorkoutRepository(this@MainActivity, uniqueId, authorized))
            }
        }
    }

    /** Espejo del calendario de planificación para la IA (contexto). */
    private fun syncAITrainingContext() {
        val session = verifiedSupabase ?: return
        val uniqueId = profile?.uniqueId ?: return
        val authorized=accountWorkGuard(uniqueId,session.userId)
        lifecycleScope.launch {
            withContext(Dispatchers.IO) {
                AITrainingContextStore(this@MainActivity, session.userId,stillAuthorized=authorized)
                    .sync(session, WorkoutRepository(this@MainActivity, uniqueId))
            }
        }
    }

    /** Apple 63f9cead: con un entreno activo se difieren las sincronizaciones
     *  no esenciales y se reanudan al terminar; la grabación nunca se bloquea. */
    private var deferredMirrorSync = false

    /** Espejo IA + bandeja: tras establecer sesión o refrescar. */
    private fun syncSupabaseMirrors() {
        if (activeWorkout != null) { deferredMirrorSync = true; return }
        deferredMirrorSync = false
        syncAITrainingInbox()
        syncWorkoutMirror()
        syncAITrainingContext()
        refreshSharing()
        refreshAIPrograms()
    }

    /** Reanuda la sincronización diferida cuando el entreno activo termina
     *  (Apple onChange(hasWorkoutInProgress): wasRecording && !isRecording). */
    private fun resumeDeferredMirrorSyncIfNeeded() {
        if (activeWorkout == null && deferredMirrorSync) syncSupabaseMirrors()
    }

    // ---- Programas IA (port AITrainingProgramsView) ----
    private var aiPrograms by mutableStateOf<List<AITrainingProgramsStore.Program>?>(
        null)
    private var aiProgramsLoading by mutableStateOf(false)
    private var aiProgramsUpdatingId by mutableStateOf<String?>(null)
    private var aiProgramsError by mutableStateOf<String?>(null)

    private fun refreshAIPrograms() {
        val session = verifiedSupabase ?: return
        val owner=profile?.uniqueId ?: return
        val revision=centerGate.revision
        val authorized=accountWorkGuard(owner,session.userId)
        fun current()=authorized() && profile?.uniqueId==owner && centerGate.revision==revision
        if (aiProgramsLoading) return
        aiProgramsLoading = true
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                AITrainingProgramsStore(stillAuthorized=authorized).refresh(session)
            }
            if(!current()) return@launch
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
        val owner=profile?.uniqueId ?: return
        val revision=centerGate.revision
        val authorized=accountWorkGuard(owner,session.userId)
        fun current()=authorized() && profile?.uniqueId==owner && centerGate.revision==revision
        if (aiProgramsUpdatingId != null) return
        aiProgramsUpdatingId = program.id
        lifecycleScope.launch {
            val failure = withContext(Dispatchers.IO) {
                AITrainingProgramsStore(stillAuthorized=authorized).changeStatus(session, program, status)
            }
            if(!current()) return@launch
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
        val owner=profile?.uniqueId ?: return
        val revision=centerGate.revision
        val authorized=accountWorkGuard(owner,session.userId)
        fun current()=authorized() && profile?.uniqueId==owner && centerGate.revision==revision
        lifecycleScope.launch {
            val map = withContext(Dispatchers.IO) {
                runCatching {
                    WorkoutMirrorStore(this@MainActivity, session.userId,stillAuthorized=authorized)
                        .refreshSharing(session)
                }.getOrNull()
            }
            if(!current()) return@launch
            if (map != null) sharingByCenter = map
        }
    }

    private fun setSharing(orgId: String, enabled: Boolean) {
        val session = verifiedSupabase ?: return
        val owner=profile?.uniqueId ?: return
        val revision=centerGate.revision
        val authorized=accountWorkGuard(owner,session.userId)
        fun current()=authorized() && profile?.uniqueId==owner && centerGate.revision==revision
        if (sharingUpdating) return
        sharingUpdating = true
        val linked = centerSnapshot?.athleteCenterIds ?: emptySet()
        lifecycleScope.launch {
            val failure = withContext(Dispatchers.IO) {
                WorkoutMirrorStore(this@MainActivity, session.userId,stillAuthorized=authorized)
                    .setSharing(session, orgId, enabled, linked)
            }
            if(!current()) return@launch
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
        val owner=profile?.uniqueId ?: return
        val revision=centerGate.revision
        val authorized=accountWorkGuard(owner,session.userId)
        fun current()=authorized() && profile?.uniqueId==owner && centerGate.revision==revision
        val uniqueId = profile?.uniqueId ?: return
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                val repository = WorkoutRepository(this@MainActivity, uniqueId)
                val store = AIChangeRequestStore(this@MainActivity, session.userId,stillAuthorized=authorized)
                store.syncCustomExercises(session, repository)
                AIAccessStore(stillAuthorized=authorized).refresh(session) to store.refresh(session)
            }
            if(!current()) return@launch
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
        val owner=profile?.uniqueId ?: return
        val revision=centerGate.revision
        val authorized=accountWorkGuard(owner,session.userId)
        fun current()=authorized() && profile?.uniqueId==owner && centerGate.revision==revision
        if (aiBusy) return
        aiBusy = true; aiError = null; aiSuccess = null
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                AIAccessStore(stillAuthorized=authorized).create(session, label, expiry, canWrite)
            }
            if(!current()) return@launch
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
        val owner=profile?.uniqueId ?: return
        val revision=centerGate.revision
        val authorized=accountWorkGuard(owner,session.userId)
        fun current()=authorized() && profile?.uniqueId==owner && centerGate.revision==revision
        if (aiBusy) return
        aiBusy = true; aiError = null; aiSuccess = null
        lifecycleScope.launch {
            val failure = withContext(Dispatchers.IO) {
                AIAccessStore(stillAuthorized=authorized).revoke(session, tokenId)
            }
            if(!current()) return@launch
            if (failure == null) {
                // Apple 0a640da8: sin mensaje de exito; solo refresca la lista.
                refreshAIAccess()
            } else aiError = "No se pudo desconectar: " + failure
            aiBusy = false
        }
    }

    private fun decideAIChange(change: AIChangeRequestStore.Change,
                               approve: Boolean) {
        val session = verifiedSupabase ?: return
        val owner=profile?.uniqueId ?: return
        val revision=centerGate.revision
        val authorized=accountWorkGuard(owner,session.userId)
        fun current()=authorized() && profile?.uniqueId==owner && centerGate.revision==revision
        val uniqueId = profile?.uniqueId ?: return
        if (aiChangeBusy) return
        aiChangeBusy = true; aiChangeError = null
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                AIChangeRequestStore(this@MainActivity, session.userId,stillAuthorized=authorized).decide(
                    session, change, approve,
                    WorkoutRepository(this@MainActivity, uniqueId),
                    WorkoutMirrorStore(this@MainActivity, session.userId,stillAuthorized=authorized))
            }
            if(!current()) return@launch
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

    private val pendingHealthRequest=PendingAccountRequest()
    private val requestHealthPermissions = registerForActivityResult(
        PermissionController.createRequestPermissionResultContract()
    ) { granted ->
        if(!pendingHealthRequest.consume(profile?.uniqueId,centerGate.revision)) return@registerForActivityResult
        refreshHealthAccess()
        if (HealthConnectReader.hasReadablePermission(granted)) {
            loadHealthToday()
        } else {
            // No volcar denegación a `status` global (aparecía en rojo en Crear).
            todayHealth = null
        }
    }

    private var pendingDriveOwner:String?=null
    private var pendingDriveRevision:Long?=null
    private val driveConsent = registerForActivityResult(
        ActivityResultContracts.StartIntentSenderForResult()
    ) { result ->
        val owner=pendingDriveOwner
        val revision=pendingDriveRevision
        pendingDriveOwner=null;pendingDriveRevision=null
        if(owner==null || revision==null || profile?.uniqueId!=owner || centerGate.revision!=revision) return@registerForActivityResult
        val resultIntent = result.data
        if (result.resultCode == RESULT_OK && resultIntent != null) {
            runCatching {
                Identity.getAuthorizationClient(this)
                    .getAuthorizationResultFromIntent(resultIntent)
                    .accessToken
            }.onSuccess { token ->
                if (!token.isNullOrBlank()) syncWithDrive(token,owner,revision)
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

    override fun onResume() {
        super.onResume()
        val user = profile
        if (user != null) {
            // Apple ensureUsableSession on return to foreground: a verified session whose JWT is about to expire is
            // renewed here too, so a revoked refresh token sends the app back to login instead of failing silently.
            val needsRenewal = verifiedSupabase != null &&
                sessionStore.load()?.expiresWithin(SESSION_REFRESH_MARGIN_SECONDS) == true
            if ((verifiedSupabase == null || needsRenewal) && !busy && !restoringSession) restoreStoredSession()
            refreshCatalogSilently(user.uniqueId);refreshHealthAccess()
        }
    }

    /** Real availability + granted-read check; never inferred from missing data. */
    private fun refreshHealthAccess() {
        val owner=profile?.uniqueId ?: return
        val revision=centerGate.revision
        lifecycleScope.launch {
            val state=withContext(Dispatchers.IO) {
                runCatching {
                    val reader=HealthConnectReader(this@MainActivity)
                    if(!reader.available()) HealthAccessState.UNAVAILABLE
                    else if(reader.hasPermissions()) HealthAccessState.GRANTED else HealthAccessState.NOT_GRANTED
                }.getOrDefault(HealthAccessState.UNKNOWN)
            }
            if(profile?.uniqueId==owner && centerGate.revision==revision) healthAccess=state
        }
    }

    private var externalRoute by mutableStateOf<String?>(null)
    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        externalRoute = routeFromIntent(intent)
    }
    private fun routeFromIntent(intent: android.content.Intent?): String? {
        val uri = intent?.data ?: return null
        if (uri.scheme != "repera") return null
        if(intent.hasExtra("plannedSession")) {
            val sessions=SessionStore(this)
            val owner=sessions.load()?.uniqueId
            val activeId=owner?.let {runCatching {LocalSnapshotStore(this,it).read()?.let {b ->org.json.JSONObject(String(b,Charsets.UTF_8)).optJSONObject("activeSession")?.optString("id")}}.getOrNull()}
            if(!PlannedWorkoutReopen.valid(owner,sessions.identityRevision(),activeId,intent.getStringExtra("plannedOwner"),intent.getStringExtra("plannedRevision"),intent.getStringExtra("plannedSession"))) return "inicio"
        }
        return LiveNavigationTarget.route(uri.host)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        externalRoute = routeFromIntent(intent)
        restoreStoredSession()
        lifecycleScope.launch { subscriptions.start() }
        setContent {
            // Tema Repera en la raíz: onboarding/permisos/paywall no usan el
            // púrpura M3 por defecto (antes solo ReperaMobileScreen lo fijaba).
            ReperaTheme {
            val sessionMovementProvider: suspend (String) -> dev.repera.domain.SessionMovement? = { sessionId ->
                val uid = profile?.uniqueId
                val revision = centerGate.revision
                if (uid == null) null else {
                    val reader = HealthConnectReader(this)
                    runCatching {
                        if (!reader.available() || !reader.hasPermissions()) return@runCatching null
                        val repo = WorkoutRepository(this, uid)
                        val range = repo.sessionTimeRange(sessionId) ?: return@runCatching null
                        reader.readSessionMovement(range.first, range.second,
                            linkedRecordId = repo.healthRecordId(sessionId), linkedSessionId = sessionId)
                    }.getOrNull().takeIf { profile?.uniqueId == uid && centerGate.revision == revision }
                }
            }
            CompositionLocalProvider(LocalSubscriptions provides subscriptions, LocalSessionMovement provides sessionMovementProvider, LocalManualMirrorSync provides ManualMirrorSyncState(manualMirrorSyncing, verifiedSupabase != null, manualMirrorLastAt, manualMirrorCount, manualMirrorError, ::syncWorkoutMirrorNow), LocalRemovePendingSet provides { id: String -> runWorkoutAction { removePendingSet(id) } }, LocalEditPendingSet provides { id: String, reps: Int, kg: Double? -> runWorkoutAction { editPendingSet(id, reps, kg) } }, LocalPersistLiveRows provides { sid: String, index: Int, rows: List<ActiveSessionDraft.Row>, unit: String? -> persistLiveRowsNow(sid, index, rows, unit) }) {
            if (restoringSession) {
                LaunchSplashScreen()
            } else if (profile == null || !onboarding.isComplete) {
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
                displayName = snapshot?.profileSettings?.displayName ?: profile?.displayName,
                busy = busy,
                syncing = syncing,
                status = status,
                overview = snapshot,
                onSetTestedOneRM = { id,value -> runWorkoutAction { setTestedOneRM(id,value) } },
                exerciseSummary = { exerciseId ->
                    val uid = profile?.uniqueId
                    val bytes = uid?.let { LocalSnapshotStore(this, it).read() }
                    if (bytes == null) null else dev.repera.domain.StatsEngine.exerciseHistory(
                        exerciseId,
                        workouts = ProgressSnapshotBuilder.statsWorkouts(
                            org.json.JSONObject(String(bytes, Charsets.UTF_8))))
                },
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
                heartSeriesProvider = { sessionId ->
                    val uid = profile?.uniqueId
                    val revision=centerGate.revision
                    if (uid == null) emptyList() else {
                        val reader = HealthConnectReader(this)
                        runCatching {
                            if (!reader.available() || !reader.hasPermissions())
                                return@runCatching emptyList()
                            val range = WorkoutRepository(this, uid)
                                .sessionTimeRange(sessionId)
                                ?: return@runCatching emptyList()
                            reader.readSessionHeartSeries(range.first, range.second,
                                linkedRecordId = WorkoutRepository(this, uid).healthRecordId(sessionId),
                                linkedSessionId = sessionId)
                        }.getOrDefault(emptyList()).takeIf {profile?.uniqueId==uid && centerGate.revision==revision}.orEmpty()
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
                healthAccess = healthAccess,
                dayHealthProvider = {day ->
                    val owner=profile?.uniqueId
                    val revision=centerGate.revision
                    val data=withContext(Dispatchers.IO) {runCatching {
                        val reader=HealthConnectReader(this@MainActivity)
                        if(reader.hasPermissions()) reader.readDay(day) else null
                    }.getOrNull()}
                    data.takeIf {profile?.uniqueId==owner && centerGate.revision==revision}
                },
                externalHealthDetail = {entry ->
                    val owner=profile?.uniqueId;val revision=centerGate.revision
                    val detail=withContext(Dispatchers.IO) {runCatching {HealthConnectReader(this@MainActivity).readExternalDetail(entry)}.getOrNull()}
                    detail.takeIf {profile?.uniqueId==owner && centerGate.revision==revision}
                },
                onHealthConnect = ::connectHealth,
                onProgressRangeChange = { wire ->
                    dev.repera.domain.ProgressTimeRange.entries.firstOrNull { it.wire == wire }
                        ?.let(::loadHealthForProgressRange)
                },
                onPrivateSleepChanged = {enabled ->
                    privateHealthRevision++
                    // Clear private samples before any reload; an earlier in-flight read is discarded below.
                    recoveryRead=recoveryRead?.copy(nights=emptyList(),vitals=recoveryRead?.vitals.orEmpty().map {it.copy(wristTemperatureCelsius=null)})
                    profile?.uniqueId?.let {id ->lifecycleScope.launch {reloadFor(id)}}
                    if(enabled) launchHealthPermissionsForCurrentAccount()
                },
                onPrivateCycleChanged = {enabled ->
                    privateHealthRevision++
                    recoveryRead=recoveryRead?.copy(menstrualDays=emptyList(),positiveOvulationTests=emptyList())
                    profile?.uniqueId?.let {id ->lifecycleScope.launch {reloadFor(id)}}
                    if(enabled) launchHealthPermissionsForCurrentAccount()
                },
                activeWorkout = activeWorkout,
                wodTimer = wodTimer,
                onWodTimerAction = ::changeWodTimer,
                onWodTimerTick = ::refreshWodTimer,
                onStartRoutine = { id, done ->
                    runWorkoutAction(onSuccess = {
                        beginLocationCapture()
                        done()
                    }) {
                        startRoutine(
                            id,
                            subscriptions.decision(
                                dev.repera.domain.monetization.ReperaFeature.ADVANCED_STRENGTH_PROGRESSION
                            ).allowed
                        )
                    }
                },
                onEditRoutine = { id, title, schedule ->
                    runWorkoutAction { updateRoutineDetails(id, title, schedule) }
                },
                onDeleteRoutine = { id -> runWorkoutAction { deleteRoutine(id) } },
                onRemoveScheduledRoutine = { id -> runWorkoutAction { removeScheduledRoutine(id) } },
                onAssignRoutineToDate = { id, date -> runWorkoutAction { assignRoutineToDate(id, date) } },
                onCopyPreviousWeek = { week ->
                    var copied = 0
                    runWorkoutAction(onSuccess = {
                        status = if (copied == 0) "La semana anterior está vacía o los días correspondientes ya están ocupados."
                            else "Se añadieron $copied entreno${if (copied == 1) "" else "s"} de la semana anterior, sin modificar los días ya programados."
                    }) { copied = copyPreviousWeekSchedule(week) }
                },
                onClearWeeklySchedule = { week -> runWorkoutAction { clearScheduledWeek(week) } },
                onReplaceRoutineBlocks = { id, drafts, title, saved ->
                    runWorkoutAction(onSuccess=saved) {
                        replaceRoutineBlocks(id, drafts,suggestedTitle=title) { before ->
                            subscriptions.syncCounts(snapshot?.libraryRoutineCount ?: 0, before)
                            subscriptions.canCreateCustomExercise(true).allowed
                        }
                    }
                },
                onCreateTemplate = {title,drafts,schedule,requestId,saved ->
                    if(permitNewTemplate(isNew=!overviewForTemplateRetry(requestId))) runWorkoutAction(onSuccess=saved) {
                        createRoutineFromDrafts(title,drafts,schedule,routineId=requestId,
                            canCreateTemplate={count ->subscriptions.policy.copy(libraryRoutineCount=count).canCreateLibraryRoutine(true).allowed}) {before ->
                            subscriptions.syncCounts(snapshot?.libraryRoutineCount ?: 0,before)
                            subscriptions.canCreateCustomExercise(true).allowed
                        }
                    }
                },
                onCreateRoutine = { title, format, entries, minutes, rounds, schedule, interval, work, rest, ladder ->
                    if(schedule.scheduledDate!=null || permitNewTemplate()) runWorkoutAction { createRoutine(title, format, entries, minutes, rounds,
                        schedule, interval, work, rest, ladder,
                            canCreateTemplate={count ->subscriptions.policy.copy(libraryRoutineCount=count).canCreateLibraryRoutine(true).allowed}) }
                },
                onCreateRoutineFromScan = { title, blocks, requestId, dayIso, saved ->
                    val existing=overviewForTemplateRetry(requestId)
                    // DayPlus con fecha: one-off al día (no consume cupo de plantilla).
                    val schedule = if (!dayIso.isNullOrBlank())
                        RoutineSchedule(scheduledDate = dayIso) else RoutineSchedule()
                    if(schedule.scheduledDate!=null || permitNewTemplate(isNew=!existing))
                        runWorkoutAction(onSuccess=saved) {
                            createRoutineFromScan(title, blocks, schedule, routineId=requestId,
                                canCreateTemplate={count ->subscriptions.policy.copy(libraryRoutineCount=count).canCreateLibraryRoutine(true).allowed})
                        }
                },
                onStartRoutineFromScan = { title, blocks, requestId, dayIso, saved ->
                    val existing = overviewForTemplateRetry(requestId)
                    val schedule = if (!dayIso.isNullOrBlank())
                        RoutineSchedule(scheduledDate = dayIso) else RoutineSchedule()
                    if (schedule.scheduledDate != null || permitNewTemplate(isNew = !existing))
                        runWorkoutAction(onSuccess = {
                            beginLocationCapture()
                            saved()
                        }) {
                            val id = createRoutineFromScan(
                                title, blocks, schedule, routineId = requestId,
                                canCreateTemplate = { count ->
                                    subscriptions.policy.copy(libraryRoutineCount = count)
                                        .canCreateLibraryRoutine(true).allowed
                                }
                            )
                            startRoutine(
                                id,
                                subscriptions.decision(
                                    dev.repera.domain.monetization.ReperaFeature.ADVANCED_STRENGTH_PROGRESSION
                                ).allowed
                            )
                        }
                },
                onStartSessionFromDrafts = { title, drafts, fav, requestId, saved ->
                    if(!fav || activeWorkout?.draftRequestId==requestId || permitNewTemplate()) runWorkoutAction(onSuccess = { beginLocationCapture();saved() }) {
                        startSessionFromDrafts(title, drafts, fav,
                            subscriptions.decision(dev.repera.domain.monetization.ReperaFeature.ADVANCED_STRENGTH_PROGRESSION).allowed,requestId=requestId,
                            canSaveFavorite={count ->subscriptions.policy.copy(favoriteCount=count).canCreateFavorite(true).allowed}) { before ->
                            subscriptions.syncCounts(snapshot?.libraryRoutineCount ?: 0, before)
                            subscriptions.canCreateCustomExercise(true).allowed
                        }
                    }
                },
                onSaveOneOffRoutine = { title, drafts, dayIso, requestId, timeMinutes, isFavorite, pin, saved ->
                    runWorkoutAction(onSuccess = saved) {
                        val id = createRoutineFromDrafts(
                            title, drafts,
                            RoutineSchedule(scheduledDate = dayIso, timeMinutes = timeMinutes),
                            routineId = requestId,
                            locationPin = pin
                        ) { before ->
                            subscriptions.syncCounts(snapshot?.libraryRoutineCount ?: 0, before)
                            subscriptions.canCreateCustomExercise(true).allowed
                        }
                        if (isFavorite) setRoutineFavorite(id, true)
                    }
                },
                centerConnected = verifiedSupabase != null,
                centerLoading = centerLoading,
                centerSubmitting = centerSubmitting,
                centerError = centerError,
                centerSnapshot = centerSnapshot,
                onSendCenterMessage = { org,title,body -> centerAction { s -> sendMessage(s,org,title,body) } },
                onExerciseCatalogRefreshRequest = { requestExerciseCatalogRefresh() },
                onCenterRefresh = {
                    refreshCenter()
                    syncSupabaseMirrors()
                },
                centerDirectory = centerDirectory,
                centerDirectorySearching = centerDirectorySearching,
                onSearchCenterDirectory = ::searchCenterDirectory,
                onRequestCenterLink = { org,kind,note -> centerAction {session -> requestLink(session,org,kind,note)} },
                onLeaveCenter = {org -> centerAction {session -> leave(session,org)} },
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
                onPlayWod={id,request,done ->runWorkoutAction(onSuccess={beginLocationCapture();done()}) {
                    startWodTemplate(id,request,subscriptions.decision(dev.repera.domain.monetization.ReperaFeature.ADVANCED_STRENGTH_PROGRESSION).allowed)
                }},
                onToggleWodFavorite={id ->runWorkoutAction {toggleWodTemplateFavorite(id)}},
                onAddWodTemplate = { templateId ->
                    val template = dev.repera.domain.CatalogWods.template(templateId)
                    if (template != null && permitNewTemplate()) runWorkoutAction { createWodRoutine(template,
                        canCreateTemplate={count ->subscriptions.policy.copy(libraryRoutineCount=count).canCreateLibraryRoutine(true).allowed}) }
                },
                onWodScore = { rounds, reps, seconds ->
                    val scoreOwner=profile?.uniqueId
                    val scoredBlock=activeWorkout
                    runWorkoutAction(onSuccess={
                        if(scoreOwner!=null && scoredBlock!=null && profile?.uniqueId==scoreOwner) {
                            WodTimerStore(this,scoreOwner).consumePendingEnd(scoredBlock.id,scoredBlock.index,
                                scoredBlock.navigationEntries.firstOrNull {it.index==scoredBlock.index}?.blockId)
                            refreshWodTimer()
                        }
                    }) { recordWodScore(rounds, reps, seconds) }
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
                onSaveQuickSets = {id,rows,notes,requestId,onSaved ->
                    runWorkoutAction(onSuccess={onSaved();refineFinishedSessionWithHealth(requestId)}) {logQuickSets(id,rows,notes,requestId)}
                },
                onQuickLog = { id ->
                    runWorkoutAction(onSuccess = { beginLocationCapture() }) { startQuickLog(id) }
                },
                onInitializeLocal = ::initializeLocalCatalog,
                onLogSet = { quantity, weight, rir, warmup, unit, duration, deficit, failure ->
                    val rest = currentRestInfo()?.let {(name,seconds) -> name to dev.repera.domain.StrengthRestPolicy.seconds(seconds,warmup=warmup)}
                    runWorkoutAction(onSuccess = {
                        rest?.let { (name, seconds) ->
                            StrengthRestService.start(this, name, seconds,snapshot?.trainingSettings?.restSoundEnabled ?: true,snapshot?.trainingSettings?.restHapticEnabled ?: true)
                        }
                    }) { logCurrentSet(quantity, weight, rir, warmup,
                        quantityUnit = unit, durationSeconds = duration, deficitCm = deficit, toFailure = failure) }
                },
                onLogDropSet = { quantity, weight, drops, rir, failure ->
                    val rest = currentRestInfo()?.let {(name,seconds) -> name to dev.repera.domain.StrengthRestPolicy.seconds(seconds,kind="dropset")}
                    runWorkoutAction(onSuccess = {
                        rest?.let { (name, seconds) ->
                            StrengthRestService.start(this, name, seconds,snapshot?.trainingSettings?.restSoundEnabled ?: true,snapshot?.trainingSettings?.restHapticEnabled ?: true)
                        }
                    }) { logDropSet(quantity, weight, drops, rir, failure) }
                },
                onLogRestPauseSet = { clusters, weight, rir, failure ->
                    val rest = currentRestInfo()?.let {(name,seconds) -> name to dev.repera.domain.StrengthRestPolicy.seconds(seconds,kind="restpause")}
                    runWorkoutAction(onSuccess = {
                        rest?.let { (name, seconds) ->
                            StrengthRestService.start(this, name, seconds,snapshot?.trainingSettings?.restSoundEnabled ?: true,snapshot?.trainingSettings?.restHapticEnabled ?: true)
                        }
                    }) { logRestPauseSet(clusters, weight, rir, failure) }
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
                    // Tras borrar: recalcular Actividad (minutos) y refrescar Salud
                    // para no dejar «Tiempo» huérfano (extra Ramón).
                    runWorkoutAction(onSuccess = {
                        profile?.uniqueId?.let { uid ->
                            lifecycleScope.launch { refreshHealthSamplesAfterMutation(uid) }
                        }
                    }) { deleteWorkout(workoutId) }
                },
                onDeleteBodyWeight = { id -> runWorkoutAction { deleteBodyWeight(id) } },
                onLogBodyWeight = { kg ->
                    val owner=profile?.uniqueId
                    val revision=centerGate.revision
                    var recorded:Pair<Long,Double>?=null
                    runWorkoutAction(onSuccess={
                        recorded?.let {(millis,value) ->
                            if(owner!=null && profile?.uniqueId==owner && centerGate.revision==revision) lifecycleScope.launch {
                                // Local save succeeds even if Health is unavailable or permission was denied.
                                withContext(Dispatchers.IO) {runCatching {
                                    if(profile?.uniqueId==owner && centerGate.revision==revision)
                                        HealthConnectReader(this@MainActivity).saveBodyMass(value,millis,owner,stillAuthorized={profile?.uniqueId==owner && centerGate.revision==revision})
                                }}
                            }
                        }
                    }) {recorded=logBodyWeight(kg)}
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
                onCreateCustomExercise = { name, group, equip, target, secondary, desc, steps, onDone ->
                    val allowed = subscriptions.policy.canCreateCustomExercise(true).allowed
                    if (!allowed) {
                        subscriptions.presentPaywall(
                            dev.repera.domain.monetization.PaywallContext.CUSTOM_EXERCISES_LIMIT,
                            feature = dev.repera.domain.monetization.ReperaFeature.UNLIMITED_CUSTOM_EXERCISES
                        )
                    } else {
                        runWorkoutAction(onSuccess = onDone) {
                            val id = java.util.UUID.randomUUID().toString()
                            check(
                                addCustomExercise(
                                    id, name, group, equip, target, secondary, desc, steps
                                )
                            ) { "No se pudo crear el ejercicio" }
                        }
                    }
                },
                onOpenPaywallForCustomExercise = {
                    subscriptions.presentPaywall(
                        dev.repera.domain.monetization.PaywallContext.CUSTOM_EXERCISES_LIMIT,
                        feature = dev.repera.domain.monetization.ReperaFeature.UNLIMITED_CUSTOM_EXERCISES
                    )
                },
                onSelectActiveExercise = { index ->
                    StrengthRestService.cancel(this)
                    runWorkoutAction { selectActiveExercise(index) }
                },
                onUpdateActiveNotes = { notes -> runWorkoutAction { updateActiveSessionNotes(notes) } },
                onSaveActiveFavorite = { runWorkoutAction { saveActiveSessionAsFavorite {count ->
                    subscriptions.policy.copy(libraryRoutineCount=count).canCreateLibraryRoutine(true).allowed
                } } },
                onSubstituteActiveExercise = { entry ->
                    StrengthRestService.cancel(this)
                    runWorkoutAction {
                        val idx = active()?.index ?: return@runWorkoutAction
                        substituteActiveExerciseAt(
                            idx, entry.id, entry.name, entry.muscleGroup
                        )
                    }
                },
                onRemoveActiveExercise = {
                    StrengthRestService.cancel(this)
                    runWorkoutAction {
                        val idx = active()?.index ?: return@runWorkoutAction
                        removeActiveExerciseAt(idx)
                    }
                },
                activeEditorDraft = {runCatching {profile?.uniqueId?.let { WorkoutRepository(this@MainActivity,it).activeRoutineForEditing() }}.getOrNull()},
                onUpdateActivePlan = {sessionId,id,blocks,done ->runWorkoutAction(onSuccess=done) {
                    updateActiveSessionPlan(id,blocks,expectedSessionId=sessionId,
                        canCreateTemplate={count ->subscriptions.policy.copy(libraryRoutineCount=count).canCreateLibraryRoutine(true).allowed}) {before ->
                        subscriptions.policy.copy(customExerciseCount=before).canCreateCustomExercise(true).allowed
                    }
                }},
                onNext = { runWorkoutAction { next() } },
                onFinish = {
                    StrengthRestService.cancel(this)
                    val finishedSessionId = activeWorkout?.id
                    val route = locationTracker.stopRouteTracking()
                    runWorkoutAction(onSuccess = {
                        finishedSessionId?.let { refineFinishedSessionWithHealth(it) }
                    }) {
                        finish()
                        if (finishedSessionId != null && route.isNotEmpty()) {
                            attachRoutePoints(finishedSessionId, route)
                        }
                    }
                },
                // endActiveSession(save: false) iOS: borra la sesión en curso
                // sin guardarla y detiene la captura de ubicación.
                accountId = profile?.uniqueId.orEmpty(),
                initialExternalRoute = externalRoute,
                onExternalRouteHandled = { externalRoute = null },
                onUpdateProfile = ::persistProfileSettings,
                onUpdateHealthGoals = { goals -> runWorkoutAction { updateHealthGoals(goals) } },
                onUpdateRotation = { plan -> runWorkoutAction { updateRotation(plan) } },
                onUpdateTrainingSettings = { value -> runWorkoutAction { updateTrainingSettings(value) } },
                onLiveActivitySaved = {
                    profile?.uniqueId?.let { id -> lifecycleScope.launch { reloadFor(id) } }
                },
                onRemoveSportFavorite = { favId ->
                    runWorkoutAction { removeFavoriteSportActivity(favId) }
                },
                onSaveTimerSession = { completion ->
                    val account = profile?.uniqueId ?: return@ReperaMobileScreen false
                    val details = dev.repera.domain.TimerCompletionDetails(
                        modeRaw = completion.config.mode.wire,
                        configuredSeconds = completion.configuredSeconds.coerceAtLeast(1),
                        rounds = if (completion.config.mode == StandaloneTimerMode.INTERVALS)
                            completion.config.rounds.coerceAtLeast(1) else 1,
                        workSeconds = completion.config.workTotalSeconds,
                        restSeconds = completion.config.restTotalSeconds,
                        countdownSeconds = if (completion.config.countdownBeforeStart) 3 else 0
                    )
                    val ok = runCatching {
                        WorkoutRepository(this@MainActivity, account).saveTimerSession(
                            id = completion.id,
                            title = "Temporizador · ${completion.config.mode.title}",
                            startedAtMillis = completion.startedAtMillis,
                            finishedAtMillis = completion.finishedAtMillis,
                            details = details,
                            locationPin = completion.locationPin
                        )
                        true
                    }.getOrDefault(false)
                    if (ok) {
                        lifecycleScope.launch { reloadFor(account) }
                        DriveSyncWorker.syncNow(this@MainActivity)
                        if (verifiedSupabase != null) syncWorkoutMirror()
                    }
                    ok
                },
                onUpdateFinishedWorkout = { workoutId, edit ->
                  // Como Apple: con Favorito, si la cuota de rutinas no deja, paywall y NO se aplica nada.
                  if (edit.saveAsFavorite && !subscriptions.canCreateLibraryRoutine(isNew = true).allowed) {
                    subscriptions.presentPaywall(
                        dev.repera.domain.monetization.PaywallContext.ROUTINES_LIMIT,
                        feature = dev.repera.domain.monetization.ReperaFeature.UNLIMITED_ROUTINES)
                  } else
                    runWorkoutAction {
                        updateFinishedWorkout(workoutId, edit,
                            canSaveFavorite={count ->subscriptions.policy.copy(favoriteCount=count).canCreateFavorite(true).allowed}) { before ->
                            subscriptions.syncCounts(snapshot?.libraryRoutineCount ?: 0, before)
                            subscriptions.canCreateCustomExercise(true).allowed
                        }
                    }
                },
                onActivePinChange = { pin ->
                    val sid = snapshot?.activeSessionId
                    if (sid != null) runWorkoutAction { setActiveLocationPin(sid, pin) }
                },
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
                onSignOut = ::signOut,
                onDeleteAccount = ::deleteCurrentAccount,
                deletingAccount = deletingAccount,
                accountDeleteError = accountDeleteError,
                onDismissAccountDeleteError = { accountDeleteError = null }
            )
            // Hoja post-entreno (SessionReviewSheet iOS): se presenta una vez
            // al terminar una sesión con valoración verificable (I-45).
            pendingReview?.let { review ->
                SessionReviewSheet(
                    review = review,
                    onDismiss = { pendingReview = null; pendingReviewSessionId = null },
                )
            }
            if (subscriptions.paywall.isPresented) {
                // Página nativa de Repera Pro; no abre un bottom sheet.
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
        // Apple f6f13169: checkpoint GPS forzado antes de una posible suspension;
        // el sensor sigue activo en segundo plano (servicio foreground).
        LiveActivityRuntime.checkpointForBackground()
        super.onStop()
    }

    override fun onMessageReceived(event: MessageEvent) {
        // Apple 4a82b4b2/1d333b42/d350b42f: petición explícita del reloj -> plan de
        // HOY fresco del estado actual del teléfono (nunca caché viejo).
        if (event.path == "/repera/request-today-plan") {
            runOnUiThread {
                val id = profile?.uniqueId ?: return@runOnUiThread
                lifecycleScope.launch {
                    val plan = withContext(Dispatchers.IO) {
                        WorkoutRepository(this@MainActivity, id)
                            .todayPlanSession(professional = centerSnapshot?.trainingSessions.orEmpty())
                    }
                    if (profile?.uniqueId == id)
                        WearActiveSessionBridge.publishTodayPlan(this@MainActivity, plan)
                }
            }
            return
        }
        if (event.path == "/repera/session-finish") {
            val sessionId = runCatching {
                JSONObject(String(event.data, Charsets.UTF_8)).optString("sessionId")
            }.getOrNull().orEmpty()
            if (sessionId.isBlank()) return
            runOnUiThread {
                val signedIn = profile
                if (signedIn == null || verifiedSupabase == null || busy) return@runOnUiThread
                val revision=centerGate.revision
                fun current()=profile?.uniqueId==signedIn.uniqueId && centerGate.revision==revision
                busy=true
                lifecycleScope.launch {
                    try {
                    val finished = withContext(Dispatchers.IO) {
                        runCatching {
                            val repo=WorkoutRepository(this@MainActivity,signedIn.uniqueId)
                            if(repo.active()?.id==sessionId) {
                                StrengthRestService.cancel(this@MainActivity)
                                val route=locationTracker.stopRouteTracking()
                                if(!repo.finishWearSession(sessionId)) return@runCatching false
                                if(route.isNotEmpty()) repo.attachRoutePoints(sessionId,route)
                                true
                            } else repo.finishWearSession(sessionId)
                        }.getOrDefault(false)
                    }
                    if(!current()) return@launch
                    if(finished) {
                        val ack=JSONObject().put("sessionId",sessionId).put("status","saved").toString().toByteArray(Charsets.UTF_8)
                        wearMessages.sendMessage(event.sourceNodeId,"/repera/session-finish-ack",ack)
                        reloadFor(signedIn.uniqueId)
                        DriveSyncWorker.syncNow(this@MainActivity)
                        if(verifiedSupabase!=null) syncWorkoutMirror()
                        refineFinishedSessionWithHealth(sessionId)
                    }
                    } finally {if(current()) busy=false}
                }
            }
            return
        }
        if (event.path == "/repera/session-pause") {
            val command=WearPauseCommand.parse(event.data) ?: return
            runOnUiThread {
                if (command.targets(activeWorkout?.id,activeWorkout?.index) && activeWorkout?.wod != null && !busy) {
                    changeWodTimer(if (command.paused) "pause" else "start")
                    refreshWodTimer()
                }
            }
            return
        }
        if (event.path == "/repera/select-exercise") {
            val command=WearSelectCommand.parse(event.data) ?: return
            runOnUiThread {
                val active=activeWorkout
                if (!busy && command.targets(active?.id,active?.index,active?.total)) {
                    StrengthRestService.cancel(this)
                    runWorkoutAction { selectActiveExercise(command.toIndex) }
                }
            }
            return
        }
        if (event.path == "/repera/session-discard") {
            val payload = runCatching { JSONObject(String(event.data, Charsets.UTF_8)) }.getOrNull()
                ?: return
            runOnUiThread {
                if (busy) return@runOnUiThread
                val sessionId = payload.optString("sessionId")
                if (sessionId.isBlank() || activeWorkout?.id != sessionId) return@runOnUiThread
                StrengthRestService.cancel(this)
                locationTracker.stopRouteTracking()
                runWorkoutAction { discardActiveSession() }
            }
            return
        }
        if (event.path == "/repera/wod-score") {
            val payload = runCatching { JSONObject(String(event.data, Charsets.UTF_8)) }.getOrNull()
                ?: return
            runOnUiThread {
                if (busy) return@runOnUiThread
                val account = profile?.uniqueId ?: return@runOnUiThread
                val sessionId = payload.optString("sessionId")
                if (activeWorkout?.id != sessionId) return@runOnUiThread
                val rounds = if (payload.has("roundsCompleted") && !payload.isNull("roundsCompleted"))
                    payload.optInt("roundsCompleted") else null
                val reps = if (payload.has("totalReps") && !payload.isNull("totalReps"))
                    payload.optInt("totalReps") else null
                val elapsed = if (payload.has("elapsedSeconds") && !payload.isNull("elapsedSeconds"))
                    payload.optInt("elapsedSeconds") else null
                runWorkoutAction {
                    WorkoutRepository(this@MainActivity, account)
                        .recordWodScore(rounds, reps, elapsed)
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
            val interval = if (payload.has("intervalIndex") && !payload.isNull("intervalIndex"))
                payload.optInt("intervalIndex") else null
            val sessionPayload = payload.optJSONObject("session")
            val warmupFlag = payload.optBoolean("warmup", false)
            val kind = payload.optString("kind", "straight").ifBlank { "straight" }
                .let { if (warmupFlag) "straight" else it }
            val drops = mutableListOf<Pair<Int, Double?>>()
            payload.optJSONArray("drops")?.let { arr ->
                for (i in 0 until arr.length()) {
                    val d = arr.getJSONObject(i)
                    drops += d.getInt("reps") to
                        if (d.has("weightKg") && !d.isNull("weightKg")) d.getDouble("weightKg") else null
                }
            }
            val clusters = mutableListOf<Pair<Int, Int>>()
            payload.optJSONArray("clusters")?.let { arr ->
                for (i in 0 until arr.length()) {
                    val c = arr.getJSONObject(i)
                    clusters += c.getInt("reps") to c.getInt("restSeconds")
                }
            }
            if (sessionId.isBlank() || exerciseIndex < 0 || quantity !in 1..10000 ||
                (weight != null && (!weight.isFinite() || weight < 0)) ||
                (rir != null && (!rir.isFinite() || rir < 0 || rir > 5)) ||
                (duration != null && duration !in 1..86400) ||
                (deficit != null && deficit !in 0..100) ||
                (interval != null && interval !in 0..100000) ||
                kind !in setOf("straight", "dropset", "restpause") ||
                (kind == "dropset" && drops.size !in 1..5) ||
                (kind == "restpause" && clusters.isEmpty())) {
                sendWearAck(event.sourceNodeId, id, "rejected")
                return@runOnUiThread
            }
            val revision=centerGate.revision
            fun current()=profile?.uniqueId==signedIn.uniqueId && centerGate.revision==revision
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
                            deficitCm = deficit, intervalIndex = interval,
                            sessionPayload = sessionPayload,warmup=warmupFlag,toFailure=payload.optBoolean("toFailure",false),
                            kind = kind, drops = drops, clusters = clusters,
                            onNewSet={
                                if(current()) wearRest?.let { (name, seconds) ->
                                    StrengthRestService.start(this@MainActivity, name, dev.repera.domain.StrengthRestPolicy.seconds(seconds,warmupFlag,kind),snapshot?.trainingSettings?.restSoundEnabled ?: true,snapshot?.trainingSettings?.restHapticEnabled ?: true)
                                }
                            }
                        )
                    }
                    if(current()) reloadFor(signedIn.uniqueId)
                }
                if(!current()) return@launch
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
        val revision=centerGate.revision
        val authorized=accountWorkGuard(uniqueId,session.userId)
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                AITrainingInbox(stillAuthorized=authorized).sync(session, WorkoutRepository(this@MainActivity, uniqueId))
            }
            if(!authorized() || profile?.uniqueId!=uniqueId || centerGate.revision!=revision) return@launch
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

    private fun searchCenterDirectory(query:String) {
        val session=verifiedSupabase ?: return
        val revision=centerGate.revision
        val generation=++centerDirectoryGeneration
        centerDirectorySearching=true
        lifecycleScope.launch {
            val result=withContext(Dispatchers.IO) {runCatching {BusinessCenterStore().searchDirectory(session,query)}}
            if(!centerGate.accepts(session.userId,revision) || generation!=centerDirectoryGeneration) return@launch
            centerDirectory=result.getOrDefault(emptyList())
            centerDirectorySearching=false
            centerError=result.exceptionOrNull()?.let {
                if(it.message?.contains("PGRST202")==true || it.message?.contains("could not find",ignoreCase=true)==true)
                    "El directorio aún no está activo en el servidor. Vuelve a intentarlo en unos minutos."
                else "No se pudo buscar centros. Comprueba la conexión e inténtalo de nuevo."
            }
        }
    }

    private fun refreshCenter() {
        val session = verifiedSupabase ?: return
        if (centerLoading) return
        centerLoading = true
        val revision=centerGate.revision
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                BusinessCenterStore().refresh(session)
            }
            if(!centerGate.accepts(session.userId,revision)) return@launch
            when (result) {
                is BusinessCenterStore.LoadResult.Loaded -> {
                    centerSnapshot = result.snapshot
                    centerError = null
                    profile?.uniqueId?.let {id ->
                        val plan=withContext(Dispatchers.IO) {WorkoutRepository(this@MainActivity,id).todayPlanSession(professional=result.snapshot.trainingSessions)}
                        if(centerGate.accepts(session.userId,revision))
                            WearActiveSessionBridge.publishTodayPlan(this@MainActivity,plan)
                    }
                }
                is BusinessCenterStore.LoadResult.Failed -> {
                    centerSnapshot=null
                    centerError = result.message
                }
            }
            if(centerGate.accepts(session.userId,revision)) centerLoading = false
        }
    }

    private fun centerAction(
        action: BusinessCenterStore.(SupabaseIdentity.Session) -> Unit
    ) {
        val session = verifiedSupabase ?: return
        if (centerSubmitting) return
        centerSubmitting = true
        val revision=centerGate.revision
        lifecycleScope.launch {
            val failure=withContext(Dispatchers.IO) {
                runCatching {BusinessCenterStore().action(session)}.exceptionOrNull()
            }
            if(!centerGate.accepts(session.userId,revision)) return@launch
            centerError=failure?.localizedMessage
            centerSubmitting=false
            if(failure==null) refreshCenter()
        }
    }

    private fun restoreStoredSession() {
        val storedRevision=sessionStore.identityRevision()
        val stored = sessionStore.load() ?: return
        if (busy) return
        // Capturar revisión de identity ANTES del IO; la de centerGate DESPUÉS de
        // verifiedSupabase=session (su setter hace update(userId) null→userId y
        // sube revision). Si se captura antes, current() queda false y
        // prepareAccountDataAfterAuth es no-op (catálogo/plan/historial vacíos).
        fun identityCurrent()=sessionStore.identityRevision()==storedRevision
        busy = true
        restoringSession = true
        lifecycleScope.launch {
            var restoreRevision=centerGate.revision
            fun current()=identityCurrent() && centerGate.revision==restoreRevision
            try {
                val session = withContext(Dispatchers.IO) {
                    if (stored.expiresWithin(SESSION_REFRESH_MARGIN_SECONDS)) {
                        synchronized(sessionRefreshLock) { SupabaseIdentity().refresh(stored.refreshToken) }
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
                if(!identityCurrent()) return@launch
                check(sessionStore.saveIfCurrent(storedRevision,stored.uniqueId,stored.userId,
                    SessionStore.StoredSession(
                        uniqueId = stored.uniqueId,
                        email = stored.email,
                        displayName = stored.displayName,
                        userId = session.userId,
                        accessToken = session.accessToken,
                        refreshToken = session.refreshToken,
                        expiresAtEpochSeconds = session.expiresAtEpochSeconds
                    )
                )) {"La sesión cambió durante la restauración"}
                verifiedSupabase = session
                restoreRevision=centerGate.revision
                refreshCenter()
                profile = GoogleProfile(stored.uniqueId, stored.email, stored.displayName)
                DriveSyncWorker.schedulePeriodic(this@MainActivity)
                RemoteExerciseCatalogWorker.schedule(this@MainActivity)
                aiPlansRealtime.start()
                prepareAccountDataAfterAuth(stored.uniqueId) { current() }
            } catch (error: Exception) {
                if(!current()) return@launch
                if(!SupabaseAuthErrors.isUnrecoverable(error)) {
                    // Apple: red u otro fallo temporal NO es logout. Se conserva la sesión cifrada y los datos locales;
                    // la cuenta remota queda sin verificar hasta reintentar (onResume).
                    profile = GoogleProfile(stored.uniqueId, stored.email, stored.displayName)
                    status = "Sin conexión con la cuenta. Los entrenos continúan guardados localmente."
                    ensureLocalSeedIfMissing(stored.uniqueId) { current() }
                    reloadFor(stored.uniqueId)
                    return@launch
                }
                // Revoked refresh token or session confirmed by Supabase: back to the login screen.
                LiveActivityRuntime.stopAll()
                LiveActivityService.stop(this@MainActivity)
                sessionStore.clearIfCurrent(storedRevision,stored.uniqueId,stored.userId)
                PlannedWorkoutNotification.cancel(this@MainActivity)
                aiPlansRealtime.stop()
                verifiedSupabase = null; resetManualMirrorSync()
                clearAIAccessState()
                centerSnapshot = null
                centerError = null
                profile = null
            } finally {
                busy = false
                restoringSession = false
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
                // Google gets SHA-256(raw); Supabase gets raw (same as iOS GIDSignIn).
                val nonce = GoogleAuthNonce.generate()
                val option = GetSignInWithGoogleOption.Builder(
                    BuildConfig.GOOGLE_WEB_CLIENT_ID
                ).setNonce(nonce.hashedHex).build()
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
                    SupabaseIdentity().signInWithGoogle(google.idToken, nonce.raw)
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
                RemoteExerciseCatalogWorker.schedule(this@MainActivity)
                aiPlansRealtime.start()
                val signInRevision = centerGate.revision
                prepareAccountDataAfterAuth(id) { profile?.uniqueId == id && centerGate.revision == signInRevision }
                status = null
            } catch (error: Exception) {
                aiPlansRealtime.stop()
                verifiedSupabase = null; resetManualMirrorSync()
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

    /** Tras terminar una sesión: primero syncWorkoutToHealth iOS (escribe o
     *  vincula el registro propio de Salud con idempotencia; sin permiso el
     *  entreno queda intacto en local) y después refineSessionReviewWithHealth
     *  (relee FC/kcal SOLO con asociación confiable y afina la nota). Si la
     *  hoja de valoración sigue visible con esa sesión, la actualiza
     *  (presentIfPending iOS). */
    private fun refineFinishedSessionWithHealth(sessionId: String) {
        val signedIn = profile ?: return
        val revision=centerGate.revision
        fun current()=profile?.uniqueId==signedIn.uniqueId && centerGate.revision==revision
        val reader = HealthConnectReader(this)
        if (!reader.available()) return
        lifecycleScope.launch {
            withContext(Dispatchers.IO) {
                runCatching {
                    if(!current()) return@runCatching
                    val repo = WorkoutRepository(this@MainActivity, signedIn.uniqueId)
                    val info = repo.sessionTitleAndRange(sessionId) ?: return@runCatching
                    if(!current()) return@runCatching
                    val linked = HealthConnectWriter(this@MainActivity,stillAuthorized={current()})
                        .syncFinishedSession(sessionId, info.first,
                            info.second, info.third, repo.healthRecordId(sessionId),
                            HealthConnectWriter.exerciseTypeFor(repo.liveSportId(sessionId)?.let(dev.repera.domain.LiveSport::byId)),
                            repo.sessionRoutePoints(sessionId))
                    if (current() && linked != null && repo.healthRecordId(sessionId) == null) {
                        repo.setHealthRecordId(sessionId, linked)
                    }
                }
            }
            if(!current()) return@launch
            val updated = withContext(Dispatchers.IO) {
                runCatching {
                    if (!current() || !reader.hasPermissions()) return@runCatching null
                    val repo = WorkoutRepository(this@MainActivity, signedIn.uniqueId)
                    val range = repo.sessionTimeRange(sessionId) ?: return@runCatching null
                    val sample = reader.readSessionSample(range.first, range.second,
                        repo.healthRecordId(sessionId), sessionId)
                    if (!current() || !sample.hasUsableSignal) return@runCatching null
                    WorkoutRepository(this@MainActivity, signedIn.uniqueId)
                        .refineSessionReviewWithCardio(sessionId, sample)
                }.getOrNull()
            }
            if (!current()) return@launch
            if (updated != null) {
                if (pendingReviewSessionId == sessionId) pendingReview = updated
                reloadFor(signedIn.uniqueId)
            }
        }
    }

    private fun launchHealthPermissionsForCurrentAccount() {
        val owner=profile?.uniqueId ?: return
        val revision=centerGate.revision
        fun current()=profile?.uniqueId==owner && centerGate.revision==revision
        lifecycleScope.launch {
            try {
                val reader=HealthConnectReader(this@MainActivity)
                if(!reader.available()) {if(current()) status="Health Connect no está disponible";return@launch}
                val requested=reader.requestedPermissions()
                val granted=androidx.health.connect.client.HealthConnectClient.getOrCreate(this@MainActivity).permissionController.getGrantedPermissions()
                if(!current()) return@launch
                if(granted.containsAll(requested)) loadHealthToday()
                else {
                    if(pendingHealthRequest.begin(owner,revision)) requestHealthPermissions.launch(requested)
                }
            } catch(error:Exception) {
                if(current()) {pendingHealthRequest.clear();todayHealth=null;status="No se pudo conectar Salud: "+error.localizedMessage}
            }
        }
    }

    private fun connectHealth() {
        if(profile==null || busy) return
        launchHealthPermissionsForCurrentAccount()
    }

    private var healthFetchDaysLoaded = 0
    private var healthLoadInFlight = false
    private var healthFetchDaysPending = 0

    /** Apple 479d8407: ampliar la ventana de Salud solo cuando el rango de
     *  Progreso elegido necesita mas dias de los cargados (360d -> 730 con el
     *  periodo previo); nunca se relee para un rango menor. */
    private fun loadHealthForProgressRange(range: dev.repera.domain.ProgressTimeRange) {
        val widening = dev.repera.domain.ProgressTimeRange
            .healthFetchWidening(healthFetchDaysLoaded, range) ?: return
        loadHealthToday(widening)
    }

    /** Tras borrar/mutar entrenos: relee Salud y recarga overview (minutos Actividad). */
    private suspend fun refreshHealthSamplesAfterMutation(owner: String) {
        val revision = centerGate.revision
        fun current() = profile?.uniqueId == owner && centerGate.revision == revision
        if (!current()) return
        runCatching {
            val reader = HealthConnectReader(this)
            val today = withContext(Dispatchers.IO) { reader.readToday() }
            if (!current()) return
            val samples = withContext(Dispatchers.IO) {
                runCatching {
                    reader.readSamples(
                        maxOf(healthFetchDaysLoaded, 14),
                        HealthExclusionSnapshot.windows(LocalSnapshotStore(this@MainActivity, owner).read())
                    )
                }.getOrNull()
            }
            if (!current()) return
            todayHealth = today
            if (samples != null) healthSamples = samples
            reloadFor(owner)
        }
    }

    private fun loadHealthToday(fetchDays: Int = 370) {
        if (healthLoadInFlight) {
            // No perder una peticion de ventana mayor durante otra lectura:
            // se relanza al terminar con el perfil VIGENTE en ese momento.
            if (fetchDays > healthFetchDaysPending) healthFetchDaysPending = fetchDays
            return
        }
        healthLoadInFlight = true
        val owner=profile?.uniqueId ?: run { healthLoadInFlight = false; return }
        val revision=centerGate.revision
        val sleepAtStart=PrivateRecoverySettings(this).sleepEnabled()
        val cycleAtStart=PrivateRecoverySettings(this).cycleEnabled()
        val privateRevision=privateHealthRevision
        fun current()=profile?.uniqueId==owner && centerGate.revision==revision
        lifecycleScope.launch {
            try {
                val reader=HealthConnectReader(this@MainActivity)
                if(!current()) return@launch
                val today=withContext(Dispatchers.IO) {reader.readToday()}
                if(!current()) return@launch
                val samples=withContext(Dispatchers.IO) {runCatching {reader.readSamples(fetchDays,
                    HealthExclusionSnapshot.windows(LocalSnapshotStore(this@MainActivity,owner).read()))}.getOrNull()}
                if(!current()) return@launch
                // Solo actividades externas amplian la ventana (Apple 479d8407);
                // recovery mantiene su ventana propia de 370d.
                val recovery=withContext(Dispatchers.IO) {runCatching {reader.readRecovery(370)}.getOrNull()}
                if(!current()) return@launch
                todayHealth=today;healthSamples=samples
                val settings=PrivateRecoverySettings(this@MainActivity)
                recoveryRead=recovery?.copy(
                    nights=if(sleepAtStart && privateRevision==privateHealthRevision && settings.sleepEnabled()) recovery.nights else emptyList(),
                    vitals=recovery.vitals.map {if(sleepAtStart && privateRevision==privateHealthRevision && settings.sleepEnabled()) it else it.copy(wristTemperatureCelsius=null)},
                    menstrualDays=if(cycleAtStart && privateRevision==privateHealthRevision && settings.cycleEnabled()) recovery.menstrualDays else emptyList(),
                    positiveOvulationTests=if(cycleAtStart && privateRevision==privateHealthRevision && settings.cycleEnabled()) recovery.positiveOvulationTests else emptyList())
                withContext(Dispatchers.IO) {
                    runCatching {
                        val weights=reader.readBodyMass()
                        if(current()) {
                            val localOnly=WorkoutRepository(this@MainActivity,owner).mergeHealthBodyWeights(weights)
                            localOnly.forEach {(millis,kg) -> if(current()) runCatching {reader.saveBodyMass(kg,millis,owner,stillAuthorized={current()})}}
                        }
                    }
                }
                if(!current()) return@launch
                if (samples != null) healthFetchDaysLoaded = fetchDays
                reloadFor(owner);status=null
            } catch(error:Exception) {
                if(current()) {todayHealth=null;status="No se pudo leer Salud: "+error.localizedMessage}
            } finally {
                healthLoadInFlight = false
                val pending = healthFetchDaysPending
                healthFetchDaysPending = 0
                if (pending > healthFetchDaysLoaded) loadHealthToday(pending)
            }
        }
    }

    private fun authorizeDrive() {
        val signedIn = profile ?: return
        if (busy) return
        val owner=signedIn.uniqueId
        val revision=centerGate.revision
        fun current()=profile?.uniqueId==owner && centerGate.revision==revision
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
                if(!current()) return@addOnSuccessListener
                if (result.hasResolution()) {
                    val pending = result.pendingIntent
                    if (pending == null) {
                        busy = false
                        syncing = false
                        status = "Drive requiere consentimiento"
                    } else {
                        pendingDriveOwner=owner;pendingDriveRevision=revision
                        driveConsent.launch(IntentSenderRequest.Builder(pending.intentSender).build())
                    }
                } else {
                    val token = result.accessToken
                    if (token.isNullOrBlank()) {
                        busy = false
                        syncing = false
                        status = "No se recibió acceso a Drive"
                    } else syncWithDrive(token,owner,revision)
                }
            }
            .addOnFailureListener {
                if(!current()) return@addOnFailureListener
                busy = false
                syncing = false
                status = "No se pudo conectar Drive: " + it.localizedMessage
            }
    }

    private fun syncWithDrive(oneTimeToken: String,owner:String,revision:Long) {
        fun current()=profile?.uniqueId==owner && centerGate.revision==revision
        if(!current()) return
        syncing = true
        status = "Sincronizando…"
        lifecycleScope.launch {
            try {
                val result = withContext(Dispatchers.IO) {
                    check(current()) {"La cuenta cambió durante la autorización de Drive"}
                    val store = LocalSnapshotStore(this@MainActivity, owner)
                    val outcome = DriveSnapshotService(oneTimeToken, store, stillAuthorized={current()}).synchronize()
                    outcome to StateOverview.fromBytes(store.read(), healthSamples, recoveryRead)
                }
                if(!current()) return@launch
                reloadFor(owner)
                if(!current()) return@launch
                status = when (result.first) {
                    DriveSnapshotService.Outcome.Empty -> "Drive no tiene aún datos de Repera"
                    DriveSnapshotService.Outcome.Unchanged -> "Datos actualizados"
                    DriveSnapshotService.Outcome.Uploaded -> "Copia guardada en Google Drive"
                    DriveSnapshotService.Outcome.Downloaded -> "Datos recuperados de Google Drive"
                    DriveSnapshotService.Outcome.Conflict ->
                        "Copias distintas: no se han sobrescrito los datos"
                    DriveSnapshotService.Outcome.PreconditionFailed ->
                        "Drive cambió en otro dispositivo: vuelve a sincronizar"
                }
            } catch (error: Exception) {
                if(current()) status = "Sincronización incompleta: " + error.localizedMessage
            } finally {
                if(current()) {busy = false;syncing = false}
            }
        }
    }

    /** iOS ReperaStore seed + RemoteExerciseCatalogStore.refresh on first connect. */
    private suspend fun ensureLocalSeedIfMissing(accountId: String, current: () -> Boolean) {
        withContext(Dispatchers.IO) {
            if (!current()) return@withContext
            if (LocalSnapshotStore(this@MainActivity, accountId).read() == null) {
                CatalogBootstrap.initializeEmptyAccount(this@MainActivity, accountId)
            }
        }
    }

    /** Copia el nombre de Google a settings.profileDisplayName si aún no hay (SettingsView iOS). */
    private fun seedDisplayNameFromGoogle(accountId: String) {
        val googleName = profile?.displayName?.trim()?.takeIf { it.isNotEmpty() } ?: return
        runCatching {
            val store = LocalSnapshotStore(this, accountId)
            val bytes = store.read() ?: return
            val state = org.json.JSONObject(String(bytes, Charsets.UTF_8))
            val settings = state.optJSONObject("settings") ?: org.json.JSONObject().also {
                state.put("settings", it)
            }
            if (settings.optString("profileDisplayName").isBlank()) {
                settings.put("profileDisplayName", googleName)
                check(store.replaceIfUnchanged(bytes, state.toString().toByteArray(Charsets.UTF_8)))
            }
        }
    }

    /**
     * Tras Google/Supabase verificado (login o restoreStoredSession): sembrar JSON local si falta,
     * descargar catálogo editorial, hidratar UI y luego espejos Supabase (BusinessWorkoutSyncStore).
     * Errores de seed/catálogo se muestran (no se tragan en silencio).
     */
    private suspend fun prepareAccountDataAfterAuth(accountId: String, current: () -> Boolean) {
        var seedError: String? = null
        var catalogError: String? = null
        withContext(Dispatchers.IO) {
            runCatching { ensureLocalSeedIfMissing(accountId, current) }
                .onFailure { seedError = it.localizedMessage ?: "No se pudo preparar el catálogo local" }
            if (!current()) return@withContext
            if (seedError == null) seedDisplayNameFromGoogle(accountId)
            if (!current()) return@withContext
            val (token, rotated) = refreshedSessionBlocking(accountId) { current() }
            if (rotated != null) {
                withContext(Dispatchers.Main) {
                    if (current()) verifiedSupabase = rotated
                }
            }
            if (!current()) return@withContext
            val feed = RemoteExerciseCatalog(this@MainActivity)
            runCatching { feed.refresh(token) }
                .onFailure { catalogError = it.localizedMessage ?: "No se pudo actualizar el catálogo" }
            runCatching { feed.applyToAccount(accountId) }
                .onFailure {
                    if (catalogError == null) {
                        catalogError = it.localizedMessage ?: "No se pudo aplicar el catálogo"
                    }
                }
        }
        if (!current()) return
        reloadFor(accountId)
        if (!current()) return
        when {
            seedError != null -> status = "Catálogo: $seedError"
            catalogError != null && (snapshot?.exercises ?: 0) == 0 ->
                status = "Catálogo: $catalogError"
            else -> if (status?.startsWith("Catálogo:") == true) status = null
        }
        syncPublicProfileFromSettings()
        syncSupabaseMirrors()
    }

    /** SettingsView.onSubmit / foto: perfil público Supabase (BusinessAuthStore.syncPublicProfile). */
    private fun persistProfileSettings(value: ProfileSettings) {
        val avatar = value.avatarJPEG?.let {
            runCatching { android.util.Base64.decode(it, android.util.Base64.DEFAULT) }.getOrNull()
        }
        runWorkoutAction { updateProfile(value) }
        syncPublicProfileFromSettings(value.displayName ?: profile?.displayName, avatar)
    }

    private fun syncPublicProfileFromSettings(
        displayName: String? = snapshot?.profileSettings?.displayName ?: profile?.displayName,
        avatarJpeg: ByteArray? = snapshot?.profileSettings?.avatarJPEG?.let {
            runCatching { android.util.Base64.decode(it, android.util.Base64.DEFAULT) }.getOrNull()
        }
    ) {
        val session = verifiedSupabase ?: return
        val uniqueId = profile?.uniqueId ?: return
        val authorized = accountWorkGuard(uniqueId, session.userId)
        lifecycleScope.launch {
            withContext(Dispatchers.IO) {
                runCatching {
                    val refreshed = refreshedSessionBlocking(uniqueId) { authorized() }
                    val active = refreshed.second?.also {
                        withContext(Dispatchers.Main) { if (authorized()) verifiedSupabase = it }
                    } ?: session
                    PublicProfileSync(stillAuthorized = authorized).sync(active, displayName, avatarJpeg)
                }
            }
        }
    }

    /** Apple requestExerciseCatalogRefresh (11ea29a6): refresco del catálogo
     * disparado por acciones del usuario (entrar en Ejercicios, abrir Apuntar,
     * guardar un entrenamiento). Nunca durante una sesión en curso; el propio
     * refresco amortigua 60 s y es silencioso. */
    private fun requestExerciseCatalogRefresh() {
        val user = profile ?: return
        if (verifiedSupabase == null || activeWorkout != null) return
        refreshCatalogSilently(user.uniqueId)
    }

    /** Silent background check when the app becomes active. Only publish UI changes
     * after a complete cache download and atomic private-state reconciliation. */
    private fun refreshCatalogSilently(accountId: String) {
        val accountRevision=centerGate.revision
        fun currentAccount()=profile?.uniqueId==accountId && centerGate.revision==accountRevision
        val now = System.currentTimeMillis()
        if (catalogRefreshRunning || now - lastCatalogCheckAt < 60_000L) return
        if (profile?.uniqueId != accountId) return
        lastCatalogCheckAt = now
        catalogRefreshRunning = true
        lifecycleScope.launch {
            try {
                // The foreground may refresh an expired encrypted session without
                // presenting an interactive Google prompt. Headless workers never do.
                val (token, rotatedSession) = withContext(Dispatchers.IO) {
                    refreshedSessionBlocking(accountId) { currentAccount() }
                }
                if (rotatedSession != null && currentAccount()) {
                    verifiedSupabase = rotatedSession
                }
                val changed = withContext(Dispatchers.IO) {
                    check(currentAccount()) {"La cuenta cambió durante la lectura del catálogo"}
                    val feed = RemoteExerciseCatalog(this@MainActivity)
                    val updated = feed.refresh(token)
                    if (updated && currentAccount()) {
                        // Incoming events are already durable in the feed cache.
                        feed.applyToAccount(accountId)
                    } else false
                }
                if (changed && currentAccount()) {
                    reloadFor(accountId)
                    DriveSyncWorker.syncNow(this@MainActivity)
                }
            } catch (_: Exception) {
                // Unavailable network/auth leaves the previous cache intact.
            } finally {
                catalogRefreshRunning = false
            }
        }
    }

    private suspend fun reloadFor(id: String) {
        val revision=centerGate.revision
        fun current()=profile?.uniqueId==id && centerGate.revision==revision
        if(!current()) return
        val (overview, active, bytes) = withContext(Dispatchers.IO) {
            val store = LocalSnapshotStore(this@MainActivity, id)
            MobilityCatalogMigration.ensure(this@MainActivity, id)
            CatalogRefreshMigration.ensure(this@MainActivity, id)
            RemoteExerciseCatalog(this@MainActivity).applyToAccount(id)
            val repository = WorkoutRepository(this@MainActivity, id)
            // Artefactos de altas one-off interrumpidas (proceso muerto antes de
            // Guardar): iOS nunca persiste rutinas con todos los bloques vacíos.
            // Recalcula notas persistidas si subió la fórmula (iOS v11).
            runCatching { repository.refreshSessionReviewsIfNeeded() }
            val bytes = store.read()
            Triple(StateOverview.fromBytes(bytes, healthSamples, recoveryRead), repository.active(), bytes)
        }
        if(!current()) return
        // Valoración pendiente tras terminar sesión (pendingSessionReview iOS).
        val review=withContext(Dispatchers.IO) {
            WorkoutRepository(this@MainActivity, id).consumePendingReview()
        }
        if(!current()) return
        review?.let { pendingReviewSessionId = it.first; pendingReview = it.second }
        snapshot = overview
        // Contadores que alimentan la política de límites Gratis (iOS:
        // SubscriptionManager.syncCounts). Rutinas guardadas y ejercicios
        // propios (isCustom) del estado real.
        overview?.let {
            subscriptions.syncCounts(
                libraryRoutines = it.libraryRoutineCount,
                customExercises = it.exerciseEntries.count { e -> e.isCustom },
                // Paridad iOS favoriteCount: rutinas ★ + actividades Comenzar.
                favorites = it.routineEntries.count { r -> r.isFavorite } +
                    it.favoriteSportActivities.size
            )
        }
        activeWorkout = active
        bytes?.let {runCatching {PlannedWorkoutNotification.refresh(this@MainActivity,id,org.json.JSONObject(String(it,Charsets.UTF_8)))}}
        refreshWodTimer()
        resumeDeferredMirrorSyncIfNeeded()
        // Local persistence is the source of truth. A missing/disconnected watch
        // must not make a saved training action appear to have failed.
        withContext(Dispatchers.IO) {
            if(!current()) return@withContext
            runCatching { WearActiveSessionBridge.publish(this@MainActivity, bytes) }
            runCatching {
                val plan = WorkoutRepository(this@MainActivity, id).todayPlanSession(professional=centerSnapshot?.trainingSessions.orEmpty())
                if(current()) WearActiveSessionBridge.publishTodayPlan(this@MainActivity, plan)
            }
        }
    }

    private fun refreshWodTimer() {
        val user = profile?.uniqueId
        val active = activeWorkout
        wodTimer = if (user != null && active?.wod != null)
            WodTimerStore(this, user).read(active.id, active.index,
                active.navigationEntries.firstOrNull { it.index == active.index }?.blockId)
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
            val store = WodTimerStore(this, user)
            val blockId = active.navigationEntries.firstOrNull { it.index == active.index }?.blockId
            wodTimer = store.update(active.id, active.index, action, blockId)
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
        val revision=centerGate.revision
        fun current()=profile?.uniqueId==signedIn.uniqueId && centerGate.revision==revision
        lifecycleScope.launch {
            withContext(Dispatchers.IO) {
                if(!current()) return@withContext
                val repo = WorkoutRepository(this@MainActivity, signedIn.uniqueId)
                val info = repo.activeSessionOutdoorInfo() ?: return@withContext
                val pin = locationTracker.capturePin()
                if(!current()) return@withContext
                if (pin != null) repo.attachLocationPin(info.sessionId, pin)
                if (locationTracker.shouldTrackRoute(info.title, info.exerciseNames)) {
                    locationTracker.startRouteTracking(info.sessionId)
                }
            }
        }
    }

    private fun overviewForTemplateRetry(requestId:String):Boolean {
        val owner=profile?.uniqueId ?: return false
        return runCatching {WorkoutRepository(this,owner).routinesSnapshot().any {it.optString("id")==requestId}}.getOrDefault(false)
    }

    /** UI entry gates are repeated at the owner of persistence, never grant Pro locally. */
    private fun permitNewTemplate(isNew:Boolean=true):Boolean {
        if(subscriptions.canCreateLibraryRoutine(isNew).allowed) return true
        subscriptions.presentPaywall(dev.repera.domain.monetization.PaywallContext.ROUTINES_LIMIT,
            feature=dev.repera.domain.monetization.ReperaFeature.UNLIMITED_ROUTINES)
        return false
    }

    private class PendingLive(val sessionId: String, val index: Int, val rows: List<ActiveSessionDraft.Row>, val unit: String?)
    private val pendingLiveRef = java.util.concurrent.atomic.AtomicReference<PendingLive?>(null)
    private val liveRowsLock = kotlinx.coroutines.sync.Mutex()

    /** Editable Play rows (Apple persistActiveLiveDraft). The newest rows are held in memory immediately, so no edit can be
     *  lost; they are saved ~600 ms later, or earlier by any other workout action (runWorkoutAction takes them first).
     *  Does not take the `busy` lock, so typing keeps focus. */
    private fun persistLiveRowsNow(sessionId: String, index: Int, rows: List<ActiveSessionDraft.Row>, unit: String?) {
        val signedIn = profile ?: return
        pendingLiveRef.set(PendingLive(sessionId, index, rows, unit))
        val revision = centerGate.revision
        val durable = SessionStore(this)
        val identityRevision = durable.identityRevision()
        fun current() = profile?.uniqueId == signedIn.uniqueId && centerGate.revision == revision &&
            durable.identityRevision() == identityRevision
        lifecycleScope.launch {
            kotlinx.coroutines.delay(600)
            liveRowsLock.withLock {
                var waited = 0
                while (busy && waited < 50) { kotlinx.coroutines.delay(100); waited++ }
                val pending = pendingLiveRef.getAndSet(null) ?: return@withLock
                try {
                    withContext(Dispatchers.IO) {
                        check(current()) { "La cuenta cambió antes de guardar las series" }
                        WorkoutRepository(this@MainActivity, signedIn.uniqueId, stillAuthorized = { current() })
                            .persistLiveRows(pending.sessionId, pending.index, pending.rows, pending.unit)
                    }
                    if (!current()) return@withLock
                    reloadFor(signedIn.uniqueId)
                    if (!current()) return@withLock
                    DriveSyncWorker.syncNow(this@MainActivity)
                } catch (error: Exception) {
                    if (current()) status = error.localizedMessage ?: "No se pudieron guardar las series"
                }
            }
        }
    }

    private fun runWorkoutAction(onSuccess: (() -> Unit)? = null,
                                 action: WorkoutRepository.() -> Unit) {
        val signedIn = profile ?: return
        if (busy) return
        val revision=centerGate.revision
        val durable=SessionStore(this)
        val identityRevision=durable.identityRevision()
        fun current()=profile?.uniqueId==signedIn.uniqueId && centerGate.revision==revision &&
            durable.identityRevision()==identityRevision
        busy = true
        lifecycleScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    check(current()) {"La cuenta cambió antes de iniciar la acción"}
                    val repository = WorkoutRepository(this@MainActivity, signedIn.uniqueId,stillAuthorized={current()})
                    // Editable Play rows still waiting for their debounce are saved first, so an action never loses them.
                    pendingLiveRef.getAndSet(null)?.let { repository.persistLiveRows(it.sessionId, it.index, it.rows, it.unit) }
                    repository.action()
                }
                if(!current()) return@launch
                reloadFor(signedIn.uniqueId)
                if(!current()) return@launch
                // Apple 11ea29a6: guardar un entrenamiento dispara refresco del catálogo.
                requestExerciseCatalogRefresh()
                DriveSyncWorker.syncNow(this@MainActivity)
                if (verifiedSupabase != null) syncWorkoutMirror()
                status = null
                onSuccess?.invoke()
            } catch (error: Exception) {
                if(current()) status = error.localizedMessage ?: "No se pudo guardar el entrenamiento"
            } finally {
                if(current()) busy = false
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

    private var deletingAccount by mutableStateOf(false)
    private var accountDeleteError by mutableStateOf<String?>(null)

    /**
     * Paridad iOS `deleteCurrentAccount`: preflight → purge local/Drive →
     * delete Edge → vaciar UI. El JWT personal identifica al usuario; nunca
     * se envía un UUID aportado por la app.
     */
    private fun deleteCurrentAccount() {
        if (busy || deletingAccount) return
        val signedIn = profile ?: return
        val session = verifiedSupabase
        if (session == null || session.accessToken.isBlank()) {
            accountDeleteError =
                "Necesitas iniciar sesión y tener conexión para eliminar la cuenta."
            return
        }
        deletingAccount = true
        busy = true
        accountDeleteError = null
        lifecycleScope.launch {
            val owner = signedIn.uniqueId
            val deletedOwnerId = session.userId
            val store = LocalSnapshotStore(this@MainActivity, owner)
            val backup = withContext(Dispatchers.IO) { store.read() }
            try {
                withContext(Dispatchers.IO) {
                    val state = backup?.let { org.json.JSONObject(String(it, Charsets.UTF_8)) }
                    AccountDeletionCoordinator.assertNoActiveSession(state)
                }
                val client = AccountDeletionClient()
                client.request("preflight", session.accessToken)
                // Best-effort Drive trash (no bloquea si falla el consentimiento).
                withContext(Dispatchers.IO) {
                    runCatching {
                        val builder = AuthorizationRequest.builder()
                            .setRequestedScopes(
                                listOf(Scope("https://www.googleapis.com/auth/drive.appdata"))
                            )
                        if (signedIn.email.isNotBlank()) {
                            builder.setAccount(Account(signedIn.email, "com.google"))
                        }
                        val auth = com.google.android.gms.tasks.Tasks.await(
                            Identity.getAuthorizationClient(this@MainActivity)
                                .authorize(builder.build())
                        )
                        val token = auth.accessToken
                        if (!token.isNullOrBlank() && !auth.hasResolution()) {
                            DriveSnapshotService(token, store).trashAppDataSnapshot()
                        }
                    }
                }
                withContext(Dispatchers.IO) {
                    store.write(
                        AccountDeletionCoordinator.emptyShellState()
                            .toString().toByteArray(Charsets.UTF_8)
                    )
                }
                try {
                    client.request("delete", session.accessToken)
                } catch (error: Exception) {
                    withContext(Dispatchers.IO) {
                        if (backup != null) store.write(backup)
                    }
                    throw error
                }
                AccountDeletionCoordinator.clearAccountPreferences(
                    this@MainActivity, deletedOwnerId
                )
                withContext(Dispatchers.IO) {
                    AccountDeletionCoordinator.wipeLocalUserFolder(
                        this@MainActivity, owner
                    )
                }
                // Mantener deletingAccount=true hasta que signOut() lo limpie
                // en finally: si no, `if (busy && !deletingAccount) return`
                // aborta el cierre de sesión con busy aún true.
                signOut()
            } catch (error: AccountDeletionClient.AccountDeletionException) {
                accountDeleteError = error.message
                deletingAccount = false
                busy = false
            } catch (error: Exception) {
                accountDeleteError =
                    "No se ha completado la eliminación. Comprueba que tengas conexión y vuelve a intentarlo."
                deletingAccount = false
                busy = false
            }
        }
    }

    private fun signOut() {
        if (busy && !deletingAccount) return
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
                verifiedSupabase = null; resetManualMirrorSync()
                clearAIAccessState()
                sessionStore.clear()
                PlannedWorkoutNotification.cancel(this@MainActivity)
                RemoteExerciseCatalogWorker.cancel(this@MainActivity)
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
                deletingAccount = false
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
    val recentAverageSleepHours: Double?,
    val nights:List<dev.repera.domain.RecoverySleepNight> = emptyList(),
    val vitals:List<dev.repera.domain.RecoveryEngine.DailyVitals> = emptyList(),
    val menstrualDays:List<java.time.LocalDate> = emptyList(),
    val positiveOvulationTests:List<java.time.LocalDate> = emptyList(),
    val trend:List<dev.repera.domain.ProgressDayPoint> = emptyList()
)

data class StateOverview(
    val workouts: Int,
    val workoutsThisWeek: Int,
    val routines: Int,
    val exercises: Int,
    val bodyWeights: Int,
    val activeSessionTitle: String?,
    val activeSessionId: String? = null,
    val activeLocationPin: dev.repera.domain.WorkoutLocationPin? = null,
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
    val favoriteSportActivities: List<FavoriteSportActivity> = emptyList(),
    val chartsByRange: Map<String, dev.repera.domain.ProgressPreparedCharts> = emptyMap(),
    /** Archivo completo, no la ventana de 20 registros recientes. */
    val liveSportSessions: List<dev.repera.domain.LiveSportHistory.LiveSession> = emptyList(),
    val completeHistory: List<WorkoutHistoryEntry> = emptyList(),
    internal val trainingSettings:TrainingSettings = TrainingSettings(),
    internal val rotationPlan:dev.repera.domain.RotationPlan? = null,
    val healthGoals:HealthGoals=HealthGoals(),
    val profileSettings:ProfileSettings=ProfileSettings(),
    val dayWorkoutMinutes:Map<java.time.LocalDate,Double> = emptyMap(),
    /** PRs reales por sesión (no prescritos; primer registro ≠ PR). */
    val prCountBySessionId: Map<String, Int> = emptyMap(),
    val dayWorkoutCounts:Map<java.time.LocalDate,Int> = emptyMap(),
    val dayEnergyKcal:Map<java.time.LocalDate,Double> = emptyMap(),
    val bodyWeightHistory:List<BodyWeightHistoryEntry> = emptyList(),
    val testedOneRMByExercise:Map<String,Double> = emptyMap(),
    val externalHealthHistory:List<ExternalHealthHistoryEntry> = emptyList(),
    val sessionScoresByRange:Map<String,List<dev.repera.domain.ProgressDayPoint>> = emptyMap(),
    val wodTemplateFavorites:Set<String> = emptySet(),
    internal val wodLibraryHistory:Map<String,List<WodLibraryResult>> = emptyMap()
) {
    /** Apple counts all undated templates, including recurring assignments, not one-offs. */
    val libraryRoutineCount:Int get()=routineEntries.count {it.scheduledDate==null}

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
            val trainingSettings=TrainingSettings.read(json)
            val monday = dev.repera.domain.StatsEngine.startOfWeek(today,trainingSettings.weekStartsOnMonday)
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
                        weeklyDayTotals[java.time.temporal.ChronoUnit.DAYS.between(monday,date).toInt()] += 1
                    }
                }
                total
            }
            val history = json.getJSONArray("workouts").let { archive ->
                (archive.length() - 1 downTo 0).map { index ->
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
                        locationPin = pinFromJson(session.optJSONObject("locationPin")),
                        startedAtIso = session.optString("startedAt").takeIf { it.isNotBlank() },
                        finishedAtIso = session.optString("finishedAt").takeIf { it.isNotBlank() },
                        notes = session.optString("notes").takeIf { it.isNotBlank() },
                        liveSportID = session.optString("liveSportID").takeIf { it.isNotBlank() && it != "null" },
                        activeDurationSeconds = session.optDouble("activeDurationSeconds",Double.NaN).takeIf { it.isFinite() && it >= 0 },
                        recordedDistanceMeters = session.optDouble("recordedDistanceMeters",Double.NaN).takeIf { it.isFinite() && it >= 0 },
                        routineId = session.optString("routineId").takeIf { it.isNotBlank() && it != "null" },
                        timerDetails = dev.repera.domain.TimerCompletionDetails.fromSession(session),
                        liveKilometerSplitsSeconds = session.optJSONArray("liveKilometerSplitsSeconds")?.let { a ->
                            (0 until a.length()).map { a.optDouble(it) }.filter { it.isFinite() && it > 0 }
                        }.orEmpty(),
                        editableBlocksJson = runCatching {
                            if (dev.repera.domain.TimerCompletionDetails.fromSession(session) != null) null
                            else CompletedWorkoutEditing.blocksFrom(session, null).toString()
                        }.getOrNull(),
                        scoreSessionJson = runCatching {
                            val slim = org.json.JSONObject().put("wodResults", session.optJSONArray("wodResults") ?: org.json.JSONArray())
                            val ex = session.optJSONArray("exercises") ?: org.json.JSONArray()
                            val exs = org.json.JSONArray()
                            for (i in 0 until ex.length()) ex.getJSONObject(i).let { e ->
                                exs.put(org.json.JSONObject().put("blockId", e.optString("blockId"))
                                    .put("loggedSets", e.optJSONArray("loggedSets") ?: org.json.JSONArray()))
                            }
                            slim.put("exercises", exs).toString()
                        }.getOrNull(),
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
                                            .takeIf { !it.isNaN() },
                                        horizontalAccuracyMeters = point.optDouble("horizontalAccuracyMeters", Double.NaN).takeIf { it.isFinite() },
                                        verticalAccuracyMeters = point.optDouble("verticalAccuracyMeters", Double.NaN).takeIf { it.isFinite() },
                                        isEstimated = if (point.has("isEstimated")) point.optBoolean("isEstimated") else null
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
                                            id = ex.optString("id").ifBlank { null },
                                            sourceJson = ex.toString(),
                                            exerciseId = ex.getString("exerciseId"),
                                            name = "",
                                            quantity = first?.optInt("targetReps")
                                                ?.takeIf { it > 0 } ?: 8,
                                            sets = planned?.length() ?: 1,
                                            weightKg = if (first?.has("targetWeightKg") == true)
                                                first.getDouble("targetWeightKg") else null,
                                            quantityUnit = ex.optString("quantityUnit").ifBlank { null },
                                            plannedSets = planned?.let { arr ->
                                                (0 until arr.length()).map { si ->
                                                    val ps = arr.getJSONObject(si)
                                                    PlannedSetDraft(
                                                        id = ps.optString("id").ifBlank { null },
                                                        targetReps = ps.optInt("targetReps", 8),
                                                        targetWeightKg = if (ps.has("targetWeightKg") &&
                                                            !ps.isNull("targetWeightKg"))
                                                            ps.getDouble("targetWeightKg") else null,
                                                        targetRir = if (ps.has("targetRir") &&
                                                            !ps.isNull("targetRir"))
                                                            ps.getDouble("targetRir") else null,
                                                        targetDurationSeconds=if(ps.has("targetDurationSeconds") && !ps.isNull("targetDurationSeconds")) ps.getInt("targetDurationSeconds") else null,
                                                        sourceJson=EditorBlockOps.plannedSetUnknownFields(ps)
                                                    )
                                                }
                                            }
                                        )
                                    }
                                }.orEmpty()
                            } else {
                                block.optJSONArray("movements")?.let { mv ->
                                    (0 until mv.length()).map { mi ->
                                        val m = mv.getJSONObject(mi)
                                        RoutineBlockEntryInfo(
                                            id = m.optString("id").ifBlank { null },
                                            sourceJson = m.toString(),
                                            exerciseId = m.optString("exerciseId"),
                                            name = m.optString("name"),
                                            quantity = when {
                                                m.has("reps") -> m.getInt("reps")
                                                m.has("calories") -> m.getInt("calories")
                                                m.has("distanceMeters") -> m.getInt("distanceMeters")
                                                else -> 1
                                            },
                                            weightKg = m.optDouble("weightMaleKg").takeIf { m.has("weightMaleKg") },
                                            quantityUnit = m.optString("quantityUnit").ifBlank { null }
                                                ?: if (m.has("distanceMeters")) "meters"
                                                else if (m.has("calories")) "calories" else null
                                        )
                                    }
                                }.orEmpty()
                            }
                            val scheme = block.optJSONArray("movements")?.optJSONObject(0)
                                ?.optJSONArray("repScheme")
                                ?.let { s -> (0 until s.length()).map { s.getInt(it) } }
                            RoutineBlockInfo(
                                id = block.optString("id").ifBlank { null },
                                sourceJson = block.toString(),
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
                        isFavorite = item.optBoolean("isFavorite", false),
                        locationPin = pinFromJson(item.optJSONObject("locationPin"))
                    )
                }
            }
            val exerciseEntries = json.getJSONArray("exercises").let { array ->
                (0 until array.length()).filterNot { n ->
                    array.getJSONObject(n).optBoolean("isCatalogArchived", false)
                }.map { n ->
                    val ex = array.getJSONObject(n)
                    val sportTag = ex.optJsonString("sportTag")
                    val muscleGroup = ex.optJsonString("muscleGroup").orEmpty()
                    val equipment = ex.optJsonString("equipment").orEmpty()
                    val targetMuscle = ex.optJsonString("targetMuscle").orEmpty()
                    val mode = ExerciseInput.mode(
                        ex.getString("name"),
                        equipment,
                        targetMuscle,
                        muscleGroup,
                        sportTag
                    )
                    ExerciseEntry(ex.getString("id"), ex.getString("name"),
                        mode.basicRecorderAvailable, mode.showsWeight,
                        muscleGroup = muscleGroup,
                        sportTag = sportTag,
                        hyroxTraining = ExerciseCatalogFilters.isHyroxTrainingMovement(
                            ex.getString("name")),
                        disciplineTags = dev.repera.domain.ExerciseDisciplineTags.forExercise(
                            ex.getString("name"),
                            sportTag,
                            muscleGroup,
                            ExerciseCatalogFilters.isHyroxTrainingMovement(ex.getString("name"))),
                        loggingStyle = when (mode) {
                            dev.repera.domain.ExerciseInputMode.MACHINE_WORK -> "machineWork"
                            dev.repera.domain.ExerciseInputMode.REPS_AND_TIME -> "repsAndTime"
                            else -> "strength"
                        },
                        equipment = equipment,
                        targetMuscle = targetMuscle,
                        secondaryMuscles = ex.optJSONArray("secondaryMuscles")?.let { arr ->
                            (0 until arr.length()).map { arr.getString(it) }
                        }.orEmpty(),
                        searchAliases = PublishedCatalogAliases.read(ex),
                        isCatalogArchived = ex.optBoolean("isCatalogArchived"),
                        isFavorite = ex.optBoolean("isFavorite", false),
                        detailDescription = ex.optString("detailDescription")
                            .takeIf { it.isNotBlank() && it != "null" },
                        instructions = ex.optJSONArray("instructions")?.let { arr ->
                            (0 until arr.length()).map { arr.getString(it) }
                        }.orEmpty(),
                        isCustom = ex.optBoolean("isCustom"),
                        mobilityHold = sportTag == "Movilidad" &&
                            ex.optJsonString("catalogId") in setOf(
                                "mobility-14", "mobility-15", "mobility-16", "mobility-20",
                                "mobility-21", "mobility-30", "mobility-31", "mobility-32",
                                "mobility-36", "mobility-38", "mobility-39", "mobility-40",
                                "mobility-41", "mobility-42", "mobility-44", "mobility-46",
                                "mobility-60", "mobility-61", "mobility-62", "mobility-67",
                                "mobility-70", "mobility-80"
                            ))
                }.sortedBy { it.name }
            }
            val recoveryState = recovery?.let { rec ->
                val stats = ProgressSnapshotBuilder.statsWorkouts(json)
                val lastNight = dev.repera.domain.RecoverySleepSummary.lastNight(rec.nights, java.time.Instant.now(),java.time.ZoneId.systemDefault())
                val recentNights = rec.nights.takeLast(14)
                val avg = if (recentNights.isEmpty()) null
                    else recentNights.map { it.hours }.average()
                val observed = health?.externalHistory?.map {
                    dev.repera.domain.RecoveryEngine.ObservedActivity(
                        epochMillis=it.endMillis,durationMinutes=it.minutes,
                        isCardio=health.externalActivities.firstOrNull {activity ->activity.epochMillis==it.startMillis}?.let {activity ->dev.repera.domain.HealthMuscleMapper.isCardio(activity.type)} ?: false)
                } ?: emptyList()
                RecoveryState(
                    readiness = if(lastNight?.day==java.time.LocalDate.now()) dev.repera.domain.RecoveryEngine.trainingReadiness(
                        nowMillis = System.currentTimeMillis(),
                        sleepHours = lastNight?.hours,
                        recentAverageSleepHours = avg,
                        workouts = stats,
                        vitalHistory = rec.vitals,
                        observedActivities = observed) else null,
                    sleepIndex = dev.repera.domain.RecoveryEngine.sleepIndex(
                        lastNight?.hours, avg),
                    lastNightHours = lastNight?.hours,
                    recentAverageSleepHours = avg,
                    nights=rec.nights,vitals=rec.vitals,menstrualDays=rec.menstrualDays,positiveOvulationTests=rec.positiveOvulationTests,
                    trend=RecoveryTrend.points(rec.nights,rec.vitals,stats,observed,java.time.Instant.now(),java.time.ZoneId.systemDefault())
                )
            }
            val archiveForMinutes=json.optJSONArray("workouts") ?: org.json.JSONArray()
            val localStats=(0 until archiveForMinutes.length()).flatMap {i ->
                val session=archiveForMinutes.getJSONObject(i)
                val one=org.json.JSONObject().put("workouts",org.json.JSONArray().put(session))
                ProgressSnapshotBuilder.statsWorkouts(one).filter {it.finished}.map {s ->
                    val linked=session.optString(dev.repera.domain.HealthSessionLink.SNAPSHOT_FIELD)
                    s.copy(durationMinutes=HealthWorkoutMinutes.resolve(s.durationMinutes,health?.verifiedWorkoutMinutes?.get(linked)))
                }
            }
            val zone=java.time.ZoneId.systemDefault()
            val minutesByDay=mutableMapOf<java.time.LocalDate,Double>()
            val countsByDay=mutableMapOf<java.time.LocalDate,Int>()
            localStats.forEach {s -> val day=java.time.Instant.ofEpochMilli(s.epochMillis).atZone(zone).toLocalDate()
                minutesByDay[day]=(minutesByDay[day] ?: 0.0)+s.durationMinutes
                countsByDay[day]=(countsByDay[day] ?: 0)+1}
            health?.externalActivities.orEmpty().forEach {s ->val day=java.time.Instant.ofEpochMilli(s.epochMillis).atZone(zone).toLocalDate()
                minutesByDay[day]=(minutesByDay[day] ?: 0.0)+s.durationMinutes
                countsByDay[day]=(countsByDay[day] ?: 0)+1}
            return StateOverview(wodLibraryHistory=WodLibraryHistory.read(json),wodTemplateFavorites=WodTemplateFavorites.read(json),
                sessionScoresByRange=dev.repera.domain.ProgressTimeRange.entries.associate {it.wire to SessionScoreProgress.points(json,it,trainingSettings.weekStartsOnMonday)},
                dayWorkoutMinutes=minutesByDay,dayWorkoutCounts=countsByDay,
                prCountBySessionId=dev.repera.domain.StatsEngine.personalRecordCountsBySessionId(
                    ProgressSnapshotBuilder.statsWorkouts(json)),
                dayEnergyKcal=health?.energyDays.orEmpty().associate {it.date to it.kcal},
                trainingSettings=trainingSettings,rotationPlan=RotationSettings.read(json),healthGoals=HealthGoals.read(json),profileSettings=ProfileSettings.read(json),
                liveSportSessions = LiveSportSnapshot.sessions(json),
                recovery = recoveryState,
                favoriteTimerCount = json.optJSONArray("favoriteTimers")?.length() ?: 0,
                favoriteSportActivities = WorkoutFavoriteSupport.listFavoriteSportActivities(json),
                workouts = workoutTitles.size,
                workoutsThisWeek = workoutsThisWeek,
                routines = routineEntries.size,
                exercises = exerciseEntries.size,
                bodyWeights = json.optJSONArray("bodyWeights")?.length() ?: 0,
                bodyWeightHistory = BodyWeightHistory.entries(json),
                testedOneRMByExercise = ExerciseLoadPreference.all(json),
                externalHealthHistory = health?.externalHistory.orEmpty(),
                activeSessionTitle = json.optJSONObject("activeSession")?.optString("title"),
                activeSessionId = json.optJSONObject("activeSession")?.optString("id")?.takeIf { it.isNotEmpty() },
                activeLocationPin = json.optJSONObject("activeSession")?.optJSONObject("locationPin")?.let { o ->
                    runCatching {
                        dev.repera.domain.WorkoutLocationPin(
                            latitude = o.getDouble("latitude"),
                            longitude = o.getDouble("longitude"),
                            recordedAtEpochMs = o.optLong("recordedAtEpochMs"),
                            name = o.optString("name").takeIf { it.isNotBlank() },
                            mapItemIdentifier = o.optString("mapItemIdentifier").takeIf { it.isNotBlank() },
                            pointOfInterestCategory = o.optString("pointOfInterestCategory").takeIf { it.isNotBlank() })
                    }.getOrNull()
                },
                recentWorkoutTitles = workoutTitles.asReversed().take(20),
                history = history.take(20),
                completeHistory = history,
                routineEntries = routineEntries,
                exerciseEntries = exerciseEntries,
                exerciseProgress = ExerciseProgressMetrics.fromWorkouts(json.getJSONArray("workouts")),
                weeklyDayTotals = weeklyDayTotals.toList(),
                weeklyMuscleGroups = MuscleWorkloadMetrics.weekly(
                    json.getJSONArray("workouts"), today, ZoneId.systemDefault()),
                exerciseSessions = ExerciseSessionHistory.fromArchive(json.getJSONArray("workouts")),
                progressByRange = dev.repera.domain.ProgressTimeRange.entries.associate { range ->
                    range.wire to ProgressSnapshotBuilder.build(json, range, monday=trainingSettings.weekStartsOnMonday,health = health)
                },
                chartsByRange = dev.repera.domain.ProgressTimeRange.entries.associate { range ->
                    range.wire to dev.repera.domain.ProgressChartBuilder.build(
                        range = range,
                        weekStartsOnMonday = trainingSettings.weekStartsOnMonday,
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
/** optString de org.json convierte JSON null en el literal «null»; filtrarlo. */
internal fun org.json.JSONObject.optJsonString(key: String): String? {
    if (!has(key) || isNull(key)) return null
    return optString(key).takeIf { it.isNotBlank() && !it.equals("null", ignoreCase = true) }
}

internal fun org.json.JSONObject.exerciseDisplayName(): String {
    val base = optString("name").ifBlank { return "Ejercicio" }
    val tag = optJsonString("sportTag")
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
    val isFavorite: Boolean = false,
    val locationPin: dev.repera.domain.WorkoutLocationPin? = null
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
    val entries: List<RoutineBlockEntryInfo> = emptyList(),
    val id: String? = null,
    val sourceJson: String? = null
)

data class RoutineBlockEntryInfo(
    val exerciseId: String,
    val name: String,
    val quantity: Int,
    val sets: Int = 1,
    val weightKg: Double? = null,
    /** Series planificadas completas (fuerza), con targetRir si la rutina lo
     *  trae (iOS lo escribe). Round-trip: editar y guardar no lo pierde. */
    val plannedSets: List<PlannedSetDraft>? = null,
    val id: String? = null,
    val sourceJson: String? = null,
    /** Apple 8a940bc5: unidad planificada (reps/meters) para la vista previa. */
    val quantityUnit: String? = null
)

data class ExerciseEntry(
    val id: String, val name: String, val supportsBasicInput: Boolean,
    val allowsWeight: Boolean, val muscleGroup: String = "",
    val sportTag: String? = null, val hyroxTraining: Boolean = false,
    /** Apple (live main) Exercise.disciplineTags: disciplinas derivadas, sin duplicar el id. */
    val disciplineTags: List<String> = emptyList(),
    val loggingStyle: String = "strength",
    val equipment: String = "",
    val targetMuscle: String = "",
    val secondaryMuscles: List<String> = emptyList(),
    val detailDescription: String? = null,
    val instructions: List<String> = emptyList(),
    val isCustom: Boolean = false,
    val isFavorite: Boolean = false,
    val mobilityHold:Boolean = false,
    val searchAliases: List<String> = emptyList(),
    val isCatalogArchived: Boolean = false
) {
    /** Nombre visible como en Apple: SportExerciseNames.displayName canoniza
     * CrossFit/Halterofilia al inglés sin tocar el nombre persistido ni el ID. */
    val displayName: String
        get() = dev.repera.domain.SportExerciseNames.displayName(name, sportTag)
}

internal fun pinFromJson(o: org.json.JSONObject?): dev.repera.domain.WorkoutLocationPin? {
    o ?: return null
    return runCatching {
        dev.repera.domain.WorkoutLocationPin(
            latitude = o.getDouble("latitude"),
            longitude = o.getDouble("longitude"),
            recordedAtEpochMs = o.optLong("recordedAtEpochMs"),
            name = o.optString("name").takeIf { it.isNotBlank() },
            mapItemIdentifier = o.optString("mapItemIdentifier").takeIf { it.isNotBlank() },
            pointOfInterestCategory = o.optString("pointOfInterestCategory").takeIf { it.isNotBlank() })
    }.getOrNull()
}

data class WorkoutHistoryEntry(
    val id: String,
    val title: String,
    val startedAt: String,
    val results: List<String>,
    val movements: List<WorkoutHistoryMovement>,
    val review: dev.repera.domain.SessionReview? = null,
    val routePoints: List<dev.repera.domain.WorkoutRoutePoint> = emptyList(),
    val locationPin: dev.repera.domain.WorkoutLocationPin? = null,
    val startedAtIso: String? = null,
    val finishedAtIso: String? = null,
    val notes: String? = null,
    /** Bloques editables (con ids) para el editor de contenido; null si no se pudieron derivar. */
    val editableBlocksJson: String? = null,
    /** Sesión mínima (bloques, wodResults, sets registrados) para mostrar/editar la marca WOD; null si no hay. */
    val scoreSessionJson: String? = null,
    val liveKilometerSplitsSeconds: List<Double> = emptyList(),
    val liveSportID: String? = null,
    val activeDurationSeconds: Double? = null,
    val recordedDistanceMeters: Double? = null,
    val routineId: String? = null,
    /** Temporizador libre: no es editable como fuerza/WOD ni aporta Salud. */
    val timerDetails: dev.repera.domain.TimerCompletionDetails? = null
) {
    /**
     * Minutos para chips/tiles (iOS displayDurationMinutes / HistoryView summary):
     * timer → live activeDuration → reloj de pared inicio→fin.
     */
    fun displayDurationMinutes(): Double {
        timerDetails?.let { return it.configuredSeconds / 60.0 }
        if (liveSportID != null) {
            activeDurationSeconds?.takeIf { it > 0 }?.let { return it / 60.0 }
        }
        val start = startedAtIso?.let { runCatching { java.time.Instant.parse(it) }.getOrNull() }
        if (start != null) {
            val end = finishedAtIso?.let { runCatching { java.time.Instant.parse(it) }.getOrNull() }
                ?: start.plusSeconds(60)
            val wall = java.time.Duration.between(start, end).seconds / 60.0
            if (wall > 0) return wall
        }
        return activeDurationSeconds?.takeIf { it > 0 }?.div(60.0) ?: 0.0
    }
}
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
