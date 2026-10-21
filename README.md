# Repera

App nativa de entrenamiento (**iPhone + Apple Watch**), **local-first + iCloud**, Sign in with Apple, UI **SwiftUI Liquid Glass** (iOS 27+).

Referencia de producto: [openGym](https://github.com/DuarteSantos8/openGym) (solo dominio/UX; no se copia código).

## Documentación

| Documento | Contenido |
|-----------|-----------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Capas, targets, paquetes, datos |
| [docs/FEATURES.md](docs/FEATURES.md) | Funcionalidad por pestaña / flujo |
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
| **Inicio** | Semana/día, métricas Salud, entrenos + externos, avatar→Ajustes, planificar / pizarra |
| **Diario** | Sesiones profesionales fechadas consultadas desde Supabase + planificación personal/rutinas conservadas; ejecución estructurada pendiente |
| **Center** | Selector Clases/Citas con lectura de horarios reales, reservas y cancelaciones mediante Supabase cuando haya sesión y bono disponible; E2E pendiente |
| **Crear desde Inicio** | Botón +: entreno libre, **Apuntar series**, favoritos, timer, foto pizarra/TV (sin pestaña propia) |
| **Progreso** | Gratis: esta semana + teaser; Pro: periodos, deltas, cardio/kcal/peso, heatmap, equilibrio |
| **Ejercicios** | Biblioteca + ficha; evolución completa = Pro (Gratis: última sesión + PR) |
| **Sesión** | Series, WU/drop/rest-pause, RIR/RPE, discos, menú ⋯, Live Activity descanso |
| **Pizarra** | OCR lite; Gratis 4 escaneos/mes; Pro ilimitados |
| **Onboarding** | Sign in with Apple obligatorio → Gratis/Pro → permisos (notif, Salud, ubicación) |
| **Ajustes** | Cuenta Apple, Pro / restaurar, iCloud, permisos/Salud, historial, peso, export/import |
| **Datos** | JSON local + iCloud Documents; CSV Strong/Hevy (sin entitlement en el JSON) |
| **Watch** | Confirmar → conteo → **+1 serie** / log rápido (sin límites Pro en v1) |
| **Monetización** | StoreKit + RevenueCat; ver [docs/MONETIZATION.md](docs/MONETIZATION.md) |

## Arranque rápido en Mac (doble clic)

- [`Repera-Business.command`](Repera-Business.command): abre por defecto el **panel profesional conectado a Supabase**, con login real y datos autorizados por RLS; requiere Python 3 y mantiene abierta una ventana Terminal. Para la demo aislada con datos ficticios, ejecuta `./Repera-Business.command --demo` o abre `/console/?demo=1`. El modo conectado todavía requiere validación E2E antes de usarse en producción.
- [`Repera-Xcode.command`](Repera-Xcode.command): **abre Xcode después de regenerar el proyecto** y comprueba que los almacenes Apple/Supabase, `AITrainingInboxStore.swift` y `AIAccessView.swift` están incluidos en *Compile Sources* del target. Úsalo al actualizar el repositorio.
- [`Repera-iOS.command`](Repera-iOS.command): intenta compilar y lanzar la app en Simulator; regenera y valida el proyecto antes de compilar; requiere macOS, Xcode con iOS 27, XcodeGen y un simulador compatible.
- Ambos lanzadores están en la raíz del repositorio; si clonas por Git, se conserva el permiso de ejecución. No se ha generado todavía una aplicación macOS firmada ni un paquete iOS listo para distribución.

**Estado:** la identidad Apple y el flujo profesional conectado con Supabase ya están en `main`. Aún requieren validación con cuentas y dispositivos reales; consulta los checks de GitHub Actions del commit actual antes de publicar en TestFlight.

## Repera Business · alta de negocios y tarifas administrables

El panel `/console/` usa Supabase Repera con sesión real. Para dar de alta un negocio se escoge **Entrenador personal** o **Gimnasio**: el identificador público se genera a partir del nombre comercial; no se introduce manualmente. El alta permite correo/teléfono, web, dirección y descripción, además de nombre/razón social, NIF/NIE/CIF, representante, persona de contacto, correo/domicilio de facturación y localidad. El **logotipo del gimnasio** o la **foto del entrenador** se sube como JPG/PNG/WebP al bucket público `business-branding` con permisos del propietario/administrador; su URL se vincula al perfil utilizado también por la búsqueda de Repera iOS. La información fiscal vive en `organization_legal_profiles` y **no es visible para atletas**.

Los planes aparecen desde `business_plans`, configurables por el **administrador verificado de Repera** (precios, cupos, promociones y visibilidad) y separados por entrenador/gimnasio. Seleccionarlos solo crea una solicitud pendiente, nunca cobra ni da acceso de pago. Requiere la migración `business_org_identity_plans` del proyecto Repera y pruebas E2E antes de producción. Más detalles: [entorno local](docs/business/README_LOCAL.md).

## Solución: Xcode no encuentra `AITrainingInboxStore`, `AIAccessView` o los almacenes Supabase

El proyecto Xcode (`Repera.xcodeproj`) **se genera localmente** y no se versiona. Puede quedarse con la lista de fuentes anterior a la integración de Supabase, aunque los archivos Swift existan en disco. Por tanto, errores como `Cannot find 'AITrainingInboxStore' in scope` (desde `ReperaApp.swift`), `Cannot find 'AIAccessView' in scope` (desde Ajustes), `Cannot find 'BusinessAuthStore' in scope` o `Cannot find 'BusinessWorkoutSyncStore' in scope` suelen requerir regenerar el proyecto, **no duplicar la clase ni eliminar la limpieza de la sesión Supabase**. El validador comprueba también que el archivo esté en *Compile Sources*, no solo en el navegador de Xcode.

Cierra Xcode y haz doble clic en [`Repera-Xcode.command`](Repera-Xcode.command). **Este lanzador ahora comprueba `origin/main` y hace solo un fast-forward cuando trabajas en `main` y no hay cambios sin confirmar**; después ejecuta XcodeGen, comprueba que los almacenes Apple/Supabase y los dos nuevos archivos IA están realmente en *Compile Sources* y abre el proyecto regenerado. [`Repera-iOS.command`](Repera-iOS.command) usa la misma reparación antes de lanzar Simulator.

Si la carpeta local tiene cambios sin confirmar, otra rama o no hay conexión, el lanzador **no sobrescribe, descarta ni fusiona nada**: avisa y utiliza el código disponible. Si faltan `AITrainingInboxStore.swift`, `AIAccessView.swift` o `BusinessWorkoutSyncStore.swift`, guarda tus cambios y actualiza `main`; regenerar un proyecto no puede inventar un archivo Swift ausente. Alternativa:

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

Requisitos: **Xcode con SDK iOS 27**, dispositivo/simulador compatible. Apple Intelligence es opcional (fallback local en pizarra).

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

Reimplementación Swift propia. openGym es AGPL — no se incorpora su código al binario.


## Acceso IA y recepción automática

Ajustes → Acceso IA crea/revoca tokens personales con la sesión Supabase del inicio normal de Repera, sin presentar otro inicio de sesión de Apple. Los entrenamientos que un asistente envía mediante el MCP aparecen en Inicio/Diario automáticamente mientras la app está abierta y se avisan con una tarjeta breve, gracias a la suscripción Realtime protegida por RLS del usuario. El botón «Sincronizar ahora» de Cuenta también recupera planes pendientes; si iOS suspende/cierra la app, se incorporan al volver al primer plano. **No hay notificaciones push cuando la app está cerrada**. Detalles y checklist en [docs/MCP_PLAN.md](docs/MCP_PLAN.md).


## Coach deportivo IA

El MCP Repera también expone un perfil de entrenamiento voluntario (objetivo, experiencia, tiempo, equipo), la agenda de rutinas personales próximas sin notas ni Salud, el catálogo de ejercicios enlazado con ID nativos y los programas por fases hasta 52 semanas. Desde **Ajustes → Entrenamiento** se puede configurar el perfil, revisar/activar programas y seguir usando **Cuenta → Sincronizar ahora**. El asistente puede crear programas persistentes y propuestas concretas de hasta 14 entrenamientos por petición. Las métricas del backend son estimaciones de esfuerzo deportivo, no un sistema clínico. La sincronización completa con entrenadores y la verificación E2E en dispositivo siguen abiertas; detalles en [docs/MCP_PLAN.md](docs/MCP_PLAN.md).
