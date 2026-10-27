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
