"""Contrato HYROX del MCP: estaciones, unidades y protección de claves existentes."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
MCP_INDEX = (ROOT / "supabase/functions/repera-mcp/index.ts").read_text(encoding="utf-8")
MCP_COACH = (ROOT / "supabase/functions/repera-mcp/coach.ts").read_text(encoding="utf-8")
MIGRATION = (ROOT / "supabase/migrations/20261023133557_hyrox_station_catalog_seed.sql").read_text(encoding="utf-8")


class HyroxMCPContractTests(unittest.TestCase):
    def test_official_eight_stations_after_running(self):
        stations = MCP_INDEX.split("const hyroxStations = [", 1)[1].split("] as const", 1)[0]
        entries = re.findall(r"\{name:\"([^\"]+)\",catalogKey:\"([^\"]+)\"", stations)
        self.assertEqual(len(entries), 9)  # 8 stations + Running
        self.assertEqual(entries[0], ("Running", "catalog:Carrera"))
        self.assertEqual(len(set(key for _, key in entries)), 9)
        self.assertIn("hyroxStations.slice(1)", MCP_INDEX)
        self.assertIn("runBeforeMeters:1000", MCP_INDEX)
        for required in ("SkiErg", "Sled Push", "Sled Pull", "Burpee Broad Jumps", "Rowing",
                         "Farmers Carry", "Sandbag Lunges", "Wall Balls"):
            self.assertIn(required, [name for name, _ in entries])

    def test_mcp_separates_logged_units(self):
        self.assertIn('server.registerTool("get_hyrox_training_reference"', MCP_INDEX)
        self.assertIn('request.in("catalog_key",[...hyroxCatalogKeys])', MCP_INDEX)
        self.assertIn('const meters=byUnit("meters")', MCP_INDEX)
        self.assertIn('calories=byUnit("calories")', MCP_INDEX)
        self.assertIn('unknown_unit_sets', MCP_INDEX)
        self.assertIn('max_meters:best("meters")', MCP_COACH)
        self.assertIn('max_calories:best("calories")', MCP_COACH)
        self.assertIn('s.quantityUnit==="reps"', MCP_COACH)
        self.assertIn('create_training_program', MCP_COACH)

    def test_sql_only_adds_absent_stations_and_preserves_existing_origin(self):
        self.assertIn("ON CONFLICT (catalog_key) DO NOTHING", MIGRATION)
        self.assertIn("catalog:Burpee Broad Jump", MIGRATION)
        self.assertIn("catalog:Sandbag Lunges", MIGRATION)
        self.assertNotIn("DELETE FROM", MIGRATION.upper())
        self.assertNotIn("TRUNCATE", MIGRATION.upper())


if __name__ == "__main__":
    unittest.main()
