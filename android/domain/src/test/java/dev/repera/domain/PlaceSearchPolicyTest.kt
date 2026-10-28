package dev.repera.domain

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PlaceSearchPolicyTest {
    @Test fun `menos de 3 caracteres no busca`() {
        assertFalse(PlaceSearchPolicy.shouldSearch(""))
        assertFalse(PlaceSearchPolicy.shouldSearch("  "))
        assertFalse(PlaceSearchPolicy.shouldSearch(" gy"))
    }
    @Test fun `desde 3 caracteres con texto real busca`() {
        assertTrue(PlaceSearchPolicy.shouldSearch("gym"))
        assertTrue(PlaceSearchPolicy.shouldSearch("  basic fit  "))
    }
}
