# Plan integral de instrumentación GA4 — Repera

**Fecha:** 2026-11-04 · **Estado:** Embudos núcleo + Centro/IA/timer/maps/Watch relay en código · ver `INSTRUMENTATION_MATRIX.md`

## Alcance y principios

iOS, Android, watchOS, Wear OS, incluidas las funciones de entrenamiento, Comenzar, temporizador, ejercicios, escáner, progreso, Centro/clases, suscripciones, IA, onboarding, navegación, ajustes e integraciones. La taxonomía versionada de `analytics/contract.json` es la única fuente de criterios funcionales. La telemetría nunca debe bloquear el guardado deportivo.

El evento lógico y sus parámetros son comunes entre plataformas. `origin_platform` indica dónde sucedió la interacción; `session_origin_platform` quién creó la sesión y `completion_platform` dónde se solicitó el cierre. `workout_completed` se emite únicamente después de la persistencia duradera y solo una vez por UUID, no al tocar Finalizar ni al recibir un snapshot. `class_attended` exige asistencia confirmada, y no se infiere de reserva.

## Despliegue por fases con dependencias

| Fase | Alcance | Criterio de aceptación | Estado |
| --- | --- | --- | --- |
| 0. Inventario y contrato | Catálogo de eventos, semántica, parámetros, privacidad, IDs de deporte y WOD, matriz funcional | La fuente de eventos y valores es única y testeable | Hecho (base) |
| 1. SDK móvil | Firebase Analytics iOS/Android; sin UI consent (estilo Cafesito); off hasta configurar; sin IDFA/AD_ID | Sin Firebase la app no falla; con Firebase se activan métricas de producto | Hecho (falta plist/json reales) |
| 2. Embudos núcleo | Alta/onboarding, pantallas, entrenamiento y persistencia, favoritos, temporizadores, progreso y escáner | 1 evento lógico por acción real, comparables y sin duplicados | Hecho en código (faltan plist/json reales) |
| 3. Relojes | Cola duradera, transporte WatchConnectivity/Data Layer, ACK, deduplicación y atribución de origen | Offline/reintentos/cambio de cuenta sin pérdida silenciosa ni doble cómputo | Parcial: relay `watch_app_opened` + ACK logSet; Wear durable pendiente |
| 4. Negocio y monetización | Clases, citas, acceso libre, asistencia, IA, compras verificadas y paywall real | Reservas != asistencia; compra comprobada; patrocinio != compra | Hecho en apps (Business web pendiente) |
| 5. Todas las interacciones | Matriz pantalla/sección/componente/acción; gestos, hojas, filtros y accesos del SO | Cada control significativo tiene un nombre estable y pruebas de paridad | Pendiente |
| 6. Informes y operación | GA4, dimensiones limitadas, BigQuery, informes comparativos y calidad de datos | Rankings por deporte, formato, clase, sección, plataforma y usuario activo | Pendiente |
| 7. E2E y rollout | Contratos Swift/Kotlin, pruebas reales cuatro dispositivos, QA privacidad, CI y activación progresiva | DebugView, prueba real de consentimiento, cero PII, regresiones verificadas | Pendiente |

## Arquitectura de integración

- Cliente iOS / Android: fachada `ReperaAnalytics` con allowlist de eventos y parámetros, consentimiento persistido y un adaptador Firebase; sin recursos de configuración del proyecto la salida permanece desactivada. En iOS el archivo `Apps/Repera/Sources/Analytics/ReperaAnalytics.swift` va **explícito** en `project.yml` (XcodeGen 2.46 puede omitir la carpeta `Analytics/` del target); `scripts/check_xcode_sources.py` y `tests/test_xcode_sources.py` fallan si desaparece de Compile Sources.
- Relojes: **NO** integrar Firebase directo en watchOS; no usar SDK ni conexión de red propia para telemetría en Wear sin necesidad. Crear mensajes tipados a móvil y una cola local de límite bajo, con ACK de recepción duradera y reintento con backoff. El teléfono revalida consentimiento y cuenta.
- Diferenciar `source_of_truth` deportivo y telemetría: que la acción suceda, que se confirme en el repositorio/servidor, y que se emita el evento son procesos separados.
- Un UUID de sesión se usa para deduplicación local y un `event_id` opaco para correlación técnica; ninguno se registra como dimensión personalizada de alta cardinalidad. En BigQuery se deduplica adicionalmente con la clave lógica de negocio.
- El orden de las fases permite primero desplegar contratos y SDKs en modo no-op, luego instrumentar puntos de éxito por áreas con suites de pruebas.

## Dimensiones y rankings

