import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from check_xcode_sources import validate


class XcodeSourceMembershipTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        directory = self.root / "Apps/Repera/Sources"
        directory.mkdir(parents=True)
        (directory / "Onboarding").mkdir()
        (directory / "Onboarding/AppleAuthStore.swift").write_text("// Apple", encoding="utf-8")
        (directory / "BusinessAuthStore.swift").write_text("// Supabase", encoding="utf-8")
        (directory / "BusinessDataStore.swift").write_text("// Business", encoding="utf-8")
        (directory / "BusinessWorkoutSyncStore.swift").write_text("// Workout Sync", encoding="utf-8")
        (self.root / "project.yml").write_text(
            "targets:\n  Repera:\n    sources:\n      - path: Apps/Repera/Sources\n"
            "    dependencies:\n      - package: Supabase\n        product: Supabase\n",
            encoding="utf-8",
        )
        (self.root / "Repera.xcodeproj").mkdir()
        self.pbx = self.root / "Repera.xcodeproj/project.pbxproj"
        self.pbx.write_text(
            "AppleAuthStore.swift in Sources\nBusinessAuthStore.swift in Sources\n"
            "BusinessDataStore.swift in Sources\n"
            "BusinessWorkoutSyncStore.swift in Sources", encoding="utf-8"
        )

    def test_current_generated_project(self):
        validate(self.root)

    def test_stale_generated_project_is_rejected(self):
        self.pbx.write_text("AppleAuthStore.swift in Sources", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "BusinessAuthStore.swift"):
            validate(self.root)

    def test_outdated_checkout_is_rejected(self):
        (self.root / "Apps/Repera/Sources/BusinessAuthStore.swift").unlink()
        with self.assertRaisesRegex(ValueError, "git pull origin main"):
            validate(self.root)

    def test_missing_workout_sync_store_requires_checkout_update(self):
        (self.root / "Apps/Repera/Sources/BusinessWorkoutSyncStore.swift").unlink()
        with self.assertRaisesRegex(ValueError, "BusinessWorkoutSyncStore.swift"):
            validate(self.root)

    def test_stale_workout_sync_target_is_rejected(self):
        pbx = self.pbx.read_text(encoding="utf-8")
        self.pbx.write_text(
            pbx.replace("BusinessWorkoutSyncStore.swift in Sources", ""),
            encoding="utf-8",
        )
        with self.assertRaisesRegex(ValueError, "BusinessWorkoutSyncStore.swift"):
            validate(self.root)

    def test_file_reference_without_compile_sources_is_rejected(self):
        pbx = self.pbx.read_text(encoding="utf-8")
        self.pbx.write_text(
            pbx.replace("BusinessWorkoutSyncStore.swift in Sources",
                        "BusinessWorkoutSyncStore.swift /* file only */"),
            encoding="utf-8",
        )
        with self.assertRaisesRegex(ValueError, "BusinessWorkoutSyncStore.swift"):
            validate(self.root)


if __name__ == "__main__":
    unittest.main()
