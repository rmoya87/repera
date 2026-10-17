# ADR 005 — HealthKit y Apple Watch

**Estado:** aceptado · **Fecha:** 2026-10-17

## Decisión
- Separar `canWriteWorkouts` / `canReadWorkouts`; no interpretar lista vacía como denegado.
- Delete HK solo samples del bundle propio; idempotente si ausente.
- Caché Salud con `healthCacheFetchedAt` + invalidate al borrar.
- Watch: `actionId` dedupe; estado vía application context; acciones vía message + cola.
- Watch UI: Digital Crown para reps; indicador de reachability; sin afirmar independencia total del iPhone (`WKRunsIndependentlyOfCompanionApp: false`).
