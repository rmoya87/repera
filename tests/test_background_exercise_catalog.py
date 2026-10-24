"""Contracts for invisible offline-first exercise catalogue updates (iOS 27)."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class BackgroundExerciseCatalogContracts(unittest.TestCase):
    def test_no_manual_sync_button_in_account(self):
        settings = source("Apps/Repera/Sources/SettingsView.swift")
        self.assertNotIn("Sincronizar ahora", settings)
        self.assertNotIn("syncEverything()", settings)
        self.assertNotIn("syncIconSpinning", settings)

    def test_native_background_refresh_is_configured(self):
        project = source("project.yml")
        app = source("Apps/Repera/Sources/ReperaApp.swift")
        self.assertIn("BGTaskSchedulerPermittedIdentifiers:", project)
        self.assertIn("com.app.repera.catalog.refresh", project)
        self.assertIn("UIBackgroundModes:", project)
        self.assertIn("  - fetch", project)
        self.assertIn(".backgroundTask(.appRefresh(", app)
        self.assertIn("BGAppRefreshTaskRequest", app)
        self.assertIn("static func runHeadless() async", app)
        self.assertIn("refresh(force: true)", app)
        self.assertIn("CatalogBackgroundRefreshScheduler.schedule()", app)

    def test_cache_io_and_overlay_are_off_main_actor(self):
        s = source("Apps/Repera/Sources/RemoteExerciseCatalogStore.swift")
        self.assertIn("private actor DiskStorage", s)
        self.assertIn("await disk.read()", s)
        self.assertIn("await disk.write(", s)
        self.assertIn("Task.detached(priority: .utility)", s)
        self.assertIn("func refresh(store: ReperaStore? = nil", s)
        self.assertIn(".limit(150)", s)
        self.assertIn("lastProbeAt", s)
        self.assertIn("store.state.syncRevision == revision", s)

    def test_health_backlog_is_automatic_after_removing_sync_control(self):
        app = source("Apps/Repera/Sources/ReperaApp.swift")
        self.assertIn("private enum AutomaticHealthWorkoutReconciler", app)
        self.assertIn("HealthKitStore.shared.canWriteWorkouts", app)
        self.assertIn("store.syncMissingWorkoutsToHealth()", app)
        self.assertIn("AutomaticHealthWorkoutReconciler.schedule(store: store)", app)

    def test_local_seed_and_archived_references_survive(self):
        domain = source("Packages/ReperaDomain/Sources/ReperaDomain/Models.swift")
        store = source("Apps/Repera/Sources/ReperaStore.swift")
        self.assertIn("public var isCatalogArchived: Bool", domain)
        self.assertIn("isCatalogArchived = try c.decodeIfPresent", domain)
        self.assertIn("Catalog.seed()", store)
        self.assertIn("restoreCached(to: self)", store)


if __name__ == "__main__":
    unittest.main()
