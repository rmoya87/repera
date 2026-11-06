# Session detail ready + Watch/Wear start countdown — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline; user asked «hazlo»). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Teléfono: skeleton hasta resumen completo; relojes: overlay 3-2-1 con skip; Comenzar teléfono intacto.

**Architecture:** Gate `isDetailReady`/`detailReady` con prefetch Health+review+POI+clima antes del reveal; countdown como overlay en capa sesión (WatchSessionView / WearHubHome) diferiendo HK/HS hasta 0 o tap.

**Tech Stack:** SwiftUI iOS/watchOS 26, Compose Android/Wear, contratos Python.

## Global Constraints

- iOS 26+ / watchOS 26+; no bajar target.
- Comenzar teléfono: no modificar `beginStartCountdown` UI del botón.
- Watch: overlay fuera del hub; `Task.yield` antes de mutar hub; no confirmationDialog.
- Docs: FEATURES (+ ARCHITECTURE si aplica); fecha 2026-11-06.
- Timeout resumen ~2,5 s fail-open; skeleton inmediato.

---

### Task 1: Contratos Python (fail first)

**Files:**
- Create: `tests/test_session_detail_ready_contract.py`
- Modify: `tests/test_watch_workout_start_and_heart_rate_contract.py`
- Modify: `tests/test_home_history_performance_contract.py` (alinear con sleep 400 ms / skeleton)

- [x] Assert iOS `isDetailReady` / `SessionDetailSkeleton` / no `detailList` hasta ready
- [x] Assert Android `detailReady` / `SessionDetailSkeleton`
- [x] Assert Watch `WatchStartCountdownOverlay` + pending countdown antes de `playHubSport`/`startSelectedPlan`
- [x] Assert Wear countdown overlay + defer start
- [x] Run tests → implement → verdes

### Task 2–6: implementado

iOS skeleton + prefetch clima; Android gate + prefetch; Watch/Wear overlay 3-2-1; docs FEATURES + spec hub.

---

Self-review vs spec: resumen todo+timeout, countdown Watch/Wear skip, teléfono Comenzar fuera — cubierto.
