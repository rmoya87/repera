#!/usr/bin/env python3
"""Import OpenPowerlifting Élite cubes from LiftGauge CC0 cohorts.json (offline seed).

Never call LiftGauge/OPL from apps at runtime. Prefer regenerating when a newer
LiftGauge release exists; otherwise rebuild from openpowerlifting-latest.csv via
`--from-csv` for a fresher all-ages+exact-age raw cube.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import urllib.request
import zipfile
from collections import defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path

LIFTS = {"squat": "squat", "bench": "benchPress", "deadlift": "deadlift"}
SEX_MAP = {"m": "male", "f": "female"}
QUANTILES = (10, 25, 50, 75, 90, 95, 99)
MIN_SAMPLE = 100
UA = "ReperaSeed/1.0 (OPL/LiftGauge offline import; https://repera.app/privacy#strength-reference)"
COHORTS_URL = "https://liftgauge.com/data/cohorts.json"
META_URL = "https://liftgauge.com/data/cohorts.meta.json"
OPL_ZIP_URL = "https://openpowerlifting.gitlab.io/opl-csv/files/openpowerlifting-latest.zip"

# IPF-style class upper bounds from LiftGauge bins.
BW_CLASSES = {
    "male": [53, 59, 66, 74, 83, 93, 105, 120, 999],
    "female": [43, 47, 52, 57, 63, 69, 76, 84, 999],
}


def fetch_json(url: str) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as response:
        return json.load(response)


def class_bounds(sex: str, upper: float) -> tuple[float, float]:
    edges = BW_CLASSES[sex]
    idx = edges.index(int(upper) if float(upper) != 999 else 999)
    prev = None if idx == 0 else edges[idx - 1]
    lo = 0.0 if prev is None else float(prev) + 0.0001
    hi = 400.0 if float(upper) >= 999 else float(upper) + 0.0001
    return (lo, hi)


def quantiles_from_cell(cell: dict) -> list[dict] | None:
    points = []
    for p in QUANTILES:
        key = f"p{p}"
        if key not in cell:
            continue
        kg = float(cell[key])
        if not math.isfinite(kg) or kg <= 0:
            return None
        points.append({"percentile": float(p), "weightKg": round(kg, 3)})
    if len(points) < 2:
        return None
    if any(b["weightKg"] <= a["weightKg"] for a, b in zip(points, points[1:])):
        return None
    return points


def from_liftgauge(cohorts: dict, revision: str) -> list[dict]:
    rows: list[dict] = []
    for key, cell in cohorts.get("percentile", {}).items():
        sex_k, lift_k, bw_k, age_k, equip_k = key.split("|")
        if equip_k != "raw" or lift_k not in LIFTS:
            continue
        n = int(cell.get("n") or 0)
        if n < MIN_SAMPLE:
            continue
        sex = SEX_MAP[sex_k]
        lift = LIFTS[lift_k]
        upper = float(bw_k)
        lo, hi = class_bounds(sex, upper)
        if age_k == "all":
            age_min, age_max = 14, 100
        else:
            age = int(age_k)
            age_min = age_max = age
        quantiles = quantiles_from_cell(cell)
        if not quantiles:
            continue
        rows.append(
            {
                "cohort": {
                    "lift": lift,
                    "sex": sex,
                    "equipment": "raw",
                    "ageMin": age_min,
                    "ageMax": age_max,
                    "bodyWeightMinKg": lo,
                    "bodyWeightMaxKg": hi,
                },
                "source": "OpenPowerlifting",
                "sourceRevision": revision,
                "sampleCount": n,
                "quantiles": quantiles,
            }
        )
    return rows


def assign_bw_bounds(sex: str, body: float) -> tuple[float, float] | None:
    edges = BW_CLASSES[sex]
    prev = None
    for upper in edges:
        lo = 0.0 if prev is None else float(prev) + 0.0001
        hi = 400.0 if upper >= 999 else float(upper) + 0.0001
        if lo <= body < hi:
            return (lo, hi)
        prev = upper
    return None


def quantile(values: list[float], percentile: float) -> float:
    position = (len(values) - 1) * percentile / 100
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return values[lower]
    return values[lower] + (values[upper] - values[lower]) * (position - lower)


def from_csv(path: Path, revision: str, window_days: int = 365) -> list[dict]:
    """Rebuild raw SBD cubes (exact age + all-ages) from an OPL CSV dump."""
    cutoff = date.today() - timedelta(days=window_days)
    # Best observation per (name,sex,lift,age_bin,bw_bin)
    best: dict[tuple, float] = {}
    with path.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        required = {
            "Name", "Sex", "Equipment", "Age", "BodyweightKg", "Date",
            "Best3SquatKg", "Best3BenchKg", "Best3DeadliftKg",
        }
        missing = required - set(reader.fieldnames or ())
        if missing:
            raise ValueError(f"Missing CSV columns: {sorted(missing)}")
        lift_cols = {
            "Best3SquatKg": "squat",
            "Best3BenchKg": "benchPress",
            "Best3DeadliftKg": "deadlift",
        }
        for row in reader:
            if row.get("Equipment") != "Raw":
                continue
            sex = {"M": "male", "F": "female"}.get(row.get("Sex") or "")
            if not sex:
                continue
            try:
                meet = datetime.strptime(row["Date"], "%Y-%m-%d").date()
            except Exception:
                continue
            if meet < cutoff:
                continue
            try:
                age = float(row["Age"])
                body = float(row["BodyweightKg"])
            except Exception:
                continue
            if not (14 <= age <= 100 and 30 <= body <= 300):
                continue
            bounds = assign_bw_bounds(sex, body)
            if not bounds:
                continue
            name = (row.get("Name") or "").strip().casefold()
            if not name:
                continue
            age_i = int(age)
            for col, lift in lift_cols.items():
                try:
                    value = float(row[col])
                except Exception:
                    continue
                if not math.isfinite(value) or value <= 0:
                    continue
                for age_key in (age_i, "all"):
                    identity = (name, sex, lift, age_key, bounds)
                    best[identity] = max(value, best.get(identity, 0.0))

    grouped: dict[tuple, list[float]] = defaultdict(list)
    for (name, sex, lift, age_key, bounds), value in best.items():
        grouped[(sex, lift, age_key, bounds)].append(value)

    rows: list[dict] = []
    for (sex, lift, age_key, bounds), values in grouped.items():
        if len(values) < MIN_SAMPLE:
            continue
        values.sort()
        points = []
        ok = True
        for p in QUANTILES:
            kg = round(quantile(values, float(p)), 3)
            if kg <= 0:
                ok = False
                break
            points.append({"percentile": float(p), "weightKg": kg})
        if not ok or any(b["weightKg"] <= a["weightKg"] for a, b in zip(points, points[1:])):
            continue
        if age_key == "all":
            age_min, age_max = 14, 100
        else:
            age_min = age_max = int(age_key)
        rows.append(
            {
                "cohort": {
                    "lift": lift,
                    "sex": sex,
                    "equipment": "raw",
                    "ageMin": age_min,
                    "ageMax": age_max,
                    "bodyWeightMinKg": bounds[0],
                    "bodyWeightMaxKg": bounds[1],
                },
                "source": "OpenPowerlifting",
                "sourceRevision": revision,
                "sampleCount": len(values),
                "quantiles": points,
            }
        )
    return rows


def download_opl_csv(dest: Path) -> Path:
    dest.parent.mkdir(parents=True, exist_ok=True)
    zip_path = dest.with_suffix(".zip")
    print(f"Downloading {OPL_ZIP_URL} …")
    req = urllib.request.Request(OPL_ZIP_URL, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=600) as response, zip_path.open("wb") as out:
        while True:
            chunk = response.read(1024 * 1024)
            if not chunk:
                break
            out.write(chunk)
    with zipfile.ZipFile(zip_path) as zf:
        names = [n for n in zf.namelist() if n.endswith(".csv")]
        if not names:
            raise RuntimeError("No CSV in OPL zip")
        # Prefer openpowerlifting.csv style
        name = sorted(names, key=lambda n: (0 if "openpowerlifting" in n.lower() else 1, len(n)))[0]
        print(f"Extracting {name}")
        with zf.open(name) as src, dest.open("wb") as out:
            out.write(src.read())
    return dest


def merge_keep_gym(existing: list[dict], opl: list[dict]) -> list[dict]:
    gym = [r for r in existing if r.get("source") == "SymmetricStrength"]
    return opl + gym


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--existing", type=Path, required=True, help="Current strength_benchmarks.json")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--android-out", type=Path, default=None)
    parser.add_argument("--from-csv", type=Path, default=None, help="Local OPL CSV; downloads latest if 'DOWNLOAD'")
    parser.add_argument("--liftgauge", action="store_true", help="Import from LiftGauge cohorts.json")
    args = parser.parse_args()

    existing = json.loads(args.existing.read_text(encoding="utf-8"))
    if args.from_csv is not None:
        csv_path = args.from_csv
        if str(csv_path) == "DOWNLOAD":
            csv_path = Path("/tmp/openpowerlifting-latest.csv")
            download_opl_csv(csv_path)
        digest = hashlib.sha256(csv_path.read_bytes()).hexdigest()[:16]
        revision = f"openpowerlifting-{date.today().isoformat()}-{digest}"
        print(f"Building Élite from CSV → {revision}")
        opl = from_csv(csv_path, revision)
    else:
        args.liftgauge = True
        meta = fetch_json(META_URL)
        cohorts = fetch_json(COHORTS_URL)
        revision = meta.get("dataset_id") or cohorts.get("dataset_id") or "liftgauge-unknown"
        print(f"Building Élite from LiftGauge → {revision}")
        opl = from_liftgauge(cohorts, revision)

    print(f"Élite rows: {len(opl)}")
    merged = merge_keep_gym(existing, opl)
    text = json.dumps(merged, ensure_ascii=False, separators=(",", ":"))
    args.out.write_text(text + "\n", encoding="utf-8")
    if args.android_out:
        args.android_out.write_text(text + "\n", encoding="utf-8")
    print(
        f"Wrote {len(merged)} "
        f"(OPL {sum(1 for r in merged if r['source']=='OpenPowerlifting')}, "
        f"gym {sum(1 for r in merged if r['source']=='SymmetricStrength')}) → {args.out}"
    )


if __name__ == "__main__":
    main()
