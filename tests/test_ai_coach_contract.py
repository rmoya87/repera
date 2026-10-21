"""Cross-platform contracts for the Repera sports-only AI coach.

Static tests; a real iOS build and a PAT-authenticated MCP E2E remain required.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def source(path):
    return (ROOT / path).read_text(encoding="utf-8")


class AICoachContractTests(unittest.TestCase):
    def test_calendar_is_native_and_sports_only(self):
        code=source("Apps/Repera/Sources/AITrainingContextStore.swift")
        for required in ('state.routines','scheduledDate','weekday','onConflict: "owner_id"',
                         'client.auth.currentSession','lastSnapshot','store.isHydrated'):
            self.assertIn(required,code)
        for secret in ('healthKitWorkoutUUID','locationPin','routePoints','sessionReview',
                       'appleActiveEnergyKcal','bodyWeightKg'):
            self.assertNotIn(secret,code)

    def test_native_screens_and_sync_are_wired(self):
        app=source("Apps/Repera/Sources/ReperaApp.swift")
        settings=source("Apps/Repera/Sources/SettingsView.swift")
        self.assertNotIn("AITrainingProfileView()", settings)
        for feature in ("AITrainingContextStore.shared.syncCalendar", "AITrainingContextStore.shared.clearSession"):
            self.assertIn(feature,app)
        for feature in ("AITrainingProgramsView()",
                        "AITrainingContextStore.shared.syncCalendar"):
            self.assertIn(feature,settings)

    def test_coaching_server_has_owner_scoped_tools(self):
        code=source("supabase/functions/repera-mcp/coach.ts")
        for tool in ("get_training_profile","get_training_calendar","get_training_analysis",
                     "get_exercise_performance","get_exercise_alternatives",
                     "search_training_exercises_enriched","create_training_program",
                     "review_training_program","adjust_training_program"):
            self.assertIn(f'"{tool}"',code)
        self.assertIn('.eq("owner_id",ownerId)',code)
        self.assertIn('native_catalog_id',code)
        self.assertIn('estimated_1rm_kg',code)
        self.assertIn('coaching_enabled',code)

    def test_schema_blocks_cross_user_and_does_not_export_health(self):
        sql=source("supabase/migrations/20261021231500_ai_coach_profiles_calendar_catalog_programs.sql")
        for table in ("athlete_training_profiles","athlete_training_calendar_snapshots",
                      "athlete_training_programs","training_exercise_metadata"):
            self.assertIn(table,sql)
        self.assertIn('owner_id=(select auth.uid())',sql)
        self.assertIn("pg_column_size(items)<300000",sql)
        self.assertNotIn("ADD TABLE public.athlete_training_profiles",sql)

    def test_programmed_workout_delivery_idempotent(self):
        sql=source("supabase/migrations/20261021233000_ai_training_plan_idempotency.sql")
        code=source("supabase/functions/repera-mcp/index.ts")
        self.assertIn("UNIQUE INDEX ai_training_plans_owner_batch_date_uq",sql)
        self.assertIn("idempotencyKey",code)
        self.assertIn('program_id: programId ?? null',code)
        self.assertIn('idempotent_replay:true',code)


if __name__ == "__main__":
    unittest.main()
