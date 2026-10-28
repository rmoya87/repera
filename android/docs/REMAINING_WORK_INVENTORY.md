# Inventario de trabajo restante (27 oct 21:21 CET)

Clasificacion COMPLETA (0 unverified) en ambas matrices; esto NO es cierre funcional.
Fuentes: AUDIT_579_PREWINDOW_MATRIX.csv (579 filas) + AUDIT_POSTBD4_WINDOW_MATRIX.csv.

## Estado vigente (recuento directo 27oct21:21 CET)
-735 filas SHA validas:579prewindow+156postwindow.
-70 abiertas:50prewindow+20postwindow. Abierta = campo6 comienza partial,
 verified-partial o in-progress. Cambiar partial a verified-partial no cierra.
- Mobile645/645(162XML) ejecutadas TODAS en4lotes+clase faltante21:06..21:14,
 cero fallos/errores. XML consolidados:repera280-mobile-xml.tar.gz. Monolitica
 no cerro120s;un intento AIAccessRenderTest fallo CalledFromWrongThread,
 aislado y despues en lote verde. No se presenta monolitica verde.
- Domain485/485(92XML) yWear8/8(1XML) REEJECUTADAS21:20 (2tasks test ejecutadas,
 no cache/up-to-date),0fallos/errores por modulo.
- Assemble mobile280 ejecutado verde21:15 (112s). Wear assemble anterior
 verde UP-TO-DATE19:48,no se presenta como compilacion nueva.
- HEAD implementacion280=0f5bb404;backup280-full recuperado mediante git am
 en clon limpio65338db7:arbol96a20bcdb590b173f7d50185e230a0341eb46255
 IDENTICO al original. Backup260commits --binary, no net diff.
- Ultimos cambios271..280: inventario reconciliado;WOD unidades explicitas;
 notificacion programados273/274;Peso210/CatmullRom/vacio275/276;
 readiness220/previewplano277 yDUO205..270278;preview ejercicio eje sesiones
195/CatmullRom279;sueno night-sky/area/220yDUO280. Renders inspeccionados.
- Runtime dispositivo,zonas FC decision,parser completo,meteo ruta,rama Diario
 siguen abiertos. Planned lockscreen YA implementado273/274, NO es ausencia
 de superficie;outdoor metricas y validacion nativa quedan abiertos.
- Cursores readiness y vacio YA portados;no inferir pendiente desde notas viejas.
 Graficas reales ejercicio/cardio/kcal y fisiologia aun difieren del corte.
- Ninguna nota historica sustituye este recuento ni la matriz viva.
  No push hasta condicion original y cierre real.

## Dependencias de validacion (bloquean cierre)
1. compile/build mobile+wear COMPLETO verde gestionado in-call (assemble OK; confirmar tras cada lote) — REQUISITO antes de integrar/push
2. Validacion runtime/UI en dispositivo/emulador de todo lo movil desde tree175 (WIP; emulador sin KVM no viable, adb requiere accion del usuario, cloud prohibido)
   - Sub-dependencia explicita (padre 14:47): lo implementado por comparacion de fuente
     (glifos 20x20, tarjeta "Musculos y equipo", iconos chips biblioteca, onboarding AI)
     NO esta visualmente validado: 0-diff de coordenadas y assemble no acreditan pixeles.
     Via intermedia honesta EN MARCHA: Robolectric 4.17 graficos nativos + ui-test-junit4
     como testImplementation. Renders inspeccionables en mobile/build/reports/render/:
     12 glifos (MuscleGlyphRenderTest), tarjeta Musculos y equipo, AIAccessScreen
     (conexiones + tokens tras scroll). Acreditan la previsualizacion JVM de esos
     fixtures/tamanos concretos; NO todos los tamanos/temas ni runtime de dispositivo.
     Diffs de glifos verificados por comparacion PROGRAMATICA exhaustiva 9/9 (no muestreo).
3. Suites COMPLETAS verdes tras cada implementacion: cifras vigentes arriba; las notas cronologicas conservan cifras de su checkpoint, no el estado actual.

## Grupos de gaps principales (pre+post)
- Onboarding AI unificado: IMPLEMENTACION COMPLETADA (f68d77ff + Desconectar 14:51 + d61c5d52 espaciado 15:11) CON DEPENDENCIAS EXPLICITAS:
  tarjeta revocada completa sin acreditar visualmente, flujo proveedor verificado->dialogo
  sin acreditar en app, revision visual del espaciado 6dp nuevo, y validacion runtime global
- Zonas FC + anillo intensidad Cardio Progreso (661e65f4/9947c212 — bloqueo decision usuario)
- Paisaje/dos paneles CERRADO 15:40 verificando contra el corte 0a640da8 (varias
  filas cambiaron tras su commit original): columna 790 solo en listas agrupadas,
  Home/Progreso full-width expandido, calendario carrusel >7 dias en expandido
  (cap 472 revertido: Apple lo retiro), margenes 16 uniformes (Apple retiro el
  +16 paisaje), 96efb7b6 cerrado (PlanView eliminado por Apple en c5aae1cc).
  Pendiente de este grupo: verificacion visual de pantallas/insets en dispositivo
- Wear fino: 3/4 items ya cerrados (linea stale): Sincronizar+mascota = 4a82b4b2
  verified-ported 15:35; flecha en descanso = a4a5d9ce/ea99a5b6 verified-ported 15:35;
  frescura planificacion = 1d333b42 verified-ported 15:35. ABIERTO real: 44713457
  captura de series WOD por movimiento YA portada; sigue diferencia sin reloj
  de bloque activo (44713457) + validacion visual estilo botones (0f528156/604b1293)
- Cursores interactivos graficas recuperacion IMPLEMENTADOS (b73d77dc/42f02b82), runtime pendiente
- Estilos parciales a verificar en runtime (margenes, miniaturas, previews)
- Grupos post-window (no lista de ausencias actuales): widgets/notificacion, Health-ruta, fullscreen map, tap targets/overlay, Health Connect por rango, tiles resumen. Ver cada matriz: varias superficies YA portadas con runtime abierto.

## Evidencia N/A
Cada fila n/a de las matrices lleva su razon (mecanica iOS nativa, superficie web/MCP/db compartida,
tipo Swift sin counterpart). Donde la ausencia Android podria ocultar funcion faltante se marco
partial/in-progress en lugar de n/a (paisaje, Wear, auth cache).

## Revision visual 27oct 18:39 (tree239)
- Selector Progreso 360dp: Recuperacion ya no se corta; se reserva todo el ancho
  de etiqueta (sin check redundante, paddings 6dp y labelMedium). Fixture claro
  renderizado e inspeccionado; fuente Apple StatsView mantiene los tres nombres.
- Rango semanal Progreso: locale es-ES explicito (la app tiene texto espanol fijo),
  elimina mezcla «Del Oct 26, 2026...». Render real: «Del 26 oct 2026 al 27 oct 2026».
- DayPointLineChart de un dato: muestra valor + «Una medicion; aun no hay tendencia»
  + una sola fecha, no linea inventada ni tres fechas repetidas. Semantica contrastada
  con Apple HealthRecovery.vitalChart (count <2 = estado sin tendencia).
