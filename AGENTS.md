# AGENTS.md — Repera

Última actualización: 2026-11-11.

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

### Primera entrada / carga de páginas (obligatorio)

Al abrir un hub o pantalla pesada la **primera vez** (o tras cold start), la
transición de pestaña/navegación y el primer paint **no** deben competir con
oleadas de morphs, charts, parse SVG ni widen de Salud. Aplicar **siempre**
en iOS y Android (paridad):

1. **Gate de revelado:** no armar `playMetricReveal` / `ogMetricRevealPlay` /
   `LocalMetricRevealPlay` ni marcar `progressHubPlayed` en el primer frame,
   `remember {}`, `onAppear` vacío o mientras hay skeleton. Armar solo con
   contenido estable (snapshot listo) + ≥1 frame + ~160 ms.
2. **Plots después de números:** `ogChartReveal` / `progressChartReveal`
   esperan el gate; en 1.ª visita ~220 ms más. Solo máscara/transform
   (composite); sin layout por frame. Android: el delay/animación **solo**
   bajo el hub Progreso (`LocalProgressChartRevealActive`); fuera (Recuperación,
   fixtures JVM) pintar completo — el default `LocalMetricRevealPlay=true` no
   implica diferir.
3. **Morph barato:** iOS `numericText` / `OGMetricRevealText`. Android un solo
   `Text` + opacidad (`graphicsLayer` / `Animatable`) — **prohibido**
   `AnimatedContent` por métrica en hubs.
4. **IO / assets fuera del pico:** widen HK/HC, parse BodyMap/SVG, sync iCloud
   de rutas → `yield` / `withFrameNanos` (o equivalente) tras el primer paint.
5. **Comenzar:** idle sin tick 1 Hz (`TimelineView` periódico) ni
   `animateValueChanges` continuo; ticks/morph de dígitos solo en
   grabación/pausa (+ cuenta atrás 3-2-1).
6. **Reducir movimiento:** valores finales al instante.
7. Contrato: `tests/test_metric_reveal_contract.py` (+ chart reveal). Docs:
   `docs/FEATURES.md` (hub Progreso / números).

Nueva UI con números grandes o charts al entrar: reutilizar este patrón; no
inventar un segundo gate ni revelar «todo a la vez» en el fade de tab.

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

#### Wear — `wearMergeRecentSports` + test que rompe deploy (11/11/2026)
- Con teléfono vacío el merge debe devolver **solo** `local` (no inventar ids).
  Un test que esperaba `walking`+`running` con `phone=[]` falló
  `:wear:testDebugUnitTest` y bloqueó `android-native` / Play.
- Contrato: `tests/test_watch_hub_contract.py` +
  `WearMultiplePlansTest.mergeRecentSportsKeepsLocalOrderAndFillsFromPhone`.

#### Apple — «Missing package product» Supabase/GoogleSignIn/Firebase (11/11/2026)
- Con disco ~lleno, `xcodebuild -resolvePackageDependencies` deja
  SourcePackages a medias (zip Firebase/gRPC rotos o checkout de
  `firebase-ios-sdk` a medias → Xcode marca Missing package product).
- Fix: liberar espacio, borrar DerivedData `Repera-*` / SourcePackages
  corruptos, resolver de nuevo (opcional
  `-clonedSourcePackagesDirPath .spm-cache`, ya en `.gitignore`).
- No «arreglar» quitando productos de `project.yml`; el wiring SPM es correcto.

#### Watch — aviso «Salud no disponible / ya iniciado» en live (11/11/2026)
- `WatchHealthKitSession.startConfigured` no debe fijar `permissionIssue` si
  ya graba el **mismo** UUID (`workout != nil && workoutID == id`) o si el
  arranque async de ese UUID aún va en vuelo: handoff/snapshot/reintento =
  no-op silencioso. Si no, la UI live muestra un falso positivo aunque FC/kcal
  midan bien. Mensajes distintos solo para otro workout vivo o HK ausente.
