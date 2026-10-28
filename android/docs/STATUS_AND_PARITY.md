# Repera Android / Wear OS — matriz de paridad verificada en código

Referencia Apple + Android en la misma línea: `origin/main` (2026-10-28, merge
`App-android` + leftovers); P0 `#119` y leftover `#121`/`#122`/`#124`/`#125`/
`#127`/`#129`/`#131` (ownership Play Apple-parity) en main.

**Última actualización:** 2026-10-28 — UI paridad visual ~100% (solo diffs plataforma: M3 nav, MapLibre, Health Connect, Icons.Filled) (Play/session, editores, detalle,
historial, permisos/onboarding, cards secundarias → Repera*); `#136`/`#137`/`#138`
en main; ownership Play (#131); sin clima Android; POI = Places si gratis else Photon.

La implementación Android **todavía no es completa** (E2E hardware / Play Console /
Edge migrate+deploy). Billing Play **alineado** (cliente + verify + ownership).
Sin clima en Comenzar Android (`weather_android: none`).

| Función | Situación en Android | Restricción vigente |
| --- | --- | --- |
| Cuenta Google | Credential Manager + badge; cierre de sesión; **Eliminar mi cuenta** → `repera-delete-account` | E2E OAuth + borrado real con Edge desplegado |
| Google Drive personal | appDataFolder + If-Match con ETag del GET media | E2E multi-dispositivo |
| Importar/exportar | SAF JSON + CSV Strong/Hevy con columna `weight_lbs` → kg | Import JSON no fusiona estado existente |
| kg/lb | `WeightUnit` dominio + UI Play convierte presentación; storage siempre kg | QA dispositivo |
| Temporizador libre | Última config, Guardar/Descartar, `timerDetails` en historial, foco día Inicio | QA dispositivo; menú Create sheet iOS fino |
| Historial de ejercicio/rutinas | Listas reales y búsqueda bilingüe | Filtros avanzados / fichas |
| Ejecutar fuerza existente | Sesiones reales fuerza + WOD | — |
| Registro de series | Fuerza/cardio + RIR/RPE + drop/RP (Play + Wear) + kg/lb | UX fina vs iOS; QA Wear físico |
| Reanudar sesión | JSON `activeSession` | Sesión en teléfono |
| Finalizar | Archiva sin duplicar | HC E2E |
| WOD | 14 formatos + relojes; editor finished Cal/m + HSPU/repsAndTime; plan series por movimiento | Reloj landscape OK; Live Activity N/A |
| Watch | Plan hoy + fuerza ACK + drop/RP + WOD Confirmar + **clock local offline** | Health Services E2E; físico |
| Actividad/Salud | Lectura Inicio + escritura HC + distancia opcional en permiso | E2E HC |
| Business / Center | Notice 12h + Actualizar + linked filter + RPC contracts fake | E2E Supabase real |
| Compras Pro | Play Billing + verify Edge **alineado** | E2E compra real / testers |
| OCR pizarra | ML Kit + lite + preprocess oscuro + EXIF | QA cámara |
| Widgets phone | No (iOS phone tampoco tiene home widgets) | — |

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
  Déficit HSPU: labels plan/historial + prefill QuickLog/live rows; técnicas
  drop/rest-pause en Play y Wear (draft/outbox/ACK con setId).
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
  `StatsView`): FIDELIDAD PORTADA (25/10): `ActivityHeatmapCard` en
  `ProgressCharts.kt` — UNA tarjeta con selector segmentado Tiempo/Volumen
  (SingleChoiceSegmentedButtonRow), franja de días con etiquetas en
  Hoy/Semana, rejilla por semanas (lunes) con gutter L/X/V, etiquetas de
  mes, scroll horizontal al final, hoy con borde y futuro al 25%
  (HeatmapGrid/HeatmapLayout.resolve portados). Corrección 25/10 (main):
  el gutter derivaba de las filas (7×(cell+gap) vs 7×cell+6×gap) y las
  etiquetas fijas ["", "L", "", "X", "", "V", ""] de iOS solo cuadran con
  semana que empieza en domingo — con lunes etiquetaban mar/jue/sáb;
  ahora se calculan del weekday REAL de la fila (L/X/V = lun/mié/vie) y el
  gutter usa spacing=gap. Modelo extraído a buildHeatmapGrid puro con
  fixture JVM de fechas reales (HeatmapGridModelTest 5/5: hoy domingo en
  última columna fila 6, columnas empiezan en lunes, futuro solo tras hoy,
  etiquetas ago/sept, franja lun-dom). VERIFICADO POR PÍXELES
  (25/10, run 40185662289): franja con 7 días + etiquetas + hoy con borde;
  rejilla 90d con gutter L/X/V, etiquetas ago/sept/oct y hoy con borde;
  cambio de métrica a Volumen con leyenda. Capturas:
  heatmap_franja_semana, heatmap_rejilla_90d, heatmap_rejilla_volumen.
  Histórico: Android ya tenía
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

- **`DayPlusSheet` (598)**: menú «＋» de un día concreto — **PORTADO**: one-off
  con `scheduledDate`, favoritos, temporizador, y escaneo de pizarra al día
  (`escaner?fecha=` → `createRoutineFromScan` con schedule). Timer/favoritos
  sin fecha (igual que iOS DayPlus).
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
- ~~NO portado (histórico 24–25/10)~~: WOD solo lectura, RIR no editable, sin buscador, solo ↑↓, sin mover entre bloques — **SUPERSEDED**. Ver secciones siguientes + «Leftovers shippables 2026-10-28».
- Verificación: puerta local compilada; androidTest (repositorio 9 + UI 5) compilados, NO ejecutados; sin inspección de píxeles.

### Actualización: desviación (3) cerrada
- `Block.plannedSets(for:)` de Apple portado en `WodPlannedSets` (domain): explícitas mandan; ola explícita (rellenada en EMOM/circuit); EMOM/circuit repiten por rondas; Tabata reparte ventanas de trabajo entre estaciones; For Time/RFQ repiten por rondas; resto, base. 11 tests JVM por formato, EJECUTADOS en local.
- `CompletedWorkoutEditing.blocksFrom` reconstruye ahora los movimientos WOD desde las entradas (REST se conserva; preservePrescription para captura global) y `applying` deriva series con esas reglas cuando el movimiento no trae explicitPlannedSets. 9 tests JVM (2 nuevos: ids de series registradas con explícitas; derivación EMOM [10,9,8]→[10,9,8,8,8]), ejecutados.
- Cerradas en el editor de contenido: RIR editable por serie, mover fuerza↔fuerza y fuerza↔WOD, buscador sobre TODO el catálogo (`foldForSearch`), editor UI de movimientos WOD, long-press + drop + autoscroll (ver «Arrastre long-press»).
- ~~Siguen abiertas (histórico)~~ buscador / mover / RIR / editor WOD / solo ↑↓ — **CERRADAS** en tip 2026-10-28. Residual: QA táctil en dispositivo (no código).

