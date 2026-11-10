"""Contratos: resumen de sesión listo de una vez + skeleton (teléfono)."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


class SessionDetailReadyContractTests(unittest.TestCase):
    def test_ios_workout_detail_gates_on_is_detail_ready_with_skeleton(self):
        history = read("Apps/Repera/Sources/HistoryView.swift")
        detail = history.split("struct WorkoutDetailView: View", 1)[1].split(
            "struct HealthActivityDetailView", 1
        )[0]
        self.assertIn("isDetailReady", detail)
        self.assertIn("SessionDetailSkeleton()", detail)
        body = detail.split("var body: some View", 1)[1].split(
            ".onAppear { loadDraft() }", 1
        )[0]
        self.assertIn("isDetailReady", body)
        self.assertIn("SessionDetailSkeleton()", body)
        # No pintar el listado real hasta ready (evita ejercicios→cardio a trozos).
        self.assertIn("if isDetailReady", body)
        loading = detail.split(".task(id: sessionId)", 1)[1].split(
            ".navigationDestination(isPresented: $showFullScreenRoute)", 1
        )[0]
        self.assertIn("milliseconds(100)", loading)
        self.assertIn("milliseconds: 1_200", loading)
        self.assertNotIn("milliseconds(400)", loading)
        self.assertNotIn("milliseconds: 2_500", loading)
        hydrate = detail.split("private func hydrateWorkoutDetail()", 1)[1].split(
            "private func fetchPlaceSuggestion", 1
        )[0]
        # Sync iCloud en Task suelto (no en la ruta crítica await del reveal).
        self.assertIn("Task { @MainActor in", hydrate)
        self.assertIn("await store.refreshFromiCloud()", hydrate)
        self.assertIn("async let suggestedPin", hydrate)
        self.assertIn("async let weather", hydrate)
        # El await de iCloud no va en serie antes de refine/POI/clima.
        critical = hydrate.split("Task { @MainActor in", 1)[0]
        self.assertNotIn("await store.refreshFromiCloud()", critical)

    def test_ios_session_detail_skeleton_exists(self):
        sk = read("Apps/Repera/Sources/SessionDetailSkeleton.swift")
        self.assertIn("struct SessionDetailSkeleton", sk)
        self.assertIn("OG.surface", sk)
        self.assertIn("accessibilityReduceMotion", sk)
        self.assertIn("tileBone", sk)

    def test_ios_route_weather_accepts_prefetch(self):
        cardio = read("Apps/Repera/Sources/CardioRouteComponents.swift")
        self.assertIn("struct RouteWeatherPrefetch", cardio)
        self.assertIn("prefetch: RouteWeatherPrefetch?", cardio)
        self.assertIn("static func load(", cardio)

    def test_android_history_detail_gates_on_detail_ready(self):
        screen = read(
            "android/mobile/src/main/java/dev/repera/mobile/CompleteHistoryScreen.kt"
        )
        fn = screen.split("internal fun WorkoutHistoryDetailScreen(", 1)[1]
        self.assertIn("detailReady", fn)
        self.assertIn("SessionDetailSkeleton(", fn)
        self.assertIn("if (!detailReady)", fn)
        self.assertIn("withTimeoutOrNull(1_200L)", fn)
        self.assertNotIn("weatherJob.await()", fn)
        self.assertIn("movementJob.await()", fn)
        self.assertIn("hrJob.await()", fn)

    def test_android_session_detail_skeleton_exists(self):
        sk = read(
            "android/mobile/src/main/java/dev/repera/mobile/SessionDetailSkeleton.kt"
        )
        self.assertIn("fun SessionDetailSkeleton", sk)


if __name__ == "__main__":
    unittest.main()
