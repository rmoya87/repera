# Inventario de trabajo restante (27 oct 19:11 CET)

Clasificacion COMPLETA (0 unverified) en ambas matrices; esto NO es cierre funcional.
Fuentes: AUDIT_579_PREWINDOW_MATRIX.csv (414 filas) + AUDIT_POSTBD4_WINDOW_MATRIX.csv.

## Contadores (recuento directo 27oct 19:11 CET)
- Filas SHA validas:735 (579prewindow+156postwindow).
- Prewindow:50abiertas (41partial+7verified-partial+2in-progress).
- Postwindow:20abiertas (13partial+7verified-partial).
- TOTAL:70abiertas. Regla fija: abierta si campo6 empieza partial,
  verified-partial o in-progress; no cerrar verified-partial por tests JVM.
- Cambio ultimo: b73d77dc reabierta desde verified-ported porque tenia una
  desviacion declarada. Readiness vacio/cursor corregidos; curva gradiente
  y catmullRom aun no portadas. No altera decisiones del usuario.
- Suite vigente:mobile608/608(149XML),domain485/485(92),wear8/8(1).
  Ultimo assemble mobile+wear completo verde en tree244; cambios posteriores
  requieren nueva pasada antes de integrar. No push hasta condicion del usuario.

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

## Siguiente unidad preparada
- b73d77dc: HealthRecovery.swift corte0a640da8 trainingRecoveryTrendCard
  usa curva catmullRom, stroke3 redondo y gradiente vertical por valor0..10:
  rojo0..0.40, amarillo0.60..0.72, acento0.84..1.0. NO por distancia temporal.
- Android DayPointLineChart es compartido con otras metricas: agregar opcion
  especifica de readiness, por defecto lineal/paleta actual. No cambiar otras
  series. Conservar seleccion por distancia calendario, bounds0..10 y estado
  sin tendencia de una muestra. Render fixture multidia explicito antes de cierre.
