package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.AccessibilityNew

/** Glifos corporales de los chips de músculo (port 1:1 de BodyPartGlyphArea +
 *  BodyPartGlyphDrawing + MuscleChipGlyph de ExerciseDetailView.swift iOS).
 *  Trazos vectoriales de referencia 20x20: silueta + una marca de área. */
enum class BodyPartGlyphArea {
    SHOULDERS, UPPER_ARM, FOREARM, CHEST, BACK, CORE, HIPS, THIGH, LOWER_LEG, UNKNOWN;

    companion object {
        /** Acepta el slug del catálogo y el nombre localizado (mismo fold que iOS). */
        fun forMuscle(muscle: String): BodyPartGlyphArea {
            val key = dev.repera.domain.CrossFitGlossary.normalize(muscle.trim()).lowercase()
            return when (key) {
                "deltoids", "deltoides", "delts", "hombros", "shoulders",
                "trapezius", "trapezio", "trapecios", "traps" -> SHOULDERS
                "biceps", "triceps", "brachialis", "brazo", "upper arms" -> UPPER_ARM
                "forearm", "forearms", "antebrazo", "antebrazos", "grip", "agarre" -> FOREARM
                "chest", "pecho", "pectorals", "pectoral", "pectorales",
                "serratus", "serrato" -> CHEST
                "upper-back", "upper back", "espalda alta", "lats",
                "latissimus dorsi", "dorsales", "dorsal", "dorsal ancho",
                "back", "espalda", "lower-back", "lower back", "lumbar" -> BACK
                "abs", "abdominals", "abdomen", "abdominales",
                "obliques", "oblicuos", "core" -> CORE
                "gluteal", "glutes", "gluteos", "gluteo",
                "hip-flexors", "hip flexors", "flexores de cadera",
                "adductors", "aductores", "abductors", "abductores",
                "hips", "cadera" -> HIPS
                "quadriceps", "cuadriceps", "quads", "hamstring",
                "hamstrings", "isquios", "isquiotibiales", "muslo" -> THIGH
                "calves", "gemelos", "soleus", "tibialis", "tibial",
                "pantorrilla", "lower legs" -> LOWER_LEG
                else -> UNKNOWN
            }
        }
    }
}

private fun Path.quad(cx: Float, cy: Float, x: Float, y: Float) =
    quadraticBezierTo(cx, cy, x, y)
private fun Path.oval(x: Float, y: Float, w: Float, h: Float) =
    addOval(Rect(x, y, x + w, y + h))

