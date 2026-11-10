"""Release-merged Android manifest advertising-permission safety tests."""
import tempfile
import unittest
from pathlib import Path

from verify_play_permissions import validate_release_manifest


class PlayPermissionsTest(unittest.TestCase):
    def create_manifest(self, root: Path, permissions: list[str]) -> Path:
        path = root / "merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml"
        path.parent.mkdir(parents=True, exist_ok=True)
        content = ['<manifest xmlns:android="http://schemas.android.com/apk/res/android">']
        content.extend(f'<uses-permission android:name="{name}" />' for name in permissions)
        content.append('</manifest>')
        path.write_text("\n".join(content), encoding="utf-8")
        return path

    def test_no_advertising_permissions_pass(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.create_manifest(root, ["android.permission.INTERNET"])
            self.assertEqual(1, len(validate_release_manifest(root)))

    def test_ads_permission_blocks_release(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.create_manifest(root, ["android.permission.ACCESS_ADSERVICES_ATTRIBUTION"])
            with self.assertRaisesRegex(ValueError, "ACCESS_ADSERVICES_ATTRIBUTION"):
                validate_release_manifest(root)

    def test_missing_manifest_blocks_release(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(FileNotFoundError):
                validate_release_manifest(Path(tmp))


if __name__ == "__main__":
    unittest.main()