- Dos dias contiguos: omite fecha central cuando coincide con un extremo.
- Alcance: JVM tema claro 360dp, no dispositivo ni todos los tamanos/fuentes.

## Fallback mapa 18:53
- Surface opaca + onSurface garantizan contraste de atribucion tanto claro como
  oscuro; renders fullscreen360x900 inspeccionados. Canvas ocupa bounds reales
  (antes180dp fijos incluso en fullscreen) y deja16dp de margen de ruta mas38sp
  para atribucion, sin trazo recortado ni cruce de texto en el fixture de2puntos.
- Corregida captura generica runCatching al aplicar estilo/capas: esos errores
  ya no activan fallback silencioso. Solo ausencia nativa y fallo de carga de mapa
  notificado por SDK degradan a Canvas. La camara/cartografia nativa siguen abiertas.

## Guardias revisadas 18:56
- WodTimerStore.update valida blockId ANTES de leer/reasignar el slot; un bloque
  nuevo en igual indice ya no hereda elapsed. Cambio de sesion elimina pendingEnd
  ajeno y blockId antiguo; consumePendingEnd usa commit comprobado.4tests nuevos.
  La politica legacy sin blockId no cambia ni migra datos (00fee1b4 sigue abierta).
- ExternalHealthDetailSheet: detalle y ruta async, asi como retorno del contract,
  comprobados con owner+record+identityRevision durable; cierre invalida instancia.
  Cubre A->B->A y proveedor no cooperativo tras cerrar;3tests del gate puro.
  Tests de gate no acreditan Activity HC ni ciclo de vida real de dispositivo.

## Paisaje compacto 19:08
- Fixture pausado620x360: avisos y metricas separados, atribucion libre.
  Acciones principales visibles; Descartar/Voz quedan bajo scroll del panel.
  Test hace scroll real y acredita que ambas son alcanzables. Render inspeccionado.
  No acredita fuentes grandes, todos los plegables ni cartografia nativa.

## Siguiente unidad preparada
- b73d77dc: HealthRecovery.swift corte0a640da8 trainingRecoveryTrendCard
  usa curva catmullRom, stroke3 redondo y gradiente vertical por valor0..10:
  rojo0..0.40, amarillo0.60..0.72, acento0.84..1.0. NO por distancia temporal.
- Android DayPointLineChart es compartido con otras metricas: agregar opcion
  especifica de readiness, por defecto lineal/paleta actual. No cambiar otras
  series. Conservar seleccion por distancia calendario, bounds0..10 y estado
  sin tendencia de una muestra. Render fixture multidia explicito antes de cierre.

## Readiness 19:15
- CatmullRom y gradiente por valor PORTADOS (readinessStyle opt-in); render multidia
  fixture explicito360claro inspeccionado. Suite mobile611/611(150XML).
  b73d77dc sigue verified-partial por dispositivo;70/735abiertas.

## pendingEnd 19:31
- 39a3f7f2 contrastada con WorkoutView.swift1362-1397 corte0a640da8.
  Android conserva checkpoint hasta guardar resultado con exito, no al montar
  el editor. Salir/volver recupera elapsed medido. Limpieza usa cuenta+revision
  durable del flujo y bloque original; refresca estado UI tras consumir.
- Test Compose desmonta/remonta y cambia pending manteniendo edicion manual
  activa. No acredita persistencia de texto manual al navegar ni Activity real.
  70/735 siguen abiertas; runtime no sustituido por JVM.

## Servicio WOD 19:40
- WodTimerService conserva binding owner/session/index/blockId del intent y lo
  usa en cada tick. Antes omitia blockId pese a la guarda en MainActivity.
  Slot reemplazado devuelve reloj no-running y detiene servicio.
- 2tests binding con store real local/doble monotonic cubren bloque nuevo y
  aislamiento cuenta/sesion. Sin iniciar servicio ni permisos/sensores.
  No cambia politica legacy sin blockId, no valida ejecucion background real.

## Lifecycle Comenzar 19:43
- Contrastado WorkoutLiveActivityCoordinator del corte: closedSessionIDs evita
  resucitar actividad terminada. LiveActivityService lleva owner+revision
  durable+gpsSessionID en intent/tick, con data URI unica en PendingIntent por
  login/sesion. Intent antiguo no muta nueva actividad; teardown solo pausa
  sesion vinculada.3tests gate puro; FGS/NotificationManager real pendientes.

## Correccion documental 19:46
- En260 un script propio escribio por error el contenido de la matriz prewindow
  sobre este inventario. Restaurado desde259 y reincorporada solo seccion nueva
  lifecycle. Evidencia original conservada; no se cambiaron clasificaciones por
  este error. Recuento desde matrices reales:579+156=735,50+20=70 abiertas.
- Mobile622/155XML ejecutada verde. Assemble conjunto --rerun-tasks260 supero
 120s durante compile mobile y fue terminado; no cuenta como verde. Proceso
 Gradle ausente tras corte. Pendiente assemble separado y domain/wear actualizados.

## Filtros biblioteca 19:52
- b4905ea1 tenia equivalente funcional pero sin contenedor modal. Portado
  ModalBottomSheet opaco con contenido separado capturable; cabecera/cierre,
  tarjetas y opciones existentes alfabeticas es-ES. Estado sort/filter
  independiente y seleccion no cierra. Render360claro inspeccionado.
- Diferencia de conjunto: Android descubre filtros desde catalogo, Apple lista
  casos fijos incluyendo WODs/Deportes (Android conserva rutas propias).
  No cerrar por render ni llamar falta de contraparte a esta diferencia.

## Rest-pause 19:58
- Reemplazado texto8+5+3+descanso comun por editor clusters individuales con
  REPS/DESCANSO numericos, boton ancho y lista. Conserva distintos descansos
  por cluster y valida5..30s como corte. Render360claro y test editando
 8reps/15s luego5reps/20s,31s rechazada. No caja dentro de caja.
- Diferencia ABIERTA: repositorio Android mantiene requisito2..8clusters,
  Apple puede guardar1; no se cambio validacion persistente en esta unidad.

## Rest-pause 20:02
- Diferencia minimo2 resuelta: permite1cluster. Guardado suma las reps de
  clusters y ya no exige rellenar campo base independiente. Test Compose de
  ActiveWorkoutCard recorre seleccion->8reps/15s->Anadir->Registrar con base
  vacia y verifica callback. Test repositorio almacena8reps y15s sin inventar.
- Tope previo Android8clusters sigue diferencia respecto Apple sin max explicito.
  No cambia ni reescribe registros antiguos.

## Rest-pause 20:05
- Tope artificial8 eliminado en UI/repositorio, test persiste9clusters18reps.
  Suma en Long con limite Int evita overflow sin limitar cantidad de clusters.
- Borrador permite quitar cluster antes de guardar, conserva resto con su
  descanso individual y renumera. Captura360claro tras quitar inspeccionada.
  No implica editar registros historicos ni persistir borrador al navegar.

## Preview Peso 20:08
-08790a22: preview Free omitia tiles que el corte conserva. Extraida
 WeightPreviewCard con aviso ficticio explicito y Actual/Objetivo/Delta
 derivadas del mismo fixture. Fondo surface distingue tiles surfaceVariant.
 Render360claro inspeccionado; no acredita todas las curvas/margenes previews.

