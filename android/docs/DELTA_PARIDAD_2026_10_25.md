# Delta de paridad Android ↔ Apple (referencia fijada 25/10/2026)

Referencia Apple EXPLÍCITA: `origin/main` = **5890215d** (feat(iOS): nuevos
deportes y métricas nativas, PR #76). La referencia anterior de paridad era
`b8f45fa` (23/10) con sync de assets en `e579bbc`. Este documento clasifica el
trabajo para llevar Android de `b8f45fa` a `5890215d`. Apple no se modifica.

## Registro de movimientos posteriores de main

| Fecha | main Apple | Acción |
| --- | --- | --- |
| 25/10 | 5890215d | Referencia fijada; delta b8f45fa→5890215d inventariado aquí. |

(Para movimientos futuros: `git diff <ref>..origin/main -- Apps/ Packages/`
y añadir fila. La meta es la referencia fijada + filas acumuladas, no un
main móvil invisible.)

## Alcance del delta (evidencia: `git diff e579bbc..5890215d`, +5683/-390 en 27 archivos)

### D1 — Dominio: modelos en vivo + StatsEngine (IMPLEMENTADO; regresión 40218496197 en curso)
- Exercise `isCatalogArchived` (retirado consultable), accuracy horizontal/
  vertical en WorkoutRoutePoint, campos de sesión `liveSportID`,
  `liveRouteID`, `recordedDistanceMeters`, `activeDurationSeconds`,
  `liveKilometerSplitsSeconds`; `durationMinutes`/`displayDurationMinutes`
  priorizan `activeDurationSeconds` cuando hay `liveSportID`.
- Catálogo LiveSport: 36 deportes (id persistido, título ES, símbolo, grupo;
  8 grupos). IDs son datos persistidos: port literal.
- StatsEngine: set `cardioLiveSports` (29 ids), `isCardioWorkout`, día de
  inicio (no fin) para sesiones en vivo en rangos/series.
- Persistencia Android: JSON con defaults (equivalente a decodeIfPresent);
  sin migración.
- Tests: port JVM de LiveActivityModelTests (3) + LiveSportProgressTests (6).
- Dependencias: ninguna. Estimación: 1 sesión de trabajo.

### D2 — Catálogo remoto editorial (Supabase, SOLO LECTURA)
- Port de RemoteExerciseCatalogStore (351 líneas Swift): descarga incremental
  por cursor, copia local independiente, merge con catálogo local
  (isCatalogArchived/sportTag), fallback offline.
- Backend EXISTENTE (el que Apple ya usa); lectura autorizada. Reusar el
  acceso Supabase del espejo (WorkoutMirrorStore) si el transporte encaja.
- Tests: port de RemoteExerciseCatalogTests con HTTP simulado.
- Estimación: 1 sesión. Riesgo: verificar endpoint/RLS reales leyendo el
  código Apple; si la tabla exige algo no legible con la sesión actual,
  documentar y no tocar backend.

### D3 — Histórico deportivo en vivo (LiveSportHistoryView, 468 líneas Swift)
- Lista/detalle por actividad: distancia, tiempo activo, parciales km,
  desnivel, pulso/energía cuando Salud los aporta (LECTURA Health Connect;
  ritmo cardiaco sería permiso de lectura nuevo — lectura, no escritura).
- Depende de D1. Estimación: 1-2 sesiones con tests + capturas.

### D4 — Tracking GPS en vivo (LiveActivityView 3077 + WorkoutLocationTracker
  +367 + HealthKitStore +229): EL GRUESO
- Picker de deporte, métricas en directo (distancia, ritmo, desnivel con
  muestras válidas, parciales de 1 km), pausa/reanudar, restauración tras
  interrupción, guía hablada (TTS), importación GPX + parser + detección de
  giros, biblioteca de rutas (archivos locales, favoritos, últimas 5,
  miniaturas, edición con selector de deporte), limpieza de estado al
  descartar.
- Reuso Android existente: WorkoutLocationTracker.kt (rutas cardio),
  RouteMapModel/MapLibre (verificado con teselas reales), patrón FGS
  (WodTimerService), TTS estándar Android.
- Permisos: localización en primer plano ya usada; BACKGROUND location es
  permiso nuevo y sensible en Play (declaración justificada en revisión) —
  documentar, no activar distribución.
