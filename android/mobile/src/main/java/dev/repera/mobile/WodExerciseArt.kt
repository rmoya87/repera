package dev.repera.mobile

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

internal fun resolveWodExercise(
    name: String, exercises: List<ExerciseEntry>, aliases: Map<String,String>,
    packaged: List<ExerciseEntry> = emptyList(), exerciseId: String? = null,
    notes: String? = null
): ExerciseEntry {
    fun entry(e: ExerciseEntry) = dev.repera.domain.CatalogExercise(
        e.id, e.name, e.searchAliases, e.isCustom, e.isCatalogArchived)
    val match = dev.repera.domain.CrossFitGlossary.catalogExercise(
        dev.repera.domain.WODMovement(name = name, exerciseId = exerciseId, notes = notes),
        exercises.map(::entry), packaged.map(::entry))
    if (match != null) (exercises + packaged).firstOrNull { it.id == match.id }?.let { return it }
    val canonical = dev.repera.domain.CrossFitGlossary.canonicalName(name, aliases)
    return ExerciseEntry("wod-preview:$canonical", canonical, false, false,
        muscleGroup = "WOD", isCustom = true)
}

/** Same bundled asset used by account hydration. Read-only: never inserts into user state. */
internal fun packagedWodExercises(seed: org.json.JSONArray): List<ExerciseEntry> =
    (0 until seed.length()).map { seed.getJSONObject(it) }.filter {
        !it.optBoolean("isCustom") && !it.optBoolean("isCatalogArchived") &&
            it.optString("name") in setOf("Burpee to target", "Toes to bar")
    }.map { e -> ExerciseEntry(e.getString("id"), e.getString("name"), false, false,
        muscleGroup = e.optString("muscleGroup"), sportTag = e.optString("sportTag"),
        searchAliases = PublishedCatalogAliases.read(e)) }

/** Read-only resolution: a missing catalog movement never creates a private exercise. */
@Composable
internal fun WodExerciseThumbnail(
    exercise: ExerciseEntry,
    aliases: Map<String, String>,
    size: androidx.compose.ui.unit.Dp = 40.dp,
) {
    val context=LocalContext.current
    val stem=remember(exercise.name,exercise.sportTag) {
        ExerciseArtImages.carouselStems(context,exercise.name,exercise.sportTag=="Movilidad",aliases,
            exercise.instructions.count {it.isNotBlank()}).firstOrNull()
    }
    val bitmap by produceState<ImageBitmap?>(null,stem) {value=stem?.let {ExerciseArtImages.load(context,it)}}
    bitmap?.let {
        Image(
            it,
            exercise.displayName,
            Modifier
                .size(size)
                .clip(RoundedCornerShape(10.dp)),
            contentScale = ContentScale.Crop
        )
    }
}
