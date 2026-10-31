# Repera · Watch/Wear sensores, complicación y bloqueo (31/10/2026)

## Cambios
- watchOS: una sesión HealthKit iniciada *en el Watch* entrega FC actual y kcal activas con builder; nunca se calculan desde GPS. El entrenamiento autónomo se guarda en Salud.
- Comenzar propiedad de iPhone: cuando el snapshot llega al Watch sin otro workout activo, se solicita una sesión de HealthKit local para obtener sensores; `mirrorsToPhone=false` y se **descarta** al terminar/revisar. Se evita duplicar un HKWorkout ya propiedad del iPhone.
- Wear: Health Services lee FC/calorías tanto en entrenamiento programado como en Comenzar companion, con ExerciseType.WALKING cuando corresponde y sin segundo GPS; si una métrica no está disponible se mantiene el guion.
- Zonas cardíacas 1–5: cinco segmentos, con FCmáx provisional de 190 lpm. No presentar estas zonas estimadas como zonas clínicas personalizadas.
- Apple Watch: `WKSupportsLiveActivityLaunchAttributeTypes` permite abrir la app del reloj al tocar la Live Activity de iPhone. La Smart Stack tiene formato `ActivityFamily.small` propio.
- Complicación de esfera: extensión y watch app comparten el estado mediante App Group `group.com.app.repera.watch`. Circular/esquina: acceso directo con mascota de Repera; rectangular: mascota, tiempo, distancia, FC y kcal con sesión, o «Iniciar actividad» sin sesión; inline: título de la sesión o «Repera».
- **Corrección del círculo negro en las esferas watchOS:** el PNG oficial `ReperaIcon/repera.png` sigue siendo exactamente el `AppIcon.png` de iPhone y Watch (no se modifica). En `accessoryCircular` y `accessoryCorner` los modos tintados de WidgetKit ahora reciben **únicamente la cara del muñeco**, recortada digitalmente de ese icono y transformada en una plantilla monocromática blanca con alfa real. El fondo verde se descarta; los ojos, sonrisa y cinta oscuros quedan como huecos transparentes. **No se dibuja `Circle()` ni se emplea `.desaturated` para la cara**, para impedir que el fondo opaque toda la complicación. En `.fullColor`, cuando la familia de widget y esfera lo permiten, se conserva el AppIcon multicolor original. watchOS elige el color final de la plantilla según la esfera; no se fuerza el verde corporativo en una esfera tintada.
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
3. Instalar una nueva build, eliminar el acceso anterior y añadir la nueva complicación `brand2`. En circular/esquina, comprobar **solo el rostro visible, sin círculo negro ni fondo opaco**, y los ojos y sonrisa recortados en modo tintado (la esfera decide los colores); en rectangular `fullColor` debe aparecer exactamente el PNG oficial. Probar selector y esfera, modo con/sin sesión, placeholder, snapshot y timeline, y navegación al tocar.
4. Wear inicia caminata con Android desbloqueado, luego bloqueado: Health Services entrega FC/kcal, zonas, y se muestra notificación persistente de Android; controles de pausa/fin coherentes.
5. Repetir con permisos denegados, Bluetooth desconectado, apps terminadas, optimización de batería y móvil en segundo plano. Verificar mensajes de error precisos y sin duplicar sesiones.
6. Compilar en Xcode con perfiles App Group y ejecutar Android unit tests, instrumentados en Wear real y revisión de permisos Health Services.

## Diagnóstico y comprobaciones de empaquetado (31/10/2026)
- Las imágenes antiguas `ReperaComplicationIcon` (66/132/198 px) tienen fondo opaco y no deben usarse para renderizar complicaciones. El código nuevo extrae una plantilla transparente de la cara del PNG oficial de Repera; el anterior `ReperaComplicationAppIconStore` tampoco participa en el widget.
- El target `ReperaWatchWidget` **sí empaqueta** `Assets.xcassets` y el PNG oficial, con `ReperaIcon` en su `Assets.car`. Ya no se utilizan los antiguos iconos opacos `ReperaComplicationIcon` ni los PNG sueltos; `AppIcon` del target principal `ReperaWatch` sigue intacto.
- CI ejecuta `tests/test_watch_complication_contract.py`, verifica igualdad SHA-256 de **iPhone, Apple Watch y complicación**, obliga a una única imagen canónica `ReperaIcon/repera.png` (sin PNG `@2x`/`@3x` huérfanos en el imageset; provocan «unassigned children» en Xcode) y valida el `Info.plist` y `Assets.car` de la extensión embebida en `ReperaWatch.app/PlugIns`. La comprobación visual en un Apple Watch requiere instalar nueva build, volver a añadir la complicación y revisar editor/esfera en ambos modos.

### Regeneración y verificación del selector watchOS
- Se sustituye el identificador anterior de WidgetKit por `com.app.repera.watch.complication.brand3`, actualizado también en la aplicación y la publicación de snapshots. Esto obliga al sistema a registrar una nueva entrada de complicación en el selector en lugar de reutilizar vistas previas de la anterior; **hay que volver a añadirla a la esfera** tras instalar la nueva build.
- En el selector y en la esfera se utiliza la misma vista `ReperaLogo`, que en modos tintados renderiza solo el rostro en alfa sin disco de fondo; `placeholder`, `getSnapshot` y `getTimeline` comparten el render. Sin `ReperaIcon` compilado se muestra una `R` evidente como indicador de error, nunca un disco indistinguible de una complicación correcta.
- No dar la validación por terminada solo con tests estáticos: ejecutar XcodeGen y compilar el target watchOS, revisar que `ReperaWatchWidget.appex/Assets.car` incluye `ReperaIcon` y probar en el editor y en la esfera real los modos `fullColor` y `accented`.
