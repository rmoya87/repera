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
| 1 | `PlaceSearchSheet` (685) | Búsqueda de lugares para el pin de gym | Opciones sin coste nuevo investigadas: `android.location.Geocoder` (plataforma, sin key ni facturación; requiere backend de Play services, con límites de tasa y disponibilidad variable) y OSM/Nominatim (política de uso estricta: 1 req/s, no producción masiva). Google Places queda como opción de pago solo si las anteriores no bastan; decisión pendiente |
| ~~2~~ | `HealthWorkoutRouteMap` (en `CardioRouteComponents`) | IMPLEMENTADO 24/10 (deb6a2d): MapLibre+OpenFreeMap (opción A autorizada por main), port exacto de segments/speedColor/cámara, degradado Canvas, atribución habilitada, privacidad preservada (ruta no sale del dispositivo). Pendiente: verificación de píxeles en ejecución integrada | 5 tests unitarios del modelo (gradiente byte a byte, cámara, segmentos) |
| 3 | Emparejado Salud↔sesión: `SessionCardioEffort` (218), `ReperaSessionMatchIndex` (91), curva FC de sesión, `refineSessionReviewWithHealth` | Curva de FC por sesión, nota ajustada por esfuerzo cardio, índice temporal | Lectura de sesiones de ejercicio en Health Connect + matching temporal |
| ~~4~~ | `DayPlusSheet` (598) | CERRADO 24/10: hoja con alta one-off (a3edd12), borrador puro con persistencia SOLO en Guardar (8789bc7, sustituye al diseño con reconcile retirado por inseguro), caption de cuota (bce299e), temporizadores favoritos en hub (3b5df6f) | Prueba: fixtures instrumentados (ciclo de vida del borrador: vacía preexistente intacta, cancelar con contenido sin persistir, guardar explícito; store de timers roundtrip) + gates locales; pendiente ejecución integrada CI |
| 5 | `LoadSuggestion` (109) + `ExerciseLoadGuideCard` (207) | PARCIAL: dominio portado (4418f5d: parseo %1RM, Epley inverso, estimación desde última serie; 4 tests de dominio). SIGUE ABIERTA la tarjeta UI. BLOQUEO REAL detectado 24/10 23:15: la tarjeta depende de `cachedHistory`/`cachedLastWorkingSession` (resúmenes `ExerciseHistorySummary`/`ExerciseLastSession`), preferencias de carga y `weightIncrementKg` del store iOS — NINGUNO existe en Android. Requiere portar primero la infraestructura de agregación de historial por ejercicio; no es solo UI | 4 tests de dominio |
| 6 | `ExerciseSessionAppearance` (206) + `ExerciseThisSessionCard` (135) | PARCIAL (25/10 00:05): motor portado a mobile (`ExerciseSessionAppearances.kt`): appearance / wodTemplateAppearance / priorAppearances / summaryLabel, 7 tests unitarios verdes. `SetSummaryLine` (displaySummaryLine/prescriptionSummaryLine) en dominio con 5 tests. PENDIENTE: seed `WODTemplate`/CatalogWODs (hoy el nombre del benchmark = título de sesión, fallback idéntico a iOS) y la tarjeta UI `ThisSessionCard` en el detalle del ejercicio | 12 tests |
| 7 | `ExerciseEquipmentGroup` (133) | IMPLEMENTADA (24/10 ~23:20): clasificador portado 1:1 a dominio (`ExerciseEquipmentGroup.kt`, 5 tests de dominio verdes) y cableado en la biblioteca Android: selector Orden (Alfabético/Músculo/Material), por defecto alfabético como iOS, búsqueda siempre plana por relevancia, secciones con collator es_ES. Fila de ejercicio duplicada inline en ambas ramas para preservar estado por ítem (rememberSaveable por clave) | 5 tests de dominio |
| 8 | Selección táctil en gráficas cardio (de `CardioRouteComponents`) | Scrub con dedo sobre altitud/FC | Junto con #2 |

Verificado 24/10 22:52 contra fuentes Android (grep de cada pieza): #3 (SessionCardioEffort / ReperaSessionMatchIndex / curva FC / refineSessionReviewWithHealth), #6 (ExerciseSessionAppearance / ExerciseThisSessionCard), #7 (orden por equipo) y #8 (scrub táctil) NO tienen NINGUNA referencia en `android/` — siguen GAP confirmado. #1 PlaceSearch: opciones sin coste documentadas, decisión pendiente en main. #2 mapa nativo de ruta: investigación técnica en curso.

## FIDELIDAD (existe; presentación/UX distinta)

| Pieza iOS | Estado Android |
|-----------|----------------|
| `ActivityHeatmapView` | Rejilla + cuartiles ya existían; paleta y leyenda corregidas 24/10. Abiertos: segmented picker en una tarjeta, franja en rangos cortos, etiquetas mes/día |
| `RegisterSwipeRevealCard` (382) + `SwipeRevealMath` (17) | PARCIAL (25/10 00:00): `SwipeRevealMath` portado 1:1 a dominio (3 tests). Borrado de REGISTRO completo implementado: tombstone del espejo ANTES de borrar (paridad BusinessWorkoutSyncStore iOS), papelera en tarjeta de historial con confirmación («¿Eliminar registro?», igual que OGConfirmSheet) y test instrumentado con fixtures (tombstone persistido, doble borrado falla sin borrar de más). SIGUE ABIERTO el gesto swipe Compose (toda la tarjeta desliza, gesto solo fuera de la banda de chips) | 3 tests dominio + 1 instrumentado |
| `SessionPreviewView` | Hoja portada 24/10; contraste visual pendiente en CI |
| `WorkoutClockCoordinator`/reloj | Apaisado real validado en captura 2400×1080 (run 40124402423); no implica todos los modos/tamaños/interacción |

