# Delta de referencia Apple · 26oct2026 01:04 CET

Referencia actual remota verificada `fc3ef7e1ad850818f463133122fead864c201701`.
Sustituye referencia37837401 para acciones nuevas. La matriz histórica conserva evidencia
válida de sus SHAs, pero no certifica la nueva adaptación.


## Estado de evidencia reconciliado, 26 oct 08:20 CET

Esta cabecera resume los anexos y evita leer como actuales las ausencias históricas.
No reemplaza la matriz completa de comportamiento ni certifica paridad.

- Checkpoint JVM: móvil 314 sin fallos en el grupo del editor SavedInstance; dominio 327 sin fallos
  en el grupo posterior, errores/omitidos 0 en ambos.
- Mobile assemble/AndroidTest compile correctos en el grupo del editor SavedInstance; Wear assemble/
  AndroidTest compile correctos en 15a8c2ff. Los fixtures instrumentados de
  las incorporaciones nocturnas NO se han ejecutado.
- Biblioteca WOD tiene catálogo/favorito/detalle/play efímero/historia y fallback
  de búsqueda locales. No píxeles nuevos ni gate Free/Pro ejecutado en pantalla;
  fallback >=620 implementado localmente; miniaturas/split no inspeccionados.
- No dispositivo conectado, emulador ni píxeles nuevos inspeccionados. No se ha probado
  Health Services/Health Connect, GPS, cámara, Drive o backend en cuentas reales.
- Actions sigue bloqueado antes de ejecutar por pagos o límite; ninguna nueva beta,
  push, merge a main, cambio Apple ni gasto en esta tanda.
- Guards, CAS e IDs de solicitud corrigen casos locales concretos, no una transacción
  global de identidad/cuota/snapshot/outboxes ni un borrador completo durable.
- Wear tiene inicio offline y colas, no ejecución autónoma completa: navegación,
  técnicas avanzadas, resultado WOD, finalización y métricas durables abiertos;
  servicio foreground ya tiene implementación local, pero ciclo de vida/continuidad y
  notificación no están validados en reloj. ACK del teléfono aún gobierna parte
  del cursor.
- Reset sin resurrección, perfil público, cuota entre dispositivos y activación de
  compras/backend siguen pendientes. Auditoría completa abierta, sin ETA defendible.

## Delta confirmado

Seis commits desde37837401: documentación GPS; adaptación DUO/landscape; correcciones de
fondos; panel derecho de Ajustes/rutinas/ejercicios; quicklog; centrado de rutinas vacías.
11fuentes iPhone cambiadas, 1049 inserciones/423borrados. Watch y ReperaDomain sin cambios.
Arte sin cambios en este delta: auditoría1066imágenes37837401 continúa aplicando a esos archivos.

| Superficie | Cambio Apple | Estado Android |
|---|---|---|
| Inicio | Ancho>=620, tarjetas en columnas, calendario expandido, Ajustes en panel derecho | Avatar y primer par de tarjetas locales; Ajustes en panel derecho implementado localmente. Sin píxeles/rotación/recorrido anidado equivalentes verificados. |
| Diario | Programa/rutinas en columnas, editor en panel derecho, vacío centrado | Programado/Rutinas separados y duales; edición y alta contextual de plantilla, asignación y quitar del día locales. Altas desde selector/columna implementadas; validación visual y recuperación durable del borrador pendientes. |
| Biblioteca | Lista izquierda y ficha derecha, encabezado/acciones en panel, fondos | Selector y ficha simultáneos desde 620 dp locales, selección por cuenta y compacto con navegación. Sin ejecución UI/píxeles ni catálogo WOD equivalente cerrado. |
| Progreso/Recuperación | Resúmenes/cards en columnas >=620 | Categorías y lecturas locales; pares de tarjetas y adaptación Recuperación parciales implementados. Resto del layout y validación visual pendientes. |
| ActividadGPS/navegación | Adaptación landscape/DUO y controles/mapa | MapLibre conserva decisión sincoste. Revisión visual por ancho pendiente. |
| Quicklog | “Apuntar ejercicio”; tarjetas, steppers/keypad; holds duración>0; caps por estilo | Texto/teclado numérico/reglas locales alineados. Campos nativos, no keypad4x4 ni steppers idénticos; pendiente visual/interacción. |

## Verificación local

Reglas quicklog validan y omiten filas cantidad0/holdduración0 antes de guardar, conservan
nota opcional y duración editorial Apple. Nuevos tests caps/hold y compilaciónAndroidTest.
No ejecutar datos reales, publicar ni modificar main/Apple.

## No cerrado

- Regresión globalHEAD; instrumentación nueva y píxeles limpios API35/API37.2.
- Adaptación >=620/rotación/tablet/fold, fuentegrande/TalkBack y hardware.
- Reset seguro con Drive/espejo/colas/sensores sin resurrección.
- Perfil público, cuota multidispositivo y compras verificadas por backend.
- Wear técnicasdrop/restpause/editar/WOD, navegaciónoffline, finalizaciónautónoma y métricasdurables.
- Salud externos rutas/distancia/velocidad, FCrecuperación1min y borrado compatible con plataforma.
- Recuperación tendencia/fases/scrub y gatesFree/Pro exactos aún requieren contraste.
- Meteo/relieve sincoste y decisiones de servicios al final con main.

Actions bloqueado antes de ejecutar por pago o límite. No reintentar sin nueva señal,
no cambiar facturación. Compilaciones/JVM no sustituyen pruebas instrumentadas ni píxeles.

## Corrección de gate Recuperación01:06

La tarjeta de preparación actual es Free y Pro en Apple; se conserva. Constantes reales
son Pro; Free ve preview fijo rotulado ficticio, sin muestras privadas ni interacción.
Sueño/ciclo observados conservan acceso como Apple. Nuevo test Free/no123privado preparado.
Preparación actual solo usa noche de hoy, no una noche de días anteriores (Apple actual).
Tendencia histórica y detalle exacto de fases aún pendientes. No cierre de gates completo.

## Tendencia local01:07

Preparadas mañanas a07:00 únicamente en noches observadas, sin punto futuro antes de07:00;
usa motor existente y media últimas14noches. Actividad externa aporta carga por fin del registro,
no por inicio, para no incluir una actividad06–08 a las07. Pro ve tendencia observada; Free ejemplo
fijo5,6,7,6,8,7,9 rotulado ficticio e inerte. Test de mañana/noches vacías y compilación, noUI/píxeles.

## Charts por fecha01:11

DayPointLineChart antes espaciaba por índice y un intervalo sin lecturas parecía continuo
al mismo ritmo. Ahora posición y scrub usan distancia entre fechas reales. Test1/10días;
Recuperación fija eje0–10 y VFC con una sola lectura no se anuncia como tendencia.
Mobile242/0, AndroidTest compila. Píxeles nuevos pendientes por bloqueoCI.

## Sueño fases/periodo01:12

Resumen/media por noches del periodo y distribución profundo/REM/ligero-otros, con fallback
explícito a últimas14noches solo cuando el periodo no contiene muestras, como Apple.
No presentar ese fallback como dentro del periodo. Ligero/otros conserva etiqueta de incertidumbre
porque el modelo Apple también usa total menos profundo/REM. Test de media/fallback y mobile243/0,
AndroidTest compila; distribución nueva NO inspeccionada visualmente. Guardia de revisión de cuenta
al recibir ACKWear evita actualizar UI/ACK de una cuenta anterior tras cambio de identidad.

## Protección de sesión Wear antigua01:13

Adoptar payloadWear no debe reabrir una sesión ya finalizada ni una ID con tombstonependiente.
Antes una serie tardía nueva adjuntando payload podía resucitarla después de finish. Ahora
adopción rechaza archivadas/tombstones; repetición de una serie ya guardada sigue ACKidempotente.
Test instrumentado finish/serie tardía/borrado preparado y compilado. Mobile243/0; sin transporte real.

## Historial Salud01:15

Faltaba READ_HEALTH_DATA_HISTORY aunque Progreso/peso/ciclo consultan más de30días.
Se declara y solicita de forma opcional solo si FEATURE_READ_HEALTH_DATA_HISTORY está disponible.
No es permiso de lectura de tipos ni requisito para lecturas parciales. Explicación de privacidad
ampliada para distinguir limitación de historial de ausencia de registros. Test gating preparado.
Compilación AndroidTest, mobile243/0 y assemble móvil+Wear pasan; permiso/sistema real noejecutados.
Fuentes API consultadas26oct2026:
- https://developer.android.com/health-and-fitness/health-connect/read-data
- https://developer.android.com/reference/kotlin/androidx/health/connect/client/permission/HealthPermission?authuser=6
No habilita lecturas en background. El historial queda limitado por el proveedor si se deniega.
Corrección matriz antigua reset: Apple conserva state.exercises; no reemplaza por Catalog.seed.

## Preview fisiología Free01:17

Completado contenido fijo Apple: VFC46/51/48/55/53/62/58 más barras de pulso66/63/65/61/60/62/58
y respiración16/15/15/14/16/14/13, rotulado ficticio/noSalud y sin interacción ni muestras privadas.
AndroidTest compilado incluye presencia de ambos valores finales y ausencia de123 privado.
Mobile243/0. No ejecutar ni inspeccionar píxeles aún; no cierre visual de preview.

## Energía y extremosFC01:19

Progreso sumaba calorías crudas por fecha de inicio: un registro cruzando medianoche caía
entero en un día y solapamientos de fuentes podían divergir de agregados Inicio.
Ahora pide AggregateGroupByPeriod de1día a Health Connect con LocalDateTime, usa fecha del bucket
y conserva ausencia como ausencia. Period permite días23/25h y el proveedor aplica reglas de prioridad.
Sin cálculo propio ni cambios a kcal de sesión verificada por origen. Compila; proveedor real noejecutado.
Fuentes: https://developer.android.com/health-and-fitness/health-connect/aggregate-data y
https://developer.android.com/reference/androidx/health/connect/client/request/AggregateGroupByPeriodRequest
Etiqueta mín-máxFC antes usaba mínimo del primer día y máximo del último, no del rango entero;
corregida a extremos de todos los puntos mostrados, test con ambos extremos en día interior.
Mobile244/0, domain292/0, AndroidTest compilado. Sin píxeles ni nuevaCI.

## Control pausaWear01:21

Mensaje pausa antes no incluía ID: entrega tardía podía pausar WOD de otra sesión.
Ahora emisor incluye sessionId; receptor rechaza formato desconocido/sinID/boolinválido y
solo cambia WOD si la ID coincide con la activa al procesarse. Mensajes antiguos sinID se ignoran.
Tests instrumentados del contrato preparados y compilados, noejecutados.
Health Services no marca pause/resume/stop como exitoso cuando la llamada falla, limpia muestras
al iniciar nueva sesión y retiene kcalacumuladas si una actualización trae soloFC. No métricasdurables,
ni reconexión/sensores hardware validados; UI pausa optimista/transporte sinACK siguen pendientes.
Mobile244/0, AndroidTest móvil+Wear compilados, assemble móvil+Wear previo al último helper pasan.

## Permisos WearOS6/API36+01:22

Target37 aún pedía BODY_SENSORS, incompatible con permiso granular HealthServices36+.
Manifest limita BODY_SENSORS hasta35 y añade health.READ_HEART_RATE; petición/comprobación
selecciona por SDK y requiere además ACTIVITY_RECOGNITION para kcal. Callback de permiso
no inicia grabación si ya no hay sesión visible. Test límites35/36/37 preparado y compilado;
assemble móvil/Wear verde. No permiso real concedido ni hardware ni ejecucióninstrumentada.
No solicitar background: gestión de ejercicio/foreground/pantallaapagada sigue auditada como pendiente.
Fuente verificada: https://developer.android.com/health-and-fitness/health-services/permissions

## Ownership y estado HealthServices01:24

Antes startExercise podía sustituir un ejercicio de otra app sin comprobarlo; ahora consulta
getCurrentExerciseInfo: otraapp conserva ejercicio y muestra aviso, desconocido falla cerrado,
ejercicio propio se reconecta al callback sin reiniciar, ninguno inicia. Operaciones serializadas.
Estado pause/ended viene del callback ExerciseUpdate, no del retorno de pause/end.
Fin externo conserva series y muestra aviso. Compila AndroidTestWear/assembleWear.
Fuente: https://developer.android.com/health-and-fitness/health-services/active-data
No test sensores/recuperaciónproceso real; asociación del ejercicio propio con IDsesión Repera,
foreground duradero, métricasfinales y UIpausaoptimista permanecen pendientes.

## Binding sesiónsensor01:25

Reconexión de ejercicio propio ahora exige IDsesión persistida antes de iniciar sensores.
Un ejercicio Repera superviviente con otraID o sin binding no se asocia a sesión visible nueva;
se muestra aviso en lugar de reiniciarlo. stop captura IDvisible anterior y no detiene registro
de otraID. Errores start/stop se muestran, no se ocultan. Compila AndroidTestWear/assembleWear.
No migración implícita de un ejercicio legado sinID. Falta recuperación/decisiónUI explícita para
ese caso y test físico. La preferencia binding es identidad operativa, no almacenamiento de métricas.

## Tombstones locales01:27

noteDeleted usaba apply asíncrono pese contrato durabilidad y ACK de upload vaciaba toda la cola,
perdiendo borrado nuevo producido durante red. Ahora commit antes de borrarlocal, lock compartido
entre instancias y ACK elimina soloIDs del lote. Ledger deIDs borradas persiste trasACK, evitando
readoptar payloadWear viejo después de que desaparezca tombstonependiente o recuperar remoto viejo.
Merge espejo compruebaledger también al aplicar, no solo selección. BorradoID inexistente no genera
ahora tombstone. Test multinstancia/ACKconcurrente/restauración preparado/compilado, mobile244/0.
No sync real ni borrado de cuenta. Reset sigue sinimplementar: esto no resuelve Drive/resetepoch.

## Guardia adicional01:28

Pausa/reanudar sensores también validan IDsesión; actualización FC/kcal solo aparece si binding
coincide con sesión visible. ensureHealth no omite comprobación cuando otroID propio está grabando.
EjeX de charts fecha usa punto medio calendario, no fecha de la observación central por índice.
Test hueco1/10días ampliado. Compilan ambosAndroidTest/mobile244/0. Visual/transporte noejecutados.

## Resultado asíncrono Salud/GPS01:30

Refinado postentreno capturaba cuenta pero podía aplicar review/lecturas después de cambiarla.
Ahora conserva revisión de login, verifica antes/después de suspensiones y antes de asociar/refinar,
y no publica resultado obsoleto; limpiar identidad borra reviewpendiente. Captura pinGPS también
revalida cuenta tras esperar pin antes de adjuntarlo/iniciar ruta. Compila AndroidTest/mobile244/0/
domain292/0. No revierte writeyaenviado al proveedor; cancelación de operaciónenred requiere
matrizE2E. No GPS/Health realejecutado, no prueba privacidadglobal de todoslosworkflows.

## Owner autorizaciónDrive01:31

ConsentimientoDrive pendiente conserva owner+revisión al abrirlo y al recibir callback. Token de
una autorización antigua no se asocia a profile actual ni a cuenta distinta. Operación sync valida
antes de empezar y no publica estado/errores viejos tras login distinto. Sin owner tras recreación
falla cerrado/ignora resultado: el usuario debe volver a abrir conectarDrive, no adivinar cuenta.
Mobile244/0 y AndroidTest compila. No OAuth/Drive real ni restauraciónprocesoreal probados.
No reversión de networkwrite ya iniciado. Alcance de cuenta sigue con builder.setAccount.

## Lint local01:41

LintWear detectó meta-data standalone ausente, Fragmenttransitivo1.1 incompatible conActivityResult
y constantesHealthServices víaCompanion restringida. Corregidos: standalone=false porque sigue
requiriendo móvil para core; pinFragment1.8.9 (existente caché) y puenteJava que usa constantesstatic
públicas documentadas, sin suprimir RestrictedApi ni reglas. Wearlint ahora VERDE, quedan warnings
backup/icon/recents/dependencias/estilo. Fuentes https://developer.android.com/training/wearables/apps/standalone-apps
Lintmóvil no termina dentro límite120s del comando; análisis iniciado, resultado NOdisponible.
Intentos offline previos faltaban dependencias; se descargaron para validación local, no CI ni servicioactivado.
Wearlint primer intento tras corrección agotó memoria; límites proceso1CPU/heap1000m/metaspace384m
lo completaron. No se cambió configuraciónrepo ni se ocultaron reglas para pasar.

## Opciones privadas atómicas01:45

PrivateRecoverySettings escribía AtomicFile pero leía baseFile directa: no usaba recuperación
AtomicFile.openRead y dos instancias podían perder elección independiente en read-modify-write.
Ahora lectura openRead y lock compartido para preservar sleep/cycle simultáneos. Tests interrupción
write y dosinstancias concurrentes preparados/compilados. Mobile244/0. No ejecucióninstrumentada.

## Backup/transfer01:48

allowBackup=false no basta para todoslosOEM enD2D según documentación. Ambos manifests ahora
además declaran dataExtractionRules excluyendo dominiosfile/database/sharedpref/external/root y
deviceprotected tanto cloud como device-transfer; fullBackupContent=false legacy. Recuperación
continúa por flujo explícito Drive/import, no migraridentidad/colas/snapshots porbackupOS.
Assemble ambos, AndroidTest ambos y Wearlint pasan; no D2Dreal ni políticaOEMfísica probada.
Fuente: https://developer.android.com/identity/data/autobackup

## Adaptación Recuperación01:50

Primera superficie del delta>=620: tarjetas históricas Recuperación usan doscolumnas al disponer
620dp y unacolumna debajo; tarjetas alineadasarriba/16dp separación. Preparaciónactual antesdelhistórico
como Apple. Ciclo no se renderiza sin días observados (hasCycleDataApple), evitando calendario
privado vacío al no optin. Test umbral619/620JVM pasa, testausenciaciclo compilado/mobile245/0.
No píxeles ni ejecuciónUI, no cierreDUO/fold. Preparaciónactual aúnfullwidth y otraspestañas siguenpendientes.

## Fechas gráficas Actividad01:52

La corrección de distanciascalendario anterior cubría DayPointLineChart, no Activity/FC-kcalCanvas.
Aplicada también a curva/bandapulso y barrasenergía, con ancho por menorpasocalendario en vez
de compactar días sinmediciones. Mobile245/0/AndroidTestcompila. Sin píxeles/gestoUI ejecutados.

## CronómetroWODWear01:53

Payloadcronómetro contiene sessionId/blockIndex pero consumidor no los validaba. Ahora caraWOD
solo usa timer coincidente, cambio sesión/ejercicio invalida timer ajeno y clear cancela tick+datos.
Nuevo payload reinicia elapsedvisible a0 para no mostrar anterior hasta primertick. Compila
AndroidTestWear/assembleWear; no mensajeríaordeninvertido/rotación/proceso ni píxeles ejecutados.

## Exclusión Drive/espejo01:57

CloudSyncGate era contador: espejo comprobaba antes de merge, pero Drive podía empezar después
entre selección y aplicación, perdiendo recuperación local por reemplazo. Añadido lock compartido:
Drive serializa su reemplazo, recuperación usa tryLock y revalida contador antes de bloque de
selección/procedencia/merge/huellas. No espera espejo si Drive activo/pendiente. Dos JVM nuevas
(skip+secuencia concurrente) pasan/mobile247/0 y AndroidTest compila. No mutexglobal de todas
escrituras repositorio, ni cierre sincronizaciónmultidispositivo/reset. Sin red/Drive real.

## Preparaciónactual y adaptación01:59

Tarjetaactual portada a componente dentro mismo grid620: anillo0–10/redondeo/acción segúnconsejo,
factores sueño/cargareciente/VFC-pulsohoy/cardio48h con umbralesfatigaApple2.3/1.1. Sin datos muestra
mensaje, no nota0. RMSSD explícito. Sigue Free+Pro como Apple; previewhistóricoficticio separado.
Antes si recovery==null no se mostraba ni previewFree; ahora estadoausente permite tarjetasvacías/
previewfixed, no inventar lecturas. Testfactores/arcoaccesible preparado/compilado; mobile247/0.
Preparación entra tambiéngrid, corrige limitaciónfullwidth del anexo anterior. No píxeles/ejecuciónUI,
no cierre Recuperación/DUO ni traducción médica exacta SDNN. Otras pestañasadaptativas pendientes.

## Pausa de bloque02:01

La guardiaIDsesión pausa no bastaba si mensaje tardío pertenece a bloque previo de misma sesión.
Emisor añade blockIndex; receptor exige entero>=0 y coincidencia índiceactivo. Test otrobloque/
fraccionario/negativo preparado y compilado ambosAndroidTest/mobile247/0. Mensajeantiguo siníndice
se ignora. No ACK ni orden/latenciahardwarevalidados; mismosbloques puedennecesitar secuenciacomandos.

## DescansoWear02:02

Contadorresta1cadadelay1000 extendía descanso si el hilo se retrasaba. Sustituido por deadline
monotónico y remaining ceil; pausa preserva milisegundos, reanudar no reinicia. Tres JVM nuevas
(catchup/pausafracción/idempotencia) pasan: domain295/0 mobile247/0; AndroidTestWear/assembleWear.
No resta en background por ticksupuestos. Aún no persiste deadline al morir proceso/reboot ni
hay servicioforeground duradero ni píxeles/aviso/hapticreal ejecutados; no cierre reloj.

## ACKrepetido y descanso02:05

logWearSet era idempotente en datos pero callbackteléfono reiniciaba descanso tras cualquierACK,
incluido replay de seriearchivada. Repositorio invoca efecto solo tras nueva serie persistida; callback
best effort no convierte fallo notificación en fallo deguardado. Replays activos/archivados ACKsin
reiniciardescanso. Testexistente ampliado cuentaunefecto en tresenvíos, compilado/mobile247/0.
No notificación ni reintento real ejecutados. Concurrencia de escrituras entreinstancias sigue abierta.

## ConfirmaciónWear02:07

Confirmarserie se habilitaba durante pausa. UI y handler ahora rechazan mientraspaused y
handler exige mismasesión/ejercicio que visible al toque, como guard!isPausedApple.
CompilanAndroidTestambos/assembleambos/mobile247/0/domain295/0. No UI ni transporteejecutados.

## FinalizarWODWear02:09

Botónterminar solo estaba ramaFuerza; sesionesWOD no exponían outboxfinish ya implementado.
Movido a consumidorcomún de sesión, sin inventarscoreWOD ni añadirresultados. Mismalimitación:
finish requiere teléfonoyACK, no autónomooffline. AndroidTestWear/assembleWear/lintWear pasan.
Sin interacción/píxeles ni scoreWOD/edit/nav resueltos; no cierreWOD.

## Cobertura preparada02:12

Dos consumidores Wear nuevos tienen pruebasUI específicas: WOD termina vía callbackcomún sin
scoreinventado; fuerzapausada botónConfirmardeshabilitado. Ambas preparancapturaredonda al ejecutarse.
Compilan, NOejecutadas ni capturasnuevasdisponibles. Inventario24oct marcado histórico, título
Watch"cubierto" corregido para no confundir mapeoficheros con paridadfuncional.

## EntradaQuicklog02:14

Campos reconstruían texto desde número trascadatecla, impidiendo borrar entero o conservar coma
final al escribir decimal. Ahora borradortextual por campo, estable porIDfila incluso al borrarotras;
validación no permite que cantidad/duración inválida desaparezca silenciosamente mientras se guardan
otrasfilas. UnJVMnuevo pasa/mobile248/0, testUIcoma/vacío preparado/compilado. Sin UI/píxeles,
no keypad4x4Apple ni persistenciadrafttrasprocesomuerto. Texto inválido bloqueaguardado, no se corrige solo.

## Estilosdeentrada02:15

Contraste Models.swift Apple378 (sin cambios hasta fc3) detectó reglas ausentes Android:
variantesburpee/banda-goma/apoyosGHD-cajón-anillas-paralelas-pared sin cargaexterna son reps,
no kg. Prioridad de dominadas/HSPU y carga compuesta conservada; HYROX mantiene adaptación
propia existente. ComparadorgrupoCardio ignora mayúsculas comoApple. Test6casos+excepciones
nuevo pasa: domain296/0, mobile248/0; AndroidTest móvil/Wearcompila. NoUIejecutada ni cierre
catálogocompleto: equivalencia movimientos, unidades y reglasHYROX siguen requiriendo auditoría.

## DefaultsQuicklog02:17

Máquina antes heredaba cantidad del historial, contra Apple que fija500m/15cal; ahora
reglaextraída y3testsJVM: máquina fija cantidad conserva duración, hold1/30s, movilidad8,
comba50, fuerza historial sin duración. Añadir tras eliminar todas las filas usa misma
regla en vez de fallback distinto. Mobile251/0, AndroidTestcompila. TestUI quitarprimera
sin mover borradorsegunda preparado, noejecutado. Persistencia draft/caps al iniciar desde
historial fuera de rango y fidelidad steppers/keypad quedan abiertos.

## CambiosdesesiónWear02:20

Pausa y descanso antes sobrevivían al paso directo a otra sesión recibida porDataItem.
Ahora se limpian al cambiarIDsesión, sin borrarseriespendientes ni reiniciar al actualizar
mismasesión. LecturaFC/kcal visible se limpia; bindingprotege métricasotraid. AndroidTest
compila y assembleWearpasa. Test identidad preparado/noejecutado. Transición de registro
HealthServices antiguo a nuevo queda ABIERTA (failclosed por binding): no se fuerza end/start
hasta contrato callback/confirmación. Lintnuevo agotó120s durante análisis sin resultado;
último lintverde634cafe1 no certifica HEAD. NoCI/push/beta/gasto.

## PruebaexactaCatálogoVirgen02:25

Drive y reconciliador clasificaban virgen por196/278/280ejercicios y noCustom. No comprobaban
favoritos/ediciones y bootstrapactual tiene288. Sustituido por huellacanónica exacta del seedactual,
camposvacíos esperados y rechazo de camposdesconocidos (no descartar preferencias nuevas).
Legacy desconocido no se presume virgen: camino normal/conflicto, nunca autocorrección.
5JVMnuevos: bootstrapactualdescarga historial, favoritono descartable, seedhuella y legacy/campos
nuevos; mobile256/0. AndroidTest bootstrapreal contra canonicalizaciónAndroid preparado/compilado,
noejecutado. Si difiere canonicalización por plataforma fallo conservador (no virgen/conflicto).
Huella actual se debe revisar con cambiosdeasset. No resuelve conflictos igualIDeditado,
resetepoch ni exclusión global escriturarepositorio vs redDrive. Sin sync real/backend/CI/publicación.

## DescargaDrivecompare-and-replace02:28

Descarga podía leer local, esperar red y sobrescribir edición local ocurrida entretanto.
Ahora todas las ramas de descarga usan replaceIfUnchanged con comparación bytes+write bajo
lock compartido por rutaLocalSnapshotStore entreinstancias. Si cambió, Conflict sin reemplazo.
openReadAtomicFile también recupera backup aun si baseausente.2testsJVM redsimulada inyectan
edición/bootstrap duranteGET: mobile258/0. AndroidTest dosinstancias preparado/compilado.
No es mutex global de read-modify-save del repositorio, ni CAS remoto Drive/ETag ni solución
reset. Upload aún puede estar desfasado respecto ediciones concurrentes. Sin pruebasistema/redreal.

## CuentaDriveenred02:32

ServicioDrive valida cuenta antes/después de cada request y antes de aplicar descarga.
Pantalla pasa owner+revision existente; worker pasa identidad+revisiondurable deSessionStore
(no cambia al refrescar token, sí logout/A-B-A) y cancelaciónWorkManager. Respuestaantigua
no reemplaza snapshot ni publica statusnuevacuenta.2testsJVM revocaciónpasan: mobile260/0;
AndroidTest revisiontoken/logout/A-B-A preparado/compilado, solo appfixtureaislada.
Limitación: request iniciado antes de logout puede ya haber llegado al servidor; comprobación
posterior no lo deshace. No global transacción identity+IO/repositorio ni garantía ETagremoto.
No OAuth/cuentasreales/redbackend/CI/gasto. Sin cierre completo de sincronización.

## Procedenciaespejoatómica02:34

mirror_recovered.json usaba tmp+rename y lock por instancia: escrituras simultáneas podían
perder entradas y fallback borraba destino antes de rename. Ahora AtomicFile+lockcompartido
cuenta, igual que snapshot; backupremoto comparte lock también. Test60entradas/dosinstancias
preparado/compilado, no ejecutado. Mobile260/0. Sin migrar datos ni redreal.

CAS remoto sigue sin verificación: no se añade If-Match como garantía imaginaria. Referencia
actual files.update no documenta precondición y tabla v2-v3 muestra files.etag n/a; eso no
prueba imposibilidad global ni permite certificar protección. Requiere contrato soportado/prueba
separada antes de cerrar concurrencia entre dispositivos.
Fuentesconsultadas26oct:
- https://developers.google.com/workspace/drive/api/reference/rest/v3/files/update
- https://developers.google.com/workspace/drive/api/guides/v2-to-v3-reference

## LogoutWearcallbacks02:37

SignedOut borraba sesión/outbox pero dependía de otroDataItem para borrar planhoy: ahora
borra plan local/persistido inmediatamente. Callbacks asíncronos nodos/set-finish no reenvían
capturas viejas después de logout/descartarcola; se valida revisiontransporte e IDs aún vivos.
AndroidTest logoutlocal preparado/compilado (reflexión test), assembleWearpasa, noejecutado.
No garantiza orden de múltiplesDataItems, aislamiento dueño ante cambio offline ni cancelación
mensaje yaenviado. Esos contratos siguen abiertos y requierenpruebas reales de transporte.

## Catálogovsescritura02:40

Bootstrap y applyToAccountcatálogoremoto también publicaban snapshot tras leer sin comprobar
cambios intermedios. Ahora usan replaceIfUnchanged: bootstrap ganadorúnico; mergecatálogo
abortaconmensaje para reintentar si cambia historial, conservando archivos. CachépúblicoIDs
puede ya estar actualizado; próximo intento re-mergea contra snapshotactual. Testbootstrap
concurrente preparado/compilado; mobile260/0. Repo general siguecon RMW no transaccional,
no se declara sincronizacióncerrada. Sinredreal/CI/gasto.

## Referenciascatálogo02:42

Dedupe solo recorría arrays/exerciseId, no objetos exercise.id ni activeSession. Podía borrar
IDcatálogo que todavía usa sesión/historial embebido. Ahora recorre objetos/arrays y sesión
activa; si dosIDs estánreferenciadas no elimina ninguna.2JVM pasan/mobile262/0, AndroidTest
compila. Migracionesmobility/refresh también CAS (faltaban en anteriorpasada) para no publicar
sobre entrenoreciéneditado. NoUIejecutada ni cierre global de concurrencia/identidad.

## Validaciónestática02:46

Wear lintDebug f4b40758 terminó49s con1worker/metaspace512:0errores/18warnings/6hints.
Móvil mismos ajustes sigueagotando120s en lintAnalyzeDebug sinresultado ni proceso restante.
No lo cuento verde.

## WODserviciocuenta02:48

WodTimerService no comprobaba cuenta mientras notificaba. Ahora comprueba identityrevision
capturada al start y cada500ms, rechaza intentdeidentidadanterior y deja de serSTART_STICKY
(no reconstruye sesión con intentnull). Sync solo inicia para dueñoactual. Mobile262/0. Véase
conteo real siguiente: mobile262/0 siguepasando; AndroidTestcompila y assemblemóvilpasa.
Sin pruebadeservicio real ni píxeles. No cambia cronómetroguardado de cuenta anterior ni
resuelve identidadGPS/otrasnotificaciones. SinCI/gasto.

## EscrituradeSalud02:50

Guardia de cuenta después de permisos/lecturascandidatas y antes de insertRecords evita
que continuaciónvieja escriba tras cuenta cambiada mientras esperabaHealthConnect. Pantalla
pasa owner+revision existente. No cancela un insert ya iniciado ni pretende transacciónconlogout.
endZoneOffset usa offsetfin (antes offsetinicio también), para sesióncruzandocambiohorario.
Mobile262/0, AndroidTestcompila+assemblemóvilpasa. Sin providerreal ni escrituraSalud/cuenta/GPSreal.

## ConsentimientoSaludcuenta02:54

Callback permisos antes usaba cuentaactual aunque permiso se pidió desde otra. Ahora launch
único capturadueño/revision durante consulta+resultado; resultado noasociado trasrecreación o
A-B-A seignora. Sleep/cycle pasan mismoflujo. Pesosescritos se revalidan después de permisos
antes deinsertRecords, tanto al registrarpeso como backfill. Mobile262/0 y AndroidTestcompila;
sin permisos/providerreal ni UI. Nocancela insert yaencurso ni transacciónidentityIO.

