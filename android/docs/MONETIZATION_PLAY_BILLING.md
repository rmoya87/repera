# Monetización Android: Google Play Billing directo (sin RevenueCat)

Decisión de Ramón (24-oct-2026, iMessage): "RevenueCat no lo utilizo en apple
así que puedes eliminarlo, conecta en el caso de apple directamente con apple
haz lo mismo en Android". Referencia: StoreKitEntitlementProvider de main
(Apple directo). Apple NO se toca.

## Modelo de seguridad (documentación oficial vigente)

- https://developer.android.com/google/play/billing/security
  "Verify purchases before granting entitlements": la verificación y
  acknowledge de compras deben hacerse en backend; la app envía el
  purchaseToken al backend.
- https://developer.android.com/google/play/billing/lifecycle/subscriptions
  `purchases.subscriptionsv2.get` es "the source of truth for subscription
  state": subscriptionState (ACTIVE / IN_GRACE_PERIOD / CANCELED / EXPIRED),
  expiryTime, canceledStateContext, acknowledgementState. Solo server-side
  (Play Developer API).
- queryPurchasesAsync devuelve SOLO compras actualmente poseídas: las
  caducadas desaparecen; no hay expiryTime on-device; PENDING no concede
  entitlement; acknowledge es obligatorio (3 días) pero no prueba vigencia.

Consecuencia: PurchaseState.PURCHASED local NO es verificación. La app Android
trata toda compra detectada como "pendiente de verificación" y solo concede
Pro desde un snapshot verificado por backend. La caché offline
(lastVerifiedProStatus/lastVerifiedProAt) solo se alimenta de validaciones
verificadas por el backend. La gracia de 7 días es política HEREDADA de iOS,
pendiente de confirmar como política propia frente a la caducidad real de
Play; NO es una garantía de Play y nunca tapa una caducidad o revocación
conocida (EXPIRED/REVOKED siempre ganan en effectiveStatus). UNKNOWN se
conserva como UNKNOWN.

## Qué existe sin backend (integración explícitamente incompleta)

- Catálogo/ofertas visibles (precios públicos de Play, queryProductDetails).
- Flujo de compra cableado hasta "compra detectada, pendiente de verificación".
- Política de dominio completa (ya portada): FeatureAccessPolicy,
  FreeUsageLedger, límites Gratis (3 rutinas / 5 ejercicios / 4 escaneos mes),
  paywall por contexto.
- Provider de producción NO configurado hasta que exista backend: equivale al
  stub UnconfiguredEntitlementProvider de iOS (Gratis, sin compras ficticias).

## Requisito mínimo en la cuenta de Ramón (antes de tocar nada)

Imprescindible para verificar (sin esto no hay Pro en producción). Fuente
única y vigente: https://developers.google.com/android-publisher/getting_started
1. Crear un proyecto Google Cloud (si no hay uno) y habilitar en él
   "Google Play Developer API". Cita oficial: "You no longer need to link
   your developer account to a Google Cloud Project in order to access the
   Google Play Developer API" - el paso de vinculación explícita ya NO
   existe; basta proyecto + API habilitada + cuenta de servicio invitada.
2. Crear la cuenta de servicio (Google Cloud Console > Service Accounts) y
   descargar su clave JSON. Autenticación oficial: "You need to configure
   access ... with an OAuth client or a service account. In most cases, you
   should use a service account" (OAuth client es para actuar en nombre de
   un usuario humano; para backend servidor-a-servidor: cuenta de servicio,
   clave guardada como secreto SOLO en el backend).
3. Play Console > Usuarios y permisos: invitar la cuenta de servicio con
   acceso SOLO a la app Repera. Permisos, cita oficial literal: "To use the
   Google Play Billing APIs, you must grant the following permissions:
   View financial data, orders, and cancellation survey responses; Manage
   orders and subscriptions". La fuente los exige CONJUNTAMENTE para las
   Billing APIs y NO documenta granularidad por endpoint: si uno solo
   bastara para purchases.subscriptionsv2.get NO está confirmado en la
   fuente - el mínimo seguro documentado son ambos, limitados a la app.
4. Endpoint backend (Supabase Edge Function nueva) que reciba purchaseToken
   de la app y consulte purchases.subscriptionsv2.get; guarda entitlement
   por usuario. La clave JSON vive solo en el backend (secreto).

Opcional para actualización oportuna (no necesario para verificar):
5. Real-time Developer Notifications: tema Cloud Pub/Sub configurado en
   Play Console (Monetización > Configuración) + suscripción que invoque el
   endpoint. Sin RTDN la verificación ocurre al comprar, restaurar y al
   refrescar en primer plano; con RTDN además al renovar/cancelar/expirar.

