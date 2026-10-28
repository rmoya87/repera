# Bloqueadores que requieren a Ramón

**Última actualización:** 2026-10-28

Pasos exactos que **no** puede completar el agente (secretos / Console / deploy /
hardware). Decisiones de producto cerradas abajo.

## RP-4 — Play Billing

**Alineado (2026-10-28):** flujo Android = Play Billing directo + Edge
`repera-play-billing-verify` (paridad del modelo iOS StoreKit + verify). No es
un gap de código abierto. **Productos creados** en Play Console
(`com.app.repera.premium.monthly` / `.yearly`). Sigue pendiente ops: SA,
secret Edge, deploy verify, testers/SHA-1, smoke. Detalle:
`android/docs/MONETIZATION_PLAY_BILLING.md`.

## RP-6 — Eliminar mi cuenta

- **Código Android:** implementado (paridad iOS) → `AccountDeletionClient` +
  Ajustes → Edge `repera-delete-account`.
- **Pendiente Ramón:** confirmar deploy en Supabase de producción y E2E con
  cuenta Google de prueba.
- Health Connect / Play subscriptions se gestionan fuera de Repera (copy UI).

## E2E hardware (no sustituible por CI)

- OAuth Google + Drive multi-dispositivo (If-Match 412).
- Health Connect con app real + permisos.
- Cámara/galería pizarra.
- Wear físico (ACK series, plan hoy, WOD per-movement con reloj de bloque).

## CI GitHub Actions

Los jobs `android-native` fallan al arrancar si **Billing & plans** del org/cuenta
tiene pagos fallidos o el spending limit agotado (no es un fallo de código).
Hay que restablecer billing de Actions para que CI vuelva a ejecutar.

## Decisiones de producto

| Tema | Estado |
|------|--------|
| Clima en Comenzar (`weather_android`) | **`none`** — no se paga proveedor; clima **no** va en Android (WeatherKit es solo iOS; Open-Meteo descartado, 2026-10-28). |
| POI (`poi_provider`) | **Google Places solo si la cuota es gratis usable**; si no, mantener **`photon_geocoder`** (Photon + Geocoder en `PlaceSearchSheet`, estado actual). |
| Billing (`billing_aligned`) | **Alineado** — productos creados en Play Console; código cliente + Edge verify listos. Ops SA/deploy/testers abiertos. |
| Wear autonomía total | MVP fuerza+ACK; WOD sin reloj de bloque no registra (decisión mantenida). |
| Sync `App-android` → `main` (`app_android_main_sync`) | **Hecho (2026-10-28).** `origin/App-android` (`2110ae8d`, #125) es ancestro de `origin/main` (`7945ec1b` Merge branch App-android). Árbol `android/` idéntico; merges previos #119–#122/#124. |