- Estimación: 3-5 sesiones. Es el bloque que desborda "hoy".

### D5 — Equivalente a Live Activity (pantalla de bloqueo)
- Apple: WorkoutLiveActivityCoordinator + TrainingLiveActivityWidget
  (Dynamic Island / lock screen). Android: notificación ongoing con métricas
  en vivo (Live Updates de Android 16 o custom views), alimentada por el FGS
  de D4. Depende de D4. Estimación: 0,5-1 sesión.

### D6 — Integración UI: pestaña "Comenzar"
- RootTabView: nueva pestaña Comenzar (livephoto.play) con LiveActivityView;
  CenterView pasa a hoja; deeplinks repera://live y repera://workout;
  hooks en HomeView (+39) e HistoryView (+73) para sesiones en vivo.
- Depende de D4. Estimación: 0,5-1 sesión.

### D7 — Alineaciones menores
- SettingsView -153 (Apple retiró el botón de resync manual completo):
  revisar equivalente Android y alinear.
- CardioRouteComponents +47, LibraryView +22, ExerciseCatalogSearchList +5,
  ReperaApp +136 (wiring), ReperaStore +180 (arranque/estado).
- Estimación: 0,5 sesión.

### Watch/Wear
- Sin cambios en la app de Watch dentro del delta (solo
  Shared/TrainingActivityAttributes para Live Activities de iOS). Wear OS
  queda fuera del delta salvo lectura futura de sesiones en vivo.

## Estimación global fundamentada
- D1+D2: hoy (sesiones de dominio y red simulada, sin UI pesada).
- D3-D6: mañana en adelante; D4 domina por superficie (UI + FGS + GPX + TTS).
- Total realista: 2-3 días de trabajo a ritmo demostrado, con verificación
  por pieza. Bloqueos reales: permiso background-location (documentación
  Play, distribución), E2E GPS/Salud con datos reales y hardware (limitado),
  sin bloqueo de autorización para D1-D3 (lecturas existentes).

## Fuera de alcance
- Producción, tracks cerrados/abiertos, productos/precios (plan beta en
  segundo plano, sin ampliar distribución). Apple intocable. Sin merge a main.

## Avance verificado 25/10, 19:06 CET
- D1: implementación + tests locales cerrados. D2: se reutiliza el worker
  existente (cursor incremental, tombstones, caché atómica, gate de sesión);
  cerrada derivación de muscleGroup con taxonomía de Apple. Regresión en
  https://github.com/rmoya87/repera/actions/runs/40218496197 (SHA 212dcbe3).
- D3: capa de datos + catálogo Deportes + historial + detalle de sesión y
  parciales activos implementados LOCALMENTE; no se declara cierre visual.
  Adaptador usa archivo completo, no las últimas 20 tarjetas. Pendientes:
  favoritos/rutas y evolución (almacén compartido D4), UI tests ejecutados y
  capturas inspeccionadas. El valor de gráfica duración es en minutos, como
  chartAttempts de Apple; métricas solo con fecha y duración/distancia válidas.
- LiveSport propiedades: GPS 19, velocidad 15, desnivel 6.
- Local: domain 264/0, mobile JVM 185/0; UI tests compilan pero aún no se
  ejecutaron. No confundir con SHA CI ni con paridad D3 completa.
- Beta sigue en draft 51500. No desplegar automáticamente un delta parcial.

- D4 arranque de dominio: parser GPX offline (trkpt/rtept + namespaces,
  timestamps opcionales, coordenadas válidas, tope 20.000) y detección de
  giros portada (ventana 30m, mínimo 20m, ángulo 52°, deduplicación 55m,
  muestreo hasta ~1200 vértices). 5 tests nuevos verdes. DTD/entidades
  externas rechazadas. No hay aún recorder/FGS/UI ni persistencia de rutas.

- D4 almacén offline de rutas: archivo atómico por cuenta, favoritos/edición
  con UUID estable, orden reciente por actividad, recuperación sin duplicados
  ni favoritos inventados y tombstones persistentes. 4 tests JVM verdes,
  incluido fallo de escritura con memoria/disco sin cambios. Aún sin wiring UI.

