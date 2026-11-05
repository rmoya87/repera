package dev.repera.mobile
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.*
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.dp
import dev.repera.domain.*
import java.time.LocalDate
import kotlin.math.abs
import kotlin.math.roundToInt

/** Una barra por sesión finalizada: siempre minutos observados, nota opcional. */
internal data class RecentWorkoutPlot(
    val id: String,
    val title: String,
    val finishedMillis: Long,
    val minutes: Double?,
    val verifiedScore: Int?
)

/** StatsView.ProgressSessionScoreChartCard geometry; period scores remain verified. */
@Composable
internal fun SessionScoreProgressCard(
    points: List<ProgressDayPoint>,
    preview: Boolean = false,
    range: ProgressTimeRange = ProgressTimeRange.WEEK,
    monday: Boolean = true,
    today: LocalDate = LocalDate.now(),
    confidenceLabel: String? = null,
    latestActivity: String? = null,
    effort: SessionScoreEffortGlance? = null,
    recentWorkouts: List<RecentWorkoutPlot> = emptyList()
) {
    val values = points.sortedBy { it.day }
    val domain = ProgressPlotAxis.domain(values.map { it.day }, range, monday, today, preview)
    var selected by remember(values, domain) { mutableStateOf<Int?>(null) }
    val accent = MaterialTheme.colorScheme.primary
    val rule = MaterialTheme.colorScheme.onSurfaceVariant
    val grid = rule.copy(alpha = 0.15f)
    fun nearest(f: Float) =
        values.indices.minBy { abs(ProgressPlotAxis.fraction(values[it].day, domain) - f) }
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.Bottom
        ) {
            ReperaSectionTitle(
                "Entrenamiento",
                modifier = Modifier.weight(1f, fill = false)
            )
            if (preview) {
                Text("Ejemplo", style = MaterialTheme.typography.labelSmall)
            }
        }
        ReperaCard(Modifier.fillMaxWidth()) {
            Column(
                Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                if (!preview && latestActivity != null) {
                    Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Text("Actividad",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text(latestActivity,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold)
                    }
                }
                val average = values.takeIf { it.isNotEmpty() }
                    ?.map { it.value }?.average()?.roundToInt()
                Row(
                    Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    Column(
                        Modifier.weight(1f),
                        verticalArrangement = Arrangement.spacedBy(9.dp)
                    ) {
                        val glance = if (preview) {
                            SessionScoreEffortGlance(5, 80, 4)
                        } else effort
                        TrendScoreMetric(
                            "Rendimiento",
                            glance?.relativeChangePercent?.let { pct ->
                                if (pct > 0) "+$pct %" else "$pct %"
                            } ?: "—"
                        )
                        TrendScoreMetric(
                            "Referencias",
                            glance?.referenceDays?.takeIf { it > 0 }?.toString() ?: "—"
                        )
                    }
                    Box(
                        Modifier.size(112.dp).semantics {
                            contentDescription = if (average == null) "Puntuación pendiente de aprendizaje"
                            else "Puntuación media $average de 10"
                        },
                        contentAlignment = Alignment.Center
                    ) {
                        Canvas(Modifier.fillMaxSize().padding(5.dp)) {
                            val stroke = 9.dp.toPx()
                            drawCircle(rule.copy(alpha = 0.15f), style = Stroke(stroke))
                            if (average != null) {
                                drawArc(
                                    color = accent,
                                    startAngle = -90f,
                                    sweepAngle = average * 36f,
                                    useCenter = false,
                                    style = Stroke(stroke, cap = StrokeCap.Round)
                                )
                            }
                        }
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                average?.toString() ?: "—",
                                style = MaterialTheme.typography.headlineLarge,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Text("de 10", style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
                // Misma barra en Pro y en vista gratuita: el encabezado de
                // esta última identifica explícitamente los valores como «Ejemplo».
                TrainingScoreConfidenceBar(
                    label = if (preview) "Media" else confidenceLabel,
                    caption = "Confianza",
                    compactInProgress = true,
                    showSelectedLevelInCaption = true
                )
                if (!preview && recentWorkouts.any { it.verifiedScore != null }) {
                    SevenRecentWorkoutScoreChart(
                        recentWorkouts.filter { it.verifiedScore != null },
                        accent,
                        rule
                    )
                } else if (values.isEmpty()) {
                    EmptyHealthChart(
                        "Repera está aprendiendo de ti. Necesita 2 días previos comparables y un 60% del rendimiento registrado con referencias.",
                        0.0, 10.0, 205.dp
                    )
                } else {
                    selected?.let {
                        Text(
                            values[it].day.format(reperaDayFormatter) + ": " +
                                Math.round(values[it].value) + "/10",
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                    Row(
                        Modifier.fillMaxWidth().semantics {
                            contentDescription =
                                if (preview) "Puntuaciones de ejemplo, datos ficticios"
                                else "Puntuaciones verificadas por día"
                            if (!preview) {
                                customActions = listOf(
                                    CustomAccessibilityAction("Punto anterior") {
                                        selected = ChartSelectionStep.step(selected, -1, values.size); true
                                    },
                                    CustomAccessibilityAction("Punto siguiente") {
                                        selected = ChartSelectionStep.step(selected, 1, values.size); true
                                    }
                                )
                            }
                        }
                    ) {
                        Column(
                            Modifier.width(36.dp).height(205.dp),
                            verticalArrangement = Arrangement.SpaceBetween
                        ) {
                            listOf("10", "5", "0").forEach {
                                Text(it, style = MaterialTheme.typography.labelSmall)
                            }
                        }
                        Canvas(
                            Modifier
                                .weight(1f)
                                .height(205.dp)
                                .testTag("session_score_plot")
                                .pointerInput(values, domain, preview) {
                                    if (preview) return@pointerInput
                                    detectTapGestures { selected = nearest(it.x / size.width) }
                                }
                                .pointerInput(values, domain, preview) {
                                    if (preview) return@pointerInput
                                    detectHorizontalDragGestures { change, _ ->
                                        change.consume()
                                        selected = nearest(change.position.x / size.width)
                                    }
                                }
                        ) {
                            fun x(i: Int) = ProgressPlotAxis.fraction(values[i].day, domain) * size.width
                            fun y(value: Double) = size.height - (value / 10 * size.height).toFloat()
                            clipRect {
                                listOf(0f, 0.5f, 1f).forEach { f ->
                                    drawLine(grid, Offset(0f, f * size.height), Offset(size.width, f * size.height), 0.5.dp.toPx())
                                    drawLine(grid, Offset(f * size.width, 0f), Offset(f * size.width, size.height), 0.5.dp.toPx())
                                }
                                val positions = values.indices.map {
                                    ReadinessCurve.Point(x(it), y(values[it].value))
                                }
                                // No unir días sin puntuación como si existieran datos.
                                val groups = mutableListOf<MutableList<ReadinessCurve.Point>>()
                                positions.forEachIndexed { i, point ->
                                    if (i == 0 || java.time.temporal.ChronoUnit.DAYS
                                            .between(values[i - 1].day, values[i].day) > 1) {
                                        groups.add(mutableListOf())
                                    }
                                    groups.last().add(point)
                                }
                                groups.forEach { group ->
                                    if (group.size > 1) {
                                        val path = Path()
                                        path.moveTo(group.first().x, group.first().y)
                                        ReadinessCurve.segments(group).forEach { c ->
                                            path.cubicTo(
                                                c.control1.x, c.control1.y,
                                                c.control2.x, c.control2.y,
                                                c.end.x, c.end.y
                                            )
                                        }
                                        drawPath(path, accent, style = Stroke(2.5.dp.toPx(), cap = StrokeCap.Round))
                                    }
                                    group.forEach { point ->
                                        drawCircle(accent, radius = 2.5.dp.toPx(), center = Offset(point.x, point.y))
                                    }
                                }
                                selected?.let { i ->
                                    drawLine(
                                        rule,
                                        Offset(x(i), 0f),
                                        Offset(x(i), size.height),
                                        1.dp.toPx(),
                                        pathEffect = PathEffect.dashPathEffect(
                                            floatArrayOf(3.dp.toPx(), 4.dp.toPx())
                                        )
                                    )
                                }
                            }
                        }
                    }
                    Row(
                        Modifier.fillMaxWidth().padding(start = 36.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        val fmt = java.time.format.DateTimeFormatter.ofPattern(
                            "d MMM",
                            java.util.Locale("es", "ES")
                        )
                        Text(values.first().day.format(fmt), style = MaterialTheme.typography.labelSmall)
                        if (values.size > 1) {
                            Text(values.last().day.format(fmt), style = MaterialTheme.typography.labelSmall)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun TrendScoreMetric(title: String, value: String) {
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(title, style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurface)
    }
}

/** Últimas sesiones con nota verificada; eje Y fijo 0–10. Sin inventar puntuaciones. */
@Composable
private fun SevenRecentWorkoutScoreChart(
    recent: List<RecentWorkoutPlot>,
    accent: Color,
    rule: Color
) {
    if (recent.isEmpty()) return
    var selectedIndex by remember(recent) { mutableIntStateOf(recent.lastIndex) }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(Modifier.fillMaxWidth()) {
            Column(
                Modifier.width(28.dp).height(180.dp),
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                listOf("10", "5", "0").forEach {
                    Text(it, style = MaterialTheme.typography.labelSmall)
                }
            }
            Canvas(
                Modifier.weight(1f).height(180.dp).testTag("recent_workouts_plot")
                    .semantics {
                        contentDescription = "Últimos ${recent.size} entrenos puntuados de 0 a 10"
                        customActions = listOf(
                            CustomAccessibilityAction("Entreno anterior") {
                                selectedIndex = (selectedIndex - 1).coerceAtLeast(0); true
                            },
                            CustomAccessibilityAction("Entreno siguiente") {
                                selectedIndex = (selectedIndex + 1).coerceAtMost(recent.lastIndex); true
                            }
                        )
                    }
                    .pointerInput(recent) {
                        detectTapGestures { offset ->
                            selectedIndex = ((offset.x / size.width.coerceAtLeast(1).toFloat()) * recent.size)
                                .toInt().coerceIn(0, recent.lastIndex)
                        }
                    }
            ) {
                fun x(index: Int) = size.width * (index + 0.5f) / recent.size
                fun y(score: Int) = size.height - (score / 10f) * size.height
                listOf(0f, 0.5f, 1f).forEach { fraction ->
                    val y = size.height * (1 - fraction)
                    drawLine(rule.copy(alpha = 0.16f), Offset(0f, y),
                        Offset(size.width, y), 0.6.dp.toPx())
                }
                val positions = recent.mapIndexed { index, workout ->
                    ReadinessCurve.Point(x(index), y(workout.verifiedScore ?: 0))
                }
                if (positions.size > 1) {
                    val path = Path()
                    path.moveTo(positions.first().x, positions.first().y)
                    ReadinessCurve.segments(positions).forEach { c ->
                        path.cubicTo(
                            c.control1.x, c.control1.y,
                            c.control2.x, c.control2.y,
                            c.end.x, c.end.y
                        )
                    }
                    drawPath(path, accent, style = Stroke(2.5.dp.toPx(), cap = StrokeCap.Round))
                }
                positions.forEachIndexed { index, point ->
                    drawCircle(
                        if (index == selectedIndex) accent else accent.copy(alpha = 0.85f),
                        radius = 3.dp.toPx(),
                        center = Offset(point.x, point.y)
                    )
                }
                selectedIndex.takeIf { it in recent.indices }?.let { index ->
                    drawLine(
                        rule.copy(alpha = 0.65f),
                        Offset(x(index), 0f),
                        Offset(x(index), size.height),
                        1.dp.toPx(),
                        pathEffect = PathEffect.dashPathEffect(
                            floatArrayOf(3.dp.toPx(), 4.dp.toPx())
                        )
                    )
                }
            }
        }
        selectedIndex.takeIf { it in recent.indices }?.let { index ->
            val score = recent[index].verifiedScore ?: return@let
            Text(
                "$score/10 · ${recent[index].title}",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceAround) {
            recent.indices.forEach { index ->
                Text(
                    (index + 1).toString(),
                    style = MaterialTheme.typography.labelSmall,
                    color = if (index == selectedIndex) accent
                    else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
