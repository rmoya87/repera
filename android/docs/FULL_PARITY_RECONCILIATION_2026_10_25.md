# Igualdad completa: reconciliación25oct21:53 CET

Referencia actual Apple37837401 (origin/main refrescado22:19); el análisis inicial
fue5890215d y sus filas históricas se corrigen por los hitos de abajo. No es
solo delta25oct. Inventarios23/24oct son históricos, no lista cerrada.
Esta pasada NO afirma equivalencia de todas las funciones ni un plazo global.

## Huecos materiales confirmados en código

| Capacidad Apple usada | Android actual y falta real | Próxima acción |
| --- | --- | --- |
| SettingsView: semana lunes/domingo | Calendarios/contadores/charts fijaban lunes | Port local iniciado: persistencia y todos esos consumidores, pendiente pruebas |
| SettingsView: descanso predeterminado | Solo descanso del ejercicio, sin fallback90s | Port local iniciado: fallback, respeta prescripción; pendiente prueba |
| SettingsView: progresión/incremento | Motor existe y lee claves, sin UI para cambiarlas | Port local iniciado: UI+persistence, pendiente ejecución |
| SettingsView: kg/lb | Apple solo selector/modelo, sin consumidor; confirmado grep5890215d | Selector/wire Android igual; no prometer conversión de pesos |
| SettingsView: RIR/RPE | CampoRIR funciona, sin consumidor effortUnit localizado | Portar conversión presentación/entrada, preservarRIR wire |
| SettingsView: modo semanal/rotación + RotationPlanEditor | Borrado de rutina limpia rotation; no selección/engine Android encontrado | Portar RotationEngine y consumidores Inicio/Diario/Wear plan |
| SettingsView: sonido descanso/haptic countdown | RestNotifier vibra siempre, no consumidor flags | Portar preferencias+consumidores con pruebas; audio/haptic real sin validar |
| SettingsView: objetivos Salud | No dailyStepsGoal/weeklyWorkoutGoal/bodyWeightGoal consumidor Android localizado | Portar editor, persistencia y progreso medido, nil no0 |
| SettingsView: nombre/foto perfil | IdentidadGoogle mostrada; no editor profileDisplayName/avatar localizado | Port local más coherencia identidad, no nueva divulgación remota silenciosa |
| SettingsView: estado permisos + abrir ajustes | Permisos se piden en flujos; faltan estado/entrada central | Portar estados actuales Android y entradas, sin conceder permisos al usuario |
| SettingsView: accesoCentro/Pro | Existen CenterTab/paywall/Play; no acceso equivalente en Ajustes | Reusar rutas existentes; no activar productos/backend/distribución |
| SettingsView: datos/contadores/export/reset | Importadores existen; export en AccountSyncCard; sin reset hallado | Reubicar acceso y contadores; diseñar reset confirmación/cola/tombstones antes implementar |
| HomeView/MessagesInboxView | MensajesCentro/entrenador y nuevo mensaje usadosApple; no UI/storeAndroid encontrado | Auditar contrato backend existente antes port; no enviar mensajes reales |
| LiveActivity GPS | Fixture corregido usa GPS real del producto enAPI30 |40233623617 proveedor2/0: coordenadas exactas, pausa/reanudación sin salto; noGPSfísico |
| CámaraLive | Pixels perspectiva/GPX/teselas correctos; test espera callback equivocado | Frame fully-rendered en nuevo enfocado; no terreno/elevación |
| Meteo histórica/viento | No proveedorAndroid | Requisito sin costes; no nuevo proveedor/backend/divulgación autorizado |

## Cobertura por superficie (existencia no certificación)

