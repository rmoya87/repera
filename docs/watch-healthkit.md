# Repera Watch — ejecución offline y HealthKit

Última actualización: 2026-11-09 (reintento Live Activity; fin desde iPhone espera el guardado)

## Hub (31/10/2026)

`WatchHomeHubView` es la raíz cuando no hay sesión activa: plan efectivo del iPhone
(`effectiveWatchPlan`: hoy \| atrasado reciente), recientes y catálogo Comenzar.
Play del plan → flujo fuerza/WOD. Play de deporte **desde el Watch** →
grabación nativa del propio reloj (`WatchLiveSessionView` + GPS + HK).
Si se inicia **desde el iPhone** con Watch reachable + cuenta, el **Watch escribe el
único `HKWorkout`** (companion, mismo UUID); el iPhone conserva GPS/UI/guardar.
Sin Watch o sin `ownerScope`, el iPhone graba Salud como siempre. Temporizador libre en
`WatchStandaloneTimerView`. Mute sincroniza `spokenGuidance` del iPhone.

## Fuente de verdad

- **HealthKit (en Apple Watch):** `HKWorkoutSession` + `HKLiveWorkoutBuilder` registran FC, energía activa y duración verificada. El `HKLiveWorkoutDataSource` activa explícitamente `heartRate` y `activeEnergyBurned` (y distancia en outdoor). Outdoor: `HKWorkoutRouteBuilder` recibe los mismos fixes GPS del hub. La UI muestra siempre el indicador **kcal** (0 si Salud aún no ha entregado muestras); no se inventan con MET/reps. Al finalizar se rellenan UUID/kcal/FC desde el builder/`totalEnergyBurned` y se cierra la ruta en Salud.
- **Repera (en Apple Watch):** conserva la planificación original, serie/reps/carga confirmadas, rondas, score WOD, descansos, pausa y progreso. El contador de movimiento es una **sugerencia** que el atleta corrige.
- **Repera (en iPhone):** almacena la misma ejecución, identificada por un UUID estable. No crea otro `HKWorkout` al importar una sesión terminada del Watch.
- **Supabase:** recibe únicamente los datos de entrenamiento permitidos por `BusinessWorkoutSyncStore.privateMirrorPayload`: nunca `healthKitWorkoutUUID`, pulso, calorías HealthKit, duración Apple ni `appleHealthProvenance`. La autorización del usuario y las RLS siguen vigentes.
- **iCloud privado:** conserva el estado local del usuario para recuperación personal.

## Flujo de sesión

1. Al conectarse, el iPhone envía la rutina programada o una prescripción estructurada del entrenador, con día de calendario. El Watch la guarda. Nunca trata el contexto antiguo de otro día como entrenamiento de hoy.
2. El botón **Iniciar** crea un UUID nuevo de ejecución; conserva el UUID de la prescripción como `routineId`. HealthKit pide permisos para leer FC/energía y compartir entrenamientos.
3. Tras solicitar autorización con la API asíncrona de HealthKit, watchOS inicia un `HKWorkoutSession` y un `HKLiveWorkoutBuilder`. **Comenzar** usa la misma tabla que iPhone (`LiveSport.healthType` / `WatchLiveSport.healthKitActivityType`) para las 53 actividades. Un **plan** con bloque WOD → `crossTraining`; solo fuerza → `traditionalStrengthTraining`. Los entrenos ya guardados en Salud conservan su tipo histórico; Repera no reescribe `HKWorkout` antiguos y Progreso sigue deduplicando con alias legacy. Usa `beginCollection(at:)` y `addMetadata(_:)` con `async/await`; se habilita `workout-processing` para continuar con la muñeca baja. Un problema de permisos no produce kcal ni FC inventadas.
4. Las actividades de HealthKit se separan por bloques, sin crear un nuevo workout por ejercicio. La petición de pausa con los dos botones físicos del reloj pausa también el temporizador Repera. Las series se confirman con reps y carga reales. En AMRAP se confirma rondas + reps; en For Time, tiempo; EMOM y Tabata tienen intervalos y descansos y no crean series ficticias.
5. Al finalizar, Repera guarda primero el trabajo confirmado en disco, incluso sin conexión. HealthKit detiene su sesión, cierra la colección y guarda un `HKWorkout`. El resumen se enriquece con el UUID, la energía, la FC y la duración **solo cuando Salud los proporciona**. El tile **Tiempo** del resumen formatea `h:mm:ss` a partir de 60 min (nunca minutos totales tipo «5865:52») y elige la duración HK/pared plausible (≤ 12 h).
6. `HKMetadataKeyExternalUUID` enlaza el sample de Salud con la ejecución de Repera. Esto permite recuperarlo cuando `finishWorkout` devuelve un `HKWorkout` nil porque el reloj está bloqueado.
7. El mirroring nativo de `HKWorkoutSession` avisa al iPhone del estado de la sesión; `WCSession.transferUserInfo` transfiere los resultados en segundo plano. La cola persiste hasta acuse del iPhone; la sesión repetida se reconcilia por UUID sin duplicar resultados. Un enriquecimiento tardío de Salud actualiza solo los campos de Salud.
   Para la **planificación de hoy**, el iPhone usa `updateApplicationContext` (último plan, incluso desconectado) y `sendMessage` (plan inmediato cuando el Watch está disponible). Si `WCSession` no está activada todavía, guarda en memoria el último snapshot protegido por `NSLock` y lo publica al completar la activación. El Watch solicita `requestToday` en el arranque, al recuperar conectividad, al volver al primer plano y desde «Sincronizar con iPhone». El iPhone responde con el snapshot disponible y vuelve a publicar los datos actuales.
