package dev.repera.mobile

import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.customActions
import dev.repera.mobile.monetization.LocalSubscriptions
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.testTag
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
    testedOneRM:Double? = null,
    estimatedOneRM:Double? = null,
    incrementKg:Double = 2.5,
    onSetTestedOneRM:(Double?)->Unit = {},
    busy:Boolean = false,
    onQuickLog:()->Unit = {},
    // Apple ExerciseDetailView toolbar: star next to quick log. Null hides it.
    onToggleFavorite:(()->Unit)? = null,
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
    ReadableColumn {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            TextButton(onClick = onBack) { Text("‹ Ejercicios") }
            Text(entry.displayName, style = MaterialTheme.typography.headlineMedium)
            Row(verticalAlignment = Alignment.CenterVertically) {
                TextButton(onClick=onQuickLog,enabled=!busy) {Text("Apuntar ejercicio")}
                if (onToggleFavorite != null) {
                    androidx.compose.material3.IconButton(onClick = onToggleFavorite, enabled = !busy,
                        modifier = Modifier.testTag("exercise_detail_favorite")) {
                        androidx.compose.material3.Icon(
                            if (entry.isFavorite) androidx.compose.material.icons.Icons.Default.Star
                            else androidx.compose.material.icons.Icons.Default.StarBorder,
                            contentDescription = if (entry.isFavorite) "Quitar de favoritos" else "Favorito",
                            tint = if (entry.isFavorite) brandGreen
                            else MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
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
                ExerciseEvolutionSection(entry = entry, exerciseSeries = exerciseSeries, testedOneRM=testedOneRM, onSetTestedOneRM=onSetTestedOneRM,busy=busy)
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
        if (!isMobility) item {
            SuggestedExerciseLoadCard(testedOneRM,estimatedOneRM,incrementKg)
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
            MuscleEquipmentCard(entry)
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
internal fun ExerciseEvolutionSection(
    entry: ExerciseEntry,
    exerciseSeries: (String, ExerciseProgressMetric, ExerciseProgressRange) ->
        List<ExerciseProgressPoint>,
    testedOneRM:Double?,onSetTestedOneRM:(Double?)->Unit,busy:Boolean
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
    var selectedPoint by remember(entry.id,metric,range) {mutableStateOf<Int?>(null)}
    val ceiling=testedOneRM?.takeIf { entry.sportTag!="Movilidad" && entry.loggingStyle!="machineWork" && entry.loggingStyle!="repsAndTime" && (selectedMetric==ExerciseProgressMetric.TOP_SET || selectedMetric==ExerciseProgressMetric.ESTIMATED_ONE_RM) }
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Evolución", style = MaterialTheme.typography.titleLarge)
            if(entry.sportTag!="Movilidad" && entry.loggingStyle!="machineWork" && entry.loggingStyle!="repsAndTime")
                TestedOneRMEditor(testedOneRM,busy,onSetTestedOneRM)
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
                val ceilingColor=MaterialTheme.colorScheme.onSurfaceVariant
                fun selectAt(x:Float,width:Int) {
                    selectedPoint=if(points.size==1) 0 else ((x/width.coerceAtLeast(1))*(points.size-1)).toInt().coerceIn(points.indices)
                }
                androidx.compose.foundation.Canvas(modifier = Modifier
                    .fillMaxWidth().height(120.dp).testTag("exercise_evolution_chart")
                    .semantics {
                        contentDescription="Evolución de ${points.size} registros"
                        customActions=listOf(
                            androidx.compose.ui.semantics.CustomAccessibilityAction("Punto anterior") {selectedPoint=ChartSelectionStep.step(selectedPoint,-1,points.size);true},
                            androidx.compose.ui.semantics.CustomAccessibilityAction("Punto siguiente") {selectedPoint=ChartSelectionStep.step(selectedPoint,1,points.size);true})
                    }
                    .pointerInput(points) {detectTapGestures {selectAt(it.x,size.width)}}
                    .pointerInput(points) {detectHorizontalDragGestures {change,_ -> selectAt(change.position.x,size.width)}}) {
                    val minV = minOf(points.minOf { it.value },ceiling ?: Double.MAX_VALUE)
                    val maxV = maxOf(points.maxOf { it.value },ceiling ?: 0.0)
                    val span = (maxV - minV).coerceAtLeast(1e-9)
                    fun x(i: Int) = if (points.size == 1) size.width / 2f
                        else i * size.width / (points.size - 1)
                    fun y(v: Double) =
                        size.height - ((v - minV) / span * size.height * 0.9f).toFloat() - size.height * 0.05f
                    ceiling?.let {drawLine(ceilingColor,androidx.compose.ui.geometry.Offset(0f,y(it)),androidx.compose.ui.geometry.Offset(size.width,y(it)),strokeWidth=2f,
                        pathEffect=androidx.compose.ui.graphics.PathEffect.dashPathEffect(floatArrayOf(10f,8f)))}
                    selectedPoint?.let {i -> drawLine(ceilingColor,androidx.compose.ui.geometry.Offset(x(i),0f),androidx.compose.ui.geometry.Offset(x(i),size.height),strokeWidth=2f)}
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
                ceiling?.let {Text("Tope 1RM · ${dev.repera.domain.ReperaNumberFormat.decimal(it)} kg",style=MaterialTheme.typography.bodySmall)}
                val last = points[selectedPoint ?: points.lastIndex]
                Text(java.time.Instant.ofEpochMilli(last.epochMillis).atZone(java.time.ZoneId.systemDefault()).toLocalDate().format(reperaDayFormatter),style=MaterialTheme.typography.bodySmall)
                Text("${if(selectedPoint==null) "Último" else "Seleccionado"}: ${formatPointValue(selectedMetric, last)} · " +
                    "${points.size} registros",
                    style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
}

private fun formatPointValue(metric: ExerciseProgressMetric,
                             p: ExerciseProgressPoint): String = when (metric) {
    ExerciseProgressMetric.TOP_SET ->
        "${dev.repera.domain.ReperaNumberFormat.decimal(p.value)} kg × ${p.reps ?: "?"}"
    ExerciseProgressMetric.ESTIMATED_ONE_RM -> "${dev.repera.domain.ReperaNumberFormat.decimal(p.value)} kg"
    ExerciseProgressMetric.EFFORT -> "RIR ${dev.repera.domain.ReperaNumberFormat.decimal(p.value)}"
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

/** Apple 49febc33: tarjeta "Músculos y equipo" con filas Músculo / También /
 *  Equipo / Disciplina, chips con glifos corporales. Interna para permitir
 *  render headless inspeccionable. */
@Composable
internal fun MuscleEquipmentCard(entry: ExerciseEntry) {
    val primary = entry.targetMuscle.ifBlank { entry.muscleGroup }
    val seen = mutableSetOf(primary.lowercase())
    val secondaries = entry.secondaryMuscles.mapNotNull { raw ->
        dev.repera.domain.MuscleTaxonomy.canonical(raw) ?: return@mapNotNull null
        val label = dev.repera.domain.MuscleTaxonomy.displayName(raw)
        val key = label.lowercase()
        if (key.isEmpty() || key in seen) return@mapNotNull null
        seen.add(key); label
    }
    // detailMeta iOS: aparatos separados por coma, en chips propios.
    val equipments = entry.equipment.split(",").map { it.trim() }.filter { it.isNotEmpty() }
    val sports = entry.disciplineTags.filter { it.isNotBlank() }
    if (primary.isBlank()) return
    Card(colors = CardDefaults.cardColors(
        containerColor = MaterialTheme.colorScheme.surfaceVariant)) {
        Column(modifier = Modifier.padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)) {
            MetaChipRow("Músculo") {
                MuscleMetaChip(primary, primary, emphasized = true)
            }
            if (secondaries.isNotEmpty()) MetaChipRow("También") {
                secondaries.forEach { MuscleMetaChip(it, it, emphasized = false) }
            }
            if (equipments.isNotEmpty()) MetaChipRow("Equipo") {
                equipments.forEach { eq ->
                    IconMetaChip(eq, ExerciseCategorySymbols.equipmentSymbol(eq))
                }
            }
            if (sports.isNotEmpty()) MetaChipRow("Disciplina") {
                sports.forEach { sp ->
                    IconMetaChip(sp, ExerciseCategorySymbols.discipline(sp))
                }
            }
        }
    }
}

@Composable
private fun MetaChipRow(title: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(title, style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.horizontalScroll(rememberScrollState())) {
            content()
        }
    }
}

@Composable
private fun IconMetaChip(label: String, icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Row(verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        modifier = Modifier
            .background(MaterialTheme.colorScheme.surface, androidx.compose.foundation.shape.CircleShape)
            .padding(horizontal = 12.dp, vertical = 7.dp)) {
        androidx.compose.material3.Icon(icon, contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurface, modifier = Modifier.size(16.dp))
        Text(label, color = MaterialTheme.colorScheme.onSurface,
            style = MaterialTheme.typography.labelMedium)
    }
}

@Composable
private fun MuscleMetaChip(label: String, muscle: String, emphasized: Boolean) {
    val bg = if (emphasized) MaterialTheme.colorScheme.primary
             else MaterialTheme.colorScheme.surfaceVariant
    val fg = if (emphasized) MaterialTheme.colorScheme.onPrimary
             else MaterialTheme.colorScheme.onSurface
    Row(verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        modifier = Modifier
            .background(bg, androidx.compose.foundation.shape.CircleShape)
            .padding(horizontal = 12.dp, vertical = 7.dp)) {
        MuscleChipGlyph(muscle, emphasized)
        Text(label, color = fg,
            style = if (emphasized) MaterialTheme.typography.labelLarge
                    else MaterialTheme.typography.labelMedium)
    }
}