| SuperficieApple5890215d | EquivalenteAndroid y estado |
| --- | --- |
| RootTabView | ReperaMobileScreen/NavHost: Inicio/Diario/Comenzar/Progreso/Ejercicios; Center sheet y Crear/favoritos/reloj rutas |
| HomeView/HistoryView | HomeTab/ReperaCards/FinishedWorkoutEditor: sesiones, revisiones, calendario, cardio; huecos settings/semana arriba |
| PlanView | DiaryTab/RoutineBlocksEditor: programación/edición/one-off/favoritos; rotación ausente confirmada |
| WorkoutView | ActiveWorkoutScreen/HomeTab/WorkoutRepository: fuerza/WOD/series; settingskg-lb/RPE sin portar |
| LibraryView/ExerciseDetail/ExerciseProgress | ExercisesTab/ExerciseDetailScreen/ProgressCharts: catálogo288, progreso, historial; revisión completa equivalencias/campos sigue abierta |
| StatsView/ActivityHeatmap/BodyMap | ProgressTab/ProgressSnapshot/Charts/MuscleBalanceCard: motores y vistas existen; no extrapolar a cada filtro/settings |
| FavoritesHub/SessionPreview/QuickLog/WODCatalog | FavoritesHubScreen/SessionPreviewSheet/pickers/drafts existen, pruebas previas, no nuevos cambios declarados |
| StandaloneTimer | StandaloneTimerScreen/WodClockScreen/servicios; sonido/haptic settings pendiente |
| Center/AIPrograms/AIAccess | CenterTab/AIProgramsScreen/AIAccessScreen + stores existentes; MessagesInbox ausente |
| MoreView/SettingsView | Datos/cuenta repartidos en cards; Ajustes mínimo no era igual. Huecos arriba |
| Onboarding/Paywall | OnboardingFlow/monetization.PaywallScreen; backend/grants comerciales separadas, no equivalencia de ejecución real |
| LiveActivity/LiveSportHistory | Bloque delta actual implementado en gran parte; GPS/cámara/regresión/hardware y meteo/terreno abiertos |
| ReperaWatch5fuentes | WearSessionStore/HealthSession/puente existentes con6tests previos; no E2E físico ni OS6.1preapp |

## Restricciones y niveles
- Apple/main intocables. Rama funcional sin merge. Beta draft51500 sin cambio.
- Sin costes; conservar MapLibre/OpenFreeMap. Nuevos servicios/backend o
  divulgaciones no se infieren del encargo de igualdad.
- CI último global verde212dcbe3 es anterior a este trabajo. Local compilar y
 199tests mobile no prueban CI/emuladores/hardware del HEAD.
- No plazo global mientras faltan descomponer/contrastar los comportamientos
  arriba. La previsión2–3días anterior describía delta, no igualdad completa.
- Monitorear falle GPS/cámara mientras se portan ajustes independientes. Cada
  control nuevo exige persistencia+consumidor, test y pixels antes cierre.

## Implementación local22:00 (sin cierre)
-3d1d8723: semana/descanso/progresión/incremento con consumidores; datos/export.
-4bd018a4: RotationPlan puro (2tests) + wire/state + modo y editor cola;
  Inicio/Diario y todayPlanSession reloj eligen siguiente; finish solo avanza
  si coincide rutina próxima, descartar no avanza. Tests integrados preparados
  para otra rutina/descartar/vueltaA→B→A/volver semana fija. No ejecutados.
-6459f4cf: flags sonido/haptic a StrengthRestService y avisos de descansoWOD
  de teléfono/servicio. StandaloneTimer usa sound/haptic=true explícitos en Apple5890215d, no debe heredar flagsglobales. Haptics reales siguen sin validar;
  no declarar preferencia global cerrada hasta cubrir todos consumidores.
-252f17bd: estado real permisos ubicación/notificación y accesoAjustesSistema,
  actualizado onResume. Botones solicitan solo por tap. Salud reusa ruta.
-Local domain284/0 mobile199/0; instrumentadas compilan. Capturas nuevas y
  TrainingSettingsInstrumentedTest2 preparados, todavía sin ejecución.

## Implementación local22:08 (sin cierre, posterior a CI40233623617)
- a97b4c2b HealthGoals: opcionales/rangos/editor/persistencia; Inicio consume pasos/kcal
  de hoy y contador semanal local. Minutos/peso/fecha seleccionada/conciliaciónSalud pendientes.
- Mensajes: tablas/RPC exactos de BusinessDataStore5890215d; bandeja+destino
  entre centros vinculados+asunto/cuerpo+Enviar explícito. Ningún envío real.