## Unidades Play 20:13
- f7109bd7: faltaba toggle reps/m en ActiveWorkout/LiveSetRows/formulario
 clasico/correccion, aunque QuickLog/history si lo tenian. Portado flag y
 etiquetas, se rechazan calorias para estos nombres. logCurrentSet y
 reviseCurrentSet ya no rechazan metros en LOAD_REPS o reps en MACHINE_WORK
 cuando supportsRepsOrMeters.3tests repositorio cubren nombres distintos.
- Render LiveSetRows360claro inspeccionado; test prueba que solo tap explicito
 cambia unidad20reps->20metros sin convertir cantidad ni16kg. Duracion
 heredada LOAD_DISTANCE se conserva, diferencia con estilo Apple registrada.

## Estado programado lockscreen 20:28
-2e9d26fc/b6b7921b: notificacion ongoing con chronometer nativo, titulo,
 ejercicio, progreso y series desde activeSession persistido iniciado.
 Refresco tras guardado durable/reload y cancel al terminar/descarte/logout.
 Verifica owner/revision/snapshot aun vigente antes de efecto; tap solo abre
 sesion original bajo login original, otro estado va Inicio.
-3tests modelo/builder, no permisos ni notify real. Sin captura lockscreen,
 sin FGS nuevo/polling; no acredita plataforma/proceso muerto/metricas outdoor.

## Readiness 20:46
- primaryChartHeight corte220 portado a readiness real/vacio/preview. Preview
 usa acento plano como HealthRecovery780-808, no gradiente real. Geometria
 CatmullRom compartida conservada. Renders reales/preview360claro revisados.
- DUO altura dinamica205..270 segun columna aun pendiente;no afirmar adaptativo
 completo por altura portrait. Resto metricas no cambia en esta unidad.

## Readiness DUO 20:49
- Formula de HealthRecovery corte542-557 ahora calculada desde columna real
 del contenedor existente: max205/min270/(columna-2*16)*2/3; primary220.
 Se aplica a curva real,preview y ejes vacios. No añade padding de relleno.
- Prueba pura portrait y clamp inferior/intermedio/superior;fixture1000dp
 Free en dos columnas inspeccionada sin cortes. No implica validacion nativa.

## Preview ejercicio 20:52
- StatsView481-526 corte: Free preview evolucion ahora sesiones1..7 (eje0..8),
 no7fechas inventadas. Ticks1/3/5/7 con grid,dominio35..65,195dp,
 CatmullRom2.5dp redondo y clip; mismos pesos ficticios. Sin interaccion.
- Captura360dp clara inspeccionada, curva/grid/ticks alineados sin cortes.
 No altera grafica real de ejercicio ni acredita validacion de dispositivo.

## Sueño 20:59
- HealthRecovery1310-1398 corte: RecoverySleepChart sustituye linea generica
100dp por area/night-sky/CatmullRom2.4dp/altura220 oDUO max220,columna-150.
 Estado vacio conserva ejes0..10 en igual altura. Datos observados y fechas
 reales;seleccion tap/drag/accesibilidad;una muestra solo punto centrado.
- Dominio espejo normal max3.5,min-.6 / min11,max+.7. Diferencia defensiva
 EXPLICITA: si observacion cae fuera o limites se invierten,se ensancha a
 min-.6/max+.7 sin cambiar ni esconder noche. Test2h acredita caso.
- Renders360curva y1000DUO vacio inspeccionados. No prueba nativa.

## Fuerza OCR sin cabecera 21:27
- Subconjunto BoardImportParser.strengthBlockFromLines165-199 ybestMatch870-933
 portado como BoardStrengthLines,invocado SOLO si cabecera Añadir entreno
 yTODAS lineas tienen sets x reps,resuelven catalogo yestan acotadas.
 Mantiene series/reps/peso@,preferencia oficial+alias antescustom. Desconocido
 o fuera limites queda ruta Lite,no truncar ni mutar historicos.
- Mas conservador queApple(default3x8):no infiere sets/reps ausentes. Parser
 completo sigue GAP:secciones/ladder/partner/footnotes/rondas/movimientos.
- 4tests nuevos:orphan fuerza+AMRAP,alias vsCustom,limites/desconocido,
 precedencia oficial. Domain489/489,93XML21:27verde. Mobile integration
 suite yassemble de este cambio pendientes;ultimo645/162XMLyassemble280.
- Reparado overwrite propio282 por variable s reusada:restaurado281+esta nota,
 sin atribucion externa ni cambios de clasificacion;matrices735/70abiertas.

## Validacion post282 21:36
- HEADae1c96ef:mobile assembleDebug ejecutado63s verde21:30;TODAS162clases,
645tests,0fallos/errores en4lotes90/97/80/82s21:31..21:36. Conjunto de clases
 esperado=real,sin faltantes. XML nuevos consolidados repera285-mobile-xml.tar.gz.
- Domain489/489,93XML completa21:27;Wear8/8,1XML ejecutada21:20. Esto NO cierra
 parser completo ni validacion nativa. Matrices735/70abiertas sin cierres.
- Causa recurrente overwrite:284/285 introduce writer append-only separado,
 SHA256 esperado,validacion inventario/rechazo matriz,replace atomico con
 segunda comprobacion.4/4tests Pythonverdes. Esta nota entra por ese writer,
 no por buffer general compartido. Reescrituras requieren diff separado.

## OCR E2MOM 21:38
- Subconjunto adicional detectFormatHeader del parser completo corte: E2MOM10'
 ahora EMOM con intervalo120s/cap10min,antesmovimiento sin cabecera.
 E3MOM sin total conserva default15min,interval180s. Enteros acotados antes
 multiplicar ysin truncar input fuera rango.2tests nuevos,domain491/491,
93XMLcompleta21:38verde. Parser completo sigue GAP. Validacion mobile tras
 esta unidad pendiente;ultimo645/162XMLyassemble post282 ya verdes.

## Cabeceras explicitas OCR 21:47
- Subconjunto detectFormatHeader del corte500-632: esquema SOLO en linea
21-15-9,PARTNER WOD/YGIG ySTRENGTH/tecnica exactos separan bloques sin crear
 movimiento con nombre de cabecera. 4-3-3-2 PUSH PRESS NO separa bloque.
- STRENGTH con todas lineas setsxreps ycatalogo usa conversion acotada282;
 conserva titulo de cabecera. Sin coincidencia queda WOD strength revisable.
- Mas conservador queFull:tokens exactos en partner/strength,no contains
 general;ladder conserva titulo,NO propaga reps del titulo a movimientos.
 Completo sigue GAP(secciones,footnotes,rondas,otras rutas/resolucion).
- 2tests adicionales:4bloques+no falso header por repwave. Domain493/493,
93XMLcompleta21:47verde. Mobilepost287TODAS645/162en4lotes+assembleverde;
 mobile postesta unidad pendiente. No runtime/dispositivo acreditado.

## Integracion wire OCR 21:56
- Post288 mobile TODAS645tests/162XML en4lotes90/102/85/84s,0fallos,
 sin faltantes;assemble48s verde. No cambios produccion posteriores.
