# Arquitectura Repera

Última actualización: 2026-10-19 (ubicación al Play + peso source)

## Visión

App **local-first**: el estado vive en el dispositivo (JSON) y se sincroniza con **iCloud Documents**. El dominio puro está en el paquete `ReperaDomain` (testeable sin UI). La app iOS añade Sign in with Apple (identidad obligatoria), Salud, Vision, Foundation Models, ubicación (pin/ruta) y Watch Connectivity.

## Estructura del repo

```
repera/
├── Apps/
│   ├── Repera/                 # Target iPhone (SwiftUI)
│   │   ├── Sources/            # UI + stores de plataforma
│   │   └── Resources/          # Assets, Info.plist, BodyPaths.json, ExerciseArt (JPG 1024 + thumbs/192)
│   ├── ReperaWatch/            # Companion Watch
│   ├── ReperaRestWidget/       # Live Activity (descanso)
│   └── Shared/                 # RestActivityAttributes (app + widget)
├── Packages/
│   └── ReperaDomain/           # Modelos + motores (sin UIKit)
├── web/                        # Sitio estático repera.app (producto, legales, FAQ)
├── docs/                       # Documentación viva
├── project.yml                 # XcodeGen
├── AGENTS.md
└── README.md
```

Marketing web (`web/`): HTML/CSS/JS sin framework; SEO (canonical, OG, sitemap, JSON-LD), banner de cookies GDPR-ready y secciones de producto. Deploy IONOS: `web/pack-ionos.sh` → zip con `.htaccess` (pretty URLs, gzip, cabeceras). Detalle en `web/README.md`.

## Targets

| Target | Rol |
|--------|-----|
| **Repera** | App iOS 27+. Tabs, sesión, Salud, OCR/IA pizarra, Live Activity host |
| **ReperaRestWidget** | Widget Extension: Dynamic Island / lock screen del descanso |
| **ReperaWatch** | Sesión + log rápido vía Watch Connectivity |
| **ReperaDomain** (SPM) | Modelos, catálogo, stats, progresión, parser, LoadSuggestion |

Generación de proyecto: `xcodegen generate` → `Repera.xcodeproj`.

## Capas

```
┌─────────────────────────────────────────┐
│  SwiftUI (Home, Plan, Stats, Library…)  │
├─────────────────────────────────────────┤
│  ReperaStore · SubscriptionManager · Onboarding / AppleAuth · HK · Location │
├─────────────────────────────────────────┤
│  ReperaDomain (Models, Stats, FeatureAccessPolicy) │
└─────────────────────────────────────────┘
```

Dependencia SPM adicional (app iOS): **RevenueCat** (`purchases-ios-spm`). No se enlaza en Watch.

### `ReperaStore` (`Apps/Repera/Sources/ReperaStore.swift`)

Fuente de verdad de la UI: ejercicios, rutinas, sesiones, peso corporal, favoritos, sesión activa. Persiste vía `LocalStore` / iCloud.

- Gates freemium: `featureAccess` inyectado desde `SubscriptionManager`; `saveRoutine` / `addCustomExercise` / `ProgressionEngine` respetan la política.
- El entitlement Pro **no** forma parte de `AppState` / JSON exportable.

- Peso corporal: **un entry por día** (`dedupeBodyWeightsByDay` / `syncBodyWeightWithHealth`) con `BodyWeightSource` (manual / health).
- Ubicación: al empezar sesión (`beginLocationTracking`) → `ensureWhenInUseAuthorized` (modal si `.notDetermined`) → pin en `activeSession.locationPin`; ruta GPS solo si el entreno parece outdoor.
- Quick log: `startQuickLog` / `logQuickSets`.
- Borrado de entreno: limpia estado local y, si hay UUID, HealthKit.

### `HealthKitStore`

Lectura/escritura Salud: peso, energía activa, workouts externos, FC, rutas. Alimenta Progreso con **caché diaria** de FC/kcal (hasta 360d); la UI promedia a semana/mes solo al pintar. Sync de peso: 1 muestra/día.

**kcal al guardar:** provisionales al instante (`estimateSessionKcal` / MET). `HealthKitStore.finishWorkout` solo adopta kcal de Watch/Salud si `shouldTrustAppleWorkoutEnergy` (≥30 kcal y no ridículas vs el estimado); samples ambiente en la misma hora (p. ej. 2 kcal) **no** pisan el entreno. Sin workout creíble se escribe el estimado en Salud.

