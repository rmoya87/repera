# Estado de desarrollo — Repera Business
Última actualización: 2026-10-19.

## IMPLEMENTADO (verificado en Supabase Repera)
- Proyecto `uvzgujlrqohreoucirms` conectado y sano; PostgreSQL 17.
- Primera migración real: `20261019190623_business_foundation_secure` (registro en `supabase_migrations.schema_migrations`).
- Tablas públicas: profiles, organizations, organization_memberships, exercises, routines, routine_exercises, workouts, workout_sets, clients y staff_client_assignments. RLS activado en las **diez**.
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
- Barra nativa iOS: `Inicio · Diario · Center · Progreso · Ejercicios`; el hub «Crear» sigue accesible desde + de Inicio.
- Diario abre en vista Entrenador (sin agenda remota simulada); planificación personal y rutinas quedan en pestañas secundarias del mismo Diario.
- Center es una pantalla nativa con selector **Clases / Citas**, estados vacíos reales por modalidad y acceso a Ajustes; no muestra horarios ni permite reservar todavía.
- Ajustes separa «Mis centros y entrenadores» y «Servicios contratados», ambos con estado Sin sincronizar; Repera Pro se mantiene independiente.
- Contrato móvil de agenda ampliado con `appointment` y `repera://appointments/{id}` en Swift y Kotlin, con pruebas de contrato añadidas: Kotlin JVM 6 comprobaciones ejecutadas correctamente; sintaxis Swift del contrato verificada con swiftc -parse. La suite XCTest completa agotó el tiempo del entorno y permanece sin validar.
- Pendiente: conectar Sign in with Apple con Supabase Auth y construir APIs de invitación/programación/clases/contratos, incorporarlas a Inicio/Diario/Center y mostrar saldos reales.
- Compilación Xcode iOS 27, UI tests y TestFlight: **no ejecutadas desde el conector**; no marcar como probado.

## PROBADO
- `list_tables`: 10 tablas RLS=true (dos migraciones de Repera, sin datos reales de cliente).
- `list_migrations`: baseline `20261019190623` y migración de clientes `20261019193414` registradas.
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
- **No merge a main**: servicios clave incompletos (Apple→Supabase, invitaciones, planes profesionales, reservas, citas, contratos/bonos, cobros) y 4 jobs de CI fallidos en el último commit comprobado.

## PENDIENTE
- Completar integración Auth extremo a extremo en navegador (confirmación de correo, dominios redirect, correo SMTP, refresh de sesión real, recuperación y logout en dispositivos).
- Invitaciones, membresía administrada transaccionalmente y consentimientos.
- Asignaciones deportivas compartidas / versiones; reservas / aforo y créditos; Stripe.
- Web profesional real, Android, deep links, push, observabilidad, e2e.
- Agenda y reservas grupales o citas 1:1 reales del deportista en Inicio/Center, contratos/sesiones/caducidades reales en Ajustes: todavía NO integrados.
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
