#!/usr/bin/env python3
"""Contrato: preflight local + Play gate en main antes de promover a beta."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PREFLIGHT = (ROOT / "scripts/play_preflight.sh").read_text(encoding="utf-8")
PROMOTE = (ROOT / "scripts/promote_to_beta.sh").read_text(encoding="utf-8")
GATE = (ROOT / ".github/workflows/play-gate.yml").read_text(encoding="utf-8")
ANDROID_CI = (ROOT / ".github/workflows/android-native-ci.yml").read_text(encoding="utf-8")
AGENTS = (ROOT / "AGENTS.md").read_text(encoding="utf-8")


class PlayDeployGateContractTests(unittest.TestCase):
    def test_preflight_covers_jvm_and_android_test_compile(self):
        for needle in (
            ":domain:testDebugUnitTest",
            ":wear:testDebugUnitTest",
            ":mobile:assembleDebug",
            ":wear:assembleDebug",
            ":mobile:testDebugUnitTest",
            ":mobile:compileDebugAndroidTestKotlin",
            ":wear:compileDebugAndroidTestKotlin",
            "test_*play*.py",
        ):
            self.assertIn(needle, PREFLIGHT)

    def test_play_gate_workflow_runs_preflight_on_main(self):
        self.assertIn("name: Play gate", GATE)
        push = GATE.split("on:", 1)[1].split("concurrency:", 1)[0]
        self.assertIn("- main", push)
        self.assertNotIn("- beta", push.split("pull_request:", 1)[0])
        self.assertIn("bash scripts/play_preflight.sh", GATE)
        self.assertIn("PLAY_PREFLIGHT_USE_SYSTEM_GRADLE", GATE)

    def test_android_native_ci_uses_same_preflight_script(self):
        # Misma batería en beta antes de emuladores: evita androidTest roto
        # gastando runners de emulator.
        self.assertIn("bash scripts/play_preflight.sh", ANDROID_CI)
        self.assertIn("PLAY_PREFLIGHT_USE_SYSTEM_GRADLE", ANDROID_CI)

    def test_promote_requires_gate_before_beta_push(self):
        self.assertIn("play_preflight.sh", PROMOTE)
        self.assertIn("Play gate", PROMOTE)
        self.assertIn("origin/main", PROMOTE)
        self.assertIn('git push origin "HEAD:beta"', PROMOTE)
        self.assertIn("--skip-local", PROMOTE)

    def test_agents_documents_promote_path(self):
        self.assertIn("promote_to_beta.sh", AGENTS)
        self.assertIn("play_preflight.sh", AGENTS)


if __name__ == "__main__":
    unittest.main()