- Dos regresiones wire nuevas pasan dentro BoardScanImportTest:orphan3x8
 alias oficial sobrecustom conserva60kg eidentidad plannedSet;ladder/EMOM/
 partner conservan formato,120s,cap10min eidentidad bloque hastaJSONreview.
- Clase wire completa5tests ejecutada21:56;resto mobile es ejecucion post288.
 No afirmar suite monolitica nueva647. Domain493/93XML,Wear8/1siguen verdes
 con tiempos de sus checkpoints. Parser completo yruntime siguen abiertos.

## Metadatos OCR 22:01
- Full corte flattenMovements/roundMarker/isFootnote: ROUND1/ROUND2 exactos
 ylineas * o• ya NO producen ejercicios inventados. Se conservan enwodNotes;
 movimientos siguientes llevan Ronda N ennotas. PalabraROUNDdentrodeejercicio
 NO se interpreta metadata.3tests nuevosincluyenRESTBTWN conmetadata antes.
- RESTentre rondas ahora se procesa en mismo map de fila cruda,no indices
 paralelos que se desalinearian al omitir metadata. Domain496/496,93XML
 completa22:01verde. ParsercompletoGAP,caminosstructured/secciones/complex.
- Mobile post290pendiente;ultimoTODAS645/162post288+clasewire5/5post289.

## Secciones OCR 22:11
- FullsectionLabelTitle335-374:prefixes Weightlifting/Metcon/Gymnastics/etc
 extraen titulo entrecomillas osufijo;seccion sin cabecera timed conserva
 titulo yformato (Metcon/Conditioning ForTime,restoStrength). Conheader timed
 mantiene concatenacion previa deLite,titulo visible. Namedstrength con
 setsxreps resuelve porvia282;no infiere3x8 de lineas sin esquema.
- Tipo de seccion se conserva aparte del titulo (Metcon Fran no pierde tipo).
 RelojOCR22:02 ynumericospuros no crean movimientos.3tests nuevos,domain499
 /499,93XMLcompleta22:11verde. Completo sigueGAP(complex/otrasrutas).
- Mobilepost290TODAS647/162XML+assemble69sverde.Mobilepostestaunidadpendiente.

## Checkpoint parser 22:18
- Post291mobileTODAS647/162XML4lotes72/80/63/62s,0fallos,sin faltantes,
 assemble54sverde;domain499/93XMLcompleta22:11. Estado vigente posterior a
 notas previas pendientes. Matrices735/70abiertas;88db5bb7/c6f89c28 anotadas
 con subsets realmente portados,sin reclasificar ni cerrar parser completo.
- Full todavia difiere:default3x8 no inferido,complexmultisegment en fallback,
 percent/setsrange enfallback,otros headers/matching yvalidacion nativa.
- Recuperacion289 desdeclon65338db7+gitam hasta289 arbol942c373cc29c9eb22a984790419df040bf272bfb
 exacto;Wearassemble47s21:57nuevo packageverde. Wear8/1tests21:20.

## Complex simple OCR 22:20
- Subset FullparseWODMovementLine730-800:1POWER CLEAN+2PUSH PRESS ahora
2movimientos tipados,notasParte1/2y2/2;cada segmento cantidad explicita.
- Restriccion deliberada:sin parentmultipliers/repwave/sharedloads/cargas
 kg-lbs/@/#/slash. Esos casos siguenreviewLiteoriginal+rawenwodNotes,no
 se redistribuyen pesos ni se inventan cantidades. No paridadFullcompleta.
-3tests:split explicito,multiplier intacto,cargaparent intacta. Domain502/502,
93XMLcompleta22:20verde. Mobilepost293pendiente;ultimo647/162completo291.

## Validacion y recuperacion293 22:27
- Mobilepost293TODAS647/162XML4lotes76/77/65/64s,0fallos,sin faltantes,
 assemble42sverde.Domain502/93XMLcompleta22:20.Wear8/8,1XMLREEJECUTADA22:26
 test ejecutada,no cache,40sverde. Wearassemble anterior21:57.
- Backup293 recuperado desdeclon limpio65338db7+gitam hasta293:arbol
3cc8c123295f0dfb4affe46239ad57a7a331621a IDENTICO aloriginal293.
- Completo parser ydispositivo siguen abiertos.735/70abiertas sin cierres.

## OCR porcentaje/setsrange 22:29
- FullparseWODMovementLine633-668:prefijoSets1-2 y#70%/@>80% extraidos
 como notasSeries1-2/70%/>80%,sin contaminar reps/nombre ni fabricar kg.
- Hardening subsetfuerza282:rechaza% yRPErange antes leer@peso;se mantiene
 ruta movimiento/rawreview,no interpreta70% ni6-8como70kg/6kg. Limite
 explicito:no convierte intensidad enplannedsets typed enesta unidad.
-2tests nuevos,domain504/504,93XMLcompleta22:29verde.Mobilepost295pendiente;
 ultimoTODAS647/162post293+assemble42s, Wear8/1reejecutada22:26.

## Evolucion real ejercicio 22:38
- ExerciseProgressView chartBlock/chartYDomain corte:altura220(antes120),
 CatmullRom azul0A84FF,dominio paddingmax8%/1 ytope1RM incluye mitadvalor.
 Xyseleccion porfechaobservada,noindiceordinal;inset8dp protegeextremos.
-2tests puros domainbounds/calendarspacing,renderchart220/full1000alto1400
 inspeccionados sinrecorte. Fixtureviejo1000x470recortaba chart ampliado,
 ajustadoaltura prueba,no resultado produccion. Todasetiquetasvisibles.
- Paridadparcial explicita:axes/grid,empty<2 ytarjeta interior aun difieren;
 unamuestra conserva punto sin tendencia,noafirmarFullchart. Mobilefocalizado
 verde;completa+assemblepostestaunidadpendientes. Sin cambiardatoshistoricos.

## Evolucion sin tendencia 22:46
- ExerciseProgressView.chartBlock corte:count<2 conserva ejes220dp con
 chartYDomain ymensaje cero/una muestra;NO linea nipunto de tendencia.
 Ultimo valor/fecha real siguen visibles aparte,datoshistoricos intactos.
- Focalizados4/4render verdes tras actualizar expectativa texto viejo a
 mensaje delcorte. Captura1000singleinspeccionada,ejes ytexto sinrecortes.
- Mobilepost296TODAS649/163XML4lotes+assemble74sverdes;postestaunidad
 completa+assemblependientes. Restoaxes/grid/cardinterior/runtimeabiertos.

## Validacion297 22:51
- Mobilepost297TODAS650/163XML4lotes58/64/53/54s,0fallos,sin faltantes;
 assemble36sverde.Domain504/93XML22:29 yWear8/1real22:26,no reejecutadas
 en297. Renders chartreal220/full1000 ysingleinspeccionados. No dispositivo.
- Ejercicioreal296/297:altura/curva/domain/fechaX yestado<2 portados;
 axes/grid/cardinteriorpendientes. Parsercompletoyruntimeabiertos.
