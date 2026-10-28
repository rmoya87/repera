"""Evita que la marca anterior reaparezca en los archivos versionados.

Se utiliza git grep sobre el árbol completo, no solamente Swift o la app iOS.
"""
from pathlib import Path
import re
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
# Construido en tiempo de ejecución para no añadir el propio nombre antiguo
# al repositorio durante la comprobación.
LEGACY_PATTERN = "open" + r"[[:space:]_.-]*" + "gym"
PATH_PATTERN = re.compile("open" + r"[\s_.-]*" + "gym", re.IGNORECASE)


class LegacyBrandReferencesContract(unittest.TestCase):
    def test_no_legacy_brand_in_tracked_text(self):
        result = subprocess.run(
            ["git", "grep", "-I", "-n", "-i", "-E", LEGACY_PATTERN, "--", "."],
            cwd=ROOT, text=True, capture_output=True, check=False
        )
        self.assertEqual(
            result.returncode, 1,
            "Una referencia a la marca anterior ha reaparecido: "
            + (result.stdout if result.returncode == 0 else result.stderr)
        )

    def test_no_legacy_brand_in_tracked_paths(self):
        result = subprocess.run(
            ["git", "ls-files", "-z"], cwd=ROOT, capture_output=True, check=True
        )
        paths = result.stdout.decode("utf-8").split("\0")
        matches = [path for path in paths if path and PATH_PATTERN.search(path)]
        self.assertEqual(matches, [])


if __name__ == "__main__":
    unittest.main()
