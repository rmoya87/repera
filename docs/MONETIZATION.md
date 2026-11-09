# Monetización — Repera Gratis / Repera Pro

Última actualización: 2026-11-08 (Ajustes → Acceso a Pro; canje código solo sin Pro)

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
| Navegación mapa 3D (Comenzar en vivo) | — | ✓ |
| Favoritos | **3** | ilimitados |
| Rutinas biblioteca sin estrella | **3** | ilimitadas |
| Ejercicios `isCustom` | máx. **5** | ilimitados |
| Escáner pizarra | **4**/mes UTC | ilimitados |
| Progreso | **Últimos 7 días** + teaser | mes + a largo plazo |
| Historial WOD (ficha catálogo) | mejor + última | completo |
| Comparar intento actual vs anterior (ficha «Esta sesión») | ✓ | ✓ |
| Progresión de carga | %1RM sugerida en ficha | + sugerencias automáticas al iniciar |
| Mapa muscular / análisis avanzado | teaser | ✓ |

Al perder Pro no se borran datos; solo se bloquea crear por encima del límite.

La tabla del paywall (`PaywallView` / `PaywallScreen`) refleja: Navegación mapa, Progreso (7 días / Completo), Por ejercicio, Progresión de carga, rutinas/favoritos, ejercicios propios, escáner. Sin fila «Historial WOD» ni título «GRATIS VS PRO». Historial WOD completo sigue siendo Pro en producto; no se destaca en la tabla.

## 3. Identificadores comerciales

| Qué | Valor |
|-----|--------|
| Producto mensual | `com.app.repera.premium.monthly` |
| Producto anual | `com.app.repera.premium.yearly` |
| Bundle iOS | `com.app.repera` |

Precios UI: **siempre** desde App Store Connect vía StoreKit (`Product.displayPrice`) o Play Billing. Sin importes hardcodeados. Scheme local: `Apps/Repera/Resources/StoreKit/ReperaProducts.storekit` (precios de referencia 5,99 € / 39,99 €; **sin** introductory offer local — si ASC/Play configuran trial/intro, la app lo muestra al recibirlo).

Debug Pro **no** inventa «14 días gratis» ni precios distintos a la referencia: solo placeholders para UI. TestFlight/producción = tienda real.

## 4. Proveedor iOS (StoreKit 2)

- `StoreKitEntitlementProvider` es el único proveedor de producción.
- Compra / restauración / `Transaction.updates` con `finish` solo en compras directas StoreKit.
- Sin productos ASC → paywall muestra indisponibilidad y permite **Reintentar**; nunca concede Pro por UI.
- Si hay una compra Apple verificada, el paywall muestra el acceso Pro actual en vez de pedir comprar otra vez.
- Un catálogo vacío no equivale a una suscripción caducada: los productos se validan de forma independiente de los derechos firmados.
- Debug: sección «Debug Pro» en Ajustes (`#if DEBUG`). Con «Simular suscripción» ON, el estado forzado **gana** a la caché `verifiedPro` (misma idea que Android `DebugEntitlementController.applyTo` tras el merge). Al apagar la simulación se restaura `StoreKitEntitlementProvider`. La fila «Efectivo» refleja `isPro` real (incluye Pro patrocinado por Center).

## 5. App Store Connect / Play Console

1. Suscripciones con los IDs de la tabla §3.
2. Paid Applications Agreement + impuestos / banking.
3. Sandbox testers (iOS) / license testers (Play).
4. Opcional: archivo `.storekit` en el scheme Xcode **solo para pruebas locales**; TestFlight consulta App Store Connect/Sandbox y no ese archivo.
5. TestFlight: confirmar que los dos IDs están disponibles para el bundle `com.app.repera`, con localización/precios/territorios y acuerdos al día. La suscripción de prueba se renueva diariamente hasta seis veces y posteriormente expira.
6. Si `Product.products(for:)` devuelve `[]`, comprobar App Store Connect y el tester Sandbox: ningún reintento en la app puede fabricar productos que Apple no ofrece.
7. Introductory offer / trial / descuento intro: **sí lo permiten** Apple y Google, pero se configuran en **App Store Connect / Play Console**, no en código. La UI ya tiene el campo dinámico `introductoryOfferSummary` (+ `hasFreeTrial`): iOS lo rellena desde `Product.subscription.introductoryOffer`; Android desde las fases de `subscriptionOfferDetails`. Sin promo hardcodeada en Debug. Si no hay oferta en tienda → el campo queda vacío y el paywall no inventa descuentos.
8. **Offer codes Apple:** crear en App Store Connect y repartir. En app: caja «¿Tienes un código?» en el paywall y «Canjear código de oferta» en Ajustes → Acceso a Pro (`offerCodeRedemption`) solo si aún no hay Pro comprado. Tras canjear se refrescan derechos; `Transaction.updates` ya estaba activo. Canje fuera de la app: App Store / URL de redención ASC.
9. **Códigos Play:** la caja del paywall abre `https://play.google.com/redeem` (canje en Play). Ofertas developer-determined / selección de `offerToken` siguen siendo un cableado aparte si hace falta elegibilidad por usuario.

## 6. Restaurar / gestionar

- Paywall y Ajustes → «Restaurar compras». iOS consulta **primero** `Transaction.currentEntitlements` (firmadas por Apple). Solo si no encuentra acceso, y únicamente tras tocar Restaurar, llama a `AppStore.sync()`; si falla, vuelve a consultar derechos antes de informar del error. Un `SKInternalErrorDomain` como el código 21 se presenta en español con el código técnico, sin interpretar que la suscripción ha caducado. Android conserva su restore propio.
- Un error de `AppStore.sync()` en TestFlight no justifica asignar Pro sin comprobación de Apple; puede requerir revisar la sesión Sandbox en el dispositivo o App Store Connect.
- Probar en un iPhone TestFlight: cuenta con Pro vigente, prueba caducada, usuario sin compra, StoreKit indisponible, catálogo vacío, segundo intento al recuperar la red. Confirmar que no se borran entrenos ni caché.
- «Gestionar suscripción» → URL de suscripciones de Apple / Play.

## 7. Offline

Si el refresh falla, se conserva un Pro **previamente verificado** un tiempo limitado (`lastVerifiedPro*`). Sin snapshot verificado → Gratis (fail-closed).

iOS y Android persisten el último Pro verificado (`repera.commercial.verifiedPro.v1`) y lo rehidratan al arranque antes del refresh. Un `.free`/lista vacía **transitorio** (p. ej. tras actualizar la app) **no borra** la caché ni degrada a Gratis mientras la caducidad futura o la gracia offline (7 días) sigan válidas. Solo se limpia la caché con **caducada / revocada** confirmada. Excepción Debug: simular Gratis/expired/revoked **sí** limpia esa caché para poder probar bloqueos.

## 8. Pro patrocinado (Center / B2B)

Además de StoreKit/Play, un atleta con `business_sponsored_pro` del RPC `get_my_effective_entitlements` obtiene acceso Pro completo (`businessSponsoredAccess` en `SubscriptionManager`).

- **iOS:** `BusinessDataStore.refreshEntitlements` → `ReperaApp.wireSubscriptionGates` (también al cambiar `entitlements?.businessSponsoredPro`).
- **Android:** `BusinessCenterStore.refresh` carga el mismo RPC y `MainActivity` llama `setBusinessSponsoredAccess`.
- No basta con estar vinculado a un centro: hace falta el flag de servidor (bono de pago + plan/trial del org).
