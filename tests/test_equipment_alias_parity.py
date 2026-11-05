"""Paridad de aliases de equipo entre coach.ts y disciplines.ts.

Contrato: todo token de infraestructura reconocido en una ruta debe producir
el mismo canonico en la otra. Borrador para la propuesta de filtro 2026-11-05;
aun no integrado en el repo.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
MCP = ROOT / "supabase" / "functions" / "repera-mcp"
COACH = (MCP / "coach.ts").read_text(encoding="utf-8")
DISC = (MCP / "disciplines.ts").read_text(encoding="utf-8")

INFRA_CANONICALS = ["wall", "bench", "pullup_bar", "rack"]


def alias_block(source: str) -> str:
    return source.split("gearAliases", 1)[1].split("};", 1)[0]


class EquipmentAliasParity(unittest.TestCase):
    def test_infra_tokens_recognized_in_both_routes(self):
        coach = alias_block(COACH)
        disc = alias_block(DISC)
        for canon in INFRA_CANONICALS:
            with self.subTest(token=canon):
                self.assertIn(f'"{canon}":"{canon}"', coach)
                self.assertIn(f'"{canon}":"{canon}"', disc)

    def test_spanish_infra_terms_map_same_in_both_routes(self):
        coach = alias_block(COACH)
        for es, canon in (("pared", "wall"), ("banco", "bench"),
                          ("barra de dominadas", "pullup_bar"), ("rack", "rack")):
            with self.subTest(term=es):
                self.assertIn(f'"{es}":"{canon}"', coach)

    def test_every_coach_infra_canonical_exists_in_disciplines(self):
        coach = alias_block(COACH)
        disc = alias_block(DISC)
        for canon in INFRA_CANONICALS:
            if f'"{canon}":"{canon}"' in coach:
                self.assertIn(f'"{canon}":"{canon}"', disc)


if __name__ == "__main__":
    unittest.main()
