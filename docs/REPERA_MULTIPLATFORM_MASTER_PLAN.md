# Repera — plan maestro de producto y ejecución multiplataforma
Fecha: 2026-10-19 · Estado: diseño de referencia y backlog ejecutable · Rama: feature/multiplatform-foundation-20261019

## 0. Decisiones cerradas y límites

- Deportista/cliente final: solo app **iOS nativa** y **Android nativa**. **No hay web de deportistas**.
- Entrenadores y gimnasios: **portal web de gestión** con vistas y permisos diferenciados. Una misma identidad puede tener más de un rol profesional/organización y usar móvil como deportista.
- Web existente en web/: **landing pública y legales**, NO reutilizarla como panel profesional. Nuevo proyecto separado apps/pro-portal/.
- Backend: **Supabase propio de Repera**, proyecto gratuito independiente de Cafesito; ninguna tabla, clave, trigger, almacenamiento ni autorización compartidos.
- Datos: mínimos estrictamente necesarios; entrenamiento privado por defecto; Salud/Health Connect, ubicación y métricas fisiológicas no se suben automáticamente. Permiso explícito para integraciones y acceso profesional al historial personal.
- Arquitectura offline-first: registrar sesiones sin red y sincronizar al recuperar conectividad; conservar la rapidez y funcionalidades actuales de iOS/Watch.
- Notificaciones: publicación de entrenamiento personalizado; nuevas clases/calendario; cambio/cancelación de reservas. Solo personas autorizadas, al publicar (no en borradores), enlaces profundos, preferencias y bandeja interna.
- Se mantienen UI nativa iOS 27+, Apple Watch, catálogo, escáner de pizarra, sesiones, progreso y Pro ya construidos. Android se implementa después con la misma semántica funcional y experiencia nativa.
- Precios de entrenadores y gimnasios: **pendiente de decisión**. No bloquear el dominio técnico por ese importe; catálogo comercial configurable.
- Objetivo final: iOS y Android de deportistas + portal profesional + backend; pruebas reales, compilación, documentación y entrega reproducible local.
- Ningún documento puede garantizar absolutamente todos los escenarios imaginables: la definición se cierra mediante matriz de aceptación, seguridad y pruebas reproducibles; casos nuevos se gestionan como cambios de alcance explícitos.

## 1. Situación real del repositorio y discrepancias a resolver

Existe Apps/Repera (SwiftUI), Apps/ReperaWatch, Apps/ReperaRestWidget, Packages/ReperaDomain, web/ (marketing), docs/, project.yml y la migración supabase/migrations/20261015120000_init_repera.sql.

La app existente persiste AppState como JSON local + espejo iCloud, realiza Sign in with Apple **local** mediante AppleAuthStore y usa RevenueCat/StoreKit para Pro. Esto **no equivale a autenticación Supabase ni a sincronización Android**. La migración SQL actual define tablas iniciales pero no acredita que estén desplegadas.

**Bloqueador de seguridad encontrado:** la migración existente permite leer perfiles a cualquier coach/gym_admin y leer workouts/workout_sets de todos los atletas a coaches y admins de gimnasio. No desplegar esa política en producción. La primera implementación debe cerrarla con RLS propietario/relación activa verificada y consentimiento expreso, antes de activar servicios profesionales. No utilizar el rol global profiles.role como permiso multiempresa: los permisos efectivos derivan de relaciones por organización.

No borrar ni migrar silenciosamente los entrenamientos de iCloud. Auditar primero el identificador estable, versión de los modelos, relaciones temporales y estrategia reversible de importación.

## 2. Arquitectura objetivo

