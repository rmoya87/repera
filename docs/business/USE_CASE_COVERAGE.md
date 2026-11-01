# Cobertura de casos de uso Business (A–F)

Última actualización: 2026-11-01.

Fuente: revisión UX V3 + plan maestro Business V3. **Estado = código/esquema real**, no intención de producto.
P0 = bloqueante para el MVP operativo Business web de esta tanda.

Leyenda de resultado: `hecho` · `parcial` · `pendiente` · `aplazado` (fuera de esta tanda).

| ID | P0 | Actor | Precondición | Ruta UI | API / RPC | Estados UI | Prueba | Resultado |
|---|---|---|---|---|---|---|---|---|
| A01 | sí | Entrenador/gym | Org activa, rol owner/admin | Clientes → Invitar | `issue_org_invitation` + Edge `repera-business-invite` | loading/empty/error envío | `invitation_rls_smoke.sql`, UI consola | parcial (email depende de secretos) |
| A02 | sí | Gimnasio | Idem | Idem | Idem | idem | idem | parcial |
| A03 | sí | Deportista | Token caducado/revocado/usado | `?invitation=` / join | `accept_org_invitation` | error útil | SQL smoke | parcial (UI mensajes a endurecer) |
| A04 | sí | Deportista | Email invitación ≠ cuenta | join | accept RPC | rechazo | pendiente E2E | parcial |
| A05 | no | Deportista | Apple Private Relay | join / iOS | accept | pendiente dispositivo | pendiente | pendiente |
| A06 | sí | Negocio | Segunda invitación mismo email | Clientes | issue cancela pendiente previa | aviso | SQL | parcial |
| A07 | no | Deportista | Invita abierta | join | (rechazo UI) | — | — | pendiente (no hay decline RPC dedicada en UI) |
| A08 | sí | Deportista | Varias orgs | Ajustes app / varias fichas | accept × N | vínculos aislados | SQL multi-org | parcial |
| A09 | sí | Negocio | Solicitud desde app | Inicio «Quieren entrenar» | `business_decide_enrollment` | accept/reject | UI+RPC | hecho (backend) |
| A10 | sí | Deportista | Email no verificado | join | accept exige verificado | error | SQL | parcial |
| A11 | no | — | Menor / consentimiento edad | — | — | — | — | pendiente producto |
| A12 | sí | Negocio | Org suspendida / owner pendiente | Workspace | trial/status guards | bloqueo altas | parcial | parcial |
| A13 | no | Usuario | Cambio de cuenta mid-flow | join | sesión | — | E2E | pendiente |
| A14 | no | Negocio | Cliente provisional | Clientes | update status | — | — | parcial |
| A15 | sí | Negocio/atleta | Vínculo con reservas futuras | Ficha / unlink app | `athlete unlink` RPCs | aviso | migraciones 27193000 | parcial |
| A16 | no | Negocio | Reactivación | Ficha | update client | sin Pro retroactivo | — | pendiente |
| A17 | no | Coach | Multi-centro | select org | memberships | — | — | parcial |
| A18 | sí | Sistema | Ya vinculado otra vía | invite/accept | anti-duplicado | — | SQL | parcial |
| A19 | sí | Negocio | Fallo Resend | Invitar | Edge 503 | «no enviado» | unit auth | parcial |
| A20 | no | Negocio | Cambio marca post-invite | — | branding | — | — | pendiente |
| B01 | sí | Negocio | Cobro externo hecho | Ficha → Asignar bono / Productos y bonos | `business_issue_offline_pass` | confirmación manual | `business-360.test.mjs` | hecho (UI+RPC; email/E2E staging pendiente) |
| B02–B06 | sí | Negocio/atleta | Varios/cero/caducado/futuro | Ficha / Center app | passes + book RPC | mensajes | booking smoke | parcial |
| B07–B11 | no | Negocio | Cuota/congelación/devolución | — | ledger parcial | — | — | pendiente |
| B12 | sí | Sistema | Reserva vs consumo | book/cancel | ledger `booking_debit` | — | smoke | hecho (provisional 12h) |
| B13–B15 | sí | Atleta/gym | Cancel / no-show / clase cancelada | Clases 360 | cancel + mark attendance P0 | — | — | parcial |
| B16 | sí | Sistema | Bono PT ≠ gym | book | kind check | error | smoke | hecho |
| B17–B28 | mixto | — | Varios comerciales | — | — | — | — | pendiente / aplazado |
| C01 | sí | Atleta | Vínculo + bono | Center app / Clases web | availability + book | — | parcial iOS | parcial |
| C02 | sí | Atletas | Última plaza | book RPC | aforo atómico | — | smoke | hecho (SQL) |
| C03 | no | Atleta | Lista espera | — | — | — | — | pendiente |
| C04 | sí | Atleta/staff | Reserva booked | cancel RPC | crédito según ventana | — | smoke | hecho |
| C05–C07 | parcial | Gym | Editar/cancelar clase | Clases 360 | `manage_service_occurrence` / cancel | — | UI | parcial |
| C08–C09 | sí | PT | Cita 1:1 | Inicio agenda | create series + book | conflictos | smoke | parcial |
| C10–C12 | no | — | Bloqueos / TZ / recurrentes | series create | parcial | — | — | pendiente |
| C13 | sí | Atleta | Lleno / sin bono | book | rechazo | UI | — | parcial |
| C14 | no | Atleta | Offline | app | — | — | — | pendiente |
| C15 | sí | Recepción | Clase del día | Inicio / detalle clase | `business_mark_class_attendance` | confirmación | tests UI + migración | hecho (aplicar migración en staging; E2E físico pendiente) |
| C16–C25 | mixto | — | Varios | — | — | — | — | pendiente |
| D01–D04 | sí | PT | Cliente vinculado | Ficha Entrenamientos | publish/update/cancel session | — | UI+RPC | parcial |
| D05–D18 | mixto | Atleta/PT | Consentimiento | app + `get_shared_athlete_results` | — | — | — | parcial / pendiente |
| E01–E18 | — | — | Pro / B2B | — | RevenueCat / trials | — | — | **aplazado** (gate tiendas) |
| F01–F08 | — | Sistema | Push 60 min | — | outbox no en migraciones | — | — | **aplazado** |
| F09 | parcial | Negocio | Email invite | Edge Resend | — | — | — | parcial |
| F10–F12 | sí | Admin | Delegación / roles / RLS | platform-admin | delegate RPCs | — | SQL | parcial |
| F13–F18 | no | — | RGPD / offline / i18n | — | — | — | — | pendiente |

## Inventario rápido backend (2026-11-01)

**Migraciones aplicadas (`supabase/migrations/`):** foundation, clients, invitations, booking wallets, 360 ops, groups/recurrence, pass offers, trainer offline pass + attendance PT, platform admin, enrollments, archive guards, Play billing ownership.

**Greenfield NO aplicado (`supabase/repera-greenfield/`):** `notification_outbox`, `classes`/`class_bookings`, `org_members` — no usar como verdad de producción.

**Edge Functions Business:** `repera-business-invite` (email). No hay Stripe webhook ni worker push.

**Consola:** `web/console/` SPA ES modules; orquestador `connected.js`; 360 `management-360.js`; bonos PT `trainer-pass-panel.js`.
