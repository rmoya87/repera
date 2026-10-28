package dev.repera.mobile

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp

/**
 * Tema Material 3 de Repera: verde de marca (OG.accent / #30D158) y radios
 * alineados con Theme.swift (radiusCard 14, radiusLG 16). Envuelve onboarding,
 * tabs y splash para no caer en el púrpura por defecto de Material.
 */
@Composable
fun ReperaTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = reperaColorScheme(darkTheme),
        shapes = reperaShapes,
        typography = Typography(),
        content = content
    )
}

/** Radios tipo OG.radiusCard / OG.radiusLG; sheets usan extraLarge. */
internal val reperaShapes = Shapes(
    extraSmall = RoundedCornerShape(8.dp),
    small = RoundedCornerShape(10.dp),
    medium = RoundedCornerShape(14.dp),
    large = RoundedCornerShape(16.dp),
    extraLarge = RoundedCornerShape(28.dp)
)
