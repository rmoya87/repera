# Repera Business — Plan maestro de arquitectura, producto y ejecución

**Versión:** 0.2 · **Fecha:** 19/10/2026 · **Estado:** especificación de destino + desarrollo local ampliado, NO producción.

## 0. Decisiones y límites ya aprobados

- **Roles visibles de negocio:** entrenador personal, gimnasio y administrador de Repera. El **deportista** usa la app nativa y no necesita ser un cuarto tipo de panel web.
- **Modelo comercial Repera → gimnasios/entrenadores:** por definir (no bloquear el desarrollo ni fingir precio confirmado).
- **Modelo comercial gimnasio/entrenador → cliente:** totalmente configurable, independiente del modelo anterior.
- **Hosting web:** IONOS compartido, solo HTML/CSS/JS precompilado; cero Node/SSR/servidor propio en producción.
- **Backend compartido:** Supabase independiente, inicialmente gratuito según disponibilidad del plan y políticas actuales, PostgreSQL + Auth + Edge Functions + Storage + tareas programadas gestionadas. Sin tocar Cafesito.
- **Apps:** iOS/watchOS 27+ nativas ya presentes; Android futura nativa, sin copiar requisitos de iCloud ni depender de Apple.
- **Identidad:** Supabase Auth es identidad de usuarios multiplataforma. Sign in with Apple debe intercambiarse por una sesión Supabase verificada; el ID guardado en Keychain por sí solo **no** es credencial de Supabase.
- **Fuente de verdad:** backend para grupos, profesionales, programas publicados, contratos, bonos, reservas y cobros; base local del móvil para sesión en curso, métricas privadas, uso offline; sincronización por entidad, nunca reemplazar todo el estado por un JSON remoto.
- **Seguridad:** negocio a negocio mediante `org_id`, RLS obligatoria, roles reales en tablas protegidas, permisos por función, consentimiento y auditoría. «Ver como» solo mediante delegación de servidor, tiempo limitado y auditada.
- **Pagos:** Stripe Connect para cobrar por cuenta del gimnasio/entrenador; Stripe Billing para futuras suscripciones B2B a Repera; proveedor fiscal homologado/compatible para emisión de facturas, sujeto a validación jurídica y fiscal.
- **Demo local actual:** deliberadamente sin login ni backend. Un selector de roles/empresas es SOLO herramienta de demostración, no constituye control de seguridad.

## 1. Arquitectura de despliegue

```text
                             IONOS Apache estático
repera.app ------------------------------------ web/ (landing/legal)
repera.app/console/ -------------------------- web/console/ (Business)
                         | HTTPS (supabase-js cuando se conecte)
                         v
                  SUPABASE / proyecto REPera AISLADO
   Auth + PostgreSQL + RLS + Storage + Edge Functions + CRON
       |                 |                   |
     iOS 27+           Android             Stripe Connect/Billing
     SwiftUI         Kotlin/Compose       Webhooks verificados
       |                 |
 LocalStore / SQLite   Room/SQLite
       +---------- sync incremental por tabla ----------+
                     iCloud opcional, solo iOS
```

**No crear una segunda organización dentro de Cafesito:** en Supabase «organización de facturación» y «organización cliente de Repera» no son lo mismo. Separación de proyectos para no compartir secretos, RLS ni logs. El usuario deberá crear desde el Dashboard la organización gratuita `Repera` y su proyecto `repera` en `eu-west-1`; herramienta actual no dispone de crear organización. Confirmar cuotas reales del plan antes de pasar a producción. **La conexión a Supabase/Stripe aún no está habilitada.**

IONOS no requiere procesos permanentes: los JS se sirven estáticos; consultas de datos mediante REST/PostgREST; operaciones privilegiadas mediante Edge Functions bajo demanda; webhooks en Edge Functions; tareas calendarizadas en Supabase Cron, con garantías de idempotencia y conciliación.

## 2. Entidades y permisos

### Identidad y estructura

