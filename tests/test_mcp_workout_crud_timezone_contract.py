"""Repera AI MCP workout/exercise CRUD + DST safety contract tests."""
from pathlib import Path
import unittest
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

ROOT=Path(__file__).resolve().parents[1]
def source(p): return (ROOT/p).read_text("utf-8")

class MCPWorkoutCRUDContractTests(unittest.TestCase):
    def test_share_strict_schema_create_and_update(self):
        schema=source("supabase/functions/repera-mcp/schema.ts")
        index=source("supabase/functions/repera-mcp/index.ts")
        mut=source("supabase/functions/repera-mcp/mutations.ts")
        self.assertIn('export const workout = z.strictObject(',schema)
        self.assertIn('import { workout } from "./schema.ts";',index)
        self.assertIn('import { workout } from "./schema.ts";',mut)
        self.assertIn('...workout.shape',mut)
        self.assertIn('workout.safeParse(candidate)',mut)
        self.assertNotIn('z.array(z.unknown())',mut)
        for name in ('plannedSet','strengthEntry','movement','block'):
            self.assertIn(name+' = z.strictObject(',schema)
        self.assertIn('scheduledUtcOffsetMinutes',schema)

    def test_time_zone_dst_is_explicit(self):
        ts=source("supabase/functions/repera-mcp/time.ts")
        self.assertIn('Intl.DateTimeFormat',ts)
        self.assertIn('INVALID_LOCAL_TIME',ts)
        self.assertIn('scheduledUtcOffsetMinutes',source("supabase/functions/repera-mcp/index.ts"))
        self.assertIn('scheduled_at',source("supabase/functions/repera-mcp/mutations.ts"))
        madrid=ZoneInfo("Europe/Madrid")
        for d,clock,utc_offset in (
            ("2026-01-15","09:00",60),
            ("2026-07-15","09:00",120),
        ):
            dt=datetime.fromisoformat(d+"T"+clock).replace(tzinfo=madrid)
            self.assertEqual(int(dt.utcoffset().total_seconds()/60),utc_offset)
        # DST 02:30 doesn't exist on last Sunday in March, 02:30 twice in October.
        spring=datetime(2026,3,29,2,30,tzinfo=madrid)
        roundtrip=spring.astimezone(ZoneInfo("UTC")).astimezone(madrid)
        self.assertNotEqual(roundtrip.replace(tzinfo=None),spring.replace(tzinfo=None))
        a=datetime(2026,10,25,2,30,tzinfo=madrid,fold=0)
        b=datetime(2026,10,25,2,30,tzinfo=madrid,fold=1)
        self.assertNotEqual(a.utcoffset(),b.utcoffset())

    def test_full_workout_commands_require_athlete_approval(self):
        server=source("supabase/functions/repera-mcp/athlete-changes.ts")
        native=source("Apps/Repera/Sources/AIChangeRequestStore.swift")
        for op in ('update_workout','delete_workout','create_custom_exercise',
                   'update_custom_exercise','delete_custom_exercise',
                   'get_custom_exercises','get_athlete_change_requests'):
            self.assertIn('"' + op + '"',server)
        self.assertIn('destructiveHint:true',server)
        self.assertIn('.eq("owner_id",ownerId)',server)
        self.assertIn('expectedUpdatedAt',server)
        self.assertIn('stage("update_workout"',server)
        self.assertIn('stage("delete_workout"',server)
        self.assertIn('store.deleteWorkout(id)',native)
        self.assertIn('store.saveWorkout(changed)',native)
        self.assertIn('store.addCustomExercise',native)
        self.assertIn('store.updateCustomExercise',native)
        self.assertIn('guard let remote,remote.deletedAt==nil',native)
        self.assertIn('AIChangeRequestStore.shared.refresh',source("Apps/Repera/Sources/ReperaApp.swift"))
        self.assertIn('Text("Cambios solicitados por la IA")',source("Apps/Repera/Sources/AIAccessView.swift"))

    def test_private_rls_queue_and_custom_catalog(self):
        sql=source("supabase/migrations/20261022110000_mcp_change_inbox_custom_exercises_tz.sql")
        for name in ('ai_athlete_change_requests','athlete_custom_exercise_mirror'):
            self.assertIn('ALTER TABLE public.'+name+' ENABLE ROW LEVEL SECURITY',sql)
        self.assertIn("owner_id=(SELECT auth.uid())",sql)
        self.assertNotIn("GRANT INSERT ON public.ai_athlete_change_requests",sql)
        self.assertIn('GRANT UPDATE(status,decided_at,decision_message)',sql)
        self.assertIn('scheduled_at timestamptz',sql)

if __name__=="__main__":
    unittest.main()
