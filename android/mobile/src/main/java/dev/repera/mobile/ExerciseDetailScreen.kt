package dev.repera.mobile

import dev.repera.mobile.monetization.LocalSubscriptions
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
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
    exerciseSeries: (String, ExerciseProgressMetric, ExerciseProgressRange) ->
        List<ExerciseProgressPoint> = { _, _, _ -> emptyList() },
    highlightSessionId: String? = null,
    highlightInstanceId: String? = null,
    sessionAppearances: (exerciseId: String, highlightSessionId: String,
        instanceId: String?) ->
        Pair<SessionAppearance?, SessionAppearance?> = { _, _, _ -> null to null },
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val aliases = remember(context) { ExerciseSearchAssets.load(context) }
    // Bloque «Esta sesión» (paridad ExerciseThisSessionCard iOS): solo al
    // abrir la ficha desde un entreno terminado.
    val appearancePair = remember(entry.id, highlightSessionId, highlightInstanceId) {
        highlightSessionId?.let { sessionAppearances(entry.id, it, highlightInstanceId) }
    }
    val thisSessionAppearance = appearancePair?.first
    val priorSessionAppearance = appearancePair?.second
    val isMobility = entry.sportTag == "Movilidad"
    val frames = remember(entry.id) {
        ExerciseArtImages.carouselStems(context, entry.name, isMobility, aliases,
            captionCount = entry.instructions.count { it.isNotBlank() })
    }
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            TextButton(onClick = onBack) { Text("‹ Ejercicios") }
            Text(entry.displayName, style = MaterialTheme.typography.headlineMedium)
        }
        if (thisSessionAppearance != null) {
            item(key = "this-session-" + highlightSessionId) {
                ThisSessionCard(thisAppearance = thisSessionAppearance,
                    prior = priorSessionAppearance)
            }
        }
        item {
            // Paridad iOS FreeExerciseSummaryCard: la evolución completa es Pro;
            // Gratis ve el teaser que abre el paywall con contexto exerciseEvolution.
            val subscriptions = LocalSubscriptions.current
            val evolutionAllowed = subscriptions
                ?.decision(dev.repera.domain.monetization.ReperaFeature.EXERCISE_EVOLUTION)
                ?.allowed ?: true
            if (evolutionAllowed) {
                ExerciseEvolutionSection(entry = entry, exerciseSeries = exerciseSeries)
            } else {
                dev.repera.mobile.monetization.ProTeaserCard(
                    title = "Tu evolución",
                    bodyText = "Consulta todas tus marcas, compara tus entrenamientos y descubre cómo has progresado con este ejercicio.",
                    cta = "Ver con Repera Pro",
                    appearance = dev.repera.mobile.monetization.ProTeaserAppearance.EVOLUTION
                ) {
                    subscriptions?.presentPaywall(
                        dev.repera.domain.monetization.PaywallContext.EXERCISE_EVOLUTION,
                        feature = dev.repera.domain.monetization.ReperaFeature.EXERCISE_EVOLUTION
                    )
                }
            }
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

/** Evolución del ejercicio: métricas, rango y gráfica
 *  (ExerciseEvolutionPanel de iOS). */
@Composable
private fun ExerciseEvolutionSection(
    entry: ExerciseEntry,
    exerciseSeries: (String, ExerciseProgressMetric, ExerciseProgressRange) ->
        List<ExerciseProgressPoint>
) {
    val metrics = ExerciseProgressMetric.available(
        if (entry.loggingStyle == "machineWork") "machineWork"
        else if (entry.loggingStyle == "repsAndTime") "repsAndTime"
        else "loadAndReps")
    var metric by rememberSaveable { mutableStateOf(metrics.first().wire) }
    var range by rememberSaveable {
        mutableStateOf(ExerciseProgressRange.ALL.wire)
    }
    val selectedMetric = metrics.firstOrNull { it.wire == metric } ?: metrics.first()
    val selectedRange = ExerciseProgressRange.entries
        .firstOrNull { it.wire == range } ?: ExerciseProgressRange.ALL
    val points = remember(entry.id, metric, range) {
        exerciseSeries(entry.id, selectedMetric, selectedRange)
    }
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Evolución", style = MaterialTheme.typography.titleLarge)
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier.fillMaxWidth()
                    .horizontalScroll(rememberScrollState())) {
                metrics.forEach { m ->
                    FilterChip(selected = m.wire == metric,
                        onClick = { metric = m.wire },
                        label = { Text(m.title) })
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                ExerciseProgressRange.entries.forEach { r ->
                    FilterChip(selected = r.wire == range,
                        onClick = { range = r.wire },
                        label = { Text(r.title) })
                }
            }
            if (points.isEmpty()) {
                Text("Todavía no hay sesiones registradas con esta métrica.",
                    style = MaterialTheme.typography.bodyMedium)
            } else {
                val line = MaterialTheme.colorScheme.primary
                androidx.compose.foundation.Canvas(modifier = Modifier
                    .fillMaxWidth().height(120.dp)) {
                    val minV = points.minOf { it.value }
                    val maxV = points.maxOf { it.value }
                    val span = (maxV - minV).coerceAtLeast(1e-9)
                    fun x(i: Int) = if (points.size == 1) size.width / 2f
                        else i * size.width / (points.size - 1)
                    fun y(v: Double) =
                        size.height - ((v - minV) / span * size.height * 0.9f).toFloat() - size.height * 0.05f
                    val path = androidx.compose.ui.graphics.Path()
                    points.forEachIndexed { i, p ->
                        if (i == 0) path.moveTo(x(i), y(p.value))
                        else path.lineTo(x(i), y(p.value))
                    }
                    drawPath(path, color = line,
                        style = androidx.compose.ui.graphics.drawscope.Stroke(width = 4f))
                    points.forEachIndexed { i, p ->
                        drawCircle(color = line, radius = 5f,
                            center = androidx.compose.ui.geometry.Offset(x(i), y(p.value)))
                    }
                }
                val last = points.last()
                Text("Último: ${formatPointValue(selectedMetric, last)} · " +
                    "${points.size} registros",
                    style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
}

private fun formatPointValue(metric: ExerciseProgressMetric,
                             p: ExerciseProgressPoint): String = when (metric) {
    ExerciseProgressMetric.TOP_SET ->
        "${p.value} kg × ${p.reps ?: "?"}"
    ExerciseProgressMetric.ESTIMATED_ONE_RM -> "%.1f kg".format(p.value)
    ExerciseProgressMetric.EFFORT -> "RIR %.1f".format(p.value)
    ExerciseProgressMetric.BEST_HOLD, ExerciseProgressMetric.DURATION ->
        "${p.value.toInt()} s"
    else -> "${p.value.toInt()} ${p.quantityUnit ?: "reps"}"
}


/** Tarjeta «Esta sesión» (port 1:1 de ExerciseThisSessionCard iOS):
 *  WOD de catálogo → marca global del benchmark; WOD libre / series → movimiento. */
@Composable
private fun ThisSessionCard(
    thisAppearance: SessionAppearance,
    prior: SessionAppearance?
) {
    val sectionTitle = if (thisAppearance.isGlobalWodScore &&
        !thisAppearance.wodTemplateName.isNullOrBlank())
        "Esta sesión · " + thisAppearance.wodTemplateName
    else "Esta sesión"
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(sectionTitle, style = MaterialTheme.typography.titleSmall)
            SessionAppearanceBlock(thisAppearance, emphasizeDate = true)
            if (prior != null) {
                Text(if (thisAppearance.isGlobalWodScore) "Intento anterior" else "Anterior",
                    style = MaterialTheme.typography.labelSmall)
                SessionAppearanceBlock(prior, emphasizeDate = false)
            } else if (thisAppearance.isGlobalWodScore) {
                Text("Sin intentos previos de este WOD para comparar.",
                    style = MaterialTheme.typography.bodySmall)
            } else if (thisAppearance.setLines.isEmpty()) {
                Text("Sin marcas previas de este movimiento para comparar.",
                    style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

@Composable
private fun SessionAppearanceBlock(row: SessionAppearance, emphasizeDate: Boolean) {
    val day = java.time.Instant.ofEpochMilli(row.dateEpochMillis)
        .atZone(java.time.ZoneId.systemDefault()).toLocalDate()
        .format(java.time.format.DateTimeFormatter.ofPattern("d MMM yyyy",
            java.util.Locale("es", "ES")))
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically) {
            Text(day,
                style = if (emphasizeDate) MaterialTheme.typography.bodyMedium
                else MaterialTheme.typography.bodySmall,
                modifier = Modifier.weight(1f))
            row.wodScoreLabel?.let { score ->
                Text(score, style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.primary)
            }
        }
        if (row.isGlobalWodScore) {
            row.wodFormatName?.let {
                Text(it, style = MaterialTheme.typography.labelMedium)
            }
        } else {
            if (row.wodFormatName != null) {
                Text(row.wodFormatName, style = MaterialTheme.typography.labelMedium)
            } else if (row.sessionTitle.isNotBlank()) {
                Text(row.sessionTitle, style = MaterialTheme.typography.labelMedium,
                    maxLines = 1)
            }
            row.prescriptionLine?.let {
                Text(it, style = MaterialTheme.typography.bodyMedium)
            }
            row.setLines.forEach { line ->
                Text(line, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}
