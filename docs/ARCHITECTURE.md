# Arquitectura Repera

## Formatos numéricos compartidos (26/10/2026)

`ReperaDomain.ReperaNumberFormat` centraliza la representación humana de cifras con punto para agrupar millares desde 1.000, coma decimal y entre cero y dos posiciones decimales. Tanto los targets iOS como los watchOS reutilizan esta utilidad; las vistas raíz propagan el locale español para gráficos y formatos nativos. `ReperaNumberFormat.parse` acepta cadenas españolas y puntos decimales antiguos en campos editables, sin cambiar los tipos de dominio ni las codificaciones ISO/JSON/Supabase/HealthKit. Las pruebas de regresión cubren millares, redondeo, negativos, entradas mixtas y separación de presentación y almacenamiento.

## Token renovable, rutas GPS y récords deportivos (26/10/2026)

- `BusinessAuthStore.ensureUsableSession()` pide una sesión vigente a `supabase-swift`, que renueva la credencial si es necesario. El inicio de la app y `BusinessWorkoutSyncStore.sync` lo utilizan. `requiresReauthentication` cambia el `ReperaApp.launchRootView` al login solo ante revocación/ausencia definitiva de credenciales; un error de transporte no borra el historial local ni provoca salida forzada. `autoRefreshToken` ya está activado.
- `LiveActivityRecorder` registra una locución por km usando `AVAudioSession.playback` y `AVSpeechSynthesizer`, con encolado de frases. Ninguna notificación substituye las locuciones de kilometraje. iOS controla el icono que aparece en otras notificaciones: se deriva del AppIcon instalado en esa compilación.
- `HealthWorkoutRouteMap` y `LiveActivityView` comparten la paleta de cuatro paradas según tierra/agua. `HealthWorkoutRouteMap` agrupa únicamente segmentos GPS contiguos y válidos en polilíneas con degradados `Gradient(stops:)` sobre la distancia acumulada, suavizado local de velocidad y esquinas visuales de máximo 3 m de desplazamiento; renderiza un halo y dos trazos con extremos/uniones redondeados. Mantiene rupturas ante pausas/saltos, sin modificar la ruta persistida ni las métricas. El visor ampliado conserva los puntos GPS, habilita gesto de zoom/pan y tiene cierre X. `CardioSplitsView` recibe segundos activos y metros totales reales para promedios, evitando extrapolar del primer km.
- `ProgressSnapshot` mantiene estímulos deportivos estimados de todas las sesiones completadas; `filteredHighEffortStimuli` limita la capa de intensidad alta a formatos potencialmente intensos, sin confundir un paseo con RIR registrado. `LiveSportHistoryView` muestra récords deportivos por sesiones reales, distintos de e1RM.



## Sesiones del mismo día y sincronización remota (2026-10-26)

- ReperaStore.saveRoutine identifica cada rutina por UUID, no por fecha; scheduledRoutines(on:) recupera todas las sesiones de un día. removeScheduledRoutine(id:) quita solo la seleccionada. copyPreviousWeekSchedule copia todas las sesiones de la fecha origen si el destino estaba libre antes de copiar.
- HomeView combina fichas completadas y pendientes y filtra únicamente la misma rutina finalizada o en curso; PlanView ofrece cabecera Añadir por día y filas con swipe individual. Cada escaneo guardado crea una rutina autónoma.
- WorkoutView guarda series editadas sin check y las elimina por swipe dentro del ScrollView. Eliminar la última deja ninguna serie hasta usar Añadir serie; nunca sustituir una eliminación por un resultado prescrito automático en borradores.
- La capa local-first persiste entrenamientos terminados en JSON/iCloud. persistWorkouts realiza flush y lanza sincronización explícita mediante BusinessWorkoutSyncStore, además del observador workoutsEpoch; Ajustes muestra el resultado del último intento de mirror de sesiones en Supabase, diferenciado de la sincronización editorial automática.
- LiveSport asigna disciplinas a tipos HKWorkoutActivityType; HealthMuscleMapper usa duración real y tipo deportivo para estimar zonas musculares y cardio sin crear series falsas ni duplicar sesiones enlazadas con Apple Watch.

