# Escáner de pizarra / TV

Última actualización: 2026-11-13 (Lite: RFT+TC conserva rondas; MAX CAL/MAX ROUNDS no roban cabeceras; BUY-IN y N ROUNDS OF abren formato; WARM UP descrito = fuerza)

## Objetivo

Foto de pizarra o pantalla → texto OCR → **secuencia de bloques** (fuerza + WOD de cualquier formato) → revisión alineada con el preview del día → editar / guardar / empezar → al apuntar, las series coinciden con el plan.

Entrada cámara/galería: modal `BoardScanSourceSheet`. Flujo anti-cuelgue:

1. JPEG reducido en MainActor (UIKit).
2. Vision off-main (**fast**, accurate si hace falta) con timeout 20s.
3. Tras OCR: **`BoardScanLocalPipeline`** (lite → score → LocalRepair si score &lt; 0,85).
4. Si **Foundation Models** está disponible: **siempre** `BoardAIImporter` con timeout duro 4 s; si falla/timeout → mejor resultado local. Sin FM → solo local. **Gratis** (no es feature Pro).
5. Galería: `PHPicker` en `fullScreenCover`. Sheet crece solo con «Leyendo…» / error.

Causa del cuelgue histórico: `BoardImportParser` + concurrencia (GCD/Thread/semáforo) no reanudaban la continuation. El parser pesado **sigue fuera** del hot path. La IA vuelve con timeout cancelable.

## Pipeline actual en la app

```
UIImage
  → BoardTextRecognizer (Vision OCR ES+EN)
  → BoardImportPipeline.interpret (async)
       → BoardScanLiteParser
       → BoardScanConfidence (0…1)
       → BoardScanLocalRepair si score < 0,85
       → BoardAIImporter si FM disponible (timeout 4s)
  → BoardImportReviewView (editar/guardar/empezar)
```

`BoardImportParser` sigue disponible para reglas completas y tests de dominio, pero no se usa en el flujo de cámara. Android: mismo lite + score + LocalRepair; sin Foundation Models Apple (excepción documentada).

Regresión del 19/10/2026: pizarra con tres bloques:
1. `EMOM 8’ @6-8`: 8 minutos, 2 High Hang Squat Snatch por estación; intensidad original conservada.
2. `EVERY 2’ X 4` + `4-3-3-2 BACK SQUAT @6-8`: **bloque de fuerza** con series 4, 3, 3 y 2; la cadencia y el RPE quedan en notas, nunca convertidos arbitrariamente en RIR.
3. `4 RFT (TC 12’)`: 4 rondas, cap 12 min, 6 Power Snatch 40/25, 8 BOB (**Bar facing burpee** / burpee over the bar), 10 Back Rack Reverse Lunges 40/25 y descanso de 60 s. Si OCR pega `4RFf` o `8BOB`, sigue siendo cabecera RFT + movimiento BOB (no un «Movimiento» suelto dentro del EVERY).

El parser reconoce `C&J` como *Clean and Jerk* (incluida la variante con DB) antes de aplicar equivalencias parciales de `clean`; esto evita confundir la cargada con el compuesto de cargada y envión.\n\nLos nombres de los movimientos se enlazan con las fichas de catálogo usando sus identidades canónicas EN (`SportExerciseNames.canonicalName`), pero siguen mostrando sus alias ES en la UI. Así, `HIGH HSQ SNATCH`, `BACK RACK R. LUNGES`, `ALT DB HANG C&J` y `KB Goblet Alt Box Step Up` no deben perder el UUID por usar vocabulario de pizarra o confundirse con sentadilla goblet.

El catálogo resuelve abreviaturas en inglés y español vía `CrossFitGlossary.canonicalName` (y, si falta en el glosario, la misma tabla EN↔catálogo que `ExerciseSearch`). Así `chin up`, `walking lunge`, `ring pull-up`, etc. caen en la ficha concreta. Una variante no encontrada no debe descartarse: se conserva como movimiento WOD editable. El emparejamiento local utiliza mapa indexado de nombres/canónicos, no comparación difusa por ejercicio; si se añaden nuevos alias, actualizarlos en `CrossFitGlossary` y/o `ExerciseSearch.bilingualPhrases`. En fuerza, se asigna `targetRir` **solo** cuando se identifica explícitamente `@RIR N`; `@6-8` no significa RIR y se mantiene como nota.