## Regresión y defecto visual, 19:15 CET
- Run 40218496197 SUCCESS a 212dcbe3: teléfono 30/35/37.2 = 212/0 cada
  uno, Wear 35/36 = 6/0 cada uno, dominio 254/0, sin omitidos. Deploy skipped.
- Píxeles: API30 lugar_hoja_confirmar muestra mapa + IME SIN cabecera/check;
  API35 sí cabecera. El detector no-vacío era insuficiente. No cierre visual.
  Hipótesis aislada: superficie GL/IME superpuesta. Prueba enfocada
  https://github.com/rmoya87/repera/actions/runs/40220246818 (dfb463ba):
  TextureView y ocultar teclado al elegir, exigir píxeles de barra superior.
  Se conservan gestos y before completo, artifact after pendiente.
- D1/D4: añadidas precisiones horizontal/vertical con defaults y round-trip
  en modelo, snapshot/historial, almacén de rutas y tracker clásico.
  Local: dominio 269/0 + mobile JVM 189/0. Cambios aún no en SHA verde CI.

- D4 recorder puro (LiveActivityState) implementado: fases idle/recording/
  paused/review, reloj activo, snapshot/restauración siempre en pausa, ID de
  sesión para descartar callbacks antiguos, odómetro filtrado sin sumar dos
  veces, parciales interpolados incluso varios cruces, elevación validada con
  umbral 3m y precisión ≤15m, limpieza al descartar. 6 tests nuevos verdes;
  dominio 275/0. Falta integración proveedor GPS/FGS/persistencia/audio/UI;
  estos tests NO prueban segundo plano ni hardware.

## Checkpoint 19:24 CET
- Enfocado 40220246818 FALLA la nueva aserción de chrome (1/1 fallido):
  no confirma arreglo. No se guardó AFTER porque la aserción iba antes del
  save. Run diagnóstico 40221024872 conserva AFTER aun con fallo y registra
  bounds root/window; misma hipótesis, evidencia adicional, no suite global.
- D4 validador GPS puro LiveGPSOdometer portado de accept de Apple: dueño
  exclusivo por sesión, precisión ≤35m, futuro ≤10s, muestras de segmento
  desde -3s, jitter 3..7m según precisión, huecos >30s/saltos sin sumar,
  límite de velocidad del deporte, reinicio de segmento tras pausa y
  precisión vertical original. 4 tests nuevos verdes, dominio 279/0.

- D4 snapshot privado en archivo atómico: round-trip reloj/pausa/ruta/
  precisiones/splits/UUID, conserva checkpoint ante fallo de escritura y
  conserva archivo corrupto sin borrado silencioso. 3 tests JVM nuevos
  verdes. Local domain 279/0, mobile 192/0. No wiring FGS todavía.

## Checkpoint Android runtime, 19:38 CET
### Terminado a nivel de dominio/JVM (no validación global)
- Recorder, odómetro, GPX/giros, rutas y checkpoint atómicos con tests locales.
### En curso
- LiveLocationSource conecta LocationManager al odómetro; runtime compartido
  por cuenta conecta recorder/checkpoint/proveedor. Servicio foreground privado
  y notificación ongoing con pausa/reanudar/finalizar implementados y compilan.
  NO se han ejecutado aún servicio, permisos ni GPS en instrumento; falta UI.
- Nuevo permiso FOREGROUND_SERVICE_LOCATION, sin ACCESS_BACKGROUND_LOCATION.
  La ruta prevista es iniciar FGS location desde UI visible con permiso de
  ubicación concedido. No se afirma validación de continuidad en background
  ni aprobación Play; debe probarse y documentarse antes de distribución.
- Cabecera API30: diagnóstico boundsRoot positivo pero boundsWindow negativo
  prueba desplazamiento de la ventana. TextureView solo no resolvió. Nuevo
  run 40221857337 prueba adjust-noting/imePadding/token del propio Dialog.
### Pendiente
- UI/comienzo/guardado/favoritos/evolución/audio y pruebas instrumentadas/
  capturas. D5 notificación es parcial hasta ejecución y métricas completas.

- D4/D6 primer wiring UI: pestaña Comenzar sustituye Crear/Center (herramientas
  accesibles por botones), picker de deportes, permiso ubicación, reloj,
  pausa/reanudar/finalizar/revisión/guardar/descarte confirmado conectados al
  runtime. Guardado local UUID-idempotente sin ejercicios/Salud ficticios;
  signout detiene runtime/FGS. UI y nuevo test de guardado COMPILAN, aún no
  ejecutados: no se declara finalización de D4/D6 ni fidelidad visual.
  Restan audio/rutas-favoritos-evolución/import UI/deeplinks y ejecución.

