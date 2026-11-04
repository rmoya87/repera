# Matriz de instrumentación GA4 — Repera

**Última actualización:** 2026-11-04

Leyenda: **hecho** = llamada real tras fuente de verdad · **parcial** · **pendiente**.

## Cubierto (iOS + Android núcleo)

| Área | Eventos | Notas |
| --- | --- | --- |
| Navegación | `screen_view` | Tabs phone |
| Cuenta | `login`, `sign_up`, `onboarding_*` | Primera Apple ID → `sign_up` |
| Entrenamiento | `workout_*` (create/schedule/start/pause/resume/set/block/save_requested/completed/discard/delete/edit) | Planned → `strength`/`crossfit`; completed tras persistencia + `trackOnce` |
| Live sport | `activity_selected`, `route_*`, `navigation_*`, `map_recenter_requested`, `sport_favorite_added` | Sin coordenadas |
| Timer | `timer_started/paused/resumed/completed/discarded`, `rest_timer_skipped` | standalone |
| Ejercicios | `exercise_search_used`, `exercise_detail_viewed`, `custom_exercise_created` | Sin texto de búsqueda |
| Escáner | `scan_started/processed/result_accepted/saved/failed` | Sin OCR |
| Progreso | `progress_section_viewed`, `progress_period_selected`, `progress_detail_opened`, `exercise_history_viewed`, `personal_record_viewed` | 6 secciones |
| Centro | `center_search/invite/link/unlink`, `class_*`, `appointment_confirmed`, `class_plan_opened` | `class_attended` solo status `attended` |
| Suscripción | embudo Pro (`MonetizationAnalytics` + checkout) | StoreKit / Play |
| IA | `ai_connection_*`, `ai_program_received/activated` | Sin tokens |
| Ajustes / datos | `settings_changed`, `data_import/export_completed` | |
| Fiabilidad | `sync_*`, `operation_failed`, `notification_opened` | iCloud |
| Reloj | `watch_command_used`, `watch_app_opened` (relay), `watch_sync_confirmed/failed` | Sin Firebase en watchOS; teléfono reemite |

## Pendiente / externo

- Firebase `GoogleService-Info.plist` / `google-services.json` reales + DebugView.
- Wear OS relay durable completo (paridad cola Watch).
- Business web analytics.
- Cobertura exhaustiva `ui_interaction` por control (fase 5 del plan).
- `ai_program_paused` cuando exista pausa de plan en producto.
- `workout_save_failed` cuando falle escritura durable (hoy fallos raros / silent).

Parámetros: allowlist en `ReperaAnalytics`; nunca Salud, GPS, PII ni texto libre de usuario.
