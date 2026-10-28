# Reset de datos de usuario: contrato pendiente (PROTOTIPO, sin UI)

Estado: WorkoutRepository.resetUserData (commit b0d7dd10) es un prototipo parcial NO seguro y NO listo.
No esta conectado a ninguna pantalla. No se ha ejecutado contra cuentas reales.

## Referencia Apple fc3ef7e1 (leida en codigo)
- ReperaStore.resetUserData (l.562) reconstruye `AppState(exercises: state.exercises, routines: [], workouts: [], bodyWeights: [], activeSession: nil, updatedAt: now)`.
  Los demas campos toman los defaults de Models.swift:2290: `settings = AppSettings()`, `rotation = nil`,
  `favoriteTimers = []`, `exerciseLoadPrefs = [:]`, `syncRevision = 0`, `lastWriterDeviceId = ""`.
  Despues `persist` aplica `stampForPersist(bumpRevision: true)` => revision 1.
- Diferencia con el prototipo Android: UserDataReset.clear CONSERVA settings, favoriteTimers y exerciseLoadPrefs.
  El texto de confirmacion de Apple solo menciona rutinas, entrenos y pesos, pero el codigo tambien restablece
  ajustes, rotacion, temporizadores favoritos y preferencias de carga. Decision de producto pendiente: paridad literal
  con el codigo Apple, o paridad con el texto. NO decidido aqui.
- Apple NO escribe tombstone de Supabase en reset (si en deleteWorkout, ReperaStore.swift:1285) y reinicia la revision
  a 1: el reset Apple puede perder frente a un Drive/iCloud con revision mayor. Paridad con Apple no equivale a seguro.

## Huecos demostrados con ensayos (UserDataResetDriveContractTest, Drive simulado, JVM)
1. Una revision remota mayor (otro dispositivo) gana y restaura el historial (Downloaded). Sin epoca de reset no hay garantia.
2. Un entreno remoto que este dispositivo nunca vio se pierde de Drive sin aviso cuando la revision local gana.
3. Con revision igual y otro escritor el resultado es Conflict o Unchanged segun timestamps: no resuelve intencion.
4. Fallo de subida: el local queda reseteado y reintenta; converge al reintentar (OK).
5. Espejo Supabase: con tombstones no se recuperan ids; si el corte ocurre tras guardar el snapshot y antes de
   escribir tombstones, se resucitan (selectRecoverable).
6. Orden inverso (tombstones antes de guardar, como hoy): si save() falla por CAS, los tombstones quedan pendientes con
   los entrenos aun locales; el paso 2 del espejo omite ids en deletedIds() y el sync borra el remoto: perdida silenciosa.
   Mismo patron preexistente en deleteWorkout. Hace falta un diario de intencion (WAL): intento -> guardar -> confirmar,
   reconciliable al arrancar (si el estado ya no contiene los ids: confirmar tombstones; si los conserva: descartar intento).
7. Rutinas y pesos no tienen tombstone en el espejo (solo entrenos). Drive es snapshot completo.

## Garantias que exigen decision o backend (aisladas, sin implementar)
- Epoca de reset en el snapshot (campo nuevo, p. ej. `resetEpoch`): mayor epoca gana sobre cualquier revision.
  Afecta al formato compartido con Apple (el decodificador Apple ignora campos desconocidos y los perderia al reescribir).
- Invalidacion de otras instalaciones y de filas Supabase de rutinas/pesos si se quiere.
- Colas pendientes (outbox) y estado Wear (sesion activa en el reloj): no inspeccionado el canal de limpieza.
- Hasta resolverlo: no exponer "Borrar todo".

## Auditoria outbox / Wear (codigo leido, 26 oct 09:40)
- Outbox unico encontrado: pendingDeletes del WorkoutMirrorStore (SharedPreferences). El reset lo alimenta via noteDeleted.
  No hay otra cola local de escrituras de usuario (WorkManager solo tiene DriveSyncWorker y catalogo remoto).
- Reloj: el telefono publica /repera/active-session; con sesion nula el reloj hace clearSession(erasePending=false) y conserva
  series/fin pendientes sin confirmar. Solo signedOut=true borra pendientes (y cierra la identidad en el reloj: demasiado para un reset).
- Vector de resurreccion por Wear: logWearSet con sessionPayload llama adoptWearSession y recrearia la sesion activa descartada.
  adoptWearSession YA rechaza ids en mirror.deletedIds() (WorkoutRepository ~l.1756), asi que basta incluir el id de la sesion
  activa en los tombstones: UserDataReset.discardedIds (commit posterior). finishWearSession sin activa devuelve false (no recrea).
- Residuo: el reloj mostrara "La sesion del telefono cambio; revisa las series pendientes" y conservara las series huerfanas
  (el finish queda reintentando sin ack). Limpiarlo exigiria un campo nuevo en el DataItem o usar signedOut: decision pendiente, no implementado.
