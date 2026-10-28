# Bloqueadores que requieren a Ramón

**Última actualización:** 2026-10-28

Pasos exactos que **no** puede completar el agente (secretos / Console / deploy /
hardware). Decisiones de producto cerradas abajo.

## RP-4 — Play Billing

**Modelo alineado (2026-10-28):** Android = Play Billing directo + Edge
`repera-play-billing-verify` (paridad del modelo iOS StoreKit + verify). Detalle:
`android/docs/MONETIZATION_PLAY_BILLING.md`.

**Estado ops (unlock 2026-10-28) — no tratar como “listo para prod”:**

- Productos Play creados en **borrador**; **no activar** aún. Trial: **none**.
- Secret SA presente (según unlock); Edge **`repera-play-billing-verify` no
  desplegado** hasta migrate+deploy explícito.
- Ownership Apple-parity aterrizado en `main` vía [#131](https://github.com/rmoya87/repera/pull/131)
  (sucesor del draft [#123](https://github.com/rmoya87/repera/pull/123), cerrado
  como superseded). Código listo; **migrate/deploy** siguen ops.

## RP-18 — Ownership / recuperación Pro tras delete

**Política cerrada (Ramón, 2026-10-28):** igualar Apple/iOS — hard delete Auth;
Pro se restaura vía compra Play / cuenta Google (como StoreKit ↔ Apple ID).
`obfuscatedAccountId = SHA256(UUID)` solo correlación Console; tras
`ON DELETE SET NULL`, `claim_play_subscription` **reclaim** al nuevo UUID si el
token Play sigue válido.

**Sigue bloqueando ops (agente no aplica sin acceso/secretos):**
1. Aplicar migración `play_subscription_ownership` en producción
   (`supabase/migrations/20261028173000_play_subscription_ownership.sql`).
2. Desplegar Edge `repera-play-billing-verify` (proyecto `uvzgujlrqohreoucirms`).
3. Activar productos Play (siguen en borrador).
4. E2E delete/restore solo con **identidad desechable** (no cuenta real).

## RP-6 — Eliminar mi cuenta

- **Código Android:** implementado (paridad iOS) → `AccountDeletionClient` +
  Ajustes → Edge `repera-delete-account`.
- **Pendiente Ramón:** E2E con **identidad desechable** (no la cuenta real).
  Coordinar con RP-18 si hay compras.
- Health Connect / Play subscriptions se gestionan fuera de Repera (copy UI).
- Tras recreate, Pro Play debe volver por query+verify (misma política Apple).

## E2E hardware (no sustituible por CI)

- OAuth Google + Drive multi-dispositivo (If-Match 412).
- Health Connect con app real + permisos.
- Cámara/galería pizarra.
- Wear físico (ACK series, plan hoy, WOD per-movement con reloj de bloque).
- Xiaomi: OAuth, Drive, HC, cámara (RP-22).

## CI GitHub Actions

Los jobs `android-native` fallan al arrancar (~2–4 s) si **Billing & plans** del
org/cuenta tiene pagos fallidos o spending limit agotado (no es fallo de código).
Hay que restablecer billing de Actions para que CI vuelva a ejecutar.

## Decisiones de producto

| Tema | Estado |
|------|--------|
| Clima en Comenzar (`weather_android`) | **`none`** — no se paga proveedor; clima **no** va en Android (WeatherKit es solo iOS; Open-Meteo descartado, 2026-10-28). |
| POI (`poi_provider`) | **Google Places solo si la cuota es gratis usable**; si no, mantener **`photon_geocoder`** (Photon + Geocoder en `PlaceSearchSheet`, estado actual). |
| Billing (`billing_aligned`) | **Alineado** — productos creados en Play Console (borrador); código cliente + Edge verify + ownership Apple-parity en `main`. Ops SA/migrate/deploy/testers/activar abiertos. |
| Play trial | **Ninguno** (2026-10-28). Gratis → Pro mensual/anual. |
| Sync `App-android` → `main` (`app_android_main_sync`) | **Hecho (2026-10-28).** Línea Android en `main` (merge `App-android` + PRs #119–#125/#127/#129). |
| Wear autonomía total | MVP fuerza+ACK; WOD sin reloj de bloque no registra (decisión mantenida). |
