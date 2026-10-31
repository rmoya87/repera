"""Contrato estático de icono y navegación de complicaciones watchOS."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

class WatchComplicationTests(unittest.TestCase):
    def test_el_icono_completo_es_el_mismo_en_ios_watch_y_complicacion(self):
        from hashlib import sha256
        app = ROOT / "Apps/Repera/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
        watch = ROOT / "Apps/ReperaWatch/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
        widget_icon = ROOT / "Apps/ReperaWatchWidget/Assets.xcassets/ReperaIcon.imageset/repera.png"
        digests = [sha256(path.read_bytes()).hexdigest() for path in (app, watch, widget_icon)]
        self.assertEqual(len(set(digests)), 1, "Los tres AppIcon deben ser idénticos")

        # El widget debe tener una única escala canónica: nada de miniaturas
        # alternativas que puedan verse distintas en el editor de esferas.
        import json
        contents = json.loads(read("Apps/ReperaWatchWidget/Assets.xcassets/ReperaIcon.imageset/Contents.json"))
        self.assertEqual(contents["images"], [
            {"filename": "repera.png", "idiom": "universal", "scale": "1x"}
        ])

    def test_capas_de_render_según_la_documentacion_de_apple(self):
        widget = read("Apps/ReperaWatchWidget/ReperaWatchWidget.swift")
        self.assertEqual(widget.count('Image("ReperaIcon")'), 1)
        self.assertIn('UIImage(named: "ReperaIcon")', widget)
        self.assertIn("renderingMode == .fullColor", widget)
        self.assertIn("Circle()", widget)
        self.assertIn(".widgetAccentable()", widget)
        self.assertIn("Image(uiImage: subject)", widget)
        self.assertIn(".widgetAccentedRenderingMode(.desaturated)", widget)
        self.assertIn(".containerBackground(for: .widget) { Color.clear }", widget)
        self.assertIn("let distance = sqrt", widget)
        self.assertIn("let luminance =", widget)
        self.assertIn("Data(bytes: base, count: raw.count)", widget)
        self.assertNotIn("ReperaMascotFace", widget)
        self.assertNotIn('Image("ReperaComplicationIcon")', widget)
        self.assertNotIn("greenExcess", widget)
        for family in ("Circular", "Corner", "Rectangular", "Inline"):
            self.assertIn(f"case .accessory{family}:", widget)
        for callback in ("placeholder", "getSnapshot", "getTimeline"):
            self.assertIn(f"func {callback}(in context:", widget)

    def test_kind_nuevo_evitar_preview_antiguo(self):
        kind = "com.app.repera.watch.complication.brand2"
        widget = read("Apps/ReperaWatchWidget/ReperaWatchWidget.swift")
        watch = read("Apps/ReperaWatch/Sources/ReperaWatchApp.swift")
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        self.assertIn(f'kind: "{kind}"', widget)
        self.assertIn(f'ofKind: "{kind}"', watch)
        self.assertIn(f'reloadTimelines(ofKind: "{kind}")', hub)

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
