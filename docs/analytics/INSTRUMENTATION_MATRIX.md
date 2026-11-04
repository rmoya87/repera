# Matriz de instrumentación GA4 — Repera

**Última actualización:** 2026-11-04

Leyenda: **hecho** = llamada real tras fuente de verdad · **parcial** · **pendiente**.

## Cubierto (~35 eventos)

| Área | Eventos | Notas de identificación |
| --- | --- | --- |
| Navegación | `screen_view` | Tabs: home/start/center/progress/exercises |
| Live sport | `activity_selected`, `workout_started/paused/resumed`, `sport_favorite_added` | `activity_type` + `activity_family` |
| Entrenamiento | `workout_started/set_recorded/block_completed/completed/discarded/deleted/edited`, `favorite_*`, `data_import_completed`, `scan_saved` | Planned sin liveSport → `strength`/`crossfit`; WOD por bloque |
| Timer | `timer_started/completed/discarded` | `timer_type=standalone` |
| Progreso | `progress_section_viewed` | 6 secciones |
| Centro | `class_booking_confirmed/cancelled`, `center_link_completed`, `center_unlinked` | Sin nombres de centro |
| Suscripción | embudo Pro (8+) | StoreKit/Play |
| Cuenta | `login`, `onboarding_started/completed` | Sin PII |
| Reloj | `watch_command_used` + completed con origen watch | Cola ACK completa pendiente |

## Pendiente relevante

Timer pause/resume, escáner completo, ejercicios search/detail, mapas route_*, Center list/view/waitlist/attended, IA, checkout_*, sync_*, cola Watch/Wear durable, Business web, Firebase files reales / DebugView.

Parámetros de entrenamiento: `feature_area`, `workout_type`, `activity_type`, `activity_family`, `wod_format`, plataformas, `result`.
