# Gymbro Foundation Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans or implement task-by-task. Steps use checkbox syntax.

**Goal:** Scaffold Gymbro iPhone + Watch apps with Liquid Glass UI, shared domain session flow, and Supabase schema ready for multi-role.

**Architecture:** SwiftUI apps + local SPM `GymbroDomain`; Watch Connectivity for live session; Supabase migrations for profiles/routines/workouts with RLS.

**Tech Stack:** Xcode 27, iOS 26 / watchOS 26, SwiftUI Liquid Glass, XcodeGen, Supabase (Postgres + Auth), CoreMotion

## Global Constraints

- Deployment: iOS 26.0+, watchOS 26.0+
- UI: prefer system toolbars + `.glassEffect` / `GlassEffectContainer` for custom chrome
- No Capacitor / no openGym web UI in the binary
- RLS on every `public` table
- Roles in DB (`profiles.role`), never in editable `user_metadata` for authz
- Spanish UI copy for athlete-facing strings in v1

## File map

- `project.yml` — XcodeGen
- `Packages/GymbroDomain/**` — session + exercise models + rep counter protocol
- `Apps/Gymbro/**` — iPhone app
- `Apps/GymbroWatch/**` — Watch app
- `supabase/migrations/*` — schema
- `reference/openGym` — upstream reference only

---

### Task 1: Repo scaffold + domain package

- [ ] Domain models: `Exercise`, `WorkoutSession`, `WorkoutExercise`, `SetLog`
- [ ] `SessionController` state machine: idle → active → counting → advance
- [ ] Unit tests for advance / confirm / finish
- [ ] Generate Xcode project via XcodeGen

### Task 2: iPhone app shell (Liquid Glass)

- [ ] Tab navigation: Hoy / Plan / Historial / Ajustes
- [ ] Start demo session → push payload to Watch via `WCSession`
- [ ] Show live session status on phone

### Task 3: Watch companion

- [ ] Receive session; show current exercise
- [ ] Confirm start → motion rep counter + manual ±
- [ ] Confirm done → next exercise; send update to phone

### Task 4: Supabase foundation

- [ ] Migration: profiles + roles + exercises + routines + workouts + sets + RLS
- [ ] `.env.example` with Supabase URL/anon key placeholders
- [ ] README: how to create project and link

### Task 5: Smoke verify

- [ ] `xcodegen generate` + `xcodebuild` build iOS + Watch
- [ ] `swift test` for GymbroDomain
