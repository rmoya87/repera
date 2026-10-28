> RECONSTRUIDO 26oct 08:58 desde el transcript del agente anterior (cat/replace de este documento, 22:49 a 08:34), tras perder la copia local. Solo se reaplicaron escrituras directas al fichero; ediciones indirectas (sed, scripts mixtos) pueden faltar. No es la copia original verificada.

# Reconciliación de paridad por comportamiento

> Estado histórico acumulativo. Referencia vigente para acciones nuevas: `fc3ef7e1` y
> `PARITY_DELTA_APPLE_FC3EF7E1.md`. Las filas iniciales "ausente" pueden estar implementadas
> localmente en anexos posteriores, sin validación UI; no usarlas como estado actual sin reconciliar.

Referencia fija Apple `37837401387e12c39ecd94beaae4b2eba427182c`, verificada en remoto25oct22:42CET.
Android funcional `778e1267` local; último pushfuncional `8fb1a50d`.
Esta matriz sustituye como orientación vigente las listas históricas de23/24oct,
pero NO certifica igualdad ni ausencia global de bugs. El encargo siempre fue
igualdad completa; estos hallazgos son omisiones de nuestra auditoría, no ampliaciones del usuario.

## Cómo leer
I = implementado con consumidor localizado, no necesariamente equivalente.
V = evidencia ejecutada y límites explícitos. R = restante confirmado.
A = contraste de contrato todavía abierto. No convertir I o una pantalla en V.
Las referencias de código son archivos del repositorio en la referencia indicada.
Fixtures y emuladores no prueban hardware, cuentas reales ni disponibilidad de servicios.

## Navegación, cuenta, Ajustes y datos

| Comportamiento Apple | Android I | V y R/A |
|---|---|---|
| RootTabView/continuar sesión/Comenzar | ReperaMobileScreen/NavHost, ActiveWorkoutScreen, LiveNavigationTarget | Navegación existe; A revisión de todas rutas de retorno/rotación/proceso muerto. |
| OnboardingFlowView: bienvenida, login, privacidad, permisos | OnboardingScreen/Store, Google, SupabaseIdentity/SessionStore | I flujo y ownership; V anteriores fixtures de identidad. R E2EGoogle real, refresco/logout entre dispositivos. AppleSignIn sustituido porGoogle, no portar botónApple. |
| SettingsView: semana, descanso, esfuerzo, incremento, progresión | TrainingSettings/Section, consumidorescalendario/repositorio/servicios | V focused40233623617 ajustes3/0,40234505143 RPE8→RIR2. R audio/hapticfísicos y última regresión completa. kg/lb solo selector/modelo enApple yAndroid, no prometer conversión. |
| SettingsView: rotación, siguiente, cola, arrastre | RotationSettings/Plan y fallbackWear; drag localdad6651a | V focused40235096876 ajustes3/0 incluye avance/noavancealdescartar. R nueva prueba real de drag y píxeles; no cerrado porcompilar. |
| SettingsView: nombre/foto local y perfil público | ProfileSettings/Section, ProfilePhotoCodec | V ajusteclarooscuro; R pickerreal/EXIF testnuevo noejecutado; avatarInicio ausente; perfilSupabase+Storage ausente. AppleBusinessAuthStore.syncPublicProfile contrato confirmado. |
| SettingsView: permisos/Salud/sistema/CentroPro/importexport | PermissionSettingsSection/rutas existentes expuestas | V viewports superiores/inferiores clarooscuro, no una captura integral. R accesoHistorial completo ausente. Restore/managePro existe enpaywall, no repetircomoausente. |
| SettingsView.resetUserData | No método ni botónAndroid | R reset confirmado seguro, activas/timers/Watch/tombstones/outbox/Drive/noresurrección. No ejecutarborradosreales. Apple conserva state.exercises y reinicia el resto mediante AppState (corregido al releer resetUserData). |
| BodyWeightListView: alta unpeso/día, historialfuente, borrar | WorkoutRepository alta/import/export/Healthmerge y deleteBodyWeight | R UIHistorial/borrado no tiene consumidor. AltaUI está dentro tarjeta con weightPoints noempty, por tanto primerpeso inaccesible desdeesaUI. Semánticaalta/sync requiere contraste completo. |
| LocalStore/iCloud/importCSV/importJSON/export/recovery | LocalSnapshotStore, DriveSnapshotService, CSVImporter | I Drive appData/local atómico/backups/conflictos; V tests anteriores y JVM. R E2EDrive y resolver conflictosenUI; A alcance exacto cuotaescáner entre dispositivos. iCloud→Drive es sustitución no ausencia de sync. |
| FreeUsageStore cuotasdispositivo/cuenta y nube | Ledger local monotónico, gates | I reglasdominio; R equivalente de sincronizacióncuotas iCloud y pruebaentre dispositivos. No habilitar backendnuevo. |

## Inicio, Diario y entrenamiento

