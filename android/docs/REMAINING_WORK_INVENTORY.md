# Inventario de trabajo restante (27 oct 15:52 CET)

Clasificacion COMPLETA (0 unverified) en ambas matrices; esto NO es cierre funcional.
Fuentes: AUDIT_579_PREWINDOW_MATRIX.csv (414 filas) + AUDIT_POSTBD4_WINDOW_MATRIX.csv.

## Contadores (reconciliado 15:52 CET, tras lote persistencia WOD)
- Pre-window: 48 partial + 2 in-progress + 1 verified-partial+gap = 51
  (los 2 in-progress son 661e65f4/9947c212 zonas FC: bloqueo preservado para decision usuario)
- Post-window: 26 (15 partial + 4 verified-partial + 2 verified-partial+GAP + 5 GAP)
- TOTAL abierto: 77 filas + dependencias de validacion
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
- Wear fino: Sincronizar+mascota, flecha en descanso, EMOM/Tabata al terminar reloj, frescura planificacion
- Cursores interactivos graficas recuperacion (b73d77dc/42f02b82)
- Estilos parciales a verificar en runtime (margenes, miniaturas, previews)
- Gaps post-window ya conocidos: widgets/LiveActivities, Health-ruta upload, fullscreen map, tap targets/overlay, Health Connect por rango, tiles resumen

## Evidencia N/A
Cada fila n/a de las matrices lleva su razon (mecanica iOS nativa, superficie web/MCP/db compartida,
tipo Swift sin counterpart). Donde la ausencia Android podria ocultar funcion faltante se marco
partial/in-progress en lugar de n/a (paisaje, Wear, auth cache).
