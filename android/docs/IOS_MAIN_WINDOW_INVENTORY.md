# iOS main window inventory (read-only), LIVE GitHub main

Source: `git fetch` (read-only, no push) of github.com/rmoya87/repera main on 2026-10-26 17:46 CET, stored locally as ref `refs/ghlive/main` = bd4d76376c89da7ebcb86aa3f9e8f8bf6124637e (commit 2026-10-26 17:28:54+01:00 "Update HealthKit mixed-distance regression contracts"). The Vault credential was used only for this read through a private file that was then shredded; nothing was stored in git config.
The earlier version of this file (mirror main 020c0978) is superseded: the mirror was an ancestor of live main and missed most of 26 Oct (313 commits after fc3ef7e1, not 16).
Window: all commits reachable from live main after 2345b5f1 (last first-parent commit before 2026-10-23 00:00 Europe/Madrid), i.e. everything integrated 23 Oct to 26 Oct 17:46 regardless of author date, INCLUDING commits contained in merges (24 merge commits).
Counts: all commits 892 (non-merge 868, merges 24); first-parent chain 594; after Apple reference fc3ef7e1: 313. `git diff --stat fc3ef7e1 refs/ghlive/main`: 59 files, +5756/-1710 (32 Apps/Repera, 9 ReperaDomain, tests, docs; 0 android).
Android alignment status per commit is NOT assessed here. Pre-fc3ef7e1 commits are not marked covered by the historical matrix. Areas: ios=395, domain-swift=130, tests=92, docs=69, ci=35, other=29, backend=26, MERGE=24, domain-swift,ios=17, watch=10, docs,tests=9, web=7, ci,docs,ios,other=7, docs,ios,tests=6, widget=6, ios,tests=5, docs,other=3, ci,ios=3, ci,ios,other=3, docs,ios=2, ci,docs,ios=2, docs,ios,tests,watch=1, ios,other=1, ci,tests=1, docs,domain-swift,ios=1, backend,ci,docs,ios,other,tests,web=1, ci,docs,ios,other,tests=1, backend,docs,ios,other,tests=1, docs,ios,other,tests=1, ci,other,tests=1, backend,ci,docs,domain-swift,ios,other,tests=1, docs,ios,other=1, ci,docs,domain-swift,ios,tests=1

