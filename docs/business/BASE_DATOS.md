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
