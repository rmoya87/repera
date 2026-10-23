"""Contracts for discipline-aware, privacy-scoped MCP planning."""
from pathlib import Path
import re
import unittest

ROOT=Path(__file__).resolve().parents[1]
MODULE=(ROOT/"supabase/functions/repera-mcp/disciplines.ts").read_text(encoding="utf-8")
INDEX=(ROOT/"supabase/functions/repera-mcp/index.ts").read_text(encoding="utf-8")
MIGRATIONS=list((ROOT/"supabase/migrations").glob("*_mcp_mobility_exercise_catalog.sql"))


class MCPDisciplinePlanningTests(unittest.TestCase):
    def test_disciplines_and_warmup_are_available(self):
        for category in ('crossfit','weightlifting','mobility','warmup'):
            self.assertIn(category, MODULE)
        self.assertIn('get_training_discipline_reference', MODULE)
        self.assertIn('get_warmup_prescription_reference', MODULE)
        self.assertIn('get_athlete_planning_context', MODULE)
        self.assertIn('warmupMovementFocus', MODULE)
        self.assertIn('detected_movement_focus', MODULE)
        self.assertIn('equipment_status:equipmentStatus', MODULE)
        self.assertIn('recent_wod_result_samples', MODULE)
        self.assertIn('registerDisciplinePlanningTools(server, db, ownerId);', INDEX)
        self.assertIn('get_wod_format_contract', MODULE)

    def test_owner_scope_history_profile_and_calendar(self):
        self.assertIn('db.from("athlete_workouts")', MODULE)
        self.assertIn('db.from("athlete_training_profiles")', MODULE)
        self.assertIn('db.from("ai_training_plans")', MODULE)
        self.assertIn('db.from("athlete_training_programs")', MODULE)
        self.assertIn('db.from("athlete_training_calendar_snapshots")', MODULE)
        self.assertGreaterEqual(MODULE.count('.eq("owner_id",ownerId)'), 5)
        self.assertIn('readOnlyHint:true', MODULE)
        self.assertNotIn('SUPABASE_SERVICE_ROLE_KEY', MODULE)
        self.assertNotIn('db.from("auth.users")', MODULE)

    def test_training_metrics_do_not_mix_units_or_claim_health(self):
        self.assertIn('case "meters":meters+=n;', MODULE)
        self.assertIn('case "calories":calories+=n;', MODULE)
        self.assertIn('set.quantityUnit==="reps"', MODULE)
        self.assertIn('set.phase==="warmup"', MODULE)
        self.assertIn('no_automatic_health_records:true', MODULE)
        self.assertIn('physiological recovery', MODULE)
        self.assertIn('possibly_truncated:rows.length===1000', MODULE)

    def test_mobility_native_catalog_has_all_82(self):
        self.assertEqual(len(MIGRATIONS),1)
        sql=MIGRATIONS[0].read_text(encoding="utf-8")
        self.assertEqual(len(set(re.findall(r"'catalog:([^']+)'",sql))),82)
        self.assertIn('native:CatalogMovilidad',sql)
        self.assertIn("ON CONFLICT (catalog_key) DO NOTHING",sql)
        self.assertNotIn('DELETE FROM',sql.upper())
        self.assertIn("Movilidad",sql)

    def test_mcp_contract_is_explicit_about_current_ios_limitations(self):
        self.assertIn('targetDurationSeconds',MODULE)
        self.assertIn('wodNotes',MODULE)
        self.assertIn("phase=warmup",MODULE)
        self.assertIn('warmupIdeas',MODULE)


if __name__=="__main__":
    unittest.main()
