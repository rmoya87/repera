package dev.repera.mobile

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.widthIn
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/** Apple 0a640da8 Theme.swift: OG.contentColumnMaxWidth = 790 pt.
 *  Una única columna centrada para tarjetas y listas en paisaje/pantallas
 *  anchas; en retrato de teléfono 790 dp supera el ancho y no restringe. */
internal val CONTENT_COLUMN_MAX_WIDTH = 790.dp

/** Apple OGReadableColumnModifier: contenido limitado a 790dp y centrado. */
@Composable
internal fun ReadableColumn(content: @Composable BoxScope.() -> Unit) {
    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
        Box(Modifier.fillMaxWidth().widthIn(max = CONTENT_COLUMN_MAX_WIDTH),
            content = content)
    }
}
