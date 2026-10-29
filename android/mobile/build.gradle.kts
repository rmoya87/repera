plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
}
android {
    namespace = "dev.repera.mobile"
    compileSdk = 37
    defaultConfig {
        applicationId = "com.app.repera"
        minSdk = 30
        targetSdk = 37
        // CI pasa REPERA_VERSION_CODE (minutos desde 2026-01-01 UTC, monotonico)
        // y REPERA_VERSION_NAME (tag exacto o 0.1.0-beta.<run>). Local: 1/0.1.0.
        versionCode = providers.gradleProperty("REPERA_VERSION_CODE").map { it.toInt() }.orElse(1).get()
        versionName = providers.gradleProperty("REPERA_VERSION_NAME").orElse("0.1.0").get()
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        val webClientId = providers.gradleProperty("REPERA_GOOGLE_WEB_CLIENT_ID").orElse("1026054616574-qmugi1nalpar1vv0tdftv97cn6aljoji.apps.googleusercontent.com").get()
        buildConfigField("String", "GOOGLE_WEB_CLIENT_ID", "\"$webClientId\"")
        // OAuth ID and publishable key are public app settings; never use service_role here.
        val publicKey = providers.gradleProperty("REPERA_SUPABASE_PUBLISHABLE_KEY").orElse("sb_publishable_uY9c82Ur7VK4VOo9n2zCEg_PmywmLbA").get()
        buildConfigField("String", "SUPABASE_URL", "\"https://uvzgujlrqohreoucirms.supabase.co\"")
        buildConfigField("String", "SUPABASE_PUBLISHABLE_KEY", "\"$publicKey\"")
        // Android Premium: clave restringida a paquete + firmas; nunca secretos de servidor.
        val mapsKey = providers.gradleProperty("REPERA_GOOGLE_MAPS_API_KEY")
            .orElse(providers.environmentVariable("REPERA_GOOGLE_MAPS_API_KEY")).orElse("").get()
        buildConfigField("String", "GOOGLE_MAPS_API_KEY", "\"$mapsKey\"")
        manifestPlaceholders["reperaGoogleMapsApiKey"] = mapsKey
    }
    // Firma release por clave de subida (upload key); Play vuelve a firmar con
    // la app signing key. Las credenciales llegan por variables de entorno y
    // NUNCA se commitean; sin ellas el build release no firma (falla claro).
    signingConfigs {
        create("release") {
            val ksFile = providers.environmentVariable("REPERA_UPLOAD_KEYSTORE_FILE").orNull
            if (ksFile != null) {
                storeFile = file(ksFile)
                storePassword = providers.environmentVariable("REPERA_UPLOAD_STORE_PASSWORD").get()
                keyAlias = providers.environmentVariable("REPERA_UPLOAD_KEY_ALIAS").get()
                keyPassword = providers.environmentVariable("REPERA_UPLOAD_KEY_PASSWORD").get()
            }
        }
    }
    testOptions {
        unitTests.isIncludeAndroidResources = true
    }

    buildTypes {
        release {
            if (providers.environmentVariable("REPERA_UPLOAD_KEYSTORE_FILE").isPresent) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
    buildFeatures { compose = true; buildConfig = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
dependencies {
    implementation(project(":domain"))
    implementation(platform("androidx.compose:compose-bom:2026.09.00"))
    implementation("androidx.activity:activity-compose:1.13.0")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.animation:animation")
    implementation("androidx.credentials:credentials:1.6.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.6.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.2.1")
    implementation("com.google.android.gms:play-services-auth:22.0.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.11.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.11.0")
    implementation("androidx.navigation:navigation-compose:2.10.2")
    implementation("androidx.work:work-runtime-ktx:2.12.0")
    implementation("com.google.android.gms:play-services-wearable:20.0.1")
    implementation("com.squareup.okhttp3:okhttp:5.5.0")
    implementation("androidx.health.connect:connect-client:1.1.0")
    implementation("com.google.mlkit:text-recognition:16.0.1")
    // Mapa nativo de ruta (paridad HealthWorkoutRouteMap iOS): MapLibre GL
    // (Apache 2.0) + teselas OpenFreeMap (0 €, sin key ni cuenta; TOS
    // openfreemap.org/tos permiten producción con atribución). Decisión y
    // alternativas: android/docs/ROUTE_MAP_OPTIONS.md.
    implementation("org.maplibre.gl:android-sdk:13.7.1")
    implementation("com.google.android.gms:play-services-maps:19.2.0")
    // Google Play Billing: solo detección de compras; la concesión Pro exige
    // verificación backend (ver android/docs/MONETIZATION_PLAY_BILLING.md).
    implementation("com.android.billingclient:billing-ktx:8.0.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20231013")
    // Render headless inspeccionable (NO es validacion de dispositivo):
    // Robolectric con graficos nativos rasteriza Compose en JVM y permite
    // capturar bitmaps revisables de composables portados por fuente.
    testImplementation("org.robolectric:robolectric:4.17")
    testImplementation("androidx.compose.ui:ui-test-junit4")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    // UiDevice: input real para gestos sobre MapLibre (la inyeccion Compose
    // comprime el tiempo y el SDK no traduce el gesto a pan).
    androidTestImplementation("androidx.test.uiautomator:uiautomator:2.3.0")
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
    debugImplementation("androidx.compose.ui:ui-test-manifest")
    androidTestImplementation("androidx.test:runner:1.7.0")
}
