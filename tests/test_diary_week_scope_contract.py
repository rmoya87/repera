"""Regresiones estáticas: Diario usa fechas semanales y Recuperación grafica el espacio.

Son contratos de fuente; la apariencia final requiere Xcode y dispositivos iOS.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "Apps" / "Repera" / "Sources"


def swift(name):
    return (SOURCES / name).read_text(encoding="utf-8")


class DiaryWeekScopeContractTests(unittest.TestCase):
    def test_diary_has_week_navigation_and_selected_dates(self):
        diary = swift("PlanView.swift")
        self.assertIn("@State private var weekOffset = 0", diary)
        self.assertIn("private var selectedWeekStart: Date", diary)
        self.assertIn('accessibilityLabel("Semana anterior")', diary)
        self.assertIn('accessibilityLabel("Semana siguiente")', diary)
        self.assertIn("let date = dateForWeekday(day)", diary)
        self.assertIn("store.scheduledRoutine(on: date)", diary)
        self.assertNotIn("let routine = store.routine(forWeekday: day)", diary)

    def test_week_selector_is_in_compact_topbar_and_duo_column_heading(self):
        diary = swift("PlanView.swift")
        self.assertIn('Text("Programado")', diary)
        self.assertIn("weekSelector(narrow: true)", diary)
        self.assertLess(diary.index('Text("Programado")'), diary.index("weekSelector(narrow: true)"))
        header = diary.split("private var diaryTopBar:", 1)[1].split("private struct DiaryDateBox", 1)[0]
        self.assertIn("weekSelector(narrow: false)", header)
        self.assertIn('OGFixedTopBar(title: "Diario")', header)
        # Compacto: menú a la derecha de Diario, semana debajo, no encima.
        self.assertLess(header.index('Text("Diario")'), header.index("weekActionsMenu", header.index("} else {")))
        self.assertLess(header.index("weekActionsMenu", header.index("} else {")),
                        header.index("weekSelector(narrow: false)"))
        self.assertIn("HStack(alignment: .top, spacing: 12)", header)
        self.assertIn(".frame(maxWidth: .infinity, alignment: .leading)", header)
        self.assertIn(".glassEffect(.regular.interactive(), in: .capsule)", diary)
        days = diary.split("private var scheduleContent", 1)[1].split("private func scheduleChips", 1)[0]
        self.assertNotIn('Text("Tu programación")', days)
        self.assertNotIn("weekOffset -= 1", days)
        self.assertNotIn("weekOffset += 1", days)

    def test_compact_diary_uses_progress_glass_tabs_without_list_gap(self):
        diary = swift("PlanView.swift")
        progress = swift("StatsView.swift")
        tabs = diary.split("private var compactDiaryTabs: some View {", 1)[1].split(
            "private struct DiaryDateBox", 1
        )[0]
        progress_tabs = progress.split('Picker("Categoría", selection: $topic)', 1)[1].split(
            ".ogReadableColumn()", 1
        )[0]
        for control in (tabs, progress_tabs):
            self.assertIn(".pickerStyle(.segmented)", control)
            self.assertIn(".controlSize(.large)", control)
            self.assertIn(".glassEffect(.regular, in: .capsule)", control)
        self.assertIn(".padding(.top, 4)", tabs)
        self.assertIn(".padding(.bottom, 10)", tabs)
        body = diary.split("var body: some View {", 1)[1].split(
            ".navigationDestination(item: $editing)", 1
        )[0]
        self.assertIn(".safeAreaInset(edge: .top, spacing: 0)", body)
        self.assertIn("compactDiaryTabs", body)
        self.assertNotIn(".ogSegmentedListRow()", body)
        self.assertEqual(diary.count('Picker("Sección", selection: $section)'), 1)
        self.assertIn("weekSelector(narrow: true)", body)

    def test_copy_and_clear_act_only_on_selected_week(self):
        diary = swift("PlanView.swift")
        store = swift("ReperaStore.swift")
        self.assertIn("store.copyPreviousWeekSchedule(to: selectedWeekStart)", diary)
        self.assertIn("store.clearWeeklySchedule(for: selectedWeekStart)", diary)
        self.assertIn("func copyPreviousWeekSchedule(to weekReference: Date = Date())", store)
        self.assertIn("scheduledRoutines(inWeekContaining: previous)", store)
        self.assertIn("scheduledRoutine(on: copyDate) == nil", store)
        self.assertIn("blocks: source.blocks.map { $0.duplicatingContent() }", store)
        self.assertIn("func clearWeeklySchedule(for weekReference: Date = Date())", store)
        self.assertIn("scheduledRoutines(inWeekContaining: weekReference)", store)
        self.assertIn("func removeScheduledRoutine(on date: Date)", store)
        self.assertIn("state.routines[index].scheduledDate = nil", store)
        self.assertIn("ids.contains($0.id) && !$0.isFavorite", store)

    def test_templates_do_not_become_recurring_when_assigned(self):
        sheet = swift("DayOverrideSheet.swift")
        store = swift("ReperaStore.swift")
        editor = swift("PlanView.swift")
        self.assertIn("store.assignRoutine(routine.id, toDate: scheduledDate)", sheet)
        self.assertIn("func assignRoutine(_ routineId: UUID, toDate date: Date)", store)
        self.assertIn("let copy = Routine(", store)
        self.assertIn("if draft.scheduledDate == nil, let weekday = draft.weekday", store)
        self.assertIn("draft.weekday = nil", store)
        self.assertIn("DatePicker(\"Fecha programada\"", editor)
        self.assertNotIn('Picker("Día en Programado"', editor)

    def test_existing_weekdays_are_migrated_without_deleting_completed_history(self):
        store = swift("ReperaStore.swift")
        self.assertIn("private func migrateLegacyWeeklyPlans() -> Bool", store)
        self.assertIn("let migratedWeekly = migrateLegacyWeeklyPlans()", store)
        self.assertIn("templates.append(Routine(", store)
        self.assertIn("migrated.scheduledDate = target", store)
        self.assertIn("migrated.weekday = nil", store)
        self.assertIn("if !alreadyDated", store)
        migrate = store.split("private func migrateLegacyWeeklyPlans()", 1)[1].split("func scheduledRoutines(", 1)[0]
        self.assertNotIn("state.workouts", migrate)
        self.assertNotIn("state.routines.removeAll", migrate)

    def test_home_only_marks_plans_with_matching_dates(self):
        home = swift("HomeView.swift")
        plan = home.split("private func makeWeekDays(", 1)[1]
        self.assertIn("guard let scheduled = routine.scheduledDate else { continue }", plan)
        self.assertNotIn("else if let wd = routine.weekday", plan)
        self.assertIn("store.scheduledRoutines(inWeekContaining: Date()).count", home)


class RecoveryChartFillContractTests(unittest.TestCase):
    def test_duo_height_comes_from_actual_column_width_not_empty_minimum(self):
        source = swift("HealthRecovery.swift")
        self.assertIn("@State private var recoveryGridWidth: CGFloat = 0", source)
        self.assertIn("private var duoColumnWidth: CGFloat?", source)
        self.assertIn("private var readinessChartHeight: CGFloat", source)
        self.assertIn("private var sleepChartHeight: CGFloat", source)
        self.assertIn("private var physiologyChartHeight: CGFloat", source)
        self.assertIn(".frame(height: readinessChartHeight)", source)
        self.assertIn(".frame(height: sleepChartHeight)", source)
        self.assertIn(".frame(height: physiologyChartHeight)", source)
        self.assertNotIn("readinessRowMinHeight", source)
        self.assertNotIn("sleepRowMinHeight", source)


if __name__ == "__main__":
    unittest.main()
