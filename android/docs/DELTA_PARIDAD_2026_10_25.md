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