Última actualización: 2026-10-27 (navegación GPX en Comenzar y widget ActivityKit)

## Series de movilidad (iOS)

`CatalogMovilidad` incorpora 82 ejercicios ES/EN identificados con `sportTag = "Movilidad"`. `Exercise.isMobilityHold` distingue las posturas estáticas de los movimientos dinámicos. Ambos usan registro tiempo+reps mediante `ExerciseLoggingStyle.repsAndTime`, con UI que oculta reps para una postura sostenida. `PlannedSet.targetDurationSeconds` es opcional en Codable y sobrevive a la duplicación de planes; `WorkoutView` lo utiliza para precargar la duración editable sin contabilizarla como registro real hasta confirmar la serie. `LoggedSet.durationSeconds` conserva los segundos ejecutados. La evolución temporal soporta `ExerciseProgressMetric.bestHold` y `duration`, y `ProgressSnapshot` resume segundos reales y número de sesiones sin asignarlos a fatiga/e1RM. `ExerciseArt` bloquea coincidencias parciales con arte de fuerza y utiliza placeholder hasta que las 82 fichas tengan imágenes revisadas.

## Catálogo de ejercicios remoto y offline (2026-10-25)

`RemoteExerciseCatalogStore` consulta el feed de cambios `mobile_exercise_catalog_events` generado por triggers sobre el catálogo profesional y sus metadatos. Una lectura de la última revisión precede a páginas incrementales de 150 eventos (confirmaciones serializadas). Las correcciones de material usan `mobile_equipment`, sin sustituir el seed más detallado por el material genérico de MCP. El actor `DiskStorage` escribe y lee la caché de forma atómica fuera de MainActor; la mezcla de fichas se calcula en una tarea detached con prioridad utility y se actualiza el estado observable solo al completar. `ReperaApp` instala `.backgroundTask(.appRefresh(...))` y agenda `BGAppRefreshTaskRequest` oportunista nativo iOS 27, además de comprobar los cambios al volver a primer plano. No existe botón manual para sincronizar. Los resultados se guardan atómicamente fuera del JSON personal/iCloud en Application Support; tras cualquier recuperación de iCloud se aplica la caché como capa editorial. `Catalog.seed()` permanece de respaldo para primer arranque sin red. `Exercise.isCatalogArchived` preserva UUID/estadísticas, resuelve equivalencias ES/EN y oculta bajas de biblioteca/pickers. Watch recibe actualizaciones de contexto desde iOS y no requiere un cliente Supabase propio. Detalles y límites de implantación: [REMOTE_EXERCISE_CATALOG.md](REMOTE_EXERCISE_CATALOG.md).

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

El editor inline de resultados de AMRAP/For Time (`WODResultInlineEditor`) se declara en `Apps/Repera/Sources/WorkoutView.swift`, no en un archivo Swift separado. Esto evita el error de símbolo no encontrado con proyectos Xcode generados antes del cambio, sin alterar el registro de series ni la captura de score por bloque. No mantener otra definición duplicada al ejecutar XcodeGen.

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
| `Catalog*.swift` | Seed gym / CrossFit / halterofilia / gimnasia / movilidad (82) + ES (`CatalogSpanish` 188/188: desc + guía entrenador); deporte en `sportTag`, grupo = músculo principal |
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