- Contrato: `tests/test_watch_native_health_permission_contract.py`.

#### Watch / Wear — swipe Controles↔Now Playing + FC en Ambient (11/11/2026)
- Continuum **Controles ← Sesión → Now Playing**: L→R = Pausar/Finalizar; R→L = audio.
 No invertir otra vez sin actualizar docs y contratos.
- watchOS: `WatchSwipeControlSurface` + temporizador; Wear: pager 3 páginas
 `initialPage = 1` (live, plan, timer) + `WearNowPlayingPage` con
 `dispatchMediaKeyEvent` (sin `MEDIA_CONTENT_CONTROL` ni intents OEM).
- Always On / Ambient: **no ocultar** `WatchHeartRateZoneBar` /
 `WearHeartRateZoneBar`; atenuar y ralentizar como el resto. Contrato:
 `tests/test_watch_wear_swipe_ambient_hr_contract.py`.
- Controles = rejilla **2×2 iconos** (`WatchSessionControlsGrid` /
 `WearLiveControlsPage`): pause↔play · flag · **X roja** · audio.
 `cancel` Wear llega al teléfono (`runtime.discard`) o limpia watch-owned.
 Contrato: `tests/test_watch_wear_controls_grid_contract.py`.

#### Sueño / Recuperación — permisos de Salud ≠ flags locales (11/11/2026)
- Conceder «todo» en **Ajustes → Salud → Repera** (iOS) o en Health Connect
  (Android) **no** escribe `sleepEnabled`/`cycleEnabled`. Sin esos flags no
  se piden ni leen noches/ciclo; Progreso queda vacío aunque el SO tenga datos.
- iOS: `ensureSleepAnalysisEnabled` (sueño **y** ciclo) al entrar en
  Recuperación / Salud conectada; flag antes del panel HK. VFC/reposo/
  respiración/SpO₂ **no** usan ese flag (solo permiso HK).
- Android: misma trampa en `PrivateRecoverySettings`;
  `ensureAnalysisEnabledIfUndecided()` antes de `requestedPermissions` /
  `loadHealthToday` / onboarding HC. Respeta switch apagado si ya hubo
  decisión. Temperatura de muñeca sí va con `sleepEnabled`; VFC/reposo no.
- No confundir con «faltan 7 días de constantes». Contrato:
  `tests/test_health_permissions.py`.

#### Android — `ProgressTab` + wrap `ProvideMetricRevealPlay` (11/11/2026)
- Abrir `ProvideMetricRevealPlay {` alrededor de `ProvideLazyDragAutoScroll` /
  `LazyColumn` exige el `}` de cierre **antes** de los helpers top-level
  (`strengthInsightCopy`, cards, etc.).
- Un `}` extra al final del archivo (p. ej. tras `HeartZonesDemoCard`) no cierra
  el wrap: Kotlin anida todos los `private fun` dentro de `ProgressTab` →
  `Unresolved reference` en llamadas tempranas +
  `Modifier 'private' is not applicable to 'local function'`.
- Tras envolver: comprobar que `ProgressTab` cierra justo antes del primer
  helper; no equilibrar braces solo al EOF.

#### Progreso / Comenzar — jank 1.ª visita (11/11/2026)
- Incumplir **Convenciones UI → Primera entrada / carga de páginas** (gate
  ~160 ms, charts ~220 ms, sin `AnimatedContent`, idle sin tick 1 Hz) vuelve
  el morph + fade de tab + HK/HC + SVG = jank. No «arreglar» solo acortando
  fades del NavHost. Contrato: `tests/test_metric_reveal_contract.py`.
- `progressChartReveal` con `delay(220)` cuando `LocalMetricRevealPlay` es el
  default `true` (fuera de `ProvideMetricRevealPlay`) deja el clip en 0 y falla
  `ReviewSpacingRenderTest.readinessMultidayCurve` (píxeles de rejilla iguales).
  Diferir solo si `LocalProgressChartRevealActive` (armado en el provider del
  hub). Contratos: `test_progress_chart_reveal_contract.py`,
  `test_metric_reveal_contract.py`.

