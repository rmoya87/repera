# Escáner de pizarra — híbrido con score + IA on-device

**Fecha:** 2026-11-04 · **Estado:** aprobado para implementación

## Objetivo

Mejorar lectura de pizarras versátiles (estructura + vocabulario) sin LLM cloud, **sin cobro Pro** por la capa lista, y sin reintroducir cuelgues.

## Pipeline

```
OCR → BoardScanLiteParser
    → BoardScanConfidence (0…1 + razones)
    → si score < 0,85: BoardScanLocalRepair + re-score
    → si Foundation Models disponible: SIEMPRE BoardAIImporter (timeout 3–5 s)
         · OK → bloques IA + enrich catálogo (source=appleIntelligence)
         · fail/timeout → mejor local (source=localRules)
    → revisión editable
```

## Umbrales

| Score | Acción |
|-------|--------|
| ≥ 0,85 | Sin LocalRepair |
| < 0,85 | LocalRepair + re-score |
| FM disponible | Siempre intentar IA tras el paso local |
| Sin FM | Solo local (+ repair si aplica) |

## LocalRepair

Síncrono, budget ~50 ms. Extra normalización OCR + re-parse lite; conservar el resultado con mejor score. No `BoardImportParser` completo ni hilos.

## IA

`BoardAIImporter` (Foundation Models). Timeout duro. Gratis. Sin API keys cloud.

## Android

Mismo lite + score + LocalRepair. Sin FM Apple (excepción documentada).

## Tests / logs

Score unitario, repair, pipeline con/sin FM mock, timeout. `BoardScanLog` sin OCR/nombres en release.

## Fuera de alcance

LLM cloud, IA de pago, parser pesado en hot path, cambio de cuota freemium.
