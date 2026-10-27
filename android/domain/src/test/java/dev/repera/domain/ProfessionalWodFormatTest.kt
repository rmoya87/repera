package dev.repera.domain
import org.junit.Assert.*
import org.junit.Test
class ProfessionalWodFormatTest {
    @Test fun appleAliasesNormalizeCaseAndUnderscores() {
        for((raw,expected) in mapOf("RFT" to "forTime","FOR_TIME" to "forTime","Every" to "emom",
            "E_M_O_M" to "emom","AMRAP" to "amrap","TABATA" to "tabata","CHIPPER" to "chipper",
            "CIRCUIT" to "circuit","LADDER" to "ladder","STRENGTH" to "strength"))
            assertEquals(expected,ProfessionalWodFormat.normalize(raw))
    }
    @Test fun unlistedFormatsRetainExactRawValueForEnumParsing() {
        assertEquals("buyInCashOut",ProfessionalWodFormat.normalize("buyInCashOut"))
        assertEquals("unsupported",ProfessionalWodFormat.normalize("unsupported"))
    }
}
