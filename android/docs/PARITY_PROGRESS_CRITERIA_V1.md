# Seguimiento por criterios v1

Fecha de base: 28-oct-2026. Ultimo producto: tree396, 11d450da. Consolidado en App-android (merge7bf6eadd).
Peticion de seguimiento: mensaje del usuario de 28-oct 12:01 y continuidad acordada a las 12:02.

## Que mide

Este registro conserva los dos bloques EN CURSO. No crea nuevos objetivos ni convierte
las 735 filas de auditoria en unidades de avance. No representa porcentaje de tiempo,
lineas, commits, pruebas ni cobertura funcional total.

Cada ID es un criterio de aceptacion inventariado de igual peso dentro de SU bloque.
No se borra ni cambia su significado para mejorar un porcentaje. Un descubrimiento se
anade con nuevo ID y nueva version, mostrando numerador y denominador anteriores y nuevos.
Las familias amplias permanecen parciales hasta enumerar y comprobar todos sus caminos.

Estados por etapa:
- A: acreditado dentro del alcance literal de la fila por codigo y evidencia indicada.
- P: parcial, hay implementacion pero la fila incluye diferencias o cobertura sin resolver.
- N: pendiente, no acreditado. No equivale siempre a ausencia de codigo.

I = implementacion. C = conexion con el consumidor Android, no integracion remota.
V = validacion nativa de extremo a extremo y visual cuando corresponda.
Una fila solo esta completada si I/C/V son A. Las pruebas JVM y PNG son evidencia de I/C,
no sustituyen V. Se puede publicar el porcentaje por etapa SOLO con este denominador y
su etiqueta; nunca llamarlo porcentaje funcional total. Toda V sigue N por falta de una
via de dispositivo validada. No se cambia esa condicion mediante renders JVM.

Cobertura global del inventario: NO demostrada exhaustiva. Las superficies son conocidas,
pero faltan enumeraciones de autoejes, textos, tamanos/temas y caminos completos del lector.
Por eso los porcentajes siguientes son de criterios inventariados v1 y nada mas.

## Fuente y limites

Corte compuesto: 0a640da8 mas ff097bf3/dbf43176/11ea29a6/ff94e6ad, conservados en
`evidence/live-window-patches/`. Sus rutas no cambian HealthRecovery/ProgressTrendCards.
Para lector, los parches son parte de la comparacion y no se presupone identidad por SHA.
No se incorpora 8ab72cfe ni cambios posteriores al limite del encargo.
No se modifican Apps/ ni Packages/, no se autoriza push ni migraciones de historicos.

## Constantes y graficos

| ID | Criterio fijo | I | C | V | Fuente / evidencia / diferencia pendiente |
|---|---|---|---|---|---|---|
| G01 | Alturas Readiness: compacto220, DUO clamp205..270 con formula de columna | A | A | N | HealthRecovery550-555; RecoveryLayout.kt + RecoveryHistoryCards.kt; RecoveryLayoutTest y fixture recoveryExpandedHeight. Solo formula/uso, no todos los insets |
| G02 | Readiness Y fijo0/5/10 y labels alineados al mismo plot | A | A | N | HealthRecovery1288-1292; ProgressCharts.kt; tree371, readinessMultidayCurve bounds/labels |
| G03 | Preview Readiness: siete valores ficticios X1..7 dominio0..8, trazo plano sin punto, sin fechas observadas | A | A | N | HealthRecovery780-813; RecoveryHistoryCards Free opt-in + ProgressCharts; trees375/377, readinessPreviewUsesPlainAccentAtSameHeight |
| G04 | Readiness observado: curva/gradiente por Y, sin PointMark; seleccion por RuleMark1dp dash3/4 y fecha/valor conservados | A | A | N | HealthRecovery1246-1276; trees379/381, readinessMultidayCurve pixel y tap; annotation exacta excluida aqui y cubierta por G12 |
| G05 | Readiness X automatico desired4 con grid y fechas del corte | P | P | N | HealthRecovery1293-1299; tree373 solo grid en anclajesfirst/mid/last, NO algoritmo Swift automatico |
| G06 | Peso real/preview/vacio: geometria, curva, dominios y ejes del corte | P | P | N | ProgressTrendCards589-770; subsets275/276/303, DayPointLineChart weightStyle; autoejes/texto aun sin cierre completo |
| G07 | Sueno real/vacio: area night-sky, curva, dominios, alturas y ejes | P | P | N | HealthRecovery1310-1398; RecoverySleepChart.kt subsets280; diferencias de dominio extremo explicitas en inventario, autoejes/runtime abiertos |
| G08 | Fisiologia preview: VFC ordinal y dos barras ficticias98dp con escalas separadas | P | P | N | HealthRecovery815-906; RecoveryPhysiologyPreview.kt subsets300-303; tree384 centrosXordinales1/8..7/8 corregidos con regresion pixel7centros/PNG; anchura0.7/9 sigue aproximada, falta revision completa del criterio contra todos los ejes/textos |
| G09 | Fisiologia real: filtro de rango, estado<2, series y barras, alturas/adicionales | P | P | N | HealthRecovery931-1070 y560; RecoveryHistoryCards/ProgressCharts; subsets300-303; autoejes/texto y estados sin cierre completo |
| G10 | Cardio real/preview/vacio: tres curvas, dominios, ejes, stats y seleccion | P | P | N | ProgressTrendCards210-405; ProgressCardioPlot.kt; cardioThreeCurvesAndSelection/EmptyKeeps190Axes; automaticY/texto/annotation abiertos. ZonasFC excluidas: decision previa pendiente |
| G11 | Kcal real/preview/vacio: curva+area, dominios, ejes, stats y seleccion | P | P | N | ProgressTrendCards408-588; ProgressCaloriesPlot.kt; caloriesCurveAndSelection/EmptyKeepsAxes; automaticY/texto/annotation abiertos |
| G12 | Etiquetas/annotation y metricas de texto: tamanos, posiciones, colisiones y tema/tamano de pantalla | P | P | N | HealthRecovery y ProgressTrendCards; renders360claro y subsetsDUO no cubren todos los tamanos/temas; annotation Android arriba de la grafica no identica a Swift |
| G13 | Evolucion de ejercicio real/preview/vacio: alturas, curva, dominio y eje temporal/sesiones | P | P | N | ExerciseProgressView.swift; ExerciseChartGeometry.kt + subsets279/296-299; autoejes/textos/runtime no cerrados |

