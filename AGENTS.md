# AGENTS.md — Repera

Última actualización: 2026-11-07.

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

#### Material alternativo y disponibilidad MCP (07/11/2026)

- Un array plano `required_equipment` es AND, no OR. No añadir ambas ramas ni
  vaciarlo para aparentar que «barra o mancuernas» está resuelto.
- Usar configuraciones OR de grupos AND; una máquina genérica no acredita una
  máquina asistida concreta. Alternativas y calentamientos comparten evaluador.
- Unificar alias de entrada no permite inferir aparatos. Probar ramas completas,
  incompletas, legacy y datos malformados; conservar filtros musculares/articulares.
- Código en main no equivale a migración/Edge desplegadas ni app instalada.


#### Catálogo App Store y botones de IA veraces (07/11/2026)

- Una pantalla de compra sin precios requiere distinguir StoreKit vacío/error (con reintento acotado, sin inventar importes) de derechos Pro firmados. Si TestFlight no recibe los productos, la disponibilidad territorial y comercial se revisa en App Store Connect; corregir Swift no activa productos no publicados.
- El texto «Continuar con ChatGPT/Claude/Grok» es engañoso cuando la app solo copia instrucciones. La UI debe reflejar disponibilidad real del catálogo y concesiones OAuth usadas; abrir la portada de un asistente no crea una vinculación.
- Claude debe abrir el formulario de conectores con cliente público PKCE; ChatGPT depende de ficha válida y revisión, Grok permanece en instrucciones manuales sin OAuth registrado. Mantener consentimiento del usuario y no escribir tokens/secretos en el chat.
- Los errores de red deben quedarse en logs diagnósticos sin mostrar CFNetwork/PostgREST en inglés; un fallo de carga no implica una lista vacía. Probar Android/iOS y estados vacío/pendiente/conectado/offline, además de CI y TestFlight real.
- Contrato: `tests/test_testflight_storekit_ai_reliability_contract.py`. Hasta ejecutar tests nativos y verificar Apple/Claude, no afirmar «compras/conexiones arregladas en producción».

#### StoreKit TestFlight y errores de red de IA (06/11/2026)

- Un `SKInternalErrorDomain 21` en `AppStore.sync()` no demuestra una compra caducada: primero consultar derechos **firmados** de `Transaction.currentEntitlements`, volver a consultarlos tras el fallo y presentar código técnico comprensible. No inventar Pro ni precios si Apple no devuelve productos.
- TestFlight usa productos App Store Connect/Sandbox, **no** el catálogo local `.storekit` de Xcode. Una suscripción Sandbox vencida y `Product.products(for:)` vacío son incidencias diferentes. El paywall debe ofrecer reintento y no pedir comprar si ya hay Pro.
- En IA, un fallo de `ai_access_tokens` **no** es una respuesta vacía. Solo mostrar «sin conexiones» tras lectura correcta; conservar configuración de proveedores ante fallo. La réplica best-effort de ejercicios no debe llenar la UI de errores internos.
- Contrato: `tests/test_testflight_storekit_ai_reliability_contract.py`. Ningún contrato sustituye la prueba de compra real en TestFlight ni las sesiones OAuth en dispositivo.



#### Comenzar — extracción Compose y eliminación completa de ramas (06/11/2026)

- Un único `LiveStartToolbar.kt` para mapa, métricas y deportes interiores. **No duplicar** la definición en `LiveActivityScreen.kt`; los tres lugares deben invocar el mismo componente. Evitar desajustes en el estado del botón central, la actividad y el candado.
- Al quitar el panel expandido, eliminar **ambas ramas** (`if expanded`) y sus delimitadores; una sustitución parcial puede dejar `LiveHeartRateZoneBar(bpm = bpm)` fuera de su ámbito e impedir compilar. Proteger con `tests/test_start_map_controls_contract.py` y comprobación de sintaxis, no solo inspección visual.
- Los jobs de GitHub Actions que terminan en segundos con `runner_name` vacío y `steps=[]` no demuestran que el código compile ni que los tests fallen: revisar primero disponibilidad de runners/logs y repetir compilación nativa cuando sea posible. No declarar paridad verificada por hardware.



Ampliar esta subsección cuando un fallo real enseñe algo nuevo.

#### Apple — XcodeGen y carpetas nuevas (GA4 / ReperaAnalytics)

