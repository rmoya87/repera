package dev.repera.mobile

import android.graphics.Path as AndroidPath
import android.graphics.RectF
import android.graphics.Region
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path as ComposePath
import androidx.compose.ui.graphics.asComposePath
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import dev.repera.domain.MuscleTaxonomy
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject

/** 0 gris · 1 verde · 2 amarillo · 3 naranja · 4 rojo (port de BodyMapPalette iOS). */
internal object BodyMapPalette {
    val yellow = Color(1f, 214f / 255f, 10f / 255f)
    val orange = Color(1f, 159f / 255f, 10f / 255f)
    val red = Color(1f, 69f / 255f, 58f / 255f)
    val gray = Color(0.23f, 0.23f, 0.24f)

    fun fill(level: Int): Color = when (level) {
        1 -> brandGreen
        2 -> yellow
        3 -> orange
        4 -> red
        else -> gray
    }

    val silhouette: Color = gray.copy(alpha = 0.55f)
}

internal class CompiledBodyView(
    val viewBox: RectF,
    val inertPaths: Map<String, List<AndroidPath>>,
    val musclePaths: Map<String, List<AndroidPath>>
)

internal class CompiledBodyPaths(val front: CompiledBodyView, val back: CompiledBodyView) {
    companion object {
        @Volatile private var cached: CompiledBodyPaths? = null

        /** Parsea una vez fuera del hilo principal (port de BodyPathsLoader iOS). */
        suspend fun shared(context: android.content.Context): CompiledBodyPaths? {
            cached?.let { return it }
            val compiled = withContext(Dispatchers.Default) {
                runCatching {
                    val text = context.assets.open("BodyPaths.json").bufferedReader().use { it.readText() }
                    val root = JSONObject(text)
                    val male = root.getJSONObject("male")
                    CompiledBodyPaths(
                        front = compile(male.getJSONObject("front")),
                        back = compile(male.getJSONObject("back"))
                    )
                }.getOrNull()
            }
            cached = compiled
            return compiled
        }

        private fun compile(view: JSONObject): CompiledBodyView {
            val parts = view.getString("vb").split(" ").mapNotNull { it.toDoubleOrNull() }
            val vb = if (parts.size == 4) RectF(
                parts[0].toFloat(), parts[1].toFloat(),
                (parts[0] + parts[2]).toFloat(), (parts[1] + parts[3]).toFloat()
            ) else RectF()
            val inert = mutableMapOf<String, MutableList<AndroidPath>>()
            val muscles = mutableMapOf<String, MutableList<AndroidPath>>()
            val paths = view.getJSONObject("p")
            for (slug in paths.keys()) {
                // Rostro y pelo se sustituyen por una cabeza neutra (port iOS).
                if (slug == "head" || slug == "hair") continue
                val arr = paths.getJSONArray(slug)
                val list = mutableListOf<AndroidPath>()
                for (i in 0 until arr.length()) {
                    val ops = SvgPathParser.parse(arr.getString(i))
                    if (ops.isNotEmpty()) list += ops.toAndroidPath()
                }
                if (list.isEmpty()) continue
                if (MuscleTaxonomy.inert.contains(slug)) inert.getOrPut(slug) { mutableListOf() }.addAll(list)
                else if (MuscleTaxonomy.muscles.contains(slug)) muscles.getOrPut(slug) { mutableListOf() }.addAll(list)
            }
            if (vb.width() > 0) {
                val headRect = RectF(vb.centerX() - 57, vb.top + 12, vb.centerX() + 57, vb.top + 12 + 143)
                inert["head"] = mutableListOf(AndroidPath().apply { addOval(headRect, AndroidPath.Direction.CW) })
            }
            return CompiledBodyView(vb, inert, muscles)
        }
    }
}

