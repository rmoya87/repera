package dev.repera.mobile.monetization

import androidx.compose.runtime.staticCompositionLocalOf

/**
 * Acceso ambiente al gestor de suscripciones (equivalente al
 * @Environment(SubscriptionManager.self) de iOS). Lo provee MainActivity.
 */
val LocalSubscriptions = staticCompositionLocalOf<SubscriptionManager?> { null }