```yaml
# ❌ BAD — solo existe en disco; un .xcodeproj antiguo omite Analytics/
# Apps/Repera/Sources/Analytics/ReperaAnalytics.swift
# → Cannot find 'ReperaAnalytics' in scope + type-check timeouts cascada

# ✅ GOOD — referencia explícita + exclude del scan + check script
# project.yml: - path: Apps/Repera/Sources/Analytics/ReperaAnalytics.swift
# scripts/check_xcode_sources.py REQUIRED + tests/test_xcode_sources.py
```

```yaml
# ❌ BAD — RemoteExerciseArtCache.swift en disco; .xcodeproj viejo no lo compila
# → Cannot find 'RemoteExerciseArtCache' in scope (ExerciseArt.swift)

# ✅ GOOD — exclude + path explícito (igual que RemoteExerciseCatalogStore)
# project.yml: - path: Apps/Repera/Sources/RemoteExerciseArtCache.swift
# scripts/check_xcode_sources.py REQUIRED + tests/test_xcode_sources.py
```

```yaml
# ❌ BAD — SessionDetailSkeleton.swift en disco; scan/XcodeGen viejo no lo compila
# → Cannot find 'SessionDetailSkeleton' in scope (HistoryView.swift)

# ✅ GOOD — exclude + path explícito + REQUIRED
# project.yml: - path: Apps/Repera/Sources/SessionDetailSkeleton.swift
# scripts/check_xcode_sources.py REQUIRED + tests/test_xcode_sources.py
```

- Tras añadir Swift en subcarpeta nueva **o archivo Swift nuevo en Sources/**: `xcodegen generate` y `python3 scripts/check_xcode_sources.py`. No «partir» vistas gigantes por type-check hasta confirmar el símbolo en Compile Sources.

#### Apple — XcodeGen scripts + User Script Sandboxing (dSYMs Archive)

```yaml
# ❌ BAD — `path:` incrusta el .sh en pbxproj (Archive ejecuta copia vieja).
# ❌ BAD — exec directo de PROJECT_DIR/scripts/*.sh sin inputFiles
#          → bash: … Operation not permitted → PhaseScriptExecution nonzero

# ✅ GOOD — declarar el .sh como inputFile + soft-fail (post-action Archive es el pase fiable)
# postBuildScripts:
#   - script: |
#       /bin/bash "${SCRIPT_INPUT_FILE_0}" || exit 0
#     inputFiles:
#       - $(SRCROOT)/scripts/embed_ios_archive_dsyms.sh
```

- Tras cambiar el wiring: `xcodegen generate`. Contrato: `tests/test_embed_ios_archive_dsyms.py`.

#### Apple — Microbenchmarks en CI (ExerciseSearch)

```swift
// ❌ BAD — umbral 3.0 ms en mediana; runners compartidos fallan ~3.3 ms
XCTAssertLessThan(medianMs, 3.0)

// ✅ GOOD — presupuesto ≤5 ms tras warm-up + mediana de lotes (PR #223)
XCTAssertLessThan(medianMs, 5.0)
```

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

#### Apple Watch — confirmationDialog / contextMenu (hub plan)

```swift
// ❌ BAD — watchOS 26 Liquid Glass: toques del diálogo no llegan (plan no arranca)
.confirmationDialog("Iniciar plan", isPresented: $show) {
    Button("Entreno guiado") { play() }
}

// ❌ BAD — overlay DENTRO de WatchHomeHubView + startToday() en el mismo toque
// → al mutar hub.active se desmonta el hub a mitad del callback → cierre inesperado
pendingPlan = nil; startToday(); play()

// ✅ GOOD — overlay en WatchSessionView (como cancelar actividad) + botones plain/cápsula
// + diferir el arranque un ciclo tras cerrar el overlay
.overlay { if let plan = pendingPlanStart { WatchPlanModeOverlay(...) } }
Task { @MainActor in await Task.yield(); startSelectedPlan(plan, ...) }
```

- Misma regla que `WatchActivityCancelOverlay`: no `.confirmationDialog` ni `.borderedProminent` para acciones críticas del hub.

#### Apple Watch — CLLocationManager.requestLocation (crash al iniciar plan)

```swift
// ❌ BAD — requestLocation() sin didFailWithError → abort en runtime
locationManager.requestLocation()
// Exception: Delegate must respond to locationManager:didFailWithError:

// ✅ GOOD — implementar siempre el fallo (como WorkoutLocationTracker en iPhone)
nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if (error as? CLError)?.code == .locationUnknown { return }
    Task { @MainActor in /* limpiar startLocationSessionID */ }
}
```

- `startToday()` / live indoor piden un pin con `requestLocation()`; el delegate debe responder al fallo o el Watch cierra al pulsar Entreno guiado/libre.

#### Apple Watch — WKApplicationDelegate `handle(_:)` (SDK watchOS 26)

```swift
// ❌ BAD — nombre antiguo; Xcode: 'handleWorkoutConfiguration' has been renamed to 'handle(_:)'
func handleWorkoutConfiguration(_ workoutConfiguration: HKWorkoutConfiguration) { … }