- `profiles` cuenta global; una persona tiene identidad única, puede ser deportista, trainer, staff de varios centros y propietario de su propia actividad independiente.
- `organizations` entidad propietaria de la relación comercial: `gym` o `coach`.
- `org_members` membresías de usuario + rol (`owner`, `manager`, `coach`, `reception`, `billing`) dentro de **cada** negocio.
- `platform_admins` controlado mediante service role, sin aceptar rol del navegador.
- `locations` sedes, salas o espacios, dirección, capacidades; ampliable a máquinas y recursos.
- `clients` ficha de relación con el negocio; `user_id` solo después de una invitación aceptada; un mismo usuario puede ser cliente de varios centros sin que se mezclen sus fichas, finanzas o entrenamientos.
- `client_data_shares` consentimientos deportivos explícitos, revocables; un staff solo ve los historiales personales del cliente en los ámbitos concedidos, no todo HealthKit.

### Servicios deportivos

- `coaching_groups`, `coaching_group_clients` para cohortes reutilizables, asignaciones masivas y seguimiento grupal.
- `program_templates` versiones de planificación; contenidos estructurados con semanas/días/bloques/ejercicios y parámetros, estados borrador/publicado/archivado.
- `program_assignments` copia o referencia versionada de un programa asociada a UN cliente, fecha, estado y modificaciones individuales.
- `athlete_workout_entries` registros hechos por el deportista. Inmutabilidad del historial desde la edición profesional; aceptar correcciones propias con revisiones.
- `classes` instancias reales de clases y sesiones 1:1, vinculadas a centro/sala y entrenador; añadir más tarde `class_series` para reglas de recurrencia y excepciones.
- `class_bookings` reserva, lista de espera, asistencia, no-show, cancelación y reintegro de crédito.

### Comercio y finanzas

- `products` definición de tarifas (sesiones, ilimitado, frecuencia semanal, cita, día suelto, cursos), validez, reglas y precio en **céntimos**.
- `client_passes` derecho concreto del cliente; estado `pending` no aporta acceso, incluso aunque aparezca en catálogo; congelaciones, caducidad, renovaciones.
- `credit_ledger` saldo mediante apuntes **append only**. Nunca actualizar saldo directamente; no admitir saldo negativo.
- `business_payments` identidad de pago, titular, importe, moneda, medio, proveedor y referencia externa. Pago solo se confirma mediante webhook verificado o registro externo auditado.
- `invoice_drafts` propuestas de documento; `issued_invoices` facturas inmutables de proveedor fiscal, con series y referencias.
- `audit_events` y `idempotency_keys` para operaciones sensibles y webhooks duplicados.

## 3. Matriz de permisos — escenario objetivo

| Recurso | Deportista | Entrenador de centro | Owner/manager del centro | Finanzas | Admin Repera |
|---|---|---|---|---|---|
| Mi cuenta y mis entrenos | Escribe sus resultados | Sólo lee datos expresamente compartidos | Sólo compartidos | No | No, salvo procedimiento excepcional |
| Clientes CRM de su centro | Solo su ficha | Lectura de cartera asignada | Crear/editar | Datos mínimos de facturación | Acceso delegado auditado |
| Programación | Ve su asignación, no altera receta original | Crea para clientes asignados | Completa | No | Soporte delegado |
| Reservas | Reserva/cancela la suya | Gestiona clases asignadas | Todas las de su centro | Consulta necesaria | Soporte delegado |
| Tarifas, bonos | Ve los propios | Solo lectura autorizada | Configura | Consulta/gestiona cobros según permiso | Reportes globales agregados |
| Facturas | Las propias | No | Las del centro | Las del centro | Las de Repera, y soporte delegado con autorización |
| Administración plataforma | No | No | No | No | Sí |

**Aviso:** SQL del paquete ofrece un RLS base deliberadamente restrictivo y no implementa todavía todos los permisos finos por entrenador asignado. Es preferible bloquear hasta implementar sus endpoints. Ningún rol web se convierte en credencial de base de datos al cambiar un selector.