- Prescripciones profesionales: proyecciónsololectura en Inicio/Diario/Center.
  La tarjetaApple NO inicia entrenamientos. Proyección temporal de plan profesional
  para Watch sí existe en ReperaStore1724–1811 y sigue pendiente en Wear.
- Filtros clientepropio+scheduled+orden fecha probados JVM201/0. Guardarevisión
  de cuenta evita aplicar carga o error de cuenta anterior y borra datos al cambiar.
- BusinessProjectionInstrumentedTest2 preparados, compilan, noejecutados;
  capturas pendientes. No cerrar paridad mensajes/profesional ni HealthGoals.
-22:10 proyección planprofesionalWear añadida como fallback a rutina propia,
  sin persistencia y progresiónoff; resolución catálogo existente porid/nombre o
  ejercicio temporal. Guardas sesiónactiva/fecha/schema/status. Test integrado
  preparado comprueba prioridadpersonal y noescritura, noejecutado aún.
  Logout limpia también caché plan/timer delreloj. E2E físico siguependiente.
-22:12 perfil local: nombre opcional y fotoJPEG256px ensettings existentes;
  Inicio usa nombre editado. No publica perfilSupabase (Apple sí sincroniza
  perfil público explícitamente); esa diferencia sigueabierta. Selecciónfoto
  y orientaciónEXIF/visual aún sin validar. No cierre de perfil.
-Accesos Ajustes aCenter y paywallPro existente, sin conceder entitlement ni
  modificar precios/compra/backend. No probado visualmente aún.
-22:13 correccióninventario: weightUnit enApple5890215d solo aparece enmodelo y
  selectorAjustes, sinconsumidor kg/lb. No prometer conversión inexistente allí.
  RIR/RPE sí tiene consumidorAppleWorkoutView; portlocal añadepreferencia a
  formulario/series de sesiónactiva y convierteentrada aRIR wire, sin cambiar
  pesokg. TestcallbackRPE8→RIR2 preparado, noejecutado.
-22:16 objetivoPeso ahora consume valor enProgreso: diferencia conúltimo punto,
  umbralApple<0.3kg y líneaobjetivo en gráfica; compila, falta visual/test.
  ObjetivoMinutos/conciliaciónporfecha y reset seguro siguenpendientes.
-22:18 huecoSalud confirmado y portado local: readSamples excluía solo package
  Repera, no registros externos enlazados/solapados conentrenoslocales.
  ReperaHealthExclusion replica ApplematchesReperaSession: idenlazado o un
  único solape>=40%; ambigüedad noexcluye. Distinto del matcherestricto de
  refinamiento.2testsJVM nuevos. No se leyó/escribió Salud real.
-22:19 objetivosInicio ahora usan día seleccionado: pasos/kcal leídos por día
  al tenerpermiso, minutos de sesiones locales (duraciónactivaEnVivo) más
  externas noexcluidas; semanaseleccionada suma sesioneslocales+externas.
  Falta validaciónvisual y equivalencia completa de duraciónSalud enlazada.
  Guardacuentarevisión en lecturaSalud evita aplicar datos viejos a otra cuenta.
  La lectura de pasos/energía no añade permisos, usa los ya existentes.

## Referencia actualizada22:20
-Apple37837401 mueve catálogoComenzar:34seleccionables, mantiene36IDs
 persistidos, no ofrecegravel/other, títulosCiclismo de carretera/montaña y
 Entrenamiento, ordenespañol dentro de secciones, símbolosactualizados.
 Portlocal con2tests. Noenfocadaactual40234505143; visualpendiente.
-La retiradaApple de tarjetaDeportes·Comenzar enProgreso no exige borrar nada
 Android: esa tarjeta no existe enProgressTab; catálogo permanece enEjercicios
 comoantes. Corrijo hipótesis anterior de quehabía quequitarla.
-AtribuciónEnVivo díaInicio ya presente enProgressSnapshot. DeltaApple sobre
 appendRouteLocation yweakself esespecíficoSwift, sinmutaciónAndroidnecesaria.
