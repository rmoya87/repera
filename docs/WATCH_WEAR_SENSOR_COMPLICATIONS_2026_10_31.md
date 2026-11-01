# Repera · Watch/Wear sensores, complicación y bloqueo (31/10/2026)

## Cambios
- watchOS: una sesión HealthKit iniciada *en el Watch* entrega FC actual y kcal activas con builder; nunca se calculan desde GPS. El entrenamiento autónomo se guarda en Salud.
- Comenzar propiedad de iPhone: cuando el snapshot llega al Watch sin otro workout activo, se solicita una sesión de HealthKit local para obtener sensores; `mirrorsToPhone=false` y se **descarta** al terminar/revisar. Se evita duplicar un HKWorkout ya propiedad del iPhone.
- Wear: Health Services lee FC/calorías tanto en entrenamiento programado como en Comenzar companion, con ExerciseType.WALKING cuando corresponde y sin segundo GPS; si una métrica no está disponible se mantiene el guion.
- Zonas cardíacas 1–5: cinco segmentos, con FCmáx provisional de 190 lpm. No presentar estas zonas estimadas como zonas clínicas personalizadas.
- Apple Watch: `WKSupportsLiveActivityLaunchAttributeTypes` permite abrir la app del reloj al tocar la Live Activity de iPhone. La Smart Stack tiene formato `ActivityFamily.small` propio.
- Complicación de esfera: extensión y watch app comparten el estado mediante App Group `group.com.app.repera.watch`. Circular/esquina: acceso directo con mascota de Repera; rectangular: mascota, tiempo, distancia, FC y kcal con sesión, o «Iniciar actividad» sin sesión; inline: título de la sesión o «Repera».
- **Icono plano vectorial:** Xcode acepta PDF en `.imageset`, no hace falta que el recurso sea PNG. La complicación utiliza `ReperaWatchFlatColor.imageset/icon.pdf` (círculo verde + mascota simplificada, sin sombras) cuando watchOS admite `fullColor`, y `ReperaWatchFlatMono.imageset/icon.pdf` (silhouette plana con ojos, sonrisa y cinta como huecos transparentes) en `accented`, renderizada como `.template` en el grupo primario. Ambos recursos activan `preserves-vector-representation=true`. El AppIcon oficial 3D de iPhone/Watch NO se modifica. La variante plana es una adaptación gráfica de su diseño, no una copia píxel a píxel.
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
3. Instalar una build con `brand6`, quitar la complicación previa y añadir la nueva. Confirmar en el selector y en la esfera circular/esquina que aparece la mascota, sus ojos y sonrisa sobre el círculo teñido. Confirmar en una esfera `.fullColor` que se ve el AppIcon original verde. Validar Always On y tap para abrir Repera.
4. Wear inicia caminata con Android desbloqueado, luego bloqueado: Health Services entrega FC/kcal, zonas, y se muestra notificación persistente de Android; controles de pausa/fin coherentes.
5. Repetir con permisos denegados, Bluetooth desconectado, apps terminadas, optimización de batería y móvil en segundo plano. Verificar mensajes de error precisos y sin duplicar sesiones.
6. Compilar en Xcode con perfiles App Group y ejecutar Android unit tests, instrumentados en Wear real y revisión de permisos Health Services.

## Diagnóstico y comprobaciones de empaquetado (31/10/2026)
- Los PNG antiguos de `ReperaComplicationIcon` eran opacos y no se usan. El script reproducible `python3 scripts/generate_watch_tinted_icon.py` crea la imagen tintada desde `Apps/Repera/.../AppIcon.png`; `--check` exige que el PNG incorporado coincida píxel a píxel (tolerancia 1/255). Las nuevas pruebas validan canal alfa, niveles de gris e igualdad de la fuente original entre iPhone, Watch y widget.
- El target `ReperaWatchWidget` **sí empaqueta** `Assets.xcassets` y el PNG oficial, con `ReperaIcon` en su `Assets.car`. Ya no se utilizan los antiguos iconos opacos `ReperaComplicationIcon` ni los PNG sueltos; `AppIcon` del target principal `ReperaWatch` sigue intacto.
- CI ejecuta `tests/test_watch_complication_contract.py`, verifica igualdad SHA-256 de **iPhone, Apple Watch y complicación**, obliga a una única imagen canónica `ReperaIcon/repera.png` (sin PNG `@2x`/`@3x` huérfanos en el imageset; provocan «unassigned children» en Xcode) y valida el `Info.plist` y `Assets.car` de la extensión embebida en `ReperaWatch.app/PlugIns`. La comprobación visual en un Apple Watch requiere instalar nueva build, volver a añadir la complicación y revisar editor/esfera en ambos modos.

