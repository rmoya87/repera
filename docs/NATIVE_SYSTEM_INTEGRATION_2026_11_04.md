# Integraciones nativas iOS / Android / Watch / Wear — 4 nov 2026

Última actualización: 2026-11-04.

Fase 5 (Share Extension, MediaSession, Focus, EventKit, board Control Widget, Wear tile, Watch Smart Stack): ver `NATIVE_OS_SURFACES_PHASE_5_2026_11_04.md`.

## Alcance / estado de este PR

Implementación incremental sobre la PR #221. Distinguir **implementado / compilado / CI / hardware**.

### Implementado aquí

- **Fase 1, entrada segura:** accesos externos de navegación, comprobación de hidratación e identidad; guardas de propiedad GPS idempotentes en Android; widget Glance tras escritura atómica sin romper login/guardado.
- **Fase 2, iOS:** App Intents/Siri Shortcuts; WidgetKit; Control Widgets (Centro de Control / Action Button iPhone); Live Activity / Dynamic Island con botones `LiveActivityIntent` de pausa/reanudación/abrir sesión que **solo encolan** comandos al proceso de la app (nunca confirman series ni escriben HealthKit desde la extensión).
- **Fase 2, Android:** launcher shortcuts, Quick Settings Tiles, Glance widget; **Google Assistant App Actions** (`OPEN_APP_FEATURE` / `GET_THING`) enlazadas a deep links `repera://…` sin sensores.
- **Fase 2, Apple Watch:** doble toque condicionado en el avance de sesión (`handGestureShortcut`); Action Button del Ultra en iPhone vía Control Widgets (validación en hardware pendiente).
- **Fase 3:** Spotlight solo catálogo público; **AppSearch Android opt-in** (consentimiento en Salud conectada, solo ejercicios públicos, borrado al cerrar sesión); dictado Watch/Wear con confirmación previa; recordatorios locales −60 min de reservas `booked`; sugerencias de lugar editables al revisar (sin inventar GPS).
- **Fase 4:** GPX iOS/Android solo puntos reales; WorkoutKit con `workoutPreview` + `WorkoutScheduler` en iPhone (API `openInWorkoutApp` no disponible en iOS); objetivos tiempo/distancia e **intervalos estructurados** `CustomWorkout` con aviso de zona FC cuando el SDK lo admite; sin grabación paralela Repera+Entreno.

### Backend de recordatorios (remoto)

- Esquema: `notification_outbox`, RPC `claim_due_reminders` (service_role).
- Código Edge: `supabase/functions/repera-business-push`.
- **Pendiente externo:** desplegar la Edge Function, cron/scheduler seguro, secretos FCM/APNs y prueba end-to-end. Los avisos locales son el fallback operativo sujeto a permisos del SO.

### Pendiente / no cerrado solo con código

| Ítem | Estado |
|------|--------|
| Pruebas físicas Watch Ultra Action Button / doble toque / corona | Hardware |
| Validación Assistant en Play Console / dispositivo | Distribución |
| Entrega remota garantizada de recordatorios | Credenciales + deploy |
| Conciliación HealthKit/Health Connect en dispositivo real | Hardware |
| Emuladores API 30/35/37.2 y Wear 5.1/6.0 | CI (ver checks de la PR) |
| Share Extension / intent GPX a nivel sistema | Código en fase 5 (`NATIVE_OS_SURFACES_PHASE_5_2026_11_04.md`); validación hardware / App Group ASC pendiente |
| AppSearch de rutinas **privadas** (además del catálogo público) | No implementado a propósito: solo público opt-in |
| Banner «Usar este lugar» Android paridad total con `SportNearbyPlaceSuggester` iOS | Parcial (título/geocoder; falta POI ≤50 m + aceptar/descartar) |

No marcar las cuatro fases como «terminadas» sin CI verde e integración en `main`.
