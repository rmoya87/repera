package dev.repera.mobile.monetization

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class SubscriptionOfferCopyTest {
    @Test
    fun emptyPhases_noOffer() {
        val summary = SubscriptionOfferCopy.summarize(emptyList())
        assertNull(summary.text)
        assertFalse(summary.hasFreeTrial)
    }

    @Test
    fun freeTrialTwoWeeks() {
        val summary = SubscriptionOfferCopy.summarize(
            listOf(
                SubscriptionOfferCopy.Phase(
                    priceAmountMicros = 0L,
                    formattedPrice = "Gratis",
                    billingPeriod = "P2W"
                )
            )
        )
        assertEquals("14 días gratis", summary.text)
        assertTrue(summary.hasFreeTrial)
    }

    @Test
    fun discountedIntro_showsOfferPrice() {
        val summary = SubscriptionOfferCopy.summarize(
            listOf(
                SubscriptionOfferCopy.Phase(
                    priceAmountMicros = 2_990_000L,
                    formattedPrice = "2,99 €",
                    billingPeriod = "P1M"
                )
            )
        )
        assertEquals("Oferta: 2,99 €", summary.text)
        assertFalse(summary.hasFreeTrial)
    }

    @Test
    fun trialPlusPaidIntro() {
        val summary = SubscriptionOfferCopy.summarize(
            listOf(
                SubscriptionOfferCopy.Phase(0L, "Gratis", "P1W"),
                SubscriptionOfferCopy.Phase(2_990_000L, "2,99 €", "P1M")
            )
        )
        assertEquals("1 semana gratis + oferta", summary.text)
        assertTrue(summary.hasFreeTrial)
    }
}
