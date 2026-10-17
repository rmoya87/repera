# ADR 006 — Compatibilidad con trabajo de ilustraciones

**Estado:** aceptado · **Fecha:** 2026-10-17 · **Ticket:** G27-030

## Decisión
Esta rama **no** modifica creativamente JPG de `ExerciseArt/` ni prompts de regeneración.

## Inconsistencias documentadas (para el equipo de arte)
- `AGENTS.md` pide ropa **tank + shorts + zapatillas**.
- Commits recientes de arte en `main` alinean estilo «shirtless» en docs de auditoría (`docs/EXERCISE_ART_AUDIT.md` / regen prompts).
- Resolver la regla canónica de vestuario **solo** en las PRs de arte (#1/#2), no aquí.

## Qué sí hace esta rama
- Loader/manifest/caché de thumbs.
- Quarantine/captions existentes se respetan.