- Colas de la bandeja IA (AIChangeRequestStore, acks pendientes): no auditadas a fondo; propuestas remotas con consentimiento.
  Sin verificar si una propuesta pendiente puede apuntar a ids ya descartados.
- Pendiente real y no resuelto: Health Connect/ejercicios derivados escritos fuera del snapshot no se tocan.

## deleteWorkout: tombstone antes de CAS (riesgo separado, preexistente)
WorkoutRepository.deleteWorkout: noteDeleted(id) en la linea tras check(stillAuthorized) y antes de archive.remove + save(state).
save() usa replaceIfUnchanged (CAS, SnapshotStorage.replaceIfUnchanged). Si falla, el id queda pendiente con el entreno local.
Prueba preparada (COMPILADA, NO EJECUTADA, sin dispositivo): DeleteWorkoutCasFailureInstrumentedTest, inyecta el escritor
concurrente via stillAuthorized (llamada 2) y asserta el estado inseguro. No se propone correccion hasta ejecutarla.

## Auditoria IA / derivados (26 oct 09:45, codigo leido, sin ejecutar)
- AIChangeRequestStore: update/delete_workout exigen que el entreno exista localmente y que la revision remota del espejo
  coincida y no este borrada; tras un reset fallan con "ya no esta disponible" (no resucitan). create/update/delete_exercise tocan el
  catalogo, que el reset conserva. La cola `acks` (ids de cambios ya aplicados pendientes de confirmar remoto) es un SEGUNDO outbox de usuario:
  solo envia "applied" al servidor, no muta el local. El reset no debe vaciarla. Queda sin comprobar si una propuesta pendiente puede
  referirse a ids ya descartados mas alla de lo anterior.
- AITrainingContextStore publica el calendario de rutinas (athlete_training_calendar_snapshots); tras reset el digest cambia y el siguiente
  sync sube items vacios (converge si el sync corre). No se ejecuto.
- Derivados que el reset NO toca: LiveRoutesStore (archivo propio con tombstones, rutas GPX/grabadas), WodTimerStore/StandaloneTimerStore
  (prefs por sesion, huerfanos inocuos), registros de Health Connect ya escritos por HealthConnectWriter (al desaparecer las ventanas de exclusion,
  actividades antes enlazadas pueden volver a verse como externas en Salud). Decision de producto pendiente: incluir o no.
- SessionStore, SyncStatusStore, RecentPlacesStore: no auditados a fondo.

## Diario de intencion y epoca (puro, NO cableado)
ResetCoordinator (ResetPorts): intencion -> save CAS -> tombstones -> borrar intencion; recover() idempotente. ResetCoordinatorTest ensaya
fallo en cada paso (intent, save, 3 tombstones, clear), CAS fallido, segundo reset con intencion viva y reaparicion de ids tras guardar (se
informa, no se vuelve a borrar). ResetEpochPolicy es SOLO una simulacion de la regla "mayor epoca gana"; no hay campo en el snapshot ni
compatibilidad con Apple/Drive implementada. Falta cablear: puertos reales en WorkoutRepository, uso de protectedIds() en el sync del espejo
(selectRecoverable) y llamada a recover() al arrancar.

## Puertos reales cableados (26 oct 09:49, sin UI, sin uso en produccion)
- El prototipo resetUserData (tombstones antes de guardar) FUE ELIMINADO. Lo sustituye `WorkoutRepository.resetUserDataJournaledForTests`
  (internal, nombre explicito, sin llamadas de UI) sobre ResetCoordinator con puertos reales: intencion en prefs del WorkoutMirrorStore
  (commit sincrono), readState/saveState sobre loadOrNull/save (CAS), noteDeleted del espejo.
- WorkoutMirrorStore.blockedIds() = deletedIds + ids de la intencion viva. Lo usan selectRecoverable, el salto de subida del paso 2,
  adoptWearSession y mergeRecovered (WorkoutRepository ~l.1756 y ~l.2152). deletedIds() sigue crudo para no persistir ids de una intencion
  que luego se descarte.
- CAMBIO EN RUTA DE PRODUCCION: WorkoutMirrorStore.sync llama a repository.recoverPendingReset() tras authorize. Sin intencion es un no-op
  (retorna antes de leer el estado). Mismo candado de proceso en reset() y recover() (companion del coordinador).
- recover() con snapshot ilegible conserva la intencion (no promueve tombstones sin probar el guardado).
- Ensayos: ResetCoordinatorTest (9, JVM) incluye carrera reset/recover con 300 iteraciones en hilos. ResetJournalPortsInstrumentedTest
  (3 casos con almacenes reales y cuenta sintetica) COMPILADO, NO EJECUTADO: la invariante con puertos reales no esta demostrada en ejecucion.
