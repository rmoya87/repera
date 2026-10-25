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

El asset `mobile/src/main/assets/catalog_seed.json` contiene **196 ejercicios base**
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


## Inspección real pendiente de la cobertura UI sintética (25/10/2026)

Los tests de UI preparados (EditorUiInstrumentedTest, SplashMapInstrumentedTest,
HealthConnectInstrumentedTest, AccountScopingInstrumentedTest) están COMPILADOS,
no ejecutados: compilación y gate local no sustituyen ejecución en emulador ni
inspección de píxeles. Aunque futuros gates automáticos pasen en CI, queda
pendiente la revisión real de mapa/splash/editor y gestos (capturas + lectura
visual) antes de declarar esas pantallas validadas.

## Wear OS 6.1 (API 36.1) — estado y siguiente intento controlado (25/10/2026)

- La pata 36.1 del job `wear-instrumented` se retiró tras dos timeouts de
  arranque (600 s y 1200 s). CAUSA NO CONFIRMADA: los logs de esos runs ya no
  son accesibles vía gh (fuera del historial recuperable).
- Hipótesis «libpulse/loader» DESCARTADA como explicación suficiente: la
  acción `reactivecircus/android-emulator-runner@v2` aplica por defecto
  `-no-window -gpu swiftshader_indirect -no-snapshot -noaudio -no-boot-anim`
  (default declarado en action.yml@v2), de modo que el job Wear YA arrancaba
  con el set sano; la ausencia de `emulator-options` en el job no implicaba
  ausencia de `-noaudio`.
- Intento controlado PREPARADO (sin rerun hasta que billing vuelva): pata 36.1
  con flags explícitos (`-memory 4096 -wipe-data -verbose`), captura del log
  del emulador y de `getprop sys.boot_completed` como artefacto, timeout 1200 s.

## Corrección del extractor de catálogo y etiquetas de equipo (25/10/2026)

- `extract_catalog.py` replica ahora `SportExerciseNames.spanishAlias` con la
  tabla `englishToSpanish` completa (originales + inverso de legacy) y el
  detalle de `CatalogMovilidad.detailedInstructions`; 127 fichas pasan a
  coincidir con lo que iOS muestra (captions y descripciones curadas).
- `equipment` de «Colgado pasivo/activo» se alinea con Apple
  («Barra de dominadas»); la agrupación de filtros y las búsquedas siguen
  funcionando por normalización de subcadena, y el modo de registro no cambia
  (Movilidad ⇒ REPS_AND_TIME).
- Los `catalogId` `hyrox-*` son internos de Android: iOS emite `nil` en
  `CatalogHyrox.sportRow`, y Android los conserva para derivar UUID v3
  deterministas entre dispositivos y para deduplicar por `catalogId` o nombre
  canónico al migrar catálogos importados de iOS. No es una diferencia de
  experiencia; es identidad estable de datos (cubierto por
  `importedIosHyroxStationWithoutCatalogIdDedupesByCanonicalName`).

## Revisión después de los merges de movilidad y HYROX (23/10/2026)

- El branch incorpora mediante `d8961ad` los 39 commits de movilidad de `main`,
  y mediante `d0b998f` las correcciones posteriores de HYROX y planificación MCP.
- `mobility_seed.json` añade 82 movimientos documentados y
  `hyrox_seed.json` añade 2 estaciones, totalizando **280** con los 196 base.
- La migración local no sustituye entrenamientos/historial de clientes, es
  idempotente y conserva el UUID de estaciones HYROX importadas de iOS aun
  cuando no tienen `catalogId`.
- Las posturas sostenidas usan tiempo real y el campo
  `targetDurationSeconds` (30 segundos por defecto en el registro rápido);
  los sets sin registros reales de movilidad no se infieren de la prescripción.
- Los transportes HYROX por metros con carga guardan kg y distancia
  separadamente; la distancia no se utiliza para estimar 1RM.
- El último CI y el emulador deben quedar verdes antes de declarar la versión
  validada. En una ejecución anterior falló la instalación de Android Emulator
  en el runner y no llegó a probar la aplicación; no confundir con una
  regresión funcional del código.
- **Abierto:** cobertura real de imágenes, evolución avanzada por período,
  gestión de la suscripción, Health Services y registro WOD completo en el
  reloj, integración MCP/UI profesional y E2E con Google Auth y Drive.