8. **Terminar / descartar en iPhone:** al limpiar `activeSession` el iPhone publica `session: Data()` vacío. El Watch ya **no ignora** ese nil: `WatchSessionHub.discardActiveSession()` cierra UI, descarta `HKWorkoutSession` si grababa en el reloj, limpia el snapshot offline (`current: nil`) y **no resucita** al reabrir la app. El Watch también ofrece **Descartar entreno** en listo/en curso. El resumen «¡Bien hecho!» solo aparece si el Watch completó la sesión; un cierre desde el iPhone vuelve al plan del día.
9. En primer plano, el iPhone busca por external UUID muestras aún pendientes de sincronizar desde Apple Salud y actualiza su sesión. La sincronización autenticada con Supabase continúa siendo independiente de las mediciones de Salud.

## Actividad en directo del iPhone y aparición en Inicio (05/11/2026)

**Incidencia:** iniciar Comenzar en Apple Watch grababa correctamente
`HKWorkoutSession`, pero el iPhone no recibía el estado Watch-owned para
crear una `ActivityKit` en la pantalla bloqueada / Dynamic Island.
Además, la primera transferencia del resultado de Comenzar desde Watch
podía esperar al callback asíncrono de `HealthKit.finish`, por lo que el
historial del iPhone no se actualizaba hasta que terminase HealthKit.

**Flujo corregido:**

1. Al iniciar desde el Watch se crea un único UUID de entrenamiento. El
   Watch publica `WatchLiveActivitySnapshot` (registro, pausa,
   reanudación y revisión) a `WatchConnectivityClient.sendWatchOwnedLive`.
   Usa `sendMessage` si el iPhone es alcanzable y
   `transferUserInfo` para transiciones duraderas en segundo plano.
   Las actualizaciones periódicas se limitan a ~12 segundos. No se
   transmiten puntos GPS ni muestras de Salud por el canal de UI.
2. El iPhone valida `ownerScope`, formato, antigüedad y orden temporal.
   `WorkoutLiveActivityCoordinator` presenta una actividad local con
   identificador `watch:UUID` separado de `free:` y `planned:`.
   El iPhone **no inicia otro workout HealthKit ni GPS**. Al recibir el
   primer snapshot **deporte** Watch-owned, adopta `LiveActivityRecorder`
   en modo espejo (`isWatchOwnedMirror`) y abre la **misma** `LiveActivityView`
   de Comenzar (métricas/mapa según preferencia) vía
   `repera.openComenzarFromWatch`. Plan/clase Watch-owned sigue en
   `WatchOwnedLiveMirrorView`. Pausa/reanudar/finalizar se envían al reloj;
   no hay segundo registrador. Indoor: kcal/FC del snapshot en UI y Live Activity.
3. Al terminar o cancelar desde el reloj se envía estado de revisión
   para cerrar exactamente el aviso de ese UUID. Al finalizar,
   `sendFinished(pending)` se encola **inmediatamente después de
   persistir el resultado local y antes de esperar HealthKit**.
   `HealthKit.finish` puede enviar después el mismo UUID con
   distancia, FC, kcal y `HKWorkout.uuid` verificados. La conciliación
   conserva las series y las ediciones manuales previas, sin duplicar.
4. `ReperaStore.applyWatchSession` distingue el cierre de una actividad
   libre (`watch:`) del cierre de un plan (`planned:`). Después del
   guardado local, el `workoutsEpoch` obliga a Inicio a rehacer las
   tarjetas sin esperar la consulta asíncrona de Salud. Una actividad
   fresca recibida desde Watch selecciona su día en Inicio; una
   transferencia histórica offline no mueve el calendario.
5. Al guardar desde Comenzar en iPhone una actividad vinculada a
   prescripción, el estado sigue siendo `.finished` aunque quede
   `awaitingResultEntry = true`; no se convierte a `.ready` con
   `finishedAt` ya fijado. Además, la pantalla de revisión no descarta
   su checkpoint GPS ni informa de éxito hasta que termine
   `LocalStore.persistAndFlush`; si falla, muestra error y permite
   reintentar sin perder el registro.
6. Si la primera versión del Watch se está persistiendo cuando llegan las
   métricas finales de HealthKit, el iPhone vuelve a volcar el estado más
   reciente antes del ACK para evitar que el Watch reintente indefinidamente.

**Plan / clase iniciados en Watch (mismo canal):** además de Comenzar,
un plan o clase con `startedOnThisWatch` publica snapshots `kind: .planned`
(ejercicio/series + pausa) por `sendWatchOwnedLive`. El iPhone pinta
`watch:UUID` y permite abrir el espejo nativo con comandos al reloj,
sin habilitar el grabador iPhone ni abrir una tarjeta `planned:` concurrente
cuando `appleHealthProvenance` es Watch.

**Play en iPhone con Watch emparejado (handoff Apple):** requiere Watch
**alcanzable** + `ownerScope` de cuenta. El iPhone marca `watchHealthKitPending`,
envía `handoffStart` y llama `HKHealthStore.startWatchApp(toHandle:)`. El Watch
guarda `pendingPhoneHandoff` y adopta el **mismo UUID** como companion HealthKit
(`adoptPhoneLiveHealthOwnership`, mirroring + outdoor). Si `startWatchApp`
despierta el reloj, el iPhone **no** abre builder local aunque el mirroring
tarde (evita cáscara 0 kcal); al Guardar/sync espera el workout del Watch
(`waitForVerifiedWatchWorkout`) y borra shells huérfanos. Solo si el Watch
**no** despertó hay fallback al builder iPhone. Si el reloj aparece a mitad de
Comenzar, `attemptLateLiveWatchHandoffIfNeeded` promociona sensores al Watch.
Comenzar usa `LiveActivityRecorder.watchHandoffHandler`.

