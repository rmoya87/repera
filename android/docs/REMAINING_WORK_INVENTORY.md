# Inventario de trabajo restante (27 oct 15:56 CET)

Clasificacion COMPLETA (0 unverified) en ambas matrices; esto NO es cierre funcional.
Fuentes: AUDIT_579_PREWINDOW_MATRIX.csv (414 filas) + AUDIT_POSTBD4_WINDOW_MATRIX.csv.

## Contadores (recontado EXACTO 16:27 CET sobre campo 6 de ambas matrices)
- Pre-window: 48 partial + 2 in-progress + 1 verified-partial+gap = 51
  (los 2 in-progress son 661e65f4/9947c212 zonas FC: bloqueo preservado para decision usuario)
- Post-window: 21 (recuento directo 16:47: cierres recientes 1c729659/056cba8b/1c9afcd0/83253491; 88db5bb7 REABIERTO como verified-partial+GAP: parser de importacion completo sin contraparte Android = diferencia funcional, no n/a)
  (39a3f7f2 verified-partial 17:58: userFinished PORTADO (pendingEnd persistido + auto-prefill For Time una vez, 7 tests); countdownFinished n/a estructural; runtime abierto;
   00fee1b4 verified-partial+GAP: legacy sin blockId indistinguible, slot
   unico sin TTL, sin migracion por decision del padre;
   b2bb19eb cerrado 16:06; 479d8407 cerrado 16:10;
   f6f13169 done 16:16: checkpoint onStop + cache geometria estructural, pendiente runtime;
   fafe016a partial 16:24: RouteMapTapTarget portado en CardioRouteSection con tests JVM;
   26a625be partial 16:26: velo oscuro + trazo 3 capas dentro de MapLibre, sin decision usuario)
- TOTAL abierto: 72 filas (51 pre + 21 post, recuento DIRECTO sobre campo 6 de ambas matrices 16:47 CET, no aritmetica) + dependencias de validacion
- Resueltas desde el inventario inicial: 35be5a8d (PlannedSetSummary), 2b1382f5 (chips disciplina), 21e26ff2/06884b8c/c3d2f246 (auth cache verificado), cadena BTT/T2B (6993e330..0a640da8), localizacion numeros post (b8cca90a/04da40ef/a192c38b/bf8de3db portados; 95847d98/fb6de251/af08512c n/a codigo muerto baseline), cluster onboarding AI (f68d77ff: logos OpenAI/Claude/Grok 0-diff, instrucciones 1:1, catalogo conexiones; quedan 5 partial: flujo Desconectar y oauth_client_id), cluster glifos corporales (este lote: 08551cb1/5099d9f1/49febc33/fdbd3558 verified-ported, 3b3792df n/a reorganizacion Xcode, b2f6b934 superseded por eliminacion Diario)

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
3. Suites COMPLETAS verdes tras cada implementacion (actual: domain 458/458 en 87 suites XML real, mobile 525/525 en 129 suites XML real)

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
  GAP captura de series WOD por movimiento en reloj (wodUsesSeries; Android Wear
  difiere siempre al movil) + validacion visual estilo botones (0f528156/604b1293)
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