#### WOD — nombres cortos `displayName` vs tests legacy (11/11/2026)
- Acortar `WodFormat.displayName` (p. ej. `For Time`, `Escalera`) sin actualizar aserciones deja rojo
  `:domain:testDebugUnitTest` (`CatalogWodsTest.labelsMatchIosPresentation`) y, más tarde, JVM/instrumented
  que aún esperan `For Time / RFT` o cabeceras Wear `Ladder`.
- Al renombrar formatos: buscar `formatLabel` / `wodFormatName` / `WearBlockHeader` / `displayBlockHeader`
  y alinear iOS+Android en el mismo cambio; contrato `tests/test_wod_format_labels_contract.py`.
- Escáner → editor: el CTA de revisión es **Continuar** (no «Crear rutina»). Si no, falla
  `BoardClassicReviewRenderTest` en `:mobile:testDebugUnitTest` y no llega `deploy-internal-beta`.

#### Play / Crear-Editar — stutter al teclear y bloques gordos (11/11/2026)
- Escribir al store/`activeSession` en cada tecla invalida toda la lista. Debounce local (~250 ms)
  + flush al cambiar de ejercicio / disappear; drafts con `durable`/`pushWatch` selectivos.
  Con foco activo en Play iOS: no flush al store (reprogramar / volcar en `onChange(focus==nil)`
  y `onDisappear`); si no, el `List` puede tirar el teclado.
- Montar N editores Compose a la vez: Android un solo `expandedEntryId` y Lazy a nivel
  ejercicio (no solo por bloque). No poner `Equatable` en un `View` (MainActor): usar
  identidad Sendable + `.id(...)`.
- **iOS `OGSetNumericCell` / `OGFormatNumberField`:** lazy con `@State isArmed` +
  `pendingAutoFocus` (no solo `@FocusState`). Sin armar = `Text`/`Button`; al tocar
  monta `UITextField` y **sigue armado**. Un swap solo vía FocusState en Form/List
  no abría el teclado. Ambas ramas `.frame(height: 44)`. Pad Repera solo al editar
  (`ensureKeypadInstalled`). Montar N `UITextField` en el 1.er frame = scroll a
  trompicones / remeds de altura.
  **Primera entrada:** no sembrar catálogo/`plannedSets`/`Play.rows` solo en
  `onAppear`. Hidratar en `init` / `resolvedExerciseCatalog` + `compactIntrinsicHeight: 44`.
  **DayEditor iOS = Android `expandedEntryId`:** solo un ejercicio/movimiento monta
  la retícula de series; el resto muestra `compactSummary`. Montar todas las series
  en el Form al pulsar «Editar» (resumen → editor) bloquea la UI varios segundos.
  Diferir el push un `Task.yield` tras preparar la rutina. Abrir con el **primer**
  ejercicio expandido (Android y iOS). `StrengthExerciseSetsIdentity` **sin**
  `plannedSetIDs`/`previousTexts`: si no, «Añadir serie» remonta el isolator.
  Bloques `.strength` siempre usan `strengthBlock` (no `completedStrengthPrescription`).
- **`StrengthExerciseSetsIdentity` solo estructura** (`itemID`, `plannedSetIDs`, unidad, estilo…).
  Nunca meter `RoutineExercise` completo / `plannedSets` con peso·reps·RIR en el `.id`: cada
  `onCommit` por tecla remontaba el isolator, destruía `@FocusState` y el input «no dejaba
  escribir» (regresión perf v2, 11/11/2026). Los valores vivos van en `item:` aparte del `.id`.
- `navSig` con `completed` recreaba todos los `BlockDraftUi` al marcar series; firmar solo estructura.
  Logging de Play como ítem Lazy aparte.
