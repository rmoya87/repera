# Repera

## Repera Business — fichas por pestañas, planes e invitaciones (27/10/2026)

**Administración · Atletas** abre directamente con avatar, nombre y email, sin encabezado duplicado ni Volver. Pestañas: **Ejercicios** (calendario a la izquierda, sesión a la derecha, botón de añadir sesión o plan), **Datos** (identidad, roles, centros y preferencias), **Acceso** (último login y métodos, sin credenciales) y **Reservas** (reservas y sesiones profesionales). Máximas y e1RM derivadas solo de series realizadas; el mapa corporal representa frecuencia **orientativa** de grupos trabajados, no composición corporal. La puntuación Amateur/Medio/Avanzado mide completitud y variedad de registro, sin acreditar profesionalidad o salud. Para planificar, el atleta debe haber aceptado una vinculación con un centro; se abre entonces el editor profesional nativo en contexto delegado.

**Centros** utiliza filas enteras pulsables y pestañas **Datos, Equipo, Clientes, Facturación**. Datos distingue `status` (operativo) de `registration_status` (propietario pendiente). El administrador puede cambiar visibilidad de búsquedas de la app mediante RPC, sin reclamar la propiedad por el titular; se impide publicar centros suspendidos. También puede solicitar un reenvío de instrucciones al propietario.

**Panel profesional** retira la cabecera superior en modo delegado y sitúa el avatar del negocio y Ajustes, Volver a Administración y Cerrar sesión al pie del menú lateral. **Clientes** se gestiona con un listado y una ficha por pestañas (Entrenamientos, Datos básicos, Reservas). Solo recibe resultados de entrenamientos compartidos explícitamente por el atleta con ese centro y autorizados por Supabase.

La aceptación de invitaciones usa correo verificado y es siempre voluntaria. Hay endpoint transaccional `repera-business-invite` desplegado en Supabase (JWT válido, permisos y rate limiting); **la entrega no queda habilitada sin RESEND_API_KEY, REPERA_INVITE_FROM y REPERA_PUBLIC_URL** en los secretos de la función. Links iOS/Android solo si sus URLs reales están configuradas. El panel muestra «invitación guardada, correo no confirmado» en vez de afirmar envíos falsos. Migraciones `20261027184500`, `20261027185000` y `20261027185500` aplicadas. Quedan pendientes la prueba E2E con varias cuentas y la entrega real de emails.


## Repera Business: actividad por calendario y operativa de entrenador — 27/10/2026

La administración web muestra cada Atleta con fila pulsable, buscador limpio, calendario de días entrenados y fichas maquetadas con las imágenes exactas de ejercicios del catálogo Repera, bloques y series/resultados útiles. Su acceso se controla por rol administrador y se registra. En centros, `status` operativo y `registration_status` de alta se muestran por separado.

Las solicitudes de vinculación enviadas por iOS pueden llegar al centro: portada con bandeja, Aceptar/Rechazar y refresco manual, sin enlazar un atleta hasta que el responsable lo autorice. Entrenamientos incluye publicación individual y masiva de plantillas a varios deportistas y fechas, con vista previa, validación de límites y prevención de duplicados. La vista delegada de soporte sigue usando el JWT real del administrador, sin suplantar al propietario.

Migraciones `20261027181000_enrollments_and_operating_status.sql` y `20261027182000_athlete_activity_bulk_training.sql` aplicadas en Supabase Repera. CI y prueba E2E de roles distintos requieren verificación; una fusión a main no equivale a desplegar IONOS.


## Administración global renovada (27/10/2026)

El favicon de la consola Business es el mismo PNG binario del icono nativo de iOS, copiado en web/assets/repera-app-icon.png. El menú lateral comienza directamente con las secciones y se pliega a iconos, con preferencia local. El acceso a Auditoría se ha retirado de la navegación, aunque los eventos siguen guardándose en Supabase.

