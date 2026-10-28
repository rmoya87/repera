package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Espejo de ReperaNumberFormatTests (Apple b2868533). */
class ReperaNumberFormatTest {

    @Test fun spanishDecimalsAndGrouping() {
        assertEquals("1.234,56", ReperaNumberFormat.decimal(1234.56))
        assertEquals("1.234.567,8", ReperaNumberFormat.decimal(1234567.8))
        assertEquals("1.000", ReperaNumberFormat.decimal(1000.0))
        assertEquals("1,2", ReperaNumberFormat.decimal(1.2))
        assertEquals("1,23", ReperaNumberFormat.decimal(1.23456))
        assertEquals("-1.234,5", ReperaNumberFormat.decimal(-1234.5))
        assertEquals("42", ReperaNumberFormat.decimal(42.0))
    }

    @Test fun decimalLimitAndIntegers() {
        assertEquals("12,35", ReperaNumberFormat.decimal(12.346, maximumFractionDigits = 6))
        assertEquals("43", ReperaNumberFormat.decimal(42.9, maximumFractionDigits = 0))
        assertEquals("5,0", ReperaNumberFormat.decimal(5.0, minimumFractionDigits = 1))
        assertEquals("1.234", ReperaNumberFormat.integer(1234))
        assertEquals("-1.234.567", ReperaNumberFormat.integer(-1234567))
    }

    @Test fun spanishAndLegacyInput() {
        assertEquals(1234.56, ReperaNumberFormat.parse("1.234,56")!!, 0.0)
        assertEquals(1234.5, ReperaNumberFormat.parse(" 1.234,5 ")!!, 0.0)
        assertEquals(1234.0, ReperaNumberFormat.parse("1.234")!!, 0.0)
        assertEquals(1234.56, ReperaNumberFormat.parse("1234.56")!!, 0.0)
        assertEquals(-12.5, ReperaNumberFormat.parse("-12,5")!!, 0.0)
        assertEquals(0.25, ReperaNumberFormat.parse("0,25")!!, 0.0)
        assertNull(ReperaNumberFormat.parse(""))
        assertNull(ReperaNumberFormat.parse("1,2,3"))
        assertNull(ReperaNumberFormat.parse("infinito"))
    }

    @Test fun formattingDoesNotChangeDataPrecision() {
        val recorded = 1234.56789
        assertEquals("1.234,57", ReperaNumberFormat.decimal(recorded))
        assertEquals(1234.56789, recorded, 0.0) // solo cambia la presentación
    }

    @Test fun keypadTypedDotInsertsComma() {
        assertEquals("24,", ReperaNumberFormat.keypadDecimal("24", "24."))
        assertEquals("24,5", ReperaNumberFormat.keypadDecimal("24,", "24,5"))
    }

    @Test fun keypadCapsTwoDecimalsAndSingleComma() {
        assertEquals("24,56", ReperaNumberFormat.keypadDecimal("24,56", "24,567"))
        assertEquals("24,5", ReperaNumberFormat.keypadDecimal("24,5", "24,5,"))
        assertEquals("24,5", ReperaNumberFormat.keypadDecimal("24,5", "24,5."))
    }

    @Test fun keypadPasteNormalizesBothFormats() {
        assertEquals("1.234,56", ReperaNumberFormat.keypadDecimal("", "1234.56"))
        assertEquals("1.234,56", ReperaNumberFormat.keypadDecimal("", "1.234,56"))
        assertEquals("1,5", ReperaNumberFormat.keypadDecimal("", "1.5"))
    }

    @Test fun keypadRejectsNonNumericAndKeepsThousands() {
        assertEquals("24", ReperaNumberFormat.keypadDecimal("24", "24a"))
        assertEquals("24", ReperaNumberFormat.keypadDecimal("24", "-24"))
        // Los puntos de millares ya formateados se conservan al editar.
        assertEquals("1.234,56", ReperaNumberFormat.keypadDecimal("1.234,5", "1.234,56"))
        assertEquals("", ReperaNumberFormat.keypadDecimal("24", ""))
    }

    @Test fun keypadIntegerDigitsOnly() {
        assertEquals("123", ReperaNumberFormat.keypadInteger("12", "123"))
        assertEquals("12", ReperaNumberFormat.keypadInteger("12", "12a"))
        assertEquals("12", ReperaNumberFormat.keypadInteger("12", "12,5"))
        assertEquals("", ReperaNumberFormat.keypadInteger("12", ""))
    }
}
