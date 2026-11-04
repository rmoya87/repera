# AGENTS.md — Repera

Última actualización: 2026-11-04.

Instrucciones para **cualquier agente o IA** que trabaje en este repo (Cursor, Claude, Codex, Copilot, Auto, Cloud Agents, etc.).

**Fuente canónica única:** este archivo.  
`.agents/skills/` = skills de diseño/ingeniería.  
`.cursor/rules/` = stubs opcionales que reenvían aquí (Cursor); no duplicar reglas ahí.

## Idioma

- Responder al usuario en **español**.
- Código e identificadores en inglés como el resto del proyecto.

## Documentación (obligatorio)

Tras **cualquier** cambio de comportamiento, UI relevante, arquitectura o flujo:

1. Actualizar los docs afectados (`README.md`, `docs/ARCHITECTURE.md`, `docs/FEATURES.md`, `docs/BOARD_SCAN.md`, …).
2. Eliminar o corregir información obsoleta / incorrecta.
3. Seguir `docs/MAINTENANCE.md`.
4. Poner fecha «Última actualización» en los docs tocados.
5. No inventar features en la doc que no estén en el código.

Si el cambio es solo tipográfico o de estilo sin cambio de producto, no hace falta tocar docs.  
Fuente de verdad de producto: `docs/*.md` actuales (excepto `docs/superpowers/`, histórico).

## Stack y versiones de OS

- **Target mínimo**: iOS 26+ / watchOS 26+ (UI Liquid Glass; no bajar de 26).
- Programar contra el **SDK más reciente**. Preferir APIs nativas nuevas frente a polyfills.
- Al salir un major nuevo: subir `project.yml`, `Package.swift` y docs (`AGENTS.md`, `README.md`, `docs/ARCHITECTURE.md`).
- SwiftUI, XcodeGen (`project.yml`).
- Dominio: `Packages/ReperaDomain`.
- App: `Apps/Repera`, Watch: `Apps/ReperaWatch`.

## Skills de diseño e ingeniería (obligatorio cuando aplique)

Referencia oficial: https://github.com/emilkowalski/skills

Las skills viven en `.agents/skills/` (lock en `skills-lock.json`). Si faltan: `npx skills@latest add emilkowalski/skills`.

- Antes de UI/UX/animación: leer el `SKILL.md` pertinente y aplicarlo.
- Progreso / métricas / dashboards: primero **`repera-design`** (`.agents/skills/repera-design/SKILL.md`).
- Otras: `emil-design-eng`, `write-swift`, `animate`, `review-animations`, `improve-animations`, `remove-animations`, `animation-performance`, `apple-design`, `mobile-native`, `break-ui`, `pick-ui-library`.
- Complementan guías oficiales; no sustituyen APIs nativas ni convenciones Repera.
- Si una skill no se puede leer: decirlo. Nunca afirmar que se consultó sin haberla leído.
- No añadir dependencias solo por aplicar una skill.

## Desarrollo nativo y reutilización por plataforma (obligatorio)

- **iOS / iPadOS:** Swift/SwiftUI nativos; reutilizar `OG*`, `Theme.swift`, modificadores y arquitectura existentes.
- **watchOS:** APIs nativas del reloj; no copiar pantallas de iPhone sin adaptar.
- **Android:** Material 3 / Compose nativo del proyecto.
- **Wear OS:** Compose for Wear, pantallas redondas, rotary, interacciones cortas.
- **Reutilizar antes de crear:** ampliar o componer; no forzar UI compartida entre plataformas si empeora la experiencia nativa.
- UI propia de cada SO, verde Repera, accesible, sin movimiento decorativo.

## Paridad funcional e incidencias entre plataformas (obligatorio)

Ante nueva feature, cambio o bug en una plataforma, revisar impacto en **iOS, iPadOS, watchOS, Android, Wear OS y Repera Business**.

1. Identificar equivalentes, sync, API y permisos en las demás.
2. Implementar/corregir en la misma tarea cuando deba existir paridad (UI nativa por plataforma).
3. Sin doble escritura de sesiones/salud; revisar offline y datos legacy.
4. Si una plataforma no admite la capacidad: excepción concreta + pendiente; no fingir paridad ni «probado».
5. Paridad funcional ≠ UI idéntica.

## Seguridad y privacidad por defecto (obligatorio)