### Editor de entreno terminado: bloques y movimientos WOD
- `EditorBlockOps` (JVM, 8 tests ejecutados): conversión fuerza↔WOD con la regla de Apple (movimiento→ejercicio descarta weightFemaleKg, scaleAlternative, notes y repScheme; REST no se convierte), mover/ordenar bloques, `writeSetsToMovement`, round-trip de campos WOD por `applying`.
- UI: renombrar/ordenar/quitar/añadir bloque, formato WOD, editor de movimientos (REST, nombre, series, Cal/m, HSPU déficit, repsAndTime Veces+seg, peso H/M, escala, notas), Mover entre cualquier bloque. androidTest COMPILADO, no ejecutado; sin inspección visual.
- ~~Abierto (histórico)~~ long-press solo ↑↓ / plan sin ids WOD / custom abort — **CERRADO** (ver long-press + PLAN + pending customs). Residual: QA dispositivo.

### Editor de PLAN con identidad (gap e)
- `RoutineBlockDraft/RoutineDraftEntry/PlannedSetDraft` llevan blockId/itemId/set id y el JSON original (campos al final, sin romper llamadas posicionales). `buildBlock` parte del JSON original: conserva ids, REST, peso M, escala, notas, restSeconds, series y RIR por serie. Si cambia la prescripción de un movimiento WOD, descarta SOLO explicitPlannedSets/repScheme/reps-cal-m previos y reescribe la cantidad. Series de fuerza no uniformes sin tocar se escriben tal cual.
- Tests instrumentados (2) COMPILADOS, no ejecutados.

### WOD→fuerza sin ejercicio en catálogo (borrador)
- Apple crea el ejercicio personalizado en el momento del drop (persiste ya). Android lo difiere: el borrador lleva `exerciseId = pending:<nombre>`; solo `updateFinishedWorkout` (Guardar) reutiliza el del catálogo por nombre o lo crea (isCustom, grupo «Otros») en la MISMA escritura. Cuota: lambda `canCreateCustom` (SubscriptionManager); si se deniega lanza antes de tocar nada. Cancelar no persiste nada. Diferencia consciente respecto a Apple (pedida por el dueño del encargo vía main).
- JVM ejecutado: EditorBlockOpsTest 9/9. Instrumentado compilado, no ejecutado: pendingCustomExerciseIsCreatedOnlyOnSaveAndRespectsQuota.
- Lote: varios `pending:` en un Guardar se normalizan (sin mayúsculas/diacríticos, como la búsqueda de catálogo), se deduplican, y la capacidad del lote completo se valida UNA vez antes de crear nada (`canCreateCustom(existentes + nuevos - 1)`). La escritura es única (`save(state)` al final): si falla o se deniega, no queda catálogo parcial ni cuota consumida; un reintento reutiliza por nombre y no vuelve a pedir cuota. Instrumentado compilado, no ejecutado.
- Editor WOD: RIR por serie (no máquina) y campo «Peso H» que aplica solo a series sin peso (como applyMovementWeightToEmptySets); «Peso M» escribe weightFemaleKg.

### Arrastre long-press (gap a, parcial)
- Asa «⠿» por ejercicio de fuerza y por movimiento WOD: `detectDragGesturesAfterLongPress`; mientras se arrastra solo se traslada la fila (graphicsLayer, sin recomponer el contenido) y al soltar se aplica UN reorden (`EditorBlockOps.reorder`). Destino por regla del punto medio sobre alturas reales (`dragTargetIndex`, JVM ejecutado). Los botones ↑↓ conviven.
- Arrastre de bloques completos añadido (asa en el título del bloque). NO hecho: soltar un ítem en OTRO bloque arrastrando (hoy: Mover). Tests de gesto (2) compilados, no ejecutados; el comportamiento táctil real no está verificado.
- Soltar entre bloques (dropDestination de Apple): al soltar se usa el centro de la fila arrastrada en coordenadas de raíz; bloque destino por geometría registrada (`EditorGeometry`), posición por el primer ítem cuyo centro queda debajo (`dropBeforeId`); bloque vacío = al final; fuera de todo bloque = drop inválido (no cambia nada); REST→fuerza o id sin resolver = rechazado sin quitar. Reutiliza `moveItem` (conversión fuerza↔WOD). JVM ejecutado: geometría y `handleItemDrop` (13/13). Autoscroll durante el arrastre: NO implementado (el editor no controla el scroll del contenedor); gestos instrumentados compilados, sin ejecutar.
- Autoscroll continuo (implementado, NO verificado en ejecución): `LocalDragAutoScroller` (HomeTab y ProgressTab lo proveen desde su `LazyListState` con `dispatchRawDelta`). Mientras dura el arrastre un `LaunchedEffect(dragging)` avanza por fotograma con velocidad `autoScrollSpeed` (rampa lineal en 96 dp de cada borde de ventana, tope 12 dp/fotograma), compensa `dy` con lo consumido para que la fila siga bajo el dedo, y se cancela solo al soltar/cancelar/salir de composición (sin corrutinas acumuladas). Borde = alto de la ventana, no del contenedor (aproximación). A demostrar en ejecución: que el destino fuera de pantalla es alcanzable, que la velocidad es cómoda, que no pelea con el scroll normal, comportamiento con el teclado/insets y con la tarjeta saliendo de composición (LazyColumn). JVM ejecutado: `autoScrollSpeed` (14/14). Instrumentado compilado: host desplazable con dedo quieto en el borde y ids conservados; gesto cancelado.
- Autoscroll, correcciones: el viewport es el REAL del contenedor (Box medido en raíz + `layoutInfo.viewportSize.height` del LazyListState), con borde de ventana solo si aún no está medido. Hosts con `ProvideLazyDragAutoScroll`: HomeTab, ProgressTab y **ExercisesTab** (detalle deporte, 2026-10-28). Reciclado de la tarjeta: HIPÓTESIS SIN VERIFICAR en arrastre largo Lazy; pendiente QA dispositivo (no bloquea código).

