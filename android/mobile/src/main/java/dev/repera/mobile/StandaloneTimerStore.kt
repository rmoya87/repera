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
            entries.firstOrNull { it.wire == wire } ?: INTERVALS
    }
}

/** Configuración del temporizador libre, paridad StandaloneTimerConfig (iOS). */
data class StandaloneTimerConfig(
    val mode: StandaloneTimerMode = StandaloneTimerMode.INTERVALS,
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
}

/** Favorito guardado, paridad FavoriteTimer (iOS). */
data class FavoriteTimer(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val config: StandaloneTimerConfig
)

/** Persistencia de favoritos del temporizador en SharedPreferences (JSON). */
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
                    config = StandaloneTimerConfig(
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
                )
            }
        }.getOrDefault(emptyList())
    }

    /** Inserta o actualiza (mismo id) y devuelve el favorito guardado. */
    fun save(favorite: FavoriteTimer): FavoriteTimer {
        val current = favorites().filterNot { it.id == favorite.id } + favorite
        val array = JSONArray()
        current.forEach { fav ->
            array.put(JSONObject().apply {
                put("id", fav.id)
                put("title", fav.title)
                put("mode", fav.config.mode.wire)
                put("durationMinutes", fav.config.durationMinutes)
                put("durationSeconds", fav.config.durationSeconds)
                put("rounds", fav.config.rounds)
                put("workMinutes", fav.config.workMinutes)
                put("workSeconds", fav.config.workSeconds)
                put("restMinutes", fav.config.restMinutes)
                put("restSeconds", fav.config.restSeconds)
                put("countdownBeforeStart", fav.config.countdownBeforeStart)
            })
        }
        preferences.edit().putString("favorites", array.toString()).apply()
        return favorite
    }

    fun delete(id: String) {
        val current = favorites().filterNot { it.id == id }
        val array = JSONArray()
        current.forEach { fav ->
            array.put(JSONObject().apply {
                put("id", fav.id); put("title", fav.title)
                put("mode", fav.config.mode.wire)
                put("durationMinutes", fav.config.durationMinutes)
                put("durationSeconds", fav.config.durationSeconds)
                put("rounds", fav.config.rounds)
                put("workMinutes", fav.config.workMinutes)
                put("workSeconds", fav.config.workSeconds)
                put("restMinutes", fav.config.restMinutes)
                put("restSeconds", fav.config.restSeconds)
                put("countdownBeforeStart", fav.config.countdownBeforeStart)
            })
        }
        preferences.edit().putString("favorites", array.toString()).apply()
    }
}
