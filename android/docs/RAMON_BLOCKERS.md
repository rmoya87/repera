# Bloqueadores que requieren a Ramón

**Última actualización:** 2026-10-28

Pasos exactos que **no** puede completar el agente (secretos / Console / deploy /
hardware). Decisiones de producto cerradas abajo.

## RP-4 — Play Billing

**Alineado (2026-10-28):** flujo Android = Play Billing directo + Edge
`repera-play-billing-verify` (paridad del modelo iOS StoreKit + verify). No es
un gap de código abierto. Detalle operativo: `android/docs/MONETIZATION_PLAY_BILLING.md`.

## RP-18 — Ownership / migrate / deploy Play

**Política cerrada (2026-10-28):** borrado + recuperación Pro = paridad Apple
(hard delete Auth; Pro vía compra Play / cuenta Google, reclaim tras
`ON DELETE SET NULL`). Código de ownership rediseñado en PR sucesor de #123.

**Sigue bloqueando ops (agente no aplica):**
1. Aplicar migración `play_subscription_ownership` en producción.
2. Desplegar Edge `repera-play-billing-verify`.
3. Activar productos Play (siguen en borrador).
4. E2E delete/restore solo con **identidad desechable** (no cuenta real).

## RP-6 — Eliminar mi cuenta

- **Código Android:** implementado (paridad iOS) → `AccountDeletionClient` +
  Ajustes → Edge `repera-delete-account`.
- **Pendiente Ramón:** confirmar deploy en Supabase de producción y E2E con
  cuenta Google de **prueba desechable** (no la cuenta real del propietario).
- Health Connect / Play subscriptions se gestionan fuera de Repera (copy UI).
- Tras recreate, Pro Play debe volver por query+verify (misma política Apple).

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
| Clima en Comenzar | **No se hace en Android.** iOS usa WeatherKit; no hay Open-Meteo ni otro proveedor en Android (decisión 2026-10-28). |
| POI | Photon + Geocoder ya en app (`PlaceSearchSheet`); calidad vs Places de pago. |
| Wear autonomía total | MVP fuerza+ACK; WOD sin reloj de bloque no registra (decisión mantenida). |
| Fusión `App-android` → `main` | Hecha (2026-10-28): #121/#122 en ambas líneas. |
