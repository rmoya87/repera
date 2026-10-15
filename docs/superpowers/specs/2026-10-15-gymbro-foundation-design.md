# Gymbro — Design (v1.0 local)

**Date:** 2026-10-15  
**Status:** Implemented — local product closed

## Product

Native iPhone + Apple Watch training app. openGym is a **domain/product reference** only.

| Layer | Choice |
|-------|--------|
| UI | SwiftUI Liquid Glass (iOS 26+) |
| Watch | Session companion (confirm → count → next) |
| Data | On-device JSON + iCloud Documents |
| Coach | Local rule engine (no LLM/network) |
| Backend cloud | Deferred (Supabase/Android later) |

## Feature set (v1.0)

- Weekly plan, library, workout logging
- Progression: off / linear / double / Greyskull / triple
- Supersets, plate math, warm-up / drop / rest-pause, RIR/RPE
- Stats, muscle fatigue map, body weight, history
- Import Strong/Hevy CSV, export/import JSON
- iCloud restore after reinstall

## Explicit non-goals (v1.0)

- Android client
- Supabase / social multi-user backend
- LLM AI coach
