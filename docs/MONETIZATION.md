# Monetización — Repera Gratis / Repera Pro

Última actualización: 2026-10-27 (verificación de Pro al guardar Favoritos)

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
| Producto mensual | `com.app.repera.premium.monthly` (Apple ID `6824535885`) |
| Producto anual | `com.app.repera.premium.yearly` (Apple ID `6824536935`) |
| Entitlement RevenueCat | `pro` |
| Offering | `default` |
| Bundle iOS | `com.app.repera` |

**TestFlight / App Store Connect (19/10/2026):** ambas suscripciones se muestran como «En preparación para el envío», grupo «Repera PRO». Los IDs numéricos de Apple son referencias del dashboard, nunca parámetros de `Product.products(for:)`, RevenueCat o compra. La primera suscripción renovable requiere envío junto a una versión nueva de la app para revisión; mientras tanto, probar en sandbox de TestFlight si Apple devuelve los productos. Comprobar que RevenueCat usa los nuevos IDs (no los antiguos `repera_pro_...`) y que el entitlement `pro` se activa solo tras transacción verificada. Probar compra mensual, anual, cancelación, restauración, expiración y nuevo inicio de sesión; no inferir aprobación de las capturas.

Primera suscripción renovable: Apple exige enviarla con una versión nueva de la app a revisión. Los productos deben tener metadatos/precios/comercialización configurados y el contrato de aplicaciones de pago activo. En TestFlight las compras usan sandbox; el archivo `.storekit` solo sirve para pruebas locales de Xcode, y sus precios/ofertas no acreditan los definidos en ASC.\n\nPrecios UI: **siempre** desde App Store Connect vía StoreKit (`Product.displayPrice`) o RevenueCat (que lee el mismo catálogo). Sin importes hardcodeados en producción. Si falta `RevenueCatPublicAPIKey`, `StoreKitEntitlementProvider` consulta StoreKit directamente (scheme con `ReperaProducts.storekit` o sandbox ASC). Objetivos ES: 5,99 €/mes · 39,99 €/año · intro anual 29,99 € (si Apple la ofrece) · trial 14 días vía oferta introductoria real.

## 4. RevenueCat

- SPM: `https://github.com/RevenueCat/purchases-ios-spm` (producto `RevenueCat`), declarado en `project.yml`.
- Clave pública: Info.plist / XcodeGen `RevenueCatPublicAPIKey` (`appl_…`).
- Sin clave RevenueCat válida, la app utiliza directamente StoreKit 2 y puede comprar los productos reales de App Store Connect. Si Apple no devuelve productos, el paywall informa de la indisponibilidad; nunca simula una compra ni concede Pro por pulsar un botón.
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

- Paywall y Ajustes → «Restaurar compras» (`AppStore.sync()` con StoreKit 2, o `Purchases.restorePurchases()` si RevenueCat está configurado).
- «Gestionar suscripción» → `https://apps.apple.com/account/subscriptions`.

### Favoritos y reconocimiento de Pro (27/10/2026)

- Los botones **Favorito** de Play, vista previa e historial solo abren el paywall tras un rechazo real de `FeatureAccessPolicy`. Un fallo de guardado con Pro activo no solicita comprar de nuevo: muestra un mensaje de error normal.
- Antes de ofrecer una suscripción por un límite de plantillas, `SubscriptionManager.refreshEntitlementsForFeatureAction()` verifica de nuevo los permisos y reintenta el guardado si la situación ha cambiado. Los rechazos con estado `unknown` muestran indicaciones para recuperar compras, sin afirmar que la cuenta sea Gratis.
- `SubscriptionManager.presentPaywall` impide la presentación del paywall a cuentas con acceso Pro o patrocinado incluso si una vista lo invoca por error.
- En caso de desacuerdo del verificador comercial principal, se consulta `StoreKit 2 Transaction.currentEntitlements` y se adoptan exclusivamente compras verificadas de los dos identificadores oficiales, incluyendo TestFlight. No se activa Pro por un booleano local ni por una pantalla de pago simulada.
- Se resetea `lastAccessDenial` al empezar cada intento de favorito, para que una denegación anterior no provoque un falso paywall en una acción nueva.
- Pruebas estáticas: `tests/test_pro_favorite_entitlements_contract.py`; política comercial: `FeatureAccessPolicyTests.swift`. Falta validación de compra/restauración en TestFlight.

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
