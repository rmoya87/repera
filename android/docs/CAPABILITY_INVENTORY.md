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
| 1 | `PlaceSearchSheet` (685) | Búsqueda de lugares para el pin de gym | DECIDIDO 25/10 (sin cuenta/coste/condiciones nuevas): proveedor `android.location.Geocoder` (plataforma; GeocoderPlaceSearchProvider con API 33+ listener y fallback legacy, sesgo por bounds como setRegion iOS, máx 5). NO es autocompletado por tecla: política de dominio PlaceSearchPolicy (mín 3 caracteres, pausa 800 ms) — diferencia de fidelidad por restricción de plataforma, documentada. Nominatim público descartado (su política no admite asumir autocompletado en producción); Google Places descartado (facturación; solo si el usuario lo pide). CAPACIDAD AUSENTE (25/10, no solo fidelidad): la búsqueda de establecimientos/POI por nombre comercial («gym Box X») que MKLocalSearch sí resuelve NO existe en Android con Geocoder, que es geocodificación de direcciones/descripciones de lugar (developer.android.com/reference/android/location/Geocoder). Pin manual y direcciones NO cierran la búsqueda comercial de Apple. NECESIDAD NO RESUELTA — opciones con política verificada 25/10: (a) Photon público (photon.komoot.io): POI search-as-you-type sobre OSM, sin cuenta/clave, «uso razonable» con throttling/ban si se excede y SIN garantía de disponibilidad (README oficial komoot/photon); apto para consultas iniciadas por el usuario, no como SLA de producción. (b) Overpass API público: POI por nombre/etiqueta OSM alrededor de bbox, sin clave; instancias públicas para proyectos pequeños, no para autocompletado en producción (wiki OSM). (c) Google Places: paridad POI real pero requiere cuenta de facturación — descartado salvo petición del usuario. (d) Self-host Photon/Nominatim: coste/operación de infraestructura. Decisión de cierre aplazada: no requerida para la hoja (el seam PlaceSearchProvider admite proveedor adicional sin cambiar UI). PORTADO en dominio: RecentPlaces (dedupe id/coords ~11 m, límite 5, reciente primero; 6 tests) + PlaceSearchPolicy (2 tests); RecentPlacesStore con la misma clave que iOS. Hoja UI COMPLETA implementada (PlaceSearchSheet.kt): PlaceSearchSheet (browse map MapLibre/OpenFreeMap, panel de resultados/recientes, mapa de confirmación con panel inferior, papelera quitar + check guardar, debounce PlaceSearchPolicy, RecentPlacesStore por cuenta) y WorkoutPlacePickerRow (icono + nombre o «Añadir lugar» + preview 160 dp no interactivo). PENDIENTE: cablear la fila en las pantallas de detalle de sesión / entreno activo / plan (equivalentes HistoryView/WorkoutView/PlanView) y la verificación integrada (emulador/CI). Sin búsquedas con ubicación real |
| ~~2~~ | `HealthWorkoutRouteMap` (en `CardioRouteComponents`) | IMPLEMENTADO 24/10 (deb6a2d): MapLibre+OpenFreeMap (opción A autorizada por main), port exacto de segments/speedColor/cámara, degradado Canvas, atribución habilitada, privacidad preservada (ruta no sale del dispositivo). Pendiente: verificación de píxeles en ejecución integrada | 4 tests del modelo en mobile (RouteMapModelTest) + 5 de análisis en dominio (CardioRouteAnalysisTest) |
| 3 | `SessionCardioEffort` (218) + `ReperaStore.refineSessionReviewWithHealth` | IMPLEMENTADA (25/10 00:39): motor en dominio 1:1 (bandas, HRmáx estimado, zona vigorosa ≥77%, densidad kcal, scoreDelta −2…+2, apply con titular/resumen/tips) con 5 tests portados de iOS; cableado: al terminar (teléfono y reloj) se lee FC/kcal de Health Connect en la ventana de la sesión y se afina la nota persistida; la hoja visible se actualiza si sigue abierta. Sin señal o sin permisos no toca nada. Curva de pulso pintada con scrub (ver fila 8). Matching Salud↔sesión portado de overlappingWorkout iOS (SessionHealthMatcher): umbrales LITERALES Apple (ventana ±45 min, solape ≥70% de la sesión y ≥60% del candidato, regla del 85% entre fuentes, externas preferidas). FC: fusión de todos los orígenes (parte equivalente a HealthKit) con dedup de duplicados exactos y detección de señal contradictoria — los umbrales concretos ±2 s / buckets 30 s / >15 lpm / ≥30% son POLÍTICA NUEVA ANDROID sin fuente Apple (HealthKit no los expone). POLÍTICA ANDROID más estricta que iOS: refinado y curva SOLO con asociación confiable (Matched); None o Ambiguous ⇒ nota y curva intactas (iOS sí lee FC de ventana sin workout). kcal SOLO del origen de la sesión asociada en su rango (workout.statistics iOS). SUB-GAP ABIERTO: Android no escribe la sesión propia como ExerciseSessionRecord (syncWorkoutToHealth iOS sí escribe en HealthKit); sin ese vínculo, una sesión de teléfono sin registro de Salud asociable nunca se refina. Sesiones propias excluidas por packageName al listar actividades externas | 5 tests dominio SessionCardioEffort + 9 SessionHealthMatcher (fixtures: dos orígenes solapados, misma app teléfono/reloj, duplicados externos, señal ajena en ventana, candidato breve, 85%) |
| ~~4~~ | `DayPlusSheet` (598) | CERRADO 24/10: hoja con alta one-off (a3edd12), borrador puro con persistencia SOLO en Guardar (8789bc7, sustituye al diseño con reconcile retirado por inseguro), caption de cuota (bce299e), temporizadores favoritos en hub (3b5df6f) | Prueba: fixtures instrumentados (ciclo de vida del borrador: vacía preexistente intacta, cancelar con contenido sin persistir, guardar explícito; store de timers roundtrip) + gates locales; pendiente ejecución integrada CI |
| 5 | `ExerciseLoadGuideCard` (207) + `RoutineExerciseEditor` (PlanView) + `LoadSuggestion` + `PlateMath.ExerciseLoadPreference` | IMPLEMENTADA (25/10 00:26): editor por serie en el editor de rutina de fuerza (filas KG/Reps/RIR, añadir/eliminar serie, Guardar/Volver como iOS) con la guía «Referencia» dentro (ÚLTIMA VEZ / CARGA SUGERIDA / Aplicar que escala la última sesión al kg sugerido / Copiar última sesión); plannedSets con targetRir escritos y releídos 1:1 (round-trip con rutinas iOS; ausente = «asumido», nunca confirmado); redondeo a settings.weightIncrementKg. La guía SOLO vive en el editor del plan (retirada del registro en vivo: iOS no la muestra ahí, comprobado en Apps/ — un único call site, PlanView). Sin migración destructiva: rutinas antiguas sin targetRir se conservan | 12 tests unitarios |
| 6 | `ExerciseSessionAppearance` (206) + `ExerciseThisSessionCard` (135) | IMPLEMENTADA (25/10 00:11): motor en mobile con 8 tests + tarjeta «Esta sesión» en la ficha al abrirla desde un movimiento del historial (ruta ejercicio/{id}?sesion={sessionId}); sección, «Anterior/Intento anterior» y estados vacíos 1:1. Divergencias documentadas: scoping por instancia portado (highlightExerciseInstanceId: solo la fila pulsada y los scores de su bloque; test con el mismo ejercicio en dos bloques) y catálogo WODTemplate ya sembrado en dominio (31 plantillas, ids idénticos a iOS) con nombre del benchmark resuelto desde la semilla (template?.name ?? session.title) | 8 tests unitarios (ExerciseSessionAppearanceTest) |
| 7 | `ExerciseEquipmentGroup` (133) | IMPLEMENTADA (24/10 ~23:20): clasificador portado 1:1 a dominio (`ExerciseEquipmentGroup.kt`, 5 tests de dominio verdes) y cableado en la biblioteca Android: selector Orden (Alfabético/Músculo/Material), por defecto alfabético como iOS, búsqueda siempre plana por relevancia, secciones con collator es_ES. Fila de ejercicio duplicada inline en ambas ramas para preservar estado por ítem (rememberSaveable por clave) | 5 tests de dominio |
| 8 | `CardioRouteComponents` (scrub chartXSelection) | IMPLEMENTADA (25/10 00:44): scrub táctil en el perfil de altitud con gesto idéntico a iOS chartXSelection (la selección existe solo durante el arrastre y se limpia al soltar/cancelar; regla discontinua + marcador + etiqueta «m · km»; caption «arrastra para inspeccionar»). Curva de pulso por sesión con el mismo scrub (sección «Ritmo cardíaco» en la tarjeta expandida; solo con datos de Salud ≥2 muestras) | Verificación píxel y arrastre/scroll en integración pendientes |