## 4. Módulo por módulo — contratos funcionales completos

### A. Acceso, onboarding, empresas y delegación

**Casos:** alta entrenador autónomo, crear centro, varias sedes, un entrenador en múltiples centros, autónomo que además imparte clases en gimnasio, invitación empleado, baja de staff, cuenta desactivada, cambio de owner, recuperación de contraseña, MFA para perfiles financieros, suspensión comercial, cierre/portabilidad RGPD. Admin entra a una vista delegada temporal y revocable, con motivo, permisos, firma de auditoría y marcas visuales. NUNCA suplantar JWT.

**UI:** login y selección de negocio; wizard alta `Tipo de negocio → Datos → Horarios/sede → Mi primer servicio → Invitar cliente`; panel de permisos por persona; «Cambiar de negocio» superior; barra amarilla de vista delegada.

### B. Clientes, CRM y altas

**Casos:** alta individual, carga CSV con validación/deduplicación, invitación app, invitación pendiente/rechazada, usuario ya existente en Repera, cliente de varios centros, clientes sin móvil, menor con representante legal, consentimientos, contactos de emergencia opcionales, facturación a un tercero, lead/prueba/activo/pausado/baja, etiquetas, grupos, notas internas privadas, histórico de servicios y pagos, portabilidad y borrado sujeto a conservación legal.

**UI:** tabla paginada buscable, filtros de estado/centro/coach/tarifa, crear con modal; detalle en pantalla o panel lateral con pestañas `Resumen · Planificación · Reservas · Bonos · Cobros · Permisos`; acciones de importación y asignación masiva.

### C. Planificador entrenador

**Casos:** plantillas diarias, semanales y ciclos de 4–52 semanas; ejercicios fuerza, cardio, WODs, descanso, pesos/reps/RIR, descansos/series, notas, vídeos autorizados, equivalencias, progresión; repetir/cambiar semana; creación desde cero, clonar desde un cliente, reutilizar plantillas; publicar a 1, selección múltiple o grupo; modificar solo futuro para todo grupo o un cliente, excepciones de calendario, vacaciones, lesión y alternativas; llevar historial de versión y autoría.

**UI:** calendario semana/mes con drag & drop accesible también vía menú, biblioteca a la izquierda, semana en centro, detalle de día a la derecha; editor rápido con teclado; «Asignar» abre sheet de destinatarios/fecha. Mantener «Deshacer» para operaciones masivas y lista de errores por cliente.

**Invariantes:** editar plantilla futura NO modifica sesiones ya realizadas; si se modifica un programa publicado, crear revisión o versionado; si hay dos programas el mismo día mostrar ambos, jamás reemplazar uno; avisar de solapamientos pero permitirlos con confirmación; `assignmentId`, `templateRevision` y `occurrenceId` estables.

### D. Integración con móvil Diario/Hoy

**Diario:** eventos de origen `personal | coach | gym | booking | external` con iconografía y colores consistentes. No sustituir `AppState.routines` por arrays remotos sin conciliación. Repeticiones expresadas como eventos concretos por día. Editar plan propio no borra el ajeno; sesiones prescritas de coach: aceptar, reprogramar según permisos o marcar adaptado.

**Hoy:** orden por hora, clases reservadas, siguiente sesión profesional, entrenamiento propio, descanso y pendientes; ficha del profesional/centro, ubicación, acción `Empezar/Apuntar`, recordatorio y estado de reserva; múltiples actividades diarias; offline muestra última copia sincronizada y hora de actualización; registrar resultados localmente y encola upload seguro.

**Resultados:** deportista es propietario de la sesión, no de la plantilla; completado enlaza `assignmentId` y el profesional ve únicamente datos que el usuario autorizó. No enviar métricas médicas ni todas las muestras de Apple Salud.

