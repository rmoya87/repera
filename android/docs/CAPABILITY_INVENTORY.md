# Inventario consolidado de capacidades iOS → Android (24/10 21:40)

Método: barrido de TODOS los fuentes Swift de main — `Apps/Repera/Sources`
(99 ficheros), `Apps/ReperaWatch/Sources` (5) y `Packages/ReperaDomain/Sources`
(50) — contrastando cada pieza por concepto contra `android/`, verificando uso
real en iOS (call sites) antes de declarar gap. Complementa y corrige las
auditorías del 23/10 (que no incluían DayPlusSheet, preview, sustitutos,
heatmap, ruta cardio ni match index).

Estados: PORTADO / PARCIAL / FIDELIDAD (existe con presentación distinta) /
GAP (ausente y usado en iOS) / SIN USO en iOS (código sin call sites, no es
gap) / SUSTITUIDO (infra Apple-only con equivalente Android ya elegido).

## GAPS ABIERTOS (capacidad; lista finita a 24/10)

| # | Pieza iOS | Qué falta en Android | Dependencia |
|---|-----------|----------------------|-------------|
| 1 | `PlaceSearchSheet` (685) | Búsqueda de lugares para el pin de gym | Decisión de proveedor: Google Places = API key + facturación → ELEVAR a decisión de cuenta antes de tocar nada |
| 2 | `HealthWorkoutRouteMap` (en `CardioRouteComponents`) | Mapa nativo de la ruta en el detalle del historial | Elección de componente de mapa (investigación técnica autorizada, sin coste) |
| 3 | Emparejado Salud↔sesión: `SessionCardioEffort` (218), `ReperaSessionMatchIndex` (91), curva FC de sesión, `refineSessionReviewWithHealth` | Curva de FC por sesión, nota ajustada por esfuerzo cardio, índice temporal | Lectura de sesiones de ejercicio en Health Connect + matching temporal |
| 4 | `DayPlusSheet` (598) | Menú «＋» de un día: alta de entreno suelto con fecha (`DayEditorView` one-off), favoritos, temporizador y escaneo para ese día | Ninguna externa; el modelo ya soporta `scheduledDate` |
| 5 | `LoadSuggestion` (109) + `ExerciseLoadGuideCard` (207) | Guía/sugerencia de carga en el detalle del ejercicio | Ninguna |
| 6 | `ExerciseSessionAppearance` (206) + `ExerciseThisSessionCard` (135) | Tarjeta «cómo apareció este ejercicio en sesiones concretas» (comparativas) | Ninguna |
| 7 | `ExerciseEquipmentGroup` (133) | Ordenación de biblioteca por grupo de material (presentación) | Ninguna |
| 8 | Selección táctil en gráficas cardio (de `CardioRouteComponents`) | Scrub con dedo sobre altitud/FC | Junto con #2 |

## FIDELIDAD (existe; presentación/UX distinta)

| Pieza iOS | Estado Android |
|-----------|----------------|
| `ActivityHeatmapView` | Rejilla + cuartiles ya existían; paleta y leyenda corregidas 24/10. Abiertos: segmented picker en una tarjeta, franja en rangos cortos, etiquetas mes/día |
| `RegisterSwipeRevealCard` + `SwipeRevealMath` | Acciones accesibles por botón; falta el gesto swipe |
| `SessionPreviewView` | Hoja portada 24/10; contraste visual pendiente en CI |
| `WorkoutClockCoordinator`/reloj | Apaisado real validado en captura 2400×1080 (run 40124402423); no implica todos los modos/tamaños/interacción |

## CORREGIDO PENDIENTE DE PRUEBA INTEGRADA

| Pieza | Estado |
|-------|--------|
| Mapa muscular (draw) | Causa raíz en logcat (`draw size=487×0`): `weight(1f)` en Row no fija altura; `fillMaxHeight()` aplicado. Pendiente: gate de píxeles en el run sobre 1320b1b |
| Ubicación (pin + ruta) | Portada completa 24/10 (dominio+tracker+wiring+permisos+onboarding); pendiente CI con ubicación simulada |
| Descartar sesión | `endActiveSession(save:false)` portado 24/10; pendiente CI |

## Watch (5 ficheros): cubierto

`ReperaWatchApp` → `WearMainActivity`; `WatchSessionHub`/`WatchSessionView` →
`WearHomeContent` + pantallas de sesión; `WatchConnectivityClient` → bridge
MessageClient; `WatchHealthKitSession` → `WearHealthSession` (Health Services).
Tests wear verdes en CI (6/6 en API 30/35/37.2 y Wear OS 5.1 en 40124402423).

## SIN USO en iOS (no son gaps)

`SubstitutePickerSheet` (dominio portado por simetría), `DebugEntitlementProvider`
(solo debug iOS).

## SUSTITUIDOS (infra Apple-only; equivalente Android ya existente)

`WatchConnectivityClient`/`PhoneConnectivity` → bridge Wear (MessageClient);
`AppleAuthStore` → Supabase Auth/Google; `StoreKitEntitlementProvider`/
`RevenueCatEntitlementProvider` → Play Billing directo (decisión del usuario
20/10); `HealthKitStore`/`HealthDiskCache` → `HealthConnectReader`;
`ReperaApp`/`RootTabView` → `MainActivity`/`ReperaMobileScreen`;
`Catalog`/`CatalogSeedBuilder`/`CatalogSpanish`/`CatalogCrossFit`/
`CatalogGimnasia`/`CatalogHalterofilia`/`CatalogMovilidad`/`CatalogEnrichment`
(datos) → `catalog_seed.json` (196 ejercicios); logs de depuración
(`BoardScanLog`, `LibrarySearchLog`, `ProgressLog`, `LaunchTiming`) → sin
equivalente necesario; `DerivedStatsCache` → caché de stats (rendimiento
interno; Android calcula al vuelo — ítem de rendimiento, no de capacidad);
`AuthSessionLaunchPolicy`/`AuthSessionTrace`/`WallClockTimer` → utilidades
internas cubiertas por el arranque Android.

## Verificación por niveles (qué prueba qué)

- Implementación: código portado en la rama (compila, gates locales verdes).
- Pruebas locales: `:domain:testDebugUnitTest` + `:mobile:testDebugUnitTest`.
- Ejecución integrada: `:mobile:connectedDebugAndroidTest` en CI sobre
  API 30/35/37.2 (36.1: el run 40124402423 no completó el arranque del
  emulador — crash nativo de surfaceflinger; hecho del run, causa no probada).
- Píxeles: capturas `ReperaVerification` con gate de píxeles reales (el gate
  del mapa demostró detectar un Canvas vacío; reloj apaisado validado por
  inspección de la captura 2400×1080).
