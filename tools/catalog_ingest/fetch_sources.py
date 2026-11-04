#!/usr/bin/env python3
"""Descarga snapshots de fuentes abiertas a tools/catalog_ingest/vendor/."""

from __future__ import annotations

import argparse
import json
import ssl
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VENDOR = Path(__file__).resolve().parent / "vendor"

SOURCES = {
    "free_exercise_db.json": (
        "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json"
    ),
    "open_wod_movements.json": (
        "https://raw.githubusercontent.com/WodWiz/open-wod-db/main/data/movements.json"
    ),
}

# Índice ligero EN/ES desde el explorador HTML público (sin clonar 900 YAML).
OEDB_SEARCH = "https://rfivesix.github.io/OpenExerciseDB/exercise-search.html"


def download(url: str, dest: Path, context: ssl.SSLContext) -> None:
    print(f"→ {url}")
    req = urllib.request.Request(url, headers={"User-Agent": "repera-catalog-ingest/1.0"})
    with urllib.request.urlopen(req, context=context, timeout=120) as resp:
        data = resp.read()
    dest.write_bytes(data)
    print(f"  wrote {dest.relative_to(ROOT)} ({len(data)} bytes)")


def parse_oedb_html(html: str) -> list[dict]:
    """Extrae id, name EN/ES y status del HTML estático de búsqueda."""
    import re

    entries: list[dict] = []
    # <article id="exercise-1000"><h3>Floor Dips <code>id/uuid: 1000</code></h3>…
    for m in re.finditer(
        r'<article[^>]*>\s*<h3>(.*?)<code>id/uuid:\s*([^<]+)</code></h3>(.*?)</article>',
        html,
        flags=re.IGNORECASE | re.DOTALL,
    ):
        title = re.sub(r"<[^>]+>", "", m.group(1)).strip()
        eid = m.group(2).strip()
        rest = m.group(3)
        en = re.search(r"\ben:\s*([^·<\n]+)", rest)
        es = re.search(r"\bes:\s*([^·<\n]+)", rest)
        recommended = "RECOMMENDED FOR ROUTINES" in rest
        status = "active" if recommended else "other"
        if re.search(r"retired|merged", rest, flags=re.IGNORECASE):
            status = "retired_or_merged"
        entries.append(
            {
                "id": eid,
                "title": title,
                "name_en": (en.group(1).strip() if en else title),
                "name_es": (es.group(1).strip() if es else None),
                "status": status,
                "recommended": recommended,
            }
        )
    return entries


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--with-oedb",
        action="store_true",
        help="Descarga el HTML de OpenExerciseDB y genera open_exercise_db_names.json",
    )
    args = parser.parse_args()
    VENDOR.mkdir(parents=True, exist_ok=True)
    ctx = ssl.create_default_context()

    for name, url in SOURCES.items():
        download(url, VENDOR / name, ctx)

    fedb = json.loads((VENDOR / "free_exercise_db.json").read_text(encoding="utf-8"))
    owod = json.loads((VENDOR / "open_wod_movements.json").read_text(encoding="utf-8"))
    print(f"Free Exercise DB: {len(fedb)} exercises")
    print(f"Open WOD movements: {owod.get('count', len(owod.get('movements', [])))}")

    if args.with_oedb:
        dest_html = VENDOR / "open_exercise_db_search.html"
        download(OEDB_SEARCH, dest_html, ctx)
        entries = parse_oedb_html(dest_html.read_text(encoding="utf-8", errors="replace"))
        out = VENDOR / "open_exercise_db_names.json"
        out.write_text(
            json.dumps({"count": len(entries), "exercises": entries}, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        active = sum(1 for e in entries if e.get("recommended"))
        print(f"OpenExerciseDB names: {len(entries)} ({active} recommended)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