El acceso Google usa `GoogleSignIn` del SDK oficial 10.1.0, fijado en `project.yml`. A petición de producto, `OnboardingFlowView.swift` presenta un `Button` SwiftUI alineado con Apple: mismo ancho, altura fija compartida de 52 pt, logos ajustados a un marco común de 20 × 20 pt, contenido centrado, radio continuo de 12 pt y sin sombra. `signInButtonHeight` y `signInIconSize` se usan en ambos accesos para evitar diferencias de tamaño. La G oficial sin modificar se incluye en `GoogleSignInLogo.imageset`; no se incluyen fuentes propias. Se retira el producto visual `GoogleSignInSwift`, cuyo botón fija sombra y alineación. El flujo de autenticación sigue usando `GIDSignIn`. La bienvenida usa scroll, texto promocional dinámico y estado local del proveedor seleccionado.

`BusinessAuthStore.nativeGoogleCredentials()` configura `GIDSignIn`, selecciona el presentador de la escena activa y pide un ID token con nonce SHA-256. Solo extrae valores `Sendable` dentro del callback de Google; Supabase valida ID token, access token y nonce original mediante `signInWithIdToken`. El UUID remoto se contrasta con el dueño local antes de dar acceso. La vinculación Apple→Google usa `linkIdentityWithIdToken`, nunca un login que sustituya al usuario actual. Cerrar sesión invalida los intentos pendientes y limpia tanto Google como Supabase; cancelar el selector no muestra error. La restauración sigue usando la sesión Supabase de Keychain sin exigir otra autenticación interactiva.

`ReperaApp.onOpenURL` entrega el retorno al SDK. `Configs/GoogleSignIn.xcconfig`, incluido desde `Version.xcconfig`, suministra los IDs públicos de iOS, su esquema invertido y Web (`serverClientID`). El cliente iOS y su esquema, facilitados por el propietario, ya están configurados. `Info.plist` y XcodeGen mantienen las mismas variables; hay validación antes de abrir el SDK para evitar fallos por configuración ausente. Regenerar con `xcodegen generate` al incorporar las dependencias. Pendientes la compilación y la autenticación nativa E2E.

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
- Bootstrap: `LaunchWarmup` solapa catálogo + `HealthDiskCache` + `app_state` con el primer frame. `ReperaStore` arranca con shell vacío; tras pintar: hydrate (reutiliza warm) → merge catálogo off-main → validar Sign in with Apple / onboarding → iCloud. Sin onboarding completo no se muestra `RootTabView`. Arranque nativo iOS 27: `Info.plist` apunta a `UILaunchStoryboardName = LaunchScreen`; `LaunchScreen.storyboard` presenta `ReperaNativeOpaqueHero` RGB de 850 × 1850 con verde `#30D158` y el muñeco con barra integrada sin transparencias. Es la primera fase de UIKit, anterior a SwiftUI. La primera fase SwiftUI utiliza exactamente la misma ilustración desde `ReperaStartupBarbell.png`, después `MascotRunning`, y finalmente Inicio. La compilación CI comprueba el storyboard compilado, la mascota dentro de `Assets.car` y el PNG de la primera fase de SwiftUI. Los storyboards antiguos no forman parte del target XcodeGen. Detalle en `docs/PERFORMANCE.md`.
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
`BusinessAuthStore.swift` usa SDK `supabase-swift` (2.55.4 exacta). **Primer login = ID token Apple o Google + nonce → `signInWithIdToken` Supabase**. Arranque: onboarding + (`isConnected` | refresh Keychain | binding) → `RootTabView`, aunque Apple Keychain esté vacío (p. ej. wipe histórico por `.revoked` espurio). Identidad Apple se espeja en UserDefaults; no se borra Keychain en `getCredentialState(.revoked)`. Trazas: Consola `com.app.repera` / `AuthSession` y DEBUG `🔐 AUTH`.

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

`HealthRecoveryStore` usa HealthKit directamente en el iPhone y no entra en la capa de `BusinessWorkoutSyncStore`. Los permisos opcionales (sueño/ciclo + flags de decisión) se almacenan en `UserDefaults` local; la UI vive en **Ajustes → Apple Salud** (`ConnectedHealthSettingsView`). Las muestras se consultan en Apple Salud y se mantienen en memoria (hasta ~120 días de sueño). No añadir estos datos a `AppSettings`, al documento iCloud de entrenamientos ni al payload de Supabase. Las sesiones sí guardan sus ejercicios, bloques, series y resultados para el entrenador con consentimiento existente. En el espejo Supabase, `privateMirrorPayload` elimina toda referencia a Apple Salud, incluido `appleDurationSeconds`.

