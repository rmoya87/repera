package dev.repera.mobile

import kotlin.math.abs
import kotlin.math.acos
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.math.tan

/**
 * Port 1:1 de SVGPathParser (iOS, BodyMapView.swift): M L H V C Q A Z +
 * relativos. Los arcos `a` son críticos en BodyPaths (conversión elíptica
 * SVG → cúbicas según spec W3C). Produce un modelo puro de operaciones para
 * ser testable sin android.graphics.Path; la capa UI lo materializa.
 */
object SvgPathParser {

    sealed interface PathOp {
        data class MoveTo(val x: Double, val y: Double) : PathOp
        data class LineTo(val x: Double, val y: Double) : PathOp
        data class CubicTo(
            val c1x: Double, val c1y: Double,
            val c2x: Double, val c2y: Double,
            val x: Double, val y: Double
        ) : PathOp
        data class QuadTo(val cx: Double, val cy: Double, val x: Double, val y: Double) : PathOp
        data object Close : PathOp
    }

    fun parse(d: String): List<PathOp> {
        val tokens = tokenize(d)
        if (tokens.isEmpty()) return emptyList()
        val ops = mutableListOf<PathOp>()
        var i = 0
        var cx = 0.0
        var cy = 0.0
        var startX = 0.0
        var startY = 0.0
        var lastCmd = 'M'

        fun isCommand(s: String) = s.length == 1 && s[0].isLetter()
        fun nextNumber(): Double? {
            if (i >= tokens.size) return null
            val v = tokens[i].toDoubleOrNull() ?: return null
            i++
            return v
        }
        fun nextPoint(): Pair<Double, Double>? {
            val x = nextNumber() ?: return null
            val y = nextNumber() ?: return null
            return x to y
        }
        fun skipNumbers() {
            while (i < tokens.size && !isCommand(tokens[i])) i++
        }

        while (i < tokens.size) {
            val cmd: Char
            if (isCommand(tokens[i])) {
                cmd = tokens[i][0]
                i++
                lastCmd = cmd
            } else {
                cmd = when (lastCmd) {
                    'M' -> 'L'
                    'm' -> 'l'
                    else -> lastCmd
                }
            }
            when (cmd) {
                'M', 'm' -> {
                    val p = nextPoint() ?: return ops
                    val ax = if (cmd == 'M') p.first else cx + p.first
                    val ay = if (cmd == 'M') p.second else cy + p.second
                    ops += PathOp.MoveTo(ax, ay)
                    cx = ax; cy = ay
                    startX = ax; startY = ay
                    while (i < tokens.size && !isCommand(tokens[i])) {
                        val q = nextPoint() ?: break
                        val lx = if (cmd == 'M') q.first else cx + q.first
                        val ly = if (cmd == 'M') q.second else cy + q.second
                        ops += PathOp.LineTo(lx, ly)
                        cx = lx; cy = ly
                        lastCmd = if (cmd == 'M') 'L' else 'l'
                    }
                }
                'L', 'l' -> {
                    while (i < tokens.size && !isCommand(tokens[i])) {
                        val p = nextPoint() ?: break
                        val ax = if (cmd == 'L') p.first else cx + p.first
                        val ay = if (cmd == 'L') p.second else cy + p.second
                        ops += PathOp.LineTo(ax, ay)
                        cx = ax; cy = ay
                    }
                }
                'H', 'h' -> {
                    while (i < tokens.size && !isCommand(tokens[i])) {
                        val x = nextNumber() ?: break
                        val ax = if (cmd == 'H') x else cx + x
                        ops += PathOp.LineTo(ax, cy)
                        cx = ax
                    }
                }
                'V', 'v' -> {
                    while (i < tokens.size && !isCommand(tokens[i])) {
                        val y = nextNumber() ?: break
                        val ay = if (cmd == 'V') y else cy + y
                        ops += PathOp.LineTo(cx, ay)
                        cy = ay
                    }
                }
                'C', 'c' -> {
                    while (i < tokens.size && !isCommand(tokens[i])) {
                        val c1 = nextPoint() ?: break
                        val c2 = nextPoint() ?: break
                        val end = nextPoint() ?: break
                        if (cmd == 'C') {
                            ops += PathOp.CubicTo(c1.first, c1.second, c2.first, c2.second, end.first, end.second)
                            cx = end.first; cy = end.second
                        } else {
                            ops += PathOp.CubicTo(
                                cx + c1.first, cy + c1.second,
                                cx + c2.first, cy + c2.second,
                                cx + end.first, cy + end.second
                            )
                            cx += end.first; cy += end.second
                        }
                    }
                }
                'Q', 'q' -> {
                    while (i < tokens.size && !isCommand(tokens[i])) {
                        val c = nextPoint() ?: break
                        val end = nextPoint() ?: break
                        if (cmd == 'Q') {
                            ops += PathOp.QuadTo(c.first, c.second, end.first, end.second)
                            cx = end.first; cy = end.second
                        } else {
                            ops += PathOp.QuadTo(cx + c.first, cy + c.second, cx + end.first, cy + end.second)
                            cx += end.first; cy += end.second
                        }
                    }
                }
                'A', 'a' -> {
                    while (i < tokens.size && !isCommand(tokens[i])) {
                        val rx = nextNumber() ?: break
                        val ry = nextNumber() ?: break
                        val rotation = nextNumber() ?: break
                        val large = nextNumber() ?: break
                        val sweep = nextNumber() ?: break
                        val x = nextNumber() ?: break
                        val y = nextNumber() ?: break
                        val ex = if (cmd == 'A') x else cx + x
                        val ey = if (cmd == 'A') y else cy + y
                        addArc(ops, cx, cy, ex, ey, abs(rx), abs(ry), rotation,
                            largeArc = large != 0.0, sweep = sweep != 0.0)
                        cx = ex; cy = ey
                    }
                }
                'Z', 'z' -> {
                    ops += PathOp.Close
                    cx = startX; cy = startY
                }
                else -> skipNumbers()
            }
        }
        return ops
    }

