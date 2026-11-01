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

    def test_pdf_plano_vectorial_compilado_y_ojos_transparentes(self):
        import json
        root = ROOT / "Apps/ReperaWatchWidget/Assets.xcassets"
        for name, template in (
            ("ReperaWatchFlatColor", "original"),
            ("ReperaWatchFlatMono", "template"),
        ):
            folder = root / f"{name}.imageset"
            manifest = json.loads((folder / "Contents.json").read_text())
            self.assertEqual(manifest["images"][0]["filename"], "icon.pdf")
            self.assertEqual(manifest["properties"]["preserves-vector-representation"], True)
            self.assertEqual(manifest["properties"]["template-rendering-intent"], template)
            pdf = (folder / "icon.pdf").read_bytes()
            self.assertTrue(pdf.startswith(b"%PDF-"), f"{name} no es PDF")
            self.assertRegex(pdf.decode("latin-1"), r"/MediaBox\s*\[\s*0\s+0\s+200\s+200\s*\]")
            self.assertNotIn(b"/Subtype /Image", pdf, "El PDF no debe incluir raster 3D")
            self.assertGreater(len(pdf), 1000)
        mono = (root / "ReperaWatchFlatMono.imageset/icon.pdf").read_bytes()
        self.assertIn(b"f*", mono, "El PDF monocromo necesita huecos reales even-odd")
        self.assertIn(b"66.5 93", mono)  # Ojo izquierdo
        self.assertIn(b"132.5 93", mono)  # Ojo derecho
        self.assertIn(b"84 75", mono)  # Boca
        widget = read("Apps/ReperaWatchWidget/ReperaWatchWidget.swift")
        self.assertIn('Image("ReperaWatchFlatColor")', widget)
        self.assertIn('Image("ReperaWatchFlatMono")', widget)
        self.assertIn(".renderingMode(.template)", widget)
        self.assertIn(".foregroundStyle(.primary)", widget)
        self.assertIn("renderingMode == .fullColor", widget)
        self.assertIn(".unredacted()", widget)
        self.assertNotIn("ReperaWatchTintedIcon", widget)
        self.assertNotIn('Image("ReperaIcon")', widget)
        self.assertIn(".containerBackground(for: .widget) { Color.clear }", widget)
        for family in ("Circular", "Corner", "Rectangular", "Inline"):
            self.assertIn(f"case .accessory{family}:", widget)

    def test_icono_circular_grande_y_verde_lateral(self):
        widget = read("Apps/ReperaWatchWidget/ReperaWatchWidget.swift")
        self.assertIn("ReperaLogo(diameter: 44)", widget)
        self.assertIn("ReperaLogo(diameter: 32)", widget)
        self.assertIn("Circle()", widget)
        self.assertIn(".frame(width: diameter * 0.88, height: diameter * 0.88)", widget)
        self.assertIn(".clipShape(Circle())", widget)

    def test_inicio_titulo_junto_hora_y_controles_abajo(self):
        home = read("Apps/ReperaWatch/Sources/WatchHomeHubView.swift")
        root = read("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        live = read("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        # En Inicio el título vuelve bajo el pictograma; no en la esquina
        # superior, que es la posición reservada para la actividad en curso.
        self.assertEqual(home.count("Text(selected.title)"), 1)
        self.assertIn('Image(systemName: selected.symbolName)', home)
        self.assertNotIn(".overlay(alignment: .topLeading)", home)
        self.assertIn(".ignoresSafeArea(.container, edges: .bottom)", home)
        self.assertIn(".overlay(alignment: .bottomLeading)", home)
        self.assertIn(".overlay(alignment: .bottomTrailing)", home)
        self.assertEqual(home.count(".offset(y: 10)"), 2)
        self.assertIn("ToolbarItem(placement: .topBarLeading)", root)
        self.assertIn(".offset(y: -11)", root)
        self.assertIn('.navigationTitle("")', root)
        self.assertNotIn(".navigationTitle(sport.title)", live)

    def test_kind_nuevo_y_recargas_watch_sincronizadas(self):
        kind = "com.app.repera.watch.complication.brand6"
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