### Editor de plan (Android)
Implementado: arrastre de entradas y bloques, "Mover" con conversión (fuerza→WOD conserva series; WOD→fuerza rechaza REST y lista campos perdidos), REST en WOD, detalles WOD (Peso H/M, escala, notas), id de series preservado. Añadido después: creación custom diferida en WOD→fuerza del plan (`pending:<nombre>`, creada solo al Guardar, cuota del lote validada antes de escribir, identidad por nombre normalizado; diferencia con Apple, que persiste al instante) y drop entre bloques por arrastre con autoscroll sobre el viewport real del ScrollState (misma conversión que Mover; soltar fuera de bloques no cambia nada). Verificación: JVM PlanPendingCustomsTest 2/2; androidTest solo compilado.
No portado (histórico):  Verificación: JVM EditorBlockOpsTest 15/15; androidTest solo compilado; sin ejecución ni inspección visual.

### Selector de unidad de cardio (plan)
Port del Picker "Unidad de cardio" de Apple: chips Calorías/Metros en el editor de plan para ejercicios que admiten ambas (`supportsCaloriesAndMeters`, evaluado sin equipamiento: aproximación). Antes el guardado pisaba la unidad original con la por defecto; ahora se conserva salvo elección. JVM CardioUnitTest 2/2; androidTest solo compilado. Pendiente de Apple: picker de día/hora/progresión ya existe en ReperaCards (no re-verificado contra DayEditorView), DatePickers de datos del entreno terminado y chrome de página/NavigationStack no portados.

### Auditoría DayEditorView (plan) - estado
- Unidad de cardio: ahora regla literal de Apple (`AppleCardioUnits`: allowsCalorieOrDistanceToggle/defaultQuantityUnit, con equipamiento). Sustituye la aproximación anterior. Nota: sled con equipamiento "trineo" admite Cal/m porque así lo define el modelo Apple.
- Añadido: "Añadir rutina" (copia bloques con ids nuevos y sin supersetGroup, como duplicatingContent) y "Elegir WOD" (plantillas CatalogWods; movimientos sin coincidencia de catálogo se conservan por nombre).
- Diferencias/no portado: la plantilla ladder con movimientos repetidos se rechaza con mensaje (el modelo de escalera del editor no la representa); Apple fija el título de la rutina al nombre de la plantilla si está vacío (no portado: este editor no posee el título); hoja "Reordenar" separada, swipe-to-delete, DatePickers de entreno terminado dentro de este editor y chrome de NavigationStack no portados; "Favorito"/"Día"/"Progresión" viven en la ficha de rutina de Android (no re-contrastado pixel a pixel).
- Verificación: JVM AppleCardioUnitsTest 2/2, CardioUnitTest 2/2, DayEditorImportTest 2/2, EditorBlockOpsTest; androidTest solo compilado.

### DayEditorView - cierre de diferencias (revisión 2)
- Ladder repetida: ya NO se rechaza. La plantilla se añade con sus 6 movimientos (reps propias, sin esquema), como WODTemplate.makeBlock; el guardado solo escribe repScheme si hay esquema explícito. JVM DayEditorImportTest comprueba 6 entradas y reps 21,21,15,15,9,9.
- Título de plantilla: si el título es vacío/"Entreno"/"Nuevo entreno", la primera plantilla elegida lo fija al guardar (ficha: updateRoutineDetails conservando el horario; día suelto: nombre del one-off). Nada se persiste antes de Guardar.
- Reordenar: botones subir/bajar por bloque y por ejercicio + arrastre; deslizar para quitar en entradas del plan. No existe la hoja "Reordenar" separada (los mismos gestos están en la propia pantalla).
- Fechas/hora: ficha de rutina ahora usa DatePicker y TimePicker (interruptor "Hora programada", 18:00 por defecto) en vez de texto libre. Entreno terminado: Inicio/Fin con pickers ya existían en FinishedWorkoutEditor.
- Favorito/Día/Progresión contrastados con DayEditorView: Favorito (estrella), Día (Sin fecha/Día concreto/Semanal + L-D) y Progresión (chips de las 5 políticas) están en la ficha de rutina, no dentro del editor de contenido; funcionalmente cubiertos, estructuralmente distintos (Apple los muestra en la cabecera del mismo formulario). "También en Programado" (modo favorito) y "Favorito" del modo sesión no tienen equivalente verificado.
- No portado: swipe-to-delete en el editor de entreno terminado, hoja Reordenar separada, chrome NavigationStack.
- Verificación: JVM ejecutado (DayEditorImportTest, AppleCardioUnitsTest, CardioUnitTest, EditorBlockOpsTest); androidTest solo compilado (ladder+título, bloque↓+swipe, etc.); sin dispositivo ni píxeles.

### DayEditorView - revisión 3
- Ladder: además de importar/guardar, la ejecución se comprueba en JVM: WodSessionAssembler acepta el bloque y genera 6 movimientos con plannedSets 21,21,15,15,9,9 (LadderTemplateExecutionTest). La edición posterior usa el mismo editor (cantidad por movimiento; esquema en blanco = sin repScheme). NO verificado: el grabador/cronómetro de WOD en pantalla con ese bloque.
- «También en Programado» (modo favorito): chips "Solo favorito" + L-D en cada favorito del hub de Favoritos (conserva título y hora si hay día). Sin test instrumentado propio (requiere StateOverview).
- Swipe para quitar en el editor de entreno terminado (ejercicios y movimientos WOD), ligado a id. androidTest compilado.
- PENDIENTE: Favorito en modo sesión (StartHubSheet «Crear entreno» → DayEditorView .session: empezar sesión desde borrador, opcionalmente guardado como favorito, título por defecto «Mi entreno», progresión off) y «guardar como favorito» al editar un entreno terminado (copia independiente con ids nuevos). No hay equivalente verificado en Android; se portan en el siguiente hito.
- Diferencia nativa documentada: sin hoja «Reordenar» separada ni NavigationStack; las acciones (subir/bajar, mover, quitar, arrastrar, deslizar) están en la propia pantalla.

