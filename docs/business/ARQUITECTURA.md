# Arquitectura objetivo — Repera Business
Última actualización: 2026-10-19.

## Situación real
El monorepo alberga `Apps/Repera`, Watch, widget, paquete `Packages/ReperaDomain` y `web/`, hoy sitio marketing estático, no panel profesional. El historial deportivo permanece en JSON local + espejo iCloud; el backend NO reemplaza `ReperaStore` ni activa subida automática.

## Capas previstas
1. iOS/watchOS 26+ SwiftUI nativo; Android Kotlin + Jetpack Compose API 30+.
2. Panel administrativo/profesional **separado** del marketing, compilable como archivos HTML/CSS/JS estáticos para IONOS Apache. Autenticación y llamadas HTTPS a Supabase; **jamás** claves secret/service_role en el bundle.
3. Supabase Repera: Auth, Postgres RLS, lógica transaccional para operaciones de negocio, Edge Functions para webhooks/notificaciones sensibles, Storage privado según autorización.
4. Espejo de datos deportivos personales local/cloud nativa según cada plataforma; en Supabase únicamente compartidos necesarios, mediando consentimiento.

## Tenencia y roles
`organizations` tiene tipo personal_trainer/gym/sports_center. `organization_memberships` registra owner/admin/coach/reception/athlete con estados. El `profiles.role` heredado **no** concede acceso cruzado ni se puede autoelevar. Acceso profesional a datos del deportista exige relación válida y consentimiento todavía por modelar.

## Modelo de extensibilidad
Separar contratos B2B de Repera y cobros B2C de cada organización; planes/precios/límites en tablas específicas futuras. Definir versiones de planes asignados para no alterar históricos.

## Riesgos actuales
No hay integración Auth con web/móvil ni API de invitaciones. Falta plan de pruebas de aceptación, modelo de consentimiento, reservas transaccionales, pagos y esquema de observabilidad. No promocionar prototipos a estado IMPLEMENTADO.