- iOS: Swift 6 / SwiftUI nativo 27+, ReperaDomain existente, adaptador ReperaAPI, almacenamiento local, reconciliador de cambios; Watch sincronizado con teléfono. Nunca insertar claves secretas.
- Android: Kotlin / Jetpack Compose / Material 3, Room y DataStore, WorkManager para sincronizar, Health Connect opt-in, cámara/OCR según disponibilidad. Mismo catálogo canónico de movimientos y mismos códigos de reglas/errores.
- Portal profesional: Next.js + TypeScript + componentes accesibles, tres superficies bajo sesión: entrenador, gimnasio y administrador plataforma. SSR controlado y verificaciones en servidor; no volcar la service_role en navegador.
- Dominio: PostgreSQL con Supabase Auth, RLS, Edge Functions para operaciones privilegiadas y eventos, Storage privado para documentos estrictamente necesarios; Realtime solo donde añada valor.
- Push: APNs para iOS y FCM para Android; Edge Function/worker con cola persistida, idempotencia, expiración de tokens, reintentos y registro mínimo de entregas.
- Facturación digital de Repera Pro: StoreKit / Google Play, sincronización de entitlements verificables (RevenueCat si se decide unificar ambos); evitar conceder Pro por payload local.
- Facturación de gimnasios, entrenadores y servicios físicos: dominio de cobro configurable; proveedor y reglas de tiendas pendientes de revisión legal/comercial. Mantener facturas, cobros y ajustes separados por entidad fiscal y rol.
- Web de marketing: conservar web/ actual y su despliegue; apps/pro-portal/ independiente con dominio/subdominio propio, CSP, SSR y controles de sesión.

### Contratos y convenciones

- IDs UUID estables por recurso y usuario; created_at / updated_at UTC, fecha y zona IANA para clases. No usar email como identificador.
- Errores tipados (UNAUTHORIZED, FORBIDDEN, MEMBERSHIP_INACTIVE, CLASS_FULL, BOOKING_CONFLICT, VERSION_CONFLICT, PAYMENT_REQUIRED, OFFLINE, etc.).
- Operaciones con efecto repetible incluyen idempotency_key y revision/updated_at.
- Un solo origen de verdad de planes y reservas: backend; sesiones creadas por atleta nacen local y se sincronizan por entidad; iCloud queda como legado exportable durante la migración.
- UTC en almacenamiento; fechas renderizadas en la zona del gimnasio. Considerar cambio horario Europa/Madrid, usuarios de viaje y sesiones nocturnas.
- Contrato compartido: especificación SQL/RPC + OpenAPI de Edge Functions y fixtures JSON para pruebas Swift, Kotlin y TypeScript.

## 3. Personas, permisos y pertenencias

**Atleta:** consulta/modifica su perfil y sesiones, sus rutinas, sus reservas y sus facturas propias; acepta o retira relaciones con entrenador/gimnasio, permisos de historial y notificaciones.

**Entrenador:** administra su agenda, clientes vinculados y programas publicados para clientes con servicio contratado vigente; solo ve resultados del atleta cuando éste lo autoriza. No puede acceder a atletas ajenos ni deducir datos por ID.

**Gimnasio propietario/manager/staff:** gestiona únicamente su organización, instalaciones, cuotas, clases, instructores, aforos, socios, asistencia, facturas y analíticas agregadas. Un entrenador contratado recibe permisos acotados a sus clases/clientes, no permiso global a datos de salud.

**Administrador plataforma:** soporte y seguridad por flujo auditado de servidor, mínimo acceso necesario, sin lectura masiva directa desde cliente. Requiere MFA web para operaciones sensibles.

**Multirol/multiempresa:** una persona puede ser atleta y entrenador, pertenecer a varios gimnasios y elegir contexto; revocar pertenencia elimina acceso futuro inmediatamente. Las relaciones personales son explícitas, no inferidas de que alguien esté en un gimnasio.

### Matriz de capacidades (aplicar también a API/RLS)
- Atleta: CRUD sobre su diario, series y preferencias; consultar clases elegibles; reservar/cancelar su plaza.
- Coach asociado con servicio activo: publicar rutina para cliente, consultar asignaciones; leer historial **solo con consentimiento específico**; no editar sesiones ejecutadas.
- Gym manager: administrar oferta, profesores, aforos y agenda propia; consultar asistentes a sus clases; no leer entrenamientos personales por ser socio.
- Staff de recepción: check-in/check-out y gestión operativa acotada; sin datos de progreso.
- Soporte plataforma: acciones mediante endpoints de servidor con auditoría; nunca SELECT de todos los datos privados desde navegador.