## Pruebalanzamientopermisos02:56

Una segunda solicitud mientras callbackanterior pendiente no puede sustituir su dueño.
PendingAccountRequest one-outstanding consumeuna vez; sinbinding/recreación/A-B-A/logout
rechaza.3JVMnuevos pasan/mobile265/0; AndroidTestcompila. No permisosUIreales. Solicitud
nueva tras respuestaantigua descartada requiere acciónexplícita, no relanza automáticamentedialog.

## Refreshcredencialtardío02:59

refreshCatalogSilently esperaba refreshToken y guardaba sesión sin verificar si logout/cambio
había pasado entretanto. Ahora saveIfCurrent compara identidad+revisiondurable bajo mismolock
SessionStore; refresh no puede reinstalar cuenta borrada/cambiada. Publicacióncatalog/UI usa
owner+revision (incluyeA-B-A). Testfixture refresh/salida/cambio preparado/compilado, mobile265/0.
SessionIdentitytests exigen appaislada sinlogin; ya no leen/restauran credencialreal previa.
Restauración inicial y otrasoperacionesasync siguen porauditar, no declaración global.

## Restoreinicial03:02

restoreStoredSession también compara revisiondurable+pantalla antes de publicar y persiste
con saveIfCurrent. Fallo antiguono puede limpiar sesiónnueva: clearIfCurrent disponiblebajolock,
con testfixture extendido preparado/compilado. Mobile265/domain296 pasan; checkpoint0301 ambos
assembleDebug y ambosAndroidTest compilados. Sin ejecutar instrumentación. Falla/reintento de
restauración conserva límites de autoridad, no implica loginreal probado.

## VínculoSaludsoloread03:04

AppleReperaStore.syncMissingWorkoutsToHealth explícitamente permite vincular workoutreloj
con lecturapermitida aun escritura denegada. Android retornaba antes de buscar si no había
write. Gatewrite movido solo al pasoInsert: reuse/adopt se rige por lectura+matcher existente.
Mobile265/0 y AndroidTestcompila, no providerreal; no se afirma flujocompleto probado.

## AmbigüedadexternaSalud03:06

associate tenía fallbackpropio tras dosfuentesexternas ambiguas, contra AppleoverlappingWorkout
que retorna nil en ese caso. Ahora externoambiguo permaneceAmbiguous y resolveLinkSkip:
noasocia propio casual ni insertanuevo por esa vía. UnJVM pasa/domain297/0, mobile265/0;
AndroidTestmóvilWearcompilan. Vínculoestableyaacreditado/clientRecordId conserva precedencia.
No providerreal ni cierre fusiónFC/plataforma.

## PropiedadderegistroSalud03:09

validStoredLink aceptaba registropropio marcado clientRecordIddeOTRAsesión si horario coincidía;
testprevio incluso documentaba esa excepción incorrecta. ApplelegacyOwn exige ausencia de
ReperaSessionID: ahora metadatoexplícito ajeno gana al horario, no reusa eseID. resolveLink
filtra propio deotrasSesiones, y lector conserva clientRecordId antes perdido. Testcorregido
con caso enventana, domain297/mobile265 pasan; ambosAndroidTestcompilan. Legacy sinID sigue
asociaciónporventana. Otrasrutas de lectura directa/recuperación aúnporcontrastar, no cierreprovider.

## LecturaSaludownership03:10

Misma exclusión de registropropio explícitodeotrasSesiones aplicada al fallback de lecturas
curva/nota (matchedSession), antes solo linkwriter. Si sessionIdausente tampoco se apropia
registropropio marcado. Legacy sinmetadato yexterno conservan reglas actuales. UnJVMnuevo
pasa/domain298/0, mobile265/0, ambosAndroidTestcompilan. No providerreal ni cierreE2E.

## CurvaFCcuentavieja03:13

heartSeriesProvider devolvía resultadoasíncrono sinvalidar dueño al terminar: ahora descarta
por owner+revision como detalleexterno/día. loadHealthToday revalida entre lecturaslargas
para no iniciar siguientetipo tras cambio. Lecturayaencurso puede finalizar pero no publica.
Mobile265/0 y AndroidTestcompila, sin proveedor ni UIreal.

## Sueño48hreales03:16

lastNight usaba edad0..2díaslocales, conservando hasta72h mientras Apple exige48hreales.
Ahora límite48h desde midnightobservada e ignora futuro; test borde+1s y findeDSTMadrid49h.
Domain299/mobile265 pasan, AndroidTestamboscompilan. El testviejo “hace2días” también era
incorrecto en26oct: hanpasado49h trasfinhorarioverano, corregido porcálculo, no relajado límite.
Sin UI/providerreal. Readinessactual sigue solo nochehoy como referencia actualApple.

## Iniciofechaseleccionada03:18

AppleHome solo muestra RecoveryHomeCard al seleccionarhoy. Android seguía mostrando
"Tu estado de hoy" al consultar otra fecha; ahora oculta esa tarjeta fuera dehoy. No inventa
recuperación histórica. AndroidTestamboscompilan/mobile265pasa, noUI/píxeles. TestlogoutWear
ahora exige prefs/outboxes vacíos antes de limpiar fixture, para no tocar datospreexistentes.

## RepositoriostaleCAS03:22

save delWorkoutRepository antes publicaba cualquierJSONObject leído aunque otra instancia o
Drive lo hubiera cambiado. Ahora guarda bytesdeorigen asociados a objeto leído y CASantesde
write: rechaza con mensaje de reintento sin sobreescribir. No autoreintenta ni fusiona acciones.
Mobile265/0, assemble+AndroidTestcompila; prueba dosrepositorio/stale/fresh preparada, noejecutada.
NOtransacciónglobal: outboxes, pendingreview y otros efectosprevios a save pueden ya existir;
CAS no losrevierte y reset aún requiere contrato. Historial no se declara seguramentecerrado.

## Reviewprefsaisladas03:25

Pendingreview/formulaversion usaban preferences globalesdewriter; otra cuenta podía consumir
laIDpendiente antes que dueño o saltarse refreshformula. Ahora preferencesporcuentahasheada,
writerIdglobal permanece identidaddevice. No se migra pendiente global sin dueñoverificable:
review ya está dentrohistorial, pero avisoúnicoantiguo puede no reaparecer. finishInPlace
publica pendiente DESPUÉSsave correcto, no antes. Test2cuentas preparado/compilado, mobile265/0.
No instrumentación ejecutada. No globaltransacciónoutbox/estado ni resetcerrado.

## Duracióncardioseñal03:27

readSessionSample mezclaba FC/kcal del workoutasociado pero duración deventanalocal, que
podía diferir. Ahora duración medida del registroasociado, restando segmentospause con
HealthWorkoutMinutes existente; si metadatoopcional inválido/ausente usa rangodelregistro,
no rangolocal. Domain300/mobile265pasan y ambosAndroidTestcompilan. No proveedorreal,
no métricasinventadas ni trasladar tiemposlocaleshistóricos automáticamente.

## Ceroobservado0328checkpoint

Duraciónmedida0 (registrocompletamentepausado) conserva0, no cae a rangobruto activo.
Testextendido pasa. Checkpoint0327: domain300/0/mobile265/0, ambosassembleDebug y ambos
AndroidTestcompilan. NoUI/provider/sensor/transporte/píxelesniGLOBALregresióninstrumentada.
ÚltimoWearlintverde f4b40758, mobilelintsinresultado. SinCI/push/beta/gasto.

## WearunidadesHYROX03:31

WatchSummary no incluía LOAD_DISTANCE como registrable y REPS_ONLY caía a "strength".
Ahora loadedcarry/sled localAndroid registra peso+metros sin RIR ni duraciónficticia ni togglemáquina;
bodyweight usa repsOnly explícito, draftpeso ignora targetWeight si modo noadmitempeso.
TestparserHYROX/bodyweight preparado/compilado, assembleWearpasa; domain300/mobile265JVMpasan.
NoUI/transporte/hardware ejecutados. No cierra adaptaciónHYROXApple completa ni navegaciónoffline.

## Wear: cantidad manual y movimiento, 03:34

La cantidad manual ya no toma como origen el contador de movimiento para modos sin
movimiento. Eso hacía que un hold precargado a 1 siguiera en 1 al pulsar +, en lugar de 2.
También se conservan las cantidades manuales de metros y máquinas. RepsOnly y HSPU
comparten ahora la admisión de movimiento de fuerza de WatchSessionHub; LOAD_DISTANCE
queda fuera porque Android lo representa expresamente en metros, no como repeticiones.
Duración y déficit se acotan antes de llegar a la cola (86400 s y 60 cm respectivamente).

Dos tests JVM de política de cantidad/movimiento ejecutados: domain 302/0, mobile 265/0,
sin errores ni omisiones. Assemble Wear y compilación AndroidTest Wear pasan.
No hay dispositivo conectado ni imágenes de esta revisión. Sensores, controles reales y
sincronización siguen sin validar en ejecución. Esto no cierra persistencia del draft,
navegación offline ni finalización autónoma.

## Wear: prescripción HSPU y unidades, 03:36

HSPU interpreta targetWeightKg como déficit en cm (WatchSessionHub.resetSetDraft),
no como kg, y lo precarga sin inventar lastre. Un target sin targetReps conserva null:
optInt antes lo convertía en 0 y desactivaba la sugerencia por movimiento sin prescripción.
El encabezado de objetivo usa m/cal/reps y cm/kg correspondientes, no siempre reps/kg.
Test parser preparado y compilado; assemble Wear pasa. Sin ejecución AndroidTest ni píxeles.
Queda abierto el avance de la siguiente prescripción tras ACK, además de persistir drafts.

## Wear: borrador recuperable y cursor de prescripción, 03:39

El draft manual se guarda localmente al cambiar campos y al salir de Activity. Al
recrear Activity se recupera solo si coinciden sesión, ejercicio y número total de
series confirmadas. Un draft no entra en la cola ni cuenta como serie. Logout/clear
lo borra; un ACK que cambia el número de series reinicia la prescripción siguiente.
El cursor cuenta también calentamientos para reiniciar el draft, pero solo las series
de trabajo consumen objetivos, igual que Models.nextWorkSetPrescription.

Tres tests JVM nuevos de roundtrip, identidad/cursor y descarte de entradas corruptas
se ejecutaron (domain 305/0, mobile 265/0). Compilan assemble Wear y AndroidTest Wear.
Prueba Activity/recreate preparada y compilada, NO ejecutada. No hay píxeles nuevos.
Quedan fuera: recuperación de pausa/descanso tras proceso, métricas durables, borrador
de drop/rest-pause, navegación offline y resolución de múltiples series pendientes
antes de ACK. Se guarda el draft de la pantalla, no se inventan ACK ni objetivos consumidos.

## Wear: recuperación de pausa/descanso local, 03:43

Checkpoint de pausa y milisegundos restantes ligado a sesión y BOOT_COUNT. Tras recreación
la pausa conserva el tiempo; un descanso activo descuenta el tiempo transcurrido por reloj
monotónico, no añade segundos por ticks retrasados. Tras reboot, BOOT_COUNT desconocido o
reloj monotónico incoherente no recupera un descanso potencialmente falso y muestra aviso.
Se guarda al empezar/saltar descanso, pausar/reanudar y salir de Activity; clear/logout lo borra.
No supone confirmación de pausa del teléfono ni del sensor: el ACK/estado de ambos sigue abierto.

Cuatro tests JVM nuevos ejecutados (domain 309/0, mobile 265/0, sin errores/omisiones).
Ambos assembleDebug y ambas compilaciones AndroidTest pasan. Fixture Activity recuperando
pausa+draft preparada/compilada, no ejecutada. No UI ni hardware validados.
Wear lint del commit anterior d223149f: 0 errores, 20 warnings, 6 hints; no atribuirlo al nuevo HEAD.

## Identidad: bandeja IA y espejos, 03:51

Las tareas iniciadas por Main para bandeja IA, contexto IA y espejo de entrenos conservan
identidad/revisión durable. Revalidan antes/después de peticiones, antes de importar local,
antes de ACK remoto y antes de guardar huellas/confirmar tombstones. La respuesta de bandeja
no actualiza la UI de otra cuenta ni un login A-B-A. Contexto/espejo comprueban además que
owner del store y sesión Supabase coincidan. No se hicieron peticiones reales ni cambios backend.

Tres tests JVM con interceptor sintético ejecutados: revocación antes de GET (cero llamadas),
revocación durante GET (respuesta rechazada) y autoridad conservada. Mobile 268/0, domain 309/0,
sin errores/omisiones. Assemble y AndroidTest móvil compilan. Tres fixtures instrumentados
espejo/contexto preparados y compilados, no ejecutados. Las guardas no cancelan una petición
ya enviada ni hacen transacción conjunta con logout/CAS/huellas. Realtime IA y atomicidad
completa de importación multi-ejercicio siguen abiertas.

## Wear: cola multi-instancia, 03:54

PendingSetStore y PendingFinishStore serializan read-modify-write entre todas las instancias
del proceso, no solo en el objeto que atiende una Activity. Evita perder append/ACK de una
segunda instancia y sobreescribir un fin de otra sesión. No es bloqueo entre procesos ni
transacción conjunta de snapshot, draft y ambas colas.

Dos pruebas instrumentadas de app aislada preparadas/compiladas (60 append paralelos,
30 ACK y dos finish de sesiones distintas). No ejecutadas. Assemble Wear pasa;
domain 309/0 y mobile 268/0 se mantienen. Sin red, CI, push ni beta.

## Wear: snapshot vacío no borra inicio offline, 03:56

WatchSessionHub ignora sesión nil del teléfono para no borrar trabajo offline. Android
limpiaba snapshot/watchStarted/draft incluso si el reloj acababa de empezar el plan y el
DataItem vacío del teléfono era anterior. Ahora conserva sesión iniciada en reloj ante
vacío o sesión distinta, con aviso de espera/conflicto; solo la misma ID adoptada o un
resumen final de esa ID permite reconciliar. Logout explícito sigue limpiando primero.
Matching adoption también quita watchStarted tras recreación, no solo en Activity nueva.

Dos JVM ejecutados: domain 311/0, mobile 268/0, sin errores/omisiones. Assemble Wear y
AndroidTest Wear pasan; fixture Activity vacía-preserva-draft preparado/compilado, NO ejecutado.
No cierra orden multi-DataItems entre cuentas, epochs, autonomía ni transporte real.

## Inicio: primera sección DUO y progreso semanal, 03:58 (sin validación visual)

Home fc3 coloca calendario/entreno primero; después Progreso semanal y Actividad en
columnas a ancho >=620. Android incorpora ese orden y ese primer par de columnas,
y mantiene Recuperación solo para hoy. Progreso semanal muestra siete días reales,
completado/planificado por accesibilidad y conteo de entrenos separado de días entrenados;
usa objetivo semanal existente, no uno inventado. Sin estado local indica falta de datos.
Los planes por fecha tienen prioridad sobre weekday recurrente, como makeWeekDays Apple.

Dos JVM de calendario y uno de corte 620 ejecutados: domain 313/0 y mobile 269/0, sin
errores/omisiones. Assemble y AndroidTest móvil compilan. Dos pruebas Compose preparadas,
NO ejecutadas. No hay dispositivo ni captura nueva, por tanto el layout es implementación
en curso y NO fidelidad cerrada. Pendientes ancho estrecho, fuente grande, rotación, píxeles,
panel derecho Ajustes, fondo/calendario expandido, demás DUO y dots de sesión aún activa.

## Progreso DUO: ejercicios/récords y corte por ancho de página, 04:03

StatsView.proAdvancedSections fc3 coloca ejercicios y récords juntos a >=620.
Android usa un par adaptativo compartido también con Inicio. Recuperación ahora recibe
los 32dp de padding de la página: antes comparaba el ancho interno y solo expandía
alrededor de 652dp de viewport, no a 620. En vistas sin padding conserva el corte directo.
No se cambia Free/Pro ni los datos de las tarjetas.

Mobile 270/0 y domain 313/0, sin errores/omisiones. Assemble y AndroidTest móvil pasan.
Prueba Compose del par estrecho preparada/compilada, no ejecutada. Columnas reales,
rotación, fuente grande y todos los píxeles siguen sin verificar. Actividad todavía no
replica su grid Apple de cuatro tarjetas. No se declara DUO completo.

## Wear: permisos y operaciones de sensores ligados a sesión, 04:06

El resultado de permisos ya no se aplica a la sesión visible que haya en ese momento:
conserva ID+revisión de la que abrió el diálogo, consume una vez y no permite relabelar
el diálogo pendiente con un segundo launch. A-B-A y logout invalidan el resultado.
Start revalida antes/después de consultar Health Services y antes de registrar callback/
identidad/inicio; pausa/reanuda verifican antes de actuar. Errores viejos no pisan la UI nueva.

Dos JVM nuevos de callback/ABA ejecutados: domain 315/0, mobile 270/0, sin errores/omisiones.
Assemble y AndroidTest Wear compilan. No diálogo real, proveedor ni sensores ejecutados.
No cancela start ya enviado ni resuelve una transición de callback de Health Services
posterior al último check. No cierra foreground, métricas durables ni lifecycle físico.

La resolución asíncrona de nodos de pausa también revalida sesión/revisión/transporte y
estado actual, para no enviar una pausa obsoleta tras logout o tras pulsar reanudar.
No hay ACK de pausa no-WOD del teléfono: el control local no afirma esa confirmación.

## Bandeja IA: preflight estructural antes de crear catálogo, 04:09

buildRoutine recorre primero el payload con resolver sin efectos; solo si todos los
bloques parsean lo recorre con el resolver real. Antes un bloque válido inicial podía
crear ejercicios y un bloque posterior inválido abortaba dejando esos ejercicios.
No duplica llamadas reales al resolver. También rechaza pesos no finitos explícitamente.
Dos JVM nuevos ejecutados: fallo tardío implica cero llamadas al resolver; payload válido
resuelve una sola vez por ejercicio. Mobile 272/0, domain 315/0, sin errores/omisiones;
assemble y AndroidTest móvil compilan.

No es transacción global: fallos de almacenamiento, CAS, límites o programación rechazados
por createRoutineFromScan después de resolver pueden seguir dejando catálogo añadido.
Parser permite 12 bloques mientras createRoutineFromScan permite 10; discrepancia pendiente,
no se oculta recortando planes. No se importaron planes reales ni se hizo ACK remoto.

## Bandeja IA: catálogo y rutina en un solo CAS local, 04:15

importAiRoutine monta ejercicios nuevos y rutina sobre el mismo JSONObject de origen,
revalida cuenta y guarda una sola vez. Fallo tardío de parse, validación, revocación o CAS
no guarda ninguno de los dos. Revisa de nuevo conflicto por fecha e ID bajo la copia
que se va a guardar; reintento de ID existente conserva ediciones y no reconstruye.
La ruta IA admite hasta12 bloques, como AITrainingInboxStore Apple; el escáner conserva
su límite10. El ACK remoto sigue después del guardado local y puede reintentarse.

Mobile 272/0 y domain 315/0 ejecutados; assemble y AndroidTest móvil pasan. Tres fixtures
instrumentados preparados/compilados: fallo tardío sin catálogo huérfano;12bloques con
una revisión/reintento sin rebuild; CAS concurrente/revocación sin media importación.
NO ejecutados. No hubo importación real ni petición backend. Esto no hace atómico el
ACK remoto ni otros writes/outboxes del repositorio; tampoco cierra cuotas multidispositivo.

## Programas IA y consentimiento de compartir: resultados antiguos, 04:19

Refresh/cambio de estado de programas y refresh/cambio de compartir resultados con centro
usan revisión durable y de pantalla. Las consultas y cambios verifican cuenta antes y
después de red; resultados viejos no actualizan programas ni toggles de otra cuenta.
Cambio de identidad limpia estado IA/compartir, no solo logout explícito.
Dos JVM con interceptor ejecutados: revocación bloquea GET/PATCH sin enviarlos y respuesta
de GET tras cambio de cuenta se rechaza. Mobile274/0, domain315/0, sin errores/omisiones.
Assemble móvil terminó; el primer comando agotó120s al compilar AndroidTest, que pasó en
llamada acotada posterior. Sin backend real ni flujo UI ejecutado. No cancela PATCH ya enviado.

## Acceso IA: tokens y propuestas ligados a cuenta, 04:24

Crear/revocar/listar tokens y decidir/refrescar propuestas conservan revisión durable y
revisión de pantalla. Revalidación antes/después de red y antes de aplicar cambios locales;
una respuesta de token de la cuenta anterior no se presenta en la nueva. Stores de cambios
verifican owner, y sync de catálogo no continúa en cuenta revocada. ACK de efecto local ya
hecho puede persistir aunque cambie cuenta, para evitar repetir una operación consentida.

Mobile276/0, domain315/0, sin errores/omisiones. Assemble móvil y compilación AndroidTest
pasan. Dos JVM de token sinenvío/revocacióndurantelectura ejecutados; fixture de propuestas
revocadas preparado/compilado, no ejecutado. No se crearon tokens ni decisiones reales.
No se cancela una petición ya enviada ni se hace transacción logout+efecto local+ACK.
ACKs multi-instancia y revisión local durante espera de revisión remota siguen abiertos.

## Propuestas IA: ACK durable y replay sin volver a presentar, 04:25

Refresh antes quitaba del conjunto los ACK enviados y después usaba ese conjunto para
filtrar las mismas filas GET antiguas: volvía a presentar cambios ya aplicados. Ahora
filtra contra el lote original y elimina cada ACK confirmado sin pisar otros concurrentes.
Queue/remove serializan entre instancias y commit verifica persistencia. Reintentar decide
sobre un ID pendiente de ACK solo reenvía ese ACK, no vuelve a borrar/aplicar localmente.

Mobile276/0, domain315/0, sin errores/omisiones. Assemble/AndroidTest móvil pasan.
Dos fixtures instrumentados sintéticos de replay y60ACK paralelos preparados/compilados,
NO ejecutados. Sigue abierta la ventana efecto local→queueAck: no es transacción conjunta,
y un corte exactamente ahí podría perder el ACK. No backend real ni cambios consentidos reales.

## Propuesta IA: revisión local además de remota, 04:29

Se conserva huella del entreno local antes de consultar la revisión remota; patch/delete
la comparan contra el mismo objeto que van a guardar, antes de tombstone o modificación.
Si el usuario u otra sincronización cambió el entreno durante GET, la propuesta se rechaza
sin borrar ni sobrescribir ese cambio. Se elimina el tombstone redundante previo del store:
lo emite deleteWorkout tras comprobar huella. CAS sigue protegiendo edits después de lectura.

Mobile276/0 y domain315/0 ejecutados; ambos assemble y ambas compilaciones AndroidTest
pasan en checkpoint0429. Fixture stale patch/delete y digest actual preparado/compilado,
NO ejecutado. No es CAS remoto ni transacción tombstone+snapshot. No backend real.

## Realtime IA existente: filtro y cola de callbacks, 04:34

AIPlansRealtimeListener ya existía y Main lo inicia en foreground; la afirmación antigua
"Realtime ausente" era inventario obsoleto, no un hueco por implementar. Su ejecución E2E
sigue sin validar. Se corrige filter de eq.uid a owner_id=eq.uid (contrato oficial Supabase),
cola LinkedBlockingQueue que rechazaba null en mensajes ignorados/cierre y podía lanzar
NullPointerException en callbacks, y salida de join sin respuesta en25s para reconectar.
Callbacks revalidan owner/token/generación después de esperar; generación es volatile.
Eventos INSERT exigen tabla y esquema esperados. No se abrió socket real.

Mobile277/0, domain315/0 ejecutados; assemble y AndroidTest móvil pasan. Test de filtro
actualizado y tabla ajena nuevo. No E2E de suscripción/cierre/cambio cuenta, no certificación
Realtime ni reducción de pendientes de hardware/píxeles. Fuente oficial consultada:
https://supabase.com/docs/guides/realtime/protocol

### Biblioteca, selector y ficha simultáneos (26 oct, local)

Referencia: `LibraryView.swift` de fc3ef7e1, `usesSplitExerciseLayout` y rama `HStack`.
En el catálogo de ejercicios Android, una anchura disponible de al menos 620 dp
muestra lista y ficha en paralelo; por debajo se conserva la navegación existente.
La ficha comparte proveedores de evolución, 1RM e incremento con la ruta compacta,
y abre el mismo borrador de registro rápido. La selección se guarda por cuenta,
se marca en la lista y tiene un estado vacío cuando el ID ya no existe.
Deportes conserva su rama separada. No se añade un catálogo WOD equivalente en
este cambio ni se declara cerrada la paridad completa de Biblioteca.

Validación local: pruebas JVM móvil y dominio, ensamblado móvil/Wear y compilación
de AndroidTest móvil/Wear correctos. Dos fixtures nuevos cubren selección inline,
cambio de cuenta y navegación compacta, pero solo están compilados, no ejecutados.
No hay dispositivo conectado ni emulador instalado en este entorno; faltan píxeles
reales, ejecución a 619/620 dp, tamaños de letra grandes y rotación. Sin CI, push,
beta, cambios Apple ni servicios de pago.

### Diario: contrato de catálogo y columnas (26 oct, local)

La revisión de `PlanView.scheduleContent` y `ReperaStore.libraryRoutines` encontró
otra diferencia funcional además del diseño: los entrenos con fecha no pertenecen
al Diario; una plantilla asignada a un día semanal sigue siendo reutilizable.
Android antes mezclaba entrenos por fecha, favoritos y programación en una lista,
y su biblioteca excluía las plantillas semanales. `DiaryCatalog` separa ahora estos
contratos sin borrar ni migrar datos: Programado muestra siete días ISO y sesiones
profesionales, Rutinas contiene todas las plantillas sin fecha, ordenadas en español.
Los entrenos sueltos siguen en Inicio. Se mantienen las acciones de editar/borrar,
favorito, progresión y empezar, además de copiar/vaciar programación con confirmación.

Desde 620 dp Programado y Rutinas se presentan simultáneamente; el editor de contenido
de una plantilla ocupa la columna derecha sin tapar Programado. Volver descarta su
borrador; reducir anchura o cambiar cuenta abandona la selección inline. En compacto
se alterna Programado/Rutinas. Los programas IA se muestran solo en Programado.

Validación local: tres pruebas JVM nuevas de catálogo (fechas, asignación semanal,
orden y día inválido) ejecutadas. Dos fixtures Compose nuevos compilados, no ejecutados.
Continúan abiertos la asignación desde un día vacío, el editor de altas en columna,
los detalles visuales y los ensayos reales de rotación/letra grande/anchuras límite.
El menú Añadir conserva su flujo anterior; no implica paridad completa con DayOverrideSheet.
No se declara Diario ni DUO visualmente terminados. Sin cambios Apple, CI ni beta.

### Diario: asignación de plantilla existente a un día libre

El día libre abre ahora el selector de plantillas reutilizables (excluye fechas,
incluye semanales), usando la acción persistente existente de editar programación.
Al reprogramar una plantilla a un día ISO, el repositorio desasigna las otras
plantillas recurrentes de ese día sin borrarlas ni tocar entrenos fechados. Esto
replica la exclusividad de `ReperaStore.assignRoutine`; antes Android podía guardar
varias semanales para el mismo día y la vista `firstOrNull` ocultaría una de ellas.
Dos pruebas JVM de exclusividad/idempotencia ejecutadas; fixture de selector y
fixture del repositorio compilados, no ejecutados. La exclusividad de otros caminos
de alta/importación, el botón de alta en el selector y el gesto de quitar del día
siguen pendientes; no se amplía este cambio a migraciones o importación remota.

Actualización del mismo hito: exclusividad semanal extendida a las cuatro altas
nativas (simple, escáner, bloques y WOD). Importación IA exige fecha y no modifica
este contrato. Se validan también día/hora antes de crear desde bloques. El plan
permite quitar del día conservando plantilla y hora, sin borrar entrenamiento.
Fixture del alta escaneada compilado; las pruebas JVM de exclusividad siguen verdes.
Importación de archivos/espejo y conflictos de entrenos con fecha siguen fuera de
esta corrección, sin migración automática ni promesa de unicidad global.

### Inicio: Ajustes en columna derecha (26 oct, local)

`HomeView` de fc3ef7e1 abre Ajustes en `ogTrailingColumnPanel` desde 620 puntos,
con la mitad derecha del ancho y un fondo negro al 10 %. Android añade ese panel
local desde los botones Ajustes de Inicio; la página no se sustituye. Fuera de Inicio
o en compacto se mantiene la ruta anterior. Los mismos callbacks y contenido se
comparten entre la ruta y el panel; no se duplican ajustes ni persistencia. Cerrar,
tocar fuera o Atrás descartan el panel, y cambio de cuenta/ruta o anchura compacta
limpia su selección. Las subpáginas siguen navegando a pantalla completa en Android:
no se declara equivalente la navegación anidada dentro del NavigationStack de Apple.

Validación: móvil 282 y dominio 315 JVM correctos, ensamblado y compilación AndroidTest
móvil/Wear correctos. Fixture de geometría mitad derecha, cierre y acción interna
compilado, NO ejecutado. No píxeles ni validación de accesibilidad, z-order con diálogos,
tamaños de letra grandes o rotación real. Panel dentro del área de contenido Android;
la extensión a barras/safe areas de Apple no está replicada ni verificada.

La lista de programas IA del Diario ya no trunca en tres: conserva todas las filas
recibidas del almacén, como PlanView (el límite remoto existente sigue en su fuente).
Corregido también el selector semántico del fixture de estado vacío de Biblioteca:
se busca el texto descendiente, no como hijo directo del contenedor de ficha.
Son correcciones de cobertura local; no convierten los fixtures en ejecutados.

### Cuota Gratis: plantillas, no entrenos fechados

Al seguir el contrato Diario/Rutinas se detectó que MainActivity alimentaba la cuota
con `overview.routines` (todas las rutinas, incluidos entrenos con fecha). Apple
`libraryRoutineCount` cuenta solo `scheduledDate == nil`, incluidas las semanales.
Se añade el contador derivado equivalente y se usa en todas las actualizaciones de
SubscriptionManager, también en callbacks de creación de ejercicios personalizados.
El total general de rutinas sigue disponible para estadísticas/exportación y no se
cambia el límite de tres, precios, productos ni concesión de Pro. Una prueba JVM
verifica dos plantillas más un one-off: total tres, cuota dos y siguiente alta permitida;
con tres plantillas sigue denegada. Móvil 283/0 y dominio 315/0; AndroidTest compila.
No se ha realizado compra, activación de producto ni llamada de facturación.

### Wear: descanso no es la política del teléfono

Relectura de `WatchSessionHub.confirmSet` (Apple378, Watch sin cambios en fc3): el
reloj no inicia descanso tras calentamiento; tras serie de trabajo intermedia usa
el descanso prescrito y tras la última no inicia descanso. Android había reutilizado
`StrengthRestPolicy` de WorkoutView (45 s para calentamiento), que no es el contrato
de Watch. `WatchStrengthRest` separa las políticas y limpia descanso cuando no procede.
Cuatro JVM nuevos ejecutados; dominio 319/0, móvil 283/0, ensamblado y AndroidTest de
ambos módulos compilan. Sin ejecución UI/sensores. El cursor sigue dependiendo de la
última confirmación del teléfono: varias series encoladas antes de ACK aún no avanzan
la prescripción local. No se declara autonomía ni temporización completa cerradas.

### Acciones locales: revocación durante ejecución asíncrona

`runWorkoutAction` antes comprobaba la cuenta solo después del trabajo. Ahora captura
la revisión duradera de identidad y la de pantalla, valida antes de empezar y pasa
un guard al repositorio. El repositorio lo comprueba antes de cargar, guardar snapshot
y emitir tombstone de borrado. Un cambio de identidad durante materialización del
borrador impide su commit, sin dejar medio catálogo. Dos fixtures de revocación antes
de leer y durante materialización compilados, NO ejecutados. Móvil 283/0 y dominio
319/0 ejecutados, ensamblado y AndroidTest móvil correctos. La invocación conjunta
anterior agotó el tiempo disponible sin resultado, luego ambas validaciones acotadas
terminaron correctamente. No se ha probado logout real.

Límite: guard y escritura no son una transacción global con SessionStore; otros efectos
auxiliares y llamadas al repositorio que usan su guard predeterminado siguen abiertos.
Esto bloquea resultados obsoletos comprobables, no promete atomicidad global ni borra
trabajo ya confirmado antes de cerrar sesión.

### Editor de rutina: título sugerido y bloques en un solo guardado

El selector de WOD podía sugerir título al guardar. La ruta de edición existente,
y luego el editor inline, lanzaban primero `onEditRoutine` y después guardar bloques;
MainActivity marca busy en la primera acción, por lo que la segunda se descartaba.
Ahora la sugerencia queda en el borrador y se envía junto con los bloques a una sola
acción y un solo CAS del repositorio. Si falla validar título/bloques no se persiste
ninguna mitad. Fixture nuevo compilado, NO ejecutado. Móvil 283/0 y dominio 319/0,
ensamblado y AndroidTest móvil correctos. No píxeles ni interacción real de selector.
El cierre optimista del editor ante error de guardado sigue abierto; no se declara
fiabilidad completa del flujo por corregir esta pérdida concreta de contenido.

