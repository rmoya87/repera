# ADR 004 — Imágenes y estadísticas

**Estado:** aceptado · **Fecha:** 2026-10-17

## Decisión
- Thumbs: `ThumbImageLoader` actor (concurrencia 4, dedupe, LRU 120, manifiesto JPG).
- `body` solo usa `cachedThumb` (sin decode).
- Stats: `DerivedStatsCache` invalidado con `syncRevision`.
- Charts: Task cancelable + generación; no publicar resultados stale.
