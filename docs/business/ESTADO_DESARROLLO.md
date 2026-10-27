## Administración global de Repera — 27/10/2026

- Nueva consola **independiente** para `platform_admin` en `web/console/src/ui/platform-admin.js` con menú de Inicio, Gimnasios, Entrenadores, Usuarios y clientes (agregados), Pagos B2B, Planes, Soporte, Auditoría y Configuración. Listados buscables y filtrables, fichas del negocio con datos públicos, recuentos de clientes y sesiones, plan, estado y actividad.
- RPCs con validación de administrador verificado: `platform_admin_directory`, `platform_admin_finances`, `platform_admin_history`, `platform_admin_pending`, `platform_admin_set_status`, `platform_admin_provision`. Altas administrativas se guardan como **pendientes**, el propietario reclama la organización al iniciar sesión con email confirmado. No hay envío automático de invitación por correo.
- Acceso delegado a **un negocio cada vez**, motivado, 30 minutos máximo y revocable: `platform_admin_delegate` / `platform_admin_current_delegation` / `platform_admin_end_delegation`. Usa el JWT propio del administrador, sin contraseñas ni intercambio de sesión; `private.has_org_role` concede permisos de gestión con delegación vigente, excluye políticas exclusivas de atleta. Entrada y salida registradas en `platform_admin_events`.
- Se incorpora `platform_billing_payments`, ledger de pagos **B2B verificados exclusivamente desde backend privilegiado**; la web muestra cobros e intenciones por separado, filtrado por organización y estado, y exportación CSV.
- **Límites explícitos:** Stripe Billing, Stripe Connect, webhooks firmados, cobros B2C, facturas fiscales, recordatorios por correo y soporte con tickets aún no están integrados. La vista de pagos reales estará vacía hasta conectar un proveedor. El panel global no abre historiales personales del deportista sin consentimiento y relación autorizada.
- Migración `20261027120000_platform_admin_console.sql` aplicada al proyecto Repera y requiere pruebas de navegador con cuentas de roles distintos antes de dar por cerrado el acceso delegado end-to-end. No equivale a despliegue en IONOS.

## Alta empresarial y catálogo comercial — 20/10/2026

Se incorpora al panel conectado un formulario de alta con identificador derivado del nombre, ficha comercial, datos fiscales privados y foto/logotipo opcional, además de edición desde Ajustes. Los planes dejan de estar fijados en el frontend: catálogo `business_plans` configurable por administración verificada, con separación entrenador/gimnasio y visibilidad configurable. La selección de plan no equivale a compra ni cambia `paid_plan`/entitlement. La migración crea `organization_legal_profiles` con RLS de propietario/admin y bucket de imágenes públicas `business-branding`, con escritura restringida a miembros gerentes. **Pendiente**: validar alta real y carga de archivos en navegadores, comprobar reglas de imagen y conciliación comercial antes de producción.

# Estado de desarrollo — Repera Business
Última actualización: 2026-10-20.

## App iOS (2026-10-20)
- Ajustes: buscar/vincular centro o entrenador + bono; acceso completo mientras vinculado; ficha con bonos/sesiones/desvincular; sync unificado; acentos negros.
- Mensajes en topbar de Inicio; avatares de organización en app y consola Business.
- Migración pendiente de aplicar en remoto: `20261020140000_org_directory_avatar_messaging` (avatar, directorio, link/leave, mensajes atleta).

## IMPLEMENTADO (verificado en Supabase Repera)
- Proyecto `uvzgujlrqohreoucirms` conectado y sano; PostgreSQL 17.
- Primera migración real: `20261019190623_business_foundation_secure` (registro en `supabase_migrations.schema_migrations`).
- Tablas públicas implantadas: **16**, todas con RLS. Incluyen identity/MVP personal, clientes, invitaciones, sesiones/bonos/reservas y planes de entrenamiento profesionales.
- Trigger de perfil con usuario de Auth; trigger para incorporar propietario al crear una organización.
- Acceso de miembros y managers con helper privado y validación de sesión; rol global no modificable por cliente.
- Primer smoke test transaccional RLS superado: dos usuarios de prueba, aislamiento y autorización negativa; ROLLBACK sin datos persistentes.
- Borrador antiguo `20261015120000_init_repera.sql`, no aplicado, sustituido por baseline seguro en esta rama.

