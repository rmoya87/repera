#!/bin/bash
# Open the current, generated Repera Xcode project; safe for existing iCloud data.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

on_exit() {
  status=$?
  if [[ "$status" -ne 0 ]]; then
    echo
    echo "No se ha podido preparar Xcode (salida $status). Revisa el error anterior."
    read -r -p "Pulsa Intro para cerrar..." _ || true
  fi
}
trap on_exit EXIT

echo "Repera · abrir Xcode con el proyecto actualizado"
echo "El archivo Repera.xcodeproj es generado y NO se guarda en GitHub."
echo "No se borran DerivedData, preferencias, simuladores, llaveros ni datos locales."
echo

if [[ ! -f "Apps/Repera/Sources/BusinessAuthStore.swift" ]]; then
  echo "ERROR: No existe BusinessAuthStore.swift en esta copia de Repera."
  echo "Actualiza el repositorio con: git pull origin main"
  exit 1
fi
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "ERROR: Falta XcodeGen. Instálalo con: brew install xcodegen"
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: Falta Python 3 para validar las fuentes del target."
  exit 1
fi

echo "Regenerando la pertenencia de archivos y paquetes en Xcode..."
# project.yml saves manual version changes before regeneration.
xcodegen generate --spec "$ROOT/project.yml"
python3 scripts/check_xcode_sources.py

echo "Abriendo Repera.xcodeproj en Xcode..."
open "$ROOT/Repera.xcodeproj"
echo "El target Repera ya incluye BusinessAuthStore.swift y BusinessDataStore.swift."
echo "Puedes compilar con ⌘B y ejecutar con ⌘R."