| Comportamiento Apple | Android I | V y R/A |
|---|---|---|
| HomeView: calendariodía/planes/objetivos | HomeTab/WeekCalendar/StateOverview | V domingo/calendario, objetivos60/45 y4/4 sintéticos. R selección día realmente filtra sesiones mostradas: HomeTab usa history20 completa, no día; entradasSaludexternas sinlistado/detalle. |
| HomeView.recordedDayWorkoutMinutes | conciliación local+externas, exclusiónHealth; linkedminutes locale6534a2b | V HealthGoals2/0 hasta anteriores; R nuevo integrado32min noejecutado, datosreales, paginaciónHealth. |
| HomeView.RecoveryHomeCard | Resumen recuperación soloProgressTab | R tarjetaInicio y navegación recuperación, historial/mediciones adicionales abajo. |
| PlanView: semana/rutinas/oneoffs/asignación/editor | DiaryTab/RoutineBlocksEditor/Repository | I semana/calendario/editor/oneoff/drafts sinpersistiralcancelar; V anteriores fixturesediciónWOD/arrastre. R copyPreviousWeekSchedule y clearWeeklySchedule sinmétodo/consumidorAndroid; siete filasProgramado/entrenosfechados distintaorganización, A interacciónexacta. |
| PlanView.copyPreviousWeekSchedule | Ausente | R copiaoneoff semanaISOanterior→actual, nuevosIDsdecontenido, omitedíasyaocupados, noduplica. |
| PlanView.clearWeeklySchedule | Ausente | R confirmación, desasignaweekday de nooneoff, conservaplantillas/oneoff/historial, rotationnull. |
| DayPlusSheet/StartHub/SessionPreview/Favorites/timers | Borradores/hojas/FavoritesHub/StandaloneTimer | I y pruebasanteriores; A contraste actual de accionesfavoriteWOD/preview/edit/deletes. No afirmar igualdad de todos modos poruna captura. |
| WorkoutView: fuerza, warmup/RPE/drop/restpause | ActiveWorkoutCard/Repository/StrengthRestPolicy | I normales/warmup/drop/restpause/ediciónborrado; V RPEytestsrepositorio. R alfallo: todasnuevasseries escriben toFailure=false y UI noexpone control. |
| WorkoutView: navegaciónlibre/anterior/siguiente/selectblock | Solo next quefinalizaejercicio | R selectExercise sinmarcarcompleto, volveranterior y selectblock. AppleyWatchconsumen explícitamente. |
| WorkoutView: editar activo/notas/favorito | Editorpostentreno y rutina existen | R menúeditaractivo yrefreshplan, notasactivas, saveActiveSessionAsFavorite sinconsumidorAndroid. No confundireditarfinalizado coneditaractivo. |
| WOD formatos/score/perMovement/temporizador | WodClock/Rules/Assembler/ScoreCard | I todosformatos portados, decisiónladderApple preservada; V fixturesprevios. A detallerevisióndecadaacción vs Watch y edición posterior. No reabrir decisiónladder. |
| QuickLogSheet: apuntarmúltiplesfilas/nota yguardar sinabrirsesión | startQuickLog crea sesiónactiva tresobjetivos | R modalguardadodirecto/notas distinto del equivalente startQuickLogApple. Laexistenciadel botón no prueba flujoigual. |
| HistoryView: historialcompleto local+Salud porfecha, detalle | Home/Progress history.take20; completeHistory solo deporte | R historialgeneralcompleto conentradasexternas/navegación. Modelocomplete no es accesoalhistorial. |
| WorkoutDetailView: editarfinalizado/tombstone/lugar/ruta/FC | WorkoutHistoryCard/FinishedWorkoutEditor/RouteMap/scrub/heartseries | I edición y rutas, V anteriores pruebas. R borrarvínculoSalud al borrarworkout (AppledeleteExternalWorkout); Androidno deleteRecords. A restoextras y fuentesSalud. |

## Ejercicios y Progreso

| Comportamiento Apple | Android I | V y R/A |
|---|---|---|
| LibraryView: catálogo/búsqueda/filtros/agrupaciones/favoritos | ExercisesTab/alias/assets/filter/collator | I288 y migraciónpreservaIDs, deportes34/legacy36; V catálogoreciente y capturas. R WODsfavoritos/discovery exacto porcontrastar; no decir92ausentes del seedhistórico. |
| ExerciseDetailView: arte/carrusel/músculos/instrucciones | ExerciseDetailScreen/ArtImages | I textos/arte; V capturasprevias. R último loteassetshash contraApple actual pendiente; A relacióncontenido/diagramas. |
| ExerciseDetailView.suggestedLoadSection | Guía existe SOLO editorplan | R detalle: slider50–95% por5%, tested1RM o e1RM, redondeoincremento. Guíaeditorporreps NO es eseconsumer. |
| ExerciseEvolutionPanel: métricas/rangos/chart/scrub/Tope1RM | ExerciseEvolutionSection métricas/rangos/Canvas | I serieshistóricas; R editar/borrarTope1RM ylíneatecho, scrub/etiqueta punto, resúmenes enlamismaficha. Historicocompleto existe expandiblebiblioteca, distintoacceso. |
| ExerciseThisSessionCard/prior porinstancia/WOD | ExerciseSessionAppearance + ThisSessionCard | I scopeinstancia/puntajeglobal, V fixturesanteriores8JVM. A últimaUIvisible. |
| StatsView: categoríasEntrenamiento/Salud/Recuperación | ProgressTab listúnica | R categoríassegmentadas, jerarquía/estadosvacíos ygatesporsección. No esigualpor tenermotores. |
| StatsView: verTodos ejercicios/récords | records.take5; ejercicio desdecatálogo | R accesoatodosrécords/ejerciciosperiodo. A matrizFree/Proporconsumer: MuscleBalanceCardApple se renderizaenambosplanes, Androidgateentero requierecontrastecontenidointernoApple. |
| StatsView: actividad/heatmap/músculos/movilidad | StatsEngine/heatmap/BodyMap/Progress | I motores ycharts; V píxelesmapamuscularanteriores. A filtrosyshowempty/rangosexactos. |
| StatsView: valoraciónsesiones/FC/kcal/peso/zonas | FC/kcal/pesoCanvas con datos, sinscorechart nizonas | R gráfico valoraciónsesión, zonasFC reales deúltimosworkouts, ejes+ausenciadatosenPro enlugardeocultar. Objetivopeso local V bloqueado doscapturaslazy, fixenfocadapendiente. |
| HealthRecoveryProgressView: sueño/constantes/ciclo/curvas | ReadRecovery duerme/HRV/RHR + resumen | R UIhistóricoporrango/scrub/fasesueño/ciclo ylecturamenstruación/respiración/SpO2/temperatura/recuperaciónFC cuandoAPIloofrece; equivalenciasdeplataforma (SDNNApple vsRMSSDAndroid) requierendocumentar,nosustituircomomedidaidéntica. Motoresdomain solosnoesUI. |

