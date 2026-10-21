# Arquitectura Repera

Última actualización: 2026-10-21 (edición unificada de entrenos terminados, snapshot de bloques)

## Unidad de cardio en rutinas y sesiones

`RoutineExercise.quantityUnit` es un campo `Codable` opcional (Cal o metros) que controla la unidad de las series de cardio en una rutina de fuerza o bloque. `SessionController.from` propaga el valor a `SessionExercise.quantityUnit`, que usa Play para inicializar el registro en la unidad elegida. Para movimientos WOD se reutiliza `WODMovement.prescribedQuantityUnit`. La ausencia del campo en JSON antiguo conserva la compatibilidad: se usa la unidad por defecto del ejercicio. Las series continúan registrándose en `LoggedSet.quantityUnit` y no como kilogramos.

La edición durante una sesión activa reconstituye la planificación y reasocia las series registradas mediante identidad de bloque y ejercicio; el ID de la sesión, los tiempos y las series previamente anotadas no se sustituyen.

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
├── Configs/Version.xcconfig    # Version y build compartidos (Xcode)
├── scripts/sync_versions.py    # Captura ediciones Xcode y validación
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

### Versionado de todos los targets

`Configs/Version.xcconfig` define `REPERA_MARKETING_VERSION` y `REPERA_BUILD_NUMBER`. Las configuraciones Debug y Release lo incluyen a nivel **proyecto**; `MARKETING_VERSION` y `CURRENT_PROJECT_VERSION` resuelven esos valores y cada target iOS/Watch/widget hereda las dos variables. En los tres `Info.plist`, `CFBundleShortVersionString=$(MARKETING_VERSION)` y `CFBundleVersion=$(CURRENT_PROJECT_VERSION)` sustituyen a los literales anteriores. XcodeGen genera estos plist con dichas expresiones, de modo que regenerar no los vuelve a fijar.

La preacción del scheme `Repera` guarda los valores efectivos que Xcode muestra para el target iPhone en el `.xcconfig`; el `options.preGenCommand` de XcodeGen ejecuta `scripts/sync_versions.py --from-project` antes de regenerar, y captura los cambios realizados en la GUI a través de `xcodebuild -showBuildSettings`. El proyecto `.xcodeproj` queda generado/no versionado, y `Configs/Version.xcconfig` es persistente. Las ediciones deben realizarse en el archivo compartido o en los ajustes del proyecto (Debug+Release) para evitar discrepancias durante una primera compilación con overrides del target iPhone. CI valida el cableado y ejecuta los tests Python. No se incrementan builds de forma automática.


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
- Ubicación: al empezar sesión (`beginLocationTracking`) → pin GPS; ruta GPS si outdoor. Además, al apuntar/editar: `PlaceSearchSheet` (MapKit) escribe `WorkoutLocationPin` con nombre + `mapItemIdentifier`. Detalle: ruta Salud → ruta propia → pin (`Marker` nativo). Sin pin manual si hay ruta Salud.
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
| `SessionReview` / `SessionReviewEngine` | Valoración post-entreno: nota por rendimiento (bandas / ritmos / typical) + ajuste ±2 con `ExerciseEquivalence` + ajuste ±2 con `SessionCardioEffort` (FC/kcal de Salud); `WorkoutSession.sessionReview` |
| `ExerciseEquivalence` | Familias de movimiento + `matchesCatalogIdentity` (id / catalogId / nombre) para historial y ficha pese a UUID huérfanos de WOD/pizarra |
| `MovementPaceStandards` / `WODPaceEstimator` | Segundos/unidad por tipo de movimiento y nivel (principiante→élite); estima tiempo/rondas de WOD a medida |
| `StatsEngine` | Series de progreso, PRs, métricas diarias; historial por ejercicio acepta `catalog` para emparejar por identidad |
| `MuscleTaxonomy` / `MuscleMapEngine` | Carga + fatiga (vida media por slug BodyMap); niveles 0–4 verde→rojo; primario 1.0 / secundarios ~0.55–0.35 |
| `BoardImportParser` / `CrossFitGlossary` | OCR texto → fuerza+WOD; equipo DB → variante mancuerna (`resolveCatalogName` / `preferEquipmentVariant`) |
| `RoutineBlock.plannedSets(for:)` | Series al apuntar según formato (EMOM/RFT/Tabata/…) |
| `SessionController` | Ciclo de vida de la sesión |
| `CompletedWorkoutEditing` | Adaptador bidireccional entre `WorkoutSession` terminada y el editor de `RoutineBlock`: muestra valores registrados, preserva IDs y técnicas, permite reordenar y no convierte series sin registrar en realizadas. `WorkoutSession.routineBlocks` guarda el snapshot de estructura (incluidos descansos WOD) de forma opcional y compatible con históricos. |
| `ProgressionEngine` | Off / lineal / doble / Greyskull / triple |
| `PlateMath` | 1RM Epley (`epleyOneRM`); preferencia `testedOneRMKg` por ejercicio |
| `LoadSuggestion` | `%` de 1RM → kg (pizarra / ficha); también kg para reps+RIR (Epley inverso) en el editor de series |
| `ExerciseSubstitutes` | Alternativas mismo músculo (dominio; UI de cambio no expuesta) |
| `ProgressTimeRange` | Periodos de Progreso |
| `Monetization/*` | `ReperaFeature`, `FeatureAccessPolicy`, `FreeUsageLedger`, `SubscriptionStatus` |

