# Ingesta de catálogos abiertos → Repera

Última actualización: 2026-11-04.

Pipeline offline para **cruzar** el catálogo canónico Repera (433) con fuentes abiertas, enriquecer o proponer altas, y publicar vía Supabase (`business_exercise_catalog` + `training_exercise_metadata`). Las apps **no** consultan estas fuentes en runtime.

## Arte (obligatorio)

Las imágenes de terceros de Free Exercise DB / RepDB / Kinetic / similares **no se importan**.

Todo arte nuevo o regenerado debe seguir el estilo canónico Repera:

- Referencia: `Apps/Repera/Resources/ExerciseArt/art_ab_wheel.jpg`
- Prompt maestro: `docs/EXERCISE_ART_REGEN_PROMPTS.md`
- Misma figura: torso descubierto, shorts charcoal, zapatillas grises, cara sin rasgos
- Fondo negro mate, ilustración plana/vectorial, highlight lima solo en músculos activos
- Full 1024 + thumb 192 vía `scripts/export_generated_art.py`
- Secuencias: mismo personaje, equipo y cámara; frame `_1` como referencia de pose

Ver `ART_STYLE.md` en esta carpeta.

## Uso

```bash
# Desde la raíz del repo
python3 tools/catalog_ingest/fetch_sources.py
python3 tools/catalog_ingest/match_catalog.py
```

Salidas en `tools/catalog_ingest/out/`:

- `overlap_summary.json` — cifras
- `overlap_report.csv` — fila por ejercicio externo
- `repera_enrich_candidates.csv` — matches Repera con campos enriquecibles
- `new_candidates.csv` — posibles altas (revisión humana)
- `ambiguous.csv` — fuzzy / dudosos

## Publicación Supabase

No aplica migraciones ni UPSERT automático a producción desde estos scripts. Tras revisión humana, un script admin separado (pendiente) escribirá en editorial; requiere confirmación explícita.

## Fuentes fase 1

| Fuente | Archivo vendor | Licencia texto | Media |
|--------|----------------|----------------|-------|
| Free Exercise DB | `vendor/free_exercise_db.json` | Unlicense (datos) | **No usar** fotos (copyright dudoso) |
| Open WOD Database | `vendor/open_wod_movements.json` | CC BY 4.0 + atribución | N/A (sin ilustraciones propias usadas) |
| OpenExerciseDB | opcional (`fetch` con `--with-oedb`) | CC BY-SA 4.0 | No importar media |
