# Repera web static redesign — Implementation Plan

> **For agentic workers:** Execute task-by-task. Spec: `docs/superpowers/specs/2026-11-08-repera-web-static-redesign-design.md`.

**Goal:** Port maqueta look/storytelling to static `web/` with SEO, App Store CTA, casos generator; no ejercicios.

**Architecture:** Hand-authored product HTML + `build_site.py` for `casos/{slug}.html` + sitemap; shared `site.css`/`site.js`; IONOS pack.

**Tech Stack:** HTML, CSS, vanilla JS, Python 3, Apache `.htaccess`.

## Global Constraints

- App Store URL: `https://apps.apple.com/es/app/repera-tu-diario-de-entreno/id6824523509`
- No `/ejercicios`; no inventar email soporte; system fonts; Spanish UI copy.
- Update docs after behavior change.

---

### Task 1: Content + generator
### Task 2: CSS + shared chrome
### Task 3: Product pages
### Task 4: Legales + FAQ skin + App Store
### Task 5: htaccess, pack, docs
### Task 6: Build verify