**Controles desde el Watch (Comenzar iniciado en iPhone):** pausa / reanudar /
finalizar / cancelar van por `transferUserInfo` (durable) + `sendMessage` si hay
reachability. Al pasar a revisión, el Watch **finaliza** su `HKWorkout`
(`finishCompanionHealthIfNeeded`); nunca lo descarta en `.review`.

**Matriz de ownership (Comenzar / Salud):**

| Caso | Dueño HK | Notas |
|------|----------|--------|
| Solo Watch / inicio Watch | Watch | Sync al iPhone sin segundo workout |
| Watch+iPhone / inicio Watch | Watch | iPhone = UI/ActivityKit |
| Watch+iPhone / inicio iPhone | Watch companion | iPhone = GPS/UI; mismo UUID |
| Solo iPhone / sin scope | iPhone | 0 kcal posible (sin muñeca) |
| Watch aparece a mitad | Pasa a Watch | Descarta builder iPhone si handoff ok |

**Clase / cita sin plan de ejercicios:** Play sigue disponible. Se abre
Comenzar como **gimnasio** (`strength` / `traditionalStrengthTraining`) o
**HIIT** si el título lo indica (`FallbackActivityKind`). En Watch, un
handoff sin plan de hoy ni tipo reconocido también arranca fuerza o HIIT,
nunca queda idle ni escribe `.other` ambiguo en Salud. **Android / Wear:**
mismo `FallbackActivityKind` en dominio (`android/domain`); Play de clase
sin bloques abre Comenzar con cuenta atrás; Wear sin plan de hoy arranca
`startWatchOwnedLive(strength|hiit)`. Detalle de dueños HC:
`docs/ANDROID_WEAR_HEALTH_METRICS_2026_11_05.md`.

**Limitación del sistema:** una `ActivityKit` puede iniciarse localmente
en el iPhone solo cuando iOS permite ejecutar la aplicación. Una entrega
`transferUserInfo` al iPhone suspendido no es una garantía de inicio
inmediato en Dynamic Island. Los tokens push-to-start / update se capturan
en `LiveActivityPushTokenStore` (UserDefaults); subirlos y enviar APNs
ActivityKit requiere ampliar `register_push_device` y Edge (no desplegado
aquí). Con `ActivityAuthorizationInfo().areActivitiesEnabled == false`
no se muestra Live Activity; se conserva el entrenamiento sin fallar.

**Pruebas de aceptación (iPhone y Apple Watch reales):**

- Inicio desde Watch con iPhone desbloqueado y Repera abierta: tarjeta
  de duración/distancia y tipo, pausa/reanudación, sin controles
  inoperantes ni otro `HKWorkout`.
- Inicio desde Watch con iPhone bloqueado, Repera en segundo plano,
  después fuera de cobertura y reconexión: observar la entrega del
  aviso cuando iOS permita iniciarlo, nunca reabrir sesiones ya
  finalizadas. Verificar que la sesión se recibe tras reconectar.
- Finalizar desde Watch: Inicio pinta la sesión antes de recibir el
  enriquecimiento de HealthKit, con el mismo UUID después de recibirlo.
- Inicio y Guardar desde iPhone: Inicio selecciona la fecha correcta,
  muestra la nueva tarjeta y el punto del calendario sin salir/entrar
  manualmente. Repetir con prescripción y `awaitingResultEntry`.
- Verificar fin de sesión, cancelación, duplicados, acciones offline,
  permiso Live Activities desactivado y reinicio de ambas apps.

Pruebas: `WatchLiveActivitySnapshotTests.swift` (política de
antigüedad/orden), `tests/test_watch_owned_live_home_contract.py`
(cableado entre reloj, teléfono, widget e historial). Compilar iOS y
watchOS con el toolchain configurado y validar en dispositivos antes
de certificar el comportamiento de ActivityKit en segundo plano.

## Continuidad Watch / iPhone y distancia GPS (07/11/2026)