Recuento v1: implementacion A4/13 =30,8%; conexion A4/13 =30,8%;
validacion nativa A0/13 =0%; criterios completos0/13 =0%.
Estas cifras NO significan que solo30,8% del codigo exista ni que el producto tenga0% de utilidad.
Las otras9filas tienen avance parcial no fraccionado. No asignarles 50% por convenio.

## Lector completo

| ID | Criterio fijo | I | C | V | Fuente / evidencia / diferencia pendiente |
|---|---|---|---|---|---|---|
| L01 | Ruido exacto de un caracter/SETS/REPS/CIRCUITO/CIRCUIT/WARMUP excluido de movimiento y fuerza explicita, notas originales conservadas | A | A | N | BoardImportParser859-868; BoardStrengthLines/BoardScanLiteParser; trees333/358/360 y tests domain+wire. CALENTAMIENTO header se trata en L05 |
| L02 | Fuerza sin cabecera con esquema setsxreps explicito y catalogo resuelto, alias oficial sobre custom; notas/carga en wire | A | A | N | BoardImportParser175-200/821-851/870-933; BoardStrengthLines; BoardStrengthLinesTest y BoardScanImportTest. Subset bounded1..200/1..100000; defaults/fallback se tratan en L03/L04 |
| L03 | Fuerza clasica sin esquema: defaults3x8 y parseo/revision de lineas completas | A | A | N | BoardImportParser37-57/821-851/330-628; BoardClassicReview + prepareBoardReview/BoardScanScreen/BoardScanReviewConfirm, trees395/622df90f/396. Defaults visibles/editables, nombre/carga/esquema/exclusion, exclusiones de cabeceras full separadas de Lite; 8 tests dominio, 2 UI->wire, callback MainActivity->createRoutineFromScan revisado. Cantidades bounded1..200/1..100000, carga finita>=0; desconocidos requieren corregir/excluir, custom/fallback sigue L04. JVM/PNG no acreditan nativo |
| L04 | buildRoutine: seleccion incluida, salvamento sin cabecera, fallback no resuelto y creacion custom equivalente | P | P | N | BoardImportParser60-92/175-200/285-310; consumidor Lite/review existente no acredita todos estos caminos |
| L05 | Secciones y TODOS los formatos/cabeceras del corte con precedencia correcta | P | P | N | BoardImportParser95-174/330-628; muchos subsets282-369 portados, contains/global y combinaciones aun pendientes |
| L06 | EVERY/CADA FOR/PARA exacto: unidades explicitas/omitidas, cadencia, duracion y rondas/override | A | A | N | BoardImportParser400-440; trees349-350, everyFor tests domain+wire. No incluye todas las cabeceras EVERY en L05 |
| L07 | Complejos: multiplicador, ondas, pareskg, porcentajes/RPE, rango de sets, escalado y notas | P | P | N | BoardImportParser630-795; subsets315-328 y tests; solo combinaciones bounded acreditadas, no todos los caminos |
| L08 | Matching completo: candidatos, oficial/alias/custom y fuzzy en todos los consumidores/rutas | P | P | N | BoardImportParser870-950 y parches del corte; BoardStrengthLines.bestMatch existe, simples/complejos usan allowFuzzy=false; no es matching global |
| L09 | Modificador de movimiento simple explicito descargado: candidatos exactos, equipo previo, T&G espaciado | A | A | N | BoardImportParser870-950; trees367/369; tests singleModifierCandidate/singleExplicitMovement/touchAndGo + wire. Otras formas en L08 |
| L10 | Metadata de ronda/footnote/quality, descansos y conversion EVERY con onda a fuerza | P | P | N | BoardImportParser216-310; BoardScanLiteParser flush y conversion185-207 existentes; precedencia completa de rutas/metadata aun sin cierre |
| L11 | Revision/importacion desde OCR a rutina editable, identidades y wire sin perdidas para todos los caminos full | P | P | N | BoardScanScreen usa Lite+catalogo persistido; BoardScanImport y20wiretests acreditan subsets, no todos los caminos full ni prueba nativa OCR->guardar->abrir |

