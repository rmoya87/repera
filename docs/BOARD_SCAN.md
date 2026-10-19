# Escáner de pizarra / TV

Última actualización: 2026-10-19 (lectura de pizarra en tres bloques, iOS 27)

## Objetivo

Foto de pizarra o pantalla → texto OCR → **secuencia de bloques** (fuerza + WOD de cualquier formato) → revisión alineada con el preview del día → editar / guardar / empezar → al apuntar, las series coinciden con el plan.

Entrada cámara/galería: modal `BoardScanSourceSheet`. Flujo anti-cuelgue:

1. JPEG reducido en MainActor (UIKit).
2. Vision off-main (**fast**, accurate si hace falta) con timeout 20s.
3. Tras OCR: **`BoardScanLiteParser`** síncrono (cabeceras EMOM/AMRAP + líneas). Sin `BoardImportParser` pesado, sin hilos, sin IA.
4. Galería: `PHPicker` en `fullScreenCover`. Sheet crece solo con «Leyendo…» / error.

Causa del cuelgue: `BoardImportParser` + concurrencia (GCD/Thread/semáforo) no reanudaban la continuation en dispositivo. El lite parser con la pizarra de prueba produce 3 bloques en <1 ms.

## Pipeline actual en la app

```
UIImage
  → BoardTextRecognizer (Vision OCR ES+EN)
  → BoardImportPipeline.interpretSync
  → BoardScanLiteParser (lineal: cabeceras → series/movimientos → catálogo)
  → BoardImportReviewView (editar/guardar/empezar)
```

La ruta activa **no** ejecuta `BoardImportParser.parseBlocks` ni Foundation Models: es intencional para evitar bloqueos observados en iPhone. `BoardImportParser` sigue disponible para reglas completas y tests de dominio, pero no se usa en el flujo de cámara.

Regresión del 19/10/2026: pizarra con tres bloques:
1. `EMOM 8’ @6-8`: 8 minutos, 2 High Hang Squat Snatch por estación; intensidad original conservada.
2. `EVERY 2’ X 4` + `4-3-3-2 BACK SQUAT @6-8`: **bloque de fuerza** con series 4, 3, 3 y 2; la cadencia y el RPE quedan en notas, nunca convertidos arbitrariamente en RIR.
3. `4 RFT (TC 12’)`: 4 rondas, cap 12 min, 6 Power Snatch 40/25, 8 BOB (Bar facing burpee), 10 Back Rack Reverse Lunges 40/25 y descanso de 60 s.

El catálogo resuelve abreviaturas en inglés y español. Una variante no encontrada no debe descartarse: se conserva como movimiento WOD editable. El emparejamiento local utiliza mapa indexado de nombres/canónicos, no comparación difusa por ejercicio; si se añaden nuevos alias, actualizarlos en `CrossFitGlossary`. En fuerza, se asigna `targetRir` **solo** cuando se identifica explícitamente `@RIR N`; `@6-8` no significa RIR y se mantiene como nota.

## OCR (`BoardTextRecognizer`)

- Vision `VNRecognizeTextRequest` accurate, ES+EN.
- Lienzo: si la imagen es **oscura** (TV/pizarra negra con texto blanco) relleno **negro**; si no, blanco. Evita texto blanco sobre blanco.

## Parser local (`BoardImportParser`)

Reglas + glosario CrossFit (`CrossFitGlossary`).

Soporta entre otros:

- Secciones: Weightlifting / Metcon / Strength / … fusionadas con el formato siguiente.
- El parser de dominio admite formatos adicionales (EMOM, E2MOM, AMRAP, RFT, ladder, etc.). El escáner activo usa un subconjunto tipado y seguro: EMOM, AMRAP, Every × N como fuerza, RFT/For Time y Tabata; formatos no detectados se conservan como movimientos de fuerza.
- Movimientos (`CrossFitGlossary.parseMovementLine`): `10 toes to bar` → reps=10 + Toes to bar; `200M RUN` / `200m cinta/carrera` → 200 m + Cinta/carrera; `5 DDB DEVIL PRESS 20/12,5` → reps + Devil press + nota «Doble mancuerna» + kg M/F.
- Equipo en nota (no en el nombre): DDB/SDB/DKB/SKB/DB/KB/BB (glosarios CrossFit habituales).
- El parser completo soporta además `%` 1RM, complejos `+`, Sets y demás reglas; no atribuir esas capacidades a la ruta lite sin pruebas de integración.
- Multi-bloque en una sola captura.
- **Ejercicios sueltos** (sin cabecera) → bloque de fuerza antes del siguiente WOD.
- **EMOM multi-estación:** si la cabecera no fija `rounds`, se deriva `vueltas = intervalos_reloj ÷ estaciones` (rest cuenta como estación). Ej. EMOM 12' + 3 estaciones → 4 vueltas. El reloj sigue usando el time cap (12 intervalos de 60s), no las vueltas.

Limitación: no es comprensión general; formatos muy raros dependen de la IA o de añadir patrones + tests.

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

Incluye EMOM 12' multi-estación → 4 rondas, fuerza+AMRAP, expansión de series en sesión.

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
