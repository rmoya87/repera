#!/usr/bin/env python3
"""Build aggregate OpenPowerlifting competition benchmarks without exporting PII.

Usage:
  python3 scripts/build_strength_benchmarks.py --input openpowerlifting.csv --output benchmarks.json --revision 2026-11

This tool does not download data or publish it. Source is competition data,
not a representative sample of the general population.
"""
import argparse
import csv
import json
import math
from collections import defaultdict
from pathlib import Path

LIFTS = {"Best3SquatKg": "squat", "Best3BenchKg": "benchPress", "Best3DeadliftKg": "deadlift"}
EQUIPMENT = {"Raw": "raw", "Wraps": "wraps", "Single-ply": "singlePly", "Multi-ply": "multiPly"}
SEX = {"M": "male", "F": "female"}
QUANTILES = (10, 25, 50, 75, 90)
MIN_SAMPLE = 100

def number(raw):
    try:
        result = float(raw)
        return result if math.isfinite(result) and result > 0 else None
    except (TypeError, ValueError):
        return None

def quantile(values, percentile):
    position = (len(values) - 1) * percentile / 100
    lower = math.floor(position)
    upper = math.ceil(position)
    return values[lower] + (values[upper] - values[lower]) * (position - lower)

def aggregate(source, revision):
    # Best valid result per normalized athlete identity, cohort and lift.
    # Name-based identity is imperfect; never claim precise population prevalence.
    best = {}
    with open(source, newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        required = {"Name", "Sex", "Equipment", "Age", "BodyweightKg", *LIFTS}
        missing = required - set(reader.fieldnames or ())
        if missing:
            raise ValueError(f"Missing CSV columns: {sorted(missing)}")
        for row in reader:
            sex = SEX.get(row["Sex"])
            equipment = EQUIPMENT.get(row["Equipment"])
            age = number(row["Age"])
            body = number(row["BodyweightKg"])
            name = row["Name"].strip().casefold()
            if not name or not sex or not equipment or not age or not body:
                continue
            if not 14 <= age <= 100 or not 30 <= body <= 300:
                continue
            age_min = int(age // 5) * 5
            weight_min = int(body // 10) * 10
            for column, lift in LIFTS.items():
                value = number(row[column])
                if value is None:
                    continue
                cohort = (lift, sex, equipment, age_min, weight_min)
                identity = (cohort, name)
                best[identity] = max(value, best.get(identity, 0))

    grouped = defaultdict(list)
    for (cohort, _), value in best.items():
        grouped[cohort].append(value)

    output = []
    for (lift, sex, equipment, age_min, weight_min), values in sorted(grouped.items()):
        if len(values) < MIN_SAMPLE:
            continue
        values.sort()
        points = [{"percentile": p, "weightKg": round(quantile(values, p), 2)} for p in QUANTILES]
        # Degenerate quantiles are not safe for interpolation.
        if any(b["weightKg"] <= a["weightKg"] for a, b in zip(points, points[1:])):
            continue
        output.append({
            "cohort": {
                "lift": lift, "sex": sex, "equipment": equipment,
                "ageMin": age_min, "ageMax": age_min + 4,
                "bodyWeightMinKg": weight_min, "bodyWeightMaxKg": weight_min + 10,
            },
            "source": "OpenPowerlifting",
            "sourceRevision": revision,
            "sampleCount": len(values),
            "quantiles": points,
        })
    return output

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--revision", required=True)
    args = parser.parse_args()
    if not args.revision.strip():
        parser.error("--revision must be nonempty")
    data = aggregate(args.input, args.revision.strip())
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Exported {len(data)} aggregate cohorts; no individual records")

if __name__ == "__main__":
    main()
