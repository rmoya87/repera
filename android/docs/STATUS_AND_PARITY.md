# Repera Android / Wear OS — matriz de paridad verificada en código

Referencia Apple: `b8f45fa50feb44e06bd09d73f37e0e257bc97a09` (23/10/2026); merge de paridad Android `e43e52b`.

La implementación Android **todavía no es completa**. La rama no altera Swift, iCloud, Xcode ni Supabase.

| Función | Situación en Android | Restricción vigente |
| --- | --- | --- |
| Cuenta Google | Inicio Credential Manager, cierre de sesión | Se necesita client ID OAuth y pruebas reales |
| Google Drive personal | Carpeta appDataFolder, permiso separado, control de conflictos y backups | Pendientes E2E y revisión multi-dispositivo |
| Importar/exportar | Selector nativo SAF JSON y exportación segura del estado local | La importación no fusiona un estado existente |
| Historial de ejercicio/rutinas | Listas reales y búsqueda bilingüe basada en 186 aliases Swift | Faltan filtros avanzados y fichas |
| Ejecutar fuerza existente | Crea sesiones reales de bloques fuerza y aumenta syncRevision | No inicia automáticamente bloques WOD |
| Registro de series | Fuerza y cardio local con calorías, metros, reps y duración, corrección y borrado | Técnicas avanzadas y flujo completo de timers pendientes |
| Reanudar sesión | Desde JSON `activeSession`, incluso tras recreación de Activity | La sesión se gestiona actualmente en el teléfono |
| Finalizar | Archiva la sesión sin duplicarla y limpia estado activo | Falta reconciliación con Health Connect |
| WOD | 14 formatos, resultados y matemáticas de reloj AMRAP/EMOM/For Time/Tabata/Circuito | Falta motor de ejecución y editor de bloques |
| Watch | Wear Material 3, lectura Data Layer, cola offline de sets de fuerza con ACK idempotente | Faltan Wear WOD, Health Services, E2E físico y sincronización de fondo |
| Actividad/Salud | Lectura explícita de pasos y energía activa reales vía Health Connect, con permisos opt-in | Resto de mediciones y E2E pendientes |
| Business | No habilitado | OAuth Google verificado por servidor, RLS y planes |
| Compras Pro | No habilitado | Play Billing/RevenueCat e id de productos |
| OCR pizarra | No habilitado | ML Kit on-device + compatibilidad del parser |

Pruebas de regresión declaradas: `domain/src/test` para reloj, WOD, presets y
conflictos; `mobile/src/androidTest` para persistencia e identidad de sesiones.
Deben ejecutarse antes de dar la funcionalidad por probada.

CI: runner operativo con Gradle 9.6 y SDK 37; la ejecución
`39931372564` pasó mobile, wear, tests JVM e instrumentados en emulador.
Los cambios de cronómetro y Diario se validan en ejecuciones posteriores.
La CI no sustituye una prueba OAuth/Drive real ni un Wear OS físico.

## Catálogo y primera cuenta

El asset `mobile/src/main/assets/catalog_seed.json` contiene **196 ejercicios**
extraídos directamente de `CatalogEnrichment`, `CatalogHalterofilia`,
`CatalogGimnasia` y `CatalogCrossFit` de Swift en `main`, sin ejercicios
ficticios añadidos. Se aplican 189 descripciones y 189 instrucciones
localizadas del diccionario `CatalogSpanish`; el resto conserva el texto
fuente a falta de portar el traductor de frases. Los ID generados son estables
por nombre dentro de Android, pero **no son los UUID aleatorios de iOS**:
el traspaso del historial se hace importando los UUID originales del JSON
exportado, no emparejando UUID generados.

`exercise_search_aliases.json` contiene 186 parejas exactas procedentes
de `ExerciseSearch.bilingualPhrases`. Búsqueda prioriza nombre exacto,
alias inglés/español y coincidencia parcial. La selección de ejercicio
inicia Apuntar series; un bloque WOD no puede transformarse de manera tácita.

