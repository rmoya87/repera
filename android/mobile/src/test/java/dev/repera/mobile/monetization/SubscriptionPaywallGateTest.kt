package dev.repera.mobile.monetization

import dev.repera.domain.monetization.CommercialSnapshot
import dev.repera.domain.monetization.PaywallContext
import dev.repera.domain.monetization.SubscriptionStatus
import java.nio.file.Files
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Una pulsación 3D no debe vender otra vez a quien ya tiene Pro. */
class SubscriptionPaywallGateTest {
    private class FakeProvider(private val states: List<SubscriptionStatus>) : EntitlementProvider {
        override val isConfigured = true
        private var refreshCount = 0

        override suspend fun refresh(): CommercialSnapshot {
            val status = states[minOf(refreshCount, states.lastIndex)]
            refreshCount++
            return CommercialSnapshot(status = status, isConfigured = true)
        }

        override suspend fun purchase(productID: String): CommercialSnapshot =
            error("No compra en estas pruebas")

        override suspend fun restore(): CommercialSnapshot =
            error("No restaura en estas pruebas")

        override suspend fun offerings(): CommercialOfferings = CommercialOfferings.empty
    }

    private fun manager(provider: EntitlementProvider): SubscriptionManager {
        val folder = Files.createTempDirectory("repera-paywall-gate").toFile()
        folder.deleteOnExit()
        return SubscriptionManager(provider = provider, freeUsage = FreeUsageStore.forAccount(folder))
    }

    @Test fun activeProCannotOpenGenericPaywall() = runBlocking {
        for (status in listOf(SubscriptionStatus.TRIAL, SubscriptionStatus.PRO_ANNUAL,
            SubscriptionStatus.PRO_MONTHLY, SubscriptionStatus.GRACE_PERIOD)) {
            val subscriptions = manager(FakeProvider(listOf(status)))
            subscriptions.start()
            assertTrue(subscriptions.policy.canUse3DNavigation)
            subscriptions.presentPaywall(PaywallContext.GENERIC)
            assertFalse(subscriptions.paywall.isPresented)
        }
    }

    @Test fun businessAccessCannotOpenGenericPaywall() = runBlocking {
        val subscriptions = manager(FakeProvider(listOf(SubscriptionStatus.FREE)))
        subscriptions.start()
        subscriptions.updateBusinessSponsoredAccess(true)
        subscriptions.presentPaywall(PaywallContext.GENERIC)
        assertFalse(subscriptions.paywall.isPresented)
    }

    @Test fun premiumAccessRecoveredAfterTapNeverOpensPricing() = runBlocking {
        val subscriptions = manager(
            FakeProvider(listOf(SubscriptionStatus.FREE, SubscriptionStatus.PRO_ANNUAL))
        )
        subscriptions.start()
        assertFalse(subscriptions.policy.canUse3DNavigation)
        subscriptions.refreshEntitlementsForFeatureAction()
        assertTrue(subscriptions.policy.canUse3DNavigation)
        subscriptions.presentPaywall(PaywallContext.GENERIC)
        assertFalse(subscriptions.paywall.isPresented)
    }

    @Test fun verifiedFreeCanOpenPaywall() = runBlocking {
        val subscriptions = manager(FakeProvider(listOf(SubscriptionStatus.FREE)))
        subscriptions.start()
        subscriptions.refreshEntitlementsForFeatureAction()
        subscriptions.presentPaywall(PaywallContext.GENERIC)
        assertTrue(subscriptions.paywall.isPresented)
    }
}