Las fichas de centros muestran cuatro indicadores por fila, datos legales y operativos, equipo, atletas asociados, actividades, cobros y un selector manual de estado. El botón de acceso al centro inicia la delegación temporal auditada de Repera Admin (30 minutos) sin formulario de motivo y sin usar credenciales de propietarios.

Las fichas de atletas incluyen relaciones con centros, entrenamientos paginados y estructurados, últimas reservas/sesiones, programas y accesos básicos (último login y proveedor); las lecturas quedan auditadas. No se exponen claves, sesiones privadas, contraseñas o HealthKit médico. Los cinco filtros de Pagos comparten una fila.

Configuración permite definir contactos y duración real de la prueba gratuita (1–60 días, aplicada en nuevas altas y reclamaciones). Siguen pendientes las integraciones Stripe, correo transaccional, fiscalidad y operaciones de privacidad/monitorización. Migraciones 20261027170000 y 20261027173000 aplicadas en Supabase. El cambio en GitHub no equivale a despliegue en IONOS.


## Centros pendientes y acceso delegado (27/10/2026)

El administrador global ya visualiza **centros pendientes** en «Centros», con estado, búsqueda y ficha editable. En cada alta se provisiona un espacio de trabajo real y privado inmediatamente, sin inscribir al administrador como propietario ni activar públicamente el centro. El propietario legítimo, después de confirmar su email, reclama ese **mismo** centro y recibe el rol `owner` sin duplicarlo. El ejemplo previo «Alicia» se ha convertido desde la solicitud existente en un espacio pendiente, conservando su estado.

Desde la ficha es posible suspender/reactivar el centro con motivo y usar acceso delegado temporal (30 minutos, auditable) incluso sin propietario registrado. Es **administración en contexto del negocio**, no suplantación de una cuenta ajena ni falsificación de tokens de usuario. El panel no muestra la franja superior; Pagos utiliza cuatro indicadores por fila en escritorio; fotos y avatares son circulares. Los cambios están en `web/console/src/ui/platform-admin.js` y `src/platform-admin-polish.css`. Migraciones `20261027153000` y `20261027154500` aplicadas a Supabase.


## Repera Business — Centros, Atletas y cuenta de administración (27/10/2026)

La consola `web/console/` presenta «Centros» como directorio común de gimnasios y entrenadores, con tipo visible e imagen. «Atletas» consulta un directorio global de cuentas verificadas o pendientes, incluidas personas sin centro asociado, a través de un RPC de plataforma protegido; solo se muestran datos de cuenta, vinculación y avatar público, no registros deportivos privados. El icono/nombre del administrador se encuentra en el pie del menú lateral y abre el perfil (nombre, imagen, correo sujeto a confirmación y contraseña).

Los planes se muestran como un catálogo agrupado y solo se despliega el formulario que se edita. Configuración de plataforma ahora permite guardar contactos de soporte, facturación y enlaces legales mediante RPCs. Las altas preparadas de centros admiten fotografía optimizada y guardada en Storage `business-branding` dentro de una carpeta con acceso limitado al administrador solicitante; cuando el propietario reclama el centro, la foto se conserva.

Migraciones aplicadas en Repera: `20261027143000_business_admin_directory_settings.sql` a `20261027143004_fix_athlete_role_text.sql`. No implican cobros Stripe reales ni despliegue IONOS. Las pruebas automatizadas en navegador siguen pendientes.


## Consola Business siempre conectada (27/10/2026)

Se ha eliminado el selector de demo offline del lanzador `Repera-Business.command`, la ruta de demostración del frontend y su enlace. El inicio autenticado consulta primero el rol de plataforma. La migración `20261027140000_fix_platform_membership_rls.sql` corrige un error RLS de delegaciones que impedía mostrar el panel global aun con una cuenta `platform_admin` válida. La migración está aplicada a Supabase Repera; es necesario actualizar el checkout local desde `origin/main` para ver el frontend nuevo.


**Pagos**: también existe `business_client_payments` para futuros cobros B2C, separado del ledger B2B y sin webhook configurado; consultar `20261027131000_platform_client_payment_ledger.sql`.