Actualización del mismo flujo: los editores de plantilla compacto e inline ya no
cierran justo al pedir guardar. Cierran solo mediante callback tras acción y recarga
correctas; si la validación/CAS falla, permanecen con el borrador y muestran el estado
de guardado. Móvil 283/0 y dominio 319/0; ensamblado y AndroidTest móvil correctos.
Sin ejecución UI ni simulación instrumentada de error asíncrono en MainActivity.
Los otros editores (sesión/one-off/escáner) conservan sus contratos anteriores y
requieren el mismo contraste; no se extiende esta conclusión a todos los guardados.

### Otros borradores: cierre tras éxito, no al solicitar guardado

Sesión libre, entreno fechado y revisión del escáner ahora reciben callback de éxito
real de runWorkoutAction y cierran solo después del guardado/recarga. Fallos conservan
borrador y estado visible; el editor activo ya usaba callback y añade estado visible.
No cambia la cuota, OCR, catálogo, captura GPS ni política de permisos. Móvil 283/0 y
dominio 319/0; ensamblado y AndroidTest móvil correctos. Sin pruebas UI ejecutadas del
error asíncrono, rotación o proceso muerto. Guardado correcto seguido de error de
recarga puede dejar el editor abierto: idempotencia del reintento de altas con ID nuevo
sigue siendo un límite, no se declara resuelto mediante estos callbacks.

### Reintento del entreno fechado: ID del borrador

El alta one-off ahora conserva un ID de solicitud con rememberSaveable por cuenta,
fecha y nombre, y el repositorio guarda esa misma identidad. Si el guardado ya existe,
el reintento devuelve su ID sin duplicar ni sobrescribir cambios posteriores. Esto
cubre el caso guardar correcto/recarga fallida en ese flujo mientras se conserva su
estado de navegación. Fixture de retry y edición posterior compilado, NO ejecutado.
Móvil 283/0 y dominio 319/0; ensamblado y AndroidTest móvil correctos. No se convierte
el borrador completo en persistencia durable: recreación/rotación/proceso no probados,
ni reintento después de borrar el registro o perder el estado de navegación. Escáner
y sesión libre aún no reciben el mismo contrato de ID estable en esta corrección.

### Escáner: solicitud estable por revisión

Cada resultado OCR nuevo reserva una identidad de revisión; Crear rutina y sus
reintentos usan esa ID. Si ya existe, el repositorio no añade otra fila ni pisa una
edición posterior. Repetir foto y obtener otro resultado generan otra identidad.
Fixture del repositorio compilado, no ejecutado. Móvil 283/0 y dominio 319/0,
ensamblado y AndroidTest móvil correctos. No OCR real/cámara ni proceso muerto.
La revisión completa sigue en memoria, no durable. Sesión libre conserva todavía
su contrato anterior; no se extrapola esta idempotencia a todos los flujos.

### Sesión libre: identidad de solicitud

El borrador de sesión reserva una ID recuperable por cuenta en navegación. El
repositorio la registra como draftRequestId en la sesión: reintento con esa ID
retorna la sesión activa ya creada, sin otra plantilla favorita ni trabajo duplicado.
Si esa solicitud ya está en el historial terminado, rechaza reiniciarla en lugar de
crear otro entrenamiento. Fixture de activo/retry/favorito/terminado compilado, no
ejecutado. Móvil 283/0 y dominio 319/0; ensamblado y AndroidTest móvil correctos.
No se preserva un ledger después de descartar/borrar sesión ni tras perder navegación;
no equivale a borrador durable ni recuperación completa de proceso. Captura de ubicación
sigue su callback anterior, sin pruebas GPS reales ni nueva autorización de proveedor.

### Escáner: vida de cuenta y cancelación OCR

La composición del escáner queda identificada por cuenta: cambiar cuenta descarta su
revisión/solicitud y cancela su scope anterior en lugar de permitir guardar la revisión
vieja en el nuevo propietario. Cancelación OCR se propaga como cancelación, no como
error de lectura. El reconocedor ML Kit se cierra al terminar/cancelar y no intenta
entregar a una continuación ya inactiva. Móvil 283/0 y dominio 319/0; ensamblado y
AndroidTest móvil correctos. No cámara/OCR real ni cambio de cuenta instrumentado:
la cancelación del proveedor y sus carreras siguen sin prueba física, y esto no añade
persistencia durable ni restituye cuotas consumidas legítimamente antes del cambio.

### Selectores multimedia: resultado vinculado a identidad de apertura

Foto de perfil y cámara/galería del escáner capturan la revisión duradera de identidad
al abrir el selector. Un resultado recibido después de cambiar cuenta se descarta,
no se reasigna a la cuenta actual. La foto aplica sobre el perfil más reciente, no
sobre la copia vieja al lanzar el selector. Con recreación que pierda la solicitud
pendiente se descarta el resultado, requiriendo abrir de nuevo; no se inventa dueño.
Móvil 283/0 y dominio 319/0; ensamblado y AndroidTest móvil correctos. Sin selector real,
rotación ni prueba de callback tardío instrumentada, y sin publicación de foto/perfil.
La revisión y la escritura no forman una transacción global; límite previamente señalado.

### Cuota de escáner: instancias concurrentes

FreeUsageStore ahora serializa por archivo y recarga antes de consumir. Una instancia
con estado antiguo no puede sobrescribir el consumo de otra ni contar dos veces el
mismo intento. Dos JVM nuevos ejecutados: instancias obsoletas y doce intentos
concurrentes conservan exactamente el límite mensual de cuatro. Móvil 285/0 y dominio
319/0; ensamblado y AndroidTest móvil correctos. Persistencia sigue siendo local por
dispositivo; no se ha añadido sincronización entre dispositivos ni backend, cambiado
el límite o concedido Pro. Recuperación ante archivo corrupto y atomicidad frente a
interrupción de escritura conservan los límites anteriores y requieren auditoría aparte.

### Cuota de plantilla: entradas de creación

Las acciones de alta simple, WOD y escáner vuelven a comprobar el permiso de crear
plantilla en MainActivity, no solo en un botón de UI. El editor simple omite ese gate
para entreno con fecha, que no consume cuota de plantillas. Reintento del escáner con
ID ya persistida se reconoce contra el archivo actual, no solo la vista que pudo
fallar al recargar, y no requiere otra plaza. No cambian límite, precio ni Pro.
Móvil 285/0 y dominio 319/0; ensamblado y AndroidTest móvil correctos. Sin interacción
paywall real; contadores de permiso frente a escrituras externas concurrentes y gates
en importadores siguen abiertos. No es una transacción entre cuota y snapshot ni
sincronización de consumo entre dispositivos.

Actualización de persistencia de cuota: si escribir el consumo falla, se restaura el
estado previo en memoria y se propaga el error; no se presenta un consumo no guardado
como éxito. JVM nuevo fuerza fallo creando un directorio en el temporal y comprueba
estado previo más reintento posterior correcto. Móvil 286/0, dominio 319/0; ensamblado
y AndroidTest móvil/Wear correctos. No demuestra recuperación frente a corte de energía
ni cambia el fallback histórico ante JSON corrupto.

### Wear: auditoría de vida del registro con pantalla apagada

Confirmado por lectura del manifiesto y WearHealthSession: permisos foreground existen,
pero no hay servicio foreground de registro. ExerciseClient y su callback dependen
actualmente de objetos creados por Activity. No basta el permiso declarado ni reconectar
la sesión para demostrar continuidad con pantalla apagada/cambio de app/proceso muerto.
La guía oficial requiere mantener un ForegroundService con el tipo adecuado durante
el ejercicio y usar ExerciseUpdate como fuente de verdad de pausa. El tipo health exige
permisos runtime y está sujeto a restricciones while-in-use al crearlo desde background.
No se introduce un servicio nominal sin mover dueño, callbacks y recuperación del
registro: sería una falsa cobertura. Quedan diseño del dueño, arranque visible,
notificación/Ongoing Activity, recuperación, métricas durables y pruebas de sistema.
Sin cambios de código ni nueva solicitud de permisos en esta auditoría.

Fuentes oficiales consultadas:
- https://developer.android.com/health-and-fitness/health-services/active-data
- https://developer.android.com/develop/background-work/services/fgs/service-types
- https://developer.android.com/health-and-fitness/health-services/permissions

### Wear: identidad y hora de ejecución al tocar Iniciar

Apple WatchSessionHub.startToday crea una sesión nueva al iniciar: la prescripción no
es la ejecución. Android reutilizaba ID y startedAt del plan generado por el teléfono,
por lo que podía incluir espera previa como duración o reutilizar identidad de plan.
WatchPlanExecution crea ID/hora actuales al tocar, conserva objetivos/routineId, empieza
en counting y rechaza planes con trabajo registrado. El inicio se confirma en disco
antes de exponerlo o iniciar sensores; fallo de almacenamiento conserva el plan.
Dos JVM nuevos ejecutados: copia sin mutar prescripción, ejecuciones independientes,
hora del toque y rechazo de trabajo previo. Dominio 321/0, móvil 286/0; ensamblados y
AndroidTest móvil/Wear correctos. Sin inicio real ni sensores, y no cierra navegación,
finalización offline, métricas durables, transporte ni servicio foreground.

Seguimiento del inicio Wear: la nueva ejecución limpia también pausa, descanso,
reloj WOD y resumen final en memoria, como startToday de Apple; no hereda temporizador
anterior aunque se hayan eliminado sus preferencias. Ensamblado y AndroidTest Wear
correctos, sin ejecución Activity/sensores. Reglas JVM anteriores sin cambios.

El método de inicio del plan también rechaza otra sesión activa o una petición de fin
pendiente, aunque se invoque fuera del botón visible. No sustituye ni descarta la sesión
anterior para iniciar un plan nuevo. Sin cambios en finalización autónoma.

El callback de terminar Wear valida que la sesión del botón sigue siendo la visible
antes de crear la petición durable; un callback obsoleto no finaliza otra ejecución.
Ensamblado y AndroidTest Wear correctos; callback tardío no ejecutado en dispositivo.
La petición sigue dependiendo del teléfono y no equivale a fin offline autónomo.

### 26 octubre 05:58 - creación de plantilla desde Diario

Comparado con `PlanView.createNewRoutine` y `DayOverrideSheet.onCreateNew` de
fc3ef7e1: Rutinas ofrece Nueva rutina; el selector de día libre ofrece Crear
nueva rutina con el nombre y weekday del día. El borrador no se persiste hasta
Guardar. Usa el editor de bloques, nombre editable y cuota de plantillas tanto
al abrir como al guardar; cuota de ejercicios personalizados en materialización.
El identificador estable del borrador reutiliza la protección existente contra
reintentar una creación ya guardada, sin sobrescribir posteriores ediciones.

En ancho >=620 el borrador aparece a la derecha conservando Programado; en
compacto reemplaza el contenido. Volver/Back descartan; cambio de cuenta limpia
selección. Guardar solo cierra tras el callback de éxito, no al solicitarlo.
El repositorio usa exclusividad semanal existente (desasignar sin borrar).

Validación local: mobile 286/0 y domain 321/0 (errores/omitidos 0), ensamblado
mobile correcto, AndroidTest compilado. Tres fixtures nuevos compilados, NO
ejecutados: alta semanal y reintento, borrador del día/cambio de cuenta y cuota
denegada. No hay píxeles nuevos ni prueba en dispositivo de compacto/expandido,
teclado, fuentes grandes, rotación o recreación. El contenido del editor sigue
en memoria: guardar el ID no recupera todos los campos tras muerte del proceso.
No se afirma fidelidad visual ni cierre de paridad total; sin push ni beta nueva.

### 26 octubre 06:08 - cuota de favorito y reintento de sesión libre

La sesión libre comprueba la cuota en el dueño de persistencia antes de
materializar ejercicios personalizados o guardar favorito/sesión. Cuenta las
plantillas sin scheduledDate del snapshot cargado. Un request ya activo vuelve
antes de esa comprobación y no consume otra plaza ni crea otro favorito.
La UI permite reintentar solo ese mismo draftRequestId aunque haya sesión activa;
no confunde el ID de solicitud con el ID de ejecución. Otra sesión sigue bloqueando.
El gate de entrada conserva el paywall cuando sí se pide una plantilla nueva.

Mobile 286/0 y domain 321/0, errores/omitidos 0. Assemble mobile y AndroidTest
compile correctos en invocaciones separadas; la primera invocación combinada
agotó el tiempo durante ensamblado, sin error de código. Dos fixtures nuevos
compilados, NO ejecutados: cuota denegada sin materialización y reintento exento;
sesión sin favorito no exige plaza. Sin UI/píxeles ni backend/cuota entre equipos.
No es una transacción global de cuotas y el proveedor del callback mantiene su
estado local; consumidores del repositorio sin callback conservan el default.

Extensión 06:10: altas de Diario y escáner repiten también su gate en el snapshot
cargado, tras devolver un ID ya guardado y antes de materializar bloques/customs.
Las rutinas de fecha concreta no exigen plaza de plantilla. El callback evalúa
una copia de la política con el contador cargado, sin mutar contadores Compose
desde IO. Fixture combinado adicional compilado, NO ejecutado: contar semanal,
excluir one-off, denegar sin efectos, reintento exento y scanner denegado.
Assemble mobile, AndroidTest compile y JVM mobile286/domain321 sin fallos.
Importadores, alta simple/WOD y favorito desde historial aún requieren revisar
este mismo endurecimiento; no se extiende el resultado a todas las altas.

Extensión 06:14: alta simple, WOD y favorito desde historial comprueban también
el contador de plantillas del snapshot cargado, antes de construir la nueva
plantilla o editar el historial. El favorito denegado no aplica título/notas ni
materializa customs. Editar sin favorito no exige plaza. Gate UI/paywall sigue.
Fixture combinado compilado, NO ejecutado: alta simple/WOD denegadas sin cambios,
favorito del historial denegado sin editar y edición sin favorito permitida.
Mobile286/domain321 sin fallo/error/omisión; AndroidTest compile y assemble móvil
correctos. Importadores siguen fuera de esta cobertura; defaults de repositorio,
cuota remota y transacciones globales no quedan resueltos.

### 26 octubre 06:19 - capacidades Health Services Wear

Auditoría de ciclo de vida confirma que WearHealthSession continúa ligado a la
Activity; no hay servicio foreground dueño del registro ni cleanup de callback
al destruir Activity. No se añade un servicio nominal ni se declara cerrado.
El reset Apple conserva ejercicios y vacía rutinas/entrenos/peso/sesión; Android
sigue sin ruta equivalente segura ante Drive/espejo/backups/colas. No se añade
un borrado parcial ni se ejecuta reset real durante esta auditoría.

Corrección acotada de sensores: antes de iniciar registro nuevo se consultan
capacidades de Health Services, se exige STRENGTH_TRAINING y se pide solo la
intersección pulso/kcal que el proveedor soporta. Si no hay tipo o métricas se
informa sin sustituir correr ni crear datos. Se revalida identidad tras await.
Reenganchar un ejercicio propio sobreviviente no reemplaza su configuración.
Dos tests de selección parcial/ausencia compilados, NO ejecutados. Assemble y
AndroidTest compile Wear correctos; JVM previo mobile286/domain321 sin cambios.
No hardware, permiso real, proveedor, pantalla apagada ni proceso terminado.

Fuentes oficiales leídas 26oct2026:
- https://developer.android.com/health-and-fitness/health-services/active-data
  exige verificar capabilities y limitar tipos/métricas al soporte del dispositivo;
  recomienda servicio foreground dueño del estado y datos durante todo el ejercicio.
- https://developer.android.com/develop/background-work/services/fgs/service-types
  tipo health, permisos runtime y restricciones while-in-use.
- https://developer.android.com/develop/background-work/services/fgs/launch
  inicio/promoción y comprobación de requisitos del servicio.

### 26 octubre 06:24 - dueño foreground de sensores Wear, implementación local

Sustituye la ausencia de servicio de los anexos anteriores: WearHealthService
privado, tipo health, ahora posee WearHealthSession con contexto de aplicación,
coroutines y callback independientes de la Activity. La Activity se enlaza para
lecturas/pausa y retira su observador al salir; no termina el ejercicio al girar
o cerrar la pantalla. La notificación persistente abre Repera y distingue
conectando/activo/pausa/terminando/error, sin marcar una llamada como confirmada.
El inicio se solicita solo desde Activity visible, tras permisos runtime, y
se promueve antes de consultar/iniciar Health Services. No pide background.

Valida el ID durable del snapshot antes y después de operaciones suspendidas;
cuando el snapshot cambia/desaparece solicita terminar solo el registro propio.
No asigna sensores de otra sesión. Terminar espera callback terminal; un fallo
conserva el servicio y anuncia revisión. Al destruir servicio retira callback,
no termina silenciosamente un ejercicio sobreviviente; al volver a UI se
reengancha por la identidad durable existente. START_NOT_STICKY: no reinicia
sensores por boot ni promete recuperación automática tras muerte del proceso.

Assemble Wear, AndroidTest compile y domain321/0 correctos. Fixture de manifest
privado/tipo health compilado, NO ejecutado. No píxeles de notificación ni prueba
hardware de permisos, cambio de app, pantalla apagada, destrucción del proceso,
reenganche, pausa o error de stop. No se declara cubierto ese ciclo de vida ni
paridad autónoma. Métricas no durables y Ongoing Activity API siguen pendientes.
Fuentes oficiales son las tres URLs del anexo 06:19; no nuevo permiso/coste.

Revisión 06:28: el servicio retira foreground también si Health Services termina
por sí mismo, no solo ante stop de Repera. Guarda el ID terminal localmente y
no crea otro registro para ese mismo entreno al recibir snapshots repetidos o
volver a UI; las series siguen disponibles. Una nueva ejecución usa otro ID.
Coalesce inicios mientras la consulta está en vuelo. No libera el dueño de un
stop durante start suspendido hasta que termina ese intento. Assemble y
AndroidTest compile Wear correctos; orden de callbacks/fin espontáneo/reentrada
siguen sin ejecución en dispositivo. No se presenta compile como prueba del
servicio ni de continuidad con pantalla apagada.

Revisión 06:29: stop consulta dueño real antes de endExercise, no depende solo
del boolean local recording. Permite terminar un ejercicio propio sobreviviente
antes del primer callback de este proceso y no termina el de otra app. Si el
proveedor confirma ausencia se marca terminal; si está propio se registra el
callback y espera su fin. Binding de sesión se revalida tras la consulta.
Assemble/AndroidTest compile Wear/domain321 correctos; proveedor no ejecutado.

Revisión 06:32: política determinista de retirada de dueño con cuatro pruebas
JVM ejecutadas. Un terminal recibido durante start no libera dueño hasta que
start retorna; stop solicitado y recording=false sin callback terminal NO son
confirmación de fin. El proveedor confirma ausencia o manda terminal antes de
retirar el servicio. Dominio325/0, errores/omitidos0; Wear assemble y AndroidTest
compile correctos. Estos tests cubren la decisión pura, no orden real del SDK,
notificación ni continuidad del servicio en un reloj.

Revisión 06:36: cada registro de callback de Health Services obtiene una
revisión nueva. Se invalida el callback anterior antes de esperar su retirada;
updates/fallos de registro ya encolados de esa revisión no modifican la siguiente.
Detach invalida también antes de await. Tras registrar se revalida identidad
antes de continuar start/stop. Assemble y AndroidTest compile Wear correctos.
Sin test de entrega tardía real del proveedor: no se considera cerrada la
reconciliación de callbacks de Health Services por una compilación correcta.

Revisión 06:39: al reenganchar registro propio se vacían pulso/kcal/pausa antes
de registrar callback y se esperan muestras actuales. Antes solo se vaciaban al
crear ejercicio nuevo; una instancia retenida podía mostrar valores previos al
reenganche. Assemble/AndroidTest compile Wear correctos, proveedor no ejecutado.
No se rellenan kcal con cero ni se trata ausencia de lectura como actividad cero.

### 26 octubre 06:42 - favorito desde sesión activa: séptima ruta de alta

La búsqueda transversal encontró otra ruta además de las seis del grupo previo:
saveActiveSessionAsFavorite. Apple llama saveRoutine para una plantilla nueva,
que aplica quota; marcar una rutina existente no crea plaza. Android ahora
comprueba el contador del snapshot antes de construir plantilla independiente;
marcar existente, incluida fechada, sigue permitido. Dos JVM nuevos ejecutados:
denegado no toca sesión/rutinas y existente no pide plaza. Mobile288/domain325,
fallos/errores/omitidos0; mobile assemble y AndroidTest compile correctos.
La auditoría anterior de seis rutas no era exhaustiva: no generalizar ese grupo
a todas las altas. Importadores/defaults/cuota entre dispositivos siguen abiertos.
Sin proveedor, UI nueva, datos reales, push ni distribución.

### 26 octubre 06:45 - contraste de plan profesional para Watch

Fallback profesional ya existe y se publica desde refresh Centro y reload,
con catálogo temporal no persistido; no declarar ausente por matriz histórica.
Contraste con professionalWorkoutForWatchToday de Apple encontró normalización
incompleta: Android cubría rft/forTime/every/emom pero no variantes mayúsculas o
con guiones bajos de amrap/tabata/chipper/circuit/ladder/strength. Alias ahora
literales de Apple; otros formatos preservan raw para parser, no se reinterpretan.
Dos pruebas JVM ejecutadas, dominio327/0; mobile288/0 y assemble/AndroidTest compile
correctos, errores/omitidos0. No transferencia física ni payload real de centro.
No permisos, rutinas privadas ni catálogo escritos durante proyección.

Revisión 06:49: proyección profesional aislada para que un JSONException al
recorrer un bloque/entrada inválido devuelva ausencia de plan, no aborte refresh
Centro antes de limpiar loading. Apple usa Decodable; Android recibe JSONObject
sin esa frontera. Fixture de bloque sin ID/tipo incorrecto compilado, NO ejecutado;
snapshot privado sin cambios esperado. Mobile288/domain327 sin fallos y
AndroidTest compile/assemble móvil correctos. No representa validación completa
del esquema ni prueba de payload real; se captura solo error estructural JSON,
no se ocultan fallos de disco/autorización fuera de la proyección.

### 26 octubre 07:06 - Biblioteca WOD: descubrimiento y favoritos, parcial

Apple LibraryView/WODTemplateDetailView permite catálogo WOD, ficha, favoritos,
play efímero y progresión. Android tenía solo picker Crear limitado a12; ahora
Biblioteca tiene entrada WODs con catálogo completo sin corte, búsqueda, favoritos
primero, ficha de formato/timecap/tiempo/músculos/notas y movimientos con pesos H/M.
Favorite usa settings.favoriteWODTemplateIds, no crea plantilla ni consume plaza;
conserva settings desconocidos y IDs importados futuros. Selección/búsqueda WOD
ligadas a cuenta. No se afirma ficha visual equivalente: miniaturas, play efímero,
historial/marca actual/último/Pro, fallback búsqueda a ejercicios y orden muscular
siguen pendientes. Picker Crear conserva su diseño separado y corte histórico.

Validación local: mobile290/domain327 sin fallos/errores/omitidos. Dos JVM nuevos
ejecutados; Compose fixture detalle/favorito compilado, NO ejecutado. Mobile
assemble y AndroidTest compile correctos. Sin píxeles/dispositivo, no cierre UI.
Tres timeouts de compilación y un daemon perdido precedieron al resultado;
compilación acotada con GCSerial/JIT limitado completó. No se cambian parámetros
del repo ni se reintenta CI ni gasto. Lo anterior no se usó como verde para WIP.

### 26 octubre 07:10 - play WOD efímero desde Biblioteca

Detalle WOD ahora ofrece Empezar ahora, como routineFromWODTemplate/playNow de
Apple. Construye rutina efímera y sesión en el mismo snapshot sin insertar
plantilla ni catálogo ni consumir plaza. Reusa constructor del alta WOD guardada
para no divergir en pesos/notas/ondas. Bloquea otra sesión/actividad En vivo;
request estable admite reintento de la misma activa y rechaza iniciar de nuevo
si esa solicitud ya está archivada. Navega a Inicio solo tras éxito. No fabrica
series/score. Una sesión ajena bloquea botón; retry propio no queda bloqueado.

Mobile290/domain327 sin fallos/errores/omitidos; mobile assemble y AndroidTest
compile correctos. Fixture repositorio nuevo compilado, NO ejecutado: cero
plantillas/customs/workouts/score inicial, request repetido misma ID y conflicto
otra solicitud sin cambios. Sin píxeles, teléfono/reloj real ni GPS/Health.
Historial WOD/miniaturas/fallback de búsqueda/orden muscular siguen abiertos;
no se declara ficha o flujo completo equivalente con esta compilación.

### 26 octubre 07:15 - historial de catálogo WOD por archivo completo

Lectura de todos los wodResults archivados, agrupados por wodTemplateId; no usa
las veinte tarjetas recientes. Replica comparator de LibraryView: menor tiempo
cuando ambos tienen elapsedSeconds, más reps cuando ambos tienen totalReps;
resto conserva orden. Lista muestra primera marca y ficha progresión: Pro todo,
Free primera y última ID distinta del array ordenado, con paywall si hay más.

Importante: Apple comenta «último cronológico» pero realmente usa history.last
DESPUÉS del ranking. Se replica ese consumidor, sin rebautizarlo último por fecha
ni corregir silenciosamente el contrato de Apple. No hay timestamp en WODBlockResult.
Dos JVM ejecutados: 25 resultados sin límite20, orden tiempo/reps y extremos Free
sin duplicar una marca. Mobile292/domain327 sin fallos/errores/omitidos; mobile
assemble y AndroidTest compile correctos. Sin UI/píxeles ni cuenta real, pendiente
prueba de gate Free/Pro visible y paridad de miniaturas/búsqueda/orden muscular.

### 26 octubre 07:18 - búsqueda WOD y orden muscular

Cuando una consulta no encuentra WOD, Biblioteca muestra coincidencias de
ejercicios con el índice de aliases existente y abre su ficha; no interpreta
la ausencia de WOD como ausencia de ejercicio. Orden WOD por Músculo usa etiqueta
muscular española y nombre, manteniendo favoritos primero. Se conserva catálogo
normal si la búsqueda está vacía. Estado de búsqueda/orden ligado a cuenta.
Dos fixtures UI nuevos compilados, NO ejecutados: extremos de historia Free sin
fila intermedia y fallback consulta sin WOD a ejercicio. Mobile292/domain327
sin fallos/errores/omitidos; mobile assemble y AndroidTest compile correctos.
La rama fallback usa navegación compacta a ficha, no duplica aún el split de
Apple >=620. Miniaturas y fidelidad visual siguen pendientes, sin píxeles nuevos.

### 26 octubre 07:22 - miniaturas del detalle WOD, implementación local

Movimientos resuelven nombre canónico/raw contra catálogo sin escribirlo, con
fallback efímero WOD si no existe; el detalle usa arte empaquetado y nombre de
la ficha resuelta. Dos JVM ejecutados: reutiliza identidad de catálogo y fallback
no crea ejercicios. Mobile294/domain327 sin fallos/errores/omitidos; mobile
assemble y AndroidTest compile correctos. Decodificación de imagen/recorte40dp
sin píxeles nuevos inspeccionados: NO certificar fidelidad, assets faltantes o
presentación final. El fallback >=620 aún navega compacto, no split Apple.

### 26 octubre 07:25 - intent foreground obsoleto/terminal

Revisión detecta retorno antes de startForeground para intent obsoleto o sesión
ya terminal: aunque no inicia sensores, ese retorno incumple el plazo de
promoción de startForegroundService. Se promueve antes de validar/retirar y,
cuando no hay dueño, retira la notificación y stopSelf. No termina otro dueño
por un intent tardío. Si promoción falla, informa al observador sin publicar
una notificación falsa ni declarar sensores activos. Wear assemble/AndroidTest
compile/domain327 correctos; deadline real/ANR/notificación NO probados en reloj.
Fuente: https://developer.android.com/develop/background-work/services/fgs/launch

### 26 octubre 07:29 - fallback WOD ancho

Se contrasta usesSplitExerciseLayout de LibraryView.swift fc3ef7e1: WOD solo
usa doble panel cuando consulta no vacía y no encuentra WOD; Deportes no.
Android incorpora esa condición >=620dp para fallback de ejercicios, con
selector y detalle real ExerciseDetailScreen compartido (e1RM probado/estimado,
incremento, progreso, quicklog). Catálogo/detalle WOD siguen sin doble panel;
compacto mantiene navegación externa. Selección saveable por cuenta; si el ID
ya no existe muestra placeholder, no elige otro ejercicio. Back solo consume
selección visible, no una selección oculta tras borrar consulta/reducir ancho.
Dos fixtures nuevos comprueban selección/cierre sin callback externo y
aparición/desaparición de split al buscar/borrar. Compilados NO ejecutados;
sin dispositivos ni píxeles nuevos. Mobile assemble/AndroidTest compile y
JVM294 correctos, sin certificar fidelidad visual ni interacción real.

### 26 octubre 07:32 - fallo await de inicio no prueba terminación Wear

Auditoría encuentra ruta adicional de retiro por recording=false al resolver
inicio. Un fallo de await/start/callback puede dejar ejercicio propio vivo en
Health Services. Antes de retirar por esa ruta se consulta ownership actual:
solo NONE u OTHER permiten soltar dueño/notificación, nunca OWNED/desconocido.
Error al consultar conserva foreground para reintento/stop desde UI visible;
no proclama recording ni fin. Ruta terminal mantiene confirmación previa.
Wear assemble/AndroidTest compile y dominio327 correctos, sin simulación de
proveedor ni dispositivo para verificar este fallo real.

### 26 octubre 07:38 - recuperación SavedInstance del editor de rutinas

Editor compartido ahora guarda título, favorito, título sugerido y bloques
mediante rememberSaveable por cuenta + ID. Codec conserva números aún inválidos
como texto, orden, JSON original desconocido, IDs, unidades, series/RIR y baseline
uniforme para no reinterpretar una edición tras restaurar. No usa toDraft al
guardar estado: validar convertiría o perdería entradas a medio escribir.
Un primer test detectó generación de UUID por serializer orientado a persistencia;
se separó codec de estado UI para conservar IDs nulos y lista vacía literalmente.
Cuatro tests JVM ejecutados, móvil298 sin fallos/errores/omitidos; assemble y
AndroidTest compile correctos. Fixture StateRestorationTester compilado NO ejecutado.
Todas las llamadas reales pasan accountId. Esto es SavedInstance, NO archivo
borrador durable, ni prueba de process death/rotación. Texto transitorio no
confirmado de subcampos por serie/diálogo WOD sigue sin persistirse; no se cierra
la recuperación completa del borrador ni riesgo de tamaño Bundle para planes grandes.
Descartar/navegar atrás no escribe una rutina y guardar sigue siendo único commit.

### 26 octubre 07:42 - aislamiento de restauración, no solo invalidación

rememberSaveable(inputs) invalida durante recomposición, pero los inputs no
son prueba de pertenencia del valor restaurado de Bundle. Cada valor guardado
ahora incluye cuenta+rutina explícitos, y cada saver rechaza un envelope de otro
dueño/ID antes de aplicarlo. También título/favorito/sugerencia, no solo bloques.
Un JVM nuevo cubre misma cuenta/ID, cambio de cuenta, cambio de rutina y null;
mobile299/0 fallos/errores/omitidos. Segundo fixture UI de cambio de cuenta con
restauración compilado NO ejecutado. No implica archivo durable ni recuperación
global de todos los campos, y no amplía permisos o cuota al restaurar.

### 26 octubre 07:49 - texto por serie sin borrado silencioso

Editor KG/RIR convertía texto inválido no vacío a null, borrando objetivo previo;
reps inválidas podían dejar valor anterior y guardar sin avisar. Parser ahora
distingue blanco opcional de inválido, rechaza no finitos/negativos y reps fuera
1..10000; RIR finito >=0 como validador de persistencia, sin inventar máximo5.
Texto por serie vive en EntryUi junto a última prescripción asociada; inválido
bloquea Guardar y sobrevive SavedInstance literalmente. Eliminar desplaza índices;
reemplazo de guía/copia limpia campos viejos; serializer descarta texto de una
prescripción sustituida. Cinco JVM nuevos, móvil304 sin fallos/errores/omitidos,
assemble/AndroidTest compile correctos. Sin UI/píxeles/rotación ejecutados.
Este anexo sustituye la ausencia de recuperación por serie de07:38 para estos
campos; diálogos WOD/subcampos restantes y durabilidad fuera de Bundle no cerrados.

