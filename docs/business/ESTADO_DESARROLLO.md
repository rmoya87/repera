# Estado de desarrollo — Repera Business
Última actualización: 2026-10-19.

## IMPLEMENTADO (verificado en Supabase Repera)
- Proyecto `uvzgujlrqohreoucirms` conectado y sano; PostgreSQL 17.
- Primera migración real: `20261019190623_business_foundation_secure` (registro en `supabase_migrations.schema_migrations`).
- Tablas públicas: profiles, organizations, organization_memberships, exercises, routines, routine_exercises, workouts y workout_sets. RLS activado en las ocho.
- Trigger de perfil con usuario de Auth; trigger para incorporar propietario al crear una organización.
- Acceso de miembros y managers con helper privado y validación de sesión; rol global no modificable por cliente.
- Primer smoke test transaccional RLS superado: dos usuarios de prueba, aislamiento y autorización negativa; ROLLBACK sin datos persistentes.
- Borrador antiguo `20261015120000_init_repera.sql`, no aplicado, sustituido por baseline seguro en esta rama.

## PROBADO
- `list_tables`: 8 tablas RLS=true.
- `list_migrations`: baseline registrada.
- `get_advisors(security)`: 0 lints al terminar.
- SQL de comprobación: `rls_smoke_pass`, organizaciones persistentes de prueba = 0.
- Estas pruebas NO constituyen auditoría integral ni validan la integración web/iOS.

## PENDIENTE
- Supabase Auth integrado en panel profesional, correo, recuperación y sesiones.
- Invitaciones, membresía administrada transaccionalmente y consentimientos.
- Asignaciones deportivas compartidas / versiones; reservas / aforo y créditos; Stripe.
- Web profesional real, Android, deep links, push, observabilidad, e2e.
- CI específico de migraciones y pruebas RLS sobre una base limpia, comprobación por usuarios reales.
- CI iOS heredado activado en PR #5: se observan fallos en varios checks del workflow; el conector no ha proporcionado pasos ni logs suficientes para atribuirlos al código o al entorno. No declarar CI superado.
- Revisión del prototipo local Repera Business v0.2 y sus 37 supuestas pruebas: archivos fuente no accesibles en este contexto.
- Validación manual iOS 27 (requiere Xcode/SDK), rendimiento y seguridad ofensiva.

## BLOQUEADO / requiere coordinación
- Material v0.2: ZIP y dos documentos enlazados a rutas sandbox de otro chat, no disponibles aquí.
- La configuración final de precios B2B, fiscalidad y productos Stripe no está aprobada.
- No se ha publicado panel web ni se han modificado datos iCloud.

## Git
Rama `feat/repera-business-platform`, derivada de `main` en `0f369a65669ef2a9b408eea9477194de7ffb6924`. No fusionar a `main` antes de revisar CI/seguridad. El proyecto Cafesito no se ha tocado.