## Repera Business: administrador global (2026-10-27)

La consola Business autenticada incorpora un panel independiente de plataforma (gimnasios, entrenadores, clientes agregados, fichas y configuraciones públicas, alta diferida de negocios, auditoría, pagos B2B y acceso delegado temporal de 30 minutos). El frontend está en `web/console/src/ui/platform-admin.js`; el backend se rige por `supabase/migrations/20261027120000_platform_admin_console.sql`. La delegación no comparte credenciales ni tokens con el propietario y conserva restricciones sobre datos privados.

**Sin integración de pagos real:** las solicitudes de plan no equivalen a cobros, y las tablas de pagos no reciben transacciones hasta configurar webhooks verificados de Stripe Billing y Connect. El sistema web conectado y la base de datos no implican por sí solos que la consola esté desplegada en IONOS. Detalles: `docs/business/ESTADO_DESARROLLO.md`, `docs/business/SEGURIDAD.md` y `docs/business/BASE_DATOS.md`.


App nativa de entrenamiento (**iPhone + Apple Watch**), **local-first + iCloud**, acceso con Apple o Google (SDK oficial iOS + sesión Supabase), UI **SwiftUI Liquid Glass** (iOS 26+ / watchOS 26+; Android API 30+).

Última actualización: 2026-10-26 (sesiones múltiples por día, Comenzar con más deportes HealthKit, eliminación de series por swipe y estado de copia Supabase; Android/Wear sigue en su rama).

El acceso Google usa el SDK oficial `GoogleSignIn` 10.1.0. Su botón tiene presentación SwiftUI adaptada al de Apple: contenido centrado, sin sombra y esquinas redondeadas; la autenticación sigue siendo del SDK. Los identificadores públicos del cliente OAuth **iOS** de `com.app.repera`, su esquema de retorno y el cliente Web del backend están configurados en `Configs/GoogleSignIn.xcconfig`. Regenerar XcodeGen antes de compilar. Configuración y validación pendiente en [docs/GOOGLE_AUTH_IOS.md](docs/GOOGLE_AUTH_IOS.md).

Android / Wear OS (en desarrollo)

Proyecto nativo independiente en [android/](android/) con Kotlin, Material 3,
login de Google y Google Drive appDataFolder. **No equivale aún a las apps Apple
ni está autorizado para producción**. Véanse
[estado de paridad](android/docs/STATUS_AND_PARITY.md) e
[identidad/sincronización](android/docs/GOOGLE_IDENTITY_DRIVE.md).

## Documentación

| Documento | Contenido |
|-----------|-----------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Capas, targets, paquetes, datos |
| [docs/GPS_TRACKING.md](docs/GPS_TRACKING.md) | GPS único de Comenzar/Play, HealthKit, rutas, bloqueo, límites de iOS y pruebas |
| [docs/ROUTE_PACE_COLORS.md](docs/ROUTE_PACE_COLORS.md) | Escala visual de velocidades relativas, paridad iOS/Android y límites de reloj |
| [docs/REMOTE_EXERCISE_CATALOG.md](docs/REMOTE_EXERCISE_CATALOG.md) | Catálogo Supabase incremental, caché offline, BGAppRefresh nativo iOS 27 y despliegue |
| [docs/FEATURES.md](docs/FEATURES.md) | Funcionalidad por pestaña / flujo |
| [docs/MOVILITY_CATALOG.md](docs/MOVILITY_CATALOG.md) | Los 82 ejercicios de movilidad, por región y alias inglés |
| [docs/PERFORMANCE.md](docs/PERFORMANCE.md) | Observation, caches, Home/HK, thumbs |
| [docs/BOARD_SCAN.md](docs/BOARD_SCAN.md) | Escáner de pizarra (OCR + IA + parser) |
| [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md) | Checklist manual por feature |
| [docs/MONETIZATION.md](docs/MONETIZATION.md) | Freemium, RevenueCat, límites Gratis/Pro |
| [web/](web/) | Sitio estático (producto, precios, privacidad, términos, FAQ) |
| [docs/MAINTENANCE.md](docs/MAINTENANCE.md) | Cómo mantener docs al día |
| [docs/MCP_PLAN.md](docs/MCP_PLAN.md) | MCP Repera: estado real, migraciones, privacidad, fases y seguridad |
| [docs/ios27-modernization/](docs/ios27-modernization/) | Canvas modernización iOS 27 |
| [docs/decisions/](docs/decisions/) | ADRs (persistencia, timers, nav, HK, arte) |
| [AGENTS.md](AGENTS.md) | Instrucciones para agentes Cursor |
| [docs/business/PLAN_MAESTRO.md](docs/business/PLAN_MAESTRO.md) | Plataforma profesional, seguridad, fases y seguimiento |

