# Igualdad completa: reconciliación25oct21:53 CET

Referencia Apple5890215d (origin/main comprobado sin cambios21:41). No es
solo delta25oct. Inventarios23/24oct son históricos, no lista cerrada.
Esta pasada NO afirma equivalencia de todas las funciones ni un plazo global.

## Huecos materiales confirmados en código

| Capacidad Apple usada | Android actual y falta real | Próxima acción |
| --- | --- | --- |
| SettingsView: semana lunes/domingo | Calendarios/contadores/charts fijaban lunes | Port local iniciado: persistencia y todos esos consumidores, pendiente pruebas |
| SettingsView: descanso predeterminado | Solo descanso del ejercicio, sin fallback90s | Port local iniciado: fallback, respeta prescripción; pendiente prueba |
| SettingsView: progresión/incremento | Motor existe y lee claves, sin UI para cambiarlas | Port local iniciado: UI+persistence, pendiente ejecución |
| SettingsView: kg/lb | No consumidor weightUnit localizado en mobile | Portar conversión presentación/entrada, conservar kg wire. No añadir picker inerte |
| SettingsView: RIR/RPE | CampoRIR funciona, sin consumidor effortUnit localizado | Portar conversión presentación/entrada, preservarRIR wire |
| SettingsView: modo semanal/rotación + RotationPlanEditor | Borrado de rutina limpia rotation; no selección/engine Android encontrado | Portar RotationEngine y consumidores Inicio/Diario/Wear plan |
| SettingsView: sonido descanso/haptic countdown | RestNotifier vibra siempre, no consumidor flags | Portar preferencias+consumidores con pruebas; audio/haptic real sin validar |
| SettingsView: objetivos Salud | No dailyStepsGoal/weeklyWorkoutGoal/bodyWeightGoal consumidor Android localizado | Portar editor, persistencia y progreso medido, nil no0 |
| SettingsView: nombre/foto perfil | IdentidadGoogle mostrada; no editor profileDisplayName/avatar localizado | Port local más coherencia identidad, no nueva divulgación remota silenciosa |
| SettingsView: estado permisos + abrir ajustes | Permisos se piden en flujos; faltan estado/entrada central | Portar estados actuales Android y entradas, sin conceder permisos al usuario |
| SettingsView: accesoCentro/Pro | Existen CenterTab/paywall/Play; no acceso equivalente en Ajustes | Reusar rutas existentes; no activar productos/backend/distribución |
| SettingsView: datos/contadores/export/reset | Importadores existen; export en AccountSyncCard; sin reset hallado | Reubicar acceso y contadores; diseñar reset confirmación/cola/tombstones antes implementar |
| HomeView/MessagesInboxView | MensajesCentro/entrenador y nuevo mensaje usadosApple; no UI/storeAndroid encontrado | Auditar contrato backend existente antes port; no enviar mensajes reales |
| LiveActivity GPS | Proveedor simulado entrega solo primera muestra | Fallo activo: diagnóstico registroLocationManager antes cierre |
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