**Arranque rápido (local-first):**
- Snapshot JSON en Application Support (`HealthDiskCache`) con actividades + FC/kcal + ancla `HKQueryAnchor`.
- Hidrata en `init` → Inicio pinta puntos/kcal al instante; luego refresh en background.
- `HKAnchoredObjectQuery` fusiona altas/bajas cuando el filtro Repera no cambió; si no, query completa.
- `HKObserverQuery` + `enableBackgroundDelivery` (entitlement `com.apple.developer.healthkit.background-delivery`) marca dirty; al volver a foreground se refresca.

### `ReperaDomain` — piezas clave

| Módulo | Responsabilidad |
|--------|-----------------|
| `Models.swift` | `Exercise`, `Routine`, `RoutineBlock`, `WODMovement`, `WorkoutSession`, `AppState`…; `ExerciseLoggingStyle` (load / reps / comba / `machineWork` Cal·m) + `LoggedSet.quantityUnit` |
| `Catalog*.swift` | Seed gym / CrossFit / halterofilia / gimnasia + ES (`CatalogSpanish` 188/188: desc + guía entrenador); deporte en `sportTag`, grupo = músculo principal |
| `CatalogWODs.swift` | Benchmarks conocidos (`WODTemplate` → `RoutineBlock` con `wodTemplateId`); `WODScoreBands` principiante→élite |
| `WODBlockResult` / `WODResultCapture` | Score por bloque (reps AMRAP / tiempo For Time / series); `WorkoutSession.wodResults` |
| `SessionReview` / `SessionReviewEngine` | Valoración post-entreno: nota por rendimiento (bandas / ritmos por movimiento / typical) + ajuste hasta ±2 con `ExerciseEquivalence`; tips por ejercicio; `WorkoutSession.sessionReview` |
| `ExerciseEquivalence` | Familias de movimiento (squat, hinge, press, pull…) y historial comparable entre ejercicios similares (mismo `loggingStyle` / `loadField`) |
| `MovementPaceStandards` / `WODPaceEstimator` | Segundos/unidad por tipo de movimiento y nivel (principiante→élite); estima tiempo/rondas de WOD a medida |
| `StatsEngine` | Series de progreso, PRs, métricas diarias, filtros `ProgressTimeRange` |
| `MuscleTaxonomy` / `MuscleMapEngine` | Carga + fatiga (vida media por slug BodyMap); niveles 0–4 verde→rojo; primario 1.0 / secundarios ~0.55–0.35 |
| `BoardImportParser` / `CrossFitGlossary` | OCR texto → fuerza+WOD; equipo DB → variante mancuerna (`resolveCatalogName` / `preferEquipmentVariant`) |
| `RoutineBlock.plannedSets(for:)` | Series al apuntar según formato (EMOM/RFT/Tabata/…) |
| `SessionController` | Ciclo de vida de la sesión |
| `ProgressionEngine` | Off / lineal / doble / Greyskull / triple |
| `PlateMath` | 1RM Epley (`epleyOneRM`); preferencia `testedOneRMKg` por ejercicio |
| `LoadSuggestion` | `%` de 1RM → kg (pizarra / ficha); también kg para reps+RIR (Epley inverso) en el editor de series |
| `ExerciseSubstitutes` | Alternativas mismo músculo (dominio; UI de cambio no expuesta) |
| `ProgressTimeRange` | Periodos de Progreso |
| `Monetization/*` | `ReperaFeature`, `FeatureAccessPolicy`, `FreeUsageLedger`, `SubscriptionStatus` |

### Monetización (app)

| Archivo | Rol |
|---------|-----|
| `SubscriptionManager` | Estado comercial observable, ofertas, compra/restore, paywall |
| `RevenueCatEntitlementProvider` | CustomerInfo → `CommercialSnapshot` |
| `FreeUsageStore` | Cuota escáner (`free_usage.json`, fuera del JSON deportivo) |
| `PaywallView` / `ProTeaserCard` | UI comercial Liquid Glass |
| Detalle | [MONETIZATION.md](MONETIZATION.md) |

## Navegación (tabs)

