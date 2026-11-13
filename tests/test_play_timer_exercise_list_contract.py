"""Play block timer shows the block exercise list with active highlight."""

from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


class PlayTimerExerciseListContract(unittest.TestCase):
    def test_ios_fullscreen_clock_builds_block_rows(self):
        play = read("Apps/Repera/Sources/WorkoutView.swift")
        clock = play.split("private var wodFullscreenClock: some View", 1)[1].split(
            "private func presentWODConfirmIfNeeded()", 1
        )[0]
        self.assertIn("exerciseRows: rows", clock)
        self.assertIn("blockTimerExerciseRows(clock:", play)
        self.assertIn("activeTimerWorkIndex(", play)
        self.assertIn("case .emom, .deathBy:", play)
        self.assertIn("intervalIndex % workCount", play)
        active = play.split("private func activeTimerWorkIndex(", 1)[1].split(
            "private func presentWODConfirmIfNeeded()", 1
        )[0]
        self.assertIn("case .forTime, .chipper, .afap, .ladder, .buyInCashOut,", active)
        self.assertIn("return nil", active)
        detail = play.split("private func timerPrescriptionDetail(", 1)[1].split(
            "private func activeTimerWorkIndex(", 1
        )[0]
        self.assertIn('joined(separator: "-")', detail)
        self.assertIn("compactRepsSummary", detail)

    def test_ios_row_layout_is_image_left_name_and_sets_right(self):
        screen = read("Apps/Repera/Sources/DigitalClockDisplay.swift")
        self.assertIn("struct BlockTimerExerciseRow", screen)
        list_block = screen.split("private var exerciseList: some View", 1)[1].split(
            "private func exerciseDetails(", 1
        )[0]
        self.assertIn("HStack(alignment: .center, spacing: 12)", list_block)
        self.assertIn("ExerciseThumb(exercise: exercise, size: 52)", list_block)
        self.assertIn("row.detail", list_block)
        self.assertIn("row.isActive", list_block)

    def test_android_clock_builds_shared_list(self):
        clock = read("android/mobile/src/main/java/dev/repera/mobile/WodClockScreen.kt")
        self.assertIn("buildTimerExerciseRows(", clock)
        self.assertIn("ExerciseListBlock", clock)
        self.assertIn("WodFormat.EMOM", clock)
        self.assertIn("activeInterval % work.size", clock)
        rows = clock.split("private fun buildTimerExerciseRows(", 1)[1]
        # AFAP/Escalera no marcan el primer movimiento.
        self.assertIn("else -> null", rows.split("val activeWork = when", 1)[1].split(
            "var workOrdinal", 1
        )[0])
        self.assertIn("move.repScheme.joinToString(\"-\")", rows)
        repo = read(
            "android/mobile/src/main/java/dev/repera/mobile/WorkoutRepository.kt"
        )
        self.assertIn("timerPrescriptionDetailLine(", repo)
        self.assertIn('wave.joinToString("-")', repo)

    def test_timer_end_returns_to_play_without_finishing_workout(self):
        play = read("Apps/Repera/Sources/WorkoutView.swift")
        clock = read("Apps/Repera/Sources/WorkoutClockCoordinator.swift")
        android = read("android/mobile/src/main/java/dev/repera/mobile/WodClockScreen.kt")
        repo = read("android/mobile/src/main/java/dev/repera/mobile/WorkoutRepository.kt")
        finish = clock.split("private func finishComplete()", 1)[1].split(
            "private func publishLiveAndAlerts()", 1
        )[0]
        self.assertIn("isVisible = false", finish)
        self.assertIn("pendingEndReason = .countdownFinished", finish)
        score = play.split("store.applyWODResult(result)", 1)[1].split(
            ".id(\"\\(block.id.uuidString)", 1
        )[0]
        self.assertNotIn("store.finishCurrentTimedBlock()", score)
        self.assertNotIn("closeFlow()", score)
        self.assertIn("face.finishedIntervals", android)
        auto = android.split("wasFinishedOnOpen = true", 1)[1].split(
            "var lastRestLabel", 1
        )[0]
        self.assertIn("onFinished()", auto)
        self.assertNotIn("onBack()", auto)
        shell = read(
            "android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt"
        )
        self.assertIn("finishBlockClockAndReturnToPlay()", shell)
        self.assertIn('popBackStack("entreno-activo", inclusive = false)', shell)
        self.assertNotIn("clearFormatAfterClock", shell)
        play_ui = read(
            "android/mobile/src/main/java/dev/repera/mobile/ActiveWorkoutScreen.kt"
        )
        self.assertIn("suppressDisposeFlush", play_ui)
        self.assertIn("PlayBlockFormatStore", play_ui)
        self.assertIn("persistFormatOverride", play_ui)
        self.assertIn("ensurePlayDraftable", play_ui)
        main = read(
            "android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt"
        )
        self.assertIn("enqueueActivePlanUpdate", main)
        self.assertIn(
            "object PlayBlockFormatStore",
            read(
                "android/mobile/src/main/java/dev/repera/mobile/PlayBlockFormatStore.kt"
            ),
        )
        record = repo.split("fun recordWodScore(", 1)[1].split(
            "fun recordWodMovement(", 1
        )[0]
        self.assertNotIn("finishInPlace(state, session)", record)

    def test_android_clock_edge_to_edge_black_and_spacing_under_minimize(self):
        shell = read("android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt")
        clock = read("android/mobile/src/main/java/dev/repera/mobile/WodClockScreen.kt")
        play = read(
            "android/mobile/src/main/java/dev/repera/mobile/ActiveWorkoutScreen.kt"
        )
        self.assertIn("val ledClockEdge = currentRoute == \"reloj\"", shell)
        self.assertIn("mapUnderTabs || inicioEdge || ledClockEdge", shell)
        self.assertIn("Spacer(Modifier.height(20.dp))", clock)
        self.assertIn("statusBarsPadding()", clock)
        self.assertIn("Color.Black", clock)
        # Minimizar: slide vertical (no horizontal de detalle) + dock animado.
        self.assertIn("isClockRoute", shell)
        self.assertIn("slideOutVertically", shell)
        self.assertIn("slideInVertically", shell)
        self.assertIn("AnimatedVisibility", play)
        self.assertIn("slideInVertically", play)

    def test_android_minimize_shows_bar_for_manual_clock(self):
        """Fuerza/libre: Minimizar debe mostrar dock, no desaparecer el reloj."""
        bar = read(
            "android/mobile/src/main/java/dev/repera/mobile/MinimizedWodClockBar.kt"
        )
        play = read(
            "android/mobile/src/main/java/dev/repera/mobile/ActiveWorkoutScreen.kt"
        )
        shell = read(
            "android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt"
        )
        clock = read(
            "android/mobile/src/main/java/dev/repera/mobile/WodClockScreen.kt"
        )
        self.assertIn("manualConfig: ManualBlockTimerConfig? = null", bar)
        self.assertIn("launchConfig: BlockClockLaunchConfig? = null", bar)
        self.assertIn("launch != null -> launch.toSpec()", bar)
        self.assertIn("BlockClockLaunchConfig.fromManual", bar)
        self.assertNotIn("active.wod ?: return", bar)
        self.assertIn("Finalizar", bar)
        self.assertIn("minimized_wod_finish", bar)
        self.assertNotIn('"Abrir"', bar)
        self.assertIn("manualClockConfig: ManualBlockTimerConfig? = null", play)
        # Dock fijo abajo (no ítem LazyColumn).
        self.assertIn("align(Alignment.BottomCenter)", play)
        self.assertIn("LocalReperaTabBarInset.current", play)
        self.assertIn("onFinishMinimizedClock", play)
        call = play.split("MinimizedWodClockBar(", 1)[1].split(
            "WorkoutUndoSnackbarHost(", 1
        )[0]
        self.assertIn("manualConfig = manualClockConfig", call)
        self.assertIn("onFinish = onFinishMinimizedClock", call)
        self.assertIn("manualClockConfig = manualClockConfig", shell)
        self.assertIn("onFinishMinimizedClock = {", shell)
        self.assertIn('onWodTimerAction("finish")', shell)
        self.assertIn("finishBlockClockAndReturnToPlay()", shell)
        self.assertNotIn("clearFormatAfterClock", shell)
        self.assertNotIn("clearCurrentBlockFormat()", call)
        minimize = shell.split('composable("reloj")', 1)[1].split(
            'composable("deportes")', 1
        )[0]
        self.assertIn("clockMinimized = true", minimize)
        self.assertIn('popBackStack("entreno-activo", inclusive = false)', minimize)
        # Abrir ya finalizado no debe auto-pop al instante.
        self.assertIn("wasFinishedOnOpen", clock)
        self.assertIn("mutableStateOf(face.finishedIntervals)", clock)


if __name__ == "__main__":
    unittest.main()