**Android:** modelos JSON neutrales, UUID, fechas ISO8601, zona horaria, versión de esquema, sincronización incremental, operaciones idempotentes; Kotlin/Compose y Room; no CloudKit obligatorio. iCloud queda espejo privado opcional, no medio de intercambio con Android ni entre profesionales.

### E. Agenda, clases y reservas

**Casos:** clases periódicas, sesiones aisladas, tutorías 1:1, recursos/salas con capacidad, instructor sustituto, reservas manuales/autoservicio, cupo personal o de grupo, listas de espera FIFO, plazos de reserva/cancelación, cupo mínimo, no-show y cargo/penalización según contrato, cancelación por enfermedad, clase cancelada por centro, transferencia/plaza recuperada, check-in presencial QR de un solo uso, cliente sin móvil, festivos y zonas horarias, cambios horario DST, bloquear duplicados y overbooking simultáneo.

**Reglas:** `POST /book` es una sola transacción SQL con `SELECT ... FOR UPDATE` sobre sesión/cupo y pass, idempotencia, comprobación de `product.rules`; confirmar solo si hay plaza y derecho suficiente; al ocupar lista de espera no descontar créditos; deducir una vez al confirmar; reintegrar una vez al cancelar dentro de política y promover lista FIFO si hay derecho; devolver respuesta oficial y notificar al móvil. No confiar en conteos client-side.

**UI:** agenda día/semana + modo lista, filtros sede/instructor/actividad, tarjeta ocupación, reserva con aviso `tienes X créditos`, lista espera, detalle de participantes, política de cancelación.

### F. Tarifas, productos, contratación y derechos

**Casos:** ilimitado, días/semana, sesiones/mes, bono N sesiones, 1 clase, mensual/anual, acceso por franjas horarias, tipo de actividad, actividad online, privado, semiprivado, inscripción curso, familias, híbridos, precios promocionales, matrícula, descuentos, prorrata, pausas, vacaciones, carencias, cambios de plan, transferencia de bonos según norma, renovación manual/automática, pagos por tercero, compra regalo, caducidad, devolución parcial y registro de deuda.

**Reglas:** producto define condiciones; compra confirmada origina contrato/bono, no al crear carrito; periodos de vigencia y reinicio precisos (`monthly anniversary`, `calendar month`, `rolling days`); contabilidad de créditos por ledger con evento y referencia únicos; los cambios futuros no modifican los bonos ya vendidos sin consentimiento/versión. Planes B2B de Repera son completamente **otra** familia de suscripciones.

**UI:** tabla por tipo, diseñador de tarifa paso a paso, simulación «qué podrá reservar este cliente», ficha de saldo/movimientos y calendario de renovaciones, vista de tarifas archivadas.

### G. Pasarela y facturación

**Casos:** cobros recurrentes Stripe, pagos puntuales, cobro presencial (registrado manual), transferencias, impuestos, recibos, contracargos, reembolsos parciales, reintentos de pago, fallos 3DS, método de pago caducado, conciliación diaria, suscripción cancelada, pago en moneda no EUR (futuro), facturación a empresa, abonos rectificativos, series por entidad, exportación CSV/contabilidad, documentos de soporte y auditoría fiscal.

**Arquitectura:** cliente web solicita intención en Edge Function; Stripe redirige checkout seguro; webhook firmado verifica `event.id`, idempotencia y relación con `org_id/account`; registra transacción y activa pass SOLO por evento confirmado; no confiar en success URL. Repera factura sus comisiones/cuotas por separado. Emisión fiscal por servicio compatible con normativa española; consultar asesoría para VERI*FACTU, SIF, e-factura y retención. Sin servidor en IONOS.

**UI:** separar pestañas `Cobros · Facturas · Impagos · Conciliación · Configuración fiscal`, widgets `Cobrado/Pendiente/Devuelto`, periodos y filtros. Sólo estados verificados muestran «Pagado». «Borrador» tiene un distintivo visible hasta la emisión real.

