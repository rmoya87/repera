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
SQL = (ROOT / "supabase/migrations/20261021213713_complete_ai_catalog_muscle_mappings.sql").read_text("utf-8")
SQL_EXTRA = (ROOT / "supabase/migrations/20261021222922_new_photo_movements_crossfit.sql").read_text("utf-8")
SQL_NATIVE_ADDED = (ROOT / "supabase/migrations/20261103220000_native_catalog_ai_metadata_parity.sql").read_text("utf-8")
SQL_EQUIPMENT = (ROOT / "supabase/migrations/20261103221000_native_equipment_metadata_parity.sql").read_text("utf-8")
SQL_SCAN = (ROOT / "supabase/migrations/20261103233000_board_scan_ddb_stepup_rkbs.sql").read_text("utf-8")
SQL_PHASE_B = (ROOT / "supabase/migrations/20261104203000_phase_b_selective_crossfit_gaps.sql").read_text("utf-8")
SQL_PHASE_C = (ROOT / "supabase/migrations/20261104210000_phase_c_selective_crossfit_gaps.sql").read_text("utf-8")
SQL_PHASE_D = (ROOT / "supabase/migrations/20261104220000_phase_d_open_wod_gaps_and_enrich.sql").read_text("utf-8")
SQL_PHASE_D_COACHING = (
    ROOT / "supabase/migrations/20261104233000_phase_d_coaching_rewrite.sql"
).read_text("utf-8")
SQL_PHASE_E = (
    ROOT / "supabase/migrations/20261104234000_phase_e_fed_selective_gym.sql"
).read_text("utf-8")
SQL_OPEN_SOURCES = (
    SQL_PHASE_B + "\n" + SQL_PHASE_C + "\n" + SQL_PHASE_D
    + "\n" + SQL_PHASE_D_COACHING + "\n" + SQL_PHASE_E
)
CORRECTED_NAMES = set(re.findall(r"\('catalog:([^']+)', ARRAY\[", SQL_EQUIPMENT))
NEW_NATIVE_NAMES = {
    "Tirón alto de arrancada",
    "Tirón alto de cargada",
    "Peso muerto de cargada",
    "Envión en sentadilla",
    "Dip y drive de envión",
    "Arrancada de potencia desde bloques",
    "Cargada de potencia desde bloques",
    "Push press con agarre de arrancada",
    "Burpee to target"
}
EXTRA_NAMES = {
    "Carrera", "Dominadas lastradas",
    "Remo pliométrico en anillas pies elevados",
    "Step-up al cajón con kettlebell goblet",
}
OPEN_SOURCE_PHASE_NAMES = {
    "Bike Erg",
    "Ab Mat Sit-Up",
    "Overhead Lunge",
    "Alternating Dumbbell Snatch",
    "Dumbbell Overhead Lunge",
    "Dead Hang",
    "Box Step-Over",
    "D-Ball Clean",
    "D-Ball Over Shoulder",
    "Seated Box Jump",
    "Dumbbell Front Squat",
    "Dumbbell Front Rack Lunge",
    "Dumbbell Power Snatch",
    "Dumbbell Power Clean",
    "Dumbbell Push Press",
    "Dumbbell Push Jerk",
    "Dumbbell Overhead Squat",
    "Dumbbell Walking Lunge",
    "Dumbbell Hang Clean and Jerk",
    "Double Kettlebell Front Rack Carry",
    "Double Kettlebell Overhead Carry",
    "Kettlebell Clean and Jerk",
    "Kettlebell Overhead Lunge",
    "Kettlebell Push Press",
    "Jumping Pull-Up",
    "Burpee Muscle-Up",
    "Bear Hug Carry",
    "Box Squat",
    "Atlas Stone Over Shoulder",
    "Axle Deadlift",
    "Axle Press",
    "Back Rack Lunge",
    "Barbell Squat Jump",
    "Barbell Step Up",
    "Battle Rope",
    "Bird Dog",
    "Bodyweight Clean And Jerk",
    "Bradford Press",
    "Burpee Bar Muscle Up",
    "Burpee Over Dumbbell",
    "Burpee Over The Bar",
    "Copenhagen Plank",
    "Crab Walk",
    "Crossover Single Under",
    "Dead Bug",
    "Deficit Deadlift",
    "Double Kettlebell Farmers Carry",
    "Double Kettlebell Front Rack Lunge",
    "Dumbbell Bench Press",
    "Dumbbell Box Step Up",
    "Dumbbell Burpee Deadlift",
    "Dumbbell Carry",
    "Dumbbell Deadlift",
    "Dumbbell Floor Press",
    "Dumbbell Hang Clean To Overhead",
    "Dumbbell Hang Power Clean",
    "Dumbbell Hang Split Snatch",
    "Dumbbell Hang Squat Clean",
    "Dumbbell Overhead Carry",
    "Dumbbell Romanian Deadlift",
    "Dumbbell Shoulder Press",
    "Dumbbell Shoulder To Overhead",
    "Dumbbell Split Clean",
    "Dumbbell Squat Clean",
    "Dumbbell Squat Clean Thruster",
    "Dumbbell Strict Press",
    "Dumbbell Waiters Walk",
    "Floor Press",
    "Flutter Kick",
    "Glute Bridge",
    "Glute Ham Raise",
    "Hand Release Push Up",
    "Hang High Pull",
    "Hanging Hip Touch",
    "Hanging Knee Raise",
    "Husafell Carry",
    "Jefferson Curl",
    "Jerry Bag Carry",
    "Jumping Jack",
    "Keg Carry",
    "Kettlebell Deadlift",
    "Kettlebell Front Rack Lunge",
    "Kettlebell Halo",
    "Kettlebell Press",
    "Kettlebell Sumo Deadlift High Pull",
    "Kettlebell Windmill",
    "Kipping Handstand Push Up",
    "L Pull Up",
    "Landmine Press",
    "Lateral Burpee",
    "Lateral Lunge",
    "Log Carry",
    "Log Clean And Jerk",
    "Log Press",
    "Medicine Ball Box Step Over",
    "Medicine Ball Sit Up",
    "Medicine Ball Throw",
    "Mountain Climber",
    "Negative Pull Up",
    "Nordic Curl",
    "Overhead Walk",
    "Pallof Press",
    "Parallel Bar Traverse",
    "Parallette Handstand Push Up",
    "Pendlay Row",
    "Plate Carry",
    "Push Up",
    "Renegade Row",
    "Reverse Hyper",
    "Ring Hamstring Curl",
    "Ring Handstand Push Up",
    "Ring Lower",
    "Ring Push Up",
    "Russian Twist",
    "Sandbag Carry",
    "Sandbag Ground To Shoulder",
    "Sandbag Load To Box",
    "Sandbag Over Log",
    "Sandbag Squat",
    "Side Plank",
    "Single Arm Dumbbell Thruster",
    "Single Arm Kettlebell Swing",
    "Single Arm Kettlebell Thruster",
    "Single Leg Glute Bridge",
    "Single Leg Romanian Deadlift",
    "Skater Jump",
    "Sled Drag",
    "Sledgehammer Strike",
    "Stiff Legged Deadlift",
    "Strict Knee Raise",
    "Strict Knees To Chest",
    "Suitcase Carry",
    "Superman",
    "Tire Flip",
    "Trap Bar Deadlift",
    "Tuck Jump",
    "Wall Climb",
    "Wall Climb Over",
    "Wall Sit",
    "Z Press",
    "Zercher Carry",
    "Zercher Deadlift",
    "Zercher Squat",
    "Crunch en polea",
    "Elevaciones laterales en polea",
    "Remo con apoyo de pecho",
    "Curl femoral sentado",
    "Curl femoral tumbado",
    "Pec deck",
    "Abducción de cadera en máquina",
    "Aducción de cadera en máquina",
    "Sentadilla en Smith",
    "Remo en T",
    "Curl inclinado con mancuernas",
    "Sentadilla a cajón con mancuernas",
    "Sentadilla búlgara con mancuernas",
    "Woodchop en polea",
}