## OCR (`BoardTextRecognizer`)

- Vision `VNRecognizeTextRequest` accurate, ES+EN.
- Lienzo: si la imagen es **oscura** (TV/pizarra negra con texto blanco) relleno **negro**; si no, blanco. Evita texto blanco sobre blanco.

## Parser local (`BoardImportParser`)

Reglas + glosario CrossFit (`CrossFitGlossary`).

Soporta entre otros:

- Secciones: Weightlifting / Metcon / Strength / … fusionadas con el formato siguiente.
- El parser de dominio admite formatos adicionales (EMOM, E2MOM, AMRAP, RFT, ladder, etc.). El escáner activo usa un subconjunto tipado y seguro: EMOM, AMRAP, Every × N como fuerza si contiene un solo movimiento, o intervalo EMOM si agrupa varios, RFT/For Time y Tabata; formatos no detectados se conservan como movimientos de fuerza.
- Movimientos (`CrossFitGlossary.parseMovementLine`): `10 toes to bar` → reps=10 + Toes to bar; `200M RUN` / `200m cinta/carrera` → 200 m + Cinta/carrera; `5 DDB DEVIL PRESS 20/12,5` → reps + Devil press + nota «Doble mancuerna» + kg M/F.
- Equipo en nota (no en el nombre): DDB/SDB/DKB/SKB/DB/KB/BB (glosarios CrossFit habituales).
- El parser completo soporta además `%` 1RM, complejos `+`, Sets y demás reglas; no atribuir esas capacidades a la ruta lite sin pruebas de integración.
- Multi-bloque en una sola captura.
- **Ejercicios sueltos** (sin cabecera) → bloque de fuerza antes del siguiente WOD.
- **EMOM multi-estación:** si la cabecera no fija `rounds`, se deriva `vueltas = intervalos_reloj ÷ estaciones` (rest cuenta como estación). Ej. EMOM 12' + 3 estaciones → 4 vueltas. El reloj sigue usando el time cap (12 intervalos de 60s), no las vueltas.

Limitación: no es comprensión general; formatos muy raros dependen de la IA o de añadir patrones + tests.

### Lite — invariantes 13/11/2026 (Android + iOS)

- `4 RFT (TC 12')` / `3 RFT (TC 9')`: el match de `TC` nombrado **no** debe ganar antes del handler RFT (si no, `rounds` queda `null`).
- Pareja ejercicio + `Max (n) reps` = max effort; **no** ante `MAX CAL …` ni `MAX ROUNDS OF …` (no robar `AMRAP` / buy-in).
- Cabeceras exactas `BUY-IN` / `N ROUNDS OF` abren formato aunque también figuren como ruido no-ejercicio.
- `WARM UP SHOULDERS` (y similares) son cabecera de fuerza; no section label que deje solo `SHOULDERS`.
- `1mn Rest between AMRAPs` → normalizar `MN`→`MIN` antes de leer el descanso entre rondas.
- Contrato JVM: `BoardScanLiteParserTest` / `BoardScanGlobalFixturesTest` en `:domain:testDebugUnitTest`.

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

## Score y LocalRepair

- `BoardScanConfidence`: señales de estructura débil, match de catálogo bajo, ruido OCR, `EVERY` ambiguo, etc.
- Umbral repair: **&lt; 0,85**. Con FM, la IA se intenta **siempre** tras el paso local (también con score alto).
- `BoardScanLocalRepair`: normalización extra (typos Jerk, GTOH, C2B, E2MOM, CAL/metros…) + re-parse lite; se conserva el mejor score.

## IA on-device (`BoardAIImporter`)

- Framework: `FoundationModels`.
- Guided generation (`@Generable` → `AIBoardPlan`).
- Si `availability != .available` → se omite; el pipeline entrega local (+ repair).
- Si disponible → **siempre** se llama tras el local; timeout **4 s**; enrich catálogo con `BoardScanLiteParser.enrichBlocks`.
- Tras convertir, `deriveEmomRoundsIfNeeded`.
- No hay LLM en la nube ni API keys. La capa lista **no** está detrás de Pro.

## Cuota freemium