Se han ejecutado CI y pruebas de emulador; véase el apartado CI superior.
Las comprobaciones de OAuth y sincronización entre dispositivos reales siguen pendientes.

## Refuerzo de seguridad y comportamiento (segunda revisión)

- Catálogo nativo original **196 movimientos** y alias bilingües **186**; el
  registro de cardio ya permite tiempo/Cal/metros y el de comba reps+tiempo.
  El editor específico de déficit HSPU y técnicas especiales continúa pendiente.
- Las rutinas con bloques WOD no se ejecutan mediante el motor de fuerza. No
  se convierten resultados de bloque en series ficticias.
- La nube conserva copias anteriores y bloquea historiales independientes
  (entrenamientos y rutinas con IDs exclusivos en ambas versiones, o sesiones
  activas incompatibles).
- Una cuenta recién inicializada con el catálogo se identifica como estado
  vacío de revisión 0 y fecha antigua. La primera sincronización prioriza el
  historial remoto real aunque el backup remoto sea legacy.
- Navegación Android usa iconografía Material y animación al actualizar
  la sesión activa. Wear muestra ejercicio y próxima serie prescrita con
  datos reales recibidos del teléfono.
- WodClock dispone de pruebas de AMRAP, For Time, EMOM, Tabata y Circuito
  basadas en `WatchSessionHub.swift`. Todavía no gobierna la ejecución
  de WOD en la interfaz.

**Advertencia:** los runners han ejecutado Gradle/SDK/emulador. No confundir
las pruebas automatizadas con validación de cuentas Google, Drive y relojes
físicos en condiciones reales.

## Salud Android (lectura observada)

Se utiliza `androidx.health.connect:connect-client:1.1.0` (estable), únicamente
con permisos de lectura `READ_STEPS` y `READ_ACTIVE_CALORIES_BURNED`.
La vista Inicio muestra las lecturas agregadas del día si existen y «—»
en ausencia de datos o permiso. Los datos de Salud **no** se vuelcan al
JSON de Repera ni a Drive/Supabase; no se generan kcal por inferencia.
El permiso se solicita sólo cuando el usuario pulsa conectar; se ofrece
explicación en la pantalla de gestión de permisos. Quedan pendientes
Health Services del reloj, operaciones de escritura y pruebas E2E.

## Captura real de bloques WOD

El port de `SessionController.from` comienza a incorporar bloques combinados
fuerza + WOD, preservando `RoutineBlock.movements` y las prescripciones
por movimiento. El motor habilita los formatos con resultado **global**
compatibles con la misma estructura `WODBlockResult` que Swift:

- AMRAP y Death By: `roundsCompleted` y `totalReps` (reps adicionales).
- Max Effort: `totalReps`, sin inventar rondas.
- For Time, Chipper, AFAP, Ladder, Buy-in/Cash-out:
  `elapsedSeconds` real que introduce el usuario.
- Tras confirmar el resultado se marcan completados todos los movimientos del
  bloque y se pasa al bloque siguiente o se archiva la sesión, exactamente
  **sin generar `loggedSets` falsos**.

El editor es inline en Inicio/Play, sin modal de resultado. El resumen
reciente incluye los resultados reales guardados. EMOM, Tabata, Circuito,
Partner, RFQ y Strength-WOD quedan bloqueados por requerir el registro
por movimiento que aún no está implementado. El cronómetro WOD del módulo
dominio **no está conectado aún al Play real**.
Se han incluido pruebas instrumentadas para For Time y fuerza + AMRAP,
pendientes de ejecución en emulador/dispositivo.

## Editor Android de rutinas y corrección de series

Desde **Crear**, Android puede guardar una rutina nativa compatible con Swift
`Routine` y `RoutineBlock`, formada por ejercicios reales del catálogo.
Tipos iniciales: Fuerza (series/reps y peso opcional), AMRAP (tiempo y
movimientos) y For Time (rondas, time cap informativo y movimientos).
El usuario selecciona ejercicios reales y los incorpora a la plantilla; no
se añaden sesiones terminadas ni objetivos de salud supuestos.

