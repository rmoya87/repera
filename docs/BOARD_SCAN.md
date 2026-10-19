# Escáner de pizarra / TV

Última actualización: 2026-10-19 (bundle `com.app.repera`)

## Objetivo

Foto de pizarra o pantalla → texto OCR → **secuencia de bloques** (fuerza + WOD de cualquier formato) → revisión alineada con el preview del día → editar / guardar / empezar → al apuntar, las series coinciden con el plan.

Entrada cámara/galería: modal `BoardScanSourceSheet`. Flujo anti-cuelgue:

1. JPEG reducido en MainActor (UIKit).
2. Vision off-main (**fast**, accurate si hace falta) con timeout 20s.
3. Tras OCR: **`BoardScanLiteParser`** síncrono (cabeceras EMOM/AMRAP + líneas). Sin `BoardImportParser` pesado, sin hilos, sin IA.
4. Galería: `PHPicker` en `fullScreenCover`. Sheet crece solo con «Leyendo…» / error.

Causa del cuelgue: `BoardImportParser` + concurrencia (GCD/Thread/semáforo) no reanudaban la continuation en dispositivo. El lite parser con la pizarra de prueba produce 3 bloques en <1 ms.

## Pipeline

```
UIImage
  → BoardTextRecognizer (Vision OCR)
  → BoardImportPipeline
       └─ BoardScanLiteParser local, síncrono (ruta activa de cámara/galería; sin IA)
  → LoadSuggestion.applyPercentLoads (% → kg vía e1RM)
  → deriveEmomRoundsIfNeeded (EMOM/circuito)
  → BoardImportReviewView (cards + thumbs = SessionPreview)
  → Editar (DayEditorView sobre draft) opcional
  → ReperaStore.saveBoardToDay / startSessionFromBoard
  → SessionController.from → plannedSets por formato
```

| Fuente | Cuándo | Coste |
|--------|--------|--------|
| `localRules` | Parser fuerte (≥2 bloques) o IA no disponible / fallo | Gratis siempre |
| `appleIntelligence` | Parser débil y `SystemLanguageModel` disponible | Gratis on-device |

La fuente queda en el log (`interpret.done`); la UI de revisión solo muestra los bloques.

## OCR (`BoardTextRecognizer`)

- Vision `VNRecognizeTextRequest` accurate, ES+EN.
- Lienzo: si la imagen es **oscura** (TV/pizarra negra con texto blanco) relleno **negro**; si no, blanco. Evita texto blanco sobre blanco.

## Parser local (`BoardImportParser`)

Reglas + glosario CrossFit (`CrossFitGlossary`).

Soporta entre otros:

- Secciones: Weightlifting / Metcon / Strength / … fusionadas con el formato siguiente.
- Formatos: EMOM, Every 90s For 12min, EVERY 2'×N, E2MOM, AMRAP, For Time (Nmin Cap), RFT, ladder, partner, tabata, chipper…
- Movimientos (`CrossFitGlossary.parseMovementLine`): `10 toes to bar` → reps=10 + Toes to bar; `200M RUN` / `200m cinta/carrera` → 200 m + Cinta/carrera; `5 DDB DEVIL PRESS 20/12,5` → reps + Devil press + nota «Doble mancuerna» + kg M/F.
- Equipo en nota (no en el nombre): DDB/SDB/DKB/SKB/DB/KB/BB (glosarios CrossFit habituales).
- También: cal, `#40/25kg`, `%` 1RM, `Sets 1-2:…`, complejos `+`, rest, Round N.
- Multi-bloque en una sola captura.
- **Ejercicios sueltos** (sin cabecera) → bloque de fuerza antes del siguiente WOD.
- **EMOM multi-estación:** si la cabecera no fija `rounds`, se deriva `vueltas = intervalos_reloj ÷ estaciones` (rest cuenta como estación). Ej. EMOM 12' + 3 estaciones → 4 vueltas. El reloj sigue usando el time cap (12 intervalos de 60s), no las vueltas.

Limitación: no es comprensión general; formatos muy raros dependen de la IA o de añadir patrones + tests.

## Regresión WOD 19/10/2026

Ejemplo real para comprobar OCR y parsing:

```text
EMOM 8' @6-8
2 HIGH HSQ SNATCH

EVERY 2' X 4
4-3-3-2 BACK SQUAT @6-8

4 RFT (TC 12')
6 POWER SNATCH 40/25
8 BOB
10 BACK RACK R. LUNGES 40/25
1' REST
```

- Bloque 1: EMOM de 8 min, arranca desde hang alto; el esfuerzo de cabecera se conserva en el texto original.
- Bloque 2: fuerza (4 series, 4-3-3-2 reps) con intervalo 120 s; @6-8 es RPE, se conserva la prescripción y el objetivo editable es RIR 3 (punto medio).
- Bloque 3: 4 RFT, límite 12 min, 6 power snatch 40/25, 8 burpees sobre barra, 10 zancadas inversas con barra en espalda 40/25 y descanso 60 s.
- El bloque EVERY con un único movimiento escalonado pasa a `.strength` si se ha podido emparejar el ID del ejercicio. Los EVERY multiestación siguen como `.emom`.
- El glosario distingue back rack reverse lunge de front rack lunge. La búsqueda permite ES/EN y abreviaturas; si falta un ID, conservar el nombre sin inventarlo.