- La transferencia de una sesión finalizada cierra también el espejo de iPhone por UUID aunque se pierda el snapshot terminal del reloj. Los reenvíos tardíos del resultado enriquecen la misma entrada, no crean un segundo entrenamiento.
- Una actividad iniciada desde Apple Watch mantiene ese dispositivo como único escritor de `HKWorkout`, ruta y muestras HealthKit. La Live Activity elimina «Registrando en Apple Watch» / «Control desde Apple Watch» y ofrece «Abrir Repera». En iPhone abre `repera://live` y muestra un espejo nativo SwiftUI de ese UUID, sin crear otro workout; en Apple Watch, la Smart Stack sigue abriendo `repera-watch://active`.
- El espejo iPhone presenta tiempo, distancia/ritmo, pulso y energía activa solo si existen métricas verificadas transmitidas por Watch. Pausar, reanudar y finalizar son comandos de WatchConnectivity con `ownerScope` y UUID, reenviados de forma duradera si es necesario. No se ejecuta una pausa falsa sobre el grabador del iPhone.
- Finalizar desde el iPhone guarda el UUID en `repera.watch.phoneRequestedFinish.v1` (ámbito de cuenta). El snapshot `.review` no desmonta Comenzar: la pantalla sigue hasta que `sendFinished` queda en disco, y solo entonces se abre Inicio con Descartar/Revisar. Un fin hecho en el reloj sigue mostrando la card sin cambiar de pestaña. El token no se borra hasta decidir si el `finishedAt` es reciente (< 10 min); si la app se reinicia antes, se reintenta al hidratar.
- Si `Activity.request` falla, la marca de entrega de ese `capturedAt` se revierte. El mismo snapshot puede volver a crear la Live Activity. Una marca más nueva o una sesión ya cerrada no se reabre. El Apple Watch sigue siendo el único escritor de Salud.
- Para las caminatas y otros exteriores, Watch solicita escritura de `HKWorkoutRoute` y distancia numérica del deporte. La ruta GPS por sí sola no añade distancia/ritmo a Fitness. Antes de añadir una muestra se comprueba `sharingAuthorized`; si falla o está denegada, el workout, FC y energía siguen guardándose y la distancia permanece en Repera. **No** se muestra aviso naranja en Resultado por ese fallo opcional (08/11/2026).
- En iPhone, `ensureWorkoutRouteAccess` solicita también escritura de los tipos de distancia (andar/correr, bici, natación y nieve). Un permiso denegado anteriormente puede necesitar habilitarse manualmente en Salud/Ajustes.
- La edición de entrenamientos terminados de cardio sin bloques de ejercicios habilita Guardar; el check usa `borderedProminent` + verde Repera (blanco día / negro noche) para no quedar transparente bajo Liquid Glass.

**Validación pendiente en hardware:** comprobar en Apple Watch + iPhone reales datos, permisos concedidos/denegados, apertura desde ambas Live Activities, fases y comandos en pausa, exportación GPS, sesiones offline, ausencia de duplicados y compilación iOS/watchOS.

## Permisos y privacidad

Entitlement HealthKit y cadenas `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` en el target del Watch. Modo background `workout-processing`. No se declara `audio`: los controles de reproducción se delegan al sistema mediante `NowPlayingView`.

No se infiere la concesión de permisos de una lista de muestras vacía. Una lectura que aún no se ha transferido entre dispositivos se mantiene **pendiente**, no como cero.

## Complicación WidgetKit y WidgetBundle

La extensión `ReperaWatchWidget` utiliza la estructura nativa de WidgetKit: `ReperaWatchWidget: Widget` devuelve `StaticConfiguration` desde `body: some WidgetConfiguration`, mientras que `ReperaWatchWidgetBundle: WidgetBundle` devuelve `ReperaWatchWidget()` desde `body: some Widget`. Nunca colocar `StaticConfiguration` directamente en el cuerpo de un `WidgetBundle`, porque `WidgetBundleBuilder.buildExpression` solo acepta tipos `Widget` y Swift devuelve `No exact matches in call to static method 'buildExpression'`.

Complicación = **icono de la app** (mascota). Watch: `ReperaIcon`/`repera_logo.png` + `.fullColor` + `contentMarginsDisabled` (sin SF Symbol). Wear: `ic_repera_logo` a color (`SMALL_IMAGE`/`PHOTO_IMAGE`) y `ic_repera_logo_mono` en huecos monocromos; sin esto la esfera queda vacía. **Launcher Wear** (menú de apps): `android:icon`/`roundIcon` = `@mipmap/ic_launcher(_round)` (mismo que el móvil); sin esto el cajón muestra el icono genérico/vacío.

## Registro de caminata, deportes outdoor y clases (incidencia 05/11/2026)

**Origen y propiedad.** Cuando el usuario pulsa Play en el Watch, el reloj debe
crear y guardar el único `HKWorkout`: no delegar su inicio al iPhone, donde
el workout podía finalizar como una cáscara sin sensores mientras la sesión
de muñeca se descartaba. El mirroring nativo de HealthKit comunica el estado
al iPhone y `WCSession` aporta los resultados a Repera. Si la sesión nace
en el iPhone, el iPhone conserva el registro; no escribir un segundo workout
de Watch en Salud.

**Tipo.** El catálogo nativo traduce `walking` a `.walking`, `hiking`
a `.hiking`, carrera a `.running`, bici a `.cycling`,
CrossFit/HYROX a `.crossTraining`, fuerza a
`.traditionalStrengthTraining`. La rutina o clase programada usa su deporte
real si tiene un `liveSportID`; si no, WOD → CrossTraining y fuerza →
Strength Training. Nunca decidir el deporte solo por el nombre editable.

**Distancia y ritmo.** `HKWorkoutRoute` da el mapa pero **no garantiza**
los kilómetros del resumen de Fitness. Antes de cerrar el builder, Repera
añade una muestra de distancia basada en sus fixes GPS reales **solo si**
HealthKit no registró ya distancia numérica. La muestra se escribe en el
identificador correcto (andar/correr, ciclismo, nieve o natación) para que
Fitness pueda calcular el ritmo/velocidad cuando el sistema lo admita.
No sumar dos veces la distancia ni calcular ritmo con GPS vacío.

**Energía y FC.** Las kcal y la FC provienen del builder / sensores de
HealthKit. Si un acumulado provisional es 0, buscar una medición positiva
real en el resultado final, el valor legacy o el acumulador en vivo. No
convertir 0 en kcal inventadas por MET, distancia, pulso o duración.
La energía total/ritmo mostrado y el icono del origen son presentaciones
gestionadas por Apple; una corrección del bundle no puede forzar su aspecto
en Fitness. Los iconos AppIcon de iPhone y Watch están registrados en
`project.yml`, y la identidad real debe validarse en una compilación firmada.