- **Gratis:** 4 escaneos correctos/mes (periodo UTC). Se consume al abrir revisión usable; cancelación/OCR vacío no cuentan.
- **Pro:** ilimitados. Contadores en `free_usage.json` (no en `app_state`). Ver [MONETIZATION.md](MONETIZATION.md).

## Entrada a la app

- **Crear** tab: `StartHubSheet`
- **Inicio** día +: `DayPlusSheet`

Ambos llaman `await BoardImportPipeline.interpret` (local + IA si hay FM).

## Tests

```bash
cd Packages/ReperaDomain && swift test --filter BoardImportParserTests
cd Packages/ReperaDomain && swift test --filter SessionControllerTests
```

Incluye EMOM 12' multi-estación → 4 rondas, fuerza+AMRAP, expansión de series en sesión y prueba de regresión del WOD de octubre. Dominio: `BoardScanConfidenceTests` + lite. La ruta de cámara usa el híbrido; hace falta prueba manual con FM disponible y sin FM.

## Logs

`BoardScanLog` → `Logger` (subsystem `com.app.repera`, category `BoardScan`) + archivo `Documents/BoardScan.log` en el contenedor de la app.

- **DEBUG:** además `print` en la consola de Xcode, las primeras 20 líneas de OCR y el detalle por bloque/movimiento (nivel debug).
- **Release:** solo pasos, tiempos y recuentos (`chars=`, `lines=`, `blocks=`…). El texto OCR y los nombres de movimientos no se imprimen ni se escriben en el archivo; el mensaje en el log unificado es `privacy: .private` (visible con Xcode conectado, redactado en Consola).

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

La variante OCR `20 / 16 CAL*` con espacios a ambos lados de la barra también debe leerse como calorías Air Bike por sexo, no como dos movimientos alternativos. El parser completo y el ligero dejan `rounds=nil` en For Time sin prefijo N RFT.


## Regresiones de pizarras reales (12/11/2026)

Las pruebas BoardScanGlobalFixturesTests.swift y BoardScanGlobalFixturesTest.kt reproducen
transcripciones del OCR de pizarras aportadas por usuarios, incluyendo:

- **Warm up** con rondas, línea suelta «OF», **Tabata** por intervalos odd/even,
  AMRAP, RFT, For Time, EMOM y Every por segundos/minutos.
- **Cabeceras y notas**: WODSITO/TC, Accessory Work, «Max (n) rep(s)»,
  «FIND 5 RM», series «Sets 1-2», rondas escritas en línea independiente,
  descansos entre AMRAP y «I Go You Go» como contexto del bloque.
- **Esquemas** de repeticiones «10-9-...-1» y «1-2-...-10» ligados al
  movimiento siguiente; se conserva la carga y se evita inventar un ejercicio
  para la línea de repeticiones.
- **Vídeos, enlaces y anotaciones** excluidos del listado de movimientos; el
  texto original se mantiene en las notas del bloque para revisión.
- **Variantes de material**: DDB PUSH PRESS debe vincular la ficha
  Dumbbell Push Press y no un push press con barra.
- **Distancias por sexo**: Buy in... 400/320m Row conserva los 400 m y
  anota 320 m en la variante femenina, sin interpretarlos como pesos.

El conjunto es una **regresión de interpretación de transcripciones**:
no sustituye pruebas de Vision/ML Kit en dispositivos reales ni garantiza
reconocimiento perfecto de cualquier imagen o escritura. La foto no se envía
a Supabase; el catálogo editorial sí continúa actualizándose remotamente.
Las variantes de máquina genérica («10/8 CAL») siguen requiriendo revisión
del aparato cuando la pizarra no especifica el ergómetro: no inferir el
material sin evidencia.

### Puerta de consistencia Apple Intelligence

El flujo iOS mantiene el análisis local incluso cuando Foundation Models
está disponible. La propuesta generativa solo se utiliza si respeta el
número, clase y orden de bloques, las rondas, los tiempos e intervalos
explícitos y el número de movimientos detectados. Se rechazan movimientos
inventados a partir de títulos («Warm Up», «Metcon») y enlaces de vídeo.
En caso de divergencia se muestra el plan local determinista, sin esperar
una segunda descarga. El control está cubierto por
BoardScanAIResultGuardTests.swift.
