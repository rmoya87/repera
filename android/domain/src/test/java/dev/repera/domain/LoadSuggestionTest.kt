package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class LoadSuggestionTest {

    @Test fun `extrae porcentaje de notas de pizarra`() {
        assertEquals(70.0, LoadSuggestion.percentOfOneRM("#70%")!!.value, 1e-9)
        assertEquals(80.0, LoadSuggestion.percentOfOneRM("3x5 #>80%")!!.value, 1e-9)
        assertTrue(LoadSuggestion.percentOfOneRM("#>80%")!!.isMinimum)
        assertTrue(!LoadSuggestion.percentOfOneRM("#70%")!!.isMinimum)
        assertEquals(65.0, LoadSuggestion.percentOfOneRM("sube a 65% en la última")!!.value, 1e-9)
        assertNull(LoadSuggestion.percentOfOneRM(null))
        assertNull(LoadSuggestion.percentOfOneRM("sin porcentaje"))
        assertNull(LoadSuggestion.percentOfOneRM("#120%"))
        assertNull(LoadSuggestion.percentOfOneRM("#0%"))
    }

    @Test fun `peso desde porcentaje redondeado al incremento`() {
        // 100 kg al 70% = 70 exacto
        assertEquals(70.0, LoadSuggestion.weightKg(100.0, 70.0), 1e-9)
        // 102.5 al 70% = 71.75 → 72.5 con paso 2.5
        assertEquals(72.5, LoadSuggestion.weightKg(102.5, 70.0), 1e-9)
        assertEquals(0.0, LoadSuggestion.weightKg(0.0, 70.0), 1e-9)
    }

    @Test fun `peso desde reps y RIR con Epley inverso`() {
        // 1RM 100, 8 reps @ RIR 2 → RTF 10 → 100/(1+10/30) = 75
        assertEquals(75.0, LoadSuggestion.weightKg(100.0, 8, 2.0), 1e-9)
        // RIR negativo se trata como 0
        assertEquals(LoadSuggestion.weightKg(100.0, 8, 0.0),
            LoadSuggestion.weightKg(100.0, 8, -3.0), 1e-9)
        assertEquals(0.0, LoadSuggestion.weightKg(100.0, 0, 2.0), 1e-9)
    }

    @Test fun `estima desde la ultima serie cuando no hay 1RM`() {
        // última: 60 kg × 10 @ RIR 2 → RTF 12 → e1RM = 60×1.4 = 84;
        // objetivo 8 @ RIR 2 → 84/(1+10/30) = 63
        assertEquals(62.5, LoadSuggestion.weightKgFromLastSet(60.0, 10, 2.0, 8, 2.0), 1e-9)
        // sin RIR registrado asume 2 (como iOS)
        assertEquals(
            LoadSuggestion.weightKgFromLastSet(60.0, 10, 2.0, 8, 2.0),
            LoadSuggestion.weightKgFromLastSet(60.0, 10, null, 8, 2.0),
            1e-9)
        assertEquals(0.0, LoadSuggestion.weightKgFromLastSet(0.0, 10, 2.0, 8, 2.0), 1e-9)
    }
}
