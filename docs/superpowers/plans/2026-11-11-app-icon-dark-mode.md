# App Icon Dark Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline) or subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** En modo noche, el icono de inicio usa fondo `#000000` con la misma mascota en iPhone, Watch, Android y Wear.

**Architecture:** iOS/Watch: variante `luminosity=dark` en AppIcon. Android/Wear: `values-night` override de `ic_launcher_background`. Script stdlib regenera `AppIcon-Dark.png` desde el canónico.

**Tech Stack:** PNG stdlib Python, Asset Catalog appearances, Android resource night qualifiers.

## Global Constraints

- Fondo dark = `#000000` puro; claro = `#30D158` sin cambio.
- Misma mascota 3D; solo sustituir verde de fondo.
- Solo modo noche (no tinted, no splash, no favicon).
- Digests `AppIcon-Dark.png` iPhone ↔ Watch idénticos.

---

### Task 1: Contrato + script + assets Apple + night Android/Wear + docs

**Files:**
- Create: `scripts/generate_app_icon_dark.py`
- Create: `tests/test_app_icon_dark_mode_contract.py`
- Create: `Apps/Repera/.../AppIcon.appiconset/AppIcon-Dark.png`
- Create: `Apps/ReperaWatch/.../AppIcon.appiconset/AppIcon-Dark.png`
- Create: `android/mobile/src/main/res/values-night/colors.xml`
- Create: `android/wear/src/main/res/values-night/colors.xml`
- Modify: both `AppIcon.appiconset/Contents.json`
- Modify: `docs/ARCHITECTURE.md`, `docs/FEATURES.md` (fecha)

**Interfaces:**
- Produces: `generate_app_icon_dark.py` with `--check` / regenerate; contract asserts dark Contents.json + night colors.

- [x] **Step 1:** Write failing contract test
- [x] **Step 2:** Implement script, generate PNGs, update Contents.json, add values-night, update docs
- [x] **Step 3:** Run contract + regenerate `--check`
- [ ] **Step 4:** Commit when user asks (no auto-commit unless requested)

---
