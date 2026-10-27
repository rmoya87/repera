# Parches del tramo final del corte (solo en remoto vivo)

Corte vigente del encargo (ventana hasta 27-oct-2026 11:05:11 CET):
- `0a640da8` (origin/main local, 27-oct 09:23:48 CET) MAS estos 4 commits
  in-window que solo existen en el remoto vivo (git fetch sin credenciales):
  - ff097bf3 09:35:26 — Periodically refresh Supabase catalog and relink historic WOD aliases
  - dbf43176 09:37:25 — Add debug diagnostics for unresolved historical exercise alias identity
  - 11ea29a6 09:42:56 — Refresh remote exercise catalog at app and workout milestones
  - ff94e6ad 09:52:31 — Normalize case and OCR confusables for BTT aliases
- Tip real 8ab72cfe (11:13:29) = FUERA del corte; no portar.

Clasificacion en AUDIT_POSTBD4_WINDOW_MATRIX.csv (ff94e6ad/11ea29a6
verified-ported, dbf43176 verified-n/a, ff097bf3 verified-partial+GAP).

Alcance de archivos: QuickLogSheet, ReperaApp, ReperaStore, RootTabView,
HistoryView, RemoteExerciseCatalogStore, Models.swift (domain),
ExerciseArt.swift, BoardImportParser.swift + tests. NINGUNO toca HomeView,
Theme, PlanView, LibraryView, StatsView, WorkoutClockCoordinator ni
SessionPreviewView (valida la lectura de paisaje/relojes contra 0a640da8).