| hash | committer date | areas | files | after fc3ef7e1 | first-parent | subject |
|---|---|---|---|---|---|---|
| 44713457 | 2026-10-23T00:00:04+02:00 | watch | 1 |  | fp | fix(watch): EMOM Tabata y circuitos mantienen captura de series al terminar reloj |
| 47515a41 | 2026-10-23T00:00:24+02:00 | tests | 1 |  | fp | test(watch): temporizador WOD terminado no bloquea el registro posterior de series |
| 3eb5b130 | 2026-10-23T00:00:45+02:00 | docs | 1 |  | fp | docs(watch): EMOM y Tabata no interrumpen captura de series al llegar a cero |
| a4a5d9ce | 2026-10-23T00:07:57+02:00 | watch | 1 |  | fp | fix(watch-play): flecha funciona con cero sin crear series falsas y final de intervalo se llama Finalizado |
| 604b1293 | 2026-10-23T00:09:21+02:00 | watch | 1 |  | fp | feat(watch-ui): eliminar música, pausa circular grande y mismos controles verdes para peso, reps y métricas |
| 0f528156 | 2026-10-23T00:10:19+02:00 | watch | 1 |  | fp | style(watch): unificar botones interactivos verde iOS con texto e icono negros |
| 93919f72 | 2026-10-23T00:10:29+02:00 | ios | 1 |  | fp | fix(settings): remove average heart rate from editable health goals |
| 4bfb57d6 | 2026-10-23T00:10:52+02:00 | docs | 1 |  | fp | docs: align editable goals and daily activity with removal of FC media |
| a0759744 | 2026-10-23T00:11:01+02:00 | tests | 1 |  | fp | test(watch): flecha activa con cero, música eliminada, pausa grande y controles verdes coherentes |
| cba3d53f | 2026-10-23T00:11:11+02:00 | docs | 1 |  | fp | test: remove retired HR goal from Objectives regression checklist |
| d6b029ba | 2026-10-23T00:11:31+02:00 | docs | 1 |  | fp | docs(watch): controles verdes, avance a cero sin registros ficticios y pausa circular de 70pt |
| ea99a5b6 | 2026-10-23T00:12:33+02:00 | watch | 1 |  | fp | fix(watch): flecha de avance también disponible durante descansos y con cero repeticiones |
| 456a0036 | 2026-10-23T00:12:46+02:00 | tests | 1 |  | fp | test(watch): permitir siguiente sin series vacías también durante el descanso |
| 90940973 | 2026-10-23T00:14:03+02:00 | docs | 1 |  | fp | docs(watch): flecha también disponible durante descansos automáticos |
| 97d0bc13 | 2026-10-23T00:21:15+02:00 | watch | 1 |  | fp | feat(watch): precargar cantidad y carga exactas de cada serie prescrita |
| c02f3ca4 | 2026-10-23T00:22:10+02:00 | domain-swift | 1 |  | fp | feat(domain): exponer valores prescritos de la siguiente serie sin contar calentamientos |
| 0328de0a | 2026-10-23T00:22:26+02:00 | watch | 1 |  | fp | refactor(watch): tomar la serie prescrita de la API común del dominio |
| d350b42f | 2026-10-23T00:22:45+02:00 | ios | 1 |  | fp | fix(watch-sync): resolver solicitud del reloj con el plan de Hoy del estado actual del iPhone |
| 1d333b42 | 2026-10-23T00:23:03+02:00 | ios | 1 |  | fp | fix(watch-sync): responder peticiones explícitas con planificación fresca del iPhone |
| 08b084ef | 2026-10-23T00:23:24+02:00 | watch | 1 |  | fp | style(watch): pantalla sin planificación sin mensajes de ayuda redundantes |
| 6897ac98 | 2026-10-23T00:24:05+02:00 | domain-swift | 1 |  | fp | test(domain): objetivos preconfigurados avanzan por serie, calentamiento no consume objetivos |
| 1ae491c9 | 2026-10-23T00:24:44+02:00 | tests | 1 |  | fp | test(watch): presets reales por serie y sincronización directa de plan del día al pulsar botón |
| 4a82b4b2 | 2026-10-23T00:29:59+02:00 | docs,ios,tests,watch | 7 |  | fp | feat(watch): mascota de Repera y botón Sincronizar inferior con petición fresca y encolada |
| 9b1b7a10 | 2026-10-23T00:31:28+02:00 | tests | 1 |  | fp | test(watch): comprobar mascot real y limitar ausencia de SF Symbol a pantalla vacía |
| 135c4a65 | 2026-10-23T00:31:41+02:00 | watch | 1 |  | fp | fix(watch-sync): evitar captura no-Sendable en fallback de WatchConnectivity |
| 160f304c | 2026-10-23T06:50:10+02:00 | ios | 1 |  |  | fix(ios): separate workout add action from daily cards |
| 7ba100b8 | 2026-10-23T06:50:13+02:00 | ios | 1 |  |  | fix(ios): keep exercise navigation bar transparent |
| 2ac224f5 | 2026-10-23T06:50:16+02:00 | ios | 1 |  |  | fix(ios): show history only under training progress |
| ddaffcf3 | 2026-10-23T06:50:19+02:00 | ios | 1 |  |  | style(ios): display body-weight metrics in tiles |
| a0852607 | 2026-10-23T06:51:08+02:00 | ios | 1 |  |  | fix(ios): route repeated exercise instances independently from workout review |
| 6186f8c6 | 2026-10-23T06:51:10+02:00 | ios | 1 |  |  | fix(ios): keep exercise details scoped to selected occurrence |
| dc8ca766 | 2026-10-23T06:51:13+02:00 | ios | 1 |  |  | fix(ios): isolate selected exercise results in session preview |
| 42f02b82 | 2026-10-23T06:51:55+02:00 | ios | 1 |  |  | feat(ios): interactive dotted chart cursors on cardio, calories and body weight |
| b73d77dc | 2026-10-23T06:53:04+02:00 | ios | 1 |  |  | feat(ios): recovery selection cursors, empty readiness chart and compact vital tiles |
| bddc3fd5 | 2026-10-23T06:53:37+02:00 | ios | 1 |  |  | fix(ios): correct Swift chart builder and interpolation syntax |
| c526e51e | 2026-10-23T06:55:50+02:00 | domain-swift | 1 |  |  | feat(domain): canonical English sport names with Spanish search aliases |
| 88dbde3c | 2026-10-23T06:56:33+02:00 | domain-swift | 1 |  |  | feat(domain): seed sport exercises with English canonical names |
| a140cabc | 2026-10-23T06:56:36+02:00 | domain-swift | 1 |  |  | fix(domain): retain Spanish technique descriptions after sport name localization |
| 09546c31 | 2026-10-23T06:56:39+02:00 | ios | 1 |  |  | fix(ios): migrate catalog display names in place preserving existing UUIDs |
| f3997b30 | 2026-10-23T06:56:41+02:00 | domain-swift | 1 |  |  | feat(domain): index Spanish sport aliases and resolve bilingual search |
| 599a9f48 | 2026-10-23T06:56:44+02:00 | domain-swift | 1 |  |  | fix(domain): preserve exercise equivalence across bilingual rename |
| 8383c6c7 | 2026-10-23T06:56:46+02:00 | ios | 1 |  |  | fix(ios): keep legacy exercise artwork and movement step animations |
| b46562cc | 2026-10-23T06:57:24+02:00 | domain-swift | 1 |  |  | fix(domain): prioritize direct localized descriptions for English-original movements |
| 983304e8 | 2026-10-23T06:57:26+02:00 | domain-swift | 1 |  |  | fix(domain): accent and case-insensitive sport alias lookup |
| 6daf8ded | 2026-10-23T06:58:00+02:00 | domain-swift | 1 |  |  | test(domain): update bilingual catalog expectations for English canonical labels |
| d03aaa76 | 2026-10-23T07:01:14+02:00 | domain-swift | 1 |  |  | fix(domain): preserve jump rope logging for canonical hyphenated names |
| 65cd6c03 | 2026-10-23T07:01:16+02:00 | domain-swift | 1 |  |  | test(domain): bilingual sport catalog migration and exercise logging regression |
| 72a62dc5 | 2026-10-23T07:02:28+02:00 | ios | 1 |  |  | feat(ios): show training score only with interactive chart cursor |
| 9a716df5 | 2026-10-23T07:02:31+02:00 | ios | 1 |  |  | feat(ios): inspect exercise evolution with dotted selection guide |
| d0b71e30 | 2026-10-23T07:05:22+02:00 | domain-swift | 1 |  |  | fix(domain): preserve historical OCR and English synonyms after sport catalog rename |
| 8ef8509d | 2026-10-23T07:06:22+02:00 | ios | 1 |  |  | fix(ios): scope WOD scores to the selected exercise block only |
| cd4b8dd9 | 2026-10-23T07:06:58+02:00 | domain-swift | 1 |  |  | fix(domain): search Spanish sport aliases with or without connecting words |
| 3aeeff2c | 2026-10-23T08:20:41+02:00 | backend | 1 |  |  | chore(supabase): record deployed bilingual sport aliases migration |
| 6850cf12 | 2026-10-23T08:21:50+02:00 | MERGE | 0 |  | fp | Merge PR #43: iOS exercise navigation, bilingual catalog and progress charts |
| 571b778a | 2026-10-23T08:46:15+02:00 | docs,ios,tests | 3 |  | fp | fix(ios): restaurar campos por movimiento en Play para todos los WOD |
| a1033015 | 2026-10-23T08:47:24+02:00 | tests | 1 |  | fp | test(play): corregir estructura del contrato tras restaurar campos WOD |
| af41164d | 2026-10-23T08:52:03+02:00 | ios | 1 |  |  | fix(play-scan): integrate ReperaStore.swift on current main |
| 44f0939a | 2026-10-23T08:52:07+02:00 | ios | 1 |  |  | feat(play): add inline WOD result fields |
| 9d0cc384 | 2026-10-23T08:52:11+02:00 | ios | 1 |  |  | fix(play-scan): integrate HistoryView.swift on current main |
| 15faba23 | 2026-10-23T08:52:14+02:00 | domain-swift | 1 |  |  | fix(play-scan): integrate BoardImportParser.swift on current main |
| b0fa14ea | 2026-10-23T08:52:18+02:00 | domain-swift | 1 |  |  | fix(play-scan): integrate BoardScanLiteParser.swift on current main |
| 55acbf90 | 2026-10-23T08:52:22+02:00 | domain-swift | 1 |  |  | fix(play-scan): integrate BoardScanLiteParserTests.swift on current main |
| 92d6f870 | 2026-10-23T08:52:59+02:00 | ios | 1 |  |  | fix(play): combine latest per-exercise entry with non-modal persistent block scores |
| cd99864c | 2026-10-23T08:53:27+02:00 | tests | 1 |  |  | test(play): cover inline AMRAP score, per-exercise sets and immediate persistence |
| 436013f6 | 2026-10-23T08:53:51+02:00 | ios | 2 |  | fp | feat(progress): liberar equilibrio muscular y mostrar graficas de ejemplo y vacias |
| 9046e515 | 2026-10-23T08:54:20+02:00 | domain-swift | 1 |  |  | test(scan): update photo regression expectations to canonical English sport names |
| a5294760 | 2026-10-23T08:55:11+02:00 | ios | 1 |  | fp | feat(recovery): mostrar ejemplos Pro y ejes cuando no hay historial |
| 8c19f866 | 2026-10-23T08:55:29+02:00 | MERGE | 0 |  | fp | Merge PR #45: persist Play results and improve WOD scan |
| 10841411 | 2026-10-23T08:56:28+02:00 | ios | 1 |  | fp | fix(progress): graficas de ejercicio sin datos y vista de ejemplo gratuita |
| 75602c8f | 2026-10-23T08:57:33+02:00 | docs | 1 |  | fp | docs(progress): documentar previews Pro y equilibrio muscular gratuito |
| 3d66dabd | 2026-10-23T08:58:10+02:00 | tests | 1 |  | fp | test(progress): proteger previews Pro, gráficos vacíos y equilibrio gratis |
| 20245174 | 2026-10-23T08:58:33+02:00 | tests | 1 |  | fp | test(progress): acotar comprobación a vista de recuperación |
| 29999d3b | 2026-10-23T09:00:31+02:00 | ios | 1 |  | fp | refactor(progress): aclarar acceso libre al mapa muscular y estado vacío |
| 2a2bb3cf | 2026-10-23T09:26:15+02:00 | docs,ios,tests | 4 |  | fp | fix(ios): incluir WODResultInlineEditor en WorkoutView ya compilado |
| 8ce12f30 | 2026-10-23T09:37:34+02:00 | docs,ios,tests | 6 |  | fp | fix(ios): restaurar diseño compacto de Play y edición WOD |
| 96de6679 | 2026-10-23T09:39:48+02:00 | ios,tests | 3 |  | fp | fix(ios): no alterar Rx al mostrar series en edición de historial |
| 6002e615 | 2026-10-23T10:09:35+02:00 | ios | 4 |  | fp | fix(ios): ajustar técnicas a ancho completo, barras e interfaz muscular |
| b44db55f | 2026-10-23T10:10:25+02:00 | ios | 2 |  | fp | fix(ios): alinear gráficos de ejemplo dentro de sus ejes |
| 6b3b4480 | 2026-10-23T10:11:03+02:00 | ios | 2 |  | fp | fix(progress): respetar márgenes en ejemplos de recuperación y ejercicio |
| 8099d3ad | 2026-10-23T10:12:46+02:00 | docs,tests | 2 |  | fp | test(docs): cubrir presentación compacta, gráficas y objetivos de Inicio |
| 55f013a6 | 2026-10-23T10:13:58+02:00 | ios,tests | 4 |  | fp | fix(charts): mantener tipo Int en escalas X de ejemplos |
| b3e3a714 | 2026-10-23T10:23:33+02:00 | ios | 2 |  | fp | fix(ios): extender gris de Inicio e integrar fechas en Tu programación |
| 08790a22 | 2026-10-23T10:25:21+02:00 | ios | 3 |  | fp | fix(progress): gráficos más anchos y previews fieles al modo Pro |
| 0d649f28 | 2026-10-23T10:26:25+02:00 | ios | 3 |  | fp | style(progress): alinear márgenes en recuperación y evolución por ejercicio |
| e1d55bed | 2026-10-23T10:27:35+02:00 | docs,tests | 2 |  | fp | test(docs): proteger programación unificada y previews fieles de Progreso |
| b2f6b934 | 2026-10-23T10:40:20+02:00 | ios | 1 |  | fp | fix(diary): excluir los entrenos sueltos con fecha de la planificación semanal |
| 9947c212 | 2026-10-23T10:41:37+02:00 | ios | 1 |  | fp | feat(progress): integrar zonas de FC y anillo de intensidad dentro de Cardio |
| 661e65f4 | 2026-10-23T10:43:03+02:00 | docs,ios,tests | 4 |  | fp | fix(progress): Cardio agrupa sus zonas y la intensidad; contratos Diario |
| 69a9f03b | 2026-10-23T10:59:51+02:00 | ios | 1 |  | fp | fix(ios): alinear miniatura y compactar valores reales en edición terminada |
| 3b24108a | 2026-10-23T11:00:18+02:00 | ios | 1 |  | fp | fix(ios): alinear también miniaturas en WOD y evitar formulario duplicado |
| c7878496 | 2026-10-23T11:01:18+02:00 | ios | 5 |  | fp | style(progress): ampliar gráficos y separar trazado de bordes verticales |
| d74afff0 | 2026-10-23T11:02:41+02:00 | docs,ios,tests | 5 |  | fp | refactor(ios): retirar editor Rx duplicado y alinear miniaturas en Play |
| 4ba0059e | 2026-10-23T11:04:33+02:00 | tests | 1 |  | fp | test(progress): validar tarjetas más altas y márgenes verticales de gráficas |
| b3abae06 | 2026-10-23T11:12:31+02:00 | ios | 1 |  | fp | fix(play): técnicas sin doble margen, clusters compactos y separador de series |
| 040227d5 | 2026-10-23T11:13:27+02:00 | ios | 1 |  | fp | fix(editor): separar Volver neutral de confirmación verde y quitar línea al expandir |
| 8e4df187 | 2026-10-23T11:15:23+02:00 | docs,tests | 3 |  | fp | test(ios): evitar regresión de margen, cluster, topbar y separadores |
| 31d835ef | 2026-10-23T11:16:51+02:00 | ios | 1 |  | fp | fix(play): separar controles de navegación neutros de check verde |
| 94b6435e | 2026-10-23T11:22:46+02:00 | docs,ios | 6 |  | fp | fix(ios): barra gris en navegación compactada salvo Inicio |
| 77d292a1 | 2026-10-23T11:23:54+02:00 | tests | 1 |  | fp | test(ios): proteger fondo gris de barras compactadas e Inicio transparente |
| aa1abc62 | 2026-10-23T11:30:36+02:00 | ios | 3 |  | fp | fix(ios): quitar instrucción redundante, usar chevrons nativos y recuperar miniatura BBJO |
| 864650c8 | 2026-10-23T11:33:00+02:00 | ios,other | 6 |  | fp | feat(auth): acceso Google nativo Supabase con vinculación segura a Apple |
| d54c9dd0 | 2026-10-23T11:35:11+02:00 | ios | 1 |  | fp | fix(auth): finalizar OAuth nativo antes de dar Google por vinculado |
| d5aaf813 | 2026-10-23T11:36:33+02:00 | ios | 2 |  | fp | fix(auth): no repetir onboarding al cambiar de Apple a Google y proteger identidad |
| de6b6248 | 2026-10-23T11:37:40+02:00 | tests | 1 |  | fp | test(auth): proteger login Google y propiedad de datos al vincular Apple |
| efd050ad | 2026-10-23T11:39:47+02:00 | docs,other | 4 |  | fp | docs(auth): documentar OAuth Google iOS, redirección y enlace seguro Apple |
| 1e284991 | 2026-10-23T11:40:44+02:00 | ios | 1 |  | fp | fix(auth): usar getLinkIdentityURL de supabase-swift 2.55.4 fijado |
| 4714ec11 | 2026-10-23T11:40:54+02:00 | tests | 1 |  | fp | test(auth): verificar API getLinkIdentityURL de SDK fijado 2.55.4 |
| c3d2f246 | 2026-10-23T11:43:21+02:00 | ios | 1 |  | fp | fix(auth): validar dueño local también en restauración de cache y fallback Apple |
| 6d86a818 | 2026-10-23T11:44:18+02:00 | tests | 1 |  | fp | test(ios): verificar mensajes eliminados, flechas nativas y miniatura Burpee Box Jump Over |
| 06884b8c | 2026-10-23T11:46:04+02:00 | ios | 1 |  | fp | fix(auth): cierre de sesión explícito impide restaurar caché previa a login Google |
| 21e26ff2 | 2026-10-23T11:46:55+02:00 | ios,tests | 2 |  | fp | fix(auth): no mostrar pestañas tras logout si sigue caché remota |
| e04a0a28 | 2026-10-23T11:59:06+02:00 | docs,ios,tests | 5 |  | fp | fix(ios): corregir appleUserID fuera de alcance y restaurar topbar translúcido |
| 5a47ad39 | 2026-10-23T12:02:04+02:00 | ci,tests | 2 |  | fp | ci(ios): permitir compilar RevenueCat con Xcode 27 y corregir contrato de fecha |
| 10624285 | 2026-10-23T12:02:52+02:00 | domain-swift | 2 |  | fp | test(domain): actualizar contratos de WOD id y navegación sin superseries |
| 13f73a8e | 2026-10-23T12:04:09+02:00 | tests | 1 |  | fp | test(progress): alinear contrato de zonas con tarjeta Cardio nativa actual |
| ab0a1b38 | 2026-10-23T12:08:51+02:00 | ios | 8 |  | fp | fix(ios): topbar transparente como Diario y teclado numérico en Temporizador |
| d27bfcf7 | 2026-10-23T12:09:19+02:00 | ios | 1 |  | fp | fix(progress): aplicar transparencia tras el modificador nativo del topbar |
| f2d710ac | 2026-10-23T12:10:21+02:00 | docs,tests | 2 |  | fp | test(ios): proteger cabeceras transparentes y temporizador numérico |
| afc7f410 | 2026-10-23T12:11:16+02:00 | tests | 1 |  | fp | test(home): actualizar etiquetas de los tiles reales Pasos Calorías Tiempo |
| 327435d1 | 2026-10-23T12:12:41+02:00 | ios | 4 |  | fp | style(ios): preservar gris bajo topbars transparentes de formularios y ejercicios |
| c7f040c6 | 2026-10-23T12:14:12+02:00 | tests | 1 |  | fp | test(watch): alinear final de intervalos con etiqueta corta Finalizado |
| df76e246 | 2026-10-23T12:15:27+02:00 | domain-swift | 2 |  | fp | fix(catalog): completar técnica y descripciones ES de siete ejercicios nuevos |
| 8c234437 | 2026-10-23T12:16:25+02:00 | tests | 1 |  | fp | test(play): exigir clusters sin Stepper sin prohibir control de reps/peso |
| 5773b297 | 2026-10-23T12:21:00+02:00 | ios | 1 |  | fp | feat(ios): reloj grande adaptable, ejercicio tras tiempo y controles anclados |
| 4eece72f | 2026-10-23T12:21:40+02:00 | ios | 3 |  | fp | fix(timer): retirar Saltar de llamadas y permitir pausar cuenta previa |
| 510ca2a4 | 2026-10-23T12:22:36+02:00 | ios | 2 |  | fp | fix(timer): reanudar cuenta previa sin consumir tiempo del bloque |
| 6f986435 | 2026-10-23T12:24:41+02:00 | docs,tests | 2 |  | fp | test(timer): proteger maquetación adaptativa y acceso seguro a audio |
| 1764dd59 | 2026-10-23T12:35:55+02:00 | ios | 2 |  | fp | fix(ios): ajustar LED de intervalos al ancho y centrar ejercicio; temporizador glass |
| 75943b66 | 2026-10-23T12:36:19+02:00 | ios | 1 |  | fp | fix(ios): usar sobrecargas SwiftUI válidas para ancho y centrado de ejercicio |
| 3cb110cc | 2026-10-23T12:37:33+02:00 | docs,tests | 2 |  | fp | test(docs): proteger ancho LED para rondas, miniatura y acción Liquid Glass |
| 8f807f62 | 2026-10-23T12:43:45+02:00 | ios | 2 |  | fp | fix(layout): conservar secciones agrupadas redondeadas al rotar iPhone |
| a584a6b1 | 2026-10-23T12:46:34+02:00 | docs,tests | 2 |  | fp | test(layout): proteger márgenes apaisados y esquinas de secciones agrupadas |
| fb96456c | 2026-10-23T12:55:53+02:00 | ios | 2 |  | fp | fix(layout): alinear listas con Progreso y contener calendario apaisado |
| ccec6474 | 2026-10-23T12:57:14+02:00 | docs,tests | 2 |  | fp | test(layout): proteger siete días completos y márgenes de 16 pt en paisaje |
| bfc79130 | 2026-10-23T12:58:41+02:00 | ios | 1 |  | fp | fix(home): evitar franjas blancas en safe areas laterales del gris inferior |
| 84abd630 | 2026-10-23T12:59:32+02:00 | docs,tests | 2 |  | fp | test(home): proteger gris de safe areas en horizontal y calendario compacto |
| fab3b207 | 2026-10-23T13:01:24+02:00 | tests | 1 |  | fp | test(wod): conservar formulario compacto de reales sin exigir Rx duplicado |
| 3045fb76 | 2026-10-23T13:07:40+02:00 | ios,tests | 3 |  | fp | fix(ios): contener listas agrupadas en horizontal y eliminar blanco lateral de Inicio |
| f170ad09 | 2026-10-23T13:08:42+02:00 | tests | 1 |  | fp | test(home): contrato del fondo blanco solo en cabecera tras rotación |
| 61d2bb47 | 2026-10-23T13:10:10+02:00 | tests | 1 |  | fp | test(wod): corregir assertIn incompleto en contrato de edición scaled |
| 5058f75f | 2026-10-23T13:11:50+02:00 | ios,tests | 2 |  | fp | fix(home): recortar calendario a sus siete días visibles al girar iPhone |
| e712c7b6 | 2026-10-23T13:13:08+02:00 | tests | 1 |  | fp | test(home): usar score real de Actividad en contrato de revisión histórica |
| b2b5121b | 2026-10-23T13:22:30+02:00 | ios | 7 |  | fp | fix(ios): centrar listas y tarjetas en una columna común en paisaje |
| ce83f8d2 | 2026-10-23T13:24:08+02:00 | tests | 1 |  | fp | test(landscape): proteger límite real de List y única excepción full-bleed de Inicio |
| 52310eed | 2026-10-23T13:29:53+02:00 | ios | 1 |  | fp | fix(ios): adapt launch splash artwork to landscape with full-bleed backdrop |
| aea25911 | 2026-10-23T13:44:29+02:00 | ios | 1 |  | fp | fix(ios): keep progress scroll container stable across recovery tabs |
| ef9025a6 | 2026-10-23T13:44:32+02:00 | ios | 1 |  | fp | fix(ios): tighten exercise catalog top spacing |
| 188624cc | 2026-10-23T13:45:09+02:00 | ios | 1 |  | fp | fix(ios): shorten overnight temperature label in recovery |
| 05819367 | 2026-10-23T13:47:38+02:00 | ios | 1 |  | fp | fix(ios): restore continuous white home background behind unchanged top bar |
| d217d702 | 2026-10-23T13:51:05+02:00 | ios | 1 |  | fp | fix(ios): never hide recorded workout sets when reps match block score |
| fa1463b9 | 2026-10-23T13:55:10+02:00 | ios | 1 |  | fp | fix(ios): show exercise prescription instead of misleading no-sets in finished workout |
| 96d9aab8 | 2026-10-23T13:57:27+02:00 | ios | 1 |  | fp | fix(ios): treat unchanged exercise targets as completed in finished session summary |
| 8af0bec1 | 2026-10-23T13:59:20+02:00 | ios | 1 |  | fp | style(ios): align completed exercise summaries with titles and use primary text color |
| 83dd2e2b | 2026-10-23T14:00:50+02:00 | ios | 1 |  | fp | style(ios): align completed workout set rows with exercise titles |
| d1f62d47 | 2026-10-23T14:02:08+02:00 | ios | 1 |  | fp | fix(ios): avoid repeating WOD block result below each movement |
| 433c621d | 2026-10-23T14:32:54+02:00 | ios | 1 |  | fp | fix(ios): avoid repeated health refresh and recovery screen flashes on tab entry |
| 85c26145 | 2026-10-23T14:33:42+02:00 | ios | 1 |  | fp | fix(ios): display every planned set in completed workout detail when logs absent |
| 2f64ae6c | 2026-10-23T14:33:59+02:00 | ios | 1 |  | fp | fix(ios): correct Swift interpolation in completed set summary |
| c1f51487 | 2026-10-23T14:36:37+02:00 | domain-swift | 1 |  | fp | fix(domain): include finished prescribed sets in exercise history and progress metrics |
| b8f45fa5 | 2026-10-23T14:37:09+02:00 | domain-swift | 1 |  | fp | fix(domain): show all effective sets in exercise this-session appearance |
| 94225871 | 2026-10-23T15:06:02+02:00 | domain-swift | 1 |  |  | feat(mobility): integrate mobility filter, search and progression semantics |
| f93eac72 | 2026-10-23T15:06:05+02:00 | ios | 1 |  |  | feat(mobility): integrate mobility filter, search and progression semantics |
| 38802dbe | 2026-10-23T15:06:08+02:00 | domain-swift | 1 |  |  | feat(mobility): integrate mobility filter, search and progression semantics |
| cab64182 | 2026-10-23T15:06:11+02:00 | domain-swift | 1 |  |  | feat(mobility): integrate mobility filter, search and progression semantics |
| f752b3c8 | 2026-10-23T15:06:14+02:00 | ios | 1 |  |  | feat(mobility): integrate mobility filter, search and progression semantics |
| f860818c | 2026-10-23T15:08:10+02:00 | domain-swift | 1 |  |  | feat(mobility): seed 80 bilingual mobility exercises with coaching |
| b2b3410d | 2026-10-23T15:09:11+02:00 | domain-swift | 1 |  |  | feat(mobility): remove strength load from mobility and document library filter |
| 74f24955 | 2026-10-23T15:09:14+02:00 | ios | 1 |  |  | feat(mobility): remove strength load from mobility and document library filter |
| a9758f47 | 2026-10-23T15:09:17+02:00 | docs | 1 |  |  | feat(mobility): remove strength load from mobility and document library filter |
| b2255c71 | 2026-10-23T15:09:21+02:00 | docs | 1 |  |  | feat(mobility): remove strength load from mobility and document library filter |
| cf809042 | 2026-10-23T15:09:24+02:00 | other | 1 |  |  | feat(mobility): remove strength load from mobility and document library filter |
| 732251df | 2026-10-23T15:09:55+02:00 | ios | 1 |  |  | fix(mobility): avoid classifying mobility exercises as strength in sport grouping |
| 952b553a | 2026-10-23T15:10:39+02:00 | domain-swift | 1 |  |  | test(mobility): catalog completeness, bilingual queries and no strength loads |
| bddd6526 | 2026-10-23T15:11:05+02:00 | docs | 1 |  |  | docs(mobility): list all 82 curated movements and aliases by region |
| c7a95389 | 2026-10-23T15:12:06+02:00 | other | 1 |  |  | docs(mobility): link exercise inventory and add verification checklist |
| c795768e | 2026-10-23T15:12:09+02:00 | docs | 1 |  |  | docs(mobility): link exercise inventory and add verification checklist |
| 26a03d2b | 2026-10-23T15:13:11+02:00 | domain-swift | 1 |  |  | feat(catalog): add HYROX tags and missing stations |
| e350a23d | 2026-10-23T15:13:14+02:00 | domain-swift | 1 |  |  | feat(domain): expose additive HYROX discipline tags |
| 9f89e59f | 2026-10-23T15:13:19+02:00 | domain-swift | 1 |  |  | feat(search): index secondary HYROX discipline |
| e327d676 | 2026-10-23T15:13:57+02:00 | ios | 1 |  |  | feat(ios): HYROX discipline in exercise picker |
| b7428a37 | 2026-10-23T15:14:00+02:00 | ios | 1 |  |  | feat(ios): HYROX library filter and shared sport sections |
| 2b1382f5 | 2026-10-23T15:14:03+02:00 | ios | 1 |  |  | feat(ios): show additive sport chips on exercise detail |
| 66281b05 | 2026-10-23T15:14:44+02:00 | domain-swift | 1 |  |  | feat(catalog): describe HYROX movements in Spanish |
| 6fcf18dc | 2026-10-23T15:15:19+02:00 | domain-swift | 1 |  |  | test(catalog): verify HYROX stations and no duplicate movements |
| 2639c096 | 2026-10-23T15:15:22+02:00 | docs | 1 |  |  | docs(features): document HYROX filter and catalog mapping |
| ea4f47a5 | 2026-10-23T15:22:01+02:00 | domain-swift | 1 |  |  | feat(catalog): bilingual HYROX movement names |
| 215627b4 | 2026-10-23T15:22:04+02:00 | domain-swift | 1 |  |  | feat(search): recognize HYROX stations in English |
| 96284a58 | 2026-10-23T15:22:06+02:00 | domain-swift | 1 |  |  | fix(hyrox): include singular Spanish label |
| 668e8b03 | 2026-10-23T15:22:10+02:00 | domain-swift | 1 |  |  | test(search): ensure Spanish and English HYROX aliases |
| e2679ee6 | 2026-10-23T15:28:59+02:00 | domain-swift | 1 |  |  | fix(stats): separate cardio distance and calorie progress metrics |
| 0cca7e58 | 2026-10-23T15:29:20+02:00 | ios | 1 |  |  | fix(ios): cardio-specific evolution metrics and remove empty training prompts |
| d805f0ad | 2026-10-23T15:29:36+02:00 | domain-swift | 1 |  |  | feat(mobility): model timed dynamic and hold exercises with backward-compatible prescribed seconds |
| 0562704a | 2026-10-23T15:30:01+02:00 | ios | 1 |  |  | feat(mobility): quick log holds by time and dynamic mobility by time plus repetitions |
| 6ada61ac | 2026-10-23T15:30:23+02:00 | ios | 1 |  |  | feat(mobility): Play uses prescribed duration, reps and hold-only time fields |
| e863a018 | 2026-10-23T15:31:25+02:00 | ios | 1 |  |  | feat(mobility): configure seconds and reps for mobility in exercise editors |
| 4eb76f4c | 2026-10-23T15:31:41+02:00 | domain-swift | 1 |  |  | fix(domain): record HYROX distances in metres with compatible load fields |
| 6219a961 | 2026-10-23T15:32:02+02:00 | ios | 1 |  |  | fix(ios): distance-loaded HYROX stations use cardio progress charts |
| 4e242b23 | 2026-10-23T15:32:04+02:00 | domain-swift | 1 |  |  | feat(mobility): measure best sustained hold and total timed mobility per session |
| ff433282 | 2026-10-23T15:32:36+02:00 | ios | 1 |  |  | feat(mobility): distinct duration, repetition and hold progress evolution without force metrics |
| d7b99416 | 2026-10-23T15:33:16+02:00 | backend | 1 |  |  | feat(mcp): expose HYROX race reference and unit-aware cardio progression |
| 42bd0fd9 | 2026-10-23T15:33:38+02:00 | domain-swift | 1 |  |  | test(mobility): validate timed holds, existing JSON and progress from recorded sets |
| f67d72f6 | 2026-10-23T15:33:59+02:00 | backend | 1 |  |  | fix(mcp): HYROX sequence contains exactly eight run-station pairs |
| f28a693c | 2026-10-23T15:34:02+02:00 | backend | 1 |  |  | fix(mcp): include cardio records in coach performance and HYROX catalog discovery |
| 4b5f1b84 | 2026-10-23T15:35:16+02:00 | ios | 1 |  |  | fix(mobility-art): avoid misleading strength illustrations and use mobility placeholder until visual QA |
| 44b6515b | 2026-10-23T15:36:34+02:00 | ios | 1 |  |  | feat(mobility): aggregate recorded mobility session count and time in Progress snapshot |
| 92fe968b | 2026-10-23T15:36:45+02:00 | domain-swift | 1 |  |  | fix(stats): never infer one-rep max from metres or calories |
| f7cfc9f8 | 2026-10-23T15:36:54+02:00 | ios | 1 |  |  | feat(mobility): show recorded duration and session frequency in native Progress UI |
| ab708883 | 2026-10-23T15:37:30+02:00 | domain-swift | 1 |  |  | test(domain): verify HYROX distance records and separate cardio unit histories |
| 35be5a8d | 2026-10-23T15:37:32+02:00 | domain-swift | 1 |  |  | feat(mobility): display prescribed hold seconds and repetitions in plan summaries |
| 283d3b6d | 2026-10-23T15:37:48+02:00 | backend | 1 |  |  | feat(db): version the applied HYROX catalog seed and secondary aliases |
| d10bd81e | 2026-10-23T15:39:21+02:00 | docs | 1 |  |  | docs: explain unit-safe cardio evolution and HYROX records |
| 6f28e73f | 2026-10-23T15:39:25+02:00 | docs | 1 |  |  | docs(mcp): document HYROX workout plan reference and cardio unit handling |
| c67efa53 | 2026-10-23T15:39:28+02:00 | docs | 1 |  |  | docs(tests): add cardio and HYROX manual E2E regression checklist |
| 63560393 | 2026-10-23T15:39:34+02:00 | docs | 1 |  |  | docs(mobility): clarify timed progress, Play configuration and unvalidated image coverage |
| ce12102c | 2026-10-23T15:39:38+02:00 | docs | 1 |  |  | docs(mobility): clarify timed progress, Play configuration and unvalidated image coverage |
| 3d10e09e | 2026-10-23T15:39:46+02:00 | docs | 1 |  |  | docs(mobility): clarify timed progress, Play configuration and unvalidated image coverage |
| 60e4b126 | 2026-10-23T15:39:50+02:00 | docs | 1 |  |  | docs(mobility): clarify timed progress, Play configuration and unvalidated image coverage |
| f1119820 | 2026-10-23T15:40:45+02:00 | domain-swift | 1 |  |  | fix(ios): make quantity-unit switch exhaustive for nonoptional resolved enum |
| 57cd8e47 | 2026-10-23T15:41:48+02:00 | web | 1 |  |  | fix(web): mirror all 198 native exercise entries including HYROX |
| 703d1564 | 2026-10-23T15:41:51+02:00 | web | 1 |  |  | test(web): verify expanded HYROX-inclusive native catalog parity |
| a5abb649 | 2026-10-23T15:42:27+02:00 | web | 1 |  |  | test(web): align onboarding contract with native adaptive appearance |
| c563d76c | 2026-10-23T15:46:09+02:00 | backend | 1 |  |  | fix(mcp): preserve legacy progression fields while adding explicit cardio units |
| 5ef7a848 | 2026-10-23T15:46:13+02:00 | backend | 1 |  |  | fix(mcp): preserve legacy progression fields while adding explicit cardio units |
| 8037c883 | 2026-10-23T15:46:38+02:00 | tests | 1 |  |  | test(mcp): cover HYROX station sequence, cardio units and additive SQL seeds |
| 9463cbf6 | 2026-10-23T15:47:59+02:00 | docs | 1 |  |  | docs(mcp): record active HYROX-compatible Edge Function v13 deployment |
| d2fa06db | 2026-10-23T15:48:14+02:00 | ios | 1 |  |  | fix(ios): reselect valid cardio metric when exercise style changes |
| be1aa650 | 2026-10-23T15:49:38+02:00 | ios | 1 |  |  | fix(mobility-progress): preserve seconds in short mobility sessions |
| d2400b96 | 2026-10-23T15:50:36+02:00 | domain-swift | 1 |  |  | fix(mobility): correct dynamic PVC good-morning exercise subtype |
| 246c3ed7 | 2026-10-23T15:52:29+02:00 | domain-swift | 1 |  |  | fix(mobility): never invent completed movement data from planned sets or 1RM records |
| fdcb9ba7 | 2026-10-23T15:55:13+02:00 | domain-swift | 1 |  |  | fix(mobility): add complete coached Spanish steps and anatomical safety cues for 82 exercises |
| ba692f65 | 2026-10-23T15:55:30+02:00 | domain-swift | 1 |  |  | fix(mobility): localize all 82 exercises through canonical CatalogSpanish API |
| 0f46a899 | 2026-10-23T15:55:56+02:00 | domain-swift | 1 |  |  | test(mobility): update catalog cardinality contract from 196 to 278 |
| 33c8ae11 | 2026-10-23T15:55:57+02:00 | backend | 1 |  |  | feat(db): seed 82 verified mobility movements for AI with stable native IDs |
| ae5e53ae | 2026-10-23T15:59:55+02:00 | backend | 1 |  |  | feat(mcp): add CrossFit, weightlifting, mobility and warmup planning references with athlete context |
| a79330fd | 2026-10-23T16:00:17+02:00 | backend | 1 |  |  | feat(mcp): register discipline reference, targeted warmups and owner-scoped athlete planning context |
| 7b670d6e | 2026-10-23T16:01:00+02:00 | tests | 1 |  |  | test(mcp): guard discipline planning, real metrics, owner scoping and mobility catalog |
| 744d4e4b | 2026-10-23T16:01:37+02:00 | docs | 1 |  |  | docs(mcp): document discipline-aware coaching and observed athlete metrics |
| 49a7d79b | 2026-10-23T16:02:10+02:00 | docs | 1 |  |  | docs(tests): add MCP training discipline, permissions and user history acceptance checks |
| e8f1c5cd | 2026-10-23T16:03:07+02:00 | backend | 1 |  |  | feat(mcp): include CrossFit gymnastics/barbell foundations and historical RIR evidence |
| 1a39a361 | 2026-10-23T16:03:37+02:00 | tests | 1 |  |  | test(ios): align verified day-score contract with renamed HomeView score binding |
| 7805bed1 | 2026-10-23T16:05:55+02:00 | backend | 1 |  |  | feat(mcp): tailor warmup choices to movement patterns and equipment, expose observed WOD results |
| 58e67077 | 2026-10-23T16:06:21+02:00 | tests | 1 |  |  | test(mcp): assert warmup movement/equipment filtering and WOD evidence |
| a2219f51 | 2026-10-23T16:08:01+02:00 | backend | 1 |  |  | chore(mcp): bump server version for multidisciplinary athlete planning tools |
| 4ba11850 | 2026-10-23T16:29:00+02:00 | MERGE | 0 |  | fp | Merge PR #47: movilidad nativa, registros por tiempo y evolución |
| f38ecbc2 | 2026-10-23T16:39:21+02:00 | MERGE | 0 |  |  | Merge movilidad and HYROX: retain both native catalogs, cardio progression, sport filters, 280 web exercises and MCP |
| 1862b056 | 2026-10-23T16:40:05+02:00 | MERGE | 0 |  | fp | Merge PR #46: HYROX, métricas cardio y MCP multidisciplina con movilidad |
| 68cf7bf9 | 2026-10-23T16:41:16+02:00 | docs | 1 |  | fp | docs(art): record truthful HYROX and mobility image coverage after integration |
| fa50fc69 | 2026-10-23T18:25:40+02:00 | ios | 1 |  |  | feat(ios): separate native exercise sorting and discipline filters, replace Deporte with Halterofilia |
| 7ae04430 | 2026-10-23T18:26:33+02:00 | domain-swift | 1 |  |  | feat(catalog): add 8 missing Olympic lifting derivatives and technical accessories |
| c56ebc7f | 2026-10-23T18:27:49+02:00 | domain-swift | 1 |  |  | feat(i18n): add complete Spanish technique notes and safety cues for 8 weightlifting drills |
| e512a743 | 2026-10-23T18:28:21+02:00 | domain-swift | 1 |  |  | feat(search): support English naming for new Olympic lifting variants |
| b2bc2160 | 2026-10-23T18:28:25+02:00 | domain-swift | 1 |  |  | feat(catalog): bilingual display aliases for lifting derivatives |
| b9ee0f4d | 2026-10-23T18:29:10+02:00 | web | 1 |  |  | feat(web): sync eight new lifting exercises into the shared catalog |
| 4f6cda4a | 2026-10-23T18:29:13+02:00 | web | 1 |  |  | test(web): expect 288 unique exercises after weightlifting audit |
| 28c1bd79 | 2026-10-23T18:29:15+02:00 | domain-swift | 1 |  |  | test(domain): enforce unique Olympic lifting variants and bilingual exercise search |
| 2d879a4c | 2026-10-23T18:29:18+02:00 | domain-swift | 1 |  |  | test(catalog): extend complete Spanish instruction checks to 288 exercises |
| 7b3afb1f | 2026-10-23T18:30:55+02:00 | backend | 1 |  |  | feat(db): seed eight stable-key Olympic lifting variations for MCP and web |
| 5018a161 | 2026-10-23T18:31:40+02:00 | tests | 1 |  |  | test(ios): keep order and discipline filtering independent within native modal |
| 2543c145 | 2026-10-23T18:31:44+02:00 | docs | 1 |  |  | docs(ios): document separate sorting and lifting facet, eight added movements |
| 449fda02 | 2026-10-23T18:31:47+02:00 | docs | 1 |  |  | docs(qa): add sorting, filtering and weightlifting catalog acceptance tests |
| af4746ab | 2026-10-23T18:33:15+02:00 | backend | 1 |  |  | chore(db): align migration filename with applied Supabase version |
| 3fa5e9c6 | 2026-10-23T18:33:17+02:00 | backend | 1 |  |  | chore(db): remove draft migration timestamp |
| 5988dd3f | 2026-10-23T18:34:41+02:00 | ios | 1 |  |  | fix(ios): apply muscle sorting to WOD templates too |
| 15e2f124 | 2026-10-23T18:36:40+02:00 | ios | 1 |  |  | fix(ios): never show WOD matches when a different discipline filter is active |
| 487bc908 | 2026-10-23T18:38:25+02:00 | domain-swift | 1 |  |  | test(domain): account for canonical English seed names while preserving Spanish aliases |
| d35eefe8 | 2026-10-23T18:38:28+02:00 | domain-swift | 1 |  |  | test(domain): update bilingual sport catalog count after eight added variants |
| b9e3dc50 | 2026-10-23T18:41:24+02:00 | MERGE | 0 |  | fp | Merge PR #50: ordenación y filtros nativos, catálogo ampliado de halterofilia |
| b4905ea1 | 2026-10-23T19:24:51+02:00 | ios | 1 |  |  | feat(ios): opaque workout-style exercise modal, alphabetic facets, outline icons and equipment ordering |
| 48e1289b | 2026-10-23T19:26:13+02:00 | domain-swift | 1 |  |  | feat(search): add Olympic and CrossFit acronyms, bilingual naming variants and safe canonical alias resolver |
| c5e444f8 | 2026-10-23T19:26:31+02:00 | domain-swift | 1 |  |  | fix(search): remove cross-exercise aliases and align rower/gymnastics canonical names |
| 9b81af37 | 2026-10-23T19:26:59+02:00 | domain-swift | 1 |  |  | fix(search): normalize punctuation and diacritics in acronym lookup (C&J, T2B, etc) |
| e7261834 | 2026-10-23T19:27:05+02:00 | domain-swift | 1 |  |  | feat(search): use shared aliases for iOS search, ranked results and board-scanner resolution |
| c6c15718 | 2026-10-23T19:28:02+02:00 | domain-swift | 1 |  |  | fix(search): case-insensitive alias lookup for existing English gymnastic and CrossFit exercise names |
| 0c77ab50 | 2026-10-23T19:28:30+02:00 | web | 1 |  |  | feat(web): display all 48 Olympic lifts in English with stable catalog IDs and ES/acronym aliases |
| ff0de466 | 2026-10-23T19:28:33+02:00 | web | 1 |  |  | test(web): keep historic IDs while asserting 48 canonical English lifting names and aliases |
| f74e2949 | 2026-10-23T19:29:11+02:00 | tests | 1 |  |  | test(ios): assert opaque cards, sorted facets, outline icons and material groups |
| 5b67471a | 2026-10-23T19:29:37+02:00 | domain-swift | 1 |  |  | test(domain): verify Olympics, CrossFit and gymnastics abbreviations in search and board scanning |
| 142c6258 | 2026-10-23T19:30:00+02:00 | domain-swift | 1 |  |  | fix(search): canonical-case mapping for existing CrossFit and lifting exercise display names |
| 4efd48d0 | 2026-10-23T19:30:51+02:00 | backend | 1 |  |  | feat(db): keep stable catalog keys, English lifting labels and additive ES/EN sport aliases |
| c91aa16d | 2026-10-23T19:31:51+02:00 | backend | 1 |  |  | fix(db): store English titles in separate presentation columns to preserve catalog key/name constraint |
| 990147c4 | 2026-10-23T19:32:28+02:00 | backend | 1 |  |  | fix(db): add English display column to catalog table and expose it through the existing view |
| 3dcabf3c | 2026-10-23T19:33:14+02:00 | backend | 1 |  |  | feat(mcp): return English lifting display labels while retaining original catalog keys |
| 6fb2d529 | 2026-10-23T19:33:17+02:00 | backend | 1 |  |  | feat(mcp): search enhanced ES/EN alias metadata and return English lifting names |
| 2e2414ef | 2026-10-23T19:37:10+02:00 | domain-swift | 1 |  |  | feat(domain): classify real exercise gear including wall balls, GHD, SkiErg, RowErg, boxes and sandbags |
| 9e35ed1d | 2026-10-23T19:37:28+02:00 | ios | 1 |  |  | feat(ios): sort exercise list by precise catalog equipment groups, not generic equipment strings |
| 2985fc7c | 2026-10-23T19:38:04+02:00 | domain-swift | 1 |  |  | test(domain): cover HYROX gear, boxes, ropes, ski/row ergs, GHD and disjoint row variants |
| 6aa7b61c | 2026-10-23T19:38:19+02:00 | tests | 1 |  |  | test(ios): verify all specific material groupings through shared domain classifier |
| cacd1e68 | 2026-10-23T19:39:03+02:00 | docs | 1 |  |  | docs(qa): document precise equipment categories and test gym/HYROX machine distinctions |
| 94581333 | 2026-10-23T19:39:07+02:00 | docs | 1 |  |  | docs(qa): document precise equipment categories and test gym/HYROX machine distinctions |
| 1001bcc2 | 2026-10-23T19:40:12+02:00 | domain-swift | 1 |  |  | fix(equipment): group standalone apparatus labels and Spanish plural forms without guessing from generic names |
| 12b18b32 | 2026-10-23T19:40:28+02:00 | domain-swift | 1 |  |  | test(domain): verify standalone equipment labels for SkiErg, RowErg, GHD and Wall/Slam Balls |
| 0d02c9a0 | 2026-10-23T19:41:30+02:00 | backend | 1 |  |  | feat(mcp): resolve English lifting labels and Spanish/acronym catalog aliases in basic search |
| 96888403 | 2026-10-23T19:42:05+02:00 | backend | 1 |  |  | fix(mcp): normalize accents with actual Unicode combining-mark range |
| 90d31fc5 | 2026-10-23T19:42:33+02:00 | backend | 1 |  |  | fix(mcp): type-safe HYROX catalog key matching |
| b147c097 | 2026-10-23T19:44:46+02:00 | backend | 1 |  |  | chore(db): align English labels migration with applied Supabase migration version |
| f0552eda | 2026-10-23T19:44:49+02:00 | backend | 1 |  |  | chore(db): remove obsolete migration filename |
| 9923b217 | 2026-10-23T19:45:26+02:00 | MERGE | 0 |  | fp | Merge PR #51: material-aware sorting, opaque modal and bilingual exercise aliases |
| 1ed11c0a | 2026-10-23T19:49:47+02:00 | domain-swift,ios | 111 |  | fp | feat(art): ilustraciones de movilidad tanda 1 (54 heroes) + alta de arte en fichas de movilidad |
| 140bf762 | 2026-10-24T00:37:10+02:00 | ios | 60 |  | fp | feat(art): ilustraciones de movilidad tanda 2 (30 heroes: resto movilidad + 2 HYROX) |
| ba610d13 | 2026-10-24T00:40:38+02:00 | ios | 66 |  | fp | feat(art): fotogramas carrusel tanda 3 (33 frames: hombro, escápula, columna/torácica) |
| fdbd3558 | 2026-10-24T12:58:14+02:00 | docs,domain-swift,ios | 11 |  | fp | fix(exercises): audit required gear and align SF Symbols |
| 3b3792df | 2026-10-24T13:00:47+02:00 | ios | 2 |  | fp | fix(iOS): make ExerciseCategorySymbols visible in existing Xcode targets |
| a0503d94 | 2026-10-24T13:19:08+02:00 | domain-swift,ios | 3 |  | fp | feat(exercises): compact muscle glyphs and multiple disciplines |
| 49febc33 | 2026-10-24T14:23:20+02:00 | ios | 1 |  | fp | feat(iOS): nine legible body-part glyphs for muscle chips |
| 5099d9f1 | 2026-10-24T14:38:46+02:00 | ios | 1 |  | fp | fix(iOS): show the Cardio heart icon in muscle chips |
| 1da10df0 | 2026-10-24T18:41:34+02:00 | backend,ci,docs,ios,other,tests,web | 24 |  | fp | feat(ai): add guided assistant connections and isolated OAuth authorization |
| 08551cb1 | 2026-10-24T18:45:18+02:00 | ios | 1 |  | fp | fix(iOS): map Dorsales to existing back muscle glyph |
| 43b6c870 | 2026-10-24T19:00:40+02:00 | docs | 1 |  | fp | docs: registrar despliegue del backend OAuth y pendientes |
| f063ead9 | 2026-10-24T19:14:41+02:00 | docs | 1 |  | fp | docs: registrar publicación web de consentimiento en IONOS |
| 363044ff | 2026-10-24T19:24:15+02:00 | docs | 1 |  | fp | docs: registrar activación OAuth y requisitos de publicación |
| 602b9f59 | 2026-10-24T19:33:31+02:00 | ci,docs,ios,other,tests | 14 |  | fp | feat(iOS): integrate official Google Sign-In SDK and promotional welcome |
| e42686c5 | 2026-10-24T19:37:39+02:00 | ios | 160 |  | fp | feat(art): fotogramas carrusel tanda 4 (80 frames: cadera, tobillo/pie, isquios, muñeca/codo, globales y HYROX) - completa los 113 fotogramas |
| 00c194a0 | 2026-10-24T19:38:37+02:00 | docs | 1 |  | fp | docs(art): regenerar auditoría con los stems de movilidad/HYROX |
| 6239bd8a | 2026-10-24T19:44:15+02:00 | domain-swift,ios | 3 |  | fp | fix(art): fase de salto visible en Burpee Broad Jump + captions de fase para WGS e Inchworm |
| ab42d793 | 2026-10-24T19:46:05+00:00 | ios | 2 |  | fp | Fix transparent enclosed details in launch mascot |
| 3f48e581 | 2026-10-24T19:47:18+02:00 | docs,other | 6 |  | fp | fix(iOS): resolve Google packages before opening generated Xcode project |
| 396f9baf | 2026-10-24T19:47:41+02:00 | ios | 2 |  | fp | fix(art): WGS f2 con codo al empeine (fase 2 visible, alineada con caption) |
| 1075577b | 2026-10-24T19:48:34+02:00 | backend,docs,ios,other,tests | 9 |  | fp | feat(ai): guiar la conexión de Claude con instrucciones y OAuth público |
| 920b8b67 | 2026-10-24T19:49:47+02:00 | ios | 2 |  | fp | fix(art): WGS f2 en linea grafica plana (misma figura/camara que f1/f3) |
| 443dd8b1 | 2026-10-24T19:59:38+00:00 | ci,ios | 3 |  | fp | Fix splash transparency and use authentic Repera head on running mascot |
| 4605a2e4 | 2026-10-24T20:00:56+02:00 | docs,ios,other,tests | 11 |  | fp | style(iOS): align Google sign-in button with Apple without shadow |
| e74ffd86 | 2026-10-24T20:02:34+00:00 | ci,ios | 3 |  | fp | Finish opaque original mascot and consistent running splash pose |
| a8b1fa2d | 2026-10-24T20:05:45+02:00 | docs,ios | 4 |  | fp | fix(iOS): use identical sign-in icon frames and button heights |
| 512382f7 | 2026-10-24T20:08:07+00:00 | ci,ios | 3 |  | fp | Restore clean solid Repera face and matching running pose from original mascot |
| bde0f43f | 2026-10-24T20:09:29+00:00 | ci | 1 |  | fp | Remove temporary original artwork transfer workflow |
| 877cbaa8 | 2026-10-24T20:14:12+00:00 | ci,ios,other | 3 |  | fp | Use the original Repera character running with transparent exterior and opaque face |
| 280c54b0 | 2026-10-24T20:17:27+02:00 | ios | 1 |  | fp | Unify ChatGPT Claude and Grok onboarding in AI connections |
| 863c5663 | 2026-10-24T20:31:26+02:00 | ios | 1 |  | fp | Show verified AI connections inline and centralize instructions |
| 59e8e1b4 | 2026-10-24T20:32:54+02:00 | ios | 6 |  | fp | Add authentic vector brand artwork for AI providers |
| f58a7e9c | 2026-10-24T20:33:06+02:00 | ios | 1 |  | fp | Use authentic ChatGPT Claude and Grok vector logos in connection buttons |
| 2546b09f | 2026-10-24T20:33:18+02:00 | ios | 1 |  | fp | Remove obsolete provider setup sheet and pending verification UI |
| 00a61caf | 2026-10-24T20:45:12+00:00 | ci,docs,ios | 5 |  | fp | Repair native splash image alpha and prevent stale MascotHero launch references |
| bd80f881 | 2026-10-24T20:47:20+00:00 | ci,docs,ios | 3 |  | fp | Refine launch barbell silhouette and keep all facial details opaque |
| 4eeca543 | 2026-10-24T21:05:21+00:00 | ci,ios,other | 6 |  | fp | Fix cached transparent iOS launch: opaque Repera mascot and new launch storyboard |
| eda7b22c | 2026-10-24T21:07:37+02:00 | ios | 10 |  | fp | Replace AI icons with user supplied SVG artwork and support dark appearance |
| d61c5d52 | 2026-10-24T21:09:35+02:00 | ios | 1 |  | fp | Tighten AI provider button spacing and hide row separators |
| d577f233 | 2026-10-24T21:21:30+02:00 | ios | 1 |  | fp | Redesign launch screen with standalone mascot on brand green |
| 1a2c20a0 | 2026-10-24T21:21:32+02:00 | ios | 1 |  | fp | Match launch background to Repera accent green |
| d02dcf8b | 2026-10-24T21:24:53+02:00 | ios | 4 |  | fp | Remove obsolete legacy splash image assets |
| c2d69e0e | 2026-10-24T21:25:19+02:00 | ci | 1 |  | fp | Automatically repair enclosed transparent mascot details on main |
| bb77408a | 2026-10-24T21:30:40+02:00 | ios | 1 |  | fp | Keep single matching mascot splash during auth restoration |
| db1a55b2 | 2026-10-24T21:31:06+00:00 | ios | 2 |  | fp | Install new overhead barbell mascot on native and SwiftUI launch |
| 88221001 | 2026-10-24T21:31:08+02:00 | other | 1 |  | fp | Repair larger enclosed transparent eyes and mouth in mascot |
| c413ac1d | 2026-10-24T21:39:03+02:00 | ios | 1 |  | fp | Show barbell-lifting Repera mascot in native launch screen |
| e1621b8d | 2026-10-24T21:39:29+02:00 | ci | 1 |  | fp | Repair transparent enclosed facial features on both launch mascots |
| a3072801 | 2026-10-24T21:45:53+02:00 | ci | 1 |  | fp | Add running mascot asset and repair launch face opacity |
| c045bd03 | 2026-10-24T21:46:09+02:00 | ios | 1 |  | fp | Use running Repera mascot during session restoration |
| 46be4cc5 | 2026-10-24T21:47:02+02:00 | other | 1 |  | fp | Force opaque facial features only within hero mascot face, preserve exterior alpha |
| 4db7545b | 2026-10-24T21:48:52+02:00 | ios | 1 |  | fp | Fix invalid MascotRunning asset catalog JSON causing actool failure |
| 2709141f | 2026-10-24T21:49:40+02:00 | ci | 1 |  | fp | Replace brittle mascot asset generator with JSON validation for Xcode |
| 8c0d1e74 | 2026-10-24T21:50:05+00:00 | ios | 2 |  | fp | Create dedicated solid green opaque launch artwork |
| de0ae459 | 2026-10-24T21:58:47+02:00 | other | 1 |  | fp | Build corrected opaque Repera hero and running pose with authentic head |
| 3947e369 | 2026-10-24T21:59:19+02:00 | ci | 1 |  | fp | Run one-time image repair and authentic mascot running composition |
| da46b4bd | 2026-10-24T22:01:51+02:00 | other | 1 |  | fp | Repair original Repera pupils and mouth as solid shapes and remove duplicate runner head parts |
| f689bfdf | 2026-10-24T22:02:16+02:00 | ci | 1 |  | fp | Rebuild Repera launch artwork with opaque face and clean matching runner |
| a94f1626 | 2026-10-24T22:06:42+02:00 | other | 1 |  | fp | Rebuild original Repera face once; preserve exact facial features in running pose without duplicate shapes |
| 625f74c1 | 2026-10-24T22:06:59+02:00 | other | 1 |  | fp | Correct argument parsing newline in splash asset builder |
| ca6bfa8d | 2026-10-24T22:07:48+02:00 | ci | 1 |  | fp | Rebuild both splash mascots from original Repera artwork |
| ed623149 | 2026-10-24T22:09:19+02:00 | ci | 1 |  | fp | Temporarily transfer original Repera mascot for faithful pose transformation |
| da7910a0 | 2026-10-24T22:14:00+02:00 | ci | 1 |  | fp | Publish faithful running mascot image with transparent background and validate splash assets |
| 045fc5a9 | 2026-10-24T22:15:31+02:00 | ci | 1 |  | fp | Validate launch mascot exterior alpha and opaque original facial details in CI |
| a45d07f0 | 2026-10-24T22:18:03+00:00 | docs | 1 |  | fp | Capture native startup proof from existing simulator video [skip ci] |
| 805b5e5c | 2026-10-24T22:44:25+02:00 | other | 1 |  | fp | Add launch-specific RGBA repair for opaque eyes smile and weights on transparent mascot |
| c57b9bfc | 2026-10-24T22:44:56+02:00 | ci | 1 |  | fp | Run one-time repair of Repera native launch artwork and verify it on brand-green background |
| 8c953709 | 2026-10-24T22:46:45+02:00 | other | 1 |  | fp | Refine equipment matte without jagged dark halos on green splash |
| 6238a1fc | 2026-10-24T22:47:03+02:00 | ci | 1 |  | fp | Rebuild and verify splash with smooth equipment alpha masks |
| 6fce452d | 2026-10-24T22:48:28+02:00 | ci | 1 |  | fp | Add native launch mascot full-pupil opacity regression checks to CI |
| 555d8af6 | 2026-10-24T22:55:27+02:00 | domain-swift,ios | 11 |  | fp | Arte: corrige 5 heroes incongruentes + pasos de instrucciones |
| 43aec645 | 2026-10-24T22:56:50+02:00 | ci,ios,other | 6 |  | fp | Restore visible native launch mascot using proven MascotHero asset with opaque pixels |
| a84fe2f2 | 2026-10-24T23:00:17+02:00 | domain-swift,ios | 8 |  | fp | Arte: carrusel propio para air squat (3 fases) |
| 386bbd40 | 2026-10-24T23:02:49+02:00 | ci | 1 |  | fp | Regenerate opaque native launch artwork and refresh iOS storyboard cache |
| d4a678f4 | 2026-10-24T23:03:46+02:00 | ci | 1 |  | fp | Correct pixel position for opaque smile validation |
| cb737326 | 2026-10-24T23:04:32+02:00 | ci | 1 |  | fp | Avoid CI workflow updates when publishing opaque launch image |
| 0efe5053 | 2026-10-24T23:04:43+02:00 | domain-swift,ios | 8 |  | fp | Arte: carrusel propio para goblet squat (3 fases) |
| b73aadde | 2026-10-24T23:04:43+02:00 | domain-swift,ios | 8 |  | fp | Arte: carrusel propio para KB swing (3 fases) |
| b1c063fd | 2026-10-24T23:05:07+02:00 | ci | 1 |  | fp | Fix staging command for opaque native launch assets |
| 67893b30 | 2026-10-24T23:05:56+02:00 | watch | 5 |  | fp | Watch: sincroniza thumbnails de los 5 heroes regenerados |
| 103e133f | 2026-10-24T23:07:10+02:00 | ci | 1 |  | fp | Regress native launch opacity and compiled resource naming against old green-eye screen |
| 57cca023 | 2026-10-24T23:07:50+02:00 | ci | 1 |  | fp | Validate installed iOS launch storyboard and opaque mascot inside compiled Repera.app |
| 3cbf45f7 | 2026-10-24T23:13:16+02:00 | ci,docs,ios,other | 6 |  | fp | Fix native green-only splash by bundling opaque Repera mascot PNG directly and validating compiled app |
| 929dc303 | 2026-10-24T23:13:47+02:00 | ci | 1 |  | fp | Use unambiguous PNG header bytes in packaged launch asset test |
| 293ccaef | 2026-10-24T23:15:32+02:00 | ci,docs,ios,other | 6 |  | fp | Force fresh iOS launch snapshot by renaming storyboard to ReperaLaunchBundle with directly bundled opaque mascot |
| d48084cf | 2026-10-24T23:18:09+02:00 | ios | 1 |  | fp | Restore legacy launch storyboard file for existing Xcode projects while keeping the new splash active |
| e7c65d3c | 2026-10-24T23:18:57+02:00 | ci | 1 |  | fp | Guard against missing legacy launch storyboard path in old generated Xcode projects |
| bfc85684 | 2026-10-24T23:19:00+02:00 | docs | 1 |  | fp | Document active launch storyboard and compatibility with stale XcodeGen project references |
| bcdcc203 | 2026-10-24T23:23:03+02:00 | ci,docs,ios,other | 7 |  | fp | Fix black native launch screen with Apple's UILaunchScreen image/color asset configuration |
| 8fe32833 | 2026-10-24T23:23:43+02:00 | ci | 1 |  | fp | Correct launch contract regression assertion for removed storyboard target |
| 8f2e5299 | 2026-10-24T23:30:54+02:00 | ci | 1 |  | fp | Install new overhead barbell Repera launch mascot in asset catalog and bundle |
| 37b81416 | 2026-10-24T23:31:29+02:00 | domain-swift,ios | 8 |  | fp | Arte: carrusel propio para thruster con mancuernas (3 fases) |
| c9910792 | 2026-10-24T23:31:29+02:00 | domain-swift,ios | 8 |  | fp | Arte: carrusel propio para thruster con kettlebell (3 fases) |
| 0ffd4b2f | 2026-10-24T23:31:33+02:00 | domain-swift,ios | 8 |  | fp | Arte: carrusel propio para pistol squat (3 fases) |
| 25f562bf | 2026-10-24T23:31:34+02:00 | domain-swift,ios | 8 |  | fp | Arte: carrusel propio para ball slam (3 fases) |
| acc2a12b | 2026-10-24T23:31:34+02:00 | domain-swift,ios | 8 |  | fp | Arte: carrusel propio para broad jump (3 fases) |
| 2b4d80c1 | 2026-10-24T23:31:38+02:00 | domain-swift,ios | 8 |  | fp | Arte: carrusel propio para snatch con mancuerna (3 fases) |
| 5a701ee1 | 2026-10-24T23:31:38+02:00 | domain-swift,ios | 8 |  | fp | Arte: carrusel propio para clean con kettlebell (3 fases) |
| 7293d5d0 | 2026-10-24T23:31:38+02:00 | domain-swift,ios | 8 |  | fp | Arte: carrusel propio para jumping squat (3 fases) |
| 51abfe4d | 2026-10-24T23:32:59+02:00 | ci,docs,ios,other | 9 |  | fp | Show new barbell Repera mascot on brand green during native and first SwiftUI launch, then runner |
| 07d0ac70 | 2026-10-24T23:33:42+02:00 | ci | 1 |  | fp | Validate newly generated overhead barbell mascot transparency and solid facial details |
| 90e40c73 | 2026-10-24T23:34:57+02:00 | docs | 1 |  | fp | Update launch architecture documentation for new overhead-barbell image and two-stage startup |
| d25c7031 | 2026-10-24T23:38:34+02:00 | ios | 1 |  | fp | Preserve stable startup layout and satisfy Repera WindowGroup source contract |
| 2988bc25 | 2026-10-24T23:39:43+02:00 | ios | 1 |  | fp | Keep barbell splash the same visual scale between native launch and SwiftUI on rotation |
| 4aa3943c | 2026-10-24T23:45:04+02:00 | ci,docs,ios,other | 6 |  | fp | Replace white native launch with brand-green storyboard showing same barbell mascot as first SwiftUI frame |
| c2975813 | 2026-10-24T23:49:53+02:00 | ci | 1 |  | fp | Generate solid RGB native barbell splash artwork for iOS launch storyboard |
| 379d3aec | 2026-10-24T23:51:11+02:00 | ci,docs,ios,other | 6 |  | fp | Fix green-only native splash with dedicated opaque barbell illustration and fresh launch storyboard |
| 45470159 | 2026-10-24T23:58:04+02:00 | ci,docs,ios,other | 6 |  | fp | Restore standard iOS LaunchScreen.storyboard with solid green barbell mascot and compile-time verification |
| 62f425e1 | 2026-10-25T00:03:47+02:00 | ci | 1 |  | fp | Require actual iOS simulator video and contact sheet for native launch validation |
| 6fb1285c | 2026-10-25T00:16:06+02:00 | ci | 1 |  | fp | Fix real simulator capture using isolated venv and detect missing mascot, not just green |
| f6e17943 | 2026-10-25T00:16:08+02:00 | ci | 1 |  | fp | Validate decoded bundled PNG instead of bytewise comparing Xcode-recompressed image |
| 9ceaeace | 2026-10-25T00:16:45+02:00 | ci | 1 |  | fp | Analyze existing simulator video for blank native launch before changing assets |
| 1699f44a | 2026-10-25T00:17:47+02:00 | ci | 1 |  | fp | Decode every variable-framerate screenshot even when simulator recording contains two frames |
| 9884fbf5 | 2026-10-25T00:20:10+02:00 | ios | 1 |  | fp | Render one opaque full-screen barbell image in native launch without size multipliers |
| d88df43d | 2026-10-25T00:21:22+02:00 | ci | 1 |  | fp | Capture actual iOS framebuffer screenshots when variable-frame-rate video produces black frames |
| 1d76f306 | 2026-10-25T00:22:43+02:00 | ci,other,tests | 4 |  | fp | Invalidate iOS launch snapshot with build 9 and preserve version across XcodeGen regeneration |
| 77dd9738 | 2026-10-25T00:24:38+02:00 | domain-swift,ios | 20 |  | fp | Arte: carruseles man maker (6 fases) y jumping lunge (3 fases, vista frontal con piernas derecha/izquierda identificadas) |
| e579bbce | 2026-10-25T00:35:04+02:00 | domain-swift,ios | 8 |  | fp | Arte: carrusel burpee al cajon (3 fases, caja consistente a escala estatura ratio 0.316, trapezoide uniforme) |
| b151c4d5 | 2026-10-25T01:32:52+02:00 | domain-swift | 1 |  | fp | Test: captions de carrusel verificadas desde los nombres sembrados reales del catálogo (puente spanishAlias EN->ES), no solo desde la clave española |
| 418fda71 | 2026-10-25T09:01:15+01:00 | backend,ci,docs,domain-swift,ios,other,tests | 26 |  | fp | feat(ios27): invisible offline-first exercise catalog with native background refresh |
| fc4c6212 | 2026-10-25T09:02:06+01:00 | other | 1 |  | fp | docs: mark iOS offline catalog as merged and clarify Android remains separate |
| 606d31c7 | 2026-10-25T09:42:29+01:00 | ios | 1 |  |  | feat(iOS): introduce live sport recording UI, GPS and offline GPX route library |
| f8f5d34c | 2026-10-25T09:43:55+01:00 | domain-swift | 1 |  |  | feat(live): integrate Models.swift with sport recording and Home |
| a82b0d55 | 2026-10-25T09:43:58+01:00 | ios | 1 |  |  | feat(live): integrate ReperaStore.swift with sport recording and Home |
| 384d5c4d | 2026-10-25T09:44:00+01:00 | ios | 1 |  |  | feat(live): integrate HealthKitStore.swift with sport recording and Home |
| 24b70c8b | 2026-10-25T09:44:03+01:00 | ios | 1 |  |  | feat(live): integrate RootTabView.swift with sport recording and Home |
| c803ada1 | 2026-10-25T09:44:06+01:00 | ios | 1 |  |  | feat(live): integrate HomeView.swift with sport recording and Home |
| f328705b | 2026-10-25T09:44:08+01:00 | ios | 1 |  |  | feat(live): integrate HistoryView.swift with sport recording and Home |
| 610a305e | 2026-10-25T09:44:11+01:00 | other | 1 |  |  | feat(live): integrate project.yml with sport recording and Home |
| 3f84691a | 2026-10-25T09:45:27+01:00 | ios | 1 |  |  | fix(live): provide center access and tick map timer continuously |
| e8a13c81 | 2026-10-25T09:46:43+01:00 | ios | 1 |  |  | fix(home): focus the recorded start day when returning from Live |
| 27cbfada | 2026-10-25T09:46:46+01:00 | ios | 1 |  |  | fix(navigation): keep chosen Progress SF Symbol gauge |
| 0b7fc847 | 2026-10-25T09:49:31+01:00 | docs | 1 |  |  | docs: document live sports, GPS lifecycle and Home integration |
| 599a36ec | 2026-10-25T09:50:13+01:00 | ios | 1 |  |  | fix(live): send only value-type GPS fixes across Swift 6 concurrency boundary |
| d83f8244 | 2026-10-25T09:51:14+01:00 | domain-swift | 1 |  |  | test(domain): verify live workout distance, active duration, and legacy JSON compatibility |
| 24a5d7e1 | 2026-10-25T09:52:01+01:00 | ios | 1 |  |  | refine(live): show speed for surf/ski/golf and center GPS map on user |
| 19f9d69a | 2026-10-25T09:54:25+01:00 | ios | 1 |  |  | fix(live): harden HomeView.swift for background and simultaneous sessions |
| d7e2b191 | 2026-10-25T09:54:27+01:00 | ios | 1 |  |  | fix(live): harden LiveActivityView.swift for background and simultaneous sessions |
| ef981ea2 | 2026-10-25T09:54:30+01:00 | ios | 1 |  |  | fix(live): harden HealthKitStore.swift for background and simultaneous sessions |
| cc300f9f | 2026-10-25T10:19:51+01:00 | ios | 1 |  |  | feat(live-activity): shared typed training status for lock screen and Dynamic Island |
| b6b7921b | 2026-10-25T10:19:54+01:00 | widget | 1 |  |  | feat(widget): Repera lock screen and Dynamic Island for all workouts |
| 0b0bc902 | 2026-10-25T10:20:59+01:00 | ios | 1 |  |  | feat(activitykit): lifecycle coordinator for live and planned training sessions |
| dc72a2b1 | 2026-10-25T10:21:41+01:00 | widget | 1 |  |  | fix(widget): keep timer as Text for reusable metric rendering |
| 4e3da82d | 2026-10-25T10:21:44+01:00 | widget | 1 |  |  | feat(widget): register workout activity alongside rest countdown |
| 246dae59 | 2026-10-25T10:21:47+01:00 | other | 1 |  |  | build: include shared workout Live Activity schema in app and widget targets |
| 69d02802 | 2026-10-25T10:22:20+01:00 | ios | 1 |  |  | feat(live): publish lock screen and Dynamic Island status on start, pause, resume, GPS changes and finish |
| 2e9d26fc | 2026-10-25T10:22:47+01:00 | ios | 1 |  |  | feat(training): publish ActivityKit for every planned/OCR/Watch workout and close it on finish |
| bc615068 | 2026-10-25T10:23:06+01:00 | ios | 1 |  |  | feat(navigation): reopen live or planned session from lock screen and Dynamic Island |
| 4a8b9899 | 2026-10-25T10:24:45+01:00 | ios | 1 |  |  | fix(activitykit): restore planned Live Activity from disk hydration and deduplicate updates |
| dc5e762f | 2026-10-25T10:24:58+01:00 | ios | 1 |  |  | fix(activitykit): prevent delayed GPS or Watch updates from recreating ended widgets |
| 789b2c34 | 2026-10-25T10:26:55+01:00 | docs | 1 |  |  | docs: lock screen and Dynamic Island behavior across free and planned workouts |
| bca1a076 | 2026-10-25T10:32:49+01:00 | ios | 1 |  |  | fix(live): keep verified mean speed and pace visible on pause and finish |
| 8d81880d | 2026-10-25T10:32:52+01:00 | ios | 1 |  |  | fix(widget): use average outdoor metrics and unknown indoor values without fabrication |
| b6c9a5d2 | 2026-10-25T10:37:10+01:00 | ios | 1 |  | fp | fix(ios): split SwiftUI app root into independently typechecked view stages |
| ebe7c33f | 2026-10-25T10:37:36+01:00 | other | 1 |  | fp | fix(xcodegen): add remote catalog store explicitly to iOS Compile Sources |
| 751ccdfe | 2026-10-25T10:37:58+01:00 | other | 1 |  | fp | test(xcodegen): fail early if iOS remote catalog file is absent from actual Compile Sources |
| 48a07ce5 | 2026-10-25T10:38:23+01:00 | other | 1 |  | fp | fix(tests): correct regex escapes when extracting Xcode Compile Sources phases |
| 5bda1b8c | 2026-10-25T10:38:54+01:00 | other | 1 |  | fp | fix(ios): keep native BG refresh plist and Xcode regeneration preflight consistent |
| 9f6102c5 | 2026-10-25T10:38:58+01:00 | ios | 1 |  | fp | fix(ios): keep native BG refresh plist and Xcode regeneration preflight consistent |
| 78750418 | 2026-10-25T10:39:01+01:00 | docs | 1 |  | fp | fix(ios): keep native BG refresh plist and Xcode regeneration preflight consistent |
| f33bb3b4 | 2026-10-25T10:40:54+01:00 | ios | 1 |  |  | fix(healthkit): provide explicit HKWorkout type in external workout reconciliation |
| cbf44c51 | 2026-10-25T10:40:59+01:00 | tests | 1 |  | fp | test(xcodegen): verify new catalog source in Repera target, stale builds and split app root |
| cdd0ee86 | 2026-10-25T10:43:22+01:00 | MERGE | 0 |  | fp | feat(iOS): En vivo y Live Activities universales para Repera (#59) |
| f530bb83 | 2026-10-25T10:50:55+01:00 | other | 1 |  |  | fix(xcode): ensure En vivo sources are included in project.yml |
| 55a3e6f9 | 2026-10-25T10:50:59+01:00 | other | 1 |  |  | fix(xcode): ensure En vivo sources are included in check_xcode_sources.py |
| 1f52916b | 2026-10-25T10:51:02+01:00 | other | 1 |  |  | fix(xcode): ensure En vivo sources are included in Repera-Xcode.command |
| 50da8451 | 2026-10-25T10:51:06+01:00 | tests | 1 |  |  | fix(xcode): ensure En vivo sources are included in test_xcode_sources.py |
| b5afc5d8 | 2026-10-25T10:52:21+01:00 | ios | 1 |  |  | fix(activitykit): tolerate non-Sendable Activity handle under Swift 6 concurrency |
| d5ad682c | 2026-10-25T10:57:29+01:00 | MERGE | 0 |  | fp | fix(iOS): restore En vivo sources in Xcode target and Swift 6 ActivityKit (#60) |
| 0425a481 | 2026-10-25T11:10:45+01:00 | ios | 1 |  |  | feat(live): fullscreen MapKit with floating Liquid Glass HUD, contextual metrics and Strava-like action dock |
| 04eb6662 | 2026-10-25T11:11:56+01:00 | ios | 1 |  |  | fix(gps): suppress transient CoreLocation operation errors and validate GPX with actionable Spanish messages |
| 5bcda360 | 2026-10-25T11:13:07+01:00 | ios | 1 |  |  | fix(routes): persist long GPX paths atomically on disk, migrate old routes, preserve UI default after saving |
| 092195c8 | 2026-10-25T11:15:04+01:00 | ios | 1 |  |  | feat(map): acquire a single preview GPS fix before starting, without recording a workout |
| 07b05ee2 | 2026-10-25T11:18:52+01:00 | MERGE | 0 |  | fp | feat(iOS): full-screen Liquid Glass En vivo map and route import fixes (#61) |
| 363249d9 | 2026-10-25T11:25:30+01:00 | domain-swift | 1 |  |  | feat(domain): persist optional favorite route identity for repeated GPS sessions |
| 202e4f90 | 2026-10-25T11:26:28+01:00 | ios | 1 |  |  | feat(live): align close X in My Routes and link saved activities to favorite GPS route |
| 33863f92 | 2026-10-25T11:28:32+01:00 | ios | 1 |  |  | feat(exercises): sports filter history, GPS favorites, repeat-route stats and evolution charts |
| 863c642c | 2026-10-25T11:29:19+01:00 | ios | 1 |  |  | feat(library): add Deportes filter leading to recorded sports and GPS progression |
| a647975e | 2026-10-25T11:29:46+01:00 | other | 1 |  |  | build(sports): register route evolution Swift source in project.yml |
| b71d3f52 | 2026-10-25T11:29:49+01:00 | other | 1 |  |  | build(sports): register route evolution Swift source in check_xcode_sources.py |
| cb8f9fdb | 2026-10-25T11:29:51+01:00 | other | 1 |  |  | build(sports): register route evolution Swift source in Repera-Xcode.command |
| 308f1705 | 2026-10-25T11:29:54+01:00 | tests | 1 |  |  | build(sports): register route evolution Swift source in test_xcode_sources.py |
| a0b3dfd5 | 2026-10-25T11:30:06+01:00 | domain-swift | 1 |  |  | test(domain): favorite GPS route ID roundtrip and backwards-compatible decoding |
| e1e535db | 2026-10-25T11:31:02+01:00 | ios | 1 |  |  | fix(routes): restore cloud-synced favorite route library from stable session IDs |
| 7a184be8 | 2026-10-25T11:31:26+01:00 | ios | 1 |  |  | style(routes): place inline Mis rutas title and X in same native navigation bar |
| 97918da5 | 2026-10-25T11:36:06+01:00 | ios | 1 |  |  | fix(corelocation): avoid fatal background setter, use guarded CLBackgroundActivitySession and stop GPS on pause |
| c1b00980 | 2026-10-25T11:36:25+01:00 | ios | 1 |  |  | feat(tabs): rename En vivo to Comenzar and use play SF Symbol |
| 4ea56288 | 2026-10-25T11:36:28+01:00 | ios | 1 |  |  | feat(ui): use Comenzar in header and keep recording status clear |
| ebcc7ba9 | 2026-10-25T11:37:02+01:00 | domain-swift | 1 |  |  | fix(progress): count recorded sports in real cardio minutes and group by start day |
| 84e23c6c | 2026-10-25T11:37:32+01:00 | ios | 1 |  |  | feat(progress): show Comenzar sports time, sessions and GPS kilometers in Progreso |
| f1663109 | 2026-10-25T11:38:02+01:00 | domain-swift | 1 |  |  | test(progress): verify cardio minutes for Comenzar sports and start-day grouping |
| 668dd9f8 | 2026-10-25T11:46:34+01:00 | MERGE | 0 |  | fp | feat(iOS): Comenzar, safe background GPS and sport/route progress (#62) |
| 05bd4b5e | 2026-10-25T11:49:40+01:00 | ios | 1 |  |  | fix(progress): explicitly type sports collection for SwiftUI ForEach and avoid Binding inference |
| ed100c8f | 2026-10-25T11:49:42+01:00 | ios | 1 |  |  | fix(iOS27): replace deprecated background task submit API with asynchronous completion handler |
| cf3107c8 | 2026-10-25T11:55:14+01:00 | MERGE | 0 |  | fp | fix(iOS): typed sports progression and iOS 27 background scheduler (#63) |
| ccfd03c7 | 2026-10-25T12:00:21+01:00 | ios | 1 |  |  | feat(live): clean standalone pause controls, black metric toolbar, clearer chart icon and bigger duration |
| f023a017 | 2026-10-25T12:01:14+01:00 | ios | 1 |  |  | feat(routes): automatically archive new recorded paths, open saved route details from Cargar ruta |
| e7704909 | 2026-10-25T12:02:32+01:00 | ios | 1 |  |  | feat(routes): detail preview, recorded metrics, repeat, edit and delete saved paths |
| 915e62e0 | 2026-10-25T12:08:36+01:00 | ios | 1 |  |  | feat(live): finish straight to WorkoutDetail-style save view reusing route map and cardio splits |
| a4007afa | 2026-10-25T12:08:48+01:00 | ios | 1 |  |  | fix(live): format recorded distance in km in save preview |
| a9c1190c | 2026-10-25T12:09:15+01:00 | ios | 1 |  |  | fix(activitykit): omit redundant Recorrido GPS subtitle for free outdoor sessions |
| 92cf9df5 | 2026-10-25T12:09:19+01:00 | other | 1 |  |  | build(widget): package Repera brand asset catalog in Live Activity widget extension |
| c94b984a | 2026-10-25T12:09:52+01:00 | widget | 1 |  |  | feat(widget): Repera barbell mark in upper right, compact Island layout and redundant subtitle removed |
| c99475d9 | 2026-10-25T12:11:51+01:00 | ios | 1 |  |  | feat(live): preload selected route on save preview while distinguishing planned from GPS-recorded data |
| aabbf51a | 2026-10-25T12:19:02+01:00 | MERGE | 0 |  | fp | feat(iOS): Comenzar save detail, route library and branded Live Activities (#64) |
| 1614b532 | 2026-10-25T12:30:21+01:00 | ios | 1 |  |  | fix(comenzar): short contextual GPS warning, Guardar entreno labels and native discard sheet |
| 526a388c | 2026-10-25T12:31:36+01:00 | ios | 1 |  |  | feat(map): pitched 3D MapKit, recenter icon only after displacement, vertical X/GPS/metrics controls |
| bcaca414 | 2026-10-25T12:32:04+01:00 | ios | 1 |  |  | style(tabs): use livephoto.play symbol for Comenzar |
| d15a24ae | 2026-10-25T12:32:07+01:00 | widget | 1 |  |  | fix(widget): constrain compact Dynamic Island timer width and sport symbol size |
| 44a3913c | 2026-10-25T12:39:07+01:00 | MERGE | 0 |  | fp | fix(iOS): Comenzar 3D map, saved workout sheet and compact Live Activity (#65) |
| 122890d1 | 2026-10-25T12:44:47+01:00 | ios | 1 |  |  | style(routes): restore large left-aligned Mis rutas, black close/import, empty first and remove Sin ruta |
| edc0cf6a | 2026-10-25T12:46:28+01:00 | ios | 1 |  |  | feat(map): car-navigation perspective tracking true GPS course, pitch and ahead-of-user camera |
| bd58f9dd | 2026-10-25T12:46:56+01:00 | ios | 1 |  |  | fix(iOS): declare location UIBackgroundMode in real bundled Info.plist for GPS lock-screen tracking |
| 435f6992 | 2026-10-25T12:47:36+01:00 | ios | 1 |  |  | feat(healthkit): authorize workout-route writing and attach own GPS track to matching Repera HKWorkout |
| 518fd8cf | 2026-10-25T12:48:01+01:00 | ios | 1 |  |  | fix(healthkit): validate nonoptional route timestamps before exporting |
| c7e73a35 | 2026-10-25T12:48:33+01:00 | ios | 1 |  |  | feat(healthkit): export recorded GPS to HealthKit after workout linkage for both live and eligible planned sessions |
| 6826b9a7 | 2026-10-25T12:49:37+01:00 | ios | 1 |  |  | feat(live): show verified HealthKit heart/energy and cardio splits in save preview, request route sharing |
| 04caceb0 | 2026-10-25T12:49:58+01:00 | widget | 1 |  |  | fix(widget): fit full sport icon within Dynamic Island and render exact-second stopwatch on Lock Screen |
| 65c76476 | 2026-10-25T12:51:40+01:00 | ios | 1 |  |  | feat(map): color genuine GPS segments by measured or derived speed, avoid fabricated coloring without valid samples |
| 750cbff2 | 2026-10-25T12:52:12+01:00 | ci | 1 |  |  | test(ci): assert compiled Repera.app contains location background capability, not just source YAML |
| fbf6f865 | 2026-10-25T12:53:03+01:00 | ios | 1 |  |  | style(routes): big Mis rutas and black X in same custom header row |
| 1352283d | 2026-10-25T13:00:17+01:00 | MERGE | 0 |  | fp | feat(iOS): navigator GPS background and HealthKit route parity for Comenzar (#66) |
| e9d0fd3e | 2026-10-25T13:07:04+01:00 | ios | 1 |  |  | feat(live): persist active kilometer splits and GPX-derived upcoming turn guidance |
| bad2a244 | 2026-10-25T13:08:02+01:00 | ios | 1 |  |  | feat(cardio): active kilometer pace, real 1km split reports, GPX-turn proximity cues and lock-screen local alerts |
| eabc3cd2 | 2026-10-25T13:08:54+01:00 | domain-swift | 1 |  |  | feat(domain): store pause-adjusted per-km splits on completed GPS sessions backward compatibly |
| 6590649c | 2026-10-25T13:09:16+01:00 | ios | 1 |  |  | feat(ui): show next GPX turn and each km report during activity, live split pace and review splits |
| 8757a009 | 2026-10-25T13:09:39+01:00 | ios | 1 |  |  | feat(cardio): use verified active-time km splits in shared Health/Workout split component |
| db9ab550 | 2026-10-25T13:10:19+01:00 | ios | 1 |  |  | fix(history): always render recorded per-km splits on live GPS activities even without HealthKit HR |
| f30b6232 | 2026-10-25T13:11:53+01:00 | domain-swift | 1 |  |  | test(domain): check pause-adjusted per-km split roundtrip and legacy workout decoding |
| 0eb0cdb6 | 2026-10-25T13:13:01+01:00 | ios | 1 |  |  | fix(cardio): show live partial pace for running and km/h for cycling |
| bcb9f677 | 2026-10-25T13:13:38+01:00 | ios | 1 |  |  | fix(gpx): detect turns across 30m track windows even on dense imported GPS routes |
| 4ab1d8f9 | 2026-10-25T13:14:52+01:00 | ios | 1 |  |  | style(map): show current km, meters and live partial pace while following GPS route |
| 63229c13 | 2026-10-25T13:18:31+01:00 | ios | 1 |  |  | fix(swift): keep file-private LiveKmSplit storage encapsulated to satisfy access control |
| 06cd21d4 | 2026-10-25T13:32:03+01:00 | MERGE | 0 |  | fp | feat(iOS): completar navegación GPX orientativa y parciales activos en Comenzar (#67) |
| 052f17f4 | 2026-10-25T13:37:40+01:00 | ios | 1 |  |  | style(comenzar): merge current kilometer split into map metric glass and inline metrics |
| e9feae2b | 2026-10-25T13:37:57+01:00 | ios | 1 |  |  | refactor(comenzar): require GPS sport for split HUD in running or paused phases |
| db2fa8b2 | 2026-10-25T13:40:21+01:00 | MERGE | 0 |  | fp | style(iOS): show kilometer split inside Comenzar metrics HUD (#68) |
| c9a8246a | 2026-10-25T13:48:25+01:00 | ios | 1 |  |  | feat(comenzar): spoken GPX turns and kilometer splits with accessible in-map mute control |
| 213ce753 | 2026-10-25T13:49:47+01:00 | ios | 1 |  |  | style(comenzar): centralize spoken alerts toggle in shared kilometer HUD for map and metrics |
| 58441752 | 2026-10-25T13:53:50+01:00 | MERGE | 0 |  | fp | feat(iOS): GPX spoken turn guidance and kilometer reports in Comenzar (#69) |
| 9ab13484 | 2026-10-25T13:59:01+01:00 | ios | 1 |  |  | fix(comenzar): move spoken km/turn alerts to map and metrics toolbar controls |
| d8c6ee10 | 2026-10-25T14:00:53+01:00 | MERGE | 0 |  | fp | fix(iOS): locate spoken guidance toggle in Comenzar topbar (#70) |
| ba62f64a | 2026-10-25T14:29:02+01:00 | ios | 1 |  |  | style(comenzar): opaque white/light black/dark sport and route circles without Liquid Glass |
| e0ef41f1 | 2026-10-25T14:30:27+01:00 | ios | 1 |  |  | test(iOS): update outdated root tab smoke assertion to Comenzar |
| 4703072f | 2026-10-25T14:35:37+01:00 | MERGE | 0 |  | fp | style(iOS): opaque adaptive circles in Comenzar and corrected tab smoke test (#72) |
| cee86507 | 2026-10-25T16:02:02+01:00 | ios | 1 |  |  | feat(iOS): modelar favoritos y recencia de rutas con migración compatible |
| dffc2b5a | 2026-10-25T16:03:23+01:00 | ios | 1 |  |  | feat(iOS): miniaturas GPS, últimas cinco rutas y sección favoritos |
| cbffe089 | 2026-10-25T16:04:46+01:00 | ios | 1 |  |  | feat(iOS): editar rutas en pantalla nativa con selector de deportes y estrella |
| ea4217b9 | 2026-10-25T16:05:29+01:00 | ios | 1 |  |  | fix(iOS): sincronizar indicadores de favoritos con la biblioteca de rutas |
| cf26f194 | 2026-10-25T16:06:59+01:00 | ios | 1 |  |  | fix(iOS): evitar key path a elemento de tupla en ordenación de rutas |
| 3ee0e001 | 2026-10-25T16:09:23+01:00 | ios | 1 |  |  | fix(iOS): conservar selección de deporte al volver desde el selector |
| a1b758d5 | 2026-10-25T16:11:47+01:00 | ios | 1 |  |  | fix(iOS): ordenar últimas rutas por la actividad reciente al repetir recorrido |
| 69109244 | 2026-10-25T16:15:18+01:00 | docs,ios,other | 7 |  | fp | fix(iOS): live GPS metrics, background tracking, spoken guidance and maps |
| a947a5c9 | 2026-10-25T16:16:09+01:00 | ios | 1 |  |  | fix(iOS): geometría CGFloat consistente al dibujar miniaturas de rutas |
| 18c29c5d | 2026-10-25T16:16:41+01:00 | MERGE | 0 |  | fp | Merge pull request #74 from rmoya87/feat/ios-recent-routes-favorites |
| 8d3ab653 | 2026-10-25T16:29:34+01:00 | ios | 1 |  |  | feat(iOS): ampliar deportes en vivo con iconos, categorías, HealthKit y GPS específico |
| 1bb5b704 | 2026-10-25T16:31:31+01:00 | ios | 1 |  |  | feat(iOS): calcular desnivel GPS con muestras válidas y restaurar tras interrupciones |
| a305fbbd | 2026-10-25T16:33:06+01:00 | ios | 1 |  |  | feat(iOS): fichas deportivas con métricas apropiadas y desnivel en directo |
| a05d6e38 | 2026-10-25T16:33:34+01:00 | domain-swift | 1 |  |  | feat(domain): contabilizar los nuevos deportes en minutos de cardio y progreso |
| d9055248 | 2026-10-25T16:34:05+01:00 | ios | 1 |  |  | feat(iOS): resumen con pulso real, energía y desnivel; limpiar estado GPS al descartar |
| ed1ce91e | 2026-10-25T16:34:45+01:00 | ios | 1 |  |  | feat(iOS): histórico deportivo con distancia, tiempo y métricas reales por actividad |
| d99799ac | 2026-10-25T16:35:09+01:00 | ios | 1 |  |  | feat(iOS): iconos coherentes para nuevos entrenamientos de Apple Salud |
| a88e3a39 | 2026-10-25T16:35:32+01:00 | domain-swift | 1 |  |  | test(domain): nuevas disciplinas suman cardio sin inventar sensores |
| 5e95cc60 | 2026-10-25T16:36:19+01:00 | ios | 1 |  |  | fix(iOS): usar SurfingSports para windsurf/kitesurf y figura Pilates nativa |
| ee525bb3 | 2026-10-25T16:56:44+01:00 | ci,docs,domain-swift,ios,tests | 11 |  | fp | feat(iOS): unified GPS and native HealthKit for free and planned workouts |
| cba49780 | 2026-10-25T17:21:24+01:00 | MERGE | 0 |  |  | Merge main into expanded iOS sports; keep unified GPS architecture |
| 5890215d | 2026-10-25T17:22:43+01:00 | MERGE | 0 |  | fp | feat(iOS): nuevos deportes y métricas nativas (#76) |
| fff1ef52 | 2026-10-25T21:24:02+01:00 | ios | 1 |  |  | fix(iOS): iconos deportivos, nombres y orden alfabético; ocultar opciones heredadas |
| fffec97a | 2026-10-25T21:34:20+01:00 | ios | 1 |  |  | fix(progress): eliminar panel independiente Deportes Comenzar; conservar métricas agregadas |
| 9de04e27 | 2026-10-25T21:34:33+01:00 | domain-swift | 1 |  |  | fix(progress): usar día de inicio de Comenzar también en mapa de actividad |
| 229d62b8 | 2026-10-25T21:35:09+01:00 | domain-swift | 1 |  |  | test(progress): sesiones Comenzar y programadas comparten resumen, cardio y heatmap |
| 2177ca15 | 2026-10-25T21:36:34+01:00 | ios | 1 |  |  | fix(progress): mantener rachas y heatmap alineados con día de Comenzar |
| 56655794 | 2026-10-25T21:38:53+01:00 | ios | 1 |  |  | fix(iOS): eliminar await innecesario al almacenar muestras GPS en Salud |
| 2eb7cdd5 | 2026-10-25T21:38:56+01:00 | ios | 1 |  |  | fix(iOS): sustituir HKWorkoutActivityType dance obsoleto por cardioDance |
| 97b48d17 | 2026-10-25T21:38:58+01:00 | ios | 1 |  |  | fix(iOS): capturar self débilmente en tareas externas de GPS programado |
| 37837401 | 2026-10-25T21:42:10+01:00 | MERGE | 0 |  | fp | Merge pull request #77 from rmoya87/feat/ios-live-sport-icons-and-sorting |
| 61af552f | 2026-10-25T23:41:10+01:00 | docs,other | 4 |  | fp | docs(gps): document unified free/planned GPS and HealthKit architecture |
| f457e61f | 2026-10-25T23:52:08+01:00 | ios | 7 |  | fp | Adapt DUO landscape and GPS/navigation UI |
| c0b0eae9 | 2026-10-26T00:18:57+01:00 | ios | 5 |  | fp | Fix DUO layout backgrounds, diary and exercise panes |
| 96efb7b6 | 2026-10-26T00:38:25+01:00 | ios | 4 |  | fp | Adaptive right-column Settings, routines and exercise actions |
| 7e5c480b | 2026-10-26T00:49:19+01:00 | ios | 4 |  | fp | Quick log becomes Apuntar ejercicio with numeric keypad and glass cards |
| fc3ef7e1 | 2026-10-26T00:52:39+01:00 | ios | 1 |  | fp | Center empty Routines card in expanded Diary layout |
| b6f2f879 | 2026-10-26T01:17:35+01:00 | ios | 1 | POST | fp | Refine GPS map voice, route banner and recording controls |
| 9ab2b510 | 2026-10-26T01:25:17+01:00 | ios | 2 | POST | fp | Fix recovery grid layout and Progress tab scroll restoration |
| f4292959 | 2026-10-26T01:29:18+01:00 | ios | 2 | POST | fp | Polish Home workout cards and separate landscape map guidance from metrics |
| 03636b4d | 2026-10-26T01:41:17+01:00 | ios | 4 | POST | fp | Normalize Home cards and compact free Progress charts |
| 6ac9f0e4 | 2026-10-26T06:34:52+01:00 | ios | 1 | POST | fp | Only show Home calendar dots for completed workouts |
| b75ecbcb | 2026-10-26T06:42:24+01:00 | ios | 1 | POST | fp | Fix stale calendar workout dot on selected empty day |
| 627af033 | 2026-10-26T08:18:13+01:00 | domain-swift | 1 | POST | fp | Keep edited live set prescriptions and block snapshots, using stable source item IDs |
| 35a93242 | 2026-10-26T08:19:25+01:00 | ios | 1 | POST | fp | Persist live Play plan edits and preserve logged sets by stable exercise identity on routine edit |
| 7ce8a9ec | 2026-10-26T08:20:35+01:00 | ios | 1 | POST | fp | Persist Play edits on every series change and before finish, support removal and correct Scan/Edit draft reconciliation |
| 19c88728 | 2026-10-26T08:23:35+01:00 | domain-swift | 1 | POST | fp | Add regression tests for edited Play sets, repeated exercises, scanned WODs and saved history |
| 3433d04b | 2026-10-26T08:26:34+01:00 | ios | 1 | POST | fp | Persist only user-authored Play edits immediately, not automatically suggested set values |
| 0897ff9b | 2026-10-26T08:27:18+01:00 | ios | 1 | POST | fp | Prevent duplicate exercise results being reassigned during plan edits; fallback only for legacy IDs |
| c898bc77 | 2026-10-26T08:28:17+01:00 | ios | 1 | POST | fp | Preserve row IDs when deleting sets and use explicit kg instead of stale 1RM percentages |
| 4b7c864e | 2026-10-26T08:28:49+01:00 | docs | 1 | POST | fp | Document regression checklist for Play and scanned workout editing persistence |
| 388f1756 | 2026-10-26T08:29:31+01:00 | docs | 1 | POST | fp | Document persistent planned-set edits and distinct confirmed session results |
| 020c0978 | 2026-10-26T08:31:41+01:00 | ios | 1 | POST | fp | Preserve updated workout title when applying in-session plan edits |
| 53d9199c | 2026-10-26T08:38:41+01:00 | domain-swift | 1 | POST | fp | Expose editable AMRAP and other WOD results, including legacy inferred results |
| ea88a1ca | 2026-10-26T08:40:58+01:00 | ios | 1 | POST | fp | Edit saved results for every global WOD format, including RFT and scoreless legacy workouts |
| 90ceb455 | 2026-10-26T08:42:01+01:00 | ios | 1 | POST | fp | Commit WOD score numbers live so Save never races UIKit focus loss |
| 38bc0f3b | 2026-10-26T08:43:46+01:00 | domain-swift | 1 | POST | fp | Regression tests for editing every global WOD score, RFT time and legacy AMRAP |
| 2fc87556 | 2026-10-26T08:44:55+01:00 | domain-swift | 1 | POST | fp | Keep newly added completed-workout exercise instance identity on repeated edits |
| d78eac8c | 2026-10-26T08:46:25+01:00 | domain-swift | 1 | POST | fp | Regression tests for Play's edited sets, repeated exercises and scanned RFT preservation |
| f6b08004 | 2026-10-26T08:48:38+01:00 | docs | 1 | POST | fp | Document editing and preserving all completed WOD results, including RFT without stored score |
| 9f1d4dd1 | 2026-10-26T08:49:17+01:00 | docs | 1 | POST | fp | Add hands-on RFT and all-format score saving regression checklist |
| 444cf043 | 2026-10-26T08:59:57+01:00 | domain-swift | 1 | POST | fp | Fix completed workout edits retaining pending sets and recorded identity |
| 742c4f3a | 2026-10-26T09:00:50+01:00 | domain-swift | 1 | POST | fp | Add regression tests for Play and completed workout roundtrips |
| 5fca2afb | 2026-10-26T09:01:09+01:00 | docs | 1 | POST | fp | Document persistence of mixed completed and pending workout sets |
| 90176952 | 2026-10-26T09:04:19+01:00 | domain-swift | 1 | POST | fp | Test mixed scanner-style WOD score and interval draft persistence |
| 887fe0e7 | 2026-10-26T09:04:48+01:00 | domain-swift | 1 | POST | fp | Fix argument order in interval persistence regression |
| 2ac10650 | 2026-10-26T09:06:24+01:00 | domain-swift | 1 | POST | fp | Correct expected For Time seconds after score edit |
| c680e21f | 2026-10-26T09:07:42+01:00 | domain-swift | 1 | POST | fp | Recover missing WOD block format from saved completed score |
| 703848be | 2026-10-26T09:07:58+01:00 | domain-swift | 1 | POST | fp | Test old scanned workouts restore recorded score format |
| 6592bcf6 | 2026-10-26T09:08:11+01:00 | docs | 1 | POST | fp | Document restoring legacy block format from recorded WOD result |
| dba1597d | 2026-10-26T09:24:36+01:00 | domain-swift | 1 | POST | fp | Preserve recorded WOD scores across subsequent format edits |
| 888d56df | 2026-10-26T09:25:10+01:00 | domain-swift | 1 | POST | fp | Test score history after changing completed workout format |
| cb0189e9 | 2026-10-26T09:25:41+01:00 | ios | 1 | POST | fp | Surface prior WOD format scores in completed session summary |
| 4d228c6b | 2026-10-26T09:26:10+01:00 | ios | 1 | POST | fp | Explain week copying and preserve prior score context when editing formats |
| 3b202ef0 | 2026-10-26T09:27:37+01:00 | ios | 1 | POST | fp | Place trained days below weekly progress heading in landscape DUO |
| 47f73700 | 2026-10-26T09:27:55+01:00 | ios | 1 | POST | fp | Prepare real daily average active calories and comparable prior-period mean |
| 34890e97 | 2026-10-26T09:28:56+01:00 | ios | 1 | POST | fp | Align calorie and body weight chart cards with comparable metric tiles |
| 55bf2628 | 2026-10-26T09:29:50+01:00 | ios | 1 | POST | fp | Keep recovery, readiness, sleep and physiology paired cards same minimum height in DUO |
| ed7bab54 | 2026-10-26T09:30:29+01:00 | ios | 1 | POST | fp | Normalize vertical insets for paired recovery cards |
| 28fcbaff | 2026-10-26T09:31:08+01:00 | docs | 1 | POST | fp | Document WOD score preservation and DUO progress presentation |
| 2106c264 | 2026-10-26T09:32:42+01:00 | tests | 1 | POST | fp | Update regression contracts for persisted WOD score history and DUO cards |
| 01ac6180 | 2026-10-26T09:32:44+01:00 | tests | 1 | POST | fp | Update regression contracts for persisted WOD score history and DUO cards |
| 3ab17b2c | 2026-10-26T09:33:31+01:00 | ios | 1 | POST | fp | Fix closing braces in weight chart metric row |
| 644a14de | 2026-10-26T09:34:40+01:00 | tests | 1 | POST | fp | Bring completed-workout source contracts up to date with result editor |
| 05b6b9a4 | 2026-10-26T09:35:19+01:00 | domain-swift | 1 | POST | fp | Polish regression naming and equal-height recovery cards |
| ec67cd80 | 2026-10-26T09:35:22+01:00 | ios | 1 | POST | fp | Polish regression naming and equal-height recovery cards |
| db32c849 | 2026-10-26T09:36:18+01:00 | domain-swift | 1 | POST | fp | Do not overwrite untyped legacy WOD scores with different result units |
| b67fe038 | 2026-10-26T09:36:33+01:00 | tests | 1 | POST | fp | Cover typed and legacy historical WOD score preservation |
| 11ae0941 | 2026-10-26T09:36:35+01:00 | domain-swift | 1 | POST | fp | Cover typed and legacy historical WOD score preservation |
| 748c8ebf | 2026-10-26T09:37:01+01:00 | ios | 1 | POST | fp | Compare previous-period active calories from the same HealthKit sources |
| 1b6ed3eb | 2026-10-26T09:37:03+01:00 | ios | 1 | POST | fp | Compare previous-period active calories from the same HealthKit sources |
| c94a7caf | 2026-10-26T09:52:50+01:00 | ios | 1 | POST | fp | Scope diary plans to real weeks, migrate legacy recurring entries and copy previous week explicitly |
| 5f28adc8 | 2026-10-26T09:53:41+01:00 | ios | 1 | POST | fp | Add diary week navigation and date-bound programming and copy/clear actions |
| 8bdd9231 | 2026-10-26T09:54:04+01:00 | ios | 1 | POST | fp | Assign reusable workout templates to one selected diary date only |
| 398b5f3c | 2026-10-26T09:54:18+01:00 | ios | 1 | POST | fp | Show only date-specific plans in Home and weekly planned counts |
| 57869769 | 2026-10-26T09:55:50+01:00 | ios | 1 | POST | fp | Size recovery graphs from DUO column width instead of leaving artificial empty card heights |
| 6f4c6753 | 2026-10-26T09:57:02+01:00 | ios | 1 | POST | fp | Normalize legacy weekday writes to dated plans, preventing new recurring schedules |
| b4db4f84 | 2026-10-26T09:57:31+01:00 | ios | 1 | POST | fp | Keep physiology chart dimensions responsive in both available-data states |
| 67c40f05 | 2026-10-26T09:58:32+01:00 | ios | 1 | POST | fp | Harden dated diary migration, first-paint refresh and calendar helper calls |
| 2c51a47a | 2026-10-26T09:58:35+01:00 | ios | 1 | POST | fp | Harden dated diary migration, first-paint refresh and calendar helper calls |
| 2db6bcfe | 2026-10-26T09:59:42+01:00 | ios | 1 | POST | fp | Preserve cloud revision precedence when migrating historical weekly plans |
| 50d0594b | 2026-10-26T10:00:23+01:00 | domain-swift | 1 | POST | fp | Update model semantics and static regressions for weekly dated diary |
| 08c28f8f | 2026-10-26T10:00:25+01:00 | tests | 1 | POST | fp | Update model semantics and static regressions for weekly dated diary |
| 8293ee3d | 2026-10-26T10:01:01+01:00 | docs | 1 | POST | fp | Document dated diary scheduling, legacy migration, week-copy behavior and responsive recovery charts |
| 80556035 | 2026-10-26T10:01:56+01:00 | tests | 1 | POST | fp | Add regressions for dated weekly planning, migration and responsive recovery charts |
| aa2f7de5 | 2026-10-26T10:03:16+01:00 | ios | 1 | POST | fp | Allow training readiness tile content to grow for larger accessibility text |
| 1c65ea86 | 2026-10-26T10:03:59+01:00 | ios | 1 | POST | fp | Keep favorited templates when clearing or removing dated diary plans |
| 8a8de807 | 2026-10-26T10:04:15+01:00 | tests | 1 | POST | fp | Protect favorite templates when clearing a scheduled week |
| d755a416 | 2026-10-26T10:04:51+01:00 | tests | 1 | POST | fp | Rename diary regression to reflect new date-based weekly scheduling |
| 78ad9067 | 2026-10-26T10:26:28+01:00 | ios | 1 | POST | fp | Move diary week navigation to Liquid Glass topbar on iPhone and left column header on DUO |
| 3705578e | 2026-10-26T10:27:22+01:00 | tests | 1 | POST | fp | Update diary layout regressions and UI documentation for Liquid Glass week picker |
| 221e564f | 2026-10-26T10:27:25+01:00 | tests | 1 | POST | fp | Update diary layout regressions and UI documentation for Liquid Glass week picker |
| fa1af8e3 | 2026-10-26T10:27:28+01:00 | docs | 1 | POST | fp | Update diary layout regressions and UI documentation for Liquid Glass week picker |
| 0e776a69 | 2026-10-26T10:27:48+01:00 | tests | 1 | POST | fp | Make DUO header regression target the actual diary column |
| 5db68ab3 | 2026-10-26T10:28:46+01:00 | ios | 1 | POST | fp | Keep week navigation and Programado heading fitting on narrow DUO columns |
| 1be22975 | 2026-10-26T10:40:15+01:00 | ios | 1 | POST | fp | Wrap compact iPhone empty routines state in same white card as DUO |
| 7c8b6775 | 2026-10-26T10:40:42+01:00 | ios | 1 | POST | fp | Reduce recovery readiness and trend cards by one third with compact content not empty padding |
| 5d2b249d | 2026-10-26T10:43:03+01:00 | ios | 1 | POST | fp | Introduce native Apple Music now playing bar with safe external playback fallback |
| ecd403b7 | 2026-10-26T10:43:22+01:00 | other | 1 | POST | fp | Declare optional Apple Music library permission for authenticated song metadata |
| 710df0f4 | 2026-10-26T10:43:25+01:00 | ios | 1 | POST | fp | Declare optional Apple Music library permission for authenticated song metadata |
| 4c551420 | 2026-10-26T10:43:55+01:00 | ios | 1 | POST | fp | Allow shared Now Playing row to draw divider only when audio is detected |
| 3483dccd | 2026-10-26T10:44:09+01:00 | ios | 1 | POST | fp | Display shared Now Playing strip on workout and standalone full-screen timers |
| a67c81b1 | 2026-10-26T10:44:40+01:00 | ios | 1 | POST | fp | Show Now Playing below Comenzar start controls and inside active GPS and metrics cards |
| 29c61804 | 2026-10-26T10:45:45+01:00 | ios | 1 | POST | fp | Prevent invisible music row from producing a blank card or padding |
| 0ab73c2c | 2026-10-26T10:45:58+01:00 | ios | 1 | POST | fp | Only present Music card and separators when an actual player is detected |
| a39e44db | 2026-10-26T10:47:08+01:00 | docs | 1 | POST | fp | Document native Apple Music integration, supported external audio fallback and layout refinements |
| 23332862 | 2026-10-26T10:47:29+01:00 | ios | 1 | POST | fp | Avoid cross-actor SwiftUI capture in Music privacy authorization callback |
| f2b734f7 | 2026-10-26T10:48:00+01:00 | ios | 1 | POST | fp | Avoid showing stale Apple Music metadata when another audio app is playing |
| 720bebaa | 2026-10-26T10:48:30+01:00 | tests | 1 | POST | fp | Add public MediaPlayer privacy and placement regression contracts for timer and Comenzar |
| 3946de02 | 2026-10-26T10:48:53+01:00 | tests | 1 | POST | fp | Test shared empty-state cards and smaller recovery charts alongside music integration |
| 05074573 | 2026-10-26T10:54:15+01:00 | ios | 1 | POST | fp | Keep Now Playing definition in existing iOS timer compile source |
| 1555fb1e | 2026-10-26T10:54:29+01:00 | ios | 1 | POST | fp | Retain compatible source placeholder to avoid duplicate Now Playing types in regenerated projects |
| 532c0b6c | 2026-10-26T10:54:59+01:00 | tests | 1 | POST | fp | Guard against missing Now Playing symbol and duplicate declarations in generated Xcode targets |
| c0a5abcd | 2026-10-26T10:55:23+01:00 | other | 1 | POST | fp | Validate Now Playing lives in a guaranteed iOS target source without duplicate declarations |
| e22c924b | 2026-10-26T11:07:29+01:00 | ios | 1 | POST | fp | Remove unsupported generic Now Playing UI and permission from iOS |
| e2a0241a | 2026-10-26T11:07:34+01:00 | other | 1 | POST | fp | Remove unsupported generic Now Playing UI and permission from iOS |
| 155b09b0 | 2026-10-26T11:07:37+01:00 | ios | 1 | POST | fp | Remove unsupported generic Now Playing UI and permission from iOS |
| a81d7805 | 2026-10-26T11:07:39+01:00 | other | 1 | POST | fp | Remove unsupported generic Now Playing UI and permission from iOS |
| 6bbf22e0 | 2026-10-26T11:07:49+01:00 | ios | 1 | POST | fp | Remove unused music component and its obsolete tests |
| 2d17a1e0 | 2026-10-26T11:07:54+01:00 | tests | 1 | POST | fp | Remove unused music component and its obsolete tests |
| 3669f813 | 2026-10-26T11:08:21+01:00 | ios | 1 | POST | fp | Remove Now Playing from Comenzar and put idle metric start controls at top left |
| 8ef18671 | 2026-10-26T11:09:39+01:00 | ios | 1 | POST | fp | Replace QuickLog steppers with exercise-specific numeric inputs and native swipe-to-delete series |
| 88d77452 | 2026-10-26T11:10:16+01:00 | ios | 1 | POST | fp | Fix Swift numeric row string interpolations in QuickLog |
| e2d870d2 | 2026-10-26T11:10:50+01:00 | docs | 1 | POST | fp | Document removal of music and new QuickLog swipe/input and metrics start placement |
| 06069bd6 | 2026-10-26T11:11:20+01:00 | ios | 1 | POST | fp | Keep empty legacy Swift source so cached Xcode projects still compile after music removal |
| 3a20a81a | 2026-10-26T11:11:46+01:00 | tests | 1 | POST | fp | Protect music removal, metrics start position and exercise-aware swipe numeric quick logging |
| 8214ee2e | 2026-10-26T11:22:23+01:00 | ios | 1 | POST | fp | Highlight selected exercise in DUO green with grouped top and bottom corner radii |
| 797a45f7 | 2026-10-26T11:22:48+01:00 | ios | 1 | POST | fp | Align metrics Audio Map Play and Finish in one leading horizontal toolbar |
| 627dfefa | 2026-10-26T11:23:40+01:00 | tests | 1 | POST | fp | Test green rounded DUO selected rows and leading metrics playback actions |
| 6be82b04 | 2026-10-26T11:23:58+01:00 | docs | 1 | POST | fp | Document selected DUO row corners and left-aligned metrics actions |
| 2434b375 | 2026-10-26T11:27:23+01:00 | ios | 1 | POST | fp | Split DUO selected row background into a simple SwiftUI view to fix type-check timeout |
| 7acc3af7 | 2026-10-26T11:27:37+01:00 | ios | 1 | POST | fp | Remove unused optional routine binding in diary swipe action |
| e49888ec | 2026-10-26T11:28:11+01:00 | tests | 1 | POST | fp | Update DUO selection regression for isolated background shape and unused routine cleanup |
| 063a2386 | 2026-10-26T11:31:57+01:00 | ios | 1 | POST | fp | Keep playback controls right aligned in Metrics and arrange Play Finish side by side |
| 5c258f89 | 2026-10-26T11:32:19+01:00 | tests | 1 | POST | fp | Test right-anchored metric actions with horizontally adjacent Play and Finish |
| 94dc4f35 | 2026-10-26T11:32:34+01:00 | docs | 1 | POST | fp | Clarify Metrics actions remain right anchored with horizontal Play Finish |
| d0c323c7 | 2026-10-26T11:32:52+01:00 | tests | 1 | POST | fp | Avoid checking Swift documentation comments as actual vertical layouts |
| 07ab1d19 | 2026-10-26T11:40:28+01:00 | ios | 1 | POST | fp | Standardize custom topbar safe-area insets and top-align trailing controls with and without subtitles |
| 30423687 | 2026-10-26T11:40:56+01:00 | ios | 1 | POST | fp | Unify screen and sheet topbar custom actions to shared safe-area spacing |
| 0be1f288 | 2026-10-26T11:41:01+01:00 | ios | 1 | POST | fp | Unify screen and sheet topbar custom actions to shared safe-area spacing |
| 21eb3c6b | 2026-10-26T11:41:05+01:00 | ios | 1 | POST | fp | Unify screen and sheet topbar custom actions to shared safe-area spacing |
| 24cdd8c7 | 2026-10-26T11:41:09+01:00 | ios | 1 | POST | fp | Unify screen and sheet topbar custom actions to shared safe-area spacing |
| cf3dcb6f | 2026-10-26T11:41:14+01:00 | ios | 1 | POST | fp | Unify screen and sheet topbar custom actions to shared safe-area spacing |
| 0bafaa94 | 2026-10-26T11:42:47+01:00 | tests | 1 | POST | fp | Add source regressions for shared top/right header insets and native toolbar exceptions |
| 29b13e0b | 2026-10-26T11:43:24+01:00 | docs | 1 | POST | fp | Document unified custom topbar insets and native iOS safe area conventions |
| bb683029 | 2026-10-26T11:49:27+01:00 | ios | 1 | POST | fp | fix(ios): match native barbell launch artwork size in first SwiftUI frame |
| 3e490f3b | 2026-10-26T11:54:02+01:00 | ios | 1 | POST | fp | Use safe-area-relative Apple-style header spacing instead of crowding top edge |
| e84d3c19 | 2026-10-26T11:54:37+01:00 | ios | 1 | POST | fp | Keep map canvas edge-to-edge but position overlay controls in safe area with consistent header margins |
| 25b68e01 | 2026-10-26T11:55:46+01:00 | tests | 1 | POST | fp | Test Apple safe-area map overlay, native compact exercise toolbar and updated topbar spacing |
| d9ee8142 | 2026-10-26T11:56:36+01:00 | ios | 1 | POST | fp | Use Apple native large exercise title and group compact actions on trailing toolbar |
| 39721fdd | 2026-10-26T11:57:31+01:00 | ios | 1 | POST | fp | Give header controls Apple-recommended touch spacing and preserve DUO title fit |
| d7b9bf44 | 2026-10-26T11:57:39+01:00 | ios | 1 | POST | fp | Give header controls Apple-recommended touch spacing and preserve DUO title fit |
| c89bec05 | 2026-10-26T11:57:43+01:00 | ios | 1 | POST | fp | Give header controls Apple-recommended touch spacing and preserve DUO title fit |
| a81db643 | 2026-10-26T11:58:08+01:00 | tests | 1 | POST | fp | Verify safe-area 12pt visual breathing room and 60pt control center spacing in map and exercise bars |
| 3e179c0b | 2026-10-26T11:58:35+01:00 | docs | 1 | POST | fp | Document Apple safe-area guidance and Repera design spacing choices without claiming universal pixel rules |
| b7b95b4b | 2026-10-26T12:00:09+01:00 | tests | 1 | POST | fp | Fix regression scope to include leading DUO exercise action HStack |
| e7f9325a | 2026-10-26T12:17:45+01:00 | ios | 1 | POST | fp | Move Diario title above week selector with trailing menu and match Progreso glass tabs without list top gap |
| 1e734d48 | 2026-10-26T12:18:19+01:00 | tests | 1 | POST | fp | Verify Diario mobile header order and Progreso-style pinned glass tabs without List section gap |
| 2a244ca7 | 2026-10-26T12:18:43+01:00 | docs | 1 | POST | fp | Document compact Diario header order and Progreso-matched Liquid Glass tabs |
| d7145ab9 | 2026-10-26T12:25:53+01:00 | ios | 1 | POST | fp | Keep Diario title compact week selector and options on one iPhone topbar row |
| 3693ab63 | 2026-10-26T12:26:46+01:00 | ios | 1 | POST | fp | Show exercise title Filter and Add inline on iPhone like DUO, preserve compact search and native WODs |
| 45486072 | 2026-10-26T12:27:36+01:00 | tests | 1 | POST | fp | Protect inline Diario title weekly selector and options order in iPhone header |
| 628e9964 | 2026-10-26T12:28:05+01:00 | tests | 1 | POST | fp | Test inline exercise title Filter Add controls on iPhone and DUO with native WODs fallback |
| 07c3f6ce | 2026-10-26T12:28:45+01:00 | docs | 1 | POST | fp | Document same-row Diario selector and exercise header actions on iPhone and DUO |
| c1b2dd44 | 2026-10-26T12:34:21+01:00 | ios | 1 | POST | fp | Tighten compact Diario gap below glass tabs by removing grouped list top margin |
| f58f81ac | 2026-10-26T12:34:36+01:00 | ios | 1 | POST | fp | Give all shared graph and card section headings Settings-like breathing room above previous content |
| 093ebcae | 2026-10-26T12:35:04+01:00 | ios | 1 | POST | fp | Expand only Home day carousel edge-to-edge on iPhone and DUO with screen-width day sizing |
| b1d6a465 | 2026-10-26T12:35:48+01:00 | tests | 1 | POST | fp | Update Home calendar regression to require full-width days while retaining margins on all other cards |
| c2391374 | 2026-10-26T12:36:20+01:00 | tests | 1 | POST | fp | Guard compact Diary tight tab-to-list spacing in source contracts |
| 8d83110f | 2026-10-26T12:37:03+01:00 | docs | 1 | POST | fp | Document tighter Diary tabs, shared section-title spacing and truly full-bleed Home day carousel |
| f4335626 | 2026-10-26T12:37:24+01:00 | tests | 1 | POST | fp | Add regression for Settings-style top spacing on shared graph and section headings |
| 6a8ac30f | 2026-10-26T12:45:21+01:00 | ios | 1 | POST | fp | Prevent first weekday glyph clipping without shifting subtitle and remove duplicate place below map |
| e750fb1d | 2026-10-26T12:45:38+01:00 | ios | 1 | POST | fp | Use copy icon for weekly actions and restore subtle Diary tabs-to-content spacing |
| 3ca50983 | 2026-10-26T12:45:58+01:00 | ios | 1 | POST | fp | Start Home calendar with yesterday first and selected today second without changing selection |
| e4e1cdea | 2026-10-26T12:46:40+01:00 | tests | 1 | POST | fp | Regress subtle Diary tabs spacing and copy icon retaining week management actions |
| 1f60cdb7 | 2026-10-26T12:47:02+01:00 | docs | 1 | POST | fp | Document workout summary date clipping fix, map footer, Diary copy icon, and Home yesterday-first positioning |
| a101698b | 2026-10-26T12:47:24+01:00 | tests | 1 | POST | fp | Protect date first-glyph, location footer and yesterday-first Home carousel behavior |
| 55790eb3 | 2026-10-26T12:54:38+01:00 | ios | 1 | POST | fp | Give Add Routine sheet breathing room above header and remove redundant scheduling explanation |
| fbe86d4a | 2026-10-26T12:55:20+01:00 | ios | 1 | POST | fp | Let Diary routines schedule date-specific copies while staying reusable; remove redundant favorites controls |
| 61a9c292 | 2026-10-26T12:57:10+01:00 | ios | 1 | POST | fp | Remove redundant 'Sin fecha' label from every saved Diario routine |
| 3a64c653 | 2026-10-26T12:57:46+01:00 | ios | 1 | POST | fp | Extract optional Diary routine scheduling bindings to keep large SwiftUI Form type-checkable |
| 4ee3ae55 | 2026-10-26T12:58:26+01:00 | tests | 1 | POST | fp | Regress Diary template date-copy retention, no redundant favorites and Add Routine sheet spacing |
| bbeb18c9 | 2026-10-26T12:58:47+01:00 | docs | 1 | POST | fp | Document routine library date-copy semantics and sheet header polish |
| 8b8a0697 | 2026-10-26T13:28:41+01:00 | domain-swift | 1 | POST | fp | Recognize completed unlogged WOD movements as conservative estimated muscle fatigue without inventing sets |
| 58d4465f | 2026-10-26T13:28:58+01:00 | domain-swift | 1 | POST | fp | Populate muscular balance from completed WOD checks with no detailed logged sets |
| a169dff4 | 2026-10-26T13:29:40+01:00 | domain-swift | 1 | POST | fp | Test real completed WOD stimulates muscles while planned-only and hard-mode remain unchanged |
| df357aca | 2026-10-26T13:30:13+01:00 | ios | 1 | POST | fp | Label estimated muscle stimulation from completed WOD without claiming actual recorded sets |
| e643d074 | 2026-10-26T13:30:50+01:00 | docs | 1 | POST | fp | Document real user WOD muscle balance root cause and safe no-deploy workaround |
| acf507be | 2026-10-26T14:12:51+01:00 | domain-swift | 1 | POST | fp | Support idempotent autosaving of performed sets without per-series confirmation |
| b922e5f6 | 2026-10-26T14:13:05+01:00 | ios | 1 | POST | fp | Persist Play input as actual exercise results, not only prescribed sets |
| de231b25 | 2026-10-26T14:13:48+01:00 | ios | 1 | POST | fp | Remove set check UI and save edited reps, load, RIR, and duration directly as performed results |
| 72868c2e | 2026-10-26T14:17:08+01:00 | domain-swift | 1 | POST | fp | Unify recorded and confirmed sets across progress volume, PRs, heatmap and session summaries |
| 0974b8a3 | 2026-10-26T14:17:23+01:00 | domain-swift | 1 | POST | fp | Count autosaved and confirmed workout sets throughout muscle fatigue and progress metrics |
| 806206c0 | 2026-10-26T14:17:27+01:00 | domain-swift | 1 | POST | fp | Count autosaved and confirmed workout sets throughout muscle fatigue and progress metrics |
| 00c26a37 | 2026-10-26T14:17:31+01:00 | domain-swift | 1 | POST | fp | Count autosaved and confirmed workout sets throughout muscle fatigue and progress metrics |
| a7b839ab | 2026-10-26T14:17:34+01:00 | ios | 1 | POST | fp | Count autosaved and confirmed workout sets throughout muscle fatigue and progress metrics |
| 90a670a3 | 2026-10-26T14:17:38+01:00 | ios | 1 | POST | fp | Count autosaved and confirmed workout sets throughout muscle fatigue and progress metrics |
| 6abfdaf7 | 2026-10-26T14:17:43+01:00 | ios | 1 | POST | fp | Count autosaved and confirmed workout sets throughout muscle fatigue and progress metrics |
| 3ec28bea | 2026-10-26T14:18:21+01:00 | domain-swift | 1 | POST | fp | Make workout volume match recorded sets across all progress and history displays |
| f9922c05 | 2026-10-26T14:19:10+01:00 | domain-swift | 1 | POST | fp | Test confirmed-set muscle recovery and never count unconfirmed plans or inferred hard RIR |
| 65ba5dc7 | 2026-10-26T14:19:37+01:00 | domain-swift | 1 | POST | fp | Regression: autosaved session set values replace by identity and persist through finish without check |
| ebf9f7f2 | 2026-10-26T14:20:38+01:00 | domain-swift | 1 | POST | fp | Preserve drop-set totals when replacing performed sets on every edit |
| 16bb031a | 2026-10-26T14:21:02+01:00 | ios | 1 | POST | fp | Only show actually worked exercise histories in Progress, not planned-only items |
| 4f80276c | 2026-10-26T14:21:27+01:00 | docs | 1 | POST | fp | Document no-check autosaved workout results and unified validated Progress calculations |
| 527b3bca | 2026-10-26T14:22:06+01:00 | tests | 1 | POST | fp | Protect no-check live set autosave and consistent progress muscle/PR/volume source of truth |
| b9c9b405 | 2026-10-26T14:23:41+01:00 | domain-swift | 1 | POST | fp | Keep per-exercise history consistent with confirmed workouts rather than planned-only exercises |
| d19c8301 | 2026-10-26T14:26:12+01:00 | domain-swift | 1 | POST | fp | Never infer planned work sets when only recorded warmups exist |
| 2aa0ad1d | 2026-10-26T14:26:25+01:00 | domain-swift | 1 | POST | fp | Test warmup-only sessions never count phantom working series for progress |
| 86aa165b | 2026-10-26T14:37:08+01:00 | domain-swift | 1 | POST | fp | Make completed workout prescription count in all progress metrics without per-exercise check |
| 8135e4d2 | 2026-10-26T14:37:50+01:00 | ios | 1 | POST | fp | Mark exercises accepted whenever a workout is saved finished including Watch imported and recovered history |
| d4c221e2 | 2026-10-26T14:38:36+01:00 | ios | 1 | POST | fp | Count finished Comenzar sports as measured-duration muscle stimulus and deduplicate HealthKit copies |
| 6de0d495 | 2026-10-26T14:38:58+01:00 | ios | 1 | POST | fp | Unify Progress snapshots for finished native sports and HealthKit duplicates without missing muscle load |
| 68a2b9fc | 2026-10-26T14:40:02+01:00 | domain-swift | 1 | POST | fp | Include finished score-only WODs in muscle stimulus regardless of per-movement check |
| 433feb38 | 2026-10-26T14:40:16+01:00 | domain-swift | 1 | POST | fp | Use finished workout context when estimating score-only WOD muscle load |
| 2476605e | 2026-10-26T14:42:30+01:00 | domain-swift | 1 | POST | fp | Test checked and unchecked historical finished workouts identically while excluding unfinished plans |
| 52c56237 | 2026-10-26T14:43:59+01:00 | domain-swift | 1 | POST | fp | Exclude unfinished draft sessions from historical exercise metrics even when a set was entered |
| 07b1d4a6 | 2026-10-26T14:44:47+01:00 | tests | 1 | POST | fp | Test historical and new finished workouts across all progress metrics and native Comenzar sports |
| abcfbda7 | 2026-10-26T14:45:32+01:00 | docs | 1 | POST | fp | Document completed workout no-check semantics, Supabase historical repair and Comenzar muscle progress |
| 27e01cec | 2026-10-26T14:52:06+01:00 | ios | 1 | POST | fp | Support independent multiple scheduled workout sessions per day in store |
| 15b5c06a | 2026-10-26T14:53:24+01:00 | ios | 1 | POST | fp | Show and individually manage multiple routines on each diary date |
| f94321d2 | 2026-10-26T14:54:05+01:00 | ios | 1 | POST | fp | Display multiple pending and completed workout cards together on Home |
| cda324cf | 2026-10-26T14:56:02+01:00 | ios | 1 | POST | fp | Remove active workout series by swipe without inline minus buttons |
| 94691326 | 2026-10-26T14:59:36+01:00 | ios | 1 | POST | fp | Flush completed workouts locally and explicitly enqueue Supabase mirror sync |
| 0b04eed4 | 2026-10-26T15:00:01+01:00 | ios | 1 | POST | fp | Expose honest manual Supabase sync feedback and errors in Settings |
| fbead1a6 | 2026-10-26T15:02:31+01:00 | ios | 1 | POST | fp | Expand Comenzar with native Watch sports and HealthKit activity mappings |
| 37d1ea67 | 2026-10-26T15:03:45+01:00 | tests | 1 | POST | fp | Update legacy source contracts for multi-session days and no-check progress |
| abd7403f | 2026-10-26T15:03:49+01:00 | tests | 1 | POST | fp | Update legacy source contracts for multi-session days and no-check progress |
| 3940bd30 | 2026-10-26T15:04:29+01:00 | tests | 1 | POST | fp | Add multi-session, sport stimulus, swipe deletion and mirror sync regression contracts |
| 04acb5d6 | 2026-10-26T15:06:15+01:00 | tests | 1 | POST | fp | Point scanner recording contract at BoardImportReviewView implementation |
| e21d725e | 2026-10-26T15:06:57+01:00 | docs | 1 | POST | fp | Document independent workouts, sport fatigue and manual mirror sync status |
| fc79b58f | 2026-10-26T15:07:28+01:00 | docs | 1 | POST | fp | Document multi-session storage, swipe behavior and verified Supabase mirror architecture |
| 551c4f4d | 2026-10-26T15:08:02+01:00 | docs | 1 | POST | fp | Update testing guide for no-check series, multiple workouts, Watch sensors and Supabase verification |
| cea1aaea | 2026-10-26T15:09:47+01:00 | ios | 1 | POST | fp | Prevent starting a second workout from overwriting an unfinished session |
| 693fd534 | 2026-10-26T15:10:12+01:00 | ios | 1 | POST | fp | Keep active workout when opening a different planned session preview |
| d62be1e3 | 2026-10-26T15:10:58+01:00 | ci | 1 | POST | fp | Run multi-session and workout sync source regressions in iOS 27 CI |
| f8705185 | 2026-10-26T15:11:22+01:00 | other | 1 | POST | fp | Update README status for multiple daily sessions, Play swipe and workout mirror |
| 89f4c471 | 2026-10-26T15:14:24+01:00 | ios | 1 | POST | fp | Keep Create editor visible when new workout could not begin |
| ee230d74 | 2026-10-26T15:14:29+01:00 | ios | 1 | POST | fp | Only open workout after selected planned routine actually starts |
| 828d2ad2 | 2026-10-26T15:14:57+01:00 | ios | 1 | POST | fp | Fix PersistenceError display conversion in Account synchronization view |
| b0968cc3 | 2026-10-26T15:18:11+01:00 | domain-swift | 1 | POST | fp | Count newly selectable cardio-intensive Comenzar sports in Progress metrics |
| d678ac1e | 2026-10-26T15:18:19+01:00 | ios | 1 | POST | fp | Avoid inflating cardio minutes from strength, mobility and recovery workouts |
| 93614760 | 2026-10-26T15:18:32+01:00 | tests | 1 | POST | fp | Regression tests for Comenzar cardio sports and non-cardio mobility workouts |
| 484bbf32 | 2026-10-26T15:18:48+01:00 | docs | 1 | POST | fp | Document cardio classification and non-cardio recovery activities |
| f470b2ac | 2026-10-26T15:18:52+01:00 | docs | 1 | POST | fp | Document cardio classification and non-cardio recovery activities |
| 64632867 | 2026-10-26T15:19:18+01:00 | ios | 1 | POST | fp | Expose gravel and generic fallback sport so Comenzar can record uncategorized activity |
| c6072eb2 | 2026-10-26T15:19:28+01:00 | ios | 1 | POST | fp | Keep unknown HealthKit workout category out of cardio-only metrics |
| 5d10fec7 | 2026-10-26T15:19:40+01:00 | tests | 1 | POST | fp | Update Comenzar regression for generic HealthKit non-cardio fallback |
| 05c31bb3 | 2026-10-26T15:20:48+01:00 | domain-swift | 1 | POST | fp | Persist deletion of final planned set in active session and routine block |
| 2f1445f2 | 2026-10-26T15:20:53+01:00 | domain-swift | 1 | POST | fp | Keep intentionally empty WOD prescription distinct from missing prescription |
| e574d4aa | 2026-10-26T15:21:09+01:00 | tests | 1 | POST | fp | Regression guard against resurrecting deleted final sets and WOD prescriptions |
| f616cf00 | 2026-10-26T15:29:41+01:00 | ios | 1 | POST | fp | Recover Supabase tokens automatically and require login only on irrecoverable auth expiry |
| 57a9968e | 2026-10-26T15:30:10+01:00 | ios | 1 | POST | fp | Restore automatic login refresh on foreground and redirect only after revoked session |
| 9cafdb48 | 2026-10-26T15:30:34+01:00 | ios | 1 | POST | fp | Automatically refresh Supabase login before syncing workout mirror |
| 8a379d7e | 2026-10-26T15:30:49+01:00 | ios | 1 | POST | fp | Require login for unrecoverable session, preserve offline use during network interruptions |
| 92c6d2c9 | 2026-10-26T15:31:36+01:00 | ios | 1 | POST | fp | Move average pace and speed into summary tiles above kilometer splits |
| 65664526 | 2026-10-26T15:32:54+01:00 | ios | 1 | POST | fp | Speak GPS kilometer splits reliably, redesign Comenzar recap and enable fullscreen route map with sport-specific colors |
| 19170af5 | 2026-10-26T15:33:19+01:00 | ios | 1 | POST | fp | Color saved land routes blue and water routes green with four-stop speed palette |
| 3eb62023 | 2026-10-26T15:35:19+01:00 | ios | 1 | POST | fp | Announce kilometer splits by voice only; keep audio active for queued guidance |
| 98dec3e7 | 2026-10-26T15:36:08+01:00 | ios | 1 | POST | fp | Track per-sport personal best distance, fastest kilometer and duration for Comenzar |
| 9280b30b | 2026-10-26T15:36:21+01:00 | ios | 1 | POST | fp | Surface Comenzar sports history and personal bests directly from Progreso |
| fd01ab95 | 2026-10-26T15:36:50+01:00 | ios | 1 | POST | fp | Separate estimated high-effort sport stimulus from low-intensity walking in Progress |
| 80fde14d | 2026-10-26T15:37:21+01:00 | ios | 1 | POST | fp | Keep low-intensity walking out of high-effort muscle estimates without losing overall fatigue |
| ec87d24f | 2026-10-26T15:37:39+01:00 | ios | 1 | POST | fp | Enable high-effort progress view for completed HIIT and CrossFit sports |
| bca8bdc7 | 2026-10-26T15:40:08+01:00 | ios | 1 | POST | fp | Remove obsolete notification-fallback state from kilometer speech pipeline |
| 22aaef21 | 2026-10-26T15:40:52+01:00 | ios | 1 | POST | fp | Expand recorded workout maps to interactive fullscreen with close control |
| 144cca50 | 2026-10-26T15:41:56+01:00 | tests | 1 | POST | fp | Add source regressions for Supabase login renewal, Comenzar maps/audio and sports Progress |
| 4fba64b2 | 2026-10-26T15:42:08+01:00 | ci | 1 | POST | fp | Execute Comenzar session and progress regression contracts in iOS CI |
| a0d6ff68 | 2026-10-26T15:43:02+01:00 | docs | 1 | POST | fp | Document token refresh, spoken kilometer guidance, map palettes and sport records |
| c049eb7d | 2026-10-26T15:43:08+01:00 | docs | 1 | POST | fp | Document token refresh, spoken kilometer guidance, map palettes and sport records |
| b2313ddd | 2026-10-26T15:43:12+01:00 | docs | 1 | POST | fp | Document token refresh, spoken kilometer guidance, map palettes and sport records |
| 4b72282b | 2026-10-26T15:43:57+01:00 | ios | 1 | POST | fp | Show average pace and speed summary above splits on saved Comenzar workout details |
| 206df9c1 | 2026-10-26T15:44:36+01:00 | ios | 1 | POST | fp | Serialize token refresh with workout mirror uploads and surface actual auth errors |
| e862ca34 | 2026-10-26T15:46:23+01:00 | ios | 1 | POST | fp | Link real Apple Watch HealthKit workout and metrics before saving Comenzar activity |
| abc4f747 | 2026-10-26T15:47:38+01:00 | tests | 1 | POST | fp | Cover Apple Watch matching and HealthKit metrics when saving Comenzar workout |
| 837b7495 | 2026-10-26T15:47:53+01:00 | docs | 1 | POST | fp | Document verified HealthKit linking on Comenzar save without duplicate workouts |
| c7e39830 | 2026-10-26T15:47:58+01:00 | docs | 1 | POST | fp | Document verified HealthKit linking on Comenzar save without duplicate workouts |
| b943d666 | 2026-10-26T15:48:23+01:00 | ios | 1 | POST | fp | Fix completed WOD muscle estimate call with workout context |
| df26af65 | 2026-10-26T15:48:25+01:00 | ios | 1 | POST | fp | Flatten saved activity review header and remove redundant Summary section |
| f535c002 | 2026-10-26T15:58:05+01:00 | ios | 1 | POST | fp | Fix AuthError compatibility using stable errorCode API |
| 5b8b04a7 | 2026-10-26T16:00:06+01:00 | domain-swift | 1 | POST | fp | Include repeated exercises from every workout block in progress and history |
| ce269f98 | 2026-10-26T16:00:45+01:00 | domain-swift | 1 | POST | fp | Test accepted input sets across repeated Power Snatch workout blocks |
| 1d03ba14 | 2026-10-26T16:01:01+01:00 | tests | 1 | POST | fp | Guard Supabase AuthError compatibility against unavailable kind property |
| c5e6df98 | 2026-10-26T16:03:21+01:00 | domain-swift | 1 | POST | fp | Honor entered reps, weights and RIR on finished workouts without checkmarks |
| 41e00cec | 2026-10-26T16:03:33+01:00 | tests | 1 | POST | fp | Align completed workout contract with saved input RIR semantics |
| c7c30a87 | 2026-10-26T16:03:46+01:00 | domain-swift | 1 | POST | fp | Test that completed inputs keep actual weight, reps and RIR without checks |
| 5cdbe946 | 2026-10-26T16:04:10+01:00 | domain-swift | 1 | POST | fp | Make accepted RIR XCTest numeric assertions explicit |
| ea2bf2a7 | 2026-10-26T16:12:00+01:00 | ios | 1 | POST | fp | Keep HealthKit identity stable when a workout clock is edited |
| eee9ec8d | 2026-10-26T16:12:31+01:00 | ios | 1 | POST | fp | Preserve manually edited workout times and measured Watch duration |
| ecbb4cf2 | 2026-10-26T16:12:53+01:00 | ios | 1 | POST | fp | Prevent edited workout times from relinking unrelated Health heart zones |
| 63ea9f77 | 2026-10-26T16:13:05+01:00 | ios | 1 | POST | fp | Refresh Health details after editing completed workout date or time |
| 94bbcef9 | 2026-10-26T16:13:46+01:00 | tests | 1 | POST | fp | Add regression contract for HealthKit identity after editing workout time |
| 954580a0 | 2026-10-26T16:15:07+01:00 | ios | 1 | POST | fp | Prefer same-session Watch HealthKit measurements when resolving edited workout details |
| f039a053 | 2026-10-26T16:16:09+01:00 | ios | 1 | POST | fp | Update all HealthKit duplicate guards to stable session-ID lookup |
| 500bb395 | 2026-10-26T16:22:14+01:00 | ios | 1 | POST | fp | Flatten completed workout header and show route-independent walking splits |
| 9cadf579 | 2026-10-26T16:22:34+01:00 | ios | 1 | POST | fp | Use matching green workout completion icon and tighten Home title-chip spacing |
| 795d7dd9 | 2026-10-26T16:23:15+01:00 | tests | 1 | POST | fp | Test flat workout summary, restored cardio splits and completed Home icon |
| 1ca608f0 | 2026-10-26T16:32:06+01:00 | ios | 1 | POST | fp | Tighten title-to-chip gap in workout cards |
| e3d9bead | 2026-10-26T16:32:18+01:00 | ios | 1 | POST | fp | Bring Home workout chips five points closer to title without overlap |
| b9833d65 | 2026-10-26T16:32:30+01:00 | tests | 1 | POST | fp | Assert tighter workout card chips spacing |
| cc5e0e6f | 2026-10-26T16:53:07+01:00 | ios | 1 | POST | fp | Place average pace and speed next to their icons in cardio tiles |
| ecf5cdce | 2026-10-26T16:53:36+01:00 | ios | 1 | POST | fp | Move completed workout date outside clipped inset-grouped row |
| 6e5cd420 | 2026-10-26T16:56:32+01:00 | ios | 1 | POST | fp | Add luminous green-yellow-orange-red route and reversible fullscreen zoom |
| ee3cbbab | 2026-10-26T16:57:18+01:00 | tests | 1 | POST | fp | Test unclipped section-header workout date and unchanged map location label |
| d4feccf3 | 2026-10-26T16:57:38+01:00 | tests | 1 | POST | fp | Guard native zoom map, vivid speed palette and inline pace stats |
| 3d1e7314 | 2026-10-26T17:03:17+01:00 | ios | 1 | POST | fp | Unify sport metric tiles and keep cardio/elevation charts equal in height |
| 97256056 | 2026-10-26T17:04:40+01:00 | ios | 1 | POST | fp | Combine sports splits and Health charts under one workout section without redundant headings |
| 77f8ec7d | 2026-10-26T17:05:34+01:00 | ios | 1 | POST | fp | Share full-screen zoom map and unified workout metrics card across Health and Repera details |
| 4cd1359c | 2026-10-26T17:06:15+01:00 | ios | 1 | POST | fp | Use shared zoom map and sport-aware unified workout section in Comenzar review |
| 3af67320 | 2026-10-26T17:07:09+01:00 | tests | 1 | POST | fp | Update Comenzar contracts for shared zoom map and three sport-aware metric tiles |
| 36fe23c1 | 2026-10-26T17:07:23+01:00 | tests | 1 | POST | fp | Update detail layout regression tests for single Entreno card and map without headers |
| 9bc44e11 | 2026-10-26T17:08:37+01:00 | ios | 1 | POST | fp | Only show Comenzar sport tiles when recorded data exists |
| 3ea33f27 | 2026-10-26T17:09:22+01:00 | ios | 1 | POST | fp | Adapt third training metric to distance for cycling and water sports |
| 5c387100 | 2026-10-26T17:10:30+01:00 | tests | 1 | POST | fp | Add reusable workout map, sport tiles, and equal-height chart regression tests |
| bcd7dde3 | 2026-10-26T17:12:08+01:00 | ios | 1 | POST | fp | Remove obsolete duplicated Health speed-tile component |
| 9113c444 | 2026-10-26T17:13:06+01:00 | ios | 1 | POST | fp | Introduce shared top metric tile for workouts, Comenzar, and Health |
| fa96661f | 2026-10-26T17:13:20+01:00 | ios | 1 | POST | fp | Reuse summary tile for finished workouts and Apple Health detail |
| a5de0d9c | 2026-10-26T17:13:35+01:00 | ios | 1 | POST | fp | Reuse identical top workout tiles in Comenzar review and normalize section layout |
| 07277228 | 2026-10-26T17:13:48+01:00 | tests | 1 | POST | fp | Assert all workout summaries use a single reusable tile design |
| 0dc1e4ee | 2026-10-26T17:19:02+01:00 | ios | 1 | POST | fp | Darken route map underlay and add gradient glow to speed trail |
| 865f3c91 | 2026-10-26T17:20:36+01:00 | ios | 1 | POST | fp | Read steps and sport-specific distance from linked HealthKit workouts with provenance |
| 937c7598 | 2026-10-26T17:21:46+01:00 | ios | 1 | POST | fp | Display real workout steps and associated movement distance in Repera and Health details |
| ac20b6b1 | 2026-10-26T17:22:38+01:00 | ios | 1 | POST | fp | Show measured steps and distances for tennis, padel, snow and cardio sessions |
| bb3c7737 | 2026-10-26T17:23:28+01:00 | ios | 1 | POST | fp | Avoid fake pace on strength cardio and racket sports without outdoor GPS |
| e3d6e908 | 2026-10-26T17:24:08+01:00 | tests | 1 | POST | fp | Guard dark map underlay and luminous gradient speed outline |
| b1024ead | 2026-10-26T17:24:27+01:00 | tests | 1 | POST | fp | Test measured per-workout steps and sport-specific HealthKit movement distances |
| 1cf4c6cb | 2026-10-26T17:26:14+01:00 | tests | 1 | POST | fp | Update padel and tennis metric tests for measured steps instead of dummy heart tiles |
| 2b8ed71d | 2026-10-26T17:28:04+01:00 | ios | 1 | POST | fp | Handle mixed cardio workouts with labeled ski, cycling and walking distances |
| ec3e9849 | 2026-10-26T17:28:20+01:00 | ios | 1 | POST | fp | Keep cardio distance unit labels when displaying imported Health workouts |
| 8ce7f034 | 2026-10-26T17:28:34+01:00 | ios | 1 | POST | fp | Label cycling and snow distance correctly in mixed sport sessions |
| bd4d7637 | 2026-10-26T17:28:54+01:00 | tests | 1 | POST | fp | Update HealthKit mixed-distance regression contracts |

## LibraryView (162 diff lines) - static read, 22:30 CET
Only iOS layout: compact Exercises header (title + filter + plus on one row), search field extraction, selected-row background shape, nav-bar toolbar visibility. No data/logic change found. No Android change made; visual parity not checked (no pixels). Remaining unread: History, Plan, QuickLog (342), StartHub, Theme, ReperaStore, HealthKitStore, HomeView, HealthRecovery, StatsView.

## QuickLogSheet (342 diff lines) - partial static read, 22:40 CET
Seen: sheet rebuilt as a List (sections), swipe-to-delete per set row (accessibility "Eliminar serie N") replacing the trash button, numbered circle + "Serie" header, steppers replaced by `metricRow` text-entry rows (load, deficit cm cap 60, weight cap 1500). Android QuickLogRows.validate already enforces the same caps (weight 0..1500, deficit 0..60) by static read. Not read: remainder of the diff (duration/quantity rows, guidance). No Android change made; open item.

## PlanView (549 diff lines) - partial static read, 22:50 CET
Apple adds a week selector (previous / current / next week, `weekOffset`), a week range label, and makes copy-previous-week, clear schedule and day assignment operate on the SELECTED week (`assigningDay: Date`, `copyPreviousWeekSchedule(to: selectedWeekStart)`, `scheduledRoutines(inWeekContaining:)`).
Android DiaryTab: weekday-keyed list (`assigningDay` = weekday Int), WeekCalendarStrip for the diary date, copy "Copiar semana pasada" and "Vaciar programación" exist (menu + confirm), but there is no previous/next week selector and the copy/clear actions have no selected-week parameter beyond the repo call. OPEN discrepancy (not implemented): week navigation and selected-week targeting. Needs a check of how Android stores date-specific schedule overrides vs Apple before porting. Rest of the Plan diff (DUO layout, top bars) not read.

## HistoryView (534 diff lines) - partial static read, 23:31 CET
Seen, differences vs Android (static, no change made):
- Apple groups wodResults per block: current-format score first, other-format scores of the SAME block listed under "Resultado de formato anterior". Android (MainActivity ~2061) lists every wodResults entry flat, no per-block split and no that label. Data is not lost; presentation differs. OPEN, small.
- Apple shows "Se ha recuperado la distancia, pero los puntos GPS no viajan por Supabase..." when distance exists without route points. Android has no such text (grep). OPEN, small.
- Apple route map: "Ampliar recorrido" fullscreen map with speed-colored segments and "Cerrar mapa". Not checked on Android route detail.
- Apple section headers renamed ("Parciales" <-> "Entreno") and "Vel. media/Vel. máx" tiles removed from one view. Not mapped.
- Editing: Apple re-reads the saved workout by sessionId before saving the draft. Not compared.
Not read: the other ~400 diff lines.

## HealthKitStore (258 diff lines) - mapping only, 00:31 CET
Diff content: steps + movement distance per workout (type-dependent distance types, associated vs time-window sums, workout totalDistance vs measured pick, labels "Distancia a pie/bici/nieve/nado/recorrida"), and workout-linking order (verified Watch workout, existing Repera workout by session id, else new). Android counterparts exist: `SessionMovement.kt` (labels/types, tests) and `SessionHealthLink` (+tests). NOT compared line by line against this diff (pick rule `workoutDistance >= measured`, time-window fallback, HRZone source order); recorded as pending per consumer. No code change.
Detail checked 00:32: `SessionMovementMetrics.resolve` (domain) already documents itself as a mapping, NOT equivalence. Differences vs Apple's diff: Apple prefers `workout.totalDistance` when it is >= the best measured sample sum and picks the MAX across candidate distance types (mixed types: walking/bike/snow); Android takes associated-then-single-origin-window and labels mixed types "Distancia recorrida" without choosing a modality. Android has no HKWorkout.totalDistance counterpart in this function. Left unchanged; per-consumer status open.
