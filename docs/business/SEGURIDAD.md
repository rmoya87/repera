## Consola y delegación de plataforma (2026-10-27)

## Centros sin propietario registrado — 2026-10-27

Un negocio pendiente ya es un tenant real pero **privado**: `is_discoverable=false`, `public_email=null`; solo el administrador autorizado puede leerlo a través de RPC o acceder a sus operaciones tras invocar la delegación registrada y temporal. El trigger `bootstrap_organization_owner` crea temporalmente la membresía del creador, eliminada en la misma transacción privilegiada, antes de exponer el registro a otras transacciones. No se otorga permiso SELECT a `platform_org_provisioning` ni `platform_admin_delegations` al navegador.

Se preserva el control de acceso mediante `private.has_org_role` con `auth.uid()` del administrador; nunca se construye JWT del propietario ni se inicia sesión como este. La suspensión se gestiona por `platform_org_controls` con motivo y auditoría, mientras que la reclamación solo admite email **verificado** coincidente y asigna membresía owner al usuario correcto. Se ha probado un ciclo completo en una transacción SQL revertida (sin registros de prueba persistentes).

Migrations: `20261027153000_materialize_pending_centers.sql`, `20261027154500_pending_centers_email_privacy.sql` ambas aplicadas y versionadas.


## Directorio global y Storage previo a altas (27/10/2026)

- El listado de cuentas y avatares es exclusivo del `platform_admin` validado en SQL por rol y correo confirmado. Ni `auth.users` ni `profiles` se hacen públicamente consultables. Se prohíbe desde la función el acceso anónimo o con usuario normal, verificado con prueba 42501. El directorio no devuelve información clínica, nutricional ni de entrenamientos.
- `platform_settings` está protegido por RLS sin permisos REST directos; las modificaciones solo entran por una función privada auditada y validada. URLs requieren HTTPS y los correos validan formato y longitud.
- Las imágenes de prealta se optimizan en navegador y se suben al bucket público de imagen comercial limitado a JPEG y 1 MB. La política exige rol plataforma y que la carpeta coincida con un UUID de alta pendiente creada por ese actor; el RPC valida existencia y ruta antes de asociarla. No se conceden permisos SELECT adicionales sobre datos de cuentas personales.
- Los avatares personales utilizan el bucket `profile-avatars` con política vinculada a `auth.uid()`; solo se modifica `display_name` y `avatar_url` del propio perfil. Los cambios de correo/contraseña usan GoTrue con JWT del usuario actual, nunca la service role.
- Las fotos públicas pueden proceder de OAuth; se renderizan solo enlaces HTTPS y su contenido se escapa al generar HTML. Quedan pendientes pruebas browser E2E de subida/reemplazo en todos los navegadores de destino.


## Reparación RLS de membresías — 27/10/2026

**Incidente real (403):** la política `memberships_platform_delegated_read` incluía un subquery directo de `platform_admin_delegations`. Aunque no existiese delegación activa, PostgreSQL evaluaba la expresión de la política y el rol `authenticated` no podía leer la tabla (correctamente denegada). El error afectaba al listado de membresías de todos los negocios y al arranque del panel.

La migración `20261027140000_fix_platform_membership_rls.sql` elimina la política redundante. Sigue vigente `memberships_select_authorized`, que consulta `private.has_org_role()`; esa función SECURITY DEFINER comprueba el administrador y las delegaciones sin exponer la tabla al navegador. **No se otorgan permisos SELECT adicionales sobre tablas administrativas.** Confirmado con sesión de prueba como rol `authenticated` y el usuario de plataforma.


- El segundo ledger `business_client_payments` no admite escrituras desde el navegador; solo un backend con verificación de firma del proveedor podrá registrar transacciones. Se definieron políticas explícitas de denegación para las tablas administrativas; wrappers públicos siguen sujetos al guard de administrador. El CSV añade neutralización de prefijos de fórmula.

La administración global no usa `service_role` en el navegador. `private.is_repera_platform_admin()` valida `profiles.role` más email confirmado de la cuenta raíz. El listado de negocio y el histórico administrativo se exponen por wrappers SQL `SECURITY INVOKER` cuyo destino es una función privada de privilegios restringidos.

La delegación exige organización existente, motivo de 12–300 caracteres, duración máxima de 30 minutos, un ámbito activo por administrador y registro de entrada/salida. Reutiliza `auth.uid()` del administrador: **no** falsifica el JWT del propietario, y `private.has_org_role` comprueba la delegación en cada consulta. Las políticas basadas únicamente en rol de deportista quedan excluidas; las operaciones individuales deben seguir comprobando consentimiento. Las modificaciones de negocio realizadas bajo delegación mantienen actor real en `created_by` y datos de auditoría existentes donde la operación ya la incorpora.

`platform_org_controls`, `platform_org_provisioning`, `platform_admin_delegations`, `platform_admin_events` y `platform_billing_payments` son tablas con RLS habilitada y **sin** acceso REST directo para clientes autenticados. Las lecturas necesarias se realizan mediante RPCs validadas. `service_role` puede escribir pagos B2B; el navegador nunca puede confirmar pagos ni alterar liquidaciones.