## 4. Modelo de datos propuesto (normalizar antes de desplegar)

### Identidad y organización
profiles (usuario, nombre visible, preferencias mínimas); organizations (id, tipo gym/coach_business, nombre, zona, facturación); organization_members (organización, usuario, rol, estado); client_relationships (atleta, entrenador opcional, organización opcional, servicio, consentimiento de historial, estado/fechas, origen de contratación); invitations (token hasheado, expiración, recurso/rol, estado, un solo uso).

### Entrenamiento
exercise_catalog (catálogo canónico con ID estable y licencia auditada); custom_exercises (owner); templates/routines; routine_blocks; assigned_programs (asignación por atleta, entrenador, versión, draft/published/archived, visible_from); training_calendar_entries (fecha, ventana, plan y relación); workout_sessions; workout_sets; personal_goals opcionales; exercise_history se calcula desde sesiones propias. No duplicar resultados derivados salvo caché regenerable.

### Gimnasio
locations; spaces; classes (plantilla, duración, categoría); class_occurrences (fecha/hora/aforo/instructor/estado/versión); access_products (derechos adquiridos); enrollments (socio/plan/vigencia); reservations (único por atleta+clase, status confirmed/waitlisted/cancelled/attended/no_show); attendance; waitlist transitions y aforo atómico; bookings_audit.

### Comercio y facturación
billing_accounts (titular fiscal); product_catalog; professional_subscriptions; service_contracts; payments (referencia externa, importe/moneda/impuestos/estado); invoices/credit_notes y line_items; refunds; subscriptions/entitlements de atletas, eventos verificables con claves únicas; jamás almacenar PAN/CVV.

### Comunicación y operación
notification_preferences; device_push_tokens privados; notification_events/outbox (destinatario+tipo+recurso+versión/idempotencia); notification_inbox; delivery_attempts resumidos; audit_events de acciones administrativas; sync_changes/sync_cursors/versiones.

**No almacenar por defecto:** muestras crudas de frecuencia cardiaca, GPS, diagnósticos, permisos de Salud, fotos no necesarias, dirección postal del atleta, fechas de nacimiento si no hay requisito legal ni capturas de notificaciones. Medidas de progreso compartidas solo bajo consentimiento y con campo estrictamente necesario.

## 5. Flujos UX y estados de pantalla

### App atleta móvil, preservando estructura actual
- Inicio: resumen semanal, próxima actividad, accesos a entreno, aviso de nuevo programa y nueva clase; cards skeleton/empty/error/offline.
- Diario: plan semanal propio + planes asignados claramente diferenciados, fecha de versión y quien lo publicó; no sobrescribir autoentrenos sin confirmación.
- Crear/Sesión: entrenar offline; series, WOD, tiempos, RPE, descanso; recuperación ante cierre forzoso; Apple Watch; sin bloqueo por sincronización.
- Progreso: histórico y métricas Free/Pro; si falta permiso Salud, métricas propias no deben desaparecer.
- Ejercicios: catálogo, favoritos, evolución limitada según plan; imágenes, accesibilidad y texto alternativo.
- Nueva sección contextual 'Mi gimnasio y entrenador': relaciones verificadas, prestaciones activas, agenda y clases disponibles, detalles de cupo, reserva/cancelación, lista de espera.
- Notificaciones: centro propio con leído/no leído, deep links y ajustes granulares; badges solo por eventos relevantes.
- Ajustes: cuenta, privacidad, consentimiento granular para historial compartido, exportar, eliminar, cerrar sesión, sincronizar ahora con estado real, compras/restore, permisos.
- Login: Apple en iOS; Google/Apple/email según plataforma y política; ambos enlazados a un único usuario Supabase. Nunca crear identidades duplicadas sin flujo explícito de vinculación.

