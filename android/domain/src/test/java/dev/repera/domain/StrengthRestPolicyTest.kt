package dev.repera.domain
import org.junit.Test
import org.junit.Assert.*
class StrengthRestPolicyTest {
    @Test fun specialTechniquesUseAppleRestDurations() {
        assertEquals(45,StrengthRestPolicy.seconds(120,true))
        assertEquals(20,StrengthRestPolicy.seconds(120,kind="dropset"))
        assertEquals(60,StrengthRestPolicy.seconds(120,kind="restpause"))
        assertEquals(45,StrengthRestPolicy.seconds(30,kind="restpause"))
        assertEquals(90,StrengthRestPolicy.seconds(90))
    }
}
