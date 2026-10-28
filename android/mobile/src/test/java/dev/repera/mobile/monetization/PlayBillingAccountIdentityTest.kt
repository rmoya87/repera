package dev.repera.mobile.monetization

import org.junit.Assert.assertEquals
import org.junit.Test

class PlayBillingAccountIdentityTest {
    @Test fun accountBindingMatchesBackendAndNormalizesUuidCase() {
        val expected = "7ac1b8d7010bb6cd3a3e84e7f90136b880bbc899e428ece49333372911ab9052"
        assertEquals(expected, PlayBillingAccountIdentity.fromUserId("00000000-0000-0000-0000-000000000001"))
        assertEquals(PlayBillingAccountIdentity.fromUserId("ABCDEF"), PlayBillingAccountIdentity.fromUserId("abcdef"))
    }
}
