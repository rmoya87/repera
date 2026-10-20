#!/bin/bash
# Repera iOS - double-click simulator runner for macOS.
# Requires Xcode with iOS 27 SDK, XcodeGen, an available iPhone simulator and Python 3.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

pause_on_error() {
  status=$?
  if [[ "$status" -ne 0 ]]; then
    echo
    echo "No se ha podido ejecutar Repera en el simulador (salida $status)."
    echo "Revisa el error anterior. El proyecto no se ha enviado a main ni a TestFlight."
    read -r -p "Pulsa Intro para cerrar..." _ || true
  fi
}
trap pause_on_error EXIT

echo "Repera iOS · ejecución local en simulador"
echo "Esta ejecución NO despliega ni publica la aplicación."
echo

if [[ ! -f "$ROOT/project.yml" ]]; then
  echo "ERROR: project.yml no encontrado. Sitúa el lanzador en la raíz de Repera."
  exit 1
fi
if ! command -v xcodebuild >/dev/null 2>&1 || ! command -v xcrun >/dev/null 2>&1; then
  echo "ERROR: Instala Xcode para macOS y selecciónalo con xcode-select."
  exit 1
fi
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "ERROR: Falta XcodeGen. Puedes instalarlo con: brew install xcodegen"
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: Falta Python 3 para seleccionar el simulador."
  exit 1
fi
if ! xcodebuild -showsdks | grep -Eq 'iphonesimulator27([[:space:]]|\.|$)|iOS 27'; then
  echo "ERROR: No está disponible el SDK del simulador iOS 27. Actualiza Xcode."
  exit 1
fi

device_id="$(
  xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
found = []
for runtime, entries in devices.items():
    if ".iOS-27" not in runtime:
        continue
    for d in entries:
        if d.get("isAvailable", True) and d["name"].startswith("iPhone"):
            found.append(d)
if found:
    found.sort(key=lambda d: (d.get("state") == "Booted", "iPhone 17" in d["name"]), reverse=True)
    print(found[0]["udid"])
'
)"
if [[ -z "$device_id" ]]; then
  echo "ERROR: No hay simulador de iPhone con iOS 27 instalado."
  echo "Xcode → Settings → Platforms: instala el simulador iOS 27."
  exit 1
fi

echo "Generando proyecto Xcode..."
xcodegen generate --spec "$ROOT/project.yml"
python3 scripts/check_xcode_sources.py

echo "Abriendo el simulador..."
open -a Simulator
if [[ "$(xcrun simctl list devices booted -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(" ".join(x["udid"] for z in d["devices"].values() for x in z))')" != *"$device_id"* ]]; then
  xcrun simctl boot "$device_id"
fi
xcrun simctl bootstatus "$device_id" -b

derived_data="$HOME/Library/Developer/Xcode/DerivedData/ReperaLocal"
echo "Compilando Repera para el simulador (SDK iOS 27)..."
xcodebuild -project "$ROOT/Repera.xcodeproj" \
  -scheme Repera -configuration Debug \
  -destination "platform=iOS Simulator,id=$device_id" \
  -derivedDataPath "$derived_data" CODE_SIGNING_ALLOWED=NO build

app="$derived_data/Build/Products/Debug-iphonesimulator/Repera.app"
if [[ ! -d "$app" ]]; then
  echo "ERROR: No se ha generado Repera.app en $app"
  exit 1
fi
echo "Instalando Repera..."
xcrun simctl install "$device_id" "$app"
xcrun simctl launch "$device_id" com.app.repera

echo
echo "Repera iniciada en el simulador."
echo "La sesión Apple → Supabase y las reservas requieren usuarios vinculados y credenciales reales."
echo "Puedes cerrar esta ventana; Simulator seguirá abierto."
