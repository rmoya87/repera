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
# También bajo outputs/ para que upload-artifact del workflow lo recoja.
UPLOAD_BATCHES="$RESULTS_ROOT/batches"
rm -rf "$MERGED_DIR" "$UPLOAD_BATCHES"
mkdir -p "$MERGED_DIR" "$UPLOAD_BATCHES"

mapfile -t CLASSES < <(python3 "$ANDROID/ci_selected_android_tests.py" | tr ',' '\n' | sed '/^$/d')
if ((${#CLASSES[@]} < 45)); then
  echo "ci_run_selected_android_tests: inventario demasiado pequeño (${#CLASSES[@]})" >&2
  exit 1
fi

echo "CI selected ${#CLASSES[@]} classes in batches of $BATCH_SIZE"
TOTAL_TESTS=0
BATCH_I=0
FAIL=0

dump_batch_failures() {
  local dest="$1"
  python3 - "$dest" <<'PY'
import re, sys
from pathlib import Path
root = Path(sys.argv[1])
for xml in sorted(root.glob("TEST-*.xml")):
    t = xml.read_text(encoding="utf-8", errors="ignore")
    for m in re.finditer(r"<testcase\b([^>]*)>(.*?)</testcase>", t, re.S):
        attrs, body = m.group(1), m.group(2)
        if "<failure" not in body and "<error" not in body:
            continue
        name = re.search(r'\bname="([^"]+)"', attrs)
        cls = re.search(r'\bclassname="([^"]+)"', attrs)
        msg = re.search(r'message="([^"]*)"', body)
        text = re.search(r"<(?:failure|error)[^>]*>([\s\S]*?)</(?:failure|error)>", body)
        stack = (text.group(1) if text else "").replace("&#10;", "\n")
        real = next(
            (
                line.strip()
                for line in stack.splitlines()
                if "dev.repera.mobile." in line and "InstrumentedTest" in line
            ),
            "",
        )
        print(
            "FAIL",
            (cls.group(1) if cls else "?") + "." + (name.group(1) if name else "?"),
        )
        if msg:
            print(" ", msg.group(1)[:300])
        if real:
            print(" ", real[:300])
PY
}

for ((i = 0; i < ${#CLASSES[@]}; i += BATCH_SIZE)); do
  BATCH_I=$((BATCH_I + 1))
  CHUNK=("${CLASSES[@]:i:BATCH_SIZE}")
  JOINED=$(IFS=,; echo "${CHUNK[*]}")
  echo "==> Batch $BATCH_I (${#CHUNK[@]} classes)"
  # Aislar SharedPreferences / checkpoints entre lotes.
  adb shell pm clear com.app.repera >/dev/null 2>&1 || true
  set +e
  gradle -p "$ANDROID" :mobile:connectedDebugAndroidTest \
    -Pandroid.testInstrumentationRunnerArguments.class="$JOINED" \
    --no-daemon --stacktrace
  CODE=$?
  set -e
  # Conservar XML de este lote antes del siguiente overwrite.
  if [[ -d "$RESULTS_ROOT" ]]; then
    DEST="$MERGED_DIR/batch-$(printf '%02d' "$BATCH_I")"
    mkdir -p "$DEST" "$UPLOAD_BATCHES/batch-$(printf '%02d' "$BATCH_I")"
    # No copiar el subdir batches/ sobre sí mismo.
    find "$RESULTS_ROOT" -maxdepth 1 -type f -name 'TEST-*.xml' -exec cp {} "$DEST"/ \;
    find "$RESULTS_ROOT" -maxdepth 1 -type f -name 'TEST-*.xml' -exec cp {} "$UPLOAD_BATCHES/batch-$(printf '%02d' "$BATCH_I")"/ \;
    for xml in "$DEST"/TEST-*.xml; do
      [[ -f "$xml" ]] || continue
      n=$(python3 - "$xml" <<'PY'
import re, sys
t = open(sys.argv[1], encoding="utf-8", errors="ignore").read()
m = re.search(r'tests="(\d+)"', t)
print(int(m.group(1)) if m else 0)
PY
)
      TOTAL_TESTS=$((TOTAL_TESTS + n))
    done
    if [[ "$CODE" -ne 0 ]]; then
      dump_batch_failures "$DEST"
    fi
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