### Regeneración y verificación del selector watchOS
- Se registra el identificador com.app.repera.watch.complication.brand6 en widget, watch app y hub. Esto evita reutilizar el preview de la implementación anterior; tras instalarla hay que volver a añadirla.
- En el selector y la esfera se usa ReperaLogo, siempre .unredacted(), incluida la vista de placeholder. Nunca recortar la cara ni generar máscaras en tiempo de ejecución para intentar corregir la redacción automática.
- No dar la validación por terminada solo con tests estáticos: ejecutar XcodeGen y compilar el target watchOS, revisar que `ReperaWatchWidget.appex/Assets.car` incluye `ReperaIcon` y probar en el editor y en la esfera real los modos `fullColor` y `accented`.

### Revisión gráfica previa al commit (01/11/2026)
- Se ha decodificado el PNG original de 1024×1024 directamente desde la rama main, segmentado el fondo verde y previsualizado el resultado de 256×256 sobre una simulación de esfera oscura. La figura, ojos, sonrisa y cinta son distinguibles; los píxeles del fondo son transparentes.
- Este control acredita **la imagen generada**, no que el selector/WidgetKit de un Apple Watch haya mostrado el widget real. Para cerrar la incidencia debe existir captura del selector y de la esfera de una compilación instalada. La última ejecución de GitHub Actions disponible se encontraba fallida antes de este cambio; no declarar build como verificada mientras no pase CI.

### Verificación de PDF vectorial (01/11/2026)
- Dos PDF de 200 × 200 pt con trazados y sin imágenes raster incrustadas, renderizados previamente a 800 × 800 px y comprobados visualmente. Se revisó además a 36 × 36 px, aproximadamente el tamaño de una complicación circular.
- El PNG 3D anterior se conserva en Assets para usos preexistentes, pero `ReperaWatchWidget.swift` no lo utiliza para la marca. El nuevo widget utiliza los dos recursos PDF `ReperaWatchFlatColor` y `ReperaWatchFlatMono`.
- `tests/test_watch_complication_contract.py` comprueba el encabezado PDF, `preserves-vector-representation`, `template-rendering-intent`, la transparencia even-odd y los nombres de imagen usados por SwiftUI. CI inspecciona que ambos recursos estén en `Assets.car` de la extensión embebida.
- Falta verificar el resultado en el selector real y la esfera instalada. No afirmar que esté resuelto hasta disponer de captura de esa compilación.

### Ajustes visuales Apple Watch (01/11/2026)
- Complicación circular ampliada de 36 a 44 pt, fondo verde corporativo hasta el borde y PDF plano centrado al 88 % para aportar más verde lateral. Corner: 32 pt; rectangular: 29/31 pt.
- Inicio: título del elemento seleccionado arriba a la izquierda junto a la hora; icono central sin título duplicado; botones de silencio y temporizador al final del lienzo extendido fuera del safe area inferior, con margen de bisel.
- Actividades: título en toolbar topBarLeading en vez del encabezado nativo debajo de la hora; Live Sport usa el mismo encabezado. Revisar en watchOS real/simulador, los tests estáticos no garantizan disposición visual.

### Ajuste de cabecera y controles (01/11/2026)

- **Inicio:** `Text(selected.title)` vuelve dentro de la misma `VStack` del pictograma central, por debajo de él. No existe un overlay `.topLeading` en Inicio; el reloj conserva despejada la franja horaria.
- **Actividad:** el título `pageTitle` continúa en `ToolbarItem(.topBarLeading)`, pero se compensa 23 pt hacia arriba para alinearlo visualmente con la hora nativa. Color blanco y ancho máximo de 112 pt para evitar invadir el reloj.
- **Controles inferiores:** se retiran los 13 pt de separación inferior y se desplazan 10 pt adicionales hacia el bisel en ambas esquinas; el desplazamiento total respecto de la compilación previa es de 23 pt.
- Pendiente verificación visual de estos ajustes en reloj y simulador watchOS; tests estáticos no sustituyen la comprobación del layout en un dispositivo.

### Alineación de nombre de actividad con hora de watchOS (01/11/2026)
- Mediciones de las capturas suministradas: con offset 0, «Caminata» estaba ~17 px por debajo del centro de la hora; con offset -23, ~19 px por encima. Se interpola un offset de **-11 puntos** para alinear los centros visuales.
- Solo cambia el desplazamiento vertical de `ToolbarItem(.topBarLeading)` en `WatchSessionView.swift`; se conservan Inicio, los controles de silencio/temporizador y las complicaciones.
- La alineación en el reloj debe comprobarse visualmente tras instalar la nueva build, ya que el cálculo entre capturas no equivale a una prueba de simulador.
