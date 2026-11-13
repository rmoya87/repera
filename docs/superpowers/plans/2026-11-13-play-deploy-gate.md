# Play deploy gate Implementation Plan

> **For agentic workers:** Implement task-by-task. Steps use checkbox syntax.

**Goal:** Local preflight + CI `Play gate` on main + `promote_to_beta.sh` so beta/Play never starts from an unvalidated commit.

**Architecture:** One shell script is the source of truth for Gradle/Python checks; GitHub Actions and promote both call it / require its CI twin.

**Tech Stack:** bash, Gradle 9.6, JDK 17, `gh`, unittest contracts.

## Global Constraints

- Target: mirror `android-native` JVM path + androidTest compile; no emulators in gate.
- `android-native-ci.yml` stays beta-only for push/deploy.
- Spanish user docs; English identifiers.

---

### Task 1: Script + workflow + promote + contract

**Files:**
- Create: `scripts/play_preflight.sh`
- Create: `scripts/promote_to_beta.sh`
- Create: `.github/workflows/play-gate.yml`
- Create: `tests/test_play_deploy_gate_contract.py`
- Modify: `AGENTS.md`, `docs/ARCHITECTURE.md`, `android/README.md`

- [ ] Implement files and contract
- [ ] Run contract unittest
- [ ] Commit
