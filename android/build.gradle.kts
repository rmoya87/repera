plugins {
    // AGP 9.4.1+ incluye el fix de R8 outliner (b/551348855): VerifyError
    // «register … Undefined but expected Integer» al componer LiveActivityScreen
    // en release minificado. No bajar de 9.4.1.
    id("com.android.application") version "9.4.1" apply false
    id("com.android.library") version "9.4.1" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.3.21" apply false
    id("com.google.gms.google-services") version "4.5.0" apply false
}
