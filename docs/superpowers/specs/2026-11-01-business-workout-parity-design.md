# Business · paridad creación de entrenos con la app

Última actualización: 2026-11-01.

## Decisión

Enfoque **capas sobre el editor actual** (`workout-editor.js` + contrato `schemaVersion: 1`): misma capacidad que iOS/Android sin reescribir el pipeline de publicación.

## Requisitos acordados

1. Constructor alineado a la app: Sin formato, + Ejercicio / Descanso / Movimiento libre, Añadir bloque, Elegir WOD (benchmarks), Mis entrenos; meta fecha/hora/duración/lugar/favorito; botón Escanear pizarra visible (OCR web = fase posterior).
2. Al editar/asignar: elegir **Mis entrenos** o **crear ahora**.
3. Al reemplazar un plan ya publicado: preguntar alcance **esta clase / serie (futuras) / día** y sustituir.

## Arquitectura

- Composer unificado en Mis entrenos, sesión PT, clase y asignación multi-clase.
- `canonicalPrescription` sigue validando en Supabase; metadatos de sesión (`meta.location`, `meta.favorite`, `meta.durationMinutes`) viajan como claves opcionales ignoradas por apps hasta consumo.
- Alcance serie: misma heurística que `edit-occurrence` (mismo título, DOW, hora, futuras).
- Alcance día: `publish_class_training_bulk` con las occurrences del día seleccionadas.

## Fases

- F1 Constructor + meta + Elegir WOD + Movimiento libre + Sin formato.
- F2 Origen + alcance unificado.
- F3 OCR pizarra web + consumo móvil de `meta` si procede.

## Fuera de alcance inmediato

Cambiar el contrato móvil de lectura de bloques profesionales; pantallas nativas iOS/Android del atleta.