Sin los pasos 1-4, Android no puede ofrecer Pro en producción con garantías:
queda Gratis funcional con paywall informativo "compras no configuradas".

## Precios confirmados por Ramón (25/10/2026, iMessage 13:40)

"Tiene que ser con los precios de apple mensual de 5,99 y si es anual de 39,99"
(mensaje phonemsg-01M5SH836466EK865PC0YT8TJV, canal iMessage verificado).
- Mensual (com.app.repera.premium.monthly): 5,99 EUR/mes.
- Anual (com.app.repera.premium.yearly): 39,99 EUR/año.
- Trial: SIN trial Pro, confirmado por Ramón el 28/10/2026. Inicio Gratis y Pro mensual/anual.
Estos importes NO van en código (la app los lee de Play). Se aplicarán al
crear los productos en Play Console cuando la subida del primer AAB y la
creación de productos estén autorizadas (hoy NO lo están). Los mismos
importes del debug provider iOS son placeholders de desarrollo; su
coincidencia con esta decisión es posterior a la confirmación de Ramón.

## Estado de la capacidad

**Última actualización:** 2026-10-28

implementado en app:
- política de dominio (cuotas Gratis, paywall, favoritos máx. 3, escaneos, etc.)
- `PlayBillingEntitlementProvider` cableado desde `MainActivity` (compra real +
  detección local → UNKNOWN, **sin** conceder Pro)
- `PlayPurchaseVerifyClient` → `POST /functions/v1/repera-play-billing-verify`
- acknowledge backend antes de devolver entitlement Pro; se reintenta en nueva verificación si falla
- Verificador en revisión `supabase/functions/repera-play-billing-verify/`
  (JWT usuario, catálogo estricto, estados exactos, token ownership atómico y acknowledgement backend). No desplegado por esta revisión.

bloqueado por Ramón / ops (sin esto Pro sigue sin concederse en prod):
1. Secretos Edge: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, `PLAY_PACKAGE_NAME`
2. Play Console: productos monthly/yearly (5,99 / 39,99 EUR) + testers
3. Despliegue de la Edge Function
4. (Opcional) RTDN Pub/Sub

Sin esos secretos la función responde `503 { configured:false }` y la app
muestra el mensaje de verificación pendiente; la caché offline solo usa
snapshots ya verificados.

## Revisión de seguridad del 28/10/2026 (BORRADOR, no desplegado)

- Play es la única fuente de producto y vencimiento. Un hint del cliente no
  permite convertir productos desconocidos en Pro. ACTIVE/CANCELED necesitan
  producto conocido y vencimiento futuro; gracia y ON_HOLD no se confunden.
- La compra incorpora `obfuscatedAccountId=SHA256(UUID Supabase en minúsculas)`.
  El servidor exige coincidencia con el usuario autenticado. Sin sesión no
  se abre la compra. No se transmite email ni UUID en claro a Play.
- Nueva tabla privada y RPC service_role-only reclaman hash de token de forma
  atómica y marcan el token sustituido como superseded. No se almacena el token
  de compra en claro. RLS no concede acceso a anon/authenticated.
- La migración `20261028173000_play_subscription_ownership.sql` es un BORRADOR.
  Su comportamiento actual de ownerNULL al borrar una cuenta impide reasignar
  compras automáticamente. La política de recuperación/retención tras borrar y
  recrear cuenta NO está decidida: no aplicar esta migración ni desplegar el
  verificador hasta acordarla e implementar una vía de recuperación real.
- No se han cambiado productos/precios, Apple, release pública o merge main
  desde esta revisión. El alcance de Console se verifica por separado.

Pruebas locales: `deno test supabase/functions/repera-play-billing-verify/verification_test.ts`
(19 casos) y `deno check .../index.ts`. PostgreSQL embebido valida sintaxis,
permisos, restores mismo dueño, rechazos, reemplazo y FK al borrar cuenta.
NO demuestra esquema remoto, concurrencia multisesión, integración Google real
ni build Android. Cuenta tester no equivale a compra con medio de prueba.

Rollback seguro: si ya hubiera datos de compra, deshabilitar el endpoint o
restaurar una versión segura manteniendo ownership; no volver al scaffold que
concede Pro ni borrar tabla/hashes para recuperar servicio. Antes de cualquier
aplicación remota comprobar esquema/migraciones existentes y guardar definición.
La migración es aditiva, no altera tablas de negocio. Sin compras reales aún,
revisión local puede descartarse sin mutaciones de producción.