### 26 octubre 07:53 - detalles WOD raw y validación

Peso H/M tenía el mismo borrado silencioso: texto no vacío inválido quitaba
campo anterior, y no finitos podían llegar a JSONObject. Ahora EntryUi conserva
texto de peso/escala/notas y apertura de detalles, valida peso finito >=0, y
bloquea Guardar hasta corregir; blanco opcional limpia explícitamente. JSON
original conserva campos desconocidos e identidad al editar sucesivamente.
Codec SavedInstance conserva texto inválido y flags sin materializar ni guardar
rutina. Tres JVM nuevos ejecutados (target anterior, no finitos/blanco,
identidad/texto tras restauración); móvil307/0 fallos/errores/omitidos, assemble
y AndroidTest compile correctos. Sin nueva prueba UI/píxeles ni durabilidad de
archivo. Sustituye ausencia de detalles WOD SavedInstance en anexos anteriores;
no cierra todo el editor ni restaura automáticamente diálogos de selección.

### 26 octubre 07:57 - REST inválido no se sustituye por60/clamp oculto

El campo libre REST filtraba dígitos y escribía60 al vaciar, o clamp15..300
aunque la pantalla mostrase otro número. Ahora conserva texto literal, mantiene
último valor válido y bloquea Guardar fuera15..300 (rango Apple PlanView).
Entrada inválida y bloqueo sobreviven SavedInstance; un JVM adicional cubre
vacío/límites/caracteres/restauración/corrección. Mobile308/0 fallos/errores/
omitidos, assemble/AndroidTest compile correctos. Sin UI/píxeles reales;
interacción step15 de Apple aún no replicada por este campo nativo libre.

### 26 octubre 08:03 - regresión agrupada y lint foreground

Regresión local incluye domain327/mobile308, assemble y compilación AndroidTest
móvil/Wear. Lint Wear encontró un error NotificationPermission nuevo: notify()
para actualizar notificación foreground sin POST_NOTIFICATIONS. No baseline ni
supresión: actualización usa startForeground con mismo ID/tipo y captura fallo.
POST_NOTIFICATIONS no es requisito para lanzar FGS, según documentación oficial;
no se introduce permiso opcional como gate de continuidad. Lint Wear posterior
0 errores/24 warnings/6 hints, assemble/AndroidTest compile correctos.
Lint móvil llegó a lintAnalyzeDebug pero invocación agotó120s, sin informe final;
no se declara verde ni fallo de código. adb devices vacío08:00, sin píxeles.
Fuentes:
https://developer.android.com/develop/ui/compose/notifications/notification-permission
https://developer.android.com/reference/android/app/Service
https://developer.android.com/develop/background-work/services/fgs/launch
No confirmación real de notification drawer/Task Manager ni reloj con permiso denegado.

### 26 octubre 08:09 - conversión no descarta entradas inválidas

Mover fuerza↔WOD reconstruía EntryUi desde defaults y podía saltar bloqueo de
texto inválido (cantidad se volvía8/10, detalles inválidos desaparecían).
Conversión ahora exige borrador válido antes de mutar. Mover entre bloques del
mismo tipo conserva instancia/texto inválido y su bloqueo sin reinterpretar.
Dos JVM nuevos verifican rechazo sin mutación y movimiento del mismo tipo;
mobile310/0 fallos/errores/omitidos, assemble/AndroidTest compile correctos.
No nueva ejecución UI/píxeles. Lint móvil aislado08:05 también agotó120s en
lintAnalyzeDebug, sin informe final ni fallo de código probado; no se reitera
sin cambiar estrategia de ejecución. Wearlint previo permanece0/24warnings/6hints.

### 26 octubre 08:15 - duración/JSON futuro por serie

PlannedSetDraft omitía targetDurationSeconds y campos futuros: editar/guardar
una rutina con hold75s lo convertía a30s fijo. Ahora modelo, lectura, JSON de
persistencia, conversión, SavedInstance, edición numérica, copia y escalado
conservan duración y campos desconocidos por serie. Hold sin duración conserva
fallback30s; una duración explícita válida no se sustituye. Serie nueva copia
duración como Apple addStrengthSet, sin duplicar ID. Tres JVM nuevos cubren
JSON futuro/duración, restauración e histórico de cargas. Regresión detectó
cambio de igualdad por guardar JSON completo; se conserva solo residual futuro
para mantener igualdad de modelos conocidos sin debilitar test existente.
Móvil313/0 fallos/errores/omitidos, assemble/AndroidTest compile correctos.
No UI de edición de duración nueva ni prueba Health/dispositivo/píxeles.

### 26 octubre 08:20 - objetivo duración en editor Movilidad

Se relee PlannedSetConfigRow Apple: Movilidad edita segundos (hold default30,
dinámico60), válido >0 hasta3600. Editor Android por serie ahora ofrece campo
segundos para catálogo Movilidad, conserva valor previo y bloquea Guardar si
texto inválido; raw/bloqueo sobreviven SavedInstance. Duración explícita no
borra KG/reps/RIR/JSON futuro ni texto a medio escribir de otro campo. Borrar
serie desplaza claves duración; aplicar guía/copia descarta textos reemplazados.
JVM nuevo de edición/restauración, móvil314/0 fallos/errores/omitidos, assemble
y AndroidTest compile correctos. No píxeles, captura ni interacción ejecutada:
control nativo extra no certifica orden/keypad/visibilidad de Apple.

### 26 octubre 08:24 - fixture pipeline duración y fallback dinámico

Se añade fixture aislado repositorio→StateOverview→edición→repositorio para
hold75→90 con ID/futuro intactos y Movilidad dinámica sin duración→60 como
Apple. Compilado NO ejecutado. Se completa fallback60 dinámico de persistencia,
no solo presentación; hold mantiene30 cuando falta. Mobile314 ejecutados sin
fallos/errores/omitidos y assemble/AndroidTest compile correctos. No datos reales
ni Salud modificados. Relectura CompletedWorkoutEditing Apple confirma que su
visibleSets tampoco copia duración registrada: no se añade divergencia nueva a
esa ruta basándose en una hipótesis de pérdida; issue funcional separado si se
quisiera cambiar Apple. Inventario completo y fidelidad de editor siguen abiertos.

### 26 octubre 08:30 - octava ruta de creación: editar sesión suelta

Auditoría encuentra otra creación de plantilla: guardar edición de sesión sin
rutina existente. Ahora cuenta cuota desde snapshot antes de materializar customs;
plantilla existente no consume slot nuevo. Al crear enlaza routineId para que
reintentos/ediciones no creen repetidos. UI captura ID de sesión al abrir editor
y repositorio rechaza otro ID antes de efectos; cambio de activa cierra ruta.
Fixture aislado quota-denied/snapshot intacto/stale-ID/reintento compilado NO
ejecutado. Mobile314/0 fallos/errores/omitidos, assemble/AndroidTest compile
correctos. Corrige inventario previo de siete rutas, no prueba exhaustividad.
Sin transacción global identidad/cuota ni E2E UI/servidor. No nueva beta/push.

### 26 octubre 08:35 - identidad del editor suelto y destino de escritura

El draft de sesión sin rutina generaba UUID nuevo por lectura; ahora deriva
ID estable de ID de sesión para restauración/reapertura. Actualizar plan exige
que plantilla existente sea routineId de esa sesión, no cualquier ID válido
supuesto por caller. Guard antes de quota/custom/materialización. Dos fixtures
ampliados compilan (ID estable y rechazo de plantilla ajena sin mutación), NO
ejecutados. Callback custom quota usa policy.copy del contador cargado en vez
de mutar estado Compose desde IO. Mobile314/0, assemble/AndroidTest compile
correctos. No prueba proceso/identidad global ni nueva escritura en cuentas reales.

### 26 octubre 10:35 - perfil público: puerto sin cablear

Apple fc3ef7e1 BusinessAuthStore.syncPublicProfile sube nombre (máx. 100) y avatar JPEG (máx. 2 MiB) a Supabase:
Storage `profile-avatars/{uid}/avatar.jpg` (upsert) y `profiles.display_name/avatar_url`; sin avatar borra el objeto
(best-effort) y escribe avatar_url NULL. Android conserva el perfil solo local (ProfileSettings: seleccionar foto no
la sube en público). Añadido `PublicProfileSync` con el mismo contrato, NO conectado a ninguna pantalla ni worker:
publicar es un efecto externo que necesita punto de consentimiento antes de cablearlo. 7 JVM con HTTP simulado
(orden subir-luego-PATCH, id en minúsculas, NULL explícito, oversize sin peticiones, fallo de subida sin PATCH,
revocación antes del PATCH). Nunca ejecutado contra Supabase real; no se comprobó el bucket ni las políticas RLS.
El guardia de dueño local de Apple (isSameLocalOwner) lo aporta el llamador con stillAuthorized.

### 26 octubre 10:42 - borrador de Apuntar ejercicio ante recreación (rotación)

Apple (QuickLogSheet.swift) guarda filas, nota, interruptor y unidad en @State: sobreviven a rotar, pero NO se
persisten tras cerrar la hoja ni tras matar el proceso. Android usaba remember{}: al rotar se perdía el borrador
y la hoja se cerraba (bandera `quick`/`quickLog` sin guardar). Cambio local: `QuickLogDraft` (puro, codec a lista
de strings, rechaza datos mal formados), `QuickLogDraftState` con Saver en rememberSaveable, texto de cada campo
guardable, banderas de apertura guardadas (en ExercisesTab por id de ejercicio, no por objeto). El requestId se
conserva, de modo que reintentar tras rotar sigue siendo idempotente. NO se persiste a disco ni se promete
supervivencia a muerte de proceso más allá de lo que Android guarde del estado de instancia (tampoco lo hace Apple).
Validado: 4 JVM del codec (mobile 351/0/0) y compileDebugAndroidTestKotlin OK. Preparado, NO ejecutado:
QuickLogRotationInstrumentedTest (StateRestorationTester). Sin píxeles ni dispositivo. Queda abierto el borrador
del editor de rutinas completo y de la sesión activa manual (distintos caminos, no auditados aquí).

### 26 octubre 10:48 - aislamiento del borrador de Apuntar ejercicio

Corrección tras revisión: el borrador guardado incluye `owner = cuenta|ejercicio` (codec versión 2) y `decode` descarta
cualquier borrador cuyo dueño no coincida; rememberSaveable usa el dueño como clave y QuickLogSheet recibe accountId.
Banderas de apertura: ExercisesTab por cuenta + id (resuelve la entrada actual desde overview; si ya no existe, no abre),
ReperaMobileScreen por entry.id + cuenta. JVM: 352/0/0 (5 casos del codec, incluido dueño distinto). compileDebugAndroidTestKotlin OK.
NO ejecutado: isolación real con StateRestorationTester ni cambio de cuenta en dispositivo. El requestId estable no prueba aislamiento;
la prueba es el dueño. No se verificó revisión de identidad (uniqueId vs userId) al restaurar: el accountId usado es el que recibe cada pantalla.
Candidatos NO aplicados por falta de ámbito de cuenta probado: título/nota del fin de sesión (LiveActivityScreen), metas de salud (HealthGoalsSection),
nombre de perfil, y FinishedWorkoutEditor (restaurar solo campos primitivos dejaría un borrador a medias respecto a los bloques JSON).

### 26 octubre 10:52 - grounding de accountId en quick log y auditoría de borradores (lectura de código, sin ejecución)

accountId que reciben ExercisesTab/ReperaMobileScreen/QuickLogSheet: MainActivity.kt:928 `profile?.uniqueId.orEmpty()` (dominio Google uniqueId,
el mismo del WorkoutRepository). No es el userId de Supabase. Con sesión sin perfil el id es "" (dueño "|ejercicio"); no se verificó si esa
pantalla es alcanzable sin perfil. ABA (A->B->A): las banderas usan rememberSaveable(accountId) y el dueño del borrador va dentro del dato, así
que al cambiar de cuenta en composición viva la clave cambia y el estado se descarta; no hay revisión de identidad (identityRevision) en la clave,
de modo que un re-login de la MISMA cuenta con el estado de instancia intacto restauraría su borrador. No ejecutado; no se declara aislamiento cerrado.
Editor de rutinas: ya tiene envelope cuenta+rutina (scopeKey) para título, favorito, sugerido y bloques completos; huecos restantes leídos:
`error`, `query` de pickers y expansión de detalles/series no se guardan (cosméticos); restoreScopedEditorValue usa JSONObject sin runCatching
(un dato corrupto lanzaría; no probado). Sesión activa manual: ActiveSessionControls guarda la nota con rememberSaveable(active.id, active.notes),
sin cuenta en la clave (active.id es UUID de sesión); `choosing`/`editingNotes` no se guardan. Hallazgos agrupados, sin cambios de código.

### 26 octubre 10:56 - restauración fail-closed y nota activa con cuenta+sesión

1. Acceso de quick log sin perfil: MainActivity muestra OnboardingFlow cuando `profile == null || !onboarding.isComplete` (l.574),
   así que ReperaMobileScreen (y con ella el quick log) solo se compone con perfil; accountId = uniqueId (no verificado que uniqueId nunca sea vacío).
2. `restoreScopedEditorValue` ya no lanza ante JSON corrupto, scope no-string o valor ausente: devuelve null (estado fresco). Los bloques
   restaurados pasan por `restoreRoutineEditorBlocksOrNull`: un dato corrupto solo descarta ese campo; título/favorito válidos se restauran aparte.
   Caso JVM nuevo (corrupto, ajeno, nulo, válido). No ejecutado en dispositivo.
3. Nota de la sesión activa: `rememberSaveable` con envelope (cuenta, active.id) reutilizando saveScopedEditorValue; ActiveSessionControls recibe accountId
   (default "" para fixtures existentes) desde ActiveWorkoutScreen y HomeTab. La clave de entrada conserva active.notes (si cambia la nota remota, se reinicia el borrador, como antes).
   ABA/misma cuenta: restaurar el borrador al mismo usuario no se trata como filtración; el guardado sigue pasando por la validación de sesión del repositorio
   (no re-auditado aquí). `choosing`/`editingNotes` siguen sin guardarse: al rotar con el diálogo de notas abierto se cierra y se pierde el cuadro, aunque el texto escrito se conserva.

### 26 octubre 11:30 - topes de bloques (10/12) y título (100): gap de paridad, sin cambio de límite

Apple fc3ef7e1: ReperaStore.saveRoutine (l.1879) no aplica tope de bloques ni de título; solo acceso a plantillas y reglas de fecha/día.
Único tope de bloques en Apple: AITrainingInboxStore.swift:321 (planes IA 1...12). No hay tope de título de rutina en Apple por búsqueda de patrones
(prefix(100), ...100, count>100); es ausencia por grep, no prueba exhaustiva.
Android (lectura de código): 10 bloques en createRoutineFromScan (WorkoutRepository.kt:366), en validatedDraftBlocks (l.533; usada por replaceRoutineBlocks y
createRoutineFromDrafts) y 12 en la ruta IA (l.437). Título <=100 en l.382, 522 y RoutineBlocksEditor l.100 (UI), ReperaCards l.822 (take(100)).
Historial: el 10 nace en c75d9874 (24 oct, editor multi-bloque) y 8dc98c62 (24 oct, importador del escáner); el 12 en d9f8a672 (26 oct, copiado de Apple IA). Ningún mensaje cita Apple.
Contrato UI: el editor permite "Añadir bloque", duplicar rutina y añadir WODs sin tope; BoardScanScreen lista todos los bloques; el error "entre 1 y 10 bloques" aparece solo al guardar.
Incoherencia concreta (por lectura, no ejecutada): una rutina IA con 11 o 12 bloques se acepta, pero editarla/reemplazar sus bloques falla en validatedDraftBlocks (1..10), y duplicarla en el editor
produce un borrador que no se puede guardar. Unificar o no el límite es decisión de contrato (Apple no tiene tope); no se cambió nada. Si se decide, tocar escáner, edición y creación a la vez.

#### Resolución 11:30 (sustituye "no se cambió nada" de arriba)
Se elimina el tope superior de 10 bloques en createRoutineFromScan y validatedDraftBlocks (editar/reemplazar y crear desde borradores);
se mantiene el mínimo de 1 bloque y toda la validación estructural (formatos, entradas, tiempos, rondas, escalera). La ruta IA conserva su tope
explícito 1...12 (Apple AITrainingInboxStore:321). No se inventa un máximo nuevo: no se encontró límite técnico en el código leído (no se midió coste de
volumen ni tamaño de payloads de Wear/sync; no auditado). Título <=100 NO se toca (ausencia en Apple solo por grep).
Pruebas: JVM estático RoutineBlockCapContractTest (2) -> mobile 355/0/0, solo prueba lectura de fuentes. Instrumentado preparado y compilado, NO ejecutado:
RoutineBlockCountContractInstrumentedTest (crear 12, reemplazar a 11, vacío falla, escáner 11, IA 13 falla/12 pasa).

### 26 octubre 12:16 - importador del escáner: tests portados de Apple (LiteParser, ruta de produccion)

Apple BoardImportPipeline usa solo BoardScanLiteParser. Android ya portaba los 13 de BoardScanLiteParserTests; se añaden
BoardScanDeviceLogOcrTest (6, JVM, ejecutados): OCR literal de dispositivo (Apple BoardScanHangRepro/FullCatalog: 3 bloques EMOM/EMOM/AMRAP, 138 ms)
y los 5 de BoardScanPhotoRegressionTests (metcon forTime 3 etapas, squat snatch 8 series con %1RM y mínimo ">80%", pull-up/ring row 5 rondas,
intervalos 4 on/1 off, descanso entre rondas). Todos pasan sin cambiar el parser. Limites: texto OCR literal, no cámara ni ML Kit reales;
catálogo catalog_seed.json de Android (no Catalog.seed() de Apple); Apple ejecuta Hang/FullCatalog contra BoardImportParser (fuera de la ruta de producción)
y aquí corren contra el LiteParser, así que no prueban equivalencia con BoardImportParser. No se portaron aserciones por nombre exacto de movimiento (catálogo en español).
domain 333/0/0 (el conteo incluye todos los tests de domain).

### 26 octubre 12:35 - Wear: stopSelf() sin startId en WearHealthService (hipótesis estática, sin fallo reproducido)

Lectura: `publish()` (al terminar sensores) y la rama `releasable` de onStartCommand llamaban a `stopSelf()` sin id. stopSelf() detiene el servicio aunque haya
una solicitud de arranque posterior pendiente; si esa solicitud era un startForegroundService de la UI visible, el servicio podría destruirse antes de
llamar a startForeground (riesgo de ForegroundServiceDidNotStartInTime). La ventana es estrecha (ambos en el hilo principal, arranque solo desde UI visible,
sesión ya terminada protegida por sensorEndedSessionId). NO reproducido; no hay reloj ni dispositivo.
Cambio mínimo: se guarda lastStartId y se usa stopSelfResult(lastStartId), que no detiene si hay un arranque más nuevo pendiente (con id -1, servicio solo enlazado, equivale a lo anterior).
Validado: :wear:compileDebugKotlin y :wear:compileDebugAndroidTestKotlin OK (solo compila; :wear:testDebugUnitTest es NO-SOURCE, el módulo wear no tiene tests JVM). Ejecución en reloj: NO. Sin test que fije el comportamiento (depende del framework de Service).

### 26 octubre 12:40 - auditoría de alcance de cuenta en estado restaurable (lectura + cambio acotado)

Inventario de rememberSaveable sin accountId en mobile/src/main. Con dato personal o referencia a entidades de una cuenta, se añade clave accountId
(se descarta al cambiar de cuenta en composición viva): ExercisesTab selectedLiveSessionID/selectedSportID/evolutionRouteID y
BodyWeightHistoryScreen.kgText (nuevo parámetro accountId con default "", pasado desde ReperaMobileScreen).
Sin cambio, abiertos: ProgressTab.weightInput (l.304; añadir parámetro a ProgressTab rompe llamadas posicionales de androidTest, requiere refactor),
CenterDirectoryDialogs.note, y estados de UI sin dato personal (filtros, orden, rangos, expanded, búsquedas). BoardScanScreen.reviewRequestId es UUID estable para idempotencia, sin dato de cuenta.
Esto es clave de entrada de rememberSaveable, no un envelope con dueño como en quick log/editor: no se ejecutó ni se probó con StateRestorationTester. JVM mobile sin regresiones, compileDebugAndroidTestKotlin OK.

#### Seguimiento alcance de cuenta (ProgressTab y directorio de centros)
ProgressTab.weightInput usa ahora envelope con dueño (cuenta + "progress-weight-input") vía saveScopedEditorValue/restoreScopedEditorValue (fail-closed);
ProgressTab recibe `accountId` como último parámetro con default "" (no rompe llamadas posicionales de androidTest) y ReperaMobileScreen lo pasa. Compila; sin restauración ejecutada.
CenterDirectoryDialog.note: calificado por lectura. Es texto que el usuario enviaría a un centro en la solicitud de vínculo (dato personal saliente).
`selected` (centro elegido) NO se guarda, y elegir un centro ejecuta `note=""`, así que tras recrear la nota restaurada queda invisible y se borra al reelegir: el guardado actual no preserva el borrador
(pérdida) pero tampoco puede mostrarse a otra cuenta. Arreglarlo exigiría guardar el id del centro y reconstruir la fila desde `rows`; no hecho, pendiente.

#### Directorio de centros: borrador de solicitud ante recreación
CenterTab.showDirectory pasa a rememberSaveable (antes el diálogo se cerraba al rotar aunque query/note/passKind se guardaban y reaparecían obsoletos al reabrir).
CenterDirectoryDialog guarda el id del centro elegido; el objeto sigue en memoria para que un cambio de resultados de búsqueda no cierre la confirmación; tras recrear se reconstruye desde `rows`
cuando llegan. La nota se conserva mientras no se reelija centro. Sin envelope de cuenta (CenterTab no recibe accountId): un cambio de cuenta en composición viva no está cubierto aquí.
Compila y JVM sin regresión; restauración no ejecutada. Filas 41 (filtro por día en Inicio, HomeTab l.315), 48 (Al fallo, ReperaCards l.351), 62 (SuggestedExerciseLoadCard) y 63 (tope 1RM, onSetTestedOneRM)
de la matriz histórica tienen consumidor en el árbol; eso no afirma equivalencia con Apple.

#### Directorio de centros: envelope de cuenta (cierra el límite anterior)
CenterTab y CenterDirectoryDialog reciben accountId (default "", pasado desde los dos CenterTab de ReperaMobileScreen). query, centro elegido, passKind y nota se guardan con envelope
[cuenta, "center-directory", campo] vía saveScopedEditorValue/restoreScopedEditorValue (fail-closed: dueño distinto o dato corrupto -> estado fresco) y showDirectory se clava a accountId.
Así una restauración con otra cuenta no muestra ni puede enviar la nota. La garantía de dueño del helper la prueban los JVM de RoutineEditorRestoration (ajeno/corrupto); la restauración del diálogo en sí NO se ejecutó.
JVM mobile 355/0/0, compileDebugAndroidTestKotlin OK.

## Reconciliación de filas "R" históricas (grep, 26oct 12:55)
Consumidor localizado en el árbol (NO equivalencia validada, sin ejecución UI): fila 45/46 (`WeeklyScheduleActions`, `MainActivity:701/703`), 49 (`onSelectExercise` en `ActiveWorkoutScreen`; no se verificó anterior/selectblock frente a Apple), 50 (`onSaveActiveFavorite`, `MainActivity:902`), 76 (`BusinessCenterStore.searchDirectory/requestLink`, `MainActivity:763/1167`). Las filas 66, 68, 79 siguen sin reconciliar.

## Filas 66 y 68 (grep, 26oct 13:32)
- 66: `ProgressRecordsCard` tiene "Ver todos los récords" (diálogo con la lista completa) y apertura de ejercicio. Consumidor existe; sin UI ejecutada ni equivalencia validada. Gate Free/Pro de MuscleBalance: sin cambio, sin prueba UI.
- 68: gráfico de valoración de sesión existe (`SessionScoreProgressCard`, `ProgressTab:223`). Zonas cardíacas: NO existe nada en Android. En Apple (`ProgressHeartZonesCard`, `HealthKitStore.heartZones`) las zonas vienen registradas por Apple Salud (personales, configuradas o de la app) con fracción de tiempo cubierto; no se calculan con umbrales propios. Health Connect no expone zonas equivalentes. Implementarlo exigiría inventar umbrales de zona en Android: no se hace; queda como decisión de Ramón (y requiere datos HC reales).

## Fila 49 (lectura de código, 26oct 13:33)
Móvil: `ActiveSessionControls` (Anterior/Siguiente/selector, `MainActivity:899`) llama `WorkoutRepository.selectActiveExercise`, que valida el índice y fija `currentIndex` y `phase="ready"`, igual que `SessionController.selectExercise(at:)` de Apple (fc3ef7e1). Comparado por lectura, sin ejecutar ni test JVM específico. Wear `selectBlock(startingAt:)` (`WatchSessionHub:785`): no verificado, ligado a hardware.

## Zonas cardíacas: qué necesita Apple y qué hay en Android (26oct 13:34, lectura de código y docs oficiales)
- Apple (`HealthKitStore.heartZones`, fc3ef7e1:1245): lee `HKWorkout.zoneGroup(for: heartRate)` de un entreno guardado (el enlazado, o uno solapado ≥40% sin ambigüedad). Duración por zona, min/max bpm y origen (system/user/app) vienen calculados por HealthKit con la configuración de zonas del usuario en Ajustes de Salud (generada por el sistema o personalizada). Exige ≥60 s cubiertos; intensidad 0-10 solo con ≥60% cubierto y ≥3 zonas. Apple documenta no estimar por edad ni FC máxima genérica. Fuente: developer.apple.com/documentation/healthkit/hkworkout/zonegroupsbytype y apple-docs.everest.mt/docs/healthkit/accessing-workout-zone-data/.
- Health Connect (connect-client 1.1.0 en el árbol): `ExerciseSessionRecord` contiene ruta, laps y segmentos; la página de workouts no menciona zonas. Hay `HeartRateRecord` (muestras) y ninguna configuración de zonas del usuario. Fuente: developer.android.com/health-and-fitness/health-connect/experiences/workouts.
- Árbol Android: sin código de zonas. Faltan (a) la configuración de zonas, que HC no aporta, y (b) los segundos por zona, que habría que calcular desde `HeartRateRecord`. Con (a) ausente cualquier umbral sería inventado. No implementado. No se ha verificado Wear Health Services ni Health Connect en dispositivo real (podrían existir datos de zonas de apps de terceros; no comprobado).

## LiveActivity/FinishedWorkoutEditor: ciclo de vida y cuenta (26oct 13:35)
Título/notas de `LiveActivityScreen` eran `remember` sin clave: con la composición viva y cambio de accountId, el texto escrito habría podido guardarse (`saveLiveActivity`) bajo la otra cuenta. Ahora `remember(accountId)`. `FinishedWorkoutEditor`: las claves pasan de `workout.id` a `(accountId, workout.id)`. No se añade persistencia (rotación/proceso) porque no se ha comprobado que Apple la requiera. Verificado solo: compila y JVM; sin prueba de cambio de cuenta en composición viva.

## Wear selectBlock: lado móvil (26oct 13:37)
`WearSelectCommand` (sessionId, fromIndex, toIndex) y manejador `/repera/select-exercise` en `MainActivity`: solo actúa si la sesión activa y el índice mostrado coinciden, el destino está en rango y no es el mismo, y no hay `busy`; cancela el descanso y llama `selectActiveExercise` (igual que el selector del móvil). `WearSelectCommandTest`: 3 JVM ejecutados (parse/targets). NO existe aún el emisor ni la lista de bloques en Wear (WatchSessionSummary solo trae el ejercicio actual; haría falta publicar la lista de bloques en `/repera/active-session`). Sin ejecución contra un reloj. Apple además ignora el salto con `awaitingHealthSave`, reinicia timers/borrador y hace checkpoint en el reloj: pendiente en la parte Wear.

## Wear selectBlock: emisor y lista de bloques (26oct 13:39)
`WearBlockStarts` (domain, port de `blockStarts(in:)`, 4 JVM ejecutados). `WatchSessionSummary.blocks` (índice, nombre del primer ejercicio) se calcula del JSON `/repera/active-session` ya recibido. `WearHomeContent` muestra "Ir a" con un botón por bloque (si hay más de uno) y `requestSelectBlock` envía `/repera/select-exercise` a los nodos conectados. SOLO COMPILA (`:wear:compileDebugKotlin`); wear no tiene tests JVM. Sin pixeles ni reloj. Pendiente frente a Apple: título de bloque `displayBlockHeader` (se usa el nombre del primer ejercicio), guarda `awaitingHealthSave`, reinicio de timers y borrador al saltar, y que se salte desde "Plan de hoy" (`startToday`+`selectBlock`).

## Wear selectBlock: diferencias restantes cerradas en lógica local (13:42)
- Cabecera: `WearBlockHeader` (domain), port de `displayBlockHeader` y `plannedIntervals` (EMOM) de fc3ef7e1; 4 JVM. Desviación: cabecera vacía se trata como ausente. Los botones de Wear usan ahora esa cabecera en vez del nombre del primer ejercicio. Las claves JSON (blockTimeCapMinutes, blockRounds, blockIntervalSeconds, blockWorkSeconds, blockRestSeconds, blockHeader, blockKind, wodFormat) coinciden con las que escribe `WorkoutRepository`/`WodSessionAssembler`.
- Guarda: Wear ignora el salto con un fin pendiente (`pendingFinish`), análogo de `awaitingHealthSave`; la equivalencia de ese estado no está verificada.
- Reset al saltar: en sesión iniciada en el reloj se cambia el snapshot local con `WatchPlanExecution.select` (2 JVM: índice+ready sin tocar ejercicios, no-op fuera de rango/ya actual), se cancela descanso y temporizador WOD, se reinicia el borrador (`seedDraft`) y el contador de reps. En sesión del móvil lo hace el móvil vía `/repera/select-exercise`. Apple además hace `health.pause()` e `isPaused=false`: aquí solo se pone `sessionPaused=false`, sin pausar sensores (sin verificar).
- Plan de hoy: lista "Empezar en" con una cabecera por bloque; `startTodayPlan(startIndex)` aplica `select` tras `begin` (Apple `startToday`+`selectBlock`).
Validación: domain 343/0/0; `:wear:compileDebugKotlin` OK (solo compila). Sin reloj ni píxeles.

## selectBlock: transición health/pausa y awaitingHealthSave (13:47)
- Apple `selectBlock` hace `health.pause()` (si empezó en el reloj), `isPaused=false`, fase `ready`; `play()` (ready) confirma el ejercicio y hace `health.resume()`. Wear no tiene fase ready: el equivalente es el estado pausado (sensores y descanso en pausa; "Reanudar" = Play; queueSet rechaza series en pausa). `selectLocally` ahora termina en `togglePause()` (pausa sensores vía `healthConnection.pause`, descanso y mensaje /repera/session-pause).
- Plan de hoy en bloque >0: queda pausado (no se pueden confirmar series hasta "Reanudar"). DIVERGENCIA CONCRETA que sigue: los sensores NO arrancan pausados (WearHealthService arranca asíncrono y no tiene modo de inicio en pausa), así que graban desde el toque; Apple los pausa. Cerrarlo exige cambio de servicio, no hecho.
- `awaitingHealthSave` (Apple): activo desde el fin hasta que HealthKit guarda, y en la recuperación de un workout `watchHealthKitPending`. Android: `pendingFinish` cubre desde la petición de fin hasta el ack; no hay análogo verificado de la recuperación de workout pendiente. El guard equivale solo en la ventana de fin. No es equivalencia probada.
- Compila (`:wear:compileDebugKotlin`); sin tests JVM de esta transición (vive en la Activity).

## Topes de título 100 retirados, por campo (13:47)
Evidencia: Apple fc3ef7e1 no limita título de rutina/entreno (sin prefix/count en Store/Views/Domain). Backend: `athlete_workout_mirror.title` check 1..200 y Apple sube `prefix(200)` (BusinessWorkoutSyncStore:271); Android ya sube `take(200)` (WorkoutMirrorStore:181), así que no choca. Los 120 de catálogo/prescripción de negocio son de profesionales, otro flujo. El 100 del perfil Apple está solo al sincronizar el perfil público (BusinessAuthStore:628); `PublicProfileSync.MAX_NAME=100` ya trunca.
Retirado (mantiene "no vacío"): título en createRoutine, appendScannedRoutine, createRoutineFromDrafts, startSessionFromDrafts (sin tope), updateRoutineDetails, título sugerido en edición, diálogo de edición de ReperaCards y su botón de crear, RoutineBlocksEditor, y nombre de perfil local (se trunca a 100 solo al publicar). No tocado: títulos de bloque, nombres de ejercicio custom, tope de avatar 300k. Test `ProfileSettingsTest` sustituido (nombre largo se guarda; avatar excesivo no sobrescribe parcialmente). Mobile JVM 359/0/0.