## Centros, IA, salud y reloj

| Comportamiento Apple | Android I | V y R/A |
|---|---|---|
| CenterView reservas/cancelación/invitaciones/bonos/sharing | CenterTab/BusinessCenterStore/WorkoutMirror | I contratosRPC/vistas; V testsanteriores y4negocioenfocado. R noE2Ereal nireserva/gastoautorizado; A estadoserrores/fechasycaducidad. |
| FindCenterTrainerView/LinkedCenterDetailView | Centrosvinculadosyalistados;sinbuscador | R searchDirectory/requestLink/leave sinmétodosniUIAndroid; detallebonos/caducidad/tipo/solicitud. No confundircentrosvinculados conbuscadorApple. |
| MessagesInbox/profesionalreadonly/Watchfallback | MessagesScreen/ProfessionalSessionCard/todayPlan | V40234505143 4/0, profesionalpixelglobalAPI30 completo. Noenvíoreal ni mutaciónrutinas. R publicprofilependiente yE2Eserver autorizado. |
| AIAccess/MCP/programas/realtime/cambios | AIAccessStore/AIInbox/Programs/Realtime | I contratosyestados; V anterioresJVM. A revisiónactual de todasoperaciones/sourcepermissions/errores/cambiocuenta yE2E, no ejecutartokensreales nuevos. |
| HealthKit lectura/escriturapeso/sesión/matching | HealthConnectReader/Writer/HealthSessionLink | I y fixtures, lecturaSaludreal noejecutada. R páginasrecords (variaslecturassoloresponse.records sinpageToken), rutas ydetalleexterno, extras/zonas ymedicionesarriba. |
| LiveActivity/GPX/mapa/voz/splits/deportes/historialrutas | Runtime/LocationSource/LiveRoutes/RouteEvolution | V proveedorGPSexacto2/0, cámara+GPX/perspectivapíxeles, controles6/0API30. R hardwareGPS/audio/background, meteo/relieve sujetossincostes; últimaregresiónnoverde. |
| WatchSessionHub: hoy/offline/fuerza/Health/repcount | WearMainActivity/HealthSession/MotionRepCounter/outbox | I iniciarplan/colas/ACK/dedup/sensores; V6testsporpatarelojsolocoberturaacotada. R terminaroffline (requierefonoconectadoactualmente), avanzar/selectexercise/bloquesoffline, guardar/transferirmétricasHealth alworkoutdurable. |
| WatchSessionView: detallesserie/técnicas/WOD/control | WearHomeContent/queueSet normal | R warmup/alfallo/drop/restpause, ajuste0.1kg, editarseries, scoreWOD/porintervalo/perMovement, resumenyfinalizaciónautónoma. logWearSetfuerzawarmup=false/rechazaWOD. |
| WatchHealthKitSession: estado/recovery/finalmetrics | WearHealthSession start/pause/resume/stop | I displaypulso/kcal; R callbacksestadoexterno/recovercoldstart/finalmétricasdurables. NoE2Efísico. |
| StoreKit→Play compras/restauración/FreePro | PlayBillinglecturacatálogo/providerseguro/gates | I localesnoconcedenPro; R purchase()lanzaerror, verificacióntokenbackendyacktrasverificar, productos/trials/cuentaPlay. Decisiones/activaciónexternas, no autorizadasporparidad. |
| Plataformanotificaciones/liveactivity/accessibilidad/adaptación | Servicios/notificaciones/landscape/semantics parciales | R TalkBack/contraste/fuentegrande/tablet/foldybackgroundmatrizcompleta; no extrapolarlandscapedeunreloj. |

## Evidencia vigente de esta pasada

-40233623617: ajustes3/0, proveedorGPS2/0,tema2/0,skips0, sintéticoGPS exacto pausa/reanudar, nofísico.
-40234505143: negocio4/0,objetivos1/0,ajustes3/0,tema2/0. Bandeja/borrador/RPE/settingsinspeccionados; blancoprofesionalcorregidoposterior.
-40235096876: negocio4/0,objetivos2/0,ajustes3/0,controles6/0; tema2fallosscrollPeso. Settingsinferior/deportes/Inicioobjetivosinspeccionados.
-40235357776 global8fb1a50d FALLÓ: dominio289/0; teléfonoAPI30=242/2fallos,API35=242/4,API37.2=242/4. Todos0errores/0skips. Wear35/36cada6/0; WearAndroid30/35secundariocada6/0. Betaomitida. Fallos:2temapesoentodos; notificaciónsinpermiso ydetectordefranjavisualen35/37.2. Causasporestudiarconrerun, noetiquetarflakeautomáticamente. CapturaprofesionalglobalAPI30 ylugarglobalAPI35síinspeccionadaslegibles.
-40236392296 enfocadafuncionalf6e9feaa: VERDE. negocio4/0,objetivos2/0,ajustes3/0,controles6/0,tema2/0,todos0errores/0skips. Peso claro/oscuro inspeccionado legible. Contornocorporaloscuro sincontraste detectado, no fidelidad cerrada. Fuera deesaCI: linkedminutes,fotoEXIF/drag/guardasCuenta yfixesfixtureAPI35.

## Límites de esta matriz

La pasada ha enumerado las superficies visibles actuales y contrastado sus acciones principales,
incluidas cincofuentesWatch y158Swift totales. NO es certificaciónlíneaalínea de158archivos.
Quedan A explícitos porcontrato/entitlement/datosvacíos/errores/identidad/rendimientoyassets.
No hay previsiónglobalsólida hasta completar esoscontrastes y convertir filasR enpruebasejecutadas.
No cambiarApple/main, no publicarbeta, no activarservicios/backend ni realizarpruebasrealesSalud/GPS sinautoridad.