> **Obligatorio:** cualquier cambio de comportamiento debe actualizar estos docs (ver `MAINTENANCE.md` y la regla Cursor `update-docs-on-change`).

## Estado actual (oct 2026)

| Área | Incluye |
|------|---------|
| **Inicio** | Semana/día, métricas Salud, varias sesiones terminadas y programadas independientes por fecha, avatar→Ajustes, planificar / pizarra |
| **Diario** | Planificación personal de varias rutinas por fecha (cada una editable/borrable por separado) y sesiones profesionales de Supabase; ejecución profesional estructurada pendiente |
| **Center** | Selector Clases/Citas con lectura de horarios reales, reservas y cancelaciones mediante Supabase cuando haya sesión y bono disponible; E2E pendiente |
| **Crear desde Inicio** | Botón +: entreno libre, **Apuntar series**, favoritos, timer, foto pizarra/TV (sin pestaña propia); al elegir un favorito desde el calendario se programa una copia para ese día |
| **Progreso** | Gratis: últimos 7 días + teaser; Pro: periodos, deltas, cardio/kcal/peso, heatmap, equilibrio |
| **Ejercicios** | Biblioteca + ficha, filtro Movilidad con 82 movimientos bilingües ES/EN; evolución completa = Pro (Gratis: última sesión + PR) |
| **Sesión** | Series editables sin check por serie, borrado por swipe, WOD/temporizadores, RIR/RPE, menú ⋯ y Live Activity |
| **Favoritos de entrenos** | Guardar como favorita una planificación crea una plantilla independiente reutilizable desde Crear → Favoritos; al borrar el día se conserva el favorito. Desde la vista previa, editor y Play se comprueba el guardado y el límite de Gratis. Pruebas en dispositivo y con iCloud **pendientes** | 
| **Comenzar (iOS)** | Cuenta atrás 3/2/1 con tono medio de 523,25 Hz (0,16 s), mismo tono sostenido de 0,49 s al llegar a cero y finalizar, pausa/reanudación silenciosas, voz de parciales/giros configurable y mapa 2D/3D persistente. **Pendiente:** audio y UI verificados en iPhone real/TestFlight; [checklist](docs/GPS_TRACKING.md) |
| **Pizarra** | OCR lite; Gratis 4 escaneos/mes; Pro ilimitados |
| **Onboarding** | Apple o Google con identidad Supabase verificada → permisos → Gratis/Pro |
| **Ajustes** | Cuenta Apple/Google, estado/reintento manual de la copia de entrenos en Supabase, Pro/iCloud, Salud, peso, export/import |
| **Datos** | JSON local + iCloud Documents; CSV Strong/Hevy (sin entitlement en el JSON) |
| **Watch** | Confirmar → conteo → **+1 serie** / log rápido (sin límites Pro en v1) |
| **Monetización** | StoreKit + RevenueCat; ver [docs/MONETIZATION.md](docs/MONETIZATION.md) |

## Arranque rápido en Mac (doble clic)