**Convenciones iOS:** respetar Theme.swift y componentes OG, navegación nativa, Liquid Glass iOS 27, barra superior sin dobles círculos, estados Loading/Empty/Error, VoiceOver, Dynamic Type y reducción de movimiento. Android: Material 3 y navegación nativa; adaptar el patrón, no clonar píxel a píxel una UI SwiftUI.

### Portal entrenador
Panel principal (clientes activos, próximas sesiones, nuevas solicitudes, alertas); Clientes (invitación, contratación y consentimiento); ficha cliente con historial permitido; editor de programa de entrenamiento con borrador, vista previa y publicación versionada; calendario; disponibilidad; seguimiento y mensajes/avisos operativos; facturación y métricas, configuración y miembros si actúa como negocio.

### Portal gimnasio
Resumen (aforo, reservas, socios, incidencias, cobros); Sedes/Salas; Clases y horario por semana; editor de clase/ocurrencia con aforo y cupos; socios y altas/renovaciones; profesores con permisos; reservas/lista espera/asistencia; planes/cuotas, pagos/facturas/notas de crédito; informes agregados; ajustes empresa/roles/notificaciones.

### UI web
Sidebar contextual por negocio; topbar con selector de organización, búsqueda y usuario; tablas con filtros persistidos, paginación servidor, accesos por teclado; formularios con guardado borrador/validación/autosave discreto; confirmación de acciones destructivas; calendario semana/mes/lista; estados de pantalla y toasts no engañosos; diseño responsive en tablet; WCAG 2.2 AA como objetivo de aceptación.

## 6. Casos de uso y decisiones de borde (test obligatorios)

**Cuenta y datos:** primer registro; permiso denegado; login interrumpido; email oculto de Apple; duplicado entre proveedores; sesión vencida; cierre de sesión; cambio de móvil/OS; usuario sin red; reautenticación; derecho de exportación y supresión; usuario con varios gimnasios; cliente que es además entrenador; transferencia de titularidad; dispositivo perdido.

**Programas:** entrenador crea borrador → edita sin avisar → publica versión → solo clientes activos asignados reciben aviso; republica sin cambio no duplica; modifica programa durante sesión activa no corrompe registro; fin de contrato revoca acceso a versiones futuras pero no borra entrenos propios; alumno sin conexión recibe versión al recuperar; atleta rechaza compartir historial y entrenador deja de verlo.

**Clases:** calendario nuevo → solo socios elegibles reciben aviso; club publica varias clases en lote → agrupación; cambio de instructor; cancelación; cambio de sala/hora; reserva última plaza por dos clientes simultáneos (una gana); no superar aforo; lista de espera y ascenso atómico; dos reservas mismo usuario; cancelar y reintentar; fecha límite cancelación; check-in; clase ya iniciada; zona horaria/DST; membresía caducada; membresía en pausa; instructor de baja; sede cerrada; evento privado/no publicado.

**Cobros:** trial elegible/no elegible; suscripción Pro renovada/revocada; compra pendiente; restore; cambio de sistema operativo manteniendo cuenta y acceso legítimo; pagos duplicados por webhook reintentado; reembolso; descuento; factura rectificativa; fallo fiscal; impago; cobro manual; cambio de titular de gimnasio; prorrateo según decisión comercial futura. Webhooks idempotentes y firma verificada.

**Push:** consentimiento denegado → bandeja sí; token antiguo/revocado; notificación recibida con sesión cerrada; borrador no avisa; envío duplicado no duplica; destinatario deja de ser elegible antes del envío; clase cancelada siempre destaca; tap abre recurso si sigue permitido y muestra fallback si desapareció; silencio nocturno para avisos no urgentes; no filtrar datos sensibles en lock screen; reintentos sin tormenta.

**Privacidad/seguridad:** atleta A intenta leer atleta B; entrenador ajeno consulta UUID de otro cliente; entrenador asociado sin consentimiento intenta leer sesiones; gimnasio A intenta leer B; empleado despedido intenta entrar; atleta intenta autopromoverse; IDs manipulados y paginación maliciosa; roles alterados en metadata; JWT caducado; doble publicación; replay de webhook; descarga de PDF de otra organización; URL Storage expirada; backups/restauración.

