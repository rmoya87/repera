"""Calendario Inicio: los planes futuros muestran punto sin falsificar completados."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps" / "Repera" / "Sources"

class FuturePlannedWorkoutsCalendarTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.home = (SRC / "HomeView.swift").read_text(encoding="utf-8")
        cls.root = (SRC / "RootTabView.swift").read_text(encoding="utf-8")

    def test_future_plans_use_the_same_dot_as_completed_sessions(self):
        cell = self.home.split("private func calendarDayColumn(", 1)[1].split(
            "private var dayWorkoutSection:", 1
        )[0]
        self.assertIn("let hasCompletedWorkout = hasCompletedWorkoutOnDay(day.iso)", cell)
        self.assertIn("let isTodayOrFuture = calendar.startOfDay(for: day.date)", cell)
        self.assertIn(">= calendar.startOfDay(for: Date())", cell)
        self.assertIn("if hasCompletedWorkout || (isTodayOrFuture && day.hasPlan)", cell)
        self.assertIn("Circle()", cell)
        self.assertIn(".fill(selected ? OG.onAccent : OG.accent)", cell)
        self.assertIn(".frame(width: 4, height: 4)", cell)
        # A plan in the past without completed activity is not shown as done.
        self.assertNotIn("if hasCompletedWorkout || day.hasPlan", cell)

    def test_local_coach_and_booked_classes_are_all_indexed(self):
        lookup = self.home.split("private func makeCalendarDayLookup()", 1)[1].split(
            "private func makeWeekDays(", 1
        )[0]
        self.assertIn("store.state.routines.compactMap { $0.scheduledDate }", lookup)
        self.assertIn("businessData.trainingSessions.map", lookup)
        self.assertIn('booking.status == "booked"', lookup)
        week = self.home.split("private func makeWeekDays(", 1)[1].split(
            "private func dayKey(", 1
        )[0]
        self.assertIn("indexed.planned.contains(key)", week)
        self.assertIn("indexed.trainerPlans.contains", week)
        self.assertIn("indexed.bookings.contains", week)

    def test_planning_changes_refresh_dots_without_full_health_analysis(self):
        self.assertIn("private var scheduledCalendarSignature: Int", self.home)
        self.assertIn(".onChange(of: scheduledCalendarSignature) { _, _ in", self.home)
        self.assertIn("rebuildWeekChrome()", self.home)
        self.assertIn("hasher.combine(routine.id)", self.home)
        self.assertIn("hasher.combine(calendar.startOfDay(for: date))", self.home)
        self.assertIn(".onChange(of: businessCalendarSignature) { _, _ in", self.home)
        completed = self.home.split("private func hasCompletedWorkoutOnDay(", 1)[1].split(
            "private func rebuildWeekChrome()", 1
        )[0]
        self.assertIn("workoutsByDayKey[key]", completed)
        self.assertIn("healthByDayKey[key]", completed)
        self.assertNotIn("hasPlan", completed)

    def test_home_does_not_show_load_route_entry(self):
        self.assertNotIn('Text("Cargar ruta")', self.home)
        self.assertNotIn("onLoadRoutes:", self.home)
        self.assertNotIn("routePickerRequest", self.root)

if __name__ == "__main__":
    unittest.main()
