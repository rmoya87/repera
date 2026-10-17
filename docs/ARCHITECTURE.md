# Arquitectura Gymbro

Última actualización: 2026-10-17 (Progreso: ProgressDataEngine + ViewModel cache)

## Visión

App **local-first**: el estado vive en el dispositivo (JSON) y se sincroniza con **iCloud Documents**. El dominio puro está en el paquete `GymbroDomain` (testeable sin UI). La app iOS añade Salud, Vision, Foundation Models y Watch Connectivity.

## Estructura del repo

```
gymbro/
├── Apps/
│   ├── Gymbro/                 # Target iPhone (SwiftUI)
│   │   ├── Sources/            # UI + stores de plataforma
│   │   └── Resources/          # Assets, Info.plist, BodyPaths.json, ExerciseArt (JPG 1024 + thumbs/192)
│   ├── GymbroWatch/            # Companion Watch
│   ├── GymbroRestWidget/       # Live Activity (descanso)
│   └── Shared/                 # RestActivityAttributes (app + widget)
├── Packages/
│   └── GymbroDomain/           # Modelos + motores (sin UIKit)
├── docs/                       # Documentación viva
├── project.yml                 # XcodeGen
├── AGENTS.md
└── README.md
```

## Targets

| Target | Rol |
|--------|-----|
| **Gymbro** | App iOS 27+. Tabs, sesión, Salud, OCR/IA pizarra, Live Activity host |
| **GymbroRestWidget** | Widget Extension: Dynamic Island / lock screen del descanso |
| **GymbroWatch** | Sesión + log rápido vía Watch Connectivity |
| **GymbroDomain** (SPM) | Modelos, catálogo, stats, progresión, parser, LoadSuggestion |

Generación de proyecto: `xcodegen generate` → `Gymbro.xcodeproj`.

## Capas

```
┌─────────────────────────────────────────┐
│  SwiftUI (Home, Plan, Stats, Library…)  │
├─────────────────────────────────────────┤
│  GymbroStore · HealthKitStore · LocalStore │
├─────────────────────────────────────────┤
│  GymbroDomain (Models, StatsEngine, …)  │
└─────────────────────────────────────────┘
```

### `GymbroStore` (`Apps/Gymbro/Sources/GymbroStore.swift`)

Fuente de verdad de la UI: ejercicios, rutinas, sesiones, peso corporal, favoritos, sesión activa. Persiste vía `LocalStore` / iCloud.

- Peso corporal: **un entry por día** (`dedupeBodyWeightsByDay` / `syncBodyWeightWithHealth`).
- Quick log: `startQuickLog` / `logQuickSets`.
- Borrado de entreno: limpia estado local y, si hay UUID, HealthKit.

### `HealthKitStore`

Lectura/escritura Salud: peso, energía activa, workouts externos, FC, rutas. Alimenta Progreso con **caché diaria** de FC/kcal (hasta 360d); la UI promedia a semana/mes solo al pintar. Sync de peso: 1 muestra/día.

### `GymbroDomain` — piezas clave

| Módulo | Responsabilidad |
|--------|-----------------|
| `Models.swift` | `Exercise`, `Routine`, `RoutineBlock`, `WODMovement`, `WorkoutSession`, `AppState`… |
| `Catalog*.swift` | Seed gym / CrossFit / halterofilia / gimnasia + ES (`CatalogSpanish` 188/188: desc + guía entrenador); deporte en `sportTag`, grupo = músculo principal |
| `StatsEngine` | Series de progreso, PRs, métricas diarias, filtros `ProgressTimeRange` |
| `MuscleTaxonomy` / `MuscleMapEngine` | Carga muscular y mapa; primario 1.0 / secundarios ~0.55–0.35; `libraryMuscleGroup` para filtros |
| `BoardImportParser` | OCR texto → bloques WOD (reglas) |
| `SessionController` | Ciclo de vida de la sesión |
| `ProgressionEngine` | Off / lineal / doble / Greyskull / triple |
| `PlateMath` | 1RM Epley (`epleyOneRM`); preferencia `testedOneRMKg` por ejercicio |
| `LoadSuggestion` | `%` de 1RM (tested o e1RM) → kg (pizarra / ficha) |
| `ExerciseSubstitutes` | Alternativas mismo músculo (dominio; UI de cambio no expuesta) |
| `ProgressTimeRange` | Periodos de Progreso |

## Navegación (tabs)

`RootTabView`: **Inicio · Diario · Crear · Progreso · Ejercicios**.

