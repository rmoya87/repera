package dev.repera.mobile

import android.content.Context
import org.json.JSONObject
import dev.repera.domain.ExerciseAliasSearch

object ExerciseSearchAssets {
    // Recursos empaquetados inmutables: reutilizar el índice entre pantallas,
    // evitando JSON y normalización en el hilo UI en cada navegación.
    @Volatile private var cachedAliases: Map<String, String>? = null

    fun load(context: Context): Map<String, String> =
        cachedAliases ?: synchronized(this) {
            cachedAliases ?: readAssets(context.applicationContext).also { cachedAliases = it }
        }

    private fun readAssets(context: Context): Map<String, String> {
        val source = context.assets.open("exercise_search_aliases.json")
            .bufferedReader(Charsets.UTF_8).use { it.readText() }
        val data = JSONObject(source)
        val mobility = context.assets.open("mobility_aliases.json")
            .bufferedReader(Charsets.UTF_8).use { JSONObject(it.readText()) }
        val hyrox = context.assets.open("hyrox_aliases.json")
            .bufferedReader(Charsets.UTF_8).use { JSONObject(it.readText()) }
        val known = data.keys().asSequence().associate { key ->
            ExerciseAliasSearch.normalize(key) to data.getString(key)
        }.toMutableMap()
        mobility.keys().forEach { key ->
            known.putIfAbsent(ExerciseAliasSearch.normalize(key), mobility.getString(key))
        }
        hyrox.keys().forEach { key ->
            known.putIfAbsent(ExerciseAliasSearch.normalize(key), hyrox.getString(key))
        }
        return known
    }
}