    /** Conversión arco elíptico SVG → cúbicas (spec W3C), port 1:1 del Swift. */
    private fun addArc(
        ops: MutableList<PathOp>,
        sx: Double, sy: Double,
        ex: Double, ey: Double,
        rxIn: Double, ryIn: Double,
        xAxisRotationDegrees: Double,
        largeArc: Boolean, sweep: Boolean
    ) {
        if (rxIn == 0.0 || ryIn == 0.0 || (sx == ex && sy == ey)) {
            ops += PathOp.LineTo(ex, ey)
            return
        }
        val phi = xAxisRotationDegrees * Math.PI / 180.0
        val cosPhi = cos(phi)
        val sinPhi = sin(phi)

        val dx = (sx - ex) / 2
        val dy = (sy - ey) / 2
        val x1p = cosPhi * dx + sinPhi * dy
        val y1p = -sinPhi * dx + cosPhi * dy

        var rx2 = rxIn
        var ry2 = ryIn
        val lambda = (x1p * x1p) / (rx2 * rx2) + (y1p * y1p) / (ry2 * ry2)
        if (lambda > 1) {
            val s = sqrt(lambda)
            rx2 *= s
            ry2 *= s
        }

        val rxSq = rx2 * rx2
        val rySq = ry2 * ry2
        val x1pSq = x1p * x1p
        val y1pSq = y1p * y1p
        var sq = max(0.0, (rxSq * rySq - rxSq * y1pSq - rySq * x1pSq) /
            (rxSq * y1pSq + rySq * x1pSq))
        sq = sqrt(sq)
        if (largeArc == sweep) sq = -sq
        val cxp = sq * (rx2 * y1p) / ry2
        val cyp = sq * -(ry2 * x1p) / rx2

        val cx = cosPhi * cxp - sinPhi * cyp + (sx + ex) / 2
        val cy = sinPhi * cxp + cosPhi * cyp + (sy + ey) / 2

        fun angle(ux: Double, uy: Double, vx: Double, vy: Double): Double {
            val n = sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
            if (n <= 0) return 0.0
            var a = acos(max(-1.0, min(1.0, (ux * vx + uy * vy) / n)))
            if (ux * vy - uy * vx < 0) a = -a
            return a
        }

        val svx = (x1p - cxp) / rx2
        val svy = (y1p - cyp) / ry2
        val evx = (-x1p - cxp) / rx2
        val evy = (-y1p - cyp) / ry2
        val theta1 = angle(1.0, 0.0, svx, svy)
        var dTheta = angle(svx, svy, evx, evy)
        if (!sweep && dTheta > 0) dTheta -= 2 * Math.PI
        if (sweep && dTheta < 0) dTheta += 2 * Math.PI

        val segments = max(1, ceil(abs(dTheta) / (Math.PI / 2)).toInt())
        val delta = dTheta / segments
        val t = (4.0 / 3.0) * tan(delta / 4)

        var angle0 = theta1
        repeat(segments) {
            val angle1 = angle0 + delta
            val cos0 = cos(angle0); val sin0 = sin(angle0)
            val cos1 = cos(angle1); val sin1 = sin(angle1)

            val e0x = cx + rx2 * cosPhi * cos0 - ry2 * sinPhi * sin0
            val e0y = cy + rx2 * sinPhi * cos0 + ry2 * cosPhi * sin0
            val e1x = cx + rx2 * cosPhi * cos1 - ry2 * sinPhi * sin1
            val e1y = cy + rx2 * sinPhi * cos1 + ry2 * cosPhi * sin1
            val c1x = e0x + t * (-rx2 * cosPhi * sin0 - ry2 * sinPhi * cos0)
            val c1y = e0y + t * (-rx2 * sinPhi * sin0 + ry2 * cosPhi * cos0)
            val c2x = e1x + t * (rx2 * cosPhi * sin1 + ry2 * sinPhi * cos1)
            val c2y = e1y + t * (rx2 * sinPhi * sin1 + ry2 * cosPhi * cos1)
            ops += PathOp.CubicTo(c1x, c1y, c2x, c2y, e1x, e1y)
            angle0 = angle1
        }
    }

