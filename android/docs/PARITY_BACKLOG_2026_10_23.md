# Paridad Android/Wear — revisión contrastada, 23/10/2026

## Refs comprobadas

- iOS `main`: `b8f45fa50feb44e06bd09d73f37e0e257bc97a09`; 59 commits desde la base común `864650c`.
- Android/Wear antes de integrar: `40a680bc3379b35b1e634c3271ea2d1154d856a1`; 60 commits propios.
- Merge no destructivo: `e43e52b` incorpora la historia de main y conserva el árbol Android y su workflow.
- GitHub Actions Android `39948430912`: compilación phone+wear, tests de dominio y tests en emulador, correctos en el head anterior al merge.
- CI main `39954688280`: fallo **Docs touchpoints** y **ReperaDomain swift test**; build XcodeGen de iOS/watchOS y pruebas UI sí pasan. No confundir build con validación global.

## Cambios recientes Apple que deben gobernar la paridad

| Commits main | Contrato observable de producto | Traducción Android |
|---|---|---|
| `b8f45fa`, `c1f5148`, `85c2614`, `fa1463b` | Mostrar todas las series prescritas aceptadas en entrenamientos finalizados sin logs reales; repercutir en detalle/estadísticas de ejercicio | Resolver registros efectivos **solo para sesiones finalizadas** sin escribir series inventadas en JSON; integrar en Progreso por ejercicio, PR, e1RM y métricas |
| `d217d70`, `d1f62d4`, `83dd2e2` | No ocultar sets registrados porque igualan score WOD; mostrar resultado una sola vez y alinear filas al título | Conservar loggedSets, un único score por bloque y filas compactas |
| `433c621`, `aea2591` | Recuperación sin recargas recurrentes ni parpadeos | Health Connect estable, flujos con cache y actualización diferencial |
| `5773b29`, `510ca2a`, `4eece72`, `1764dd5` | Relojes grandes, pre-cuenta independiente, pausa/reanudación, disposición adaptable | Máquina de estados de timer con tests de reloj monotónico, pre-cuenta y pausa en Compose |
| `52310ee`, `b2b5121`, `3045fb7`, `5058f75` | Paisaje, calendario siete días, márgenes y splash | Compose adaptativo WindowSizeClass, orientación y edge-to-edge según sistema |
| `21e26ff`, `06884b8`, `c3d2f24` | Logout anula recuperación de caché antigua y exige identidad propietaria | Google/Supabase sesión durable con cache ligada al `userId` verificado y sin mezcla de cuentas |
| `df76e24` | Catálogo traducido y técnicas completas de nuevas entradas | Actualizar seed/aliases y descripciones Android desde Swift; preservar identificadores |

## Inventario inspeccionado

`android/mobile` contiene MainActivity, una pantalla Compose de ~1.000 líneas, repositorio local JSON, cronómetro WOD, sincronización Google Drive, Health Connect solo pasos/calorías y puente Data Layer de salida. `android/domain` contiene WODClock, reglas de WOD, conflictos y búsqueda bilingüe. `android/wear` contiene una única Activity y escucha Data Layer: refleja la sesión activa, cache offline solo lectura; sin escritura autónoma, Health Services ni compensación.

## Bloqueos prioritarios (no marcar completos hasta sus pruebas)

**P0 — corrección y seguridad:**
1. Autenticación Google con refresh, logout coherente, propiedad de datos Supabase y E2E real entre móviles; evitar mezcla Google Drive/iCloud.
2. Importación/exportación portable y conflictos bidireccionales de sesiones, rutinas y planes, con reversión y recuperabilidad.
3. Paridad de todos los formatos de WOD, selección y edición por movimiento, RIR/RPE, calentamientos, técnicas especiales y edición de sesión terminada.
4. Verificar CI actual de iOS (dos jobs rojos) y Android tras cada integración; escenarios reales de reloj emparejado.

**P1 — función del atleta:**
5. Progreso: periodos/filtros, e1RM, máximos, frecuencia, PR, equilibrio muscular, zonas y recuperación sin flashes; mismo motor de registros efectivos que historial.
6. Pantallas Inicio, Diario, Crear y Ejercicios equivalentes; navegación/detalles, miniaturas, widgets contextuales, fechas y planificaciones.
7. Wear: sesiones offline de escritura, temporizador/control bidireccional, reconciliación por ID de set, Health Services, pausas, haptics y errores de red.
8. Escaneo de pizarra con ML Kit y parser equivalente al iOS; validación bilingüe.

