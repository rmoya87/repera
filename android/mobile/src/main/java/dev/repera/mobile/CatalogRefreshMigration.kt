package dev.repera.mobile

import android.content.Context
import org.json.JSONObject
import java.time.Instant

/**
 * Refresco no destructivo del catálogo nativo frente al seed actual (289 entradas,
 * paridad con iOS). Para snapshots de instalaciones anteriores:
 * - actualiza los campos de catálogo de las entradas existentes casadas por `id`
 *   (incluidos los 43 renombrados canónicos, p.ej. "Arrancada" → "Snatch"),
 *   preservando `id`, `isFavorite` y cualquier entrada `isCustom`;
 * - añade las entradas del seed ausentes (p.ej. las 8 nuevas de halterofilia).
 * Nunca toca workouts, routines ni sets: las referencias son por `id`, que se
 * conserva, por lo que el historial del atleta queda intacto. Idempotente: una
 * segunda ejecución no modifica nada y devuelve false.
 */
internal object CatalogRefreshMigration {
    private val CATALOG_FIELDS = listOf(
        "name", "muscleGroup", "catalogId", "detailDescription", "equipment",
        "instructions", "primaryRegions", "secondaryMuscles", "secondaryRegions",
        "targetMuscle", "bodyPart", "sportTag"
    )

    fun ensure(context: Context, accountId: String): Boolean {
        val store = LocalSnapshotStore(context, accountId)
        val bytes = store.read() ?: return false
        LocalSnapshotStore.validate(bytes)
        val state = JSONObject(String(bytes, Charsets.UTF_8))
        val seed = context.assets.open("catalog_seed.json")
            .bufferedReader(Charsets.UTF_8).use { org.json.JSONArray(it.readText()) }
        check(seed.length() > 0) { "Catálogo semilla vacío" }
        val changed = mergeSeedIntoState(seed, state)
        if (!changed) return false
        check(store.replaceIfUnchanged(bytes,state.toString().toByteArray(Charsets.UTF_8))) {
            "El historial cambió durante la migración del catálogo; vuelve a intentarlo"
        }
        return true
    }

