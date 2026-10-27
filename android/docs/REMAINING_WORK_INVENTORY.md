# Inventario de trabajo restante (27 oct 15:00 CET)

Clasificacion COMPLETA (0 unverified) en ambas matrices; esto NO es cierre funcional.
Fuentes: AUDIT_579_PREWINDOW_MATRIX.csv (414 filas) + AUDIT_POSTBD4_WINDOW_MATRIX.csv.

## Contadores
- Pre-window: 54 partial + 31 in-progress = 85
- Post-window: 20 partial + 14 in-progress = 34
- TOTAL abierto: 119 filas + dependencias de validacion

## Dependencias de validacion (bloquean cierre)
1. compile/build mobile+wear COMPLETO (bloqueado por limite 120s por llamada) — REQUISITO antes de integrar/push
2. Validacion runtime/UI en dispositivo/emulador de todo lo movil desde tree175 (WIP)
3. Tests runner ligero + domain verdes tras cada implementacion (actual: 448/448 domain, 36/36 runner)

## Grupos de gaps principales (pre+post)
- Onboarding AI unificado (OAuth/instrucciones/logos): AIAccessScreen 324l vs Apple 648l
- Zonas FC + anillo intensidad Cardio Progreso (661e65f4/9947c212)
- Glifos corporales en chips musculo (08551cb1 cluster)
- Paisaje/dos paneles (calendario 7 dias, secciones, safe areas)
- Wear fino: Sincronizar+mascota, flecha en descanso, EMOM/Tabata al terminar reloj, frescura planificacion
- Cursores interactivos graficas recuperacion (b73d77dc/42f02b82)
- compactSummary con segundos hold en planes (35be5a8d) — EN IMPLEMENTACION
- Auth cache post-logout (21e26ff2/06884b8c/c3d2f246)
- Chips disciplina ficha ejercicio (2b1382f5)
- Estilos parciales a verificar en runtime (margenes, miniaturas, previews)
- Gaps post-window ya conocidos: widgets/LiveActivities, Health-ruta upload, fullscreen map, tap targets/overlay, Health Connect por rango, tiles resumen

## Evidencia N/A
Cada fila n/a de las matrices lleva su razon (mecanica iOS nativa, superficie web/MCP/db compartida,
tipo Swift sin counterpart). Donde la ausencia Android podria ocultar funcion faltante se marco
partial/in-progress en lugar de n/a (paisaje, Wear, auth cache).