**Offline/sync:** crear entrenos en iPhone y Android sin conexión, editar uno, reencontrar conflicto; duplicados y orden de series; idempotencia; importación de legado JSON/iCloud; cambios de catálogo; sesión a medias; fallo de escritura local; red intermitente; backend inaccesible; recuperación con último estado fiable, sin spinner infinito. Nunca usar last-write-wins silencioso para sesiones simultáneas con cambios divergentes.

## 7. API y seguridad

- Supabase Auth es identidad común; credenciales Apple y Google verificadas server-side. No confiar en claims editables por usuario.
- RLS en toda tabla expuesta. Atleta ve solo su ID; empleados únicamente vía membresía de organización activa y scopes por función; coach solo relación vigente y opt-in para historial. Escritura de invitaciones, roles, contratos, published/booking y facturas por RPC/Edge Functions autenticadas con transacción.
- Preferir funciones SECURITY INVOKER; si hay SECURITY DEFINER justificada, ubicar en schema privado, restringir EXECUTE, fijar search_path, validar auth.uid y auditar.
- Reservas y aforo en transacciones/constraint; nunca 'leer aforo y luego insertar' desde cliente.
- Índices por owner_id, organization_id, athlete_id, assigned_coach_id, occurrence_id, status/created_at y claves de idempotencia; EXPLAIN antes de índices extra.
- Webhook de cobro con firma, timestamp y dedupe; finanzas y facturas respaldadas por conciliación, no por evento del cliente.
- MFA obligatoria para administradores financieros; rate limits, logs sin tokens/PII, rotación de secretos, separación dev/staging/prod y mínimos privilegios.
- RGPD: base legal por finalidad, acuerdos de encargado, política de conservación limitada, exportación/eliminación verificable, consentimiento revocable, solicitud de acceso, registro de tratamiento y revisión legal antes del lanzamiento.
- Integraciones salud: lectura local autorizada, cualquier subida desactivada por defecto; no usar información de salud con fines publicitarios.
- Notificaciones: la decisión del destinatario se revalida en el worker **al despachar**, no solo al publicar; payload exterior genérico si la información pudiera ser sensible.

## 8. Eventos y notificaciones (contrato)

Eventos inmutables: program.published, program.updated, calendar.published, class.available, class.changed, class.cancelled, booking.confirmed, booking.cancelled, waitlist.promoted, invoice.issued. Campos: event_id, actor_id, organization_id, resource_id, resource_revision, happened_at UTC, idempotency_key.

Pipeline: transacción de publicación → outbox → worker busca receptores elegibles de forma segura → preferencias + quiet hours + idempotencia → inbox persistente → APNs/FCM → estado de entrega. No enviar al pulsar Guardar borrador. Push se minimiza y se agrupa si hay muchas clases. Deep link /program/{id}, /classes/{id}, /reservations/{id} con autorización al abrir.

## 9. Analíticas, retención y operación

- Métricas agregadas por rol y organización: usuarios activos, tasa de completar entrenamiento, publicación → apertura, clases creadas/reservadas/asistencia, cancelaciones, ingresos conciliados, churn, conversión Free→Pro, MRR profesional si existe. Nunca cruces entre organizaciones.
- Telemetría sin datos de salud, minimizada/consentida según proveedor y legislación; no enviar nombre, email, tokens ni texto libre a analíticas.
- Observabilidad: error rates de API, lag de outbox, push fallidos, reservas con conflicto, sincronizaciones pendientes, compras no verificadas, latencia p95, incidentes de RLS.
- Backups y restores ensayados; alertas por crecimiento y presupuesto de Supabase Free; plan de migración a pago cuando datos, almacenamiento, límites de ejecución o SLA lo exijan.

## 10. Mapa de archivos de implementación