**Limitación de históricos.** Los `HKWorkout` ya guardados no adquieren
retroactivamente kcal o distancia que nunca se almacenó. No sobrescribir
muestras históricas ni cambiar su tipo a ciegas; solo reconciliar datos
existentes bajo el UUID verificado.

**Prueba de aceptación en dispositivos reales:**
1. Iniciar caminata de 10+ min desde Repera Watch con iPhone conectado;
   confirmar `walking`, una sola actividad, icono/origen, HR, kcal activas,
   ruta y km/ritmo en Fitness. Repetir desconectado.
2. Iniciar una caminata desde iPhone con GPS e incluir metros; comprobar
   distancia y ausencia de workout duplicado.
3. Probar carrera, bici, senderismo, fuerza, CrossFit/HYROX y clase
   planificada: tipo esperado, tiempos, FC y energía real disponible.
4. Denegar permisos de distancia/energía, reautorizar desde Salud,
   pausar/reanudar, pantalla bloqueada, cancelar y reconectar Watch.
5. Revisar en Xcode/TestFlight real que AppIcon se empaqueta en ambos targets.
   Si Fitness sigue usando placeholder, investigar la caché de iconos/instalación
   y la identidad firmada, sin prometer una API que fuerce su presentación.

Contratos estáticos: `tests/test_healthkit_activity_export_contract.py`.
La comprobación de sensores, permisos y presentación de Fitness requiere
iPhone y Apple Watch físicos.

## Pruebas antes de publicar

- XcodeGen + build iOS/watchOS 27 con firma y entitlements efectivos; ejecutar en Apple Watch físico (los sensores no son equivalentes en simulador).
- Denegar permisos de lectura/escritura, permitirlos después y comprobar que la app sigue registrando series sin inventar salud.
- Entreno con pantalla apagada, pausa/reanudación, finalización de AMRAP/EMOM/Tabata, descanso real entre series, batería baja, relanzamiento tras crash.
- Finalizar sin iPhone, reiniciar Watch, abrir el iPhone y comprobar una sola sesión con las series correctas.
- Verificar **un solo** workout HealthKit por ejecución; FC y calorías se leen del sample correspondiente. Verificar ventana temporal y que los datos no aparecen en Supabase.
- Si `finishWorkout` devuelve nil con el reloj bloqueado, desbloquear y comprobar que el iPhone resuelve `HKMetadataKeyExternalUUID`.
- Probar las tres familias de complicación y la interfaz nativa de controles multimedia.
- Probar la actualización de la planificación profesional tras descarga de Supabase.

La disponibilidad efectiva de los permisos, sensores, background execution y estados de firma solo puede certificarse en dispositivos y perfiles de Apple válidos.

## Estados nativos de HealthKit: evitar pausa y reanudación duplicadas

`HKWorkoutSession.startActivity(with:)` inicia la sesión de HealthKit. No debe llamarse `resume()` cuando `HKWorkoutSession.state == .running`: watchOS puede generar el aviso «Unable to perform 'resume' from current state 'Running'», antes visible en naranja en Play. `WatchHealthKitSession` solicita `pause()` **únicamente desde `.running`** y `resume()` **únicamente desde `.paused`**, bloquea solicitudes pendientes repetidas y valida los eventos de cambio de estado antes de sincronizar el cronómetro de Repera. Las transiciones de actividad de los bloques se aplazan hasta `.running`; no iniciar `beginNewActivity` durante una pausa. No se silencian fallos reales de HealthKit: se evita la llamada inválida que los originaba.

La regresión `test_healthkit_state_transitions_never_repeat_running_resume` verifica los guardas de estado y el botón único de avance.

## APIs asíncronas y compatibilidad con Swift 6

El Watch utiliza las variantes `async throws` de `requestAuthorization(toShare:read:)`, `beginCollection(at:)`, `addMetadata(_:)`, `endCollection(at:)` y `finishWorkout()`. El inicio opcional del mirroring usa `startMirroringToCompanionDevice()` de manera independiente, para que el entrenamiento siga funcionando sin iPhone. No volver a introducir las sobrecargas con `completion` que Xcode 27 señala con **Consider using asynchronous alternative function**. Los errores se tratan sin atribuir mediciones inventadas a Salud. El contrato de código que comprueba estas APIs está en `tests/test_watch_healthkit_contract.py`.




## Paridad del registro de entrenamiento iPhone ↔ Apple Watch

El Apple Watch utiliza los tipos de dominio compartidos `SessionExercise`, `LoggedSet` y `WODBlockResult`. El formulario depende de `exercise.loggingStyle`: fuerza usa kg/reps/RIR, peso corporal reps/RIR, HSPU puede usar déficit en cm, comba registra veces/segundos y ergómetros o carrera duración más **Cal o metros**; no convertir esas unidades a repeticiones genéricas.

La opción **Más datos** permite elegir trabajo o calentamiento, serie normal, al fallo, dropset (cada drop con carga/reps) y rest-pause (reps/descanso de cada cluster). La versión offline de las entradas pendientes se guarda en `WatchSetDraft` dentro del snapshot Codable del reloj; una serie confirmada se convierte en `LoggedSet` sin eliminar campos opcionales. Volver por gestos a una serie anterior conserva ID, fecha y metadatos usando `SessionController.replaceLoggedSet`, sin registrar una serie adicional. EMOM/Tabata conserva intervalos/series reales y requiere **Terminar bloque** explícito: registrar una serie del último movimiento no debe cerrar el WOD.