FILES = {
    "CatalogHalterofilia.swift": ("h", 48),
    "CatalogGimnasia.swift": ("gy", 58),
    "CatalogCrossFit.swift": ("cf", 191),
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
                if name in CORRECTED_NAMES:
                    self.assertIn("'catalog:" + name + "'", SQL_EQUIPMENT)
                    self.assertIn(
                        sql_array(primary) + ", " + sql_array(secondary) + ", " + sql_array(equipment),
                        SQL_EQUIPMENT, name,
                    )
                elif name in NEW_NATIVE_NAMES:
                    self.assertIn("'catalog:" + name + "'", SQL_NATIVE_ADDED, name)
                    self.assertIn(sql_array(primary), SQL_NATIVE_ADDED, name)
                    self.assertIn(sql_array(secondary), SQL_NATIVE_ADDED, name)
                    self.assertIn(sql_array(equipment), SQL_NATIVE_ADDED, name)
                elif name == "Step-up al cajón con doble mancuerna":
                    self.assertIn("'catalog:" + name + "'", SQL_SCAN, name)
                    self.assertIn(sql_array(primary), SQL_SCAN, name)
                    self.assertIn(sql_array(secondary), SQL_SCAN, name)
                    self.assertIn("ARRAY['Cajón','Mancuernas']::text[]", SQL_SCAN, name)
                elif name in EXTRA_NAMES:
                    self.assertIn("'catalog:" + name + "'", SQL_EXTRA, name)
                    self.assertIn(sql_array(primary), SQL_EXTRA, name)
                    self.assertIn(sql_array(secondary), SQL_EXTRA, name)
                elif name in OPEN_SOURCE_PHASE_NAMES:
                    self.assertIn("'catalog:" + name + "'", SQL_OPEN_SOURCES, name)
                    self.assertIn(sql_array(primary), SQL_OPEN_SOURCES, name)
                    self.assertIn(sql_array(secondary), SQL_OPEN_SOURCES, name)
                else:
                    prefix = "('catalog:" + name.replace("'", "''") + "', " + sql_array(primary)
                    self.assertIn(prefix, SQL, name)
                    self.assertIn(
                        sql_array(primary) + ", " + sql_array(secondary) + ", " + sql_array(equipment),
                        SQL, name,
                    )
                    self.assertIn("'native:" + filename.removesuffix(".swift") + "'", SQL)
        self.assertEqual(total, 297)
        self.assertEqual(len(OPEN_SOURCE_PHASE_NAMES), 157)
        self.assertEqual(len(CORRECTED_NAMES), 52)
        self.assertEqual(len(set(all_names)), total)
        self.assertEqual(
            set(cardio_names),
            {"Dobles de comba", "Simples de comba", "Triples de comba",
             "Air bike", "Echo bike", "Bike Erg", "Shuttle run", "Carrera"},
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