`RootTabView`: **Inicio · Diario · Center · Progreso · Ejercicios**. El antiguo `StartHubSheet` se presenta desde Inicio mediante +; el flujo de sesión y todas sus herramientas se conservan. `CenterView` es nativa y muestra estados vacíos auténticos hasta conectar datos profesionales.

- Flujo de entreno: overlay `NavigationStack` (`sessionPreview` → `workout`).
- Tab bar: `minimize` solo con sesión activa; accessory **Continuar**.

La pestaña Diario prioriza **Entrenador** y conserva **Personal · Rutinas** como alternativas sin sobrescribir almacenamiento local. Ajustes agrupa relaciones profesionales y contratos con estados «Sin sincronizar» hasta disponer de APIs y sesión Supabase móvil verificadas.

## UI / design system

`Theme.swift` (`OG*`):

- Colores oscuros, acento verde `#30d158`
- `OGCard`, `OGPageHeader`, `OGBackPageHeader` (legacy / sheets compactos)
- `ogPinnedTransparentNav`: título large debajo de volver/acciones (subpáginas)
- `ogFixedTopBar` / `OGFixedTopBar`: título arriba del todo; acciones en la misma fila (roots sin franja vacía)
- `OGCardSectionTitle`: título gris encima de la card (estilo Ajustes)
- Botones glass: `OGToolbarGlassButton` (`appliesGlass: false` en `.toolbar` del sistema)
- Sheets: `ogFittedSheet` / `ogSheetCorners` (radio 38 + **liquid glass** de fondo)
- Confirmaciones (eliminar, vaciar…): `OGConfirmSheet` (mismo glass)

## Datos y sync

- Estado: `AppState` Codable → JSON local (`Application Support/Repera`) + espejo iCloud Documents.
- Bootstrap: `LaunchWarmup` solapa catálogo + `HealthDiskCache` + `app_state` con el primer frame. `ReperaStore` arranca con shell vacío; tras pintar: hydrate (reutiliza warm) → merge catálogo off-main → validar Sign in with Apple / onboarding → iCloud. Sin onboarding completo no se muestra `RootTabView`. LaunchScreen: `Splash` PNG 473∶1024 en `UIImageView.scaleAspectFit` fijada a los cuatro bordes sobre `#002E24`; durante la validación de sesión, `LaunchSplashView` usa la misma vista UIKit y los mismos límites para evitar saltos de escala al pasar del lanzamiento nativo a SwiftUI. Detalle en `docs/PERFORMANCE.md`.
- `WorkoutSession` puede llevar `locationPin` y `routePoints` (Codable, migrable); el detalle prioriza ruta Salud → ruta propia → pin.
- Conflictos: `syncRevision` + `lastWriterDeviceId` (`SyncConflictResolver`); fallback a `updatedAt` para docs legacy.
- I/O: actor `AppStatePersistence` (encode/write atómicos, coalescing); fachada `LocalStore` en MainActor.
- Fases: `AppSyncPhase` (`loadingLocal` → `awaitingRemote` → `ready` / `offline` / `recoveringCorrupt`).
- Canvas de modernización: `docs/ios27-modernization/`.
- Thumbs: `ThumbImageLoader` (concurrencia 4, LRU, manifiesto JPG).
- Stats: `DerivedStatsCache` invalidado con `syncRevision`; epochs Observation (`catalogEpoch` / `workoutsEpoch` / `sessionEpoch`); chrome de sesión `hasActiveSession` + `continueAccessory` (sin partir el documento Codable).
- Progreso: `ProgressViewModel` + `ProgressDataEngine` preparan un `ProgressSnapshot` off-MainActor (tiles, charts, heatmap, músculo, PRs, peso); caché por `ProgressDataKey` (periodo + revisiones). `StatsView` pinta `LazyVStack` con datos listos.
- Salud: hydrate disco para primer paint; match Repera↔HK con `ReperaSessionMatchIndex`; al cambiar entrenos Repera se invalida solo el filter (sin vaciar UI) y se re-fetch coalescido; observers marcan `healthNeedsRefresh`.
- Rendimiento: detalle en `docs/PERFORMANCE.md`.

- Export / import JSON; import CSV Strong/Hevy (`WorkoutCSVImporter`).

## Plataforma específica (solo app)