## Series al apuntar (`RoutineBlock.plannedSets(for:)`)

| Formato | Series por movimiento |
|--------|----------------------|
| EMOM / circuito | Ola `4-3-3-2` = esas series; si la ola tiene **menos** números que `rounds`, se completa con el **último** (`4-3-3` → `4-3-3-3`); rango `5-10` / `6-8` = techo × `rounds` |
| EVERY N'×M / Tabata / RFT / RFQ | N = `rounds` |
| Ladder | Wave (21-15-9…) |
| Chipper / AFAP / Buy-in | 1 set |
| AMRAP / Partner / Death By / Max | 1 set base (editable) |
| Fuerza | `plannedSets` del ejercicio |

Editar movimiento WOD (`WODMovementEditor`): mismas series derivadas que Apuntar/Empezar; se pueden añadir/quitar.

## Revisión UI

- Tras escanear desde el sheet **Añadir entreno** (Inicio → +), se cierra el modal y se abre una **página** en el `NavigationStack` de Inicio: título **«Añadir entreno»** (`BoardImportReviewView` + `ogPinnedTransparentNav`).
- Desde la pestaña Crear (`StartHubSheet`) el push es en el mismo stack (también página, no sheet).
- `OGRoutineBlockCard` / `OGRoutineBlocksList`: mismas cards con miniaturas que `SessionPreviewView` (tocar card → editor). Nombres OCR/WOD se resuelven con `CrossFitGlossary.resolveCatalogName` → catálogo/`ExerciseArt`.
- Equipo (`DB`/`DDB`/`KB`/`BB` → notes): `preferEquipmentVariant` elige el ejercicio de catálogo (p. ej. thruster→Thruster mancuernas, snatch→Snatch mancuerna/kettlebell, clean→Clean mancuerna, press banca→Press mancuernas). 1 vs 2 mancuernas queda en la nota; Guardar/Empezar **no** re-parsean con `BoardImportParser` si el draft ya trae bloques (evita freeze).
- Toolbar: **Guardar** (`checkmark`, tint neutro) y **Empezar** (`play.fill`, accent); sin botón Editar.
- Guardar / Empezar usan los bloques del draft (incl. rondas derivadas).

## IA on-device (`BoardAIImporter`)

- Framework: `FoundationModels`.
- Guided generation (`@Generable` → `AIBoardPlan`).
- Si `availability != .available` → `nil` y el pipeline usa el parser.
- Tras convertir, `deriveEmomRoundsIfNeeded`.
- No hay LLM en la nube ni API keys.

## Cuota freemium

- **Gratis:** 4 escaneos correctos/mes (periodo UTC). Se consume al abrir revisión usable; cancelación/OCR vacío no cuentan.
- **Pro:** ilimitados. Contadores en `free_usage.json` (no en `app_state`). Ver [MONETIZATION.md](MONETIZATION.md).

## Entrada a la app

- **Crear** tab: `StartHubSheet`
- **Inicio** día +: `DayPlusSheet`

Ambos llaman `BoardImportPipeline.interpret`.

## Tests

```bash
cd Packages/ReperaDomain && swift test --filter BoardImportParserTests
cd Packages/ReperaDomain && swift test --filter SessionControllerTests
```

Incluye EMOM 12' multi-estación → 4 rondas, fuerza+AMRAP, expansión de series en sesión y prueba de regresión del WOD de octubre. La ruta activa es `BoardScanLiteParser`; hace falta además prueba manual con la captura original.

## Logs

`BoardScanLog` → **siempre** `print` + `Logger` (subsystem `com.app.repera`, category `BoardScan`) + archivo `Documents/BoardScan.log` en el contenedor de la app.

En Xcode: filtro `[BoardScan]`. Cada pasada tiene un id corto y tiempos `+Nms · ΣTotalms`:

```
▶ PASS a1b2c3d4 START · DayPlus
• photos.load …
• jpeg.prep …
• vision.fast … lines=N
• ocr.text …
• pipeline / local.blocks / ai.availability …
• interpret.done source=…
◀ PASS a1b2c3d4 OK · total=…
```

Si se queda en «Leyendo…», la última línea `•` indica la fase colgada (p. ej. `vision`, `ai.respond`).

Para sacar el log del iPhone: Xcode → Devices → Repera → Download Container → `AppData/Documents/BoardScan.log`, o:

```bash
xcrun devicectl device info files --device <udid> \
  --domain-type appDataContainer --domain-identifier com.app.repera \
  --subdirectory Documents
```