- Contrato: `tests/test_play_editor_perf_v2_contract.py`. No afirmar «probado en dispositivo» sin medición.
- **Android editor:** `setsExpanded` arranca en `false` (Lazy). `toDraft()` solo emite
  `plannedSets` si `setsExpanded || untouchedUniform`. Con fila colapsada y quantity/sets/weight
  sucios → `plannedSets` del draft es `null` (ganan los campos uniformes); las series con
  ids/RIR siguen en memoria UI. No asumir el default antiguo `setsExpanded=true` en
  `RoutineEditorRestorationTest.plannedIdsRirAndUniformDirtyBaselineSurvive` (bloqueó
  `:mobile:testDebugUnitTest` y `deploy-internal-beta` el 11/11/2026).

#### Android — Play upload `RedirectMissingLocation` / httplib2 308 (10/11/2026)
- `deploy-internal-beta` puede fallar en *Publish AAB…* con
  `httplib2.error.RedirectMissingLocation` tras builds/tests verdes: el upload
  resumable de Play responde **308** sin `Location` («resume incomplete»).
- Causa: `httplib2` (a menudo el paquete del sistema del runner) trata 308 como
  redirect antes de que `googleapiclient` continúe el `MediaFileUpload`.
- Fix: `disable_httplib2_308_redirects()` en
  `android/scripts/upload_play_release.py` + `pip install --upgrade httplib2`
  en `android-native-ci.yml`. No es un bug de la app.
- Contrato: `android/scripts/test_upload_play_release.py`.

#### Android — Comenzar VerifyError R8 outliner / AGP 9.4.0 (10/11/2026)
- Release minificado con **AGP 9.4.0** puede crashear al abrir Comenzar:
  `java.lang.VerifyError` / `register vN has type Undefined but expected Integer`
  sobre la clase ofuscada de `LiveActivityScreen` (firma Compose con
  `onSavedAndEdit` + `autoStartAfterChoose`). No es un bug de UI ni de
  permisos MIUI (`FrameInsert`/`miuilog` son ruido del OEM).
- Causa: bug del **outliner de R8** (issuetracker `b/551348855`), corregido en
  **AGP ≥ 9.4.1** (también listado en 9.3.3). Mantener
  `android/build.gradle.kts` en 9.4.1+; no bajar.
- Debug/`minifyEnabled false` no reproduce el fallo. Tras subir AGP: regenerar
  AAB/APK release e instalar en dispositivo (no basta compileDebug).
- Contrato: `tests/test_android_r8_agp_contract.py`.
- **CI Play:** `android-native-ci.yml` en push solo `origin/beta` (no `main`).
  Deploy Play = job `deploy-internal-beta`. Contrato:
  `tests/test_android_wear_ci_disk_contract.py`.

#### Android — suite JVM completa y advertencias de Robolectric (10/11/2026)
- **Compilación verde no equivale a tests verdes**: `android-native` compila móvil/Wear y después ejecuta `:mobile:testDebugUnitTest`; una ejecución registró 814 tests y 60 fallos, agrupados en 31 clases. No eliminar aserciones ni excluir tests para acelerar la subida a Play.
- Eliminar `!!` solo porque Kotlin avisa puede romper la compilación cuando el tipo sigue siendo `String?`: usar `requireNotNull(value)` o una rama nula explícita, y compilar `:domain:compileDebugUnitTestKotlin` antes de darlo por corregido.
- Robolectric `AndroidInterceptors.FileDescriptorInterceptor` puede lanzar `IllegalAccessException` al acceder a `jdk.internal.access.SharedSecrets` en JDK recientes: configurar `--add-exports=java.base/jdk.internal.access=ALL-UNNAMED` para JVM de tests, sin añadirlo a APK/AAB.
- El catálogo virgen debe compararse mediante el digest canónico de **la versión realmente empaquetada** de `catalog_seed.json`; un digest obsoleto bloquea la reconciliación segura. Nunca flexibilizar la coincidencia ni descartar datos de usuario solo para hacer pasar la prueba.
- `tools:node="remove"` puede emitir avisos "no other declaration present" cuando la dependencia no solicita el permiso publicitario. Mantener las exclusiones y el contrato de permisos; no eliminarlas para silenciar logs. Los `.so` de terceros no despojados no implican error de compilación; diagnosticar con `--info` antes de cambiar el empaquetado.

