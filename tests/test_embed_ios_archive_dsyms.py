"""Contract: Firebase SPM archive dSYM embed wiring stays in the XcodeGen project."""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "embed_ios_archive_dsyms.sh"
PROJECT_YML = ROOT / "project.yml"


class EmbedIosArchiveDsymsTests(unittest.TestCase):
    def test_script_exists_and_is_executable(self) -> None:
        self.assertTrue(SCRIPT.is_file(), f"missing {SCRIPT}")
        self.assertTrue(os.access(SCRIPT, os.X_OK), f"not executable: {SCRIPT}")

    def test_project_yml_wires_build_phase_and_archive_post_action(self) -> None:
        text = PROJECT_YML.read_text(encoding="utf-8")
        self.assertIn("scripts/embed_ios_archive_dsyms.sh", text)
        self.assertIn("Embed framework dSYMs in archive", text)
        self.assertIn("DEBUG_INFORMATION_FORMAT: dwarf-with-dsym", text)
        self.assertIn("runOnlyWhenInstalling: true", text)
        self.assertIn("--archive", text)

    def test_help_exits_zero(self) -> None:
        result = subprocess.run(
            [str(SCRIPT), "--help"],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--archive", result.stdout)

    def test_archive_mode_rejects_missing_path(self) -> None:
        missing = Path(tempfile.gettempdir()) / "repera-missing.xcarchive"
        if missing.exists():
            missing.unlink()
        result = subprocess.run(
            [str(SCRIPT), "--archive", str(missing)],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("archive not found", result.stderr)

    def test_build_phase_skips_when_not_installing(self) -> None:
        env = os.environ.copy()
        env["ACTION"] = "build"
        result = subprocess.run(
            [str(SCRIPT)],
            check=False,
            capture_output=True,
            text=True,
            env=env,
        )
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
