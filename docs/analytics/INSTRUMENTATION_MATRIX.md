# Matriz de instrumentación GA4 — Repera

**Última actualización:** 2026-11-04

Leyenda de estado: **hecho** = llamada real tras fuente de verdad · **parcial** · **pendiente**.

| Evento | Momento | iOS | Android | Web Business | Prueba |
| --- | --- | --- | --- | --- | --- |
| screen_view | Cambio de tab real | hecho | hecho | pendiente | contrato + UI |
| activity_selected | Elegir deporte catálogo | hecho | hecho | — | contrato |
| progress_section_viewed | Chip progreso | hecho | hecho | — | contrato |
| workout_completed | Tras persistencia finished | hecho | hecho | — | contrato hooks |
| workout_discarded | Descarte confirmado | hecho | hecho | — | contrato hooks |
| workout_deleted | Borrado local confirmado | hecho | hecho | — | contrato hooks |
| workout_edited | Edición finished persistida | hecho | hecho | — | contrato hooks |
| data_import_completed | Import CSV (no completed/sesión) | hecho | pendiente | — | contrato |
| Embudo suscripción (8+) | StoreKit / Play verificados | hecho | hecho | — | contrato |
| Reloj cola/ACK | — | pendiente | pendiente | — | — |
| Center / clases | — | pendiente | pendiente | pendiente | — |
| Timer / escáner / IA | — | pendiente | pendiente | — | — |

Parámetros habituales de entrenamiento: `feature_area`, `workout_type`, `activity_type`, `activity_family`, `wod_format` (si un solo formato), `session_origin_platform`, `completion_platform`, `result`.
