# Estructura componible de entrenamientos — v1 (12/11/2026)

Última actualización: 2026-11-13 (sin editor de estructura avanzada en UI).

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
For Time no están asociados al descanso entre rondas. En iOS, Android y
web Business **no hay editor de estructura avanzada** (fases/sección/técnicas):
añadía complejidad sin valor. Las fases y `structure` siguen existiendo como
metadatos opcionales del escáner/remoto y se conservan al serializar, con
limpieza de referencias a movimientos eliminados.

## Limitaciones y comprobaciones

- La recogida OCR sobre fotos en dispositivos físicos y los cambios de
  reloj en tiempo real requieren validación de integración.
- Las fases de fuerza ya admiten `WorkoutStrengthTechnique` opcional para
  superseries, triseries, giant sets, cluster, dropset, rest-pause, tempo
  e isométricos, con prescripción tipada y conservación en las series.
  Las métricas de descanso y la ejecución automática de cada subtécnica
  requieren dispositivos para comprobar su comportamiento efectivo.
- La validación de esquema MCP debe publicarse junto con la Edge Function
  para habilitar nuevos campos en propuestas remotas. El cambio de GitHub
  por sí solo no despliega Supabase.
- No se han añadido nuevas tablas ni migraciones destructivas porque la
  estructura opcional viaja en el JSON existente.

## Ampliación transversal — 13/11/2026

- **Resultados por fase y por atleta:** `WorkoutPhaseResult` incluye fase,
  iteración, atleta 1/2 y movimiento opcional, con repeticiones/rondas/tiempo
  o medición tipada. Se guarda como `phaseResults[]` junto al resultado
  anterior del WOD, sin crear una actividad por fase ni confirmar series
  artificiales. Los resultados antiguos sin esta clave siguen abriendo.
- **Crear/Editar/Play/Business:** sin UI de fases jerárquicas ni técnicas
  avanzadas; Partner y Max Effort siguen con selectores de modalidad/medida.
  Los metadatos `structure` existentes se conservan al guardar, reabrir o
  duplicar.
- **Comparadores:** incorporan límite exacto y modalidad/estructura; las
  marcas de carga/calorías/distancia tienen comparación tipada sin convertir
  kilogramos decimales a repeticiones.
- **Supabase/MCP:** `schema.ts` admite `plannedSets[].technique` y
  `structure.phases[].technique`. Se mantienen idénticos los 14
  identificadores y el contrato de autenticación OAuth vigente.
- **Persistencia:** no se necesita crear nuevas tablas SQL porque las
  prescripciones y `wod_results` existentes son JSONB. La función MCP
  debe desplegarse con todas sus dependencias y el mismo modo de
  verificación JWT de producción.
- **Validación física:** comprobar interrupción/continuación en intervalos,
  dos atletas, series avanzadas, reloj, edición de marcas y sincronización.
  No dar por validados estos puntos únicamente porque se haya fusionado
  el código.

## Registro desde los relojes — 13/11/2026

- **Apple Watch:** en revisión de bloque se selecciona la unidad de Max
  Effort definida por la prescripción y se registran kg, calorías o metros.
  Las cargas admiten pasos de 0,5 kg. Los parciales de AMRAP y equipo se
  guardan explícitamente por fase/iteración/atleta y no completan el WOD.
  El resultado final conserva los parciales ya anotados.
- **Wear OS:** la misma pantalla de revisión ofrece valor máximo y parciales
  por intervalo/atleta. Para sesiones iniciadas en el reloj, los datos se
  conservan en su snapshot protegido. Para sesiones del teléfono, se usa el
  canal existente `/repera/wod-score` con `phaseResult` opcional y
  validación de sesión activa en el teléfono; no se añade una nueva ruta
  capaz de duplicar series o finalizar automáticamente.
- **Retrocompatibilidad:** un WOD sin `structure` o sin métrica tipada
  mantiene el score clásico. Los relojes no inventan la unidad de una
  prueba máxima a partir de las repeticiones.
- **Pruebas:** `tests/test_watch_advanced_wod_contract.py` comprueba la
  conexión de las pantallas con el almacenamiento y los canales, pero no
  sustituye la compilación de watchOS/Wear OS ni una prueba real de
  interrupciones, sesión offline o reconexión.
