#!/usr/bin/env bash
# Safe, optional local fast-forward before regenerating a gitignored Xcode project.
# Never stashes, resets, removes files, checks out another branch, or changes iCloud.
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
if [[ "${REPERA_SKIP_GIT_UPDATE:-0}" == "1" ]]; then
  echo "Actualización Git omitida (REPERA_SKIP_GIT_UPDATE=1)."
  exit 0
fi
if ! command -v git >/dev/null 2>&1 || ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Aviso: no es una copia Git; usaré los archivos Swift que ya tienes."
  exit 0
fi

branch="$(git -C "$ROOT" symbolic-ref -q --short HEAD || true)"
if [[ "$branch" != "main" ]]; then
  echo "Aviso: rama actual '$branch'. No cambio de rama ni mezclo cambios automáticamente."
  echo "Para instalar la última versión, cambia a main cuando hayas guardado tus cambios."
  exit 0
fi
if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
  echo "Aviso: hay cambios locales sin confirmar. No hago git pull para protegerlos."
  echo "Guárdalos en un commit antes de actualizar; sí puedo regenerar el proyecto actual."
  exit 0
fi
if ! git -C "$ROOT" remote get-url origin >/dev/null 2>&1; then
  echo "Aviso: origin no está configurado. No actualizaré el código."
  exit 0
fi
echo "Comprobando origin/main (solo avance rápido, sin sobrescribir cambios)..."
if ! git -C "$ROOT" fetch --quiet origin main; then
  echo "Aviso: sin conexión a GitHub. Continuaré con los archivos locales disponibles."
  exit 0
fi
if ! git -C "$ROOT" merge-base --is-ancestor HEAD FETCH_HEAD; then
  echo "Aviso: main local ha divergido de origin/main. No hago reset ni merge automático."
  exit 0
fi
git -C "$ROOT" merge --ff-only FETCH_HEAD >/dev/null
echo "Repera: checkout main actualizado (fast-forward)."