internal fun List<SvgPathParser.PathOp>.toAndroidPath(): AndroidPath {
    val p = AndroidPath()
    for (op in this) {
        when (op) {
            is SvgPathParser.PathOp.MoveTo -> p.moveTo(op.x.toFloat(), op.y.toFloat())
            is SvgPathParser.PathOp.LineTo -> p.lineTo(op.x.toFloat(), op.y.toFloat())
            is SvgPathParser.PathOp.CubicTo -> p.cubicTo(
                op.c1x.toFloat(), op.c1y.toFloat(),
                op.c2x.toFloat(), op.c2y.toFloat(),
                op.x.toFloat(), op.y.toFloat()
            )
            is SvgPathParser.PathOp.QuadTo -> p.quadTo(op.cx.toFloat(), op.cy.toFloat(), op.x.toFloat(), op.y.toFloat())
            SvgPathParser.PathOp.Close -> p.close()
        }
    }
    return p
}

/** Silueta frente/espalda sombreada por fatiga / intensidad (verde → rojo). Port 1:1 de BodyMapView iOS. */
@Composable
internal fun BodyMapView(
    load: Map<String, Double>,
    fatigueScores: Map<String, Double>?,
    selected: String?,
    onSelect: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current.applicationContext
    val compiled by produceState<CompiledBodyPaths?>(null, context) {
        value = CompiledBodyPaths.shared(context)
    }
    val levels: Map<String, Int> = if (fatigueScores != null) {
        dev.repera.domain.MuscleMapEngine.levels(fatigueScores)
    } else {
        dev.repera.domain.MuscleLoadEngine.levels(load)
    }

    val paths = compiled
    if (paths == null) {
        Spacer(modifier.height(220.dp).fillMaxWidth())
        return
    }
    Row(modifier.height(220.dp).fillMaxWidth().testTag("body_map_loaded")) {
        BodySilhouetteView(paths.front, levels, selected, onSelect, Modifier.weight(1f))
        Spacer(Modifier.width(4.dp))
        BodySilhouetteView(paths.back, levels, selected, onSelect, Modifier.weight(1f))
    }
}

@Composable
private fun BodySilhouetteView(
    view: CompiledBodyView,
    levels: Map<String, Int>,
    selected: String?,
    onSelect: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Canvas(
        modifier.pointerInput(view, selected) {
            detectTapGestures { offset ->
                hitTest(view, offset, size)?.let(onSelect)
            }
        }
    ) {
        val vb = view.viewBox
        if (vb.width() <= 0 || vb.height() <= 0) return@Canvas
        val scale = minOf(size.width / vb.width(), size.height / vb.height())
        val dx = (size.width - vb.width() * scale) / 2 - vb.left * scale
        val dy = (size.height - vb.height() * scale) / 2 - vb.top * scale

        drawContext.canvas.save()
        drawContext.canvas.translate(dx, dy)
        drawContext.canvas.scale(scale, scale)
        for (slug in MuscleTaxonomy.muscles) {
            val level = levels[slug] ?: 0
            val isSel = selected == slug
            for (path in view.musclePaths[slug] ?: emptyList()) {
                val compose = path.asComposePath()
                drawPath(compose, color = BodyMapPalette.fill(level))
                if (isSel) {
                    drawPath(compose, color = Color.White, style = Stroke(width = 1.5f / scale))
                }
            }
        }
        for (path in view.inertPaths["head"] ?: emptyList()) {
            drawPath(path.asComposePath(), color = BodyMapPalette.silhouette)
        }
        drawContext.canvas.restore()
    }
}


private fun hitTest(view: CompiledBodyView, point: Offset, size: androidx.compose.ui.unit.IntSize): String? {
    val vb = view.viewBox
    if (vb.width() <= 0 || vb.height() <= 0) return null
    val scale = minOf(size.width / vb.width(), size.height / vb.height())
    val dx = (size.width - vb.width() * scale) / 2 - vb.left * scale
    val dy = (size.height - vb.height() * scale) / 2 - vb.top * scale
    val px = ((point.x - dx) / scale).toInt()
    val py = ((point.y - dy) / scale).toInt()
    val clip = Region(
        (vb.left - 1).toInt(), (vb.top - 1).toInt(),
        (vb.right + 1).toInt(), (vb.bottom + 1).toInt()
    )
    for (slug in MuscleTaxonomy.muscles.asReversed()) {
        for (path in view.musclePaths[slug] ?: emptyList()) {
            val region = Region()
            region.setPath(path, clip)
            if (region.contains(px, py)) return slug
        }
    }
    return null
}