## D3 wiring de rutas, 19:46 CET
- Favoritos enlazados desde historial, guardado de ruta registrada y UUID en
  sesión, pantalla evolución con mapa/intentos completos/best time y métricas
  minutos/ritmo/velocidad/km. No agrupa intentos por día. Reutiliza almacén D4.
- Test UI nuevo: salida incompleta no rebaja mejor tiempo ni entra en gráfica;
  métricas alternables y captura. COMPILA, aún no ejecutado ni inspeccionado.
- Diferencias pendientes conocidas: acción accesible Guardar ruta en botón
  (swipe Apple no portado), interpolación de gráfica lineal (Apple catmullRom),
  detalle de sesión actual no tiene toda la edición del detalle antiguo.
  No cierre D3 todavía. Necesita validar fixtures/capturas y completar wiring.

- D4 importación GPX desde selector de documentos (16MB máximo, sin red),
  biblioteca con miniaturas MapLibre, elegir ruta/favorito/editar título y
  deporte implementada y COMPILA. No ejecutada en UI todavía; faltan borrar
  con confirmación, últimas5 basadas en actividad (actual usa creación),
  recuperación desde sesiones y guía hablada/giros. No cierre de biblioteca.
- API30 40221857337: AFTER completo muestra cabecera/check/buscador/mapa/panel
  sin IME y boundsWindow positivos. Aceptado por main. Test rojo por franja
  demasiado baja, corregida contra before/after (no se relajan umbrales).
  Cadena completa pendiente run 40222615922.

## Checkpoint 19:56 CET
- Cabecera + cadena gestos API30 run40222615922 SUCCESS 1/0. AFTER completo
  inspeccionado: cabecera/check/buscador/mapa/panel, sin IME, bounds positivos.
  No sustituye regresión global. Before/after preservados en artifacts debug.
- D4 guía de ruta pura port updateUpcomingTurn (55m fuera,250m aviso,70m a
  pie/120m bici, una locución por giro). 2 tests nuevos; domain281/0.
- TTS Android y audio-focus transitorio exclusivo (pausa, no duck), opt-out
  persistido, mensajes km/giro y parada al pausar/finalizar/descarte/cuenta
  implementados y compilan. NO ejecución/audio real validados. Faltan fallback
  de aviso cuando voz falla/está off, voz instalada de mejor calidad y tests.
- Pruebas instrumentadas D3/historial/evolución/guardado sintético lanzadas en
  rama debug separada sobre 6d003b02 (NO incluyen aún guía/TTS posterior).

## Validación D3 20:08 CET
- 40223448697 SUCCESS XML4/0 solo LiveSportHistoryInstrumentedTest (runner no
  ejecutó la segunda clase de la lista). Catálogo/historial legibles en
  capturas. Evolución: resumen/gráfica legibles, mapa no evaluable por captura
  Compose (SurfaceView). No se da guardado por probado ni mapa por vacío real.
- Nueva clase explícita única LiveActivitySaveInstrumentedTest ejecuta guardado
  UUID-idempotente y captura de ventana real tras estilo +8s con ruta sintética.
  Run nuevo debug sobre ecdd57f8, sin regresión global ni cambios beta.

- D4 UI recientes5 ordenadas por última actividad real, filtro favoritas/todas
  y borrado confirmado que conserva sesiones y retira selección actual. Compila.
- D4 voz: preferir voz es-ES instalada offline de mayor calidad, fallback a
  notificación con permiso en background cuando voz apagada/falla; solicitud
  POST_NOTIFICATIONS al desactivar voz. Compila, sin validación audio/FGS aún.

- D6 deeplinks repera://live→Comenzar y repera://workout→Inicio añadidos,
  notificación abre Comenzar. workout aún NO presenta sesión activa concreta
  (diferencia explícita). Solo compila, no validación de intents aún.
- Biblioteca recupera rutas de sesiones completas por UUID al abrir, sin
  favoritos inventados y respetando tombstones. Compila, store ya probado.

