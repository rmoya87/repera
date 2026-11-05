# Monetización — Repera Gratis / Repera Pro

Última actualización: 2026-11-04 (StoreKit / Play + Pro patrocinado B2B; sin RevenueCat)

## 1. Arquitectura

```
SwiftUI / Compose (paywall propio, Settings, gates)
        ↓
SubscriptionManager  ·  PaywallCoordinator
        ↓
EntitlementProviding  →  StoreKit 2 (iOS) / Play Billing (Android) / Debug
        ↓
FeatureAccessPolicy (ReperaDomain)  ←  FreeUsageStore (cuotas)
        ↓
ReperaStore.featureAccess (gates en saveRoutine / addCustomExercise / ProgressionEngine)
```

| Componente | Rol |
|------------|-----|
| `ReperaFeature` | Catálogo tipado de funcionalidades |
| `FeatureAccessPolicy` | ¿Puede? ¿Cuánto queda? ¿Por qué no? |
| `CommercialSnapshot` / `SubscriptionStatus` | Estado comercial (+ política offline) |
| `FreeUsageLedger` / `FreeUsageStore` | Cuota escáner |
| `SubscriptionManager` | Fachada + ofertas + compra/restore |
| `PaywallView` / `PaywallScreen` | Paywall nativo contextual |
| `StoreKitEntitlementProvider` | iOS: precios y cargos App Store |
| `PlayBillingEntitlementProvider` | Android: Google Play Billing |

**Separación de datos:** el entitlement Pro **no** vive en `app_state.json`. Las cuotas gratis viven en `Application Support/Repera/free_usage.json` (+ espejo iCloud best-effort).

No hay SDK de terceros de suscripciones. iOS usa StoreKit 2; Android usa Play Billing + verificación Edge cuando exista.

## 2. Gratis vs Pro

| Función | Gratis | Pro |
|---------|--------|-----|
| Entrenamientos / series / RIR / WOD registro | ✓ | ✓ |
| Catálogo, timers, Watch, Salud, iCloud, export/import | ✓ | ✓ |
| Historial general de sesiones | ✓ | ✓ |
| Mapa y navegación GPS 2D, GPX | ✓ | ✓ |
| Navegación 3D | — | ✓ |
| Favoritos | **3** | ilimitados |
| Rutinas biblioteca sin estrella | **3** | ilimitadas |
| Ejercicios `isCustom` | máx. **5** | ilimitados |
| Escáner pizarra | **4**/mes UTC | ilimitados |
| Progreso | **Últimos 7 días** + teaser | mes + a largo plazo |
| Comparativas WOD / progresión de carga | básicas / no | avanzadas / sí |

Al perder Pro no se borran datos; solo se bloquea crear por encima del límite.

La tabla del paywall (`PaywallView` / `PaywallScreen`) refleja estas filas (Mapa GPS, Progreso, Por ejercicio, Comparativas WOD, Progresión de carga, rutinas/favoritos, ejercicios propios, escáner).

## 3. Identificadores comerciales

| Qué | Valor |
|-----|--------|
| Producto mensual | `com.app.repera.premium.monthly` |
| Producto anual | `com.app.repera.premium.yearly` |
| Bundle iOS | `com.app.repera` |

Precios UI: **siempre** desde App Store Connect vía StoreKit (`Product.displayPrice`) o Play Billing. Sin importes hardcodeados. Scheme local: `Apps/Repera/Resources/StoreKit/ReperaProducts.storekit`.

## 4. Proveedor iOS (StoreKit 2)

- `StoreKitEntitlementProvider` es el único proveedor de producción.
- Compra / restauración / `Transaction.updates` con `finish` solo en compras directas StoreKit.
- Sin productos ASC → paywall muestra indisponibilidad; nunca concede Pro por UI.
- Debug: sección «Debug Pro» en Ajustes (`#if DEBUG`).

## 5. App Store Connect / Play Console

1. Suscripciones con los IDs de la tabla §3.
2. Paid Applications Agreement + impuestos / banking.
3. Sandbox testers (iOS) / license testers (Play).
4. Opcional: archivo `.storekit` en el scheme Xcode.

## 6. Restaurar / gestionar

- Paywall y Ajustes → «Restaurar compras» (`AppStore.sync()` / Play restore).
- «Gestionar suscripción» → URL de suscripciones de Apple / Play.

## 7. Offline

Si el refresh falla, se conserva un Pro **previamente verificado** un tiempo limitado (`lastVerifiedPro*`). Sin snapshot verificado → Gratis (fail-closed).

iOS y Android persisten el último Pro verificado (`repera.commercial.verifiedPro.v1`) y lo rehidratan al arranque antes del refresh. Un `.free`/lista vacía **transitorio** (p. ej. tras actualizar la app) **no borra** la caché ni degrada a Gratis mientras la caducidad futura o la gracia offline (7 días) sigan válidas. Solo se limpia la caché con **caducada / revocada** confirmada.

## 8. Pro patrocinado (Center / B2B)

Además de StoreKit/Play, un atleta con `business_sponsored_pro` del RPC `get_my_effective_entitlements` obtiene acceso Pro completo (`businessSponsoredAccess` en `SubscriptionManager`).

- **iOS:** `BusinessDataStore.refreshEntitlements` → `ReperaApp.wireSubscriptionGates` (también al cambiar `entitlements?.businessSponsoredPro`).
- **Android:** `BusinessCenterStore.refresh` carga el mismo RPC y `MainActivity` llama `setBusinessSponsoredAccess`.
- No basta con estar vinculado a un centro: hace falta el flag de servidor (bono de pago + plan/trial del org).