#### Live Activity y fin Watch pedido en el iPhone (09/11/2026)

- No dar por aceptado un snapshot Watch antes de que ActivityKit cree la
  tarjeta. `watchMarks` con `capturedAt > mark.capture` bloquea el reintento
  del mismo dato si la marca se queda tras un `Activity.request` fallido.
  Revertir solo esa captura (`rollbackWatchDeliveryMark`); no pisar una marca
  más nueva ni una sesión `closed`.
- El reloj publica `.review` antes de `sendFinished`. Ese snapshot no puede
  hacer `clearWatchOwnedSportMirror` si el fin lo pidió el iPhone: Comenzar
  sigue hasta `persistAndFlush` y solo entonces Inicio. Borrar el UUID de
  `phoneRequestedFinish` antes del chequeo de 10 min quema la recuperación.
- Contratos: `tests/test_watch_live_activity_retry_contract.py`,
  `tests/test_watch_phone_finish_review_contract.py`.

#### Inicio — Descartar|Revisar Watch (09/11/2026)

- No ocultar solo con UserDefaults local: iPhone ≠ simulador y el ack no
  viaja por iCloud. Descartar/Revisar debe poner `awaitingResultEntry = false`
  en el entreno (`clearAwaitingResultEntry`).
- La fila solo mira `awaitingResultEntry` (no `watchHealthKitPending` solo):
  el pending de HK puede durar y reabrir la card tras un ack local perdido.
- `onAppear` de Inicio: `formUnion` de dismissals, nunca sustituir por un set
  vacío si `ownerScope` aún no está listo.
- Contrato: `test_home_review_actions_clear_awaiting_result_entry_durably`.
- Android (paridad): `return@paramName` en un lambda de parámetro nombrado
  (`onAcknowledgeWatchReview = { … }`) es «Unresolved label». Usar label
  explícito (`acknowledge@{ …; return@acknowledge }`), como `sendChat@` /
  `loadThread@` en `MainActivity`. `var x by remember { mutableStateOf(…) }`
  exige `import androidx.compose.runtime.getValue` + `setValue` (FQN de
  `remember`/`mutableStateOf` no basta).

#### Apple — `Self.` en init de stored property + atributos sueltos (09/11/2026)

- En un inicializador de propiedad almacenada, `Self.staticMember` falla:
  «Covariant 'Self' type cannot be referenced from a stored property
  initializer». Usar el nombre de tipo (`WorkoutLiveActivityCoordinator.watchMarksKey`)
  o un literal; no «arreglar» con `Self.`.
- No insertar un método nuevo entre `@discardableResult` / atributos y la
  función a la que pertenecen: el atributo se pega al siguiente `func` (p. ej.
  recovery `requestWatchOwnedLiveSnapshot` Void robó el `@discardableResult`
  de `sendWatchOwnedLiveCommand` → Bool).
- Extensiones de protocolo con default vacío: siempre `func …() {}`, nunca
  solo la firma (rompe el build Watch).
- Contratos: `tests/test_watch_owned_live_home_contract.py`.

#### Charts — ForEach por índice sin dejar `point` (09/11/2026)

- `ChartContentBuilder` no tolera bien destructuring de tuplas en el closure
  (`ForEach(days) { point in` / `(date, minutes)`). Preferir
  `ForEach(days.indices)` + `let day = days[index]`.
- Al migrar, actualizar **todos** los marks (`AreaMark` y `LineMark`). Dejar
  `point.date` tras quitar el parámetro provoca «Cannot find 'point'» y a
  menudo «unable to type-check this expression».
- Contrato: `tests/test_strength_visual_contract.py::test_recovery_has_daily_line_and_pro_gate`.

