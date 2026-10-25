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
