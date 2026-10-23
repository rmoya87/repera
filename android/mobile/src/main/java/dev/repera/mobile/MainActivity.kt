package dev.repera.mobile

import android.accounts.Account
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.IntentSenderRequest
import android.net.Uri
import dev.repera.domain.ExerciseInput
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.lifecycle.lifecycleScope
import androidx.health.connect.client.permission.PermissionController
import com.google.android.gms.auth.api.identity.AuthorizationRequest
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.common.api.Scope
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.security.SecureRandom

/**
 * Native Google identity, separate consent for private appDataFolder.
 * The Google ID token is never accepted as Supabase authorization: backend token
 * verification and Google provider setup must be completed before business login.
 */
class MainActivity : ComponentActivity() {
    private data class GoogleProfile(
        val uniqueId: String, val email: String, val displayName: String
    )

    private var profile by mutableStateOf<GoogleProfile?>(null)
    private var busy by mutableStateOf(false)
    private var status by mutableStateOf<String?>(null)
    private var snapshot by mutableStateOf<StateOverview?>(null)
    private var activeWorkout by mutableStateOf<ActiveWorkout?>(null)
    private var todayHealth by mutableStateOf<TodayHealth?>(null)
    private val credentialManager by lazy { CredentialManager.create(this) }

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
                else { status = "No se recibió acceso a Drive"; busy = false }
            }.onFailure { status = "No se pudo autorizar Drive: " + it.localizedMessage; busy = false }
        } else {
            status = "Acceso a Drive cancelado"
            busy = false
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            ReperaMobileScreen(
                isAuthenticated = profile != null,
                displayName = profile?.displayName,
                busy = busy,
                status = status,
                overview = snapshot,
                todayHealth = todayHealth,
                onHealthConnect = ::connectHealth,
                activeWorkout = activeWorkout,
                onStartRoutine = { id -> runWorkoutAction { startRoutine(id) } },
                onCreateRoutine = { title, format, entries, minutes, rounds ->
                    runWorkoutAction { createRoutine(title, format, entries, minutes, rounds) }
                },
                onWodScore = { rounds, reps, seconds ->
                    runWorkoutAction { recordWodScore(rounds, reps, seconds) }
                },
                onQuickLog = { id -> runWorkoutAction { startQuickLog(id) } },
                onInitializeLocal = ::initializeLocalCatalog,
                onLogSet = { quantity, weight, rir, warmup ->
                    runWorkoutAction { logCurrentSet(quantity, weight, rir, warmup) }
                },
                onReviseSet = { id, quantity, weight ->
                    runWorkoutAction { reviseCurrentSet(id, quantity, weight) }
                },
                onNext = { runWorkoutAction { next() } },
                onFinish = { runWorkoutAction { finish() } },
                onImportJson = { importJson.launch(arrayOf("application/json", "text/plain", "application/octet-stream")) },
                onGoogleSignIn = ::signInWithGoogle,
                onDriveSync = ::authorizeDrive,
                onSignOut = ::signOut
            )
        }
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
                check(id.isNotBlank())
                profile = GoogleProfile(
                    uniqueId = id,
                    email = google.email ?: "",
                    displayName = google.displayName ?: "Deportista"
                )
                reloadFor(id)
                status = if (snapshot == null) "No hay datos locales. Sincroniza Google Drive." else null
            } catch (error: Exception) {
                status = "No se pudo iniciar sesión con Google: " + error.localizedMessage
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
                todayHealth = withContext(Dispatchers.IO) {
                    HealthConnectReader(this@MainActivity).readToday()
                }
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
                        status = "Drive requiere consentimiento"
                    } else {
                        driveConsent.launch(IntentSenderRequest.Builder(pending.intentSender).build())
                    }
                } else {
                    val token = result.accessToken
                    if (token.isNullOrBlank()) {
                        busy = false
                        status = "No se recibió acceso a Drive"
                    } else syncWithDrive(token)
                }
            }
            .addOnFailureListener {
                busy = false
                status = "No se pudo conectar Drive: " + it.localizedMessage
            }
    }

    private fun syncWithDrive(oneTimeToken: String) {
        val signedIn = profile ?: run { busy = false; return }
        status = "Sincronizando…"
        lifecycleScope.launch {
            try {
                val result = withContext(Dispatchers.IO) {
                    val store = LocalSnapshotStore(this@MainActivity, signedIn.uniqueId)
                    val outcome = DriveSnapshotService(oneTimeToken, store).synchronize()
                    outcome to StateOverview.fromBytes(store.read())
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
            }
        }
    }

    private suspend fun reloadFor(id: String) {
        val (overview, active, bytes) = withContext(Dispatchers.IO) {
            val store = LocalSnapshotStore(this@MainActivity, id)
            val bytes = store.read()
            Triple(StateOverview.fromBytes(bytes), WorkoutRepository(this@MainActivity, id).active(), bytes)
        }
        snapshot = overview
        activeWorkout = active
        withContext(Dispatchers.IO) {
            WearActiveSessionBridge.publish(this@MainActivity, bytes)
        }
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
                credentialManager.clearCredentialState(ClearCredentialStateRequest())
            } catch (_: Exception) {
                // UI still returns to login; existing account files stay isolated.
            } finally {
                withContext(Dispatchers.IO) {
                    WearActiveSessionBridge.publish(this@MainActivity, null)
                }
                profile = null
                snapshot = null
                activeWorkout = null
                todayHealth = null
                status = null
                busy = false
            }
        }
    }
}

