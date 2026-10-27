package dev.repera.mobile

import androidx.compose.ui.graphics.drawscope.clipRect
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
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import kotlin.math.roundToInt
import dev.repera.domain.ProgressPreparedCharts

/** Gráficas de Progreso (pulso y calorías) a partir de las series
 *  preparadas por ProgressChartBuilder. Sin librerías externas. */
@Composable
internal fun ProgressChartsCard(charts: ProgressPreparedCharts,showEmpty:Boolean=false,preview:Boolean=false) {
    if (!showEmpty && charts.calories.isEmpty() && charts.heartRate.isEmpty()) return
    Column(Modifier.fillMaxWidth(),verticalArrangement=Arrangement.spacedBy(12.dp)) {
        if(showEmpty || charts.heartRate.isNotEmpty()) ProgressCardioCard(charts,preview)
        if(showEmpty || charts.calories.isNotEmpty()) ProgressCaloriesCard(charts,preview)
    }
}

@Composable internal fun ProgressCardioCard(charts:ProgressPreparedCharts,preview:Boolean) {
 Card(Modifier.fillMaxWidth().testTag("progress_cardio_card")) {
  Column(Modifier.padding(horizontal=10.dp,vertical=20.dp),verticalArrangement=Arrangement.spacedBy(10.dp)) {
   Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {
    Text("Cardio",style=MaterialTheme.typography.titleMedium)
    if(preview) Text("Ejemplo",style=MaterialTheme.typography.labelMedium)
    else if(charts.heartRate.isNotEmpty()) Text("Media ${Math.round(charts.heartRate.map {it.avgBpm}.average())} lpm",style=MaterialTheme.typography.labelMedium)
   }
   ProgressCardioPlot(charts,preview)
  }
 }
}
@Composable internal fun ProgressCaloriesCard(charts:ProgressPreparedCharts,preview:Boolean) {
 Card(Modifier.fillMaxWidth().testTag("progress_calories_card")) {
  Column(Modifier.padding(horizontal=10.dp,vertical=20.dp),verticalArrangement=Arrangement.spacedBy(10.dp)) {
   Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {
    Text("Calorías",style=MaterialTheme.typography.titleMedium)
    if(preview || charts.caloriesTotal>0) Text((if(preview) "Ejemplo · " else "")+Math.round(charts.caloriesTotal)+" kcal",style=MaterialTheme.typography.labelMedium)
   }
   ProgressCaloriesPlot(charts,preview)
   ProgressCalorieStats(charts)
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
    bounds:ClosedFloatingPointRange<Double>? = null,
    interactive:Boolean=true,
    readinessStyle:Boolean=false,
    weightStyle:Boolean=false,
    weightPreview:Boolean=false,
    readinessGradient:Boolean=true,
    physiologyStyle:Boolean=false,
    chartHeight:androidx.compose.ui.unit.Dp?=null
) {
    if (points.isEmpty()) return
    // Apple HealthRecovery.vitalChart: one observed sample is not a trend.
    // Keep its value visible, without fabricating a line or repeated dates.
    if (points.size == 1) {
        Column(modifier.fillMaxWidth().testTag("day_point_single_sample")) {
            Text(valueFormat(points.single().value), style=MaterialTheme.typography.labelMedium)
            Text("Una medición; aún no hay tendencia.", style=MaterialTheme.typography.bodySmall)
            Text(points.single().day.format(reperaDayFormatter), style=MaterialTheme.typography.labelSmall)
        }
        return
    }
    val line = MaterialTheme.colorScheme.primary
    var selected by remember(points) { mutableStateOf<Int?>(null) }
    val minV = bounds?.start ?: minOf(points.minOf { it.value },goal ?: Double.POSITIVE_INFINITY)
    val maxV = bounds?.endInclusive ?: maxOf(points.maxOf { it.value },goal ?: Double.NEGATIVE_INFINITY)
    val padding=if(weightStyle) maxOf(if(weightPreview) 1.6 else 1.2,(maxV-minV)*(if(weightPreview) 0.35 else 0.22)) else 0.0
    val axisMin=minV-padding
    val axisMax=maxV+padding
    val span = (axisMax - axisMin).coerceAtLeast(1e-9)
    val plotHeight=chartHeight ?: if(weightStyle) 210.dp else if(readinessStyle) 220.dp else 100.dp
    val insetPlot=readinessStyle || weightStyle
    val firstDay = points.first().day
    val midDay = DayChartPositions.midpoint(points)
    val lastDay = points.last().day
    val shortFormatter = java.time.format.DateTimeFormatter
        .ofPattern("d MMM", java.util.Locale("es", "ES"))
    val description = "Gráfica de ${firstDay.format(reperaDayFormatter)} a " +
        "${lastDay.format(reperaDayFormatter)}; " +
        "valores entre ${valueFormat(axisMin)} y ${valueFormat(axisMax)}; " +
        "último punto ${valueFormat(points.last().value)}"
    Column(modifier = modifier.fillMaxWidth()
        .testTag("day_point_line_chart")
        .semantics(mergeDescendants = true) {
            contentDescription = description
            if(interactive) customActions = listOf(
                androidx.compose.ui.semantics.CustomAccessibilityAction("Punto anterior") {selected = ChartSelectionStep.step(selected,-1,points.size);true},
                androidx.compose.ui.semantics.CustomAccessibilityAction("Punto siguiente") {selected = ChartSelectionStep.step(selected,1,points.size);true})
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
                    .height(plotHeight+24.dp)
                    .padding(end = 4.dp),
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                Text(valueFormat(axisMax),
                    style = MaterialTheme.typography.labelSmall,
                    maxLines = 1, softWrap = false)
                Text(valueFormat(axisMin),
                    style = MaterialTheme.typography.labelSmall,
                    maxLines = 1, softWrap = false)
            }
            Column(modifier = Modifier.weight(1f)) {
            Canvas(modifier = Modifier
                .fillMaxWidth()
                .height(plotHeight)
                .testTag(if(physiologyStyle) "physiology_observed_plot" else "day_point_plot")
                .pointerInput(points,interactive,insetPlot) {
                    if(!interactive) return@pointerInput
                    detectTapGestures { offset ->
                        val idx = DayChartPositions.nearest(points,if(insetPlot)
                            (offset.x-8.dp.toPx())/(size.width-16.dp.toPx()).coerceAtLeast(1f)
                            else offset.x / size.width)
                        selected = if (selected == idx) null else idx
                    }
                }
                .pointerInput(points,interactive,insetPlot) {
                    if(!interactive) return@pointerInput
                    detectHorizontalDragGestures { change, _ ->
                        change.consume()
                        val idx = DayChartPositions.nearest(points,if(insetPlot)
                            (change.position.x-8.dp.toPx())/(size.width-16.dp.toPx()).coerceAtLeast(1f)
                            else change.position.x / size.width)
                        selected = idx
                    }
                }) {
                fun x(i: Int):Float {
                    val inset=if(insetPlot) 8.dp.toPx() else 0f
                    return inset+DayChartPositions.fraction(points,i)*(size.width-2*inset).coerceAtLeast(0f)
                }
                fun y(v: Double) =
                    size.height - ((v - axisMin) / span * size.height * 0.85f)
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
                if(readinessStyle) {
                    val curve=Path()
                    val observed=points.indices.map {ReadinessCurve.Point(x(it),y(points[it].value))}
                    curve.moveTo(observed.first().x,observed.first().y)
                    ReadinessCurve.segments(observed).forEach {c ->
                        curve.cubicTo(c.control1.x,c.control1.y,c.control2.x,c.control2.y,c.end.x,c.end.y)
                    }
                    // Gradient is anchored to the score axis, not sample order.
                    val brush=androidx.compose.ui.graphics.Brush.verticalGradient(
                        0f to line,0.16f to line,
                        0.28f to Color(0xFFFFD60A),0.40f to Color(0xFFFFD60A),
                        0.60f to Color(0xFFFF453A),1f to Color(0xFFFF453A),
                        startY=y(10.0),endY=y(0.0))
                    clipRect {
                        drawPath(curve,brush=if(readinessGradient) brush else androidx.compose.ui.graphics.SolidColor(line),style=Stroke(width=3.dp.toPx(),
                            cap=androidx.compose.ui.graphics.StrokeCap.Round,
                            join=androidx.compose.ui.graphics.StrokeJoin.Round))
                    }
                } else if(weightStyle) {
                    val curve=Path()
                    val observed=points.indices.map {ReadinessCurve.Point(x(it),y(points[it].value))}
                    curve.moveTo(observed.first().x,observed.first().y)
                    ReadinessCurve.segments(observed).forEach {c ->curve.cubicTo(c.control1.x,c.control1.y,c.control2.x,c.control2.y,c.end.x,c.end.y)}
                    clipRect {drawPath(curve,color=line,style=Stroke(width=2.25.dp.toPx(),cap=androidx.compose.ui.graphics.StrokeCap.Round,join=androidx.compose.ui.graphics.StrokeJoin.Round))}
                } else {
                    if(physiologyStyle) {
                        val grid= line.copy(alpha=0.12f)
                        listOf(0f,0.5f,1f).forEach {f ->drawLine(grid,Offset(f*size.width,0f),Offset(f*size.width,size.height),0.5.dp.toPx())}
                    }
                    if(physiologyStyle) clipRect {drawPath(path,color=line,style=Stroke(width=2.dp.toPx()))}
                    else drawPath(path,color=line,style=Stroke(width=4f))
                }
                if(!physiologyStyle) drawCircle(color = line, radius = 6f,
                    center = Offset(x(points.size - 1), y(points.last().value)))
                selected?.let { i ->
                    drawLine(
                        color = line.copy(alpha = 0.5f),
                        start = Offset(x(i), 0f),
                        end = Offset(x(i), size.height),
                        strokeWidth = if(physiologyStyle) 1.dp.toPx() else 2f,
                        pathEffect=androidx.compose.ui.graphics.PathEffect.dashPathEffect(if(physiologyStyle) floatArrayOf(3.dp.toPx(),4.dp.toPx()) else floatArrayOf(6f,6f))
                    )
                    if(!physiologyStyle) drawCircle(color = line, radius = 8f,
                        center = Offset(x(i), y(points[i].value)))
                }
            }
            Row(modifier = Modifier.fillMaxWidth().padding(top = 2.dp)) {
                Text(firstDay.format(shortFormatter),
                    style = MaterialTheme.typography.labelSmall,
                    maxLines = 1, softWrap = false)
                Spacer(modifier = Modifier.weight(1f))
                if (midDay != firstDay && midDay != lastDay) {
                    Text(midDay.format(shortFormatter),
                        style = MaterialTheme.typography.labelSmall,
                        maxLines = 1, softWrap = false)
                    Spacer(modifier = Modifier.weight(1f))
                }
                Text(lastDay.format(shortFormatter),
                    style = MaterialTheme.typography.labelSmall,
                    maxLines = 1, softWrap = false)
            }
            }
        }
    }
}

@Composable
internal fun EmptyHealthChartAxes(low:Double,high:Double,plotHeight:androidx.compose.ui.unit.Dp=96.dp) {
    val axis=MaterialTheme.colorScheme.onSurfaceVariant
    Text(formatWeight(high),style=MaterialTheme.typography.bodySmall)
    Canvas(Modifier.fillMaxWidth().height(plotHeight).testTag("empty_health_chart_axes")) {
        drawLine(axis,Offset(0f,0f),Offset(0f,size.height),2f)
        drawLine(axis,Offset(0f,size.height),Offset(size.width,size.height),2f)
    }
    Text(formatWeight(low),style=MaterialTheme.typography.bodySmall)
}
