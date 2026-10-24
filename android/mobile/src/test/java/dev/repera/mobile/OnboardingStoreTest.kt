package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Paridad con OnboardingStore.swift: mismas claves, misma migración v1→v2. */
class OnboardingStoreTest {

    private class FakePrefs : OnboardingPrefs {
        val map = mutableMapOf<String, Any?>()
        override fun getString(key: String): String? = map[key] as? String
        override fun getInt(key: String, default: Int): Int = map[key] as? Int ?: default
        override fun getBool(key: String, default: Boolean): Boolean = map[key] as? Boolean ?: default
        override fun putString(key: String, value: String) { map[key] = value }
        override fun putInt(key: String, value: Int) { map[key] = value }
        override fun putBool(key: String, value: Boolean) { map[key] = value }
    }

    @Test
    fun `primer arranque empieza en signIn y sella flowVersion 2`() {
        val prefs = FakePrefs()
        val store = OnboardingStore.create(prefs)
        assertEquals(OnboardingStep.SignIn, store.step)
        assertFalse(store.priceAlreadySeen)
        assertEquals(2, prefs.getInt("repera.onboarding.flowVersion", 0))
    }

    @Test
    fun `migracion v1 en permissions ya vio precios y no los repite`() {
        val prefs = FakePrefs()
        prefs.putString("repera.onboarding.step", "permissions")
        val store = OnboardingStore.create(prefs)
        assertTrue(store.priceAlreadySeen)
        assertEquals(OnboardingStep.Permissions, store.step)
        store.finishPermissions()
        assertEquals(OnboardingStep.Done, store.step)
    }

    @Test
    fun `migracion v1 en choosePlan NO habia visto precios y pasa a permissions`() {
        // v1: signIn → precio → permisos. Quien estaba EN choosePlan aún no
        // había completado precios: priceAlreadySeen=false (solo permissions
        // y done cuentan como vistos, port 1:1 de iOS).
        val prefs = FakePrefs()
        prefs.putString("repera.onboarding.step", "choosePlan")
        val store = OnboardingStore.create(prefs)
        assertFalse(store.priceAlreadySeen)
        assertEquals(OnboardingStep.Permissions, store.step)
        store.finishPermissions()
        assertEquals(OnboardingStep.ChoosePlan, store.step)
    }

    @Test
    fun `flujo v2 nuevo usuario signIn permisos precio done`() {
        val store = OnboardingStore.create(FakePrefs())
        store.reconcile(isSignedIn = true)
        assertEquals(OnboardingStep.Permissions, store.step)
        store.finishPermissions()
        assertEquals(OnboardingStep.ChoosePlan, store.step)
        store.finishPrices()
        assertEquals(OnboardingStep.Done, store.step)
        assertTrue(store.isComplete)
    }

    @Test
    fun `reconcile sin sesion no toca el paso`() {
        val store = OnboardingStore.create(FakePrefs())
        store.reconcile(isSignedIn = false)
        assertEquals(OnboardingStep.SignIn, store.step)
    }

    @Test
    fun `reconcile con precios vistos y paso a medias cierra el wizard`() {
        val prefs = FakePrefs()
        val store = OnboardingStore.create(prefs)
        store.reconcile(isSignedIn = true)          // → permissions
        store.finishPrices()                        // marca precios vistos y done
        store.advance(OnboardingStep.Permissions)   // simula estado a medias
        store.reconcile(isSignedIn = true)
        assertEquals(OnboardingStep.Done, store.step)
    }

    @Test
    fun `resetToSignIn conserva precios vistos`() {
        val store = OnboardingStore.create(FakePrefs())
        store.finishPrices()
        store.resetToSignIn()
        assertEquals(OnboardingStep.SignIn, store.step)
        assertTrue(store.priceAlreadySeen)
        store.reconcile(isSignedIn = true)
        assertEquals(OnboardingStep.Done, store.step)
    }

    @Test
    fun `estado persiste entre instancias`() {
        val prefs = FakePrefs()
        OnboardingStore.create(prefs).finishPermissions()
        val reopened = OnboardingStore.create(prefs)
        assertEquals(OnboardingStep.ChoosePlan, reopened.step)
    }
}
