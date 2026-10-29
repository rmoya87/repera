package dev.repera.domain.monetization

import dev.repera.domain.ProgressTimeRange
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FeatureAccessPolicyTest {

    @Test
    fun `la navegacion 3D requiere Pro efectivo`() {
        assertFalse(FeatureAccessPolicy().canUse3DNavigation)
        for (status in listOf(SubscriptionStatus.EXPIRED, SubscriptionStatus.REVOKED, SubscriptionStatus.UNKNOWN)) {
            assertFalse(FeatureAccessPolicy(snapshot = CommercialSnapshot(status = status)).canUse3DNavigation)
        }
        for (status in listOf(SubscriptionStatus.TRIAL, SubscriptionStatus.PRO_MONTHLY,
            SubscriptionStatus.PRO_ANNUAL, SubscriptionStatus.GRACE_PERIOD)) {
            assertTrue(FeatureAccessPolicy(snapshot = CommercialSnapshot(status = status)).canUse3DNavigation)
        }
        assertTrue(FeatureAccessPolicy(businessSponsoredAccess = true).canUse3DNavigation)
    }

    @Test
    fun `gratis puede registrar sin límites de sesión`() {
        val policy = FeatureAccessPolicy(libraryRoutineCount = 10, customExerciseCount = 50)
        assertFalse(policy.canAccess(ReperaFeature.EXERCISE_EVOLUTION))
        assertFalse(policy.isPro)
    }

    @Test
    fun `pro accede a premium`() {
        val snap = CommercialSnapshot(
            status = SubscriptionStatus.PRO_ANNUAL,
            lastVerifiedProStatus = SubscriptionStatus.PRO_ANNUAL,
            isConfigured = true
        )
        val policy = FeatureAccessPolicy(snapshot = snap, libraryRoutineCount = 100, customExerciseCount = 100)
        for (feature in ReperaFeature.entries) {
            assertTrue("Pro debería acceder a $feature", policy.canAccess(feature))
        }
    }

    @Test
    fun `vínculo con centro o entrenador otorga acceso completo`() {
        val policy = FeatureAccessPolicy(
            libraryRoutineCount = 100, customExerciseCount = 100,
            businessSponsoredAccess = true
        )
        assertTrue(policy.isPro)
        for (feature in ReperaFeature.entries) {
            assertTrue("Patrocinio Business debería acceder a $feature", policy.canAccess(feature))
        }
    }

    @Test
    fun `gratis 3 rutinas OK y cuarta bloqueada, edición permitida`() {
        var policy = FeatureAccessPolicy(libraryRoutineCount = 2)
        assertTrue(policy.canCreateLibraryRoutine(isNew = true).allowed)
        policy = policy.copy(libraryRoutineCount = 3)
        assertFalse(policy.canCreateLibraryRoutine(isNew = true).allowed)
        assertTrue(policy.canCreateLibraryRoutine(isNew = false).allowed)
        assertEquals(PaywallContext.ROUTINES_LIMIT, policy.canCreateLibraryRoutine(isNew = true).paywallContext)
    }

    @Test
    fun `gratis 5 custom OK y sexto bloqueado`() {
        var policy = FeatureAccessPolicy(customExerciseCount = 4)
        assertTrue(policy.canCreateCustomExercise(isNew = true).allowed)
        policy = policy.copy(customExerciseCount = 5)
        assertFalse(policy.canCreateCustomExercise(isNew = true).allowed)
        assertTrue(policy.canCreateCustomExercise(isNew = false).allowed)
    }

    @Test
    fun `gratis 3 favoritos OK y cuarto bloqueado`() {
        var policy = FeatureAccessPolicy(favoriteCount = 2)
        assertTrue(policy.canCreateFavorite(isNew = true).allowed)
        policy = policy.copy(favoriteCount = 3)
        assertFalse(policy.canCreateFavorite(isNew = true).allowed)
        assertTrue(policy.canCreateFavorite(isNew = false).allowed)
        assertEquals(PaywallContext.ROUTINES_LIMIT, policy.canCreateFavorite(isNew = true).paywallContext)
        val pro = FeatureAccessPolicy(
            snapshot = CommercialSnapshot(status = SubscriptionStatus.PRO_MONTHLY),
            favoriteCount = 99
        )
        assertTrue(pro.canCreateFavorite(isNew = true).allowed)
    }

    @Test
    fun `periodo Progreso solo semana en Gratis`() {
        val free = FeatureAccessPolicy()
        assertTrue(free.canSelectProgressRange(ProgressTimeRange.WEEK).allowed)
        assertFalse(free.canSelectProgressRange(ProgressTimeRange.TODAY).allowed)
        assertFalse(free.canSelectProgressRange(ProgressTimeRange.MONTH).allowed)
        assertFalse(free.canSelectProgressRange(ProgressTimeRange.DAYS_90).allowed)

        val pro = FeatureAccessPolicy(snapshot = CommercialSnapshot(status = SubscriptionStatus.TRIAL))
        assertTrue(pro.canSelectProgressRange(ProgressTimeRange.DAYS_360).allowed)
    }

    @Test
    fun `cambio de estado actualiza permisos`() {
        var policy = FeatureAccessPolicy()
        assertFalse(policy.canAccess(ReperaFeature.ADVANCED_MUSCLE_ANALYSIS))
        policy = policy.copy(snapshot = policy.snapshot.copy(status = SubscriptionStatus.PRO_MONTHLY))
        assertTrue(policy.canAccess(ReperaFeature.ADVANCED_MUSCLE_ANALYSIS))
        policy = policy.copy(snapshot = policy.snapshot.copy(status = SubscriptionStatus.EXPIRED))
        assertFalse(policy.canAccess(ReperaFeature.ADVANCED_MUSCLE_ANALYSIS))
    }

    @Test
    fun `offline Pro cacheado con caducidad futura sigue Pro`() {
        val now = System.currentTimeMillis()
        val snap = CommercialSnapshot(
            status = SubscriptionStatus.UNKNOWN,
            lastVerifiedProStatus = SubscriptionStatus.PRO_ANNUAL,
            lastVerifiedProAt = now,
            expirationDate = now + 86_400_000,
            lastRefreshFailedOffline = true
        )
        assertTrue(snap.grantsProAccess)
        assertTrue(FeatureAccessPolicy(snapshot = snap).canAccess(ReperaFeature.EXERCISE_EVOLUTION))
    }

    @Test
    fun `offline sin caché Pro no desbloquea`() {
        val snap = CommercialSnapshot(status = SubscriptionStatus.UNKNOWN, lastRefreshFailedOffline = true)
        assertFalse(snap.grantsProAccess)
    }

    @Test
    fun `caducado confirmado no da Pro`() {
        val snap = CommercialSnapshot(
            status = SubscriptionStatus.EXPIRED,
            lastVerifiedProStatus = SubscriptionStatus.PRO_MONTHLY,
            expirationDate = System.currentTimeMillis() - 100
        )
        assertFalse(snap.grantsProAccess)
    }

    @Test
    fun `revocado no da Pro`() {
        val snap = CommercialSnapshot(status = SubscriptionStatus.REVOKED)
        assertFalse(snap.grantsProAccess)
    }
}
