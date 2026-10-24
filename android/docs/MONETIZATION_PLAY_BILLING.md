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

Imprescindible para verificar (sin esto no hay Pro en producción):
1. Play Console > Configuración > Acceso a la API: vincular un proyecto de
   Google Cloud y habilitar "Google Play Android Developer API".
   (https://developers.google.com/android-publisher/getting_started)
2. Crear cuenta de servicio en ese proyecto y descargar su clave JSON.
3. Play Console > Usuarios y permisos: invitar la cuenta de servicio con
   acceso SOLO a la app Repera. Permiso imprescindible para VERIFICAR
   (GET purchases.subscriptionsv2.get): "Ver datos financieros, pedidos y
   respuestas a encuestas de satisfacción". La página oficial
   (https://developers.google.com/android-publisher/getting_started) lista
   ADEMÁS "Manage orders and subscriptions" para las Billing APIs en
   general: solo hace falta si el backend ejecuta acciones de escritura
   (acknowledge/refund/revoke por API); manteniendo el acknowledge en el
   dispositivo NO se necesita. Autenticación: la misma página permite OAuth
   client (en nombre de un usuario humano) o cuenta de servicio; para un
   backend servidor-a-servidor la oficial recomendada es cuenta de servicio
   con clave JSON guardada como secreto SOLO en el backend. El enlace del
   proyecto Google Cloud con Play Console (Configuración > Acceso a la API)
   es paso obligatorio del flujo oficial, no opcional.
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

## Estado de la capacidad

implementado: política de dominio completa con pruebas (19 tests).
en preparación segura: facade, store de cuotas, provider on-device estricto,
UI paywall/teaser/choosePlan.
bloqueado por decisión de cuenta: backend de verificación (pasos 1-4 de
Ramón) y activación de productos/precios/trials/acuerdos en Play Console.
