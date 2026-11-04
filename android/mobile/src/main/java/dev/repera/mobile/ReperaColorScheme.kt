package dev.repera.mobile

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/**
 * Tokens adaptativos de Theme.swift (OG.*): primary = verde Repera.
 * Claro y oscuro: #30D158 (OG.accent) + onPrimary negro (OG.onAccent), paridad iOS.
 * tertiary = azul OG (no violeta). surfaceTint verde para que tonales M3
 * no deriven al púrpura del ColorScheme por defecto.
 * error = OG.red; en claro se usa la variante accesible (#D70015, AA sobre blanco).
 */
internal fun reperaColorScheme(dark: Boolean): ColorScheme {
    val extended = reperaExtendedColors(dark)
    return if (dark) {
    darkColorScheme(
        primary = brandGreen, onPrimary = Color.Black,
        primaryContainer = Color(0xFF143A22), onPrimaryContainer = Color(0xFFB8F4C7),
        secondary = Color(0xFFAEB0AE), onSecondary = Color.Black,
        secondaryContainer = Color(0xFF2C2C2E), onSecondaryContainer = Color(0xFFF5F5F7),
        tertiary = Color(0xFF0A84FF), onTertiary=Color.Black,
        tertiaryContainer=Color(0xFF102C4C),onTertiaryContainer=Color(0xFFD3E5FF),
        inverseSurface=Color(0xFFF5F5F7),inverseOnSurface=Color(0xFF1C1C1E),inversePrimary=brandGreen,
        background = Color.Black, onBackground = Color(0xFFF5F5F7),
        surface = Color(0xFF1C1C1E), onSurface = Color(0xFFF5F5F7),
        surfaceVariant = Color(0xFF2C2C2E), onSurfaceVariant = Color(0xFFAEB0B2),
        surfaceContainer = Color(0xFF1C1C1E), surfaceContainerLow = Color(0xFF0C0C0C),
        surfaceContainerHigh = Color(0xFF2C2C2E), surfaceContainerHighest = Color(0xFF3A3A3C),
        surfaceContainerLowest = Color.Black, outline = Color(0xFF787880), outlineVariant = Color(0xFF3A3A3C), surfaceTint = brandGreen,
        error = extended.destructive, onError = Color.Black,
        errorContainer = Color(0xFF4A1512), onErrorContainer = Color(0xFFFFDAD6))
    } else {
    lightColorScheme(
        primary = brandGreen, onPrimary = Color.Black,
        primaryContainer = Color(0xFFC5F1CF), onPrimaryContainer = Color(0xFF083C1B),
        secondary = Color(0xFF5D6E63), onSecondary = Color.White,
        secondaryContainer = Color(0xFFDCE4DF), onSecondaryContainer = Color(0xFF172620),
        tertiary = Color(0xFF0965BC), onTertiary=Color.White,
        tertiaryContainer=Color(0xFFD3E5FF),onTertiaryContainer=Color(0xFF082448),
        inverseSurface=Color(0xFF1C1C1E),inverseOnSurface=Color(0xFFF5F5F7),inversePrimary=brandGreenReadable,
        background = Color(0xFFF2F5F3), onBackground = Color(0xFF172620),
        surface = Color.White, onSurface = Color(0xFF172620),
        surfaceVariant = Color(0xFFF2F5F3), onSurfaceVariant = Color(0xFF5D6E63),
        surfaceContainer = Color.White, surfaceContainerLow = Color(0xFFF2F5F3),
        surfaceContainerHigh = Color(0xFFEBEFED), surfaceContainerHighest = Color(0xFFDCE4DF),
        surfaceContainerLowest = Color.White, outline = Color(0xFF89998F), outlineVariant = Color(0xFFDCE4DF), surfaceTint = brandGreen,
        error = extended.destructive, onError = Color.White,
        errorContainer = Color(0xFFFFDAD6), onErrorContainer = Color(0xFF410002))
    }
}

/**
 * Colores de sistema OG que Material 3 no modela (paridad Theme.swift:
 * OG.blue/orange/red/yellow…), con variante clara y oscura como UIColor dinámico.
 * `destructive` y `warning` son seguros como texto (≥ 4.5:1 sobre surface).
 */