    /** Núcleo puro (sin I/O) para pruebas JVM: aplica el seed sobre el estado.
     *  Devuelve true si el estado quedó modificado. */
    internal fun mergeSeedIntoState(
        seed: org.json.JSONArray,
        state: JSONObject,
        now: Instant = Instant.now()
    ): Boolean {
        val catalog = state.getJSONArray("exercises")
        val byId = mutableMapOf<String, JSONObject>()
        for (i in 0 until catalog.length()) {
            val item = catalog.getJSONObject(i)
            byId[item.getString("id")] = item
        }
        var changed = false
        for (i in 0 until seed.length()) {
            val seedEntry = seed.getJSONObject(i)
            val existing = byId[seedEntry.getString("id")]
            if (existing == null) {
                catalog.put(JSONObject(seedEntry.toString()))
                changed = true
                continue
            }
            if (existing.optBoolean("isCustom")) continue
            // Supabase es la fuente editorial: el seed nunca puede deshacer su última revisión.
            if (existing.optString("_remoteCatalogKey").isNotBlank()) continue
            for (field in CATALOG_FIELDS) {
                val seedValue = seedEntry.opt(field)
                if (seedValue == null || seedValue == JSONObject.NULL) continue
                val current = existing.opt(field)
                val equal = when {
                    current == null || current == JSONObject.NULL -> false
                    current is org.json.JSONArray && seedValue is org.json.JSONArray ->
                        current.toString() == seedValue.toString()
                    else -> current.toString() == seedValue.toString()
                }
                if (!equal) {
                    existing.put(field, seedValue)
                    changed = true
                }
            }
        }
        // Dedupe por nombre canónico: una importación Apple puede traer una entrada
        // con el mismo nombre que una del seed y distinto UUID. Sobrevive el id
        // referenciado por rutinas/entrenos; si ninguno lo está, el no-seed (el
        // importado). Jamás se elimina un id referenciado ni una entrada custom.
        val seedIds = (0 until seed.length()).map { seed.getJSONObject(it).getString("id") }.toSet()
        val referenced = mutableSetOf<String>()
        listOf("routines","workouts","activeSession").forEach {section ->
            collectExerciseIds(state.opt(section),referenced)
        }
        val groups = mutableMapOf<String, MutableList<Int>>()
        for (i in 0 until catalog.length()) {
            val item = catalog.getJSONObject(i)
            if (item.optBoolean("isCustom")) continue
            val key = dev.repera.domain.ExerciseAliasSearch.normalize(item.optString("name"))
            if (key.isNotEmpty()) groups.getOrPut(key) { mutableListOf() }.add(i)
        }
        val toRemove = sortedSetOf<Int>()
        for ((_, idxs) in groups) {
            if (idxs.size < 2) continue
            val ids = idxs.map { catalog.getJSONObject(it).getString("id") }
            val referencedIds = ids.filter { it in referenced }
            val survivor = when {
                referencedIds.size == 1 -> referencedIds.single()
                referencedIds.size > 1 -> continue  // ambos referenciados: no tocar nada
                else -> ids.firstOrNull { it !in seedIds } ?: continue
            }
            for ((pos, id) in ids.withIndex()) {
                if (id != survivor && id !in referenced) toRemove.add(idxs[pos])
            }
            // Trasladar vínculos del perdedor al superviviente antes de borrar:
            // - isFavorite vive EN la entrada: se conserva si alguno lo tenía.
            // - exerciseLoadPrefs (clave = exerciseId) se re-etiqueta al id superviviente.
            val survivorEntry = catalog.getJSONObject(
                idxs[ids.indexOf(survivor)])
            var favorite = survivorEntry.optBoolean("isFavorite")
            for ((pos, id) in ids.withIndex()) {
                if (id == survivor || id in referenced) continue
                if (catalog.getJSONObject(idxs[pos]).optBoolean("isFavorite")) favorite = true
            }
            if (favorite != survivorEntry.optBoolean("isFavorite")) {
                survivorEntry.put("isFavorite", favorite)
                changed = true
            }
            val loadPrefs = state.optJSONObject("exerciseLoadPrefs")
            if (loadPrefs != null) {
                for (id in ids) {
                    if (id == survivor || id in referenced) continue
                    val pref = loadPrefs.opt(id) ?: continue
                    if (!loadPrefs.has(survivor)) loadPrefs.put(survivor, pref)
                    loadPrefs.remove(id)
                    changed = true
                }
            }
        }
        // descendingSet() y no reversed(): TreeSet.reversed() (Java 21
        // SequencedSet) no existe en API < 35 (NoSuchMethodError en API 30).
        for (i in toRemove.descendingSet()) {
            catalog.remove(i)
            changed = true
        }

        if (!changed) return false

        val untouched = state.optInt("syncRevision", -1) == 0 &&
            state.optString("updatedAt") == "1970-01-01T00:00:00Z" &&
            state.optString("lastWriterDeviceId") == "" &&
            listOf("workouts", "routines", "bodyWeights", "favoriteTimers")
                .all { state.optJSONArray(it)?.length() == 0 } &&
            state.optJSONObject("activeSession") == null &&
            state.optJSONObject("settings")?.length() == 0 &&
            state.optJSONObject("exerciseLoadPrefs")?.length() == 0 &&
            (0 until catalog.length()).none { catalog.getJSONObject(it).optBoolean("isCustom") }
        if (!untouched) {
            state.put("syncRevision", state.optInt("syncRevision", 0) + 1)
            state.put("updatedAt", now.toString())
            state.put("lastWriterDeviceId", "android-catalog-refresh")
        }
        return true
    }
    private fun collectExerciseIds(node:Any?,into:MutableSet<String>) {
        when(node) {
            is org.json.JSONArray -> (0 until node.length()).forEach {collectExerciseIds(node.opt(it),into)}
            is JSONObject -> {
                node.optString("exerciseId").takeIf {it.isNotBlank()}?.let(into::add)
                node.optJSONObject("exercise")?.optString("id")?.takeIf {it.isNotBlank()}?.let(into::add)
                node.keys().forEach {key ->collectExerciseIds(node.opt(key),into)}
            }
        }
    }
}