Durante Play fuerza, el usuario puede **editar una serie ya registrada**
sin duplicarla: `id`, `completedAt` y orden se mantienen y `completedReps`
se recalcula con las series confirmadas. El resumen Inicio muestra resultados
WOD registrados o el número real de series de cada entrenamiento.

Se han definido pruebas instrumentadas de creación y ejecución de rutinas
de fuerza y AMRAP desde el catálogo nativo; no se han ejecutado en Android
por la limitación de runner documentada. El editor completo por movimiento
y la programación de sesiones siguen pendientes.

## Campos fuerza: RIR y calentamientos

Se añadió `rir` opcional a la serie confirmada y la fase `work/warmup`,
siguiendo `LoggedSet` / `SetPhase` Swift. Las series de calentamiento se
muestran en Play y se guardan, **pero no consumen objetivos de trabajo ni
aumentan `completedReps`**. El prefill de la próxima serie depende solo
del número de series de trabajo realmente confirmadas.

La revisión inline permite ajustar reps/peso manteniendo identidad, fecha,
fase y RIR ya guardados. Quedan pendientes la revisión específica de fase/RIR,
la presentación RPE alternativa, dropsets y rest-pause. Hay un test de
persistencia con una serie de calentamiento y otra de trabajo, todavía sin
ejecutar en dispositivo Android.

## Histórico detallado (Inicio)

La tarjeta de cada sesión archivada abre un resumen que incluye las
puntuaciones globales WOD y el detalle por ejercicio, con navegación
«Volver al resumen». Los valores se construyen exclusivamente desde
`WorkoutSession.wodResults` y `SessionExercise.loggedSets` persistidos.
Se muestran reps, unidades de máquina, kg, fase de calentamiento y RIR
cuando figuran en el JSON. Los movimientos de un WOD con score global
no se anuncian como series vacías: se indica que existe puntuación por
bloque. Se añadió aserción instrumentada de For Time `6:27` y dos
movimientos sin series ficticias.

Pendiente: gráficos completos, filtrado diario/calendario, miniaturas,
estadísticas avanzadas y pruebas de interacción instrumentadas en
dispositivos reales.

## Actualización frente al main iOS (23/10/2026)

Se integró `main` en la rama Android en el commit de merge `ff55c09d`
sin reescribir archivos Swift: nueva base Apple
`10841411bfb8c9bf2e4aff2ae53e9927f3e584ea`.
Se revisaron `ExerciseSearch.bilingualPhrases` (186 equivalencias)
y `CatalogSpanish` (190 descripciones y 190 conjuntos de instrucciones);
las entradas del asset Android coinciden con las definiciones correspondientes
tras la actualización de iOS. Las modificaciones más recientes del escáner
Swift siguen pendientes de port completo a Android.

En Wear OS, la sesión recibida muestra los movimientos y objetivos reales
del bloque WOD, junto con su modalidad, en vez de poner «0 series» para un
resultado global. Se mantiene como vista de **solo lectura**: no implica
registro autónomo ni sustitución de WatchSessionHub.

## Temporizador WOD visible en Play Android

El Play de WOD global muestra el tiempo activo como cronómetro de cuenta ascendente
(For Time y similares) o cuenta atrás por formato/intervalo según el motor
`domain/WodClock`. Los botones nativos Iniciar/Pausar/Reanudar/Reiniciar
guardan el tiempo usando `SystemClock.elapsedRealtime` y preferencias
aisladas por cuenta y sesión. Al reiniciar el dispositivo se pausa el
cronómetro en vez de inventar tiempo de entrenamiento. En For Time,
«Usar tiempo del cronómetro» copia el tiempo medido al editor de resultado
y exige confirmación explícita: ningún tiempo medido se guarda como un
resultado de sesión sin confirmación.

