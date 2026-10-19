# Monetización — Repera Gratis / Repera Pro

Última actualización: 2026-10-19 (paywall nativo, compras verificadas en TestFlight y recuperación StoreKit)

## 1. Arquitectura

```
SwiftUI (paywall, Settings, gates en vistas)
        ↓
SubscriptionManager (@Observable)  ·  PaywallCoordinator
        ↓
EntitlementProviding  →  StoreKit 2 / RevenueCat / Debug
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
| Producto mensual | `repera_pro_monthly` |
| Producto anual | `repera_pro_annual` |
| Entitlement RevenueCat | `pro` |
| Offering | `default` |
| Bundle iOS | `com.app.repera` |

Precios UI: **siempre** desde App Store Connect vía StoreKit (`Product.displayPrice`) o RevenueCat (que lee el mismo catálogo). Sin importes hardcodeados en producción. Si falta `RevenueCatPublicAPIKey`, `StoreKitEntitlementProvider` consulta StoreKit directamente (scheme con `ReperaProducts.storekit` o sandbox ASC). Objetivos ES: 5,99 €/mes · 39,99 €/año · intro anual 29,99 € (si Apple la ofrece) · trial 14 días vía oferta introductoria real.

## 4. RevenueCat

- SPM: `https://github.com/RevenueCat/purchases-ios-spm` (producto `RevenueCat`), declarado en `project.yml`.
- Clave pública: Info.plist / XcodeGen `RevenueCatPublicAPIKey` (`appl_…`).
- Sin clave válida: la app usa StoreKit 2 directamente; si los productos existen en App Store Connect puede comprar en TestFlight/producción sin RevenueCat. Si no existen, permanece en Gratis y el paywall explica la indisponibilidad.
- Debug: sección «Debug Pro» en Ajustes (solo `#if DEBUG`) + `DebugEntitlementProvider`.

## 5–8. App Store Connect / productos / entitlement / offerings

Checklist del propietario:

1. **App Store Connect** → app `com.app.repera` → Suscripciones.
2. Grupo «Repera Pro» con:
   - `repera_pro_monthly` (1 mes) — intro: 14 días gratis (elegibles).
   - `repera_pro_annual` (1 año) — intro opcional: 29,99 € primer año.
3. **RevenueCat** → proyecto iOS → API key pública Apple → pegar en `RevenueCatPublicAPIKey`.
4. Products con los mismos IDs → Entitlement `pro` → Offering `default` (anual destacado + mensual).
5. Paid Applications Agreement + impuestos / banking activos.
6. Sandbox testers + (opcional) `Apps/Repera/Resources/StoreKit/ReperaProducts.storekit` en el scheme.

## 9. Prueba gratuita

Solo la oferta introductoria de Apple. No hay contador local de 14 días. Si el usuario no es elegible, no se promete trial en UI.

## 10. Restaurar / gestionar

- Paywall y Ajustes → «Restaurar compras» (RevenueCat o StoreKit 2, con alternativa StoreKit si RevenueCat falla).
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

StoreKit Configuration: adjuntar `ReperaProducts.storekit` al scheme Repera **solo para pruebas locales desde Xcode**; TestFlight ignora ese archivo y obtiene los productos de App Store Connect. El paywall permite recargar el catálogo, muestra un error comprensible si está vacío y mantiene consistente el proveedor de catálogo y compra. La X de la barra usa `CloseToolbarButton(large: false)` para que iOS 27 aplique Liquid Glass una sola vez.

## Pruebas de compra TestFlight (Sandbox)

- Instalar la build desde TestFlight: las transacciones de prueba son reales en Sandbox Apple y **no generan cobros**; no activar Pro con un interruptor simulado en Release.
- Revisar en App Store Connect los productos **repera_pro_monthly** y **repera_pro_annual** dentro del bundle **com.app.repera**, con nombre, localización, precio y acuerdo de aplicaciones de pago firmado. Sin estos productos, StoreKit no puede abrir la hoja de Apple y el paywall muestra el motivo.
- Si se utiliza RevenueCat, verificar el offering `default`, entitlement `pro` y clave pública, o utilizar StoreKit 2 directo como alternativa (sin mezclar catálogo de un proveedor con compra de otro).
- Validar: cargar planes → pulsar «Continuar con Repera Pro» → hoja de compra nativa Apple/Sandbox → aprobar → acceso Pro concedido a partir de transacción verificada; también probar cancelación, pendiente, error, restauración y relanzamiento.
- Para cambiar tasas de renovación o restablecer pruebas, usar una cuenta Sandbox en Ajustes del sistema → Desarrollador → Cuenta Sandbox; la guía de Apple explica los requisitos de acceso.

## 15. Producción

1. Sustituir `YOUR_REVENUECAT_PUBLIC_API_KEY` por `appl_…`.
2. Verificar offering `default` y entitlement `pro` en dashboard.
3. Probar sandbox mensual, anual, restore, caducidad.
4. Confirmar que Release **no** muestra Debug Pro ni desbloquea por preferencia local.
