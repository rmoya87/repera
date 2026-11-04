# AGENTS.md — Repera

Última actualización: 2026-11-04.

Instrucciones para agentes (Cursor / Auto) que trabajan en este repo.

## Idioma

- Responder al usuario en **español**.
- Código e identificadores en inglés como el resto del proyecto.

## Documentación (obligatorio)

Tras **cualquier** cambio de comportamiento, UI relevante, arquitectura o flujo:

1. Actualizar los docs afectados (`README.md`, `docs/ARCHITECTURE.md`, `docs/FEATURES.md`, `docs/BOARD_SCAN.md`, …).
2. Eliminar o corregir información obsoleta / incorrecta.
3. Seguir `docs/MAINTENANCE.md`.
4. No inventar features en la doc que no estén en el código.

Si el cambio es solo tipográfico o de estilo sin cambio de producto, no hace falta tocar docs.

## Stack

- **Target mínimo**: iOS 26+ / watchOS 26+ (UI Liquid Glass; no bajar de 26). Programar contra el SDK más reciente. Al salir un major nuevo, subir `project.yml`, `Package.swift` y docs.
- SwiftUI, XcodeGen (`project.yml`).
- Dominio: `Packages/ReperaDomain`.
- App: `Apps/Repera`, Watch: `Apps/ReperaWatch`.

## Skills de diseño e ingeniería (obligatorio cuando aplique)

Referencia oficial: https://github.com/emilkowalski/skills

Las skills viven versionadas en `.agents/skills/` (lock en `skills-lock.json`). Si faltan en el entorno local: `npx skills@latest add emilkowalski/skills`. Para actualizar el set vendored: mismo comando y revisar el diff antes de commit.

- Antes de proponer, diseñar o implementar cambios de UI, UX, componentes visuales, transiciones o animaciones, **identificar las skills pertinentes**, abrir y leer sus archivos `SKILL.md` y aplicar sus criterios al cambio concreto.
- En trabajo de **diseño de producto / Progreso / métricas / dashboards de datos**, leer primero **`repera-design`** (`.agents/skills/repera-design/SKILL.md`): lenguaje tipo Apple Salud (chips, insights narrativos, ventanas fijas) con métricas propias Repera, Liquid Glass, chips verde/negro y sin clonar iconografía Activity/Salud.
- Seleccionar según el trabajo: `repera-design` (filosofía de producto Repera), `emil-design-eng` (calidad visual e interacciones), `write-swift` (Swift moderno), `animate`, `review-animations`, `improve-animations`, `remove-animations` y `animation-performance` (movimiento justificado, revisión y fluidez), `apple-design` (principios de Apple adaptados a web), `mobile-native` (experiencia web móvil), `break-ui` (casos extremos) y `pick-ui-library` (priorizar soluciones maduras frente a componentes improvisados).
- Las skills **complementan** las guías oficiales de cada plataforma; no sustituyen las APIs, los patrones nativos ni las convenciones de Repera.
- Si una skill no existe, no está instalada o no puede leerse, comunicarlo. **Nunca afirmar que se ha consultado sin haber leído su contenido** ni bloquear una corrección urgente por ello.
- No instalar dependencias innecesarias ni añadir complejidad solo para aplicar una skill.

## Desarrollo nativo y reutilización por plataforma (obligatorio)

