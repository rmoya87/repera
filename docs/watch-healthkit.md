# Repera Watch — ejecución offline y HealthKit

## Fuente de verdad

- **HealthKit (en Apple Watch):** `HKWorkoutSession` + `HKLiveWorkoutBuilder` registran FC, energía activa y duración verificada. Las calorías no se calculan usando repeticiones, MET ni el cronómetro de Repera.
- **Repera (en Apple Watch):** conserva la planificación original, serie/reps/carga confirmadas, rondas, score WOD, descansos, pausa y progreso. El contador de movimiento es una **sugerencia** que el atleta corrige.
- **Repera (en iPhone):** almacena la misma ejecución, identificada por un UUID estable. No crea otro `HKWorkout` al importar una sesión terminada del Watch.
- **Supabase:** recibe únicamente los datos de entrenamiento permitidos por `BusinessWorkoutSyncStore.privateMirrorPayload`: nunca `healthKitWorkoutUUID`, pulso, calorías HealthKit, duración Apple ni `appleHealthProvenance`. La autorización del usuario y las RLS siguen vigentes.
- **iCloud privado:** conserva el estado local del usuario para recuperación personal.

## Flujo de sesión

1. Al conectarse, el iPhone envía la rutina programada o una prescripción estructurada del entrenador, con día de calendario. El Watch la guarda. Nunca trata el contexto antiguo de otro día como entrenamiento de hoy.
2. El botón **Iniciar** crea un UUID nuevo de ejecución; conserva el UUID de la prescripción como `routineId`. HealthKit pide permisos para leer FC/energía y compartir entrenamientos.
3. Tras solicitar autorización con la API asíncrona de HealthKit, watchOS inicia un `HKWorkoutSession` con actividad `functionalStrengthTraining`, `highIntensityIntervalTraining` o `crossTraining` según los bloques y un `HKLiveWorkoutBuilder`. Usa `beginCollection(at:)` y `addMetadata(_:)` con `async/await`; se habilita `workout-processing` para continuar con la muñeca baja. Un problema de permisos no produce kcal ni FC inventadas.
4. Las actividades de HealthKit se separan por bloques, sin crear un nuevo workout por ejercicio. La petición de pausa con los dos botones físicos del reloj pausa también el temporizador Repera. Las series se confirman con reps y carga reales. En AMRAP se confirma rondas + reps; en For Time, tiempo; EMOM y Tabata tienen intervalos y descansos y no crean series ficticias.
5. Al finalizar, Repera guarda primero el trabajo confirmado en disco, incluso sin conexión. HealthKit detiene su sesión, cierra la colección y guarda un `HKWorkout`. El resumen se enriquece con el UUID, la energía, la FC y la duración **solo cuando Salud los proporciona**.
6. `HKMetadataKeyExternalUUID` enlaza el sample de Salud con la ejecución de Repera. Esto permite recuperarlo cuando `finishWorkout` devuelve un `HKWorkout` nil porque el reloj está bloqueado.
7. El mirroring nativo de `HKWorkoutSession` avisa al iPhone del estado de la sesión; `WCSession.transferUserInfo` transfiere los resultados en segundo plano. La cola persiste hasta acuse del iPhone; la sesión repetida se reconcilia por UUID sin duplicar resultados. Un enriquecimiento tardío de Salud actualiza solo los campos de Salud.
8. En primer plano, el iPhone busca por external UUID muestras aún pendientes de sincronizar desde Apple Salud y actualiza su sesión. La sincronización autenticada con Supabase continúa siendo independiente de las mediciones de Salud.

## Permisos y privacidad

Entitlement HealthKit y cadenas `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` en el target del Watch. Modo background `workout-processing`. No se declara `audio`: los controles de reproducción se delegan al sistema mediante `NowPlayingView`.

No se infiere la concesión de permisos de una lista de muestras vacía. Una lectura que aún no se ha transferido entre dispositivos se mantiene **pendiente**, no como cero.

## Complicación WidgetKit y WidgetBundle

La extensión `ReperaWatchWidget` utiliza la estructura nativa de WidgetKit: `ReperaWatchWidget: Widget` devuelve `StaticConfiguration` desde `body: some WidgetConfiguration`, mientras que `ReperaWatchWidgetBundle: WidgetBundle` devuelve `ReperaWatchWidget()` desde `body: some Widget`. Nunca colocar `StaticConfiguration` directamente en el cuerpo de un `WidgetBundle`, porque `WidgetBundleBuilder.buildExpression` solo acepta tipos `Widget` y Swift devuelve `No exact matches in call to static method 'buildExpression'`.

El test `test_watch_complication_uses_widget_configuration_inside_widget` en `tests/test_watch_healthkit_contract.py` protege esta composición. Se mantienen las familias circular, rectangular e inline, el icono `ReperaIcon` y el enlace `repera-watch://today`.

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

## APIs asíncronas y compatibilidad con Swift 6

El Watch utiliza las variantes `async throws` de `requestAuthorization(toShare:read:)`, `beginCollection(at:)`, `addMetadata(_:)`, `endCollection(at:)` y `finishWorkout()`. El inicio opcional del mirroring usa `startMirroringToCompanionDevice()` de manera independiente, para que el entrenamiento siga funcionando sin iPhone. No volver a introducir las sobrecargas con `completion` que Xcode 27 señala con **Consider using asynchronous alternative function**. Los errores se tratan sin atribuir mediciones inventadas a Salud. El contrato de código que comprueba estas APIs está en `tests/test_watch_healthkit_contract.py`.


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
