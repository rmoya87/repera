# Read ledger: Apple window fc3ef7e1..refs/ghlive/main (bd4d7637), non-test, non-Packages files
Baseline for every row: `git diff fc3ef7e1 refs/ghlive/main -- <file>`. "Evidence" is the section of PARITY_DELTA_APPLE_FC3EF7E1.md that states the read. This ledger was built from those section headings and sentences at 08:2x CET; it does NOT re-verify that each read was complete. "Read" = a doc section says the diff was read; "partial" = a section covers a slice or a mapping only; "none found" = no doc section names a read.
Correction: tree156 listed LibraryView and WorkoutView as unread. That list was stale. Evidence says both were read (below); no re-read is needed.

| File (diff lines) | Status | Evidence |
|---|---|---|
| LibraryView (162) | read fully, static | tree125 |
| WorkoutView (250) | read fully, static | tree125/128 Play rows assessment ("WorkoutView diff, read fully") |
| Theme (50) | read, static | tree113, tree128 |
| StatsView (98) | read, static | tree113 |
| BusinessWorkoutSyncStore (21) | read, static | tree113 |
| DayOverrideSheet (37), RegisterSessionChrome (30) | read, static | tree113 |
| HealthRecovery (151) | read, static | tree109 (loading-state condition not compared) |
| MuscleBalanceCard (21), ProgressSnapshot (41) | read, static | tree109/110 |
| ProgressTrendCards (89), ProgressChartBuilder (29) | read, static | window diff note near line 2144 |
| QuickLogSheet (342) | read, static | tree123/124 |
| PlanView (549) | read, static | tree143 plus earlier PlanView sections |
| HomeView (211) | read, static | tree144 (four Home points still open) |
| CardioRouteComponents (270) | read, static | tree137 |
| HealthKitStore (258) | read, static | tree138 |
| HealthMuscleMapper (75) | read fully, static | tree162 (full diff re-read; below) |
| SessionPreviewView (7), StartHubSheet (1) | read (tiny), static | tree106 |
| HistoryView (534) | read fully, static | tree115, tree132, tree159 (remaining ~400 lines read 2026-10-27 09:36; findings in tree159 section below) |
| LiveActivityView (782) | read fully, static | tree132-135, tree160 (full 1087-line diff re-read 2026-10-27 09:38; findings below) |
| ReperaStore (406) | read fully, static | tree161 (full 590-line diff re-read 2026-10-27 09:40; audit below) |
| BusinessAuthStore (90) | read fully, static | tree162 (full diff re-read 2026-10-27 09:41; below) |
| LiveSportHistoryView (34) | read, static | tree156 |
| ActivityHeatmapView (21) | read fully, static | tree162: only change is strip cellHeight cap (below) |
| SettingsView (48), ReperaApp (30) | read, static | tree158 |
| DayPlusSheet (1), DigitalClockDisplay (5), RegisterSwipeRevealCard (2), ReperaNowPlayingBar (4) | read (tiny), static | tree159: cosmetic/comment-only diffs, no Android behavior (details below) |
| BusinessAuthStore/Sync, workflows, README, docs/* | workflows excluded by instruction; docs not read as parity targets | |

Not covered by this ledger: the 579 commits older than fc3ef7e1 (only the 37837401 historical matrix) and Packages/ (domain Swift sources; the three Apple domain test files were read tree147/149/151-154, the Swift sources diff is not mapped line by line).

Pending reading kept (per parent, 08:26): Packages/ Swift sources not mapped line by line, the 579 older commits (37837401 matrix only), and the four 1-5 line files (done tree159).

## tree159 (2026-10-27 09:36 CET, reconstructed sandbox): HistoryView rest + 4 tiny files

Reading only; "read" is not parity validation. Full diff re-read: `git diff fc3ef7e1 bd4d7637 -- Apps/Repera/Sources/HistoryView.swift` (804 diff lines) and the four tiny files.

Tiny files: DayPlusSheet drops a 4pt top padding; DigitalClockDisplay changes a comment; RegisterSwipeRevealCard VStack spacing 2->0; ReperaNowPlayingBar is a new intentionally EMPTY file (Apple removed its Now Playing bar entirely). No Android behavior to port; Android never had a Now Playing bar.

HistoryView behavioral findings vs Android (mobile/src/main/java/dev/repera/mobile):
1. Fullscreen interactive map from history previews (WorkoutMapZoomDestination: tap preview -> push with zoom transition, close X top-right, pan/zoom/rotate, scale view, no compass; used by both WorkoutDetailView and HealthActivityDetailView). Android: NO fullscreen map (grep: no match). OPEN.
2. WOD previous-format results: Apple groups saved wodResults by blockId, shows current-format score first and other formats as "Resultado de formato anterior" cards. Android preserves the data (JVM tests tree150-154) but does NOT display historical-format results (grep: no match). OPEN.
3. Unified "Entreno" card: one card with CardioSplitsView (now fed totalActiveSeconds, totalDistanceMeters, maxSpeedKmh, healthStats, sport, embedded) + HealthSessionMetricsCard embedded, single header. Speed stats REMOVED from the heart-rate stat row (they live in the splits card now). Android still shows separate SessionSportMetricRow/LiveKilometerSplitsSection/SessionRangeTiles and no unified card; maxSpeedKmh from health extras not fed into splits. OPEN (was "card unificada NO port"; this confirms Apple's target shape).
4. After saving an edited session Apple re-resolves health extras by stable UUID (date/time edits change the Health window; old FC/route not recycled). Android ExercisesTab detail loads the heart series with produceState keyed only on session id, so a date/time edit leaves stale health data until re-entry. OPEN (minor).
5. External health detail: Apple added stepsCount, movementDistanceMeters/Label, movementUsesTimeWindow into SessionExtras. Android ExternalHealthDetailSheet shows no steps/movement fields (grep: no match). OPEN (known: steps fields existed but were never compared).
6. Route map rendering: Apple now draws 3 layers per segment (17pt glow at 20% + 10pt white-gradient border + 5pt color core) over a dark backdrop polygon, interactive mode adds rotate, compass removed. Android RouteMapView draws a single 4f line per segment (per-segment speed color already matches the new 4-stop gradient, water variant included). Visual-only gap. OPEN (low priority, MapLibre layers).
7. RouteUnavailableNotice: ported and condition matches (usesGPS && meters>0 && <2 route points). Minor divergence: Apple only shows it when there is no location pin either; Android applies() does not check the pin. Edge case noted, not fixed.
8. Purely iOS cosmetics with no Android action: date subtitle moved to an exterior section header, summaryTile extracted to shared WorkoutSummaryTile, HR chart 140->170pt, ogCardListRow padding tweaks, "Colores = velocidad" footer removed (Android never had it).

Window extension pending: origin/main advanced past bd4d7637 (inventoried 2026-10-26 17:28). 21 new commits seen 2026-10-27 09:34 (weighted walking lunges reps/meters, scanner distance parsing, topbar/scroll fixes, BTT T2B snapshot relinks). NOT yet inventoried for parity; extends the user's 3-day review request.

## tree160 (2026-10-27 09:38 CET): LiveActivityView window diff fully read

`git diff fc3ef7e1 bd4d7637 -- Apps/Repera/Sources/LiveActivityView.swift` (1087 diff lines). Reading only, not parity validation.

Already ported (verified in android/ sources): the 21 new LiveSports with groups "Combate"/"Cardio y gimnasio", isSelectable=true for all (gravel/other as fallback), healthKey mapping, isWaterSport, km and turn spoken copies (LiveSpokenPhrases/LiveGPX match the new wording including "cambia de sentido" >145 deg and "Ahora, ..." <=20 m), km queued behind turns, voice-on => never notifications even when speech fails, voice-off => optional background visual notice, audio focus released only when the queue drains.

OPEN gaps found:
1. Live recording trace color: Apple's LIVE trace palette differs from the history map: land slow stop is BLUE (0.06,0.39,0.98), water is (0.08,0.72,0.31); both go yellow->orange->red. Android reuses RouteMapModel.speedColor (green slow stop for land) for the live trace. Small pure-function port pending.
2. Live save flow: Apple re-queries Health at save time if the preview read has not finished, and when an external (Apple Watch) workout matches it stores healthKitWorkoutUUID + appleActiveEnergyKcal + appleAverageHeartRateBpm + appleHealthProvenance="healthKitExternal" on the session. Android saveLiveActivity is idempotent by session id and archives the GPX route, but never links Health Connect at save (no healthRecordId/provenance/kcal/HR). OPEN.
3. Save double-invocation: Apple disables Guardar while isSavingRecordedActivity (async health query). Android save is synchronous and idempotent, but the button is not disabled during save. Minor.
4. Live screen restructure (Compose work, not started): pause (yellow)/resume (green)/finish (black) circular buttons moved into the map header and a metrics trailing row (order Audio, Map, Resume, Finish, growing left); discard "xmark" removed from active headers; bottom controls emptied during recording/paused/review; landscape adaptive layout (width>height && width>=620, side column min 260 max 390 or 42%); navigation banner restyled (larger type, OG.accent background, black text); metrics idle controls top-left max 360; review uses the same unified "Entreno" card (CardioSplitsView with totals + maxSpeedKmh + healthStats + sport, embedded) and fullscreen map zoom; "Recorrido sin puntos GPS" copy now "La distancia y los parciales se conservan aunque no haya puntos para dibujar el mapa."; summary tiles via shared WorkoutSummaryTile; safe-area padding for map overlay.
5. Android LiveActivityScreen is a single-column layout with text buttons (Pausar/Reanudar/Finalizar/Descartar) - far from the Apple structure; the DUO/landscape layout is also missing (was "PlanDUOtopbar abierto").

## tree161 (2026-10-27 09:40 CET): ReperaStore window diff fully read + Android audit

`git diff fc3ef7e1 bd4d7637 -- Apps/Repera/Sources/ReperaStore.swift` (590 diff lines). Reading only.

Apple rules in the window and Android status:
1. persistWorkouts also pushes an independent mirror sync after local persist. Android: mirror push happens at action level (runWorkoutAction incl. onUpdateFinishedWorkout, Wear session finish, sign-in/restore), not inside persist. Effect equivalent for user-driven saves; structural difference only. OK.
2. startSession and scan start guard: no new session/scan while another is active. Android: ported ("Ya existe una sesión activa" checks in WorkoutRepository). OK.
3. Diary no longer falls back to weekday-recurring routine for a date. Android: STILL has the weekday fallback (WorkoutRepository today-assembly line ~1757). Tied to the legacy-weekday migration decision (A/B pending user authorization); not changed unilaterally.
4. Scan import never merges blocks into an existing same-day routine; each scan is an independent session. Android: scan import creates independent dated routines (tree146). OK.
5. refreshActiveSessionPlan: relink by item identity only; legacy block+name fallback gated on a SESSION-LEVEL flag (legacyIdentity = no remaining exercise id appears in the session's own routineBlocks). Android ActiveSessionPlan.refresh matches by id first, but its fallback is PER-ITEM (id not in the fresh plan) and does not carry adaptedReps/adaptedWeightKg. TWO divergences -> fix in tree161.
6. Edit save: appleDurationSeconds derived from corrected times ONLY when healthKitWorkoutUUID is nil; with a Health link the measured duration is preserved. Android updateFinishedWorkout recomputes appleDurationSeconds unconditionally when start+end known. DIVERGENCE -> fix in tree161.
7. Health link after manual time correction no longer overwrites startedAt/finishedAt. Android setHealthRecordId only writes the link field, never times. OK.
8. normalizedFinishedWorkout marks ALL exercises isCompleted on finish/save (iPhone, Watch, import, old edits). Android: KNOWN open divergence (finish only marks logged; edit clears flags) - recorded before, still open (behavior change, needs its own port decision).
9. saveRoutine: same-day duplicates allowed; weekday->this-week-date compat shim for legacy emitters; isLibraryTemplate requires both dates nil. Android: same-day duplicates ported (tree146); weekday->dated compat shim NOT verified for AI/import emitters. OPEN question.
10. clearWeeklySchedule(for weekReference): only the visible week; dated favorites unscheduled not deleted; no global weekday/rotation wipe. Android: KNOWN divergence - repo clear still removes legacy weekday+rotation globally. Open, tied to migration decision.
11. copyPreviousWeekSchedule snapshots occupied days BEFORE copying; copies never overwrite occupied days. Android: ported. OK.
12. assignRoutine(toDate) schedules an independent copy with duplicated content ids, template untouched, favorite=false. Android: ported (repo comment cites Apple assignRoutine(_:toDate:)). OK.
13. migrateLegacyWeeklyPlans: pins legacy weekday routines to THIS week's dates, keeps reusable templates with fresh content ids, idempotent, does not advance local revision before iCloud compare. Android: migration PREPARED WITHOUT CALLER, not activated (user decision pending). Correct to stay inactive.

## tree162 (2026-10-27 09:41 CET): BusinessAuthStore + HealthMuscleMapper + ActivityHeatmapView read fully

BusinessAuthStore (90 diff lines): requiresReauthentication semantics now fully mapped. It is an in-memory flag set ONLY on confirmed revocation (AuthError sessionNotFound/refreshTokenNotFound/userBanned), never on network failure; cleared on verified login, disconnect, and successful refresh/ensure. ensureUsableSession(): guard explicit-sign-out/reauth/client; same-owner check (identity change => reauth); expired JWT after SDK attempt => "Renovacion del acceso pendiente", return false; success => connected. Unrecoverable refresh failure no longer sets isMigrationRequired nor clears BusinessDataStore (old code did). Android tree158 ported only the onResume JWT<=60s restore trigger; the requiresReauthentication flag, its exact messages, the owner-change gate and the unrecoverable-vs-network split remain OPEN (error codes unverifiable without live Supabase).

HealthMuscleMapper (75 diff lines): uniqueExternalActivities = linked-UUID filter + native overlap (same healthType, start <90 s, duration <3 min). Android: overlap rule ported verbatim in domain HealthMuscleMapper.dropNativeOverlaps; the linked-id part is handled by the reader (ReperaHealthExclusion) instead of the mapper - equivalent coverage, different placement. nativeSportStimuli, isEstimatedIntense (HIIT/cross/functionalStrength/boxing/kickboxing/martialArts/wrestling) and isCardio (strength/core/yoga/pilates/flexibility/cooldown/other NOT cardio) all ported. No open item.

ActivityHeatmapView (21 diff lines): only change is HeatmapLayout gaining cellHeight; in strip mode cells become horizontal rectangles with height min(cell, 76) so 1-3 day strips do not grow hundreds of points tall. Android ProgressCharts heatmap still uses square cells for strips (canvasHeight = cell * rows). OPEN (small visual).

## tree163 — Correcciones portadas (27oct 09:55 CET)

Baseline REAL previo: domain 382/0/0/0, mobile 446/0/0/0 (XML; primera ejecución combinada cortada
con daemon eliminado sin OOM explícito en log — hipótesis memoria, no confirmada; solución observada:
módulos por separado + heap 900m). Coincidencia de conteos NO certifica identidad del árbol ni validación runtime.

1. **updateFinishedWorkout: duración preservada con vínculo Salud.** Apple ReperaStore.saveWorkout
   (edición, bd4d7637): appleDurationSeconds solo se deriva fin-inicio (mín 60) cuando
   liveSportID==nil AND healthKitWorkoutUUID==nil. Android lo recalculaba siempre, pisando la
   medición Health Connect. Fix: puerta pura FinishedSessionDuration.shouldDeriveFromSchedule
   (healthKitWorkoutUUID, healthConnectRecordId=HealthSessionLink.SNAPSHOT_FIELD, liveSportID).
   Tests: FinishedSessionDurationTest 5/5 (4 unitarios puros + guardia estática de uso en repo).
2. **ActiveSessionPlan.refresh: legacyIdentity a nivel de sesión + adapted*.** Apple
   ReperaStore.refreshActiveSessionPlan (bd4d7637): fallback por ejercicio SOLO si la sesión es
   legada (ningún id de sus ejercicios aparece en sus propios routineBlocks exercises+movements);
   conserva loggedSets/completedReps/isCompleted/adaptedReps/adaptedWeightKg; copia title;
   fallback de currentIndex también gobernado. Android hacía fallback por ítem (id !in freshIds),
   que robaba series a ítems repetidos en sesiones con identidad estable. Tests: ActiveSessionPlanTest
   7/7 (4 previos intactos + 3 nuevos: no-reasignación no legada, arrastre adapted*, copia título).
3. explicitPlannedSets=[] NO cambiado (decisión main 09:42: riesgo legacy WOD, trazar
   writers/consumidores antes; parche de borrado ya revertido en el pasado).

Post-ventana REGISTRADA, fuera de cobertura solicitada (usuario fijó «desde hace 3 días» 26oct 17:43;
ventana resuelta bd4d7637): 152 commits first-parent bd4d7637..origin/main (26oct 18:01 → 27oct 09:23,
87 archivos, +3580/-1686): walking lunges kg reps/metros, escáner distancias, relinks snapshots BTT/T2B,
fixes topbar, tests nuevos Packages. NO se portan ni amplían alcance sin aprobación del usuario.

Pendiente sin cambios: auditoría 579 commits anteriores (matriz), resto de items de implementación de
hallazgos (mapa fullscreen, resultado formato WOD, card Entreno unificada, traza azul, live-save Salud,
cap heatmap 76, Live restructure, requiresReauthentication, edit-save health re-resolve, steps en detalle).

## tree164 — WOD estimado en carga muscular semanal + matriz 579 (27oct 10:10 CET)

4. **MuscleWorkloadMetrics.weekly: equivalente WOD estimado.** Apple MuscleLoadEngine.load /
   MuscleMapEngine.statuses (bd4d7637): effectiveSets = sets>0 ? sets : estimatedSetEquivalent (1.0;
   nunca hardOnly; requiere terminado, blockKind==wod o blockId en wodResults, sin series de trabajo
   confirmadas). Android saltaba esas entradas. Port: mismo gate; la ruta de fatiga x0.7 ya estaba
   portada. Tests: MuscleWorkloadMetricsTest 6/6 nuevos; suite mobile completa 460/460 REAL.
5. **Auditoría 579 arrancada**: definición exacta recuperada (892 ventana 3 días = 313 leídos + 579
   previos a fc3ef7e1; android/ jamás en main). Artefactos: AUDIT_579_PREWINDOW.md + matriz CSV
   heurística (todo unverified; 315 con candidato por subject, 264 sin). Verificación real pendiente.

## tree165 — Equivalente WOD también en MuscleLoadEngine de dominio (27oct 10:16 CET)

6. **domain/MuscleLoadEngine.load**: el motor de barras de equilibrio muscular ignoraba
   completedWodSetEquivalent (que el modelo ya traía de ProgressSnapshot con el gate Apple exacto:
   terminado + bloque WOD o score global + no movilidad + sin series de trabajo). Apple
   MuscleLoadEngine.load: effectiveSets = sets>0 ? sets : estimated (nunca hardOnly). Port aplicado;
   hardOnly sigue excluyendo el estimado. Tests: MuscleLoadEngineTest 8/8 (5 previos + 3 nuevos:
   estimado suma, hardOnly lo ignora, series reales no duplican). Suite domain completa 385/385 REAL.
   Doble conteo por consumidor verificado: ProgressSnapshot (loadAll/loadHard → MuscleBalanceCard) y
   MuscleWorkloadMetrics.weekly (ProgressTab) son superficies independientes que derivan cada una del
   archivo bruto, como en Apple (barras vs mapa de fatiga x0.7). Ningún consumidor suma ambas.
   Nota main 10:11: la matriz 579 es índice heurístico, no cobertura; "313 leídos" = diffs de ventana
   revisados estáticamente, no commits verificados; al resolver hallazgos manda baseline bd4d7637
   sobre reglas antiguas supersedidas (giros GPX 30m, no 20m).

## tree166 — Primeras 7 filas 579 verificadas (27oct 10:18 CET)

Verificación real (diff Apple leído + árbol Android comparado, baseline bd4d7637):
- 92fe968b 1RM nunca desde metros/kcal: guard peso>0+reps>0+no movilidad+terminado idéntico en
  domain/StatsEngine.personalRecords.
- 983304e8 / 9b81af37 / 48e1289b / e512a743 SportExerciseNames: key() diacríticos+case,
  aliasKey() puntuación->espacio, supplementalAliases 75/75 claves Y valores idénticos al baseline,
  canonicalName/spanishAlias/englishAliasForSpanish estructura 1:1.
- eabc3cd2 / f30b6232 splits km con pausas: liveKilometerSplitsSeconds en modelo, persistencia
  (WorkoutRepository:138, LiveActivitySnapshotStore), UI (ExercisesTab, ReperaCards,
  LiveActivityScreen) y cómputo con reloj activo (pausedSeconds excluidos, interpolación de cruce
  de km) en domain/LiveActivityState.receive; tests LiveSportHistoryTest + roundtrip snapshot.
Matriz actualizada: 7/579 verified, resto unverified.

## tree167 — isJumpRope completo + 3 filas más verificadas (27oct 10:21 CET)

- bcb9f677 giros GPX: detect 1:1 ya portado en domain/LiveGPX.kt (ventanas 30m, guard 20m, umbral
  52 grados, dedup 55m) — confirma la regla vigente 30m del baseline, no la antigua 20m.
- c02f3ca4 + 97d0bc13 prescripción siguiente serie en Watch: semántica ya cubierta inline en
  wear/WearMainActivity.kt (work sets consumen prescripción, último target persiste, precarga
  reps/peso/rir/deficit/duración/unidad). Sin propiedad de dominio compartida; no se añade.
- d03aaa76 isJumpRope: GAP real encontrado y corregido — faltaban `triple`+comba y prefijo `su `
  (la normalización Android convierte guiones en espacios, así que las variantes con guion ya
  estaban cubiertas; Apple conserva guiones y por eso lista ambas). Test nuevo
  jumpRopeCoversTripleAndSuPrefixLikeApple. ExerciseInputModeTest 8/8; domain COMPLETO 386/386 REAL.
Matriz: 10 verified + 1 verified-with-fix / 579.

## Reconciliación 20m vs 30m (10:23 CET, petición main)

Son CAPAS DISTINTAS, ambas portadas correctamente contra bd4d7637:
1. DETECCIÓN de giro (LiveRouteTurn.detect, LiveActivityView.swift): ventana de rumbo a ~30m a
   cada lado del vértice, exige ≥20m disponibles por lado, umbral 52°, dedup 55m → Android
   domain/LiveGPX.kt detect: idéntico constante a constante. bcb9f677 (30m en rutas densas) es ESTA
   capa; 30m es la regla vigente del baseline.
2. ANUNCIOS hablados (updateUpcomingTurn): se dispara a ≤120m (ciclismo) / ≤70m (resto), redondeo
   10m, "Sigue el recorrido" >250m, fuera de ruta ≥55m, lookahead +8m, dedup por routeIndex, y el
   WORDING "Ahora, <dir>." solo a ≤20m ("En unos N metros" el resto) → Android
   domain/LiveRouteGuidance.kt + LiveSpokenPhrases.turn: idéntico, incluido "cambia de sentido" >145°.
   El 20m de tree132 es este umbral de wording, no el de detección. Sin contradicción ni regresión.
Residual abierto (menor): Apple calcula followingTurnMeters/Symbol (preview del SEGUNDO giro en UI);
el Cue Android no lo expone. Anotado, sin portar aún.

## tree168 (10:26) — filtro HYROX: set incompleto vs Apple (fix) + hallazgo abierto 9f89e59f
- e350a23d / 96284a58 (Apple): filtro HYROX con matchingNames completo (ES + plurales). Android `mobile/ExerciseCatalogFilters.kt` tenía el set recortado: faltaban 16 equivalentes ES/plural (p.ej. "remo", "zancadas", "double unders", "sentadillas", formas pluralizadas). FIX aplicado: set ampliado a las matchingNames de Apple, formas normalizadas al criterio Android. Nuevo test `ExerciseCatalogFiltersTest` verifica que cada nombre Apple coincide con el filtro.
- Test REAL (XML, post-fix): mobile FULL 462/462, 0 failures/errors/skipped (baseline 460 + 2 nuevos).
- Matrix: e350a23d, 96284a58 → verified-with-fix (tree168).
- HALLAZGO ABIERTO 9f89e59f (Apple): indexa `disciplineTags.joined(" ")` en el campo "sport" de ExerciseSearch → buscar "hyrox" por texto devuelve todos los ejercicios HYROX. Android NO tiene concepto disciplineTags; `ExerciseAliasSearch.score(query, name, aliases)` solo puntúa nombre+aliases y los call sites (ExercisesTab, ReperaCards, WodLibraryScreen) solo pasan `name`. Buscar "hyrox" por texto en Android no devuelve nada (solo funciona el chip de filtro). NO arreglado: requiere decisión de diseño (dónde compone Android el documento de búsqueda; cómo alimentar disciplina sin alterar ranking). Fila 9f89e59f revertida a unverified con nota. Candidato a subir como gap en reporte final.

## tree169 (10:33) — búsqueda por disciplina HYROX (port 9f89e59f, instrucción del padre 10:28:09 verificada en chat_events)
- Apple 9f89e59f: ExerciseSearch indexa disciplineTags.joined(" ") en el campo meta (perTokenInMeta=120, por debajo de todo peso de nombre/alias).
- Android no tiene disciplineTags pero ExerciseEntry.hyroxTraining ya existe (poblado desde ExerciseCatalogFilters.isHyroxTrainingMovement, mismo matchingNames de Apple). Port: ExerciseAliasSearch.score gana param opcional extraTerms (default "" → comportamiento idéntico); si todos los tokens de la query normalizada están en normalize(extraTerms) → 40 (por debajo de 50 tokens-en-nombre y de todo match de nombre/alias, igual que Apple meta<nombre). Call sites reales actualizados: ExercisesTab, ReperaCards, WodLibraryScreen pasan "hyrox" cuando entry.hyroxTraining.
- Ranking conservado para consultas no disciplina: param por defecto y tests de regresión (defaultUnchanged -1, wrongDiscipline -1, name match > discipline match).
- Tests REALES XML: domain 388/388 (386+2 nuevos), mobile 462/462 REAL XML.
- Matrix: 9f89e59f → verified-with-fix (tree169).

## tree170 (10:41) — b46562cc + ba692f65 VERIFICADOS por paridad de datos (sin fix)
- Método: extractor propio del repo (android/tools/extract_catalog.py, implementa orden nombre-primero post-b46562cc) regenerado contra bd4d7637 → 288 entradas; comparación campo a campo (name, muscleGroup, catalogId, detailDescription, equipment, instructions, sportTag) con catalog_seed.json → 0 diffs. Segunda reimplementación independiente en Python de spanishByName/spanishAlias/translateSentence: 206 desc + 208 instrucciones coincidentes, 0 diffs. check_catalog_parity.py oficial: PASS (288 entradas, 196 ids preservados, esquemas v3/v5).
- b46562cc (orden nombre-primero): único caso discriminante en toda la tabla = "Back rack reverse lunge" (alias "Zancadas inversas con barra", textos distintos); el seed Android lleva el texto del orden NUEVO. Verified.
- ba692f65 (fallback CatalogMovilidad): mobility_seed.json 82/82 lleva verbatim detailedDescription/detailedInstructions de Apple (raw + sufijo "Ejercicio de movilidad controlada para…"); la vía translateSentence produce el mismo texto (descripciones raw ya en español, phrasePairs solo inglés). Verified.
- Nota: las 2 entradas HYROX (Burpee Broad Jump, Sandbag Lunges) no tienen catalogId en Apple bd4; los hyrox-* de Android son identidad propia por diseño (README android/tools, esquema v3). No es divergencia.
- matrix actualizada: b46562cc, ba692f65 → verified. Scratch b46562cc eliminado.

## tree171 (10:44) — e9feae2b port (splits HUD) + 5890215d/2eb7cdd5 verificados
- e9feae2b: Apple muestra kilometerSplitSummary en el HUD live con guard usesGPS && (recording||paused). Android no mostraba el resumen de parciales completados en el HUD (solo en REVIEW). Port: LiveKilometerSplitsSection añadido al HUD en LiveActivityScreen con guard idéntico (RECORDING||PAUSED; usesGPS implícito en el bloque + early-return si no hay splits). Sin tests de UI en el repo (no hay Robolectric/compose-ui-test): verificación estática + compileDebugKotlin + suite mobile 462/462 REAL XML. Runtime visual no ejecutado (sin emulador en sandbox).
- 5890215d (merge deportes/métricas): comparación sistemática LiveSport Apple bd4 vs Android domain: 53/53 ids, title, symbol (incl. hyrox=ExerciseCategorySymbols.discipline=figure.run), group, usesGPS, isWaterSport, displaysSpeed, tracksElevation, maxGPSMetersPerSecond (12/22/24/42/50), healthType → 0 diffs. metricDescription: fórmula idéntica. Orden del enum Android difiere del Apple: deliberado (ids persistidos, cabecera del archivo).
- 2eb7cdd5 (HK dance obsoleto→cardioDance): N/A-equivalente. Health Connect EXERCISE_TYPE_DANCING no está obsoleto; mapping Android DANCE→EXERCISE_TYPE_DANCING ya es el tipo correcto; healthKey "dance" es namespace interno con consumidores consistentes (HealthMuscleMapper 84/112/151).

## tree172 (10:57) — disciplineTags port completo (e327d676, 26a03d2b) + 9 filas catálogo verificadas
- Nuevo domain/ExerciseDisciplineTags.kt: port exacto de ExerciseDisciplineRules (crossFitGeneral 19, crossFitGymnastics 19, hyroxAlsoCrossFit 2, cardioNames 19) + lógica Exercise.disciplineTags (Models.swift). normalized() conserva puntuación como Apple ("double-under" con guion; distinto de ExerciseAliasSearch.normalize).
- Nuevo domain/HyroxExercises.kt: port de HyroxExercises (matchingNames 27 raw + fold diacríticos exacto + competitionStations 9). mobile ExerciseCatalogFilters.isHyroxTrainingMovement = set Android (tree168) OR Apple exacto (unión; nunca pierde un match Apple).
- ExerciseEntry.disciplineTags poblado en el build del catálogo (MainActivity). WodExerciseArt preview queda con lista vacía (sportTag null, muscleGroup WOD: Apple tampoco derivaría disciplinas ahí salvo cardioNames por nombre — preview de arte, sin impacto de filtro).
- ExerciseCatalogFilters.matches: chips no fijos filtran por disciplineTags.contains(filter) (=Apple ExerciseCatalogSearchList e327d676). Cardio: "Cardio" in disciplineTags (muscleGroup Cardio ∪ cardioNames) — corrige desviación Android vieja que incluía TODA Movilidad (repsAndTime) y Burpee Broad Jump (machineWork) bajo el chip Cardio. Efecto neto seed: 10 Cardio + SkiErg, igual que Apple.
- Búsqueda: extraTerms ahora recibe TODAS las disciplineTags (no solo hyrox) en ExercisesTab/ReperaCards/WodLibraryScreen — completa 9f89e59f (Apple indexa disciplineTags.joined(" ")).
- Tests REALES XML: domain 401/401 (+13: ExerciseDisciplineTagsTest 7 + ExerciseDisciplineCatalogTest 6 espejo de CatalogQualityTests/ExerciseDisciplineTagsTests Apple: 288 seed, 48 Halterofilia→CrossFit, 58 Gimnasia→CrossFit, 11 HYROX, estaciones 9, Wall ball [CrossFit,HYROX], Gato-vaca [Movilidad], sin duplicados). Mobile 462/462.
- Incidencia: domain/src/test/resources/catalog_seed.json (fixture de BoardScan tests) estaba STALE (196 entradas vs 288 reales). Sincronizarlo rompe 5 tests de parser fijados al fixture viejo → revertido; mi test usa recurso propio catalog_seed_288.json. Hallazgo anotado: fixture BoardScan desactualizado, decisión de actualizar expectativas queda pendiente (no bloquea paridad).
- Filas verificadas por evidencia tree170 (paridad datos bd4): c56ebc7f, 7ae04430, 66281b05, df76e246, 88dbde3c, fdcb9ba7, f860818c, 94225871 (CatalogMovilidad.rows en composición), a140cabc (superseded por b46562cc; estado final verificado).

## tree173 — BoardScan: índice de catálogo con alias (fix caso C&J) + clasificación 5 divergencias
- Clasificación de los 5 fallos del fixture BoardScan con la ruta real (catálogo 288): 4 = modernización correcta (Apple bd4 espera los mismos nombres ingleses en sus tests); 5º («20 ALT DB HANG C&J») = gap real Android.
- Causa raíz (código Apple origin/main, no ejecutado aquí): `BoardScanLiteParser.catalogIndex` indexa también `Exercise.searchAliases` (oficiales > custom > alias, alias no pisa canónico; commits post-bd4 88db5bb7/83253491/ca7b1ae2). El port Android solo indexaba `norm(name)` con putIfAbsent.
- Emulación Python de las tablas reales bd4 (aliases/legacy/supplemental/bilingual) confirmó que el parser produce move.name «Cargada y envión con mancuerna» en ambas plataformas y que la resolución a «Dumbbell Clean and Jerk» ocurre en el match de catálogo vía alias. NO es ejecución real de Apple.
- Cambios: CatalogExercise +searchAliases +isCustom; catalogIndex portado (parse + structuredStrength); BoardScanScreen puebla alias vía SportExerciseNames.searchAliases(name) e isCustom; helper de tests igual.
- Tests: nuevo BoardScanCatalogIndexTest (5 tests: repro C&J con 288, 4 nombres modernizados, 3 orden/colisiones official-custom-alias). ScratchTraceTest.kt eliminado (su repro útil trasladada a resolvesDumbbellCleanAndJerkThroughPublishedAlias). Fixture 196 restaurado a la versión committed 4a359974 (un overwrite lo había dejado en 288 inglés; git checkout).
- REAL XML: domain 406/406, mobile 462/462, 0 fallos/errores/skipped.
- Descubrimiento lateral: en origin/main local (0a640da8) el seed de Apple nombra la ficha «Cargada y envión con mancuerna» y no hay rename en seed(); el test de Apple que espera «Dumbbell Clean and Jerk» parece depender del catálogo hidratado de Supabase (producción), no de Catalog.seed(). Además el remoto LIVE tiene commits posteriores al ref local (diff en HistoryView/Models/FEATURES) — cobertura 09:23→11:05 pendiente de verificación live.

## tree174 — Port ff94e6ad: officialName BTT/T2B (OCR confusables) + hook glosario + respaldo arte
- Fuente: commit live-only ff94e6ad (27oct 09:52:31 CET, dentro de ventana), patch descargado vía navegador (sesión GitHub usuario).
- Nuevo domain WODHistoryPresentation.officialName: NFKC, mapa de confusables visuales (cirílico/griego/cherokee/small-caps) ANTES de transliterar (Apple: la transliteración genérica rompe В→V), fold diacritics/case, [^a-z0-9]+→espacio, match compacto para abreviaturas (btt/t2b/ttb) y exacto para frases. Sin búsqueda difusa.
- Hook en CrossFitGlossary.canonicalName (antes del glosario, como Apple); respaldo de arte en ExerciseArtResolver.heroFor antes del caso BBJO.
- Apple aplica transliteración Latin genérica (ICU); el port usa mapa explícito + NFKC — cubre todos los casos de sus tests; otros alfabetos no mapeados quedan fuera igual que antes (limitación documentada en comentario).
- Tests: WODHistoryPresentationTest (espejo de las aserciones visibles del patch: 3 previas + 10 variantes BTT × officialName y canonicalName + 2 negativos); ExerciseArtResolverTest.ocrLookalikeT2bResolvesOfficialArt (Τ2Β griego → art_cf_ttb).
- REAL XML: domain 408/408, mobile 463/463, 0 fallos/errores/skipped.
