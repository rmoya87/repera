"""Contrato estático de icono y navegación de complicaciones watchOS."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

class WatchComplicationTests(unittest.TestCase):
    def test_logo_vectorial_en_todas_las_familias_sin_png_opacos(self):
        widget = read("Apps/ReperaWatchWidget/ReperaWatchWidget.swift")
        self.assertIn("private struct ReperaMascotFace: Shape", widget)
        self.assertIn("FillStyle(eoFill: true)", widget)
        self.assertIn(".widgetAccentable()", widget)
        self.assertIn("renderingMode == .fullColor", widget)
        self.assertIn(".containerBackground(for: .widget) { Color.clear }", widget)
        self.assertNotIn('Image("ReperaIcon")', widget)
        self.assertNotIn('Image("ReperaComplicationIcon")', widget)
        for family in ("Circular", "Corner", "Rectangular", "Inline"):
            self.assertIn(f"case .accessory{family}:", widget)
        # Ni el placeholder ni el snapshot ni la timeline deben recurrir al PNG.
        self.assertIn("func placeholder(in context:", widget)
        self.assertIn("func getSnapshot(in context:", widget)
        self.assertIn("func getTimeline(in context:", widget)

    def test_target_watch_widget_sin_dependencias_de_imagenes(self):
        project = read("project.yml")
        widget_target = project.split("\n  ReperaWatchWidget:\n", 1)[1].split("\n  ReperaUITests:\n", 1)[0]
        self.assertIn("Apps/ReperaWatchWidget/ReperaWatchWidget.swift", widget_target)
        self.assertIn("Apps/ReperaWatchWidget/ReperaComplicationSharedStore.swift", widget_target)
        for legacy in ("ReperaComplicationAppIconStore.swift", "Apps/ReperaWatchWidget/Assets.xcassets",
                       "ReperaWatchAppIcon.png", "repera_complication.png"):
            self.assertNotIn(legacy, widget_target)
        self.assertIn("      - target: ReperaWatchWidget\n        embed: true", project)
        self.assertTrue((ROOT / "Apps/ReperaWatch/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json").exists())

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
