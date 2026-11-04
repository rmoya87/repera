# Analytics A+B Implementation Plan

> **For agentic workers:** Implement task-by-task. Steps use checkbox syntax.

**Goal:** Activar métricas estilo Cafesito (sin UI consent) + instrumentar entrenamientos confirmados con dedup.

**Architecture:** Fachada `ReperaAnalytics` tipada; emisión tras persistencia en `ReperaStore` / `WorkoutRepository`; contrato `analytics/contract.json`.

**Tech Stack:** SwiftUI/FirebaseAnalyticsCore, Kotlin/Firebase Analytics BoM, pytest contrato.

## Global Constraints

- iOS 26+ / watchOS 26+; sin Firebase en relojes.
- Sin `GoogleService-Info.plist` / `google-services.json` inventados.
- Responder docs en español; código en inglés.
- No PII/salud/GPS en eventos.

---

### Task 1: Contrato + fachada

- [ ] Añadir `workout_type` y `activity_family` enums al contrato
- [ ] Reescribir configure/track/trackOnce iOS + Android (Cafesito)
- [ ] Quitar UI consentimiento Ajustes
- [ ] Tests contrato actualizados

### Task 2: Instrumentación persistencia

- [ ] iOS ReperaStore ganchos
- [ ] Android WorkoutRepository ganchos
- [ ] activity_family helper compartido por plataforma

### Task 3: Docs + verify

- [ ] FIREBASE_SETUP.md, PRIVACY.md, matriz mínima, plan status
- [ ] pytest + revisión CI local disponible
