"""Contratos actuales de programación en Inicio y editores compartidos.

El antiguo Diario fue retirado. La programación se basa exclusivamente
en fechas concretas y conserva historial y plantillas reutilizables.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "Apps" / "Repera" / "Sources"


def swift(name):
    return (SOURCES / name).read_text(encoding="utf-8")


class ScheduledWorkoutContractTests(unittest.TestCase):
    def test_retired_diary_not_restored_as_navigation(self):
        editor = swift("PlanView.swift")
        shell = swift("RootTabView.swift")
        self.assertIn("El antiguo Diario y sus pestañas se han retirado", editor)
        self.assertIn("struct DayEditorView: View", editor)
        self.assertNotIn("PlanView()", shell)
        self.assertNotIn("weekSelector(narrow:", editor)

    def test_home_calendar_only_marks_concrete_planned_dates(self):
        home = swift("HomeView.swift")
        self.assertIn("private func makeCalendarDayLookup()", home)
        self.assertIn("store.state.routines.compactMap { $0.scheduledDate }.map(dayKey)", home)
        self.assertIn("businessData.trainingSessions.map(\\.scheduledDate)", home)
        self.assertIn('guard booking.status == "booked" else { return nil }', home)
        self.assertIn("hasPlan: indexed.planned.contains(key) ||", home)
        self.assertIn("let key = dayKey(dayStart)", home)
        self.assertNotIn("else if let wd = routine.weekday", home)

    def test_day_editor_uses_native_navigation_not_legacy_tabs(self):
        editor = swift("PlanView.swift")
        self.assertIn("DayEditorChromeModifier", editor)
        self.assertIn(".ogScrollingTitleNav()", editor)
        self.assertIn(".navigationBarBackButtonHidden(false)", editor)
        self.assertIn("OGDoneCheckButton(", editor)
        self.assertIn("OGToolbarGlassButton(", editor)
        self.assertNotIn('Picker("Sección", selection:', editor)

    def test_copy_previous_week_only_fills_unoccupied_dates(self):
        store = swift("ReperaStore.swift")
        block = store.split("func copyPreviousWeekSchedule(", 1)[1].split("func assignRoutine(", 1)[0]
        self.assertIn("scheduledRoutines(inWeekContaining: previous)", block)
        self.assertIn("let originallyOccupied = scheduledRoutines(inWeekContaining: targetStart)", block)
        self.assertIn("!originallyOccupied.contains(where:", block)
        self.assertIn("blocks: source.blocks.map { $0.duplicatingContent() }", block)
        self.assertIn("if saveRoutine(copy) { created += 1 }", block)

    def test_clear_week_preserves_favorites_and_other_dates(self):
        store = swift("ReperaStore.swift")
        block = store.split("func clearWeeklySchedule(", 1)[1].split("func removeScheduledRoutine(", 1)[0]
        self.assertIn("scheduledRoutines(inWeekContaining: weekReference)", block)
        self.assertIn("state.routines[i].scheduledDate = nil", block)
        self.assertIn("state.routines[i].weekday = nil", block)
        self.assertIn("!$0.isFavorite || $0.favoriteTemplateId != nil", block)
        self.assertIn("persist()", block)
        self.assertIn("pushActiveToWatch()", block)

    def test_templates_are_copied_to_date_without_recurring(self):
        sheet = swift("DayOverrideSheet.swift")
        store = swift("ReperaStore.swift")
        editor = swift("PlanView.swift")
        self.assertIn("store.assignRoutine(routine.id, toDate: scheduledDate)", sheet)
        self.assertIn("func assignRoutine(_ routineId: UUID, toDate date: Date)", store)
        self.assertIn("let copy = Routine(", store)
        self.assertIn("blocks: source.blocks.map { $0.duplicatingContent() }", store)
        self.assertIn("DatePicker(\"Fecha programada\"", editor)
        self.assertNotIn('Picker("Día en Programado"', editor)

    def test_plan_editor_saves_library_then_schedules_optional_copy(self):
        editor = swift("PlanView.swift")
        self.assertIn('Toggle("Programar también en una fecha", isOn: planScheduleEnabled)', editor)
        self.assertIn('DatePicker("Fecha programada", selection: planScheduledDate,', editor)
        self.assertIn("private var planScheduleEnabled: Binding<Bool>", editor)
        self.assertIn("private var planScheduledDate: Binding<Date>", editor)
        block = editor.split("private func confirmWithVerifiedAccess() async", 1)[1].split("case .oneOff:", 1)[0]
        self.assertIn("let dateToSchedule = draft.scheduledDate", block)
        self.assertIn("draft.scheduledDate = nil", block)
        self.assertIn("guard await saveRoutineWithVerifiedAccess(draft) else { return }", block)
        self.assertIn("store.assignRoutine(draft.id, toDate: dateToSchedule)", block)

    def test_add_routine_sheet_preserves_compact_header_and_spacing(self):
        sheet = swift("DayOverrideSheet.swift")
        self.assertIn('OGPageHeader(title: dayLabel)', sheet)
        self.assertIn(".padding(.top, 14)", sheet)
        self.assertIn(".padding(.bottom, 18)", sheet)
        self.assertIn(".ogFittedHeight()", sheet)
        self.assertNotIn("La rutina se copiará solo a esta fecha.", sheet)

    def test_legacy_weekdays_migrate_without_erasing_workouts(self):
        store = swift("ReperaStore.swift")
        self.assertIn("private func migrateLegacyWeeklyPlans() -> Bool", store)
        self.assertIn("let migratedWeekly = migrateLegacyWeeklyPlans()", store)
        block = store.split("private func migrateLegacyWeeklyPlans()", 1)[1].split("func scheduledRoutines(", 1)[0]
        self.assertIn("templates.append(Routine(", block)
        self.assertIn("migrated.scheduledDate = target", block)
        self.assertIn("migrated.weekday = nil", block)
        self.assertIn("if !alreadyDated", block)
        self.assertNotIn("state.workouts", block)
        self.assertNotIn("state.routines.removeAll", block)


class RecoveryChartFillContractTests(unittest.TestCase):
    def test_duo_charts_fill_measured_columns_without_blank_space(self):
        source = swift("HealthRecovery.swift")
        self.assertIn("@State private var recoveryGridWidth: CGFloat = 0", source)
        self.assertIn("private var duoColumnWidth: CGFloat?", source)
        self.assertIn("private var readinessChartHeight: CGFloat", source)
        self.assertIn("private var sleepChartHeight: CGFloat", source)
        self.assertIn("private var fittedSleepChartHeight: CGFloat", source)
        self.assertIn("private func alignDuoRecoveryRows()", source)
        self.assertIn(".frame(height: readinessChartHeight)", source)
        self.assertIn(".frame(height: fittedSleepChartHeight)", source)
        self.assertIn(".frame(height: physiologyChartHeight)", source)
        self.assertNotIn("readinessRowMinHeight", source)
        self.assertNotIn("sleepRowMinHeight", source)


if __name__ == "__main__":
    unittest.main()