Reconciliación 25/10 00:47 contra fuentes Android (grep de cada pieza + conteo de @Test): #2 RouteMapModel/RouteMapView presentes (4 tests modelo + 5 análisis); #3 SessionCardioEffort dominio (5 tests) + refine cableado en SessionReviewSupport/WorkoutRepository/MainActivity + readSessionSample/readSessionHeartSeries con dedup por dataOrigin y exclusión del packageName propio; #5 editor de series en RoutineBlocksEditor con LoadGuideSection como ÚNICO call site de la guía (12 tests); #6 ExerciseSessionAppearance (8 tests) + tarjeta en ExerciseDetailScreen; #7 ExerciseEquipmentGroup dominio (5 tests) cableado en ExercisesTab; #8 scrubs con onDragEnd/onDragCancel que limpian la selección (ReperaCards 1657-1658, 1871-1872); swipe-to-reveal con SwipeRevealMath en tarjeta de historial (ReperaCards 1267-1302). #1 PlaceSearch sigue con decisión pendiente en main.

## FIDELIDAD (existe; presentación/UX distinta)

| Pieza iOS | Estado Android |
|-----------|----------------|
| `ActivityHeatmapView` | Rejilla + cuartiles ya existían; paleta y leyenda corregidas 24/10. Abiertos: segmented picker en una tarjeta, franja en rangos cortos, etiquetas mes/día |
| `RegisterSwipeRevealCard` (382) + `SwipeRevealMath` (17) | PARCIAL (25/10 00:00): `SwipeRevealMath` portado 1:1 a dominio (3 tests). Borrado de REGISTRO completo implementado: tombstone del espejo ANTES de borrar (paridad BusinessWorkoutSyncStore iOS), papelera en tarjeta de historial con confirmación («¿Eliminar registro?», igual que OGConfirmSheet) y test instrumentado con fixtures (tombstone persistido, doble borrado falla sin borrar de más). Gesto swipe Compose implementado 25/10 (f6657fe): la tarjeta de historial desliza con SwipeRevealMath.clampedOffset/shouldOpen y revela la papelera con la misma confirmación | 3 tests dominio + 1 instrumentado; verificación táctil/scroll en integración pendiente |
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
