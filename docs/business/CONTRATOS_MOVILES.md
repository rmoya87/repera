# Contratos móviles — iOS/Android/backend
Última actualización: 2026-10-19.
Estado: propuesta; **no hay integración móvil publicada**.

## Principio
No sustituir `AppState` local ni el espejo iCloud de iOS. Supabase guardará principalmente identidad, organizaciones, relaciones, planes **compartidos** y asignaciones; no transferir automáticamente sesiones/series/salud. Android usará solución local-first y sync nativo a definir sin perder interoperabilidad.

## Identidad
`auth.uid()` vincula sesión Supabase a `profiles.id`. Sign in with Apple existente **no equivale automáticamente** a una sesión Supabase; diseñar e implementar puente de identidad seguro (OAuth/ID token y sesión) sin almacenar credenciales en texto plano. Android tendrá proveedor compatibles de Auth sin suplantación.

## Entidades compartidas existentes
`Organization(id,name,slug,kind,createdBy)` y `Membership(id,organizationId,userId,role,status)`. Campos en camelCase solo en SDK; en SQL snake_case. No se permite que el móvil elija un rol privilegiado. IDs: UUID; fechas: ISO 8601 UTC.

## Contratos futuros
`ClientConsent`, `TrainingPlanVersion`, `TrainingAssignment`, `ClassOccurrence`, `Booking`, `CreditLedgerEntry`, `NotificationDestination`. Definir versionado, caducidad, revocación, optimistic locking/idempotency keys y políticas de sincronización antes de conectar la app.

## Deep links (diseño)
Requerir destino exacto y autorización vigente, con fallback seguro si no hay permisos: plan asignado, clase, reserva, cambio de horario y mensaje relevante. Ningún payload de push con secretos o datos clínicos.