- **iOS / iPadOS:** utilizar Swift y SwiftUI y los controles, navegación, sheets, gestos, tipografía, accesibilidad y patrones nativos de Apple. Conservar y reutilizar los componentes `OG*`, `Theme.swift`, modificadores y arquitectura existentes antes de crear otros.
- **Apple Watch / watchOS:** utilizar las APIs nativas de watchOS (SwiftUI, Digital Crown, HealthKit, WatchConnectivity cuando corresponda), con interacciones breves, controles y jerarquías visuales específicos del reloj. No trasladar pantallas de iPhone sin adaptar.
- **Android:** utilizar el stack nativo real del proyecto y los componentes oficiales de Android / Material 3 (Jetpack Compose cuando corresponda), respetando navegación del sistema, tamaños de ventana, accesibilidad, gestos y comportamiento del dispositivo.
- **Wear OS:** emplear componentes y patrones específicos de Wear OS (Compose for Wear OS cuando corresponda), teniendo en cuenta pantallas redondas, biseles, rotary input, batería, legibilidad e interacciones cortas. No copiar sin adaptar la UI de Android móvil.
- **Versiones de OS:** diseñar y probar tomando como referencia la **última versión estable disponible** de cada sistema y su SDK oficial compatible, aprovechando componentes y comportamientos actuales. Mantener los **mínimos de despliegue declarados en este repositorio** y aplicar comprobaciones de disponibilidad/fallbacks cuando una API no exista en sistemas anteriores; nunca subir mínimos ni introducir APIs incompatibles sin valorar y documentar su impacto.
- **Reutilizar antes de crear:** buscar primero vistas, componentes, tokens, utilidades, modelos, servicios y flujos existentes. Preferir ampliarlos o componerlos frente a duplicar lógica o crear archivos, controles, librerías o capas nuevos sin necesidad. Compartir lógica y contratos cuando proceda; **no forzar compartir UI entre plataformas si empeora la experiencia nativa**.
- La UI debe sentirse propia de **cada** sistema, moderna, coherente con el verde de Repera, rápida, accesible, clara y sin movimiento decorativo. Respetar tamaño de texto dinámico, contraste, áreas táctiles, modo claro/oscuro, orientación, tamaños de pantalla y estados de carga/vacío/error.

## Paridad funcional e incidencias entre plataformas (obligatorio)

Cuando el usuario solicite una **nueva funcionalidad, modificación de comportamiento o corrección de incidencia en una plataforma**, revisar su impacto en **iOS, iPadOS, watchOS, Android, Wear OS y Repera Business**, según corresponda.

1. Identificar las implementaciones equivalentes, modelos, persistencia, sincronización, contratos de API y permisos afectados en las demás plataformas.
2. Si la funcionalidad debe existir también en ellas, **implementarla o corregirla en la misma tarea** de forma equivalente y adaptada a su UI nativa; no limitarse automáticamente a la plataforma mencionada.
3. Verificar regresiones, sincronización entre móvil/reloj/web, estados offline y compatibilidad con datos preexistentes. No duplicar escrituras, sesiones o registros de salud.
4. Si una plataforma no admite una capacidad, queda fuera del alcance funcional o no puede verificarse en el entorno, **explicar de forma concreta la excepción, su motivo y lo que queda pendiente**; no simular paridad ni declarar que se ha probado.
5. No confundir **paridad funcional** con interfaces visualmente idénticas: cada sistema conserva su navegación, componentes y convenciones.

## Seguridad y privacidad por defecto (obligatorio en toda tarea)

- Considerar la seguridad desde el diseño, la implementación, las pruebas y el despliegue; aplicar **mínimo privilegio, defensa en profundidad y denegación por defecto**.
- Autenticación y autorización **en el servidor** para toda operación sensible: validar sesión, identidad, rol, propiedad del recurso, pertenencia al centro/entrenador y permisos por acción. No confiar en ocultar botones, comprobaciones solo de frontend o IDs facilitados por el cliente.
- En Supabase/PostgreSQL: revisar y probar **RLS**, políticas multi-tenant, funciones `SECURITY DEFINER`, grants y acceso a Storage. Impedir accesos horizontales entre atletas, entrenadores, gimnasios y administradores. Evitar elevación de privilegios o suplantación al usar administración delegada; limitar duración y auditar accesos.
- Nunca introducir claves, tokens, service-role keys ni secretos en apps, repositorio, logs o navegador. Mantener secretos en el entorno seguro correspondiente. Almacenar credenciales/sesiones mediante los mecanismos oficiales y manejar expiración, revocación y renovación.
- Validar entradas en el servidor y proteger frente a inyección, XSS, CSRF cuando aplique, escalada de privilegios, abuso de endpoints y automatizaciones; aplicar límites de tasa, controles de concurrencia e idempotencia en operaciones críticas.
- Tratar entrenamientos, ubicación, HealthKit/Health Connect, pagos y datos personales con minimización, consentimiento y acceso estrictamente necesario, transporte cifrado, registros sin información sensible y protección acorde con RGPD y las políticas de cada plataforma.
- Las operaciones de cobro, suscripciones y webhooks deben verificarse **en servidor**; nunca inferir derechos de pago a partir de indicadores del cliente.
- Toda migración o cambio de permisos requiere revisión del efecto sobre datos existentes, políticas RLS y pruebas negativas: un usuario/centro **no debe poder consultar ni modificar datos ajenos**.
- Si una decisión introduce riesgo de seguridad relevante, priorizar corregirlo antes de considerar la tarea terminada y comunicar bloqueos sin exponer secretos.