**P2 — integraciones y distribución:**
9. Conexión MCP, mensajes Realtime, planificaciones IA/profesionales y autorización RLS.
10. Suscripciones Play Billing, restauración, restricciones Gratis/Pro y protección de entitlement.
11. Accesibilidad, TalkBack, Dynamic Color coherente con la marca, tablet/plegable, landscape, rotación; notificaciones, permisos y consumo de batería.
12. Firma, Play Console, pruebas en varios dispositivos, monitorización de fallos y versión de datos/migraciones.


- Material 3 claro y oscuro comparten el verde de marca `#30D158` con contenido negro para acciones primarias; no usar el verde oscuro y texto blanco de la base previa.

## Criterios de cierre

La paridad no es un porcentaje inventado: requiere matriz por comportamiento y resultado entre iOS 27 y Android 17, pruebas contractuales para cada WOD/unidad/estadística, E2E Google/Supabase/Drive, pruebas con reloj físico y CI verde después de integrar. En la revisión actual **no se afirma equivalencia funcional ni ausencia de bugs**.

### Incremento de métricas base

`ExerciseProgressMetrics` recorre **todo** `workouts` (no las últimas 20) y calcula apariciones, récord de carga, reps, Cal, metros y e1RM Epley con sets efectivos, excluyendo calentamientos y WODs de score global sin registros. La ficha de catálogo permite consultar el resumen gratuito de última sesión y récords. La visualización de e1RM, series temporales y frecuencia avanzada queda pendiente de control real de entitlement Pro y gráficos nativos. Se añaden tres pruebas instrumentadas.

### Incremento de esta auditoría

El lector `WorkoutHistorySets` aplica fallback de sets prescritos terminados **solo en memoria**, conserva warmups reales, unidades Cal/metros, RIR y WOD globales sin series falsas. La prueba instrumentada protege estos invariantes. Para estadísticas agregadas faltan portar `StatsEngine.effectiveWorkSets` a un motor transversal Android, no reimplementar reglas diferentes por pantalla.


## Incremento Wear: registro de fuerza con cola offline

- `WearPendingSetStore` conserva el UUID de cada acción y su prescripción local mientras no hay confirmación del teléfono; no muestra la serie como sincronizada antes de recibir ACK `saved`.
- `MainActivity` acepta mensajes **solo con login Google/Supabase validado y Activity activa**, y `WorkoutRepository.logWearSet` protege UUID, sesión, índice y ausencia de duplicados, incluso tras archivar.
- El reloj reintenta al abrir la actividad, recibir una sesión y al pulsar Reenviar. Al cerrar sesión recibida limpia la cola por privacidad.
- **Limitación explícita:** aún no hay reconciliación automática en segundo plano sin abrir el teléfono, Health Services ni captura Wear de WOD por movimiento. No considerar Watch al nivel de Apple hasta completar E2E físico.
- CI: nuevas pruebas de idempotencia tras reinicio, duplicados y rechazo de sesiones ajenas. No extrapolar tests Android Emulator a un Wear físico.


## Paridad adicional incorporada tras la auditoría

- Android Play permite eliminar sets de fuerza sin tocar los demás registros.
- El menú de cuenta exporta un JSON local validado mediante el selector de
  documentos de Android (sin subirlo automáticamente a ningún servidor).
- Diario usa calendario de siete días con saltos de semana y conserva la
  selección de fecha al recrearse la Activity; sigue pendiente la edición de
  programación y planes profesionales.
- Progreso muestra barras de las siete fechas actuales y cuenta sesiones
  del historial completo usando la zona horaria local, sin fabricar actividad.
- Progreso por ejercicio calcula mejor carga, reps, calorías, metros, e1RM y
  veces a partir de sets efectivos. Esto NO significa tener las pantallas de
  evolución/periodos/pro/recuperación equivalentes a iOS.
- Los tests de regresión revelaron un error real en For Time (prescripción de
  WOD leída como serie). Corregido con `e8e4f3d`, CI `39959971235` verde.