## Tanda posterior local (25oct23:00CET), todavía NO validada en emulador

- Contraste cuerpo/leyenda neutros por tema corregido con contrato de píxeles con todos los músculos sin actividad. Compila, sin inspección de sus píxeles corregidos todavía.
- `HealthRecordPages` recorre las diez lecturas paginadas de Health Connect. Cuatro JVM verdes: página vacía intermedia, final vacío, fallo sin retorno parcial y token repetido. Sin lectura de cuenta real.
- `WeeklyScheduleActions` + repositorio + Diario + callbacks a recarga/Wear: copiar semana anterior ISO y vaciar programación con confirmación. Cuatro JVM verdes: domingo/límites, día ocupado, IDs nuevos profundos conservando catálogo/prescripción, no pérdida de historia/activo/plantillas. Nuevo test UI compilado, pendiente de ejecución y píxeles.
- `BodyWeightHistoryScreen` accesible desde Ajustes y Progreso, incluso sin primer peso, con historial completo/fuente y borrado local confirmado. Dos JVM verdes de calendario local y validación. UI instrumentada compilada, pendiente de ejecución/píxeles. Guardado inmediato en Health Connect desde esta acción aún NO implementado; no confundir la sincronización al conectar con escritura al pulsar Añadir.
- Nueva CI enfocada `40237380498`, debug9efaa5a2, cubre fotoEXIF/arrastre/minutos/fixtures30+35 pero NO estos cambios posteriores. No beta.

- `40237380498` VERDE en API30 y35, cadauna foto1/0,objetivos2/0,ajustes4/0,controles6/0,tema2/0,lugar1/0,todos0errores/0skips. Rotación B/A/C y cabecera lugar visibles inspeccionadas en ambas APIs; API35fixture componente de rotación sin insets pisa statusbar, no equivale a pantallaAjustes completa. Foto sintética EXIF128x256 rojoarriba/azulabajo inspeccionada, no una foto real ni capturaUI deperfil.
- `ActiveSessionControls`: anterior/siguiente/selectorejercicio y notas persistidas en Inicio/rutaactiva. Navegar no confirma ni añade trabajo, repasar ejercicio cerrado admite serie real comoApple. Test instrumento compilado, pendiente ejecución. Sigue pendiente editarplanactivo/favorito y técnicasal fallo.
- MobileJVM220/0 a23:00; nuevaCIdebug0751db98 verifica consumidores posteriores pero no convierte rama funcional en globalverde.
- Confirmado adicional: StatsView actual declara explícitamente mapa y barras musculares Gratis, con consumidor en ramas Free/Pro. MuscleBalanceCard no aplica gateinterno. GatewholecardAndroid retirado local8fe21e98; rangos siguen gateindependiente. Falta pruebaUIGratisrealconLocalSubscriptions y capturas, no cerrado por comentario.
- WriterHealth también consultaba solo primera página de candidatos. Ahora usa helpercomúnpaginas local8fe21e98. Fusión peso corrige comparaciónUTC/local. MobileJVM220/0; dominio289/0. Assemblelocalmóvil interrumpido enmergeExtDex por límite del comando; no usarAPKviejo ni afirmarassemblecorrecto.

- Local Wearassemble falló por dependenciasruntime sin caché en modo offline (protolayout/health/lifecycle/guava), no por Kotlin; no volver a repetirofflinecomo remediación. CIbuildWearglobal8fb1a50d seguía válido para eseSHA, noHEAD. Nuevo testFreeMuscleAccess compila, espera próxima tanda después de40238407527 ycapturadeprogresogratis.

## Actualización23:19CET
- `40238407527` verdeAPI30/35: BodyMapContrast1/0,WeeklySchedule1/0,BodyWeightHistory1/0,ActiveSessionControls1/0,Theme2/0 en cadaAPI,0errores/0skips. Inspección de anatomía oscura ambasAPI confirma contrastecorregido. Diarioconfirmación/peso81kgfuentePropio legibles. FixturesaisladasAPI35 pisabanstatusbar yaccionesrutina podíanpartirBorrarverticalmente: corregidoslocaldbb16682conFlowRow+safeDrawingPadding; pendienteCI40239363374(debugf08a20f0), incluyeFreeMuscleAccess.
- Tanda local Tope1RM/carga: preferenciatestada persistida por ejercicio sin borrarotraspreferencias; editorenEvoluciónsoloFuerza, alta/borrado yredondeo0.1comoApple; slider50–95por5,valorinicial70%,prioridad1RMtestado→e1RM ypasopesoSettings. Chart evolución incluye techo1RMporfuerza yselecciónde puntofecha/valor mediante tap/drag. DosJVMnuevos pasan yUIinstrumentadacompila; sinpíxeles/ejecuciónemulador todavía. Esto NO está en40239363374. Gráfico necesita contratoUIdegesto/techo antesdecerrarse.
- Local directorioCentros: RPCexactossearch_discoverable_organizations(p_query),request_org_athlete_link(p_org,p_pass_kind,p_note),leave_org_as_athlete(p_org), sin llamadas reales. UIbuscar→seleccióntipobono/nota→confirmar ydesvincularconconfirmación; detallecréditos/caducidad/sesiones. Resultadosdebuscador guardados porrevisióncuenta+generaciónconsulta. DosJVMcontratosHTTPsintéticos verdes ydosUItestscompilados, no ejecutados. Pendiente erroresconservarhoja/nota+hacerconsumirprivacidadendetalle yformateocaducidad. Noafirmarequivalenciacentrocerrada.
- Directorio local siguiente: solicitud conservaorg/nota anteerror, cierra solo trasvínculoconfirmadorefresh; desvinculacióntampococierraoptimista; detalleexponeswitchprivacidad existente ycaducidadfecha local. UItestsadaptadoscompilan,emuladorpendiente. Consentimientoefectos sigue en botones explícitos dentroapp, ninguna operaciónreal realizada.
- Historial localnuevo: rutaaccesibleAjustes/Inicio/Progreso, todaslocalesfinalizadas+externasHealthregistradasenventana370d, agrupadofecha ysinlímite20; detalleexternobásicosololectura; Iniciofiltralistapor díaseleccionado. UnJVMnuevoverifica25locales+externa/orden/noincluirborrador; testUIcompila. Sinemuladortodavía. Pendientesexternas: métricas/FC/ruta/borradoSalud yverificarlímitehistóricoplataforma, noesigualdadcompletadetalleApple.
- `40239363374` API35yaVERDE: cuerpo1/0,Diario1/0,peso1/0,sesión1/0,Gratis1/0,tema2/0. API30seguíaejecutándose23:26. InspeccionadoDiario35: textoBorrar yanoapilado e insets separan título; capturaGratismuestra título/togglesdemúsculos perocuerpo quedafuera alfinalviewport, porloque nueva captura debe hacer scrollalcuerporeal,nobastatítulo.
- `40239363374` terminó VERDE API30/35,cadaAPI7tests: cuerpo1,Diario1,peso1,sesión1,Gratis1,tema2,todos0fallos/errores/skips. DiariopíxelesambasAPIs sintextoBorrarapilado yconsafeinsets. Gratisfixtureprobótarjetaperoimagenmostrósolotítulo/toggles; siguientetestscrollalcuerpocompletoincluidoen debugd6056e3a juntoTope1RM2tests,Centros2,Historial1,Temas2. Rutaejerciciohistorialcorregidaenfuncionalposteriorparausarquerysesion/instancia, fueraeseCI.