- Mínimo privilegio, defensa en profundidad, denegación por defecto.
- AuthZ **en servidor** (sesión, rol, pertenencia, acción); no confiar en UI oculta.
- Supabase: RLS, multi-tenant, `SECURITY DEFINER`, Storage; sin accesos horizontales.
- Nunca secretos/`service_role` en apps, repo, logs o cliente.
- Validar entradas en servidor; rate limit / idempotencia en operaciones críticas.
- Health/GPS/pagos: minimización, consentimiento, sin PII en logs.
- Cobros/webhooks verificados en servidor.
- Migraciones/permisos: pruebas negativas entre tenants.
- Riesgo de seguridad relevante → corregir antes de cerrar la tarea.

## Repera Business — UX rápida, moderna y segura

- Menos clics razonables para entrenadores, gimnasios y admins; sin sobrecarga de modales/animación.
- Jerarquía clara, edición contextual, lotes cuando proceda; nunca éxito antes de confirmación real del servidor.
- Responsive escritorio/tablet; seguridad multi-centro de principio a fin.
- No sacrificar authZ/privacidad por reducir clics.

## Verificación antes de dar una tarea por terminada

- Cambio mínimo coherente con la arquitectura.
- Flujos feliz/error, vacío, carga, offline, permisos, a11y, rendimiento.
- Tests/linters/builds disponibles; si no hay SDK/dispositivo, decirlo.
- Regresiones y paridad; docs al día.
- No afirmar desarrollado/probado/desplegado/subido sin haberlo hecho.

## Convenciones UI

- Tokens `OG*` en `Theme.swift`.
- Roots: `ogFixedTopBar`. Subpáginas: `ogPinnedTransparentNav`.
- Sheets: `OGPageHeader` + `ogFittedSheet` / `ogSheetCorners`.
- Títulos de sección: `OGCardSectionTitle`.

### Filosofía de diseño

Fuente: `.agents/skills/repera-design/SKILL.md`.

- Lenguaje tipo Apple Salud + métricas propias Repera (no dump Health ni clon Activity).
- Chips: icono+nombre / valor debajo; seleccionado verde+negro; glass en no seleccionados (iOS).
- Héroe → grid → insights periodo → largo plazo Pro.
- No: calendario global en hubs, chevrons muertos, anillos Activity, iconos Salud Apple, pantallas tintadas de verde, ceros fisiológicos inventados.

## Arte de ejercicios (carrusel)

- Mismo equipo y misma persona en todos los frames.
- Ropa: tank + shorts + zapatillas.
- Regenerar: frame `_1` como referencia; solo cambiar pose.

## Pizarra

OCR → Apple Intelligence si hay → si no, `BoardImportParser`. Detalle: `docs/BOARD_SCAN.md`.

## Commits / PR

Solo cuando el usuario lo pida. Seguir las reglas git/PR del entorno.

## Aprender de fallos (obligatorio)

Tras **cualquier** fallo de CI, compilación, revisión o bug reproducido:

1. Corregir la **causa raíz** (no parches sintomáticos).
2. Añadir o actualizar la lección en la sección **Lecciones nativas** de este mismo archivo.
3. Preferir un contrato/test que falle si se reintroduce el error.
4. Distinguir implementado / compilado / CI / hardware; no cerrar solo porque compile.

Antes de código nuevo: reutilizar flujos existentes; comprobar disponibilidad de API **por target**; APIs nativas del SO; sin duplicar sensores/sesiones/Health ni inventar GPS/métricas.

### Prohibido (nativo)

- APIs `@available(…, unavailable)` en el target equivocado.
- Confirmar series, escribir HealthKit/Health Connect o arrancar GPS desde widgets, tiles, receivers o Live Activity intents.
- Dos grabaciones a la vez (Repera + Entreno / HC).
- Afirmar paridad o «probado en hardware» sin evidencia.
- Docs que contradigan el código.

### Lecciones nativas (no repetir)

Ampliar esta subsección cuando un fallo real enseñe algo nuevo.

#### Apple — WorkoutKit (PR #221)

```swift
// ❌ BAD — openInWorkoutApp es solo watchOS; rompe CI iOS
try await plan.openInWorkoutApp()

// ✅ GOOD — iPhone: preview de sistema + scheduler nativo
.workoutPreview(plan, isPresented: $showPreview)
await WorkoutScheduler.shared.schedule(plan, at: when)
```