Desde **¡Bien hecho!** el botón **Volver al inicio** oculta el resumen en el acto, incluso mientras HealthKit está guardando. Se conserva internamente `lastFinished` para incorporar pulsaciones/calorías/UUID de Salud y esperar el ACK del iPhone; `summaryDismissed` se persiste para no reabrir el resumen tras reiniciar el reloj. Ni el retorno a Inicio ni el cierre de la vista deben cancelar el registro o fabricar datos. Los contratos automatizados están en `tests/test_watch_healthkit_contract.py` y los datos/ediciones se comprueban con `WatchSetNavigationTests.swift`.

## Interfaz nativa de entrenamiento en Apple Watch

El flujo se organiza por **entrenamiento del día → bloque preparado → Play → Bien hecho**:

- **Entrenamiento del día:** el nombre del entrenamiento es el título nativo de navegación, inmediatamente bajo la hora de watchOS. No hay una etiqueta «HOY» ni otra cabecera duplicada en el scroll. El formato queda a la izquierda del tiempo total; cada bloque tiene **una sola tarjeta**, con ejercicios y miniaturas separados por un divisor gris claro (sin tarjetas internas).
- **Bloque preparado:** el nombre del bloque es el título nativo, no otro encabezado que desplace el contenido hacia abajo. Las miniaturas se agrupan en una tarjeta única, con separadores, y se presenta «Iniciar bloque» o «Empezar ejercicio».
- **Play:** nombre del bloque en la navegación, cronómetro y **botón iconográfico pausa/reanudar a su derecha**. No hay barra de progreso de tiempo, texto permanente «En pausa», botón inferior «Pausar», ni «Finalizar antes». Siguen disponibles los valores reales de Salud cuando existen. Debajo se presenta el ejercicio con miniatura y controles grandes de cantidad (o unidades Cal/m), carga y tiempo según el tipo. Se retiran **RIR y Más datos del panel principal**, pero siguen siendo editables al tocar la cabecera del ejercicio, que abre un panel secundario; así la simplificación visual no borra la paridad de registro iPhone/Watch.
- **Acciones y gestos:** un solo botón **verde con flecha** a la derecha de «Resumen» registra los valores de la serie y avanza cuando corresponde; en la última serie válida cambia a un check verde para finalizar. El antiguo botón grande «Siguiente» se elimina por duplicado. La flecha se deshabilita si una serie individual no tiene cantidad registrada o el reloj está pausado. En un WOD global abre primero la captura de rondas/tiempo sin inventar repeticiones. El gesto horizontal para revisar series continúa funcionando, pero se elimina el texto «Desliza ← → para revisar otras series» para aprovechar el espacio. EMOM/Tabata conservan la acción específica «Terminar bloque» porque registrar una serie no significa que todos los intervalos hayan acabado.
- **Resumen del plan:** accesible desde el botón «Resumen» (la X nativa cierra la hoja). Conserva el título «Resumen», los bloques seleccionables, las tarjetas únicas y las líneas divisorias. La acción «Finalizar entrenamiento» guarda directamente sin pasar por el diálogo «¿Finalizar el entrenamiento?» ni por «Guardar entrenamiento». Si el WOD necesita rondas/reps/tiempo, abre la captura del resultado y el botón **Terminar** la confirma, guardando la sesión sin otra confirmación.
- **Fin:** encabezado horizontal con icono y «¡Bien hecho!», resultados disponibles y botón «Volver al inicio». La persistencia de HealthKit y la cola offline continúan aun después de volver; los errores de Salud reales son visibles, pero no se muestran mensajes técnicos de éxito por defecto.

Las miniaturas proceden de las **mismas ilustraciones originales de Repera iOS**. Hay 188 imágenes de lista de 192 px incluidas en `Apps/ReperaWatch/Resources/Assets.xcassets`; `WatchExerciseArtwork` y `WatchExerciseThumb` están definidos junto a `WatchSessionView.swift` (fuente ya incluida en el target) y resuelven el ejercicio sin conexión y utiliza SF Symbol cuando todavía no existe ilustración. La prueba `test_watch_exercise_thumbnail_assets_are_ios_originals` verifica que cada JPEG es idéntico al thumbnail iOS. Las pruebas Swift del dominio (`WatchSetNavigationTests`) cubren edición sin duplicados, salto seguro y finalización del último ejercicio; el contrato estático de vista se verifica en `test_watch_workout_native_play_and_one_tap_save`.

El emulador no sustituye un Apple Watch real para probar Digital Crown, haptics, gestos a la vez que el scroll, FC en vivo y el cierre de una sesión HealthKit cuando la pantalla se apaga.

## Ajustes de Play y avance con cero

La interfaz del reloj **no muestra el botón de música/podcast**. La navegación conserva el título del bloque bajo la hora del sistema. El control `pause.fill/play.fill` es un **círculo verde de 70 × 70 puntos** con icono negro, con una altura aproximada equivalente a cronómetro grande más su leyenda. Se mantienen las reglas de los temporizadores de iOS y sus métricas HealthKit.

**Un solo sistema visual para acciones y valores:** `#30D158`, el verde original de Repera iOS, con icono/texto **negro**. En Play, «Resumen» y la flecha de avance usan relleno verde. Los botones `− / número / +` de repeticiones, peso, déficit, duración, puntuación WOD y RIR comparten tamaño, fondo verde, iconos negros y la unidad justo debajo; los ajustes avanzados siguen estando en la hoja del ejercicio. Los botones de borrado dentro de esa hoja también respetan el verde/negro, sin controles rojos ni grises por defecto.

