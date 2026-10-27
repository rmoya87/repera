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
| 2 Organizaciones | Clientes, entrenadores, invitaciones | PARCIAL | Consentimiento explícito, revocación y operaciones transaccionales |
| 3 Web profesional | Panel conectado y usable | PARCIAL | Sin datos simulados en módulos declarados completos |
| 4 Programación | Ejercicios, planes, grupos, versiones | PARCIAL | Assign/revoke idempotente, contratos móviles comprobados |
| 5 Clases | Reservas, aforo, espera, créditos | PARCIAL | Última plaza y concurrencia verificadas |
| 6 Móvil | iOS existente y Android nativo | PARCIAL | Compatibilidad, deep links y modo offline |
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

## Actualización técnica comprobada 2026-10-19

- Supabase Repera (no Cafesito): 7 migraciones reales; 16 tablas `public` con RLS; advisor de seguridad sin lints; pruebas SQL transaccionales con identidades aisladas y ROLLBACK.
- Invitaciones consentidas, alta/vinculación de cliente, asignación de entrenador, prescripción simple por día, clases/citas con capacidad y prevención de solape, bonos de cortesía separados, reservas idempotentes y ledger reversible.
- Panel web conectado (correo), con módulos operativos de invitaciones, clientes, horarios, cortesías y publicaciones simples; la demo sigue aislada.
- iOS nativo 27: inicio de sesión Apple→Supabase preparado con SDK oficial y nonce, lectura de centros, sesiones, citas y bonos en Center/Inicio/Diario/Ajustes. **No hay build TestFlight/Xcode validada ni registro real de usuario**.
- Bloqueos de salida: activar y comprobar el proveedor Apple del proyecto, compilar iOS 27 y Watch con SDK compatible, CI actual fallido, E2E y concurrencia multi-sesión, facturación fiscal y Stripe, membresías de pago, listas de espera, planes completos 1–52 semanas/plantillas/versiones, push, Android nativo, despliegue profesional IONOS y cumplimiento legal.
- La política de cancelación de créditos es **provisional** (12h) y necesita parametrización por tipo de producto y confirmación legal/comercial antes de habilitar pagos.
- No fusionar el borrador de PR en `main` mientras no estén cumplidos los criterios de aceptación.

## Experiencia de entrenador personal (27/10/2026)
- **Inicio:** dos columnas: *Quieren entrenar contigo* (clientes potenciales y en prueba) a la izquierda y *Próximas citas* a la derecha. Incluye citas con hora, grupos y entrenamientos individuales fechados; estos últimos se etiquetan **sin hora** porque no equivalen a una reserva. Agenda mensual interactiva para consultar sesiones o abrir el alta de cita/grupo.
- **Navegación:** el entrenador independiente gestiona entrenamientos dentro de cada ficha de cliente y citas/grupos desde Inicio, sin menús globales duplicados de Entrenamientos o Clases y reservas. Otros tipos de negocio conservan sus apartados.
- **Clientes:** URL directa compatible con hosting estático (`?espacio=<uuid>&seccion=clients&cliente=<uuid>`), navegación anterior/siguiente y persistencia en recarga. El avatar real proviene de `profiles.avatar_url` mediante RPC autorizada, con imagen propia de `clients.avatar_url` como respaldo. Entrenamientos individuales editables o cancelables mediante RPC (baja lógica sin borrar resultados previos), editor en ficha y bonos existentes filtrados por cliente y organización.
- **Planificación:** botón *Añadir planificación*, modal que reutiliza la planificación masiva transaccional ya existente en main: selección de plantilla, destinatarios y rango de fechas (hasta 120 sesiones, deduplicación). La creación individual desde una ficha no exige una plantilla.
- **Configuración:** secciones *Datos del profesional* y *Plan y suscripción*, manteniendo los formularios y operaciones actuales.
- **Relación profesional:** *Finalizar relación* marca al cliente como cancelado **solo tras confirmar que el contrato ya venció**; no elimina su cuenta Repera ni cancela suscripciones móviles independientes. **Pendiente:** modelar fecha de inicio, fin y renovaciones del contrato B2C para programar bajas futuras automáticamente. No interpretar el estado del cliente como vencimiento de Apple/Google.
- **Límites actuales:** el calendario registra eventos de `service_occurrences`, que son distintos de entrenamientos en `professional_training_sessions`; aún no hay asociación obligatoria de un cliente a una cita en su creación (la inscripción se completa desde el detalle con bono válido). *Quieren entrenar contigo* muestra solicitudes reales de inscripción que llegan desde la app, con aceptar/rechazar. Las compras de bonos y las facturas B2C requieren integración transaccional antes de mostrarse como pagadas.
- **Privacidad:** el endpoint público `business_client_avatars` es SECURITY INVOKER y delega en la función privada `private.business_client_avatars_impl` con comprobación de organización, estado y asignación del profesional; no permite ejecución anónima. Migraciones registradas en `supabase/migrations/`.


