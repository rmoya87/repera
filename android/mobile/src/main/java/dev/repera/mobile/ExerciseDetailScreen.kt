package dev.repera.mobile

import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.customActions
import dev.repera.domain.ReperaNumberFormat
import dev.repera.mobile.monetization.LocalSubscriptions
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.EditNote
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

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
    exerciseSummary: (String) -> dev.repera.domain.ExerciseHistorySummary? = { null },
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
        contentPadding = reperaScrollContentPadding(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                ReperaToolbarGlassIconButton(
                    icon = Icons.AutoMirrored.Outlined.ArrowBack,
                    contentDescription = "Volver",
                    onClick = onBack
                )
                Spacer(Modifier.weight(1f))
                ReperaToolbarGlassIconButton(
                    icon = Icons.Outlined.EditNote,
                    contentDescription = "Apuntar ejercicio",
                    onClick = onQuickLog,
                    enabled = !busy
                )
                if (onToggleFavorite != null) {
                    ReperaToolbarGlassIconButton(
                        icon = if (entry.isFavorite) Icons.Outlined.Star
                        else Icons.Outlined.StarBorder,
                        contentDescription = if (entry.isFavorite) "Quitar de favoritos" else "Favorito",
                        onClick = onToggleFavorite,
                        enabled = !busy,
                        active = entry.isFavorite,
                        modifier = Modifier.testTag("exercise_detail_favorite")
                    )
                }
            }
            ReperaPageHeader(title = entry.displayName)
        }
        // Orden: título → imagen+descripción unidas → cómo (un cuadro) → músculos → carga → evolución
        item {
            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                Column {
                    ExerciseArtHero(
                        frames = frames,
                        name = entry.name,
                        clipTopOnly = entry.detailDescription != null
                    )
                    entry.detailDescription?.let { description ->
                        Text(
                            description,
                            style = MaterialTheme.typography.bodyMedium,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 14.dp)
                        )
                    }
                }
            }
        }
        if (thisSessionAppearance != null) {
            item(key = "this-session-" + highlightSessionId) {
                ThisSessionCard(
                    thisAppearance = thisSessionAppearance,
                    prior = priorSessionAppearance
                )
            }
        }
        if (entry.instructions.isNotEmpty()) {
            item { ReperaSectionTitle("Cómo hacerlo") }
            item {
                ReperaCard(modifier = Modifier.fillMaxWidth()) {
                    Column(
                        Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        entry.instructions.forEachIndexed { index, step ->
                            if (index > 0) {
                                HorizontalDivider(
                                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                                )
                            }
                            Text(
                                "${index + 1}. $step",
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                    }
                }
            }
        }
        item { MuscleEquipmentCard(entry) }
        if (!isMobility) {
            item { ReperaSectionTitle("Carga sugerida") }
            item { SuggestedExerciseLoadCard(testedOneRM, estimatedOneRM, incrementKg) }
        }
        item {
            val subscriptions = LocalSubscriptions.current
            val evolutionAllowed = subscriptions
                ?.decision(dev.repera.domain.monetization.ReperaFeature.EXERCISE_EVOLUTION)
                ?.allowed ?: true
            if (evolutionAllowed) {
                ExerciseEvolutionSection(
                    entry = entry,
                    exerciseSeries = exerciseSeries,
                    testedOneRM = testedOneRM,
                    onSetTestedOneRM = onSetTestedOneRM,
                    busy = busy,
                    summary = exerciseSummary(entry.id)
                )
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
        if (entry.detailDescription == null && entry.instructions.isEmpty()) {
            item {
                ReperaEmptyState(
                    title = "Ficha sin textos todavía",
                    subtitle = "El arte y el registro ya están disponibles"
                )
            }
        }
    }
    }
}

@Composable
private fun ArtImage(
    stem: String?,
    contentDescription: String,
    modifier: Modifier = Modifier,
    shape: RoundedCornerShape = RoundedCornerShape(0.dp)
) {
    if (stem == null) return
    val context = LocalContext.current
    val bitmap by produceState<ImageBitmap?>(initialValue = null, stem) {
        value = ExerciseArtImages.load(context, stem)
    }
    bitmap?.let {
        Image(
            bitmap = it,
            contentDescription = contentDescription,
            modifier = modifier.clip(shape),
            contentScale = ContentScale.Crop
        )
    }
}

/** I-31 hero full-width con swipe e indicador «1/N». */
@Composable
private fun ExerciseArtHero(
    frames: List<String>,
    name: String,
    clipTopOnly: Boolean = false
) {
    val imageShape = if (clipTopOnly) {
        RoundedCornerShape(topStart = 12.dp, topEnd = 12.dp)
    } else {
        RoundedCornerShape(12.dp)
    }
    if (frames.isEmpty()) {
        Box(
            Modifier
                .fillMaxWidth()
                .aspectRatio(4f / 3f)
                .background(MaterialTheme.colorScheme.surfaceVariant, imageShape)
        )
        return
    }
    if (frames.size == 1) {
        ArtImage(
            frames.first(),
            name,
            Modifier.fillMaxWidth().aspectRatio(4f / 3f),
            shape = imageShape
        )
        return
    }
    var page by rememberSaveable(frames) { mutableStateOf(0) }
    Box(
        Modifier
            .fillMaxWidth()
            .aspectRatio(4f / 3f)
            .clip(imageShape)
            .pointerInput(frames, page) {
                detectHorizontalDragGestures { _, dragAmount ->
                    if (dragAmount < -40 && page < frames.lastIndex) page++
                    else if (dragAmount > 40 && page > 0) page--
                }
            }
            .testTag("exercise_art_hero")
    ) {
        ArtImage(
            frames[page.coerceIn(0, frames.lastIndex)],
            name,
            Modifier.fillMaxSize(),
            shape = RoundedCornerShape(0.dp)
        )
        Text(
            "${page + 1}/${frames.size}",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(12.dp)
                .background(Color.Black.copy(alpha = 0.45f), RoundedCornerShape(8.dp))
                .padding(horizontal = 8.dp, vertical = 4.dp)
                .testTag("exercise_art_page")
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
    testedOneRM:Double?,onSetTestedOneRM:(Double?)->Unit,busy:Boolean,
    summary: dev.repera.domain.ExerciseHistorySummary? = null
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
    var editingTope by remember { mutableStateOf(false) }
    var topeDraft by remember { mutableStateOf("") }
    val isStrengthLogging = entry.sportTag != "Movilidad" &&
        entry.loggingStyle != "machineWork" && entry.loggingStyle != "repsAndTime"
    val ceiling=testedOneRM?.takeIf { isStrengthLogging && (selectedMetric==ExerciseProgressMetric.TOP_SET || selectedMetric==ExerciseProgressMetric.ESTIMATED_ONE_RM) }
    fun beginTopeEdit() {
        if (busy) return
        topeDraft = testedOneRM?.let { ReperaNumberFormat.decimal(it) }.orEmpty()
        editingTope = true
    }
    fun commitTopeEdit() {
        if (!editingTope) return
        val trimmed = topeDraft.trim()
        when {
            trimmed.isEmpty() || trimmed == "—" -> onSetTestedOneRM(null)
            else -> {
                val v = ReperaNumberFormat.parse(trimmed)
                if (v != null && v > 0) {
                    onSetTestedOneRM(kotlin.math.round(v * 10.0) / 10.0)
                }
            }
        }
        editingTope = false
    }
    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        androidx.compose.foundation.layout.Column(Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Evolución", style = MaterialTheme.typography.titleLarge)
            summary?.let { h ->
                val isMobility = entry.sportTag == "Movilidad"
                val isMobilityHold = entry.mobilityHold
                val style = when (entry.loggingStyle) {
                    "machineWork" -> "machineWork"
                    "repsAndTime" -> "repsAndTime"
                    else -> "loadAndReps"
                }
                val isStrength = !isMobility && style == "loadAndReps"
                fun fmtDur(sec: Int): String {
                    val m = sec / 60; val ss = sec % 60
                    return if (ss == 0) "$m:00" else "%d:%02d".format(m, ss)
                }
                if (isMobility) {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        EvoTile(if (isMobilityHold) "Mejor sostén" else "Duración máx.",
                            h.bestDurationSeconds?.let { fmtDur(it) } ?: "—", Modifier.weight(1f))
                        if (!isMobilityHold) {
                            EvoTile("Reps máx.", h.bestReps?.toString() ?: "—", Modifier.weight(1f))
                        }
                        EvoTile("Sesiones", if (h.hasData) "${h.timesPerformed}" else "—", Modifier.weight(1f))
                    }
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        EvoTile("Último tiempo", h.lastDurationSeconds?.let { fmtDur(it) } ?: "—", Modifier.weight(1f))
                        if (!isMobilityHold) {
                            EvoTile("Últimas reps", h.lastReps?.toString() ?: "—", Modifier.weight(1f))
                        }
                    }
                } else if (isStrength) {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        TopeOneRMTile(
                            testedOneRM = testedOneRM,
                            editing = editingTope,
                            draft = topeDraft,
                            modifier = Modifier.weight(1f),
                            onBeginEdit = ::beginTopeEdit
                        )
                        EvoTile(
                            "Máx.",
                            h.maxWeightKg?.let {
                                ReperaNumberFormat.decimal(it) + " kg"
                            } ?: "—",
                            Modifier.weight(1f)
                        )
                        EvoTile(
                            "e1RM",
                            h.estimatedOneRM?.let {
                                ReperaNumberFormat.decimal(it) + " kg"
                            } ?: "—",
                            Modifier.weight(1f)
                        )
                    }
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        EvoTile("Reps máx.", h.bestReps?.toString() ?: "—", Modifier.weight(1f))
                        EvoTile("Veces", if (h.hasData) "${h.timesPerformed}" else "—", Modifier.weight(1f))
                    }
                } else {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        if (style == "machineWork") {
                            EvoTile("Cal máx.", h.bestCalories?.toString() ?: "—", Modifier.weight(1f))
                            EvoTile("Mejor m", h.bestMeters?.toString() ?: "—", Modifier.weight(1f))
                        } else {
                            EvoTile("Reps máx.", h.bestReps?.toString() ?: "—", Modifier.weight(1f))
                            EvoTile("Tiempo", h.bestDurationSeconds?.let { fmtDur(it) } ?: "—", Modifier.weight(1f))
                        }
                        EvoTile("Veces", if (h.hasData) "${h.timesPerformed}" else "—", Modifier.weight(1f))
                    }
                    if (style == "machineWork" || entry.loggingStyle == "repsAndTime") {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            EvoTile("Mejor tiempo", h.bestDurationSeconds?.let { fmtDur(it) } ?: "—", Modifier.weight(1f))
                            EvoTile("Última", h.lastQuantityLabel ?: "—", Modifier.weight(1f))
                        }
                    }
                }
            }
            if (isStrengthLogging && summary == null) {
                TopeOneRMTile(
                    testedOneRM = testedOneRM,
                    editing = editingTope,
                    draft = topeDraft,
                    modifier = Modifier.fillMaxWidth(),
                    onBeginEdit = ::beginTopeEdit
                )
            }
            if (editingTope) {
                ReperaNumericKeypadSheet(
                    title = "Tope 1RM",
                    draft = topeDraft,
                    onDraftChange = { topeDraft = it },
                    onDismiss = { editingTope = false },
                    onCommit = { draft ->
                        topeDraft = draft
                        commitTopeEdit()
                    }
                )
            }
            // Píldoras full-width (mismo estilo que Progreso / resto de la app).
            ReperaTopicSegmentedPicker(
                options = metrics.map { it.title },
                selected = selectedMetric.title,
                onSelected = { label ->
                    metrics.firstOrNull { it.title == label }?.let { metric = it.wire }
                },
                modifier = Modifier.fillMaxWidth(),
                optionTestTag = { i, _ -> "evo_metric_$i" }
            )
            ReperaTopicSegmentedPicker(
                options = ExerciseProgressRange.entries.map { it.title },
                selected = selectedRange.title,
                onSelected = { label ->
                    ExerciseProgressRange.entries.firstOrNull { it.title == label }
                        ?.let { range = it.wire }
                },
                modifier = Modifier.fillMaxWidth(),
                optionTestTag = { i, _ -> "evo_range_$i" }
            )
            Column(Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.surfaceVariant,RoundedCornerShape(12.dp)).padding(12.dp),verticalArrangement=Arrangement.spacedBy(10.dp)) {
            if (points.size<2) {
                val (low,high)=ExerciseChartGeometry.bounds(points.map {it.value},ceiling)
                Column(Modifier.testTag("exercise_evolution_empty")) {
                    EmptyHealthChartAxes(low,high,220.dp)
                    Text(if(points.isEmpty()) "Aún no hay valores registrados." else "Haz al menos 2 sesiones para ver la tendencia.",style=MaterialTheme.typography.bodyMedium)
                    points.singleOrNull()?.let {point ->
                        Text("Último: ${formatPointValue(selectedMetric,point)}",style=MaterialTheme.typography.bodySmall)
                        Text(java.time.Instant.ofEpochMilli(point.epochMillis).atZone(java.time.ZoneId.systemDefault()).toLocalDate().format(reperaDayFormatter),style=MaterialTheme.typography.bodySmall)
                    }
                }
            } else {
                val ceilingColor=MaterialTheme.colorScheme.primary
                val gridColor=MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha=0.18f)
    val chartLineColor = MaterialTheme.colorScheme.tertiary
                val (axisLow,axisHigh)=ExerciseChartGeometry.bounds(points.map {it.value},ceiling)
                Row(Modifier.fillMaxWidth()) {
                Column(Modifier.size(width=44.dp,height=220.dp),verticalArrangement=Arrangement.SpaceBetween) {
                    Text(formatWeight(axisHigh),style=MaterialTheme.typography.labelSmall)
                    Text(formatWeight((axisLow+axisHigh)/2),style=MaterialTheme.typography.labelSmall)
                    Text(formatWeight(axisLow),style=MaterialTheme.typography.labelSmall)
                }
                Column(Modifier.weight(1f)) {
                fun selectAt(x:Float,width:Int,inset:Float) {
                    selectedPoint=ExerciseChartGeometry.nearest(points,((x-inset)/(width-2*inset).coerceAtLeast(1f)))
                }
                androidx.compose.foundation.Canvas(modifier = Modifier
                    .fillMaxWidth().height(220.dp).clip(RoundedCornerShape(2.dp)).testTag("exercise_evolution_chart")
                    .semantics {
                        contentDescription="Evolución de ${points.size} registros, valores entre ${formatWeight(axisLow)} y ${formatWeight(axisHigh)}"
                        customActions=listOf(
                            androidx.compose.ui.semantics.CustomAccessibilityAction("Punto anterior") {selectedPoint=ChartSelectionStep.step(selectedPoint,-1,points.size);true},
                            androidx.compose.ui.semantics.CustomAccessibilityAction("Punto siguiente") {selectedPoint=ChartSelectionStep.step(selectedPoint,1,points.size);true})
                    }
                    .pointerInput(points) {detectTapGestures {selectAt(it.x,size.width,8.dp.toPx())}}
                    .pointerInput(points) {detectHorizontalDragGestures {change,_ -> selectAt(change.position.x,size.width,8.dp.toPx())}}) {
                    val (minV,maxV)=ExerciseChartGeometry.bounds(points.map {it.value},ceiling)
                    val span=maxV-minV
                    fun x(i:Int)=8.dp.toPx()+ExerciseChartGeometry.fraction(points,i)*(size.width-16.dp.toPx()).coerceAtLeast(0f)
                    fun y(v:Double)=size.height-((v-minV)/span*size.height).toFloat()
                    listOf(axisLow,(axisLow+axisHigh)/2,axisHigh).forEach {value ->drawLine(gridColor,androidx.compose.ui.geometry.Offset(0f,y(value)),androidx.compose.ui.geometry.Offset(size.width,y(value)),0.5.dp.toPx())}
                    listOf(0f,0.5f,1f).forEach {fraction ->val gx=8.dp.toPx()+fraction*(size.width-16.dp.toPx());drawLine(gridColor,androidx.compose.ui.geometry.Offset(gx,0f),androidx.compose.ui.geometry.Offset(gx,size.height),0.5.dp.toPx())}
                    ceiling?.let {drawLine(ceilingColor,androidx.compose.ui.geometry.Offset(0f,y(it)),androidx.compose.ui.geometry.Offset(size.width,y(it)),strokeWidth=2f,
                        pathEffect=androidx.compose.ui.graphics.PathEffect.dashPathEffect(floatArrayOf(10f,8f)))}
                    selectedPoint?.takeIf {it in points.indices}?.let {i -> drawLine(ceilingColor,androidx.compose.ui.geometry.Offset(x(i),0f),androidx.compose.ui.geometry.Offset(x(i),size.height),strokeWidth=1.dp.toPx(),pathEffect=androidx.compose.ui.graphics.PathEffect.dashPathEffect(floatArrayOf(3.dp.toPx(),4.dp.toPx())))}
                    val observed=points.indices.map {ReadinessCurve.Point(x(it),y(points[it].value))}
                    val path=androidx.compose.ui.graphics.Path()
                    path.moveTo(observed.first().x,observed.first().y)
                    ReadinessCurve.segments(observed).forEach {c ->path.cubicTo(c.control1.x,c.control1.y,c.control2.x,c.control2.y,c.end.x,c.end.y)}
                    drawPath(path,color=chartLineColor,
                        style=androidx.compose.ui.graphics.drawscope.Stroke(width=2.dp.toPx(),cap=androidx.compose.ui.graphics.StrokeCap.Round,join=androidx.compose.ui.graphics.StrokeJoin.Round))
                }
                Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {
                    val monthFormatter=java.time.format.DateTimeFormatter.ofPattern("MMM",java.util.Locale("es","ES"))
                    val zone=java.time.ZoneId.systemDefault()
                    val firstMonth=java.time.Instant.ofEpochMilli(points.first().epochMillis).atZone(zone).format(monthFormatter)
                    val lastMonth=java.time.Instant.ofEpochMilli(points.last().epochMillis).atZone(zone).format(monthFormatter)
                    Text(firstMonth,style=MaterialTheme.typography.labelSmall)
                    if(lastMonth!=firstMonth) Text(lastMonth,style=MaterialTheme.typography.labelSmall)
                }
                }
                }
                ceiling?.let {Text("Tope 1RM · ${dev.repera.domain.ReperaNumberFormat.decimal(it)} kg",style=MaterialTheme.typography.bodySmall)}
                val last = points[selectedPoint?.takeIf {it in points.indices} ?: points.lastIndex]
                Text(java.time.Instant.ofEpochMilli(last.epochMillis).atZone(java.time.ZoneId.systemDefault()).toLocalDate().format(reperaDayFormatter),style=MaterialTheme.typography.bodySmall)
                Text("${if(selectedPoint==null) "Último" else "Seleccionado"}: ${formatPointValue(selectedMetric, last)} · " +
                    "${points.size} registros",
                    style = MaterialTheme.typography.bodyMedium)
            }
            }
            summary?.takeIf { it.hasData }?.let { h ->
                Column(
                    Modifier
                        .fillMaxWidth()
                        .background(
                            MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f),
                            RoundedCornerShape(12.dp)
                        )
                        .padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    if (h.maxWeightKg != null && h.repsAtMaxWeight != null) {
                        Row(Modifier.fillMaxWidth()) {
                            Text("Mejor serie", modifier = Modifier.weight(1f))
                            Text(
                                "${h.repsAtMaxWeight} × ${dev.repera.domain.ReperaNumberFormat.decimal(h.maxWeightKg!!)} kg",
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                    val lastBits = listOfNotNull(
                        h.lastQuantityLabel,
                        h.lastWeightKg?.let {
                            "${dev.repera.domain.ReperaNumberFormat.decimal(it)} kg"
                        }
                    ).joinToString(" · ")
                    val lastDay = h.lastEpochMillis?.let {
                        java.time.Instant.ofEpochMilli(it)
                            .atZone(java.time.ZoneId.systemDefault())
                            .toLocalDate()
                            .format(reperaDayFormatter)
                    }
                    if (lastDay != null || lastBits.isNotEmpty()) {
                        Row(Modifier.fillMaxWidth()) {
                            Text("Última", modifier = Modifier.weight(1f))
                            Text(
                                listOfNotNull(lastDay, lastBits.takeIf { it.isNotEmpty() })
                                    .joinToString(" · "),
                                fontWeight = FontWeight.Medium,
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                    }
                }
                ReperaCard(modifier = Modifier.fillMaxWidth()) {
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text("Historial", fontWeight = FontWeight.SemiBold)
                            Text(
                                "${h.timesPerformed} sesiones",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        Text(
                            "${h.timesPerformed}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

/**
 * Tope 1RM editable in-place (topeOneRMTile iOS):
 * toque → draft en el tile + teclado Repera; ✓/ocultar → commitTopeEdit.
 */
@Composable
private fun TopeOneRMTile(
    testedOneRM: Double?,
    editing: Boolean,
    draft: String,
    modifier: Modifier = Modifier,
    onBeginEdit: () -> Unit,
) {
    val display = when {
        editing -> draft.ifEmpty { "—" }
        testedOneRM != null -> ReperaNumberFormat.decimal(testedOneRM)
        else -> "—"
    }
    EvoTile(
        title = "Tope 1RM",
        value = display,
        modifier = modifier,
        accent = true,
        onClick = if (!editing) onBeginEdit else null
    )
}

/** Apple evoTile: valor arriba, etiqueta abajo. [accent] = Tope 1RM verde. */
@Composable
private fun EvoTile(
    title: String,
    value: String,
    modifier: Modifier = Modifier,
    accent: Boolean = false,
    onClick: (() -> Unit)? = null
) {
    val bg = if (accent) brandGreen.copy(alpha = 0.18f)
    else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.65f)
    val labelColor = if (accent) brandGreenReadable
    else MaterialTheme.colorScheme.onSurfaceVariant
    val valueColor = if (accent) brandGreenReadable
    else MaterialTheme.colorScheme.onSurface
    Column(
        modifier
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .background(bg, RoundedCornerShape(12.dp))
            .padding(horizontal = 10.dp, vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(
            value,
            fontSize = 18.sp,
            fontWeight = FontWeight.SemiBold,
            color = valueColor,
            maxLines = 1,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
        Text(
            title,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
            color = labelColor,
            maxLines = 1,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
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
    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp),
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
    fun localizedMuscle(raw: String): String {
        val slug = dev.repera.domain.MuscleTaxonomy.canonical(raw)
        return if (slug != null) dev.repera.domain.MuscleTaxonomy.displayName(slug) else raw
    }
    val primaryRaw = entry.targetMuscle.ifBlank { entry.muscleGroup }
    val primary = localizedMuscle(primaryRaw)
    val seen = mutableSetOf(primary.lowercase())
    val secondaries = entry.secondaryMuscles.mapNotNull { raw ->
        val slug = dev.repera.domain.MuscleTaxonomy.canonical(raw) ?: return@mapNotNull null
        val label = dev.repera.domain.MuscleTaxonomy.displayName(slug)
        val key = label.lowercase()
        if (key.isEmpty() || key in seen) return@mapNotNull null
        seen.add(key); label
    }
    // detailMeta iOS: aparatos separados por coma, en chips propios.
    val equipments = entry.equipment.split(",").map { it.trim() }.filter { it.isNotEmpty() }
    val sports = entry.disciplineTags.filter { it.isNotBlank() }
    if (primary.isBlank()) return
    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        androidx.compose.foundation.layout.Column(Modifier.padding(14.dp),
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
    // Mismo chip gris que «También» (surfaceVariant), no blanco sobre card.
    Row(verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        modifier = Modifier
            .background(
                MaterialTheme.colorScheme.surfaceVariant,
                androidx.compose.foundation.shape.CircleShape
            )
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
