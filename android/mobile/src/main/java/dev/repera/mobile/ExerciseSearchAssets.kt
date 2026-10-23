package dev.repera.mobile

import android.content.Context
import org.json.JSONObject
import dev.repera.domain.ExerciseAliasSearch

object ExerciseSearchAssets {
    fun load(context: Context): Map<String, String> {
        val source = context.assets.open("exercise_search_aliases.json")
            .bufferedReader(Charsets.UTF_8).use { it.readText() }
        val data = JSONObject(source)
        return data.keys().asSequence().associate { key ->
            ExerciseAliasSearch.normalize(key) to data.getString(key)
        }
    }
}
