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
- Trial: SIN RESPUESTA aún; dato abierto para la aprobación final agrupada.
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
- acknowledge local solo tras verify OK
- Edge Function scaffold `supabase/functions/repera-play-billing-verify/`
  (JWT usuario + `purchases.subscriptionsv2.get` cuando hay SA)

bloqueado por Ramón / ops (sin esto Pro sigue sin concederse en prod):
1. Secretos Edge: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, `PLAY_PACKAGE_NAME`
2. Play Console: productos monthly/yearly (5,99 / 39,99 EUR) + testers
3. Despliegue de la Edge Function
4. (Opcional) RTDN Pub/Sub

Sin esos secretos la función responde `503 { configured:false }` y la app
muestra el mensaje de verificación pendiente; la caché offline solo usa
snapshots ya verificados.
