# Bloqueadores que requieren a Ramón

**Última actualización:** 2026-10-28

Pasos exactos que **no** puede completar el agente (secretos / Console / deploy).
El código de cliente y el scaffold Edge ya están en repo.

## RP-4 — Play Billing (Pro real en producción)

1. **Play Console — productos**
   - App: `com.app.repera`
   - Suscripciones:
     - `com.app.repera.premium.monthly` → **5,99 EUR**/mes
     - `com.app.repera.premium.yearly` → **39,99 EUR**/año
   - Configurar trial si se confirma (pendiente de decisión).
   - Licencia tester + builds firmados con el SHA-1 de release en OAuth/Play.

2. **Google Cloud — service account**
   - Proyecto con **Google Play Developer API** habilitada.
   - Cuenta de servicio + clave JSON (solo backend).
   - Play Console → Usuarios y permisos: invitar la SA a la app Repera con
     **View financial data…** y **Manage orders and subscriptions**.

3. **Supabase secrets + deploy Edge**
   - Secret: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` = contenido del JSON de la SA.
   - Desplegar `supabase/functions/repera-play-billing-verify/` (scaffold en repo).
   - Sin esto la app deja compras en `UNKNOWN` / no concede Pro (correcto).

4. **Opcional:** Real-time Developer Notifications (Pub/Sub) para renovaciones.

Detalle: `android/docs/MONETIZATION_PLAY_BILLING.md`.

## RP-6 — Eliminar mi cuenta

- **Código Android:** implementado (paridad iOS) → `AccountDeletionClient` +
  Ajustes → Edge `repera-delete-account` (traído de `main`).
- **Pendiente Ramón:** confirmar que la función está desplegada en el proyecto
  Supabase de producción y probar E2E con una cuenta Google de prueba.
- Health Connect / Play subscriptions se gestionan fuera de Repera (copy UI).

## E2E hardware (no sustituible por CI)

- OAuth Google + Drive multi-dispositivo (If-Match 412).
- Health Connect con app real + permisos.
- Cámara/galería pizarra.
- Wear físico (ACK series, plan hoy, WOD per-movement con reloj de bloque).

## Decisiones de producto abiertas

| Tema | Nota |
|------|------|
| Clima en Comenzar | iOS WeatherKit; Android **sin** proveedor en repo. Candidato gratis: Open-Meteo (no cableado; requiere OK explícito). |
| POI | Photon + Geocoder ya en app (`PlaceSearchSheet`); calidad vs Places de pago. |
| Wear autonomía total | MVP fuerza+ACK; WOD sin reloj de bloque no registra (decisión mantenida). |
| Fusión `App-android` → `main` | Cuándo mergear y actualizar docs raíz. |