## IMPLEMENTADO adicional (2026-10-19)
- Reincorporado y revisado el prototipo Business v0.2 presente en la rama: web/console, scripts, contratos Swift/Kotlin y SQL greenfield **no aplicado**.
- Panel web profesional: acceso conectado por defecto a Supabase Auth (correo+contraseña, registro, recuperación, renovación, logout), organizaciones reales, actualización segura del nombre y primera ficha de clientes potenciales; demo aislada mediante `?demo=1`.
- Nuevo esquema incremental `20261019193414_business_clients_scoped`: clientes por organización y asignaciones limitadas por permisos (sin interfaz de asignación aún); no comparte HealthKit ni entrenamientos privados.
- La clave de navegador es `sb_publishable_` pública, y el código rechaza otro proyecto Supabase; no existe service_role en el cliente.
- No se ha desplegado la consola en IONOS. Auth configurado en producción (SMTP, redirects, Confirm email) aún necesita verificación E2E.

## CAMBIO DE EXPERIENCIA iOS (implementación parcial)
- Barra nativa iOS: `Inicio · Diario · Crear|Center · Progreso · Ejercicios` (Center solo con vínculo a centro/entrenador); el hub Crear también desde + de Inicio.
- Diario abre en vista Entrenador (sesiones profesionales reales si existen, estado vacío si no); planificación personal y rutinas intactas en pestañas secundarias.
- Center es pantalla nativa con selector Clases/Citas, consulta real del backend y botones de reserva/cancelación mediante RPC, sujetos a sesión Apple→Supabase y bono válido; integración iOS pendiente de pruebas en dispositivo.
- Ajustes separa centros/entrenadores y bonos reales obtenidos del backend, con sesiones restantes y vencimiento; Repera Pro se mantiene independiente.
- Contrato móvil de agenda ampliado con `appointment` y `repera://appointments/{id}` en Swift y Kotlin, con pruebas de contrato añadidas: Kotlin JVM 6 comprobaciones ejecutadas correctamente; sintaxis Swift del contrato verificada con swiftc -parse. La suite XCTest completa agotó el tiempo del entorno y permanece sin validar.
- Pendiente: verificar en dispositivos el puente Sign in with Apple ↔ Supabase y flujos completos, añadir contratos de pago/facturación, ciclos de plan avanzados, lista de espera y notificaciones.
- Compilación Xcode iOS 27, UI tests y TestFlight: **no ejecutadas desde el conector**; no marcar como probado.

## PROBADO
- `list_tables`: 16 tablas públicas, RLS=true en las 16. `list_migrations`: 7 versiones aplicadas en Supabase Repera.
- `get_advisors(security)`: 0 advertencias después de desplegar las siete migraciones. Las funciones privilegiadas operan dentro de `private`, con wrappers públicos INVOKER.
- `get_advisors(security)`: 0 lints al terminar.
- SQL de comprobación: `rls_smoke_pass`, organizaciones persistentes de prueba = 0.
- Estas pruebas NO constituyen auditoría integral ni validan la integración web/iOS.

- Smoke SQL clientes: `clients_rls_smoke_pass` y `persisted_clients=0`; prueba rollback con dos usuarios, inserción no autorizada bloqueada y columna de vinculación protegida.
- Cinco pruebas de lógica de autenticación ejecutadas en V8 aislado; no sustituyen `node --test` ni prueba de navegador real.
- JavaScript / Swift / Kotlin de v0.2: el usuario informa 37/2/3 pruebas superadas; este paso no ha reproducido todas esas suites ni el CI iOS.

