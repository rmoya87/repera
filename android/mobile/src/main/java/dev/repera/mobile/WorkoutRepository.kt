package dev.repera.mobile

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.UUID

/**
 * Real local-first strength session writes using the wire format of ReperaDomain.Models.
 * No synthetic workouts, no inferred Health Connect readings, no skipped WOD blocks.
 * A WOD requires the Swift-equivalent planner and is explicitly rejected for now.
 */
class WorkoutRepository(context: Context, googleId: String) {
    private val local = LocalSnapshotStore(context, googleId)
    private val prefs = context.getSharedPreferences("repera.local.writer", Context.MODE_PRIVATE)
    private val writerId: String by lazy {
        prefs.getString("writerId", null) ?: UUID.randomUUID().toString().also {
            prefs.edit().putString("writerId", it).apply()
        }
    }

    @Synchronized fun active(): ActiveWorkout? {
        val state = loadOrNull() ?: return null
        return state.optJSONObject("activeSession")?.let { summarize(it) }
    }

    @Synchronized fun startStrengthRoutine(id: String): ActiveWorkout {
        val state = loadOrNull() ?: error("Importa primero un historial o crea tus datos locales")
        check(state.isNull("activeSession")) { "Ya existe una sesión activa" }
        val routines = state.getJSONArray("routines")
        val routine = (0 until routines.length()).map { routines.getJSONObject(it) }
            .firstOrNull { it.optString("id") == id } ?: error("Rutina no encontrada")
        val blocks = routine.optJSONArray("blocks") ?: JSONArray()
        require(blocks.length() > 0) { "Esta rutina no tiene bloques" }
        // Never silently reinterpret a WOD as strength or discard its movements.
        check((0 until blocks.length()).all { blocks.getJSONObject(it).optString("kind") == "strength" }) {
            "Los bloques WOD aún no admiten ejecución en Android"
        }
        val catalog = state.getJSONArray("exercises")
        val byId = (0 until catalog.length()).associate {
            val exercise = catalog.getJSONObject(it)
            exercise.getString("id") to exercise
        }
        val planned = JSONArray()
        for (blockIndex in 0 until blocks.length()) {
            val block = blocks.getJSONObject(blockIndex)
            val entries = block.optJSONArray("exercises") ?: JSONArray()
            for (j in 0 until entries.length()) {
                val entry = entries.getJSONObject(j)
                val exercise = byId[entry.getString("exerciseId")]
                    ?: error("La rutina contiene un ejercicio ausente del catálogo")
                val item = JSONObject()
                    .put("id", UUID.randomUUID().toString())
                    .put("exercise", JSONObject(exercise.toString()))
                    .put("plannedSets", JSONArray((entry.optJSONArray("plannedSets") ?: JSONArray()).toString()))
                    .put("loggedSets", JSONArray())
                    .put("completedReps", 0)
                    .put("isCompleted", false)
                    .put("blockId", block.getString("id"))
                    .put("blockKind", "strength")
                copyIfPresent(entry, item, "restSeconds", "quantityUnit")
                copyIfPresent(block, item, "wodFormat")
                if (block.has("timeCapMinutes")) item.put("blockTimeCapMinutes", block.getInt("timeCapMinutes"))
                if (block.has("emomIntervalSeconds")) item.put("blockIntervalSeconds", block.getInt("emomIntervalSeconds"))
                if (block.has("rounds")) item.put("blockRounds", block.getInt("rounds"))
                if (block.has("workSeconds")) item.put("blockWorkSeconds", block.getInt("workSeconds"))
                if (block.has("restSeconds")) item.put("blockRestSeconds", block.getInt("restSeconds"))
                if (block.has("restBetweenRoundsSeconds")) item.put("blockRestBetweenRoundsSeconds", block.getInt("restBetweenRoundsSeconds"))
                item.put("blockHeader", block.optString("title"))
                planned.put(item)
            }
        }
        require(planned.length() > 0) { "La rutina no contiene ejercicios ejecutables" }
        val session = JSONObject()
            .put("id", UUID.randomUUID().toString())
            .put("title", routine.getString("title"))
            .put("routineId", id)
            .put("exercises", planned)
            .put("currentIndex", 0)
            .put("phase", "ready")
            .put("startedAt", nowISO8601())
            .put("wodResults", JSONArray())
            .put("routineBlocks", JSONArray(blocks.toString()))
            .put("routePoints", JSONArray())
        state.put("activeSession", session)
        save(state)
        return summarize(session)
    }

    @Synchronized fun logCurrentSet(quantity: Int, weightKg: Double?): ActiveWorkout {
        require(quantity >= 0) { "Cantidad inválida" }
        require(weightKg == null || (weightKg.isFinite() && weightKg >= 0)) { "Peso inválido" }
        val state = requireState()
        val session = requireActive(state)
        val array = session.getJSONArray("exercises")
        val index = session.getInt("currentIndex")
        val exercise = array.getJSONObject(index)
        check(!exercise.optBoolean("isCompleted")) { "Ejercicio ya completado" }
        val logged = exercise.getJSONArray("loggedSets")
        val set = JSONObject()
            .put("id", UUID.randomUUID().toString())
            .put("reps", quantity)
            .put("completedAt", nowISO8601())
            .put("phase", "work")
            .put("kind", "straight")
            .put("toFailure", false)
            .put("drops", JSONArray())
            .put("clusters", JSONArray())
        if (weightKg != null) set.put("weightKg", weightKg)
        val unit = exercise.optString("quantityUnit")
        if (unit.isNotBlank()) set.put("quantityUnit", unit)
        logged.put(set)
        exercise.put("completedReps", exercise.optInt("completedReps") + quantity)
        session.put("phase", "counting")
        save(state)
        return summarize(session)
    }

