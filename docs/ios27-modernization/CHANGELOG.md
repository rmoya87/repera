# CHANGELOG — Modernización iOS 27

Historial de implementaciones (G27 + J28). Rama activa: `fix/ios27-jank-search-reliability`.

## 2026-10-17 — J28 Fase C (fiabilidad + splash)

- Splash: `LaunchScreen` vuelve a mostrar `Splash.jpg` (fondo brand green); se revirtió el negro plano.
- J28-006/008: `persistAndFlush` + cola FIFO cloud recover/upload.
- J28-009/010: `WorkoutClockCoordinator` wall-clock; standalone intervals catch-up.
- J28-011/024: Live Activity generation; `RestLocalNotifier` al fin de descanso.
- J28-012…016/019/020: heatmap revision, HealthKit revision/filtros/overlap, Watch ACK, OCR off-main, CI fail-hard.
- J28-023: blocked (dispositivo físico).

## 2026-10-17 — J28 Fase B (buscador / thumbs) in_review

- J28-001/004: `ThumbMemoryCache` + ImageIO; prefetch ventana ≤20; max 4 workers; sin doble pasada; cancel al salir de Ejercicios.
- J28-002: `ExerciseSearch.Document` sin Exercise completo; índice/secciones en `Task.detached`; `.task(id:)` cancelable.
- J28-003: OSSignposter IndexBuild/SectionsBuild; no `disablesAnimations` en teclado.
- J28-005: Plan/QuickLog usan `ExerciseSearch.ranked`.
- J28-007: shell vacío + `Catalog.prewarm` (commit previo en rama).
- J28-023: blocked (dispositivo físico).
- Canvas: 25 tareas J28 en P5; generador admite P5.

## 2026-10-17 — Canvas inicial

- Creado `docs/ios27-modernization/` con `progress.json`, generador, `canvas.html`, README.
- HEAD alineado con base auditada `2536e7f`.
- 30 tareas G27-001…030 en estado `pending` (auditoría previa ≠ implementación).

## 2026-10-17 — P0 implementación (in_review)

### G27-001 / G27-002 — Persistencia e iCloud
- Bootstrap solo local; uploads remotos gated hasta recuperación.
- `AppStatePersistence` actor, coalescing, flush en background.
- `syncRevision` + `lastWriterDeviceId` + `SyncConflictResolver`.

### G27-003 / G27-004 — Temporizadores y descanso
- `WallClockTimer` + TimelineView.
- `RestSessionCoordinator` en `GymbroStore`; Live Activity sin updates/s.
- WOD: pre-countdown solo en el primer arranque.

### G27-005 / G27-006 — HealthKit
- Borrado centralizado e idempotente; ownership por bundle.
- `canReadWorkouts` / `canWriteWorkouts`; guard en `beginWorkout`.

### G27-007 — Watch
- `actionId` dedupe; context vs message; cola pendiente; logging.

Validaciones: `swift test` (conflict+timer), `xcodebuild` Gymbro + GymbroWatch (iPhone 17e / Watch Series 12).
QA multi-dispositivo / Watch físico: **bloqueada**.

## 2026-10-17 — P1 rendimiento (in_review)

### G27-008 — Concurrency
- Cancelación real de prepare charts; Rest LA en MainActor; loader actor.

### G27-009/010 — Ilustraciones
- Manifiesto JPG; `ThumbImageLoader` con límite, dedupe y LRU.

### G27-011/012 — Stats
- `DerivedStatsCache` + tests golden; cancel de Task al cambiar periodo.

### G27-013/014 — Salud / arranque
- Freshness + invalidate; prefetch diferido; sin prompt HK en cold launch.

## 2026-10-17 — P2–P4 (in_review)

- Navegación: gesto volver en rutas anidadas del flujo de sesión.
- swipeActionsContainer + reorderable/reorderContainer (SDK iOS 27).
- Steppers sin highPriority Drag; PhotosPicker; zoom biblioteca; sensoryFeedback.
- Watch Digital Crown + reachability.
- UITests target, CI workflow, ADRs, METRICS template, art boundary ADR.
