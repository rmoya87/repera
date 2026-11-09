# En vivo (iOS 27)

Última actualización: 2026-11-09 (resumen outdoor: mapa tras tiles).

## Experiencia

La tercera pestaña es **Comenzar** (antes «En vivo»). Se puede seleccionar deporte y grabar una actividad libre sin crear una plantilla. Los deportes con GPS muestran mapa y métricas, mientras que los demás utilizan una pantalla simplificada con cronómetro. La grabación permite pausar, reanudar, finalizar, añadir un título y notas, y guardar.

Al **finalizar**, la pantalla «Guardar entreno» presenta un resumen estilo Fitness: tiles de tiempo/distancia/ritmo/energía, **mapa GPS outdoor justo debajo**, parciales, nombre/notas. **Guardar** es el checkmark de la toolbar/cabecera; **Descartar actividad** abre la modal inferior (`OGConfirmSheet` / `ReperaConfirmSheet`), no un diálogo de sistema. El confirm «Finalizar y revisar» usa fondo verde con texto negro.

El guardado llama a `ReperaStore.saveWorkout(_ :)`, creando un `WorkoutSession` con `phase = .finished`, `startedAt`, `finishedAt`, `liveSportID`, `activeDurationSeconds`, `recordedDistanceMeters` y `routePoints`. Se persiste con los mismos mecanismos local/iCloud que los entrenos habituales, incrementando `workoutsEpoch`. **Inicio agrupa los registros de Comenzar por el día local de inicio** (no por el de finalización); al guardarlos vuelve a Inicio seleccionando esa fecha. Las tarjetas permiten consultar el detalle, el mapa y la distancia. Las actividades también se encuentran en Historial y Progreso.

Última actualización: 2026-11-05.

## Ubicación y recorridos

`LiveActivityRecorder` es un `@MainActor @Observable` singleton que retiene la sesión independientemente de la vista. Solo se solicitan permisos de ubicación al iniciar un deporte con GPS. Usa `CLLocationManager` con soporte de actualización de ubicación en segundo plano mientras existe una sesión grabándose; en iOS se declara `UIBackgroundModes: location`.

Se filtran posiciones con poca precisión, fechas obsoletas y saltos implausibles. **La distancia registrada procede de posiciones aceptadas, nunca de la longitud de un GPX**. La grabación pausa la suma de distancia y tiempo activo durante descansos. Se guarda periódicamente una instantánea local para recuperar un registro tras una interrupción; al restaurar, la sesión queda **pausada** para no inventar tiempo.

La biblioteca de rutas se mantiene local mediante `LiveRoutesStore`. Se importan archivos GPX con `trkpt` o `rtept`, se dibuja el recorrido previsto sobre MapKit y se superpone la ruta real. Si el usuario está lejos de los puntos de la ruta se muestra un aviso básico; **no existe todavía navegación giro a giro, recalculado de trayectos ni mapas offline garantizados**. El modo de baja cobertura sigue registrando coordenadas si el sistema dispone de GPS y permiso, aunque los mapas base puedan requerir red.

## Apple Salud

`ReperaStore.syncWorkoutToHealth` envía el tipo de deporte y la ubicación indoor/outdoor apropiados a `HealthKitStore.finishWorkout`. Se conserva el emparejamiento por `ReperaSessionID` y la conciliación con el Watch para evitar duplicados. Las calorías y la frecuencia cardíaca **solo se presentan si Salud aporta datos auténticos**; el iPhone no genera estimaciones de sensores. Las pausas se conservan como duración activa de Repera, independientemente de la duración de pared que pueda tener un HKWorkout.

El recorrido registrado se guarda en el modelo de Repera y se visualiza en su detalle. En outdoor de iPhone se exporta como `HKWorkoutRoute` al finalizar (permiso de ruta + ≥2 puntos). En outdoor iniciado en Apple Watch, el propio Watch escribe la ruta en Salud; el iPhone no puede adjuntarla a un workout de `watchkitapp`. Al arrancar, `repairPastHealthKitExports` reintenta adjuntar rutas locales a workouts del iPhone y borra cáscaras 0 kcal huérfanas.

## Limitaciones y verificación en dispositivo

- Verificar en iPhone real permisos, GPS durante bloqueo de pantalla, retorno desde otras apps, pérdida de señal, avión/sin red, pausa/reanudación y desconexión del Watch.
- Confirmar que Apple Salud no duplica sesiones, y que una carrera se escribe como `running` y una bicicleta como `cycling`.
- Probar un GPX corto, uno largo, uno vacío o malformado y uno con coordenadas fuera de rango.
- Validar sesión empezada antes de medianoche y finalizada después: debe verse en Inicio en la fecha de inicio.
- Las clases y la edición avanzada de rutinas siguen entrando por Inicio/Diario. El centro profesional sigue accesible para perfiles vinculados.

## Pantalla bloqueada y Dynamic Island (ActivityKit)

`TrainingActivityAttributes` es un contrato pequeño y codificable compartido entre `Repera` y `ReperaRestWidget`. `TrainingLiveActivityWidget` presenta la misma identidad negra/verde de Repera en todos los deportes: nombre, estado, duración y dos métricas adaptadas al tipo. En pausa, la cabecera cambia a amarillo; al terminar se muestra brevemente el estado completado. La Dynamic Island incorpora modos expanded, compact y minimal. Tocar cualquiera de estas superficies abre `repera://live` o `repera://workout` (no existen botones inertes de pausa dentro del widget).