## Monetización y matriz CI (24/10/2026)

Decisión registrada (Ramón, 24/10): Google Play Billing directo, sin
RevenueCat; Apple no se toca. Modelo de seguridad acordado: una compra
detectada localmente NO concede Pro hasta verificación backend
(`purchases.subscriptionsv2.get` como fuente de verdad, documentación
oficial citada en `MONETIZATION_PLAY_BILLING.md`). En producción el
provider queda **no configurado** (Gratis) hasta que exista ese backend:
la integración comercial está deliberadamente incompleta.

Implementado en rama (con pruebas locales, sin activar compras):
dominio (`SubscriptionStatus`, `CommercialSnapshot`, `ReperaFeature`,
límites Gratis, `FreeUsageLedger`, política por feature + 19 tests) y capa
mobile (`EntitlementProvider` + provider Play Billing estricto,
`FreeUsageStore` local, `SubscriptionManager`, coordinador, analítica,
`PaywallScreen` Compose modos sheet/onboarding, `ProTeaserCard`, mascota
real reutilizada de los assets de main). 6 tests JVM nuevos del store
(persistencia, idempotencia, aislamiento por carpeta, JSON corrupto).
Pendiente: activación de productos/precios/trials en Play Console
(decisión de Ramón), backend de verificación (autorización pendiente),
cableado de las decisiones en pantallas concretas y onboarding.

Matriz CI verificada con XML reales del run `40119255128` (HEAD `b4e8313`):
API 30 = 114 mobile + 6 wear; API 35 = 114 + 6; API 37.2 (Android 17
canary) = 114 mobile; Wear OS 5.1 (API 35) = 6 wear; dominio = 143 tests
JVM. Todo 0 fallos. **API 36.1 falló dos veces seguidas** con el mismo
síntoma: `system_server` muere antes de instalar los APK (`Can't find
service: package`, I/O error en /sdcard) con 6.8G libres al arrancar; la
causa raíz NO está probada (no se descarta interacción con nuestra carga
de tests). Se añadió volcado logcat crash+system al paso de fallo para el
próximo intento. **Wear OS 6.1 (36.1 firmado) sigue sin ejecución
validada** (timeout de arranque en CI). Las capturas de verificación
visual del reloj WOD apaisado y del mapa muscular se corrigieron tras
detectar en inspección que el apaisado era byte-idéntico al vertical
(constraints coaccionados) y que el mapa capturaba el placeholder de
carga asíncrona; su verificación visual queda pendiente del próximo run.

## Ubicación: pin de gym y ruta outdoor (gap abierto, 24/10/2026)

iOS tiene `WorkoutLocationTracker` (210 líneas): pin al empezar la sesión
(`capturePin` con timeout suave de 4s, no bloquea el Play), ruta GPS para
entrenos outdoor (heurística `shouldTrackRoute` por título/ejercicios:
correr/bici/caminar/trail/outdoor/ski/skate/remo outdoor), buffer con filtro
de distancia mínima 8 m, máximo 400 puntos con downsample uniforme, y tipos
de dominio `WorkoutSession.locationPin` / `routePoints` (Codable, sync
incluido). Consumidores iOS: `ReperaStore` (start/finish sesión),
`PlaceSearchSheet` (búsqueda de gym), onboarding (fila Ubicación).

Estado 24/10 21:20 — PORTADO en rama (pendiente de CI):
`WorkoutLocationLogic` de dominio (heurística con plegado diacrítico +
downsample uniforme, 5 tests JVM), `WorkoutLocationTracker` mobile con
`LocationManager`/FUSED_PROVIDER (sin dependencia nueva), wiring en
MainActivity (pin al iniciar con timeout 4s, ruta al terminar, también en el
cierre desde el reloj), permisos en el manifiesto, fila Ubicación en el
onboarding, y test instrumentado de round-trip (pin+ruta sobreviven al
finish; el espejo Supabase sigue sin recibir ubicación, paridad con
`BusinessWorkoutSyncStore` iOS). Pendiente de verificación: captura real con
ubicación SIMULADA de emulador (nunca ubicaciones reales del usuario sin
autorización). Sub-gaps abiertos: (a) `PlaceSearchSheet` — búsqueda manual
del sitio con proveedor de lugares (iOS usa MapKit; Google Places requiere
API key y facturación → decisión de coste/cuenta que elevar); (b) mapa de la
ruta en el detalle del entreno (componente de mapa por elegir).

