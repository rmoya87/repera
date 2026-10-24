plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
}
android {
    namespace = "dev.repera.wear"
    compileSdk = 37
    defaultConfig {
        applicationId = "com.app.repera"
        minSdk = 30
        targetSdk = 37
        versionCode = 1
        versionName = "0.1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
    buildFeatures { compose = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
dependencies {
    implementation(project(":domain"))
    implementation(platform("androidx.compose:compose-bom:2026.09.00"))
    implementation("androidx.activity:activity-compose:1.13.0")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.wear.compose:compose-material3:1.7.1")
    implementation("androidx.wear.compose:compose-foundation:1.7.1")
    implementation("com.google.android.gms:play-services-wearable:20.0.1")
    implementation("androidx.health:health-services-client:1.1.0")
    implementation("androidx.wear.watchface:watchface-complications-data-source-ktx:1.2.1")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    androidTestImplementation("androidx.test:runner:1.7.0")
    // Declara la ComponentActivity que lanza createComposeRule en los tests
    // visuales (sin ella: "Unable to resolve activity" en el APK de test).
    debugImplementation("androidx.compose.ui:ui-test-manifest")
    androidTestImplementation(platform("androidx.compose:compose-bom:2026.09.00"))
    // Espresso 3.5.0 (transitivo de ui-test-junit4) usa reflexión sobre
    // InputManager.getInstance, API oculta eliminada en Android 17 (API 37):
    // rompe cualquier test Compose en imagen API 37.2 aunque la app funcione.
    // No usamos Espresso directamente; al excluirlo, el EspressoLink de
    // Compose se desactiva solo y los tests corren en API 30-37.2.
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    // Espresso 3.5.0 (transitivo) resuelve por reflexión
    // InputManager.getInstance, API oculta eliminada en Android 17 (API 37):
    // cualquier test Compose fallaba en la imagen 37.2. No se puede excluir
    // (Compose lo referencia: NoClassDefFoundError). 3.7.0 difiere la
    // resolución a la inyección de eventos, que estos tests no ejercitan
    // (gestos por el InputDispatcher de Compose, no por Espresso).
    androidTestImplementation("androidx.test.espresso:espresso-core:3.7.0")
}
