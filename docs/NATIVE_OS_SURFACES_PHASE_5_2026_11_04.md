# Superficies nativas del SO — fase 5 (4 nov 2026)

Última actualización: 2026-11-04.

Complementa `NATIVE_SYSTEM_INTEGRATION_2026_11_04.md` (fases 1–4). Distinguir **implementado / compilado / CI / hardware / backend**.

## Implementado en código

| Superficie | Qué hace | Límites |
|---|---|---|
| **Share Extension iOS** (`ReperaShare`) + document types | Copia GPX / foto de pizarra al App Group `group.com.app.repera`; abre `repera://import`. La app hidratada parsea GPX (`LiveRoutesStore`) o abre OCR. | Extensión **no** OCR / Health / GPS |
| **Android SEND/VIEW** | Intent filters GPX + `image/*`; `SystemShareImport` → cache → rutas `en-vivo` / `escaner` | Sin sensores desde el intent |
| **Now Playing iOS** | `RestRemoteCommandCenter` + `MPRemoteCommandCenter` en descanso (pause/resume/skip) | Solo timer UI |
| **MediaSession Android** | `RestMediaSessionController` en `StrengthRestService` | Solo skip/countdown |
| **Live Activity push tokens** | `Activity.request(…, pushType: .token)` + `LiveActivityPushTokenStore` | **Push remoto / push-to-start APNs** pendiente de backend + entitlement |
| **Focus Filter** | `ReperaFocusFilterIntent` silencia tab Center | Preferencia local |
| **EventKit / CalendarContract** | Mirror opcional de reservas `booked` | Write-only; permiso usuario |
| **Control Widget + Atajo «Escanear pizarra»** | `ReperaBoardScanControl` / `ReperaBoardScanIntent` → `repera://board` | No Camera Control hardware dedicado |
| **Assistant / Gemini** | Capacidades shortcuts + `ReperaAppFunctions` catalog; App Functions API cuando estabilice | Navegación only |
| **Wear tile** | Continuar + hint Descanso en sesión activa; OngoingActivity ya existía | Hint vía prefs `restHint` |
| **Watch complications / Smart Stack** | Snapshot con `restRemainingSeconds` / `nextBookingLabel` | Hablar al hub para rellenar booking/rest |

## Pendiente externo

- Desplegar push ActivityKit (APNs + Edge) para updates / push-to-start sin abrir app.
- Validar Share Extension y MediaSession en dispositivo real.
- App Group `group.com.app.repera` en Apple Developer + provisioning.
- App Functions (`androidx.appfunctions`) cuando el target lo fije el proyecto.
- ~~Consumir `pendingGpxPath` / `pendingBoardPath`~~ → `SystemImportPending` + LaunchedEffect en En vivo / Escáner.
- ~~Rellenar `restHint` / `nextBookingLabel`~~ → Wear `publishRestHint()`; Watch `publishComplicationSnapshot` con descanso + plan de hoy (no reservas Center remotas en Watch aún).

## Seguridad

- Extensiones y intents: solo bytes + navegación.
- Calendario: write-only / notas con id de booking; clear al logout.
- Tokens ActivityKit en UserDefaults locales hasta exista canal push autenticado.
