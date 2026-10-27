# Inventario de trabajo restante (27 oct 20:19 CET)

Clasificacion COMPLETA (0 unverified) en ambas matrices; esto NO es cierre funcional.
Fuentes: AUDIT_579_PREWINDOW_MATRIX.csv (579 filas) + AUDIT_POSTBD4_WINDOW_MATRIX.csv.

## Estado vigente (recuento directo 27oct20:19 CET)
-735 filas SHA validas:579prewindow+156postwindow.
-70 abiertas:50prewindow+20postwindow. Abierta = campo6 comienza partial,
 verified-partial o in-progress. Cambiar partial a verified-partial no cierra.
- Mobile632/632(160XML) ejecutada completa20:18. Domain485/485(92XML) y
 Wear8/8(1XML) ejecutadas19:48. Cero fallos/errores por modulo.
- Assemble mobile ejecutado verde269;270 solo agrega test. Wear assemble
 verde UP-TO-DATE19:48, no se presenta como compilacion nueva.
- Readiness curva Catmull-Rom+gradiente por valor YA portadas (tree251/252);
 b73d77dc permanece abierta por runtime. No inferir pendiente desde notas viejas.
- Cambios256..270: pendingEnd hasta guardado; bindings servicios por identidad;
 peso tiles/previews; filtros opacos/reset; rest-pause individual; reps/metros
 Play con pruebas de filas/clasico/correccion. Ver notas y matrices para limites.
- Runtime dispositivo, zonas FC decision, parser completo, meteo ruta,
 Live status entrenos planificados y rama Diario siguen abiertos.
- Ninguna nota historica posterior sustituye este recuento ni la matriz viva.
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
- Cursores interactivos graficas recuperacion (b73d77dc/42f02b82)
- Estilos parciales a verificar en runtime (margenes, miniaturas, previews)
- Gaps post-window ya conocidos: widgets/LiveActivities, Health-ruta upload, fullscreen map, tap targets/overlay, Health Connect por rango, tiles resumen

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
