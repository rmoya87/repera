"""Contrato mínimo del pipeline tools/catalog_ingest (sin red)."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FETCH = ROOT / "tools/catalog_ingest/fetch_sources.py"
MATCH = ROOT / "tools/catalog_ingest/match_catalog.py"


def _load(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


class CatalogIngestTests(unittest.TestCase):
    def test_normalize_collapses_equipment_plurals(self):
        m = _load(MATCH, "catalog_ingest_match")
        self.assertEqual(m.normalize("Barbell Back Squats"), "barbell back squat")
        self.assertEqual(m.normalize("Pull-Ups"), "pull up")

    def test_oedb_html_parser_extracts_en_es(self):
        f = _load(FETCH, "catalog_ingest_fetch")
        html = (
            '<main><h2>Exercises</h2>'
            '<article id="exercise-1000"><h3>Floor Dips <code>id/uuid: 1000</code></h3>'
            "<p>en: Floor Dips · es: Fondos en el suelo · active · "
            "RECOMMENDED FOR ROUTINES</p></article></main>"
        )
        entries = f.parse_oedb_html(html)
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0]["id"], "1000")
        self.assertEqual(entries[0]["name_en"], "Floor Dips")
        self.assertEqual(entries[0]["name_es"], "Fondos en el suelo")
        self.assertTrue(entries[0]["recommended"])


if __name__ == "__main__":
    unittest.main()