### DayEditorView - revisión 4 (modo sesión y favorito)
- Implementado: Crear > "Crear entreno" abre el editor en modo sesión (borrador puro, título por defecto «Mi entreno», progresión off, sin día). "Empezar" valida y construye todo antes de una única escritura (`startSessionFromDrafts`); sin Favorito no se persiste rutina; con Favorito se guarda como rutina favorita tras comprobar la cuota (paywall si no cabe, y no se empieza nada, como Apple). Custom diferidos igual que en el plan.
- Implementado: «Guardar también como favorito» al editar un entreno terminado: copia independiente con ids nuevos de los bloques editados (nunca sobrescribe la rutina original); cuota comprobada antes de aplicar nada.
- Verificación: solo compilación + androidTest compilados (sessionModeStartsWithFavoriteChoice, saveAsFavoriteFlagReachesEdit). No hay test JVM de startSessionFromDrafts ni de la copia favorita (dependen del repositorio con ficheros): NO probado en ejecución. Diferencia posible: Apple arranca sesión con progresión del motor (applySuggestions); aquí la sesión se ensambla sin sugerencias de progresión porque la rutina es off.
- Pendiente general sin cambios (ver secciones anteriores): ejecución/visual, dispositivo, backend de monetización, Wear 6.1, sync final de arte.

## Progresión al iniciar sesión - contraste con Apple (revisión 5)
- Apple: `ReperaStore.startSession(from:)` aplica `ProgressionEngine.applySuggestions` solo si `canAccess(.advancedStrengthProgression)`; con `routine.progression == .off` usa `settings.defaultProgression` (si falta, `.linear`); el incremento viene de `weightIncrementKg` (2,5 por defecto).
- Android (implementado, NO ejecutado): `WorkoutRepository.assembleSession(..., applyDefaultPolicy)` replica esa resolución; sin acceso avanzado la política es off. `startRoutine` y `startSessionFromDrafts` reciben `allowAdvancedProgression` desde `subscriptions`.
- Cambio de comportamiento respecto a Android anterior: una rutina con progresión off ahora recibe la política por defecto (lineal) al iniciar, como Apple, solo con la función avanzada.
- Diferencia conocida no replicada: Apple aplica sugerencias también a movimientos de WOD; Android solo a fuerza.
- Cobertura: ProgressionApplyInstrumentedTest y DraftSessionRepositoryInstrumentedTest (almacenamiento temporal, id de usuario aleatorio) están COMPILADOS, no ejecutados.

### Progresión sobre movimientos WOD (revisión 5b)
Implementado (no ejecutado): como `applySuggestions` de Apple, con acceso a progresión avanzada también los movimientos WOD pasan por `ProgressionEngine.suggest` y quedan con series uniformes (reps/peso sugeridos). Consecuencia literal de Apple: un ladder 21-15-9 pierde su esquema por movimiento al iniciar si la política efectiva no es off (incluida la política por defecto lineal). Replicado tal cual por paridad; sin acceso avanzado se conservan los objetivos. Cobertura: `ProgressionApplyInstrumentedTest.wodMovementsAreProgressedLikeAppleOnlyWithAdvancedAccess` (compilada, no ejecutada). Pendiente de decisión de Ramón si prefiere NO replicar esta pérdida de ladder (se mantendría la paridad con Apple por defecto).

### Ladder y progresión: flujo completo en Apple (evidencia de código, revisión 5c)
- `ReperaStore.startSession(from:)` (ReperaStore.swift ~598): `SessionController.from(routine:)` genera plannedSets del ladder desde `plannedSets(for:)` (21,15,9). Si `canAccess(.advancedStrengthProgression)`, `ProgressionEngine.applySuggestions` (ProgressionEngine.swift ~133) recorre TODOS los ejercicios de sesión, incluidos WOD, y reescribe `plannedSets` como `setCount` series idénticas con `suggestion.reps`. Con `settings.defaultProgression` por defecto `.linear` (Models.swift:49) y rutina off, la política efectiva es lineal. `suggest` toma `baselineReps = planned.first.targetReps` (21) y `baselineSets = planned.count` (3): el ladder queda 21-21-21 (con historial y hit completo, el peso sube).
- Efecto real: WorkoutView usa `exercise.plannedSets` de la sesión; se aplanan los objetivos de la sesión, no la definición. `applySuggestions` devuelve solo la sesión: la rutina guardada y sus bloques no cambian. `routineForEditing` (WorkoutView ~306) devuelve la rutina guardada si existe; solo reconstruye desde la sesión (con el aplanado) cuando no hay rutina asociada.
- Android replica: sesión aplanada, definición persistida (rutina y routineBlocks de la sesión) intacta. Fixture: ProgressionApplyInstrumentedTest.wodMovementsAreProgressedLikeAppleOnlyWithAdvancedAccess distingue definición original / sesión generada (compilado, no ejecutado). No he verificado el efecto en la UI de grabación WOD de Apple ni de Android.
- DECISIÓN ABIERTA para Ramón: replicar el aplanado de Apple (estado actual) o preservar el esquema del ladder/movimientos WOD y progresar solo fuerza (se desviaría de Apple, que no se toca).

### Sincronización: recuperación del espejo vs Apple (revisión 5d)
- Apple `mergeRecoveredWorkoutsFromSupabase` solo corre con `didCompleteInitialRemoteSync` y sin `isSyncingiCloud`. Android ya portaba el merge solo-IDs-nuevos (androidTest compilado), pero no tenía ninguna guarda.
- Implementado: `CloudSyncGate` cierra la recuperación remota→local del espejo mientras una sincronización de Drive (Activity o worker) está en curso; en ese caso no se marca ningún ID como visto y se reintenta en el siguiente ciclo. JVM EJECUTADO: CloudSyncGateTest 2/2 (apertura/cierre, liberación en fallo, anidado). La integración con WorkoutMirrorStore no tiene test ejecutado (necesita Context).
- No replicado: `didCompleteInitialRemoteSync` (Android no tiene fase inicial equivalente a refreshFromiCloud(isInitial)). Diferencia documentada, no equivalencia.
- Sin E2E con Drive/Supabase reales.