-735/70abiertas sincierres,no push. Las notas anteriores conpendientes
 mobile296/297 quedan superadas por esta ejecucion real completa.

## Ejes evolucion 22:57
- ExerciseProgressViewchartBlock410-437:superficieinterior12dp/radio12,
 Ylabels/domain real ygrid0.5dp,Xmeses locales,selecciondashed3/4dp.
 Labelmismomes solo1,no dosnov redundantes. Plot220dpconclip.
- AproximacionAndroid explicita:ticksYlow/mid/high ygridX0/.5/1,noalgoritmo
 automaticoSwiftCharts,no afirmar pixelparity. Guardiaindice seleccion.
- Nuevofixture360datosirregulares+1000full inspeccionados,curva/grid/labels
 enteros;focalizados7tests verdes. Mobilecompleta+assemblepost299pendientes.
 Domain504/93yWear8/1siguen checkpoints previos.735/70abiertas,sincierres.

## Preview fisiologia 23:05
- HealthRecoverypreview810-858/height560:VFCFree usa diasordinal1..7/eje0..8,
 CatmullRom sin marcadorfinalestatico,128dp oDUO max128/columna-(330extra
 vitals/265sinextra). Datosficticiosfijos,NOdiascalendarinventados.
- DominioYAndroid explicito min-2/max+2 para margen,noautodomainSwift.
 Formulaaltura conectada SOLOpreview enestaunidad,vitalesPro100dp aunGAP.
-2tests(formula4casos+render128),PNGs360/1000inspeccionadossinrecortes.
 Post299mobileTODAS651/163XML+assemble75sverde;post300completa/assemble
 pendientes. Domain504/93Wear8/1siguen checkpoints anteriores.

## VFC observada 23:19
- Post300mobile653/163XML,0fallos/errores/omitidos,4lotes70/77/62/62s.
- HealthRecovery930-994:VFCProlineal128dp/formulaDUO/latestextrafull,
 sinmarcador estatico,niconseleccion;regladiscontinua3/4dp yfecha/valor
 alseleccionar,muestrafinalvisible y<2 axes0..100sinlineainventada.
- Renders360(no/single/multiple) y1000(162dp) inspeccionados. Focalizados
 verdes79s+interaccion2tests46s. Ensayo previo falló captura de nodo fusionado:
 corregido useUnmergedTree,no problema de producto. Compilacion inicial
 excedio120s;no se contabiliza comosuiteverde.
- SoloVFC;resto constantes aun chartslineales100dp(no barras98Apple),
 ticks aproximadosAndroid,noSwiftautomatico. No cierres ni validacionnativa.
- AssembleDebug alcanzado dentrocomandointerrumpido;separadoverdependiente.
 Mobilecompletapost301pendiente;domain504/93Wear8/1anteriores.

## Barras constantes 23:28
- Post301mobile655/163XMLreales,0errores/fallos/omitidos,4lotes68/76/61/62s.
 Copia301recuperada baseline+gitam=arbol84d3ec9d57203d4366e08128057996ad6a7d6095.
- HealthRecovery1000-1090:pulso/respiracionen2barras98dp,radius3dp,
 cajas12dp/padding10,gap10,escalasindependientes yfecha seleccioncompartida
 con nearestencadadataset. Tap/drag/accionesaccesibles,nolecturasreales.
- Diascalendarrealesconhuecos,singledaycentrado,axes0..100+Sin datosvacio.
 EscalaYAndroid0..max yanchura0.7dia son aproximaciones,noautoscalaSwift.
- Focalizados10tests/3XMLverdes53s;compilacion59s. PNG360observado,
 single/vacio yseleccionambas seriesinspeccionadas. Suitecompleta302pendiente.
- ExtrasSpO2/temperaturaaunlineasredundantes100dp(noportadasen302),
 latestdaytiles sin cambios.735/70abiertas,no push ni cierre runtime.

## Revision constantes, avance parcial 23:37
- Bloque validacioncompletadebarras302:657/163XMLreales0fallos/errores/
 omitidos,4lotes67/73/61/61s. Solo bateriacerrada,no paridadnativa.
- Bloque revisiondiferenciasconstantes/graficos sigueencurso:subhueco
 yaidentificado deSpO2/temperatura historialredundante retirado. Corte
 HealthRecovery0a640da8:1070latestonlytiles,4patchescompuestos sintocar
 HealthRecovery. Mantieneultimo diafullindependientedelrango yrestriccion
 muñeсаabsoluta+coincidenciasueño;sin cambiarlecturas nivalores.
-2testsregresion:extrasanterioresnocuelan enultimodia ytilesultimodia
 fuera del rango siguenvisibles. Focalizados6/2XMLverdes51s,compile48s.
 PNG360x1844inspeccionado,todosvalores/mensajesenteros sinlineasextras.
- Mobilecompleta303pendiente,assemble303pendiente;domain504/93Wear8/1
 anteriores.735/70abiertas,ejesAndroidaproximados,runtimeabierto,nopush.

## Continuidad de estados 23:43
- Bloque revisionconstantes/graficos:5filas dematriz anotadasensuestado
 vigente,conservando historia ystatus verified-partial. Pendientes de
 subsets277-303 quedan explicitamentesuperados,no toda la fila cerrada.
- Bateria303659/163XML0fallos/errores/omitidos4lotes65/73/58/59s,
 assemble39sverde. Cardio/kcal yautoejes/ticksaproximados aunpendientes;
 runtime735/70abierto,domain504/93Wear8/1anteriores,nopush.
- Sin cambios ejecutables304;la validacion303no sepresentacomoejecucion304.

## Revision graficos, avance kcal 23:47
- Mismobloque revisionconstantes/graficos:subhueco kcalantespendiente
 ahora area naranjaFF9F0A gradiente.32/.02+CatmullRom2.25dpredondo210dp.
 No barras96dp;dominioY0..max(1,peak*1.18real/1.28preview),dominioX
 periodoelegido ypreviewprimer/ultimodia+-0.5dia. Tap/drag/accesibilidad.
- Vacio/allzeroaxes0..600210dp sinfabricarmuestras. Valorespreparados
 sin cambios;flagpreviewexplicitdesdeProgresoFree,noinferencia porvalor.
- TickYAndroid0/mitad/max yXprimer/ultimo son aproximaciontodavia:
 tickDatesgranularidadSwift/greedylabels/gridcompleto/tarjetastats noportados.
 Cardio96dp/banda aunpendiente,no tocarzonasFC/intensidaddecisionusuario.
-4focalizados/2XMLverdes65s(3nuevos),PNG360preview yvacioinspeccionados.
 Compilacion72s. Completa305pendiente;ultima303659/163XMLassemble39s.
 Sin cambioestadosmatriz735/70,nativopendiente,no push.

## Revision kcal, avance parcial 23:56
- Full305mobile662/163XMLejecutados64/73/58/60s0error/fallo/omitidos,
 assemble73sverde. Bloquerevisiongraficos sigue abierto.
- Subhuecosyatrazados305:tickDatesportado stride diaweek1/restoN/6
 incluyendoultimo,gridX0.5dp enticks reales. Etiquetasformatogranularidad
 yreglagreedyAndroidanchofijo(aproximacion,nofontmetricsSwift).
