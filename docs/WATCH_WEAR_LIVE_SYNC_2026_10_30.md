# Repera — sincronización Apple Watch / Wear OS y Comenzar (30/10/2026)

## Implementado en la rama de revisión
- Apple: los entrenamientos iniciados en Watch no se eliminan cuando el iPhone publica
  un *snapshot* sin sesión. Las transiciones terminales se envían por UUID y estado
  guardado/descartado. Las sesiones controladas por iPhone aceptan actualizaciones de
  su ejecución y el Watch mantiene HealthKit como dueño cuando él empezó el workout.
- iOS Comenzar → Watch: datos agregados (deporte, tiempo activo, distancia validada,
  velocidad media e indicación de ruta), sin transferir track GPS ni información
  sanitaria sensible. Watch interpola solo el reloj visible y pide al móvil pausar,
  reanudar o pasar a revisión. El guardado del workout libre sigue siendo explícito
  en el teléfono. No se crea un segundo HKWorkout en Watch por abrir esta pantalla.
- Android: Data Layer publica los mismos agregados de Comenzar y un receptor de
  mensajes controla la actividad desde Wear aunque MainActivity esté detenida.
  Wear muestra el estado de ejecución; no crea una segunda ruta.
- Wear: un estado vacío del teléfono no descarta un entreno iniciado sin conexión;
  el descarte explícito usa un evento terminal por UUID. Las series y el cierre
  llegan al servicio de recepción cuando el teléfono no tiene la Activity activa;
  la escritura es idempotente por ID de serie y solo se confirma tras persistencia.
  El cronómetro activo dispone de checkpoint para recuperación tras recreación.

## Hub 31/10/2026 (complemento)

Además del companion phone-owned, el hub Deportes permite iniciar un deporte
desde el reloj: con teléfono reachable usa `startLive` (el móvil abre Comenzar;
si había revisión abierta se descarta; Finalizar en el reloj → revisión en el
teléfono). Offline o con entreno programado activo graba en el reloj (HK + GPS)
y consolida al finalizar. Spec:
`docs/superpowers/specs/2026-10-31-watch-wear-hub-design.md`.

## Límites deliberados: no declarar paridad completa
1. El inicio autónomo desde el reloj existe en código (hub 31/10) pero **exige
   validación en hardware** (permisos ubicación, background workout, batería,
   reconciliación de rutas/HK con el teléfono). No declarar paridad completa
   hasta pasar la checklist de aceptación.
2. La lectura de métricas HealthKit/Health Services no se simula ni se deduce de
   distancia/repeticiones. Cuando el móvil posee la actividad libre el reloj
   acompaña y controla; no debe escribir otro workout de Salud.
3. El receptor Wear de background admite series/finalización; otros comandos
   de edición/cambio de ejercicio aún necesitan reconciliación posterior.
4. Múltiples sesiones programadas para el mismo día todavía precisan un
   selector de planes en ambos relojes.
5. CI y simuladores no sustituyen pruebas con sensores, Bluetooth, permisos y
   apps físicamente emparejadas.

## Condiciones de aceptación antes de integrar a main
- Comenzar caminata iPhone/Android con reloj pareado; cambio de pantalla,
  bloqueo, pausa y reanudación desde el reloj; distancia final igual al odómetro
  propietario y ninguna segunda ruta ni sesión de Salud.
- Watch/Wear inicia entrenamiento programado sin móvil; varios sets offline,
  reloj en reposo/reiniciado, reconexión, misma sesión y mismos UUID/series.
- Descarte explícito desde teléfono sincronizado con el reloj, sin dispararlo
  por un snapshot vacío anterior a la primera adopción.
- Dos entrenamientos sucesivos: el terminal del primero nunca cancela el segundo.
- Logout/cambio de cuenta: limpiar el estado de pantalla del wearable sin
  transportar registros de otra cuenta.
- Cronómetro en Wear reanudado tras recrear Activity y cambios de pausa.
- Completar CI iOS/watchOS, Android/Wear, tests de dominio e instrumentados.
- Probar pérdida de red, retrasos de HealthKit y cola de entrega de datos,
  con un solo registro final y un solo HKWorkout/Health Services por actividad.

## Archivos centrales
- Apps/Repera/Sources/PhoneConnectivity.swift
- Apps/ReperaWatch/Sources/WatchConnectivityClient.swift
- Apps/ReperaWatch/Sources/WatchSessionHub.swift
- Apps/ReperaWatch/Sources/WatchSessionView.swift
- Apps/Repera/Sources/LiveActivityView.swift
- Packages/ReperaDomain/Sources/ReperaDomain/WatchLiveActivitySnapshot.swift
- android/mobile/src/main/java/dev/repera/mobile/WearActiveSessionBridge.kt
- android/mobile/src/main/java/dev/repera/mobile/WearLiveCommandListener.kt
- android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt
- android/wear/src/main/java/dev/repera/wear/WearHomeContent.kt