## Actualización25oct23:38CET: controles activos, esfuerzo y favorito

-341fefda implementa control explícito «Al fallo» en fuerza. Registro normal, dropset y
rest-pause conservan toFailure y RIR; fallo fuerza RIR0. Warmup descarta fallo/RIR y
no hereda una técnica oculta al cambiar de fase. Comparado con WorkoutView.saveSet
Apple37837401. Nuevo test instrumentado de persistencia de las tres técnicas y prueba
UI fallo→warmup compilados, NO ejecutados aún. No cubre edición posterior ni Wear.
-06e597c8 implementa saveActiveSessionAsFavorite y consumidor tanto Inicio como ruta
activa: rutina existente se marca in situ conservando día/progresión; sesión independiente
crea plantilla desde plannedSets, no desde trabajo registrado, y actualiza routineId.
Replica agrupación/atributos WOD de favoriteTemplateApple, sin inventar resultados.
Dos nuevos JVM verdes, test UI consumidor extendido compilado, NO ejecutado aún.
-a54bc9a6 corrige contenedor vertical de controles/contenido en el slot de Inicio.
Inspección visual de este cambio aún pendiente.
-JVMmobile227/0, errores0/skips0; compilación instrumentación local verde en06e597c8.
Esto NO sustituye regresión global, pruebas físicas ni revisión visual nueva.
-CIenfocada40240312239d6056e3a es ANTERIOR a estos cambios y al arreglo de query de
historialab6abeeb. No mezclar su resultado con HEAD. Sin pushfuncional ni beta.

## Actualización25oct23:44CET

-CI40240312239d6056e3a FALLIDA en ambasAPI30/35: porAPI Tope2/2fallos,
Centro2/0,Historial1/0,MúsculosFree1/0,Tema2/0; todoserrores0/skips0.
FallosTope de localizador/assertexacto: textoTope duplicado (editor y gráfico)
y assertTextContains sin substring aunque semántica muestra«70% e1RM ·55kg».
Se corrigen selectores y comparación de fecha usando mismo locale; quedan sin
reejecución todavía. No se afirma que el comportamientoTope esté verificado.
-Píxeles inspeccionadosCentroAPI30/35 con nota+tipo+botones legibles; HistorialAPI30
muestraRegistro24 (25º), detalleSaludAPI35 muestra fuente y35min.
MúsculosFreeAPI35 muestra cuerpos y pecho coloreado, captura termina en cuerpo,
no cubre leyenda inferior ni barras. No servicio real ni mutación de centro.
-Nuevo editor activo: borrador de solo lectura; guardado reconstruye plan con match
porbloque+ejercicio, fallbackejercicio consumido unaúnicavez, mantiene sets/estado,
ID/inicio/notas/reloj/resultadosWOD. No aplica sugerencias de progresión al refrescar,
igual aSessionController.fromApple. DosJVMnuevosverdes (229/0 total); dospruebas
instrumentadas nuevas compiladas noejecutadas; faltaUIE2E y píxeleseditoractivo.

## Actualización26oct00:05CET

-CI40241624054: porAPI30/35Tope2/0,Técnicas4/0,Controles1/0,
Editoractivo2/0,Tema2/0; falloUI1/1 porlocalizadorwarmup ambiguo; errores0/skips0.
Tope95%95kgAPI30 y techo100kg/punto20oct60x5API35 inspeccionadoslegibles.
FalloAPI35 switch pegado atexto:12dp explícitosab3671d0, prueba nueva en
CI40242982485debug780d4c03 (pendiente). EditorUIguardar/cancelar añadido20f2322f,
y selectorwarmupetiquetado; esta tanda no contiene cambiosSaludposteriores.
-CargaAPI35 captura70% aunque assert95% pasó: nueva captura espera renderestable.
No dar95%API35porverificadovisualmente aún. No hay regresión globalHEADverde.
-Peso manual ahora conservaIDdel día y timestamprealalalta (antes medianoche),
lanza escrituraSaludtrasguardadolocal con guardacuentarevisión y sin solicitar
permisos automáticamente. FallodeSalud no borra entrada local. Syncconproveedor
vacío ya exporta díaslocales. Metadata clientRecordId hashcuenta+díalocal,
clientRecordVersion timestamp para idempotencia de reintentos/actualizaciones.
DosJVMidentidad/díaDSTverdes:231/0total. Instrumentaciónpeso extendida(compila),
sinejecución aún. No seha escrito nadaenSaludreal, no se afirmaE2EHealthConnect.

