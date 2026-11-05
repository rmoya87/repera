"""Semantica del filtro de material: vacio curado vs no curado.

Contratos de codigo (replica del predicado, mismo metodo que la verificacion
SQL nocturna). Borrador para la propuesta de filtro 2026-11-05.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
MCP = ROOT / "supabase" / "functions" / "repera-mcp"
COACH = (MCP / "coach.ts").read_text(encoding="utf-8")
DISC = (MCP / "disciplines.ts").read_text(encoding="utf-8")


def coach_candidate(required, declared_gear):
    """Replica del predicado de find_equipment_alternatives con la convencion
    adoptada (columna NOT NULL): [] = no curado -> excluido (seguro);
    [bodyweight] = curado sin material; cada token distinto de bodyweight
    debe estar declarado (canonico)."""
    if not required or "gym_machine_unspecified" in required:
        return False
    return all(g == "bodyweight" or g in declared_gear for g in required)


def warmup_status(required, declared=None):
    """Replica del equipmentStatus corregido: [] no curado ->
    pendiente_confirmacion; [bodyweight] curado -> sin_material."""
    if not required:
        return "pendiente_confirmacion"
    needs = [x for x in required if x != "bodyweight"]
    if not needs:
        return "sin_material"
    if declared is None:
        return "pendiente_confirmacion"
    return "disponible_declarado" if all(x in declared for x in needs) else "no_declarado"


class FilterSemantics(unittest.TestCase):
    def test_uncurated_empty_is_excluded_and_pending(self):
        self.assertFalse(coach_candidate([], {"bodyweight", "wall"}))
        self.assertEqual(warmup_status([], {"wall"}), "pendiente_confirmacion")

    def test_curated_bodyweight_is_candidate_and_sin_material(self):
        self.assertTrue(coach_candidate(["bodyweight"], {"bodyweight"}))
        self.assertEqual(warmup_status(["bodyweight"], None), "sin_material")

    def test_infra_requires_declaration(self):
        self.assertFalse(coach_candidate(["bodyweight", "wall"], {"bodyweight"}))
        self.assertTrue(coach_candidate(["bodyweight", "wall"], {"bodyweight", "wall"}))
        self.assertEqual(warmup_status(["bodyweight", "wall"], {"wall"}), "disponible_declarado")
        self.assertEqual(warmup_status(["bodyweight", "wall"], set()), "no_declarado")

    def test_machine_unspecified_stays_excluded(self):
        self.assertFalse(coach_candidate(["gym_machine_unspecified"], {"gym_machine_unspecified"}))

    def test_partial_declaration_excludes_in_both_routes(self):
        # RackPull con SOLO barra: falta rack -> excluido/no_declarado.
        self.assertFalse(coach_candidate(["barbell", "rack"], {"barbell"}))
        self.assertEqual(warmup_status(["barbell", "rack"], {"barbell"}), "no_declarado")
        # Curl concentrado con SOLO mancuernas: falta banco.
        self.assertFalse(coach_candidate(["dumbbells", "bench"], {"dumbbells"}))
        self.assertEqual(warmup_status(["dumbbells", "bench"], {"dumbbells"}), "no_declarado")
        # Wall Sit con SOLO peso corporal: falta pared.
        self.assertFalse(coach_candidate(["bodyweight", "wall"], {"bodyweight"}))
        self.assertEqual(warmup_status(["bodyweight", "wall"], set()), "no_declarado")

    def test_complete_declaration_es_en_includes_in_both_routes(self):
        for declared in ({"barbell", "rack"}, {"barbell", "rack"}):
            self.assertTrue(coach_candidate(["barbell", "rack"], declared))
        self.assertEqual(warmup_status(["barbell", "rack"], {"rack", "barbell"}), "disponible_declarado")
        self.assertTrue(coach_candidate(["dumbbells", "bench"], {"dumbbells", "bench"}))
        self.assertEqual(warmup_status(["dumbbells", "bench"], {"dumbbells", "bench"}), "disponible_declarado")
        self.assertTrue(coach_candidate(["bodyweight", "wall"], {"bodyweight", "wall"}))
        self.assertEqual(warmup_status(["bodyweight", "wall"], {"wall"}), "disponible_declarado")

    def test_source_keeps_safe_exclusion_of_unknown(self):
        # El buscador sigue excluyendo las filas no curadas ([]) y disciplines
        # ya no las etiqueta como sin_material.
        self.assertIn("!x.required_equipment?.length", COACH)
        status = DISC.split("function equipmentStatus", 1)[1].split("function ", 1)[0]
        self.assertIn('if(!requirements.length)return "pendiente_confirmacion";', status)


if __name__ == "__main__":
    unittest.main()