- StatsMedia/dia/Periodoant/Variacion ahoratres superficiescentradas10dp,
 incluso sinserie conplaceholder,despuesgrafica. UsaCalorieAverageStats
 existente sinrecalcularaqui ni cambiardatos.
-5focalizados/2XMLverdes44s,compile64s;PNG360con7dias ystatsinspeccionado.
 Yticks0/mitad/max aunaproximados;cardio190/3curvas aunpendiente.
 Completa306pendiente,domain504/93Wear8/1previos.735/70,nativopendiente.

## Revision graficos, avance cardio 00:05 28oct
- Full306mobile663/163XMLreales64/72/61/58s0fallos/errores/omitidos.
- Mismobloque revisionconstantes/graficos:cardioyahuecopendiente ahora
3curvasCatmullRom190dp:Minazul0A84FF1.75,MediaFF453A2.25,MaxFF9F0A1.75,
 sin banda. Dominiocorte min-12/max+14 real,-18/+22preview,low>=40 yspan>=24.
- DominioXperiodo/preview ytickDates compartidosconkcal,seleccionnearest
 tap/drag/accesibilidad yregla3/4dp. TilesMin/Media/Maxcentrados,escalas
 propiasdelperiodo. Vacioaxes60..160190dp,noobservacionesinventadas.
- No cambiosenzonasFC/intensidad(decisionpendiente),lecturas ni series.
 Yticks ygreedylabelsAndroidaproximados. Surfacecombinedcontinua,noigual
 layouttarjetasseparadasSwift.8focalizados/3XMLverdes64s,compile65s;
 PNG360curvas/vacioinspeccionados. Completa307+assemblependientes.
-735/70abiertas,nativopendiente,nopush;domain504/93Wear8/1anteriores.

## Revision graficos, continuidad 00:15 28oct
- Full307mobile666/163XMLreales66/80/65/62s0error/fallo/omitidos,
 assemble73sverde. Ultimabateriacompleta,noejecucion308.
- Mismobloque ysubhuecoyaindicado:cardiokcalseparadosahora2cards
 ordenCardio->Calorias,gap12,padding10horizontal/20vertical,titulos y
 ejemplo/totalenfila;statsdespuesdeplot,sinsuperficiecombinadaanterior.
- Hallazgonuevoenrevision:305/307permitianseleccionenpreviewFree,
 contrarioStatsViewfreeHealthPreview allowsHitTestingfalse. Regresion
 propia corregida:tap/drag/customactions inactivos sipreview. Datos reales
 mantienenseleccion.3testsverdes64s,nointeraccionFreey2seleccionesreal,
 compile62s. PNG360x742inspeccionado,curvas/ticks/tileslegibles.
- Gridcompleto4cardsadaptativoSwift aunpendiente:AndroidseccionScores/
 peso estaenseparadositems,estas2cards aunverticales. Noafirmarreticula
 totalni cierreblock.Yticks/greedylabelsaproximados,nativopendiente.
- Completa308/assemblependientes;735/70nopush,domain504/93Wear8/1previos.

## Revision graficos, reticula parcial 00:25 28oct
- Full308mobile667/163XMLreales63/76/63/61s0fallo/error/omitidos,
 assemble39sverde. No cierre deparidad.
- Mismobloque revisionconstantes/graficos,subhuecoreticulaglobal4cards
 conocido308:score/cardio/kcal/pesoahora1componentegrid1/2columnas
 umbral620,gap12,ordenfuenteenFree/Pro. PermisoSalud yupsellfuera,
 tras4cards;si chartsausentesconservacardsvacias,nodatosinventados.
- Pesorealextraidoasin cambiodelregistrocallback/owner/saver;test
 entrada76,2->callback76.2.3testsrender/editorverdes89s;previosfixtures
 +BodyWeight/Previewverdes69s. PNG360/1000inspeccionadossinrecortes.
- Scoresiguegeometria100/130Androidnoportadaalafuente;Yticks/greedylabels
 aproximados yruntimependientes. Reticula noequivale a todoschartsportados.
- Completa309+assemblependientes,735/70,nopush,domain504/93Wear8/1previos.

## Revision graficos, avance Score 00:35 28oct
- Full309mobile670/163XMLreales70/85/67/68s0fallos/errores/omitidos,
 assemble84sverde. Ultimabateriacompleta,noejecucion310.
- Mismobloque revisionconstantes/graficos,subhuecoScore conocido309:
 StatsView971-1110 corte:205dp real/preview/vacio,C at mullRom2.5dpaccent,
 dominioY0..10/ticks0/5/10 yXperiodoelegido/preview+-0.5dia,clip.
- Realnearestfecha/valor,tap/drag/accesibilidad yregla3/4dp;preview
 nointeractivo,ficticioexplicito;mediaresumen/header ycaptionhistorial.
 Preparaciondailyverified sin cambios;range/mondaydelaseleccionconectados.
-5focalizados/2XMLverdes56s,compile83s;PNG360real/preview y1000vacio
 inspeccionados,alturas/ticks/textosenteros. Xautomatic4Swift sigue
 aproximadoAndroid3grid/2labels;vacioaxeshelpernoesSwiftcompleto.
- Completa310/assemblependientes;735/70nativopendiente,nopush,
 domain504/93Wear8/1anteriores. Bloquerevisionabierto.

## Revision graficos, vacios 00:44 28oct
- Full310mobile672/163XMLreales75/91/68/68s0fallos/errores/omitidos,
 assemble60sverde. Referenciaanterior,nobateria311.
- Mismobloque,subhuecovaciohelperconocido310:ProgressEmptyChartcorte
 ProgressTrendCards6-35:ahora3labelsmin/medio/maxlateral ygridhorizontal
0.6dpdash3/4,noLvertical/basecontinua. Alturaplotconservadas205/210/190/
220/128/98seguncaller,sinseriesinventadas. Mensajes aundebajo,nooverlay
 centralSwift:gapexplicitopendiente,nopixelparity.
- Focalizados7tests/2XMLverdes49s,compile59s. PNG360kcal/cardio/recovery
 inspeccionados,tickscentrales ytextos/tileslegibles. Suite311pendiente.
-735/70abiertas,nativopendiente,nopush;domain504/93Wear8/1previos.

## Revision graficos, overlayvacio 00:53 28oct
- Full311mobile672/163XMLreales70/81/61/64s0fallo/error/omitidos,
 assemble47sverde. Copia311recuperada baseline+gitam arbol
 a5e3fd0c9aef24914c1d0d5a1166ff9e6e4291bfidenticooriginal;amboslimpios.
 Recuento579/50+156/20=735/70,noApps/Packagesdiffacumulado.
- Mismobloque ysubhuecoya311:mensajevacioahoracentradosobreplot,
 24dphorizontal,wrapcentro,onSurfaceVariant. Aplicadokcal/cardio/score/
 peso/readiness/sleep/VFC/bar tiles,sinserieinventada ni lecturas.
-12focalizados/3XMLverdes61s,compile72s;PNG360kcal/recoveryinspeccionados,
 mensajeslegibles/nochoqueticks.Alturasplotintactas.Yticksconserie y
 greedylabelscontinuaproximados,nativopendiente,no cierreblock.