El campo histórico `supersetGroup` permanece en el formato Codable para abrir copias antiguas, pero se ignora al decodificar y no debe utilizarse para nuevas planificaciones.


### Plantillas favoritas independientes de la planificación (27/10/2026)

- `Routine` en `ReperaDomain/Models.swift` guarda `favoriteTemplateId: UUID?` **solo como vínculo opcional** del entrenamiento fechado a una plantilla sin fecha, compatible al decodificar ficheros previos sin esa clave. La fuente de verdad está en `ReperaStore.state.routines`, persistida por `LocalStore` / iCloud.
- `ReperaStore.setRoutineFavorite` clona el contenido prescrito con IDs propios antes de activar el favorito en el día. `saveRoutine` aplica las restricciones de Biblioteca Gratis; el rechazo nunca genera un estado de favorito falso. `favoriteRoutines` oculta la fila del día cuando existe una plantilla vinculada, evitando duplicados.
- **Play y prescripción inmutable al iniciar:** `SessionController.from(routine:)` crea `SessionExercise.plannedSets` desde las series guardadas, manteniendo distinto `targetReps`/`targetWeightKg` en cada índice. `ReperaStore.startSession` omite `ProgressionEngine.applySuggestions` si la rutina es favorita, está vinculada a una plantilla o tiene progresión `.off`. `assignRoutine(_:toDate:)` fija `.off` en copias programadas desde un favorito. En `WorkoutView.prefill` y `rebuildLiveSets` las prescripciones explícitas prevalecen sobre `cachedLastWorkingWeight` y demás valores históricos; no se autocompletan pesos intencionadamente sin configurar. Solo rutinas no favoritas con una política de progresión activa pueden recibir cálculos automáticos.

- `PlanView.DayEditorView` y `SessionPreviewView` gestionan el guardado y sus errores; `WorkoutView` conserva `activeSession.routineId` y registra la nueva plantilla en `favoriteRoutineId` para no perder la identidad del origen. `FavoritesHubView` permite reutilizar la plantilla mediante `assignRoutine(_:toDate:)` desde el calendario, manteniendo el inicio inmediato desde Crear general.
- El borrado del calendario respeta las plantillas vinculadas. Los favoritos fechados antiguos sin `favoriteTemplateId` siguen visibles y se tratan con la política histórica. **Validar en dispositivo** creación/edición, desconexión/iCloud, paywall y reutilización. Ver `docs/FEATURES.md` y tests de contrato.

### Navegación GPX y ActivityKit (27/10/2026)
- `LiveActivityRecorder` calcula giros del GPX y hace una única consulta `MKReverseGeocodingRequest` por giro (25 m después de la maniobra), con cancelación y descarte de respuestas de otra ruta. Si no devuelve una vía, la guía sigue siendo geométrica y no simula una ruta vial.
- `TrainingActivityAttributes.ContentState.NavigationCue` transporta únicamente flecha, instrucción, distancia y vía aproximada. `WorkoutLiveActivityCoordinator.updateFree` lo publica junto a duración, ritmo/velocidad y distancia; `TrainingLiveActivityWidget` lo visualiza en bloqueo e isla, sin transferir trazas GPX ni alterar el estado de planes indoor.

### Motor GPS único para Comenzar y Play (iOS 27)

**Referencia técnica, secuencia completa y matriz de validación:** [GPS_TRACKING.md](GPS_TRACKING.md).

