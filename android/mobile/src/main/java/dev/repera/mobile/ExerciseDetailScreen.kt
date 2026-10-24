package dev.repera.mobile

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

/**
 * Ficha de ejercicio: héroe + carrusel de pasos numerados (semántica iOS),
 * descripción e instrucciones localizadas del catálogo semilla y músculos.
 */
@Composable
internal fun ExerciseDetailScreen(
    entry: ExerciseEntry,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val aliases = remember(context) { ExerciseSearchAssets.load(context) }
    val isMobility = entry.sportTag == "Movilidad"
    val frames = remember(entry.id) {
        ExerciseArtImages.carouselStems(context, entry.name, isMobility, aliases)
    }
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            TextButton(onClick = onBack) { Text("‹ Ejercicios") }
            Text(entry.name, style = MaterialTheme.typography.headlineMedium)
        }
        if (frames.size <= 1) {
            item { ArtImage(frames.firstOrNull(), entry.name, Modifier.fillMaxWidth().aspectRatio(4f / 3f)) }
        } else {
            item {
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(frames, key = { it }) { stem ->
                        ArtImage(stem, entry.name,
                            Modifier.height(220.dp).aspectRatio(4f / 3f))
                    }
                }
            }
        }
        item {
            val facts = buildList {
                if (entry.muscleGroup.isNotBlank()) add(entry.muscleGroup)
                if (entry.equipment.isNotBlank()) add(entry.equipment)
                if (entry.targetMuscle.isNotBlank()) add(entry.targetMuscle)
            }
            if (facts.isNotEmpty()) {
                Text(facts.joinToString(" · "), style = MaterialTheme.typography.labelLarge)
            }
            if (entry.secondaryMuscles.isNotEmpty()) {
                Text("Secundarios: " + entry.secondaryMuscles.joinToString(", "),
                    style = MaterialTheme.typography.bodySmall)
            }
        }
        entry.detailDescription?.let { description ->
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(description, style = MaterialTheme.typography.bodyMedium)
                    }
                }
            }
        }
        if (entry.instructions.isNotEmpty()) {
            item { Text("Cómo hacerlo", style = MaterialTheme.typography.titleMedium) }
            itemsIndexed(entry.instructions, key = { index, _ -> index }) { index, step ->
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("${index + 1}. $step", style = MaterialTheme.typography.bodyMedium)
                    }
                }
            }
        }
        if (entry.detailDescription == null && entry.instructions.isEmpty()) {
            item {
                Text("Ficha sin textos todavía; el arte y el registro ya están disponibles.",
                    style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

@Composable
private fun ArtImage(stem: String?, contentDescription: String, modifier: Modifier = Modifier) {
    if (stem == null) return
    val context = LocalContext.current
    val bitmap by produceState<ImageBitmap?>(initialValue = null, stem) {
        value = ExerciseArtImages.load(context, stem)
    }
    bitmap?.let {
        Image(
            bitmap = it,
            contentDescription = contentDescription,
            modifier = modifier.clip(RoundedCornerShape(12.dp)),
            contentScale = ContentScale.Crop
        )
    }
}
