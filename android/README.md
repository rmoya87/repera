# Repera nativo Android / Wear OS

Proyecto Android Studio/Gradle en `android/`. **En desarrollo, no versión de producción**.

- Teléfono: Kotlin y Jetpack Compose Material 3.
- Reloj: Kotlin y Compose for Wear OS Material 3.
- Dominio: fuentes Swift portadas por contrato, pruebas en `domain/src/test`.
- Identidad: Credential Manager + Google.
- Archivos personales: `appDataFolder` privada de Google Drive. Scope mínimo separado.
- Integración reloj: Google Play Services Wearable Data Layer.

## Configuración OAuth necesaria

Habilita Google Auth Platform y Drive API en el proyecto Google Cloud de Repera;
configura consent screen, SHA-256 debug/release y clientes Android + Web.
No pongas secrets en el repositorio. En `~/.gradle/gradle.properties`:

```
REPERA_GOOGLE_WEB_CLIENT_ID=<OAuth Web client ID>
```

La ID token que entrega Credential Manager necesita **verificación del servidor**
antes de autorizar datos de Supabase. El ID Token no es un access token de Drive.

## Compilar y comprobar

Con JDK 17, Android SDK 37 y Gradle 9.6:

```shell
cd android
gradle :domain:testDebugUnitTest :mobile:assembleDebug :wear:assembleDebug
```

No se ha ejecutado esa compilación en este entorno. Véase
`docs/STATUS_AND_PARITY.md` para matriz de paridad y limitaciones.