- `WorkoutLocationTracker.shared` es el **único propietario del `CLLocationManager`** del iPhone en sesiones deportivas. «Comenzar» y «Play» reutilizan ese propietario por UUID de sesión; no se pueden superponer dos recorridos. La previsualización del pin también pasa por este servicio.
- `CLBackgroundActivitySession` se activa únicamente cuando hay una sesión outdoor autorizada y el bundle declara `UIBackgroundModes/location`. Las pausas liberan los servicios y cortan la continuidad GPS; al reanudar se empieza un segmento nuevo.
- Las muestras conservan marca temporal, coordenadas, velocidad, altitud y precisión real horizontal/vertical. El motor filtra lecturas imprecisas, saltos imposibles y jitter; no suma distancia entre huecos de más de 30 s. **Nunca reduce a 400 puntos** al guardar: la simplificación es exclusivamente visual.
- El motor publica el mismo total de metros a «Comenzar» (parciales, ritmo, mapa, ActivityKit) y «Play» (ruta, progreso outdoor y ActivityKit); los entrenamientos indoor mantienen sus contadores de series. Los snapshots GPS locales por UUID permiten recuperar puntos ya persistidos tras una interrupción, sin inventar datos ausentes.
- `HealthKitStore` mantiene `HKWorkoutBuilder` y `HKWorkoutRouteBuilder` por sesión; encola los `CLLocation` originales y los inserta progresivamente en Salud. Al guardar, solo finaliza/adjunta la ruta a un `HKWorkout` cuyo `ReperaSessionID` coincide exactamente. Ante permisos denegados, se conserva la ruta local y se reintenta sin duplicar entrenos. Los entrenos pertenecientes a Apple Watch se respetan como fuente de verdad.
- **Límites Apple**: iOS puede retrasar Live Activities, no garantiza recopilación cuando se fuerza el cierre y puede finalizar el proceso. No se reconstruye un recorrido durante un periodo sin ubicación. La recuperación de una sesión restaurada exige decisión expresa de reanudar.

### Audio de Comenzar y temporizadores (iOS 27, 27/10/2026)