### H. Equipo, sedes y accesos físicos

**Casos:** múltiples sedes, salas con horarios, material compartido, disponibilidad staff, vacaciones y sustitución; fichar asistencia a clase; acceso QR caducable sin claves persistentes, lectores terceros opcionales sin acoplar la app a hardware concreto; lista de entradas/salidas y rechazo explícito. Datos de accesos físicos minimizados según RGPD.

### I. Analíticas y negocio

**Casos:** ingresos bruto/neto/impuestos, ingresos por producto/sede/coach, MRR B2B/B2C separado, churn de clientes, retención de cohortes, clientes activos/suspendidos, duración media, utilización real vs aforo, absentismo, conversión lead→alta, costes de pasarela, márgenes cuando se registren costes de equipo/sala, ranking servicios, vencimientos próximos. Filtros fecha/organización/sede/entrenador/actividad. Descarga y comparación de periodos.

**Privacidad:** datos deportivos sólo agregados y autorizados; no exponer métricas personales de todos los clientes en reportes de negocio sin base legal. Cálculos monetarios enteros en céntimos y métricas con periodos coherentes.

### J. Administrador Repera

**Casos:** buscador organizaciones, activación, suspensión, incidencias, estado de sincronización, estado Stripe conectado, cuota B2B si se define, auditoría, invitaciones, acceso delegado solo con motivo y registro, exportación regulada, incidencias de webhooks, salud operacional. Reportes globales agregados sin detalle de entrenamiento personal. Recuperación de errores sin cambiar datos privados a mano.

**UI:** dashboard Repera, organizaciones, incidencia, pagos Repera, facturas Repera, configuración de futuros planes, auditoría y soporte delegado.

### K. Notificaciones y automatizaciones

**Casos:** confirmación/cambio/cancelación clase, promoción espera, próximo entrenamiento, invitación, cuota por vencer, impago, renovación, contrato congelado, WOD nuevo, entrenador sustituido. Preferencias por canal/app, consentimiento, frecuencia, plantillas multilenguaje, no notificar doble. Tareas programadas Supabase Cron + Edge Functions idempotentes; notificaciones Apple Push/FCM a tokens cifrados y revocables.

## 5. Arquitectura frontend detallada — árbol de archivos objetivo

```text
web/
  (landing y legales existentes, intactos)
  console/
    index.html                     [HECHO] HTML estático accesible por /console/
    src/styles.css                 [HECHO] tokens oscuros coherentes con la marca
    src/main.js                    [HECHO] entrypoint
    src/core/seed.js               [HECHO] datos ficticios 2 negocios y múltiples casos
    src/core/domain.js             [HECHO] motor validado de operaciones locales
    src/core/store.js              [HECHO] almacenamiento transaccional del demo
    src/ui/components.js           [HECHO] componentes base sanitizados
    src/ui/pages.js                [HECHO] 9 módulos + admin
    src/ui/app.js                  [HECHO] router visual, eventos, formularios
    tests/domain.test.mjs          [HECHO] pruebas automatizadas dominio
    [FUTURO] src/core/auth.js      sesión Supabase, refresh, cierre sesión, MFA
    [FUTURO] src/core/api.js       repositorios paginados, retries, cursor
    [FUTURO] src/core/sync.js      reconciliación con móviles / realtime
    [FUTURO] src/core/permissions.js  permisos de presentación, nunca sustituyen RLS
    [FUTURO] src/core/stripe.js    wrapper de Edge Functions (sin secret keys)
    [FUTURO] src/components/*     desglose de tablas, calendario, composer, sheet
    [FUTURO] src/pages/*          módulos extraídos a archivos por área
    [FUTURO] src/styles/*         tokens, responsive, componentes, a11y
    [FUTURO] public/manifest.json iconos PWA optativos
```

