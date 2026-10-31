"""Contrato estático de icono y navegación de complicaciones watchOS."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

class WatchComplicationTests(unittest.TestCase):
    def test_logo_real_and_accented_mode(self):
        widget = read("Apps/ReperaWatchWidget/ReperaWatchWidget.swift")
        self.assertIn('Image("ReperaIcon")', widget)
        self.assertIn('Image("ReperaComplicationIcon")', widget)
        self.assertIn('.widgetAccentedRenderingMode(.desaturated)', widget)
        self.assertNotIn('Circle().fill(.white.opacity(0.20))', widget)
        self.assertIn("case .accessoryCircular:", widget)
        self.assertIn("case .accessoryCorner:", widget)
        for name in ("ReperaIcon", "ReperaComplicationIcon"):
            self.assertTrue((ROOT / f"Apps/ReperaWatchWidget/Assets.xcassets/{name}.imageset/Contents.json").exists())

    def test_deeplink_and_dismiss_old_sheets(self):
        widget = read("Apps/ReperaWatchWidget/ReperaWatchWidget.swift")
        watch = read("Apps/ReperaWatch/Sources/ReperaWatchApp.swift")
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        view = read("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        project = read("project.yml")
        self.assertIn('"repera-watch://today"', widget)
        self.assertIn('"repera-watch://active"', widget)
        self.assertIn(".widgetURL(", widget)
        self.assertIn("hub.openFromComplication(url: url)", watch)
        self.assertIn("complicationOpenEpoch &+= 1", hub)
        self.assertIn("summaryDismissed = true", hub)
        self.assertIn(".onChange(of: hub.complicationOpenEpoch)", view)
        for modal in ("showTimer", "showOutline", "showSetDetails"):
            self.assertIn(f"{modal} = false", view)
        self.assertIn("- repera-watch", project)

if __name__ == "__main__":
    unittest.main()
