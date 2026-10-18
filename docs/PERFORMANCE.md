# Rendimiento (iOS 27)

Última actualización: 2026-10-18 (Gymbro workouts en primer paint como Salud)

Prácticas nativas aplicadas para fluidez (listas, Inicio, sesión, Salud) y arranque.

## Cold start

- `LaunchWarmup.start()` en `GymbroApp.init`: en paralelo precalienta `Catalog`, `HealthDiskCache` y `app_state.json`.
- **Gymbro workouts** y **Salud**: ambos en el primer frame — `GymbroStore.init` usa `LaunchWarmup.appStateForFirstPaint()` (sync/`warm` de `app_state.json`), igual que `HealthKitStore` con `HealthDiskCache`.
- `hydrateFromDisk` confirma (caché caliente, sin segundo decode lento); seed/enrich **off-MainActor**; iCloud después.
- Home pinta buckets Gymbro al instante si hubo diskPaint; `onChange(isHydrated)` por si el shell iba vacío.
- Consola: filtro `subsystem:app.gymbroapp.ios category:Launch`.

## Observation + sync

- `GymbroStore` expone epochs (`catalogEpoch`, `workoutsEpoch`, `sessionEpoch`) además de `AppState.syncRevision`.
- Biblioteca → `catalogEpoch`; Historial / Home buckets → `workoutsEpoch` + `healthDataRevision`.
- `persist(touchWorkouts:)` solo en cambios de la lista de entrenos terminados — **loguear series no rebuilda Inicio**.
- Tras `touchWorkouts`: `invalidateExternalActivityFilter` (mantiene arrays) + refresh Salud coalescido con el nuevo filtro de exclusión.

## Stats fuera del body

- `DerivedStatsCache` (historial, última sesión, peso, PRs) invalidado con `syncRevision`.
- Acceso vía `GymbroStore.cachedHistory` / `cachedLastWorkingSession` / `cachedPersonalRecordCountsBySession`.
- Historial: mapa sesión→PRs en **un pase cronológico** (`StatsEngine.personalRecordCountsBySessionId`), no O(n²) por fila.

## Thumbs

- `ThumbImageLoader`: ImageIO, concurrencia 4, LRU, manifiesto JPG (sin `fileExists` en hot path).
- Prefetch de ventana visible; accessory Continuar solo lee caché / carga lazy con modelo Equatable mínimo.

## Buscadores

- Filas ligeras (`id` + strings); índice alfabético off-main; debounce ~140 ms.
- `ExerciseSearch.normalize` sin regex; tokens de músculo en `Set`.

## Home + Salud

- Home: buckets + semana en el primer paint; racha/PRs y `refreshAuthorizationStatus` en **utility** (no bloquean Inicio).
- **Cambiar de día no dispara HealthKit** (solo buckets + refine opcional de Hoy).
- Tras hydrate: `refreshToday` en el camino corto; ventana Salud 180d en `Task.utility` (no await en el launch task).
- Cards con chips: swipe UIKit (`transform` + pan); `UIScrollView` desactivado durante el pan; no se recrea el hosting a mitad del gesto (evita temblor).
- `HealthDiskCache`: hydrate síncrono en `HealthKitStore.init` para pintar Inicio al instante.
- Filter key = digest estable corto (`healthFilterKey`); refrescos Home/Progreso **coalescidos** a `max(days)`.

## Sesión / chrome

- Reloj WOD: `TimelineView` solo lectura (`displaySeconds(at:)`); catch-up de intervalos en `feedbackTask`.
- Tab / Inicio observan `hasActiveSession` + `continueAccessory` (Equatable), no el grafo completo de `activeSession`.
- Watch: `updateApplicationContext` con debounce ~280 ms al loguear series; flush inmediato en start/end/inbound Watch.

## Qué no tocar

- Ranking off-main del catálogo, Progressive Health + anclas HK, Progress snapshot off-main, launch shell.