El prototipo funcional utiliza ES Modules y CSS puro sin dependencias. No se añadió React ni se fuerza Tailwind: se puede migrar a Tailwind compilado sin modificar arquitectura de negocio. Para IONOS, esta versión se sirve directamente como estáticos. No requiere `npm install` ni `npm run build` para probar.

## 6. Integración nativa iOS y Android — cambios previstos archivo por archivo

**Código existente auditado en GitHub:** `Apps/Repera/Sources/ReperaApp.swift` (Apple sign-in, Bootstrap), `Onboarding/AppleAuthStore.swift` (clave de Apple en Keychain; sin token Supabase), `ReperaStore.swift` (LocalStore/iCloud y asignación **única** por día), `HomeView.swift` (Hoy prioriza un entrenamiento), `PlanView.swift` (semana Lu–Do + biblioteca) y `Packages/ReperaDomain/Sources/ReperaDomain/Models.swift` (Routine/WorkoutSession).

**No modificar todavía** estas pantallas sin contrato de sincronización cerrado. Próximos archivos concretos:

```text
Packages/ReperaDomain/Sources/ReperaDomain/Business/
    Organization.swift           datos multitenant sin detalles UI
    TrainingAssignment.swift     UUID, origin, dates, template_revision
    AgendaEvent.swift           evento discriminado plan/bookings/personal
    ClassBooking.swift          reserva y cancelación
    BusinessEntitlement.swift   bonos y derechos ajenos al paywall Repera
    SyncEnvelope.swift          versionado por entidad, dispositivo e idempotencia
Apps/Repera/Sources/Business/
    SupabaseSessionStore.swift   token sesión Supabase + Apple verified exchange
    BusinessSyncClient.swift    pulls incrementales, cursor, ETag/revisión
    AgendaReconciler.swift      mezcla local con profesional sin eliminar histórico
    BusinessAgendaStore.swift   estado aislado de iCloud + offline cache
    ClassReservationView.swift  reservar/cancelar desde app
    TrainerLinkView.swift       aceptar invitación y revocar consentimientos
Apps/Repera/Sources/ReperaApp.swift    inyectar BusinessAgendaStore no bloqueante
Apps/Repera/Sources/HomeView.swift     presentar múltiples entradas de Hoy
Apps/Repera/Sources/PlanView.swift     añadir capa «Profesionales» a Diario
Apps/Repera/Sources/ReperaStore.swift no modificar flujo local hasta tests
Apps/ReperaWatch/...                 reflejar sólo actividades compatibles
Android/app/...                     Android futuro con dominio/API compatibles
```

**Migración:** cuando se añada `AgendaEvent`, una rutina ya guardada por el usuario mantiene su ID; eventos del profesional tienen ID remoto y no colisionan. Al terminar un entrenamiento profesional, el móvil lo registra en historial propio y envía sólo los resultados consentidos. Nunca sobrescribir iCloud con datos de otro gimnasio.

## 7. SQL independiente y endurecimiento de seguridad

Archivo creado: `supabase/repera-greenfield/0001_business_foundation.sql`.

- Aislado: para **un nuevo proyecto**. Jamás aplicar a la base existente de Cafesito.
- **NO ejecutar junto a `supabase/migrations/20261015120000_init_repera.sql`:** la migración antigua incluye una política que permite a coaches leer entrenos ajenos por su rol global. Se debe descartar/reemplazar esa migración en el nuevo proyecto, no añadir el esquema encima.
- Política restrictiva: usuarios sólo ven su negocio; los atletas sólo su propia información; informes financieros sólo roles habilitados; escrituras de créditos, pagos, reservas, facturas emitidas, permisos y auditoría no abiertas desde cliente.
- Endpoints pendientes de crear antes de conectar UI a Supabase: `create-invitation`, `accept-client-invitation`, `assign-program-batch`, `book-class`, `cancel-booking`, `activate-pass`, `stripe-webhook`, `billing-invoice`, `delegate-access`, `revoke-data-share`.
- **Revisión bloqueante:** auditoría RLS SQL incluyendo cadenas de referencias, foreign keys y SECURITY DEFINER; ensayos con identidades reales de dos centros y una cuenta no miembro; transacciones concurrentes y duplicación de webhook; retención y copias verificadas.

