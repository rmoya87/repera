#!/usr/bin/env bash
# Promueve HEAD a origin/beta solo tras preflight local + Play gate verde.
# No uses `git push origin main:beta` a ciegas.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SKIP_LOCAL=0
WAIT_SECS=2400
POLL_SECS=30

usage() {
  cat <<'EOF'
Uso: scripts/promote_to_beta.sh [--skip-local] [--wait-secs N]

  1) Ejecuta scripts/play_preflight.sh (salvo --skip-local)
  2) Exige que HEAD esté en origin/main
  3) Espera a que el workflow «Play gate» esté success para ese SHA
  4) git push origin HEAD:beta

Requiere: gh autenticado, red, JDK 17 / Android SDK para el preflight.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-local) SKIP_LOCAL=1; shift ;;
    --wait-secs) WAIT_SECS="${2:?}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opción desconocida: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "promote_to_beta: instala GitHub CLI (gh)" >&2
  exit 1
fi

SHA="$(git rev-parse HEAD)"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$SKIP_LOCAL" -eq 0 ]]; then
  echo "==> Preflight local"
  bash "$ROOT/scripts/play_preflight.sh"
else
  echo "==> Preflight local omitido (--skip-local)"
fi

echo "==> Comprobar que $SHA está en origin/main"
git fetch origin main --quiet
if ! git merge-base --is-ancestor "$SHA" origin/main; then
  echo "promote_to_beta: HEAD ($SHA) no está en origin/main." >&2
  echo "Haz push a main primero (y espera Play gate), luego vuelve a ejecutar." >&2
  exit 1
fi

echo "==> Esperar Play gate verde para $SHA (máx ${WAIT_SECS}s)"
deadline=$((SECONDS + WAIT_SECS))
conclusion=""
run_url=""

while (( SECONDS < deadline )); do
  export PLAY_GATE_JSON
  PLAY_GATE_JSON="$(
    gh run list --commit "$SHA" --workflow "Play gate" --limit 5 \
      --json databaseId,status,conclusion,url 2>/dev/null || echo "[]"
  )"
  state="$(
    python3 - <<'PY'
import json, os
runs = json.loads(os.environ.get("PLAY_GATE_JSON") or "[]")
run_count = len(runs)
pending = 0
conclusion = ""
url = ""
for run in runs:
    status = run.get("status") or ""
    conc = run.get("conclusion") or ""
    url = run.get("url") or url
    if status == "completed" and conc == "success":
        conclusion = "success"
        break
    if status == "completed" and conc and conc != "success":
        conclusion = conc
        break
    if status != "completed":
        pending = 1
print("%d|%d|%s|%s" % (run_count, pending, conclusion, url))
PY
  )"
  IFS='|' read -r run_count pending conclusion run_url <<<"$state"
  if [[ "$conclusion" == "success" ]]; then
    break
  fi
  if [[ -n "$conclusion" ]]; then
    echo "promote_to_beta: Play gate falló ($conclusion): $run_url" >&2
    exit 1
  fi
  if [[ "${run_count:-0}" -eq 0 ]]; then
    echo "  (aún no hay run Play gate para este SHA; esperando…)"
  elif [[ "${pending:-0}" -eq 1 ]]; then
    echo "  Play gate en curso… (${run_url:-})"
  fi
  sleep "$POLL_SECS"
done

if [[ "$conclusion" != "success" ]]; then
  echo "promote_to_beta: timeout esperando Play gate success para $SHA" >&2
  echo "Comprueba: gh run list --commit $SHA --workflow 'Play gate'" >&2
  exit 1
fi

echo "==> Play gate OK ($run_url)"
echo "==> Push $BRANCH ($SHA) → origin/beta"
git push origin "HEAD:beta"
echo "promote_to_beta OK — CI Play (emuladores + deploy) arrancará en beta."