#### Conecta tu IA — desactivar / abrir / borrar (08/11/2026; sheet manual 10/11/2026)

- En Form, **Button** dentro de `VStack` se promociona a filas sueltas; el swipe
  full puede desincronizar el Form. Usar Text+`onTapGesture`; `allowsFullSwipe: false`.
- Hub sin «Solo instrucciones» ni pie largo: Continuar lleva el prompt al chat (`?q=`).
- Desactivar izq. / Abrir der.; swipe → Edge `…/delete`. Contrato: `test_ai_provider_launch_contract`.
- **Conexión manual** = 4.º botón en «Elige tu asistente» → sheet (no fila
  aparte ni DisclosureGroup); sin copy «Usa tu asistente…» / «Para asistentes…»;
  URL pública `https://repera.app/mcp` + copiar tras el toggle de escritura;
  «Crear token» gris hasta ≥3 letras. Ajustes/IA ocultan el menú principal.
- **Android FC máxima:** no usar `runWorkoutAction`/`busy` para ±; persistencia
  optimista (`persistTrainingSettings`) o el stepper bloquea todo Ajustes.

#### Material / ordenación biblioteca (08/11/2026)

- `ExerciseEquipmentGroup`: el **primer chip** de `equipment` gana; el nombre
  solo infiere si el equipo es genérico (`Peso corporal` / `Máquina` / vacío).
- No usar `contains("mat")` suelto: «neumático» acababa en Colchonetas. Token
  seguro (`isMatEquipment`) + grupo `Neumáticos`.
- Back lever tuck → `Anillas` (familia German hang); Couch stretch → `Pared`
  (banco solo en coaching). Dominadas colgadas → `Barra de dominadas`, no `Barra`.
- Contratos: `ExerciseEquipmentGroupTests`, `tests/test_equipment_symbol_contract.py`.
  Migración remota: `20261108200000_fix_material_grouping_equipment.sql`.
- `business_exercise_catalog` **no** tiene `updated_at` (sí `training_exercise_metadata`).
  Un `SET …, updated_at = now()` en el catálogo rompe `db push` (42703). Solo
  tocar `mobile_equipment` ahí.

#### Strength benchmarks remoto (09/11/2026)

- Esquema + seed en Supabase Repera (`strength_benchmark_*`, 1132 filas:
  914 OPL nov-2026 + 218 SS / 14 lifts).
- UI de **Rendimiento**: `StrengthBenchmarkRemoteStore` desde Supabase
  (bootstrap/delta); JSON bundle solo offline. Resolver de lifts gym (SBD +
  front/sumo/OHP/etc.); sin lift o sin cohorte → no inventar Pxx.
- Aportes Amateur: siempre activos al guardar 1RM → RPC
  `submit_strength_benchmark_contribution` (bandas, rate limit, sin user id en
  inbox; sin toggle en Ajustes). Agregar con
  `strength_benchmark_aggregate_contributions` (service_role). Motor: ante
  empate de cohorte, preferir más muestras / revisión más nueva. UI
  Rendimiento: máx. 1RM/e1RM + última marca (azul); verde si coinciden.

#### Material alternativo y disponibilidad MCP (07/11/2026)

- Un array plano `required_equipment` es AND, no OR. No añadir ambas ramas ni
 vaciarlo para aparentar que «barra o mancuernas» está resuelto.
- Usar configuraciones OR de grupos AND; una máquina genérica no acredita una
 máquina asistida concreta. Alternativas y calentamientos comparten evaluador.
- Unificar alias de entrada no permite inferir aparatos. Probar ramas completas,
 incompletas, legacy y datos malformados; conservar filtros musculares/articulares.
- Código en main no equivale a migración/Edge desplegadas ni app instalada.


#### StoreKit TestFlight y errores de red de IA (06/11/2026)

