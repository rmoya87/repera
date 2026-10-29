package dev.repera.mobile

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/** Modos del temporizador libre, como StandaloneTimerMode (iOS). */
enum class StandaloneTimerMode(val wire: String, val title: String) {
    UP("up", "Arriba"),
    DOWN("down", "Abajo"),
    INTERVALS("intervals", "Intervalos");

    companion object {
        fun fromWire(wire: String): StandaloneTimerMode =
            // Default iOS: duración/cuenta atrás, no Intervalos (R4 #12).
            entries.firstOrNull { it.wire == wire } ?: DOWN
    }
}

/** Configuración del temporizador libre, paridad StandaloneTimerConfig (iOS). */
data class StandaloneTimerConfig(
    val mode: StandaloneTimerMode = StandaloneTimerMode.DOWN,
    val durationMinutes: Int = 40,
    val durationSeconds: Int = 0,
    val rounds: Int = 5,
    val workMinutes: Int = 1,
    val workSeconds: Int = 30,
    val restMinutes: Int = 0,
    val restSeconds: Int = 0,
    val countdownBeforeStart: Boolean = true
) {
    val durationTotalSeconds: Int get() = (durationMinutes * 60 + durationSeconds).coerceAtLeast(1)
    val workTotalSeconds: Int get() = (workMinutes * 60 + workSeconds).coerceAtLeast(1)
    val restTotalSeconds: Int get() = (restMinutes * 60 + restSeconds).coerceAtLeast(0)

    val configuredDurationSeconds: Int
        get() = when (mode) {
            StandaloneTimerMode.UP, StandaloneTimerMode.DOWN -> durationTotalSeconds
            StandaloneTimerMode.INTERVALS ->
                rounds * workTotalSeconds + maxOf(0, rounds - 1) * restTotalSeconds
        }

    val shortLabel: String
        get() = when (mode) {
            StandaloneTimerMode.UP ->
                "Arriba · %d:%02d".format(durationMinutes, durationSeconds)
            StandaloneTimerMode.DOWN ->
                "Abajo · %d:%02d".format(durationMinutes, durationSeconds)
            StandaloneTimerMode.INTERVALS ->
                "Intervalos · %d× %d:%02d/%d:%02d".format(
                    rounds, workMinutes, workSeconds, restMinutes, restSeconds)
        }

    val defaultFavoriteTitle: String
        get() = when (mode) {
            StandaloneTimerMode.UP -> "Cronómetro %d:%02d".format(durationMinutes, durationSeconds)
            StandaloneTimerMode.DOWN -> "Cuenta atrás %d:%02d".format(durationMinutes, durationSeconds)
            StandaloneTimerMode.INTERVALS -> "Intervalos %d×".format(rounds)
        }

    fun toJson(): JSONObject = JSONObject()
        .put("mode", mode.wire)
        .put("durationMinutes", durationMinutes)
        .put("durationSeconds", durationSeconds)
        .put("rounds", rounds)
        .put("workMinutes", workMinutes)
        .put("workSeconds", workSeconds)
        .put("restMinutes", restMinutes)
        .put("restSeconds", restSeconds)
        .put("countdownBeforeStart", countdownBeforeStart)

    companion object {
        fun fromJson(o: JSONObject): StandaloneTimerConfig = StandaloneTimerConfig(
            mode = StandaloneTimerMode.fromWire(o.optString("mode")),
            durationMinutes = o.optInt("durationMinutes", 40),
            durationSeconds = o.optInt("durationSeconds", 0),
            rounds = o.optInt("rounds", 5),
            workMinutes = o.optInt("workMinutes", 1),
            workSeconds = o.optInt("workSeconds", 30),
            restMinutes = o.optInt("restMinutes", 0),
            restSeconds = o.optInt("restSeconds", 0),
            countdownBeforeStart = o.optBoolean("countdownBeforeStart", true)
        )
    }
}

/** Favorito guardado, paridad FavoriteTimer (iOS). */
data class FavoriteTimer(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val config: StandaloneTimerConfig
)