## Actualización26oct00:15CET: Progreso

-112c1c1b/4d7840e5 exponen todosrécords y ejerciciosdelperiodo (primeros5+
lista«todos», navegaciónficha). Récords porfechadesc/e1RM; ejerciciosporúltimafecha,
comoProgressSnapshotApple, no alfabético ni catálogocompleto. Récords/ejercicios
avanzadosPro, mapamuscularFree sigue abierto. No son pruebasdecompra.
-Gráficapuntuación: soloreview.scoreBasis=personalHistory, agrupafechafin,
mediaredondeadadía; ejes0–10 y vacíoexplícito. PreviewFreefijoetiquetadoficticio,
no lee puntuacionesprivadas. LocalJVM233/0antesdelúltimotestpreview.
-PestañasEntreno/Actividad/Recuperación con contenido separado y periodo compartido.
ActividadProconservaejesvacíosFC/kcal/puntuación, pesoreal porperiodo; Freeusa
perfilesficticiosAppleexplícitos, nopesoprivado, teaserPro. R botonesheaderanclado,
restoFCzonas/extras/ejesgráficascondatos/scrubpreviewdisabled y fidelidadtiles.
-Recuperaciónesresumenactual/estadovacío, NOhistorialcompleto/fases/ciclo ni todas
constantes; no cerrarporpestaña. EncontradoApple HealthRecoveryStore opt-insprivados
sueño/ciclo; AndroidpermisoSleepactualagrupadoenHealthConnectReader.permissions:
R introducirdecisiónexplícita y no confundirconsentimientoSaludconopt-inanalíticas.
-NuevasUIrecords/ejercicios/puntuaciones/temasFreePro compiladas pendientesdeejecutar;
ningúnpíxel nuevoProgreso todavía. Toda la tanda es posterioraCI40242982485.

## Actualización26oct00:18CET

-CI40242982485debug780d4c03verdeporAPI30/35: Tope2/0,Técnicas4/0,
Fallo1/0,Controles1/0,Editoractivo3/0,Tema2/0; errores0/skips0.
PEROcapturasAPI35Tope/fallo/editor tienen overlayPixelLauncherANR, no son evidencia
visualválida. API30editorlegible y separaciónfallo12dp verificadapíxeles.
-No darporcerrado95%API35ni editorAPI35 peseaassertComposeverde.
826cde33 exige ventanaforegroundappantesdecapturas; nuevo loteenfocado incluye
repeticiónactiva, pesolocal, Progreso233→234JVM, nuevaslistas/temas/free/puntuación.
Dominio289/0local, Mobile234/0local, compilacióninstrumentadavérificada; sinfinalglobal.
-Mapa/barrasFree mantienecoberturaanterior. NUEVAcategoríaprogreso no estáenúltimo
verde, quedaejecutarUIe inspeccionarsusimágenes antesdeafirmarfidelidad.

## Bloqueo externo26oct00:19CET

-CI40244103152debug65338db7noejecutópasos:2segundos,runnerid0.
PáginaActionsautenticada confirmaambasAPI: pagosrecientescuentafallidos O límitegasto
necesitaaumento. La anotación no distingue cuál. Noatribuiracódigo, nodecirpruebasejecutadas.
-Noautorizadoaumentarlímites/pagar(usuarioexigesincostes). Sinreintentosautomáticos.
PruebasnuevasProgreso/peso y píxelesAPI35/global permanecenpendientes.
Continuarvalidaciónlocalposible y código/auditoría independiente; informarparent.

## Actualización26oct00:24CET: recuperación privada

-a92a6793: sueño requiere decisión explícita independiente enAjustes, defaultoff.
Estado atómico ennoBackupFilesDir, noAppState/Drive/backupAndroid; quitarpermisoSleep
por defecto, solo incluirlo alactivar. Desactivación elimina nochesenmemoria y
lecturasen-vuelo no puedenreintroducirlas (revisiónprivada). No se revoca permisoOS
sin solicitud, se deja deleer/mostrar. Instrumentaciónoptinpersistido compilada,
noejecutada porbloqueoActions. Ciclo todavíaausente, no selector sin consumidor.
-Nuevahistoriarecuperaciónporperiodo desde370dlecturasdisponibles: noches+horas
profundas/REM y curvasVFC-RMSSD/pulsoreposo, vacíosexplícitos,scrub existente.
NoesSDNNApple, seindicaenUI. TarjetaInicio consueñoreal→AjustesSalud.
UIhistorialcompilada,nopíxeles/emulador nuevos. R ciclo, respiración/SpO2/temperatura,
FCrecovery y mayorfidelidad/detallefases/ejes/gates/retencióndatosprivados.
-Mobile234/0Dominio289/0local, compileinstrumentaciónverde. NoAPKglobalHEAD.
-SDKlocaltieneplatform-toolspero sinemulator/system-images ni/dev/kvm; no es
alternativaemuladorlista. Continuaciónlocaldecontratos/código no bloqueada.

