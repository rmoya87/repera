## Administración global (2026-10-27)

## Materialización temprana de centros pendientes (2026-10-27)

`private.platform_admin_provision` inserta `platform_org_provisioning` y llama `private.platform_admin_materialize_pending` con validación de administrador. El UUID del tenant real aparece en `claimed_org_id` aunque `status='pending'`, por compatibilidad con la estructura existente. El directorio `private.platform_admin_directory()` une ambas tablas y obtiene estado operativo real (`active`/`suspended`) junto con registro (`pending`/`claimed`). Los registros pendientes se muestran como `status='pending'` mientras no estén suspendidos.

Al insertar el centro, el trigger existente crea la membresía del creador; se elimina atómicamente y ningún usuario adquiere propiedad hasta su posterior registro confirmado. `private.claim_platform_provisioning` no duplica la organización: conserva ID, crea membresía owner con la identidad verificada y reinicia prueba de 7 días. Las imágenes previamente cargadas quedan asociadas al tenant.

Se migró la prealta histórica «Alicia». Antes de la aceptación no se muestran esos centros en búsquedas públicas ni se publica el correo del propietario. Migraciones aplicadas: `20261027153000_materialize_pending_centers.sql` y `20261027154500_pending_centers_email_privacy.sql`.


## Directorio de atletas y perfil de centro (2026-10-27)

El directorio `public.platform_admin_athletes()` es un wrapper `SECURITY INVOKER` que delega en `private.platform_admin_athletes()`, condicionado a `private.is_repera_platform_admin()`. Incluye usuarios de `auth.users` aunque no tengan membresías; nombre público y avatar de `profiles` u OAuth para presentación, correo verificado, fecha de alta y agregados de vinculación. No expone historiales personales ni datos HealthKit. El campo `profiles.role` (enum) se convierte a texto al construir JSON; corrección aplicada en `20261027143004_fix_athlete_role_text.sql`.

`platform_settings` tiene RLS, privilegios directos revocados y RPCs autenticadas `platform_admin_settings` y `platform_admin_update_settings`, con validaciones y auditoría. Los valores editables son correo/URL de soporte, correo de facturación, URL de privacidad y términos.

`platform_org_provisioning.avatar_url` guarda la imagen subida únicamente para un ID de alta pendiente por el administrador verificado. Policy INSERT del bucket existente `business-branding` usa `private.can_upload_pending_business_brand(id)` y exige ruta `pending/{uuid}/logo.jpg` o `trainer.jpg`. RPC `platform_admin_attach_branding` valida que el objeto exista y que la URL coincida exactamente con el proyecto, bucket y negocio de la prealta. Al confirmar su correo y reclamar la prealta, `claim_platform_provisioning` copia la URL a `organizations.avatar_url`.

Las migraciones `20261027143000`–`20261027143004` están versionadas y aplicadas. No se exponen claves `service_role` al frontend.


## Hotfix de RLS — 27/10/2026

Migración **aplicada**: `20261027140000_fix_platform_membership_rls.sql`. Elimina una política redundante sobre `organization_memberships` que generaba `42501 permission denied for table platform_admin_delegations` en operaciones normales. La política `memberships_select_authorized` ya delega comprobación de roles en `private.has_org_role`, incluido el acceso temporal del administrador global. El ledger de delegaciones sigue sin SELECT para `authenticated`. Comprobación de acceso realizada como rol Postgres `authenticated`; listado de membresías y directorio de plataforma responden sin error.


- Migración complementaria aplicada: `20261027131000_platform_client_payment_ledger.sql` crea `business_client_payments` para cobros B2C verificados por proveedor (RLS habilitada, cero permisos directos de navegación; solo backend privilegiado). `platform_admin_finances` separa `payments` (B2B), `client_payments` (B2C) e `intents` (solicitudes no cobradas). No hay Stripe Connect activo.

Migración aplicada: `supabase/migrations/20261027120000_platform_admin_console.sql`.

Nuevas tablas (todas con RLS):
- `platform_org_controls`: suspensión/reactivación administrativa de una organización con motivo y actor.
- `platform_org_provisioning`: solicitud de alta por correo del futuro propietario y estado; `claim_platform_provisioning` crea organización y membresía owner mediante trigger **solo** para email confirmado que coincide.
- `platform_admin_delegations`: actor, organización, motivo, caducidad (30 min) y revocación.
- `platform_admin_events`: auditoría administrativa de creación, reclamación, suspensión, apertura y cierre de delegación.
- `platform_billing_payments`: transacciones B2B con céntimos, divisa, referencia única de proveedor, fecha y estado; **no implica Stripe conectado**.

Los wrappers de lectura y acciones en `public` son invoker; la lógica privilegiada y la validación de `platform_admin` están en `private`. `private.has_org_role` conserva la membresía real y admite de manera temporal los permisos administrativos del negocio en delegación, sin acceso a roles exclusivos de atleta. Si la organización está suspendida, sus miembros ordinarios pierden los privilegios de empresa hasta reactivación.

`platform_admin_directory` ofrece recuentos de clientes/sesiones y campos públicos; `platform_admin_finances` distingue pagos verificados de `business_subscription_intents` que siguen siendo simples solicitudes. Los negocios no se crean a nombre del superadministrador: el registro pendiente se reclama desde la cuenta verificada del titular. El plan solicitado en una prealta es de referencia, sin activación ni cobro.