/** Resumen pendiente de Guardar/Descartar tras completar el reloj (iOS StandaloneTimerCompletion). */
data class StandaloneTimerCompletion(
    val id: String = UUID.randomUUID().toString(),
    val startedAtMillis: Long,
    val finishedAtMillis: Long,
    val config: StandaloneTimerConfig
) {
    val configuredSeconds: Int get() = config.configuredDurationSeconds

    fun toJson(): JSONObject = JSONObject()
        .put("id", id)
        .put("startedAtMillis", startedAtMillis)
        .put("finishedAtMillis", finishedAtMillis)
        .put("configuration", config.toJson())

    companion object {
        fun fromJson(o: JSONObject): StandaloneTimerCompletion? {
            val configObj = o.optJSONObject("configuration") ?: return null
            val started = o.optLong("startedAtMillis", 0L)
            val finished = o.optLong("finishedAtMillis", 0L)
            if (started <= 0L || finished < started) return null
            return StandaloneTimerCompletion(
                id = o.optString("id").ifBlank { UUID.randomUUID().toString() },
                startedAtMillis = started,
                finishedAtMillis = finished,
                config = StandaloneTimerConfig.fromJson(configObj)
            )
        }
    }
}

/**
 * Persistencia de favoritos, última configuración y resumen pendiente.
 * Paridad StandaloneTimerStore / ConfigurationStore / CompletionStore (iOS).
 */
internal class StandaloneTimerStore(context: Context) {
    private val preferences =
        context.getSharedPreferences("repera.standalone.timer", Context.MODE_PRIVATE)

    fun favorites(): List<FavoriteTimer> {
        val raw = preferences.getString("favorites", null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { i ->
                val o = array.optJSONObject(i) ?: return@mapNotNull null
                FavoriteTimer(
                    id = o.optString("id").ifBlank { UUID.randomUUID().toString() },
                    title = o.optString("title"),
                    config = StandaloneTimerConfig.fromJson(o)
                )
            }
        }.getOrDefault(emptyList())
    }

    /** Inserta o actualiza (mismo id) y devuelve el favorito guardado. */
    fun save(favorite: FavoriteTimer): FavoriteTimer {
        val current = favorites().filterNot { it.id == favorite.id } + favorite
        persistFavorites(current)
        return favorite
    }

    fun delete(id: String) {
        persistFavorites(favorites().filterNot { it.id == id })
    }

    /** Última configuración usada al abrir desde Añadir (no favoritos). */
    fun loadLastConfiguration(): StandaloneTimerConfig? {
        val raw = preferences.getString(KEY_LAST_CONFIG, null) ?: return null
        return runCatching { StandaloneTimerConfig.fromJson(JSONObject(raw)) }.getOrNull()
    }

    fun saveLastConfiguration(config: StandaloneTimerConfig) {
        preferences.edit().putString(KEY_LAST_CONFIG, config.toJson().toString()).apply()
    }

    fun loadPendingCompletion(): StandaloneTimerCompletion? {
        val raw = preferences.getString(KEY_PENDING_COMPLETION, null) ?: return null
        return runCatching { StandaloneTimerCompletion.fromJson(JSONObject(raw)) }.getOrNull()
    }

    fun savePendingCompletion(completion: StandaloneTimerCompletion) {
        preferences.edit()
            .putString(KEY_PENDING_COMPLETION, completion.toJson().toString())
            .apply()
    }

    fun clearPendingCompletion() {
        preferences.edit().remove(KEY_PENDING_COMPLETION).apply()
    }

    private fun persistFavorites(current: List<FavoriteTimer>) {
        val array = JSONArray()
        current.forEach { fav ->
            array.put(fav.config.toJson().apply {
                put("id", fav.id)
                put("title", fav.title)
            })
        }
        preferences.edit().putString("favorites", array.toString()).apply()
    }

    companion object {
        private const val KEY_LAST_CONFIG = "lastConfiguration.v1"
        private const val KEY_PENDING_COMPLETION = "pendingCompletion.v2"
    }
}
