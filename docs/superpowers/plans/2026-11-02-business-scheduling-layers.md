# Plan de implementación: scheduling layers Business

Última actualización: 2026-11-02.

Spec: `docs/superpowers/specs/2026-11-02-business-scheduling-layers-design.md`.

## Archivos

| Área | Archivos |
|------|----------|
| SQL | `supabase/migrations/20261102090000_business_scheduling_layers.sql`, tests en `supabase/tests/` |
| Docs | `docs/business/BASE_DATOS.md`, `USE_CASE_COVERAGE.md`, `ESTADO_DESARROLLO.md`, `FEATURES.md` |
| Web | `web/console/src/ui/connected.js`, `auth.js`, nuevo `operation-settings.js`, agenda/management |
| iOS | `BusinessDataStore.swift`, `CenterView.swift` / `BusinessCenterViews.swift` |
| Android | `BusinessCenterStore.kt`, `CenterTab.kt` |

## Tareas

1. Spec + docs (matriz) — hecho en esta entrega.
2. Migración capas + backfill + RPCs + cancel hours.
3. Web: Ajustes Operación, salas, tipos, programa del día, series_id en alta.
4. Apps: settings bundle, open_access, sala, contenido resuelto.
5. Tests SQL/UI smoke + waitlist visible.