## Lanzadores locales añadidos (2026-10-19)
- `Repera-Business.command`: doble clic en Mac, Python 3, servidor loopback y apertura automática de la demo profesional (sin datos reales).
- `Repera-iOS.command`: doble clic en Mac, comprueba Xcode/XcodeGen/SDK iOS 27, intenta compilar, instalar y arrancar la app en Simulator.
- **Pruebas de ejecución**: sintaxis de ambos scripts verificada con `bash -n`; servidor del lanzador Business probado con HTTP en `127.0.0.1` y ruta demo correcta. Lanzador iOS pendiente de ejecutar en Mac con Xcode + SDK iOS 27; ninguno demuestra por sí solo que CI/builds nativos sean correctos.
- **No merge a main**: funcionalidades esenciales sin validar E2E (Apple Auth, iOS, reserva real bajo concurrencia), pagos/facturación/lista de espera/planes avanzados pendientes y cuatro jobs CI fallidos.

## Vinculación consentida — backend y panel (2026-10-19)
- Esquema incremental `20261019201141_business_org_invitations_consent` añade invitaciones por correo verificado y rol permitido (no owner), caducidad a 14 días, cancelación, protección multiempresa y aceptación explícita.
- Esquema incremental `20261019201248_business_invitation_private_rpc` mueve todas las operaciones privilegiadas al esquema `private` y deja solo wrappers INVOKER en API pública; advisors de seguridad: 0 lints.
- Al aceptar, crea o reactiva membresía y vincula la ficha del deportista **solo** tras consentimiento. No se transfieren datos personales de Salud, entrenamientos o iCloud.
- SQL real en transacción: `invitation_rls_smoke_pass`, adversario no accede ni acepta, aceptación válida crea vínculo y no permite reutilizar; ROLLBACK, 0 datos de prueba persistidos.
- Panel profesional autenticado: emisión de invitaciones de miembro y aceptación desde la propia cuenta Supabase con correo confirmado; **sin entrega de emails automática ni conexión Apple→Supabase iOS todavía**.

## Servicios y reservas con crédito (backend en construcción)
- Migración incremental `20261019201914_business_services_booking_wallets`: 4 nuevas tablas con RLS: `service_occurrences`, `service_passes`, `service_bookings`, `service_credit_ledger`.
- Clases grupales con aforo, citas 1:1 con exclusividad de entrenador, reservas atómicas (bloqueo de plaza y bono), petición idempotente, saldos separados para clases/citas, devolución de crédito al cancelar con al menos 12 horas de antelación (regla provisional).
- Emisión de **bonos de cortesía** por owner/admin exclusivamente, sin confundirlos con pagos o derechos adquiridos. Los pagos reales y facturas están pendientes.
- SQL smoke `business_booking_smoke_pass`: horario sin solapes, doble petición no duplica, bonos separados, doble reserva denegada, cancelación devuelve 1 crédito; ROLLBACK (0 reservas persistentes). Advisors de seguridad: 0 lints.
- Panel conectado: vista de horarios reales, alta de clases y citas por propietario/admin, emisión explícita de bonos de cortesía a clientes que aceptaron la invitación; consulta de balances y reservas del centro.
- No hay todavía reserva nativa desde iOS, bonos de pago, facturación, listas de espera ni confirmaciones push.

## Puente Apple → Supabase en iOS (pendiente de compilación/E2E)
- SDK oficial `supabase-swift` versión exacta 2.55.4, llave `sb_publishable_` pública específica del proyecto Repera.
- `BusinessAuthStore`: valida project URL, usa nonce aleatorio generado por SecureRandom y SHA-256 para el ID token Apple; `signInWithIdToken` del SDK intercambia identidad por sesión Supabase.
- El onboarding mantiene la sesión Apple e iCloud aunque Supabase no esté disponible; no se copian historiales privados. Las cuentas Apple existentes pueden reautorizarse desde Ajustes para obtener token fresco.
- `ReperaApp` restaura la sesión profesional asíncronamente; al cerrar sesión también solicita cierre de Supabase.
- **Falta compilar y ejecutar iOS 27/TestFlight**, configurar/verificar el proveedor Apple de Supabase, probar login real y sesiones; sin ello NO afirmar que todas las cuentas ya estén registradas.

