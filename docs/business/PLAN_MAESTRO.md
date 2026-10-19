# Repera Business — Plan maestro
Última actualización: 2026-10-19. Estado: desarrollo incremental; no producto comercial completo.

## Objetivo y segmentos
- Deportista: iOS 27+ SwiftUI/Watch (existente); Android Kotlin/Jetpack Compose (pendiente). Sin web para deportistas.
- Profesional: entrenador independiente, gimnasio o centro deportivo. Panel web estático, compatible con Apache de IONOS.
- Operación: administración Repera separada de la de cada organización.
- Cobros B2B de Repera a profesionales **distintos** de pagos B2C de profesionales a deportistas. Precios configurables, no fijados en SQL.

## Arquitectura adoptada
Monorepositorio rmoya87/repera. Backend exclusivo Supabase uvzgujlrqohreoucirms en eu-west-1. Datos deportivos personales local-first/iCloud en Apple; en Android, estrategia nativa por especificar. Backend para identidad, relaciones profesionales, asignaciones compartidas, reservas y operaciones económicas; minimización de datos. Web profesional separada de `web/` (marketing estático actual); nunca requerir un proceso Node residente en IONOS.

## Fases y criterios de aceptación
| Fase | Entregable | Estado | Criterio de aceptación |
|---|---|---|---|
| 0 Auditoría | Repo, migraciones, Supabase, CI | PARCIAL | Revisar prototipo v0.2 adjunto cuando esté accesible |
| 1 Identidad y seguridad | Auth, roles y RLS | PARCIAL | Autenticación real web/móvil, pruebas de aislamiento y ciclo de sesiones |
| 2 Organizaciones | Clientes, entrenadores, invitaciones | PENDIENTE | Consentimiento explícito, revocación y operaciones transaccionales |
| 3 Web profesional | Panel conectado y usable | PENDIENTE | Sin datos simulados en módulos declarados completos |
| 4 Programación | Ejercicios, planes, grupos, versiones | PENDIENTE | Assign/revoke idempotente, contratos móviles comprobados |
| 5 Clases | Reservas, aforo, espera, créditos | PENDIENTE | Última plaza y concurrencia verificadas |
| 6 Móvil | iOS existente y Android nativo | PENDIENTE | Compatibilidad, deep links y modo offline |
| 7 Notificaciones | Push y sincronización | PENDIENTE | Deep links exactos y deduplicación |
| 8 Facturación | B2B/B2C y Stripe | PENDIENTE | Webhooks idempotentes, impuestos y conciliación |
| 9 Admin | Repera operaciones | PENDIENTE | Trazas y permisos restringidos |
| 10 Entrega | E2E, seguridad, rendimiento | PENDIENTE | Sin riesgos críticos; controles observables |

## Casos límite obligatorios
Dos clientes compitiendo por una plaza; reservas repetidas; créditos agotados/caducados; cancelaciones tardías; subida y bajada en lista de espera; duplicación de webhooks; error de red/offline; transferencias entre entrenadores o sedes; cambios de plan publicado; consentimiento revocado; accesos cruzados; permisos por tenant; exportación/borrado GDPR.

## Decisiones pendientes
Diseño de consentimientos y retención; política de sincronización Android; proveedor de emails de invitación; pagos/fiscalidad/IVA; límites y tarifas comerciales; entorno staging antes de desplegar operaciones económicas; seguridad y estrategia de despliegue de panel profesional.

## Experiencia móvil aprobada (2026-10-19)

En la navegación del deportista: **Inicio / Diario / Center / Progreso / Ejercicios**.
- **Inicio:** resumen personal del día más planes prescritos y clases confirmadas. Botón + abre herramientas antes incluidas en Crear. No ocultar entrenamiento libre ni logs.
- **Diario:** planificación que publica el entrenador personal como vista principal; mantener acceso a «Personal» y «Rutinas». En ausencia de entrenador conectado, estado vacío honesto sin perder datos previos.
- **Center:** catálogo y calendario de clases del gimnasio o gimnasios vinculados; confirmar/anular reserva, espera, horarios y cupos reales. Las reservas confirmadas se reflejan en Inicio.
- **Ajustes:** varias afiliaciones/entrenadores y detalle de productos externos contratados (bonos, sesiones usadas/disponibles, vencimiento, suspensión y próxima renovación); gestión del contrato mediante operaciones autorizadas. Repera Pro de Apple permanece separado.

**Dependencias no implementadas:** identidad Apple→Supabase y relación consentida, publicación de planes, eventos en agenda móvil, reservas transaccionales, catálogo de servicios y saldos, webhooks/pagos, notificaciones y deep links.

**Decisiones de producto pendientes de validación:** qué hacer cuando el usuario tenga varios entrenadores y gimnasios; visibilidad de planes personales junto al plan profesional; cancelación/reembolso de reservas y bonos; qué significa «gestionar» (renovación, baja, cambio de plan, congelación) según contrato y normativa aplicable. Defaults seguros: agregación ordenada por centro, origen claramente etiquetado, no auto-compras, no publicar historial/Salud sin consentimiento, no prometer reintegro hasta transacción confirmada.

## Confirmación de producto: Center → Clases y Citas (2026-10-19)

- **Clases**: actividades grupales con aforo y lista de espera; reservas y cancelaciones gestionadas mediante transacciones servidor. Los permisos y créditos se comprueban en cada reserva.
- **Citas**: sesiones **1:1** con entrenador personal (independiente o perteneciente a un centro), sobre huecos ofrecidos por el profesional. Cada cita ocupa un bloque de tiempo exclusivo del entrenador y, si aplica, de una sala. No hay lista de espera por defecto para citas 1:1.
- **Contratos separados**: un bono de gimnasio no paga automáticamente una cita con entrenador ni viceversa. Los productos indican tipo de servicio, emisor, crédito/saldo, validez y condiciones particulares; el cliente puede pertenecer a varios centros y contratar distintos entrenadores.
- **Inicio y Ajustes**: tanto citas confirmadas como clases confirmadas aparecen en el día de Inicio; Ajustes muestra contrato, sesiones restantes, renovaciones y caducidad por profesional/centro, sin confundirlo con Repera Pro.
- **Concurrencia e idempotencia**: bloquear un hueco de entrenador y su eventual recurso físico, evitar doble reserva en franjas solapadas, reintentos seguros y prohibir saldo negativo. Las cancelaciones siguen reglas explícitas del emisor y actualizan el ledger en la misma transacción.
- **Privacidad**: compartir reservas con el profesional/centro solo según vínculo autorizado. Nunca compartir historial local/HealthKit al confirmar una cita.

**Estado actual:** selector Clases/Citas implementado en SwiftUI y contrato de agenda ampliado a `kind=appointment` en Swift/Kotlin; no hay disponibilidad ni reservas reales desplegadas en Supabase ni conectadas a iOS. La disponibilidad, las citas, la conciliación de bonos y las políticas de cancelación deberán tener pruebas backend y E2E antes de habilitar acciones de pago/reserva.