## Plan de hoy en bloque >0: inicio pausado de sensores (13:48)
Cierra la divergencia anterior: `WearStartPauseIntent` (domain) decide con cada actualización de sensores: PAUSE una sola vez cuando el servicio confirma `recording` y aún no está pausado, WAIT si no graba todavía o la actualización es de otro dueño, DROP si cambió la sesión, si el usuario ya pulsó Reanudar, o si el sensor confirmó la pausa. 5 JVM ejecutados (incluye carreras: reanudar antes de grabar, otra sesión, otro dueño, sin spam). La Activity solo ejecuta la decisión (`pauseSensorsIntent`) y la borra al reanudar. Carrera no cubierta: si el proceso del reloj se reinicia, la intención se pierde (el estado pausado de UI se restaura por `restState`, los sensores podrían quedar grabando); sin ejecutar. Brecha separada y abierta: recuperación pendingFinish/HealthKit pendiente.

## Zonas cardíacas: fuentes posibles en Android (13:49, docs oficiales)
- Wear Health Services (`androidx.health.services.client.data`): el resumen del paquete no lista ningún tipo de zonas (revisado por texto). Sin fuente de zonas guardadas.
- Health Connect (connect-client 1.1.0): sin zonas; solo `HeartRateRecord` (muestras).
- Existe `TimeInHeartRateZone` en la API cloud Google Health v4 (docs.rs/google-devicesandservices-health-v4 y googleapis.dev/java/google-api-services-health). Es una API web con OAuth, distinta de Health Connect: usarla sería una integración externa nueva con consentimiento propio; no se ha activado ni probado ni disponible en el árbol.
- Opción local sin inventar umbrales: que el usuario configure sus zonas en Repera (min/max bpm por zona) y calcular segundos por zona con `HeartRateRecord` del entreno. Es un diseño de producto (ajuste nuevo), no una paridad de comportamiento Apple (que lee zonas de Salud), y no se ha implementado.

## Inicio pausado de sensores: recuperación y ventana exacta (13:49)
- Estado durable: la pausa de UI ya se persiste (`persistRest` -> `restState`, commit). `restoreRest` recrea ahora `WearStartPauseIntent` si la pausa restaurada es true, de modo que tras reiniciar el proceso/servicio, sensores que graben sin pausa se pausan una vez cuando el servicio confirma `recording`. 1 JVM nuevo (intención nueva tras reinicio emite un único PAUSE); 6 en total, todos decisiones puras.
- Capacidad del servicio: `WearHealthSession` marca `recording` cuando el estado de Health Services no es PREPARING ni terminal, y `pause` exige `recording && !paused`; `ExerciseConfig` no ofrece arranque pausado en el código revisado. Por tanto hay una ventana inevitable con el diseño actual: desde que arranca el ejercicio hasta la primera actualización no-PREPARING más el callback de pausa, los sensores graban aunque la UI esté pausada. No se mide su duración (sin reloj). Los 6 tests NO prueban la transición del SDK; solo la decisión.
- Sigue abierto: no se ha verificado que `pauseExercise` sobre un ejercicio recién ACTIVE se acepte siempre, ni el efecto de esa ventana en kcal/FC registradas. Recuperación pendingFinish/HealthKit pendiente: brecha separada.

## Fila 43 RecoveryHomeCard y filas 33/53 (13:55)
- 43: discrepancia funcional encontrada y corregida: Apple muestra la tarjeta "Tu estado de hoy" con noche anterior O fragmento de ciclo (`hasHomeData`, HealthRecovery.swift:1512); Android solo con `lastNightHours`. `HomeRecoveryModel` (4 JVM) decide la tarjeta y el texto de fase con las mismas etiquetas que Apple; `HomeTab` lo consume. No se replica la guarda `sleepEnabled` de Apple por separado (en Android los datos de sueño solo se leen si está activado: sin verificar en ejecución). Estilo visual (icono luna, navegación) sin comparar. Sin UI ejecutada.
- 33: `BodyWeightHistoryScreen` tiene consumidor (`ReperaMobileScreen:679`); 53: `CompleteHistoryScreen` (local + Health Connect por fecha) tiene consumidor. Existencia de consumidor, no equivalencia.
Validación: mobile JVM 363/0/0, compileDebugAndroidTestKotlin OK.

## Filas 45/46 y 52, comparadas por lectura con fc3ef7e1 (14:05)
- 45 copyPreviousWeekSchedule: misma ventana (lunes a lunes ISO), mismo salto si el día destino ya tiene entreno suelto (incluye los recién creados), nuevos IDs en contenido, favorito=false, `weekday` ausente. `WeeklyScheduleActionsTest` existe. Diferencias no replicadas: Apple llama `saveRoutine` (ordena `routines` y hace `pushActiveToWatch`); Android no reordena la lista guardada. Efecto del orden en pantallas: sin comprobar.
- 46 clearWeeklySchedule: mismo efecto (quita `weekday` de plantillas sin fecha y `rotation`). Apple además empuja a Watch; Android no (sin verificar si el reloj lo necesita).
- `deleteAllRoutines` (Apple): sin llamadores en Apps (solo su definición); no se porta.
- 52 QuickLog: `QuickLogDefaults` ya porta defaultReps/defaultWeight/defaultDuration con test; filas iniciales = 3 como Apple. Diferencia menor: peso inicial null (no 0) sin historial. El guardado directo sin abrir sesión existe; la equivalencia de su resultado frente a `logQuickSets` no se ha comparado en esta pasada.
- 52, guardado: `WorkoutRepository.logQuickSets` coincide por lectura con `ReperaStore.logQuickSets` (título "Apuntar · nombre", sesión terminada, inicio = ahora - max(60, 90*series), notas recortadas o ausentes, `appleDurationSeconds`, valoración adjunta, entrada completada). Diferencias: Android usa un id de petición idempotente (ya existe); Apple suma reps sin calentamientos (el sheet de Android no tiene calentamiento: no comparado); el envío a Health (`finishWorkout`) de Apple no tiene equivalente verificado en este camino. Sin ejecución.

## Row 65 - Progreso categories (read-only comparison, 2026-10-26 14:14 CET)
Static reading only; nothing executed, no pixels.
- Apple StatsView (fc3ef7e1:14-20, 133): ProgressTopic training/health/recovery labelled Entreno/Actividad/Recuperación. Android ProgressTab:98,118 uses the same three labels and order.
- Pro/Free teaser titles and bodies for Entreno and Actividad are the same strings on both platforms (ProgressTab:231, 264).
- Apple shows "Preparando progreso" for non-recovery topics until the snapshot matches the range; Android has no equivalent loading card (not compared further).
- Apple recovery topic renders HealthRecoveryProgressView; Android renders its own recovery block (ProgressTab:217). Content equivalence of each card (tiles, muscleBalance, mobility, proAdvancedSections) is NOT verified. Consumer exists; equivalence not validated.
- No code change in this step.

## Row 79 - accessibility (inventory only, 2026-10-26 14:24 CET)
Grep counts of annotation lines, NOT a measure of equivalence: Apple (Apps/) 181 accessibility* lines; Android (mobile+wear main) 63 contentDescription/semantics/stateDescription lines. Apple's heaviest files: Theme, WorkoutView, PlanView, HomeView, HealthRecovery, LiveActivityView, WatchSessionView. Android's heaviest: PlaceSearchSheet, ExercisesTab, ProgressCharts, LiveSportHistoryScreens. No screen-by-screen comparison done, no TalkBack/VoiceOver run, no font-scale check (Apple has 63 dynamicTypeSize/minimumScaleFactor lines). Row stays open; per-screen reading of the live workout, plan and home screens is the next step.

### Row 79 addendum (14:25 CET)
Read all 5 `contentDescription = null` Icons/Images in mobile+wear main: LiveActivityScreen:155,198; LiveSportHistoryScreens:45; PlaceSearchSheet:208,538; ReperaMobileScreen:338 (nav icon with label); OnboardingScreen Google G, ReperaMascot. All sit next to a Text label or are decorative, so null is the right Compose practice. Icons without a description argument: ExerciseDetailScreen:99, ExercisesTab:330/416, ReperaCards:757, StandaloneTimerScreen:480 (Delete), PaywallScreen, ProTeaserCard: not individually read yet. The low Android count is largely because Compose Text/Button expose their text by default; this is a static reading, not a TalkBack run. Open: read those 6 call sites, custom gesture/drag controls, charts (ProgressCharts has semantics), font scale.
Correction: the call sites ExerciseDetailScreen:99, ExercisesTab:330/416, ReperaCards:757 and StandaloneTimerScreen:480 do carry contentDescription on a following line (multi-line calls; my single-line grep missed them). Only PaywallScreen and ProTeaserCard remain unread. Icon-only controls read so far are labelled.

## Watch push after plan edits (read-only comparison, 2026-10-26 14:26 CET)
Apple: ReperaStore pushActiveToWatch (debounced 280 ms, or immediate) after saveRoutine/deleteRoutine/clearWeeklySchedule/deleteAllRoutines/assignRoutine/replaceActiveExercise/startSession/endActiveSession/catalog change (l.60,573-2373); sendWatchContextNow sends session, today workout, quickLogHint, revision, completed ack.
Android: no per-mutation push. Instead every runWorkoutAction (MainActivity:1731) ends in reloadFor (1622), which publishes /repera/active-session and recomputes /repera/today-plan via todayPlanSession. Covered by that path: routine edit/delete/copy-week/clear-week/replace-blocks/updateTrainingSettings (schedule mode), AI change applied (l.376), AI inbox import (l.1166), catalog refresh with changes (l.1608), center refresh (l.1205). Read, not executed.
Differences kept open:
- No 280 ms debounce; a burst of actions publishes once per action (DataClient putDataItem with identical payload is deduplicated by Wear, not verified here).
- Apple's quickLogHint has no Android counterpart found in the bridge or wear sources (logWearSet exists on the phone). Whether the Android watch needs it is unverified.
- Drive restore and local-only mutations outside runWorkoutAction were not traced to a publish.
Not claimed equivalent: static comparison, no device.

## Row 52 - quick-log save result (read-only comparison, 2026-10-26 14:26 CET)
Apple logQuickSets (ReperaStore:1299) vs Android WorkoutRepository.logQuickSets:1028 + MainActivity:825.
Same: title "Apuntar · <name>"; one finished session with one completed exercise; plannedSets copy reps/weight of logged sets; start = now - max(60, n*90) s; appleDurationSeconds = that span; notes trimmed, blank dropped; review attached and pending; Health write then review refine afterwards (Apple Task / Android refineFinishedSessionWithHealth).
Differences (read, not run):
- Android is idempotent on requestId (returns the existing id); Apple has none (extra on Android, harmless).
- Missing exercise or empty rows: Apple returns nil silently, Android throws and the status line shows the message.
- Apple completedReps excludes warmups; Android quick rows are always phase work, so no warmups exist to exclude.
- Apple sets quantityUnit only for machineWork; Android sets it per row via QuickLogRows.validate (units per input mode); equivalence of that mapping with Apple's style switch (QuickLogSheet:335-360) is NOT verified.
- Apple updates started/finished from the HealthKit result; Android refine path was not compared field by field.
Row stays partial: save skeleton matches, quantityUnit/deficit/duration mapping and Health refine fields not validated.

### Row 52 addendum - quick-log mapping read (14:35 CET)
Compared Apple QuickLogSheet:335-360 + Models.swift (loggingStyle, quantityCap, usesDuration, loadField, defaultQuantityUnit, isSled/isHyroxDistance) with android QuickLogRows.validate + ExerciseInputMode.
Matches (static): caps 50 / 99 / 999 / 100000 per style; duration only for repsAndTime/machineWork and required there; weight only for load+weight; deficit only for the deficit field (0..60 on Android, Apple only checks >0); rows with reps 0 dropped; hold rows without duration dropped; unit toggle only where the exercise allows it.
Concrete divergences found (reading, not run):
1. Sled push/pull, farmer carry/walk, sandbag lunges: Android ExerciseInputMode.mode() maps them to LOAD_DISTANCE (kg + metres, no duration, unit "meters" required). Apple fc3ef7e1: sled with "trineo" equipment is machineWork (quantity in m, duration required); farmer/sandbag go through the normal style switch and QuickLogSheet stores quantityUnit only for machineWork, so Apple stores no metres unit for them even though defaultQuantityUnit is metres. Android keeps kg+metres (commit e5995989 "preserve kg/metres station metrics"). This is an Android-side extension, not an Apple match. Not changed: it preserves more data than Apple; whether to mirror Apple's looser behaviour or keep it is not something evidence settles.
2. Android requires one unit across all rows and rejects mixed rows; Apple has one picker for the whole sheet, so the same outcome by construction.
3. Apple Health refine updates started/finished/kcal/duration/UUID from the HealthKit result; Android refine path field comparison still pending.
Row 52 stays partial until the Health refine fields are compared.

### Row 52 - Health refine: kcal field fixed (14:37 CET)
Finding (reading): Apple logQuickSets/finishWorkout writes appleActiveEnergyKcal (and duration/start/finish/UUID) on the saved session from the HealthKit result; Android refineFinishedSessionWithHealth only updated the review and the healthRecordId link, so strength/quick-log sessions never carried measured kcal, although ProgressSnapshot:203 consumes the field.
Change: SessionReviewSupport.applyMeasuredEnergy + WorkoutRepository.refineSessionReviewWithCardio. Writes the kcal from readSessionSample (reliably associated Health Connect session, same origin package, inside its range) once; never overwrites, ignores null/<=0/NaN, never derived from time or load. 2 JVM tests (MeasuredEnergyTest). No schema change (field already in WorkoutMirrorStore list).
Limits: the review-unchanged + kcal-written case returns null, so the UI refreshes on the next reload, not immediately. Only runs when sample.hasUsableSignal. Duration, start/finish and UUID are NOT copied from Health (Android keeps its local range and healthRecordId); not claimed equal. Applies to any session that goes through that refine path, not only quick log. Not run on device; HC association behaviour is hardware-bound.

### Row 52 - kcal write hardened (14:39 CET)
Parent review: association not proven enough. Read SessionHealthMatcher/matchedSession: validStoredLink, associate (70%/60% overlap, 0.85 ambiguity) and eligibleForSession compare ONE local session with Health candidates; nothing proves that no other local session matched the same record. So "reliably associated" is only per-session, not cross-session.
Change: applyMeasuredEnergy now also refuses when the session lacks parseable start/finish or its time range overlaps any other saved workout (conservative: skip, never double count). Infinity: isFinite already rejected +/-Inf; tests added for both. Idempotent (never overwrites). 3 JVM tests; mobile 366/0/0.
Still unproven: a long external record spanning two non-overlapping Repera sessions is excluded only by the matcher's overlap ratios, not by this guard. LOAD_DISTANCE left as is (parent: keep, decide at the end only if it blocks the intended result).

### Row 52 - kcal exclusivity (14:43 CET)
Parent: two non-overlapping local sessions could share one long Health record. Changes: SessionCardioSample.sourceRecordId (set from the matched candidate id in readSessionSample); applyMeasuredEnergy requires a non-blank sourceRecordId and refuses when any other saved workout already carries that record id (HealthSessionLink.SNAPSHOT_FIELD), plus the earlier overlap/no-times guard.
Property test twoDisjointSessionsNeverBothMatchOneLongRecord: grid of 7 record lengths x disjoint session pairs (1750 combinations), none matched by both. This follows from the matcher thresholds (each session needs overlap >= max(60 s, 60% of the record), two disjoint overlaps cannot both satisfy that). It is a grid check of the real SessionHealthMatcher.associate, not a proof over all inputs.
Results: :domain 349/0/0, :mobile 368/0/0 (MeasuredEnergyTest 5), compileDebugAndroidTestKotlin OK. Ambiguous or unknown attribution = no write. Other Health fields untouched.

### Row 79 - leftovers read and two fixes (14:46 CET)
Read: PaywallScreen/ProTeaserCard icons with contentDescription=null are decorative next to text (OK). Gesture controls: LiveSportHistory SaveRouteSwipeRow already has a custom accessibility action; ReperaCards swipe-to-delete keeps a visible labelled trash IconButton; ExerciseDetail/ProgressCharts scrubbing and BodyMap pointerInput not individually checked for a non-gesture alternative.
Fixes (compile-verified only, no TalkBack run, no unit test):
1. Paywall plan option: selected state was only a border and an icon without description. Added semantics role=RadioButton + selected.
2. FinishedWorkoutEditor DragReorderItem (blocks and items): reorder was long-press drag only. Added custom accessibility actions "Mover arriba"/"Mover abajo" that call the same onDrop path with the row's own center and the neighbouring index (blocks use the target index; items reach the same-block branch of handleItemDrop). Not exercised: whether the item case resolves to the same block depends on geo bounds at runtime.
Apple comparison: Apple's draggable rows get VoiceOver reorder from SwiftUI; Theme.swift:863 has an accessibilityAdjustableAction. No screen-by-screen Apple/Android equivalence claimed. Still open: font scale, chart scrubbers, BodyMap, other screens.

### Row 79 - reorder accessibility, geometry removed (14:49 CET)
Parent: move actions that need row geometry are not verified as an accessible alternative. Changed: DragReorderItem takes an optional onMoveTo(targetIndex); actions exist only when supplied and are built by the pure moveActionTargets(index,count). The earlier version that reused onDrop with the row center is gone. Wired with explicit index operations: FinishedWorkoutEditor blocks (EditorBlockOps.moveBlock), exercises and WOD movements inside a block (EditorBlockOps.reorder), RoutineBlocksEditor blocks. Not wired (cross-block geometry): RoutineBlocksEditor entries; RotationSettingsSection already has Subir/Bajar buttons.
Tests (JVM): EditorBlockOpsTest +2 (label/target mapping incl. ends and single row; neighbour targets reorder arrays without geometry). Mobile 370/0/0; compileDebugAndroidTestKotlin OK.
Still not verified: that TalkBack exposes and invokes the actions (semantics are not asserted by a UI test), nor that onChanged persists in each caller. Row 79 stays open: scrubbing (ExerciseDetail/ProgressCharts), BodyMap, font scale, RoutineBlocksEditor entries.

## Row 65 - Entreno topic, cards compared (2026-10-26 14:56 CET)
Compared StatsView tilesGrid/mobilityProgressCard/exercise+record sections (fc3ef7e1:209-312, 645-760) with ProgressTab Entreno blocks. Static reading + JVM tests of extracted display logic; layout/pixels not seen.
Fixed (ProgressTilesModel, 3 JVM tests; mobile total below):
- Average time: Apple rounds (Swift half away from zero) and shows a delta vs previous period; Android truncated with toInt and showed no delta. Now rounded + delta (only when both averages exist; no text for 0/nil).
- Streak: Apple shows delta vs previousStreak; Android had previousStreak in the snapshot but never showed it. Now shown as "(+n)".
- Mobility time: Apple shows "N s" below a minute, else "m min s s"; Android showed floor minutes only (0 min for short sessions). Now Apple format.
Matches by reading: empty states for exercises and records (same strings); mobility card only when sessions>0; Free teaser strings.
Not compared / still open: Apple tile layout (three tiles in a row, adaptive) vs Android text cards (presentation differs, not changed); Android Entreno tab also shows total volume, kcal and cardio minutes that Apple places elsewhere (Actividad) or not at all; Apple's Pro mobility exercise links; Apple's "Ver más" top-5 list vs ProgressExercisesCard; heatmap, muscle balance, Actividad and Recuperación topic cards; exercise-list top weights.

### Row 65 - Actividad topic (15:07 CET)
Compared StatsView healthSections (fc3ef7e1:313-382) with ProgressTab Actividad. Same order of cards: session score, cardio (HR), calories, weight; Free preview + teaser present on both.
Gap fixed: Apple shows "Salud no conectada" (+ settings CTA) when Health is not authorized and there is neither HR nor active-energy data; Android had no such card. Added ProgressHealthPrompt (pure rule, 1 JVM test) + card in Pro Actividad wired to todayHealth!=null and onHealthConnect. Text says Health Connect (platform adaptation).
Limits: "connected" is the app's own signal (todayHealth loaded), not a live permission check, so the card can appear before the first read completes; not seen on screen. Apple's expanded-layout 2-column grid for these cards not compared. Weight card details (goal line, empty state) and Recuperación topic (RecoveryHistoryCards vs HealthRecoveryProgressView) still open.

### Row 65 - Health prompt re-done on checked state (15:11 CET)
Parent: todayHealth!=null does not prove authorization (pending load, no data, error). Replaced with HealthAccessState (UNKNOWN/UNAVAILABLE/NOT_GRANTED/GRANTED) set by MainActivity.refreshHealthAccess from the real HealthConnectReader.available()/hasPermissions(); refreshed on resume and after the permission result; reset to UNKNOWN on account change; failure of the check leaves UNKNOWN.
ProgressHealthPrompt.kind: no prompt while UNKNOWN (pending), none when GRANTED even with empty charts (that is just no data), none when HR/kcal series exist; NOT_GRANTED -> "Salud sin permiso de lectura" + "Autorizar Salud" (opens the existing permission flow); UNAVAILABLE -> informational card without button. 3 JVM tests on the pure rule. Compile-only for the Activity/screen wiring; not run on a device, so the real values of hasPermissions on hardware are unverified. Pro-only, like Apple.

### Row 65 - Recuperación topic and Pro teasers (15:17 CET)
Compared HealthRecoveryProgressView (fc3ef7e1 HealthRecovery.swift:518-780) with RecoveryHistoryCards by reading. Already matching by structure: evolution chart + "Aún no hay suficientes registros" empty text, Free sample labelled fictitious, sleep card with out-of-range fallback (SleepPeriodSummary.outsideRange vs displayNights suffix(14)), physiological constants cards with Android-specific RMSSD/SDNN wording, cycle card only with data. Strings differ in wording in places (Android is more explicit); not equated.
Gaps fixed (compile + existing JVM suite only, no UI test, no pixels):
- Recuperación topic had no Free teaser. Added ProTeaserCard "Recuperación completa" / "Consulta cómo evolucionan tu descanso y tu preparación para entrenar." / "Descubrir Repera Pro", appearance RECOVERY, opens the same paywall as the other teasers.
- Entreno and Actividad teasers passed no appearance/cta, so they rendered with the default EVOLUTION artwork and "Ver con Repera Pro". Apple uses .progress / .activity and "Descubrir Repera Pro". Set both.
Still open: Apple's tap-to-select chart behaviour on these charts, physiology card contents beyond titles, expanded two-column layout, weight card goal line/empty state, Entreno extra lines. Mobile JVM suite 376/0/0 (no new tests in this step).

### Row 66 - muscle balance placement and gate (15:26 CET)
Apple StatsView training order: Pro = tiles, activity, muscleBalance, mobility, exercises+records; Free = freeTiles, freeActivity, muscleBalance, mobility, freeTrend preview, teaser. The map/bars are free ("sin filtros de suscripción", StatsView:~250).
Android (before): muscle card came AFTER exercises/records/teaser and was hidden when muscleStatuses was empty. Changed: card now sits before the exercises/records block (and the Free teaser), always shown for Free and Pro; MuscleBalanceCard already carries its own empty texts ("Sin entrenar en este periodo", "Sin series duras..."), as Apple's does.
Not changed: Android keeps mobility inline in "Constancia" rather than Apple's separate Movilidad card, and cardio card/heatmap order; Free freeTiles/freeActivity variants not compared. Gate: no subscription check around the card on either side by reading; no UI run. Instrumented tests reference MuscleBalance (BodyMapContrast, VisualVerification) were NOT executed, so any layout dependence on the old position is unchecked. JVM mobile suite re-run: 376/0/0.

## Row 65 weight card goal source (static read, 2026-10-26 15:46)
- Apple passes `store.state.settings.bodyWeightGoalKg` as `goalKg` (StatsView.swift l.376). Android `ProgressTab` passes `overview.healthGoals.weightKg`, read by `HealthGoals.read` from the same `settings.bodyWeightGoalKg` key (valid 20..350). Same source key; goal line drawn by `DayPointLineChart(goal=)`.
- Not verified: rendering of the goal line vs Apple, empty-state text, Apple range validation. No execution beyond existing JVM tests; instrumented tests not run.

## Row 65 Movilidad card (2026-10-26 15:58)
- Apple: separate "Movilidad" card after muscle balance (Free and Pro), rows "Tiempo registrado" and "Sesiones con movilidad"; Pro adds links to the first 3 `chartExercises` with `isMobility`.
- Android before: one text line inside "Constancia". Now `ProgressMobilityCard` after `MuscleBalanceCard`, same two rows (duration via `ProgressTilesModel.mobilityDuration`), Pro/no-subscription-gate links to first 3 mobility rows (`ProgressExerciseRow.isMobility` = any `StatsExercise.isMobility`). Line removed from Constancia.
- Not verified: that `StatsExercise.isMobility` is populated from every source (Android mobility seconds still derive from sportTag "Movilidad"; the two flags are separate paths); Apple's chartExercises ordering for mobility; pixels. Compose UI only compile-checked, no JVM test of the card.

## Row 65 "Progreso por ejercicio" comparison (2026-10-26 16:08)
- Same as Apple (static read of ProgressSnapshot.swift l.305-345 vs ProgressSnapshot.kt): ordering by last date desc then name; top weight = max of non-warmup sets with reps>0 and weight>0; empty text; top-5 list; mobility duration filters (non-warmup, reps>0, duration>0).
- Changed: "Ver todos los ejercicios (N)" -> visible "Ver más" with contentDescription "Ver todos los ejercicios" (Apple label/a11y). The instrumented test string was updated; not executed.
- Differences left: Apple opens a pushed `ProgressAllExercisesView`, Android an AlertDialog list (same content, different container; not validated visually). Apple derives chartExercises from the exercise catalog, Android from workout entries (a deleted-catalog exercise would appear on Android only; not checked).

## Row 65/66 Free Entreno variants (2026-10-26 16:17)
- Apple Free Entreno: freeTilesGrid (3 tiles Entrenos/Tiempo/Racha), freeActivityCard (week heatmap), muscle balance, mobility, `freeExerciseTrendPreview` (fictitious weights 42..55, label "Ejemplo", a11y "Ejemplo de evolución por ejercicio, datos simulados."), then the teaser.
- Added on Android: `ProgressExerciseTrendPreview` (same weights, bounds 35..65, non-interactive) before the Free teaser. The chart axis shows the last 7 calendar days, Apple's axis is session index 1..7 (axis labels differ, not changed).
- Still differing (no change): Android Free/Pro Entreno uses a text "Resumen" card instead of Apple's tile grid; Free "Tiempo" tile (avg*count) has no Android tile; the Free heatmap range is whatever Android passes (not checked to be forced to week). Not executed visually.

## Row 65/66 Entreno tile row (2026-10-26 16:30)
- Added the 3-tile row (Entrenos / Tiempo medio (Pro) or Tiempo (Free: round(avg*sessions)) / Racha) above the existing "Resumen" card, with Apple's delta rules (Pro sessions delta needs previous; Free has deltas only on Racha; zero/nil delta reserves the line, invisible). Logic is `ProgressTilesModel.tiles` (+1 JVM test).
- Not removed: the Android "Resumen" text card (volume, kcal, cardio lines) stays since Apple's location for those extras is not mapped, so tile values now appear twice on Android. Layout is compile-only: no pixel check, no minimumItemWidth/adaptive wrap, no 28pt/minScale text behaviour.

## Row 65 Entreno: duplicates removed + adaptive tile width (2026-10-26 16:31)
- Removed metrics now shown by tiles: "N sesiones" (kept only "X movidos"), "Duración media", "Periodo anterior ... sesiones (+d)", and the "N semanas seguidas" streak sentence in Constancia. Kept (not mapped to Apple): volume moved, kcal, cardio medio, sesiones este mes.
- Tile layout: columns = floor((width+8)/(96*fontScale+8)) clamped 1..3, so large font scale wraps tiles into fewer columns (mirrors Apple minimumItemWidth 96 with scaling; the font-scaled minimum is my choice, not an Apple value). Compile-only: no render at font scale 1.3/2.0, no pixels.

## Row 79 chart selection without gestures (2026-10-26 16:38)
- `DayPointLineChart` (interactive) and the ExerciseDetail evolution chart selected points only by tap/drag. Both now expose TalkBack custom actions "Punto anterior"/"Punto siguiente" driven by the pure `ChartSelectionStep.step` (no geometry; from no selection both start at the last point; clamped). JVM test: `ChartSelectionStepTest`.
- ExerciseDetail chart also got a contentDescription ("Evolución de N registros"); the selected value remains in the Text below, which is not announced as a live change.
- Not verified: TalkBack behaviour, that the merged semantics of DayPointLineChart announce the selected point, Apple's VoiceOver adjustable behaviour (not read). BodyMap, font scale elsewhere remain open.