## Datos reales del deportista en iOS (implementación a validar)
- `BusinessDataStore` consulta organizaciones vinculadas, invitaciones pendientes, horarios reales, pases y reservas de titular mediante el SDK Supabase y las políticas RLS.
- `CenterView` muestra clases/citas reales, aceptación de invitaciones, reserva con bono compatible y cancelación mediante RPC transaccional (no opera sin sesión).
- `HomeView` añade tarjetas de clases/citas **confirmadas** en el día seleccionado, sin alterar `ReperaStore`/iCloud/HealthKit.
- Ajustes lee los centros vinculados y el saldo/caducidad reales de cada bono, separados de Repera Pro. No permite compra/facturación no verificada.
- **Pendiente crítico**: compilar bajo Xcode iOS 27 y validar Apple OAuth provider, respuesta del SDK, errores de PostgREST, sesiones y flujos completos. Sin tests manuales reales, no declarar listo para producción.

## Entrenamientos del entrenador — backend + web
- Migración `20261019203258_business_professional_training_sessions` crea sesiones fechadas con RLS por cliente y entrenador autorizado, publicaciones idempotentes y cancelación restringida. La ficha del usuario solo se comparte si la invitación fue aceptada.
- RPC `assign_coach_client` permite que owner/admin asigne un entrenador activo al cliente, sin escritura directa en tabla de relaciones.
- Panel conectado: listar sesiones profesionales, publicar entrenamientos fechados y asignar entrenadores a clientes vinculados.
- Smoke PostgreSQL `professional_sessions_smoke_pass`: owner publica, duplicado no se añade, deportista vinculado lee, deportista no puede suplantar al entrenador; 0 datos persistidos.
- Pendiente editor semanal 1–52 semanas con bloques estructurados, versiones, histórico de cambios y entrega de entrenos completos ejecutables en iOS.

## Entrega móvil de planificación profesional (lectura)
- `BusinessDataStore` lee `professional_training_sessions` y filtra por `client_id` del deportista autenticado, además de RLS del servidor.
- `Diario → Entrenador` muestra los entrenamientos fechados y las instrucciones publicadas; `Inicio` presenta los asignados al día elegido, sin eliminar rutinas personales.
- La prescripción todavía es de texto libre; no hay importación automática a un `Routine` ejecutable con bloques/series ni captura de resultados vinculada al entrenador. Se mantiene separado el historial privado local/iCloud.
- Pendiente compilación iOS 27, prueba de autorización real con Apple, push, versionado avanzado y flujos de edición/cancelación completos.

## Aforo real protegido para el deportista
- RPC `get_service_availability`: solo miembros activos consultan identificador, plazas reservadas y capacidad de su organización (no muestra clientes ajenos).
- `BusinessDataStore` consulta aforo y `CenterView` distingue disponible, completo o aforo desconocido. Se deshabilitan reservas a ciegas, sin sustituir las comprobaciones transaccionales definitivas del backend.
- Smoke de seguridad SQL superado: propietario lee, tercero denegado, ROLLBACK, cero datos persistidos.
- Pendiente verificar iOS 27 compilado y concurrencia real en dispositivos; sin lista de espera.

## CI de negocio separado del runner iOS
- `.github/workflows/repera-business-ci.yml`: Node 22 ejecuta las pruebas de `web/console`; otro job comprueba inventario de migraciones, smoke SQL y docs.
- El CI iOS preexistente falla en cuatro jobs incluso antes del primer paso (GitHub devuelve `steps: null`, `logs_url: null`, logs 404). Causa de infraestructura/cola por confirmar; **no son pruebas concluyentes de errores de Swift**.
- El nuevo CI aporta diagnóstico independiente, pero sus checks tampoco sustituirán pruebas Supabase con tokens reales y E2E en iPhone.

