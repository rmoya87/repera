# CHANGELOG — Modernización iOS 27

Historial de implementaciones en `feat/ios27-native-performance-audit`.

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
