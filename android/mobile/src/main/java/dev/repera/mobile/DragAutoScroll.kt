package dev.repera.mobile

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.foundation.lazy.LazyListState

/** Contenedor desplazable padre: `by` desplaza `delta` px y devuelve lo consumido; `viewport` da (top, bottom) en
 *  coordenadas de raíz del área visible REAL del contenedor (null si aún no medido). */
internal class DragScroller(val by: (Float) -> Float, val viewport: () -> Pair<Float, Float>?)

internal val LocalDragAutoScroller = compositionLocalOf<DragScroller?> { null }

@Composable
internal fun ProvideLazyDragAutoScroll(state: LazyListState, content: @Composable () -> Unit) {
    var boxTop by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf<Float?>(null) }
    val scroller = androidx.compose.runtime.remember(state) {
        DragScroller(
            by = { d -> state.dispatchRawDelta(d) },
            viewport = { boxTop?.let { it to it + state.layoutInfo.viewportSize.height } })
    }
    androidx.compose.foundation.layout.Box(
        androidx.compose.ui.Modifier.androidxFill().androidxMeasure { boxTop = it }) {
        CompositionLocalProvider(LocalDragAutoScroller provides scroller, content = content)
    }
}

private fun androidx.compose.ui.Modifier.androidxFill() = this.fillMaxSize()
private fun androidx.compose.ui.Modifier.androidxMeasure(onTop: (Float) -> Unit) =
    this.onGloballyPositioned { onTop(it.positionInRoot().y) }

/**
 * Velocidad de autoscroll (px por fotograma) para una fila arrastrada cuyo centro está en `centerY`
 * (coordenadas de ventana). 0 en la zona central; rampa lineal dentro de `edgePx` de cada borde;
 * acotada por `maxPerFrame`. Negativa = subir. Pura y testeable.
 */
internal fun autoScrollSpeed(centerY: Float, viewportTop: Float, viewportBottom: Float, edgePx: Float, maxPerFrame: Float): Float {
    if (edgePx <= 0f || viewportBottom <= viewportTop) return 0f
    return when {
        centerY < viewportTop + edgePx -> -maxPerFrame * ((viewportTop + edgePx - centerY) / edgePx).coerceIn(0f, 1f)
        centerY > viewportBottom - edgePx -> maxPerFrame * ((centerY - (viewportBottom - edgePx)) / edgePx).coerceIn(0f, 1f)
        else -> 0f
    }
}