## Endurecimiento de sesión y cancelación
- Limpieza de respuestas asíncronas obsoletas al salir/cambiar identidad Apple con `refreshRevision`, verificación de usuario Auth justo antes de presentar datos y sesión SDK cerrada si no coincide la identidad Apple local.
- Cancelar reserva requiere confirmación nativa y expone el riesgo de perder el crédito cuando faltan 12h según la política provisional (la transacción servidor determina el resultado).
- Pruebas Swift/iOS 27 sobre concurrencia, revocaciones y UX de cancelación pendientes; no dar por validadas sin Xcode.

## Reparación de CI iOS 27 (2026-10-19)
- Workflow `.github/workflows/ios27-ci.yml`: cambia el job de build de `macos-15` a `xcode-27` (imagen GitHub GA publicada 15/10/2026, con SDK iOS 27/watchOS 27 y Apple Silicon). Ya no fuerza el Xcode antiguo desde `/Applications/Xcode.app`.
- Compila iOS con destino genérico y sin firma para desacoplar errores de Swift de la disponibilidad de simulador; Watch utiliza `-target ReperaWatch` directamente para no depender de un scheme autogenerado.
- Añade validación `swiftc -frontend -parse` de fuentes, selección explícita de simulador iOS 27 para tests y logs/xcresult como artifacts.
- **Pendiente confirmar**: que el ejecutor de GitHub Actions admita jobs (los fallos anteriores a cada step también ocurren en `main`) y que Xcode 27 compile/reproduzca las pruebas. No se ha validado localmente un build Apple: este entorno es Linux.

## Diagnóstico real obtenido al reactivar CI
- El runner de GitHub ya ejecuta steps. Dos jobs de ReperaDomain fallaban por desajuste reproducido: `swift-tools-version: 6.4` frente a Swift 6.1 (macos-15) y 6.3.3 (macos-latest/macOS 26). Se pasa la prueba de dominio y caption al runner `xcode-27` y se selecciona expresamente la toolchain.
- Panel Business: 42/44 tests pasaban; los dos fallos no eran fallos de Auth sino fixtures con `refresh_token: 'r1'` (2 caracteres), rechazados correctamente por el código. Se corrigen los fixtures a refresh tokens sintéticos válidos de más de 2 caracteres.
- Compilación Xcode 27 iniciada y lectura de logs en curso; no se declara superada hasta conocer el resultado.

## Correcciones de tests de dominio tras logs Swift 6.4
- Eliminada la dependencia rota de `/tmp/repera-parser-bench/exercises.json` en dos pruebas de parsing: usan `Catalog.seed()` embarcado en Repera. No se eliminan pruebas.
- El catálogo ha crecido de 188 a 189 con `Back rack reverse lunge`: descripción y siete instrucciones técnicas en español añadidas; la aserción protege mínimo de 188 sin impedir nuevos movimientos.
- El test Chipper valida identificación de bloque y número de series, en lugar de depender del nombre localizado `Run`/ `Correr`.
- Se evita un `localizedStandardCompare` caro en cada empate de ranking del buscador: usa la clave de nombre normalizada y precomputada, preservando orden por puntuación; test de rendimiento <3ms debe volver a medirse en CI Xcode 27.
- Validación Swift 6.4 con CI todavía necesaria; las modificaciones siguen en rama.

