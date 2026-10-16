# Escáner de pizarra / TV

Última actualización: 2026-10-16

## Objetivo

Foto de pizarra o pantalla → texto OCR → **bloques de entreno** tipados (`RoutineBlock` + `WODMovement`) → revisión → guardar en un día o empezar sesión.

## Pipeline

```
UIImage
  → BoardTextRecognizer (Vision OCR)
  → BoardImportPipeline
       ├─ 1) BoardImportParser local; si ≥2 bloques con movimientos → **skip IA**
       ├─ 2) BoardAIImporter (Foundation Models) si hace falta y hay AI
       └─ 3) Fallback localRules
  → LoadSuggestion.applyPercentLoads (% → kg vía e1RM)
  → BoardImportReviewView
  → GymbroStore.saveBoardToDay / startSessionFromBoard
```

| Fuente | Cuándo | Coste |
|--------|--------|--------|
| `localRules` | Parser fuerte (≥2 bloques) o IA no disponible / fallo | Gratis siempre |
| `appleIntelligence` | Parser débil y `SystemLanguageModel` disponible | Gratis on-device |

La UI de revisión muestra qué fuente se usó.

## OCR (`BoardTextRecognizer`)

- Vision `VNRecognizeTextRequest` accurate, ES+EN.
- Lienzo: si la imagen es **oscura** (TV/pizarra negra con texto blanco) relleno **negro**; si no, blanco. Evita texto blanco sobre blanco.

## Parser local (`BoardImportParser`)

Reglas + glosario CrossFit (`CrossFitGlossary`).

Soporta entre otros:

- Secciones: Weightlifting / Metcon / Strength / … fusionadas con el formato siguiente.
- Formatos: EMOM, Every 90s For 12min, EVERY 2'×N, E2MOM, AMRAP, For Time (Nmin Cap), RFT, ladder, partner, tabata, chipper…
- Movimientos: reps, metros, cal, `#40/25kg`, `%` 1RM, `Sets 1-2:…`, complejos `+`, rest, Round N (nota).
- Multi-bloque en una sola captura.

Limitación: no es comprensión general; formatos muy raros dependen de la IA o de añadir patrones + tests.

## IA on-device (`BoardAIImporter`)

- Framework: `FoundationModels`.
- Guided generation (`@Generable` → `AIBoardPlan`).
- Si `availability != .available` → `nil` y el pipeline usa el parser.
- No hay LLM en la nube ni API keys.

## Entrada a la app

- **Crear** tab: `StartHubSheet`
- **Inicio** día +: `DayPlusSheet`

Ambos llaman `BoardImportPipeline.interpret`.

## Tests

```bash
cd Packages/GymbroDomain && swift test --filter BoardImportParserTests
```

Incluye caso Weightlifting + Metcon (Every 90s + For Time 20' Cap).

## Logs

`BoardScanLog` → Logger + print DEBUG (`[BoardScan]`).