## Repera Business — UX rápida, moderna y segura

- Priorizar que **entrenadores personales, gimnasios y administradores** completen sus tareas habituales con el menor número razonable de pasos, clics y esperas. Diseño limpio, actual, dinámico solo cuando aporte claridad y feedback; sin sobrecargar el panel de tarjetas, modales o animaciones.
- Preferir navegación y jerarquías claras, acciones principales evidentes, reutilización de componentes, edición contextual, formularios breves, valores preseleccionados seguros, acciones en lote cuando proceda y estados de confirmación/error comprensibles.
- Optimizar tiempo de respuesta percibido y real: evitar consultas y rerenders redundantes, paginar listados grandes, dar respuesta inmediata, mostrar estados de carga y evitar bloquear la interfaz. Nunca mostrar éxito antes de la confirmación real del servidor; las actualizaciones optimistas deben poder revertirse.
- Diseñar con criterios responsive para escritorio y tablet, además de móvil cuando corresponda: tablas, calendarios, menú lateral, paneles de detalle, formularios, estados vacíos y errores.
- Aplicar seguridad **alta de principio a fin** en cada flujo Business: separación de centros, protección de información de atletas, autorizaciones por rol/acción, auditoría de cambios críticos, control de invitaciones y enlaces, gestión segura de bonos, reservas, planes y pagos.
- No sacrificar autorización, trazabilidad, consistencia de datos ni privacidad por reducir clics. Evitar solicitar permisos o mostrar datos que el rol no necesita.

## Verificación antes de dar una tarea por terminada

- Inspeccionar primero el código y los componentes existentes; introducir el cambio mínimo coherente con la arquitectura.
- Revisar flujos felices y de error, estados vacíos, carga, conexión lenta/sin conexión, permisos denegados, datos extremos, tamaños y orientaciones de pantalla, accesibilidad y rendimiento.
- Ejecutar las pruebas, linters y builds disponibles para las plataformas afectadas. Si no hay simulador, SDK, cuenta o dispositivo para verificar algo, indicarlo expresamente.
- Revisar regresiones y paridad con el resto de plataformas; documentar las excepciones. Actualizar la documentación afectada siguiendo `docs/MAINTENANCE.md`.
- No afirmar que está desarrollado, probado, desplegado o subido a otra rama cuando esa operación no se haya realizado y confirmado.

## Convenciones UI

- Tokens `OG*` en `Theme.swift`.
- Roots sin volver: `ogFixedTopBar` (título arriba; acciones a la derecha en la misma fila).
- Subpáginas con volver: `ogPinnedTransparentNav` (título large debajo del chevron/acciones).
- Sheets compactos: `OGPageHeader` + `ogFittedSheet` / `ogSheetCorners`.
- Títulos de sección **encima** de las cards: `OGCardSectionTitle` (gris, estilo Ajustes).

### Filosofía de diseño (agente de diseño)

Fuente de verdad: `.agents/skills/repera-design/SKILL.md` (regla `.cursor/rules/repera-design.mdc`).

- **Salud como lenguaje, Repera como contenido:** chips temáticos + insights narrativos + ventanas fijas; métricas propias (entreno + sensores), no dump de Health ni clon de Apple.
- **Chips:** icono+nombre en fila, valor debajo; seleccionado = verde sólido + negro sin outline; no seleccionado = Liquid Glass (iOS); barra transparente.
- **Jerarquía:** héroe → grid glance → insights de periodo → largo plazo (Pro). Cards insight con icono tintado, frase, número y mini viz.
- **No:** calendario global en hubs, chevrons muertos, anillos Activity, iconos Salud Apple, pantallas tintadas de verde, ceros fisiológicos inventados.