## 26oct00:28 · arte y vigencia de sueño (local)
- Auditoría de 1.066 imágenes Apple37837401, incluidos thumbs: cero ausentes y cero SHA-256 diferentes por ruta relativa. Evidencia JSON en docs/evidence.
- Carrusel: fallback de hero ausente y holds por alias; movilidad conserva su fallback separado (no adopta un paso huérfano). Pruebas JVM añadidas.
- Recuperación: noches antiguas permanecen en historial pero no producen consejo actual; ventana de última noche 0–2 días naturales (aproximación por día al límite48h Apple), promedio de últimas14noches como Apple. Test de fecha pasada/futura añadido. No alegar equivalencia exacta al segundo: el modelo de noche solo conserva LocalDate.
- Mobile236/0 y domain290/0 local. Móvil assembleDebug y Wear compileDebugKotlin verdes antes de estos últimos ajustes; no ejecución/píxeles nuevos, CI sigue bloqueado por facturación/límite, sin reintentos.

## 26oct00:31 · ciclo privado (implementado, no validado en dispositivo)
- Decisión explícita de ciclo independiente de sueño, desactivada por defecto y archivo noBackup; no snapshot/Drive/backend. Guardado atómico preserva la otra decisión.
- HealthConnectReader solicita menstruación/periodos/ovulación solo tras activar ciclo. Lee únicamente permisos concedidos, días observados y positivos registrados; expande intervalos con final exclusivo y límite10días como Apple.
- Apagar borra muestras en memoria; revisión descarta lecturas antiguas en vuelo. No revoca permisos del sistema ni escribe registros de salud.
- Recuperación consume días/test positivos, fase conservadora existente en dominio y calendario de6semanas con días observados; advertencia de no confirmar ovulación/anticoncepción. Layout pendiente de píxeles y accesibilidad en dispositivo.
- Mobile236/0, domain291/0 local; AndroidTest compila. Instrumentación nueva de decisión y UI ciclo aún NO ejecutada por bloqueo Actions. No se leyó/escribió salud real ni se desplegó beta.

## 26oct00:35 · constantes y permisos declarados
- Añadidas lecturas opcionales observadas de respiración y SpO2, medianas/rangos y charts. Son permisos solicitados con acción explícita, no requisitos nuevos para actividad ya autorizada. Respiración usa ventana de mañana <=07:00 como Apple. No se interpreta SpO2 como diagnóstico.
- Auditoría del manifest encontró READ_HEART_RATE, READ_EXERCISE y WRITE_EXERCISE ausentes aunque había consumidores y solicitud runtime. Declaraciones añadidas. No se concedieron permisos reales ni se probó panel del sistema.
- Temperatura de muñeca y recuperación de FC1min siguen sin equivalente consumidor: no sustituir temperatura corporal/piel relativa como si fueran lo mismo. Falta resolver SkinTemperature con garantía de tipo/feature y ausencia de baseline.
- UI nueva de constantes compila, no ejecutada ni inspeccionada. CI sigue bloqueado; no beta ni push.

## 26oct00:39 · muñeca y revisión de permisos opcionales
- SkinTemperatureRecord leído solo con feature disponible, permiso concedido y opt-in sueño. Acepta únicamente ubicación muñeca, baseline absoluto conocido, delta finito y muestra dentro de fase dormida observada. baseline+delta 25–42°C; no usa temperatura corporal, dedos/pies, solo baseline ni delta relativo sin referencia.
- Desactivar sueño limpia también temperatura en memoria y descarta ese campo de lecturas en vuelo. Etiqueta diferencia respecto al sensor Apple Watch. Sigue NO validado con proveedor/dispositivo real.
- Fuente oficial inspeccionada: https://developer.android.com/reference/androidx/health/connect/client/records/SkinTemperatureRecord (baseline opcional; deltas relativos; feature/ubicación). Guía https://developer.android.com/health-and-fitness/health-connect/features/skin-temperature confirma control feature y diferencia de temperatura central. Guía usa frase ambigua sobre delta entre medidas; contrato API específico establece delta respecto al baseline, usado aquí.
- ConectarSalud ahora revisa también permisos opcionales pedidos al pulsar, en vez de saltar el panel si ya estaban los básicos. Denegar opcionales no bloquea lectura básica.
- Mobile236/0, domain292/0 (errores/omitidos0), AndroidTest compila previo al último cambio del botón Conectar. Sin píxeles ni instrumentación ejecutada, no alegar cierre.

## 26oct00:45 · Apuntar series directo desde ficha (local, no cerrado visualmente)
- Botones de biblioteca/ficha abren borrador modal en lugar de arrancar sesión completa. Tres filas con últimos reps/kg/duración cuando disponibles, añadir/eliminar, métricas por modo, holds sin reps visibles y nota opcional.
- Repository.logQuickSets valida todas las filas antes de persistir; guarda una sesión finalizada con duración editorial min60s/90s por serie igual a Apple, nunca energía ficticia. No la presenta como duración medida. Conserva sesión activa y rutinas. UUID del borrador evita duplicación al reintentar. Valoración y refinementHealth reutilizan ruta existente tras guardar.
- Cancelar/cerrar no escribe. Error de guardado deja hoja abierta; se cierra tras éxito. Cambio de unidad común se conserva en filas.
- Mobile238/0 local, AndroidTest compila. Nuevo test repositorio de no mutar activa/rollback/idempotencia solo compilado, NO ejecutado. Hoja nueva NO inspeccionada en píxeles. Inputs usan campos numéricos en vez de steppers Apple, layout y paridad de interacción siguen pendientes.
- Wrist/Conectar opcionales incluido en compilación verde. Sin push, beta ni Actions.