1. `activity_family`: grupos globales deportivos; `activity_type`: ID persistido en `LiveSport` Swift/Kotlin. Nunca inferir el deporte a partir del título libre del entrenamiento.
2. `workout_type`: planificado, libre, clase, entrenador, IA, importado; `wod_format` es el catálogo compartido `WODFormat` de 14 valores. Una sesión puede tener varios bloques; el top de formatos cuenta **bloques completados**, no duplica entrenamientos.
3. `service_kind`: `class | appointment | open_access`; `class_category`: **clasificación global** del `activity_types.code` del centro mediante un mapeo cerrado. Los nombres de clases, gimnasios, entrenadores y títulos libres nunca se envían a GA4. Mantener el detalle de cada centro con RLS en Supabase, fuera de GA4.
4. `screen_name` y `section_name` estables; el texto visible es solo metadato curado, nunca etiqueta libre. Las seis secciones de Progreso son `training | strength | fitness | heart | recovery | sports`.
5. `ui_interaction` para gestos y controles (tap, selección, toggle, swipe, zoom, pan, corona) con `component_id` y `action_name` de lista cerrada. No emitir scroll continuo, caracteres tecleados, ticks, GPS, FC o estados cada segundo.

Rankings:
- Top actividades por sesiones únicas **guardadas**; top actividades seleccionadas/iniciadas por eventos distintos.
- Top formatos WOD por bloques completados, sin sumar el mismo workout varias veces.
- Top tipos de clases por asistencia **verificada**; otra tabla separada por reservas confirmadas.
- Top secciones por usuarios únicos y vistas reales; top acciones por usos validados.
- Cortes por `origin_platform`, móvil/reloj, plan (`free/pro/sponsored`), fecha/cohorte y versión.

## Inventario por sección y puntos de verdad

| Área | Fuente actual | Tracking objetivo |
| --- | --- | --- |
| Navegación principal | `RootTabView`, `MainActivity` + Compose | `screen_view`, `ui_interaction` solo al cambio real |
| Entrenamientos | `ReperaStore`, `SessionController`, `WorkoutRepository` | guardar/editar/borrar/completar desde escrituras confirmadas |
| Comenzar / GPS | `LiveActivityView`, `LiveActivityScreen` | deporte, sesión, ruta cargada, 2D/3D (sin coordenadas) |
| Apple Watch / Wear | `WatchSessionHub`, `PhoneConnectivity`, `WearMainActivity`, `WearLiveCommandListener` | comandos, ACK, un cierre por sesión |
| Suscripciones | `MonetizationAnalytics`, `SubscriptionManager` | reutilizar ocho eventos existentes; correlacionar compra/verificación |
| Progreso | `ProgressCategoryChips` Swift/Kotlin | seis IDs unificados; periodo y detalle |
| Centro | `BusinessDataStore`, `CenterView`, `service_bookings` | lectura, reserva, waitlist, asistencia confirmada |
| AI/escáner | stores de AI y pipeline OCR | inicio, validación, aceptación, resultado persistido |
| Interacciones | controles SwiftUI/Compose por pantalla | matriz de controles y `ui_interaction` semantic |

## Privacidad y seguridad

Recopilación desactivada por defecto. Antes de habilitar producción hay que aprobar la base legal y la preferencia de aceptación/revocación en Ajustes y los textos de App Store/Play/Data Safety. No enviar datos de Salud/HealthKit/Health Connect (incluidos derivados), ubicación, rutas, identificadores de cuenta en texto, nombres propios ni valores escritos. No usar `GoogleService-Info.plist` ni `google-services.json` inventados. Restringir la lista de parámetros permitidos y prohibir passthrough de datos libres. El cambio de usuario obliga a borrar identidad y cola del anterior.

## Pruebas de aceptación

1. iOS y Android emiten el mismo evento para guardar un entrenamiento nuevo; editar e importar histórico no cuentan como entreno nuevo.
2. Apple Watch/Wear offline -> reenvío -> ACK repetido -> **una** única finalización, atribuida al dispositivo correcto.
3. Clases: booked/waitlist/cancelled no cuentan como attended; una asistencia con workout asociado no duplica el entrenamiento.
4. Sin consentimiento, sin configuración o sin red: cero envíos y experiencia deportiva normal. Revocación borra colas pendientes y resetea identidad.
5. GA4 DebugView: validar nombres, parámetros, atribución, tipos de dato, y ventanas de fecha; comparar con almacenamiento local/sistema de reservas.
6. CI tests Swift/Kotlin de contrato y paridad, builds iOS/watchOS/Android/Wear, pruebas reales GPS/BT/pausa y consumo de batería.
7. Auditoría de cardinalidad: no registrar `event_id` como dimensión GA4, limitar valores de `ui_interaction`; no nombres arbitrarios.
8. Dashboard y BigQuery verifican definición, denominadores, consentimientos, muestreo y eventos retrasados.

## Requisitos externos pendientes

- Crear o reutilizar la propiedad GA4 y sus flujos de iOS y Android.
- Incorporar valores de Firebase obtenidos realmente de la consola: `GoogleService-Info.plist` en iOS y `google-services.json` para Android móvil. No se crean placeholders que suplanten credenciales.
- Aprobar textos de privacidad/consentimiento, dimensiones personalizadas, vinculación BigQuery y políticas de retención.
- Ejecutar E2E con dispositivos iPhone/Apple Watch y Android/Wear reales.