### Archivos existentes a conservar/adaptar
- Apps/Repera/Sources/ReperaApp.swift: bootstrap sesión backend y ciclo de vida.
- Apps/Repera/Sources/Onboarding/AppleAuthStore.swift: reemplazar identidad Apple solo local por intercambio token con Supabase y vinculación consistente.
- Apps/Repera/Sources/LocalStore.swift: mantener caché rápida; pasar espejo remoto desde iCloud a adaptador Supabase; ofrecer importación legado.
- Apps/Repera/Sources/ReperaStore.swift: repositorios por entidad y colas de sincronización; no convertir un JSON gigante en última escritura ganadora remota.
- Packages/ReperaDomain/Sources/ReperaDomain/Models.swift: añadir contract DTO/versión sin romper Codable legado.
- Apps/Repera/Sources/PlanView.swift, HomeView.swift, RootTabView.swift, SettingsView.swift: módulos personales + calendario/avisos + preferencias + sync.
- Apps/Repera/Sources/Monetization/SubscriptionManager.swift y RevenueCatEntitlementProvider.swift: conciliar entitlement backend sin conceder Pro local.
- Apps/Repera/Sources/Theme.swift: respetar tokens y componentes existentes.
- web/: conservar marketing; actualizar legales cuando haya tratamiento real de datos.

### Archivos nuevos previstos, organizados por frontera
- supabase/migrations/: 1) reparación RLS y enlaces autorizados, 2) org/membresías, 3) programas y publicación, 4) clases y reserva atómica, 5) contratación/facturas, 6) notificaciones/sync/auditoría.
- supabase/tests/: pruebas SQL de owner, relaciones, RLS cruzada, aforo concurrente, roles, idempotencia.
- supabase/functions/: invite-member, publish-program, publish-calendar, reserve-class, cancel-reservation, payment-webhook, dispatch-notifications, generate-invoice, export-user-data, delete-user-data.
- Apps/Repera/Sources/Backend/: SupabaseSession, APIClient, AthleteRepository, AssignedProgramsRepository, BookingRepository, NotificationRepository, SyncCoordinator, LegacyImporter.
- Apps/Repera/Sources/Professional/: AssignedProgramView, ClassesCalendarView, ClassDetailView, BookingView, InboxView, PrivacySharingView.
- Apps/ReperaUITests/: login/migración/programas/reservas/offline/push/pagos.
- android/app/src/main/: ui/home|diary|session|progress|library|classes|account, data/local|remote|sync, domain/model|policy, notifications, health, tests.
- apps/pro-portal/: app/(auth), app/(coach), app/(gym), app/(admin), components/ui, features/clients|programs|calendar|bookings|memberships|billing|analytics, lib/auth|supabase|permissions, tests/e2e.
- contracts/: HTTP/Edge OpenAPI, JSON fixtures, event schemas and DTO versions.
- .github/workflows/: checks SQL/RLS, Swift tests/UI, Android Gradle tests, web lint/typecheck/e2e, secret scanning.

## 11. Fases, orden obligatorio y definición de terminado

**Fase 0 — seguridad y diseño:** documentación viva, matriz de roles, auditoría de RLS actual, contratos/versiones, diagrama de datos, pruebas negativas antes de usuarios reales. Sin despliegue en Cafesito. (Primera entrega de la rama actual.)

**Fase 1 — entorno Repera aislado:** crear proyecto Free propio; migraciones revisadas; backups y RLS; credenciales públicas por entorno, secretos solo servidor; seed de datos de prueba. Aceptación: dos atletas + dos orgs no se leen entre sí; pruebas SQL verdes.

**Fase 2 — identidad y migración iOS:** Supabase Auth, Apple token verificado, vinculación cuentas, offline/sync incremental, importación iCloud opt-in, export/rollback. Aceptación: cerrar sesión vuelve a login; progreso no se pierde; dos dispositivos sincronizan; conflicto controlado.

**Fase 3 — profesional web base:** Next.js, login + MFA profesional, contextos de organización, roles, invitación/contrato, gestión de clientes, navegación y accesibilidad. Aceptación: usuarios de org A nunca ven org B, auditoría y tests E2E.

**Fase 4 — programas personales:** editor versionado con borradores/publicación, asignación, lectura móvil, consentimiento, revocación, notificaciones. Aceptación: guardado borrador no avisa, publicar sí, solo cliente correcto, tap abre programa.

