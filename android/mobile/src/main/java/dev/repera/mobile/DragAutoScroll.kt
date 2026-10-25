package dev.repera.mobile

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.foundation.lazy.LazyListState

/** Función que desplaza el contenedor padre `delta` px y devuelve lo consumido (null = sin contenedor). */
internal val LocalDragAutoScroller = compositionLocalOf<((Float) -> Float)?> { null }

@Composable
internal fun ProvideLazyDragAutoScroll(state: LazyListState, content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalDragAutoScroller provides { d -> state.dispatchRawDelta(d) }, content = content)
}

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