- Completa312+assemblependientes;domain504/93Wear8/1previos,nopush.

## Revision graficos, etiquetas 01:02 28oct
- Full312mobile672/163XMLreales66/80/66/65s0error/fallo/omitidos,
 assemble48sverde. Ultimabateriacompleta,noejecucion313.
- Mismobloque ysubhuecogreedylabelsconocido:ancho38/45dpfijo sustituido
 pormedicionComposeTextMeasurerconestilo10spcomofuente,cadanombrede
 mes/dia+escalausuario. Greedyordendatescongap3dp,clampinsideplot,
 rechazaetiquetamasanchaplot;gridticksnoalterados aunqueocultalabel.
-2tests nuevos:geometriacollision+bounds yfixture360mesesenero-octubre.
 Focalizados8/2XMLverdes49s,compile66s. PNG360meses y7dias inspeccionados,
 sinchoques/recortes. NoafirmaralgorithmofontmetricsSwiftidentico.
- Yautoaxes yXScoreautomaticopendientes,nativopendiente735/70,nopush.
 Completa313/assemblependientes;domain504/93Wear8/1anteriores.

## Revision graficos, fixtureFree 01:10 28oct
- Full313mobile674/163XMLreales63/74/60/61s0fallo/error/omitidos,
 assemble87sverde. Referenciaanterior,nobateria314.
- Mismobloque:hallazgonuevocontrastandoProgressChartBuildercorte40-82:
 previewAndroidomitiócaloriesDailyAverage/previousCaloriesDailyAverage.
 Seriesficticias correctaspero3tiles salianguiones. CorregidosSOLOcampos
 preview:media7diaspropiosficticios yprevious500ficticioexplícito.
- Testnuevo507kcal/500/+1%,3focalizados/2XMLverdes60s,PNG360inspeccionado,
 3tileslegibles,avisoejemplo/noseleccionconservados. Datosrealesintactos.
- Completa314+assemblependientes.Yautoaxes/XScoreautomatico/nativo
 pendientes735/70,nopush,domain504/93Wear8/1anteriores.

## Lector completo, avance parcial 01:19 28oct
- Transicionreportadaparent01:15:revisiongraficosquedaabierta,Yautoejes/
 XScoreautomatico/fontmetrics/nativo. Ultimovalidado314mobile675/163XML,
 domain504/93Wear8/1realmente reejecutados01:14;assemblemobile34s.
 Copia314recuperada5fb41cf4133bca11293eeb7d0d69523417bcb1cbidentica.
- Bloquelectorcompletosigueparcial;subhuecoconocidomultiplicadorcomplejo
 descargado(corteBoardImportParser705-800):3X1PushPress+1OHSQsplit2partes
 connotesComplejo×3,NOtriplicarepsnisets. Solo1..200y2+partesconcantidad
 explicita,sinwave/cargacompartida/@/#/kg/slash. OrigenwodNotesconservado.
-2nuevostests+testviejoactualizadoquedocumentabalimitacionyaimplementada.
 Primercompleto506/93fallóSOLOexpectativaviejaunsplit;corregidasegunfuente,
 completofinaldomain506/93verde40s0error/fallo/omitidos. Noparserfull.
- Mobile/Wearpost315yassemblependientes;735/70nativopendiente,nopush.

## Lector completo, ola descargada 01:27 28oct
- Full315mobile675/163XML63/75/61/59s,domain506/93XML40s,
 Wear8/1XMLreal+assemble43s yassemblemobile36sverdes,0fallos/errores/
 omitidospor modulo. Solo baterias,nolectorfullninativo.
- Mismobloquelectorparcial,subhuecowavecomplejoyaregistrado:ola
 descendente4-3-3-2PushPress+2AirSquatsplit;repSchemeSOLOprimerparte,
 repsnullprimera,reps2segunda,notaSeries4-3-3-2compartida,ParteN/total.
- Ascendente5-10,rangoinvalido/overflow,cargacompartida/@/#/kg/slash
 conservadosreviewunsplit. Catalogmatchingexistente+origenwodNotesintactos.
-2tests nuevos,domaincompleto508/93XMLrealverde51s0error/fallo/omitidos.
 Mobile/Wear316+assemblependientes.735/70nativopendiente,nopush.

## Lector completo, par kgcomplejo 01:36 28oct
- Full316mobile675/163XML65/79/61/59s,domain508/93XML51s,
 Wear8/1XMLreal+assemble38s yassemblemobile34sverdes,0fallos/errores/
 omitidospor modulo. Solo baterias,nolectorfullninativo.
- Mismobloque,subhuecocargapadreyaabierto:parH/MexplicitoKGalsufijo
 de2+partes ahoraextraidoprimeropre-split,SOLOprimermovimientorecibe
 cargaparental,comodicecorteBoardImportParser694-700/770-777.
 Menor/mayornormalizados comohelperexistente;noautoconvertirLBnicargas
 implicitas. Validafinito/positivo;slashsinKG/@/%/cargalocalmantienereview.
-1testdominio+1wire nuevos;domaincompleto509/93XMLverde26s0fallo/error/
 omitidos;wiremobile6/1XMLverde55s. Carga50/35kg solo primerJSON,nosegundo.
- Mobilecompleta/Wear317+assemblependientes.735/70nativopendiente,nopush.

## Lector completo, limites de sufijo kg 01:44 28oct
- Continuidad: full317 mobile676/163XML,domain509/93XML,Wear8/1XML y ambos assemble verdes. No cierre funcional ni nativo.
- Hallazgo nuevo en el subconjunto317: un signo negativo separado (- 25/40kg) o exponente (1e3/40kg) podia reconocer una cola positiva y separar indebidamente. Prueba de regresion fallo con negativo separado antes de corregir.
-318 exige frontera de token y rechaza signo negativo separado antes del par; valores cero, negativos y decimales malformados quedan en review sin dividir. No cambia la interpretacion de cargas validas.
- Bateria dominio completa realmente ejecutada510/93XML,47s,0fallos/errores/omitidos. Mobile/Wear318 pendientes; matrices735/70 sin cierres. Lector completo sigue parcial; no push.

## Lector completo, anotaciones compartidas 01:53 28oct
-318 validacion completa: mobile676/163XML ejecutados62/82/60/63s;domain510/93XML;Wear8/1XML reejecutado con ambos assemble44s,0fallos/errores/omitidos. Backup318 recuperado desde65338db7,arbol identico fb0f7ebc4f8bf630a48f80dbdb7d1331a04447a1.
- Mismo bloque parcial: subconjunto319 extrae porcentaje #70%/#>80%/@70% y RPE entero @6-8 antes de separar complejo; comparte notas en todas las partes, siguiendo BoardImportParser630-669/749-790. No asigna porcentaje como carga/reps/sets. Combinacion ola+RPE+parKG mantiene carga solo en primera parte.
- RPE decimal/at simple, alternativas escala y cargas implicitas siguen en review sin separar; no default3x8. Dos tests nuevos, mas limites en regresion. Dominio completo512/93XML y wire mobile6/1XML verdes; mobile completa/Wear319 pendientes.735/70sin cierres,no push,nativo pendiente.

