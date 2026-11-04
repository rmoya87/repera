# Matriz de instrumentación GA4 — Repera

**Última actualización:** 2026-11-04

Leyenda: **hecho** = llamada real tras fuente de verdad · **parcial** · **pendiente**.

## Cubierto

| Área | iOS | Android | Notas |
| --- | --- | --- | --- |
| Navegación / `ui_interaction` tab | hecho | hecho | `component_id=tab_bar` |
| Entrenamiento + `workout_save_failed` | hecho | parcial | Fallo persistencia iOS |
| Live / mapas | hecho | hecho | recenter + nav mode |
| Timer | hecho | parcial | pause/resume Android |
| Ejercicios / progreso | hecho | parcial | search/period/export |
| Escáner | hecho | pendiente | |
| Center | hecho | hecho | waitlist/attended en refresh |
| IA | hecho | hecho | paused + inbox |
| Sync | iCloud | Drive | `sync_*` |
| Reloj | WC relay | Wear durable + ACK | `/repera/analytics-event` |
| Business web | — | — | `product-analytics.js` + gtag opcional |
| Suscripción | hecho | hecho | MonetizationAnalytics |

## Pendiente externo / fino

- plist/json Firebase reales + DebugView (ver `FIREBASE_SETUP.md`).
- Escáner Android, timer start/complete Android, login/onboarding Android.
- Matriz exhaustiva `ui_interaction` en todos los controles (solo tabs + allowlist contrato).
- E2E hardware cuatro dispositivos.
