# Repera Business — entorno de desarrollo local v0.2

Última actualización: 2026-10-20.

**Estado real:** plataforma en construcción. El lanzador abre por defecto `/console/`, el panel con login de **Supabase Repera** y operaciones reales autorizadas de empresas, clientes, clases y planificación; todavía falta validación E2E con iOS, permisos y reservas. Los pagos y la facturación real no están habilitados. `?demo=1` es un **prototipo offline** separado con nombres, ingresos y reservas ficticios; no introduzcas allí datos personales reales.

## Lanzadores macOS de doble clic (rama de desarrollo)

Hay tres archivos ejecutables (`100755`) en la **raíz del repositorio**:

- **`Repera-Business.command`**: doble clic en Finder → levanta un servidor en `127.0.0.1`, puerto libre, y abre automáticamente `/console/` (login real de Supabase). Para iniciar la demo usa `./Repera-Business.command --demo` desde Terminal o el enlace «Abrir demostración local» en el login. Solo sirve `web/` por loopback. Necesita Python 3 y mantener abierta la ventana Terminal.
- **`Repera-Verificar.command`**: ejecuta pruebas de consola, paquetes Swift y, en macOS equipado, compilaciones iOS/watchOS; genera logs y un resumen sin publicar, fusionar ni modificar la base de datos.
- **`Repera-iOS.command`**: doble clic → comprueba Xcode/iOS 27/XcodeGen/Python 3, genera el proyecto con XcodeGen, compila el target **Repera** e intenta instalarlo y abrirlo en un simulador de iPhone con iOS 27. Necesita el SDK y un simulador instalados. **No equivale a un binario macOS nativo**; la app es iOS y se abre dentro de Simulator.

Si Finder impide abrir un script procedente de Internet, usa el diálogo de apertura de macOS para scripts de confianza. En una copia Git que no preserve el bit ejecutable: `chmod +x Repera-Business.command Repera-iOS.command Repera-Verificar.command`.

**Modo conectado** (predeterminado, solo para profesionales): la URL abierta es `http://127.0.0.1:<puerto>/console/`, sin `?demo=1`. Las operaciones permitidas modifican datos reales según Supabase Auth y RLS; no confundas este modo con la demo. Para confirmar el correo o recuperar la contraseña, configura en Supabase Auth las URL de redirección de loopback y el puerto utilizado, según corresponda.

**No hay todavía binario de producto terminado** ni firma/distribución TestFlight validada; los scripts facilitan pruebas locales. No fusionar `main` mientras CI iOS y seguridad E2E no estén validados.

## Alta real de entrenador o gimnasio (octubre de 2026)

En `/console/` la creación del negocio pide nombre comercial y genera un identificador único a partir de ese nombre. No hay una categoría de «centro»: los nuevos negocios eligen **entrenador personal** o **gimnasio** (el tipo anterior se mantiene internamente solo por compatibilidad). Se recogen datos comerciales, de contacto, fiscales y de representante, dirección postal, país ISO, y se puede subir foto de entrenador o logo. La foto se convierte en JPEG, se limita a 1 MB y es **pública** para mostrarse también en el directorio. Los datos fiscales se almacenan en una tabla separada con RLS para propietarios/administradores, no dentro de la ficha pública.

El panel de **Administración Repera** permite modificar o crear planes de cada categoría (nombre, precio mensual sin IVA, límite de clientes, descuento de lanzamiento, visibilidad y orden). Los formularios de alta y suscripción leen el catálogo real de Supabase. Un plan elegido genera un interés de compra, no un cobro ni una suscripción activa. Requiere aplicar el SQL versionado `business_org_identity_plans` con Supabase Repera y validar sesión real en navegador. Hasta entonces, una columna o RPC ausente dará error: nunca reemplazarla por datos demo.

## Arranque web en 20 segundos

```bash
cd web
python3 -m http.server 8080
```

Abre `http://localhost:8080/console/` para el acceso autenticado real a Supabase; el modo demo es `http://localhost:8080/console/?demo=1`. La demo no necesita Node, Postgres ni Docker, conserva datos ficticios en `localStorage` y permite restablecerlos en **Configuración → Restablecer datos de ejemplo**. El modo conectado necesita conexión a internet y una cuenta autorizada en Repera; no uses la demo para datos personales reales.

## Recorrido de prueba sugerido (solo demo offline)

