package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.ceil
import kotlin.math.floor
import dev.repera.domain.RecoverySleepNight

internal fun sleepChartHeightDp(columnWidthDp: Float, expanded: Boolean) =
    if (expanded) maxOf(220f, columnWidthDp - 150f) else 220f

internal fun sleepChartBounds(nights: List<RecoverySleepNight>): Pair<Double, Double> {
    val yLo = 0.0
    val yHi = minOf(12.0, kotlin.math.ceil((nights.maxOfOrNull { it.hours } ?: 8.0) + 0.5))
    return yLo to yHi
}

/** Horas por noche: área + línea con degradado (paridad iOS Sueño). */
@Composable
internal fun RecoverySleepChart(nights: List<RecoverySleepNight>, height: Dp) {
    if (nights.isEmpty()) return
    val ordered = nights.sortedBy { it.day }
    val (yLo, yHi) = sleepChartBounds(ordered)
    var selected by remember(ordered) { mutableStateOf<Int?>(null) }
    val dark = isSystemInDarkTheme()
    val ink = if (dark) Color(0.14f, 0.18f, 0.36f) else Color(0.07f, 0.10f, 0.22f)
    val mid = if (dark) Color(0.42f, 0.52f, 0.88f) else Color(0.32f, 0.42f, 0.78f)
    val glow = if (dark) Color(0.68f, 0.78f, 1.0f) else Color(0.55f, 0.68f, 0.95f)
    val tooltipBg = if (dark) Color(0.24f, 0.32f, 0.62f) else Color(0.12f, 0.16f, 0.30f)
    val density = LocalDensity.current
    val labelStyle = MaterialTheme.typography.labelMedium
    fun nearest(fraction: Float): Int {
        val start = ordered.first().day.toEpochDay()
        val span = (ordered.last().day.toEpochDay() - start).coerceAtLeast(1)
        return ordered.indices.minBy {
            kotlin.math.abs((ordered[it].day.toEpochDay() - start).toFloat() / span - fraction)
        }
    }
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            "Horas por noche",
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Canvas(
            Modifier
                .fillMaxWidth()
                .height(height)
                .testTag("recovery_sleep_chart")
                .clip(RoundedCornerShape(12.dp))
                .background(ink)
                .semantics {
                    contentDescription =
                        "Sueño, ${ordered.size} noches registradas; última ${formatWeight(ordered.last().hours)} h"
                    customActions = listOf(
                        CustomAccessibilityAction("Noche anterior") {
                            selected = ChartSelectionStep.step(selected, -1, ordered.size); true
                        },
                        CustomAccessibilityAction("Noche siguiente") {
                            selected = ChartSelectionStep.step(selected, 1, ordered.size); true
                        }
                    )
                }
                .pointerInput(ordered) {
                    detectTapGestures { selected = nearest(it.x / size.width.coerceAtLeast(1).toFloat()) }
                }
                .pointerInput(ordered) {
                    detectHorizontalDragGestures { change, _ ->
                        change.consume()
                        selected = nearest(change.position.x / size.width.coerceAtLeast(1).toFloat())
                    }
                }
        ) {
            val start = ordered.first().day.toEpochDay()
            val span = ordered.last().day.toEpochDay() - start
            fun x(i: Int) =
                if (span == 0L) size.width / 2f
                else (ordered[i].day.toEpochDay() - start).toFloat() / span * size.width
            val topPadPx = ProgressChartYTopPadDp.toPx()
            fun y(value: Double) =
                progressChartPlotY(value, yLo, yHi, size.height, topPadPx)
            val points = ordered.indices.map { ReadinessCurve.Point(x(it), y(ordered[it].hours)) }
            val curve = Path()
            curve.moveTo(points.first().x, points.first().y)
            ReadinessCurve.segments(points).forEach { c ->
                curve.cubicTo(c.control1.x, c.control1.y, c.control2.x, c.control2.y, c.end.x, c.end.y)
            }
            val area = Path().apply {
                addPath(curve)
                lineTo(points.last().x, size.height)
                lineTo(points.first().x, size.height)
                close()
            }
            // Serie recortada; guías Y + badge de selección fuera del clip para no cortar el tip.
            clipRect {
                drawPath(
                    area,
                    Brush.verticalGradient(listOf(mid.copy(alpha = 0.65f), ink))
                )
                drawPath(
                    curve,
                    glow,
                    style = Stroke(2.4.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round)
                )
                if (points.size == 1) {
                    drawCircle(glow, 3.dp.toPx(), Offset(points.first().x, points.first().y))
                }
            }
            val hoursInk = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
                color = android.graphics.Color.argb(185, 235, 241, 255)
                textSize = 10.sp.toPx()
                textAlign = android.graphics.Paint.Align.LEFT
            }
            for (hour in ceil(yLo).toInt()..floor(yHi).toInt() step 2) {
                if (hour.toDouble() <= yLo + 0.01) continue
                val lineY = y(hour.toDouble())
                drawLine(
                    Color.White.copy(alpha = 0.25f),
                    Offset(0f, lineY), Offset(size.width, lineY),
                    strokeWidth = 1.dp.toPx(),
                    pathEffect = PathEffect.dashPathEffect(
                        floatArrayOf(2.dp.toPx(), 4.dp.toPx())
                    )
                )
                drawContext.canvas.nativeCanvas.drawText(
                    hour.toString() + " h",
                    6.dp.toPx(),
                    (lineY + 11.dp.toPx()).coerceAtMost(size.height - 2.dp.toPx()),
                    hoursInk
                )
            }
            selected?.let { i ->
                drawLine(
                    glow,
                    Offset(x(i), 0f),
                    Offset(x(i), size.height),
                    1.dp.toPx(),
                    pathEffect = PathEffect.dashPathEffect(floatArrayOf(3.dp.toPx(), 4.dp.toPx()))
                )
                drawCircle(glow, 5.dp.toPx(), Offset(x(i), y(ordered[i].hours)))
                val tip = "${formatWeight(ordered[i].hours)} h · ${
                    ordered[i].day.format(
                        java.time.format.DateTimeFormatter.ofPattern("d MMM", java.util.Locale("es", "ES"))
                    )
                }"
                val textPaint = android.graphics.Paint().apply {
                    isAntiAlias = true
                    color = android.graphics.Color.WHITE
                    textSize = with(density) { labelStyle.fontSize.toPx() }
                    typeface = android.graphics.Typeface.create(
                        android.graphics.Typeface.DEFAULT,
                        android.graphics.Typeface.BOLD
                    )
                }
                val pad = 5.dp.toPx()
                val textW = textPaint.measureText(tip)
                val boxW = textW + pad * 2
                val boxH = textPaint.textSize + pad * 1.4f
                val px = x(i).coerceIn(boxW / 2f, size.width - boxW / 2f)
                val py = (y(ordered[i].hours) - boxH - 8.dp.toPx()).coerceAtLeast(4.dp.toPx())
                drawRoundRect(
                    color = tooltipBg,
                    topLeft = Offset(px - boxW / 2f, py),
                    size = Size(boxW, boxH),
                    cornerRadius = androidx.compose.ui.geometry.CornerRadius(6.dp.toPx())
                )
                drawIntoCanvas { canvas ->
                    canvas.nativeCanvas.drawText(
                        tip,
                        px - textW / 2f,
                        py + boxH - pad,
                        textPaint
                    )
                }
            }
        }
        if (ordered.size > 1) {
            Row(Modifier.fillMaxWidth()) {
                val axisDate =
                    java.time.format.DateTimeFormatter.ofPattern("d MMM", java.util.Locale("es", "ES"))
                Text(ordered.first().day.format(axisDate), style = MaterialTheme.typography.labelSmall)
                Spacer(Modifier.weight(1f))
                Text(ordered.last().day.format(axisDate), style = MaterialTheme.typography.labelSmall)
            }
        }
    }
}