@Immutable
internal data class ReperaExtendedColors(
    val blue: Color,
    val orange: Color,
    val yellow: Color,
    val red: Color,
    val cyan: Color,
    val destructive: Color,
    val onDestructive: Color,
    val warning: Color,
    val switchTrackOff: Color,
    /** Píldora del tab bar y accesorio «Continuar». */
    val chromeSurface: Color,
    val onChromeSurface: Color,
    /** Fondo de miniaturas/thumbs sobre [chromeSurface]. */
    val chromeThumb: Color,
    val tabSelectedFill: Color,
    /** Tiempo y ronda del temporizador espejo de Wear OS (rojo/verde LED, legibles sobre surface). */
    val timerRed: Color,
    val timerGreen: Color,
    /** Teclado numérico Repera (OGReperaNumericKeypad): fondo, tecla de dígito, utilidades y tinta. */
    val keypadBackground: Color,
    val keypadKey: Color,
    val keypadUtility: Color,
    val keypadInk: Color,
)

internal fun reperaExtendedColors(dark: Boolean): ReperaExtendedColors = if (dark) {
    ReperaExtendedColors(
        blue = Color(0xFF0A84FF), orange = Color(0xFFFF9F0A), yellow = Color(0xFFFFD60A),
        red = Color(0xFFFF453A), cyan = Color(0xFF64D2FF),
        destructive = Color(0xFFFF453A), onDestructive = Color.Black,
        warning = Color(0xFFFFB340),
        switchTrackOff = Color(0xFF39393D),
        chromeSurface = Color(0xFF2C2C2E), onChromeSurface = Color(0xFFF5F5F7),
        chromeThumb = Color(0xFF3A3A3C),
        tabSelectedFill = brandGreen.copy(alpha = 0.16f),
        timerRed = Color(0xFFFF382E), timerGreen = Color(0xFF38FF59),
        keypadBackground = Color(0xFF1C1C1E), keypadKey = Color(0xFF48484A),
        keypadUtility = Color(0xFF2C2C2E), keypadInk = Color(0xFFF5F5F7))
} else {
    ReperaExtendedColors(
        blue = Color(0xFF007AFF), orange = Color(0xFFFF9500), yellow = Color(0xFFFFCC00),
        red = Color(0xFFFF3B30), cyan = Color(0xFF32ADE6),
        destructive = Color(0xFFD70015), onDestructive = Color.White,
        warning = Color(0xFFB26A00),
        switchTrackOff = Color(0xFFE9E9EB),
        chromeSurface = Color.White, onChromeSurface = Color.Black,
        chromeThumb = Color(0xFFF2F2F7),
        tabSelectedFill = brandGreen.copy(alpha = 0.08f),
        timerRed = Color(0xFFD70015), timerGreen = brandGreenReadable,
        keypadBackground = Color(0xFFECEDF2), keypadKey = Color.White,
        keypadUtility = Color(0xFFDBDEE3), keypadInk = Color(0xFF080F1F))
}

internal val LocalReperaColors = staticCompositionLocalOf { reperaExtendedColors(dark = false) }

internal val MaterialTheme.reperaColors: ReperaExtendedColors
    @Composable @ReadOnlyComposable get() = LocalReperaColors.current

/**
 * Acentos fijos de categoría / métrica (mismo tono en claro y oscuro, como
 * los colores de categoría de Progreso en iOS). Solo para iconos, chips y
 * gráficos, nunca como color de texto sobre surface.
 */
internal object ReperaAccents {
    val training = Color(0xFF30D158)
    val strength = Color(0xFFFF9500)
    val fitness = Color(0xFF5AC8FA)
    val heart = Color(0xFFFF453A)
    val recovery = Color(0xFF33C6B8)
    val sports = Color(0xFF8C73F2)
    val energy = Color(0xFFFF9F0A)
    val minutes = Color(0xFF0A84FF)
    val swipeEdit = Color(0xFF0A84FF)
    val swipeDelete = Color(0xFFFF3B30)
    val pauseFab = Color(0xFFFFD60A)
    val heartZones = listOf(
        Color(0xFF64D2FF), Color(0xFF30D158), Color(0xFFFFD60A),
        Color(0xFFFF9F0A), Color(0xFFFF453A))
}
