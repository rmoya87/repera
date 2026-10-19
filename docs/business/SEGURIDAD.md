# Seguridad multiempresa — Repera
Última actualización: 2026-10-19.

## Controles implantados
- RLS en **todas las ocho** tablas publicadas, política explícita `TO authenticated` y predicados de propietario / membresía.
- `profiles.role` no depende de `raw_user_meta_data` y la API solo dispone de UPDATE(display_name); no autoascenso.
- Todas las funciones SECURITY DEFINER del baseline viven en esquema **private** con `search_path=''`; no se publica una función privilegiada en `public`.
- Helper de membresía solo devuelve booleano asociado a `auth.uid()`, exige membresía activa, y no expone filas privadas.
- Trigger de alta de organización asigna propietario sin permitir INSERT arbitrario en membresías.
- Prohibido publicar `service_role` o secretos en iOS/Android/web; claves publishable/anon siempre sujetas a RLS.
- `get_advisors(type=security)` no reportó lints después de la migración (no sustituye pentest).

## Matriz inmediata
Atleta autenticado: solo perfil y contenido propio; si es miembro activo, consulta organización autorizada. Owner/Admin: consulta miembros y actualiza **nombre** de organización. Coach/Recepción: consulta información de organización, no miembros ajenos. Admin global: no dispone aún de API de soporte implementada; el campo role no habilita bypass. Sin sesión: sin permisos en tablas de aplicación.

## Pruebas realizadas
Se ejecutó SQL como rol authenticated para dos usuarios Auth temporales, verificando: alta perfil, incorporación automática owner, lectura owner, aislamiento de B frente a A, imposibilidad de INSERT suplantando otro usuario, rol global/membresía sin escritura cliente. ROLLBACK confirmó 0 orgs persistidas. Test reproducible en `supabase/tests/rls_smoke.sql`.

## Riesgos y pruebas pendientes
- Acceso explícito entrenador-deportista, consentimientos, borrado/retención GDPR, autorización por relación.
- Test suites para cada tabla y operación (INSERT/UPDATE/DELETE) con credenciales Auth reales y funciones administrativas.
- Estructura de webhooks con verificación de firma, idempotencia y audit logs.
- Evitar DELETE/UPDATE no autorizados por grants en futuros esquemas.
- Separar staging y producción y repetir advisors después de cada migración.
