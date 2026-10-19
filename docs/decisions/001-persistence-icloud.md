# ADR 001 — Persistencia e iCloud

**Estado:** aceptado · **Fecha:** 2026-10-17 · **Última actualización:** 2026-10-17

## Contexto
`bootstrap()` persistía a iCloud antes de completar la descarga remota, pudiendo sobrescribir backups con seed.

## Decisión
- Carga inicial **solo local** (`loadLocalOnly`).
- Uploads remotos gated hasta `recoverFromiCloud`.
- Conflictos: `syncRevision` + `lastWriterDeviceId` (`SyncConflictResolver`), fallback `updatedAt`.
- I/O en actor `AppStatePersistence`; fachada `LocalStore` en MainActor.
- Arranque rápido: `ReperaStore` con shell vacío (sin disco/`Catalog.seed` en `init`); hydrate + `Catalog.prewarm()` off-main tras el primer frame; LaunchScreen con `Splash.jpg` (~170KB); poll iCloud corto + reintento en background; URL Documents cacheada; JSON compacto.
- Sin migrar a SwiftData/CloudKit en esta fase.

## Consecuencias
- Reinstalación segura si el stub iCloud aún no está listo.
- La UI no espera la descarga completa de iCloud para salir del LaunchScreen.
- QA multi-dispositivo sigue siendo manual.
