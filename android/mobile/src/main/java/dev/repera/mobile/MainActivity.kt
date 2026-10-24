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
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.time.Instant
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
    private var wodTimer by mutableStateOf<WodTimerState?>(null)
    private var todayHealth by mutableStateOf<TodayHealth?>(null)
    private var healthSamples by mutableStateOf<HealthSamples?>(null)
    private var recoveryRead by mutableStateOf<RecoveryRead?>(null)
    private val credentialManager by lazy { CredentialManager.create(this) }
    private var verifiedSupabase: SupabaseIdentity.Session? = null
    private val sessionStore by lazy { SessionStore(this) }

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
        setContent {
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
                todayHealth = todayHealth,
                onHealthConnect = ::connectHealth,
                activeWorkout = activeWorkout,
                wodTimer = wodTimer,
                onWodTimerAction = ::changeWodTimer,
                onWodTimerTick = ::refreshWodTimer,
                onStartRoutine = { id -> runWorkoutAction { startRoutine(id) } },
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
                onQuickLog = { id -> runWorkoutAction { startQuickLog(id) } },
                onInitializeLocal = ::initializeLocalCatalog,
                onLogSet = { quantity, weight, rir, warmup, unit, duration, deficit ->
                    runWorkoutAction { logCurrentSet(quantity, weight, rir, warmup,
                        quantityUnit = unit, durationSeconds = duration, deficitCm = deficit) }
                },
                onLogDropSet = { quantity, weight, drops ->
                    runWorkoutAction { logDropSet(quantity, weight, drops) }
                },
                onLogRestPauseSet = { clusters, weight ->
                    runWorkoutAction { logRestPauseSet(clusters, weight) }
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
                onLogBodyWeight = { kg ->
                    runWorkoutAction { logBodyWeight(kg) }
                },
                onSetRoutineProgression = { id, policy ->
                    runWorkoutAction { setRoutineProgression(id, policy) }
                },
                onNext = { runWorkoutAction { next() } },
                onFinish = { runWorkoutAction { finish() } },
                onImportJson = { importJson.launch(arrayOf("application/json", "text/plain", "application/octet-stream")) },
                onExportJson = { exportJson.launch("repera-entrenamientos.json") },
                onGoogleSignIn = ::signInWithGoogle,
                onDriveSync = ::authorizeDrive,
                onSignOut = ::signOut
            )
        }
    }

    override fun onStart() {
        super.onStart()
        wearMessages.addListener(this)
    }

    override fun onStop() {
        wearMessages.removeListener(this)
        super.onStop()
    }

    override fun onMessageReceived(event: MessageEvent) {
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
            if (sessionId.isBlank() || exerciseIndex < 0 || quantity !in 1..10000 ||
                (weight != null && (!weight.isFinite() || weight < 0))) {
                sendWearAck(event.sourceNodeId, id, "rejected")
                return@runOnUiThread
            }
            busy = true
            lifecycleScope.launch {
                val result = runCatching {
                    withContext(Dispatchers.IO) {
                        WorkoutRepository(this@MainActivity, signedIn.uniqueId).logWearSet(
                            sessionId, exerciseIndex, id, quantity, weight
                        )
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
                reloadFor(stored.uniqueId)
            } catch (_: Exception) {
                // Expired or revoked refresh token: back to the login screen.
                sessionStore.clear()
                verifiedSupabase = null
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
                val signedIn = GoogleProfile(
                    uniqueId = id,
                    email = google.email ?: "",
                    displayName = google.displayName ?: "Deportista"
                )
                profile = signedIn
                persistSession(session, signedIn)
                DriveSyncWorker.schedulePeriodic(this@MainActivity)
                reloadFor(id)
                status = if (snapshot == null) "No hay datos locales. Sincroniza Google Drive." else null
            } catch (error: Exception) {
                verifiedSupabase = null
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
            val bytes = store.read()
            Triple(StateOverview.fromBytes(bytes, healthSamples, recoveryRead), WorkoutRepository(this@MainActivity, id).active(), bytes)
        }
        snapshot = overview
        activeWorkout = active
        refreshWodTimer()
        // Local persistence is the source of truth. A missing/disconnected watch
        // must not make a saved training action appear to have failed.
        withContext(Dispatchers.IO) {
            runCatching { WearActiveSessionBridge.publish(this@MainActivity, bytes) }
        }
    }

    private fun refreshWodTimer() {
        val user = profile?.uniqueId
        val active = activeWorkout
        wodTimer = if (user != null && active?.wod != null)
            WodTimerStore(this, user).read(active.id, active.index)
        else null
        WodTimerService.sync(this, active, wodTimer, user)
    }

    private fun changeWodTimer(action: String) {
        val user = profile?.uniqueId ?: return
        val active = activeWorkout ?: return
        if (active.wod == null || busy) return
        runCatching {
            wodTimer = WodTimerStore(this, user).update(active.id, active.index, action)
        }.onFailure { status = "Cronómetro: " + (it.localizedMessage ?: "error al guardar") }
    }

    private fun runWorkoutAction(action: WorkoutRepository.() -> Unit) {
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
                status = null
            } catch (error: Exception) {
                status = error.localizedMessage ?: "No se pudo guardar el entrenamiento"
            } finally {
                busy = false
            }
        }
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
                verifiedSupabase = null
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
                            name = movement?.optString("name") ?: "Ejercicio",
                            wod = exercise.optString("blockKind") == "wod",
                            registered = WorkoutHistorySets.displayLines(session, exercise),
                            entryId = exercise.optString("id"),
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
                        startedAt = session.optString("startedAt").take(10),
                        results = results,
                        movements = movements
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
                    val day = item.optString("scheduledDate").takeIf { it.isNotBlank() }
                        ?.let { value -> runCatching {
                            Instant.parse(value).atZone(ZoneId.systemDefault()).toLocalDate().toString()
                        }.getOrNull() }
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
                        progression = item.optString("progression", "off")
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

data class RoutineEntry(
    val id: String,
    val title: String,
    val supported: Boolean,
    val scheduledDate: String? = null,
    val weekday: Int? = null,
    val timeMinutes: Int? = null,
    val blocks: List<RoutineBlockInfo> = emptyList(),
    val progression: String = "off"
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
    val isCustom: Boolean = false
)

data class WorkoutHistoryEntry(
    val id: String,
    val title: String,
    val startedAt: String,
    val results: List<String>,
    val movements: List<WorkoutHistoryMovement>
)
data class WorkoutHistoryMovement(
    val name: String,
    val wod: Boolean,
    val registered: List<String>,
    val entryId: String = "",
    val editableSets: List<FinishedSetRef> = emptyList()
)

/** Serie registrada editable de un entreno terminado (identidad real del snapshot). */
data class FinishedSetRef(
    val setId: String,
    val line: String
)
