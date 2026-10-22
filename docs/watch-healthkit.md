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
3. Con los permisos autorizados, watchOS abre una sesión de `functionalStrengthTraining` con un builder; se habilita `workout-processing` para continuar con la muñeca baja. Un problema de permisos no produce kcal ni FC inventadas.
4. Las series se confirman con reps y carga reales. En AMRAP se confirma rondas + reps; en For Time, tiempo; EMOM y Tabata tienen intervalos y descansos y no crean series ficticias.
5. Al finalizar, Repera guarda primero el trabajo confirmado en disco, incluso sin conexión. HealthKit detiene su sesión, cierra la colección y guarda un `HKWorkout`. El resumen se enriquece con el UUID, la energía, la FC y la duración **solo cuando Salud los proporciona**.
6. `HKMetadataKeyExternalUUID` enlaza el sample de Salud con la ejecución de Repera. Esto permite recuperarlo cuando `finishWorkout` devuelve un `HKWorkout` nil porque el reloj está bloqueado.
7. `WCSession.transferUserInfo` transfiere en segundo plano. La cola persiste hasta acuse del iPhone; la sesión repetida se reconcilia por UUID sin duplicar resultados. Un enriquecimiento tardío de Salud actualiza solo los campos de Salud.
8. En primer plano, el iPhone busca por external UUID muestras aún pendientes de sincronizar desde Apple Salud y actualiza su sesión. La sincronización autenticada con Supabase continúa siendo independiente de las mediciones de Salud.

## Permisos y privacidad

Entitlement HealthKit y cadenas `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` en el target del Watch. Modo background `workout-processing`, más `audio` para avisos hápticos mientras se entrena, según las instrucciones de Apple.

No se infiere la concesión de permisos de una lista de muestras vacía. Una lectura que aún no se ha transferido entre dispositivos se mantiene **pendiente**, no como cero.

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
