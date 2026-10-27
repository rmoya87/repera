package dev.repera.mobile

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

internal fun resolveWodExercise(name:String,exercises:List<ExerciseEntry>,aliases:Map<String,String>):ExerciseEntry {
    val canonical=dev.repera.domain.CrossFitGlossary.canonicalName(name,aliases)
    return exercises.firstOrNull {dev.repera.domain.ExerciseEquivalence.sameName(it.name,canonical) ||
        dev.repera.domain.ExerciseEquivalence.sameName(it.name,name)} ?:
        ExerciseEntry("wod-preview:$canonical",canonical,false,false,muscleGroup="WOD",isCustom=true)
}

/** Read-only resolution: a missing catalog movement never creates a private exercise. */
@Composable
internal fun WodExerciseThumbnail(exercise:ExerciseEntry,aliases:Map<String,String>) {
    val context=LocalContext.current
    val stem=remember(exercise.name,exercise.sportTag) {
        ExerciseArtImages.carouselStems(context,exercise.name,exercise.sportTag=="Movilidad",aliases,
            exercise.instructions.count {it.isNotBlank()}).firstOrNull()
    }
    val bitmap by produceState<ImageBitmap?>(null,stem) {value=stem?.let {ExerciseArtImages.load(context,it)}}
    bitmap?.let {Image(it,exercise.displayName,Modifier.size(40.dp),contentScale=ContentScale.Crop)}
}
