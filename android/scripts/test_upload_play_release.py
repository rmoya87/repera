"""Safety checks for the Google Play Publisher integration (offline, no credentials)."""
import tempfile
import unittest
import zipfile
from pathlib import Path

from upload_play_release import (
    BUNDLE_MAPPING_PATH,
    disable_httplib2_308_redirects,
    has_embedded_mapping,
    make_release,
    parse_tracks,
)


class PlayUploadSafetyTests(unittest.TestCase):
    def test_only_internal_and_closed_tracks(self):
        self.assertEqual(["internal", "alpha"], parse_tracks("internal,alpha"))
        self.assertEqual(["internal", "grupo-a"], parse_tracks("internal,grupo-a"))
        for text in ("production", "internal", "internal,beta", "internal,production",
                     "internal,internal", "alpha,internal", "internal,alpha,production",
                     "internal,invalid/track"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                parse_tracks(text)

    def test_release_notes_and_version_code(self):
        result = make_release("alpha", "2026.11.2", 451800, "Mejoras internas.")
        self.assertEqual(["451800"], result["releases"][0]["versionCodes"])
        self.assertEqual("completed", result["releases"][0]["status"])
        self.assertEqual("es-ES", result["releases"][0]["releaseNotes"][0]["language"])
        for notes in ("", "x" * 501):
            with self.assertRaises(ValueError):
                make_release("alpha", "2026.11.2", 451800, notes)

    def test_bundle_mapping_detection(self):
        with tempfile.TemporaryDirectory() as directory:
            bundle = Path(directory) / "app.aab"
            with zipfile.ZipFile(bundle, "w") as zf:
                zf.writestr("base/manifest/AndroidManifest.xml", b"test")
            self.assertFalse(has_embedded_mapping(bundle))
            with zipfile.ZipFile(bundle, "a") as zf:
                zf.writestr(BUNDLE_MAPPING_PATH, b"mapping")
            self.assertTrue(has_embedded_mapping(bundle))

    def test_httplib2_308_is_not_treated_as_redirect(self):
        # Play MediaFileUpload needs raw 308 responses; following them breaks CI.
        import sys
        import types

        fake = types.ModuleType("httplib2")
        fake.REDIRECT_CODES = frozenset({301, 302, 303, 307, 308})
        previous = sys.modules.get("httplib2")
        sys.modules["httplib2"] = fake
        try:
            disable_httplib2_308_redirects()
            self.assertNotIn(308, fake.REDIRECT_CODES)
            self.assertIn(307, fake.REDIRECT_CODES)
        finally:
            if previous is None:
                sys.modules.pop("httplib2", None)
            else:
                sys.modules["httplib2"] = previous


if __name__ == "__main__":
    unittest.main()