## 8. Roadmap ejecutable y puertas de calidad

| Fase | Implementación archivo a archivo | Criterio de aceptación |
|---|---|---|
| 0 · Demo local **hecha** | `web/console/*`, pruebas Node | Navega, crea cliente, publica plantilla local, asigna a varios, reserva, simula bono/cobro, CSV, panel admin demo |
| 1 · Proyecto separado | crear org/proyecto Supabase, revisar 0001, Auth Apple y correo | Login real web, logout, aislamiento automático, tenant sin datos ajenos |
| 2 · Dominio servidor | funciones transaccionales, invitaciones, grupos, plantillas versionadas, permisos | 2 empresas / 3 roles, tests adversariales RLS y operaciones concurrentes |
| 3 · Planificación | calendario visual, catálogo, asignaciones, progreso, vistas por cliente/grupo | Asignar 20 deportistas y editar 1 sin cambiar 19 ni su histórico |
| 4 · Apps | contratos `AgendaEvent`, SyncBridge incremental iOS, Android-ready JSON | Entrenamiento del centro en Diario y Hoy; offline; no duplicados; multiactividad |
| 5 · Agenda | recurrencia, reservas atómicas, aforos, espera, políticas | 50 reservas paralelas sin overbooking; refund una vez |
| 6 · Comercio | Stripe Connect, pagos reales, renovaciones/reintentos, ledger | Webhooks firmados y repetidos; pago fallido no da bono |
| 7 · Fiscal | proveedor fiscal, numeración, impuestos, rectificativas, PDFs, conciliación | Facturas legales emitidas en pruebas y aprobadas por asesoría |
| 8 · Análisis + admin | analítica eficiente, soporte delegado, alertas y auditoría | Métricas cuadran con transacciones; auditoría siempre identifica actor |
| 9 · Android | cliente Kotlin Compose + Room compartiendo Auth/API | Todos los flujos fundamentales sin Apple/iCloud |
| 10 · Release | rendimiento, accesibilidad, RGPD, backups, rollback, IONOS build CI | Sin secretos en bundle, rollback probado, métricas y recuperación |

## 9. Calidad requerida en cada PR/entrega

- Unit tests: cálculos monetarios con céntimos, compatibilidad de fechas/zonas, series de recurrentes, congelaciones, prorrateos, reserva/espera/cancelación, grupos y asignaciones duplicadas.
- Integration: Supabase Auth, RLS multitenant, SQL concurrente, webhooks duplicados, serialización iOS/Android, rotación de credenciales.
- End-to-end: alta negocio→cliente→producto→pago validado→reserva→Diario/Hoy→resultado→reporte→factura.
- Observabilidad: logs con `request_id`, `org_id` anonimizado, `actor_id` minimizado; nunca guardar tokens/tarjetas/datos HealthKit crudos en logs.
- Seguridad: CSP, HTTPS, XSS de nombres/notas, validación de entradas, secretos solo Supabase Edge, cuota de acceso, expiración de delegaciones, accesibilidad teclado/WCAG.
- Privacidad/legal: información RGPD, minimización por defecto, registro de consentimientos, acuerdos de encargado, derecho de acceso/exportación/baja, retenciones legales, tratamiento de menores.
- CI: tests Node frontend, linters, DDL y RLS, `swift test` + XcodeGen/iOS build y Android más adelante. Los cambios deben actualizar AGENTS/docs existentes según normas repo.

## 10. Criterios de aceptación de la PRIMERA VERSIÓN local

