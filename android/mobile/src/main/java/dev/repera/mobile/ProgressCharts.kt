package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.ui.platform.testTag
import androidx.compose.foundation.horizontalScroll
import androidx.compose.ui.unit.sp
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.RowScope
import androidx.compose.ui.platform.testTag
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.clip
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
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

/** Modelo de presentación del heatmap (HeatmapGrid.build iOS), puro y
 *  testable en JVM: franja (Hoy/Semana) o rejilla por semanas (lunes). */
internal data class HeatmapColModel(
    val cells: List<Triple<java.time.LocalDate?, Int, Boolean>>) // (día, nivel, futuro)
internal data class HeatmapGridModel(
    val columns: List<HeatmapColModel>,
    val monthLabels: List<String>,
    val dayLabels: List<String>,
    val isStrip: Boolean)

internal fun buildHeatmapGrid(
    levels: List<Pair<java.time.LocalDate, Int>>,
    range: dev.repera.domain.ProgressTimeRange,
    locale: java.util.Locale = java.util.Locale("es", "ES")
): HeatmapGridModel {
    val es = locale
    val dayFmt = java.time.format.DateTimeFormatter.ofPattern("EEE", es)
    val monthFmt = java.time.format.DateTimeFormatter.ofPattern("MMM", es)
    val today = levels.last().first
    val levelByDay = levels.toMap()
    val isStrip = range == dev.repera.domain.ProgressTimeRange.TODAY ||
        range == dev.repera.domain.ProgressTimeRange.WEEK
    if (isStrip) {
        val days = levels.take(15) // iOS: tope tras 15 columnas
        return HeatmapGridModel(
            columns = days.map { (day, level) ->
                HeatmapColModel(listOf(Triple(day, level, false)))
            },
            monthLabels = emptyList(),
            dayLabels = days.map { (day, _) -> dayFmt.format(day).replace(".", "") },
            isStrip = true)
    }
    val weeksBack = when (range) {
        dev.repera.domain.ProgressTimeRange.MONTH -> 4
        dev.repera.domain.ProgressTimeRange.DAYS_90 -> 13
        dev.repera.domain.ProgressTimeRange.DAYS_180 -> 26
        dev.repera.domain.ProgressTimeRange.DAYS_360 -> 52
        else -> 0
    }
    val offsetInWeek = today.dayOfWeek.value - 1 // lunes = 0, como iOS (firstWeekday 2)
    val endOfWeek = today.minusDays(offsetInWeek.toLong())
    val start = endOfWeek.minusWeeks(weeksBack.toLong())
    val cols = mutableListOf<HeatmapColModel>()
    val months = mutableListOf<String>()
    var lastMonth = -1
    for (wk in 0..weeksBack) {
        val colStart = start.plusWeeks(wk.toLong())
        val mo = colStart.monthValue
        val showM = mo != lastMonth && colStart.dayOfMonth <= 7 && wk < weeksBack
        months.add(if (showM) monthFmt.format(colStart) else "")
        if (colStart.dayOfMonth <= 7) lastMonth = mo
        val cells = (0..6).map { d ->
            val date = colStart.plusDays(d.toLong())
            val future = date.isAfter(today)
            Triple(date, if (future) 0 else (levelByDay[date] ?: 0), future)
        }
        cols.add(HeatmapColModel(cells))
    }
    return HeatmapGridModel(cols, months, emptyList(), isStrip = false)
}

/** Etiquetas del gutter por weekday REAL de cada fila (fila 0 = lunes):
 *  L/X/V en lunes/miércoles/viernes. iOS usa ["", "L", "", "X", "", "V", ""],
 *  que solo cuadra con semana que empieza en domingo (con lunes quedaban en
 *  martes/jueves/sábado: corrección de main 25/10, no desviación silenciosa). */
internal fun heatmapGutterLabels(colStart: java.time.LocalDate): List<String> =
    (0..6).map { d ->
        when (colStart.plusDays(d.toLong()).dayOfWeek) {
            java.time.DayOfWeek.MONDAY -> "L"
            java.time.DayOfWeek.WEDNESDAY -> "X"
            java.time.DayOfWeek.FRIDAY -> "V"
            else -> ""
        }
    }

/** Heatmap de actividad (ActivityHeatmapView iOS): UNA tarjeta con selector
 *  segmentado Tiempo/Volumen (iOS tenía picker segmentado dentro de la tarjeta;
 *  antes había aquí dos tarjetas separadas). Hoy/Esta semana = franja de días
 *  estirada a lo ancho con etiquetas de día; rangos largos = rejilla por semanas
 *  (semana que empieza en lunes) con gutter L/X/V, etiquetas de mes y scroll
 *  horizontal que arranca al final. Hoy lleva borde claro; futuro al 25%. */
