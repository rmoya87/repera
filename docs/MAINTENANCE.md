# Mantenimiento de la documentación

Última actualización: 2026-10-24 (resolución de paquetes Swift tras regenerar Xcode)

## Regla de oro

**Todo cambio de comportamiento o arquitectura debe dejar la documentación coherente en el mismo PR / misma sesión de agente.**

No acumular docs obsoletas. Preferir editar y borrar a añadir páginas huérfanas.

## Qué actualizar según el cambio

| Cambio | Actualizar |
|--------|------------|
| Nueva pestaña / flujo UI | `FEATURES.md`, a veces `README.md` tabla de estado |
| Nuevo módulo / store / dependencia | `ARCHITECTURE.md` |
| OCR / IA / parser pizarra | `BOARD_SCAN.md` (+ tests mencionados) |
| Bundle, iCloud, arranque, requisitos | `README.md` |
| Rendimiento / Observation / caches | `PERFORMANCE.md`, a veces `ARCHITECTURE.md` |
| Freemium / RevenueCat / límites | `MONETIZATION.md`, `FEATURES.md`, `ARCHITECTURE.md`, `TESTING_GUIDE.md` |
| Web marketing / legales ASC | `web/` (`index`, `privacy`, `terms`, `faq`, `.htaccess`, `pack-ionos.sh`, `README`) + `FEATURES` / `ARCHITECTURE` si cambia alcance |
| Convención para agentes | `AGENTS.md`, `.cursor/rules/` |
| Feature eliminada o renombrada | Quitar o corregir en **todos** los docs que la citaban |

## Checklist al terminar un cambio

1. ¿El README “Estado actual” sigue siendo verdad?
2. ¿ARCHITECTURE lista archivos/módulos nuevos o eliminados?
3. ¿FEATURES describe la UI tal como la ve el usuario?
4. ¿Hay menciones a bots, APIs o pantallas que ya no existen? → borrarlas.
5. Poner **Última actualización: YYYY-MM-DD** en docs tocados.

## Proyecto Xcode generado y nuevos archivos Swift

El target iOS se define en `project.yml` con el directorio `Apps/Repera/Sources`; el archivo `Repera.xcodeproj` se genera localmente y no está versionado. Si se añade un nuevo `.swift`, abrir un proyecto Xcode generado antes de ese commit puede dar errores `Cannot find type in scope` aunque el fichero exista.

- Regenerar desde la raíz con `xcodegen generate` y volver a abrir `Repera.xcodeproj` cuando se añadan o eliminen archivos Swift. El nuevo `RemoteExerciseCatalogStore.swift` está declarado expresamente en `project.yml`: `scripts/check_xcode_sources.py` comprueba que aparece en **Compile Sources del target Repera**, no solo en el navegador de Xcode.
- Si aparecen `Cannot find RemoteExerciseCatalogStore in scope` en `ReperaApp.swift` o `ReperaStore.swift` junto con un error de tiempo de type-check, actualizar la copia local y ejecutar `./Repera-Xcode.command` (o `git pull --ff-only origin main && xcodegen generate --spec project.yml && python3 scripts/check_xcode_sources.py`). No borrar DerivedData ni datos del usuario por defecto; cerrar el proyecto antiguo antes de regenerarlo.
- Tras añadir paquetes como Google Sign-In, los archivos Swift pueden actualizarse por Git mientras el proyecto local sigue sin enlazar los productos nuevos. Cerrar Xcode y ejecutar `./Repera-Xcode.command`: actualiza de forma segura, regenera, valida fuentes y ejecuta `xcodebuild -resolvePackageDependencies` antes de abrir. `Repera-iOS.command` también resuelve los paquetes antes de lanzar Simulator; `Repera-Verificar.command` incluye la resolución entre sus comprobaciones. Estos pasos no borran cachés ni datos de usuario.
- Al corregir errores que afectan a personas con proyectos ya generados, es preferible mantener componentes pequeños en un archivo **ya incluido** hasta que se regenere el proyecto. La tabla compacta de series (`OGSetFieldID`, `OGSetEntryHeader`, `OGSetEntryRow`) se encuentra en `Apps/Repera/Sources/Theme.swift` precisamente por este motivo.
- No introducir definiciones duplicadas entre `Theme.swift` y archivos independientes: XcodeGen acabaría compilando ambas.

## Docs históricas

`docs/superpowers/` son notas de diseño fundacional (2026-10-15). Están marcadas como **históricas**. No las uses como fuente de verdad; la verdad vive en `README` + `docs/*.md` de este directorio (excepto `superpowers/`).

## Idioma

Documentación del proyecto en **español** (producto ES). Nombres de tipos/código en inglés como en el repo.