- [`Repera-Business.command`](Repera-Business.command): abre por defecto el **panel profesional conectado a Supabase**, con login real y datos autorizados por RLS; requiere Python 3 y mantiene abierta una ventana Terminal. Para la demo aislada con datos ficticios, ejecuta `./Repera-Business.command --demo` o abre `/console/?demo=1`. El modo conectado todavía requiere validación E2E antes de usarse en producción.
- [`Repera-Xcode.command`](Repera-Xcode.command): **regenera el proyecto, valida sus fuentes y resuelve los paquetes Swift antes de abrir Xcode**, incluido `GoogleSignIn`. Si la resolución falla, muestra el error y no abre el proyecto a medias. Úsalo al actualizar el repositorio.
- [`Repera-iOS.command`](Repera-iOS.command): intenta compilar y lanzar la app en Simulator; regenera y valida el proyecto antes de compilar; requiere macOS, Xcode con iOS 27, XcodeGen y un simulador compatible.
- Ambos lanzadores están en la raíz del repositorio; si clonas por Git, se conserva el permiso de ejecución. No se ha generado todavía una aplicación macOS firmada ni un paquete iOS listo para distribución.

**Estado:** la identidad Apple y el flujo profesional conectado con Supabase ya están en `main`. Aún requieren validación con cuentas y dispositivos reales; consulta los checks de GitHub Actions del commit actual antes de publicar en TestFlight.

## Repera Business · alta de negocios y tarifas administrables

El panel `/console/` usa Supabase Repera con sesión real. Para dar de alta un negocio se escoge **Entrenador personal** o **Gimnasio**: el identificador público se genera a partir del nombre comercial; no se introduce manualmente. El alta permite correo/teléfono, web, dirección y descripción, además de nombre/razón social, NIF/NIE/CIF, representante, persona de contacto, correo/domicilio de facturación y localidad. El **logotipo del gimnasio** o la **foto del entrenador** se sube como JPG/PNG/WebP al bucket público `business-branding` con permisos del propietario/administrador; su URL se vincula al perfil utilizado también por la búsqueda de Repera iOS. La información fiscal vive en `organization_legal_profiles` y **no es visible para atletas**.

Los planes aparecen desde `business_plans`, configurables por el **administrador verificado de Repera** (precios, cupos, promociones y visibilidad) y separados por entrenador/gimnasio. Seleccionarlos solo crea una solicitud pendiente, nunca cobra ni da acceso de pago. Requiere la migración `business_org_identity_plans` del proyecto Repera y pruebas E2E antes de producción. Más detalles: [entorno local](docs/business/README_LOCAL.md).

## Solución: Xcode no encuentra `AITrainingInboxStore`, `AIAccessView` o los almacenes Supabase

El proyecto Xcode (`Repera.xcodeproj`) **se genera localmente** y no se versiona. Puede quedarse con la lista de fuentes anterior a la integración de Supabase, aunque los archivos Swift existan en disco. Por tanto, errores como `Cannot find 'AITrainingInboxStore' in scope` (desde `ReperaApp.swift`), `Cannot find 'AIAccessView' in scope` (desde Ajustes), `Cannot find 'BusinessAuthStore' in scope` o `Cannot find 'BusinessWorkoutSyncStore' in scope` o `Cannot find 'AIChangeRequestStore' in scope` suelen requerir regenerar el proyecto, **no duplicar la clase ni eliminar la limpieza de la sesión Supabase**. El validador comprueba también que el archivo esté en *Compile Sources*, no solo en el navegador de Xcode.

**Errores SwiftUI en `ReperaApp.swift` (líneas de `.environment` o `.overlay` sobre `Scene`):** la raíz del `WindowGroup` ahora utiliza una propiedad `@ViewBuilder launchRootView` explícitamente tipada como `some View`. Para recibir este arreglo, descarga la última versión de `main`; regenerar XcodeGen **sin actualizar el código** no corrige ese error. En cambio, si el error es `AIChangeRequestStore` fuera de ámbito, el archivo ya existe en `Apps/Repera/Sources`: regenera `Repera.xcodeproj` para incluirlo en *Compile Sources*. El mensaje de Xcode **“Update to recommended settings”** es informativo y no sustituye ninguno de estos pasos; la configuración autoritativa está en `project.yml`.

