package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Test

/** Placeholder copy for Inicio Salud: permiso vs vacío vs desconocido. */
class HomeHealthPlaceholderTest {
    private fun placeholder(access: HealthAccessState): String = when (access) {
        HealthAccessState.NOT_GRANTED -> "Conecta Salud"
        HealthAccessState.UNAVAILABLE -> "Salud no disponible"
        HealthAccessState.GRANTED -> "Sin datos"
        HealthAccessState.UNKNOWN -> "—"
    }

    @Test
    fun distinguishesPermissionFromEmptyData() {
        assertEquals("Conecta Salud", placeholder(HealthAccessState.NOT_GRANTED))
        assertEquals("Sin datos", placeholder(HealthAccessState.GRANTED))
        assertEquals("Salud no disponible", placeholder(HealthAccessState.UNAVAILABLE))
        assertEquals("—", placeholder(HealthAccessState.UNKNOWN))
    }
}
