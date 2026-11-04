# Configuración Firebase / GA4 — Repera

**Última actualización:** 2026-11-04 (dSYM embed: note soft en build-phase + CODESIGNING_FOLDER_PATH).

## Modelo

Métricas de producto (estilo cafesito-app): sin UI de consentimiento in-app, sin IDFA/`AD_ID`. Con ficheros reales, `ReperaAnalytics.configure()` activa la colección. Sin ellos, Analytics es no-op.

## iOS: dSYMs de Firebase Analytics (Archive / App Store Connect)

Firebase se integra por **SPM** (`firebase-ios-sdk` en `project.yml`, producto `FirebaseAnalyticsCore`). Los binarios `FirebaseAnalytics.framework` y `GoogleAppMeasurement.framework` llegan como XCFramework **sin** `.dSYM` públicos. Tras archivar, Xcode Organizer puede mostrar «Upload Symbols Failed» con UUIDs de esos frameworks.

**Fix en el repo (no hace falta ignorar el aviso):**

1. `DEBUG_INFORMATION_FORMAT = dwarf-with-dsym` a nivel de proyecto.
2. Fase de build *Embed framework dSYMs in archive* (`scripts/embed_ios_archive_dsyms.sh`, solo al instalar/archivar) + post-action del scheme `Repera` Archive.
3. El script usa `dsymutil` sobre los Mach-O embebidos en el `.app` y escribe dSYMs con el UUID que exige App Store Connect.

La fase de build puede imprimir `note: … no .app yet (build-phase)` si Xcode aún no ha asentado el `.app`; **no es un fallo**. El post-action de Archive (`--archive ${ARCHIVE_PATH}`) es el pase fiable. Log: `${TMPDIR}/repera_archive_dsyms.log`.

Tras regenerar (`xcodegen generate`) y archivar de nuevo, el aviso de esos frameworks debería desaparecer. Si un archive antiguo ya está en Organizer, puedes repararlo a mano:

```bash
./scripts/embed_ios_archive_dsyms.sh --archive ~/Library/Developer/Xcode/Archives/.../Repera.xcarchive
```

No afecta a Analytics en runtime ni a los dSYM de código propio de Repera. Crashlytics no está enlazado hoy; cuando se añada, el upload de símbolos de la app sigue siendo independiente.

## Qué necesitas de ti (bloqueante para ver datos)

1. Acceso a [Firebase Console](https://console.firebase.google.com/) del proyecto Repera (o crear uno).
2. Acceso a [Google Analytics](https://analytics.google.com/) para vincular GA4.
3. Bundle / application IDs reales:
   - iOS: `com.app.repera`
   - Android mobile: el `applicationId` de `android/mobile` (revisar `build.gradle.kts`)
4. Decisión **dev vs prod**: dos propiedades GA4 / dos apps Firebase recomendado.

No hace falta `service_role` ni service accounts en el repo: solo los JSON/plist **cliente**.

## Pasos (orden)

### A. Firebase + apps

1. Crear o abrir el proyecto Firebase «Repera».
2. Añadir app **iOS** con bundle `com.app.repera` → descargar `GoogleService-Info.plist`.
3. Añadir app **Android** con el `applicationId` móvil → descargar `google-services.json`.
4. Colocar localmente (no inventar valores):
   - `Apps/Repera/Resources/GoogleService-Info.plist`
   - `android/mobile/google-services.json`
5. (Opcional CI) Secretos GitHub:
   - `REPERA_IOS_GOOGLESERVICE_INFO_PLIST`
   - `REPERA_ANDROID_GOOGLE_SERVICES_JSON`
   y escribirlos en esas rutas en el job de release.

### B. GA4

1. En Firebase → Project settings → Integrations → vincular **Google Analytics** (o crear propiedad GA4).
2. Confirmar streams iOS y Android en la propiedad.
3. En GA4 → Admin → Data streams → cada app → **DebugView** disponible.

### C. Validar DebugView (tú en dispositivo)

**iOS**

1. Scheme Repera → Arguments → `-FIRAnalyticsDebugEnabled`
2. Instalar con plist real, abrir app, cambiar de tab / guardar un entreno.
3. GA4 → DebugView: deben aparecer `screen_view`, `workout_completed`, etc.

**Android**

```bash
adb shell setprop debug.firebase.analytics.app <applicationId>
```

Luego abrir la app y mirar DebugView.

### D. BigQuery (operación)

1. GA4 → Admin → Product links → BigQuery Link → export diario.
2. Sustituir `PROJECT.DATASET` en `analytics/bigquery/*.sql` y ejecutar en BigQuery.
3. Plantillas: workouts, sports, funnel Center, plataformas/reloj.

### E. Business web (opcional)

1. Crear measurement ID GA4 web (o stream web).
2. Cargar `gtag` en la consola (`web/console`) con ese ID.
3. El módulo `web/console/src/core/product-analytics.js` ya emite eventos allowlisted si `window.gtag` existe.

### F. Textos legales / tiendas

Revisar App Store Privacy / Play Data Safety: analytics de producto sin ads ID. Textos en `docs/analytics/PRIVACY.md`.

## Qué NO hacer

- No commitear placeholders inventados de plist/json.
- No poner service accounts o `service_role` en apps.
- No afirmar DebugView OK sin haber visto eventos reales.