## 26oct00:47 · permisos parciales
- Corrigido requisito global de TODOS permisos (incluidos escritura de peso/entreno y VFC) para leer actividad: ahora cada tipo se lee con su permiso. readDay agrega solo métricas concedidas y devuelve null para ausentes. La respuesta del panel continúa con cualquier permiso de lectura válido, no con write-only.
- Conectar mantiene solicitud explícita para tipos aún no concedidos; no exige aceptar todos para mostrar los disponibles. Estado de Ajustes dice lecturas autorizadas, no autorización total.
- Nuevo test instrumentado parcial/read-only/write-only y UIquicklog cancel/guardado preparados. Compilación y JVM verificados antes de añadir estos dos tests; ejecutarlos y píxeles siguen pendientes.

## 26oct00:49 · agrupación diaria FC
- Health Connect puede devolver un HeartRateRecord que cruza medianoche. Antes Android asignaba todas las muestras al día de inicio del registro. Ahora cada muestra usa su propio instante/día local y se filtra a la ventana pedida.
- Test JVM medianoche/cambio horario Madrid25oct, promedio/min/máx por día: mobile239/0 y AndroidTest compila. No muestras reales ni UI nueva validada.

## 26oct00:51 · petición Wear de finalizar resistente a desconexión
- Antes terminar dependía de un sendMessage efímero; sin teléfono no retenía intención. Ahora outbox separado persiste petición por sessionID, reenvía al abrir/reconectar/reintentar y espera ACK exacto.
- Se espera a que no queden series pendientes de ESA sesión antes de enviar finish. Teléfono finaliza ID activo coincidente o confirma ID ya archivado sin duplicar ni finalizar otra sesión. ACK posterior al guardado. Logout limpia petición privada.
- Esto NO equivale a finalización autónoma Apple: el reloj mantiene sesión/sensor activos hasta recibir estado final del teléfono. Terminar offline local, técnicas/WOD y persistencia de métricas nativas siguen pendientes. No anunciar que termina offline.
- Nuevos tests de outbox/recreación/ACK y finish idempotente/nootraactiva están preparados para instrumentación; no ejecutados. Compilación anterior de móvil/Wear AndroidTest verde; sin píxeles/transportehardware nuevo.

## 26oct00:54 · detalle externo observado
- Desde Historial, detalle ampliado de un registro externo: relectura de ID exacto y verificación origen/inicio/final antes de usar rango. Pulso/energía solo del mismo origen; sin señal se dice ausente, nunca estimación. Curva usa scrub existente.
- No añadido borrado de registros externos: HealthConnect no autoriza asumir borrado de datos de otra app. Ruta/distancia/velocidad de externos siguen pendientes. UI y proveedor real no ejecutados; no cerrar paridad de detalle.
- Guard adicional Wear: no permite nuevas series después de petición finish persistida para evitar carrera finish/serie nueva; serializa acción de teléfono. Quicklog borrador reinicia al cambiar cuenta.

## 26oct00:56 · consumidor real ficha y onboarding
- Auditoría detectó que ficha navegada ExerciseDetailScreen es distinta de panel expandido ExercisesTab. Añadido botón y hoja directa también al consumidor navegado; informe00:45 sobre ficha solo era correcto para panel expandido, no para esta ruta. Ahora ambas rutas tienen consumidor local compilado. Sin pruebaUI/píxeles.
- Resultado del permiso parcial en onboarding usa misma regla de lecturas, no vuelve a exigir todos.

## 26oct00:58 · avatar de Inicio
- Inicio muestra foto guardada local con recorte circular y acceso Ajustes; fallback seguro con icono al no haber JPEG válido. No sube foto ni cambia audiencia.
- Test fallback/click preparado y compilado, mobile239/0; visual aún no inspeccionada. Perfil público continúa sin sincronización, requiere contrato y audiencia explícita; no se activó backend.

## 26oct01:00 · Wear warmup/fallo y campos por modo
- Wear añade elección calentamiento/trabajo y alfallo para modos compatibles; outbox conserva ambas decisiones y teléfono usa logCurrentSet común. Warmup no suma completedReps, sin RIR/fallo; descanso warmup usa política compartida. Dos tests instrumentados preparados, no ejecutados.
- Step de peso Wear0.1kg con redondeo decimal como control principal Apple; evita deriva binaria. RIR no se envía ni muestra en máquina/comba/movilidad; máquina ahora muestra/envía duración, que estaba omitida.
- Compilación AndroidTest móvil/Wear verde antes de los últimos tests/ajustes. No píxeles ni emulación nueva. Drops/restpause/ediciónseries/WOD y finalizaciónofflinecompleta siguen pendientes.

## 26oct01:02 · Wear contrato de borrador
- Inicio autónomo y recuperación de caché antes dejaban reps0/unidadreps en máquinas pese al plan. Seed central usa prescripción reps/kg/duración/RIR/unidad, reconoce hold movilidad y no muestra contador reps para hold. Al cambiar ejercicio reinicia ese borrador, no arrastra unidad/déficit de otro ejercicio.
- Máquina cambia solo cal/metros si el ejercicio lo permite; carrera fija metros. Test de contrato Running/AirBike/hold/RIR preparado.
- AndroidTest Wear compila y assembleDebug móvil+Wear verdes localmente con esta tanda. Últimos JVM móvil239/domain292. Sin instrumentación/píxeles/sensores nuevos.

## 26oct01:04 · referencia actual fc3ef7e1

Main remoto cambió a `fc3ef7e1ad850818f463133122fead864c201701`, verificado gitlsremote/fetch.
No merge ni modificaciónApple. Véase `PARITY_DELTA_APPLE_FC3EF7E1.md`:11fuentes iPhone,
adaptación >=620 y quicklog; Watch/dominio/arte sin delta. Matriz vieja es evidencia histórica,
no referencia vigente de las nuevas pantallas. Quicklog local actualiza texto “Apuntar ejercicio”,
teclado numérico, caps y omisión de filas0/holdsinsegundos. Mobile240/0 y AndroidTest compila.
Layout dual/keypad4x4/steppers Apple NO implementados ni visualmente validados.