## Gaps detectados en la auditoría de capacidades (24/10 21:25)

Contrastados contra `Apps/Repera/Sources` y `Packages/ReperaDomain` de main;
ninguno aparecía en las auditorías del 23/10.

- **Sustitución de ejercicio**: iOS tiene `ExerciseSubstitutes` (dominio) y
  `SubstitutePickerSheet`, pero SIN call sites — su propia ARCHITECTURE.md lo
  declara «UI de cambio no expuesta». Portado el dominio a Android con tests
  (24/10): **paridad alcanzada**; no hay UI que portar hasta que iOS la
  active. NO es un gap.
- **Resumen pre-inicio / gestión de sesión** (`SessionPreviewView` 205,
  usada por `RootTabView`): PORTADO 24/10 (pendiente CI): hoja
  `SessionPreviewSheet` con etiqueta de día (1:1 `dayLabel`), bloques con
  ejercicios y series objetivo, menú Editar/Borrar (con confirmación,
  `showDeleteConfirm`) y Play; tocar una rutina en Inicio abre la hoja en
  vez de iniciar directo. Además `endActiveSession(save: false)` iOS no
  existía en Android: añadido `discardActiveSession` + acción «Descartar
  entreno» (con confirmación) en las tarjetas de fuerza y WOD, deteniendo
  la captura de ubicación como iOS.
- **Heatmap de actividad** (`ActivityHeatmapView` 488, usada por
  `StatsView`): NO es gap de capacidad — Android ya tiene
  `StatsEngine.heatmapLevel/heatmapThresholds` (dominio) + `HeatmapCard`
  (rejilla semanal por cuartiles) en Progreso. Diferencias de presentación
  abiertas (fidelidad, no capacidad): iOS usa un segmented picker
  Tiempo/Volumen en UNA tarjeta (Android: dos tarjetas), franja horizontal
  en rangos cortos (Android: siempre rejilla), etiquetas de mes/día, y la
  paleta `BodyMapPalette.fill(level)` (Android: alfa escalado del primario →
  corregido a la paleta de marca el 24/10, pendiente CI).
- **Ruta cardio y análisis** (`CardioRouteComponents` 570 + dominio
  `CardioRouteAnalysis` 147, usados por `HistoryView`): PORTADO 24/10 el
  análisis (dominio 1:1 con 5 tests: distancia haversine, desnivel con
  referencia estable, perfil de altitud, splits por km) y la sección Ruta
  del detalle del historial (resumen + perfil + splits). Sub-gaps ABIERTOS:
  mapa nativo de la ruta (`HealthWorkoutRouteMap`, componente por elegir en
  la investigación autorizada), selección táctil sobre las gráficas y la
  curva de FC de la sesión (requiere el emparejado Salud↔sesión).
- **ReperaSessionMatchIndex** (91): índice temporal interno para emparejar
  sesiones Repera ↔ Salud sin escaneos O(H×G); pertenece a la familia del
  emparejado Salud↔sesión, que en Android aún no existe como función (sin
  curva de FC por sesión ni enriquecimiento con Salud). Estado: ABIERTO,
  pendiente de esa función (baja prioridad mientras no haya superficie).

## Segunda pasada de la auditoría (24/10 21:31, inventario completo de Apps)

Barrido sobre los 99 ficheros `.swift` de `Apps/Repera/Sources` contrastando
cada concepto con Android. Además de lo ya registrado:

- **`DayPlusSheet` (598)**: menú «＋» de un día concreto con alta de entreno
  suelto (editor one-off con `scheduledDate`), acceso a favoritos,
  temporizador independiente y escaneo de pizarra para ese día. En Android no
  existe el alta one-off por fecha desde Inicio (el modelo `RoutineEntry` ya
  soporta `scheduledDate`; falta la UI y el menú). Estado: ABIERTO.
- **`RegisterSwipeRevealCard` (382)**: tarjeta de registro con gesto swipe de
  revelado de acciones (UIKit). Las ACCIONES existen en Android como botones;
  el gesto es un ítem de fidelidad. Estado: ABIERTO (fidelidad, no capacidad).
