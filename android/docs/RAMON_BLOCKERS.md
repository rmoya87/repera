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
- Secret SA presente; Edge **`repera-play-billing-verify` no desplegado**.
- Draft de seguridad [#123](https://github.com/rmoya87/repera/pull/123)
  (ownership, ON_HOLD, ack backend). **No mergear / no migrar / no desplegar**
  hasta RP-18. Revisión: ver informe del Project `docs/pr123-billing-review.md`
  (store) cuando esté publicado en el hilo del coordinador.

## RP-18 — Recuperación Pro tras borrar/recrear cuenta

**Política fijada (Ramón, 2026-10-28):** igualar Apple/iOS en este repo — no
inventar otra. `repera-delete-account` hace hard delete de auth y **no** toca la
suscripción de tienda; en iOS Pro se restaura con StoreKit/`AppStore.sync` +
`Transaction.currentEntitlements` del **Apple ID** (no del UUID Supabase). Android
debe permitir el mismo camino vía Google Play (restore + verify) tras
delete+recreate.

**Bloqueante antes de aplicar** la migración de ownership de [#123](https://github.com/rmoya87/repera/pull/123)
o desplegar el verificador: el draft ata `SHA256(UUID)` + `ON DELETE SET NULL` y
**rompe** esa paridad. Hay que rediseñar ownership/rebind antes de migrate/deploy.
Detalle: informe Project `docs/pr123-billing-review.md`. E2E delete solo con
**identidad desechable** (no la cuenta real).

## RP-6 — Eliminar mi cuenta

- **Código Android:** implementado (paridad iOS) → `AccountDeletionClient` +
  Ajustes → Edge `repera-delete-account`.
- **Pendiente Ramón:** confirmar deploy en Supabase de producción y E2E con
  **identidad desechable** (no cuenta real). Coordinar con RP-18 si hay compras.
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
| Clima en Comenzar | **No se hace en Android.** iOS usa WeatherKit; no hay Open-Meteo ni otro proveedor en Android (decisión 2026-10-28). |
| POI | Photon + Geocoder ya en app (`PlaceSearchSheet`); Google Places solo si cuota free usable — hoy no integrado. |
| Play trial | **Ninguno** (2026-10-28). Gratis → Pro mensual/anual. |
| Play productos | Borrador en Console; **sin activar** hasta verify+ownership+recovery. |
| Recuperación tras delete | **Abierta (RP-18)** — bloquea migrate/deploy de #123. |
| Wear autonomía total | MVP fuerza+ACK; WOD sin reloj de bloque no registra (decisión mantenida). |
| Fusión `App-android` → `main` | Hecha (2026-10-28): línea Android en `main`. |
