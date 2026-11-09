#!/usr/bin/env python3
"""One-time FitnessVolt gym (Symmetric Strength) import into Repera benchmark JSON.

CC BY 4.0: attribution lives on repera.app/privacy and /terms.
Do NOT call FitnessVolt from apps at runtime — only this offline seed.

Usage:
  python3 scripts/import_fitnessvolt_gym_seed.py \\
    --opl Apps/Repera/Resources/strength_benchmarks.json \\
    --out Apps/Repera/Resources/strength_benchmarks.json \\
    --android-out android/mobile/src/main/assets/strength_benchmarks.json
"""
from __future__ import annotations

import argparse
import json
import re
import urllib.request
from pathlib import Path

# All gym lifts published by FitnessVolt Symmetric Strength (CC BY).
LIFTS = {
    "squat": "squat",
    "bench-press": "benchPress",
    "deadlift": "deadlift",
    "front-squat": "frontSquat",
    "sumo-deadlift": "sumoDeadlift",
    "power-clean": "powerClean",
    "incline-bench-press": "inclineBenchPress",
    "overhead-press": "overheadPress",
    "push-press": "pushPress",
    "snatch-press": "snatchPress",
    "dip": "dip",
    "chin-up": "chinUp",
    "pull-up": "pullUp",
    "pendlay-row": "pendlayRow",
}
SEXES = ("male", "female")
SOURCE = "SymmetricStrength"
REVISION = "fitnessvolt-gym-seed-2026-11-09-all-lifts"
UA = "ReperaSeed/1.0 (one-time CC BY import; https://repera.app/privacy#strength-reference)"
BASE = "https://fitnessvolt.com/wp-json/rpe-training/v1/public/standards"
MIN_SAMPLE = 100


def fetch(lift_slug: str, sex: str) -> dict:
    url = f"{BASE}/{lift_slug}?sex={sex}&unit=kg"
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as response:
        payload = json.load(response)
    if not payload.get("success") or "gym" not in payload:
        raise RuntimeError(f"Unexpected payload for {lift_slug}/{sex}")
    return payload["gym"]


def parse_class_limit(label: str) -> float | None:
    text = label.strip().lower()
    if text.endswith("+kg"):
        return float(text[:-3])
    match = re.fullmatch(r"(\d+(?:\.\d+)?)kg", text)
    return float(match.group(1)) if match else None


def class_bounds(labels: list[str]) -> list[tuple[str, float, float]]:
    """Map FV weight-class labels to [min, max) kg bands (IPF-style)."""
    parsed: list[tuple[str, float, bool]] = []
    for label in labels:
        text = label.strip().lower()
        plus = text.endswith("+kg")
        limit = parse_class_limit(text if not plus else text)
        if limit is None:
            raise ValueError(f"Unrecognized weight class: {label}")
        parsed.append((label, limit, plus))
    limits = [item[1] for item in parsed]
    if limits != sorted(limits):
        raise ValueError(f"Weight classes not ascending: {labels}")
    bands: list[tuple[str, float, float]] = []
    previous = 0.0
    for label, limit, plus in parsed:
        if plus:
            bands.append((label, limit, 400.0))
        else:
            bands.append((label, previous, limit + 0.0001))
            previous = limit + 0.0001
    return bands


def quantiles_from(percentiles: dict) -> list[dict]:
    points = []
    for key, value in percentiles.items():
        if not key.startswith("p"):
            continue
        pct = float(key[1:])
        kg = float(value)
        if not (0 <= pct <= 100) or not (kg > 0):
            continue
        points.append({"percentile": pct, "weightKg": round(kg, 3)})
    points.sort(key=lambda row: row["percentile"])
    cleaned: list[dict] = []
    for row in points:
        if cleaned and row["weightKg"] <= cleaned[-1]["weightKg"]:
            continue
        cleaned.append(row)
    return cleaned


def gym_rows(gym: dict, lift: str, sex: str) -> list[dict]:
    classes = gym.get("weight_classes") or []
    labels = [row["weight_class"] for row in classes]
    bands = {label: (lo, hi) for label, lo, hi in class_bounds(labels)}
    out: list[dict] = []
    for row in classes:
        sample = int(row.get("sample_size") or 0)
        if sample < MIN_SAMPLE:
            continue
        lo, hi = bands[row["weight_class"]]
        quantiles = quantiles_from(row.get("percentiles") or {})
        if len(quantiles) < 2:
            continue
        out.append(
            {
                "cohort": {
                    "lift": lift,
                    "sex": sex,
                    "equipment": "raw",
                    "ageMin": 14,
                    "ageMax": 100,
                    "bodyWeightMinKg": lo,
                    "bodyWeightMaxKg": hi,
                },
                "source": SOURCE,
                "sourceRevision": REVISION,
                "sampleCount": sample,
                "quantiles": quantiles,
            }
        )
    return out


def build_amateur() -> list[dict]:
    rows: list[dict] = []
    for slug, lift in LIFTS.items():
        for sex in SEXES:
            gym = fetch(slug, sex)
            chunk = gym_rows(gym, lift, sex)
            if not chunk:
                raise RuntimeError(f"No gym cohorts for {slug}/{sex}")
            rows.extend(chunk)
            print(f"  {slug}/{sex}: {len(chunk)} cohorts")
    return rows


def merge(opl: list[dict], amateur: list[dict]) -> list[dict]:
    kept = [row for row in opl if row.get("source") != SOURCE]
    return kept + amateur


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--opl", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--android-out", type=Path, default=None)
    parser.add_argument("--fixture", type=Path, default=None, help="Skip network; load gym payloads JSON")
    args = parser.parse_args()

    opl = json.loads(args.opl.read_text(encoding="utf-8"))
    if not isinstance(opl, list):
        raise SystemExit("OPL file must be a JSON array")

    if args.fixture:
        fixture = json.loads(args.fixture.read_text(encoding="utf-8"))
        amateur: list[dict] = []
        for slug, lift in LIFTS.items():
            for sex in SEXES:
                key = f"{slug}:{sex}"
                if key not in fixture:
                    continue
                amateur.extend(gym_rows(fixture[key]["gym"], lift, sex))
    else:
        amateur = build_amateur()

    merged = merge(opl, amateur)
    text = json.dumps(merged, ensure_ascii=False, separators=(",", ":"))
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(text + "\n", encoding="utf-8")
    if args.android_out:
        args.android_out.parent.mkdir(parents=True, exist_ok=True)
        args.android_out.write_text(text + "\n", encoding="utf-8")
    print(
        f"Wrote {len(merged)} distributions "
        f"({sum(1 for r in merged if r['source']=='OpenPowerlifting')} OPL, "
        f"{sum(1 for r in merged if r['source']==SOURCE)} gym) → {args.out}"
    )


if __name__ == "__main__":
    main()
