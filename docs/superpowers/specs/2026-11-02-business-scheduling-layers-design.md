# Diseño: planificación unificada Business (capas)

Última actualización: 2026-11-02.

## Objetivo

Cubrir box CrossFit, gimnasio multi-actividad y centro multi-sala con un **modelo unificado por capas**, sin productos verticales separados. Staff gestiona en web; apps atleta consumen.

## Decisiones

| Tema | Decisión |
|------|----------|
| Alcance | Unificado box + gym + multi-sala |
| Contenido | Programa del día + override por clase |
| Salas | Híbridas: opcionales según ajustes del centro |
| Open gym | Con aforo gestionable (`kind=open_access`) |
| Configuración | Ajustes de operación por organización |

## Capas

1. **Recursos** — `facility_rooms` (capacidad, activo).
2. **Oferta** — `activity_types` + `service_series` (serie viva) → `service_occurrences` (`class` \| `appointment` \| `open_access`).
3. **Programa** — `day_programs` (fecha + ámbito global / activity_type / room); override en `service_occurrence_details.prescription`.
4. **Demanda** — `service_bookings` / waitlist / ledger (eje existente).

## Resolución de contenido

1. Override en la occurrence →
2. `day_program` del día (mismo `activity_type_id` o `room_id` según ámbito) →
3. Sin entreno.

## Aforo

`effective_capacity = least(occurrence.capacity, room.capacity)` si hay sala; si no, `occurrence.capacity`. Open gym usa el mismo mecanismo de plazas.

Anti-solape: coach (existente) + sala cuando `room_id` no es null.

## Ajustes de operación (`org_operation_settings`)

- `profile`: `box` \| `gym_multi` \| `hybrid_rooms` \| `pt`
- `use_rooms` boolean
- `day_program_enabled` boolean
- `day_program_scope`: `global` \| `activity_type` \| `room`
- `open_access_enabled` boolean
- `open_access_requires_booking` boolean (reserva previa vs check-in recepción)
- `cancel_credit_hours` int (sustituye hardcode 12 h)
- Defaults según perfil en onboarding; editables en Ajustes → Operación.

## Matriz casuística × perfil × superficie

| Casuística | Box | Gym multi | Multi-sala | Web | Apps |
|---|---|---|---|---|---|
| Horarios fijos / varias clases/día | Sí | Sí | Sí | Agenda + series | Center lista |
| WOD del día compartido | Sí | Opcional | Por tipo/sala | Programa del día | Detalle resuelto |
| Override por clase | Sí | Sí | Sí | Detalle slot | Detalle |
| Salas + conflicto | Off default | On | On | CRUD + columnas | Filtro/etiqueta |
| Open gym con aforo | Opcional | Sí | Sí | Serie open_access | Segmento Acceso libre |
| Citas 1:1 / PT día | Sí | Sí | Sí | Agenda PT | Citas / Inicio |

## RPCs nuevas / ampliadas

- `upsert_org_operation_settings` / `get_org_operation_settings`
- CRUD `facility_rooms`, `activity_types`, `day_programs`
- `create_service_series` → escribe `service_series` + `series_id` en occurrences
- `manage_service_series` (esta / esta y siguientes)
- `resolve_occurrence_training(occurrence_id)` → prescription efectiva
- `get_org_schedule_bundle(org_id)` → settings públicos + rooms activas + occurrences con contenido resuelto (miembros)
- Cancelación atleta usa `cancel_credit_hours` de la org

## Apps

- Center: Clases / Citas / Acceso libre (si enabled)
- Mostrar sala si `use_rooms`; filtro si ≥2 salas
- Inicio: cards reserva+plan; open gym sin fingir WOD
- Sin panel de gestión staff

## Fuera de alcance

Multi-sede como tenant, panel coach nativo, Stripe, QR check-in avanzado.

## Criterio de éxito

Un box publica un WOD del día y todas las clases lo muestran sin copiar; un gym multi-sala no solapa dos clases en la misma sala; open gym limita plazas; el centro configura su perfil en Ajustes; el atleta ve solo lo relevante.
