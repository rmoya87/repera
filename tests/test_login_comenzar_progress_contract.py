"""Contratos fuente: token Supabase, Comenzar, mapa y Progreso de deportes.

Estos tests no sustituyen pruebas iOS/watchOS reales de audio, HealthKit o UI.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps/Repera/Sources"
DOMAIN = ROOT / "Packages/ReperaDomain/Sources/ReperaDomain"


def text(path):
    return path.read_text(encoding="utf-8")


class LoginComenzarProgressContracts(unittest.TestCase):
    def test_supabase_expired_session_refreshes_without_manual_logout(self):
        auth = text(IOS / "BusinessAuthStore.swift")
        app = text(IOS / "ReperaApp.swift")
        sync = text(IOS / "BusinessWorkoutSyncStore.swift")
        self.assertIn("autoRefreshToken: true", auth)
        self.assertIn("func ensureUsableSession() async -> Bool", auth)
        self.assertIn("let session = try await client.auth.session", auth)
        self.assertIn("try await client.auth.refreshSession()", auth)
        self.assertIn("private(set) var requiresReauthentication = false", auth)
        self.assertIn("Self.isUnrecoverableAuthError(error)", auth)
        self.assertIn("!businessAuth.requiresReauthentication", app)
        self.assertIn("await businessAuth.ensureUsableSession()", app)
        self.assertIn("await BusinessAuthStore.shared.ensureUsableSession()", sync)
        self.assertNotIn("Nunca caduque", auth)
        # El SDK fijado puede no disponer de AuthError.kind.
        auth_classifier = auth.split("private static func isUnrecoverableAuthError(", 1)[1].split("private func ", 1)[0]
        self.assertIn("switch authError.errorCode", auth_classifier)
        self.assertNotIn("authError.kind", auth_classifier)
        self.assertIn("return false", auth_classifier)

    def test_comenzar_kilometer_uses_voice_instead_of_push(self):
        source = text(IOS / "LiveActivityView.swift")
        km = source.split("private func reportKilometer(", 1)[1].split(
            "private func updateUpcomingTurn(", 1
        )[0]
        self.assertIn("speakNavigation(message)", km)
        # Solo se recurre a una notificación cuando iOS no activa el audio;
        # un aviso correcto nunca genera un duplicado visual.
        self.assertIn("if spokenGuidanceEnabled && !didSpeak", km)
        self.assertIn("fallbackWhenSpeechFailed: true", km)
        self.assertIn("setCategory(", source)
        self.assertIn(".playback, mode: .spokenAudio", source)
        self.assertIn("guard spokenGuidanceEnabled, !message.isEmpty else", source)
        self.assertIn("pendingGuidanceUtterances", source)
        self.assertIn("finishGuidanceUtterance(id)", source)

    def test_recaps_show_average_tiles_and_expand_routes(self):
        live = text(IOS / "LiveActivityView.swift")
        splits = text(IOS / "CardioRouteComponents.swift")
        maps = text(IOS / "HistoryView.swift")
        self.assertIn("private var averagePace: String?", splits)
        self.assertIn('title: "Vel. media"', splits)
        self.assertIn('title: "Vel. máx"', splits)
        self.assertIn('title: "Ritmo medio"', splits)
        self.assertIn("struct SessionSportMetricTile: View", splits)
        self.assertIn("healthStats: previewHealthExtras", live)
        self.assertIn("totalActiveSeconds: session.activeDurationSeconds", live)
        self.assertIn("totalDistanceMeters: session.recordedDistanceMeters", live)
        self.assertIn("navigationDestination(isPresented: $showFullScreenRoute)", live)
        self.assertIn('sourceID: "live-review-route", in: routeZoomNamespace', live)
        self.assertIn("WorkoutMapZoomDestination(", live)
        self.assertIn("Abrir recorrido a pantalla completa", live)
        self.assertIn("WorkoutMapTapTarget(", live)
        self.assertIn("struct WorkoutMapTapTarget<MapPreview: View>: View", maps)
        self.assertIn("Rectangle()", maps)
        self.assertIn(".fill(Color.clear)", maps)
        self.assertIn(".contentShape(Rectangle())", maps)
        self.assertIn(".allowsHitTesting(false)", maps)
        self.assertIn('Image(systemName: "xmark")', live)
        self.assertIn("isWaterSport: recorder.sport.isWaterSport", live)
        self.assertIn("extras.hasExternalSaludSource", live)
        self.assertIn("let matchedUUID = extras.resolvedWorkoutUUID", live)
        self.assertIn("session.healthKitWorkoutUUID = matchedUUID", live)
        self.assertIn("session.appleAverageHeartRateBpm = extras.averageHeartRateBpm", live)
        self.assertIn("isSavingRecordedActivity", live)
        review = live.split("private var review: some View", 1)[1].split(
            "private func reviewTile(", 1
        )[0]
        self.assertNotIn('Text(isRecordedRoute ? "Recorrido registrado"', review)
        self.assertNotIn('"%.1f km/h de media"', review)
        self.assertIn("navigationDestination(isPresented: $showFullScreenRoute)", maps)
        self.assertIn(".navigationTransition(.zoom(sourceID: sessionId, in: routeZoomNamespace))", maps)
        self.assertEqual(maps.count(".matchedTransitionSource(id: sessionId, in: routeZoomNamespace)"), 3)
        self.assertIn(".glassEffect(.regular, in: .circle)", maps)
        self.assertIn("colorScheme == .dark ? Color.white : Color.black", maps)
        self.assertIn("struct WorkoutMapZoomDestination: View", maps)
        self.assertIn(".matchedTransitionSource(id: activityId, in: routeZoomNamespace)", maps)
        self.assertIn("isInteractive: true", maps)
        self.assertIn("MapPolygon(coordinates: routeBackdrop)", maps)
        self.assertIn("Color.black.opacity(0.33)", maps)
        self.assertIn(".mapOverlayLevel(level: .aboveRoads)", maps)
        self.assertEqual(maps.count(".mapOverlayLevel(level: .aboveLabels)"), 3)
        self.assertIn("segment.color.opacity(0.35), lineWidth: 19", maps)
        self.assertIn("LinearGradient(", maps)
        self.assertIn("lineWidth: 11", maps)
        self.assertIn(".stroke(segment.color, lineWidth: 6)", maps)
        self.assertIn("var isWaterSport: Bool = false", maps)
        self.assertIn("water ? (0.00, 1.00, 0.45) : (0.00, 1.00, 0.25)", maps)
        self.assertIn("(1.00, 0.98, 0.00), (1.00, 0.43, 0.00), (1.00, 0.07, 0.15)", maps)
        self.assertNotIn("(0.06, 0.39, 0.98)", maps)

    def test_cardio_fatigue_and_records_include_start_sports_without_fake_e1rm(self):
        health = text(IOS / "HealthMuscleMapper.swift")
        progress = text(IOS / "ProgressSnapshot.swift")
        sport = text(IOS / "LiveSportHistoryView.swift")
        stats = text(IOS / "StatsView.swift")
        self.assertIn("nativeSportStimuli(from: input.workouts)", progress)
        self.assertIn("HealthMuscleMapper.uniqueExternalActivities(", progress)
        self.assertIn("nativeHighEffortSportStimuli(from: input.workouts)", progress)
        self.assertIn("filteredHighEffortStimuli", progress)
        self.assertIn("case .highIntensityIntervalTraining, .crossTraining", health)
        self.assertNotIn("case .walking, .hiking:", health.split("private static func isEstimatedIntense", 1)[1].split("static func highEffortStimuli", 1)[0])
        self.assertIn("fastestRecordedKilometerSeconds", sport)
        self.assertIn("longestDistanceMeters", sport)
        self.assertIn('Section("Mejores marcas', sport)
        self.assertIn("LiveSportsCatalogView()", stats)
        self.assertIn("Deportes · evolución y récords", stats)

    def test_multiple_workouts_day_remain_independent(self):
        store = text(IOS / "ReperaStore.swift")
        home = text(IOS / "HomeView.swift")
        self.assertIn("func scheduledRoutines(on date: Date) -> [Routine]", store)
        self.assertIn("ForEach(planned) { routine in", home)
        self.assertIn("ForEach(workouts) { session in", home)


if __name__ == "__main__":
    unittest.main()
