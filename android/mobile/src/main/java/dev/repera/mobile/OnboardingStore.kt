package dev.repera.mobile

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

/** Pasos del wizard obligatorio (primer acceso y usuarios existentes).
 *  Port 1:1 de OnboardingStep/OnboardingStore.swift (iOS). */
enum class OnboardingStep(val raw: String) {
    SignIn("appleSignIn"),      // iOS conserva el raw histórico aunque en Android sea Google
    ChoosePlan("choosePlan"),
    Permissions("permissions"),
    Done("done");

    companion object {
        fun fromRaw(raw: String?): OnboardingStep? = entries.firstOrNull { it.raw == raw }
    }
}

/** Almacén clave-valor mínimo para poder probar la lógica en JVM. */
interface OnboardingPrefs {
    fun getString(key: String): String?
    fun getInt(key: String, default: Int): Int
    fun getBool(key: String, default: Boolean): Boolean
    fun putString(key: String, value: String)
    fun putInt(key: String, value: Int)
    fun putBool(key: String, value: Boolean)
}

/** Implementación sobre SharedPreferences (mecanismo Android equivalente a UserDefaults). */
class SharedOnboardingPrefs(context: Context) : OnboardingPrefs {
    private val prefs = context.getSharedPreferences("repera.onboarding", Context.MODE_PRIVATE)
    override fun getString(key: String): String? = prefs.getString(key, null)
    override fun getInt(key: String, default: Int): Int = prefs.getInt(key, default)
    override fun getBool(key: String, default: Boolean): Boolean = prefs.getBoolean(key, default)
    override fun putString(key: String, value: String) { prefs.edit().putString(key, value).apply() }
    override fun putInt(key: String, value: Int) { prefs.edit().putInt(key, value).apply() }
    override fun putBool(key: String, value: Boolean) { prefs.edit().putBoolean(key, value).apply() }
}

/**
 * Progreso del wizard. Port 1:1 de OnboardingStore.swift, con las MISMAS claves
 * y la misma migración de flowVersion v1 (signIn→precio→permisos) a v2
 * (signIn→permisos→precio):
 * - v1: un usuario viejo ya en permissions/done YA vio precios: nunca repetir.
 * - reconcile(isSignedIn) solo AVANZA; bajar de done a signIn dejaba la
 *   pantalla en blanco tras reconectar (comentario iOS conservado).
 */
class OnboardingStore private constructor(private val prefs: OnboardingPrefs) {

    var priceAlreadySeen by mutableStateOf(false)
        private set

    var step by mutableStateOf(OnboardingStep.SignIn)
        private set

    val isComplete: Boolean get() = step == OnboardingStep.Done

    init {
        val previous = OnboardingStep.fromRaw(prefs.getString(STEP_KEY)) ?: OnboardingStep.SignIn
        if (prefs.getInt(FLOW_VERSION_KEY, 0) < 2) {
            // v1: signIn → precio → permisos. v2: signIn → permisos → precio.
            priceAlreadySeen = previous == OnboardingStep.Permissions || previous == OnboardingStep.Done
            step = when (previous) {
                OnboardingStep.Done -> OnboardingStep.Done
                OnboardingStep.SignIn -> OnboardingStep.SignIn
                else -> OnboardingStep.Permissions
            }
            prefs.putString(STEP_KEY, step.raw)
            prefs.putBool(PRICE_SEEN_KEY, priceAlreadySeen)
            prefs.putInt(FLOW_VERSION_KEY, 2)
        } else {
            step = previous
            priceAlreadySeen = prefs.getBool(PRICE_SEEN_KEY, false)
        }
    }

    fun advance(to: OnboardingStep) {
        step = to
        prefs.putString(STEP_KEY, to.raw)
    }

    /** Completa permisos antes de que un usuario nuevo vea precios.
     *  A usuarios migrados del flujo viejo no se les pregunta dos veces. */
    fun finishPermissions() {
        advance(to = if (priceAlreadySeen) OnboardingStep.Done else OnboardingStep.ChoosePlan)
    }

    fun finishPrices() {
        priceAlreadySeen = true
        prefs.putBool(PRICE_SEEN_KEY, true)
        advance(to = OnboardingStep.Done)
    }

    fun resetToSignIn() {
        // Cerrar sesión no es crear una cuenta nueva: recordar que el usuario
        // ya pasó permisos y precios evita repetir el onboarding al reentrar.
        advance(to = OnboardingStep.SignIn)
    }

    /** Si hay sesión completa: avanza el wizard. Si no hay sesión: NO tocar el
     *  paso (bajar de Done a SignIn dejaba una pantalla en blanco al reconectar). */
    fun reconcile(isSignedIn: Boolean) {
        if (!isSignedIn) return
        if (step == OnboardingStep.SignIn) {
            advance(to = if (priceAlreadySeen) OnboardingStep.Done else OnboardingStep.Permissions)
        } else if (priceAlreadySeen && step != OnboardingStep.Done) {
            // Reauth / update: ya vio precios; no repetir wizard a medias.
            advance(to = OnboardingStep.Done)
        }
    }

    companion object {
        private const val STEP_KEY = "repera.onboarding.step"
        private const val FLOW_VERSION_KEY = "repera.onboarding.flowVersion"
        private const val PRICE_SEEN_KEY = "repera.onboarding.priceAlreadySeen"

        fun create(prefs: OnboardingPrefs): OnboardingStore = OnboardingStore(prefs)
        fun create(context: Context): OnboardingStore = OnboardingStore(SharedOnboardingPrefs(context))
    }
}
