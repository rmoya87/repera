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

    def test_comenzar_kilometer_uses_voice_instead_of_push(self):
        source = text(IOS / "LiveActivityView.swift")
        km = source.split("private func reportKilometer(", 1)[1].split(
            "private func updateUpcomingTurn(", 1
        )[0]
        self.assertIn("speakNavigation(message)", km)
        self.assertNotIn("notifyDuringBackground(", km)
        self.assertIn("setCategory(", source)
        self.assertIn(".playback, mode: .spokenAudio", source)
        self.assertIn("guard spokenGuidanceEnabled else", source)
        self.assertIn("!self.speechSynthesizer.isSpeaking", source)

    def test_recaps_show_average_tiles_and_expand_routes(self):
        live = text(IOS / "LiveActivityView.swift")
        splits = text(IOS / "CardioRouteComponents.swift")
        maps = text(IOS / "HistoryView.swift")
        self.assertIn("private var averagePace: String?", splits)
        self.assertIn('averageStat("Ritmo medio"', splits)
        self.assertIn('averageStat("Velocidad media"', splits)
        self.assertIn("totalActiveSeconds: session.activeDurationSeconds", live)
        self.assertIn("totalDistanceMeters: session.recordedDistanceMeters", live)
        self.assertIn("fullScreenCover(isPresented: $showFullScreenRoute)", live)
        self.assertIn("Abrir recorrido a pantalla completa", live)
        self.assertIn('Image(systemName: "xmark")', live)
        self.assertIn("isWaterSport: recorder.sport.isWaterSport", live)
        review = live.split("private var review: some View", 1)[1].split(
            "private func reviewTile(", 1
        )[0]
        self.assertNotIn('Text(isRecordedRoute ? "Recorrido registrado"', review)
        self.assertNotIn('"%.1f km/h de media"', review)
        self.assertIn("fullScreenCover(isPresented: $showFullScreenRoute)", maps)
        self.assertIn("var isWaterSport: Bool = false", maps)
        self.assertIn("water ? (0.08, 0.72, 0.31) : (0.06, 0.39, 0.98)", maps)

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