Cierra Xcode y haz doble clic en [`Repera-Xcode.command`](Repera-Xcode.command). **Este lanzador ahora comprueba `origin/main` y hace solo un fast-forward cuando trabajas en `main` y no hay cambios sin confirmar**; después ejecuta XcodeGen, comprueba que los almacenes Apple/Supabase y los dos nuevos archivos IA están realmente en *Compile Sources* y abre el proyecto regenerado. [`Repera-iOS.command`](Repera-iOS.command) usa la misma reparación antes de lanzar Simulator.

Si la carpeta local tiene cambios sin confirmar, otra rama o no hay conexión, el lanzador **no sobrescribe, descarta ni fusiona nada**: avisa y utiliza el código disponible. Si faltan `AITrainingInboxStore.swift`, `AIAccessView.swift`, `BusinessWorkoutSyncStore.swift` o `AIChangeRequestStore.swift`, guarda tus cambios y actualiza `main`; regenerar un proyecto no puede inventar un archivo Swift ausente. Alternativa:

```bash
cd /Users/ramon/Proyectos/repera
git pull origin main
xcodegen generate --spec project.yml
python3 scripts/check_xcode_sources.py
open Repera.xcodeproj
```

Si falta alguno de los archivos de autenticación o IA en la copia local, la herramienta avisa de que hay que actualizar Git. Si ya existen, **no los dupliques ni borres la clase**: cierra Xcode y regenera el proyecto con XcodeGen, porque `Repera.xcodeproj` está excluido de Git. Si tienes cambios locales sin confirmar, haz una copia o confírmalos antes de ejecutar el `git pull` manual. La generación **no borra datos de entrenamientos**, simuladores ni DerivedData, y conserva la versión del proyecto según `Configs/Version.xcconfig`.

## Arranque

```bash
xcodegen generate
open Repera.xcodeproj
# Tests dominio
cd Packages/ReperaDomain && swift test
# Web marketing (local)
cd web && python3 -m http.server 8080
```