    @Synchronized fun next(): ActiveWorkout? {
        val state = requireState()
        val session = requireActive(state)
        val exercises = session.getJSONArray("exercises")
        val index = session.getInt("currentIndex")
        exercises.getJSONObject(index).put("isCompleted", true)
        if (index + 1 == exercises.length()) {
            finishInPlace(state, session)
            return null
        }
        session.put("currentIndex", index + 1).put("phase", "ready")
        save(state)
        return summarize(session)
    }

    @Synchronized fun finish(): Unit {
        val state = requireState()
        finishInPlace(state, requireActive(state))
    }

    @Synchronized fun reviseCurrentSet(setId: String, quantity: Int, weightKg: Double?): ActiveWorkout {
        require(quantity >= 0 && (weightKg == null || (weightKg.isFinite() && weightKg >= 0)))
        val state = requireState()
        val session = requireActive(state)
        val exercise = session.getJSONArray("exercises").getJSONObject(session.getInt("currentIndex"))
        val logged = exercise.getJSONArray("loggedSets")
        val index = (0 until logged.length()).firstOrNull {
            logged.getJSONObject(it).optString("id") == setId
        } ?: error("Serie no encontrada")
        val original = logged.getJSONObject(index)
        original.put("reps", quantity)
        if (weightKg == null) original.remove("weightKg") else original.put("weightKg", weightKg)
        // Recompute only work sets, preserving each existing identity and completedAt.
        val total = (0 until logged.length()).sumOf { i ->
            val set = logged.getJSONObject(i)
            if (set.optString("phase") == "warmup") 0 else
                set.optInt("reps") + (set.optJSONArray("drops")?.let { drops ->
                    (0 until drops.length()).sumOf { drops.getJSONObject(it).optInt("reps") }
                } ?: 0)
        }
        exercise.put("completedReps", total)
        save(state)
        return summarize(session)
    }

    private fun finishInPlace(state: JSONObject, session: JSONObject) {
        check(session.optString("phase") != "finished")
        val exercises = session.getJSONArray("exercises")
        for (i in 0 until exercises.length()) {
            val exercise = exercises.getJSONObject(i)
            if ((exercise.optJSONArray("loggedSets")?.length() ?: 0) > 0) {
                exercise.put("isCompleted", true)
            }
        }
        session.put("phase", "finished").put("finishedAt", nowISO8601())
        state.getJSONArray("workouts").put(session)
        state.remove("activeSession")
        save(state)
    }

    private fun nowISO8601(): String = DateTimeFormatter
        .ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'")
        .withZone(ZoneOffset.UTC)
        .format(Instant.now())

    private fun loadOrNull(): JSONObject? = local.read()?.let { bytes ->
        LocalSnapshotStore.validate(bytes)
        JSONObject(String(bytes, Charsets.UTF_8))
    }

    private fun requireState() = loadOrNull() ?: error("No hay estado local")
    private fun requireActive(state: JSONObject): JSONObject =
        state.optJSONObject("activeSession") ?: error("No hay sesión activa")

    private fun save(state: JSONObject) {
        state.put("syncRevision", state.optInt("syncRevision", 0) + 1)
        state.put("updatedAt", nowISO8601())
        state.put("lastWriterDeviceId", writerId)
        local.write(state.toString().toByteArray(Charsets.UTF_8))
    }

    private fun copyIfPresent(source: JSONObject, target: JSONObject, vararg keys: String) {
        for (key in keys) if (source.has(key) && !source.isNull(key)) target.put(key, source.get(key))
    }

    private fun summarize(session: JSONObject): ActiveWorkout {
        val exercises = session.getJSONArray("exercises")
        val index = session.getInt("currentIndex")
        val current = exercises.getJSONObject(index)
        val plan = current.optJSONArray("plannedSets") ?: JSONArray()
        val logged = current.optJSONArray("loggedSets") ?: JSONArray()
        val finishedWork = (0 until logged.length()).count {
            logged.getJSONObject(it).optString("phase") == "work"
        }
        val next = if (plan.length() == 0) null
            else plan.getJSONObject(minOf(finishedWork, plan.length() - 1))
        return ActiveWorkout(
            id = session.getString("id"),
            title = session.getString("title"),
            index = index,
            total = exercises.length(),
            exerciseName = current.getJSONObject("exercise").getString("name"),
            completedSets = logged.length(),
            prescribedQuantity = next?.optInt("targetReps"),
            prescribedWeightKg = next?.takeIf { it.has("targetWeightKg") && !it.isNull("targetWeightKg") }
                ?.getDouble("targetWeightKg"),
            sets = (0 until logged.length()).map { n ->
                val set = logged.getJSONObject(n)
                WorkoutSetSummary(set.getString("id"), set.getInt("reps"),
                    if (set.has("weightKg")) set.getDouble("weightKg") else null)
            }
        )
    }
}

data class WorkoutSetSummary(val id: String, val reps: Int, val weightKg: Double?)
data class ActiveWorkout(
    val id: String,
    val title: String,
    val index: Int,
    val total: Int,
    val exerciseName: String,
    val completedSets: Int,
    val prescribedQuantity: Int?,
    val prescribedWeightKg: Double?,
    val sets: List<WorkoutSetSummary>
)
