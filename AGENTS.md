# AGENTS.md — Gymbro

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

- iOS 26+ / watchOS 26+, SwiftUI, XcodeGen (`project.yml`).
- Dominio: `Packages/GymbroDomain`.
- App: `Apps/Gymbro`, Watch: `Apps/GymbroWatch`.

## Convenciones UI

- Tokens `OG*` en `Theme.swift`.
- Cabeceras de subpágina: `OGBackPageHeader` + botones glass 44pt.
- Sheets: `ogFittedSheet` / `ogSheetCorners`.
- Títulos dentro de cards: `OGCardSectionTitle`.

## Pizarra

Pipeline: OCR → Apple Intelligence si hay → si no, `BoardImportParser`. Detalle en `docs/BOARD_SCAN.md`.

## Commits / PR

Solo cuando el usuario lo pida. Seguir las user rules de git/PR del entorno.

## No hacer

- No asumir backend social.
- No meter API keys de LLM cloud para el escáner (on-device o parser local).
- No reintroducir el botón «+ Plan» en la lista de ejercicios sin pedirlo.
