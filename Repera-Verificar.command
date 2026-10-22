#!/bin/bash
# Repera developer preflight: repeatable checks without GitHub hosted Actions.
# Nothing here merges branches, pushes to GitHub or modifies Supabase.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 1
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG_DIR="${TMPDIR:-/tmp}/Repera-Preflight-$STAMP"
mkdir -p "$LOG_DIR"
PASSED=0
FAILED=0
SKIPPED=0
echo "Repera · Verificación local · $STAMP"
echo "Carpeta de registros: $LOG_DIR"
echo "No se modificará main, Supabase, IONOS ni TestFlight."
echo

run_check() {
  local name="$1"
  shift
  local file="$LOG_DIR/${name// /_}.log"
  echo "▶ $name"
  if "$@" >"$file" 2>&1; then
    echo "  OK  → $file"
    PASSED=$((PASSED+1))
  else
    local result=$?
    echo "  ERROR ($result) → $file"
    tail -n 18 "$file"
    FAILED=$((FAILED+1))
  fi
}

skip_check() {
  echo "  PENDIENTE: $1"
  SKIPPED=$((SKIPPED+1))
}

run_check "Sintaxis de lanzadores" bash -n Repera-Business.command Repera-iOS.command Repera-Xcode.command
if command -v node >/dev/null 2>&1; then
  run_check "Panel Business Node" bash -c 'cd "$1/web/console" && node --test tests/*.test.mjs' _ "$ROOT"
else
  skip_check "Node.js 20+ no instalado. No se pueden ejecutar tests de panel."
fi
if command -v python3 >/dev/null 2>&1; then
  run_check "Modernizacion iOS canvas" python3 docs/ios27-modernization/generate_canvas.py --check
  run_check "Validar herramienta Xcode Auth" python3 -m unittest discover -s tests -p test_xcode_sources.py -v
  run_check "Plist fuente complicacion Watch" python3 scripts/check_watch_widget_plist.py
  run_check "Tests metadatos complicacion Watch" python3 -m unittest discover -s tests -p test_watch_widget_plist.py -v
else
  skip_check "Python 3 no instalado. No se puede validar canvas."
fi
if command -v swift >/dev/null 2>&1; then
  run_check "ReperaDomain Swift" swift test --package-path Packages/ReperaDomain
  run_check "Contratos Business Swift" swift test --package-path mobile-contracts/swift
else
  skip_check "Swift no instalado. No se pueden ejecutar las pruebas de dominio/contratos."
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  if command -v xcodegen >/dev/null 2>&1 && command -v xcodebuild >/dev/null 2>&1; then
    if xcodebuild -showsdks 2>/dev/null | grep -Eq "iphonesimulator27|iOS 27"; then
      run_check "Generacion XcodeGen" xcodegen generate --spec "$ROOT/project.yml"
      run_check "Fuentes Auth en target iOS" python3 scripts/check_xcode_sources.py
      if [[ -f "$ROOT/Repera.xcodeproj/project.pbxproj" ]]; then
        run_check "Build iOS 27 Simulator" xcodebuild -project Repera.xcodeproj -scheme Repera -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
        run_check "Build watchOS 27 Simulator" xcodebuild -project Repera.xcodeproj -scheme ReperaWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO build
      else
        skip_check "XcodeGen no generó Repera.xcodeproj."
      fi
    else
      skip_check "No hay SDK iOS 27 instalado; actualiza Xcode e instala el simulador."
    fi
  else
    skip_check "Instala Xcode y XcodeGen para compilar iOS/watchOS."
  fi
else
  skip_check "iOS/watchOS requieren macOS y Xcode con SDK 27."
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Resultados: $PASSED correctos · $FAILED fallidos · $SKIPPED pendientes"
echo "Registros: $LOG_DIR"
echo "Las pruebas de Auth Apple, reservas multiusuario simultáneas, Stripe, IONOS"
echo "y TestFlight necesitan staging y credenciales reales; no se validan aquí."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
if [[ "$FAILED" -gt 0 || "$SKIPPED" -gt 0 ]]; then
  echo "ESTADO: NO APTO PARA FUSIÓN. Corrige errores y completa pruebas externas."
else
  echo "Tests locales finalizados. AÚN NO APTO: faltan pruebas externas y revisión final."
fi
if [[ -t 0 ]]; then read -r -p "Pulsa Intro para cerrar..." _ || true; fi
if [[ "$FAILED" -gt 0 || "$SKIPPED" -gt 0 ]]; then exit 1; fi
