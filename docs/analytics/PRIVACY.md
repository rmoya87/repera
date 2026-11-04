# Privacidad de Analytics — Repera

**Última actualización:** 2026-11-04

## Comportamiento en app

- **Sin UI propia** de consentimiento de Analytics (ni toggle en Ajustes).
- Colección desactivada en Info.plist / manifest hasta que exista configuración Firebase y `configure()` la active.
- Sin IDFA, sin permiso `AD_ID`, sin personalización publicitaria.
- Allowlist de parámetros; valores `^[a-zA-Z0-9_]{1,40}$`.
- Prohibido enviar: salud/HK/HC, GPS/rutas, títulos libres, OCR, emails, IDs de cuenta/centro, pesos/reps personales.

## Qué sí se mide (producto)

IDs de catálogo: deporte (`activity_type`), familia (`activity_family`), tipo de entreno (`workout_type`), formato WOD único si aplica, pantallas, embudo Pro, sección de progreso, plataformas de origen/cierre.

`workout_completed` solo tras persistencia local, **una vez** por sesión (dedup local opaca; el UUID no va a GA4).

## Cambio de cuenta

`ReperaAnalytics.clearLocalState()` borra el registro local de dedup. Llamarlo al cambiar de identidad cuando el flujo de auth lo permita (cola de reloj futura también).

## Eliminación de datos ya transmitidos

Datos ya enviados a GA4/Firebase viven en la propiedad Google del proyecto. Solicitudes de borrado: consola GA4 / proceso de eliminación de datos de usuario de Google Analytics, según la política legal aprobada. La app solo puede dejar de enviar y limpiar colas locales.

## Declaraciones store

App Store Privacy / Google Play Data safety: declarar Analytics como datos de uso de producto / diagnósticos según el texto legal aprobado. Distinguir de Salud y ubicación (esas APIs existen para el producto deportivo; **no** se envían a GA4).
