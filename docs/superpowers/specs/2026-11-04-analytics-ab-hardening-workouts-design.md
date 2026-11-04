# Analytics A+B — Hardening + entrenamientos confirmados

**Fecha:** 2026-11-04 · **Estado:** aprobado para implementación

## Objetivo

Completar la base GA4 de Repera al estilo **cafesito-app móvil**: métricas de producto sin UI de consentimiento, y emitir `workout_completed` (y ciclo cercano) **solo tras persistencia duradera**, una vez por sesión lógica.

## Consentimiento / activación

- Sin toggle ni copy de Analytics en Ajustes.
- Sin ATT como puerta (no es publicidad; sin IDFA/`AD_ID`).
- Si existe configuración Firebase real → `setAnalyticsCollectionEnabled(true)` en `configure()`.
- Sin plist/json → no-op; la app deportiva no falla.
- Privacidad de payload: allowlist; sin salud, GPS, PII ni textos libres.
- App Store / Play / RGPD: revisión legal externa (doc de pendientes).

## Qué se recoge en entrenamientos

Sí (IDs de catálogo): `activity_type`, `activity_family`, `workout_type`, `wod_format` (si hay un único formato de catálogo), plataformas, `feature_area`, `result`, `access_tier` si se conoce.

No: título del entreno, notas, pesos, reps, coordenadas, kcal, FC, UUIDs en GA4.

## Deduplicación

Registro local (UserDefaults / SharedPreferences) con clave opaca del UUID de sesión. `trackOnce` para `workout_completed`. Edición e import CSV no reemiten completed.

## Ganchos

| Evento | iOS | Android |
| --- | --- | --- |
| workout_completed | endActiveSession(save), logQuickSets, 1ª llegada Watch, 1º saveWorkout finished | finishInPlace, saveLiveActivity |
| workout_discarded | endActiveSession(!save) | discardActiveSession |
| workout_deleted | deleteWorkout | deleteWorkout |
| workout_edited | saveWorkout de sesión ya archivada | edición finished |

## Fuera de esta entrega

Cola Watch/Wear, Center, BigQuery operativo, DebugView con credenciales reales.
