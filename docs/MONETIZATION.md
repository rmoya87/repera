# Monetización — Repera Gratis / Repera Pro

Última actualización: 2026-10-29 (verificación de Pro en acceso 3D y pricing compacto)

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
| Mapa y navegación GPS 2D, GPX, registro de rutas | ✓ | ✓ |
| Navegación con perspectiva 3D e inclinación del mapa | — | ✓ (MapKit iOS; MapLibre o Google Maps Android) |
| Mapas Google de actividades en Android | — (OpenFreeMap) | ✓ (SDK Google cuando esté configurado; fallback MapLibre) |
| Favoritos de entrenamiento o actividades deportivas | **3**; el **4.º** abre la suscripción | ilimitados |
| Otras rutinas reutilizables sin estrella | **3**, cuota independiente de favoritos | ilimitadas |
| Ejercicios `isCustom` | máx. **5** | ilimitados |
| Escáner pizarra (éxito → revisión usable) | **4**/mes UTC | ilimitados |
| Evolución / historial completo por ejercicio | última sesión + PR + teaser | completo |
| Historial WOD / comparativas | mejor + último | completo |
| Progreso | solo **Esta semana** + teaser | todos los periodos + métricas |
| Mapa muscular / equilibrio / fatiga UI | teaser | completo |
| `ProgressionEngine.applySuggestions` al empezar | off | on |
| %→kg / 1RM básico / discos | ✓ | ✓ |

Al perder Pro: **no se borran** rutinas, ejercicios ni entrenos; solo se bloquea crear por encima del límite. La navegación vuelve a **2D plano** inmediatamente; se desactiva la inclinación por gestos en Gratis y el botón 3D ofrece abrir Repera Pro. Se conserva la preferencia anterior para poder recuperarla si se restablece Pro. La misma política `FeatureAccessPolicy.canUse3DNavigation` rige en Swift y Kotlin, incluyendo accesos patrocinados y Pro válido sin conexión. Los favoritos reales (plantillas marcadas y actividades de Comenzar) comparten una cuota de tres elementos en Gratis, independiente de la cuota de rutinas sin estrella. Las copias fechadas de un favorito no se cuentan dos veces; el estado personal se sincroniza mediante iCloud.

### Presentación y contenido de Repera Pro (29/10/2026)

- La página usa una **única comparativa Gratis/Pro** con mapa 2D frente a navegación 3D, periodos de progreso, evolución por ejercicio, cupos reales de biblioteca/favoritos/ejercicios y escáner/análisis. Ya no duplica una lista larga de ventajas encima de la comparativa. Los planes ocupan filas compactas y Restaurar, Gestionar, Privacidad y Términos comparten una línea en móviles normales (con fallback adaptable). Se mantienen la mascota, el precio localizado, el CTA fijo y las condiciones visibles bajo el contenido.
- En el botón 3D de «Comenzar», **antes de mostrar precio** se vuelve a consultar el entitlement firmado (StoreKit/RevenueCat en iOS; Play/Edge verificado en Android). Si reaparece Pro o acceso patrocinado, abre 3D sin paywall. Si no se puede verificar, informa de la incidencia y orienta a comprobar/restaurar compras, sin conceder Pro por un booleano local; únicamente un estado Gratis confirmado puede abrir el paywall. `presentPaywall` en Android también rechaza llamadas si el usuario ya tiene Pro; ambas plataformas cierran la oferta visible al verificarse Pro posteriormente.

- Al solicitar Pro desde Ajustes o desde una funcionalidad limitada, iOS presenta una **página completa** sobre la navegación de raíz mediante overlay, con transición horizontal y botón «Volver», en lugar de `.sheet`. Android sustituye `ReperaModalBottomSheet` por una pantalla completa dentro del host principal, con flecha y BackHandler. En onboarding se mantiene el flujo integrado y el botón «Seguir con Gratis».
- Diseño sobrio: fondo `OG.bg` / `MaterialTheme`, mascota original (`ReperaMascotPose.hero`), beneficios breves de las capacidades realmente sujetas a `FeatureAccessPolicy`, comparativa Gratis/Pro compacta, selección mensual/anual y CTA fijo al pie. En iOS solo hay un desplazamiento ambiental sutil de la mascota y su halo, desactivado con «Reducir movimiento».
- El precio y las ofertas siguen viniendo exclusivamente de StoreKit/RevenueCat o Play Billing; no se prometen pruebas gratuitas si no son elegibles. Sin productos se muestra indisponibilidad y se deshabilita la compra. Se conservan restauración, gestión, privacidad, términos y explicación de renovación.
- El plan Gratis **sí** incluye entrenamientos, reloj, historial general, métricas básicas y parte del equilibrio muscular; Pro amplía los periodos, detalle por ejercicio, análisis muscular avanzado, comparativas WOD, recomendaciones de progresión y cuotas. Ningún número de testimonios ni métrica promocional se inventa.

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
- «Restaurar compras» vuelve a consultar StoreKit si RevenueCat responde sin Pro o falla la restauración. Si `AppStore.sync()` falla, se permite únicamente una transacción todavía activa y verificada por `Transaction.currentEntitlements`. No se concede acceso por instalar TestFlight ni por elegir un plan sin compra real de sandbox.
- Las actividades de «Comenzar» se guardan por `liveSportID` como acceso reutilizable al deporte, incluso si un histórico restaurado contiene ejercicios o bloques auxiliares; no se convierten en rutinas de fuerza. El detalle de historial ofrece errores específicos cuando falla el guardado. «Comprobar acceso Pro» distingue una compra activa de un acceso temporal conservado sin red y explica que las transacciones sandbox de TestFlight no tienen por qué aparecer en las suscripciones reales del iPhone.
- **Raíz del bug Pro (28/10):** `FeatureAccessPolicy.canCreateLibraryRoutine(isNew:)` y las acciones equivalentes de ejercicios personalizados / escaneo no respetaban `isPro`, pese a que `decision(for:)` sí lo hacía. Los accesos verificados de TestFlight/StoreKit, las pruebas activas y los accesos patrocinados se admiten ahora en **todas** las acciones. El límite de favoritos usa `canCreateFavorite(isNew:)` y `favoriteCount` sobre plantillas marcadas y deportes, no sobre rutinas normales. El cuarto favorito Gratis muestra paywall; Pro no tiene límite.
- El mensaje de error del favorito del historial utiliza un aviso de Repera con botón sólido verde, texto blanco en día y negro en noche (un `.alert` de SwiftUI no permite personalizar el fondo del botón).
- Pruebas estáticas: `tests/test_pro_favorite_entitlements_contract.py` (incluido fallback de restauración); política comercial: `FeatureAccessPolicyTests.swift`. Falta validación de compra/restauración en TestFlight.

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

### Android Play (paridad Apple, 2026-10-28)

Detalle: `android/docs/MONETIZATION_PLAY_BILLING.md`. Pro sigue a la compra Play /
cuenta Google (como StoreKit ↔ Apple ID). Hard delete Auth no cancela la
suscripción; tras recreate, reclaim del token hash si el owner quedó NULL.
Migración y Edge verify **no** se aplican/despliegan sin ops; productos draft.
