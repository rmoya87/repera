# ADR 002 — Temporizadores y descanso

**Estado:** aceptado · **Fecha:** 2026-10-17

## Decisión
- Fuente de verdad: fechas límite wall-clock (`WallClockTimer`, `ContinuousClock` vía `Task.sleep`).
- UI: `TimelineView` (no decrementar ticks como verdad).
- Descanso de sesión: `RestSessionCoordinator` en `GymbroStore` (sobrevive a `WorkoutView.onDisappear`).
- Live Activity: `endDate` fijo al iniciar; sin `update` cada segundo.
- Live Activity coordinator en `@MainActor` (no `nonisolated(unsafe)`).

## APIs
- [TimelineView](https://developer.apple.com/documentation/swiftui/timelineview)
- [ActivityKit](https://developer.apple.com/documentation/activitykit)