    /** Tokeniza paths SVG; separa `37.02.75` → `37.02` + `.75` (muy frecuente en BodyPaths). */
    internal fun tokenize(d: String): List<String> {
        val out = mutableListOf<String>()
        var num = StringBuilder()
        var sawDot = false
        var sawExp = false

        fun flush() {
            if (num.isNotEmpty()) {
                out += num.toString()
                num = StringBuilder()
            }
            sawDot = false
            sawExp = false
        }

        for (ch in d) {
            if (ch.isLetter() && ch != 'e' && ch != 'E') {
                flush()
                out += ch.toString()
            } else if (ch == ',' || ch.isWhitespace()) {
                flush()
            } else if ((ch == 'e' || ch == 'E') && num.isNotEmpty()) {
                num.append(ch)
                sawExp = true
            } else if (ch == '-' || ch == '+') {
                // Signo: nuevo número, salvo exponente (`1e-3`).
                if (num.isEmpty() || sawExp && (num.last() == 'e' || num.last() == 'E')) {
                    num.append(ch)
                    if (sawExp) sawExp = false
                } else {
                    flush()
                    num.append(ch)
                }
            } else if (ch == '.') {
                if (sawDot) {
                    // Segundo punto decimal → empieza otro número (p. ej. 37.02.75).
                    flush()
                    num.append(ch)
                    sawDot = true
                } else {
                    num.append(ch)
                    sawDot = true
                }
            } else if (ch.isDigit()) {
                num.append(ch)
            } else {
                flush()
            }
        }
        flush()
        return out
    }
}
