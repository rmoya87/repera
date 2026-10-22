"""Cross-layer WOD results and timer semantics for the deployed Repera MCP."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


class WODFormatContractTests(unittest.TestCase):
    def setUp(self):
        self.schema = read("supabase/functions/repera-mcp/schema.ts")
        self.mcp = read("supabase/functions/repera-mcp/index.ts")
        self.ios = read("Packages/ReperaDomain/Sources/ReperaDomain/Models.swift")

    def test_every_native_wod_format_is_in_mcp_contract(self):
        formats = (
            "amrap", "emom", "forTime", "tabata", "chipper", "deathBy",
            "strength", "afap", "ladder", "partner", "buyInCashOut",
            "roundsForQuality", "circuit", "maxEffort",
        )
        contract = self.schema.split("export const wodFormatContract = {", 1)[1]
        contract = contract.split("} as const satisfies", 1)[0]
        actual = re.findall(r"^  ([A-Za-z]+): \\{", contract, re.MULTILINE)
        self.assertEqual(set(actual), set(formats))
        self.assertEqual(len(actual), len(formats))

    def test_amrap_and_death_by_use_completed_rounds_and_partial_reps(self):
        self.assertIn('primaryResult: "rounds_completed_plus_partial_reps"', self.schema)
        self.assertIn("totalReps = SOLO reps de la vuelta incompleta", self.schema)
        self.assertIn("AMRAP requires a fixed countdown duration", self.schema)
        self.assertIn('timer: "countdown"', self.schema)
        self.assertIn('timer: "progressive_intervals"', self.schema)
        self.assertIn("case .amrap, .deathBy, .maxEffort:", self.ios)
        sheet = read("Apps/Repera/Sources/WODResultConfirmSheet.swift")
        self.assertIn('numberInput("Rondas completas"', sheet)
        self.assertIn('numberInput("Reps adicionales"', sheet)

    def test_for_time_and_equivalents_use_real_elapsed_time(self):
        self.assertIn('primaryResult: "elapsed_seconds"', self.schema)
        self.assertIn('timer: "countup_optional_time_cap"', self.schema)
        self.assertIn('case .forTime, .chipper, .afap, .ladder, .buyInCashOut:', self.ios)
        self.assertIn("time cap avisa, nunca reemplaza la marca", self.schema)

    def test_intervals_are_not_aggregate_round_scores(self):
        self.assertIn('primaryResult: "sets_and_repetitions_per_interval"', self.schema)
        self.assertIn('primaryResult: "work_interval_results"', self.schema)
        self.assertIn('timer: "alternating_work_and_rest"', self.schema)
        self.assertIn("descanso no es una serie", self.schema)
        self.assertIn("sin intervalId persistente", self.schema)
        self.assertIn("case .emom, .tabata, .circuit", self.ios)

    def test_max_effort_limit_is_explicit_not_fabricated(self):
        self.assertIn('primaryResult: "max_repetitions"', self.schema)
        self.assertIn("campo de score global en iOS", self.schema)
        self.assertIn("No inventarla ni convertirla en reps", self.schema)

    def test_mcp_exposes_read_only_contract_and_preserves_history(self):
        self.assertIn('server.registerTool("get_wod_format_contract"', self.mcp)
        self.assertIn('inputSchema: z.strictObject({ format: wodFormat.optional() })', self.mcp)
        self.assertIn("wodFormatContract[format]", self.mcp)
        self.assertIn('wod_result_contract_tool:"get_wod_format_contract"', self.mcp)
        self.assertIn("wod_results:row.wod_results??[]", self.mcp)
        self.assertIn("wod_result_semantics:", self.mcp)


if __name__ == "__main__":
    unittest.main()
