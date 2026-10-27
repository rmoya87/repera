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
| HealthMuscleMapper (75) | partial | native stimuli and overlap rule; isEstimatedIntense compared tree155 |
| SessionPreviewView (7), StartHubSheet (1) | read (tiny), static | tree106 |
| HistoryView (534) | read fully, static | tree115, tree132, tree159 (remaining ~400 lines read 2026-10-27 09:36; findings in tree159 section below) |
| LiveActivityView (782) | partial: route/notification/audio/trace slices | tree132-135; most of the diff unread |
| ReperaStore (406) | partial: migrateLegacyWeeklyPlans, updateActiveExerciseDraft | several sections; persist/sync trigger not audited |
| BusinessAuthStore (90) | partial | tree108 |
| LiveSportHistoryView (34) | read, static | tree156 |
| ActivityHeatmapView (21) | read enough to record cellHeight not ported | open list; no dedicated section found in this scan |
| SettingsView (48), ReperaApp (30) | read, static | tree158 |
| DayPlusSheet (1), DigitalClockDisplay (5), RegisterSwipeRevealCard (2), ReperaNowPlayingBar (4) | read (tiny), static | tree159: cosmetic/comment-only diffs, no Android behavior (details below) |
| BusinessAuthStore/Sync, workflows, README, docs/* | workflows excluded by instruction; docs not read as parity targets | |

Not covered by this ledger: the 579 commits older than fc3ef7e1 (only the 37837401 historical matrix) and Packages/ (domain Swift sources; the three Apple domain test files were read tree147/149/151-154, the Swift sources diff is not mapped line by line).

Pending reading kept (per parent, 08:26): LiveActivityView most of 782, ReperaStore (persist/sync-trigger audit), BusinessAuthStore (partial, tree108), HealthMuscleMapper (partial), ActivityHeatmapView (only cellHeight recorded), Packages/ Swift sources not mapped line by line, the 579 older commits (37837401 matrix only), and the four 1-5 line files (done tree159).

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