Limitaciones restantes: la misma lógica de cronómetro todavía no se transmite
como control bidireccional a Wear OS; los formatos WOD de registro por movimiento
siguen bloqueados. El CI incluye tests instrumentados de pausas, reanudación
y aislamiento entre cuentas.

## Programación por fecha (Diario Android)

Se han portado los campos nativos Swift `Routine.weekday`,
`Routine.scheduledDate` y `Routine.scheduledTimeMinutes`. Crear permite
rutina sin fecha, para un día concreto o patrón semanal, más una hora
opcional. El Diario distingue entrenamientos de hoy, fechas concretas,
programación semanal y biblioteca, mostrando solo rutinas almacenadas reales.
Las fechas se codifican como inicio de día de la zona horaria local y se
recuperan desde ISO-8601. Pendiente: integración con programas IA y
planificaciones profesionales, edición/reprogramación y vistas de calendario
más avanzadas.

## Incremento verificado en rama (23/10/2026)

La ejecución GitHub Actions `39935572402` terminó con conclusión `success`
para el commit `cf1255e`. Incluye pruebas de registro, persistencia,
corrección y eliminación de movimientos en WOD por intervalos. No sustituye
pruebas con Wear OS real o sesiones Google reales.

Desde `172045f`, Play propone automáticamente el número de intervalo de
EMOM y Tabata según el cronómetro monotónico. Al editarlo manualmente se
respeta la selección del usuario; el avance del reloj nunca guarda repeticiones
ni marca movimientos como realizados. Este último cambio requiere superar
su propia ejecución de CI.

**Pendiente para paridad real**: pruebas E2E Android/Google Drive, registro
autónomo y conciliación del reloj sin teléfono, servicio de ejercicio y
sensores Wear, panel completo de Progreso, OCR ML Kit, planes profesionales,
facturación Google Play y distribución firmada. Nada de esto debe describirse
como completado.


## Revisión posterior y límites (23/10/2026)

La rama integra mediante `e43e52b` las 59 correcciones del `main` auditado.
Los commits Android posteriores incorporan: sets efectivos en sesiones terminadas
(sin inventar series WOD), indicadores por ejercicio sobre todo el historial,
editor para eliminar series de fuerza, exportación JSON, calendario semanal con
selección persistente y barras de progreso semanal ajustadas a hora local.

Wear añade envío de series de fuerza con una cola local y ACK del teléfono,
con validación de sesión y deduplicación por UUID. Esta solución **no** ofrece
sincronización en segundo plano cuando la Activity Android está cerrada.

La ejecución CI `39959971235` sobre `e8e4f3d` terminó satisfactoriamente.
El último commit de rama debe validarse por su propia ejecución de Actions;
no considerar validados los cambios posteriores por una ejecución anterior.
Quedan E2E OAuth/Drive, pruebas de hardware Wear, medidas Health Services,
Pro/billing, OCR, MCP/planificación profesional, UI completa de progreso y
paridad visual. El documento actualizado `PARITY_BACKLOG_2026_10_23.md`
detalla los criterios de aceptación.


## Actualización de registro y validación (23/10/2026)

El dominio Kotlin ahora soporta unidades de cardio equivalentes a Swift:
`calories`, `meters` y `reps`, además de `durationSeconds` opcional.
Play permite corregir o borrar los registros locales; el historial muestra
los tiempos y Progreso calcula los mejores resultados de cada unidad.

El protocolo Wear diferencia finalizar la sesión de cerrar sesión: sólo
este último solicita borrar la cola de sets pendientes y la caché del reloj.
Sincronización en segundo plano, WOD por movimiento y prueba con dispositivo
real continúan pendientes; lo implementado **no** constituye paridad completa.

Últimos tests instrumentados de cardio: `CardioRecordInstrumentedTest`.
El CI debe comprobarse en el HEAD actual; sus ejecuciones anteriores no
certifican commits más recientes.