La flecha **no se deshabilita por ver 0**. Pulsarla con una serie individual a cero avanza al próximo ejercicio **sin crear ni confirmar un `LoggedSet` ficticio**; en el último ejercicio finaliza sin inventar repeticiones. Si hay cantidad positiva, registra la serie y avanza según los conjuntos prescritos. Los WOD con puntuación global pasan a la pantalla de resultado, y los WOD por intervalos solo registran series positivas o permiten saltar al siguiente movimiento sin afirmar que se hizo uno. Durante un descanso automático la flecha permanece operativa: pulsarla omite el descanso antes de avanzar, sin crear una serie de cero. Solo queda deshabilitada cuando la sesión está pausada o en la pantalla de revisión de bloque.

Al agotarse los intervalos el texto se simplifica a **«Finalizado»**; los ejercicios y resultados siguen registrables según las reglas del formato. Se conserva el gesto horizontal de revisar series y se elimina únicamente el mensaje explicativo, no la interacción.

## Controles y temporizadores: paridad visual y funcional con iOS

- **Gestos:** se conserva el gesto horizontal para revisar y corregir series guardadas. Solo se elimina el texto visible «Desliza ← → para revisar otras series»; las acciones `swipeSet(-1/1)`, los identificadores de serie y la edición sin duplicados permanecen intactos.
- **Verde oficial:** `WatchSessionView` usa el mismo `OG.accent` de iPhone, RGB 48/209/88 (`#30D158`). Todos los botones rellenos en ese verde muestran texto o símbolo **negro** (`OG.onAccent`). También el selector Cal/Metros seleccionado contrasta en negro.
- **Pausa/reanudación:** botón circular de 42 × 42 puntos con fondo verde de Repera e icono negro. Deja más anchura disponible al cronómetro, ahora en fuente redondeada grande (43 pt); cambia de pausa a play según el estado.
- **EMOM / Every X, Death By:** el número principal es la cuenta atrás del **intervalo vigente**, no el acumulado de la sesión. La leyenda «Intervalo N/M» o «Ronda N/M» aparece inmediatamente bajo la cifra. En la expiración se evita un intervalo N+1 ficticio. Para WOD con series individuales el final del cronómetro **no fuerza la pantalla de resultado** ni inventa repeticiones: las series siguen editables hasta que el usuario pulse «Terminar bloque».
- **Tabata:** muestra el tiempo restante de la fase activa (trabajo o descanso) y justo debajo «Trabajo/Descanso · ronda N». Se respeta la secuencia de iPhone, incluida la fase de descanso de cada ronda. Al terminar los intervalos muestra **«Intervalos finalizados»**, pero permite introducir las series que falten y finalizarlas explícitamente, como iPhone.
- **Circuito:** el cronómetro principal muestra la fase de estación o descanso entre rondas y la leyenda indica qué estación o ronda corresponde. Las pausas entre rondas se añaden a la planificación del tiempo como en iPhone, nunca tras la ronda final.
- **AMRAP / Max Effort:** cuenta atrás del bloque, sin reloj de intervalo adicional. **For Time, AFAP, Chipper, Ladder y Buy-in/Cash-out:** cronómetro **ascendente**; el time cap es informativo y no termina ni recorta el resultado automáticamente. **Fuerza y restantes formatos:** cronómetro ascendente sin límite prescrito o cuenta atrás cuando la planificación establece límite, igual que la lógica del temporizador de iPhone.
- **Descansos:** al estar en un formato por intervalos no se dibuja un segundo reloj grande de descanso, pues el principal ya corresponde a la fase vigente.

Las comprobaciones estáticas están en `test_watch_timers_and_primary_buttons_match_ios` del contrato Watch. La validación completa de intervalos, estados HealthKit, haptics y tamaño del reloj sigue requiriendo compilar y probar en Xcode con watchOS 27.

## Pantalla sin planificación y sincronización solicitada

La pantalla vacía utiliza la mascota original `MascotWatch` de iOS en tamaño grande, centrada, con «Sin plan descargado» y sin textos de ayuda. El botón verde «Sincronizar», con icono negro, queda fijado al pie y ocupa el ancho disponible. Se mantiene espacio flexible para tamaños distintos de Apple Watch.

Al pulsar «Sincronizar» se solicita al iPhone el entrenamiento actual del día mediante `WCSession.sendMessage`, sin mostrar primero una caché antigua como respuesta. El iPhone consulta `phoneConnectivityLatestWorkoutForToday` y devuelve `todayWorkout` y `todayDayStart`. Si no está alcanzable, la petición se encola con `transferUserInfo`; el iPhone la recibe cuando pueda procesarla y publica la planificación por `updateApplicationContext`. La activación de WCSession conserva la petición manual pendiente; la entrega de mensajes en segundo plano es eventual.

## Inicio del reloj: control multimedia y sincronización

El botón de música/podcast en el extremo superior derecho utiliza un círculo verde de acento con el símbolo `playpause.fill` **negro** y monocromo para mantener el contraste en la interfaz oscura watchOS. Abre `NowPlayingView` nativo.

«Sin plan descargado» significa que **el reloj todavía no tiene una prescripción para su día local**, no que la cuenta carezca necesariamente de un entrenamiento. El botón «Sincronizar con iPhone» vuelve a solicitar el plan; para los simuladores, arrancar un iPhone y Apple Watch *emparejados* y abrir Repera también en el iPhone. No requiere que el iPhone esté conectado de forma continua una vez se descargó la planificación. Los cambios programados posteriormente se reenvían en vivo cuando ambas apps son alcanzables, o por `applicationContext` cuando watchOS permita la entrega.

