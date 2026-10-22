"""MCP v2 & iOS UX regression contracts.

These static tests protect cross-layer wiring and security; iPhone E2E and a
Swift package test on Xcode 27 must still run before release.
"""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def read(path):return (ROOT/path).read_text(encoding="utf-8")

class MCPV2Contracts(unittest.TestCase):
    def test_all_public_tool_inputs_are_strict(self):
        for file in ("supabase/functions/repera-mcp/index.ts",
                     "supabase/functions/repera-mcp/coach.ts",
                     "supabase/functions/repera-mcp/mutations.ts"):
            source=read(file)
            self.assertNotIn("z.object(",source)
            self.assertIn("z.strictObject(",source)
        index=read("supabase/functions/repera-mcp/index.ts")
        self.assertIn("block = z.strictObject",index)
        self.assertIn("movement = z.strictObject",index)
        self.assertIn("plannedSet = z.strictObject",index)

    def test_optimistic_reversible_changes_are_owner_scoped(self):
        code=read("supabase/functions/repera-mcp/mutations.ts")
        for tool in ("update_ai_training_plan","archive_ai_training_plan",
                     "restore_ai_training_plan","update_training_program",
                     "archive_training_program","restore_training_program"):
            self.assertIn(f'"{tool}"',code)
        self.assertIn('.eq("owner_id",ownerId)',code)
        self.assertIn('.eq("status","pending")',code)
        self.assertIn('.eq("revision",expectedRevision)',code)
        self.assertIn('destructiveHint:true',code)
        self.assertIn("structuredContent:{error}",code)
        self.assertNotIn('.delete()',code)
        self.assertIn("workoutSchema.safeParse(",code)

    def test_token_scopes_and_full_lifecycle(self):
        token=read("supabase/functions/repera-ai-tokens/index.ts")
        index=read("supabase/functions/repera-mcp/index.ts")
        ios=read("Apps/Repera/Sources/AIAccessView.swift")
        for phrase in ("scopes", "canWrite", "training:read"):
            self.assertTrue(phrase in index or phrase in token,phrase)
        self.assertIn("if (canWrite) registerMutationTools",index)
        self.assertIn('server.registerTool("get_mcp_access_info"',index)
        self.assertIn("canWrite",ios)
        self.assertIn("case scopes",ios)
        self.assertIn("revoke",ios)
        self.assertIn("ai_access_tokens_scope_vocabulary",
                      read("supabase/migrations/20261022004000_ai_pat_scopes.sql"))

    def test_ai_access_tokens_grants_new_scopes_without_exposing_secrets(self):
        migration=read("supabase/migrations/20261022070000_ai_access_tokens_scopes_column_grant.sql")
        token_view=read("Apps/Repera/Sources/AIAccessView.swift")
        self.assertIn("GRANT SELECT (scopes)",migration)
        self.assertIn("TO authenticated",migration)
        self.assertNotIn("GRANT SELECT ON",migration)
        self.assertNotIn("GRANT ALL",migration)
        self.assertIn("token_hash",migration)
        self.assertIn("relrowsecurity",migration)
        self.assertIn('token_prefix,created_at,expires_at,revoked_at,last_used_at,scopes',token_view)
        self.assertRegex(token_view,r"tokens = items\s+errorMessage = nil")
        self.assertIn(".refreshable { await refreshTokens() }",token_view)

    def test_no_silent_truncation_of_main_lists(self):
        index=read("supabase/functions/repera-mcp/index.ts")
        coach=read("supabase/functions/repera-mcp/coach.ts")
        self.assertIn("get_workout_history",index)
        self.assertIn("get_ai_training_plans",index)
        self.assertIn("nextCursor",index)
        self.assertIn("hasMore",index)
        self.assertIn("get_training_programs",coach)
        self.assertIn("nextCursor",coach)
        self.assertIn("Use exactly one of catalogKey or name",coach)

    def test_joint_coverage_and_new_exercise_identity(self):
        joints=read("supabase/migrations/20261022002000_joint_demands_all_catalog.sql")
        new=read("supabase/migrations/20261022003500_new_photo_movements_crossfit.sql")
        for term in ("joint_demands_source","muscle_region_heuristic_v1",
                     "movement_specific_plus_muscle_heuristic_v1"):
            self.assertIn(term,joints)
        for name in ("Carrera","Dominadas lastradas",
                     "Remo pliométrico en anillas pies elevados",
                     "Step-up al cajón con kettlebell goblet"):
            self.assertIn(f"'catalog:{name}'",new)

    def test_workout_preview_to_exercise_and_compact_account(self):
        preview=read("Apps/Repera/Sources/SessionPreviewView.swift")
        cards=read("Apps/Repera/Sources/OGRoutineBlockCard.swift")
        settings=read("Apps/Repera/Sources/SettingsView.swift")
        plan=read("Apps/Repera/Sources/PlanView.swift")
        self.assertIn("opensExerciseDetail: true",preview)
        self.assertIn("ExerciseDetailView(exerciseId:",cards)
        self.assertIn("PhotosPicker(selection: $photoItem",settings)
        self.assertNotIn("Quitar foto",settings)
        self.assertNotIn("Compras no configuradas en este build",settings)
        self.assertNotIn("Programas de entrenamiento IA",settings)
        self.assertIn("De tu entrenador IA",plan)
        self.assertIn("AITrainingProgramsView()",plan)
        self.assertIn("if let syncFeedback",settings)

    def test_percent_load_kept_as_percent_not_fabricated_kg(self):
        models=read("Packages/ReperaDomain/Sources/ReperaDomain/Models.swift")
        scan=read("Packages/ReperaDomain/Sources/ReperaDomain/BoardScanLiteParser.swift")
        inbox=read("Apps/Repera/Sources/AITrainingInboxStore.swift")
        self.assertIn("targetPercent1RMIsMinimum",models)
        self.assertIn("targetPercent1RMIsMinimum: line.contains",scan)
        self.assertIn("percent1RMIsMinimum",inbox)
        self.assertIn("Every 90s For 12min",read("Packages/ReperaDomain/Tests/ReperaDomainTests/BoardScanPhotoRegressionTests.swift"))

if __name__=="__main__":unittest.main()
