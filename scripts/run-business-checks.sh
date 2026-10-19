#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
printf '\n== Web/Business domain/SQL contract tests ==\n'
(cd "$ROOT/web/console" && node --test tests/*.test.mjs)
if command -v swift >/dev/null 2>&1; then
  printf '\n== Swift native agenda contracts ==\n'
  (cd "$ROOT/mobile-contracts/swift" && swift test)
else
  echo 'Swift no disponible (sólo se ejecuta en Mac/Linux con toolchain Swift)'
fi
if command -v kotlinc >/dev/null 2>&1 && command -v java >/dev/null 2>&1; then
  printf '\n== Kotlin native agenda contracts ==\n'
  jarfile="$(mktemp --suffix=.jar)";trap 'rm -f "$jarfile"' EXIT
  kotlinc "$ROOT/mobile-contracts/android/src/main/kotlin/dev/repera/contracts/BusinessAgenda.kt" \
          "$ROOT/mobile-contracts/android/src/test/kotlin/dev/repera/contracts/BusinessAgendaSmoke.kt" -include-runtime -d "$jarfile"
  java -jar "$jarfile"
else
  echo 'Kotlin/JDK no disponibles (test opcional hasta incorporar Android/Gradle)'
fi