| Archivo | Uso |
|---------|-----|
| `BoardTextRecognizer` | Vision OCR |
| `BoardAIImporter` | Foundation Models (Apple Intelligence) |
| `BoardImportPipeline` | Local primero (skip IA si ≥2 bloques) → IA → fallback → enrich + rondas EMOM |
| `OGRoutineBlockCard` | Cards+thumbs compartidas (preview día + revisión pizarra) |
| `BoardScanReviewPayload` | Cierra `DayPlusSheet` y empuja `BoardImportReviewView` como página en Inicio («Añadir entreno») |
| `RestLiveActivity` + widget | Timer de descanso en isla / lock screen |
| `BodyMapView` + `BodyPaths.json` | Mapa muscular SVG |
| `ProgressTrendCards` | Cardio, kcal, peso vs objetivo |
| `QuickLogSheet` / `QuickLogPickerView` | Apuntar series |
| `ExerciseArt` / `ExerciseThumb` | Hero 1024px anatómico (gris+lime/charcoal); carrusel = `base_1…N` o `movementFrames` (reuso de héroes); caption = instructions[i]; holds estáticos sin carrusel; poses en aire sin sombra de suelo; listas usan `thumbs/` 192px; prefetch paralelo |
| `ExerciseSearch` | `Document` index + `score`/`ranked` (filtro sync en LibraryView) |
| `LibrarySearchLog` | Timing DEBUG rebuild/`rank top` del buscador |
| `PhoneConnectivity` / Watch | Sesión + acciones `quickLog` / `logSet` |

## Tests

```bash
cd Packages/ReperaDomain && swift test
```

Incluye `BoardImportParserTests`, `LoadSuggestionTests`, sesión, progresión, waves.

Guía manual: [TESTING_GUIDE.md](TESTING_GUIDE.md).

## Plataforma profesional (desarrollo separado dentro del monorepo)

- Primera migración Supabase del proyecto Repera aplicada con perfiles, organizaciones y RLS. No está integrada con el flujo actual Sign in with Apple ni con iCloud.
- Plan, estado y pruebas: [docs/business/PLAN_MAESTRO.md](business/PLAN_MAESTRO.md), [docs/business/ESTADO_DESARROLLO.md](business/ESTADO_DESARROLLO.md), [docs/business/SEGURIDAD.md](business/SEGURIDAD.md).
- El panel profesional web y Android nativo permanecen pendientes; el sitio `web/` continúa siendo **marketing** y sus ficheros de IONOS no se han cambiado.

## No vive aquí todavía

- Backend operativo conectado a las aplicaciones iOS/Android
- Android
- Coach / LLM en la nube (Foundation Models solo pizarra on-device)

## Auditoría de ilustraciones de ejercicios (2026-10-17)

- `ExerciseArt.imageName(forExerciseName:muscleGroup:)` solo devuelve un hero cuando hay asignación exacta en `nameMap`: nunca emplea una foto ajena como fallback por músculo.
- `imageNames(for:)` prioriza pasos propios `_1…_8`, después `movementFrames` verificados y por último un hero. La lista de candidaturas no habilita por sí misma un fallback.
- El conjunto `quarantinedSequences` bloquea carruseles con fallos comprobados visualmente: la ficha conserva el hero y el texto técnico mientras se regenera el material, aunque el hero también requiere QA independiente.
- Los holds estáticos se fuerzan a un único hero. Los N primeros textos de `CatalogSpanish.instructions` son captions de fase; si hay menos de N, se retira el carrusel y queda solo el hero. Los pasos siguientes son coaching («Cómo hacerlo») y no cuentan para ese chequeo.
- `scripts/export_generated_art.py` escribe full JPEG 1024×1024 y thumb JPEG 192×192 bajo `Apps/Repera/Resources/ExerciseArt/`; no hace falta registrar cada recurso por separado en `project.yml`.
- `scripts/audit_exercise_art.py` con Pillow valida JPEG, medidas, pares full/thumb, referencia desde `nameMap` y N captions. `docs/EXERCISE_ART_AUDIT.csv` recopila por stem los defectos confirmados y lo que continúa pendiente de inspección visual.

El auditor estructural **no puede aprobar** similitud del personaje, ejecución anatómica, lateralidad, sombra, equipo y activación muscular sin revisión visual. No publicar una secuencia en cuarentena hasta generar y exportar todos sus frames y miniaturas, comprobarlos visualmente y retirar su entrada de cuarentena.
