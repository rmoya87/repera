package dev.repera.mobile

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color

/** Tokens adaptativos de Theme.swift 5890215d, manteniendo componentes
 * Material nativos. Evitar superficies/chips violetas del tema por defecto. */
internal fun reperaColorScheme(dark: Boolean): ColorScheme = if (dark) {
    darkColorScheme(
        primary = brandGreen, onPrimary = Color.Black,
        primaryContainer = Color(0xFF143A22), onPrimaryContainer = Color(0xFFB8F4C7),
        secondary = Color(0xFFAEB0AE), onSecondary = Color.Black,
        secondaryContainer = Color(0xFF2C2C2E), onSecondaryContainer = Color(0xFFF5F5F7),
        tertiary = Color(0xFF0A84FF), onTertiary=Color.Black,
        tertiaryContainer=Color(0xFF102C4C),onTertiaryContainer=Color(0xFFD3E5FF),
        inverseSurface=Color(0xFFF5F5F7),inverseOnSurface=Color(0xFF1C1C1E),inversePrimary=brandGreenReadable,
        background = Color.Black, onBackground = Color(0xFFF5F5F7),
        surface = Color(0xFF1C1C1E), onSurface = Color(0xFFF5F5F7),
        surfaceVariant = Color(0xFF2C2C2E), onSurfaceVariant = Color(0xFFAEB0B2),
        surfaceContainer = Color(0xFF1C1C1E), surfaceContainerLow = Color(0xFF0C0C0C),
        surfaceContainerHigh = Color(0xFF2C2C2E), surfaceContainerHighest = Color(0xFF3A3A3C),
        surfaceContainerLowest = Color.Black, outline = Color(0xFF787880), outlineVariant = Color(0xFF3A3A3C), surfaceTint = brandGreen)
} else {
    lightColorScheme(
        primary = brandGreenReadable, onPrimary = Color.White,
        primaryContainer = Color(0xFFC5F1CF), onPrimaryContainer = Color(0xFF083C1B),
        secondary = Color(0xFF5D6E63), onSecondary = Color.White,
        secondaryContainer = Color(0xFFDCE4DF), onSecondaryContainer = Color(0xFF172620),
        tertiary = Color(0xFF0965BC), onTertiary=Color.White,
        tertiaryContainer=Color(0xFFD3E5FF),onTertiaryContainer=Color(0xFF082448),
        inverseSurface=Color(0xFF1C1C1E),inverseOnSurface=Color(0xFFF5F5F7),inversePrimary=brandGreen,
        background = Color(0xFFF2F5F3), onBackground = Color(0xFF172620),
        surface = Color.White, onSurface = Color(0xFF172620),
        surfaceVariant = Color(0xFFF2F5F3), onSurfaceVariant = Color(0xFF5D6E63),
        surfaceContainer = Color.White, surfaceContainerLow = Color(0xFFF2F5F3),
        surfaceContainerHigh = Color(0xFFEBEFED), surfaceContainerHighest = Color(0xFFDCE4DF),
        surfaceContainerLowest = Color.White, outline = Color(0xFF89998F), outlineVariant = Color(0xFFDCE4DF), surfaceTint = brandGreenReadable)
}