/** Silueta (outline) y marca de área (highlight), coordenadas 0..20. */
private fun glyphPaths(area: BodyPartGlyphArea): Pair<Path, Path> {
    val line = Path()
    val mark = Path()
    when (area) {
        BodyPartGlyphArea.SHOULDERS -> {
            line.moveTo(7f, 2f); line.quad(7f, 4f, 6f, 5f); line.quad(3f, 5f, 2f, 7f)
            line.lineTo(1.5f, 14f)
            line.moveTo(13f, 2f); line.quad(13f, 4f, 14f, 5f); line.quad(17f, 5f, 18f, 7f)
            line.lineTo(18.5f, 14f)
            line.moveTo(7f, 5f); line.quad(10f, 7f, 13f, 5f)
            line.moveTo(5f, 10f); line.lineTo(6f, 16f)
            line.moveTo(15f, 10f); line.lineTo(14f, 16f)
            mark.oval(2.4f, 6.7f, 3.5f, 4f); mark.oval(14.1f, 6.7f, 3.5f, 4f)
        }
        BodyPartGlyphArea.UPPER_ARM -> {
            line.moveTo(3f, 12f); line.quad(2f, 8f, 4f, 5f); line.quad(5f, 2f, 8f, 3.5f)
            line.quad(11f, 5f, 10f, 8f); line.quad(12f, 5f, 15f, 6f)
            line.quad(19f, 8f, 18f, 11f); line.quad(18f, 16f, 14f, 17f)
            line.quad(6f, 19f, 3f, 12f)
            mark.oval(10.1f, 8f, 5.1f, 4f)
        }
        BodyPartGlyphArea.FOREARM -> {
            line.moveTo(3f, 2f); line.lineTo(6f, 10f); line.quad(8f, 13f, 12f, 15f)
            line.lineTo(15f, 17f); line.quad(18.5f, 16f, 18f, 13f)
            line.lineTo(14f, 11f); line.lineTo(10f, 9f); line.lineTo(8f, 2f)
            mark.oval(8f, 9f, 5f, 4f)
        }
        BodyPartGlyphArea.CHEST -> {
            line.moveTo(7f, 2f); line.quad(7f, 4f, 5f, 5f); line.quad(3f, 5f, 2f, 7f)
            line.lineTo(1.5f, 14f)
            line.moveTo(13f, 2f); line.quad(13f, 4f, 15f, 5f); line.quad(17f, 5f, 18f, 7f)
            line.lineTo(18.5f, 14f)
            line.moveTo(5f, 9f); line.lineTo(6f, 17f)
            line.moveTo(15f, 9f); line.lineTo(14f, 17f)
            mark.oval(4.4f, 6f, 5f, 4.7f); mark.oval(10.6f, 6f, 5f, 4.7f)
        }
        BodyPartGlyphArea.BACK -> {
            line.moveTo(7f, 2f); line.quad(7f, 4f, 3f, 6f); line.lineTo(2f, 14f)
            line.moveTo(13f, 2f); line.quad(13f, 4f, 17f, 6f); line.lineTo(18f, 14f)
            line.moveTo(5f, 10f); line.lineTo(6f, 17f)
            line.moveTo(15f, 10f); line.lineTo(14f, 17f)
            line.moveTo(10f, 5f); line.lineTo(10f, 16f)
            mark.oval(5f, 6f, 4.2f, 8f); mark.oval(10.8f, 6f, 4.2f, 8f)
        }
        BodyPartGlyphArea.CORE -> {
            line.moveTo(4f, 2f); line.quad(6f, 9f, 4f, 17f)
            line.moveTo(16f, 2f); line.quad(14f, 9f, 16f, 17f)
            line.moveTo(6f, 4f); line.lineTo(14f, 4f)
            line.moveTo(6f, 16f); line.lineTo(14f, 16f)
            mark.oval(7f, 7f, 6f, 7f)
        }
        BodyPartGlyphArea.HIPS -> {
            line.moveTo(5f, 2f); line.quad(2f, 5f, 3f, 10f); line.quad(4f, 14f, 8f, 16f)
            line.lineTo(10f, 18f); line.lineTo(12f, 16f); line.quad(16f, 14f, 17f, 10f)
            line.quad(18f, 5f, 15f, 2f)
            line.moveTo(8f, 12f); line.quad(10f, 9f, 12f, 12f)
            mark.oval(4.9f, 7f, 5f, 6f); mark.oval(10.1f, 7f, 5f, 6f)
        }
        BodyPartGlyphArea.THIGH -> {
            line.moveTo(4f, 2f); line.lineTo(3f, 8f); line.lineTo(4f, 17f)
            line.moveTo(16f, 2f); line.lineTo(17f, 8f); line.lineTo(16f, 17f)
            line.moveTo(4f, 2f); line.quad(10f, 5f, 16f, 2f)
            line.moveTo(10f, 8f); line.lineTo(8f, 17f)
            line.moveTo(10f, 8f); line.lineTo(12f, 17f)
            mark.oval(4.2f, 8f, 3.6f, 7f); mark.oval(12.2f, 8f, 3.6f, 7f)
        }
        BodyPartGlyphArea.LOWER_LEG -> {
            line.moveTo(6f, 2f); line.quad(4f, 6f, 6f, 10f); line.lineTo(5f, 15f)
            line.quad(4f, 17f, 2f, 18f); line.lineTo(16f, 18f)
            line.quad(17f, 16f, 14f, 15f); line.lineTo(12f, 13f)
            line.quad(15f, 7f, 13f, 2f)
            mark.oval(7.1f, 5.5f, 4.5f, 7f)
        }
        BodyPartGlyphArea.UNKNOWN -> {}
    }
    return line to mark
}

/** Glifo de 16dp para el chip de un músculo. Cardio usa el mismo corazón que
 *  el filtro de la biblioteca (Apple 5099d9f1); desconocido, el icono genérico. */
@Composable
fun MuscleChipGlyph(muscle: String, emphasized: Boolean) {
    val tint = if (emphasized) MaterialTheme.colorScheme.onPrimary
               else MaterialTheme.colorScheme.onSurface
    if (muscle.trim().equals("Cardio", ignoreCase = true)) {
        // Mismo corazón que el filtro Cardio de la biblioteca (Apple 5099d9f1).
        androidx.compose.material3.Icon(
            androidx.compose.material.icons.Icons.Filled.Favorite,
            contentDescription = null, tint = tint, modifier = Modifier.size(16.dp))
        return
    }
    val area = BodyPartGlyphArea.forMuscle(muscle)
    if (area == BodyPartGlyphArea.UNKNOWN) {
        // ExerciseCategorySymbols.muscle iOS ("figure.stand") ≈ persona de pie.
        androidx.compose.material3.Icon(
            androidx.compose.material.icons.Icons.Filled.AccessibilityNew,
            contentDescription = null, tint = tint, modifier = Modifier.size(16.dp))
        return
    }
    val ink = if (emphasized) MaterialTheme.colorScheme.onPrimary
              else MaterialTheme.colorScheme.onSurface
    val highlight = if (emphasized) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.65f)
                    else MaterialTheme.colorScheme.primary
    Canvas(Modifier.size(16.dp)) {
        val scale = size.width / 20f
        val (outline, mark) = glyphPaths(area)
        fun Path.scaled(): Path {
            val p = Path(); p.addPath(this); p.transform(
                androidx.compose.ui.graphics.Matrix().apply { scale(scale, scale) })
            return p
        }
        drawPath(mark.scaled(), color = highlight)
        drawPath(outline.scaled(), color = ink,
            style = Stroke(width = 1.5.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}