## Lector completo, escala ultima parte 02:01 28oct
-319 bateria completa mobile676/163XML63/77/62/64s,domain512/93XML26s,Wear8/1XML+ambosassemble48s verdes0fallos/errores/omitidos; solo bateria cerrada.
- Mismo bloque parcial,subconjunto320: alternativa de escala con slash espaciado se extrae antes de dividir complejo y se asigna solo a ultima parte, segun fuente BoardImportParser669-680/788. Varias alternativas se conservan expandidas. Par H/M espaciado KG sigue siendo carga solo primera parte,nunca escala.
- Alternativa con '+' ambigua queda sin dividir para review; no inferir receta ni carga. Porcentaje y RPE compartidos preservados en JSON.2 tests dominio nuevos y1wire. Dominio514/93XML54s ywire7/1XML verdes. Mobile completa/Wear320 pendientes.735/70sin cierres,lectorfull/nativo pendientes,no push.

## Continuidad matrices lector parcial 02:07 28oct
-320 bateria completa mobile677/163XML63/76/60/62s,domain514/93XML54s,Wear8/1XML+ambosassemble48s verdes0fallos/errores/omitidos. Backup320 recuperado desde65338db7: arbol33ca6f62dd935d3b2b8452377ac6057351cd1adf identico,clon limpio.
- Reconciliadas notas de c6f89c28/88db5bb7 con subsets315-320; conservados estados verified-partial y verified-partial+GAP,ninguna fila cerrada.735/70. Restan default3x8 deliberadamente no inferido,rutas/fallback/matching y runtime;subsetcomplejo atsimple/decimalRPE/cargaimplicita aun review.
-321 solo documentacion; sigue bloque lector completo parcial y revision grafica abierta. No push ni cambios Apps/Packages.

## Lector completo, prefijo de rango de series 02:09 28oct
- Mismo bloque parcial,subconjunto322: prefijo SET(S)1-2: ahora extraido antes de separar complejo y compartido como nota Series1-2 en todas las partes,segun BoardImportParser636-647. No fabrica plannedSets; sigue compatible con multiplicador,porcentaje,RPE yescala ultima parte. Acotado1..200 ascendente;ceros/invertido/overflow quedan sin dividir para review.
- Verificado corte compuesto: cuatro patches durables inspeccionados;ff94e6ad cambia canonicalName,no esta extraccion.2tests nuevos. Dominio516/93XML54s ywire7/1XML verdes0fallos/errores/omitidos. Mobile completa/Wear322 pendientes;ultima completa320mobile677/163domain514/93Wear8/1.735/70sin cierres,no push,nativo pendiente.

## Lector completo, token @ final 02:17 28oct
-322 bateria completa mobile677/163XML64/77/59/59s,domain516/93XML54s,Wear8/1XML+ambosassemble49s verdes0fallos/errores/omitidos. Solo bateria cerrada.
- Mismo bloque parcial323: @numero entero/decimal al final del complejo pasa como nota literal compartida, no peso ni reps ni plannedSets, siguiendo BoardImportParser665-668. No etiqueta arbitraria RPE. Subconjunto acotado al sufijo; token con kg/exponente/signo/decimal malformado y RPEdecimal siguen sin dividir para review.
-2tests nuevos,dominio518/93XML55s ywire7/1XML verdes0fallos/errores/omitidos. Mobile completa/Wear323 pendientes;735/70sin cierres,default3x8 no inferido,nativo pendiente,no push.

## Lector completo, limites de partes 02:26 28oct
-323 bateria completa mobile677/163XML67/80/62/59s,domain518/93XML55s,Wear8/1XML+ambosassemble50s verdes0fallos/errores/omitidos. Backup323 recuperado desde65338db7,arbol747c01cc663b8732399e53e2dffb17267f99825a identico,clon limpio.
- Hallazgo nuevo en subconjunto de complejos: filtro de partes vacias aceptaba '++' eliminando evidencia, y cantidad explicita sin cota podia perder reps por overflow. Regresion fallo antes de corregir con doble '+';324 conserva linea sin dividir ante parte vacia o cantidad fuera1..100000. No agrega cantidades inferidas.
-1test nuevo de6casos;dominio519/93XML50s ywire7/1XML verdes0fallos/errores/omitidos. Mobile completa/Wear324 pendientes. Mismo lector parcial735/70sin cierres,no push,nativo pendiente.

## Lector completo, anotacion no soportada en escala 02:35 28oct
-324 bateria completa mobile677/163XML63/80/63/62s,domain519/93XML50s,Wear8/1XML+ambosassemble50s verdes0fallos/errores/omitidos. Solo bateria cerrada.
- Hallazgo nuevo del subconjunto320: al extraer escala se ocultaba de la guardia posterior un @/# no soportado (RPEdecimal uotro token). Regresion fallo antes del arreglo.325 rechaza dividir cuando una alternativa aun contiene @/# despues de extraer anotaciones soportadas. No elimina contenido ni inventa carga;linea queda para revision.
-1test de3casos nuevo;dominio520/93XML51s ywire7/1XML verdes0fallos/errores/omitidos. Mobile completa/Wear325 pendientes. Mismo lector parcial735/70sin cierres,nativo pendiente,no push.

## Lector completo, precedencia REST 02:44 28oct
-325 bateria completa mobile677/163XML67/84/67/67s,domain520/93XML51s,Wear8/1XML+ambosassemble50s verdes0fallos/errores/omitidos. Backup325 recuperado desde65338db7:arbola60f7aaa1d7ab7b3ad7334a81a0a21bbd27a4476 identico,clon limpio.
- Hallazgo nuevo: complejo con REST/DESCANSO se separaba en trabajo+descanso,cuando fuente BoardImportParser731-734 da precedencia al descanso de linea completa. Regresion fallo antes de corregir;326 enruta linea REST completa al parser existente antes de separar. No agrega movimiento de trabajo ficticio.
-1test nuevo conREST/DESCANSO;dominio521/93XML66s ywire7/1XML verdes0fallos/errores/omitidos. Mobile completa/Wear326 pendientes. Mismo lector parcial735/70sin cierres,no push,nativo pendiente.

## Lector completo, candidatos exactos en complejo 02:59 28oct
-326 bateria completa mobile677/163XML92/114/84/84s,domain521/93XML66s,Wear8/1XML+ambosassemble97s verdes0fallos/errores/omitidos. Solo bateria cerrada.
- Mismo bloque parcial327: complejos acotados ahora usan candidatos por segmento original, quitando modificadores BN/BTN/etc como fuente870-899, prioridad exacto oficial>alias editorial>exacto custom. Respuesta mantiene id/nombre elegidos en matching posterior. No se habilita fallback fuzzy ni cambia matching de lineas simples. Helper existente de fuerza conserva fuzzy por defecto.
- Regresion fallo antes de corregir con alias oficial frente a custom conBN;2tests nuevos cubren prioridad exacta y ausencia defuzzy. Dominio523/93XML42s ywire7/1XML verdes0fallos/errores/omitidos. Mobile completa/Wear327 pendientes.735/70sin cierres,lectorfull/fuzzy/rutas/nativo pendientes,no push.
