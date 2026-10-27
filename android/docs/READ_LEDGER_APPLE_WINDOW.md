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
| HistoryView (534) | partial: route slices and a second ~170 filtered-line slice | tree115, tree132; about 400 lines unread |
| LiveActivityView (782) | partial: route/notification/audio/trace slices | tree132-135; most of the diff unread |
| ReperaStore (406) | partial: migrateLegacyWeeklyPlans, updateActiveExerciseDraft | several sections; persist/sync trigger not audited |
| BusinessAuthStore (90) | partial | tree108 |
| LiveSportHistoryView (34) | read, static | tree156 |
| ActivityHeatmapView (21) | read enough to record cellHeight not ported | open list; no dedicated section found in this scan |
| SettingsView (48), ReperaApp (30) | read, static | tree158 |
| DayPlusSheet (1), DigitalClockDisplay (5), RegisterSwipeRevealCard (2), ReperaNowPlayingBar (4) | none found (tiny) | to read |
| BusinessAuthStore/Sync, workflows, README, docs/* | workflows excluded by instruction; docs not read as parity targets | |

Not covered by this ledger: the 579 commits older than fc3ef7e1 (only the 37837401 historical matrix) and Packages/ (domain Swift sources; the three Apple domain test files were read tree147/149/151-154, the Swift sources diff is not mapped line by line).

Pending reading kept (per parent, 08:26): HistoryView ~400 lines, LiveActivityView most of 782, ReperaStore (persist/sync-trigger audit), BusinessAuthStore (partial, tree108), HealthMuscleMapper (partial), ActivityHeatmapView (only cellHeight recorded), Packages/ Swift sources not mapped line by line, the 579 older commits (37837401 matrix only), and the four 1-5 line files.