- **`StartHubSheet` (376)**: contenido de la pestaña Crear en iOS; Android ya
  tiene `CreateTab`. Cobertura de opciones a contrastar en profundidad, pero
  no es un gap de superficie. Sin acción.

Recordatorio del método: el barrido es por concepto; un «Android tiene X»
exige contrastar contenido, no solo nombre (el heatmap era fidelidad, no
capacidad; los sustitutos eran paridad exacta por código muerto en iOS).

## Selector de lugar: dónde está conectado (25/10, c6603b51 y siguiente)
- Entreno activo (WorkoutView iOS): CONECTADO. Compilado + tests JVM; sin ejecución en dispositivo.
- Detalle de entreno archivado sin ruta (HistoryView iOS): CONECTADO (`setFinishedLocationPin`, no toca entrenos con ruta). Tests instrumentados nuevos `WorkoutPinEditingInstrumentedTest` (5): compilados, NO ejecutados.
- Plan (PlanView iOS, «Datos del entreno realizado» vía `onApplyCompleted`): AUSENTE. Android no tiene el flujo de marcar un plan como completado con datos editables; el selector no tiene dónde colgarse sin construir ese flujo entero. No se ha fabricado una pantalla.
- Búsqueda de POI por nombre: Photon público (`PhotonPlaceSearchProvider`) con pausa de tecleo, ≥3 caracteres, 1 petición/s, caché, enfriamiento de 120 s ante 429/5xx/timeout y caída a Geocoder + pin manual. Al exterior sale sólo el texto y el centro del mapa a 2 decimales. Política: README komoot/photon (uso razonable, sin garantías). 9 tests JVM con fixtures (ejecutados en local; ninguna petición real).

### Corrección sobre el selector de lugar (tras 30d880b0)
- En iOS, PlanView/DayEditorView con `onApplyCompleted` NO es «marcar un plan como completado»: es el editor de un entreno TERMINADO (HistoryView → «Editar»), que además tiene su propia sección de edición (nombre, inicio, fin, lugar, notas) con borrador y confirmación. Android lo porta ahora en `FinishedWorkoutEditorSection` + `WorkoutRepository.updateFinishedWorkout`: borrador local, escritura solo al Guardar, Cancelar descarta; fin < inicio => inicio + 60 s; la valoración previa se elimina; el pin solo si no hay ruta; no crea ni borra entrenos (cuota/tombstones intactos).
- Lo que NO está portado: edición de bloques/ejercicios/series reordenables dentro del editor de entreno terminado (DayEditorView completo). Android solo edita/borra series individuales. Pendiente.
- Tests: 8 en `WorkoutPinEditingInstrumentedTest` y 2 en `FinishedWorkoutEditorUiInstrumentedTest`: compilados, no ejecutados.

### Photon: fuentes, condiciones y privacidad
- Fuente de política: https://raw.githubusercontent.com/komoot/photon/master/README.md ("You are welcome to use the API for your project as long as the number of requests stay in a reasonable limit. Extensive usage will be throttled or completely banned. We do not [give guarantees]"). El README no fija cifra de peticiones, atribución, User-Agent ni contacto: no se han inventado requisitos. Los límites de la app (1 petición/s, caché, 120 s de enfriamiento) son decisiones propias conservadoras, no un umbral oficial ni una garantía de servicio.
- Atribución de datos: los datos de Photon proceden de OpenStreetMap (ODbL, atribución «© OpenStreetMap contributors»). No he verificado que la hoja de resultados de búsqueda muestre esa atribución (RouteMapView sí la muestra en su estado de error): pendiente de revisión visual.
- Privacidad: al proveedor (photon.komoot.io, tercero) salen el texto de la consulta (que el usuario puede haber escrito con una dirección exacta), el centro del mapa redondeado a 2 decimales y, como en toda petición HTTPS, la IP. La app no registra coordenadas en logs. Redondear el centro no garantiza anonimato.
- Fallo visible: si el servicio no se puede consultar (límite, caída, enfriamiento) la hoja muestra un aviso explícito de que solo se muestran direcciones y de que un resultado vacío no significa «sin establecimientos». La espera entre búsquedas se hace esperando, no descartando.
- Validación: contrato/fallback con fixtures (JVM, ejecutados). Validación contra el servicio real y en UI: PENDIENTE (no se ha hecho ninguna petición real).