- El último head requiere siempre verificación independiente del CI y de
  dispositivos Google reales; ningún feature sin E2E debe marcarse production-ready.

## Incremento cardio / protección de datos del reloj

- `ExerciseInput` porta las unidades por defecto iOS para máquina/carrera/comba:
  Bike/Ski → calorías; Remoerg/Carrera → metros; Comba → reps + duración.
  El selector de unidades sólo se ofrece para máquinas compatibles.
- El registro persistido guarda `LoggedSet.quantityUnit` y `durationSeconds`
  conservando JSON compatible con ReperaDomain; admite corrección explícita de
  cantidad/unidad/segundos y alimenta mejores cal/meters en Progreso.
- Android Wear no permite registrar estos ejercicios con un campo de reps erróneo:
  informa que requieren edición en el teléfono; únicamente confirma ejercicios
  `loadAndReps` y `repsOnly` conocidos.
- Sesión terminada ≠ logout: la primera limpia la pantalla de sesión activa
  conservando la cola de series pendientes; un logout explícito solicita borrado
  de cola y caché mediante bandera `signedOut` en Data Layer.
- Limitación: un logout realizado sin conectividad puede no llegar al reloj
  hasta que se restablezca la conexión; pendiente de endurecimiento de identidad
  en datos del wearable y servicio de fondo.
- El registro de calorías/metros/duración y la corrección se protegen con tests
  instrumentados. Paridad no implica E2E aprobado hasta CI verde en el último head.


## Registro cardio completo en este incremento

Se ha habilitado el registro básico nativo de máquinas y comba, con unidad
elegible cuando corresponde y duración opcional en segundos. El JSON mantiene
`LoggedSet.reps`, `quantityUnit` y `durationSeconds` como campos separados,
y permite corregir o borrar un tiempo sin cambiar las demás series. La métrica
de mejor duración usa el mismo histórico completo que cal/meters, excluyendo
calentamientos; no se inventan series de WOD con puntuación global.
Los tests de `CardioRecordInstrumentedTest` cubren SkiErg, carrera, comba,
revisiones, borrado de duración y contribución a Progreso. El último HEAD
requiere validación de CI y de dispositivo real antes de marcarlo estable.


## Historial completo por ejercicio (paridad de acceso gratuito)

`ExerciseSessionHistory` construye una línea temporal por UUID de ejercicio
con todas las visitas (no sólo las últimas 20), fusiona bloques repetidos
en una misma sesión y muestra todas sus series reales o las prescripciones
aceptadas en sesiones terminadas. Los WOD que sólo tienen score global no
se convierten en series de movimiento. En Ejercicios el usuario puede expandir
las primeras cinco visitas o desplegar todas, con fechas y cantidades.
El histórico es gratuito, mientras que la futura gráfica avanzada deberá
respetar la suscripción Pro como en iOS. No se afirma equivalencia del motor
de equivalencias de ejercicios de Swift ni de la interfaz avanzada de Progreso.


## Seguimiento del catálogo iOS del 23 de octubre: 280 movimientos

Nuevos commits de iOS incorporados a la rama: 39 de movilidad y un segundo
bloque de cambios sobre HYROX y MCP multidisciplina. El catálogo Android se
alimenta de los 196 ejercicios base + 82 movimientos de movilidad + 2 estaciones
HYROX adicionales, con técnicas españolas, alias bilingües, UUIDs estables y
migración idempotente que respeta las identidades existentes de Apple.
`catalogId` de los dos ejercicios HYROX es un identificador de migración
Android; el catálogo Swift usa `catalogId=nil` en `sportRow`, por lo que el
importador evita duplicados por nombre canónico.

Los registros de movilidad miden tiempo y/o repeticiones; los holds tienen
30 segundos prescritos por defecto pero jamás suman tiempo sin ser confirmados.
HYROX integra distancia y carga sin e1RM ficticio. La clasificación muscular
de movilidad se excluye del reparto de series de fuerza: esto **no** es una
medición de fatiga clínica.

Pendientes para completar paridad real: motor de recuperación y gráficos,
miniaturas revisadas visualmente, flujo de planificación profesional/MCP,
Pro en Play Billing, registro en reloj de cardio y WOD por movimiento,
Health Services, autorización durable y reconciliación en segundo plano,
permisos y pruebas E2E físicas.
