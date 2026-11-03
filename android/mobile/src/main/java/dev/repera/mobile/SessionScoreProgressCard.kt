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

/** StatsView.ProgressSessionScoreChartCard geometry; prepared verified daily values unchanged. */
@Composable
internal fun SessionScoreProgressCard(
    points: List<ProgressDayPoint>,
    preview: Boolean = false,
    range: ProgressTimeRange = ProgressTimeRange.WEEK,
    monday: Boolean = true,
    today: LocalDate = LocalDate.now()
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
                if (preview) "Puntuación de entrenamiento · ejemplo" else "Puntuación de entrenamiento",
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
                val average = values.takeIf { it.isNotEmpty() }
                    ?.map { it.value }?.average()?.roundToInt()
                Row(
                    Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Box(
                        Modifier.size(94.dp).semantics {
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
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(
                            if (average == null) "Repera está aprendiendo de ti" else "Tu rendimiento personal",
                            style = MaterialTheme.typography.titleSmall
                        )
                        if (average == null) {
                            Text(
                                "Necesita 2 días previos con ejercicios o WOD comparables; algunos WOD requieren 3 días de referencia.",
                                style = MaterialTheme.typography.bodySmall
                            )
                        } else {
                            Text("${values.size} días con resultados evaluables", style = MaterialTheme.typography.bodySmall)
                            Text("Comparación con tus marcas anteriores, no con otros deportistas.",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text("Consulta los factores y la confianza en cada entrenamiento.",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
                if (values.isEmpty()) {
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