### Photon: verificación 25/10 03:35 y atribución
- Términos del propio servicio (https://photon.komoot.io/ , «Terms of Use»): "You can use the API for your project, but please be fair - extensive usage will be throttled. We do not guarantee for the availability and usage might be subject of change in the future." Sin cifra, sin cuenta, sin cobro, sin atribución propia ni contacto exigidos.
- Atribución de datos OSM: https://osmfoundation.org/wiki/Licence/Attribution_Guidelines - "Geocoders that use OpenStreetMap data must credit OpenStreetMap" y "Applications that incorporate such a geocoder must credit OpenStreetMap"; forma aceptada «© OpenStreetMap contributors». La hoja de búsqueda ahora muestra «Datos de lugares © OpenStreetMap contributors» (testTag place_osm_attribution; compilado, no inspeccionado en pantalla).
- Validación de servicio: UNA petición sintética no personal («Berlin Hauptbahnhof», limit=2, sin lat/lon, UA `Repera-Android/1.0 (dev.repera.mobile)`) -> HTTP 200, `Cache-Control: max-age=3600`. La respuesta real se usa como fixture del test `parsesRealServiceResponseShape`. No se hizo ninguna otra petición.
- Cobertura POI: OSM, no Apple Maps. La cobertura/ranking de gimnasios y comercios locales NO está medida; hasta pruebas reales con búsquedas de uso previsto queda como limitación documentada, con aviso visible y pin manual de respaldo.
- Corrección: al editar un entreno terminado la valoración se RECALCULA con el motor (como attachSessionReview de Apple), no se borra; solo desaparece si el motor devuelve null. Se conserva notas y demás datos. Igual que saveWorkout iOS: sin vínculo de Salud se quita appleActiveEnergyKcal y appleDurationSeconds = max(60, fin - inicio).

### Editor de entreno terminado: contenido (DayEditorView / CompletedWorkoutEditing)
- Port en `CompletedWorkoutEditing.kt` (JSON, con ids): `blocksFrom` (≙ routine(from:)) y `applying` (≙ applying(_:to:catalog:)). 7 tests JVM con fixtures, EJECUTADOS en local: reordenar + editar conserva ids de ejercicio y de serie, el ejercicio añadido no inventa series registradas, quitar ejercicio, serie añadida recibe completedAt = finishedAt, WOD con REST y score global sobreviven, cambio de formato WOD invalida el score, ejercicio sin bloque en el snapshot.
- Editor con borrador (`FinishedContentEditor`): reordenar, quitar, añadir ejercicio (primeros 60 del catálogo), editar reps/kg, añadir/quitar series. El original no se muta; Cancelar no escribe; Guardar escribe metadatos + contenido en un único `save()`.
- NO portado / desviaciones: (1) bloques WOD solo lectura (sin editor de movimientos Android); (2) RIR no editable en la UI (se conserva); (3) `Block.plannedSets(for:)` de Apple (rellenos EMOM/Tabata/rondas) no portado: un movimiento WOD sin explicitPlannedSets conserva las series previas; (4) añadir ejercicio solo desde el menú de los primeros 60 del catálogo (sin buscador); (5) swap/arrastre: botones ↑ ↓, no drag and drop; (6) no se mueve un ejercicio entre bloques.
- Verificación: puerta local compilada; androidTest (repositorio 9 + UI 5) compilados, NO ejecutados; sin inspección de píxeles.

### Actualización: desviación (3) cerrada
- `Block.plannedSets(for:)` de Apple portado en `WodPlannedSets` (domain): explícitas mandan; ola explícita (rellenada en EMOM/circuit); EMOM/circuit repiten por rondas; Tabata reparte ventanas de trabajo entre estaciones; For Time/RFQ repiten por rondas; resto, base. 11 tests JVM por formato, EJECUTADOS en local.
- `CompletedWorkoutEditing.blocksFrom` reconstruye ahora los movimientos WOD desde las entradas (REST se conserva; preservePrescription para captura global) y `applying` deriva series con esas reglas cuando el movimiento no trae explicitPlannedSets. 9 tests JVM (2 nuevos: ids de series registradas con explícitas; derivación EMOM [10,9,8]→[10,9,8,8,8]), ejecutados.
- Siguen abiertas: buscador sobre catálogo completo, mover entre bloques, RIR editable, editor UI de movimientos WOD, arrastre (gesto) para reordenar.