Sitio público: [repera.app](https://repera.app) — `cd web && ./pack-ionos.sh` y extraer el zip en IONOS `htdocs`; ver [web/README.md](web/README.md).

Requisitos: **Xcode con SDK iOS 26+** (mínimo despliegue 26), dispositivo/simulador compatible. Android **API 30+**. Apple Intelligence es opcional (fallback local en pizarra).

Cold start: Splash nativo y pantalla de espera usan la misma UIImageView UIKit en modo AspectFit y fijada a los cuatro bordes; evita saltos de escala, y una build nueva invalida la captura antigua de iOS. Store en shell vacío hasta hidratar disco; `Catalog.prewarm()` fuera del MainActor. En Debug+Simulador el dylib (~20 MB) puede retrasar el process start; medir en Release/dispositivo.

## Versiones de Xcode (una sola fuente de verdad)

La **versión comercial** (`MARKETING_VERSION`, por ejemplo `1.2.0`) y la **compilación** (`CURRENT_PROJECT_VERSION`, por ejemplo `42`) proceden de [`Configs/Version.xcconfig`](Configs/Version.xcconfig). Se aplican automáticamente a **Repera iPhone, ReperaWatch y ReperaRestWidget** y a sus respectivos `Info.plist` mediante sustitución de variables de Xcode.

**Desde Xcode (recomendado):** abre `Configs/Version.xcconfig` en el navegador del proyecto y cambia `REPERA_MARKETING_VERSION` y `REPERA_BUILD_NUMBER`. Los tres targets toman los valores en la siguiente compilación, sin editar archivos individuales. También puedes introducirlos en **PROJECT Repera → Build Settings** para Debug y Release; al compilar con el scheme `Repera`, una preacción guarda esos valores de nuevo en `Version.xcconfig`. Para evitar que Watch o el widget difieran en la primera compilación, edita la versión **del proyecto** o el archivo compartido, no solamente **TARGET Repera → General**.

El script [`scripts/sync_versions.py`](scripts/sync_versions.py) se ejecuta automáticamente **antes de regenerar con XcodeGen**, recuperando los valores del proyecto Xcode existente para no perder los cambios hechos en la interfaz. `Repera.xcodeproj` sigue sin versionarse: los dos valores persistentes viven en `Version.xcconfig`. Si se editó únicamente la versión del target iPhone en `General`, regenera con `xcodegen generate` antes de archivar, para volver a unificar los tres targets.

```bash
xcodegen generate                   # preserva versiones de Xcode si ya existía el proyecto
python3 scripts/sync_versions.py --check
python3 scripts/sync_versions.py --set 1.2.0 42  # alternativa por terminal
python3 -m unittest discover -s tests -p 'test_sync_versions.py'
```

**Importante:** cambiar una versión no incrementa automáticamente el número de compilación. Para cada envío a TestFlight/App Store, pon un build mayor que el anterior; la publicación en App Store Connect sigue siendo manual.

## Identificadores

| Qué | Valor |
|-----|--------|
| Bundle iOS | `com.app.repera` |
| iCloud | `iCloud.com.app.repera` |
| Team | ver `project.yml` |
| RevenueCat API key | `RevenueCatPublicAPIKey` en Info.plist (pública `appl_…`) |
| Productos | `com.app.repera.premium.monthly` / `com.app.repera.premium.yearly` · entitlement `pro` |

## No integrados aún en las apps

- Android nativo: planificado, no implementado.
- Backend Supabase de Repera: **migraciones de negocio aplicadas en Supabase Repera y tablas públicas protegidas por RLS**, con operaciones pendientes de validación E2E. Panel profesional conectado a invitaciones, horarios, bonos de cortesía y entrenamientos fechados. iOS incluye puente Apple→Supabase y lectura de Center/Diario/Inicio/Ajustes, **pendiente compilar y validar con proveedor Apple y cuentas reales**. No hay Stripe, facturación legal ni bonos de pago; la elección de planes no cobra ni activa prestaciones. Ver [estado real](docs/business/ESTADO_DESARROLLO.md) y [criterios y accesos necesarios para cerrar la entrega](docs/business/RELEASE_GATE.md).
- Coach / tips con IA (sí hay Foundation Models on-device para pizarra)
- SDK RevenueCat en Apple Watch

## Licencia

Repera mantiene una implementación propia y utiliza las dependencias de terceros según sus respectivas condiciones de licencia.


## Acceso IA y recepción automática

Ajustes → Conecta tu IA presenta los asistentes disponibles y las conexiones; los tokens personales quedan en Configuración manual. La vinculación OAuth requiere autorización de Repera en la web. Claude ofrece instrucciones copiables para configurar el conector una vez con un ID público, sin claves personales; ChatGPT permanece deshabilitado hasta publicar su ficha real. Los entrenamientos que un asistente envía mediante el MCP aparecen en Inicio/Diario automáticamente mientras la app está abierta y se avisan con una tarjeta breve, gracias a la suscripción Realtime protegida por RLS del usuario. Las propuestas pendientes se recuperan automáticamente al iniciar la app y al volver al primer plano, sin acciones manuales. **No hay notificaciones push cuando la app está cerrada**. Detalles y checklist en [docs/MCP_PLAN.md](docs/MCP_PLAN.md).


## Coach deportivo IA

El MCP Repera también expone un perfil de entrenamiento voluntario (objetivo, experiencia, tiempo, equipo), la agenda de rutinas personales próximas sin notas ni Salud, el catálogo de ejercicios enlazado con ID nativos y los programas por fases hasta 52 semanas. El perfil se deduce del historial deportivo mediante `get_training_profile` y el asistente pregunta por objetivos, tiempo y material cuando faltan datos; no hay formulario de perfil IA en Ajustes. Desde **Ajustes → Entrenamiento** se pueden revisar/activar programas y recibir las actualizaciones de forma automática. El asistente puede crear programas persistentes y propuestas concretas de hasta 14 entrenamientos por petición. Las métricas del backend son estimaciones de esfuerzo deportivo, no un sistema clínico. La sincronización completa con entrenadores y la verificación E2E en dispositivo siguen abiertas; detalles en [docs/MCP_PLAN.md](docs/MCP_PLAN.md).


### Perfil IA, Apple y permisos (21/10/2026)

El perfil de entrenamiento se observa a partir del historial deportivo de Repera; las preferencias que el histórico no acredita (objetivo actual, disponibilidad, material) se preguntan durante el chat y solo se guardan si el deportista las confirma expresamente mediante MCP. No existe formulario «Perfil deportivo IA» en Ajustes. El servidor aporta requisitos de equipamiento normalizado para el catálogo y demandas articulares orientativas solo donde la asignación está contrastada; no son evaluaciones de lesiones. La cuenta Apple puede sincronizar nombre y avatar ahora que Supabase tiene la columna `profiles.avatar_url`, el bucket `profile-avatars` y permisos RLS de propietario. La sincronización se realiza automáticamente al restaurar sesión y volver al primer plano, sin controles manuales en Cuenta. En Apple Salud, los permisos de sueño y ciclo no se presentan como pendientes por no haber sido decididos: se solicitan únicamente si el usuario los activa.


## Escáner CrossFit / Coach MCP v0.4 (22/10/2026)

El catálogo nativo, la búsqueda y Supabase incorporan cuatro movimientos distintivos detectados en ejemplos de gimnasios (Carrera, Dominadas lastradas, Remo pliométrico en anillas pies elevados y Step-up al cajón con kettlebell goblet). El parser ligero separa intervalos, For Time con varios tramos, series de halterofilia con %1RM, pausas y descansos. Los programas de IA se abren desde Diario; antes de empezar una sesión se puede pulsar en movimientos enlazados a la biblioteca. En Cuenta el avatar editable integra el indicador Apple y la sincronización muestra el estado dentro del botón. Se elimina el texto que pedía configurar RevenueCat porque StoreKit puede funcionar sin él.

El MCP v0.4 ofrece edición/archivo/restauración de propuestas pendientes con versiones, tokens personales de solo lectura o lectura/escritura y fechas de vencimiento, entradas estrictas, paginación de historial/planes/programas y metadatos de articulaciones informativos. **No** borra directamente entrenamientos ya realizados ni envía notificaciones cuando la app está cerrada. El soporte OAuth 2.1 se añade detrás de activación controlada; véase [conexiones OAuth](docs/OAUTH_CONNECTIONS.md). Ver [docs/MCP_PLAN.md](docs/MCP_PLAN.md).


## Historial editable de manera segura desde MCP

Desde Acceso IA se pueden aprobar o rechazar propuestas de cambio de entrenamientos completados y de ejercicios personalizados generadas por un asistente con permiso de escritura. Nunca se sobrescriben directamente los entrenos en iCloud desde el backend. La creación/edición de un ejercicio personalizado respeta los límites de cuenta; la biblioteca de ejercicios de Repera sigue siendo curada. Los horarios concretos requieren zona IANA y offset UTC explícitos; fechas sin hora mantienen su semántica de día del calendario. Los planes comparten un esquema completo y estricto para creación y actualización. Más detalles: [docs/MCP_PLAN.md](docs/MCP_PLAN.md).


## Conexión guiada con asistentes (2026-10-24)

Última actualización: 2026-10-24.

Se incorpora el soporte de OAuth gestionado por Supabase, consentimiento web y aislamiento de credenciales MCP, manteniendo los PAT manuales. La UI **Conecta tu IA** ofrece Claude con instrucciones copiables para añadir una conexión personalizada OAuth (sin tokens en el chat). ChatGPT permanece pendiente de su ficha publicada. La integración no está publicada por el hecho de integrar este código. Arquitectura, pruebas, despliegue y presentación a revisión: [docs/OAUTH_CONNECTIONS.md](docs/OAUTH_CONNECTIONS.md).
