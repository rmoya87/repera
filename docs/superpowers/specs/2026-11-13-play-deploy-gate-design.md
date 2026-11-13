# Play deploy gate (opción B) — diseño

Última actualización: 2026-11-13.

## Problema

«Compila en local» no equivale al gate de Play. Fallos típicos (suite JVM
completa, `compileDebugAndroidTestKotlin`) solo aparecen tras `push` a
`origin/beta`, provocando ciclos fix → push → CI rojo.

## Decisión

Opción **B**: preflight local + gate CI duro en `main`. Los emuladores
siguen solo en `android-native-ci.yml` / `deploy-internal-beta` (no en el
preflight).

## Piezas

1. **`scripts/play_preflight.sh`** — fuente única de tareas:
   - tests Python de upload Play (`android/scripts/test_*play*.py`)
   - `:domain:testDebugUnitTest` `:wear:testDebugUnitTest`
   - `:mobile:assembleDebug` `:wear:assembleDebug`
   - `:mobile:testDebugUnitTest`
   - `:mobile:compileDebugAndroidTestKotlin`
     `:wear:compileDebugAndroidTestKotlin`
2. **`.github/workflows/play-gate.yml`** — en push a `main` (paths
   `android/**` + scripts/workflow del gate) y `workflow_dispatch`; ejecuta
   el mismo script tras JDK 17 / SDK / Gradle 9.6.
3. **`scripts/promote_to_beta.sh`** — no hace `git push …:beta` hasta:
   - preflight local OK (salvo `--skip-local`)
   - `HEAD` existe en `origin/main`
   - run `Play gate` para ese SHA = `success` (`gh`)
4. **Docs** — `AGENTS.md`, `docs/ARCHITECTURE.md`, `android/README.md`:
   prohibir `git push origin main:beta` a ciegas; usar promote.

## Fuera de alcance

- Emuladores / instrumented en el gate (opción C).
- Arreglar contratos iOS rojos ajenos a Play.

## Éxito

Ningún AAB de Play sale de un commit que no haya pasado preflight local +
`Play gate` verde en GitHub antes de actualizar `beta`.
