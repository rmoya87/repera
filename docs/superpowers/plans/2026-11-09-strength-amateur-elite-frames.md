# Strength Amateur / Élite frames — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Let athletes pick Amateur (gym) vs Élite (competition) in Training settings; show one Rendimiento curve/Pxx for that frame; seed Amateur once from FitnessVolt gym tables (CC BY attributed on web); host aggregates in Supabase with delta sync like the exercise catalog; grow Amateur via anonymous opt-in contributions later.

**Architecture:** Extend `StrengthBenchmarkDistribution` with frame via `source` (`OpenPowerlifting` = Élite, `SymmetricStrength` / seed = Amateur). Bundle combined JSON for offline bootstrap. Supabase tables + RPCs mirror catalog revision/cursor (migration checked in; **no remote apply without human**). Settings field `strengthReferenceFrame` syncs in AppSettings / TrainingSettings.

**Tech stack:** Swift ReperaDomain + SwiftUI, Kotlin domain/mobile, Python seed script, Supabase SQL migration, existing strength_benchmarks assets.

## Decisions locked

- UI labels: **Amateur / Élite** (default Amateur).
- One campana + Pxx; never blend.
- One-time FV download only; attribution already on `/privacy` + `/terms`.
- No runtime FV API.
- Supabase delta for updates; contribution opt-in (default off until implemented).

## File map

- `scripts/import_fitnessvolt_gym_seed.py` — one-shot import → amateur rows
- `Apps/Repera/Resources/strength_benchmarks.json` + Android assets — combined
- `Packages/ReperaDomain/.../StrengthBenchmarkEngine.swift` (+ Kotlin) — filter by frame
- `Models.swift` / `TrainingSettings.kt` — `strengthReferenceFrame`
- Settings + StrengthBenchmarkVisual iOS/Android
- `supabase/migrations/YYYYMMDDHHMMSS_strength_benchmark_frames.sql` — schema only
- Docs + `tests/test_strength_visual_contract.py`

## Tasks

### Task 1: Seed script + JSON merge

Import FV gym percentiles for squat/bench/deadlift × sex into Repera distribution shape (weight classes → bodyWeightMin/Max, age 14–100, equipment raw, source SymmetricStrength). Merge with existing OpenPowerlifting rows. Copy to iOS + Android assets. Unit-test importer with fixture.

### Task 2: Domain frame

Add `StrengthReferenceFrame` amateur/elite. Engine `compare…` takes frame (or filters source). Kotlin parity + tests.

### Task 3: Settings + UI

Picker Amateur/Élite in Training settings (default amateur). Rendimiento loads distributions and uses selected frame; empty state if cohort thin.

### Task 4: Supabase migration (local file only)

Tables for distributions + revision/events; bootstrap/delta RPCs sketched; contribution stub. **Do not apply/deploy without confirmation.**

### Task 5: Docs/contracts

Update ATHLETE/FEATURES/ARCHITECTURE; contracts for frame labels and dual sources.