### Sincronización: riesgos de la guarda inicial (revisión 5e)
- Selección de recuperación extraída a `WorkoutMirrorStore.selectRecoverable` (pura). JVM EJECUTADO: MirrorRecoverySelectionTest 2/2 (solo filas nuevas, vivas e íntegras; tombstone remoto, tombstone local pendiente, ya visto, sin finishedAt o con id distinto no se recuperan; borrado local aún no subido no resucita).
- Corrección de orden: antes se persistían las huellas "vistas" antes del merge, de modo que un fallo del merge descartaba esos IDs para siempre; ahora se funde primero y luego se marcan.
- RIESGO ABIERTO (sin resolver): en un dispositivo nuevo/reinstalado el espejo puede recuperar entrenos ANTES de la primera sincronización con Drive. El estado local deja de ser virgen y `DriveSnapshotService` lo trata como historial independiente (Outcome.Conflict, sin sobrescribir): no hay pérdida de datos, pero sí degradación. Apple lo evita con `didCompleteInitialRemoteSync`. Android no sabe si el usuario usará Drive (es opt-in con consentimiento), así que una guarda estricta bloquearía la recuperación del espejo a quien no use Drive. Decisión de producto pendiente; no la resuelvo por inferencia. Sin E2E real.

### Sincronización: alcance real del riesgo mirror-antes-que-Drive (revisión 5f)
Corrección de 5e por lectura de `DriveSnapshotService`/`CloudHistoryConflict`: el estado deja de ser virgen, pero `Conflict` solo se da si hay IDs (workouts o rutinas) únicos en AMBOS lados. Un historial recuperado por el espejo que es subconjunto del de Drive converge por versión (JVM EJECUTADO: CloudHistoryConflictTest 6/6, 2 casos nuevos). Conflicto si el espejo trae un entreno que Drive aún no tiene Y Drive tiene algo que el local no (p. ej. rutinas). Esas garantías cubren solo los casos testeados: sin integración ni E2E.
Alternativas sin consentimiento nuevo (NO implementadas): (1) procedencia: persistir en un fichero lateral los IDs recuperados del espejo y excluirlos del cálculo de `onlyLocal`; exige re-fundirlos tras una descarga de Drive (hoy `seen` impediría re-recuperarlos y quedarían solo en la copia de seguridad). (2) diferir la recuperación hasta una sincronización de Drive exitosa si ya consta consentimiento (`SyncStatusStore` es global, no por cuenta: habría que hacerlo por cuenta). (3) mantener el comportamiento actual.

### Sincronización: recuperación del espejo -> Drive (revisión 5g, implementado)
Diseño elegido tras contrastar alternativas (no relaja la detección de conflictos):
- Procedencia por cuenta (`mirror_recovered.json` junto al snapshot, id -> huella canónica) escrita por `WorkoutMirrorStore` tras fundir.
- `MirrorRecoveryReconciler` solo actúa si el local es EXACTAMENTE catálogo virgen (ignorando los 3 campos de versión que cada save() cambia) + entrenos recuperados sin editar (huella igual a la registrada). Cualquier otra cosa (rutinas, sesión activa, ajustes, pesos, entreno propio, recuperado y editado, catálogo distinto, sin procedencia) -> camino normal con su Conflict.
- Aplicable: se toma el documento de Drive y se re-funden solo-añadiendo los recuperados que Drive no tiene, con revisión remota+1 para que local gane y suba; copia de seguridad del remoto y del local previo. Una descarga nunca descarta entrenos recuperados.
- Reintento tras fallo parcial (local escrito, subida fallida): local ya no es "virgen+recuperados" -> el camino normal decide por versión y no hay IDs solo-remotos, sin Conflict.
- Tombstones: no se tocan; la selección de recuperación sigue excluyendo borrados remotos/pendientes. Borrar un recuperado tras recuperar lo deja fuera del local (subconjunto de la procedencia): se aplica la misma regla.
- JVM EJECUTADO: MirrorRecoveryReconcilerTest 4/4. androidTest COMPILADO: MirrorProvenanceInstrumentedTest (por cuenta y acumulación). SIN test de integración DriveSnapshotService (requiere red/OAuth), SIN E2E; casos no cubiertos: remoto concurrente entre lectura y subida (sin ETag, igual que antes), fallo de disco entre write y rename de procedencia.

### Reconciliación espejo -> Drive: cobertura de integración simulada (revisión 5h)
- `DriveSnapshotService` ahora recibe `SnapshotStorage` y un `OkHttpClient` inyectable. JVM EJECUTADO: DriveSnapshotServiceMirrorTest 6/6 contra un Drive simulado en memoria (interceptor) y almacenamiento local simulado: subconjunto -> descarga sin subida; recuperado ausente en Drive -> sube y la siguiente sync es Unchanged; fallo de subida (500) y reintento -> converge sin pérdida ni Conflict; datos locales independientes -> Conflict sin subir; recuperado y borrado localmente después NO se re-añade; misma ID con contenido distinto -> el reconciliador declina y manda el camino normal (aquí gana la versión remota, el local previo queda como copia de recuperación vía `LocalSnapshotStore.write`).
- Tombstones: el documento de Drive no lleva tombstones; la re-fusión solo añade lo que el local ya tenía, así que no resucita borrados locales. Un borrado hecho en otro dispositivo tras la recuperación no se refleja en Drive por este camino (igual que antes del cambio).
- Procedencia: ahora se escribe ANTES del merge (si falla, no se funde y se reintenta; entradas sobrantes son inocuas).
- Sigue ABIERTO: escritura concurrente entre lectura y subida sin ETag (no se garantiza seguridad global), `LocalSnapshotStore` real (AtomicFile) no ejercitado en JVM, E2E con Drive/Supabase reales.

### Reconciliación espejo -> Drive: revisión 5i (se retira la subida automática)
- Corrección: ausente en Drive no distingue "registro nuevo" de "borrado remotamente", y el espejo no aplica tombstones remotos al local (solo los omite al recuperar; los tombstones los escribe cada dispositivo al borrar). Sin prueba de no-borrado, la re-fusión con subida se ELIMINA: `MirrorRecoveryReconciler` solo resuelve el caso en que Drive ya contiene TODO lo recuperado (se descarga Drive; no se sube nada). Si falta algún recuperado en Drive -> `NotApplicable` y manda el camino normal (Conflict o versión) con copias de recuperación; el local no se toca. Misma ID con contenido distinto -> también declina.
- JVM EJECUTADO: MirrorRecoveryReconcilerTest 4/4, DriveSnapshotServiceMirrorTest 6/6 (Drive simulado): subconjunto -> descarga sin subir; ausente en Drive -> Conflict, Drive y local intactos, 0 subidas; borrado local tras recuperar -> nunca llega a Drive; datos independientes -> Conflict; descarga idempotente; misma ID distinta -> versión remota por el camino normal.
- Órdenes de fallo (razonado, solo parcialmente probado): (a) falla la procedencia antes del merge -> nada fundido, se reintenta; (b) merge falla tras escribir la procedencia -> entrada sobrante, la selección vuelve a elegir el ID (no está en seen), inocuo porque la procedencia solo habilita el caso "todo local ⊆ procedencia con huella igual"; (c) falla guardar `seen` tras fundir -> el ID ya es local y se omite; si se borrara después, el tombstone pendiente/remoto lo excluye. No hay test de integración de (a)-(c) con WorkoutRepository real (necesita Context).
- Abierto: sin ETag no hay garantía de escritura concurrente segura; sin E2E.

