# Seguimiento GPS deportivo unificado — Repera iOS

Última actualización: 2026-10-25
Estado: implementación integrada en `main` (PR #75); compilación iOS/watchOS y contratos de arquitectura verificados, **validación funcional con iPhone físico pendiente**.

Esta es la referencia técnica para GPS, rutas, Apple Salud, actividad en directo y entrenamientos libres/programados. La descripción de producto está en [FEATURES.md](FEATURES.md) y el contexto general en [ARCHITECTURE.md](ARCHITECTURE.md). La fuente de verdad definitiva es el código.

## Objetivo y responsabilidades

Evitar dos desarrollos paralelos: `Comenzar` (sesión libre) y `Play` (entrenamiento programado) usan **el mismo servicio de localización** y reglas de aceptación de puntos. HealthKit, MapKit y ActivityKit consumen esos resultados; ninguno debe volver a calcular su propia distancia a partir de una ruta simplificada.

| Capa | Archivo principal | Responsabilidad |
| --- | --- | --- |
| GPS compartido | `Apps/Repera/Sources/Location/WorkoutLocationTracker.swift` | Permisos, único `CLLocationManager` para entrenamiento, background, validación, distancia, muestras, snapshots y entrega de cambios |
| Actividad libre | `Apps/Repera/Sources/LiveActivityView.swift` | Estado de la sesión libre, parciales, navegación por GPX, audio y presentación de métricas |
| Entrenamiento programado | `Apps/Repera/Sources/ReperaStore.swift` | Inicio/cierre de `Play`, clasificación de exterior, recuperación y persistencia de la sesión |
| Salud | `Apps/Repera/Sources/HealthKitStore.swift` | `HKWorkoutBuilder`, `HKWorkoutRouteBuilder`, autorización, datos de Salud, asociación exacta y reintentos |
| Pantalla bloqueada | `Apps/Repera/Sources/WorkoutLiveActivityCoordinator.swift` y `Apps/ReperaRestWidget/` | Construcción/publicación de `ActivityKit.ContentState`; no son propietarios del GPS |
| Modelos compartidos | `Packages/ReperaDomain/Sources/ReperaDomain/Models.swift` | `WorkoutSession`, `WorkoutRoutePoint`, precisión opcional compatible con rutas previas |
| Mapa de sesión/histórico | `Apps/Repera/Sources/HistoryView.swift` y `CardioRouteComponents.swift` | Dibujado de tramos, ritmo/color, altitud y datos meteorológicos |
| Ciclo de vida | `Apps/Repera/Sources/ReperaApp.swift` | Arranque, reconciliación de HealthKit y recuperación de sesiones programadas |

## Flujo de principio a fin

1. **Iniciar:** `Comenzar` crea un UUID estable para la sesión GPS y lo utiliza después como identificador del `WorkoutSession`. `Play` usa `WorkoutSession.id`. Nunca iniciar una segunda captura deportiva mientras otra sesión ocupe el GPS.
2. **Permisos:** solicitar ubicación «al utilizar la app» cuando sea necesario; solicitar escritura de workouts y rutas a Salud por separado. Sin permisos de Salud se conserva el entrenamiento local. La actividad de Apple Watch tiene prioridad: no crear una segunda captura HealthKit del mismo entrenamiento.
3. **Captura:** `WorkoutLocationTracker.shared.startRouteTracking` configura Core Location con `activityType = .fitness` y precisión alta; si el `Info.plist` efectivo declara `UIBackgroundModes/location`, habilita ubicación en segundo plano y `CLBackgroundActivitySession`.
4. **Validación:** el gestor recibe todos los puntos entregados por Core Location, incluso en lotes tras el bloqueo. Descarta precisiones horizontales superiores a 35 m, marcas de tiempo imposibles o no ordenadas y movimientos inverosímiles. Saltos o cortes mayores de 30 s abren un segmento nuevo **sin añadir una recta a la distancia**.
5. **Persistencia:** cada punto aceptado se incorpora sin reducir a un límite de 400 vértices; se guardan marca temporal, velocidad, altitud y precisiones reales. El checkpoint local se asocia al UUID de sesión. Los puntos no recibidos durante una suspensión o cierre forzado **no se inventan**.
6. **Publicación:** distancia GPS verificada y tiempo activo producen ritmo/velocidad media para la vista y la actividad en directo. `ActivityKit` puede retrasar visualmente las actualizaciones: no debe prometerse refresco fijo cada cinco segundos.
7. **Salud:** el entrenamiento local usa `HKWorkoutBuilder`; la ruta utiliza su `HKWorkoutRouteBuilder` cuando está disponible, con inserciones progresivas y originales `CLLocation`. Tras finalizar, únicamente se enlaza a un `HKWorkout` cuya metadata `ReperaSessionID` coincide con el UUID de la sesión. La ruta se guarda localmente si Salud falla; no enlazar por simple coincidencia temporal.
8. **Finalizar:** detener GPS y liberar la actividad de fondo; preservar el workout, la ruta y su estado de sincronización. No sobrescribir la ruta de una sesión cuyo propietario real sea Apple Watch.

## Diferencias deliberadas por tipo de entrenamiento

| Aspecto | Comenzar | Play programado |
| --- | --- | --- |
| GPS de exterior | Motor compartido | Mismo motor compartido, solo si sesión detectada como exterior |
| Identificador | UUID de la actividad libre | `WorkoutSession.id` |
| Ritmo y distancia | GPS + duración activa; parciales de km | GPS común en widget outdoor; fuerza/WOD indoor conserva ejercicios y series |
| Navegación por GPX/audio | Gestión de la vista libre | No se crea un segundo navegador ni una segunda captura GPS |
| Guardado | Workout libre, ruta y resultado | Workout prescrito + resultados, y ruta si hubo ubicación válida |
| Recuperación | Tras relanzamiento se restaura **pausada** | Se intenta recuperar la captura de la sesión programada aún activa por UUID |

**Atención:** la detección de «outdoor» en planes sin deporte explícito se basa en títulos/movimientos. No debe activar GPS de forma automática para ergómetros interiores (SkiErg, Assault Bike, cinta, etc.). Revisar esta clasificación cuando se amplíe el catálogo. No presentar como comprobado que las pausas de todos los tipos de `Play` detienen GPS si no existe test funcional específico.

## Precisión, pausas y energía

- `WorkoutRoutePoint.horizontalAccuracyMeters` y `verticalAccuracyMeters` son opcionales para conservar compatibilidad con datos históricos. Nunca sustituir una precisión desconocida por una cifra ficticia como 15 m.
- Se usa el GPS para distancia y geometría; el color representa el ritmo/velocidad de los tramos válidos. Un corte de señal no puede convertirse en una línea recta dibujada.
- Simplificar o agrupar segmentos **solo al representar el mapa**, sin modificar las muestras originales que se archivan o se adjuntan a Salud.
- El modo de alta precisión y la grabación continua consumen batería: su optimización adaptativa por disciplina requiere mediciones reales en dispositivo, no una promesa basada en el simulador.
- La actividad en directo no es una tarea de ejecución: recibe datos del grabador. El sistema puede limitar su frecuencia de visualización.

## Privacidad y límites de plataforma

- Apple Salud y Core Location necesitan permisos independientes; una negativa no debe impedir guardar el resultado local.
- El espejo de entrenamientos de Supabase no debe recibir coordenadas, ruta completa ni otros datos privados de HealthKit. WeatherKit recibe coordenada redondeada para la consulta histórica, no un archivo GPX.
- `HKWorkoutRouteBuilder` **no captura GPS por sí mismo**; Core Location es la fuente en iPhone. HealthKit sirve para persistir/compartir datos del workout autorizado.
- El uso de `CLLocationManager` y `CLBackgroundActivitySession` es nativo de Apple. El motor compartido todavía **no** ha migrado a `CLLocationUpdate.liveUpdates` ni `CLServiceSession`; evaluar su adopción por separado, con una migración medida y pruebas.
- Ni la actividad en directo ni la app garantizan reconstrucción de rutas en periodos sin callbacks. Si el usuario fuerza el cierre o iOS termina el proceso pueden perderse puntos y la continuidad de la ruta.
- Las voces internas de Siri no se exponen directamente a apps de terceros: las indicaciones utilizan voces españolas disponibles mediante `AVSpeechSynthesizer`.

## Avisos de kilómetro y audio en segundo plano (27/10/2026)

- **Comenzar → actividades con GPS:** al superar cada kilómetro GPS aceptado se calcula el tiempo activo exacto del tramo interpolando la muestra del cruce, sin contar pausas. La locución anuncia el número de kilómetro, su tiempo y velocidad media en km/h, **también para Caminata y Senderismo**; desde el km 2 añade velocidad media acumulada hasta ese punto. Los números se leen en español. No se inventa frecuencia cardíaca ni calorías no medidas.
- **Comenzar → cuenta atrás sonora (todos los deportes):** pulsar Iniciar reproduce 3 pitidos compartidos con el Temporizador mediante `RestFeedback.tick(3, 2, 1)` y, al llegar a cero, `RestFeedback.restComplete`. La captura de GPS/Salud y el tiempo activo comienzan **tras** los tres segundos. Durante el precalentamiento el botón muestra el segundo restante y puede pulsarse Cancelar. Al finalizar se emite únicamente la misma señal de fin del temporizador, sin locución de «Entrenamiento finalizado». **Pausa y Reanudación** siguen anunciándose mediante `LiveSessionVoiceAnnouncement` y `AVSpeechSynthesizer`. No se generan locuciones por redibujar, volver a primer plano o recuperar una sesión interrumpida.
- **Preferencias antes de comenzar (27/10/2026):** el icono de voz también aparece con la sesión en estado `idle`, tanto en el encabezado de Métricas (deportes de interior) como sobre el mapa (deportes con GPS). El grabador compartido carga `repera.live.spokenGuidance.enabled` de `UserDefaults`: primera apertura **activado**, después última selección, incluso al cerrar o reiniciar la app. `speakNavigation` aplica esa preferencia a los avisos hablados de pausa, reanudación, parciales y giros; `RestFeedback` recibe el mismo booleano para silenciar cuenta atrás y finalización. Con voz desactivada nunca se generan frases; al desactivar se cancelan también las pendientes.
- **Tipo de mapa:** en Comenzar la vista inicial es **plana 2D** (`@AppStorage("repera.live.map.navigation3D.enabled") = false`); cuando el usuario selecciona modo navegador 3D o vuelve a plano, la última elección se persiste automáticamente y se conserva al iniciar, finalizar, girar el dispositivo, regresar a la pestaña o relanzar la aplicación. No altera la configuración de los mapas de históricos.
- El mismo interruptor de voz de Comenzar se muestra en actividades GPS y sin GPS. Si el usuario lo desactiva, tanto las indicaciones del recorrido como los avisos de estado permanecen silenciados. Los cambios de fase son prioritarios y cancelan avisos de km o giros antiguos; no se reanuda una frase de otra fase.
- **Finalizar y guardar:** el aviso final es un `SystemSound` independiente del sintetizador hablado, por lo que la navegación al resumen o el guardado no lo cancela al limpiar locuciones pendientes. La locución de pausa/reanudación está en `ReperaDomain/LiveSessionVoiceAnnouncement.swift`; el temporizador y Comenzar comparten `RestFeedback` para las señales sonoras.

- El formateo independiente de SwiftUI es `ReperaDomain/KilometerVoiceAnnouncement.swift`; `LiveActivityRecorder.reportKilometer` reproduce el mensaje a través de `AVSpeechSynthesizer` en cuanto recibe el cruce de Core Location. Si el GPS entrega muestras por lotes con la pantalla bloqueada, usa los tiempos del cruce y no el momento en que el usuario reabre la app.
- `UIBackgroundModes = [location, audio]` en el Info.plist **real y en project.yml**; el grabador GPS permanece fuera de la jerarquía SwiftUI. La sesión `AVAudioSession(.playback, .spokenAudio)` permanece activa hasta terminar todas las frases encoladas; solo se libera cuando no hay pendientes, al silenciar la guía o al pausar/finalizar. Los demás reproductores pueden quedar temporalmente interrumpidos durante la locución.
- Si activar el audio falla se registra el error; en segundo plano se intenta un aviso visual *solo como respaldo* cuando ya está autorizado, sin prometer que sustituye al audio. El interruptor de voz del usuario se sigue respetando.
- **Límite iOS:** no hay locución garantizada cuando el usuario fuerza el cierre de la app, se pierde permiso de ubicación, el sistema deja de entregar GPS o interrumpe el audio por llamadas u otras causas. Los permisos/configuración no prueban por sí solos el resultado en un iPhone real.

## Validación y pruebas de regresión

Pruebas automáticas: `tests/test_unified_gps_contract.py`, `tests/test_kilometer_voice_background_contract.py`, `Packages/ReperaDomain/Tests/ReperaDomainTests/LiveSessionVoiceAnnouncementTests.swift` y `Packages/ReperaDomain/Tests/ReperaDomainTests/KilometerVoiceAnnouncementTests.swift` (tests Swift del formato), además del flujo invocado desde `.github/workflows/ios27-ci.yml`. Verifica que no se reintroduzca otro `CLLocationManager` en `Comenzar`, el único odómetro compartido, la preservación de precisiones y la asociación de rutas con el workout exacto. Son **contratos de código**, no sustituyen tests de sensores ni de ciclo de vida real.

Checklist manual imprescindible para dar la función por validada en producción:

- [ ] Caminar/correr con pantalla encendida, bloqueada, Dynamic Island y otra app en primer plano; comprobar que la distancia acumulada es coherente y que no depende de reabrir Repera.
- [ ] Caminata: cruzar km 1 y km 2 escuchando por voz el tiempo y velocidad media de cada tramo; con pantalla bloqueada, auriculares Bluetooth y música externa; comprobar que no se corta la segunda frase ni se duplican avisos.
- [ ] Comenzar una Caminata y otro deporte sin GPS: escuchar 3 pitidos, verificar que GPS y duración empiezan al llegar a cero; pausar/reanudar con voz, finalizar con señal de fin. Comprobar cambios rápidos, audio desactivado, botón Cancelar durante la cuenta y guardado inmediato tras Finalizar. Repetir con bloqueo de pantalla y auriculares.
- [ ] Antes de iniciar, verificar altavoz encendido por defecto en mapa y en Métricas; desactivar, iniciar y comprobar silencio total. Terminar y relanzar: debe mantenerse apagado; volver a activar y comprobar las locuciones.
- [ ] Primera apertura del mapa en plano 2D. Cambiar a modo navegador 3D, rotar, navegar a Métricas y volver, terminar y reiniciar la app: debe mantenerse 3D. Volver a plano, cerrar y comprobar que 2D se conserva.
- [ ] Comprobar locuciones al recibir GPS por lotes, al pausar y reanudar y con el control de voz silenciado. Probar también una llamada/uso de Siri durante la locución.
- [ ] Repetir en `Play` programado exterior; confirmar coincidencia de mapa, detalle histórico, Live Activity y Salud.
- [ ] Repetir con fuerza/CrossFit y ergómetros interiores: no debe capturar una ruta exterior por error.
- [ ] Pausar, reanudar y terminar ambos flujos; no conectar segmentos separados ni sumar movimientos de la pausa.
- [ ] Crear una zona de mala cobertura GPS y comprobar que no aparecen rectas ni kilómetros inventados.
- [ ] Relanzar la app con una sesión pendiente, tanto libre como programada; verificar los checkpoints y que no se pierden ni duplican rutas.
- [ ] Denegar permisos de Salud, permitirlos después y comprobar reintento sin duplicar `HKWorkout`.
- [ ] Registrar desde Apple Watch con iPhone cerca: una única sesión sanitaria y ruta de la fuente propietaria.
- [ ] Medir batería y temperatura en sesiones prolongadas por deporte y comprobar los efectos de la reproducción de música y la guía hablada.

## Cambios futuros: una sola implementación

Cualquier cambio de filtrado, permisos GPS, cortes de señal, distance filter, validación, checkpoint o precisión se hace en `WorkoutLocationTracker` y se prueba en **Comenzar y Play**. No copiar ese algoritmo a SwiftUI, Watch widgets o HealthKit. Las pantallas deben consumir el mismo estado publicado. Actualizar este documento, `ARCHITECTURE.md`, `FEATURES.md` y las pruebas cuando cambie la semántica.

Referencias internas: [PR #75](https://github.com/rmoya87/repera/pull/75) (GPS unificado) y [PR #73](https://github.com/rmoya87/repera/pull/73) (métricas, voz y mapas). 
