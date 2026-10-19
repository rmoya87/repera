# Canvas de evolución — iOS 27 / watchOS 27

Panel visual persistente del trabajo de modernización de Repera.

**Última actualización:** 2026-10-17

## Abrir el Canvas

```bash
# Desde la raíz del repo (o este worktree)
python3 docs/ios27-modernization/generate_canvas.py --write
open docs/ios27-modernization/canvas.html
```

`canvas.html` es **autónomo**: los datos de `progress.json` se incrustan en el HTML. No hace falta servidor ni servicios de pago.

## Actualizar progreso

1. Edita `progress.json` (estado de tareas, commits, tests, métricas, histórico).
2. Ejecuta el generador:

```bash
python3 docs/ios27-modernization/generate_canvas.py --write
```

3. Valida sin escribir:

```bash
python3 docs/ios27-modernization/generate_canvas.py --check
```

## Estados

| Valor JSON | Kanban |
|------------|--------|
| `pending` | Pendiente |
| `in_progress` | En curso |
| `in_review` | En revisión |
| `blocked` | Bloqueado |
| `completed` | Completado |

Una tarea **no** debe marcarse `completed` sin evidencias en `tests[]` (resultado `pass` o, si el hardware falta, `blocked` documentado y la implementación claramente separada en `notes`).

## Reglas

- Fuente de verdad: `progress.json`.
- El generador recalcula agregados globales y por fase.
- Rama de trabajo: `feat/ios27-native-performance-audit`.
- Base auditada: `2536e7f` — auditar ≠ implementar; el estado inicial es todo `pending`.
- No mezclar con PRs de arte de ejercicios (`G27-030`).

## Archivos

| Archivo | Rol |
|---------|-----|
| `progress.json` | Estado real de G27-001…030 |
| `canvas.html` | Dashboard generado |
| `generate_canvas.py` | Generación + validación |
| `CHANGELOG.md` | Historial de implementaciones |
| `README.md` | Este documento |