## Arte de ejercicios (carrusel)

- Mismo **equipo** (diseño idéntico) y misma **persona** (pelo, ropa, zapatillas) en todos los frames de un ejercicio.
- Ropa: **tank + shorts + zapatillas**; nunca torso desnudo ni sin shorts.
- Al regenerar: usar el frame `_1` como `reference_image_paths` y solo cambiar la pose.

## Pizarra

Pipeline: OCR → Apple Intelligence si hay → si no, `BoardImportParser`. Detalle en `docs/BOARD_SCAN.md`.

## Commits / PR

Solo cuando el usuario lo pida. Seguir las user rules de git/PR del entorno.

## Lecciones de fallos (obligatorio)

Tras un fallo real de CI/compilación/producto: corregir causa raíz **y** registrar la lección en `.cursor/rules/native-platform-lessons.mdc` (proceso en `.cursor/rules/learn-from-failures.mdc`). Priorizar APIs nativas por SO, sin duplicar sensores ni inventar datos. No dar por cerrado un trabajo solo porque compile.

## Fiabilidad, rendimiento y seguridad (auditoría 2026-11-04)

Fuente de la pasada: `docs/RELIABILITY_SECURITY_AUDIT_2026_11_04.md`. En trabajo nuevo, **mantener** estas invariantes:

### Rendimiento
- **Android:** no leer/parsear `app_state.json` ni Health Connect en el hilo principal desde Compose/callbacks; usar `Dispatchers.IO` + caché por revisión. Release con **R8 + shrinkResources**. Preferir `collectAsStateWithLifecycle` y `key` estable en Lazy lists.
- **iOS:** rutas GPS y snapshots grandes en Application Support (Data Protection), no UserDefaults; no invalidar toda `LiveActivityView` por cada fix GPS; cachear historial/formatters calientes.
- **Relojes:** Always On / Ambient con métricas clave y ticks lentos; GPS con `distanceFilter`; rutas grandes por archivo/trozos, no un `transferUserInfo` monstruo; sensores (acelerómetro) solo cuando hacen falta.

### Bugs / sync móvil↔reloj
- Confirmaciones explícitas: Wear `live-start` debe ACK también con la app móvil en primer plano; el resumen de fin companion **solo** tras confirmación del teléfono.
- Nunca doble escritura Salud/Health Connect (Watch dueño → iPhone enlaza; companion Wear sin ExerciseClient de workout).
- Aislar preferencias por cuenta (`ownerScope` / account id); no adoptar datos legados sin dueño.
- Session vacía por WatchConnectivity **no** cancela; solo evento terminal por id (doc en `docs/watch-healthkit.md`).

### Seguridad
- Edge Functions: secretos de cron **obligatorios** (fail closed); CORS con allowlist; rate limit en MCP; nunca `service_role` en clientes.
- Logs: nada de OCR/salud/tokens en release (`#if DEBUG` / strip R8).
- Monetización: no tratar «sin snapshot» como Pro; verificar compras en servidor cuando exista el camino (Play ya; App Store en progreso).
- Placeholder `YOUR_REVENUECAT_PUBLIC_API_KEY`: runtime = monetización no disponible; archive Release debe fallar (`project.yml` preBuildScripts).
- No aplicar migraciones ni desplegar Edge desde el agente sin confirmación explícita del humano; seguir `docs/SUPABASE_MIGRATION_RECONCILIATION_2026-11-04.md`.

### UX
- «**Center**» es nombre de producto (no traducir a «Centro»); accesibilidad en español natural.
- Roots `ogFixedTopBar` / subpáginas `ogPinnedTransparentNav`; Watch tokens `WatchTheme` (no `#30D158` suelto); Wear touch ≥ 48 dp y `strings.xml`.

## No hacer

- No asumir backend social.
- No meter API keys de LLM cloud para el escáner (on-device o parser local).
- No reintroducir el botón «+ Plan» en la lista de ejercicios sin pedirlo.
- No reutilizar APIs de otra plataforma sin comprobar disponibilidad en el SDK del target (p. ej. `openInWorkoutApp` solo watchOS).
- No dejar Edge Functions abiertas sin secreto de cron ni logs con texto OCR/PII en release.