**Pendiente obligatorio:** pruebas automáticas multirol con JWT reales, políticas directas/RPC de toda acción delegada, monitorización de expiración/revocación y auditoría de cada mutación relevante; Stripe/webhooks solo con firma e idempotencia. No utilizar la delegación como autorización para acceder a datos HealthKit privados.

El advisor de seguridad del proyecto notificó otros avisos no introducidos por este panel (vista `training_exercise_catalog`, función `search_discoverable_organizations`, protección de contraseñas filtradas); resolver por separado antes de considerar producción endurecida.

# Seguridad multiempresa — Repera
Última actualización: 2026-10-20 (avatar profiles).

## Controles implantados
- RLS en **todas las once** tablas publicadas, política explícita `TO authenticated` y predicados de propietario / membresía.
- `profiles.role` no depende de `raw_user_meta_data` y la API solo dispone de UPDATE(`display_name`, `avatar_url`); no autoascenso. Avatares en bucket `profile-avatars` solo escritura en carpeta `auth.uid()`.
- Todas las funciones SECURITY DEFINER del baseline viven en esquema **private** con `search_path=''`; no se publica una función privilegiada en `public`.
- Helper de membresía solo devuelve booleano asociado a `auth.uid()`, exige membresía activa, y no expone filas privadas.
- Trigger de alta de organización asigna propietario sin permitir INSERT arbitrario en membresías.
- Prohibido publicar `service_role` o secretos en iOS/Android/web; claves publishable/anon siempre sujetas a RLS.
- `get_advisors(type=security)` no reportó lints después de la migración (no sustituye pentest).

## Matriz inmediata
Atleta autenticado: solo perfil y contenido propio; si es miembro activo, consulta organización autorizada. Owner/Admin: consulta miembros y actualiza **nombre** de organización. Coach/Recepción: consulta información de organización, no miembros ajenos. Admin global: no dispone aún de API de soporte implementada; el campo role no habilita bypass. Sin sesión: sin permisos en tablas de aplicación.

## Pruebas realizadas
Se ejecutó SQL como rol authenticated para dos usuarios Auth temporales, verificando: alta perfil, incorporación automática owner, lectura owner, aislamiento de B frente a A, imposibilidad de INSERT suplantando otro usuario, rol global/membresía sin escritura cliente. ROLLBACK confirmó 0 orgs persistidas. Test reproducible en `supabase/tests/rls_smoke.sql`.

## Invitaciones, aceptación y privilegios
- Invitaciones visibles exclusivamente para owner/admin y destinatario con correo confirmado; expiración 14 días; roles permitidos: admin, coach, reception y athlete (jamás owner).
- La membresía no se crea hasta la aceptación autenticada con email confirmado. La ficha del atleta solo se vincula entonces; sin transferencia del historial.
- Mutaciones exclusivas de RPC con validación de org y actor, no por escritura directa.
- Funciones expuestas en `public` operan como **invoker** y llaman a lógica `SECURITY DEFINER` del esquema privado. `get_advisors(security)` después de corregir privilegios: 0 lints.
- SQL smoke: owner emite, destinatario acepta, extraño no puede aceptar/emitir, rechazo de repetición; los datos se revierten por ROLLBACK.

## Riesgos y pruebas pendientes
- Acceso explícito entrenador-deportista, consentimientos, borrado/retención GDPR, autorización por relación.
- Test suites para cada tabla y operación (INSERT/UPDATE/DELETE) con credenciales Auth reales y funciones administrativas.
- Estructura de webhooks con verificación de firma, idempotencia y audit logs.
- Evitar DELETE/UPDATE no autorizados por grants en futuros esquemas.
- Separar staging y producción y repetir advisors después de cada migración.

## Asociación de sesión Apple / Supabase en iOS (2026-10-19)

`BusinessAuthStore` solo restaura una sesión Supabase si se corresponde con el identificador de Apple actual, comparando un hash SHA-256 persistido localmente. Al cerrar sesión se elimina la asociación; una identidad distinta no puede reusar por accidente tokens anteriores. Es un control local adicional a la verificación de identidad de Supabase y su RLS, no sustituye comprobaciones servidor. Pendiente de validar en TestFlight los cambios de cuenta, revocaciones y modo sin conexión.

## Protección frente a respuestas tardías de sesión (2026-10-19)

Al cerrar sesión o cambiar de identidad Apple, `BusinessDataStore.clear()` invalida las consultas asíncronas anteriores mediante un contador de revisión. Antes de publicar resultados de Supabase se comprueba que la revisión siga activa, que exista sesión profesional y que el identificador Auth coincida con el de inicio. `BusinessAuthStore` limpia los datos al desconectar y no reusa una sesión del SDK bajo otra cuenta Apple. Esto es una mitigación de exposición de datos en UI; no sustituye la RLS de servidor. Pendiente prueba XCTest con peticiones concurrentes y cambio de cuenta en dispositivo real.