## Revisión de ficha del atleta y operaciones de entrenador (27/10/2026)

- **Administrador · ficha del atleta:** la orientación del entrenamiento se sitúa en la cabecera; desaparece el botón duplicado de añadir un plan. El calendario combina días con actividad y sesiones profesionales futuras cuando estas constan en Supabase.
- **Mapa muscular:** Business usa las siluetas geométricas exactas de `Apps/Repera/Resources/BodyPaths.json` y la taxonomía de 18 músculos. La escala visual de 0 a 4 sigue los umbrales de `MuscleMapEngine` (gris, verde, amarillo, naranja y rojo). Estimación basada únicamente en series realmente sincronizadas y compartidas; no se inventan cargas ni datos de Apple Health.
- **Visualización:** calendario autónomo de altura, columna izquierda ligeramente más amplia y bloques WOD verticales. El catálogo web añade la miniatura verificada para *Hang Squat Snatch*.
- **Entrenador · ficha del cliente:** calendario con puntos para actividad compartida, planes profesionales y asistencia registrada. Los entrenamientos del día se ven a la derecha y las métricas e1RM/mapa muscular bajo el conjunto. La edición de un plan se abre a demanda; no se muestra el constructor continuamente.
- **Planificación masiva:** creación desde el constructor en modal sin requerir Excel ni plantilla. Publicación atómica de 1 a 20 atletas, rango hasta 56 días y máximo 120 asignaciones; deduplica coincidencia de título/cliente/día, guarda huella de solicitud y rechaza reintentos con parámetros distintos. Las plantillas preexistentes continúan disponibles por pestaña.
- **Bonos y tarifas del entrenador:** catálogo de precios reales `business_pass_offers`. La asignación manual crea un bono con procedencia `manual_offline` y registro de crédito sin atribuir un cobro electrónico a Repera; la casilla de confirmación reconoce la gestión externa.
- **Asistencia presencial:** registro en el momento de la sesión, haya o no entrenamiento programado. Función transaccional valida org/cliente/bono, descuenta un crédito, registra asistente y movimiento de saldo; si había una reserva ya cobrada, deja constancia de la asistencia sin segundo descuento. Una solicitud idempotente no puede aplicarse dos veces.
- **Límite de clientes:** trigger de BD para entrenador personal consulta `business_plans.max_clients` según `organization_trials.paid_plan` vigente; durante la prueba permite hasta cinco clientes vinculados y tras expirar, sin plan activo, bloquea nuevas vinculaciones. Leads pendientes no ocupan una plaza. Los límites actuales del catálogo son 5, 50 y 75.
- **Privacidad:** el historial mostrado al entrenador depende de la autorización de compartición existente; no se consultan entrenamientos privados directamente. Las futuras sesiones que el atleta cree localmente en su dispositivo solo serán visibles cuando su sincronización a un origen autorizado incluya fecha planificada; no se deben fingir.
- **Pendientes:** integración real de pago y facturación, contrato del cliente con cancelación programada, sincronización completa de futuros entrenamientos creados por el propio atleta en móvil, pruebas E2E del flujo completo entre dispositivos y pasarela.