## Inventario general: pagos y validaciones por versión (revisión 5j, auditoría por lectura de código; sin ejecución)
Pagos:
- Dominio (SubscriptionStatus, CommercialSnapshot.effectiveStatus, FeatureAccessPolicy, FreeUsageLedger): lectura lado a lado con Swift, port 1:1 de reglas (estados, política offline de 7 días, caducidad/revocación ganan). Tests JVM de política y ledger ejecutados en runs anteriores; no he re-comparado caso a caso todos los límites contra Swift en este run.
- Proveedor: Play Billing directo sin RevenueCat (decisión de Ramón, iMessage 24/10 20:06, verificada en el canal). Compra detectada = pendiente de verificación (UNKNOWN, no concede Pro): Play no expone expiryTime en dispositivo y su documentación pide verificación en backend. Sin backend/Play Console (autoridad pendiente) no hay compras ni Pro en producción. No es un gap que pueda cerrar sin cuentas/backend; sigue ABIERTO y declarado, no cerrado.
- Diferencia con Apple (StoreKit verifica en dispositivo con JWS y expirationDate): en Android no hay equivalente on-device de la vigencia.
Validaciones por versión:
- Build: minSdk 30, compileSdk/targetSdk 37 (mobile, wear, domain). Matriz CI: 30, 35, 37.2 canary, Wear 5.1 y Wear 6.0 VERDES ejecutadas (run 40185662289: 37.2 = 206/206 con los 4 tests nuevos de verificación); teléfono 36.1 RETIRADO (tres renderers, fallo pre-app) y Wear 6.1 sin validar (ver sección siguiente).
- Revisión de manifiestos: `WodTimerService` es el único servicio en primer plano; declara `specialUse` con subtipo y permiso, y llama a startForeground con tipo en API 34+ (coherente). `StrengthRestService` no usa startForeground. POST_NOTIFICATIONS se pide en ≥33. Wear declara FOREGROUND_SERVICE_HEALTH sin servicio de salud en primer plano (inocuo). Las ramas SDK_INT ≤29 son código muerto con minSdk 30 (inocuo).
- Ejecución: ver la sección siguiente (estado por pata al 25/10 con runs y evidencia).

## Estado de ejecución en CI al 25/10/2026 (runs 40178955252, 40181550822, 40183447742)

Patas VERDES con tests ejecutados (XML verificados, no solo guardián de 0-tests):
teléfono API 30 (208/208), API 35 (208/208), Android 17 API 37.2 canary (202/202),
Wear OS 5.1 (API 35) y Wear OS 6.0 (API 36, android-wear-signed; verde en
40183447742), más el job android-native (JVM + builds). Bugs reales encontrados por
la ejecución y corregidos con confirmación verde: targeting del drop de arrastre con
autoscroll/relayout (03b37651) y copia de favorito (061a6629). Verificación visual
en emulador (artefactos android-visual-screenshots-*): editores de plan y de entreno
terminado y drag A->B validados por captura; corregidos hueco del selector de
formatos (FlowRow; el chip estrangulado inflaba su fila), sangrado del "Quitar" del
swipe en reposo (contenido opaco) y contraste del esquema claro (primary #0E7A38).

Teléfono API 36.1: NO validado aún. Historia: surfaceflinger crasheó con el gpu por
defecto (40124402423); con -gpu guest el arranque es inestable (~50%: arrancó en
40177026987 y 40178955252; QEMU murió al iniciar en 40181550822 y 40183447742; la
imagen no soporta guest rendering y cae a lavapipe). Cuando la imagen arranca, el
usuario tarda ~7 min en pasar a RUNNING_UNLOCKED: el workflow ya espera la
precondición real (run-as = almacenamiento CE) con timeout de pata de 45 min.
Diagnóstico (run 40184763940, gpu guest→lavapipe + -verbose -show-kernel):
el boot llega a sys.boot_completed=1 y en ese instante surfaceflinger recibe
SIGABRT (t≈54s del guest) → init mata zygote → adb pierde el pipe (exit 224).
Fallo PRE-APP de display en esta configuración; que el renderer (lavapipe)
sea la causa es HIPÓTESIS sin contrastar (el SIGABRT no lleva el motivo en el
kernel log). Contraste final con swiftshader_indirect + emulador 37.3.5
(build 16632760, run 40185662289): adb nunca llegó a subir (exit 1 al
minuto). PATA RETIRADA de la matriz (25/10): los tres renderers mueren
pre-app en el display en esta configuración de CI (gpu por defecto:
40124402423; swiftshader_indirect: RegionSamplingThread x2 y 40136277749 sin
boot con emulador 37.2.12, 40185662289 sin adb; guest→lavapipe: 40184763940).
No reintentar sin señal nueva (imagen 36.1 nueva o cambio de runner).

Wear OS 6.1 (API 36.1; único build oficial publicado: 36.1_signed_r01):
BLOQUEADO / NO VALIDADO (fallo pre-app). Firma: ~17 s tras el boot el guest entra
en bucle de crash tipo system_server (crash_dump64 -> init mata zygote cada ~2.5 s;
SIGKILL repetido a netd/media/audioserver; sys.init.updatable_crashing=1) con AMBOS
renderers (swiftshader_indirect y guest/lavapipe), sin OOM; adb nunca llega a subir
y nuestro código nunca se ejecuta (kernel logs de 40178955252 y 40181550822).
Aislamiento: Wear OS 6.0 (API 36, también android-wear-signed) SÍ arranca y pasa
los tests en el mismo runner y emulador (40183447742). Lectura limitada: el build
6.1 falla EN ESTA CONFIGURACIÓN mientras 6.0 pasa en ella; no se demuestra un
defecto exclusivo de la imagen independiente del entorno. Sin más reintentos de
esa pata hasta nueva señal (build nuevo de la imagen u otra evidencia). Queda
pendiente; no cerrado ni sustituido por 5.1/6.0.

## Reconciliación global del inventario (25/10, con la evidencia de ejecución actual)

Clasificación contra CAPABILITY_INVENTORY.md y PARITY_BACKLOG_2026_10_23.md,
distinguiendo trabajo EJECUTABLE sin más decisiones de lo BLOQUEADO (y por qué).

### Verificado en ejecución/captura hoy (no solo compilado)
- Patas CI verdes con tests ejecutados (XML): teléfono API 30 (208/208), API 35
  (208/208), Android 17 API 37.2 canary (202/202), Wear OS 5.1, Wear OS 6.0
  (signed), job android-native (JVM + builds). Runs 40178955252/40183447742.
- Editores de plan y de entreno terminado: instrumentados + capturas inspeccionadas
  (selector de formatos sin hueco ni chips estrangulados, swipe sin sangrado,
  contraste de acciones, drag A->B visible, acciones Guardar/Cancelar/favorito).
- Catálogo 288 (seed + migración verificadas), progresión con movimientos WOD
  como Apple (4/4 instrumentadas), mapa muscular (gate de píxeles), reloj WOD
  apaisado/vertical (capturas), fixes de arrastre y copia de favorito.

### Ejecutable sin la decisión WOD (autorizado, pendiente de hacer)
Reconciliado contra el CÓDIGO 25/10 (el backlog estaba viejo en varias piezas):
- #1 PlaceSearchSheet: CABLEADO en los tres call sites de iOS (WorkoutView ->
  HomeTab:235 activo; HistoryView -> FinishedWorkoutEditor:79 con la misma
  regla "sin pin manual si hay ruta de Salud"; PlanView completedDetails ->
  mismo editor de terminado). Búsqueda POI: YA hay proveedor compuesto
  Photon + Geocoder (PhotonPlaceSearchProvider/GeocoderPlaceSearchProvider).
  Verificación integrada HECHA (25/10, run 40185662289): seam
  `providerOverride` + flujoBusquedaLugarConProveedorSimulado VERDE con
  capturas inspeccionadas (resultados del proveedor falso listados con
  atribución OSM; estado confirmar con papelera+check). La inspección de
  píxeles encontró y se corrigieron DOS diferencias con iOS: el panel de
  recientes/hint quedaba visible en estado confirmar (iOS cierra el panel:
  ahora clearFocus al elegir) y el placeholder del campo era el texto del
  hint (iOS: "Buscar otro sitio…"). El preview del pin en el picker es GL
  (invisible a captureToImage): captura real lugar_selector_pin_mapa vía
  UiAutomation + seam onMapStyleLoaded (ejecución pendiente del próximo run).