@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
internal fun ActivityHeatmapCard(
    timeLevels: List<Pair<java.time.LocalDate, Int>>,
    volumeLevels: List<Pair<java.time.LocalDate, Int>>,
    range: dev.repera.domain.ProgressTimeRange
) {
    if (timeLevels.isEmpty() && volumeLevels.isEmpty()) return
    var metric by androidx.compose.runtime.saveable.rememberSaveable { mutableStateOf("time") }
    val levels = if (metric == "time") timeLevels else volumeLevels
    if (levels.isEmpty()) return
    val grid = buildHeatmapGrid(levels, range)
    val isStrip = grid.isStrip
    val columns = grid.columns
    val monthLabels = grid.monthLabels
    val dayLabels = grid.dayLabels
    val today = levels.last().first

    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(18.dp)) {
            Text("Actividad", style = MaterialTheme.typography.titleLarge)
            // Picker .segmented de iOS.
            SingleChoiceSegmentedButtonRow(
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp)
                    .testTag("heatmap_metric")
            ) {
                listOf("time" to "Tiempo", "volume" to "Volumen").forEachIndexed { i, (key, label) ->
                    SegmentedButton(
                        selected = metric == key,
                        onClick = { metric = key },
                        shape = androidx.compose.material3.SegmentedButtonDefaults.itemShape(
                            index = i, count = 2),
                        modifier = Modifier.testTag("heatmap_metric_$key"),
                        label = { Text(label) })
                }
            }

            BoxWithConstraints(modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
                // HeatmapLayout.resolve de iOS, en dp.
                val density = androidx.compose.ui.platform.LocalDensity.current
                val widthDp = with(density) { maxWidth }
                val cols = columns.size.coerceAtLeast(1)
                val rows = if (isStrip) 1 else 7
                val labelWidth = if (isStrip) 0.dp else 14.dp
                val gapRatio = if (isStrip) 0.12f else 0.2f
                val minCell = if (isStrip) 28.dp else 11.dp
                val usable = maxOf(40.dp, widthDp - labelWidth - if (isStrip) 0.dp else 4.dp)
                val ideal = usable / (cols + gapRatio * (cols - 1).coerceAtLeast(0))
                val needsScroll = ideal < minCell
                val cell = if (needsScroll) minCell else ideal
                val gap = if (needsScroll) (if (isStrip) 4.dp else 3.dp)
                          else maxOf(2.dp, cell * gapRatio)
                val canvasWidth = cell * cols + gap * (cols - 1).coerceAtLeast(0)
                val canvasHeight = cell * rows + gap * (rows - 1).coerceAtLeast(0)
                val radius = maxOf(2.dp, minOf(8.dp, cell * 0.2f))
                val scroll = androidx.compose.foundation.rememberScrollState()

                Column {
                    if (!isStrip) {
                        // Etiquetas de mes sobre las columnas (monthLabelsRow iOS).
                        Row(modifier = Modifier.horizontalScroll(scroll)) {
                            Spacer(Modifier.width(labelWidth + gap))
                            monthLabels.forEach { label ->
                                Text(label, fontSize = 9.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    maxLines = 1, softWrap = false,
                                    modifier = Modifier.width(cell + gap))
                            }
                        }
                    }
                    Row {
                        if (!isStrip) {
                            // Gutter (weekDayGutter iOS): VStack con
                            // spacing=gap y cada etiqueta de altura cell — si
                            // no, 7×(cell+gap) deriva respecto a 7×cell+6×gap.
                            // Etiquetas por weekday REAL de la fila.
                            val gutter = heatmapGutterLabels(
                                columns.first().cells[0].first!!)
                            Column(verticalArrangement = Arrangement.spacedBy(gap)) {
                                gutter.forEach { g ->
                                    Box(modifier = Modifier.width(labelWidth).height(cell),
                                        contentAlignment = Alignment.CenterEnd) {
                                        Text(g, fontSize = 9.sp,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    }
                                }
                            }
                            Spacer(Modifier.width(gap))
                        }
                        val canvas: @Composable () -> Unit = {
                            Canvas(modifier = Modifier
                                .width(canvasWidth).height(canvasHeight)
                                .testTag("heatmap_canvas")) {
                                val cellPx = cell.toPx(); val gapPx = gap.toPx()
                                columns.forEachIndexed { colIdx, col ->
                                    col.cells.forEachIndexed { row, (date, level, future) ->
                                        val x = colIdx * (cellPx + gapPx)
                                        val y = row * (cellPx + gapPx)
                                        var color = BodyMapPalette.fill(level)
                                        if (future) color = color.copy(alpha = 0.25f)
                                        drawRoundRect(color = color,
                                            topLeft = Offset(x, y),
                                            size = androidx.compose.ui.geometry.Size(cellPx, cellPx),
                                            cornerRadius = androidx.compose.ui.geometry.CornerRadius(
                                                radius.toPx()))
                                        if (date == today) {
                                            drawRoundRect(color = Color.White.copy(alpha = 0.75f),
                                                topLeft = Offset(x, y),
                                                size = androidx.compose.ui.geometry.Size(cellPx, cellPx),
                                                cornerRadius = androidx.compose.ui.geometry.CornerRadius(
                                                    radius.toPx()),
                                                style = Stroke(width = maxOf(1f, cellPx * 0.05f)))
                                        }
                                    }
                                }
                            }
                        }
                        if (needsScroll) {
                            Row(modifier = Modifier.horizontalScroll(scroll)) { canvas() }
                            // iOS arranca con el scroll al final (lo más reciente).
                            androidx.compose.runtime.LaunchedEffect(cols, metric) {
                                scroll.scrollTo(scroll.maxValue)
                            }
                        } else canvas()
                    }
                    if (isStrip) {
                        // Etiquetas de día bajo la franja (dayLabelsRow iOS).
                        Row {
                            dayLabels.forEach { label ->
                                Text(label, fontSize = 10.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    maxLines = 1, softWrap = false,
                                    textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                                    modifier = Modifier.width(cell + gap))
                            }
                        }
                    }
                }
            }
            // Leyenda 1:1 con ActivityHeatmapView iOS.
            Row(
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(if (metric == "volume") "Menos volumen" else "Menos tiempo",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                (0..4).forEach { level ->
                    Spacer(Modifier.width(4.dp))
                    Box(Modifier.size(11.dp).clip(androidx.compose.foundation.shape.RoundedCornerShape(2.dp))
                        .background(BodyMapPalette.fill(level)))
                }
                Spacer(Modifier.width(4.dp))
                Text(if (metric == "volume") "Más volumen" else "Más tiempo",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
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
    valueFormat: (Double) -> String = { formatWeight(it) },
    goal:Double? = null,
    bounds:ClosedFloatingPointRange<Double>? = null
) {
    if (points.isEmpty()) return
    val line = MaterialTheme.colorScheme.primary
    var selected by remember(points) { mutableStateOf<Int?>(null) }
    val minV = bounds?.start ?: minOf(points.minOf { it.value },goal ?: Double.POSITIVE_INFINITY)
    val maxV = bounds?.endInclusive ?: maxOf(points.maxOf { it.value },goal ?: Double.NEGATIVE_INFINITY)
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
        .testTag("day_point_line_chart")
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
            // Columna de valores (máx arriba, mín abajo) separada de las
            // fechas: antes el mínimo compartía fila con la primera fecha y
            // colisionaban ("80.9 25 sept").
            Column(
                modifier = Modifier
                    .width(52.dp)
                    .height(124.dp)
                    .padding(end = 4.dp),
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                Text(valueFormat(maxV),
                    style = MaterialTheme.typography.labelSmall,
                    maxLines = 1, softWrap = false)
                Text(valueFormat(minV),
                    style = MaterialTheme.typography.labelSmall,
                    maxLines = 1, softWrap = false)
            }
            Column(modifier = Modifier.weight(1f)) {
            Canvas(modifier = Modifier
                .fillMaxWidth()
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
                goal?.let {target ->
                    drawLine(color=line.copy(alpha=0.55f),start=Offset(0f,y(target)),end=Offset(size.width,y(target)),
                        strokeWidth=2f,pathEffect=androidx.compose.ui.graphics.PathEffect.dashPathEffect(floatArrayOf(10f,8f)))
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
            Row(modifier = Modifier.fillMaxWidth().padding(top = 2.dp)) {
                Text(firstDay.format(shortFormatter),
                    style = MaterialTheme.typography.labelSmall,
                    maxLines = 1, softWrap = false)
                Spacer(modifier = Modifier.weight(1f))
                Text(midDay.format(shortFormatter),
                    style = MaterialTheme.typography.labelSmall,
                    maxLines = 1, softWrap = false)
                Spacer(modifier = Modifier.weight(1f))
                Text(lastDay.format(shortFormatter),
                    style = MaterialTheme.typography.labelSmall,
                    maxLines = 1, softWrap = false)
            }
            }
        }
    }
}