## Row 79 RoutineBlocksEditor entries move actions (2026-10-26 16:48)
- Entries in a block now pass `onMoveTo` to `DragReorderItem` (TalkBack "Mover arriba/abajo", explicit index, same remove/add as the drop path's same-block branch). Cross-block moves already have the "Mover" menu (`PlanEntryMoves.move`).
- No new JVM test (the action body is an inline list mutation on a Compose state list; the index math is the tested `moveActionTargets`). Not verified: TalkBack, persistence by the caller.

## Row 79 BodyMap / muscle bars (2026-10-26 17:00)
- Apple (MuscleBalanceCard.swift l.76-81, 132-178): only a map tap selects a muscle; bars are not interactive. Android matches this; no discrepancy, so no change.
- An Android-only a11y extension (bar rows toggling selection) was added in 665ed5a8 and reverted (not parity, not requested). Known limit: the map has no per-muscle semantics or contentDescription, and TalkBack was never tested.

## pendingFinish / watchHealthKitPending comparison (static read, 2026-10-26 17:10)
- Apple Watch (WatchSessionHub.swift l.295-312, 955-985): `awaitingHealthSave` is an in-memory flag. After relaunch it is rebuilt from persisted `lastFinished` with `appleHealthProvenance == "watchHealthKitPending"` and no `healthKitWorkoutUUID`; then `health.recoverIfNeeded(id)` and, if recovered, `health.finish` fills uuid/duration/kcal/avg HR/start/end (`applySavedHealth`) and resends the finished session. While the flag is set, selectBlock/set actions are ignored.
- Android Wear: finish intent is persisted by `WearPendingFinishStore`; set/selectBlock actions are blocked while it exists (WearMainActivity l.438, 528, 625); resend is re-driven by `resendFinish`; the live exercise is reattached from `ExerciseClient.getCurrentExerciseInfo` (WearHealthSession l.106/154/185). No `watchHealthKitPending` provenance equivalent exists on Android because Health Services holds no persistent HKWorkout-like record to re-save.
- Unverified (hardware-bound, nothing run): that a process kill between `endExercise` and phone ack reattaches/finishes correctly on a device; whether Apple's metric backfill (duration/start/end) has an Android counterpart is the open row 52 field set. No code change made from this read.

## Row 65 Entreno "Resumen" extra lines (static grep, 2026-10-26 17:28)
- StatsView.swift at fc3ef7e1 has no "movidos", "Energía activa" or "Cardio medio" strings (grep count 0). The Android Resumen lines (volume moved, kcal, cardio medio) have no Apple Entreno counterpart. Left in place: removing user-visible data is not a parity fix by itself and was not requested. Whether the data appears elsewhere in Apple (e.g. Actividad) is not mapped.

## Row 52 Health refine fields: contract/origin/association/effects (static read, 2026-10-26 17:35)
Apple sources (fc3ef7e1): ReperaStore.swift l.180-215 (kcal recalc), 1427-1470 (`syncWorkoutToHealth`), 1612-1632 (verifiedWatchWorkout link), 1542-1549; HealthKitStore.swift l.1188-1205; WatchSessionHub.swift l.955-985.
- Origin of times. In `syncWorkoutToHealth` Apple first WRITES an HKWorkout from the session's own startedAt/finishedAt (`finishWorkout(start:end:)`), then copies `apple.startedAt/finishedAt/durationSeconds/kcal` back. For an app-written workout those are the same values that went in (identity copy). For a Watch-captured workout (`verifiedWatchWorkout`, WatchSessionHub.applySavedHealth) the times come from the Watch session that IS the primary record, and only duration/kcal/uuid are copied on the phone link path (l.1625-1627: no start/end copy there).
- Association. Apple links by session id / UUID written by the app itself. Android has no app-written Health workout and no Watch HKWorkout; its only link is `HealthSessionLink.SNAPSHOT_FIELD` set from a Health Connect session found by time overlap (kcal write, `applyMeasuredEnergy`). Start/finish are therefore the key of the association: copying them from the matched record would be circular and would rewrite saved times on a heuristic match.
- Duration. Apple `appleDurationSeconds` = wall time (end-start, min 60) unless provenance is watchHealthKit. Android (`WorkoutRepository` editing path l.2515-2518, quick-log l.1053) writes the same wall-time/min-60 value; consumers `ProgressSnapshot` l.146 and `HealthExclusionSnapshot` l.13 read the field (equivalence with Apple HealthKitStore l.1197/1836 and ReperaSessionMatchIndex l.28 not compared). No Android path sets watchHealthKit provenance.
- Effects of copying times: changes sort order, streaks, weekly buckets, exclusion windows for external Health workouts and Wear/phone dedup keys. Not tested.
- Conclusion (static): there is no Android flow in which Health times differ from local times by construction, so Apple's start/finish copy has no functional counterpart to reconcile. Not copying is kept for functional reasons (circular association; data rewrite). Local tests: `MeasuredEnergyTest` covers kcal only; no test exercises start/finish/duration refine because the code does not exist. Not verified: Apple behaviour on a real Watch link, any device.

## Row 65 mapping of volume / kcal / cardio in Apple StatsView (static grep, 2026-10-26 17:40)
- Volume: only as the heatmap "volume" metric (`preparedVolume: snap.heatmapVolume`, l.429/738). Android has `heatmapVolume` in `ActivityHeatmapCard`. No separate "volume moved" line in Apple Entreno.
- kcal and HR: Actividad topic only, via `cardioHealthSection` -> `ProgressCardioChartCard` (l.320-363, 494-501) with the authorization prompt (l.351). Android has the Actividad HR/kcal charts (`chartsByRange`) plus the Health prompt.
- Cardio minutes: no Apple Entreno counterpart found. Android has an Entreno "Cardio" card (`cardioSeries`) and a "Cardio medio" line in Resumen. Both are Android-only on Entreno.
- Consequence: Resumen lines (movidos, kcal, cardio medio) and the Entreno Cardio card duplicate or extend data Apple shows only in the heatmap or Actividad. Not removed (data removal not requested); recorded as a divergence for the final decision list.

## Row 52 CORRECTION of the section above (2026-10-26 17:50)
- The earlier statements "Android has no app-written Health workout" and "no counterpart to reconcile" were WRONG. Exact Android paths: `MainActivity` l.1411 -> `HealthConnectWriter.syncFinishedSession` (HealthConnectWriter.kt) -> `SessionHealthMatcher.resolveLink`: reuse stored link / adopt own record with the same `HealthSessionLink.clientRecordId` / adopt ONE unambiguous external ExerciseSessionRecord (no write) / else insert an `ExerciseSessionRecord` from the local start/end with a stable clientRecordId. The id is stored with `WorkoutRepository.setHealthRecordId`; then `refineSessionReviewWithCardio` reads HR/kcal.
- Apple counterpart (`HealthKitStore.finishWorkout` l.2013-2083, `ReperaStore.syncWorkoutToHealth` l.1427-1470): same four cases, but when an external workout (Watch/Apple Entreno) or a previous own workout is adopted, Apple resolves `resolvedStart/resolvedEnd/duration` from that record ("fuente de la verdad: duración y fechas del HKWorkout real") and the store copies startedAt/finishedAt/appleDurationSeconds/kcal into the session.
- Real divergence: on ADOPTION of an existing record Android keeps local start/finish/duration and stores only the id (the writer returns an id, not times). For an own-inserted record both sides are an identity copy. The adopted-external case is the only place times can differ; Android uses `SessionHealthMatcher` window rules (QUERY_SLACK_MS) so the adopted record already overlaps the local window.
- Decision state: NOT changed. Local times stay (no rewrite on heuristic match, per parent). Still to do locally before any change: read `SessionHealthMatcher` tests/rules to bound how far an adopted record's times can differ, check the downstream effects listed earlier, and add a pure JVM test of any chosen rule. Not executed here.
- Bound from `SessionHealthMatcher.associate` (thresholds documented in the file as literal copies of Apple's overlappingWorkout; the copy itself not re-verified here): an adopted record must overlap >=70% of the session and >=60% of the record, with the two best within 85% treated as ambiguous. So an adopted external record can start/end materially differently from the local session (up to ~30% of the session length at the edges); copying would shift saved times by that much. This is the effect size to weigh; no test of it exists.

## Row 52 downstream consumers of saved startedAt/finishedAt (grep, 2026-10-26 17:40)
Files in mobile/domain/wear main that read the keys "startedAt"/"finishedAt": CompletedWorkoutEditing, ExerciseLoadGuide, ExerciseProgressMetrics, ExerciseProgressSeries, ExerciseSessionAppearance, ExerciseSessionHistory, HealthExclusionSnapshot, LiveSportSnapshot, MainActivity, MuscleWorkloadMetrics, ProgressSnapshot, SessionReviewJson, SessionReviewSupport, SessionScoreProgress, WearActiveSessionBridge, WorkoutHistorySets, WorkoutMirrorStore, WorkoutRepository, WatchPlanExecution (domain), WearMainActivity.
- So a time rewrite on adoption would reach: history ordering and progress series, muscle workload windows, review/score history, exclusion windows for Health workouts, the Wear bridge and the mirror to the backend (`WorkoutMirrorStore`). It is not a local cosmetic field.
- Not read per consumer (which ones are order-only vs window-sensitive); no test exists for any of them under a shifted time. Therefore no code change; if one is wanted it needs a pure rule plus per-consumer tests first.

## Play identidad estable de ítem (live main 6ac9f0e4..c898bc77, 26 Oct 08:18-08:28)
Apple: `SessionExercise.id` = id del ítem/movimiento de la rutina; `refreshActiveSessionPlan` empareja por ese id y solo recurre a ejercicio para ids antiguos.
Android antes: id de sesión aleatorio; `ActiveSessionPlan.refresh` emparejaba por ejercicio+bloque en orden, de modo que reordenar un ejercicio repetido reasignaba resultados al otro ítem (fallo plausible por análisis estático, no reproducido en dispositivo).
Cambio: `assembleSession` y `WodSessionAssembler` usan el id del ítem; `refresh` empareja por id primero y el fallback por ejercicio solo usa ids previos que ya no existen en el plan nuevo; la selección actual sigue al id. JVM: ActiveSessionPlanTest +2 (reorden de repetido, ids antiguos). Sin verificación en dispositivo.
NO hay contraparte Android de "editar series pendientes en Play": el flujo Android registra la serie al confirmarla con valores prefijados (no hay lista editable de series sin confirmar ni "Quitar serie"). Se documenta; no se añade función.

## Home: puntos del calendario solo con entreno finalizado (live main 6ac9f0e4, b75ecbcb)
Apple: punto en el día solo si hay entreno finalizado (Repera o Salud); sin punto por planes ni sesiones en curso; seleccionar cambia el color, no la visibilidad; el hueco se reserva.
Android antes: `WeekCalendarStrip` NO pintaba ningún punto (hueco pre-existente, no solo del cambio nuevo).
Cambio: parámetro `completedDays`; Home pasa los días con `overview.dayWorkoutCounts>0` (sesiones locales con `finished` + actividades externas de Salud, ya la fuente del progreso semanal). Punto verde 4dp con hueco reservado y stateDescription "Entrenamiento completado". Diario no pasa días (Apple no los tiene allí; sin verificar). Home ya lista todos los planes del día como Apple. Compilado + JVM sin regresión (sin test nuevo: UI); sin verificación visual ni TalkBack.

## HealthRecovery live main 9ab2b510 (auditado por diff, sin cambio de código)
Contenido: ancho expandido decidido por el contenedor Progress (sin recalcular al entrar en Recuperación), alturas de gráficas derivadas del ancho de columna DUO (readiness 205-270, sueño >=220, fisiología >=128), banner Pro único fuera de la rejilla, celda reservada para la gráfica de recuperación (empty chart con la misma altura), título+gráfica de Sueño como una sola celda.
Naturaleza: afinado de maquetación iPad/DUO en puntos; no cambia datos ni reglas. Android usa `AdaptiveCardPair` y alturas propias; la equivalencia solo se puede juzgar con píxeles en dispositivo. Estado: por verificar en hardware, NO cerrado ni declarado alineado. "Progress scroll restoration" (mismo commit) sin auditar aún en Android.
Sin leer todavía: ActivityHeatmapView, StatsView, ProgressChartBuilder/Snapshot/TrendCards, LiveActivityView/CardioRouteComponents, HealthKitStore mixed-distance, MuscleMapEngine/Taxonomy/HealthMuscleMapper, StatsEngine, CompletedWorkoutEditing, History/Library/Plan/QuickLog/Settings/StartHub.

## Home dots: fuente (auditoría) y Progress (live main StatsView 26 Oct)
Dots: el punto solo depende de `dayWorkoutCounts>0`, así que un duplicado Repera+Salud del mismo día no cambia el resultado. Las sesiones sin finalizar se excluyen por `finished`; ojo: Android define finished = `phase==finished` O `finishedAt` no vacío, Apple Home exige `finishedAt`. Caso límite (phase finished sin finishedAt) no reproducido ni tratado. Sin test, sin píxeles.
Progress cambio de pestaña: Apple vuelve al encabezado sin animación al cambiar de tema (offset inválido dejaba la vista vacía). Android comparte un solo LazyColumn entre temas: `scrollToItem(0)` al cambiar de tema (no en composición inicial/restaurada). Compilado; sin test ni dispositivo; el fallo de Apple no se reprodujo en Android.
Progress enlace "Deportes · evolución y récords" (Entreno, solo con actividades En vivo finalizadas): Android no tenía acceso desde Progreso (el catálogo de deportes existe en Biblioteca > Deportes). Añadido enlace que abre Biblioteca en modo Deportes (solicitud de un solo uso). Compilado; sin test ni navegación probada en dispositivo.
Heatmap Apple (celda rectangular `cellHeight=min(cell,76)` para rangos de 1-3 días): maquetación, Android no auditado.

## HealthKitStore live main (26 Oct): auditado por diff
1. Asociación por identidad, no por horario (existingReperaWorkout por metadata ReperaSessionID; sin solape tras editar hora; Watch verificado por id con prioridad; no sustituir enlace previo por otro entreno). Android: `SessionHealthMatcher.resolveLink` solo se llama al finalizar (`MainActivity` -> `syncFinishedSession`), con las horas del cierre; no hay re-sincronización tras editar horas, así que el escenario "hora editada días después" no existe hoy en Android. Diferencia estática residual: `validStoredLink` exige que un enlace externo guardado siga solapando la ventana actual (Apple confía en la identidad persistida); no alcanzable sin re-sync. Sin cambio. El "Watch verificado por id" es Apple-only (no hay equivalente Wear en este flujo; sin verificar).
2. HUECO IDENTIFICADO, no implementado: métricas de movimiento por sesión (pasos y distancia del HKWorkout, etiqueta por deporte/mixtos, "en horario" cuando son muestras horarias, distancia mayor medida, nunca estimada). Android solo lee pasos diarios (`StepsRecord.COUNT_TOTAL`); no hay lectura de `DistanceRecord` ni pasos por sesión en la reseña. Cerrarlo requiere permiso de lectura de distancia en Health Connect y lectura por ventana de la sesión asociada: cambio de permisos/producto, pendiente de decisión del propietario antes de implementarlo.
3. HistoryView: aviso "distancia recuperada, pero los puntos GPS no viajan por Supabase" y tarjetas de métricas con `hasMovement`: sin auditar en Android.

## Métricas de movimiento por sesión (Apple workoutMovementMetrics, live main 26 Oct) - implementado local
- Dominio puro `SessionMovementMetrics.resolve` (5 tests JVM): pasos y distancia solo con valores finitos >0, nunca estimados; asociado antes que ventana; `usesTimeWindow` si alguna cifra mostrada viene de ventana; etiqueta por tipo (nieve/bici/nado/a pie; mixtos "Distancia recorrida"; agua sin distancia de muestras sueltas pero con pasos).
- Lector `HealthConnectReader.readSessionMovement`: misma asociación que `readSessionSample` (sin asociación o ambigua = nada). "Asociado" = mismo origen (paquete) que la sesión de Salud asociada dentro de su rango; si no hay, suma de cualquier origen en el rango marcada "en horario". Cada lectura exige su permiso ya concedido; no se solicita nada nuevo en ejecución.
- Manifiesto: se declara `READ_DISTANCE` (antes solo `READ_STEPS`); `optionalMovementPermissions` se añade a `requestedPermissions()` pero NO a `permissions` ni a `hasPermissions()`: su rechazo no desactiva nada. Declarar no concede; la concesión real la hace el usuario en Health Connect (pendiente, al final). Posible impacto en la ficha de Play (declaración de permisos de Salud): no verificado.
- UI: `SessionMovementSection` en tarjeta de historial y detalle de deporte, por `LocalSessionMovement` (sin cambiar firmas ni esquema; nada se persiste).
- Límites reales (NO equivalencia): Health Connect no enlaza muestras a un ejercicio ni distingue modalidades en DistanceRecord, por lo que no se puede reproducir "mayor modalidad medida" ni "workout.totalDistance" de Apple; mixtos usan etiqueta genérica. No probado en dispositivo ni con datos reales. Compilado + JVM de la regla; el lector y la UI solo compilan.

### Corrección 18:15 sobre movimiento por sesión
- Se retira `optionalMovementPermissions` de `requestedPermissions()` (la nota anterior que lo añadía queda sin efecto): la app NO pide `READ_DISTANCE` automáticamente; el manifiesto solo lo declara y la lectura exige que ya esté concedido. Cualquier petición futura requiere decisión del propietario.
- Ventana sin asociación: ya no se suman orígenes. Se lee por origen (agregado por paquete) y solo se usa si UN único origen aporta datos (`windowTotal`); con varios, sin dato (fail-closed), porque pueden duplicar los mismos pasos/distancia y aquí no hay prioridad de Health Connect conocida. Test JVM multi-origen en dominio. El lector sigue compilado sin probar con datos reales.
- "Asociado" = mismo paquete y rango que la sesión de Salud asociada; NO es un vínculo muestra-ejercicio como en HealthKit.

## Regla única de series confirmadas (Apple StatsEngine.confirmedWorkSets, MuscleMapEngine/Taxonomy; live main 26 Oct)
Apple: estadísticas, volumen, PRs, equilibrio muscular y fatiga usan una sola regla: sesión sin finalizar = nada; series de trabajo registradas mandan; solo calentamientos registrados NO confirman lo prescrito; sin registros, sesión finalizada acepta lo prescrito; todas las apariciones del ejercicio en varios bloques cuentan.
Android antes: carga muscular, historial y progreso por ejercicio usaban `WorkoutHistorySets.effectiveWorkSets` (con fallback a prescrito si finalizada), pero el adaptador de Progreso (`ProgressSnapshotBuilder.adapt`, base de volumen/PRs/resumen) solo veía `loggedSets` -> volumen del Resumen distinto de lo que mostraban otras vistas para la misma sesión (estático + test); además un calentamiento registrado sin series de trabajo caía al prescrito.
Cambio: `WorkoutHistorySets.confirmedWorkSets` (finalizada + regla anterior); usado en `MuscleWorkloadMetrics` y en el adaptador cuando la sesión finalizada no tiene ningún set registrado. JVM: ConfirmedWorkSetsTest (+2) incl. volumen del adaptador. Sin escribir sets sintéticos en disco.
NO cambiado: `ExerciseProgressMetrics/Series`, `ExerciseLoadGuide`, `ExerciseSessionAppearance` siguen con `effectiveWorkSets` (sin auditar si Apple las pasó a confirmed).
Aviso de producto (decisión del propietario al final): en Android, "finalizar" acepta lo prescrito en sesiones sin series registradas igual que Apple; el modelo de entrada difiere (Android registra al confirmar), así que esto puede contar como ejecutado trabajo que el usuario no marcó.
PENDIENTE sin tocar: estímulo muscular estimado de WOD completado sin series (MuscleCompletedWODStimulus: equivalente 1 serie, x0.7 en carga); Android excluye WOD explícitamente de las series y no tiene ese equivalente. Lista ampliada de tipos externos de actividad en StatsEngine (crossfit, boxeo, artes marciales, etc.): sin comparar.

### Auditoría por consumidor de la regla confirmed (18:25)
Apple (live main, `git grep`): usan `confirmedWorkSets` -> StatsEngine.history, exerciseProgressSeries, lastWorkingSession, exerciseSessionSnapshots, PRs, totalSets, volumen, MuscleMapEngine, MuscleTaxonomy, MuscleBalanceCard, ProgressSnapshot. `ExerciseSessionAppearance` sigue con `effectiveWorkSets`. `ExerciseLoadGuide`: no se localizó fuente Apple equivalente por este grep (sin auditar).
Android tras el cambio: `confirmedWorkSets` en adaptador de Progreso, `MuscleWorkloadMetrics`, `ExerciseProgressMetrics` (resumen por ejercicio) y `ExerciseProgressSeries`; `ExerciseSessionAppearance` queda en `effectiveWorkSets` como Apple; `ExerciseLoadGuide` queda en `effectiveWorkSets` (sin fuente Apple verificada). Tests JVM por consumidor: adaptador, muscle gate (WorkoutHistorySets), resumen por ejercicio, serie por ejercicio. `MuscleWorkloadMetrics`, `lastWorkingSession` y `totalSets` equivalentes en Android: sin test propio de consumidor. Origen inferido: el fallback prescrito NO es trabajo realmente confirmado; ni Apple ni Android lo marcan en la UI de métricas (Android no distingue la fuente inferida; pendiente de diseño si se quiere mostrar).

## CompletedWorkoutEditing (live main vs fc3ef7e1) - Android comparison

Closed locally (pure rule, JVM tests in CompletedWorkoutEditingTest):
- Unconfirmed or new sets in the editor are not turned into LoggedSet (only ids already logged are rebuilt).
- durationSeconds is kept/edited; deficitCm cleared on non-deficit load; completedReps counts only phase == work.
- visibleSets overlays logged sets by position over planned ones and keeps pending planned sets.
- Changing a WOD format no longer deletes a real result; each result keeps its own format; only deleting the block deletes it.
- Missing block wodFormat is recovered from the recorded result (non per-movement) in blocksFrom and for blocks created from exercises.

Open (not implemented): editableScore / scoreValue / changingScore (editable WOD score fields reps/rounds/minutes/seconds, with limits 5000/200/180/59, inference of a legacy single-set AMRAP score). Android's editor UI has no such score fields yet; this is a UI+rule port still to do. Tests are JVM-only; the editor UI has no pixel or TalkBack check.

### Update: editable WOD score ported (local)
Pure rules editableScore/scoreValue/changingScore in CompletedWorkoutEditing (limits 5000/200/180/59; other-format result kept; legacy single-set total inferred for display only). Finished-workout editor shows reps/rounds or minutes/seconds fields for blocks with a global-capture format; edits are replayed on save after content edits (WorkoutRepository.updateFinishedWorkout). JVM tests cover the pure rules only; the repository replay and the editor UI are compile-only (no instrumented run, no pixels/TalkBack).

## Live sports catalog and native-sport muscle stimulus (live main vs fc3ef7e1)
Closed locally (JVM tests in NativeSportStimuliTest + updated LiveSport tests):
- LiveSport: +17 sports (combat, racquet, cardio/gym, team), groups +Combate/+Cardio y gimnasio, gravel/other selectable, healthKey (Apple healthType mirror), cardio set 29 -> 45.
- HealthMuscleMapper.nativeSportStimuli / isEstimatedIntense / highEffortStimuli / nativeHighEffortSportStimuli; Progress muscle "all" layer adds native-sport stimuli, the "hard" layer uses only high-effort external stimuli (previously all external), hasHardSets includes them. isCardio: coreTraining/yoga/pilates/flexibility/cooldown/other are not cardio minutes.
- Icons for new sports are Material approximations (LACROSSE uses a generic icon). Compile-only, no pixels.
Not done (open): MuscleCompletedWODStimulus (completed WOD without sets: 0.7 x 1 set-equivalent in fatigue, 1 in weekly load), StatsEngine.confirmedWorkSets inside MuscleMapEngine.retainedLoad/weekly, uniqueExternalActivities native-overlap dedup (Android uses ReperaHealthExclusion at reader level; not shown equivalent), HealthConnect write mapping for new sports (no Android writer for LiveSport types found), LiveActivity recorder voice changes (rate/pitch/kilometre phrases, no km notification) and Cardio route components not yet compared.

### Update: MuscleCompletedWODStimulus (local)
MuscleStimulusExercise.completedWodSetEquivalent (set by ProgressSnapshot.adapt: finished, WOD block or block score, not mobility, no work set recorded). MuscleMapEngine.retainedLoad uses 0.7 x 1 when no recorded sets (not in the hard layer); weekly load uses 1. JVM tests on the engine (CompletedWodStimulusTest); the adapter flag has no test. confirmedWorkSets inside the engine remains covered only through the adapter's existing confirmed-sets rule.

### Update: confirmedWorkSets inside the muscle engine (local)
ProgressSnapshot.adapt now feeds MuscleMapEngine only confirmed work sets: unfinished sessions and warmups/sets without reps no longer add fatigue or weekly load (before, recorded warmups added 0.25 fatigue each and unfinished logged sets counted). Test: ConfirmedWorkSetsMuscleEngineTest through ProgressSnapshotBuilder.build (JVM; the red-before state was reasoned from code, not run).

### Update: Health Connect writer exercise type (local)
Correction of the earlier "no writer found" note: the writer exists (HealthConnectWriter.syncFinishedSession, stable clientRecordId, reader/dedupe tests are synthetic, not E2E). It always wrote EXERCISE_TYPE_STRENGTH_TRAINING. Now the exercise type comes from the session's liveSportID (HealthConnectWriter.exerciseTypeFor; classic sessions stay strength). Health Connect has no dedicated type for CrossFit, core, pickleball, padel, kickboxing, wrestling or lacrosse: nearest type used, an approximation, not verified equal to Apple's HKWorkoutActivityType. The Apple title heuristic for non-live outdoor routes (bike/walk/run keywords) is not ported. Overlap matching in SessionHealthMatcher/ReperaHealthExclusion does not compare the activity type (Apple uniqueExternalActivities does): still open. No device or Health Connect E2E run.

### Update: native-overlap dedup in Progress (local)
HealthMuscleMapper.dropNativeOverlaps (Apple uniqueExternalActivities overlap rule: same type via LiveSport.healthKey, start < 90 s, duration < 3 min vs a finished live-sport session) is applied in ProgressSnapshotBuilder.build to day samples, streak and stimuli. The id-link half stays in the reader (ReperaHealthExclusion), which also uses a different 40%/45-min overlap rule that Apple's Progress layer does not have; the two rules are not shown equivalent. Health Connect type keys come from the reader (exerciseTypeKey); where HC lacks a type (crossTraining, core, pickleball...) keys differ from healthKey and the overlap will not match. History/external-list screens do not use this filter. JVM tests only.

### Update: LiveActivity spoken guidance (local)
Closed: kilometre phrase (Apple new wording, comma decimal, singular/plural; domain LiveSpokenPhrases, JVM-tested); kilometre and turn speech are queued instead of refused/flushed while voice is playing (LiveSpokenGuidance.speak(queue=true), focus released when the queue empties); the kilometre no longer falls back to a notification. TTS queue/focus behaviour is compile-only (no device, no audio check). Not changed: Apple speech rate/pitch tuning (AVSpeech 0.52 vs Android TTS 1.0, platform scales differ, not compared by ear); turn-notification fallback differs slightly (Android notifies when voice failed, Apple only when voice disabled). Still unread: CardioRouteComponents (route banner, recording controls, landscape guidance) and LiveSportHistoryView diff.

## Update tree75: session sport metric tiles (speed/pace/distance)
Pure rules in SessionSportMetrics (JVM tests); composable tiles are compile-only (no pixels/TalkBack). Distance uses only recorded distance (no health-movement fallback); recorded max speed not wired (falls back to route-point speeds). Still open: steps tile, HR/altitude Mín/Media/Máx tiles, split-table restructure.

## Audit 19:38: Play pending-set editing (no code change)
Apple main: SessionController.updateExerciseDraft persists edited, not-yet-done planned sets into the session and its routine block (item-id identity, occurrence fallback for old sessions, WOD explicitPlannedSets, [] allowed after swipe delete). Android: grep of mobile/domain main sources shows plannedSets written only by routine/finished-workout editors, board import, progression (progressedPlannedSets) and JSON codecs; no code path found that mutates planned sets of an active session from Play. Static finding from source reading, not a reproduced failure. Not implemented: needs the Android Play UI surface decided first. Remains open.

## Audit 19:40: Android Play surface vs Apple updateExerciseDraft (static, no code change)
Android Play (ActiveWorkoutCard in ReperaCards.kt, ActiveWorkoutScreen, ActiveSessionControls): one entry form for the next set (quantity/weight/deficit/unit/duration/RIR, `remember` keyed by active.id/index/completedSets, not rememberSaveable), logged via onLogSet at confirmation. There is no list of pending planned sets, so "Quitar serie", per-set draft edits, pct1RM drop and "untouched suggestions not saved" have no object to act on. The only persistence path for pending plan changes is "Editar entreno" (routine editor) -> ActiveSessionPlan.refresh, which already follows Apple's item-id identity with occurrence fallback and keeps logged results. Differences still open (each separate): inline per-set pending editing, Quitar serie incl. empty list, pct1RM drop, untouched suggestions not saved, WOD explicitPlannedSets. Implementing them means adding a pending-set list to Play; not started.

## Update tree76: ActiveSessionDraft (pure rule only)
Port of Apple updateExerciseDraft on the session JSON (item-id identity, occurrence fallback, WOD explicitPlannedSets, empty list kept). JVM tested (3 tests). NOT wired to any Play UI: no pending-set list exists yet, so Quitar serie, inline edits, pct1RM drop and untouched-suggestion handling remain open.

## Note 19:58: steps tile
Steps and movement distance already render through SessionMovementSection (ExercisesTab detail, ReperaCards) from SessionMovement (JVM-tested rule). Not verified: the LiveSportHistoryScreens route-detail screen itself (see grep count in report), HR/altitude Mín/Media/Máx tiles, splits table restructure remain open.

## Update tree77: HR and altitude Mín/Media/Máx tiles
Pure ranges in SessionSportMetrics (JVM tested). Tiles in the live-sport activity detail (ExercisesTab), always with "—" when missing for HR; altitude only with a route of >=2 points. Average is the mean of the shown series, not Apple's measured Health average (extras.averageHeartRateBpm), not validated equal. Composables compile-only. Still open: splits table restructure, ascent/descent label removal check, recorded max-speed source.

## Update tree78: splits table (KM / Tiempo / Ritmo|km/h / Frec. cardiaca)
Pure rule SessionSportMetrics.splitRows (JVM tested: invalid splits skipped, "—" bpm). Composable table compile-only. Instrumented test text updated to the new format ("5:00/km"); androidTest compiled, NOT executed. Recorded max-speed source still open.

## Update tree79: ActiveSessionDraft.revise (pure, planned part of persistActiveLiveDraft)
Rows -> planned sets: pending rows keep own id, completed rows keep the planned id at that position, reps >=1, different absolute kg drops targetPercent1RM and its minimum flag, else previous percent kept, empty list allowed. JSON keys checked against existing Android readers (targetReps/targetWeightKg/targetPercent1RM/targetPercent1RMIsMinimum). JVM tested; NOT wired. Apple's recorded-sets half (performedSets replace by id, no per-set check) not ported: it implies Apple Play has editable result rows with no per-set confirmation, whereas Android Play logs at confirmation. Still open as separate items.

## Update tree80: ActiveSessionDraft.replaceRecordedSets (pure)
Port of Apple replaceRecordedSets: replaces loggedSets by exercise id, completedReps from work-phase sets (+dropset drops). JVM tested; NOT wired. Semantics check 20:41: Apple finishWorkout and Android finishInPlace both mark isCompleted only for exercises with loggedSets and create no sets; "finish accepts prescribed" withdrawn (no source). Play rows UI still open.

## Update tree81: WorkoutRepository.updateActiveExerciseDraft (wiring of the pure rules)
One-save entry point (plan + optional recorded sets by id), mirrors ReperaStore.updateActiveExerciseDraft. Compiles; the repository method itself has NO test (storage-bound) and no caller in Play UI. Existing Android deleteCurrentSet/reviseCurrentSet already cover removing/editing a logged set by id. Play rows UI still open.

## Update tree82: "Quitar serie" for pending planned sets (Play)
Pure rule ActiveSessionDraft.removePending (only sets not covered by recorded work sets; last one removable; results untouched; JVM tested). WorkoutRepository.removePendingSet, ActiveWorkout.pendingSets (strength only, not WOD), LocalRemovePendingSet provided in MainActivity, "Pendiente N ... Quitar serie" rows in ActiveWorkoutCard (compile-only: no pixels/TalkBack; repository method untested). Not done: Watch is not notified of the changed prescription; inline editing of pending rows, pct1RM wiring, explicitPlannedSets for WOD movements, editable-result-rows model remain open.

## Update tree83: removePending transition tests
Added JVM tests: warmups ignored, drop set counts as one recorded set, repeated items address only the requested exercise id, a deleted logged set frees its planned slot. Rule remains positional (work-phase count), not id-based. Not covered: rest-pause clusters, WOD, removing recorded results via the row model, Watch notification.

## Update tree84: edit pending planned set (Play)
Pure ActiveSessionDraft.editPending (same positional coverage rule as removePending; reps>=1; kg change drops targetPercent1RM and its minimum flag; JVM tested), WorkoutRepository.editPendingSet (untested, storage-bound), LocalEditPendingSet, "Editar"/"Guardar serie pendiente" fields in ActiveWorkoutCard (compile-only). Edits the plan only; Apple's editable result rows (recorded sets without a confirmation tap) are not ported. Duration/RIR/deficit fields of a pending row are not editable here. Watch consumption of the changed plan not verified.

## Update tree85: Start with an active session continues it (SessionPreviewView)
Apple live main: with hasActiveSession, the preview's play button continues the active session instead of starting another. Android: startRoutine failed with "Ya existe una sesión activa". Now ReperaMobileScreen wraps onStartRoutine (3 call sites) and navigates to the active workout when one exists. Compile-only (:mobile:compileDebugKotlin); no test, no UI run. Only the call sites that receive onStartRoutine in ReperaMobileScreen are covered; other start entry points (widgets, Wear, quick start) were not audited.

## Update tree86: "Sincronizar ahora" (Settings, Apple SettingsView + BusinessWorkoutSyncStore)
Manual sync with visible state: button (disabled while syncing or without a verified Supabase session), footer error > "Última sincronización con Supabase: <fecha> · N registros remotos" > idle text. Footer rule JVM tested; the button composable and the MainActivity wiring are compile-only/untested. Uses the existing WorkoutMirrorStore.sync (Result.ok/mirroredCount/error); the automatic silent mirror is unchanged. Limits: `verifiedSupabase` is a plain var, so the enabled state may not recompose until another state changes; last sync text is not persisted across restarts (Apple store keeps it in memory too, not verified); Apple's serialized JWT refresh (ensureUsableSession) not compared with Android's session handling. Also read from the same diff pass: DayOverrideSheet (assign a copy by date) matches the existing Android date-copy action (WeeklyScheduleActions, static read only); RegisterSessionChrome WorkoutSummaryTile not audited.

## Update tree87: reactivity and isolation of the manual sync
verifiedSupabase is now backed by Compose state (custom setter kept, incl. the existing account-change reset by AccountRevisionGate), so the button's enabled state follows the session. Manual-sync state (syncing/last/count/error) resets when the verified session is cleared or the account changes; a finishing sync is applied only if profile uniqueId AND verified userId still match the ones that started it. Feedback: error text on failure (Result.error, exception message, or "No hay una sesión activa de Supabase..." without session), "Última sincronización..." on success. All of this is compile-only/untested (no JVM test of the activity state); no real-account sync was run. JWT refresh serialization and persistence of the last sync remain unaudited.

## Update tree88: network failure is not logout (Apple BusinessAuthStore.isUnrecoverableAuthError)
Finding (static, reproduced only by reading): Android restoreStoredSession cleared the stored session and returned to the login screen on ANY exception while restoring, including no network. Apple: only confirmed revocation (session_not_found, refresh_token_not_found, user_banned) requires re-login; network/other errors keep the session and local data and retry.
Change: SupabaseIdentity now throws AuthHttpException(httpCode, error_code from the body; message unchanged, no body/tokens in it); SupabaseAuthErrors.isUnrecoverable (JVM tested: 2 tests). On a recoverable restore failure Android keeps the encrypted session, sets the profile, shows "Sin conexión con la cuenta. Los entrenos continúan guardados localmente.", reloads local data, and retries restore in onResume while the session is unverified. Compile-only for the activity flow: no device/network-off run. Not changed: other refresh site (catalog refresh) already swallowed errors; no mutex serializing the two refresh sites (Apple serializes JWT renewal); manual/automatic mirror sync still uses the in-memory token without an expiry check before the call (open); startup side effects (Drive periodic work, realtime, mirrors) only run after a successful verification. Whether Supabase reports exactly these error_code values for revoked refresh tokens was not verified against a live server.

## Update tree89: serialized JWT refresh and pre-sync expiry check
- MainActivity: `refreshedSessionBlocking` under `sessionRefreshLock` refreshes the JWT if it expires within 90 s and saves via `saveIfCurrent`. Used by the catalog refresh, the restore path and both mirror sync entry points (sync receives the refreshed session; store key stays `session.userId` per AccountIdentityContractTest).
- Verified: compile and JVM tests only (:mobile:testDebugUnitTest). No network or device test. Last-sync persistence across restarts is still open.

## Update tree90: copyPreviousWeek occupied-days snapshot
- Apple `copyPreviousWeekSchedule` snapshots occupied dates BEFORE copying. Android re-checked the growing list, so a second session on the same source day was skipped after the first copy. Fixed in WeeklyScheduleActions; new JVM test (two same-day sessions both copy). 
- Still open: week navigator UI (prev/current/next week) and selected-week targeting in DiaryTab (the repo call already takes a reference date).

## Update tree91: copy previous week targets the selected week
- CORRECTION of my 22:59 report: Android already has a previous/next-week navigator (WeekCalendarStrip "‹ Semana" / "Semana ›"). The real gap was that "Copiar semana pasada" always used the current week. DiaryTab now passes the selected diary day to `copyPreviousWeekSchedule(week)` (Apple: `copyPreviousWeekSchedule(to: selectedWeekStart)`).
- Verified: JVM suite green (copy logic already tested at tree90) and androidTest compile at this step; the UI wiring (menu -> selected day) has NO test and no device run. Not done: no "return to current week" tap on the range label, clear-schedule is not week-scoped on Apple either to my reading (not verified), assign-by-date for the selected week not audited beyond the earlier static read.

## Update tree92: "Recorrido no disponible" notice
- Apple HistoryView shows an explanation when a GPS sport has recovered distance but no route points. Android now shows `RouteUnavailableNotice` in both detail sites (ReperaCards expanded card, ExercisesTab detail), gated by `RouteUnavailable.applies` (JVM tested: GPS sport + distance > 0 + fewer than 2 points). Text adapted ("dispositivo", not "iPhone/iCloud").
- Compile + predicate test only. UI has no pixels/TalkBack. Apple's HistoryView WOD "Resultado de formato anterior" grouping remains open.

## Update tree93: Home delete of a scheduled routine
- Apple Home now calls `removeScheduledRoutine(id:)`: dated + favorite -> keep template, clear date/weekday; dated + not favorite -> delete. Android Home delete called `deleteRoutine`, which deleted a favorite/library template. Added `WeeklyScheduleActions.removeScheduled` + `WorkoutRepository.removeScheduledRoutine`, wired only from HomeTab (`onRemoveScheduledRoutine`); Diary keeps `deleteRoutine` (its Apple delete semantics not audited).
- Weekday-only legacy routine (no dated copy): unassigns the weekday (previous Apple Home rule); this is my choice where Apple's new code has no equivalent.
- JVM test for the pure rule; Home wiring has no test; no device run.
- Other Apple Home changes recorded, NOT done: planned cards exclude routines already completed that day or currently active; day dot only when a completed workout/health activity exists; workouts without finishedAt excluded from day grouping; weekly streak "planned" count = dated routines in current week; layout metrics (calendar width, card min height 108).

## Update tree94: Home planned cards hide completed/active routines
- Apple `plannedRoutinesForSelectedDay` hides planned routines already completed that day (by workout routineId) and the active routine (today only). Android Home always listed them. Added `routineId` to WorkoutHistoryEntry and ActiveWorkout, and `HomePlannedFilter` (JVM tested: finished workouts on that local day only, active hidden only today). HomeTab uses it.
- Limits: finished-day uses finishedAt local date (Apple uses finishedAt for non-live sessions; live sports use startedAt - NOT mirrored here). Android still also lists weekday-only recurring routines (Apple's dated-only rule not adopted). Compose wiring has no test/pixels.
- Home still open: weekly planned-streak count, unfinished-workout day grouping, layout metrics.

## Update tree95: live-sport day + legacy weekday finding
- HomePlannedFilter: live-sport sessions now count on startedAt day (Apple `startedAt ?? finishedAt`), others on finishedAt; JVM test added (22:30Z start, 00:30Z finish).
- routineId propagation (static read): set at session start from the routine (WorkoutRepository ~1022), and by ActiveSessionFavorite/draft save to the new template id; finishing moves the whole session JSON into workouts (line ~2653), so it persists. Sports/manual/older records have no routineId -> null -> never excluded (no inferred identity). Whether Apple also rebinds routineId on "save as favorite" is not checked.
- Apple legacy weekday-only routines: `migrateLegacyWeeklyPlans` (ReperaStore, idempotent) turns each weekday routine into a DATED routine in the current week (unless that date is already occupied) and appends an independent reusable template copy (fresh block ids); the weekday is cleared; history untouched; no routine is hidden or deleted. Android has NO such migration and keeps recurring weekday display. Not changed here (no data migration, no hiding). DECISION FOR END: (A) keep Android recurring weekday behavior as is; (B) port Apple one-time migration (dated copy for current week + template, weekday cleared). Impact of B: existing weekday plans stop repeating after the migration week; future weeks show nothing until scheduled; needs a test with real-shape data first. Impact of A: Android and Apple plans diverge for synced accounts.

## Update tree96: legacy weekday migration PREPARED, NOT WIRED
- `WeeklyScheduleActions.migrateLegacyWeekly` mirrors Apple `migrateLegacyWeeklyPlans`. No caller anywhere; not activated; no real data touched. Synthetic JVM tests: dated in current week, template copy with fresh ids, weekday cleared, favorite flag moves to the template, occupied date -> weekday cleared with no dated copy and no template, history/activeSession byte-identical, idempotent.
- Reversibility: the transformation is one-way (weekday cleared). Undo would need a pre-migration state snapshot (the existing state backup path was not evaluated). Impact on Android UI if activated: DiaryTab/HomeTab recurring display (`weekday == day`) stops matching migrated routines after the migration week.
- Mondays: helper uses ISO Monday week start; Apple uses firstWeekday=2 too. `mondayFirst` parameter is unused (kept off the logic on purpose).

## Update tree97: exact branches of the (unwired) legacy migration
Apple `migrateLegacyWeeklyPlans`, per weekday-only routine `source` (read from refs/ghlive/main ReperaStore.swift ~2036-2056):
- Target date free: the ORIGINAL object (same id) becomes dated in the current week with isFavorite=false and weekday=nil; a NEW template Routine (new id, fresh block ids, source's isFavorite) is appended.
- Target date already has a dated routine: the ORIGINAL object keeps id/title/blocks/isFavorite, gets weekday=nil and NO date; no copy and no extra template. It becomes an unscheduled template; its weekday recurrence is gone.
- In both cases the weekday value itself is erased. Nothing is deleted, but the recurrence is lost. A previous weekday can be recovered ONLY from a pre-migration snapshot/backup; I did not verify that such a snapshot exists in the Android save path, and synthetic tests do not replace a real-shape export. B must not be described as lossless in behavior or reversible without a verified snapshot.
- The prepared Android function follows the same two branches (test asserts original id/title/blocks stay in the occupied branch). Still no caller, not activated.

## Update tree98: "Vaciar programación" is week-scoped (Apple clearWeeklySchedule(for:))
- CORRECTS my tree91 note ("clear not week-scoped on Apple, not verified"): Apple `clearWeeklySchedule(for weekReference)` clears only DATED routines of the visible week (favorites unscheduled and kept, others removed); other weeks, templates and sessions untouched. Android's clear only removed weekday recurrence + rotation and kept every dated routine.
- Added `WeeklyScheduleActions.clearWeek` (+ JVM tests: only that week, favorite kept as unscheduled template, other weeks/templates/history untouched), `WorkoutRepository.clearScheduledWeek(week)`, DiaryTab passes the selected day. LEGACY behavior kept: the same action still also runs the old clear (weekday recurrence + rotation, any week), so nothing legacy was dropped. Whether that legacy clear should remain is a decision tied to the A/B weekday question. Dialog text and menu visibility updated; menu shows if dated routines exist in the selected week OR weekly recurrence exists.
- Compile + JVM only; UI no test/pixels. `clearWeeklySchedule()` (old repo method) is still used by the androidTest, which was compiled, not run; that test's old expectations were not re-run.

## Update tree99: clear combination caveat + normalizedFinishedWorkout entry points (no behavior change)
Clear (point NOT closed): `clearScheduledWeek` = Apple's new week-scoped dated clear PLUS the old global clear. Verified old Apple rule (fc3ef7e1 `clearWeeklySchedule`): weekday cleared on every routine with no scheduledDate, `state.rotation = nil`, any week - identical to Android's old clear. Live main REMOVED that global effect (its clear no longer touches weekday or rotation). So the combined Android action is NOT an isolated selected-week operation and NOT closed Apple parity: clearing even a distant week wipes recurrence and rotation everywhere. JVM test now documents this. Decision tied to A/B.

normalizedFinishedWorkout (Apple, ReperaStore ~1724) - exact facts read:
- Condition: `phase == .finished || finishedAt != nil`; then sets `isCompleted = true` on EVERY exercise; creates no sets, changes no loads. Applied inside `upsertWorkout` (every save/upsert path: manual QuickLog ~1391, saveWorkout ~1473, active finish ~1526/1617-1623, imports, edits) and when appending in ~1708. So it is the saved-history normalization at write time, not only a finish step.
- `StatsEngine.confirmedWorkSets` does NOT read isCompleted: guard is `phase == .finished || finishedAt != nil`; actual non-warmup logged sets win; warmup-only -> none; otherwise prescribed values (rir nil unless set). Domain test CompletedWODMuscleStimulusTests states "Finalizar equivale a dar por hecho lo prescrito; el check manual NO es necesario".
- Android `finishInPlace` (WorkoutRepository ~2650) marks isCompleted only for exercises with loggedSets. Android domain stat engines do not read isCompleted (grep: only plan builders write it). So per-consumer stats are NOT affected by this flag; the flag differs in saved JSON (Apple all true, Android only exercises with sets), and Android finished-edit (~2401) resets isCompleted=false when all sets are removed, whereas Apple would re-set true on next upsert.
- This does not contradict the 20:41 statement (no sets created); it refines it: Apple also forces the flag on all exercises. Consumers of the flag in Android: active navigation marker (~2956), edit guard (~1852), Wear plan; Apple Watch/mirror payload consumption of isCompleted NOT verified. Nothing modified; confirmedWorkSets and editor rules untouched. Stays PENDING per consumer.

## Update tree100: consumer table for the prescribed fallback (docs only, no behavior change, 00:23 CET)
Explicit: Apple `StatsEngine.confirmedWorkSets` DOES return prescribed values for a finished session with no logged sets (not warmup-only, not unfinished). This is NOT a generic "finish accepts prescribed" decision item; it is the stats rule. It does not create LoggedSets and does not read isCompleted.
Apple consumers (grep refs/ghlive/main): MuscleBalanceCard:68, ProgressSnapshot:299/329/362, MuscleMapEngine:96/189, MuscleTaxonomy:265, StatsEngine.confirmedVolumeKg and personalRecords.
Android consumers via `WorkoutHistorySets.confirmedWorkSets`: ExerciseProgressMetrics:84, ExerciseProgressSeries:95, MuscleWorkloadMetrics:41, ProgressSnapshot:166/169/212 (feeds statsWorkouts -> StatsEngine.personalRecords/volume), MuscleMapEngine (domain, fed from the same snapshot).
Existing Android tests (ConfirmedWorkSetsTest names): finishedWithoutRecordsAcceptsPrescribedAndStatsVolumeAgrees; unfinishedNeverConfirmsAndWarmupOnlyDoesNotConfirmPrescribed; exerciseSummaryIgnoresPrescribedWhenOnlyWarmupsWereLogged; exerciseSeriesIgnoresPrescribedWhenOnlyWarmupsWereLogged; warmupOnlyAndUnfinishedContributeNoFatigue. NO dedicated test found for: personal records from a prescribed-only finished session, MuscleWorkloadMetrics (Apple MuscleLoadEngine/MuscleBalance), MuscleTaxonomy hard-only filtering. Equivalence per consumer is therefore NOT closed.
Also read (static): Apple scan import no longer merges blocks into an existing routine of the same day; Android appendScannedRoutine always appends a new routine (no merge) - consistent by reading, not tested. Apple persistWorkouts now also triggers an independent sync push after a local flush; Android equivalent trigger not audited.

## Update tree101: two more consumer tests for the prescribed fallback
- New JVM tests (ConfirmedWorkSetsPrAndWorkloadTest): personal records and weekly muscle workload (MuscleWorkloadMetrics) use prescribed values for a finished session without logged sets, give nothing for unfinished or warmup-only. These were previously untested consumers. Still NO dedicated test for taxonomy hard-only filtering and for Apple MuscleBalanceCard (Android counterpart not mapped). Equivalence per consumer remains open. (A first run failed only because my test date fell outside the week window, fixed in the test; no production change.)

## Update tree102: calorie Media/día, Periodo ant., Variación (Apple ProgressTrendCards)
- Window diff of ProgressTrendCards/ProgressChartBuilder: Apple added `caloriesDailyAverage` (average per day WITH data), `previousCaloriesDailyAverage` (previous period via `previousPeriodBounds`; null if no data or fewer data days than the current period) and three stat tiles. Android had none. Ported in domain `ProgressChartBuilder` + `CalorieAverageStats`; shown as one text line under the "Calorías activas" title (not Apple's three tiles; Compose, compile-only, no pixels).
- Tests (domain JVM): comparable previous period gives +50 %; absent or shorter previous period gives null; labels "—", "+50 %", "-10 %".
- Limits: previous-period values depend on how much Health Connect history the reader loads (not audited here; if it loads less than the previous period the value is null by the same rule). The free-tier teaser preview keeps null values (Apple's teaser uses a fictitious previous average of 500; not mirrored). Apple's weight stats now always show with "—" placeholders; Android weight card not compared. Other Apple diffs in these files are layout (chart heights, DUO grid, scroll-to-top on topic change) - not ported. HealthRecovery diff is layout/DUO sizing plus showing the recovery trend regardless of refresh key; not ported.

## Update tree103: explicitPlannedSets null vs empty (Apple live main) - NOT ACTIVE
- Apple live `RoutineBlock.plannedSets(for:)` returns `explicitPlannedSets` whenever non-nil: `[]` = user deleted every set, `nil` = derive from format. Android readers treat `[]` as derive.
- Writer audit (static read, no real data touched). Android paths that can write `[]` with "derive" intent: `EditorBlockOps.exerciseToMovement` (item without plannedSets -> `JSONArray()`), `CompletedWorkoutEditing.movementFor` (visibleSets of an entry without plannedSets), `ActiveSessionDraft.update` (writes whatever set list it gets, caller intent unknown), `WeeklyScheduleActions` copy (propagates existing value). `BoardScanImport` and `AITrainingInbox` write only non-empty (AI import rejects 0 sets). `WorkoutRepository` guards `length()>0`. Old stored data cannot be told apart from an intentional delete, so reading `[]` as deleted could make existing plans vanish.
- Decision: the tree103 read change was reverted in code (readers keep legacy `[]` = derive). A JVM test pins the legacy behavior. The Apple semantics stay an open item, to adopt only with a way to discriminate (e.g. a marker written by the new delete action) or after a data check authorized by Ramón.
- Consumers Play / Wear / rest-pause of explicit sets: NOT audited and NOT closed. explicitPlannedSets stays open for all three.
- Weight card: Apple Actual/Objetivo/Δ tiles with "-" not ported (Android text lines). Open.
- HealthMuscleMapper native-sport / unique-external / high-effort has Android counterparts; equivalence not validated.

### tree105 scope note: consumers of explicit/planned sets (static read only, nothing executed)
- Wear (`WearMainActivity` ~888) reads the session entry `plannedSets`, positional by count of work-phase logged sets; empty plan = no target. It never reads `explicitPlannedSets` of the routine. Whether the Watch gets a shorter plan after Play edits is untested (no Wear JVM tests).
- Play/session assembly: `WodSessionAssembler.plannedSets` treats `[]` as derive (legacy, consistent with the readers kept in tree104). `ActiveSessionDraft.update/removePending/editPending` operate on session `plannedSets`.
- Rest-pause: `WorkoutRepository.logRestPauseSet` exists; its interaction with an edited or shortened plan has no test.
- None of the three consumers is verified. explicitPlannedSets stays open.

### tree106: StartHub guard and SessionPreview (static read)
- Apple SessionPreview play button: with an active session it continues it, otherwise starts and opens only if a session exists. Android `startOrContinueRoutine` (ReperaMobileScreen ~262) already navigates to the active workout when one exists, else `startRoutine` (which throws "Ya existe una sesión activa" if one exists). Mapped, not executed.
- Apple StartHub planned-routine row: after `startSession(from:)` it opens the workout only if `activeSession.routineId == routine.id`. With a different active session Apple stays put; Android routes every start entry through `startOrContinueRoutine`, so it would open the other active session. Android has no separate StartHub file; the equivalent entry point was not located. Difference noted, not changed (no verified Android surface equals StartHub). Open.

### tree107: sport "Mejores marcas" (Apple LiveSportHistoryView, live main)
- Ported: `LiveSportHistory.records` (longest recorded distance, fastest recorded km split, longest active duration; only values saved for that sport, NaN/<=0 ignored) and a "Mejores marcas" card in `LiveSportHistoryScreen`; `LiveSession` now carries `liveKilometerSplitsSeconds`. Distance and best-km tiles only for GPS sports, as in Apple. JVM test added. Compose is compile-only (no pixels).
- Apple "Sincronizar ahora" in Settings: Android already has `ManualMirrorSync`; Apple's pre-flush of local persistence before sync was not compared.
- Apple ReperaApp: re-validate JWT on foreground and skip startup work when `requiresReauthentication`: Android tree89 has the refresh lock and pre-sync check; foreground re-validation and the reauth flag were not compared. Launch-screen artwork is iOS only.

### tree108: foreground JWT / reauthentication mapping (static read)
- Apple: on foreground, `ensureUsableSession()`; startup work is skipped while `requiresReauthentication`, set only on a confirmed unrecoverable auth error (not on network failure).
- Android: `MainActivity.onResume` retries verification (comment at ~1388); `syncWorkoutMirror` refreshes through `refreshedSessionBlocking` before syncing; startup side effects only after successful verification; `isUnrecoverable` exists (error_code values vs real Supabase responses not verified live). No separate persistent `requiresReauthentication` flag was found; behavior on revoked refresh token not tested. JWT refresh path still has no unit test. Open.

### tree109: Apple HealthRecovery / MuscleBalanceCard / ProgressSnapshot diff read (static)
- HealthRecovery diff is layout for the iPad DUO grid (chart heights from column width, one cell for title+chart, single Pro banner outside the grid, reserved trend cell, loading state shown only while `currentReadiness == nil`). No data logic. Not ported; no phone-width Android effect identified. The loading-state condition (`appliedRecoveryKey != refreshKey && currentReadiness == nil`) was not compared with Android. Open as layout/DUO.

### tree110: MuscleBalanceCard estimated-WOD footnote; ProgressSnapshot diff mapping
- Ported Apple `includesEstimatedWODMuscles`: `ProgressSnapshotData.includesEstimatedWodMuscles` (any in-range stimulus exercise with `completedWodSetEquivalent > 0`) and the footnote in `MuscleBalanceCard` shown only in the "all sets" mode. Apple computes it over the card's `workouts`; Android uses the range-filtered stimuli, which is the same intent but the exact Apple input set was not diffed. No dedicated JVM test for the flag (compile + existing suite only). Compose compile-only.
- ProgressSnapshot diff mapped as already present on Android: unique external activities (dropNativeOverlaps), native sport stimuli, high-effort layer. Not re-verified here: Apple now passes the whole external history to the chart (previous-period comparison) while Android filters (calorie/previous-period depends on the Health Connect history loaded); "performed" exercise filter for charts (confirmedWorkSets or mobility with reps) not compared on Android's chartExercises. Open.
- ActivityHeatmap `cellHeight` (strip cells min(cell,76)) not ported: layout. Open.

### tree111: chart exercises = practiced only (Apple ProgressSnapshot live main)
- Android listed every exercise present in a filtered session (including plan-only or warmup-only entries) and dated it by any session containing it. Now `performedForChart` (a non-warmup set with reps or duration, or mobility with reps) filters entries, and `lastEpochMillis` is the last session where it was practiced. Apple input is `StatsEngine.confirmedWorkSets`; Android uses the snapshot `StatsExercise.sets` (which already applies the prescribed fallback for finished sessions without logged sets). Equivalence of those two inputs for every case is not proven; one JVM test covers work/warmup-only/date.

### tree112: weight stat tiles (Apple ProgressTrendCards live main)
- Apple always shows Actual / Objetivo / Δ ("—" when missing; Δ = latest - goal, sign "+" only when > 0). Android now shows the same three tiles (domain `WeightStatsTiles`, JVM test with Locale.US) in both the empty and the data weight card, replacing the previous "vs objetivo / En objetivo" text line (the Android-only "En objetivo ±0.3" wording is gone). "Último" and "Cambio 30 días" lines kept. Apple's Δ color is `label2` (neutral); Android uses the default text color. Compose is compile-only. The Free teaser weight card is unchanged.
- Checked: "Deportes · evolución y récords" link and the calorie Media/día, Periodo ant., Variación line already exist on Android (calorie variation is one text line, not three tiles).

### tree113: Theme / StatsView / BusinessWorkoutSyncStore / DayOverrideSheet / RegisterSessionChrome diff reads (static)
- StatsView scroll-to-top on topic change: Android already has it (`ProgressTab` `LaunchedEffect(topic)` -> `scrollToItem(0)`).
- Theme: the top-bar insets (16/12/8) and header alignment are iOS safe-area layout, not ported. The numeric set field commits on every keystroke and on disappear because the iOS check-mark could close the screen before focus-lost: Android has no `onFocusChanged` commit path in the set fields (only `PlaceSearchSheet`), so that failure mode was not reproduced or tested; whether every Android numeric field writes on change was not audited. Open.
- BusinessWorkoutSyncStore: serialized JWT renewal before the mirror (Android tree89 `refreshedSessionBlocking`).
- DayOverrideSheet: Apple now assigns an independent copy of a template to a concrete date (no weekday check, no "Día libre" row). Android's Diary weekday entry still says "Día libre · toca para asignar" (weekday path, legacy kept pending the A/B decision); the date-based assign sheet on Android was not re-compared. Open.
- RegisterSessionChrome `WorkoutSummaryTile`: not audited on Android.

### tree114: numeric set fields (static read, correction of the tree113 open note)
- Android Play fields (`ReperaCards.kt` ~233-410, 620-652) are local Compose state (`pendingReps`, `pendingWeight`, `editingDuration`, ...) consumed by the explicit log/save buttons, not model-bound cells with a focus-lost commit. Apple's failure (check closing the screen before focus-lost) needs bound grid cells; this path does not exist on Android as written. No data-loss path found statically; not reproduced or tested on a device, and the draft-recovery behavior when the screen is left with an uncommitted field was not audited. Stays on the open list as "not audited", not as a discrepancy.

### tree115: HistoryView diff, second slice (static read, ~170 filtered lines)
- Fullscreen map (route and location pin, "Ampliar recorrido/ubicación", water-sport map flag): presentation, not ported (already listed).
- Apple merges "Parciales" and "Entreno" into one embedded card. `CardioSplitsView` now also receives `totalActiveSeconds`, `totalDistanceMeters`, `maxSpeedKmh`, `healthStats`, `sport`, and is shown when route >= 2 points OR km splits exist OR (live sport with recorded distance > 0 and duration > 0) OR movement data. Android (`ReperaCards.kt` ~1498-1520) shows the route section only with >= 2 points, the live-km splits section from `liveKilometerSplitsSeconds`, the movement/sport rows separately, and the `RouteUnavailableNotice`. Android has no combined totals header (total distance, total time, max speed) inside the splits card; the recorded max-speed source is still not wired. Open, needs a deliberate UI port (not started).
- Apple notice text for a recovered distance without GPS points ("los puntos GPS no viajan por Supabase") vs Android `RouteUnavailableNotice` wording not compared line by line.

### tree116: CORRECTION of tree115 (read CardioSplitsView in full)
- tree115 wrongly said Android has no totals header. `SessionSportMetricRow` already renders Vel. media / Vel. máx / (Distancia or Ritmo medio) from the same inputs as Apple (`SessionSportMetrics.tiles`: average speed = meters / active seconds * 3.6, pace, max speed from route `speedMps` finite, > 0, <= 50 when no explicit max).
- Real remaining difference: Apple passes `extras.maxSpeedKmh` (Health-recorded max) as `maxSpeedKmh`; Android passes `null`, so max speed comes only from route points. Steps tile and the no-GPS branch (steps / distance / avg HR from health extras) exist as `SessionMovementSection`/rows, not compared field by field. Apple embeds all of it in one card with the splits table (layout only).

### tree117: recorded max-speed source needs a permission decision
- Apple derives `maxSpeedKmh` from HealthKit speed samples of the workout (`speeds.max * 3.6`). The Android equivalent would read Health Connect speed data (a new read permission, Play Health declaration and data-safety form). No such reader or permission exists in `mobile/src/main`. Adding it changes shipped permissions, so it is NOT done locally; it joins the existing decision about `READ_DISTANCE` and the Play Health forms. Until then max speed uses route points only (domain `SessionSportMetrics.maxSpeedKmh(recordedKmh=null, points)`).

### tree118: Play / Health Connect requirement check (docs read 27 Oct 2026; nothing changed)
- Official docs read: developer.android.com/health-and-fitness/health-connect/publish (Data safety section + Health apps declaration form on the Play Console "App content" page, required for every publishing request, new or update, when the data types change; request only types that back a user-facing feature; privacy policy on the store page matching the one Health Connect links), support.google.com/googleplay/android-developer/answer/12991134 (health permissions guidance: minimum access, consent/prominent disclosure, accurate listing), developer.android.com/health-and-fitness/health-connect/data-types and reference/android/health/connect/HealthPermissions (both `READ_DISTANCE` and `READ_SPEED` exist as separate permissions).
- What this app actually declares (mobile manifest, code evidence): READ_HEALTH_DATA_HISTORY, STEPS, DISTANCE, HEART_RATE, EXERCISE (+WRITE), RESPIRATORY_RATE, OXYGEN_SATURATION, ACTIVE_CALORIES_BURNED, SLEEP, SKIN_TEMPERATURE, MENSTRUATION, OVULATION_TEST, HEART_RATE_VARIABILITY, RESTING_HEART_RATE, WEIGHT (+WRITE). Wear manifest: READ_HEART_RATE, FOREGROUND_SERVICE_HEALTH. No READ_SPEED.
- NOT verified: the current Play Console Health apps form and Data safety answers (no Console access from here), whether READ_DISTANCE is already covered, whether the menstruation/ovulation reads (declared in the manifest) have a justified user-facing feature. A new permission (READ_DISTANCE shipped, READ_SPEED proposed) means the declaration must be updated before release; I state this from the docs, not from the Console state. Sensitive reproductive-health types in the manifest deserve the owner's review against "request the minimum".

### tree119: menstruation / ovulation read audit (code only; no personal data read, nothing changed)
- Correction of the tree118 wording: this IS a user-facing feature on both platforms, not an orphan permission. Android: opt-in switch "Seguimiento del ciclo" (`PermissionSettingsSection`, `PrivateRecoverySettings.setCycle`, decision stored on-device only, default off, text "No se lee hasta que lo actives"); the three read permissions enter `requestedPermissions()` ONLY when `cycleEnabled()`; `HealthConnectReader` reads 230 days only under the same gate and permission grant; `MainActivity` drops the values when the choice or revision changes (~784, ~1582) and clears them in memory when disabled; surfaces: `CycleHistoryCard` in Recovery history, `HomeRecoveryModel.cycleLabel`. Values live in in-memory `RecoveryState`; grep found no path from them into the mirror, AI context or sync stores in `mobile/src/main`. Apple (`HealthRecovery.swift`): same shape (cycleEnabled/cycleDecisionMade, `setCycle` requests authorization only when enabled, `declineCycle` and disable clear the arrays, 230-day window, "Menstruación registrada" card and advice text).
- Manifest declares the permissions statically (needed for Health Connect to offer them); the request is gated. Minor Android nuance: `hasReadablePermission` counts a granted menstruation/ovulation permission as "readable" like the others; not changed.
- Therefore no user decision is needed to keep or remove it. What remains is the Play Health apps form / Data safety: it must describe these reads as an opt-in cycle-tracking feature. The current state of those Console forms for this app is NOT verified (no Console access); left pending, no credential request created.
- READ_DISTANCE: whether an existing declaration already covers it is unknown; READ_SPEED (not added) would need the types/forms review before any release.

### tree120: Plan week label returns to the current week
- Apple PlanView `weekSelector`: tapping the week label sets `weekOffset = 0`. Android `WeekCalendarStrip` gets an optional `returnToDay`; DiaryTab passes today, so tapping the date-range label selects today (current week). Home does not pass it (no change there). Android selects a day, Apple selects an offset, so the selected day inside the current week is today rather than Monday. Compose compile-only, no test. Apple's "Vaciar programación" visibility rule (shown only when the selected week has scheduled routines) already matches the DiaryTab condition (weekly or dated in that week).

### tree121: CORRECTION of tree120 (visibility of "Vaciar programación")
- Verified current Android condition (`DiaryTab` ~210): the item shows when `weekly.isNotEmpty()` (legacy weekday recurrences, independent of the selected week) OR a dated routine falls in the selected week. Apple (`scheduledRoutines(inWeekContaining:)`, ReperaStore ~2059) counts ONLY routines with a `scheduledDate` inside the selected week; weekday-only routines never count.
- So it does NOT match Apple: with only weekday routines, or in a distant week with no dated routines, Android shows the item and Apple hides it. This is the known legacy behavior (the combined clear also clears weekday and rotation globally); kept on purpose and listed as a divergence tied to the A/B decision, not as parity. My tree120 sentence saying it matches was wrong.
- The label tap (tree120) is compile-only: no visual or behavior validation (no device, no test).

### tree122: assign-by-date vs Android weekday assign (static read, no change)
- Apple `assignRoutine(_:toDate:)` creates an INDEPENDENT copy of the template (new id, `scheduledDate` = the day, blocks duplicated, `isFavorite=false`); the old weekday API now maps to a date in the current diary week. Several independent sessions can share a date (`scheduledRoutines(on:)` sorts by time, title, id).
- Android Diary "Tu programación" assign dialog (`DiaryTab` ~254) calls `onEditRoutine(... RoutineSchedule(weekday=...))`, i.e. it sets the weekday on the template itself (recurring, mutates the template, no copy). That is the legacy path kept pending the weekday A/B decision; no date-based copy assign exists on that screen. `DayPlusSheet` favorites/create paths were not traced end to end here.
- Android `importAiRoutine` refuses when another plan already exists on the same date ("Ya existe un entreno para ese día"); Apple allows several sessions per date. Whether that guard is intentional (AI import specific) was not determined. Both items stay open; nothing changed.

### tree123: QuickLogSheet diff remainder (static read)
- The Apple diff is a presentation/input rework: ScrollView/cards -> inset `List` sections, swipe-to-delete per set row (accessibility label "Eliminar serie N"), header with number + "Serie", metrics stacked, steppers (±weight step from `weightIncrementKg`, ±5 s, ±quantity step) replaced by the keyboard numeric field, the guidance block removed. Data limits (deficit 60, load 1500, duration 86 400, quantity cap) match the earlier cap audit (1500/60 equal on Android). Not re-verified: the replacement field's clamping and the removal of the `weightIncrementKg` step in Apple's new input vs Android steppers. Android keeps its own set rows; not ported (layout/input). QuickLog stays on the open list for those two points.

### tree124: QuickLog Android vs Apple new input (static read of QuickLogSheet.kt / QuickLogRows.kt)
- Android QuickLog already uses numeric text fields (no steppers), so the Apple removal of steppers/`weightIncrementKg` step has no Android counterpart to change. Android has a per-row "Eliminar serie N" button and the note switch; Apple uses swipe-to-delete (gesture difference, not ported).
- Real difference: Apple clamps typed values on input (`parseInt(cap:)`: deficit 60, quantity cap; weight rounded to 2 decimals and clamped 0..1500). Android keeps the typed value and `QuickLogRows.validate` rejects out-of-range (weight 0..1500, deficit 0..60) on Save with an error message; blank/invalid number becomes -1/NaN and is rejected too. Outcome: Apple silently saves the capped value, Android refuses to save and shows an error. No data is corrupted either way; which behavior is wanted is not settled by evidence, so no change. Quantity cap and duration (86 400) rejection on Android not re-checked here. Compile/JVM: no code changed.

### tree125: LibraryView diff (162 lines, fully read, static)
- Presentation only: iPhone Ejercicios uses a custom header (title + filter + plus on one row, search field under it, `safeAreaInset`), DUO shares it, WODs/Deportes keep the native toolbar; selected exercise row in the DUO list gets an accent background with rounded first/last corners and `onAccent` text colors. No filter, sort, search or data logic changed. Not ported (layout/selection styling). Android actions "Filtrar y ordenar" and "Nuevo ejercicio" were not re-compared here. Library diff: closed as read, with no concrete functional discrepancy found.

### tree126: QuickLog typed input now clamps like Apple (code, JVM-tested)
- Supersedes the "no change" note in tree124. `QuickLogInput` (QuickLogRows.kt) maps typed text to the model like Apple `parseInt(cap:)`/`roundWeight`: quantity 0..cap by mode (100 000 / 999 / 99 / 50, same as Apple `quantityCap`), deficit 0..60, duration 0..86 400, blank or non-numeric = 0, comma or point decimal, weight rounded to 2 decimals and capped at 1500. The text field keeps what the user typed (intermediate states: empty, trailing decimal), only the model value is clamped. Existing drafts, stored rows and `QuickLogRows.validate` are unchanged (old invalid drafts still restore); nothing is rewritten on open.
- Known small differences: weight <= 0 or blank becomes `null` (Apple stores no weight when <= 0, same outcome); deficit 0 stays 0 on Android (Apple saves nil when 0; not checked how the Android save consumer treats 0). Swipe delete is not ported (button instead). Compose field behavior is compile-only; the helper has JVM tests.

### tree127: QuickLog save consumer check (static read of WorkoutRepository.logQuickSets, line ~1038)
- The save consumer writes `weightKg` and `deficitCm` only when > 0 (`takeIf { it > 0 }`), also for the planned set. So Android deficit 0 and weight null/0 are stored as no value, the same outcome as Apple's nil when <= 0. That closes the "deficit 0 vs nil" point from tree126. Not covered by a dedicated JVM test of `logQuickSets` (read only).

### tree128: Theme.swift diff (static) and Play editable rows assessment
- Theme: new top-bar metrics (`topBarHorizontalInset` 16, `topBarTopInset` 12, `topBarBottomInset` 8, header HStack aligned `.top`, trailing controls spaced 16), a global 12 pt top margin before charts, and the int stepper field now updates its binding while typing (not only on blur) and commits on disappear, clamped to the range. Layout metrics: not ported (iOS safe-area specific). The live-update/commit-on-disappear rule has no direct Android counterpart checked here; Android QuickLog/Play fields keep typed text and read it on explicit save buttons (see tree113/114).
- Play editable rows (WorkoutView diff, read fully): Apple removed the per-set confirmation check; rows are editable result rows where typing saves (`persistActiveLiveDraft` after the first edit of an exercise, suggestions are not saved until edited via `editedLiveExerciseIDs`), delete by swipe removes planned and recorded set by id (`removeLiveSet`), edits to unit/RIR/duration/deficit/weight are written as planned sets plus performed sets by id (`updateActiveExerciseDraft`), absolute kg edits drop the percent prescription, and applying an edited routine from the editor resets the live drafts and refreshes the session plan. Android today: recorded sets are logged on confirm with prefilled values; recorded sets can be edited/deleted and pending sets edited (reps, kg) or removed through explicit buttons (ReperaCards). Repository `updateActiveExerciseDraft`/`editPendingSet`/`removePendingSet` exist; the planned-sets half is JVM tested (tree~), the performed-sets half is not wired. Porting the no-confirmation model changes the core Play interaction on Android and cannot be validated visually here, so it is NOT started; it stays open.

### tree129: Play editable rows, data half (code, JVM-tested; UI not wired yet)
- `ActiveSessionDraft.recorded` (Apple `persistActiveLiveDraft` recorded part): rows with reps > 0 become results with no per-set check, a row matching an existing straight work set keeps its id and completedAt, new rows get a fresh straight work set, rows removed by the user drop their result, rows at 0 reps record nothing. Warmup sets and non-straight sets (dropset, rest-pause, clusters) are kept untouched in place (Android safeguard; Apple rows do not hold them). Weight/deficit stored only when > 0; duration only for duration modes; RIR/toFailure only for strength modes.
- `WorkoutRepository.persistLiveRows(rows, quantityUnit)` (internal) combines `revise` + `recorded` + `update` + `replaceRecordedSets` in one save for the current non-WOD exercise. Compiled only: it needs the Android file store, no JVM test of this method.
- JVM: `ActiveSessionDraftRecordedTest` 6 tests; observed XML mobile 427 tests / 0 failures / 0 errors (domain not re-run, unchanged).
- Not done yet: Play UI rows (summaries lack duration/RIR/deficit for pending sets), "edited exercise" gate so untouched suggestions are not saved, swipe delete, WOD rows, routine-editor apply resetting live drafts, `unit` picker edit.

### tree130: Play editable rows, UI wired (compile-only UI; data/pure parts JVM-tested)
- `ActiveWorkout.liveRows` (computed in `liveRowsOf`): recorded straight work sets (completed rows) + pending planned sets; null (classic form stays) for WOD, no basic recorder, or when any logged work set is not straight (rows are matched to planned sets by position). `quantityCap` per input mode.
- `LiveSetRows` (new): per-row fields reps/kg or deficit/duration/RIR(RPE), unit chips for cardio toggle, "Eliminar serie N" button, "Añadir serie". No per-set check. Rows start as the prescription; NOTHING is handed over until the user edits a row (`edited` gate), so untouched suggestions are never recorded. After the first edit every change hands the newest rows over at once (`LocalPersistLiveRows`).
- Activity: the newest rows are held in memory immediately (`pendingLiveRef`), saved ~600 ms later without taking the `busy` lock (typing keeps focus), and `runWorkoutAction` saves any waiting rows first, so "Siguiente", "Finalizar" or a classic-form set never lose the last edit. `persistLiveRows(sessionId, exerciseIndex, ...)` applies rows to that exercise of that session only (never to whatever is current after navigation); if the session ended or changed it does nothing.
- Classic form kept behind a chip "Calentamiento o técnica (dropset, rest-pause)"; warmups/technique sets are not rows and are preserved by `recorded`. The old pending-set edit block is hidden when rows are shown.
- JVM: `LiveRowEditTest` (clamping, effort, draft rows) + tree129 tests; observed XML mobile 430 tests / 0 failures / 0 errors. NOT covered by any test: `persistLiveRows` and `liveRowsOf` (need the Android file store), the debounce/ordering in MainActivity, the Compose UI (compile-only, no device or emulator available).
- Known limits: if Wear logs a set while the rows are open, the Android rows do not reseed and the next edit would drop that set (not reproduced; rows only know their own list). Swipe delete is a button. WOD rows, `removeLiveSet` for results/WOD and applying an edited routine from the editor (reset of live drafts) are NOT ported. Rest timer start after a set (Apple removed `completeLiveSet` rest start) not compared.

### tree131: Play rows: target guard and external-set reconciliation (pure rules, JVM-tested)
- The guard logic moved out of the repository into `ActiveSessionDraft.applyRows(state, sessionId, exerciseIndex, rows, ...)`: rows only apply to the session id and exercise index they were edited on; after navigation they still go to their own exercise, and a finished/different session or bad index returns null with the state untouched; WOD is rejected. `persistLiveRows` is now a thin wrapper (compile-only, needs the file store).
- `LiveRowEdit.reconcile`: a result recorded outside the open rows (Wear, classic form) is added as a completed row before the pending ones, ids already known (including ones the user deleted) are never re-added, local edits are not replaced. The test shows the failure it prevents: with stale rows, `recorded` drops a set logged elsewhere (`w1`); with the reconciled rows it is kept.
- JVM: `ActiveSessionDraftApplyRowsTest` 5 tests; observed XML mobile 435 tests / 0 failures / 0 errors.
- NOT proven: that the ordering/debounce in MainActivity never loses an edit (compile-only, not exercised under real interleaving), that a set deleted on Wear while rows are open is handled (reconcile only adds), or any Compose behavior. Do not read this as a no-loss guarantee.

### tree132: LiveActivityView / HistoryView route diffs (code, JVM-tested; map rendering compile-only)
- Spoken turn guidance now follows Apple live main: "Ahora, <dir>." within 20 m, else "En unos N metros, <dir>.", with <dir> = "gira a la derecha" / "gira a la izquierda" / "cambia de sentido" (> 145 degrees). Display text unchanged. `LiveSpokenPhrases.turn`, `Turn.spokenDirection`.
- `LiveSport.isWaterSport` (Apple list of 8). Saved-route speed gradient changed from the old 3-stop to Apple's 4-stop `speedColor` (HistoryView), with a greener slow stop for water sports; `RouteMapModel.speedColor(..., water)` and `segments(points, water)`; `RouteMapView(waterSport=)` is passed by the live screen and by both saved-route detail callers (history card, exercise detail). Old test expectations replaced by the new stops (computed from Apple's constants).
- NOT ported: the live-recorder trace gradient (`traceColor`, blue slow stop) because Android has no equivalent live trace color function (not searched beyond RouteMapModel); fullscreen route "Ampliar recorrido"; double-save guard `isSavingRecordedActivity` (Android save path not compared); background notification rule (voice on = no notification) and "do not deactivate audio while another utterance speaks" (Android speech/notification behavior not compared).

## tree133 - LiveActivity: notification fallback and save guard (static read)
- Turn cues in `LiveActivityRuntime`: with voice on, Android no longer sends a notification when speech fails (Apple notifies only with voice off). Changed; compile-only, no JVM test (needs Context). Kilometer cues were already voice-only.
- Save guard: `saveLiveActivity` is `@Synchronized` and idempotent by `gpsSessionID`. Read statically as equivalent to Apple's `isSavingRecordedActivity`. Not tested.
- Open: audio-focus deactivation while another utterance speaks (`LiveSpokenGuidance.kt` not compared), live trace gradient, fullscreen route.

## tree134 - audio focus release (static read)
Apple now deactivates guidance audio after an utterance only if the synthesizer is not speaking. Android `LiveSpokenGuidance.finishOne` abandons audio focus only when `pending == 0`, so it reads as equivalent. Static read only, no test, no ear check.

## tree135 - live trace gradient (static read)
Apple `traceColor(fraction, water)` uses the same 4 stops as the saved-route gradient (tree132). Android draws the live trace through `RouteMapView`, which already uses the 4-stop `speedColor(..., water)`, JVM-tested in `RouteMapModelTest`. Not compared: Apple quantizes the live trace into 6 speed buckets (`bucket / 5`); Android's bucketing was not checked. Fullscreen live route ("Ampliar") still not ported.

## tree136 - manual sync flushes pending Play rows
Apple calls `persistAndFlush` before "Sincronizar ahora". Android's workout store writes on each action, but Play rows waiting in the 600 ms debounce were not saved before a manual mirror sync. `syncWorkoutMirrorNow` now saves them first. Compile-only (MainActivity, needs the file store); no JVM test, no concurrency claim. The persistent `requiresReauthentication` flag check on foreground is still not ported or verified.

## tree137 - CardioRouteComponents diff (read, static)
- Already ported earlier (consumer exists, equivalence not validated): Mín/Media/Máx range tiles with "—" (`SessionRangeTiles`), sport metric tiles (`SessionSportMetricRow`), steps/distance/average-HR tiles, the splits table columns (`LiveSportHistoryScreens`).
- Layout only, not ported: chart height 145 to 170, tile height 72, tile background.
- Open, not decided: Apple removed the ascent/descent line (`+N m` / `−N m`) under one chart. Android shows "Desnivel +x m / −y m" in `ReperaCards.kt` (~1710) and "↑ N m" in the profile header. I did not map which Apple card that line belonged to, so I changed nothing.
- Splits: Apple shows the cycling column as `3600/seconds` km/h and the others as `clock/km`. Not compared to Android's formatting.

## tree138 - HealthKitStore diff (read, static)
- Movement metrics (steps, distance by type, "en horario" label, mixed sessions pick the larger measured modality, no water-sport walking distance): already ported earlier as the Health Connect movement reader and `SessionSportMetrics`. Consumer exists; equivalence not validated against Apple.
- Apple (new): a persisted workout link wins and is fetched by id, so after the user edits the session time a linked workout is NOT replaced by a different workout that overlaps the new time (returns nil instead). A verified Watch workout for the session id beats an empty iPhone record. Overlap search runs only when no link is persisted.
- Android differs, concrete and not fixed yet: `HealthConnectReader.matchedSession` reads candidates by the (possibly edited) session window, then `SessionHealthMatcher.validStoredLink`. If the linked record is outside that window, or fails the overlap thresholds, the link is dropped and window matching can pick another external record. Closing it needs a read by record id (`readRecord`, compile-only) plus a pure rule "stored link present and not valid = no association" with JVM tests. Not done in this step. The Watch-vs-iPhone preference has no Android analogue (no Watch HKWorkout).

## tree139 - persisted Health link read by id (fix of the tree138 difference)
- Domain `SessionHealthMatcher.resolveStoredLink` with `LinkLookup` (Found / Gone / Unreadable) and `LinkResolution` (Use / FallBackToWindow / KeepLinkUnresolved). JVM-executed: `SessionHealthLinkTest` now 15 tests (4 new). They prove the rules only: a found persisted record is used even outside an edited window; Unreadable never reassociates or reads another record; only a verified Gone, no stored link, or another session's own record falls back to window matching.
- `HealthConnectReader.matchedSession` now calls `lookupLinkedRecord` (`readRecord` by id) first. Compile-only; depends on real Health Connect, not run.
- Limit: the Health Connect error that means "record does not exist" was not verified, so the reader only returns Found or Unreadable. A record deleted in Health Connect therefore leaves the session with no association (no reassociation, link not erased) instead of falling back to window matching. A verified not-found signal on a device would be needed to produce Gone.
- `validStoredLink` is no longer used in production code; still covered by its older tests.

## tree140 - Play "Editar entreno" and live drafts (static read plus one change)
- Apple (new): persists the live draft before opening the editor and before finishing; opens the editor on `session.routineBlocks` (newer than the template); applying the editor resets live drafts, saves the template only if it exists, and refreshes the plan.
- Android: `activeRoutineForEditing` used the template blocks when a template existed. It now uses the session's `routineBlocks` when present (copy, nothing saved). Compile-only, no JVM test (needs the file store).
- Android applies edits through `runWorkoutAction`, which saves pending Play rows first, then `updateActiveSessionPlan` (writes the template if it exists, `ActiveSessionPlan.refresh` keeps logged sets by item id). By static read this covers the save-first and reset/refresh behavior. The editor can still open with rows inside the 600 ms debounce not yet saved; the editor shows the plan, not the typed values. Not tested.
- Not compared: Apple's `editedLiveExerciseIDs` rule (unedited suggestions stay unregistered) against the Android rows path. Android keeps unregistered suggestions unregistered by design (tree129/130), but no test shows the same behavior after an editor apply.

## tree141 - Play rebuild/removeLiveSet (static read, no code change)
- Apple `rebuildLiveSets`: row count is now `max(planned, logged, retained)` with no forced minimum of 1. Android `liveRowsOf` also adds no minimum row (match by static read).
- Apple builds a row from each logged set with `completed: false`, and `removeLiveSet` / every edit call `noteLiveDraftEdited`, which persists the exercise draft and replaces results by id. Android builds recorded rows with `completed = true`. I have NOT verified that the Android rows let the user edit or delete such a done row the way Apple does, or what the check/uncheck state means after tree130. Open until `LiveSetRows` is read for that.
- Notes: Apple saves the notes draft before finishing. Android notes use a dialog with an explicit confirm button, so there is no uncommitted text at finish (different UI model, no gap found).
- Still not ported: WOD rows, `removeLiveSet` for results/WOD.

## tree142 - done rows are editable (static read of LiveSetRows, closes the tree141 question)
`LiveSetRows` shows every row (recorded or pending) with the same editable fields and an "Eliminar serie" button; `completed` is never used to disable a field or hide delete. By static read this matches Apple's all-rows-editable model. Deleting a row removes it from the saved results by id through `ActiveSessionDraft.recorded` (JVM-tested rule, `ActiveSessionDraftRecordedTest`). The Compose layer is compile-only, not run. Apple's `removeLiveSet` for WOD/results of non-row exercises is still not ported.

## tree143 - PlanView diff (read, static) and copy-week texts
- Week navigator, week-scoped copy/clear, per-date assign: already covered in tree120-122 (open items unchanged: weekday-only recurring, date-copy assign, several sessions per date).
- `copyPreviousWeek`: the Android rule matches Apple's by static read (sources from the previous week, occupied days snapshot taken before copying, fresh ids, no favorite). JVM tests exist for it (`WeeklyScheduleActions`); I did not re-read them for the new texts.
- Changed (text only): menu "Copiar semana pasada" is now "Copiar semana anterior", and the two result messages use Apple's new wording. The androidTest was updated to the new label; not run (no device). Apple's new clear confirmation says only this week is cleared; Android's combined clear still also clears weekday/rotation globally, so that text was NOT ported (documented divergence).
- Apple's day rows now always show "añadir otra" and list several sessions per date; Android's Diary day card still assigns one weekday template. Not ported.

## tree144 - HomeView remainder (static read, no code change)
- Unfinished-workout day grouping (open Home point): Apple now groups only finished sessions plus Health records by day and no longer marks days of unfinished sessions. Android `dayWorkoutCounts` (MainActivity ~2376) counts finished stats plus external Health activities only. Matches by static read; not tested; the live-sport startedAt/finishedAt day difference stays separate.
- Plan dot / planned streak: Apple reads only dated routines (`scheduledRoutines`), the weekday branch is gone. Android `WeeklyWorkoutProgress.days` still counts weekday-only routines as planned. This is the weekday A/B decision; unchanged. The planned-streak count (Apple: dated routines in the current week) was not re-checked on Android.
- Apple's selected day shows several planned sessions (excluding done and the active one) and the empty card only when there is nothing at all; Android Home day cards not compared line by line. Layout metrics (`singleWorkoutMinHeight` 100 to 108, icons) not ported.
- Remaining Home points all stay open: planned-streak count, layout metrics, day dot (static), weekday-only listing.

## tree145 - Apple contract tests (2 of ~10 read) and date-assign rule
- Read: `tests/test_multi_session_and_sync_contract.py` and `tests/test_diary_week_scope_contract.py` (assertions only). Unread: topbar alignment, login/comenzar progress, finished workout all metrics, split selection metrics, autosaved series progress, summary/home/calendar, quicklog metrics, plus the Apple Swift domain tests.
- Static checks against Android from the multi-session contract: all 16 sports named there exist in `LiveSport` (name only, behavior not checked); Android adds no "at least one planned set" guard (Apple removed it) and strength `plannedSets = []` stays `[]` (explicit-`[]` question only concerns WOD movements, which the rows path excludes); independent dated routines, `removeScheduled` and week-scoped `clearWeek` already exist.
- Not blocked by the weekday A/B decision: showing several dated sessions per date and "añadir otra" (date-copy assign) can be built without migrating data or changing any recurrence, because it only adds dated copies. Added the rule `WeeklyScheduleActions.assignTemplateToDate` (independent copy, fresh ids, no weekday, not favorite, template/weekday routines/rotation untouched). JVM-executed: `WeeklyScheduleActionsTest` 14 tests (1 new), mobile total 437 / 0 failures / 0 errors. No caller yet: no repository method, no UI. Not wired, not user-visible.
- Still needed for this item: repository wrapper, Diary day listing of dated sessions (Apple lists every session of the date and removes by id), assign dialog by date. Compose will be compile-only.

## tree146 - Diary: dated sessions per date and "añadir otro" (no migration, no recurrence change)
- New: `DiaryCatalog.datedOn` (every dated session of a date, ordered by time, title, id), `WorkoutRepository.assignRoutineToDate` (wraps the tree145 rule), callback `onAssignRoutineToDate`, and in the Diary "Tu programación" each weekday row now lists the dated sessions of that date in the week of the selected day (Monday-based, as clear/copy), each with "Quitar de <fecha>" (existing `removeScheduledRoutine`) and "＋ Añadir otro entreno el <fecha>" opening a template picker.
- JVM-executed: `DiaryCatalogTest` (new datedOn test) and `WeeklyScheduleActionsTest` (tree145). Compose and wiring are compile-only: not run, not visually validated; the androidTests were not updated for the new rows.
- Unchanged by design: the weekday recurring routine of each row, rotation, and the weekday assign dialog ("toca para asignar" still sets the recurring weekday). Apple's Diary no longer has the weekday assign, so this screen now shows both models; whether to remove the weekday assign is the weekday A/B product decision, untouched.
- Not ported: Apple's week navigator in the Diary day rows is the existing week strip; the DatePicker "Fecha programada" in the routine editor is not ported (tied to how weekday assign ends).

## tree147: repeated occurrences and WOD prescribed in exercise progress (Apple contract tests, live main)
Read (static): `CompletedWODMuscleStimulusTests.testFinishedInputValuesCountAcrossEveryOccurrenceOfSameExercise` and `testFinishedInputsPreserveEnteredRIRWithoutChecks`; Apple `StatsEngine.effectiveWorkSets/confirmedWorkSets` has no WOD exclusion (commit 5b8b04a7 "every workout block").
Reproduced by reading Android: `ExerciseProgressSeries.compute` emitted one point per occurrence (two points for a repeated exercise) and `effectiveWorkSets` excluded `blockKind == wod`.
Changed: exercise summary and series opt in (`includeWodPrescribed = true`), series merges all occurrences of the exercise in a session into one point. Muscle load and `displayLines` keep the WOD exclusion (no double count with `completedWodSetEquivalent`).
JVM (mobile 441 / 0 failures / 0 errors): `RepeatedOccurrenceProgressTest` (3 tests: summary, series TOTAL_QUANTITY=12 and TOP_SET=60 as one point, display unchanged).
Open / not changed: `ExerciseSessionAppearance` and `ExerciseLoadGuide` still use `effectiveWorkSets` without WOD (Apple snapshot expects 4 set lines); old instrumented test `scoreOnlyWodIsNotAnExerciseVisit` encodes the pre-change behavior and was not run or updated; Apple's `personalRecords`/`totalSets` per consumer not compared; `isCompleted` at upsert differs (stats do not read it). Contract tests `split_selection` (layout only) and `autosaved_series` (already ported, tree129/131) need no code change by this read.

## tree148: Apple contract tests workout_summary_home_calendar and quicklog_metrics_music_removal (read, live main)
Static read of the Python assertions plus targeted greps of Android sources. No code change, no execution.
- Movement ("Pasos en horario"/"Dist. en horario", measured steps/distance for all workouts): Android has the feature (`SessionMovementSection`, domain `SessionMovement`, fail-closed on multiple origins) but with different wording ("Pasos", "Distancia", plus a note when `usesTimeWindow`). Labels are not equal to Apple's; whether to rename is a text-parity item, not validated. Apple's `workout.statistics(for:)` / `predicateForObjects(from:)` have no Android equivalent by construction (Health Connect aggregates by origin and time range); equivalence not validated.
- Splits/metrics template: Android has "Ritmo medio", "Vel. media", "Vel. máx", "Recorrido no disponible" in `SessionSportMetricRow`; "Parciales" still exists in `LiveSportHistoryScreens` (Apple removed it for "Entreno", already an open item). "Pulso medio" present. "Distancia a pie" label absent. Whether Android avoids GPS for padel/tennis (`usesGPS`) was not re-checked in this pass.
- Home initial scroll (yesterday first, today second) is a property of Apple's horizontally scrolling calendar; Android Home uses a `WeekCalendarStrip` of the selected week (no scroll position to match). Structural difference, left open with the other Home points.
- Home chip height 24, green strength icon, swipe layout: layout-only, not ported, not compared in code.
- QuickLog contract: `OGSwipeDeleteButton` swipe delete and "Serie" header cells; swipe-delete already on the open list. Music removal: Android has no MediaPlayer/now-playing code to remove (not grepped for permissions in this pass).
Nothing here is closed; all items stay on the open list.

## tree149: Apple SessionControllerTests (+262 lines vs fc3ef7e1) mapped to Android (read only)
Apple tests added: editedPlaySetsPersistAfterFinish, autosaveRecordedSetEditsWithoutChecksAndKeepIDs, repeatedExerciseEditsRemainAttachedToCorrectOccurrence, editedWODMovementSnapshotPreservesBlockScore, draftNeverReplacesConfirmedLoggedSets, livePlayEditsMoreOrFewerSets..., repeatedExerciseEditTargetsOnlyCorrectOccurrence, scannedRFTMovementRetainsEditedSetsWithOriginalScore.
Android counterparts found by reading `ActiveSessionDraft.update/replaceRecordedSets` and `ActiveSessionDraftTest`/`CompletedWorkoutEditingTest`: occurrence targeting by item id with occurrence fallback (JVM tests exist: ids i1/i2, legacy, m1), `explicitPlannedSets` for WOD movements (JVM), recorded sets replaced separately from plan (tree129/131), `wodRestAndGlobalScoreSurviveEditing` and `scoreEditUpdatesRftTimeWithLimitsAndKeepsOtherFormatResult` (JVM). Not found and not verified: a test equal to "draftNeverReplacesConfirmedLoggedSets" (Apple) and the scanned-RFT edited-sets-with-score case on the live path; the comparison is by name and code reading, not by running Apple's assertions. Open, not closed.

## tree150: draftNeverReplacesConfirmedLoggedSets counterpart
Apple test read (`SessionControllerTests.testDraftNeverReplacesConfirmedLoggedSets`). Android `ActiveSessionDraft.update` was already shown not to drop logged sets by count; added `draftEditNeverRewritesRecordedSetsContent` (JVM) asserting identical loggedSets JSON and a 3-set plan after a plan edit. Pure rule on JSON; the Play UI path through `updateActiveExerciseDraft` is not covered by this test.

## tree151: CompletedWorkoutEditingTests (+414 lines vs fc3ef7e1) mapped to Android
Apple tests added (11): allGlobalWODFormatsAllowEditing..., editingRFTTimePreservesOtherBlockResultsAndHealthData, legacyAMRAPSingleSet..., changingWODFormatRetainsPreviousRecordedScore, playExtraPendingSetsSurviveFinish..., completedSetEditAndNewPendingSetDoNotFabricateResult, removingRecordedSetFromCompletedEditorDoesNotTurnPendingIntoPerformed, mixedScannedBlocks..., legacyScannedScoreRecoversMissingBlockFormat..., untypedLegacyRepsSurviveChangingToElapsedTime, formatChangesDoNotErasePreviousRecordedScores...
Android JVM counterparts by name/reading (existing): wodRestAndGlobalScoreSurviveEditing, changingWodFormatKeepsRealResultWithItsOwnFormat, missingBlockFormatIsRecoveredFromRecordedResult, legacyAmrapSingleSetScoreIsInferredForDisplayOnly, scoreEditUpdatesRftTimeWithLimitsAndKeepsOtherFormatResult, addedUnconfirmedSetIsNotTurnedIntoLoggedSet.
Added (JVM): `removingRecordedSetDoesNotTurnPendingIntoPerformed`, passes (mobile 443/0/0).
Not mapped/tested: allGlobalWODFormats no-prior-score, mixedScannedBlocks, untypedLegacyReps (format null result kept when switching to forTime), playExtraPendingSets reload, Health data preserved on RFT edit. Open; names compared, Apple assertions not run.

## tree152: untypedLegacyRepsSurviveChangingToElapsedTime counterpart
Added JVM `untypedLegacyRepsSurviveChangingToElapsedTime` (format-less result with totalReps kept when the block becomes forTime; new forTime result 360 s; `editableScore` null). Passes. Remaining unmapped from tree151: global formats with no prior score, mixed scanned blocks, extra pending sets after reload, Health data on RFT edit.

## tree153: allGlobalWODFormatsAllowEditingAndPersistingResultWithNoPriorScore counterpart
Added JVM `allGlobalWodFormatsAllowEditingAndPersistingResultWithNoPriorScore` for the 8 formats (amrap, deathBy, maxEffort, forTime, chipper, afap, ladder, buyInCashOut): edit with no prior score, save through `applying`, one result with the right format and fields (rounds only AMRAP/deathBy, elapsed 757 s), no logged sets, same session id. Passes (mobile 445/0/0). No Codable-style round trip and no finishedAt check (not asserted). Still unmapped: mixed scanned blocks, extra pending sets after reload, Health data on RFT edit.

## tree154: mixedScannedBlocks counterpart
Added JVM `mixedScannedBlocksKeepRftAmrapScoresAndEmomExplicitSeriesAfterEditing` (RFT/AMRAP/EMOM fixture as JSON): after a seconds edit on RFT (533 -> 501 s) and `applying`, AMRAP score (6 rounds, 4 reps), RFT rounds, AMRAP cap, the 5 EMOM planned sets and `explicitPlannedSets` (5) stay, no logged sets. Passes. The Apple path that creates the draft through the live controller (startOnPhone, updateExerciseDraft, recordWODResult, finish) is not replayed; the fixture is built directly. Still unmapped: extra pending sets after reload, Health data on RFT edit.

## tree155: contracts topbar_alignment and login_comenzar_progress (read, live main)
Static reading of the Python assertions and greps on Android. No code change, no execution.
- topbar_alignment: all assertions are SwiftUI layout constants (16/12/8/44 insets, glass toolbar, DUO/exercise header). Not applicable to Compose by construction; not ported (already open: DUO/top bars, Theme insets). No claim of parity.
- login_comenzar_progress:
  - `isEstimatedIntense` list compared line by line: Apple `highIntensityIntervalTraining, crossTraining, functionalStrengthTraining, boxing, kickboxing, martialArts, wrestling`; Android `HealthMuscleMapper.isEstimatedIntense` has the same 7 types and excludes walking/hiking (same by static read; the existing JVM `NativeSportStimuliTest` covers native sports, not this list line by line).
  - Records/evolution: Android has fastest-km, longest distance, "Mejores marcas" (`LiveSportHistory*`) and "Deportes · evolución y récords" (`ProgressTab`, `ExercisesTab`).
  - Absent on Android: "Abrir recorrido a pantalla completa" (fullscreen route from the live review, already open), `hasExternalSaludSource`-style naming (the Health link logic exists under other names; tree139 covers the stored link), HealthKit UUID rewrite on save.
  - Auth refresh (`ensureUsableSession`, `requiresReauthentication`, error-code classifier): already on the open list (persistent reauth flag and `error_code` values not verified).
  - Voice instead of push for km cues: tree133 (compile-only).
  - Multiple workouts per day independent: tree145/146 (JVM + compile-only).
Nothing newly closed.

## tree156: window file list re-checked, LiveSportHistoryView read, "widgets" correction
`git diff --stat fc3ef7e1 refs/ghlive/main` (non-test, non-Packages) lists 37 files; none is a widget or Watch app file. The "widgets" item on the unread list had no basis in this window and is removed from the pending reading (older commits are not covered by this statement).
Still unread: see READ_LEDGER_APPLE_WINDOW.md (this line was stale for LibraryView and WorkoutView).
LiveSportHistoryView (+34): "Mejores marcas" with Mayor distancia / Mejor km (both require `usesGPS`), Mayor duración and the strength-records note are present in Android `LiveSportHistoryScreens` with the same guards; domain `LiveSportHistory.records` has a JVM test (5000 m, 295 s, 3600 s, nulls). Same by static read; UI compile-only.

## tree158: SettingsView and ReperaApp diffs (read, static) and foreground session renewal
SettingsView (+48): the "Sincronizar ahora" button, error/last-sync/idle texts, disabled while syncing or not connected, and `persistAndFlush` before sync are already on Android (`ManualMirrorSync`, `MainActivity` tree136).
ReperaApp (30): startup splash art (UIKit launch canvas) is iOS-only. The auth part applies to Android: Apple calls `ensureUsableSession()` on return to foreground and treats `requiresReauthentication` as logged out.
Android before: `onResume` ran `restoreStoredSession()` only when `verifiedSupabase == null`; a verified session with an expiring JWT was renewed only when a sync used it (`refreshedSessionBlocking`, errors swallowed by `runCatching`), so a revoked refresh token did not return to login until relaunch (static read, not reproduced).
Changed: `onResume` also calls `restoreStoredSession()` when the stored JWT expires within 60 s; that path already refreshes and, for an unrecoverable error (`SupabaseAuthErrors.isUnrecoverable`), clears the session and returns to login. Compile-only (:mobile:compileDebugKotlin OK); no JVM test (Activity code), no device. The persistent `requiresReauthentication` flag itself is not ported (the restore path decides each time), and the `error_code` values stay unverified live.
