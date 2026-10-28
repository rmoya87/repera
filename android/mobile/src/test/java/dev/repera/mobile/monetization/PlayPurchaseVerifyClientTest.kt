package dev.repera.mobile.monetization

import dev.repera.domain.monetization.SubscriptionStatus
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PlayPurchaseVerifyClientTest {

    @Test
    fun activeMonthlyMapsToVerifiedPro() {
        val snap = PlayPurchaseVerifyClient.mapSnapshot(
            JSONObject()
                .put("status", "proMonthly")
                .put("expiryEpochMs", 1_800_000_000_000L)
                .put("productId", CommercialConfig.MONTHLY_PRODUCT_ID),
            now = 1_700_000_000_000L
        )!!
        assertEquals(SubscriptionStatus.PRO_MONTHLY, snap.status)
        assertTrue(snap.grantsProAccess)
        assertEquals(CommercialConfig.MONTHLY_PRODUCT_ID, snap.activeProductID)
        assertEquals(1_800_000_000_000L, snap.expirationDate)
        assertEquals(SubscriptionStatus.PRO_MONTHLY, snap.lastVerifiedProStatus)
    }

    @Test
    fun expiredDoesNotGrantPro() {
        val snap = PlayPurchaseVerifyClient.mapSnapshot(
            JSONObject().put("status", "expired").put("productId", CommercialConfig.ANNUAL_PRODUCT_ID)
        )!!
        assertEquals(SubscriptionStatus.EXPIRED, snap.status)
        assertFalse(snap.grantsProAccess)
        assertNull(snap.lastVerifiedProStatus)
    }

    @Test
    fun trialAndGraceGrantPro() {
        assertTrue(
            PlayPurchaseVerifyClient.mapSnapshot(JSONObject().put("status", "trial"))!!.grantsProAccess
        )
        assertTrue(
            PlayPurchaseVerifyClient.mapSnapshot(JSONObject().put("status", "gracePeriod"))!!.grantsProAccess
        )
    }

    @Test
    fun missingStatusReturnsNull() {
        assertNull(PlayPurchaseVerifyClient.mapSnapshot(JSONObject().put("productId", "x")))
    }

    @Test
    fun revokedNeverGrantsPro() {
        val snap = PlayPurchaseVerifyClient.mapSnapshot(JSONObject().put("status", "revoked"))!!
        assertEquals(SubscriptionStatus.REVOKED, snap.status)
        assertFalse(snap.grantsProAccess)
    }
}
