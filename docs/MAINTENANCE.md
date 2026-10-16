# Mantenimiento de la documentación

Última actualización: 2026-10-16 (fix carruseles; sin sombra en poses aéreas)

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
| Convención para agentes | `AGENTS.md`, `.cursor/rules/` |
| Feature eliminada o renombrada | Quitar o corregir en **todos** los docs que la citaban |

## Checklist al terminar un cambio

1. ¿El README “Estado actual” sigue siendo verdad?
2. ¿ARCHITECTURE lista archivos/módulos nuevos o eliminados?
3. ¿FEATURES describe la UI tal como la ve el usuario?
4. ¿Hay menciones a bots, APIs o pantallas que ya no existen? → borrarlas.
5. Poner **Última actualización: YYYY-MM-DD** en docs tocados.

## Docs históricas

`docs/superpowers/` son notas de diseño fundacional (2026-10-15). Están marcadas como **históricas**. No las uses como fuente de verdad; la verdad vive en `README` + `docs/*.md` de este directorio (excepto `superpowers/`).

## Idioma

Documentación del proyecto en **español** (producto ES). Nombres de tipos/código en inglés como en el repo.