**Fase 5 — gimnasios y calendario:** clases/salas/instructores, aforo, contratos, reservas, lista espera, cancelaciones, agenda móvil, push. Aceptación: doble reserva concurrente nunca excede aforo, cancelación avisa a afectados, control de elegibilidad.

**Fase 6 — comercio y facturación:** catálogo de ofertas configurable, conciliación de suscripciones móviles, cuotas profesionales/web, cobros/facturas/abonos, impuestos y reportes. **No fijar precios de gimnasios/entrenadores hasta decisión**; revisar compliance de tiendas.

**Fase 7 — Android nativo:** Compose, Room, auth, workout/offline, biblioteca, progreso, calendario, reservas y push FCM; Health Connect opcional. Aceptación: Android+iOS comparten la misma cuenta sin perder datos; funciones equivalentes.

**Fase 8 — endurecimiento y lanzamiento:** permisos, carga, dispositivos reales, accesibilidad, RGPD, restores, incident runbook, analíticas, monitorización, versiones y despliegues escalonados.

### Pruebas y calidad mínimas
- Unitarias y contrato: Swift Package ReperaDomain, Kotlin, TypeScript + JSON fixtures iguales para ambas plataformas.
- Backend: migrations en instancia limpia y actualizada, RLS test con JWT usuario A/B, benchmarks de reserva concurrente y dispatch idempotente.
- E2E navegador por rol; XCUITest, instrumentados Android; pruebas sin red, DST, permisos denegados, restauración y compra sandbox.
- CI en PR sin secretos sensibles: lint/format/test/build de módulos y verificación esquema. Merge solo verde y revisión.
- SLO operativos propuestos: sincronización eventual al recuperar red; publicación de push con latencia observada y cola rastreable; ninguna fuga cross-tenant.
- Evidencias antes de declarar entregado: capturas, logs redactados, builds instalables, test report, instrucciones y checklist de QA.

## 12. Cómo probar en local y distribución

1. Clonar rama: git clone -b feature/multiplatform-foundation-20261019 https://github.com/rmoya87/repera.git
2. iOS existente: xcodegen generate; abrir Repera.xcodeproj; disponer de Xcode compatible iOS 27; ejecutar en iPhone/simulador. El Watch requiere destino correspondiente. La implementación nueva no debe alterar el arranque hasta completar Fase 2.
3. Dominio actual: cd Packages/ReperaDomain && swift test.
4. Web marketing actual: cd web && python3 -m http.server 8080. **No es aún panel profesional**.
5. Backend local futuro: instalar Supabase CLI + Docker; consultar supabase --help, ejecutar supabase start/db reset según versión instalada, aplicar migraciones de rama y ejecutar pruebas RLS antes de conectar apps. Las migraciones en git no significan que se hayan aplicado al proyecto remoto.
6. Panel web futuro: instalación lockfile pinneada y tests; .env.local solo con URL + clave publicable y secretos servidor, nunca service_role en cliente.
7. Para probar pagos móviles usar StoreKit Configuration/TestFlight sandbox y Google Play test tracks; prohibido simular compra como éxito de producción.

## 13. Estado de cierre

**Cerrado como requisito funcional:** plataformas y roles, privacidad mínima, notificaciones de publicación, reservas, planes, facturación y analíticas, seguridad multiempresa, experiencia offline.
**Abierto conscientemente:** tarifas de gimnasios/entrenadores, proveedor de pagos profesionales y política de tratamiento fiscal definitiva, criterios legales especiales según país, diseño visual detallado pantalla a pantalla y diseño final de Android; convertir en ADRs antes de cada implementación.
**Todavía no implementado:** backend remoto Repera, portal profesional, Android, API de programas/clases/contratación; no confundir esta especificación con producto terminado.

Esta documentación es el mapa de ejecución. Cada fase exige implementar código, escribir pruebas y actualizar estado/archivos de documentación sin proclamar funcionalidades aún inexistentes.
