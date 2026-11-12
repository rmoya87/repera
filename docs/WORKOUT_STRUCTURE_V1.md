# Estructura componible de entrenamientos — v1 (12/11/2026)

## Contrato sin ruptura

La app conserva sus 14 valores `WODFormat` y los campos históricos
`timeCapMinutes`, `rounds`, `emomIntervalSeconds`, `workSeconds`,
`restSeconds`, `restBetweenRoundsSeconds`, `movements` y `exercises`.
Los nuevos campos opcionales de un bloque son:

- `timeCapSeconds`: duración exacta; prevalece sobre minutos al ejecutar.
- `structure.version = 1`: `section`, `collaboration`, `resultMetric`
  y `phases[]`.
- Cada fase tiene `kind` (`work`, `rest`, `buyIn`, `main`, `cashOut`),
  título, UUID de los movimientos originales, repetición/trabajo/descanso,
  notas y posibles subfases. Son **instrucciones**, no ejercicios extra.

Los bloques antiguos se descodifican sin nuevos campos. Al duplicar una
rutina iOS se regeneran también los identificadores de movimientos
referenciados por las fases. Android y la web respetan los identificadores
de movimientos ya existentes al editar.

## Escáner

El parser ligero (iOS/Android) sigue determinando cabeceras, carga,
series, alternativas y catálogo remoto. Después se añade contexto ortogonal:

- `Warm Up`, `Accessory`, `Strength`, `Metcon`: sección, no ejercicio.
- `I Go You Go`, `Syncro`, `A repartir`, `Juntos`: colaboración,
  sin reemplazar EMOM/AMRAP/For Time.
- `5min AMRAP (x3)` + `2min Rest entre AMRAPs`: tres ventanas
  de 300 s y dos descansos de 120 s; el parser conserva las instrucciones
  de continuación en notas.
- `Buy in... 400/320m Row` dentro de un AMRAP repetido: fase de buy-in
  y fase principal anidadas, con referencias a movimientos existentes.
- `TC 12:30`: 750 segundos, sin perder los minutos de lectura antigua.
- `FIND A HEAVY 1RM` / `MAX CAL`: métrica de carga/calorías, no inventar
  repeticiones. El registro de resultado iOS/Android acepta una medida
  numérica y su unidad.

La IA on-device de iOS mantiene el plan local si altera indebidamente los
límites de bloque; si pasa la validación hereda los metadatos opcionales.

## Play, relojes y resultados

- iOS y watchOS: los AMRAP repetidos ejecutan fases de trabajo/descanso
  separadas; sus datos se derivan de la instantánea del bloque activo.
- Android, Wear OS y notificaciones: comparten la secuencia y la duración
  exacta, con retrocompatibilidad para programas sin estructura.
- For Time conserva cronómetro ascendente y cap informativo. Las horas
  prescritas no se convierten en marcas realizadas.
- Max Effort puede registrar una carga en kg, calorías o metros en
  `measuredValue`/`measuredMetric`. Los resultados tradicionales
  `totalReps` y `elapsedSeconds` permanecen válidos.
- Las nuevas fases no deben generar series confirmadas ni repeticiones
  ficticias por cambio de intervalo.

## Crear, Editar y web

Los flujos existentes conservan su diseño y estado. Los metadatos nuevos
viajan en la instantánea del bloque y el borrador. Los minutos y segundos de
For Time no están asociados al descanso entre rondas. En la web Business
se conservan las fases al serializar, con limpieza de referencias a
movimientos eliminados; el editor visual avanzado de fases es una evolución
independiente y no se debe afirmar que existe.

## Limitaciones y comprobaciones

- La recogida OCR sobre fotos en dispositivos físicos y los cambios de
  reloj en tiempo real requieren validación de integración.
- Las fases avanzadas no sustituyen todavía todas las formas de fuerza
  especializadas (cluster, dropset, tempo); esas modalidades siguen usando
  prescripciones de series y notas existentes.
- La validación de esquema MCP debe publicarse junto con la Edge Function
  para habilitar nuevos campos en propuestas remotas. El cambio de GitHub
  por sí solo no despliega Supabase.
- No se han añadido nuevas tablas ni migraciones destructivas porque la
  estructura opcional viaja en el JSON existente.