- D4 métricas UI ritmo/velocidad por deporte, elevación medida y parcial en
  curso añadidas. Mapa actualiza polilínea al recibir puntos (antes era solo
  creación inicial). Compila, pendiente ejecución y perf con ruta larga.

- Test instrumentado añadido de runtime interior sintético: inicio/pausa,
  cambio de cuenta, restauración pausada con mismo UUID/reloj, revisión y
  descarte. No usa servicio ni sensores, compila pero espera ejecución.

## Validación guardado/mapa 20:22 CET
- 40224535920 SUCCESS XML2/0 sin omitidos: guardado En vivo UUID-idempotente
  probado en disco real aislado, duración activa y sin Salud/ejercicios falsos.
- Captura ventana real mapa evolución inspeccionada: teselas, ruta, extremos
  y atribución visibles. Tema del fixture era Material genérico (violeta), NO
  evidencia de fidelidad Repera. Fixture corregido a primary=brandGreen.
- Próxima ejecución incluye ciclo runtime interior aislado/restauración sin
  sensores (3 pruebas en clase). FGS/permisos/background siguen sin validar.

- D4/D6 selector de deporte pasa a Dialog como Apple, no lista de 36 antes
  del botón iniciar. Si existe entreno clásico activo, Comenzar ofrece
  Continuar y no inicia segundo GPS. Destino Continuar sigue siendo Inicio,
  no detalle concreto: pendiente alinear navegación.
- D7 Settings: no existe botón Android de resync completo en Ajustes actual;
  no procede retirar algo inexistente. Resto de Settings no se declara a
  paridad por este gap-check puntual.

## Checkpoint 20:29 CET (HEAD local, aún no regresión global)
### Terminado local/JVM
- Dominio 282/0 y mobile JVM 192/0 sin omitidos. Nuevo test prueba que
  restaurar desnivel conserva filtro de precisión vertical del directo.
- Guardado de ruta nueva archiva con identidad derivada de UUID de sesión;
  reintento no duplica. Prueba instrumentada añadida, aún por ejecutar.
### En curso
- Comenzar con selector compacto; guard de entreno clásico también tras
  permiso; edición legacy disponible en detalle deportivo; Center en hoja.
- Gráfica Catmull-Rom, mapa con colección/capa única en vez de una por
  segmento y cámara con mínimo span. Compila, pendiente nueva imagen real.
- Revisión consulta Salud únicamente con permisos existentes y asociación
  inequívoca; enseña solo pulso/kcal medidos. Sin E2E Health real autorizado.
- Notificación incluye ritmo/velocidad media; voz exige es-ES instalada
  offline (sin fallback inadvertido de red). Audio real sigue sin ejecutar.
- Añadida clase enfocada LiveActivityControlsInstrumentedTest, 3 pruebas:
  guard clásico, picker Pádel y FGS interior con acciones reales de
  notificación sobre sesión sintética en emulador vacío. Solo compilada.
### Pendiente
- Enfocado de controles y archivo de ruta; nueva captura tras cambio mapa.
- Comenzar aún no replica canvas inicial GPS + controles flotantes de Apple,
  falta mapa/métricas alternables y navegación de sesión concreta.
- Guard inverso (impedir inicio clásico si hay En vivo activo), símbolos,
  swipe guardar ruta y otras alineaciones menores D7 por auditar.
- Servicio con GPS/background, permisos denegados, ciclo vida, audio real;
  después regresión global del bloque coherente. Beta draft 51500 intacta.

## Tema compartido y auditoría D7, 20:35 CET
- Tema real anterior solo fijaba primary: superficies/chips seguían violeta
  Material. ReperaColorScheme extrae bg/surface/label adaptativos de Apple
  Theme.swift 5890215d; conserva verde oscuro legible en claro. Cambia TODA
  la app Android, no solo Comenzar. Requiere capturas de pantallas afectadas
  en claro y oscuro antes de cerrar visual; no basta evolución de rutas.
- VisualVerificationInstrumentedTest ahora usa el esquema real compartido;
  argumento reperaDark=true habilita pasada oscura. Solo compilado.
- D7 auditoría HistoryView detectó otro cambio: no unir pérdida de GPS/pausa,
  velocidad geométrica si no hay instantánea válida, gates30s/25m/s. Portado
  al modelo de trazo, con prueba nueva (mobile193/0). Ruta planificada GPX
  conserva trazo azul completo, distinto de una actividad medida.