- #3 Salud: el escritor YA EXISTE (HealthConnectWriter.syncFinishedSession
  con clientRecordId estable, adopción de vínculo y sin escritura de kcal/FC),
  llamado desde MainActivity al terminar; contrato de degradación probado en
  CI SIN escribir registros reales (HealthConnectInstrumentedTest). La
  degradación y el wiring probados NO demuestran fidelidad completa de
  lecturas/escrituras con Health Connect: el E2E real queda PENDIENTE,
  requiere la app Health Connect real (entorno, no código) y no se ejecuta
  con datos reales sin autoridad.
- #2 RouteMap: VERIFICADO CON MAPLIBRE REAL (25/10, run 40185662289):
  captura ruta_cardio_mapa (UiAutomation.takeScreenshot, NO el fallback) —
  teselas del Retiro cargadas en CI, polilínea naranja y marcador inicio/fin
  visibles, inspeccionada por píxeles. El fallback degradado se guarda con
  nombre propio (ruta_cardio_mapa_fallback_canvas) y no se ejecutó.
- Ubicación (pin + ruta) y descartar sesión: pruebas integradas en CI con
  ubicación simulada.
- Fidelidad: ~~ActivityHeatmapView~~ PORTADA (25/10, ver entrada del heatmap);
  ~~OnboardingFlowView~~ PORTADA (25/10: botón Google neutro surface+borde+
  label, busy sustituye al icono dentro del botón, título/subtítulo
  centrados; icono = letra "G", aproximación documentada, mascota sigue
  pendiente de arte); SessionPreviewView (contraste visual): captura
  session_preview añadida, corrección de contraste PENDIENTE de inspección
  de píxeles (tarjetas surfaceVariant del esquema M3 por defecto).
  Verificación táctil: swipe-to-reveal YA probado con aserciones en
  EditorUiInstrumentedTest (plan) y FinishedWorkoutEditorUiInstrumentedTest
  (terminado); scrub cardio ahora con verificación real: arrastre
  horizontal sobre DayPointLineChart debe cambiar los píxeles (selección),
  captura progreso_cardio_scrub.

### Bloqueado de verdad (y causa)
- Decisión WOD ladder (Ramón, preguntada 09:30, sin respuesta): SOLO bloquea
  revisar el criterio de progresión sobre movimientos WOD; la política en vigor
  es la réplica literal de Apple. Nada más depende de ella.
- Comercial/monetización (Play Console, productos, precios, backend de compras):
  SIN autorización del usuario. Bloqueo de autorización, no técnico.
- Sync multidispositivo: separado en (a) verificable con el backend EXISTENTE
  (Supabase/Google Drive ya usados por la app: qué flujos se comportan igual en
  dos dispositivos hoy, con almacenamiento/proveedores simulados) y (b) lo que
  exige cambio de backend NUEVO no autorizado (equivalente al iCloud
  best-effort de iOS). Solo (b) está bloqueado por autorización.
- Hardware físico y E2E teléfono-reloj real: fuera del alcance de CI/sandbox.
- Wear OS 6.1: bloqueado pre-app (firma documentada arriba; en esta
  configuración el build 6.1 falla y el 6.0 pasa; no se afirma defecto
  exclusivo de la imagen independiente del entorno). Sin reruns idénticos.
- Teléfono API 36.1: NO VALIDADO — pata RETIRADA (25/10) tras el fallo
  pre-app de display con los tres renderers (firma arriba).
- Arte: el lote solicitado está CERRADO (489 raíz + 488 thumbs verificados por
  hash) y main b151c4d no añadió assets; NO está bloqueado. Solo re-verificar si
  aparece una señal actual de assets nuevos.