## Error real de compilación watchOS corregido en workflow
- Los logs de Xcode 27 mostraron `actool: AppIcon did not have any applicable content` porque el comando global `-sdk iphonesimulator` forzaba al target `ReperaWatch` (integrado en la scheme iOS) a compilar con iconos de iPhone; actool ejecutaba `--platform iphonesimulator` sobre `Assets.xcassets` de Apple Watch. Se retira ese flag y se deja que los targets seleccionen automáticamente iOS Simulator y watchOS Simulator según su plataforma.
- No se han inventado ni sustituido iconos de Watch; se mantiene el catálogo real del proyecto. Pendiente validación de build posterior con CI.

## Buscador de ejercicios optimizado para test de rendimiento
- La búsqueda `ExerciseSearch.rankedDocuments` evita puntuar el mismo criterio dos veces cuando los alias o las palabras vacías dan tokens idénticos, y devuelve resultados inmediatamente al encontrar coincidencia de prefijo/frase claramente superior al resto de pesos. No se ha elevado el límite del test (<3 ms).
- Última medición Xcode 27 previa: 74/75 pruebas de dominio correctas, test de ranking 6,27 ms fallido. Pendiente nueva ejecución y medición.

## Fix de variante WOD: Bar facing burpee
- `CrossFitGlossary.canonicalName` ahora conserva la variante explícita `Bar facing burpee`, evitando que el alias parcial `burpee` degrade un movimiento específico cuando la pizarra incluye `8 BOB`. Test de regresión agregado junto al importador real.
- Con Xcode 27 la última ejecución obtuvo 75 XCTest verdes y 68/69 pruebas Swift Testing verdes; la única pendiente era esta variante, corregida y pendiente de nueva verificación.

## Error de tipado SwiftUI `PlanView.swift` resuelto en código
- Logs reales Xcode 27: `setWODFormat` era una función `Void` decorada erróneamente con `@ViewBuilder`, mientras que `wodBlock(index:) -> some View` construía múltiples vistas sin ese atributo. Se ha movido `@ViewBuilder` a `wodBlock`. 
- Pendiente nueva compilación de iOS/watchOS después de este cambio; no se declara verde hasta comprobar resultados.

## PENDIENTE
- Completar integración Auth extremo a extremo en navegador (confirmación de correo, dominios redirect, correo SMTP, refresh de sesión real, recuperación y logout en dispositivos).
- Invitaciones, membresía administrada transaccionalmente y consentimientos.
- Asignaciones deportivas compartidas / versiones; reservas / aforo y créditos; Stripe.
- Web profesional real, Android, deep links, push, observabilidad, e2e.
- Agenda y reservas iOS codificadas para Supabase, pero **sin build ni prueba E2E**; siguen pendientes su validación, contratos comerciales pagados, emisiones automáticas tras pago, clases recurrentes y reglas configurables de cancelación.
- CI específico de migraciones y pruebas RLS sobre una base limpia, comprobación por usuarios reales.
- CI iOS heredado activado en PR #5: se observan fallos en varios checks del workflow; el conector no ha proporcionado pasos ni logs suficientes para atribuirlos al código o al entorno. No declarar CI superado.
- Código fuente del prototipo Business v0.2 presente en `web/console/` y contratos Swift/Kotlin. El usuario informa 37 pruebas JS/2 Swift/3 Kotlin anteriores; los tests agregados después requieren nueva ejecución completa.
- Validación manual iOS 27 (requiere Xcode/SDK), rendimiento y seguridad ofensiva.

## BLOQUEADO / requiere coordinación
- El ZIP original de v0.2 de otra conversación no es accesible aquí; **su contenido fuente relevante sí está incorporado a esta rama**. Las diferencias exactas con aquel ZIP no pueden verificarse sin volver a adjuntarlo.
- La configuración final de precios B2B, fiscalidad y productos Stripe no está aprobada.
- No se ha publicado panel web ni se han modificado datos iCloud.

## Git
Rama `feat/repera-business-platform`, derivada de `main` en `0f369a65669ef2a9b408eea9477194de7ffb6924`. No fusionar a `main` antes de revisar CI/seguridad. El proyecto Cafesito no se ha tocado.