- Inicio ya muestra deporte, reloj activo y distancia registrados, y texto
  Ver actividad en lugar de Ver ejercicios para sesiones Live. Compilado.
- Parciales activos muestran km/h en deportes displaysSpeed y min/km en
  resto. Falta FC por parcial cuando existe señal medida, y meteo/viento
  equivalente de D7 no existe aún en Android. No declarar D7 terminado.

## Comenzar canvas, 20:38 CET (solo local/compilado)
- GPS en idle pasa a mapa con header/controles superpuestos, sin inventar
  ubicación; centrar pide permiso y captura puntual con timeout. Sin fix,
  texto explícito de que mapa no representa tu ubicación. Nunca usa un
  centro Madrid como ubicación del usuario. Plan GPX azul y trazo registrado
  separados. MapLibre TextureView para controles superpuestos verificables.
- Iniciar muestra métricas y deja alternar Ver mapa/Ver métricas; interiores
  conservan métricas sin mapa. Símbolos Material para 36 deportes en picker
  y catálogo. Controles en FlowRow para anchuras pequeñas.
- Captura puntual retira listener al cancelar/timeout y rechaza fix de más
  de15s. Solo compilado; no se afirma continuidad GPS física.
- Test nuevo canvas idle/activo/métricas usando puntos sintéticos directos,
  sin sensores ni FGS. Pendiente enfocado posterior al actual40226505506.

## Cierre de enfocado40226505506, 20:41 CET
- SUCCESS, SHAdebug6c583804: controles4/0 (incluye FGS interior y acciones
  reales de notificación), save4/0 (incluye archivo de ruta idempotente).
  XML separados, cero omitidos. GPS/Health/audio físicos NO probados.
- Capturas evolución/Pádel legibles. Picker se capturó antes del frame y
  guard clásico blanco: descartadas como evidencia visual, no como test
  funcional. Espera de frame añadida. outlineVariant lavanda corregido.
- Nuevo enfocado40227284906 SHAdebugc40323c1: controles5/save4/tema2,
  en curso.12 capturas de6 pantallas reales claro/oscuro previstas.
- Local posterior: checkpoint valida valores y conserva corruptos; runtime
  bloquea sobrescritura hasta descarte explícito. Prueba instrumentada nueva
  compilada, no incluida en run en curso. Mobile JVM195/0.
- FC por parcial conecta proveedor medido existente; conserva segundos
  activos y usa km/h según deporte. Curva del detalle reutilizada. Nueva
  prueba sintética compilada, sin leer Salud real.

## Checkpoint 21:07 CET (local, todavía sin cierre)
- Enfocado40227284906 verde a c40323c1: controles5/0, save4/0, tema2/0,
  sin omitidos. Inspeccionadas12 capturas claro/oscuro de6 pantallas. Canvas
  activo NO aceptado: teselas pendientes en captura; atribución idle oculta.
- c8cb5efc sincroniza onStart/onResume de MapView montado con owner ya
  reanudado, mueve atribución por encima de controles y espera callback de
  mapa completamente renderizado en test. En ejecución40229021477,
  debug1c4edd6c. No sustituye prueba de píxeles ni suite global.
- Local siguiente: swipe trailing revela Guardar ruta (tap explícito antes
  de escribir, acción accesible); guardar revisión transmite fecha de inicio
  a calendario Inicio. Tests compilan, ejecución pendiente. Más vistas de
  tema preparadas: Diario, Ajustes, catálogo Deportes y Crear claro/oscuro.
- Meteo/viento sigue sin equivalente: Apple usa WeatherKit autenticado;
  Android no tiene transporte/backend existente. No se añaden proveedores
  ni se transmiten coordenadas privadas a servicios nuevos silenciosamente.

## D6 navegación, 21:10 CET local
- Verificación exacta Apple5890215d: repera://workout NO resuelve un UUID;
  abre flujo de sesión activa si existe o Inicio sin sesión. Android ahora
  abre ruta dedicada de sesión activa (fuerza/WOD y lugar), en vez de dejar
  la tarjeta por debajo del calendario. Nuevo componente reutiliza callbacks
  ya existentes. Pendiente ejecución/capturas claro/oscuro.
