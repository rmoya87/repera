# Contratos móviles — iOS/Android/backend
Última actualización: 2026-10-20.
Estado: propuesta; **no hay integración móvil publicada**.

## Principio
No sustituir `AppState` local ni el espejo iCloud de iOS. Supabase guardará principalmente identidad, organizaciones, relaciones, planes **compartidos** y asignaciones; no transferir automáticamente sesiones/series/salud. Android usará solución local-first y sync nativo a definir sin perder interoperabilidad.

## Implementación inicial Apple → Supabase (2026-10-19)
- `BusinessAuthStore.swift`: usa supabase-swift 2.55.4, Sign in with Apple nativo con nonce aleatorio/hash SHA-256, y sesión administrada por el SDK. Solo conecta a `uvzgujlrqohreoucirms.supabase.co` con clave pública.
- La primera autorización Apple intenta registrar/iniciar Supabase sin bloquear el modo local cuando no hay red o el provider falla. Usuarios previos: reconectar en Ajustes para intercambiar un ID token actualizado.
- Login de producto: Apple → Supabase en el **primer** acceso; en arranques siguientes basta Apple + (sesión Keychain o binding UserDefaults). Los datos de entreno siguen local/iCloud y se espejan cuando hay sesión.
- Tras conectar, iOS empuja `profiles.display_name` y el avatar JPEG a Storage `profile-avatars/{uid}/avatar.jpg` + `profiles.avatar_url` (`BusinessAuthStore.syncPublicProfile`). Espejo de entrenamientos vía `BusinessWorkoutSyncStore` (no Salud).
- Estado de conexión en Ajustes y logout complementario. Aún no se sincroniza agenda, membresías ni historial personal.
- Riesgos por verificar: Apple provider en Supabase, cuentas de correo oculto, duplicados identitarios, token inválido/nonce, renovación de sesiones, revocación, login TestFlight y cambios de credenciales.

## Identidad
`auth.uid()` vincula sesión Supabase a `profiles.id`. Sign in with Apple existente **no equivale automáticamente** a una sesión Supabase; diseñar e implementar puente de identidad seguro (OAuth/ID token y sesión) sin almacenar credenciales en texto plano. Android tendrá proveedor compatibles de Auth sin suplantación.

## Entidades compartidas existentes
`Organization(id,name,slug,kind,createdBy)` y `Membership(id,organizationId,userId,role,status)`. Campos en camelCase solo en SDK; en SQL snake_case. No se permite que el móvil elija un rol privilegiado. IDs: UUID; fechas: ISO 8601 UTC.

## Contratos futuros
`ClientConsent`, `TrainingPlanVersion`, `TrainingAssignment`, `ClassOccurrence`, `Booking`, `CreditLedgerEntry`, `NotificationDestination`. Definir versionado, caducidad, revocación, optimistic locking/idempotency keys y políticas de sincronización antes de conectar la app.

## Deep links (diseño)
Requerir destino exacto y autorización vigente, con fallback seguro si no hay permisos: plan asignado, clase, reserva, cambio de horario y mensaje relevante. Ningún payload de push con secretos o datos clínicos.

## Sesiones individuales en Center

La agenda compartida v1 admite eventos `kind=appointment` junto a `training` y `class`. Los eventos individuales llevan `booking_id` cuando exista reserva y usan un enlace interno de la forma `repera://appointments/{appointmentId}` (no URL externa). El backend debe validar siempre propietario, vínculo profesional, estado de reserva y permisos de lectura al resolver el enlace.

Las **clases** consumen los derechos del producto de clases y las **citas individuales** los del producto de entrenador personal. No convertir créditos de uno en otro silenciosamente. El backend debe ofrecer intervalos disponibles y reservas atómicas; ambos tipos de reserva se mostrarán de forma aditiva en Inicio, sin borrar rutinas locales o historial iCloud. Este contrato todavía no implica endpoints disponibles.

## Datos de servicios en iOS (implementación inicial)

`BusinessDataStore.swift` consulta `organizations`, `organization_invitations`, `clients` (para filtrar las fichas del usuario), `service_occurrences`, `service_passes` y `service_bookings` directamente con la sesión Supabase autenticada. RLS sigue siendo la frontera de seguridad; la selección local adicional por `client_id` es para evitar mostrar reservas ajenas a un usuario que también administre un centro.

`CenterView`: selección Clases/Citas, acciones aceptar invitación, reservar por bono compatible y cancelar; `HomeView`: reservas confirmadas del día; `SettingsView`: centros y saldos por tipo de servicio. La programación profesional en Diario y el histórico de entrenamientos permanecen sin sincronizar hasta publicar versiones de planes. No se suben entrenamientos privados.
