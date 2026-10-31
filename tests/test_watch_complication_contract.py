"""Contrato estático de icono y navegación de complicaciones watchOS."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

class WatchComplicationTests(unittest.TestCase):
    def test_usa_exclusivamente_el_icono_oficial_del_watch(self):
        from hashlib import sha256
        original = ROOT / "Apps/ReperaWatch/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
        complication = ROOT / "Apps/ReperaWatchWidget/Assets.xcassets/ReperaIcon.imageset/repera.png"
        self.assertEqual(sha256(original.read_bytes()).digest(),
                         sha256(complication.read_bytes()).digest(),
                         "El widget debe usar exactamente el PNG original, no una versión dibujada")

        widget = read("Apps/ReperaWatchWidget/ReperaWatchWidget.swift")
        self.assertIn('Image("ReperaIcon")', widget)
        self.assertIn('UIImage(named: "ReperaIcon")', widget)
        self.assertIn("Image(uiImage: tinted)", widget)
        self.assertIn("renderingMode == .fullColor", widget)
        self.assertIn(".widgetAccentedRenderingMode(.accented)", widget)
        self.assertIn(".containerBackground(for: .widget) { Color.clear }", widget)
        self.assertNotIn("ReperaMascotFace", widget)
        self.assertNotIn('Image("ReperaComplicationIcon")', widget)
        self.assertIn("private enum ReperaOfficialWatchIcon", widget)
        for family in ("Circular", "Corner", "Rectangular", "Inline"):
            self.assertIn(f"case .accessory{family}:", widget)

    def test_mascara_de_tinte_derivada_de_los_pixeles_originales(self):
        widget = read("Apps/ReperaWatchWidget/ReperaWatchWidget.swift")
        self.assertIn("context.draw(original", widget)
        self.assertIn("greenExcess = green - max(red, blue)", widget)
        self.assertIn("let detail = ", widget)
        self.assertIn("let data = Data(bytes: address, count: buffer.count)", widget)
        self.assertIn("CGDataProvider(data: data as CFData)", widget)
        self.assertIn("static let tintedImage:", widget)
        self.assertIn("func placeholder(in context:", widget)
        self.assertIn("func getSnapshot(in context:", widget)
        self.assertIn("func getTimeline(in context:", widget)

    def test_extensión_incluye_Assets_car_y_app_icon_de_watch(self):
        project = read("project.yml")
        target = project.split("\n  ReperaWatchWidget:\n", 1)[1].split("\n  ReperaUITests:\n", 1)[0]
        self.assertIn("Apps/ReperaWatchWidget/ReperaWatchWidget.swift", target)
        self.assertIn("Apps/ReperaWatchWidget/ReperaComplicationSharedStore.swift", target)
        self.assertIn("Apps/ReperaWatchWidget/Assets.xcassets", target)
        self.assertIn("buildPhase: resources", target)
        self.assertNotIn("ReperaComplicationAppIconStore.swift", target)
        self.assertNotIn("ReperaWatchAppIcon.png", target)
        self.assertIn("      - target: ReperaWatchWidget\n        embed: true", project)
        self.assertTrue((ROOT / "Apps/ReperaWatch/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json").exists())
        ci = read(".github/workflows/ios27-ci.yml")
        self.assertIn('REPERA_WATCH_WIDGET_ASSETS', ci)
        self.assertIn('ReperaIcon', ci)
        self.assertIn('test_watch_complication_contract.py', ci)

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
