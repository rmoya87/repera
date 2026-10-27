package dev.repera.mobile

import android.content.res.Configuration
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** Apple OGListChromeModifier (8f807f62/fb96456c/3045fb76): margen horizontal
 *  de 16pt siempre; en altura compacta (iPhone apaisado) se reservan 16pt
 *  exteriores extra para conservar el aire y las esquinas redondeadas.
 *  En Android el Scaffold ya aplica los insets de cutout/safe drawing, asi que
 *  aqui solo se añade el margen extra de paisaje sobre las listas agrupadas
 *  (Progreso, Crear, Ejercicios; Inicio no usa ogListChrome en Apple). */
internal val GROUPED_LIST_MARGIN: Dp = 16.dp
internal val GROUPED_LIST_MARGIN_LANDSCAPE: Dp = 32.dp

internal fun groupedListHorizontalMargin(isLandscape: Boolean): Dp =
    if (isLandscape) GROUPED_LIST_MARGIN_LANDSCAPE else GROUPED_LIST_MARGIN

@Composable
internal fun groupedListContentPadding(): PaddingValues {
    val landscape = LocalConfiguration.current.orientation ==
        Configuration.ORIENTATION_LANDSCAPE
    return PaddingValues(
        horizontal = groupedListHorizontalMargin(landscape),
        vertical = GROUPED_LIST_MARGIN)
}
