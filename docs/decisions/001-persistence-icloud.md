# ADR 001 — Persistencia e iCloud

**Estado:** aceptado · **Fecha:** 2026-10-17

## Contexto
`bootstrap()` persistía a iCloud antes de completar la descarga remota, pudiendo sobrescribir backups con seed.

## Decisión
- Carga inicial **solo local** (`loadLocalOnly`).
- Uploads remotos gated hasta `recoverFromiCloud`.
- Conflictos: `syncRevision` + `lastWriterDeviceId` (`SyncConflictResolver`), fallback `updatedAt`.
- I/O en actor `AppStatePersistence`; fachada `LocalStore` en MainActor.
- Sin migrar a SwiftData/CloudKit en esta fase.

## Consecuencias
- Reinstalación segura si el stub iCloud aún no está listo.
- QA multi-dispositivo sigue siendo manual.
