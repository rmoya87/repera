# Configuración Firebase / GA4 — Repera

**Última actualización:** 2026-11-04

## Modelo

Misma idea que cafesito-app móvil: **métricas de producto**, sin UI de consentimiento en la app, sin IDFA/`AD_ID`. Si el proyecto Firebase está configurado, la colección se activa en `ReperaAnalytics.configure()`. Sin ficheros reales, Analytics es no-op y el entrenamiento no se ve afectado.

## Ficheros reales (no inventar)

| Plataforma | Fichero | Ubicación en repo |
| --- | --- | --- |
| iOS | `GoogleService-Info.plist` | `Apps/Repera/Resources/GoogleService-Info.plist` (XcodeGen ya lo incluye si existe) |
| Android | `google-services.json` | `android/mobile/google-services.json` (el plugin solo se aplica si el fichero existe) |

Obtenerlos desde la consola Firebase del proyecto Repera (apps iOS `com.app.repera` y Android equivalentes). **No** commitear secretos de service account; estos JSON/plist de cliente son los de la app, no `service_role`.

## CI / secretos recomendados

1. Guardar el contenido como secretos de GitHub Actions, p. ej. `REPERA_IOS_GOOGLESERVICE_INFO_PLIST` y `REPERA_ANDROID_GOOGLE_SERVICES_JSON`.
2. En el job de build release/internal, escribirlos en las rutas anteriores antes de `xcodegen` / Gradle.
3. Builds locales de desarrollo pueden omitirlos: la app compila y corre sin Analytics.

## Entornos

Usar propiedades GA4 / proyectos Firebase distintos para **dev** y **producción** para no contaminar informes reales. El código no distingue entornos: la separación es por fichero de configuración inyectado.

## DebugView

Con el plist/json reales:

- iOS: argumento de scheme `-FIRAnalyticsDebugEnabled`.
- Android: `adb shell setprop debug.firebase.analytics.app <package>`.

No afirmar validación DebugView sin haber observado eventos reales.

## BigQuery / dashboards

Plantillas SQL: `analytics/bigquery/` (cuando existan). Activación de exportación GA4→BigQuery en consola Firebase; no automatizada en esta fase.
