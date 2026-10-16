# Arquitectura Gymbro

Última actualización: 2026-10-17 (auditoría y guardas para carruseles)

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
| `Catalog*.swift` | Seed gym / CrossFit / halterofilia / gimnasia + ES; deporte en `sportTag`, grupo = músculo principal |
| `StatsEngine` | Series de progreso, PRs, métricas diarias, filtros `ProgressTimeRange` |
| `MuscleTaxonomy` / `MuscleMapEngine` | Carga muscular y mapa; `libraryMuscleGroup` para filtros |
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

- Estado: `AppState` Codable → fichero en contenedor iCloud Documents cuando hay cuenta.
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
| `ExerciseArt` / `ExerciseThumb` | Arte anatómico gris+lime sobre charcoal, torso descubierto. Prioridad `base_1…N` → `movementFrames` verificados (vacío temporalmente) → hero. Holds: hero; secuencias defectuosas: cuarentena. Captions de `CatalogSpanish`; thumbs 192px bajo `ExerciseArt/thumbs/`; auditoría con `scripts/audit_exercise_art.py` |
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
