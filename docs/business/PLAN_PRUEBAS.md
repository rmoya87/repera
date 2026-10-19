# Plan de pruebas — Repera Business
Última actualización: 2026-10-19.

## Ejecutadas sobre Supabase Repera
- Consulta de proyecto: ACTIVE_HEALTHY, PostgreSQL 17.
- Migraciones: siete versiones `20261019190623`–`20261019210032`; tablas públicas: **16**, RLS todas true.
- Advisors de seguridad: cero lints reportados.
- `supabase/tests/rls_smoke.sql`: dos identidades simuladas en transacción, verificación de trigger, owner, RLS cross-tenant, permisos de rol y SQL de suplantación rechazado; ROLLBACK y 0 orgs persistidas.

- SQL adicional probado: `clients_rls_smoke`, `invitation_rls_smoke`, `business_booking_smoke`, `professional_sessions_smoke` y `availability_rls_smoke`, usando usuarios temporales y ROLLBACK. Esto no sustituye pruebas de carga simultáneas ni Auth E2E.
- El CI remoto falla antes de ejecutar los steps incluso para checks que no requieren Xcode. Su diagnóstico operativo se mantiene en `docs/business/RELEASE_GATE.md`.

## Próximas automatizaciones
1. En CI de backend, aplicar todas las migraciones desde cero y verificar que el baseline se despliega sin depender del estado remoto.
2. Probar dos organizaciones y varios roles: owner/admin/coach/reception/athlete; membresía suspended/revoked; staff no puede consultar datos privados de otros.
3. Mutaciones negativas: UPDATE(created_by), UPDATE(role), INSERT memberships, DELETE de terceros, read/write anónimos.
4. Invitaciones: token caducado/reutilizado, cambio de correo, organización equivocada, consentimientos revocados.
5. Concurrencia reservas: una plaza; idempotencia de cancelaciones y reposición de crédito.
6. Pagos/webhooks: firma inválida, reintentos, duplicados, conciliación y distintos merchant accounts.
7. Pruebas iOS 27 en Xcode, Android Gradle/Compose, compilación web estática y rutas bajo Apache IONOS.
8. Security + performance advisors y pruebas end-to-end contra staging; ninguna prueba debe borrar datos productivos.

## Estado de cobertura
La prueba RLS inicial es un smoke test real, **no** valida toda la seguridad ni la autenticación web, el CI o la plataforma profesional. No dar por superadas las supuestas 37 pruebas del prototipo v0.2 sin su código.