1. Abrir `http://localhost:8080/console/` sin instalar dependencias ni levantar backend.
2. Tener roles demostrativos y cambiar entre gimnasio, entrenador y admin.
3. Alta de cliente con validación y duplicados por negocio.
4. Crear programa semanal, duración, y asignar masivamente desde la sección Planificación.
5. Ver una ficha con programación del día y derechos de bonificación.
6. Crear clase con entrenador, aforo y fecha; reservar cliente con bono y cancelar.
7. Ver funcionamiento de lista de espera y créditos y comprobarlo en las pruebas automatizadas.
8. Crear tarifas de sesiones o ilimitadas, simular venta, ver saldos y estados.
9. Registrar cobros, crear un borrador no fiscal y exportar CSV.
10. Dashboard y analítica recalculan según los datos cambiados.
11. Admin demo `Ver como`, sin confundirlo con delegación real.
12. Restaurar datos demo. Nunca afectar a Cafesito, Apple, Stripe ni producción.

## 11. Limitaciones conscientes de la entrega actual

**No implementado todavía:** login auténtico, sincronización con iOS/Android, webhooks/pagos reales, factura legal/rectificativa, multiusuario simultáneo, control acceso QR real, repetición de clases, drag & drop del planificador, permisos finos de personal, monitorización/cron, app Android. Existen sus contratos y casos de aceptación, pero el demo local no simula seguridad real. El estado se guarda en LocalStorage sin cifrar: no usar datos personales reales.

**Revisión crítica detectada:** migración inicial Repera de GitHub usa `profiles.role` global y permite consultar `workouts` a coaches/gym admins. Debe sustituirse en la nueva base y no reutilizarse como acceso al backend multicliente.

## 12. Próximo orden exacto de commits (cuando se autorice)

1. Commit A: `docs/REPERA_BUSINESS_SPEC.md` + `web/console/` con demo local probada.
2. Commit B: `supabase/repera-greenfield/0001_business_foundation.sql` + tests RLS con proyecto nuevo.
3. Commit C: proveedores Auth y frontend Supabase; login Apple/email con session Supabase verificada.
4. Commit D: RPC reserva/cancelación/pagos; tests concurrentes.
5. Commit E: planificador real + iOS `AgendaEvent` y API multiplataforma.
6. Commits posteriores: Stripe, fiscal, analíticas, admin, Android.

El prototipo v0.2 se incorpora posteriormente a la rama `feat/repera-business-platform`. Esto no significa que se haya desplegado en IONOS ni integrado con los clientes iOS/Android; las propuestas SQL no deben aplicarse sin adaptación al esquema vigente de Repera.


## 13. Incremento local 0.2 (implementado y probado en esta sesión)

- Nuevas pantallas **Grupos, Agenda de deportistas, Operaciones, Notificaciones** con formularios y estados; se mantiene la demo admin sin elevación real.
- Edición de clientes, alta de profesionales, salas, asignación grupal idempotente, ajuste individual por fecha, planificación de lunes a domingo y clases recurrentes semanales, validación de recursos y aforos.
- Control local de asistencia, cancelación de clases, reintegro de créditos, bandeja de avisos local con deep-link. Corrección de devolución de crédito en datos de ejemplo y enlace pago-bono pendiente.
- `src/core/backend.js` con contrato de JWT Supabase y RPC autenticadas, NO conectado hasta crear la base.
- `src/core/mobile-contract.js` más Swift y Kotlin equivalentes (compilados/tests de contrato).
- `supabase/repera-greenfield/0002_booking_transactions.sql`: funciones SQL transaccionales candidatas a revisión de Postgres real, políticas de cliente/coach más restrictivas, aislamiento de notas y outbox.
- 37 tests Node pasan (incluyen checks estáticos del DDL, que no sustituyen un test SQL). 2 tests Swift pasan; 3 comprobaciones Kotlin pasan. Navegador real no validado por restricción de acceso local.
- Sin conexión real de Supabase, Apple, Google, Stripe, IONOS, APNs ni FCM.

Consulta `docs/INTEGRACION_Y_ESTADO.md` para el contrato de agenda v1, los riesgos y la puerta de calidad antes de declarar el sistema completo.