### Monetización (app)

| Archivo | Rol |
|---------|-----|
| `SubscriptionManager` | Estado comercial observable, ofertas, compra/restore, paywall; `businessSponsoredAccess` si hay vínculo activo a centro/entrenador |
| `RevenueCatEntitlementProvider` | CustomerInfo → `CommercialSnapshot` |
| `FreeUsageStore` | Cuota escáner (`free_usage.json`, fuera del JSON deportivo) |
| `PaywallView` / `ProTeaserCard` | UI comercial Liquid Glass |
| Detalle | [MONETIZATION.md](MONETIZATION.md) |

## Navegación (tabs)

`RootTabView`: **Inicio · Diario · Crear|Center · Progreso · Ejercicios**. La pestaña central es **Crear** (`StartHubSheet`) salvo vínculo/invitación a gimnasio o entrenador, cuando pasa a **Center**. El + de Inicio sigue abriendo Crear en hoja. `CenterView` divide **Clases / Citas** con datos reales de Supabase.

- Flujo de entreno: overlay `NavigationStack` (`sessionPreview` → `workout`).
- Tab bar: `minimize` solo con sesión activa; accessory **Continuar**.

La pestaña Diario prioriza **Entrenador** y conserva **Personal · Rutinas** como alternativas sin sobrescribir almacenamiento local. Ajustes: **Buscar centro o entrenador**, ficha con bonos/sesiones, sync unificado; mensajes en topbar de Inicio.

## UI / design system

`Theme.swift` (`OG*`):

- Tokens `OG*` adaptativos (día/noche según sistema), acento verde `#30d158`
- `OG.bg` = lienzo (día gris agrupado, noche negro); `OG.surface` = cards/filas (día blanco, noche gris) — mismo patrón de secciones en ambos modos
- `OGCard`, `OGPageHeader`, `OGBackPageHeader` (legacy / sheets compactos)
- `ogPinnedTransparentNav`: título large debajo de volver/acciones (subpáginas); fuerza `.toolbar(.visible)` porque roots con `ogFixedTopBar` ocultan la barra
- `ogFixedTopBar` / `OGFixedTopBar`: título arriba del todo; acciones en la misma fila (roots sin franja vacía)
- `OGCardSectionTitle`: título gris encima de la card (estilo Ajustes)
- Botones glass: `OGToolbarGlassButton` (`appliesGlass: false` en `.toolbar` del sistema)
- Sheets: `ogFittedSheet` / `ogSheetCorners` (radio continuo 44 + **liquid glass** de fondo; estilo sheet nativo iPhone)
- Confirmaciones (eliminar, vaciar…): `OGConfirmSheet` (mismo glass)
- Filas Inicio/Historial: `OGRegisterLeadingIcon` + `WorkoutRegisterChips` / `OGRegisterChipsRow` (`RegisterSessionChrome.swift`); minutos = `displayDurationMinutes`; Inicio usa check, Historial icono de fuerza

## Datos y sync

- Estado: `AppState` Codable → JSON local (`Application Support/Repera`) + espejo iCloud Documents.
- Bootstrap: `LaunchWarmup` solapa catálogo + `HealthDiskCache` + `app_state` con el primer frame. `ReperaStore` arranca con shell vacío; tras pintar: hydrate (reutiliza warm) → merge catálogo off-main → validar Sign in with Apple / onboarding → iCloud. Sin onboarding completo no se muestra `RootTabView`. LaunchScreen: `Splash` PNG 473∶1024 en `UIImageView.scaleAspectFit` fijada a los cuatro bordes sobre `#002E24`; durante la validación de sesión, `LaunchSplashView` usa la misma vista UIKit y los mismos límites para evitar saltos de escala al pasar del lanzamiento nativo a SwiftUI. Detalle en `docs/PERFORMANCE.md`.
- `WorkoutSession` puede llevar `locationPin` (lat/lon + `name` + `mapItemIdentifier`) y `routePoints` (Codable, migrable); el detalle prioriza ruta Salud → ruta propia → pin.
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

## Planificación profesional sincronizada en iOS
`BusinessDataStore` lee `professional_training_sessions` de clientes vinculados (doble control: RLS del servidor + filtro local). `PlanView` en modo Entrenador lista títulos, fechas e instrucciones del coach y `HomeView` muestra la programación del día, sin alterar las rutinas/series JSON privadas de iCloud. El editor de bloques/series profesionales avanzado no está conectado todavía.