El reloj se renderiza localmente en el sistema con `Text(date, style: .timer)` y no necesita actualizar ActivityKit cada segundo. El coordinador `WorkoutLiveActivityCoordinator` publica inicio, pausa, reanudación, fin y cambios de métricas. Las actualizaciones GPS son como máximo aproximadamente una cada 15 segundos, aparte de las transiciones de estado. La Live Activity de descanso antigua se conserva como tipo independiente; el sistema decide cuál es visible si coinciden varias.

En los entrenamientos planificados (también los creados con OCR o recibidos del Apple Watch), `ReperaStore` publica el nombre de la sesión, ejercicio actual, progreso de ejercicios y número de series registradas. El widget se actualiza al mutar `activeSession`, persiste aunque `WorkoutView` deje de ser visible y se cierra al finalizar o descartar la sesión. El enlace en la Dynamic Island vuelve a Play si hay una sesión activa.

Apple impone límites de duración y actualización a las Live Activities; por tanto, **no debe confundirse su duración en pantalla con la persistencia y grabación del entrenamiento**. En dispositivos sin soporte de Dynamic Island sigue apareciendo la Live Activity de pantalla bloqueada si el sistema y el usuario la permiten. Sin permiso de Actividades en directo, se sigue grabando el entrenamiento de forma normal.

Los botones de **Pausar / Reanudar / Abrir** en bloqueo e isla usan `LiveActivityIntent` compartidos (`TrainingLiveActivityIntents.swift`): solo encolan un comando al proceso de Repera. La app aplica pausa/reanudación en `LiveActivityRecorder` tras hidratar identidad. **Abrir / Confirmar serie** navega a la sesión; nunca confirma series ni escribe HealthKit desde la extensión.

### Comprobaciones específicas

- Iniciar/pausar/reanudar/finalizar Carrera y comprobar que el tiempo queda congelado al pausar y continúa sin saltos al reanudar.
- Repetir con Bicicleta, HIIT y Pádel: nunca inventar velocidad, FC o calorías si falta el sensor.
- Empezar entrenamiento programado (fuerza/WOD/OCR), completar una serie y cambiar de ejercicio: el widget refleja el progreso.
- Bloquear el iPhone, abrir Dynamic Island, pulsar y confirmar navegación al flujo correcto.
- Comprobar coexistencia con la Live Activity del descanso (que sigue siendo independiente).
- Salir de la app durante una actividad y restaurar la sesión sin perder tiempo o distancia; si se restauró en pausa no contar el tiempo de interrupción.

## Espejo nativo y permisos de Watch (07/11/2026)

- Se eliminan de las Live Activities los textos «Registrando en Apple Watch» y «Control desde Apple Watch». «Abrir Repera» desde el iPhone abre `repera://live` (Comenzar). Deporte iniciado en Watch → misma `LiveActivityView` que phone-start; plan/clase → espejo de bloques. Smart Stack del reloj: `repera-watch://active`.
- El iPhone puede consultar las métricas reales Watch (tiempo, GPS, ritmo, FC y kcal) y enviar pausa, reanudación o finalización al propietario de la sesión, pero **no** registrar otro `HKWorkout`, GPS ni inventar métricas. WatchConnectivity verifica ámbito de cuenta y UUID; el reloj sigue siendo propietario de HealthKit.
- Si Salud ha denegado escritura de distancia, se conserva el entrenamiento y el GPS local; se omite la muestra de distancia no autorizada y se comunica el permiso requerido. El refresco de permisos del iPhone incluye compartir los tipos numéricos de distancia.
- El check verde del editor permite guardar también caminatas y otras actividades completadas sin bloques de ejercicios.
- Requiere validación con pareja física iPhone/Watch y compilación Xcode antes de certificar el comportamiento en TestFlight.

## Ajustes de bloqueo y apertura del Watch (06/11/2026)

- La tarjeta de bloqueo utiliza una distribución con título, tres métricas, parcial corto opcional y **botones siempre al final**, con margen superior, inferior y lateral homogéneo. Ya no existe una segunda línea «TRAMO». Si el texto del parcial ocupa demasiado, se oculta en lugar de recortar las métricas o acciones.
- Pausar/Reanudar muestran los iconos circulares nativos; «Abrir Repera» se pinta en verde y texto negro.
- La Smart Stack del reloj abre `repera-watch://active` (app instalada de watchOS), mientras bloqueo y Dynamic Island del iPhone conservan sus rutas `repera://`. El `Info.plist` de watchOS declara `WKSupportsLiveActivityLaunchAttributeTypes` para permitir abrir la app del reloj.
- Un entrenamiento libre iniciado en iPhone mantiene el editor y la ruta GPS en el teléfono; con Watch reachable + cuenta, el reloj escribe el **único** `HKWorkout` (mismo UUID). Si `startWatchApp` despertó el Watch no se abre builder iPhone 0 kcal; al Guardar se espera el workout del reloj. Handoff tardío si el Watch aparece a mitad. Controles Watch por `transferUserInfo` + `sendMessage`. Revisión → `finishCompanionHealthIfNeeded`. Gráficas FC/elevación con eje Y overlay (Progreso).
- Verificación física pendiente en iPhone + Apple Watch: apertura desde Smart Stack, tipografía grande, navegación GPX con avisos, pausa con botones físicos, GPS/FC/calorías, inicio con/desconexión de reloj, finalización, guardado y ausencia de duplicados en Salud. No hay compilación Xcode disponible en este entorno.