- Distribución (firma, Play Console, P2 #12): no autorizada.

### Verificación visual cerrada en píxeles (25/10 tarde, run 40190145252)
- lugar_selector_pin_mapa: barras del sistema legibles (iconos oscuros sobre
  banda clara) y contenido fuera de ellas. El defecto tenía DOBLE origen:
  flujo real (PlaceSearchSheet, Dialog de pantalla completa sin insets con
  edge-to-edge forzado en targetSdk 37: header bajo la barra e iconos claros
  del tema del dialog) y host de prueba (brandContent sin insets, actividad
  de test con iconos claros). Corregidos ambos (51365a0a): statusBarsPadding
  + navigationBarsPadding + apariencia clara en la ventana del dialog; el
  host aplica insets e iconos oscuros. El flujo principal (Scaffold M3) ya
  gestionaba insets. MapLibre real (teselas + pin) se mantiene como cierre
  separado del renderizado.
- session_preview: contraste ACEPTADO sin cambios (surfaceVariant con texto
  oscuro legible; botón primary #0E7A38/blanco). No hubo ajuste especulativo.
- progreso_cardio_scrub: selección visible tras el drag (etiqueta
  "23 oct 2026: 30", línea vertical y punto seleccionado). Fix previo: el
  down caía en la columna de ejes; ahora dentro del Canvas.
- lugar_hoja_confirmar: panel de recientes/hint CERRADO en modo confirmar.
  Máquina de estados iOS-exacta (5020cd87): showsConfirmMap = pending !=
  null && !isTyping && !searchFocused; la flag se fija en el handler porque
  clearFocus() no garantiza onFocusChanged en el emulador. Matiz residual
  documentado: el campo puede conservar el estilo visual de foco aunque el
  estado de búsqueda ya está cerrado (cosmético, sin efecto en el flujo).
- Fallo API 30 del mismo run: 18 tests visuales rompieron por MI fix del
  host (WindowInsetsControllerCompat en el hilo de instrumentación; la ruta
  Impl30 toca View.setSystemUiVisibility -> CalledFromWrongThreadException;
  en API 35/37 no toca la vista y por eso pasó). Corregido con
  compose.runOnUiThread. Sin rerun idéntico: la causa es de test, no de app.

### Reconciliación final de sync (25/10, fuente/cuenta/alcance)
- Fuentes y cuentas: espejo de entrenos Supabase (WorkoutMirrorStore, por
  session.userId), snapshot Drive (LocalSnapshotStore, carpeta por
  sha256(uniqueGoogleId)), conciliación espejo->Drive con procedencia POR
  CUENTA (mirror_recovered.json junto al snapshot). Espejos IA (contexto,
  bandeja, planes realtime) son contexto de solo-lectura, fuera del
  historial de entrenos.
- Verificado con el backend EXISTENTE y proveedores/almacenamiento
  simulados (sin tocar cuentas reales): convergencia de dos dispositivos
  (subconjunto -> descarga sin subir; recuperado ausente en Drive ->
  Conflict sin subir, 0 subidas automáticas; datos independientes ->
  Conflict; misma id con contenido distinto -> camino normal por versión),
  selección de recuperación pura (tombstones respetados), procedencia por
  cuenta acumulativa, conflictos por versión (CloudHistoryConflictTest 6/6),
  y el almacenamiento REAL AtomicFile ejercitado en dispositivo
  (LocalSnapshotStoreInstrumentedTest: roundtrip, backup en sobrescritura,
  copia remota antes de subir, rechazo de documento corrupto, revisión).
- ABIERTO (no verificable en este alcance): escritura concurrente
  lectura<->subida sin ETag; E2E con Drive/Supabase REALES (requiere
  cuentas reales, no autorizado); equivalente al iCloud best-effort de iOS
  (backend NUEVO, no autorizado); fidelidad con la app Health Connect real
  (entorno). Alcance: ninguna escritura en cuentas reales, ninguna subida
  automática (retirada en 5i), ningún cambio de backend.

### Conflicto resuelto (25/10)
PARITY_BACKLOG_2026_10_23.md pedía "#30D158 con contenido negro" en ambos temas.
Corrección de LEGIBILIDAD dentro del encargo de paridad (fuente: revisión de
capturas por main, 25/10; no una preferencia estética nueva atribuida a Ramón):
en el esquema CLARO el primary pasa a #0E7A38 con onPrimary blanco
(~2:1 -> ~4.9:1); el esquema oscuro mantiene #30D158. Alcance: solo el esquema
claro y sus capturas. Supersede a la nota del 23/10.

---

## P0 parity 2026-10-28

Cableado: Play Billing verify client + Edge scaffold; rest chronometer/skip;
Health Inicio placeholders; board dark OCR preprocess; Drive If-Match;
Wear todayPlan TTL 18h; favoritos Gratis máx. 3 (paridad main). STATUS de
filas OCR/billing/Health del encabezado actualizado arriba. E2E hardware,
secretos Play y despliegue Edge siguen abiertos (Ramón).

## Leftovers shippables 2026-10-28 (tarde)

- Wear drop/RP: `WatchInputDraft` + outbox + `logWearSet` ramificado + UI picker.
- Wear clock WOD local: `WearLocalWodClock` + botones Iniciar/Pausar/Reiniciar;
  `stations`/`plannedIntervals` en `/repera/wod-timer`; teléfono matching gana.
- Editor WOD finished: chips Cal/m, label Déficit HSPU, Veces+seg repsAndTime.
- Editor plan: «Editar series del movimiento» → `explicitPlannedSets`.
- Autoscroll: `ProvideLazyDragAutoScroll` también en `ExercisesTab` (deporte).
- Center: `CenterCancellationPolicy` 12h; botón Actualizar; lista solo vinculados;
  JVM RPC accept/book/cancel/send.
- Widgets phone: explícitamente no (paridad iOS phone).

### Cierre auditoría post-#127

**Nada shippable de código pendiente** sin autorización Ramón / hardware.
Abierto solo: Play Console + Edge deploy + borrado real; E2E OAuth/Drive/HC/
Wear físico; decisión ladder WOD; CI Wear 6.1 / API 36.1. Bullets históricos
contradictorios del editor (arriba) marcados SUPERSEDED/CERRADO.

*Última actualización: 2026-10-28.*
