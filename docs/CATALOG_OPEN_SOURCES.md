# Catálogo Repera ↔ fuentes abiertas

Última actualización: 2026-11-04 (Fase G +6 → seed/remoto **476**; C–G aplicadas en Supabase).

## Nombres CrossFit / halterofilia

- **Título visible:** inglés típico de box/competición (`Snatch`, `Clean and Jerk`, `Thruster`, `Double-Under`…).
- **Aliases:** español formal + jerga, diminutivos y acrónimos en ES e EN (`arrancada`, `dos tiempos`, `C&J`, `dobles`, `DU`, `TGU`, `assault bike`…).
- Implementación: `SportExerciseNames` (Swift + Kotlin). La UI usa el canónico EN; la búsqueda/OCR usa `searchAliases` / glosario.

## Objetivo

Ampliar y enriquecer el catálogo maestro (hoy **476** fichas en `Catalog.seed()` tras Fase G) con texto y taxonomía de bibliotecas abiertas, **sin** que las apps consulten esas fuentes en runtime y **sin** importar sus fotografías/GIF.

Publicación operativa: `business_exercise_catalog` + `training_exercise_metadata` → `mobile_exercise_catalog_events` (ver [REMOTE_EXERCISE_CATALOG.md](REMOTE_EXERCISE_CATALOG.md)). Destino = **Supabase** (SQL/admin). Tras la migración de arte remoto: subir JPG al bucket `exercise-art` y rellenar `mobile_art_keys` (sin App Store). Hasta entonces el arte empaquetado sigue siendo el fallback; seed solo bootstrap.

## Arte

Obligatorio el estilo canónico Repera (`art_ab_wheel`, prompt en `docs/EXERCISE_ART_REGEN_PROMPTS.md`). Detalle en [`tools/catalog_ingest/ART_STYLE.md`](../tools/catalog_ingest/ART_STYLE.md). Licencias: [`tools/catalog_ingest/LICENSE_MATRIX.md`](../tools/catalog_ingest/LICENSE_MATRIX.md).

## Pipeline

```bash
python3 tools/catalog_ingest/fetch_sources.py --with-oedb
python3 tools/catalog_ingest/match_catalog.py
python3 tools/catalog_ingest/build_phase_a_draft.py
# Tras altas con «cómo hacerlo» genérico:
python3 tools/catalog_ingest/rewrite_phase_d_coaching.py
```

Salidas en `tools/catalog_ingest/out/` (local, no versionado): informe CSV, candidatos new/ambiguous, borrador Fase A, coaching rewrite, shortlist Fase E.

## Fases

| Fase | Qué | Publicación |
|------|-----|-------------|
| A | Enriquecer matches (aliases, textos revisados) | Supabase editorial tras revisión humana |
| B | Altas selectivas de huecos | Misma vía; arte Repera en deploy posterior |
| C | Lotes amplios con dedupe | Idem; backfill seed opcional en release (bootstrap), no bloquea apps en producción |
| D | Huecos Open WOD + variantes por material | Idem |
| E | Huecos gym FED/OEDB **selectivos** (no dump masivo) | Idem |
| F | Huecos FED/OEDB gym + opcionales | Idem |
| G | Huecos RepDB/Kinetic **selectivos** (+ crédito RepDB en Ajustes) | Idem |

**No** aplicar UPSERT a producción sin confirmación humana explícita.

## Snapshot de solape y fases (2026-11-04)

Tras cruzar Free Exercise DB (876) + Open WOD movements (314) + OpenExerciseDB recommended (868):

- **157 / 290** fichas Repera (antes de Fase B) con match externo enriquecible
- Fase A: aliases CF/HL sincronizados a `training_exercise_metadata` (migración `20261104201500_…`)
- Fase B: **+12** CrossFit selectivos — migración `20261104203000_…`
- Fase C: **+16** huecos selectivos — `20261104210000_…`
- Fase D: **+115** huecos Open WOD + variantes por material — `20261104220000_…`
- **Coaching rewrite Fase D:** 115 fichas con «cómo hacerlo» genérico → pasos específicos + músculos/equipo corregidos — `20261104233000_…` + `tools/catalog_ingest/rewrite_phase_d_coaching.py`
- Fase E: **+14** gym FED/OEDB selectivos (crunch polea, pec deck, remo en T, curls femorales máquina, woodchop, etc.) + aliases EN→ficha existente — `20261104234000_…`
- Fase F: **+23** huecos FED/OEDB (16 gym + 6 opcionales + Band Pull Apart); movilidad FED no añadida (ya cubierta en `CatalogMovilidad`, 82) — `20261104250000_…`
- Fase G: **+6** huecos RepDB/Kinetic selectivos (Almeja, Hidrante, TKE, Windshield wipers, Dragon flag, Planche lean) — `20261104270000_…`; coaching propio Repera; crédito RepDB en Ajustes
- Política media: solo ExerciseArt Repera. Altas B/C/D/E/F/G cableadas a stems cercanos (`nameMap`); regen dedicada = backlog.
- Fill remaining + sport tags Enrichment: `20261104240000_…`, `20261104241000_…` (0 fichas sin `sportTag`).
- **RepDB / Kinetic:** licencia en `LICENSE_MATRIX.md`. Fase G aplicada; crédito visible en Ajustes (iOS/Android).
- **Remoto (2026-11-04 noche):** migraciones C–G + backfills (`210000`…`250000`, `270000`) aplicadas una a una (`db query` + `migration repair`); `260000` ya estaba. Catálogo activo remoto = **476**, 0 sin descripción / `sportTag`. Historial local↔remoto sin pendientes de este lote.
- **Backlog:** dump masivo FED/OEDB; arte dedicado restante; Human flag / Cuban / Y–T (opcionales no incluidos).

## Metadatos (2026-11-04)

Tras Fase G:

- Remoto/seed activo **476** con descripción, instrucciones y equipo específicos (no boilerplate).
- `skill_level` y `primary_muscles` rellenados en altas E/F/G; D reescritas.
- `sportTag`/disciplina: **476/476** con tag. Los 66 Enrichment gym previos recibieron tag (`20261104241000_…`); F/G etiquetan según ficha.
- **RepDB / Kinetic (revisión 2026-11-04):** ver `LICENSE_MATRIX.md`. Kinetic JSON = MIT. RepDB free = in-app con atribución («Exercise data by RepDB (repdb.co)» en Ajustes); sin redistribuir dataset ni usar imágenes para gen-AI; arte = ExerciseArt.
- Logging (kg/reps/cal/m): reglas nativas `Exercise.loggingStyle`.
- **Carga sugerida (%1RM):** solo si `loggingStyle == loadAndReps` (no cardio/máquina/movilidad).
- **Evolución:** tabs scrollables «Mejor m / Mejor cal / Suma m / Suma cal / Tiempo» (iOS chips; Android `ScrollableTabRow`) — nunca menú desplegable para máquina.
- Arte: `nameMap` cubre las fichas; héroes dedicados prioritarios + reuso de stems (**regen dedicada = único backlog**).
- Seed local (2026-11-04): altas D/E/F/G con descripción + instrucciones ES (tono entrenador), `sportTag`, aliases en `SportExerciseNames`/`BoardImportParser`, y `nameMap` de arte. Contador seed = **476** (`CatalogQualityTests`).
- Movilidad: no se importó el dump de stretching FED/OEDB; `CatalogMovilidad` ya cubre los patrones útiles (gato-vaca, WGS, couch, 90/90, etc.). De FED sí se añadió **Aperturas con banda** (Band Pull Apart).