- Cobertura tema preparada11 pantallas×2, con aserción del focusDay de Inicio.
- Preparada prueba proveedor Android simulado: dos fixes con distancia,
  pausa sin callbacks y reanudación sin unir salto. No GPS/hardware real.

## Canvas navegación, 21:16 CET local
- Comparación directa Apple5890215d detectó además modo navegador/2D y
  seguimiento del punto actual. Preparado toggle, cámara centrada en última
  muestra real, rumbo desde geometría medida y lookahead35m, pitch60° máximo
  MapLibre (Apple67°). Gesto manual suspende seguimiento hasta centrar.
- GPX planificado sigue debajo de traza, no se sustituye por traza al iniciar.
- Tests JVM cámara2/0. Compilación instrumentada verde. Captura navegador
  preparada, aún NO ejecutada. No afirmar relieve3D Apple: proveedor vectorial
  Android actual no aporta terreno/elevación3D. Es diferencia abierta.
- Run40229854247 a debug a1e9d4f8 ejecuta bloque ANTERIOR al modo navegador;
  no confundir con HEAD posterior local. Sin beta nueva.

## Evidencia canvas confirmada21:14 CET
- https://github.com/rmoya87/repera/actions/runs/40229021477 SUCCESS,
  debug1c4edd6c: controles5/0 y save5/0, sin omitidos. Capturas completas
  inspeccionadas: idle con mundo y labels, activo con calles/edificios y
  métricas con mapa. Atribución e info ahora visibles sin panel superpuesto.
- Diferencia respecto a captura anterior: MapView recibe onStart/onResume
  al montarse con owner ya RESUMED y prueba espera render completo, no solo
  estilo. Función y píxeles separados: esta evidencia es API30/sintética.
- Siguiente enfocado40229854247 en ejecución a debug a1e9d4f8, bloque de
  favoritos/fecha/GPX/tema/proveedor. No contiene cambios65bfedff de cámara
  navegador/voz/descarte en mapa. Local domain282/0, mobile199/0.

## Bloque21:26 CET, sin cierre GPS
- Run40229854247 FAILURE a debug a1e9d4f8. Clases controles6/0, save5/0,
  historial6/0, tema2/0; proveedor simulado1/1 fallido (cero primer callback).
  Cero omitidos. Capturas22 claro/oscuro de11 pantallas inspeccionadas,
  legibles/sin violeta en viewports mostrados; NO todos los estados de app.
- Swipe revela acción, no escribe hasta tap (prueba6 historial). GPX azul
  permanece debajo de traza sobre teselas. Save devuelve día de inicio y
  calendario aplica foco (controles6 y tema2). No inferir GPS validado.
- Hipótesis proveedor: prueba solicitaba ubicación foreground SIN Activity
  ni FGS.178cb079 añade Activity visible + grantRuntimePermission; conserva
  callbacks/distance/pausa/reanudación como aserciones. Pendiente ejecución.
- Enfocado nuevo debug7a8d5e60 solo controles/proveedor; además ejecuta modo
  navegador/2D/seguimiento desde posición medida, voz/descarte del mapa.
  Diferencia abierta: no relieve3D de Apple, pitch MapLibre60° vs Apple67°.
- No beta/merge/main/Apple cambios. Domain282/0, mobile199/0 locales.

## Restricción coste21:34 CET
Usuario pide solución sin costes, también meteo. No activar facturación ni
servicios nuevos. Google Weather queda candidato no autorizado, no elegido.
Mapa Android actual: MapLibre13.7.1 + OpenFreeMap Liberty (RouteMapView y
PlaceSearchSheet); no Google Maps. Fuente actual https://openfreemap.org/ :
instancia pública gratuita, uso comercial/apps permitido, sin límites de
vistas/requests ni key. Obligación de atribución. https://openfreemap.org/tos/
(14-10-2026): as-is, sin garantía disponibilidad ni permanencia; offline hasta
3000 teselas/50MB,4 peticiones paralelas, User-Agent propio por descarga.
No se implementó descarga offline. No confundir ausencia de coste actual con
SLA gratis o garantía eterna. OpenFreeMap no da elevación ni cálculo rutas:
https://github.com/hyperknot/openfreemap . Relieve3D aún no portado.
