# Seguimiento GPS deportivo unificado — Repera iOS

Última actualización: 2026-10-27 (navegación GPX en Comenzar y widget ActivityKit)
Estado: implementación integrada en `main` (PR #75); compilación iOS/watchOS y contratos de arquitectura verificados, **validación funcional con iPhone físico pendiente**.

Esta es la referencia técnica para GPS, rutas, Apple Salud, actividad en directo y entrenamientos libres/programados. La descripción de producto está en [FEATURES.md](FEATURES.md) y el contexto general en [ARCHITECTURE.md](ARCHITECTURE.md). La fuente de verdad definitiva es el código.

## Audio y favoritos: ajustes 27/10/2026
- `RestFeedback` no llama `AVAudioSession.setActive/setCategory` desde `MainActor`: una cola serial activa/desactiva el hardware; un identificador de tono evita reproducir solicitudes obsoletas, y `.spokenAudio` protege la locución GPS durante la liberación. Validar en dispositivo real con Bluetooth, bloqueo y cambios de ruta de audio.
- Crear → Favoritos permite editar la plantilla con un swipe a la derecha (lápiz azul); la eliminación roja permanece en el swipe opuesto y los cambios guardados se reutilizan en futuras sesiones.

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
- **Comenzar → cuenta atrás sonora (todos los deportes):** pulsar Iniciar reproduce 3 pitidos compartidos con el Temporizador mediante `RestFeedback.tick(3, 2, 1)` y, al llegar a cero, `RestFeedback.restComplete`. La captura de GPS/Salud y el tiempo activo comienzan **tras** los tres segundos. Durante el precalentamiento el botón muestra el segundo restante y puede pulsarse Cancelar. Al finalizar se emite únicamente la misma señal de fin del temporizador, sin locución de «Entrenamiento finalizado». **Pausa y Reanudación** no emiten voz ni sonido. Se interrumpe cualquier indicación GPS pendiente al cambiar de fase; las únicas locuciones siguen siendo kilómetros y giros. No se generan locuciones por redibujar, volver a primer plano o recuperar una sesión interrumpida.
- **Preferencias antes de comenzar (27/10/2026):** el icono de voz también aparece con la sesión en estado `idle`, tanto en el encabezado de Métricas (deportes de interior) como sobre el mapa (deportes con GPS). El grabador compartido carga `repera.live.spokenGuidance.enabled` de `UserDefaults`: primera apertura **activado**, después última selección, incluso al cerrar o reiniciar la app. `speakNavigation` aplica esa preferencia a los avisos hablados de parciales y giros; `RestFeedback` recibe el mismo booleano para silenciar cuenta atrás y finalización. Con voz desactivada nunca se generan frases; al desactivar se cancelan también las pendientes.
- **Tipo de mapa:** en Comenzar la vista inicial es **plana 2D** (`@AppStorage("repera.live.map.navigation3D.enabled") = false`); cuando el usuario selecciona modo navegador 3D o vuelve a plano, la última elección se persiste automáticamente y se conserva al iniciar, finalizar, girar el dispositivo, regresar a la pestaña o relanzar la aplicación. No altera la configuración de los mapas de históricos.
- El mismo interruptor de audio se muestra en actividades GPS y sin GPS. Si se desactiva, los pitidos de inicio y finalización y las locuciones de kilómetros/giros permanecen silenciados. Los cambios de fase cancelan locuciones antiguas; pausar y reanudar nunca generan aviso de audio.
- **Finalizar y guardar:** el aviso final utiliza `AVAudioPlayer` con un WAV generado en memoria, independiente del sintetizador hablado, por lo que la navegación al resumen o el guardado no lo cancela al limpiar locuciones pendientes. El temporizador y Comenzar comparten `RestFeedback` para las señales sonoras, sin textos de inicio, pausa, reanudación ni fin.

- El formateo independiente de SwiftUI es `ReperaDomain/KilometerVoiceAnnouncement.swift`; `LiveActivityRecorder.reportKilometer` reproduce el mensaje a través de `AVSpeechSynthesizer` en cuanto recibe el cruce de Core Location. Si el GPS entrega muestras por lotes con la pantalla bloqueada, usa los tiempos del cruce y no el momento en que el usuario reabre la app.
- `UIBackgroundModes = [location, audio]` en el Info.plist **real y en project.yml**; el grabador GPS permanece fuera de la jerarquía SwiftUI. La sesión `AVAudioSession(.playback, .spokenAudio)` permanece activa hasta terminar todas las frases encoladas; solo se libera cuando no hay pendientes, al silenciar la guía o al pausar/finalizar. Los demás reproductores pueden quedar temporalmente interrumpidos durante la locución.
- Si activar el audio falla se registra el error; en segundo plano se intenta un aviso visual *solo como respaldo* cuando ya está autorizado, sin prometer que sustituye al audio. El interruptor de voz del usuario se sigue respetando.
- **Límite iOS:** no hay locución garantizada cuando el usuario fuerza el cierre de la app, se pierde permiso de ubicación, el sistema deja de entregar GPS o interrumpe el audio por llamadas u otras causas. Los permisos/configuración no prueban por sí solos el resultado en un iPhone real.

- **Cabecera de Métricas y Mapa:** Audio, Mapa y Pausa/Reanudar son tres botones de 44 pt contiguos con 6 pt entre centros de superficies, alineados al margen derecho `OG.topBarHorizontalInset`. Pausa/Reanudar ocupa el extremo derecho (mismo eje horizontal que el primer control de la vista Mapa); al pausar aparece Finalizar a la izquierda de Audio, sin mover los tres restantes. Se eliminan los subtítulos «Grabando actividad» y «En pausa»; la separación flexible se coloca entre el nombre del deporte y Audio. El título usa como máximo dos líneas y se adapta a tamaños compactos.

- **Sonido compartido (Comenzar y Temporizador):** `RestFeedback` usa un tono medio (fundamental **523,25 Hz, Do5**) sintetizado localmente por `AVAudioPlayer`, sin sonidos de sistema con distinta melodía. Cada segundo de la cuenta 3, 2, 1 suena una nota breve de **0,16 s**; el paso a cero y la finalización reproducen **la misma nota** sostenida **0,49 s** (duración intermedia entre 0,16 y los 0,82 s anteriores). Respetar el interruptor de audio; el gestor no desactiva una locución GPS que entre mientras se está liberando el tono. Pausa/reanudación siguen silenciosas.
- **Tarjeta de mapa/tiempo:** `RouteWeatherStrip` presenta icono grande a la izquierda y título/valor apilados a la derecha en cada una de las tres columnas. La fila textual independiente «Apple Weather» se elimina; por requisitos de WeatherKit se conserva una marca oficial discreta enlazada a `attribution.legalPageURL`. `HealthWorkoutRouteMap` añade margen vertical y desplaza ligeramente al norte la cámara **solo en la vista previa**, evitando que se recorte el halo superior de la ruta sin modificar coordenadas.

## Pendiente de verificación en iPhone / TestFlight (27/10/2026)

Las pruebas de contrato en CI comprueban la presencia de la lógica y sus invariantes, pero **no acreditan que el sonido ni los mapas se comporten correctamente en un dispositivo**. Para cerrar el trabajo de Comenzar quedan estas comprobaciones manuales:

- Comparar el tono medio de los segundos **3, 2 y 1** (0,16 s) con la señal de **cero** y **finalización** (0,49 s), asegurando mismo timbre y volumen cómodo mediante altavoz y auriculares Bluetooth. El antiguo aviso del sistema ya no debe escucharse.
- Verificar que **audio desactivado** silencia tanto los tonos como los anuncios GPS, y que la preferencia y el mapa 2D/3D persisten tras salir y relanzar. Comprobar pausas/reanudaciones sin locuciones.
- Repetir una caminata real con **pantalla bloqueada y la app en segundo plano**. Comprobar kilómetros anunciados solo con GPS válido, interrupciones de llamada/Siri y reanudación de otros reproductores. iOS puede suspender ubicación/audio; no afirmar garantía absoluta.
- Revisar en iPhone pequeño y horizontal que Audio/Mapa/Pausa queden juntos, sin salto al aparecer Finalizar; que el mapa de historial muestre toda la curva superior; y que Tiempo/Humedad/Viento estén legibles y con atribución legal WeatherKit accesible.
- Compilar con **Xcode iOS 27**, ejecutar los tests Swift y la suite Python del pipeline y distribuir una nueva build de TestFlight. La inspección del código no reemplaza esa validación.

## Validación y pruebas de regresión

Pruebas automáticas: `tests/test_unified_gps_contract.py`, `tests/test_kilometer_voice_background_contract.py`, `Packages/ReperaDomain/Tests/ReperaDomainTests/KilometerVoiceAnnouncementTests.swift` (tests Swift del formato), además del flujo invocado desde `.github/workflows/ios27-ci.yml`. Verifica que no se reintroduzca otro `CLLocationManager` en `Comenzar`, el único odómetro compartido, la preservación de precisiones y la asociación de rutas con el workout exacto. Son **contratos de código**, no sustituyen tests de sensores ni de ciclo de vida real.

Checklist manual imprescindible para dar la función por validada en producción:

- [ ] Caminar/correr con pantalla encendida, bloqueada, Dynamic Island y otra app en primer plano; comprobar que la distancia acumulada es coherente y que no depende de reabrir Repera.
- [ ] En Métricas comprobar que no hay texto «Grabando actividad»/«En pausa» y que Audio, Mapa y Pausa permanecen contiguos, al borde derecho, sin saltos al pausar; en pausa, Finalizar se añade a su izquierda. En detalle de la actividad, el mapa mantiene toda la curva superior visible y el clima aparece con icono a la izquierda, sin línea textual de marca.
- [ ] Comparar los tres pitidos de tono medio (523,25 Hz) de 3, 2, 1 con el tono sostenido de 0,49 s al llegar a cero y al finalizar; deben conservar el mismo timbre con distinta duración y no interrumpir locuciones GPS posteriores.
- [ ] Caminata: cruzar km 1 y km 2 escuchando por voz el tiempo y velocidad media de cada tramo; con pantalla bloqueada, auriculares Bluetooth y música externa; comprobar que no se corta la segunda frase ni se duplican avisos.
- [ ] Comenzar una Caminata y otro deporte sin GPS: escuchar 3 pitidos, verificar que GPS y duración empiezan al llegar a cero; pausar/reanudar sin audio, finalizar con señal de fin. Comprobar cambios rápidos, audio desactivado, botón Cancelar durante la cuenta y guardado inmediato tras Finalizar. Repetir con bloqueo de pantalla y auriculares.
- [ ] Antes de iniciar, verificar altavoz encendido por defecto en mapa y en Métricas; desactivar, iniciar y comprobar silencio total. Terminar y relanzar: debe mantenerse apagado; volver a activar y comprobar las locuciones.
- [ ] Primera apertura del mapa en plano 2D. Cambiar a modo navegador 3D, rotar, navegar a Métricas y volver, terminar y reiniciar la app: debe mantenerse 3D. Volver a plano, cerrar y comprobar que 2D se conserva.
- [ ] Comprobar locuciones al recibir GPS por lotes y que se interrumpen al pausar; verificar silencio tanto al pausar como al reanudar y con el control de voz silenciado. Probar también una llamada/uso de Siri durante la locución.
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


## Navegación de rutas GPX en Comenzar (27/10/2026)

- Al cargar una ruta y comenzar, la vista permanece en **Mapa** (también en vertical y horizontal); Métricas sigue accesible mediante su botón y conserva una indicación compacta. No se cambia de pantalla automáticamente cuando existe una ruta.
- El aviso verde de navegación se muestra mientras haya una ruta seleccionada, incluso durante la espera de GPS, al seguir recto, al llegar al final o fuera del recorrido. La próxima maniobra se estima por los ángulos del GPX, no por una ruta de coche recalculada; el rumbo inicial, la precisión GPS y los vértices del archivo afectan a los giros que se pueden detectar.
- Cuando MapKit devuelve una dirección en el punto situado aproximadamente 25 m después del giro, se presenta el **nombre de la vía orientativo**. La consulta se hace una vez por maniobra y se cancela al cambiar de tramo/ruta. Si no hay calle, cobertura o conectividad, se conserva la flecha y la instrucción sin inventar nombres.
- ActivityKit comparte únicamente instrucción, símbolo, distancia al giro y calle orientativa, sin enviar coordenadas. La Live Activity adapta el panel a navegación + duración, ritmo/velocidad y kilómetros en pantalla bloqueada y Dynamic Island expandida. La isla compacta prioriza flecha y distancia al próximo giro, y mantiene el cronómetro cuando no hay maniobra con distancia.
- **Pendiente de validación real en iPhone/TestFlight:** GPX urbano con giro, GPX recto y sendero sin calles, ruta alejada/fuera de ruta, bloqueo/Dynamic Island, permisos GPS, modo apaisado y ausencia de red. iOS limita la cadencia de ActivityKit en segundo plano.
