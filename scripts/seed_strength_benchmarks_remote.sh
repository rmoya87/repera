#!/usr/bin/env bash
# Re-seed OpenPowerlifting + SymmetricStrength rows into the linked Supabase project.
# Requires: supabase CLI linked to Repera (uvzgujlrqohreoucirms).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JSON="$ROOT/Apps/Repera/Resources/strength_benchmarks.json"
OUT="/tmp/repera_strength_seed"
mkdir -p "$OUT"
python3 - <<PY
import json, math
from pathlib import Path
rows = json.loads(Path("$JSON").read_text())
assert len(rows) >= 800
out = Path("$OUT")
batch, batches = [], []
for i, r in enumerate(rows):
    c = r["cohort"]
    q = json.dumps(r["quantiles"], separators=(",", ":")).replace("'", "''")
    batch.append(
        f"('{c['lift']}','{c['sex']}','{c['equipment']}',{int(c['ageMin'])},{int(c['ageMax'])},"
        f"{float(c['bodyWeightMinKg'])},{float(c['bodyWeightMaxKg'])},"
        f"'{r['source']}','{r['sourceRevision']}',{int(r['sampleCount'])},"
        f"'{q}'::jsonb,true,now())"
    )
    if len(batch) >= 50 or i == len(rows) - 1:
        batches.append(batch); batch = []
for i, b in enumerate(batches):
    sql = (
        "INSERT INTO public.strength_benchmark_distributions ("
        "lift,sex,equipment,age_min,age_max,body_weight_min_kg,body_weight_max_kg,"
        "source,source_revision,sample_count,quantiles,is_active,updated_at) VALUES\n"
        + ",\n".join(b)
        + "\nON CONFLICT (lift,sex,equipment,age_min,age_max,body_weight_min_kg,body_weight_max_kg,source,source_revision)\n"
        "DO UPDATE SET sample_count=EXCLUDED.sample_count, quantiles=EXCLUDED.quantiles, is_active=true, updated_at=now();"
    )
    (out / f"batch_{i:03d}.sql").write_text(sql)
print(f"batches={len(batches)} rows={len(rows)}")
PY
for f in "$OUT"/batch_*.sql; do
  echo "=== $(basename "$f") ==="
  supabase db query --linked --yes -f "$f" >/dev/null
done
supabase db query --linked --yes "select source, count(*)::int n from public.strength_benchmark_distributions group by 1 order by 1;"
