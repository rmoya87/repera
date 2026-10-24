package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import kotlin.math.roundToInt
import dev.repera.domain.ProgressPreparedCharts

/** Gráficas de Progreso (pulso y calorías) a partir de las series
 *  preparadas por ProgressChartBuilder. Sin librerías externas. */
@Composable
internal fun ProgressChartsCard(charts: ProgressPreparedCharts) {
    if (charts.calories.isEmpty() && charts.heartRate.isEmpty()) return
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(18.dp)) {
            Text("Actividad y pulso", style = MaterialTheme.typography.titleLarge)
            if (charts.calories.isNotEmpty()) {
                Text("Calorías activas · ${charts.caloriesTotal.toInt()} kcal en el rango",
                    style = MaterialTheme.typography.bodyMedium)
                val color = MaterialTheme.colorScheme.primary
                val values = charts.calories.map { it.value }
                Canvas(modifier = Modifier
                    .fillMaxWidth()
                    .height(96.dp)
                    .padding(top = 8.dp)) {
                    val maxV = (values.maxOrNull() ?: 0.0).coerceAtLeast(1.0)
                    val barWidth = size.width / values.size
                    values.forEachIndexed { i, v ->
                        val h = (v / maxV * size.height).toFloat()
                        drawRect(
                            color = color,
                            topLeft = Offset(i * barWidth + barWidth * 0.15f,
                                size.height - h),
                            size = androidx.compose.ui.geometry.Size(
                                barWidth * 0.7f, h)
                        )
                    }
                }
            }
            if (charts.heartRate.isNotEmpty()) {
                Text("Frecuencia cardíaca" +
                    (charts.averageHeartRate?.let {
                        " · media ${it.toInt()} ppm" } ?: ""),
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(top = 12.dp))
                val band = MaterialTheme.colorScheme.tertiary.copy(alpha = 0.25f)
                val line = MaterialTheme.colorScheme.tertiary
                val points = charts.heartRate
                Canvas(modifier = Modifier
                    .fillMaxWidth()
                    .height(96.dp)
                    .padding(top = 8.dp)) {
                    val minV = points.minOf { it.minBpm }
                    val maxV = points.maxOf { it.maxBpm }
                    val span = (maxV - minV).coerceAtLeast(1.0)
                    fun x(i: Int) =
                        if (points.size == 1) size.width / 2f
                        else i * size.width / (points.size - 1)
                    fun y(v: Double) =
                        size.height - ((v - minV) / span * size.height).toFloat()
                    // Banda mín-máx.
                    val area = Path()
                    points.forEachIndexed { i, p ->
                        if (i == 0) area.moveTo(x(i), y(p.maxBpm))
                        else area.lineTo(x(i), y(p.maxBpm))
                    }
                    for (i in points.indices.reversed()) {
                        area.lineTo(x(i), y(points[i].minBpm))
                    }
                    area.close()
                    drawPath(area, color = band)
                    // Línea de media.
                    val avg = Path()
                    points.forEachIndexed { i, p ->
                        if (i == 0) avg.moveTo(x(i), y(p.avgBpm))
                        else avg.lineTo(x(i), y(p.avgBpm))
                    }
                    drawPath(avg, color = line, style = Stroke(width = 3f))
                }
                val first = charts.heartRate.first()
                val last = charts.heartRate.last()
                Text("${first.minBpm.toInt()}-${last.maxBpm.toInt()} ppm (mín-máx del rango)",
                    style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

/** Mapa de calor por semanas (columnas) y días (filas), niveles 0-4. */
@Composable
internal fun HeatmapCard(title: String, levels: List<Pair<java.time.LocalDate, Int>>) {
    if (levels.isEmpty()) return
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(18.dp)) {
            Text(title, style = MaterialTheme.typography.titleLarge)
            val base = MaterialTheme.colorScheme.primary
            val empty = MaterialTheme.colorScheme.surfaceVariant
            Canvas(modifier = Modifier
                .fillMaxWidth()
                .height(118.dp)
                .padding(top = 8.dp)) {
                val first = levels.first().first
                // Semana que empieza en lunes, como iOS.
                val offset = first.dayOfWeek.value - 1
                val totalCells = levels.size + offset
                val weeks = (totalCells + 6) / 7
                val cw = size.width / weeks
                val ch = size.height / 7
                val gap = minOf(cw, ch) * 0.16f
                levels.forEachIndexed { i, (day, level) ->
                    val cell = offset + i
                    val col = cell / 7
                    val row = cell % 7
                    val color = when (level) {
                        0 -> empty
                        1 -> base.copy(alpha = 0.25f)
                        2 -> base.copy(alpha = 0.45f)
                        3 -> base.copy(alpha = 0.7f)
                        else -> base
                    }
                    drawRoundRect(
                        color = color,
                        topLeft = Offset(col * cw + gap / 2, row * ch + gap / 2),
                        size = androidx.compose.ui.geometry.Size(
                            cw - gap, ch - gap),
                        cornerRadius = androidx.compose.ui.geometry.CornerRadius(4f)
                    )
                }
            }
            Text("Intensidad por cuartiles del periodo",
                style = MaterialTheme.typography.bodySmall)
        }
    }
}

/** Gráfica de línea simple para series de puntos día→valor. */
/**
 * Serie temporal por día con ejes legibles (paridad iOS ProgressTrendCards):
 * - eje X: fecha del primer, punto medio y último día (localizadas es-ES);
 * - eje Y: valor mínimo y máximo del rango;
 * - tocar o arrastrar muestra fecha y valor del punto más cercano, como la
 *   RuleMark + annotation de Swift Charts;
 * - contentDescription resume rango de fechas y valores para TalkBack.
 */
@Composable
internal fun DayPointLineChart(
    points: List<dev.repera.domain.ProgressDayPoint>,
    modifier: Modifier = Modifier,
    valueFormat: (Double) -> String = { formatWeight(it) }
) {
    if (points.isEmpty()) return
    val line = MaterialTheme.colorScheme.primary
    var selected by remember(points) { mutableStateOf<Int?>(null) }
    val minV = points.minOf { it.value }
    val maxV = points.maxOf { it.value }
    val span = (maxV - minV).coerceAtLeast(1e-9)
    val firstDay = points.first().day
    val midDay = points[points.size / 2].day
    val lastDay = points.last().day
    val shortFormatter = java.time.format.DateTimeFormatter
        .ofPattern("d MMM", java.util.Locale("es", "ES"))
    val description = "Gráfica de ${firstDay.format(reperaDayFormatter)} a " +
        "${lastDay.format(reperaDayFormatter)}; " +
        "valores entre ${valueFormat(minV)} y ${valueFormat(maxV)}; " +
        "último punto ${valueFormat(points.last().value)}"
    Column(modifier = modifier.fillMaxWidth()
        .semantics(mergeDescendants = true) {
            contentDescription = description
        }) {
        selected?.let { i ->
            Text("${points[i].day.format(reperaDayFormatter)}: " +
                valueFormat(points[i].value),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.primary)
        }
        Row(modifier = Modifier.fillMaxWidth()) {
            Text(valueFormat(maxV),
                style = MaterialTheme.typography.labelSmall,
                modifier = Modifier
                    .align(androidx.compose.ui.Alignment.Top)
                    .padding(end = 4.dp))
            Canvas(modifier = Modifier
                .weight(1f)
                .height(100.dp)
                .pointerInput(points) {
                    detectTapGestures { offset ->
                        val idx = if (points.size == 1) 0
                        else ((offset.x / size.width) * (points.size - 1))
                            .roundToInt().coerceIn(0, points.size - 1)
                        selected = if (selected == idx) null else idx
                    }
                }
                .pointerInput(points) {
                    detectHorizontalDragGestures { change, _ ->
                        change.consume()
                        val idx = if (points.size == 1) 0
                        else ((change.position.x / size.width) * (points.size - 1))
                            .roundToInt().coerceIn(0, points.size - 1)
                        selected = idx
                    }
                }) {
                fun x(i: Int) = if (points.size == 1) size.width / 2f
                    else i * size.width / (points.size - 1)
                fun y(v: Double) =
                    size.height - ((v - minV) / span * size.height * 0.85f)
                        .toFloat() - size.height * 0.075f
                val path = Path()
                points.forEachIndexed { i, p ->
                    if (i == 0) path.moveTo(x(i), y(p.value))
                    else path.lineTo(x(i), y(p.value))
                }
                drawPath(path, color = line, style = Stroke(width = 4f))
                drawCircle(color = line, radius = 6f,
                    center = Offset(x(points.size - 1), y(points.last().value)))
                selected?.let { i ->
                    drawLine(
                        color = line.copy(alpha = 0.5f),
                        start = Offset(x(i), 0f),
                        end = Offset(x(i), size.height),
                        strokeWidth = 2f
                    )
                    drawCircle(color = line, radius = 8f,
                        center = Offset(x(i), y(points[i].value)))
                }
            }
        }
        Row(modifier = Modifier.fillMaxWidth()) {
            Text(valueFormat(minV),
                style = MaterialTheme.typography.labelSmall,
                modifier = Modifier.padding(end = 4.dp, top = 2.dp))
            Row(modifier = Modifier.weight(1f)) {
                Text(firstDay.format(shortFormatter),
                    style = MaterialTheme.typography.labelSmall)
                Spacer(modifier = Modifier.weight(1f))
                Text(midDay.format(shortFormatter),
                    style = MaterialTheme.typography.labelSmall)
                Spacer(modifier = Modifier.weight(1f))
                Text(lastDay.format(shortFormatter),
                    style = MaterialTheme.typography.labelSmall)
            }
        }
    }
}