- Un `SKInternalErrorDomain 21` en `AppStore.sync()` no demuestra una compra caducada: primero consultar derechos **firmados** de `Transaction.currentEntitlements`, volver a consultarlos tras el fallo y presentar código técnico comprensible. No inventar Pro ni precios si Apple no devuelve productos.
- TestFlight usa productos App Store Connect/Sandbox, **no** el catálogo local `.storekit` de Xcode. Una suscripción Sandbox vencida y `Product.products(for:)` vacío son incidencias diferentes. El paywall debe ofrecer reintento y no pedir comprar si ya hay Pro.
- En IA, un fallo de `ai_access_tokens` **no** es una respuesta vacía. Solo mostrar «sin conexiones» tras lectura correcta; conservar configuración de proveedores ante fallo. La réplica best-effort de ejercicios no debe llenar la UI de errores internos.
- Contrato: `tests/test_testflight_storekit_ai_reliability_contract.py`. Ningún contrato sustituye la prueba de compra real en TestFlight ni las sesiones OAuth en dispositivo.

#### Debug Pro Free y espejo Watch→iPhone (08/11/2026)

- Simular «Gratis» en Debug Pro **no** puede pasar por el hold de `verifiedPro` (`.free` transitorio de StoreKit). Con `overrideEnabled`, forzar el snapshot debug y limpiar la caché; al apagar, restaurar `StoreKitEntitlementProvider`. La UI del picker no es `isPro`: mostrar «Efectivo» (Center patrocinado sigue OR-eando Pro).
- No usar `#else let flag = false` y luego `if !flag else`: en Release el compilador pliega el flag y marca el `else` («will never be executed» / condition always true). La limpieza de caché va solo en `#if DEBUG`. Con `status == .free`, `grantsProAccess` ya es falso: no volver a comprobarlo.
- Contratos: `tests/test_debug_pro_simulation_contract.py`. Android ya aplicaba el override tras el merge.
- Watch→iPhone: deporte Watch-owned → `LiveActivityRecorder.adoptWatchOwnedSportMirror` + misma `LiveActivityView` (no `WatchOwnedLiveMirrorView` de cards). Plan sigue en espejo. Postear `repera.openComenzarFromWatch`. Sin persistir snapshot phone ni segundo HK/GPS. Hub Watch: no `.offset(y: +N)` hacia el bisel; `padding(.bottom)`.
- Material AbMat/parallettes/etc.: ampliar `equipmentSymbol` iOS+Android + grupo `AbMats`; contrato `tests/test_equipment_symbol_contract.py`.
- Chips de equipo: nunca Title-Case palabra a palabra de frases ExerciseDB. Usar `ExerciseEquipmentDisplay.chips` («Colchoneta o superficie…» → `Colchoneta`; tirar «variante C»). Holds de suelo (Arch/Hollow/Candlestick) = `Colchoneta`. Remoto: migración `20261108190000_colchoneta_floor_holds_equipment.sql` (no desplegar sin confirmación).



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
| Android | Compose M3, WorkManager, AppSearch, App Actions XML |
| Wear OS | Compose for Wear, Tiles, Health Services |

Si la API no existe: alternativa oficial documentada o bloqueo externo explícito — no fingir disponibilidad.

## Fiabilidad, rendimiento y seguridad (auditoría 2026-11-04)

Fuente: `docs/RELIABILITY_SECURITY_AUDIT_2026_11_04.md`. Mantener estas invariantes:

### Rendimiento

- **Android:** no parsear `app_state.json` / Health Connect en main desde Compose; `Dispatchers.IO` + caché; R8 + shrinkResources; `collectAsStateWithLifecycle`; `key` estable en Lazy lists.
- **iOS:** GPS/snapshots grandes en Application Support (Data Protection); no invalidar toda `LiveActivityView` por cada fix GPS.
- **Relojes:** Ambient con ticks lentos; GPS con `distanceFilter`; rutas por archivo/trozos; sensores solo cuando hacen falta.
- **Primera entrada a hubs:** ver **Convenciones UI → Primera entrada / carga de páginas** (gate de revelado, charts diferidos, morph barato, sin IO en el pico del fade).

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
