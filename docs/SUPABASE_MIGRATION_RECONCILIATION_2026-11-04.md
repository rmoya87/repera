# Reconciliación de versiones Supabase — 4 de noviembre de 2026

## Objetivo

Conservar el SQL histórico y evitar que `supabase db push` vuelva a ejecutar cambios ya ejecutados sobre producción por haber cambiado los timestamps de los archivos.

## Evidencia comprobada

- Proyecto: `uvzgujlrqohreoucirms`.
- Al comparar `supabase_migrations.schema_migrations.statements[1]` con los archivos fuente originales, **44 pares son idénticos byte a byte salvo espacios finales**.
- **2 pares son semánticamente equivalentes** y difieren solo en comentarios o formato, no en instrucciones SQL: publicación de `ai_training_plans` en Realtime y eliminación de la política `memberships_platform_delegated_read` con recarga de PostgREST.
- Se restituyen los **46 timestamps realmente aplicados por Supabase**, conservando los nombres descriptivos de los archivos. No se modifica ninguna fila de datos ni el historial de producción.
- Antes: 48 versiones compartidas, 80 solo en git y 46 solo en remoto. Después de estos renombrados: **94 versiones compartidas, 34 solo en git, 0 solo en remoto** antes de desplegar los últimos cambios de catálogo.
- No se presume que las 34 restantes estén todas pendientes: existen funciones/objetos de varias sin historial y faltan otras (p. ej. las 4 tablas de notificaciones).

## Migraciones del catálogo aplicadas a producción

El 04/11/2026 se aplicaron **atómicamente** las siguientes migraciones DML, registrando simultáneamente su versión y texto original en `supabase_migrations.schema_migrations`:

- `20261103220000_native_catalog_ai_metadata_parity.sql`
- `20261103221000_native_equipment_metadata_parity.sql`
- `20261103233000_board_scan_ddb_stepup_rkbs.sql`

Primero se ejecutó una prueba transaccional con `ROLLBACK` y se confirmó que no dejó registros. Posteriormente se confirmaron `Step-up al cajón con doble mancuerna`, el alias `DDB Step Up`, `RKBS` y los metadatos de `Burpee to target`; las tres versiones constan como aplicadas en producción.

**Estado tras estas tres migraciones: 97 versiones compartidas, 31 solo en git y 0 solo en remoto.** Las 31 restantes requieren verificación del esquema existente y de la cadena de despliegue.

## Regla de seguridad

No ejecutar `supabase db push` masivo mientras haya migraciones de schema sin historial que puedan estar parcial o completamente aplicadas. Revisar independientemente las 31 versiones restantes y proteger los datos de producción antes de corregirlas. Las migraciones de catálogo nuevas son DML idempotente, independientes del historial antiguo.

## Mapeo de renombrados verificados

| Versión remota (conservada) | Archivo previo |
|---|---|
| `20261021165932` | `20261021171000_ai_training_plans_realtime_publication.sql` |
| `20261021210911` | `20261021231500_ai_coach_profiles_calendar_catalog_programs.sql` |
| `20261021211642` | `20261021232000_seed_training_catalog_from_ios.sql` |
| `20261021211737` | `20261021232500_native_catalog_key_bridge.sql` |
| `20261021212050` | `20261021233000_ai_training_plan_idempotency.sql` |
| `20261021213713` | `20261021235000_complete_ai_catalog_muscle_mappings.sql` |
| `20261021215222` | `20261021235500_apple_profile_avatar_storage.sql` |
| `20261021215502` | `20261021235800_exercise_equipment_joint_demands.sql` |
| `20261021221822` | `20261022001000_ai_proposal_revision_and_soft_undo.sql` |
| `20261021222254` | `20261022002000_joint_demands_all_catalog.sql` |
| `20261021222922` | `20261022003500_new_photo_movements_crossfit.sql` |
| `20261021223428` | `20261022004000_ai_pat_scopes.sql` |
| `20261022044054` | `20261022070000_ai_access_tokens_scopes_column_grant.sql` |
| `20261022050145` | `20261022110000_mcp_change_inbox_custom_exercises_tz.sql` |
| `20261022051410` | `20261022113000_training_program_calendar_time_zones.sql` |
| `20261024164612` | `20261024162744_ai_oauth_connections.sql` |
| `20261027105322` | `20261027120000_platform_admin_console.sql` |
| `20261027110148` | `20261027131000_platform_client_payment_ledger.sql` |
| `20261027112147` | `20261027140000_fix_platform_membership_rls.sql` |
| `20261027115137` | `20261027143000_business_admin_directory_settings.sql` |
| `20261027115140` | `20261027143001_business_admin_athlete_directory.sql` |
| `20261027115143` | `20261027143002_business_admin_settings_rpc.sql` |
| `20261027115146` | `20261027143003_business_admin_pending_branding.sql` |
| `20261027115229` | `20261027143004_fix_athlete_role_text.sql` |
| `20261027121142` | `20261027153000_materialize_pending_centers.sql` |
| `20261027121517` | `20261027154500_pending_centers_email_privacy.sql` |
| `20261027123928` | `20261027170000_platform_admin_detail_views.sql` |
| `20261027124917` | `20261027173000_platform_trial_settings.sql` |
| `20261027141021` | `20261027181000_enrollments_and_operating_status.sql` |
| `20261027141140` | `20261027182000_athlete_activity_bulk_training.sql` |
| `20261027142949` | `20261027182500_fix_business_trial_insert_guard.sql` |
| `20261027152538` | `20261027184500_platform_center_visibility.sql` |
| `20261027153156` | `20261027185000_business_invitation_email_dispatch.sql` |
| `20261027154228` | `20261027185500_pending_owner_email_recovery.sql` |
| `20261027160015` | `20261027190000_discoverable_center_excludes_suspended.sql` |
| `20261027165916` | `20261027193000_athlete_unlink_and_professional_time.sql` |
| `20261027165922` | `20261027193500_business_pass_offers_catalog.sql` |
| `20261027170250` | `20261027194000_only_assigned_trainer_reads_results.sql` |
| `20261027181657` | `20261027201000_trainer_pass_attendance_seat_limit.sql` |
| `20261028144743` | `20261028165000_archived_athlete_business_snapshot.sql` |
| `20261028144908` | `20261028165500_archived_booking_requester.sql` |
| `20261028145343` | `20261028170000_archived_athlete_staff_assignment_rls.sql` |
| `20261028145502` | `20261028170500_archived_client_no_new_operations.sql` |
| `20261028145538` | `20261028171000_archived_service_credit_actor.sql` |
| `20261028150051` | `20261028171500_archived_client_guard_definer_rpcs.sql` |
| `20261103185104` | `20261103190000_athlete_workout_hard_delete.sql` |

Fuente: historial del proyecto Supabase y árbol de GitHub del 04/11/2026. No se han reejecutado SQL históricos.
