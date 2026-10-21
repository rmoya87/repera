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

# Repera.xcodeproj no se versiona: antes de generarlo comprobamos la versión
# de main; únicamente actualizamos automáticamente si la copia Git está limpia.
bash "$ROOT/scripts/update_repera_checkout.sh" "$ROOT"

# AppleAuthStore.swift lives in Sources/Onboarding; the Python validator
# checks nested paths. These newer stores are direct children of Sources/.
for source in BusinessAuthStore.swift BusinessDataStore.swift BusinessWorkoutSyncStore.swift AITrainingInboxStore.swift AIAccessView.swift AITrainingContextStore.swift AITrainingProgramsView.swift; do
  if [[ ! -f "Apps/Repera/Sources/$source" ]]; then
    echo "ERROR: Falta $source en esta copia local de Repera."
    echo "Actualiza los archivos con: git pull origin main"
    echo "La regeneración de Xcode no puede crear código Swift que aún no has descargado."
    exit 1
  fi
done
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
echo "El target Repera incluye los archivos de autenticación, sincronización y las nuevas fuentes IA."
echo "Puedes compilar con ⌘B y ejecutar con ⌘R."
