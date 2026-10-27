"""Source contracts for iCloud route persistence, Home route handoff and light navigation.

These tests are intentionally offline and do not claim to replace iCloud
multi-device verification or an iOS 27 simulator build.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps" / "Repera" / "Sources"

def code(filename):
    return (SRC / filename).read_text(encoding="utf-8")

class RouteCloudAndHomePerformanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.live = code("LiveActivityView.swift")
        cls.backup = code("LiveRouteCloudBackup.swift")
        cls.home = code("HomeView.swift")
        cls.root = code("RootTabView.swift")
        cls.project = (ROOT / "project.yml").read_text(encoding="utf-8")

    def test_icloud_documents_is_enabled_and_route_archive_is_coordinated(self):
        self.assertIn("iCloud.com.app.repera", self.project)
        self.assertIn("- path: Apps/Repera/Sources/LiveRouteCloudBackup.swift", self.project)
        self.assertIn('private let containerID = "iCloud.com.app.repera"', self.backup)
        self.assertIn("forUbiquityContainerIdentifier: containerID", self.backup)
        self.assertIn("struct LiveRouteCloudArchive: Codable, Sendable", self.backup)
        self.assertIn("deletedIDs: [UUID]", self.backup)
        self.assertIn("readingItemAt: url", self.backup)
        self.assertIn("writingItemAt: url", self.backup)
        self.assertIn("startDownloadingUbiquitousItem", self.backup)
        self.assertIn("guard coordinationError == nil", self.backup)
        self.assertIn("let archive = try? JSONDecoder().decode", self.backup)
        self.assertIn("else { return .unavailable }", self.backup)

    def test_local_backup_and_cloud_merge_do_not_erase_favorites(self):
        store = self.live.split("final class LiveRoutesStore {", 1)[1].split(
            "private enum LiveRouteError", 1
        )[0]
        self.assertIn('appendingPathComponent("LiveRoutes.json")', store)
        self.assertIn("routes[index].modifiedAt = .now", store)
        self.assertIn("modifiedAt = try values.decodeIfPresent", self.live)
        self.assertIn("deletedIDs.union(remote.deletedIDs)", store)
        self.assertIn("route.modifiedAt > existing.modifiedAt", store)
        self.assertIn("route.isFavorite && !existing.isFavorite", store)
        self.assertIn("try persist(scheduleCloud: false)", store)
        self.assertIn("cloudSyncRequestedAgain = true", store)
        self.assertIn("LiveRouteCloudBackup.shared.write(archive)", store)
        self.assertIn("UserDefaults.standard.set(erased.map(", store)
        self.assertIn("requestICloudSynchronization()", store)

    def test_recorded_gps_walking_routes_are_archived_when_saved(self):
        save = self.live.split("private func saveRecordedActivity()", 1)[1].split(
            "private var routeSheet:", 1
        )[0]
        self.assertIn("session.routePoints.count >= 2", save)
        self.assertIn("recorder.sport.usesGPS", save)
        self.assertIn("session.liveRouteID = try routes.addRecordedRoute(from: session)", save)
        self.assertIn("store.saveWorkout(session)", save)

    def test_home_load_route_switches_to_start_and_opens_library_without_play(self):
        self.assertIn("var onLoadRoutes: () -> Void", self.home)
        self.assertIn('Text("Cargar ruta")', self.home)
        self.assertIn("Button(action: onLoadRoutes)", self.home)
        self.assertIn("routePickerRequest &+= 1", self.root)
        self.assertIn("tab = .start", self.root)
        self.assertIn("routeLibraryOpenRequest: routePickerRequest", self.root)
        self.assertIn("openRequestedRouteLibrary()", self.live)
        self.assertIn("handledRouteLibraryOpenRequest = routeLibraryOpenRequest", self.live)
        self.assertIn("routePicker = true", self.live)
        self.assertIn("recorder.phase == .idle", self.live)
        # The selection prepares the course; starting remains an explicit Play.
        self.assertIn("recorder.selectRoute(selected)", self.live)

    def test_home_calendar_uses_one_planning_index_not_105_queries(self):
        self.assertIn("let lookup = makeCalendarDayLookup()", self.home)
        self.assertIn("makeWeekDays(offset: offset, lookup: lookup)", self.home)
        self.assertIn("private func makeCalendarDayLookup()", self.home)
        self.assertIn("startsByOccurrence[booking.occurrenceId]", self.home)
        week = self.home.split("private func makeWeekDays(", 1)[1].split(
            "private func dayKey(", 1
        )[0]
        self.assertIn("let indexed = lookup ?? makeCalendarDayLookup()", week)
        self.assertNotIn("for routine in store.state.routines", week)
        self.assertNotIn("businessData.occurrences.first(where:", week)
        self.assertIn("LazyVStack(spacing: 6)", self.home)

    def test_home_reloading_does_not_show_black_gap_and_tab_transition_is_shorter(self):
        self.assertIn(".background(OG.surface.ignoresSafeArea())", self.home)
        self.assertNotIn(".frame(height: 360, alignment: .top)", self.home)
        self.assertIn(".animation(.easeOut(duration: 0.18), value: flowPath.isEmpty)", self.root)
        self.assertIn("businessCalendarSignature: Int", self.home)
        self.assertNotIn('(training + reservations + occurrences).sorted().joined', self.home)

if __name__ == "__main__":
    unittest.main()