Para comprobarlo: abrir el Watch sin plan, programar el entreno para el **día actual** en el iPhone, verificar su aparición sin reinstalar, probar con el Watch desconectado y reconectado, pasar la app Watch a segundo plano y volver, y asegurar que una ejecución offline ya iniciada nunca se borra al refrescar.

## Identidad visual: icono único en iOS, watchOS y complicación

El recurso canónico es `Apps/Repera/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`. La app Apple Watch y la complicación reutilizan ese PNG: `ReperaIcon.imageset` solo tiene **`repera.png`** (escala `1x`, `template-rendering-intent: original`, `pre-rendered`). No dejar `repera@2x.png` / `repera@3x.png` sueltos en el imageset: Xcode marca «unassigned children». Detalle de render `fullColor` / `accented` y CI en `docs/WATCH_WEAR_SENSOR_COMPLICATIONS_2026_10_31.md` y `tests/test_watch_complication_contract.py`.

## Ejecutar la app Watch en el simulador

La app del reloj es el target `ReperaWatch` y necesita su **scheme ejecutable** homónimo. El target `ReperaWatchWidget` es únicamente una extensión de WidgetKit para la complicación de la esfera; seleccionarlo en Xcode no ejecuta la app de entrenamientos. `project.yml` declara ahora explícitamente el scheme `ReperaWatch` con `build.targets.ReperaWatch: all` y `run.executable: ReperaWatch`.

Tras actualizar `main`, cerrar Xcode y ejecutar `xcodegen generate --spec project.yml`, abrir `Repera.xcodeproj`. En la barra superior, elegir **ReperaWatch** (no `ReperaWatchWidget`) y después un simulador **Apple Watch con watchOS 27** o un Watch físico emparejado. Si no hay simuladores Watch disponibles, instalarlos en **Xcode → Settings → Components** y crearlos/emparejarlos en **Window → Devices and Simulators**. El scheme debe aparecer también en `xcodebuild -list -project Repera.xcodeproj`, comprobado por el CI.

El simulador puede validar navegación, series, temporizadores y aspectos de UI, pero no sustituye a un Apple Watch real para pulsaciones, energía, sensores y sesiones HealthKit en segundo plano.

## Instalación de la complicación watchOS

El `ReperaWatchWidget.appex` requiere un `CFBundleName` no vacío para que CoreSimulator/installd pueda instalarlo dentro de `ReperaWatch.app`. El nombre establecido es `ReperaWatch`, declarado **tanto** en `Apps/ReperaWatchWidget/Info.plist` como en `project.yml` (target `ReperaWatchWidget`, `info.properties`). También se mantiene `CFBundleInfoDictionaryVersion: 6.0`, el tipo `XPC!`, el identificador `com.app.repera.watchkitapp.widget` y el punto de extensión `com.apple.widgetkit-extension`.

La verificación de los plists fuente está en `python3 scripts/check_watch_widget_plist.py`. Para validar el resultado real de una compilación, indicar su ruta: `python3 scripts/check_watch_widget_plist.py --built /ruta/a/ReperaWatchWidget.appex/Info.plist`. El job de Xcode CI comprueba el `.appex` compilado después del build Watch. Los tests de regresión están en `tests/test_watch_widget_plist.py`.

Si el simulador muestra `does not have a CFBundleName key with a non-zero length string value`, actualizar `origin/main`, regenerar con `xcodegen generate --spec project.yml`, compilar e instalar nuevamente. Si persiste, verificar la copia efectiva de `Info.plist` dentro de `ReperaWatchWidget.appex`, no únicamente el fichero del repositorio. Un plist correcto en origen no garantiza que el paquete generado lo conserve.

## Recompilar después de incorporar archivos Swift al Watch

`Repera.xcodeproj` está ignorado en Git y se genera localmente con XcodeGen; descargar el archivo Swift desde GitHub **no actualiza automáticamente** la lista de `Compile Sources` de un proyecto Xcode que ya estaba abierto.

Si Xcode muestra `Cannot find 'WatchHealthKitSession' in scope` en `WatchSessionHub.swift`:

1. Cerrar Xcode. Guardar antes cualquier cambio local que se quiera conservar.
2. Actualizar `main` sin sobrescribir cambios locales; recomendamos abrir **`Repera-Xcode.command`**, que realiza fast-forward seguro y regenera con XcodeGen. Alternativamente:
   ```bash
   cd /Users/ramon/Proyectos/repera
   git pull --ff-only origin main
   xcodegen generate --spec project.yml
   python3 scripts/check_xcode_sources.py
   open Repera.xcodeproj
   ```
3. La comprobación tiene que confirmar que `Apps/ReperaWatch/Sources/WatchHealthKitSession.swift` existe y está dentro de **ReperaWatch → Build Phases → Compile Sources**. No basta con que aparezca en el navegador del proyecto.
4. Compilar `ReperaWatch`. Si el error persiste, verificar primero la ruta del proyecto que Xcode tenga abierto y luego usar **Product → Clean Build Folder** (sin borrar datos personales ni DerivedData manualmente).

La verificación automatizada vive en `scripts/check_xcode_sources.py` y `tests/test_xcode_sources.py`; se ejecuta tras `xcodegen generate` y en el job XcodeGen de CI. La comprobación de pertenencia a un target no sustituye a una compilación real con el SDK watchOS.
