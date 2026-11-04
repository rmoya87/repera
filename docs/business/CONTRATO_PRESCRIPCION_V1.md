# Contrato de programación profesional v1

Última actualización: 2026-11-04.

La **fuente editorial viva** del catálogo móvil es Supabase (`business_exercise_catalog` + `training_exercise_metadata` → feed `mobile_exercise_catalog_events`). Las apps reciben altas/ediciones/bajas **sin App Store**; detalle en [REMOTE_EXERCISE_CATALOG.md](../REMOTE_EXERCISE_CATALOG.md). `Catalog.seed()` y `web/console/src/data/exercise-catalog.json` son bootstrap / espejo de consola: **no** es obligatorio actualizarlos al publicar un ejercicio nuevo o corregir campos.

`catalogKey` usa `catalog:<nombre canónico>` como identidad lógica **inmutable** compartida entre Business, MCP y apps, **no** un UUID aleatorio de `Exercise.id` (los IDs locales cambian). La app resuelve primero `catalogKey` y como alternativa el nombre normalizado. Los movimientos libres tienen `source: "free"`, `name` y `catalogKey: null`; permanecen dentro de la prescripción del entrenador, sin contaminar el catálogo global.

El formato JSON se guarda en `professional_training_sessions.prescription` y se valida por el backend:
```json
{
  "schemaVersion": 1,
  "blocks": [
    {
      "id": "fef9e3f2-2dc8-4c3b-a47e-6e87fe088169",
      "title": "Fuerza",
      "kind": "strength",
      "exercises": [{
        "id": "14d3f3aa-73f7-4cc9-a18f-0948fc97925a",
        "source": "catalog",
        "catalogKey": "catalog:Press banca",
        "name": "Press banca",
        "plannedSets": [
          {"id": "aed5bb0b-d757-474f-aa9c-547ab5b021a3", "targetReps": 8, "targetWeightKg": 40, "targetRir": 2}
        ]
      }],
      "movements": []
    },
    {
      "id": "2fa16dbd-ddd8-4f27-8afc-ddc08d23f958",
      "title": "WOD por tiempo",
      "kind": "wod",
      "wodFormat": "forTime",
      "rounds": 4,
      "timeCapMinutes": 12,
      "exercises": [],
      "movements": [{
        "id": "661ca10d-1c31-45d3-82d0-aed2192fc949",
        "source": "free",
        "catalogKey": null,
        "name": "Movimiento personalizado",
        "reps": 10,
        "notes": "Versión adaptada"
      }]
    }
  ]
}
```

- Fuerza: `exercises` (series, repeticiones, kg, RIR). **No** lleva `isRest` dentro de `exercises` (paridad `PlanView.insertRest`).
- WOD: `wodFormat` según `WODFormat` nativo, rondas, time cap, intervalos, movimientos en orden con reps y escala opcional.
- Descanso: movimiento WOD con `isRest: true` y `restSeconds` (mín. 5). Si el editor web añade descanso desde un bloque de fuerza, se publica como bloque WOD «Descanso» aparte con **`wodFormat: "forTime"`** (obligatorio: sin formato el RPC `validate_professional_prescription` rechaza el guardado). iOS (`ReperaStore`) y Android (`WorkoutRepository`) proyectan esos movimientos a `WODMovement.isRest`.
- Bloques/ejercicios/movimientos tienen IDs estables por publicación; versiones: cada publicación/cancelación conserva historial separado.
- Se conserva `instructions` para versiones antiguas y resumen. A partir de v1, web y iOS leen primordialmente `prescription`.
- La base de datos valida estructura, pertenencia y existencia de ejercicios de catálogo; **ningún entrenador puede leer historiales personales** por publicar un plan.
- Lectura y vista detallada en Inicio/Diario solo para la cuenta vinculada, con RLS existente.

**Metadatos de sesión (web, 01/11/2026):** el editor Business puede añadir `meta` opcional al wire (`location`, `favorite`, `durationMinutes`). La validación SQL solo exige `schemaVersion` + `blocks`; claves extra no invalidan. Las apps móviles las ignoran hasta un consumo explícito.

**Límites actuales:** los bloques profesionales se muestran como planificación de solo lectura en iOS; no se importan automáticamente al historial local ni a HealthKit. OCR de pizarra en Business web queda pendiente. Tests E2E en dispositivos con Apple pendientes.

Última actualización: 2026-11-01.
