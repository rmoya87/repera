package dev.repera.mobile

import android.accounts.Account
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.lifecycle.lifecycleScope
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
    private val credentialManager by lazy { CredentialManager.create(this) }

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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            ReperaMobileScreen(
                isAuthenticated = profile != null,
                displayName = profile?.displayName,
                busy = busy,
                status = status,
                overview = snapshot,
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
                    serverClientId = BuildConfig.GOOGLE_WEB_CLIENT_ID
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
                val store = LocalSnapshotStore(this@MainActivity, id)
                val local = withContext(Dispatchers.IO) {
                    val bytes = store.read()
                    StateOverview.fromBytes(bytes) to bytes
                }
                snapshot = local.first
                withContext(Dispatchers.IO) {
                    WearActiveSessionBridge.publish(this@MainActivity, local.second)
                }
                status = if (snapshot == null) "No hay datos locales. Sincroniza Google Drive." else null
            } catch (error: Exception) {
                status = "No se pudo iniciar sesión con Google: " + error.localizedMessage
            } finally {
                busy = false
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
                snapshot = result.second
                withContext(Dispatchers.IO) {
                    WearActiveSessionBridge.publish(
                        this@MainActivity,
                        LocalSnapshotStore(this@MainActivity, signedIn.uniqueId).read()
                    )
                }
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
    val routineTitles: List<String>,
    val exerciseTitles: List<String>
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
            val workoutTitles = titles("workouts")
            val routineTitles = titles("routines")
            val exerciseTitles = titles("exercises")
            return StateOverview(
                workouts = workoutTitles.size,
                routines = routineTitles.size,
                exercises = exerciseTitles.size,
                bodyWeights = json.optJSONArray("bodyWeights")?.length() ?: 0,
                activeSessionTitle = json.optJSONObject("activeSession")?.optString("title"),
                recentWorkoutTitles = workoutTitles.asReversed().take(20),
                routineTitles = routineTitles,
                exerciseTitles = exerciseTitles.sorted()
            )
        }
    }
}
