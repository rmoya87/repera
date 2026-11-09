"""OpenPowerlifting importer contract with synthetic CSV; never uses real athlete data."""
import csv
import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("build_strength_benchmarks", ROOT / "scripts/build_strength_benchmarks.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class StrengthBenchmarkImportTests(unittest.TestCase):
    def test_private_rows_are_not_exported_and_small_samples_suppressed(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "synthetic.csv"
            with path.open("w", newline="", encoding="utf-8") as handle:
                writer = csv.DictWriter(handle, fieldnames=[
                    "Name", "Sex", "Equipment", "Age", "BodyweightKg",
                    "Best3SquatKg", "Best3BenchKg", "Best3DeadliftKg"
                ])
                writer.writeheader()
                for i in range(120):
                    writer.writerow({
                        "Name": f"synthetic-lifter-{i}", "Sex": "M", "Equipment": "Raw",
                        "Age": "37", "BodyweightKg": "85", "Best3SquatKg": str(100 + i),
                        "Best3BenchKg": "", "Best3DeadliftKg": ""
                    })
                writer.writerow({
                    "Name": "synthetic-lifter-0", "Sex": "M", "Equipment": "Raw",
                    "Age": "37", "BodyweightKg": "85", "Best3SquatKg": "90",
                    "Best3BenchKg": "", "Best3DeadliftKg": ""
                })
            result = module.aggregate(path, "fixture-v1")
            self.assertEqual(len(result), 1)
            self.assertEqual(result[0]["sampleCount"], 120)
            self.assertEqual(result[0]["sourceRevision"], "fixture-v1")
            self.assertNotIn("Name", str(result))
            self.assertEqual(result[0]["cohort"]["lift"], "squat")

if __name__ == "__main__":
    unittest.main()
