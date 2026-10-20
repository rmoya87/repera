#!/usr/bin/env python3
"""Validate that double-click Xcode recovery can fast-forward without data loss."""
from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "update_repera_checkout.sh"


def git(path: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(path), *args], text=True).strip()


def run_script(path: Path) -> str:
    return subprocess.check_output(
        ["bash", str(SCRIPT), str(path)], text=True, stderr=subprocess.STDOUT
    )


class SafeXcodeCheckoutUpdateTests(unittest.TestCase):
    def setUp(self) -> None:
        temp = tempfile.TemporaryDirectory(prefix="repera-xcode-source-")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        self.remote = root / "origin.git"
        self.author = root / "author"
        self.local = root / "local"
        subprocess.run(["git", "init", "--bare", str(self.remote)], check=True, capture_output=True)
        subprocess.run(["git", "clone", str(self.remote), str(self.author)], check=True, capture_output=True)
        git(self.author, "config", "user.email", "repera-tests@example.invalid")
        git(self.author, "config", "user.name", "Repera CI")
        git(self.author, "checkout", "-b", "main")
        (self.author / "README.md").write_text("Initial repo\n", encoding="utf-8")
        git(self.author, "add", "README.md")
        git(self.author, "commit", "-qm", "initial")
        git(self.author, "push", "-q", "-u", "origin", "main")
        subprocess.run(["git", "clone", "-b", "main", str(self.remote), str(self.local)], check=True, capture_output=True)

    def add_remote_source(self) -> str:
        sources = self.author / "Apps" / "Repera" / "Sources"
        sources.mkdir(parents=True, exist_ok=True)
        (sources / "BusinessWorkoutSyncStore.swift").write_text(
            "final class BusinessWorkoutSyncStore {}\n", encoding="utf-8"
        )
        git(self.author, "add", ".")
        git(self.author, "commit", "-qm", "add sync store")
        git(self.author, "push", "-q", "origin", "main")
        return git(self.author, "rev-parse", "HEAD")

    def test_clean_main_fast_forwards_to_missing_swift_store(self) -> None:
        remote_head = self.add_remote_source()
        self.assertFalse((self.local / "Apps/Repera/Sources/BusinessWorkoutSyncStore.swift").exists())
        output = run_script(self.local)
        self.assertIn("fast-forward", output)
        self.assertEqual(git(self.local, "rev-parse", "HEAD"), remote_head)
        self.assertTrue((self.local / "Apps/Repera/Sources/BusinessWorkoutSyncStore.swift").exists())

    def test_uncommitted_changes_are_not_overwritten(self) -> None:
        remote_head = self.add_remote_source()
        (self.local / "README.md").write_text("Personal modifications\n", encoding="utf-8")
        before = git(self.local, "rev-parse", "HEAD")
        output = run_script(self.local)
        self.assertIn("cambios locales", output)
        self.assertEqual(git(self.local, "rev-parse", "HEAD"), before)
        self.assertNotEqual(before, remote_head)
        self.assertEqual((self.local / "README.md").read_text(), "Personal modifications\n")

    def test_feature_branch_is_not_changed(self) -> None:
        self.add_remote_source()
        git(self.local, "checkout", "-b", "feature/wip")
        before = git(self.local, "rev-parse", "HEAD")
        output = run_script(self.local)
        self.assertIn("No cambio de rama", output)
        self.assertEqual(git(self.local, "symbolic-ref", "--short", "HEAD"), "feature/wip")
        self.assertEqual(git(self.local, "rev-parse", "HEAD"), before)

    def test_environment_can_disable_all_git_network_work(self) -> None:
        self.add_remote_source()
        before = git(self.local, "rev-parse", "HEAD")
        output = subprocess.check_output(
            ["bash", str(SCRIPT), str(self.local)],
            env={**os.environ, "REPERA_SKIP_GIT_UPDATE": "1"}, text=True
        )
        self.assertIn("omitida", output)
        self.assertEqual(git(self.local, "rev-parse", "HEAD"), before)


if __name__ == "__main__":
    unittest.main()
