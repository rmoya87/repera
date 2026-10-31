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
        # PNG sueltos @2x/@3x sin entrada en Contents.json provocan
        # «unassigned children» en el asset catalog.
        import json
        imageset = ROOT / "Apps/ReperaWatchWidget/Assets.xcassets/ReperaIcon.imageset"
        contents = json.loads((imageset / "Contents.json").read_text(encoding="utf-8"))
        self.assertEqual(contents["images"], [
            {"filename": "repera.png", "idiom": "universal", "scale": "1x"}
        ])
        self.assertEqual(
            sorted(p.name for p in imageset.iterdir() if p.suffix.lower() == ".png"),
            ["repera.png"],
        )

    def test_complicacion_usa_icono_real_con_mascara_tintada_estatica(self):
        import json
        import sys
        sys.path.insert(0, str(ROOT / "scripts"))
        from generate_watch_tinted_icon import decode_png, generate_rgba

        original = ROOT / "Apps/Repera/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
        path = ROOT / "Apps/ReperaWatchWidget/Assets.xcassets/ReperaWatchTintedIcon.imageset/icon.png"
        width, height, source = decode_png(original)
        target_width, target_height, rgba = decode_png(path)
        self.assertEqual((target_width, target_height), (256, 256))
        expected = generate_rgba(source,width,height)
        self.assertLessEqual(max(abs(a-b) for a,b in zip(expected,rgba)), 1)

        alpha = rgba[3::4]
        self.assertLess(alpha[0], 10)       # Verde del fondo eliminado
        self.assertGreater(max(alpha), 240) # La mascota queda visible
        coverage = sum(a > 50 for a in alpha) / len(alpha)
        self.assertGreater(coverage, 0.20)
        self.assertLess(coverage, 0.45)
        shades = set(rgba[0::4])
        self.assertGreater(len(shades), 40) # Ojos, sonrisa, cinta y piel no son disco uniforme
        contents = json.loads(read("Apps/ReperaWatchWidget/Assets.xcassets/ReperaWatchTintedIcon.imageset/Contents.json"))
        self.assertEqual(contents["images"][0]["filename"], "icon.png")

        widget = read("Apps/ReperaWatchWidget/ReperaWatchWidget.swift")
        self.assertIn('Image("ReperaIcon")', widget)
        self.assertIn('Image("ReperaWatchTintedIcon")', widget)
        self.assertIn("renderingMode == .fullColor", widget)
        self.assertIn(".widgetAccentedRenderingMode(.desaturated)", widget)
        self.assertIn(".unredacted()", widget)
        self.assertIn(".containerBackground(for: .widget) { Color.clear }", widget)
        for removed in ("makeFaceTemplate", "CGContext(", "UIImage(named:",
                        "Image(uiImage:", "ReperaMascotFace"):
            self.assertNotIn(removed, widget)
        for family in ("Circular", "Corner", "Rectangular", "Inline"):
            self.assertIn(f"case .accessory{family}:", widget)

    def test_kind_nuevo_para_no_reutilizar_preview_antiguo(self):
        kind = "com.app.repera.watch.complication.brand5"
        widget = read("Apps/ReperaWatchWidget/ReperaWatchWidget.swift")
        app = read("Apps/ReperaWatch/Sources/ReperaWatchApp.swift")
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        self.assertIn(f'kind: "{kind}"', widget)
        self.assertIn(f'ofKind: "{kind}"', app)
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
