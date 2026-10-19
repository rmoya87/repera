# AGENTS.md — Repera

Instrucciones para agentes (Cursor / Auto) que trabajan en este repo.

## Idioma

- Responder al usuario en **español**.
- Código e identificadores en inglés como el resto del proyecto.

## Documentación (obligatorio)

Tras **cualquier** cambio de comportamiento, UI relevante, arquitectura o flujo:

1. Actualizar los docs afectados (`README.md`, `docs/ARCHITECTURE.md`, `docs/FEATURES.md`, `docs/BOARD_SCAN.md`, …).
2. Eliminar o corregir información obsoleta / incorrecta.
3. Seguir `docs/MAINTENANCE.md`.
4. No inventar features en la doc que no estén en el código.

Si el cambio es solo tipográfico o de estilo sin cambio de producto, no hace falta tocar docs.

## Stack

- **Siempre la última OS**: iOS 27+ / watchOS 27+ (no programar para majors anteriores). Al salir una nueva, subir `project.yml`, `Package.swift` y docs.
- SwiftUI, XcodeGen (`project.yml`).
- Dominio: `Packages/ReperaDomain`.
- App: `Apps/Repera`, Watch: `Apps/ReperaWatch`.

## Convenciones UI

- Tokens `OG*` en `Theme.swift`.
- Roots sin volver: `ogFixedTopBar` (título arriba; acciones a la derecha en la misma fila).
- Subpáginas con volver: `ogPinnedTransparentNav` (título large debajo del chevron/acciones).
- Sheets compactos: `OGPageHeader` + `ogFittedSheet` / `ogSheetCorners`.
- Títulos de sección **encima** de las cards: `OGCardSectionTitle` (gris, estilo Ajustes).

## Arte de ejercicios (carrusel)

- Mismo **equipo** (diseño idéntico) y misma **persona** (pelo, ropa, zapatillas) en todos los frames de un ejercicio.
- Ropa: **tank + shorts + zapatillas**; nunca torso desnudo ni sin shorts.
- Al regenerar: usar el frame `_1` como `reference_image_paths` y solo cambiar la pose.

## Pizarra

Pipeline: OCR → Apple Intelligence si hay → si no, `BoardImportParser`. Detalle en `docs/BOARD_SCAN.md`.

## Commits / PR

Solo cuando el usuario lo pida. Seguir las user rules de git/PR del entorno.

## No hacer

- No asumir backend social.
- No meter API keys de LLM cloud para el escáner (on-device o parser local).
- No reintroducir el botón «+ Plan» en la lista de ejercicios sin pedirlo.