// ✅ GOOD — firma actual del protocolo (handoff startWatchApp desde iPhone)
func handle(_ workoutConfiguration: HKWorkoutConfiguration) { … }
```

- El hub interno puede seguir llamándose `handleWorkoutConfiguration`; solo el método del delegate usa `handle(_:)`.
- Contrato: `tests/test_watch_owned_live_home_contract.py`.

#### Apple — cáscara iPhone 0 kcal no gana al Watch

```swift
// ❌ BAD — finishWorkout se queda con existingReperaWorkout del iPhone (0 kcal en Fitness)
//         aunque el Watch tenga el HKWorkout real con FC/energía
savedUUID = owned.uuid  // phone shell

// ✅ GOOD — si phoneShell (Repera iPhone + 0 kcal), buscar Watch por ventana/ID
// y BORRAR la cáscara de Salud (si no, Fitness sigue mostrando «Repera / 0 KCAL»)
overlappingWorkout(..., watchOnly: true, expectedSessionID:)
_ = await deleteExternalWorkout(id: owned.uuid)
// Históricos: deleteOrphanPhoneShells + repairPastHealthKitExports al arrancar
```

- Fitness con «Repera / 0 KCAL / FC 134» = cáscara iPhone; la FC puede venir de muestras del intervalo, no de kcal del workout.
- No inventar kcal si Salud tiene 0 de verdad.
- Outdoor Watch: `HKWorkoutRouteBuilder` en watchkitapp (el iPhone no puede adjuntar ruta a un workout del Watch). Wear outdoor: `routePoints` en live-save + HC `ExerciseRoute`.

#### Apple Watch — Comenzar desde iPhone: companion finish + controles (06/11/2026)

```swift
// ❌ BAD — live.phase == .review con solo companionSensorID → health.discard()
// → Fitness «Repera / 0 KCAL»; el Watch nunca guarda energía

// ❌ BAD — sendLiveCommand exige isReachable; el espejo llega por context
// pero pausa/finalizar fallan («lo veo en el reloj pero no controlo»)

// ❌ BAD — handoff live sin pendingPhoneHandoff; startWatchApp arranca otro UUID
// ❌ BAD — companion startLive(..., outdoor: false, mirrorsToPhone: false)
// ❌ BAD — startWatchApp woke=true pero mirroring lento → beginWorkout iPhone 0 kcal
// ❌ BAD — sync/Guardar con watchHealthKitPending escribe finishWorkout del iPhone

// ✅ GOOD — finishCompanionHealthIfNeeded en .review (phoneOriginated o companion)
// ✅ GOOD — transferUserInfo + sendMessage opcional; espejo local de pausa
// ✅ GOOD — pendingPhoneHandoff + adoptPhoneLiveHealthOwnership (mismo UUID)
// ✅ GOOD — startLive(..., outdoor: sport.usesGPS, mirrorsToPhone: true)
// ✅ GOOD — si woke Watch: healthOwnedByWatch / pending; waitForVerifiedWatchWorkout
// ✅ GOOD — late handoff al volver reachable; deleteOrphanPhoneShells también por solape
```

- Contratos: `tests/test_watch_live_sync_contract.py`, `tests/test_health_fitness_parity_contract.py`.

#### Android / Wear — companion flush kcal + comandos duraderos (06/11/2026)

```kotlin
// ❌ BAD — syncCompanionSensors: remove(companionLiveSessionId) y luego stop
// → publishCompanionHeartRate no envía; teléfono guarda sin wearTotalEnergyKcal

// ❌ BAD — live-command solo MessageClient con nodes vacíos → fallo inmediato

// ✅ GOOD — flushCompanionMetrics → stop → luego clear companion id
// ✅ GOOD — finish live-command incluye totalEnergyKcal; listener accept() antes de finish()
// ✅ GOOD — pendingLiveCommands + flushPendingLiveCommands en onStart
```

- Contrato: `tests/test_android_wear_health_metrics_contract.py::test_companion_flush_metrics_before_stop_and_durable_commands`.

#### Apple — kcal Watch: no quitar `totalEnergyBurned`

```swift
// ❌ BAD — solo statistics; tras sync iPhone a menudo nil → chip «—»
workout.statistics(for: activeEnergy)?.sumQuantity()

