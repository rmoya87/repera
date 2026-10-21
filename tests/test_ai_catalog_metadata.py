"""Ensure AI exercise metadata mirrors native muscle assignments without guesses.

Source of truth: Packages/ReperaDomain CatalogHalterofilia, CatalogGimnasia,
CatalogCrossFit and MuscleTaxonomy. The iOS source code must not change.
"""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "Packages/ReperaDomain/Sources/ReperaDomain"
SQL = (ROOT / "supabase/migrations/20261021235000_complete_ai_catalog_muscle_mappings.sql").read_text("utf-8")
FILES = {
    "CatalogHalterofilia.swift": ("h", 40),
    "CatalogGimnasia.swift": ("gy", 56),
    "CatalogCrossFit.swift": ("cf", 44),
}
CANONICAL = {
    "trapezius", "deltoids", "chest", "upper-back", "serratus",
    "biceps", "triceps", "forearm", "abs", "obliques", "lower-back",
    "gluteal", "quadriceps", "hamstring", "adductors", "hip-flexors",
    "calves", "tibialis",
}
ALIASES = {"lats": "upper-back", "hip flexors": "hip-flexors"}


def source_entries(filename, helper):
    content = (CATALOG / filename).read_text("utf-8")
    pattern = rf'\b{helper}\("([^"]+)"[\s\S]*?primaries:\s*(\[[^\]]*\])\s*,\s*secondaries:\s*(\[[^\]]*\])\s*\)'
    names = re.findall(rf'\b{helper}\("([^"]+)"', content)
    rows = []
    for match in re.finditer(pattern, content):
        primary = list(dict.fromkeys(ALIASES.get(x, x) for x in json.loads(match.group(2))))
        secondary = [x for x in dict.fromkeys(ALIASES.get(x, x) for x in json.loads(match.group(3)))
                     if x not in primary]
        equipment = re.search(r'equipment:\s*("(?:[^"\\]|\\.)*"|nil)', match.group(0))
        if not equipment:
            raise AssertionError("Missing equipment in " + match.group(1))
        gear = [] if equipment.group(1) == "nil" else [json.loads(equipment.group(1))]
        rows.append((match.group(1), primary, secondary, gear))
    if len(rows) != len(names):
        raise AssertionError(f"Missing metadata in {filename}: {len(rows)} / {len(names)}")
    return rows


def sql_array(items):
    return "ARRAY[" + ",".join("'" + x.replace("'", "''") + "'" for x in items) + "]::text[]"


class CatalogMetadataParityTests(unittest.TestCase):
    def test_all_native_sport_seed_exercises_are_mapped(self):
        total = 0
        all_names = []
        cardio_names = []
        for filename, (helper, count) in FILES.items():
            rows = source_entries(filename, helper)
            self.assertEqual(len(rows), count)
            total += len(rows)
            for name, primary, secondary, equipment in rows:
                all_names.append(name)
                self.assertTrue(set(primary + secondary).issubset(CANONICAL), name)
                if not primary:
                    cardio_names.append(name)
                    self.assertTrue(secondary, name)
                prefix = "('catalog:" + name.replace("'", "''") + "', " + sql_array(primary)
                self.assertIn(prefix, SQL, name)
                self.assertIn(
                    sql_array(primary) + ", " + sql_array(secondary) + ", " + sql_array(equipment),
                    SQL, name,
                )
                self.assertIn("'native:" + filename.removesuffix(".swift") + "'", SQL)
        self.assertEqual(total, 140)
        self.assertEqual(len(set(all_names)), total)
        self.assertEqual(
            set(cardio_names),
            {"Dobles de comba", "Simples de comba", "Triples de comba",
             "Air bike", "Echo bike", "Shuttle run"},
        )

    def test_migration_is_non_destructive_and_tracks_provenance(self):
        self.assertIn("metadata_source text NOT NULL DEFAULT 'unmapped'", SQL)
        self.assertIn("metadata_source = 'native:CatalogEnrichment'", SQL)
        self.assertIn("m.metadata_source = 'unmapped'", SQL)
        self.assertIn("RAISE EXCEPTION 'Uncovered movement", SQL)
        self.assertIn("RAISE EXCEPTION 'Invalid muscle taxonomy slug'", SQL)
        for forbidden in ("DROP TABLE", "DELETE FROM", "ALTER TABLE public.athlete_workout_mirror",
                          "INSERT INTO public.athlete_workout_mirror"):
            self.assertNotIn(forbidden, SQL)


if __name__ == "__main__":
    unittest.main()