## CORREGIDO PENDIENTE DE PRUEBA INTEGRADA

| Pieza | Estado |
|-------|--------|
| Mapa muscular (draw) | CERRADO con evidencia: gate de píxeles VERDE en run 40127550912 (todos los API); capturas api35 inspeccionadas y aceptadas por main 22:23 (cuerpo coloreado en Esfuerzo y Fatiga; leyenda compartida confirmada correcta contra MuscleBalanceCard.swift) |
| Ubicación (pin + ruta) | Portada completa 24/10 (dominio+tracker+wiring+permisos+onboarding); pendiente CI con ubicación simulada |
| Descartar sesión | `endActiveSession(save:false)` portado 24/10; pendiente CI |

## Pendientes transversales (fuera del inventario por fichero)

- Monetización comercial/backend: Play Billing directo decidido; activación de
  producto/precio/prueba en Play Console y verificación de compras en backend
  siguen SIN autorización ni decisión. «Sustituido» no es paridad completa
  mientras estos gates sigan abiertos (HealthConnect igual: lectura base
  portada, emparejado con sesiones abierto como gap #3).
- Sync entre dispositivos: iCloud best-effort de iOS sin equivalente Android
  (requeriría backend; no autorizado).
- Sincronización de arte: lote @045fc5a9 (920b8b67 WGS f2 + 6239bd8a BBJ f3/captions) verificado COMPLETO por hash sha256 (489 raíz + 488 thumbs idénticos) y captions WGS/Inchworm idénticas en catalog_seed.json. ABIERTA al lote futuro del agente de arte (nuevos carruseles air squat/kettlebell swing…): re-verificar contra el main vigente al cierre; no declarar assets futuros como completos.
- API 36.1: en el run 40124402423 el emulador no completó el arranque con un
  crash nativo de surfaceflinger (hecho del run; causa no probada). Wear OS
  6.1: sin ejecución validada (timeouts de arranque en CI).
- Hardware físico: sin validación en dispositivo real (fuera de mi alcance).

## Catálogo de ejercicios: 288 iOS vs 196 Android (GAP de datos, RECONCILIADO)

Referencia Apple: `origin/main` e1621b8 (24/10). `CatalogQualityTests` (commit
2d879a4) exige `seed.count == 288`. Conteo exacto por familias (nombres
únicos): Enrichment 52 + Halterofilia 48 + Gimnasia 58 + CrossFit 46 +
Movilidad 82 + Hyrox 2 = **288**. Android `catalog_seed.json`: **196**, subconjunto
estricto (0 nombres extra; faltan exactamente **92**, casi toda la familia
Movilidad y variantes de haltero/gimnasia añadidas tras el port inicial
2c6bd9e). El «288 semillas» del análisis de arte coincide con este conteo.

Identidad: iOS genera `UUID()` aleatorio por instalación para semillas → la
identidad multiplataforma NO es el UUID; es nombre/`catalogId`. El seed
Android usa uuid5 propio (estable solo en Android). Reglas del re-sync:
referencia = origin/main e1621b8 o posterior; NO reasignar ids de las 196
entradas existentes (las referencian entrenos guardados); ids uuid5 nuevos
solo para las 92 entradas nuevas; añadir test instrumentado de conteo exacto
y campos obligatorios. Estado: ABIERTO (plan listo, extractor pendiente).

AVISO de frescura: las lecturas iOS previas de esta sesión usaban FETCH_HEAD
5099d9f y main avanzó a e1621b8. Re-verificación ya hecha: de los ficheros
portados en la sesión, SOLO `OnboardingFlowView` cambió (refinamiento visual
del paso de acceso: colores de marca del botón Google, busy por proveedor,
layout responsivo con ScrollView; estructura del flujo intacta) — queda como
ítem de fidelidad. El resto (LoadSuggestion, CardioRouteAnalysis,
ExerciseSubstitutes, SessionPreviewView, WorkoutLocationTracker,
OnboardingStore) está SIN CAMBIOS entre 5099d9f y e1621b8. El total 288 está
confirmado por `CatalogQualityTests` en main independientemente de HEADs
concretos de runs antiguos. Este inventario es base auditada PENDIENTE de
revalidación continua contra el main vigente, no cierre definitivo.

## Watch (5 ficheros): cubierto## Watch (5 ficheros): cubierto

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

> Nota catálogo (24/10): las 288 entradas de iOS NO eran 92 ausentes funcionales: 84 ya llegaban por MobilityCatalogMigration (82 Movilidad + 2 Hyrox, UUID v3 determinista); solo 8 eran genuinamente nuevas (halterofilia). El seed unificado preserva los 196 ids históricos (153 mismo nombre + 43 canonicalizadas vía SportExerciseNames) y comparte el esquema v3 con la migración. Extractor y verificación reproducible en android/tools/. CatalogRefreshMigration refresca campos y renombres en snapshots antiguos sin tocar historial (ids intactos).
