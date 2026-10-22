"""Regression tests for the Watch WidgetKit extension's installation metadata."""
from __future__ import annotations

from pathlib import Path
import plistlib
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from check_watch_widget_plist import validate_built, validate_source


class WatchWidgetPlistTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        widget = self.root / "Apps/ReperaWatchWidget"
        widget.mkdir(parents=True)
        self.source = widget / "Info.plist"
        self.built = self.root / "ReperaWatchWidget.appex/Info.plist"
        self.built.parent.mkdir(parents=True)
        self.data = {
            "CFBundleName": "ReperaWatch",
            "CFBundleDisplayName": "Repera",
            "CFBundleExecutable": "ReperaWatchWidget",
            "CFBundleIdentifier": "com.app.repera.watchkitapp.widget",
            "CFBundleInfoDictionaryVersion": "6.0",
            "CFBundlePackageType": "XPC!",
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "1",
            "NSExtension": {
                "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
            },
        }
        (self.root / "project.yml").write_text(
            "targets:\n"
            "  ReperaWatchWidget:\n"
            "    settings:\n"
            "      INFOPLIST_FILE: Apps/ReperaWatchWidget/Info.plist\n"
            "      GENERATE_INFOPLIST_FILE: false\n"
            "    info:\n"
            "      properties:\n"
            "        CFBundleName: ReperaWatch\n"
            '        CFBundleInfoDictionaryVersion: "6.0"\n'
            "  ReperaUITests:\n",
            encoding="utf-8",
        )
        self.write_data()

    def write_data(self):
        self.source.write_bytes(plistlib.dumps(self.data))
        self.built.write_bytes(plistlib.dumps(self.data))

    def test_real_repository_metadata(self):
        validate_source(ROOT)

    def test_valid_source_and_built_plists(self):
        validate_source(self.root)
        validate_built(self.built)

    def test_empty_bundle_name_is_rejected_before_installation(self):
        self.data["CFBundleName"] = ""
        self.write_data()
        with self.assertRaisesRegex(ValueError, "CFBundleName"):
            validate_source(self.root)
        with self.assertRaisesRegex(ValueError, "CFBundleName"):
            validate_built(self.built)

    def test_bundle_name_missing_from_generated_spec_is_rejected(self):
        path = self.root / "project.yml"
        path.write_text(
            path.read_text(encoding="utf-8").replace(
                "        CFBundleName: ReperaWatch\n", ""
            ),
            encoding="utf-8",
        )
        with self.assertRaisesRegex(ValueError, "CFBundleName"):
            validate_source(self.root)

    def test_invalid_compiled_bundle_id_is_rejected(self):
        self.data["CFBundleIdentifier"] = "com.example.invalid.widget"
        self.write_data()
        with self.assertRaisesRegex(ValueError, "CFBundleIdentifier"):
            validate_built(self.built)

    def test_unresolved_build_variable_is_rejected(self):
        self.data["CFBundleExecutable"] = "$(EXECUTABLE_NAME)"
        self.write_data()
        with self.assertRaisesRegex(ValueError, "CFBundleExecutable"):
            validate_built(self.built)


if __name__ == "__main__":
    unittest.main()
