# Repera · Watch/Wear sensores, complicación y bloqueo (31/10/2026)

## Cambios
- watchOS: una sesión HealthKit iniciada *en el Watch* entrega FC actual y kcal activas con builder; nunca se calculan desde GPS. El entrenamiento autónomo se guarda en Salud.
- Comenzar propiedad de iPhone: cuando el snapshot llega al Watch sin otro workout activo, se solicita una sesión de HealthKit local para obtener sensores; `mirrorsToPhone=false` y se **descarta** al terminar/revisar. Se evita duplicar un HKWorkout ya propiedad del iPhone.
- Wear: Health Services lee FC/calorías tanto en entrenamiento programado como en Comenzar companion, con ExerciseType.WALKING cuando corresponde y sin segundo GPS; si una métrica no está disponible se mantiene el guion.
- Zonas cardíacas 1–5: cinco segmentos, con FCmáx provisional de 190 lpm. No presentar estas zonas estimadas como zonas clínicas personalizadas.
- Apple Watch: `WKSupportsLiveActivityLaunchAttributeTypes` permite abrir la app del reloj al tocar la Live Activity de iPhone. La Smart Stack tiene formato `ActivityFamily.small` propio.
- Complicación de esfera: extensión y watch app comparten el estado mediante App Group `group.com.app.repera.watch`. Circular: FC/tiempo; rectangular: tiempo, distancia, FC, kcal. Si no hay sesión, aparece marca.
- En el modo accented de watchOS, Apple puede reemplazar los colores: se usa marca legible de una tinta en lugar de forzar un PNG opaco que se vuelve una mancha.
- Android: un mensaje de inicio desde Wear puede atenderse con el móvil bloqueado; si Android rechaza arrancar un FGS de ubicación en segundo plano, el estado se revierte y el reloj recibe el motivo.

## Configuración obligatoria de Apple Signing
Registrar el App Group `group.com.app.repera.watch` en Apple Developer y habilitarlo en los identificadores y provisioning profiles de `com.app.repera.watchkitapp` y `com.app.repera.watchkitapp.widget`. Sin esta capacidad compartida, el widget se mostrará inactivo y Xcode puede rechazar la firma.

## Límites importantes
- La FC exacta y las kcal dependen de sensores, permisos y disponibilidad real. No inventar números ni estimar calorías.
- WidgetKit limita la cadencia de actualización de las complicaciones. La pantalla de la app refleja muestras tan pronto como las entregue Salud; la esfera no puede garantizar un refresco por segundo.
- Cuando el Watch empieza un entrenamiento **sin conexión al móvil**, ActivityKit no garantiza iniciar una Live Activity en el iPhone bloqueado. Para un inicio remoto garantizado necesitaríamos App Intents con condiciones de ejecución compatibles o push-to-start de ActivityKit mediante APNs y backend (no incluido). El modo conectado que delega Comenzar en iPhone usa el inicio local existente.
- Android 14+ puede impedir iniciar un FGS de ubicación desde un evento en segundo plano. Mostrar el error y pedir abrir el móvil, nunca informar de una grabación que no ha comenzado.

## Pruebas pendientes en dispositivos reales
1. Apple Watch inicia caminata: conceder Salud, comprobar FC y kcal (incluyendo 0 inicial), zonas, pausa y reanudación; finalizar y verificar solo un HKWorkout.
2. iPhone inicia Comenzar: reloj abierto obtiene FC/kcal reales, la Smart Stack muestra métricas, tocarla abre Repera **Watch** y no iPhone; pausa/reanuda y cierra sin sesión duplicada en Salud.
3. Añadir complicación circular y rectangular en distintas esferas y editor: no aparece un disco negro opaco. Confirmar actualización y tap de navegación al reloj.
4. Wear inicia caminata con Android desbloqueado, luego bloqueado: Health Services entrega FC/kcal, zonas, y se muestra notificación persistente de Android; controles de pausa/fin coherentes.
5. Repetir con permisos denegados, Bluetooth desconectado, apps terminadas, optimización de batería y móvil en segundo plano. Verificar mensajes de error precisos y sin duplicar sesiones.
6. Compilar en Xcode con perfiles App Group y ejecutar Android unit tests, instrumentados en Wear real y revisión de permisos Health Services.
