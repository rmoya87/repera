package dev.repera.mobile

import androidx.compose.ui.graphics.Color
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

/** El esquema Repera no debe caer en el púrpura M3 por defecto (#6750A4). */
class ReperaColorSchemeTest {
    private val materialPurple = Color(0xFF6750A4)

    @Test
    fun lightPrimaryIsReadableBrandGreen() {
        val scheme = reperaColorScheme(dark = false)
        assertEquals(brandGreenReadable, scheme.primary)
        assertEquals(Color.White, scheme.onPrimary)
        assertEquals(brandGreenReadable, scheme.surfaceTint)
        assertNotEquals(materialPurple, scheme.primary)
        assertNotEquals(materialPurple, scheme.secondary)
        assertNotEquals(materialPurple, scheme.tertiary)
    }

    @Test
    fun darkPrimaryIsBrandGreen() {
        val scheme = reperaColorScheme(dark = true)
        assertEquals(brandGreen, scheme.primary)
        assertEquals(Color.Black, scheme.onPrimary)
        assertEquals(brandGreen, scheme.surfaceTint)
        assertNotEquals(materialPurple, scheme.primary)
    }
}