Recuento v1: implementacion A5/11 =45,5%; conexion A5/11 =45,5%;
validacion nativa A0/11 =0%; criterios completos0/11 =0%.
Son criterios inventariados, NO porcentaje de cobertura total ni del lector funcional.
Las 6 filas parciales no reciben fraccion inventada. L03 acreditado I/C no cierra el lector ni sustituye validacion nativa.

## Fuera de estos porcentajes

- Diario eliminado: rama separada, integracion/validacion pendientes. No se audita su
  contenido ni se asigna porcentaje desde este registro.
- ZonasFC/intensidad y decisiones/migraciones historicas: restricciones previas vigentes.
- Salud/rutas/mapas/reloj/lockscreen: validacion global pendiente; no absorbida por el
  porcentaje de graficos o lector. No hay nueva superficie ni autoridad en este registro.

## Regla de informe

Omitir Terminado si no existe un cierre nuevo respecto al ultimo informe visible.
Una bateria verde no es cierre nuevo de estos bloques. Mantener nombres de bloques,
explicar cambio concreto y porcentaje por etapa con etiqueta 'criterios inventariados v1'.
Si esta etiqueta y las etapas no caben claramente en el canal, mantener estado parcial y
fraccion literal antes que publicar un porcentaje ambiguo. No presentar0/13o0/11nativo
como0%global del producto. Registrar todos los cambios de denominador y evidencia.

## Evidencia posterior sin cambio de criterio

- Tree386: G10/G11 helper de formatoX ahora respeta granularidadWEEKantes de rangeTODAY/WEEK. Matriz de patrones y render labels acreditados. El agregador actual no genera esa combinacion, por tanto no se afirma impacto visible de usuario en esa ruta. G10/G11 permanecen P/P/N; denominadores y recuentos v1 intactos.

- Tree388: G07 fechas extremas de sueno en d MMM como HealthRecovery1393-1403; no cambia dato/seleccion/curva/area/dominio/alto. Regresion render roja/verde y PNG360 inspeccionado. G07 permanece P/P/N; denominadores y recuentos v1 intactos.

- Tree390: G08 divisor entre VFC ficticia y barras con alpha0.25/spacing14 como HealthRecovery850-852; regresion de existencia/bounds y PNG360 inspeccionado. No claimcolorSwiftidentico. G08 permanece P/P/N; denominadores/recuentos v1 intactos.

- Tree392: G08 fila de VFC ficticia con titulo izquierdo y ultimo valor58msderecho, como HealthRecovery827-834; regresion textos/bounds y PNG360 inspeccionado. No claimfontmetricsidenticas. G08 permanece P/P/N; denominadores/recuentos v1 intactos.

- Tree396: L03 pasa N/N/N a A/A/N tras conjunto fuerza clasica y revision completa contra el corte. Ciclo consolidado: mobile695/164XML, domain566/94XML, Wear8/1XML, cero fallos/errores/omitidos; ambos assembleDebug verdes. PNG de revision3x8editable inspeccionado. El nuevo menuInicio->DayPlusSheet sigue Apple actual confirmado para resolver fusionDiario; prueba botonreal->cuatroopciones->callbackEscanear y PNG360x900 inspeccionado. Esto NO acredita todos los caminos L04/L05/L08/L11 ni validacion en dispositivo. No se modifica denominador.