- Auth del scheduler **no Sendable**: puente `nonisolated` → `rawValue` / outcome Sendable.
- Intervalos: `CustomWorkout` / `IntervalBlock` solo con `supportsActivity` / `supportsGoal` / `supportsAlert`; nunca inventar GPS.

#### Apple — Live Activities / intents

- `LiveActivityIntent` solo **encola** (`UserDefaults` + notificación); la app aplica tras hidratar identidad.
- «Confirmar serie» desde isla/bloqueo = **abrir** la sesión; nunca escribir sets en la extensión.

#### Apple — Swift 6 / App Intents

- Títulos/flags/`AppEnum`: `let` / estáticos; evitar `var` mutables entre procesos.

#### Android / Wear

- Assistant: deep links `repera://…`; capabilities en el mismo XML de shortcuts.
- AppSearch: opt-in, solo catálogo público; borrar al logout; `setSchemaAsync` / `putAsync`.
- GPS: un owner de sesión; no preemptar; no interpolar al exportar GPX.
- Share/SEND: solo copiar a cache y navegar; OCR/GPX en UI autenticada (`SystemShareImport` / `ReperaShareInbox`).
- MediaSession / Now Playing: solo control de descanso/timer; nunca series ni Health.
- Live Activity `pushType: .token` + store local; push remoto solo con backend APNs autenticado.
- EventKit / CalendarContract: mirror write-only de `booked`; clear al logout.
- App Functions / Gemini: hasta estabilizar API, catálogo + shortcuts; navegación only.

| Plataforma | Preferir |
|---|---|
| iOS | SwiftUI, ActivityKit, App Intents, WorkoutKit preview/scheduler, UNUserNotificationCenter |
| watchOS | SwiftUI watch, Digital Crown, handGestureShortcut, HealthKit watch-owned donde ya exista |
| Android | Compose M3, Glance, WorkManager, AppSearch, App Actions XML |
| Wear OS | Compose for Wear, Tiles, Health Services |

Si la API no existe: alternativa oficial documentada o bloqueo externo explícito — no fingir disponibilidad.

## Fiabilidad, rendimiento y seguridad (auditoría 2026-11-04)

Fuente: `docs/RELIABILITY_SECURITY_AUDIT_2026_11_04.md`. Mantener estas invariantes:

### Rendimiento

- **Android:** no parsear `app_state.json` / Health Connect en main desde Compose; `Dispatchers.IO` + caché; R8 + shrinkResources; `collectAsStateWithLifecycle`; `key` estable en Lazy lists.
- **iOS:** GPS/snapshots grandes en Application Support (Data Protection); no invalidar toda `LiveActivityView` por cada fix GPS.
- **Relojes:** Ambient con ticks lentos; GPS con `distanceFilter`; rutas por archivo/trozos; sensores solo cuando hacen falta.

### Bugs / sync móvil↔reloj

- Wear `live-start` ACK también con app en primer plano; resumen companion solo tras confirmación del teléfono.
- Sin doble escritura Salud/HC (Watch dueño → iPhone enlaza; Wear companion sin ExerciseClient de workout).
- Preferencias por cuenta (`ownerScope`); no adoptar legacy sin dueño.
- Session vacía por WatchConnectivity **no** cancela; solo evento terminal por id (`docs/watch-healthkit.md`).

### Seguridad

- Edge: secreto de cron obligatorio (fail closed); CORS allowlist; rate limit MCP; nunca `service_role` en cliente.
- Logs release sin OCR/salud/tokens.
- Monetización: sin snapshot ≠ Pro; compras en servidor cuando exista el camino.
- Monetización iOS: solo StoreKit 2 (`StoreKitEntitlementProvider`); sin RevenueCat.
  Sin snapshot Pro verificado → Gratis (fail-closed). Android: Play Billing.
- No migrar/desplegar Edge sin confirmación humana (`docs/SUPABASE_MIGRATION_RECONCILIATION_2026_11_04.md`).

### UX

- «**Center**» es nombre de producto (no «Centro»).
- Roots/subpáginas OG; Watch vía `WatchTheme`; Wear touch ≥ 48 dp y `strings.xml`.

## No hacer

- No asumir backend social.
- No meter API keys de LLM cloud para el escáner.
- No reintroducir «+ Plan» en la lista de ejercicios sin pedirlo.
- No reutilizar APIs de otra plataforma sin comprobar el SDK del target.
- No dejar Edge abiertas sin secreto de cron ni logs con OCR/PII en release.