- Flujo de entreno: overlay `NavigationStack` (`sessionPreview` → `workout`).
- Tab bar: `minimize` solo con sesión activa; accessory **Continuar**.

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

- Estado: `AppState` Codable → JSON local (`Application Support/Gymbro`) + espejo iCloud Documents.
- Bootstrap: `GymbroStore` arranca con shell vacío (sin disco ni `Catalog.seed` en `init`). Tras el primer frame: hydrate disco → `Catalog.prewarm()` off-main → merges → iCloud. LaunchScreen muestra `Splash.jpg` (~170KB) a pantalla completa sobre fondo brand green. Poll iCloud corto + reintento en background.
- Conflictos: `syncRevision` + `lastWriterDeviceId` (`SyncConflictResolver`); fallback a `updatedAt` para docs legacy.
- I/O: actor `AppStatePersistence` (encode/write atómicos, coalescing); fachada `LocalStore` en MainActor.
- Fases: `AppSyncPhase` (`loadingLocal` → `awaitingRemote` → `ready` / `offline` / `recoveringCorrupt`).
- Canvas de modernización: `docs/ios27-modernization/`.
- Thumbs: `ThumbImageLoader` (concurrencia 4, LRU, manifiesto JPG).
- Stats: `DerivedStatsCache` invalidado con `syncRevision`.
- Progreso: `ProgressViewModel` + `ProgressDataEngine` preparan un `ProgressSnapshot` off-MainActor (tiles, charts, heatmap, músculo, PRs, peso); caché por `ProgressDataKey` (periodo + revisiones). `StatsView` pinta `LazyVStack` con datos listos.
- Salud: frescura `healthCacheFetchedAt` + invalidate al borrar; match Gymbro↔HK con `GymbroSessionMatchIndex`; refrescos serializados por generación (sin sobrescribir 370d con 180d).

- Export / import JSON; import CSV Strong/Hevy (`WorkoutCSVImporter`).

## Plataforma específica (solo app)

| Archivo | Uso |
|---------|-----|
| `BoardTextRecognizer` | Vision OCR |
| `BoardAIImporter` | Foundation Models (Apple Intelligence) |
| `BoardImportPipeline` | Local primero (skip IA si ≥2 bloques) → IA → fallback |
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
cd Packages/GymbroDomain && swift test
```

Incluye `BoardImportParserTests`, `LoadSuggestionTests`, sesión, progresión, waves.

Guía manual: [TESTING_GUIDE.md](TESTING_GUIDE.md).

## No vive aquí

- Backend / auth multi-usuario
- Android
- Coach / LLM en la nube (Foundation Models solo pizarra on-device)

## Auditoría de ilustraciones de ejercicios (2026-10-17)

- `ExerciseArt.imageName(forExerciseName:muscleGroup:)` solo devuelve un hero cuando hay asignación exacta en `nameMap`: nunca emplea una foto ajena como fallback por músculo.
- `imageNames(for:)` prioriza pasos propios `_1…_8`, después `movementFrames` verificados y por último un hero. La lista de candidaturas no habilita por sí misma un fallback.
- El conjunto `quarantinedSequences` bloquea carruseles con fallos comprobados visualmente: la ficha conserva el hero y el texto técnico mientras se regenera el material, aunque el hero también requiere QA independiente.
- Los holds estáticos se fuerzan a un único hero. Los N primeros textos de `CatalogSpanish.instructions` son captions de fase; si hay menos de N, se retira el carrusel y queda solo el hero. Los pasos siguientes son coaching («Cómo hacerlo») y no cuentan para ese chequeo.
- `scripts/export_generated_art.py` escribe full JPEG 1024×1024 y thumb JPEG 192×192 bajo `Apps/Gymbro/Resources/ExerciseArt/`; no hace falta registrar cada recurso por separado en `project.yml`.
- `scripts/audit_exercise_art.py` con Pillow valida JPEG, medidas, pares full/thumb, referencia desde `nameMap` y N captions. `docs/EXERCISE_ART_AUDIT.csv` recopila por stem los defectos confirmados y lo que continúa pendiente de inspección visual.

El auditor estructural **no puede aprobar** similitud del personaje, ejecución anatómica, lateralidad, sombra, equipo y activación muscular sin revisión visual. No publicar una secuencia en cuarentena hasta generar y exportar todos sus frames y miniaturas, comprobarlos visualmente y retirar su entrada de cuarentena.
