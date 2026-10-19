# Monetización — Repera Gratis / Repera Pro

Última actualización: 2026-10-19 (precios StoreKit/ASC en onboarding + RevenueCat)

## 1. Arquitectura

```
SwiftUI (paywall, Settings, gates en vistas)
        ↓
SubscriptionManager (@Observable)  ·  PaywallCoordinator
        ↓
EntitlementProviding  →  RevenueCat / Debug / Unconfigured
        ↓
FeatureAccessPolicy (ReperaDomain)  ←  FreeUsageStore (cuotas)
        ↓
ReperaStore.featureAccess (gates en saveRoutine / addCustomExercise / ProgressionEngine)
```

| Componente | Rol |
|------------|-----|
| `ReperaFeature` | Catálogo tipado de funcionalidades |
| `FeatureAccessPolicy` | ¿Puede? ¿Cuánto queda? ¿Por qué no? ¿Qué decir? |
| `CommercialSnapshot` / `SubscriptionStatus` | Estado comercial (+ política offline) |
| `FreeUsageLedger` / `FreeUsageStore` | Cuota escáner (JSON aparte del deporte) |
| `SubscriptionManager` | Fachada app + ofertas + compra/restore |
| `PaywallView` / `PaywallContext` | Paywall nativo contextual |
| `MonetizationAnalytics` | Eventos locales (sin terceros) |

**Separación de datos:** el entitlement Pro **no** vive en `app_state.json`. Importar un backup no otorga ni revoca Pro. Las cuotas gratis viven en `Application Support/Repera/free_usage.json` (+ espejo iCloud best-effort).

## 2. Gratis vs Pro

| Función | Gratis | Pro |
|---------|--------|-----|
| Entrenamientos / series / RIR / WOD registro | ✓ | ✓ |
| Catálogo, timers, Watch, Salud, iCloud, export/import | ✓ | ✓ |
| Historial general de sesiones | ✓ | ✓ |
| Rutinas reutilizables (`scheduledDate == nil`) | máx. **3** | ilimitadas |
| Ejercicios `isCustom` | máx. **5** | ilimitados |
| Escáner pizarra (éxito → revisión usable) | **4**/mes UTC | ilimitados |
| Evolución / historial completo por ejercicio | última sesión + PR + teaser | completo |
| Historial WOD / comparativas | mejor + último | completo |
| Progreso | solo **Esta semana** + teaser | todos los periodos + métricas |
| Mapa muscular / equilibrio / fatiga UI | teaser | completo |
| `ProgressionEngine.applySuggestions` al empezar | off | on |
| %→kg / 1RM básico / discos | ✓ | ✓ |

Al perder Pro: **no se borran** rutinas, ejercicios ni entrenos; solo se bloquea crear por encima del límite.

## 3. Identificadores comerciales

| Qué | Valor |
|-----|--------|
| Producto mensual | `com.app.repera.premium.monthly` |
| Producto anual | `com.app.repera.premium.yearly` |
| Entitlement RevenueCat | `pro` |
| Offering | `default` |
| Bundle iOS | `com.app.repera` |

Precios UI: **siempre** desde App Store Connect vía StoreKit (`Product.displayPrice`) o RevenueCat (que lee el mismo catálogo). Sin importes hardcodeados en producción. Si falta `RevenueCatPublicAPIKey`, `StoreKitEntitlementProvider` consulta StoreKit directamente (scheme con `ReperaProducts.storekit` o sandbox ASC). Objetivos ES: 5,99 €/mes · 39,99 €/año · intro anual 29,99 € (si Apple la ofrece) · trial 14 días vía oferta introductoria real.

## 4. RevenueCat

- SPM: `https://github.com/RevenueCat/purchases-ios-spm` (producto `RevenueCat`), declarado en `project.yml`.
- Clave pública: Info.plist / XcodeGen `RevenueCatPublicAPIKey` (`appl_…`).
- Sin clave válida: la app compila, permanece en Gratis, no compra productos ficticios, paywall muestra «compras no disponibles».
- Debug: sección «Debug Pro» en Ajustes (solo `#if DEBUG`) + `DebugEntitlementProvider`.

## 5–8. App Store Connect / productos / entitlement / offerings

Checklist del propietario:

1. **App Store Connect** → app `com.app.repera` → Suscripciones.
2. Grupo «Repera Pro» con:
   - `com.app.repera.premium.monthly` (1 mes) — intro: 14 días gratis (elegibles).
   - `com.app.repera.premium.yearly` (1 año) — intro opcional: 29,99 € primer año.
3. **RevenueCat** → proyecto iOS → API key pública Apple → pegar en `RevenueCatPublicAPIKey`.
4. Products con los mismos IDs → Entitlement `pro` → Offering `default` (anual destacado + mensual).
5. Paid Applications Agreement + impuestos / banking activos.
6. Sandbox testers + (opcional) `Apps/Repera/Resources/StoreKit/ReperaProducts.storekit` en el scheme.

## 9. Prueba gratuita

Solo la oferta introductoria de Apple. No hay contador local de 14 días. Si el usuario no es elegible, no se promete trial en UI.

## 10. Restaurar / gestionar

- Paywall y Ajustes → «Restaurar compras» (`Purchases.restorePurchases`).
- «Gestionar suscripción» → `https://apps.apple.com/account/subscriptions`.

## 11. Offline

- Pro verificado con `expirationDate` futura → se mantiene Pro sin red.
- Sin fecha: margen de 7 días desde `lastVerifiedProAt` si el refresh falla.
- `unknown` sin caché Pro → Gratis (no desbloquea).
- Caducado / revocado confirmados → sin Pro.

## 12. Cuotas escáner

- Periodo: mes natural **UTC** (`yyyy-MM`).
- Consume al llegar a revisión con bloques/líneas usables (idempotente por `attemptID`).
- No consume: cancelación, permiso denegado, OCR vacío/error.
- Sin backend: no hay antifraude absoluto multi-dispositivo; iCloud es best-effort.

## 13. Migración usuarios existentes

Pasan a Gratis salvo suscripción válida. Conservan rutinas/ejercicios por encima del límite; solo se limita crear nuevos.

Al instalar esta versión, el **onboarding** (Sign in with Apple → elegir Gratis o Pro → permisos) es obligatorio también para quienes ya tenían datos locales; iCloud recupera si hay copia.

## 14. Pruebas

```bash
cd Packages/ReperaDomain && swift test   # incluye FeatureAccessPolicy + FreeUsageLedger
xcodegen generate
```

Debug: Ajustes → Debug Pro → simular Free/Pro/Trial/gracia/caducada/offline.

StoreKit Configuration: adjuntar `ReperaProducts.storekit` al scheme Repera.

## 15. Producción

1. Sustituir `YOUR_REVENUECAT_PUBLIC_API_KEY` por `appl_…`.
2. Verificar offering `default` y entitlement `pro` en dashboard.
3. Probar sandbox mensual, anual, restore, caducidad.
4. Confirmar que Release **no** muestra Debug Pro ni desbloquea por preferencia local.
