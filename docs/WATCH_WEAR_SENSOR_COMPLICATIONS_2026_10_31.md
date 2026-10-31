# Repera · Watch/Wear sensores, complicación y bloqueo (31/10/2026)

## Cambios
- watchOS: una sesión HealthKit iniciada *en el Watch* entrega FC actual y kcal activas con builder; nunca se calculan desde GPS. El entrenamiento autónomo se guarda en Salud.
- Comenzar propiedad de iPhone: cuando el snapshot llega al Watch sin otro workout activo, se solicita una sesión de HealthKit local para obtener sensores; `mirrorsToPhone=false` y se **descarta** al terminar/revisar. Se evita duplicar un HKWorkout ya propiedad del iPhone.
- Wear: Health Services lee FC/calorías tanto en entrenamiento programado como en Comenzar companion, con ExerciseType.WALKING cuando corresponde y sin segundo GPS; si una métrica no está disponible se mantiene el guion.
- Zonas cardíacas 1–5: cinco segmentos, con FCmáx provisional de 190 lpm. No presentar estas zonas estimadas como zonas clínicas personalizadas.
- Apple Watch: `WKSupportsLiveActivityLaunchAttributeTypes` permite abrir la app del reloj al tocar la Live Activity de iPhone. La Smart Stack tiene formato `ActivityFamily.small` propio.
- Complicación de esfera: extensión y watch app comparten el estado mediante App Group `group.com.app.repera.watch`. Circular/esquina: acceso directo con mascota de Repera; rectangular: mascota, tiempo, distancia, FC y kcal con sesión, o «Iniciar actividad» sin sesión; inline: título de la sesión o «Repera».
- **Corrección del icono gris del selector:** WidgetKit redacta automáticamente el contenido de placeholder(in:), convirtiendo las imágenes en rectángulos grises. El PNG oficial es contenido público y ReperaLogo usa .unredacted() para que la imagen se vea en el selector, en la esfera y durante Always On. getSnapshot(context.isPreview) no accede a datos de sesión, por lo que no depende del App Group. El icono utilizado es ReperaIcon/repera.png, idéntico al AppIcon oficial de iPhone y Watch; en fullColor se muestra íntegro y en accented usa desaturated conforme a Apple. Se retiran las máscaras y recortes UIImage que ocultaban el icono original.
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
3. Instalar una nueva build con brand4, eliminar la complicación anterior y añadir la nueva. Probar selector y esfera (circular, esquina, rectangular e inline) en modo normal, teñido y Always On; el icono no debe convertirse en un cuadrado gris ni desaparecer. Comprobar navegación y placeholder, snapshot y timeline.
4. Wear inicia caminata con Android desbloqueado, luego bloqueado: Health Services entrega FC/kcal, zonas, y se muestra notificación persistente de Android; controles de pausa/fin coherentes.
5. Repetir con permisos denegados, Bluetooth desconectado, apps terminadas, optimización de batería y móvil en segundo plano. Verificar mensajes de error precisos y sin duplicar sesiones.
6. Compilar en Xcode con perfiles App Group y ejecutar Android unit tests, instrumentados en Wear real y revisión de permisos Health Services.

## Diagnóstico y comprobaciones de empaquetado (31/10/2026)
- Las imágenes antiguas `ReperaComplicationIcon` (66/132/198 px) tienen fondo opaco y no deben usarse para renderizar complicaciones. El widget actual usa el `ReperaIcon` oficial directamente, y nunca genera plantillas de la cara con CoreGraphics ni `UIImage`; el anterior `ReperaComplicationAppIconStore` tampoco participa en el widget.
- El target `ReperaWatchWidget` **sí empaqueta** `Assets.xcassets` y el PNG oficial, con `ReperaIcon` en su `Assets.car`. Ya no se utilizan los antiguos iconos opacos `ReperaComplicationIcon` ni los PNG sueltos; `AppIcon` del target principal `ReperaWatch` sigue intacto.
- CI ejecuta `tests/test_watch_complication_contract.py`, verifica igualdad SHA-256 de **iPhone, Apple Watch y complicación**, obliga a una única imagen canónica `ReperaIcon/repera.png` (sin PNG `@2x`/`@3x` huérfanos en el imageset; provocan «unassigned children» en Xcode) y valida el `Info.plist` y `Assets.car` de la extensión embebida en `ReperaWatch.app/PlugIns`. La comprobación visual en un Apple Watch requiere instalar nueva build, volver a añadir la complicación y revisar editor/esfera en ambos modos.

### Regeneración y verificación del selector watchOS
- Se registra el identificador com.app.repera.watch.complication.brand4 en widget, watch app y hub. Esto evita reutilizar el preview de la implementación anterior; tras instalarla hay que volver a añadirla.
- En el selector y la esfera se usa ReperaLogo, siempre .unredacted(), incluida la vista de placeholder. Nunca recortar la cara ni generar máscaras en tiempo de ejecución para intentar corregir la redacción automática.
- No dar la validación por terminada solo con tests estáticos: ejecutar XcodeGen y compilar el target watchOS, revisar que `ReperaWatchWidget.appex/Assets.car` incluye `ReperaIcon` y probar en el editor y en la esfera real los modos `fullColor` y `accented`.
