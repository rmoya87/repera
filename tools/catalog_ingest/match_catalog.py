#!/usr/bin/env python3
"""Cruza Repera (290) con Free Exercise DB + Open WOD (+ OpenExerciseDB opcional).

Clasifica cada fila externa: matched | enrichable | new | ambiguous.
No escribe en Supabase ni modifica el seed.
"""

from __future__ import annotations

import csv
import json
import re
import sys
import unicodedata
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
VENDOR = HERE / "vendor"
OUT = HERE / "out"

DOMAIN = ROOT / "Packages/ReperaDomain/Sources/ReperaDomain"


def normalize(value: str) -> str:
    text = unicodedata.normalize("NFKD", value or "")
    text = "".join(c for c in text if not unicodedata.combining(c))
    text = text.casefold()
    text = text.replace("&", " and ")
    text = re.sub(r"[_\-/]+", " ", text)
    text = re.sub(r"[^a-z0-9\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    # Colapsar plurales triviales de tokens finales comunes.
    synonyms = {
        "pullups": "pull up",
        "pullup": "pull up",
        "chinups": "chin up",
        "chinup": "chin up",
        "pushups": "push up",
        "pushup": "push up",
        "situps": "sit up",
        "situp": "sit up",
        "dumbbells": "dumbbell",
        "kettlebells": "kettlebell",
        "barbells": "barbell",
        "lunges": "lunge",
        "squats": "squat",
        "burpees": "burpee",
        "deadlifts": "deadlift",
        "presses": "press",
        "rows": "row",
        "curls": "curl",
    }
    tokens = [synonyms.get(t, t) for t in text.split()]
    joined = " ".join(tokens)
    phrases = {
        "pull ups": "pull up",
        "chin ups": "chin up",
        "push ups": "push up",
        "sit ups": "sit up",
        "muscle ups": "muscle up",
        "muscle up": "muscle up",
    }
    return phrases.get(joined, joined)


def parse_swift_string_dict(path: Path, const_name: str) -> dict[str, str]:
    """Extrae `[String: String]` literales simples de un enum Swift."""
    src = path.read_text(encoding="utf-8")
    marker = f"private static let {const_name}"
    start = src.find(marker)
    if start < 0:
        return {}
    brace = src.find("{", start)
    if brace < 0:
        return {}
    # Busca el primer `[` de diccionario tras el `{` o `=`
    bracket = src.find("[", brace)
    if bracket < 0:
        return {}
    depth = 0
    i = bracket
    while i < len(src):
        c = src[i]
        if c == "[":
            depth += 1
        elif c == "]":
            depth -= 1
            if depth == 0:
                body = src[bracket + 1 : i]
                break
        i += 1
    else:
        return {}
    pairs = re.findall(r'"((?:\\.|[^"\\])*)"\s*:\s*"((?:\\.|[^"\\])*)"', body)
    out: dict[str, str] = {}
    for a, b in pairs:
        out[a.replace('\\"', '"')] = b.replace('\\"', '"')
    return out


def load_repera() -> list[dict]:
    catalog = json.loads(
        (ROOT / "web/console/src/data/exercise-catalog.json").read_text(encoding="utf-8")
    )["exercises"]
    aliases_path = ROOT / "android/mobile/src/main/assets/exercise_search_aliases.json"
    android_aliases = json.loads(aliases_path.read_text(encoding="utf-8"))

    sport = DOMAIN / "SportExerciseNames.swift"
    legacy_es_en = parse_swift_string_dict(sport, "legacySpanishToEnglish")
    original_en_es = parse_swift_string_dict(sport, "originalEnglishAliases")

    movilidad = DOMAIN / "CatalogMovilidad.swift"
    mov_src = movilidad.read_text(encoding="utf-8") if movilidad.exists() else ""
    # englishAliasesByName: "Nombre": ["en1", "en2"]
    mov_aliases: dict[str, list[str]] = defaultdict(list)
    for m in re.findall(
        r'"((?:\\.|[^"\\])*)"\s*:\s*\[((?:.|\n)*?)\]',
        mov_src,
    ):
        name, arr = m
        engs = re.findall(r'"((?:\\.|[^"\\])*)"', arr)
        if engs and len(name) < 80:
            mov_aliases[name.replace('\\"', '"')] = [e.replace('\\"', '"') for e in engs]

    rows = []
    for ex in catalog:
        name = ex["name"]
        labels = {name}
        name_n = normalize(name)
        if name in android_aliases:
            labels.add(android_aliases[name])
        # aliases.json: claves de búsqueda EN/ES → nombre canónico (comparar normalizado)
        for k, v in android_aliases.items():
            if normalize(v) == name_n or normalize(k) == name_n:
                labels.add(k)
                labels.add(v)
        if name in legacy_es_en:
            labels.add(legacy_es_en[name])
        for es, en in legacy_es_en.items():
            if normalize(en) == name_n or normalize(es) == name_n:
                labels.add(es)
                labels.add(en)
        if name in original_en_es:
            labels.add(original_en_es[name])
        for en, es in original_en_es.items():
            if normalize(en) == name_n or normalize(es) == name_n:
                labels.add(en)
                labels.add(es)
        for es_name, engs in mov_aliases.items():
            if normalize(es_name) == name_n or any(normalize(e) == name_n for e in engs):
                labels.add(es_name)
                labels.update(engs)
        labels = {x.strip() for x in labels if x and x.strip()}
        rows.append(
            {
                "catalog_key": ex["catalogKey"],
                "name": name,
                "category": ex.get("category") or "",
                "labels": sorted(labels),
                "norms": sorted({normalize(x) for x in labels if normalize(x)}),
            }
        )
    return rows


@dataclass
class Hit:
    catalog_key: str
    repera_name: str
    score: float
    via: str


@dataclass
class ExtRow:
    source: str
    source_id: str
    name: str
    aliases: list[str] = field(default_factory=list)
    instructions: list[str] = field(default_factory=list)
    description: str | None = None
    primary_muscles: list[str] = field(default_factory=list)
    secondary_muscles: list[str] = field(default_factory=list)
    equipment: str | None = None
    category: str | None = None
    name_es: str | None = None
    media_forbidden: bool = True


def token_set(s: str) -> set[str]:
    return set(normalize(s).split()) - {"a", "the", "and", "con", "de", "del", "la", "el", "en"}


def jaccard(a: set[str], b: set[str]) -> float:
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


def best_hits(ext: ExtRow, index: dict[str, list[dict]], repera: list[dict]) -> list[Hit]:
    candidates: dict[str, Hit] = {}
    labels = [ext.name, *(ext.aliases or [])]
    if ext.name_es:
        labels.append(ext.name_es)
    for label in labels:
        n = normalize(label)
        if not n:
            continue
        for row in index.get(n, []):
            hit = Hit(row["catalog_key"], row["name"], 1.0, f"exact:{label}")
            prev = candidates.get(hit.catalog_key)
            if not prev or hit.score > prev.score:
                candidates[hit.catalog_key] = hit

    if candidates:
        return sorted(candidates.values(), key=lambda h: -h.score)

    # Fuzzy: jaccard sobre tokens del mejor label vs cada ficha Repera.
    ext_sets = [token_set(l) for l in labels if token_set(l)]
    fuzzy: list[Hit] = []
    for row in repera:
        best = 0.0
        via = ""
        for rs in row["norms"]:
            rt = set(rs.split())
            for et in ext_sets:
                score = jaccard(et, rt)
                if score > best:
                    best = score
                    via = f"fuzzy:{rs}"
        if best >= 0.72:
            fuzzy.append(Hit(row["catalog_key"], row["name"], best, via))
    fuzzy.sort(key=lambda h: -h.score)
    return fuzzy[:3]


def classify(hits: list[Hit]) -> str:
    if not hits:
        return "new"
    top = hits[0]
    if top.score >= 0.999:
        # Ambiguo si dos exactos distintos.
        exact = [h for h in hits if h.score >= 0.999]
        keys = {h.catalog_key for h in exact}
        if len(keys) > 1:
            return "ambiguous"
        return "matched"
    if top.score >= 0.72:
        if len(hits) > 1 and abs(hits[0].score - hits[1].score) < 0.05:
            return "ambiguous"
        return "ambiguous" if top.score < 0.85 else "matched"
    return "new"


def enrichable_fields(ext: ExtRow) -> str:
    bits = []
    if ext.aliases:
        bits.append("aliases")
    if ext.instructions:
        bits.append("instructions")
    if ext.description:
        bits.append("description")
    if ext.primary_muscles or ext.secondary_muscles:
        bits.append("muscles")
    if ext.equipment:
        bits.append("equipment")
    if ext.name_es:
        bits.append("name_es")
    return ",".join(bits)


def load_external() -> list[ExtRow]:
    rows: list[ExtRow] = []
    fedb = json.loads((VENDOR / "free_exercise_db.json").read_text(encoding="utf-8"))
    for ex in fedb:
        rows.append(
            ExtRow(
                source="free_exercise_db",
                source_id=ex.get("id") or normalize(ex["name"]).replace(" ", "_"),
                name=ex["name"],
                aliases=[],
                instructions=list(ex.get("instructions") or []),
                primary_muscles=list(ex.get("primaryMuscles") or []),
                secondary_muscles=list(ex.get("secondaryMuscles") or []),
                equipment=ex.get("equipment"),
                category=ex.get("category"),
                media_forbidden=True,
            )
        )

    owod = json.loads((VENDOR / "open_wod_movements.json").read_text(encoding="utf-8"))
    for ex in owod.get("movements", []):
        rows.append(
            ExtRow(
                source="open_wod",
                source_id=ex.get("id") or normalize(ex["name"]).replace(" ", "_"),
                name=ex["name"],
                aliases=list(ex.get("aliases") or []),
                description=ex.get("description"),
                equipment=",".join(ex.get("equipment") or []) or None,
                category=ex.get("category"),
                media_forbidden=True,
            )
        )

    oedb_path = VENDOR / "open_exercise_db_names.json"
    if oedb_path.exists():
        oedb = json.loads(oedb_path.read_text(encoding="utf-8"))
        for ex in oedb.get("exercises", []):
            if not ex.get("recommended"):
                continue
            rows.append(
                ExtRow(
                    source="open_exercise_db",
                    source_id=str(ex["id"]),
                    name=ex.get("name_en") or ex.get("title") or "",
                    name_es=ex.get("name_es"),
                    media_forbidden=True,
                )
            )
    return rows


def write_csv(path: Path, fieldnames: list[str], rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=fieldnames)
        w.writeheader()
        for row in rows:
            w.writerow(row)


def main() -> int:
    if not (VENDOR / "free_exercise_db.json").exists():
        print("Falta vendor: ejecuta python3 tools/catalog_ingest/fetch_sources.py", file=sys.stderr)
        return 1

    OUT.mkdir(parents=True, exist_ok=True)
    repera = load_repera()
    index: dict[str, list[dict]] = defaultdict(list)
    for row in repera:
        for n in row["norms"]:
            index[n].append(row)

    external = load_external()
    report_rows: list[dict] = []
    by_status: dict[str, int] = defaultdict(int)
    by_source_status: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    repera_hits: dict[str, list[dict]] = defaultdict(list)

    for ext in external:
        hits = best_hits(ext, index, repera)
        status = classify(hits)
        # matched con campos útiles → enrichable a efectos de reporte
        disposition = status
        if status == "matched" and enrichable_fields(ext):
            disposition = "enrichable"

        by_status[disposition] += 1
        by_source_status[ext.source][disposition] += 1
        top = hits[0] if hits else None
        row = {
            "source": ext.source,
            "source_id": ext.source_id,
            "name": ext.name,
            "name_es": ext.name_es or "",
            "aliases": " | ".join(ext.aliases),
            "status": disposition,
            "match_catalog_key": top.catalog_key if top else "",
            "match_repera_name": top.repera_name if top else "",
            "score": f"{top.score:.3f}" if top else "",
            "via": top.via if top else "",
            "alt_matches": " | ".join(
                f"{h.repera_name}({h.score:.2f})" for h in hits[1:3]
            ),
            "enrich_fields": enrichable_fields(ext),
            "instruction_count": len(ext.instructions),
            "has_description": bool(ext.description),
            "media_policy": "repera_art_only",
            "equipment": ext.equipment or "",
            "category": ext.category or "",
            "primary_muscles": ",".join(ext.primary_muscles),
        }
        report_rows.append(row)
        if top and disposition in {"matched", "enrichable"}:
            repera_hits[top.catalog_key].append(row)

    fields = list(report_rows[0].keys()) if report_rows else []
    write_csv(OUT / "overlap_report.csv", fields, report_rows)
    write_csv(
        OUT / "new_candidates.csv",
        fields,
        [r for r in report_rows if r["status"] == "new"],
    )
    write_csv(
        OUT / "ambiguous.csv",
        fields,
        [r for r in report_rows if r["status"] == "ambiguous"],
    )

    enrich_rows = []
    for key, hits in sorted(repera_hits.items()):
        # Preferir la fuente con más campos enriquecibles
        best = max(
            hits,
            key=lambda r: (len(r["enrich_fields"].split(",")) if r["enrich_fields"] else 0, r["source"]),
        )
        enrich_rows.append(
            {
                "catalog_key": key,
                "repera_name": best["match_repera_name"],
                "best_source": best["source"],
                "source_id": best["source_id"],
                "source_name": best["name"],
                "enrich_fields": best["enrich_fields"],
                "instruction_count": best["instruction_count"],
                "sources_matched": ",".join(sorted({h["source"] for h in hits})),
                "match_count": len(hits),
            }
        )
    write_csv(
        OUT / "repera_enrich_candidates.csv",
        list(enrich_rows[0].keys()) if enrich_rows else ["catalog_key"],
        enrich_rows,
    )

    # Cobertura: cuántas fichas Repera tienen al menos un match
    covered = len(repera_hits)
    summary = {
        "repera_count": len(repera),
        "repera_with_external_match": covered,
        "repera_without_match": len(repera) - covered,
        "external_total": len(external),
        "by_status": dict(by_status),
        "by_source_status": {k: dict(v) for k, v in by_source_status.items()},
        "art_policy": "Never import third-party exercise photos/GIFs; use Repera ExerciseArt style only.",
        "outputs": [
            "overlap_report.csv",
            "repera_enrich_candidates.csv",
            "new_candidates.csv",
            "ambiguous.csv",
        ],
    }
    (OUT / "overlap_summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(json.dumps(summary, ensure_ascii=False, indent=2))
    print(f"\nCSV en {OUT.relative_to(ROOT)}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
