package dev.repera.mobile

import android.graphics.BlurMaskFilter
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Reloj digital estilo LED (ronda en verde + tiempo en rojo), puerto 1:1 de
 * DigitalClockDisplay.swift (iOS): mismas proporciones (dígito 0,58h, grosor
 * máx(4, 0,11h), segmentos 0,72w/0,38h, separaciones 0,08h/0,22h), mismos
 * colores y halo luminoso. widthFactor(hasRound) = 4,22/2,76 como en iOS.
 */
object LedClock {
    val roundColor = Color(0.22f, 1.0f, 0.35f)
    val timeColor = Color(1.0f, 0.22f, 0.18f)

    /** Ancho del conjunto de dígitos en múltiplos de la altura (como iOS). */
    fun widthFactor(hasRound: Boolean): Float = if (hasRound) 4.22f else 2.76f
}

private val SEGMENTS: Map<Int, String> = mapOf(
    0 to "abcdef", 1 to "bc", 2 to "abdeg", 3 to "abcdg", 4 to "bcfg",
    5 to "acdfg", 6 to "acdefg", 7 to "abc", 8 to "abcdefg", 9 to "abcdfg"
)

/** Dígito de 7 segmentos (a..g) con halo en los segmentos encendidos. */
@Composable
private fun LedDigit(digit: Int, onColor: Color, height: Dp) {
    val width = height * 0.58f
    val lit = SEGMENTS[digit.coerceIn(0, 9)] ?: ""
    Canvas(modifier = Modifier.width(width).height(height)) {
        val h = size.height
        val w = size.width
        val t = maxOf(4.dp.toPx(), h * 0.11f)
        val offColor = onColor.copy(alpha = 0.12f)
        val corner = CornerRadius(t * 0.35f, t * 0.35f)

        data class Seg(val horizontal: Boolean, val cx: Float, val cy: Float)
        val segs = mapOf(
            'a' to Seg(true, w / 2f, t / 2f),
            'd' to Seg(true, w / 2f, h - t / 2f),
            'g' to Seg(true, w / 2f, h / 2f),
            'f' to Seg(false, t / 2f, h / 2f - h * 0.22f),
            'b' to Seg(false, w - t / 2f, h / 2f - h * 0.22f),
            'e' to Seg(false, t / 2f, h / 2f + h * 0.22f),
            'c' to Seg(false, w - t / 2f, h / 2f + h * 0.22f)
        )
        val glowPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.argb(
                191, (onColor.red * 255).toInt(),
                (onColor.green * 255).toInt(), (onColor.blue * 255).toInt())
            maskFilter = BlurMaskFilter(h * 0.08f, BlurMaskFilter.Blur.NORMAL)
        }
        segs.forEach { (id, seg) ->
            val segW = if (seg.horizontal) w * 0.72f else t
            val segH = if (seg.horizontal) t else h * 0.38f
            val rect = Rect(
                offset = Offset(seg.cx - segW / 2f, seg.cy - segH / 2f),
                size = Size(segW, segH)
            )
            val on = id in lit
            val color = if (on) onColor else offColor
            if (on) {
                drawIntoCanvas { canvas ->
                    canvas.nativeCanvas.drawRoundRect(
                        rect.left, rect.top, rect.right, rect.bottom,
                        corner.x, corner.y, glowPaint)
                }
            }
            drawRoundRect(color = color, topLeft = rect.topLeft,
                size = rect.size, cornerRadius = corner)
        }
    }
}

@Composable
private fun LedPair(value: Int, onColor: Color, height: Dp) {
    Row(horizontalArrangement = Arrangement.spacedBy(height * 0.08f)) {
        LedDigit((value.coerceIn(0, 99)) / 10, onColor, height)
        LedDigit(value.coerceIn(0, 99) % 10, onColor, height)
    }
}

@Composable
private fun LedColon(onColor: Color, height: Dp) {
    Column(
        modifier = Modifier.height(height),
        verticalArrangement = Arrangement.spacedBy(height * 0.22f, Alignment.CenterVertically)
    ) {
        repeat(2) {
            Canvas(modifier = Modifier.width(height * 0.12f).height(height * 0.12f)) {
                drawIntoCanvas { canvas ->
                    val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
                        color = android.graphics.Color.argb(
                            204, (onColor.red * 255).toInt(),
                            (onColor.green * 255).toInt(), (onColor.blue * 255).toInt())
                        maskFilter = BlurMaskFilter(size.height * 0.5f, BlurMaskFilter.Blur.NORMAL)
                    }
                    canvas.nativeCanvas.drawCircle(center.x, center.y, size.height / 2f, paint)
                }
                drawCircle(onColor)
            }
        }
    }
}

/**
 * Ronda (verde, opcional) + MM:SS (rojo) como en BlockTimerScreen de iOS.
 * La descripción de accesibilidad replica la de iOS en español.
 */
@Composable
fun LedClockDisplay(
    roundNumber: Int?,
    totalSeconds: Int,
    digitHeight: Dp,
    modifier: Modifier = Modifier
) {
    val seconds = totalSeconds.coerceAtLeast(0)
    val minutes = seconds / 60
    val secs = seconds % 60
    val description = if (roundNumber != null)
        "Ronda $roundNumber, $minutes minutos $secs segundos"
    else "$minutes minutos $secs segundos"
    Row(
        modifier = modifier.semantics(mergeDescendants = true) {
            contentDescription = description
        },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(digitHeight * 0.22f)
    ) {
        if (roundNumber != null) {
            LedPair(roundNumber.coerceIn(0, 99), LedClock.roundColor, digitHeight)
        }
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(digitHeight * 0.08f)
        ) {
            LedPair(minutes.coerceAtMost(99), LedClock.timeColor, digitHeight)
            LedColon(LedClock.timeColor, digitHeight)
            LedPair(secs, LedClock.timeColor, digitHeight)
        }
    }
}