Pendiente: integración Stripe Billing/Connect, webhooks verificados, almacenamiento/conciliación de cobros de clientes B2C, facturación fiscal y tests E2E de tenant con JWT reales.

# Base de datos — Repera
Última actualización: 2026-10-20 (profiles.avatar_url; ensure search_discoverable_organizations).

**Proyecto autorizado:** `uvzgujlrqohreoucirms` (eu-west-1, PostgreSQL 17).
**Migraciones aplicadas:** `20261019190623_business_foundation_secure`, `20261019193414_business_clients_scoped`, `20261019201141_business_org_invitations_consent` y `20261019201248_business_invitation_private_rpc`, `20261019201914_business_services_booking_wallets`, `20261019203258_business_professional_training_sessions` y `20261019210032_business_service_availability`.
La migración antigua `20261015120000_init_repera.sql` **no se aplicó** y fue sustituida en esta rama; no volver a ejecutarla desde `main`.

## Tablas implantadas
| Tabla | Uso | Política básica |
|---|---|---|
| `profiles` | Identidad ligada a `auth.users` (`display_name`, `avatar_url`) | Propietario; UPDATE `display_name` + `avatar_url`; JPEG en bucket Storage `profile-avatars` |
| `organizations` | Tenant y tipo | Miembros activos leen; owner/admin modifica nombre |
| `organization_memberships` | Roles/estado por tenant | Usuario propio y gestores leen; cliente no puede modificar |
| `exercises` | MVP personal y catálogo del sistema | Ejercicio de sistema o propio |
| `routines` | MVP personal | Solo owner |
| `routine_exercises` | Ítems de rutinas | Vía rutina propia |
| `workouts` | MVP personal (sin sync móvil) | Solo owner |
| `workout_sets` | Series | Vía workout propio |

| `clients` | Cliente por empresa (vinculación consentida) | Owner/admin y entrenador asignado, solo la propia ficha al deportista |
| `staff_client_assignments` | Entrenador asignado a cliente | Sin mutaciones directas; solo consulta de interesados |
| `organization_invitations` | Invitaciones verificadas, aceptación/cancelación | Gestores y destinatario verificado, sin escritura directa |

Invitaciones: propietario/administrador llama `issue_org_invitation`; destinatario registrado con correo **confirmado** llama `accept_org_invitation`; el backend crea membresía + vínculo de cliente si es deportista. Las tres RPC son wrappers `SECURITY INVOKER` que llaman a funciones protegidas en `private`. Aún falta notificación por correo y login móvil con Apple en Supabase.

Funciones de trigger y helper en esquema `private`: `handle_new_user`, `bootstrap_organization_owner`, `has_org_role`. El helper verifica `auth.uid()` y membresía activa. `service_role` y el rol DB administrador se mantienen únicamente en backend.

## Invariantes
La organización se crea con `created_by=auth.uid()` y un trigger crea su primer propietario; UNIQUE(organization_id,user_id) evita duplicidad. Desde el cliente no se puede insertar/editar miembros. RLS en las ocho tablas. Ningún usuario/organización de prueba quedó persistido.

## Servicios reales (migración 20261019201914)
- `service_occurrences`: clase o cita 1:1, entrenador, inicio/fin, aforo, estado. Trigger comprueba rol activo y evita solapamientos simultáneos de entrenador.
- `service_passes`: bonos de cortesía separados por tipo de servicio (clase/cita), cliente vinculado, validez y créditos disponibles.
- `service_bookings`: reserva con identidad verificada, petición idempotente y estado.
- `service_credit_ledger`: concesión manual, consumo y devolución auditable; no refleja ingresos.
- RPCs publicadas como wrappers SECURITY INVOKER hacia funciones privadas: `grant_complimentary_pass`, `book_service_occurrence`, `cancel_service_booking`.
- La política provisional devuelve un crédito si la cancelación ocurre más de 12 h antes del evento; confirmar norma y excepciones con el negocio antes de cobros o producción.
- Suite de pruebas SQL real: `supabase/tests/business_booking_smoke.sql`. Concurrencia simultánea cliente-cliente requiere ensayo e2e paralelo adicional.

## Próximas migraciones
Tablas de invitaciones con token de un solo uso; enlaces entrenador-cliente y consentimiento con revocación; sedes/salas; versión/asignación de planes; clases/aforo/reservas/espera/créditos; catálogo comercial B2B y pagos B2C separados, webhooks y auditoría. Definir idempotency keys y transacciones atómicas por operación.

## Entrenamientos profesionales (20261019203258)

Tabla `professional_training_sessions`: identificador, organización, cliente vinculado, coach emisor, fecha, título, instrucciones, prescripción JSON y estado. Solo se puede publicar mediante RPC validada e idempotente; la escritura directa está revocada. RLS permite lectura únicamente al atleta vinculado, al profesional asignado y al administrador del centro; no comparte workouts personales. `assign_coach_client` valida miembro con rol coach activo, cliente vinculado y gestor autorizado. `supabase/tests/professional_sessions_smoke.sql` prueba los límites.

## Aforo real (20261019210032)

`public.get_service_availability(p_org)` expone únicamente `occurrence_id`, plazas reservadas y capacidad para miembros activos de una organización. Utiliza wrapper `SECURITY INVOKER` y comprobación privada del rol; no devuelve datos de otras reservas. El recuento no sustituye `book_service_occurrence`, que revalida aforo en la transacción. La aplicación bloquea la reserva cuando el RPC no retorna información suficiente. Smoke: `supabase/tests/availability_rls_smoke.sql`.