data class StateOverview(
    val workouts: Int,
    val routines: Int,
    val exercises: Int,
    val bodyWeights: Int,
    val activeSessionTitle: String?,
    val recentWorkoutTitles: List<String>,
    val routineEntries: List<RoutineEntry>,
    val exerciseEntries: List<ExerciseEntry>
) {
    companion object {
        fun fromBytes(bytes: ByteArray?): StateOverview? {
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
                            score.has("roundsCompleted") && score.has("totalReps") ->
                                "${score.getInt("roundsCompleted")} rondas + " +
                                    "${score.getInt("totalReps")} reps"
                            score.has("totalReps") -> "${score.getInt("totalReps")} reps"
                            else -> null
                        }
                    }.toMutableList()
                    val exercises = workout.optJSONArray("exercises") ?: org.json.JSONArray()
                    val recordedSets = (0 until exercises.length()).sumOf { n ->
                        exercises.getJSONObject(n).optJSONArray("loggedSets")?.length() ?: 0
                    }
                    if (recordedSets > 0) details += "$recordedSets series"
                    workout.optString("title") + if (details.isEmpty()) ""
                        else " · " + details.joinToString(" / ")
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
                    RoutineEntry(item.getString("id"), item.optString("title"), supported)
                }
            }
            val exerciseEntries = json.getJSONArray("exercises").let { array ->
                (0 until array.length()).map { n ->
                    val ex = array.getJSONObject(n)
                    val mode = ExerciseInput.mode(
                        ex.getString("name"),
                        ex.optString("equipment"),
                        ex.optString("targetMuscle"),
                        ex.optString("muscleGroup")
                    )
                    ExerciseEntry(ex.getString("id"), ex.getString("name"),
                        mode.basicRecorderAvailable, mode.showsWeight)
                }.sortedBy { it.name }
            }
            return StateOverview(
                workouts = workoutTitles.size,
                routines = routineEntries.size,
                exercises = exerciseEntries.size,
                bodyWeights = json.optJSONArray("bodyWeights")?.length() ?: 0,
                activeSessionTitle = json.optJSONObject("activeSession")?.optString("title"),
                recentWorkoutTitles = workoutTitles.asReversed().take(20),
                routineEntries = routineEntries,
                exerciseEntries = exerciseEntries
            )
        }
    }
}

data class RoutineEntry(val id: String, val title: String, val supported: Boolean)

data class ExerciseEntry(val id: String, val name: String, val supportsBasicInput: Boolean, val allowsWeight: Boolean)
