#!/usr/bin/env bash
# Ejecuta androidTest en lotes cortos. Un único -Pclass=a,b,c… muy largo
# (AGP 9.4.x) truncaba el extra del InstrumentationRunner y solo corría la
# primera clase → falso verde (p. ej. 2 tests). Lotes evitan el truncado y
# aíslan estado estático entre grupos. Fallar = cualquier lote ≠ 0.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID="$ROOT/android"
BATCH_SIZE="${CI_ANDROID_TEST_BATCH_SIZE:-8}"
RESULTS_ROOT="$ANDROID/mobile/build/outputs/androidTest-results/connected/debug"
MERGED_DIR="$ANDROID/mobile/build/ci-instrumented-batches"
rm -rf "$MERGED_DIR"
mkdir -p "$MERGED_DIR"

mapfile -t CLASSES < <(python3 "$ANDROID/ci_selected_android_tests.py" | tr ',' '\n' | sed '/^$/d')
if ((${#CLASSES[@]} < 45)); then
  echo "ci_run_selected_android_tests: inventario demasiado pequeño (${#CLASSES[@]})" >&2
  exit 1
fi

echo "CI selected ${#CLASSES[@]} classes in batches of $BATCH_SIZE"
TOTAL_TESTS=0
BATCH_I=0
FAIL=0

for ((i = 0; i < ${#CLASSES[@]}; i += BATCH_SIZE)); do
  BATCH_I=$((BATCH_I + 1))
  CHUNK=("${CLASSES[@]:i:BATCH_SIZE}")
  JOINED=$(IFS=,; echo "${CHUNK[*]}")
  echo "==> Batch $BATCH_I (${#CHUNK[@]} classes)"
  set +e
  gradle -p "$ANDROID" :mobile:connectedDebugAndroidTest \
    -Pandroid.testInstrumentationRunnerArguments.class="$JOINED" \
    --no-daemon --stacktrace
  CODE=$?
  set -e
  # Conservar XML de este lote antes del siguiente overwrite.
  if [[ -d "$RESULTS_ROOT" ]]; then
    DEST="$MERGED_DIR/batch-$(printf '%02d' "$BATCH_I")"
    mkdir -p "$DEST"
    cp -a "$RESULTS_ROOT"/. "$DEST"/ || true
    for xml in "$DEST"/TEST-*.xml; do
      [[ -f "$xml" ]] || continue
      n=$(python3 - <<PY
import re,sys
t=open(sys.argv[1],encoding='utf-8',errors='ignore').read()
m=re.search(r'tests="(\d+)"', t)
print(int(m.group(1)) if m else 0)
PY
"$xml")
      TOTAL_TESTS=$((TOTAL_TESTS + n))
    done
  fi
  if [[ "$CODE" -ne 0 ]]; then
    echo "Batch $BATCH_I FAILED (exit $CODE)" >&2
    FAIL=1
  fi
done

echo "CI instrumented batches done: total_tests≈$TOTAL_TESTS fail=$FAIL"
if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
if [[ "$TOTAL_TESTS" -lt 100 ]]; then
  echo "FALLO HARNESS - demasiado pocos tests agregados ($TOTAL_TESTS)" >&2
  exit 1
fi
# Dejar un XML agregado mínimo para el chequeo legacy del workflow.
mkdir -p "$RESULTS_ROOT"
python3 - <<PY
from pathlib import Path
root = Path("$MERGED_DIR")
n = 0
fails = 0
for xml in root.rglob("TEST-*.xml"):
    t = xml.read_text(encoding="utf-8", errors="ignore")
    import re
    m = re.search(r'tests="(\d+)"', t)
    f = re.search(r'failures="(\d+)"', t)
    e = re.search(r'errors="(\d+)"', t)
    if m: n += int(m.group(1))
    if f: fails += int(f.group(1))
    if e: fails += int(e.group(1))
out = Path("$RESULTS_ROOT") / "TEST-ci-batches-summary.xml"
out.write_text(
    f'<testsuites tests="{n}" failures="{fails}" errors="0" skipped="0"/>\n',
    encoding="utf-8",
)
print(out, "tests", n, "failures", fails)
PY