// ❌ BAD — llamar la propiedad Swift (deprecada iOS 18 / watchOS 11 → warning)
workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())

// ✅ GOOD — statistics + totalEnergyBurned vía KVC (sin warning; PR b3b6e06)
[statisticsKcal, workout.value(forKey: "totalEnergyBurned") as? HKQuantity].compactMap …
```

- Tras editar horario: no poner `appleActiveEnergyKcal = nil` en el save; rehidratar y **solo sustituir si hay medición**.
- Contrato: `test_watch_energy_uses_total_energy_burned_fallback`.

#### Apple Watch / Wear — indicador kcal siempre + sensores

```swift
// ❌ BAD — ocultar kcal con «—» y dataSource por defecto (crossTraining a veces sin energía)
value: hub.measuredEnergyKcal.map { … } ?? "—"

// ✅ GOOD — UI con 0 hasta que llegue la muestra; forzar colección
var displayedEnergyKcal: Double { health.kcal ?? 0 }
dataSource.enableCollection(for: energy, predicate: nil)
```

```kotlin
// Wear: displayedEnergyKcal() + pedir CALORIES_TOTAL y CALORIES
add(DataType.CALORIES_TOTAL); add(DataType.CALORIES)
```

#### Apple Watch — tipos HealthKit de Comenzar = iPhone

```swift
// ❌ BAD — Watch mapeaba CrossFit/HYROX a HIIT; iPhone usa crossTraining
case .hiit, .hyrox, .crossfit: .highIntensityIntervalTraining

// ✅ GOOD — misma tabla que LiveSport.healthType en iPhone (53 deportes)
case .crossfit, .hyrox: .crossTraining
case .hiit: .highIntensityIntervalTraining
```

- Plan Watch/iPhone con WOD → `crossTraining`; solo fuerza → `traditionalStrengthTraining`.
- Alinear tipos **no reescribe** `HKWorkout` históricos; `HealthMuscleMapper.matchesRecordedHealthType` acepta alias legacy al deduplicar.
- Contrato: `tests/test_watch_hub_contract.py::test_watch_crossfit_healthkit_type_matches_iphone`.

#### Apple — Live Activities / intents

- `LiveActivityIntent` solo **encola** (`UserDefaults` + notificación en `@MainActor`); la app aplica tras hidratar identidad. `perform()` suele ir en background: sin hop a main, SwiftUI avisa «Publishing changes from background threads».
- «Confirmar serie» desde isla/bloqueo = **abrir** la sesión; nunca escribir sets en la extensión.

#### Apple — Swift 6 / App Intents

- Títulos/flags/`AppEnum`: `let` / estáticos; evitar `var` mutables entre procesos.

#### Android — splash no espera catálogo/fromBytes (06/11/2026)

```kotlin
// ❌ BAD — restoringSession=true durante prepareAccountDataAfterAuth (red + StateOverview.fromBytes)
// → LaunchSplashScreen eterno en emulador; Inicio nunca aparece
prepareAccountDataAfterAuth(id) { current() } // dentro del try, splash aún visible

// ✅ GOOD — tras profile + sesión verificada, bajar splash y hidratar después
profile = GoogleProfile(...)
restoringSession = false; busy = false
prepareAccountDataAfterAuth(id) { current() }
```

- Contrato: `tests/test_android_launch_splash_contract.py`.

#### Wear OS — tipografía Material3 sin `headline*` (06/11/2026)

```kotlin
// ❌ BAD — phone M3 tokens; Wear Compose Material3 1.7 no tiene headline*
MaterialTheme.typography.headlineMedium

// ✅ GOOD — escala Wear: display* / title* / label* / body* / numeral*
MaterialTheme.typography.displayMedium
```

- Cascada típica: `Unresolved reference 'headlineMedium'` + `Cannot infer type for type parameter 'R'` en el `?.let`.
- Contrato: `tests/test_wear_typography_contract.py`.

#### Android / Wear — Pro B2B naming (CI 2026-11-04)

```kotlin
// ❌ BAD — `var businessSponsoredAccess by mutableStateOf` genera setBusinessSponsoredAccess
//         y choca en JVM con el método homónimo (Platform declaration clash).
var businessSponsoredAccess by mutableStateOf(false)
fun setBusinessSponsoredAccess(enabled: Boolean) { … }

// ✅ GOOD — backing privado + val de lectura; método = mismo nombre que iOS
private var businessSponsoredAccessState by mutableStateOf(false)
val businessSponsoredAccess: Boolean get() = businessSponsoredAccessState
fun setBusinessSponsoredAccess(enabled: Boolean) { … }
```

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
