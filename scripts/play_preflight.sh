#!/usr/bin/env bash
# Fuente única del gate Play (local + CI play-gate + android-native).
# Compilar la app NO basta: incluye suite JVM y compile de androidTest.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -z "${JAVA_HOME:-}" ]]; then
  if [[ -d /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ]]; then
    export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
  elif [[ -d /opt/homebrew/opt/openjdk@17 ]]; then
    export JAVA_HOME=/opt/homebrew/opt/openjdk@17
  fi
fi

if [[ -n "${JAVA_HOME:-}" ]]; then
  export PATH="$JAVA_HOME/bin:$PATH"
fi

if [[ "${PLAY_PREFLIGHT_USE_SYSTEM_GRADLE:-}" == "1" ]] || ! [[ -x "$ROOT/android/gradlew" ]]; then
  if ! command -v gradle >/dev/null 2>&1; then
    echo "play_preflight: hace falta gradle en PATH o android/gradlew" >&2
    exit 1
  fi
  GRADLE=(gradle -p "$ROOT/android")
else
  GRADLE=("$ROOT/android/gradlew" -p "$ROOT/android")
fi

echo "==> Play upload / publisher unit tests"
python3 -m unittest discover -s android/scripts -p 'test_*play*.py' -v

echo "==> Domain + Wear unit tests + debug assemble"
"${GRADLE[@]}" \
  :domain:testDebugUnitTest \
  :wear:testDebugUnitTest \
  :mobile:assembleDebug \
  :wear:assembleDebug \
  --no-daemon --stacktrace

echo "==> Mobile complete JVM unit suite"
"${GRADLE[@]}" :mobile:testDebugUnitTest --no-daemon --stacktrace

echo "==> Compile instrumented test sources (androidTest)"
"${GRADLE[@]}" \
  :mobile:compileDebugAndroidTestKotlin \
  :wear:compileDebugAndroidTestKotlin \
  --no-daemon --stacktrace

echo "play_preflight OK — no promover a beta hasta que «Play gate» esté verde en GitHub para este commit."
