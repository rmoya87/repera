plugins {
    // AGP 9.5.1+: R8 más reciente. AGP 9.4.1 mitigó b/551348855 (Comenzar),
    // pero Play 2026.11.9 (9.4.1) aún VerifyError al abrir «Añadir entreno»
    // (clase ofuscada Compose). Mantener ≥ 9.5.1 + keep Compose en proguard.
    id("com.android.application") version "9.5.1" apply false
    id("com.android.library") version "9.5.1" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.3.21" apply false
    id("com.google.gms.google-services") version "4.5.0" apply false
}