- SessionStore guarda la sesion cifrada de identidad: el reset no la toca. SyncStatusStore es un estado visual global (no por cuenta) que puede
  mostrar un resultado de sync previo al reset. RecentPlacesStore (por cuenta) conserva lugares recientes; Apple no los limpia en resetUserData
  (solo se vio su uso en PlaceSearchSheet). Decision de producto, no tocado.
- IA: update/delete_workout no resucitan ENTRENOS porque exigen existencia local y revision remota viva; eso no cubre rutinas/pesos ni todas
  las operaciones, y quedan sin cerrar los huecos de propuestas pendientes mencionados arriba.

## Identidad y alcance por cuenta (26 oct 09:52, lectura de codigo; local, no desplegado ni ejecutado en cuentas reales)
- HALLAZGO PREEXISTENTE (no corregido): WorkoutRepository se construye con `profile.uniqueId` (GoogleIdTokenCredential.uniqueId, MainActivity ~l.1322)
  y su `mirror = WorkoutMirrorStore(context, googleId)` (WorkoutRepository l.28) usa las prefs "repera.mirror.<googleUniqueId>". El sync de MainActivity
  (l.133, 226, 246, 372) usa `WorkoutMirrorStore(this, session.userId)` con el id de Supabase: otras prefs. Si ambos ids difieren (el userId de GoTrue es un UUID),
  los tombstones de deleteWorkout y la intencion del reset quedan en un almacen que el espejo no lee. Consecuencia posible, NO reproducida: borrados locales no se
  propagan y el espejo podria recuperarlos. Hay que ejecutar ResetJournalAccountScopeInstrumentedTest (compilado) para confirmarlo.
- Mitigacion ADITIVA aplicada solo a la proteccion del reset: WorkoutMirrorStore.sync une `blockedIds()` propio con `repository.mirrorBlockedIds()` en la recuperacion
  y en el salto de subida. Solo puede bloquear mas (ids de reset/borrados de esa cuenta); no cambia la propagacion de tombstones, que sigue pendiente de decision.
- La intencion es por cuenta (prefs del repositorio, clave = id Google): el test instrumentado compilado comprueba que la de A no bloquea ni recupera para B.
- ResetCoordinator: intencion ilegible -> CorruptIntentKept (no lanza, no borra, bloquea un segundo reset). Snapshot distinto tras un corte: recover solo tombstonea
  los ids de la intencion y nunca modifica el snapshot (test JVM con "other1").
- Revocacion: save() ya comprueba stillAuthorized (si falla, el reset devuelve CasFailedNothingChanged y borra la intencion sin tombstones); loadOrNull lanza si no esta autorizado.

## Auditoria de identidades (26 oct 09:57; lectura de codigo + guardia estatica JVM; no ejecutado en Android real)
Dos dominios: Google = profile.uniqueId; Supabase = session.userId. SessionStore guarda el par; accountWorkGuard (MainActivity ~l.114) exige que
uniqueId, userId y la revision de identidad (A-B-A) sigan siendo los capturados.
- Dominio Google: LocalSnapshotStore, WorkoutRepository (y su mirror interno), LiveRoutesStore, RecentPlacesStore, WodTimerStore.
- Dominio Supabase: WorkoutMirrorStore del sync, AITrainingContextStore, AIChangeRequestStore (y su cola `acks`, prefs "repera.ai.change.acks.<userId>").
- Dos sitios sin id de cuenta: AIAccessStore, AITrainingProgramsStore, BusinessCenterStore (usan la sesion).
- AIChangeRequestStore.decide recibe un `mirror` (Supabase) que NO usa. Su delete_workout llama repository.deleteWorkout, que tombstonea en el almacen Google.
  Efecto posible, sin reproducir: el borrado IA no llega al espejo remoto (la fila sigue viva para otros dispositivos). En este dispositivo selectRecoverable lo
  frena si el id esta en `seen` (se subio antes); un id nunca visto podria recuperarse.
- Cambio local de endurecimiento: syncWorkoutMirror pasa el guardia `authorized` al WorkoutRepository del sync (antes `stillAuthorized` por defecto = true).
  Asi recoverPendingReset/loadOrNull fallan cerrados bajo revocacion o rebind. Solo toca la cuenta nombrada por `uniqueId`; nunca la sesion actual.
- AccountIdentityContractTest (JVM, lee fuentes): fija el reparto de dominios y los dos hallazgos "KnownDivergence". No prueba aislamiento en ejecucion.
- Reparacion propuesta (NO aplicada: propagaria borrados al espejo y exige migrar tombstones reales de prefs Google a Supabase): resolver uniqueId->userId desde
  SessionStore al construir el almacen de tombstones del repositorio, con migracion idempotente de los pendientes existentes. Requiere ejecucion Android para validar.
