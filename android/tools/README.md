# Herramientas del catálogo semilla

`catalog_seed.json` (288 entradas) se deriva del catálogo iOS de `origin/main`
con identidad estable para Android. Nunca se edita a mano.

- `extract_catalog.py --git-ref <ref> --out <fichero>`: parsea los
  `Packages/ReperaDomain/Sources/ReperaDomain/Catalog*.swift`, `CatalogSpanish`,
  `MuscleTaxonomy` y `SportExerciseNames` de la ref dada y replica la semántica
  de `Catalog.seed()` (displayName → libraryMuscleGroup → localize). Requiere
  git y la ref disponible localmente.
- `catalog_reference_ios.json`: referencia congelada con procedencia
  (origin/main e1621b8, 2026-10-24). Se regenera con el extractor cuando main
  cambia el catálogo y se decide resincronizar.
- `catalog_id_registry.json`: los 196 ids históricos preservados (nombre iOS →
  id Android). Intocable: son los ids que los snapshots de usuarios ya
  referencian.
- `check_catalog_parity.py`: verificación offline y reproducible del seed
  contra la referencia y las reglas de identidad (196 preservados, v3 para
  mobility-*/hyrox-*, v5 para altas nuevas). Debe pasar tras cualquier
  regeneración.

Reglas de identidad (resumen): entrada existente → conserva id; mobility/hyrox
→ UUID v3 `repera:catalog:<catalogId>` (idéntico al de MobilityCatalogMigration,
así cuentas antiguas y nuevas comparten id); alta nueva → UUID v5
`repera-seed:<catalogId|name>`.