- `Apps/Repera/Sources/RestFeedback.swift` es el único generador de pitidos para **Comenzar, Temporizador, descansos e intervalos**. Genera PCM WAV mono a 22.050 Hz en memoria y lo reproduce con `AVAudioPlayer`. No usa sonidos preinstalados del sistema.
- `tick` e `intervalBeep` usan un tono de **523,25 Hz (Do5)** de **0,16 s**. `restComplete` mantiene exactamente el mismo timbre y frecuencia durante **0,49 s**. Tanto el aviso a cero de la cuenta previa como el de finalizar actividad pasan por `restComplete` y respetan el booleano `sound`. Su duración anterior era 0,82 s y la frecuencia anterior 392 Hz; las pruebas comprueban estos nuevos valores.
- `LiveActivityRecorder.beginStartCountdown()` mantiene `idle` durante tres segundos y luego inicia GPS/HealthKit en `start()`. El selector persistente de voz se aplica a los tonos y a `AVSpeechSynthesizer`; **pausa y reanudación no anuncian nada**, mientras que cruces por kilómetro y giros sí pueden generar locuciones. Una sesión de reproducción de tonos no debe desactivar el audio del sintetizador en curso.
- **Pendiente:** ejecución de tests y compilación Xcode en macOS, escucha real en altavoz/Bluetooth y bloqueo, auditoría de interrupciones de `AVAudioSession` y comprobación visual de mapa/clima en dispositivo. El detalle paso a paso está en [GPS_TRACKING.md](GPS_TRACKING.md#pendiente-de-verificación-en-iphone--testflight-27102026).

### Cardio con GPS (solo iPhone)

`CardioRouteAnalysis` (ReperaDomain) recibe coordenadas/fechas y FC, filtra saltos GPS, calcula distancia con haversine e interpola los instantes de cruce de cada kilómetro. Devuelve perfil altimétrico y parciales únicamente para tramos válidos; no hace peticiones a red. `HealthKitStore.RoutePoint.altitudeMeters` y `WorkoutRoutePoint.altitudeMeters` son opcionales, preservan rutas antiguas y pueden provenir de GPS de Apple Salud o Core Location. `CardioRouteComponents` usa Swift Charts (selección x nativa, `catmullRom` + clip), selector Cardio/Altitud con tiles contextuales, parciales y `SessionMapWeatherCard`. WeatherKit **no se persiste**: se pide al abrir el detalle (`startedAt`/`finishedAt`, no `.distantPast`); requiere capacidad en App ID + entitlement; si falla → «—». El clima histórico muestra viento (km/h) en lugar de AQI, que no está disponible.

`BusinessWorkoutSyncStore.privateMirrorPayload` elimina `routePoints`, `locationPin` y datos de HealthKit antes de transmitir a Supabase. La posición inicial del recorrido se redondea a 2 decimales (~1 km) antes de consultar WeatherKit; nunca se envía el recorrido completo ni se comunica nada a Supabase.

### Diagnóstico CI de octubre de 2026

La configuración `.github/workflows/ios27-ci.yml` completó correctamente los cuatro jobs el 20-10-2026 a las 13:52 UTC (run 39434137818). En las ejecuciones posteriores los cuatro jobs, incluidos los basados en `ubuntu-latest`, han fallado antes del primer paso (`steps: null`), sin logs disponibles a través del conector. Esto es distinto de un error del compilador y requiere investigar GitHub Actions/runner facturación o límites de cuenta desde la interfaz administrativa. No desactivar los tests para forzar resultados verdes.


## Acceso IA mediante token personal (21/10/2026)

`athlete_workout_mirror` permanece como tabla física privada para que las versiones iOS actuales sigan funcionando con `upsert(id)`. `athlete_workouts` es una vista `security_invoker` para lectura deportiva filtrada. `training_exercise_catalog` es un alias de consulta de `business_exercise_catalog`. Las cinco tablas vacías del prototipo se retiraron con `RESTRICT`.

Los accesos manuales usan credenciales personales `rep_ai_…`, emitidas desde **Ajustes → Datos → Conecta tu IA**. La Edge Function `repera-ai-tokens` verifica la sesión Supabase del iPhone y crea tokens aleatorios de 256 bits: solo persiste SHA-256, metadatos y expiración, nunca el secreto original. La aplicación lo muestra una vez, con nombre, caducidad configurable (incluida ilimitada) y revocación posterior. `mcp_user_consents` se eliminó tras comprobar que estaba vacío. Los JWT OAuth no disponen de acceso directo al historial por Data API; el nuevo recorrido OAuth los valida exclusivamente en el MCP con audiencia y rol aislados.

La Edge Function `repera-mcp` verifica el hash de cada Bearer token antes de construir el servidor MCP; usa consultas filtradas por `owner_id` asociado al token. `service_role` es exclusivamente un secreto de servidor, nunca se expone al iPhone/agente. Los planes generados se validan contra el contrato de `RoutineBlock` (fuerza/WOD, series/RIR y formatos) y se escriben en la bandeja `ai_training_plans` del dueño. `AITrainingInboxStore` los incorpora al modelo nativo `Routine` en el iPhone, evitando reemplazar planes de fechas ocupadas; Inicio muestra el calendario y Diario tiene sección de entrenos por fecha. **No exportar HealthKit, GPS, peso o notas privadas.**

La integración requiere pruebas reales de MCP con PAT, Xcode/TestFlight, renovación/revocación de tokens, ejercicio libre y WOD completo. No considerar deploy activo como prueba E2E. Plan y criterios de aceptación: [MCP_PLAN.md](MCP_PLAN.md).


## Entrega de entrenamientos de IA por Realtime (21/10/2026)

`AITrainingInboxStore` es el receptor local-first de propuestas estructuradas creadas con el MCP. Su `startRealtime(store:)` usa el cliente Supabase Swift Realtime V2, un canal por sesión de usuario y un filtro Postgres Changes `InsertAction` por `owner_id`. La tabla `ai_training_plans` está en la publicación `supabase_realtime` y mantiene RLS (el usuario autenticado solo puede consultar sus propuestas); **no** se publican datos de Salud, tokens ni el espejo completo de entrenamientos. Se suscribe antes de hacer la lectura inicial para cubrir eventos concurrentes. Cuando llega una propuesta, se lee con SELECT autenticado y se transforma en `Routine` usando el mismo método `saveRoutine` de Diario/Inicio; las planificaciones locales del día quedan protegidas. `ReperaApp` inicia/detiene el canal al activar/suspender la escena, después del inicio de sesión y al cambiar de usuario. Un aviso flotante breve indica que se recibió un plan. Fuera del primer plano, la reconexión automática al regresar a primer plano recupera el historial pendiente: Realtime no es un sistema push APNs.


## Coach IA — perfil, calendario y programas (21/10/2026)

Además del espejo local-first de entrenamientos terminados, `AITrainingContextStore` sincroniza una fotografía reducida de las rutinas personales futuras/recurrentes a `athlete_training_calendar_snapshots` (hasta 90 días): nombre, fecha/weekday, bloques, identidades y prescripción deportiva. Nunca envía notas privadas, Salud, GPS ni el JSON completo de las rutinas; la app/iCloud sigue siendo la fuente de verdad. el MCP deduce hábitos desde el historial y recoge por chat las preferencias explícitamente confirmadas en `athlete_training_profiles` (sin formulario en iOS); `AITrainingProgramsView` lista los macrociclos de `athlete_training_programs` y permite activarlos o pausarlos.

El MCP despliega `coach.ts` con análisis semanal, calidad de datos, perfil, calendario, catálogo enriquecido, programas de 1–52 semanas y revisión por versión. `training_exercise_metadata` vincula el catálogo de negocio a los ID nativos de `CatalogEnrichment` sin inventar metadatos faltantes. Se permite emitir a Repera un máximo de 14 sesiones concretas por petición MCP; las propuestas quedan separadas de la definición del macrociclo y se importan al calendario sin sobrescribir rutinas existentes. Los tokens PAT, RLS y el filtro `owner_id` siguen protegiendo los datos individuales. Ver [MCP_PLAN.md](MCP_PLAN.md) para aceptación y límites.


## Catálogo muscular para MCP (21/10/2026)

Los 189 ejercicios del catálogo profesional han heredado de los cuatro catálogos Swift sus músculos y equipamiento; la migración SQL preserva la procedencia en `training_exercise_metadata.metadata_source`. 183 asignan grupos musculares principales, mientras seis actividades cardiovasculares intencionalmente solo asignan músculos secundarios. No se ha alterado ningún archivo de la app para este enriquecimiento.


## Apple profile/avatars y material de IA (21/10/2026)

Apple y Google pueden ser métodos de acceso a **la misma identidad Supabase**. `BusinessAuthStore` comprueba el UUID antes de reutilizar historial local y usa la sesión Supabase validada y copia únicamente nombre/avatar públicos a `profiles`, tras crear `avatar_url` y almacenamiento `profile-avatars` con rutas restringidas a `{auth.uid()}/avatar.jpg`. Nunca se comparten datos sanitarios. Las tareas concurrentes se esperan mediante tareas asíncronas automáticas; el botón manual de Cuenta se ha retirado. La vista de Centro no debe mostrar errores de identidad pública. `training_exercise_metadata.required_equipment` enumera requisitos del equipo y `joint_demands` describe cargas articulares orientativas, nunca compatibilidad clínica. El MCP pregunta por disponibilidad de material antes de ofrecer sustituciones. Los permisos de descanso y ciclo no son requeridos para completar HealthKit ni aparecen como pendientes por defecto.


## Escáner de pizarras + entregas AI (22/10/2026)

`BoardScanLiteParser` conserva sección Metcon/Weightlifting, For Time con cap global y tramos secuenciales, intervalos ON/OFF, descansos entre rondas, A/B alterno, series `Every 90s` y porcentajes de 1RM (incluyendo `>80%` como mínimo, no 80% exacto). `PlannedSet.targetPercent1RM` y `targetPercent1RMIsMinimum` son opcionales para mantener compatibilidad con rutinas anteriores y evitar inventar kilogramos. Cinco pruebas con las transcripciones de fotos externas protegen la estructura. Cuatro entradas nuevas de `CatalogGimnasia`/`CatalogCrossFit` se versionan también en Supabase para que IA y buscador utilicen la misma identidad.

Los programas IA se consultan en `PlanView` → Diario/Programado, junto a las sesiones de entrenadores. `SessionPreviewView` enlaza las filas que tienen un ID resoluble con `ExerciseDetailView`. En Cuenta, avatar Apple, nombre y correo comparten una única fila y el estado de sincronización es subtítulo del botón.


## Autoridad local para CRUD deportivo por IA (22/10/2026)

Las operaciones remotas `update_workout`, `delete_workout` y CRUD de ejercicios personalizados **no** escriben en `athlete_workout_mirror` ni cambian un historial iCloud por su cuenta. El MCP autentica al titular, valida cambios con esquema cerrado, comprueba existencia/versión del espejo y crea una solicitud pendiente. El iPhone consulta `ai_athlete_change_requests` con RLS propietaria y solo aplica tras confirmación explícita en Acceso IA. `AIChangeRequestStore` preserva campos privados, HealthKit y GPS en correcciones de series/título porque solo muta campos concretos sobre la sesión local existente. Los borrados se ejecutan con el mismo flujo que la eliminación manual, incluido el aviso de Salud. Ejercicios personalizados confirmados se espejan sin tocar los ejercicios curados globales. El calendario planificado mantiene fecha civil, zona IANA, desfase de horario de verano y, cuando hay hora concreta, instante UTC.



## Conexión guiada con asistentes (2026-10-24)

Última actualización: 2026-10-27 (navegación GPX en Comenzar y widget ActivityKit)

Se incorpora el soporte de OAuth gestionado por Supabase, consentimiento web y aislamiento de credenciales MCP, manteniendo los PAT manuales. La UI **Conecta tu IA** ofrece Claude con instrucciones copiables para añadir una conexión personalizada OAuth (sin tokens en el chat). ChatGPT permanece pendiente de su ficha publicada. La integración no está publicada por el hecho de integrar este código. Arquitectura, pruebas, despliegue y presentación a revisión: [OAUTH_CONNECTIONS.md](OAUTH_CONNECTIONS.md).


## Pantalla de lanzamiento con mascota (iOS 27)

La primera fase nativa usa `LaunchScreen.storyboard` con `UILaunchStoryboardName`, fondo verde `#30D158` y la nueva imagen `ReperaNativeOpaqueHero` **RGB sin canal alfa**, que integra la misma mascota levantando la barra y el mismo verde. La imagen opaca evita que el compositor de launch de iOS omita un PNG transparente. La ilustración muestra la misma mascota de Repera sosteniendo una barra con discos; los ojos y la boca son opacos. Para evitar la pantalla oscura o verde vacía procedente de snapshots nativos en caché, el primer fotograma de SwiftUI repite el personaje con `LaunchBarbellSplashView` y una copia en el bundle `ReperaStartupBarbell.png`, visible brevemente antes de `MascotRunning` y de la pantalla de Inicio. El `WindowGroup` mantiene un `ZStack` raíz estable mientras progresa el arranque, para que la hidratación de sesión no se reinicie al cambiar de mascota. El modo de pruebas UI omite el intro. La imagen del storyboard y la primera imagen SwiftUI utilizan el mismo recurso visual. Los storyboards obsoletos no forman parte del target generado. El CI comprueba que el nuevo storyboard y la mascota están dentro de la aplicación compilada.
