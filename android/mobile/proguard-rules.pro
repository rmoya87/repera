# Repera Android (release, R8). Las librerías (Compose, Health Connect, MapLibre,
# Play Billing, ML Kit, OkHttp, WorkManager, Glance, Wearable) aportan sus
# consumer rules; los componentes del manifest los mantiene AAPT2.
# El estado persistido (app_state.json, SharedPreferences) usa claves literales
# con org.json del sistema: no hay reflexión sobre nombres de campos.

# Credential Manager resuelve el proveedor de Play Services por reflexión.
-if class androidx.credentials.CredentialManager
-keep class androidx.credentials.playservices.** {
  *;
}

# Trazas de diagnóstico (Log.v/d/i) nunca llegan a release: pueden contener
# identificadores, nombres de ejercicios o datos de salud. Log.w/e se conservan
# y no deben incluir datos personales.
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# Stack traces legibles con build/outputs/mapping/release/mapping.txt
# (subirlo a Play Console junto al AAB).
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
