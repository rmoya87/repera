#!/usr/bin/env python3
"""Borrador Fase A: propuestas de enriquecimiento (aliases + refs) sin tocar Supabase.

Lee out/repera_enrich_candidates.csv + vendor y genera out/phase_a_enrich_draft.json
para revisión humana. No escribe en la base de datos.
"""

from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
VENDOR = HERE / "vendor"
OUT = HERE / "out"


def main() -> int:
    enrich_path = OUT / "repera_enrich_candidates.csv"
    if not enrich_path.exists():
        print("Ejecuta antes match_catalog.py", file=sys.stderr)
        return 1

    fedb = {
        (ex.get("id") or ex["name"]): ex
        for ex in json.loads((VENDOR / "free_exercise_db.json").read_text(encoding="utf-8"))
    }
    owod = {
        ex["id"]: ex
        for ex in json.loads((VENDOR / "open_wod_movements.json").read_text(encoding="utf-8")).get(
            "movements", []
        )
    }
    oedb = {}
    oedb_path = VENDOR / "open_exercise_db_names.json"
    if oedb_path.exists():
        oedb = {
            str(ex["id"]): ex
            for ex in json.loads(oedb_path.read_text(encoding="utf-8")).get("exercises", [])
        }

    proposals = []
    for row in csv.DictReader(enrich_path.open(encoding="utf-8")):
        source = row["best_source"]
        sid = row["source_id"]
        aliases: list[str] = []
        instructions: list[str] = []
        description = None
        name_es = None
        attribution = None

        if source == "free_exercise_db":
            ex = fedb.get(sid) or next(
                (v for v in fedb.values() if v.get("name") == row["source_name"]), None
            )
            if ex:
                instructions = list(ex.get("instructions") or [])
                attribution = "Free Exercise DB (Unlicense) — text only; no images"
        elif source == "open_wod":
            ex = owod.get(sid)
            if ex:
                aliases = list(ex.get("aliases") or [])
                description = ex.get("description")
                attribution = (
                    "Open WOD Database, https://www.wodwiz.com/benchmarks (CC BY 4.0)"
                )
        elif source == "open_exercise_db":
            ex = oedb.get(sid)
            if ex:
                name_es = ex.get("name_es")
                if ex.get("name_en"):
                    aliases.append(ex["name_en"])
                attribution = "OpenExerciseDB (CC BY-SA 4.0) — names/taxonomy"

        # Alias mínimo: nombre de la fuente si difiere del nombre Repera
        if row["source_name"] and row["source_name"].casefold() != row["repera_name"].casefold():
            aliases.append(row["source_name"])
        if name_es and name_es.casefold() != row["repera_name"].casefold():
            aliases.append(name_es)

        # Dedup aliases casefold
        seen = set()
        clean_aliases = []
        for a in aliases:
            k = a.casefold().strip()
            if not k or k == row["repera_name"].casefold() or k in seen:
                continue
            seen.add(k)
            clean_aliases.append(a.strip())

        proposals.append(
            {
                "catalog_key": row["catalog_key"],
                "repera_name": row["repera_name"],
                "action": "enrich_only",
                "proposed_aliases_add": clean_aliases,
                "proposed_description_en": description,
                "proposed_instructions_en": instructions[:12],
                "sources_matched": row["sources_matched"].split(","),
                "attribution": attribution,
                "media": "keep_repera_exercise_art_or_generate_same_style",
                "notes": (
                    "Revisar calidad ES antes de publicar. "
                    "Si se usan instrucciones EN, traducir/adaptar a tono coach Repera "
                    "(CatalogSpanish). No importar fotos de la fuente."
                ),
            }
        )

    draft = {
        "phase": "A",
        "mode": "draft_for_human_review",
        "applies_to": "business_exercise_catalog + training_exercise_metadata via admin UPSERT",
        "do_not_auto_apply": True,
        "count": len(proposals),
        "art_policy": "Repera ExerciseArt style only (see tools/catalog_ingest/ART_STYLE.md)",
        "proposals": proposals,
    }
    out = OUT / "phase_a_enrich_draft.json"
    out.write_text(json.dumps(draft, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {out} ({len(proposals)} proposals). Review before any Supabase write.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