## Datos reales de Centro/bonos en iOS
`BusinessDataStore.swift` es un overlay `@Observable` alimentado por Supabase SDK autenticado. `CenterView` lee Clases/Citas, bonos y reservas; `FindCenterTrainerView` / `LinkedCenterDetailView` gestionan directorio, vínculo, bono y desvinculación; `MessagesInboxView` mensajes bidireccionales. Migración `org_directory_avatar_messaging`: `avatar_url`, directorio, `request_org_athlete_link`, `leave_org_as_athlete`, `athlete_send_org_message`. No se fusiona con el JSON local ni iCloud.

## Puente de identidad iOS/Repera Business
`BusinessAuthStore.swift` usa SDK `supabase-swift` (2.55.4 exacta). **Primer login = Apple id_token + nonce → `signInWithIdToken` Supabase**. Arranque: onboarding + (`isConnected` | refresh Keychain | binding) → `RootTabView`, aunque Apple Keychain esté vacío (p. ej. wipe histórico por `.revoked` espurio). Identidad Apple se espeja en UserDefaults; no se borra Keychain en `getCredentialState(.revoked)`. Trazas: Consola `com.app.repera` / `AuthSession` y DEBUG `🔐 AUTH`.

## Plataforma profesional (desarrollo separado dentro del monorepo)

- Seis migraciones Supabase en el proyecto Repera: identidad, relaciones consentidas, bonos, reservas y sesiones profesionales, con RLS. El puente nativo Apple está escrito y pendiente de validar en dispositivo y proveedor Supabase; no hay intercambio de historial deportivo con iCloud.
- Plan, estado y pruebas: [docs/business/PLAN_MAESTRO.md](business/PLAN_MAESTRO.md), [docs/business/ESTADO_DESARROLLO.md](business/ESTADO_DESARROLLO.md), [docs/business/SEGURIDAD.md](business/SEGURIDAD.md).
- El panel profesional autenticado vive en `web/console`, con algunas operaciones reales y otras pendientes; el sitio `web/` de IONOS sigue siendo **marketing** y su empaquetado no incluye la consola. Android nativo no está implementado.

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


### Salud y recuperación local

`HealthRecoveryStore` usa HealthKit directamente en el iPhone y no entra en la capa de `BusinessWorkoutSyncStore`. Los permisos opcionales (sueño/ciclo + flags de decisión) se almacenan en `UserDefaults` local; la UI vive en **Ajustes → Salud conectada** (`ConnectedHealthSettingsView`). Las muestras se consultan en Apple Salud y se mantienen en memoria (hasta ~120 días de sueño). No añadir estos datos a `AppSettings`, al documento iCloud de entrenamientos ni al payload de Supabase. Las sesiones sí guardan sus ejercicios, bloques, series y resultados para el entrenador con consentimiento existente. En el espejo Supabase, `privateMirrorPayload` elimina toda referencia a Apple Salud, incluido `appleDurationSeconds`.

El campo histórico `supersetGroup` permanece en el formato Codable para abrir copias antiguas, pero se ignora al decodificar y no debe utilizarse para nuevas planificaciones.


### Cardio con GPS (solo iPhone)

`CardioRouteAnalysis` (ReperaDomain) recibe coordenadas/fechas y FC, filtra saltos GPS, calcula distancia con haversine e interpola los instantes de cruce de cada kilómetro. Devuelve perfil altimétrico y parciales únicamente para tramos válidos; no hace peticiones a red. `HealthKitStore.RoutePoint.altitudeMeters` y `WorkoutRoutePoint.altitudeMeters` son opcionales, preservan rutas antiguas y pueden provenir de GPS de Apple Salud o Core Location. `CardioRouteComponents` usa Swift Charts (selección x nativa, `catmullRom` + clip), selector Cardio/Altitud con tiles contextuales, parciales y `SessionMapWeatherCard`. WeatherKit **no se persiste**: se pide al abrir el detalle (`startedAt`/`finishedAt`, no `.distantPast`); requiere capacidad en App ID + entitlement; si falla → «—». AQI histórico sin proveedor → «—».

`BusinessWorkoutSyncStore.privateMirrorPayload` elimina `routePoints`, `locationPin` y datos de HealthKit antes de transmitir a Supabase. La posición inicial del recorrido se redondea a 2 decimales (~1 km) antes de consultar WeatherKit; nunca se envía el recorrido completo ni se comunica nada a Supabase.

### Diagnóstico CI de octubre de 2026

La configuración `.github/workflows/ios27-ci.yml` completó correctamente los cuatro jobs el 20-10-2026 a las 13:52 UTC (run 39434137818). En las ejecuciones posteriores los cuatro jobs, incluidos los basados en `ubuntu-latest`, han fallado antes del primer paso (`steps: null`), sin logs disponibles a través del conector. Esto es distinto de un error del compilador y requiere investigar GitHub Actions/runner facturación o límites de cuenta desde la interfaz administrativa. No desactivar los tests para forzar resultados verdes.
