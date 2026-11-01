# ADR — Decisiones Business V3 (tanda P0, 2026-11-01)

Estado: aceptado para esta tanda. No implica merge a `main` ni producción.

## Contexto

El plan maestro V3 y la revisión UX exigen Fase 0 antes de features. Esta tanda cubre auditoría + P0 de consola Business web.

## Decisiones

### 1. Cobro externo declarado ≠ cobro verificado

- `business_issue_offline_pass` / `issuance_type=manual_offline` registran que el profesional **declara** haber cobrado fuera de Repera.
- Etiqueta de UI: «Confirmado por el centro» / «Asignación externa». Nunca «Pagado con Stripe» ni «Verificado por proveedor».
- `business_client_payments` / webhooks quedan para fases posteriores.

### 2. Cupos B2B

- Objetivo de producto: contar **personas distintas con vínculo aceptado y contrato comercial elegible**.
- Hoy el trigger PT `enforce_trainer_client_limit` cuenta clientes vinculados con estado activo/trial/paused (no solo con bono).
- **No se cambia el trigger en esta tanda** sin dry-run de datos y migración atómica. Se documenta la discrepancia en `USE_CASE_COVERAGE` / estado.

### 3. Pro patrocinado por negocio

- **Aplazado** hasta evaluación explícita App Store / Play (apartado 10.6 del plan maestro).
- No conceder Pro por invitación, cortesía ni UI local.

### 4. Recordatorio push 60 minutos

- **Aplazado.** Esquema real: `business_client_notifications` in-app. `notification_outbox` solo en greenfield no aplicado.
- No implementar cron/Edge/FCM en esta tanda.

### 5. Asistencia de clase (gimnasio)

- Al reservar (`book` / `enroll_managed_client`) ya se descuenta crédito (`booking_debit`).
- Marcar `attended` / `no_show` es transición de estado de la reserva **sin segundo descuento**.
- Cancelar clase/reserva sigue las reglas de crédito existentes.

### 6. Consola PT agenda-first (2026-11-01)

- Nav PT: Agenda + Clientes; ajustes solo vía identidad clicable.
- Agenda mes/día (`data-agenda-view`); cita 1:1 asignable con enroll/cortesía para la app del cliente.
- Modales `pt-sheet` (Avisos, Solicitudes, Invitar, Crear cita, Entreno).
- Clases de gym asignadas al coach: `coach_ack` + RPCs list/ack/reschedule/cancel; cobro de tarifas externo con `billing_model`.
- App móvil: atleta ve cambios de horario/cancelación; sin panel de gestión coach.

### 7. Stack UI

- Se mantiene la SPA vanilla en `web/console/` (sin React).
- Skills de diseño aplicadas: `emil-design-eng` (jerarquía, una CTA, sin animación ornamental). `break-ui` se usará en revisión de formularios críticos.