1. Selecciona **Gimnasio** o **Entrenador** desde la cabecera; el selector es una demo, no autentica.
2. **Clientes:** crea una ficha, abre el detalle, edita sus datos y comprueba planes y bonos.
3. **Grupos:** crea grupo, elige alumnos y asigna una plantilla con fecha de inicio. Repite la asignación para ver que no se duplica.
4. **Planificación:** crea plantilla con cualquiera de los 7 días y asígnala a uno o varios deportistas. En su ficha puedes ajustar un día individual, sin cambiar el programa de sus compañeros.
5. **Agenda de deportistas:** consulta qué entrenamientos y clases tendría cada atleta en Hoy/Diario de su móvil.
6. **Clases y reservas:** crea clases únicas o semanales recurrentes. El sistema comprueba colisiones por sala y entrenador, aforo y validez del bono.
7. **Operaciones:** registra asistencias, faltas y cancela una clase. Comprueba el reintegro de créditos.
8. **Tarifas y bonos:** crea productos, simula un cobro confirmado o pendiente, y reserva una plaza. Un pendiente no activa el derecho.
9. **Cobros y facturas:** usa «Confirmar demo» en un pago pendiente, crea borrador sin validez fiscal y exporta el CSV.
10. **Notificaciones:** ve los avisos de planes y cancelaciones en la bandeja local. No se envían push reales.
11. **Equipo y espacios:** añade profesionales pendientes de invitación y espacios físicos.
12. **Administrador:** consulta datos agregados y usa «Ver como» en modo demostración, sin suplantar sesiones reales.

## Pruebas automatizadas

```bash
cd web/console
node --test tests/*.test.mjs
# 37 pruebas a fecha 19/10/2026 — NODE 20+

cd ../../mobile-contracts/swift
swift test
# 2 XCTest validados con Swift 6.2.1

cd ../android
kotlinc src/main/kotlin/dev/repera/contracts/BusinessAgenda.kt \
        src/test/kotlin/dev/repera/contracts/BusinessAgendaSmoke.kt \
        -include-runtime -d /tmp/repera-contracts.jar
java -jar /tmp/repera-contracts.jar
# 3 comprobaciones Kotlin validadas con JDK
```

**Limitación del entorno donde se creó:** Chromium/Playwright no pudo abrir localhost (`ERR_BLOCKED_BY_ADMINISTRATOR`); los tests Node, XCTest y compilación Kotlin sí se ejecutaron. Falta prueba visual navegador real y E2E integrada.

## Organización de archivos

```text
web/console/
    index.html, src/styles.css
    src/main.js, src/ui/{app,pages,extra-pages,components}.js
    src/core/{domain,operations,backend,mobile-contract,seed,store}.js
    tests/{domain,operations,backend,mobile-contract,sql-contract,ui-smoke,app-init}.test.mjs
supabase/repera-greenfield/
    0001_business_foundation.sql
    0002_booking_transactions.sql
mobile-contracts/
    swift/Package.swift + Sources + XCTest
    android/src/main/kotlin/... + smoke tests
docs/
    PLATAFORMA_REPERA_PLAN_MAESTRO.md
    INTEGRACION_Y_ESTADO.md
```

## Supabase y Cafesito

- **Cafesito no se ha tocado** y los scripts jamás deben ejecutarse ahí.
- SQL preparado para un proyecto Repera completamente nuevo, sin compartir API keys, Auth, RLS o usuarios con Cafesito.
- Migración `0001` del repositorio GitHub original **NO** debe ejecutarse junto con este esquema. Aquella migración antigua concede lecturas generales a entrenadores y necesita sustitución antes de iniciar la sincronización.
- Las migraciones históricas del prototipo greenfield no son equivalentes al esquema productivo. La migración `business_org_identity_plans` sí está aplicada en Supabase Repera, pero aún se necesitan pruebas E2E de RLS y carga de imágenes con usuarios reales.
- `src/core/auth.js` conecta la ruta `/console/` con Supabase Repera mediante sesión autenticada y RLS; `src/core/backend.js` define otro contrato de transporte. Ambos son distintos de la demo y no implican validación E2E.

## IONOS y GitHub

Para integrar sin sustituir la landing de `repera.app`, copia `web/console` en la carpeta `web/` del repositorio `rmoya87/repera`. La ruta final planificada es `/console/`. El despliegue actual de `web/pack-ionos.sh` NO incluye `/console/`: modificar y validar el despliegue antes de publicar; revisar también los fallback de SPA, CSP, HTTPS y caché. Este código se incorpora a la rama `feat/repera-business-platform` en GitHub; no implica despliegue en IONOS ni conexión real a Supabase.

## Qué sigue faltando

Login Supabase y Apple verificados, alta y aceptación de invitaciones, backend transaccional probado en base real, Stripe Connect/Billing, cumplimiento fiscal y facturas legales, envío real APNs/FCM, cliente iOS conectado a la capa Business, aplicación Android de usuario final, controles de acceso físico y check-in, distintas sedes/comercio avanzado, contrato de consentimientos, sincronización local-first entre dispositivos, soporte técnico delegado seguro, tareas en segundo plano y observabilidad. El precio que **Repera** cobrará a profesionales sigue pendiente.

Consulta [el estado y pasos exactos](INTEGRACION_Y_ESTADO.md) y [el plan maestro](PLATAFORMA_REPERA_PLAN_MAESTRO.md).
