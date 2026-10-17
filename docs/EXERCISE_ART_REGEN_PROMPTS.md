# GYMBRO — PROMPTS INDIVIDUALES PARA REGENERACIÓN DE ARTE

> Fuente: auditoría vigente en rama `fix/exercise-art-audit-20261017` · 2026-10-17.
>
> **109 stems señalados**: 89 FAIL + 20 WARN. Afectan a **80 ejercicios**.
> **155 stems incluidos en este documento**: los 109 con incidencias y 46 héroes/fotogramas hermanos aconsejados para regenerar junto a ellos y mantener un único personaje, cámara y equipamiento. Son tareas de generación, **no archivos exportados ni aprobados**.
> Los otros **182 stems sin veredicto definitivo** también deben pasar QA visual; no se prescriben aquí como errores confirmados.
>
> **Uso**: entregar a la IA `art_ab_wheel.jpg` y, para un ejercicio completo, sus JPG originales; generar **una única imagen por solicitud** usando el prompt literal del stem. Preferir regenerar el hero y la secuencia completa de una misma familia en un lote con referencias compartidas, **pero cada output es individual**. Para un stem marcado como `CONTINUIDAD`, no hay defecto específico confirmado; se incluye para uniformidad con sus hermanos.
>
> Nunca modificar otra carpeta, otro esquema de nombres ni devolver solo un archivo de `GenerateImage`.

## PROMPT MAESTRO (aplicado íntegramente a cada stem)

```text
You are the dedicated art director and movement illustrator for GYMBRO. Produce exactly ONE finished square exercise image PER requested STEM, NOT a collage or infographic. This is an individual output asset used directly in an iOS exercise library.

CANONICAL REFERENCE (must be provided to the image AI): Apps/Gymbro/Resources/ExerciseArt/art_ab_wheel.jpg. When available provide also the original hero and a GOOD existing sibling frame for the same exercise as visual reference; reference appearance and equipment, NEVER repeat an incorrect pose.

SUBJECT: same ONE athletic adult male in every image and every sequence: flat clean anatomical/vector style, medium-gray skin/silhouette and musculature, featureless face (no realistic facial traits), short solid charcoal hair, BARE SHIRTLESS TORSO ALWAYS, dark charcoal athletic shorts, gray trainers. Constant age, height, limb lengths, musculature and head proportions; nothing on the torso, no knee pads, belts, gloves or decorative accessories unless exercise equipment mechanically requires them.

VISUAL: uniform very dark near-black charcoal matte background (#101314 approx.), flat 2D illustration with subtle vector shading and crisp contours like canonical art_ab_wheel; symmetrical dark gray equipment, no room, no gym background, no labels, no arrows, no text, no logos, no watermark, no UI. Square 1:1 at least 1024×1024, full athlete + entire equipment visible centered with margins; NEVER crop barbell ends, feet, wall target, rings or pads.

EQUIPMENT: one fixed apparatus for ONE exercise, including same bar, same plate count/disc shape, same bench and support geometry, same kettlebell or dumbbells throughout hero and all numbered frames. FRONT rack means bar resting against front shoulders and elbows directed forward/up, NEVER behind neck. Jerk is NOT a shoulder press or curl; no loose floating dumbbells; realistic physical body–equipment contacts.

POSE: reproduce ONE unambiguous movement instant specified below (do not display phases combined or phantom limbs). In a sequence, lock camera angle/distance/side and body orientation, changing only joint angles and movement progress. Distinct phases must show a meaningful articular change; NEVER duplicate 3 nearly identical lockouts.

HIGHLIGHT: neon lime ONLY as FLAT FILLED areas on the specific active muscles of THIS phase, never painted all over the body and never neon outlines only. Gray skin otherwise. No red or blue anatomy highlights.

SHADOW: supported feet/hands/bench may have subtle low-opacity charcoal oval underneath ACTUAL contacts; NO ground oval, fake ground or floor shadow AT ALL when fully airborne, hanging from bar, on suspended rings or in unsupported high-bar support.

OUTPUT: create ONE standalone JPG for the exact specified STEM. Save under Apps/Gymbro/Resources/ExerciseArt/<stem>.jpg at 1024×1024 and a matching 192×192 JPG thumb under Apps/Gymbro/Resources/ExerciseArt/thumbs/<stem>.jpg. Do NOT output posters, grids, title text, a montage, a watermark or a single file combining multiple stages. Verify visually and export BOTH sizes using scripts/export_generated_art.py, e.g. .venv-art/bin/python scripts/export_generated_art.py /path/generated.jpg <stem>. Once generated confirm readable JPG, correct dimensions, same person/equipment and captions matching frames.
```

## PROMPTS INDIVIDUALES — copiar y pegar uno a uno

Los siguientes prompts **son autónomos**: cada uno vuelve a incluir el contrato visual imprescindible, para que la IA no dependa de la memoria entre peticiones.

### 1. Aperturas — `art_aperturas`

- **Equipo obligatorio:** two identical gray dumbbells and one flat bench.
- **Cámara fija:** fixed slightly elevated side three-quarter view.
- **Lime:** pectoralis major and anterior deltoids.
- **Sombra:** floor shadow only under bench.
- **Referencias:** `art_ab_wheel.jpg`, `art_aperturas.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_aperturas` — FAIL

**Problema:** Aperturas con lime en abdominales en lugar de músculos pectorales

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_aperturas image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Aperturas. ASSET NAME: art_aperturas. FRAME: representative hero.
EXACT JOINT/GEAR POSE: lying supine on bench, dumbbells opened to chest level, elbows softly bent; show a true dumbbell chest fly.
FIXED EQUIPMENT: two identical gray dumbbells and one flat bench.
LOCKED CAMERA AND LATERALITY: fixed slightly elevated side three-quarter view.
LIME MUSCLE FILL: pectoralis major and anterior deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor shadow only under bench. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_aperturas; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Aperturas con lime en abdominales en lugar de músculos pectorales.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_aperturas.jpg 1024x1024 and matching thumbs/art_aperturas.jpg 192x192.
```

#### `art_aperturas_1` — FAIL

**Problema:** Pectorales no iluminados; lime en abdominales durante apertura

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Cierra el arco: mancuernas casi juntas sobre el esternón, codos blandos.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_aperturas image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Aperturas. ASSET NAME: art_aperturas_1. FRAME: step 1 of 2.
EXACT JOINT/GEAR POSE: Cierra el arco: mancuernas casi juntas sobre el esternón, codos blandos..
FIXED EQUIPMENT: two identical gray dumbbells and one flat bench.
LOCKED CAMERA AND LATERALITY: fixed slightly elevated side three-quarter view.
LIME MUSCLE FILL: pectoralis major and anterior deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor shadow only under bench. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_aperturas; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Pectorales no iluminados; lime en abdominales durante apertura.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Cierra el arco: mancuernas casi juntas sobre el esternón, codos blandos..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_aperturas_1.jpg 1024x1024 and matching thumbs/art_aperturas_1.jpg 192x192.
```

#### `art_aperturas_2` — FAIL

**Problema:** Pectorales no iluminados; lime en abdominales durante apertura

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Abre en arco amplio hasta estirar el pecho, mancuernas a la altura del torso.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_aperturas image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Aperturas. ASSET NAME: art_aperturas_2. FRAME: step 2 of 2.
EXACT JOINT/GEAR POSE: Abre en arco amplio hasta estirar el pecho, mancuernas a la altura del torso..
FIXED EQUIPMENT: two identical gray dumbbells and one flat bench.
LOCKED CAMERA AND LATERALITY: fixed slightly elevated side three-quarter view.
LIME MUSCLE FILL: pectoralis major and anterior deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor shadow only under bench. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_aperturas; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Pectorales no iluminados; lime en abdominales durante apertura.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Abre en arco amplio hasta estirar el pecho, mancuernas a la altura del torso..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_aperturas_2.jpg 1024x1024 and matching thumbs/art_aperturas_2.jpg 192x192.
```


### 2. Sentadilla búlgara — `art_bulgara`

- **Equipo obligatorio:** two identical gray dumbbells and low rear-foot bench.
- **Cámara fija:** fixed lateral side view; front leg always LEFT throughout.
- **Lime:** front quadriceps and gluteus maximus.
- **Sombra:** soft oval at grounded foot and bench.
- **Referencias:** `art_ab_wheel.jpg`, `art_bulgara.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_bulgara` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_bulgara image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Sentadilla búlgara. ASSET NAME: art_bulgara. FRAME: representative hero.
EXACT JOINT/GEAR POSE: front foot grounded, rear instep supported on a bench behind, dumbbells hanging by both sides, controlled split squat.
FIXED EQUIPMENT: two identical gray dumbbells and low rear-foot bench.
LOCKED CAMERA AND LATERALITY: fixed lateral side view; front leg always LEFT throughout.
LIME MUSCLE FILL: front quadriceps and gluteus maximus; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval at grounded foot and bench. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_bulgara; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_bulgara.jpg 1024x1024 and matching thumbs/art_bulgara.jpg 192x192.
```

#### `art_bulgara_1` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Pie trasero en banco, torso erguido.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_bulgara image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Sentadilla búlgara. ASSET NAME: art_bulgara_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Pie trasero en banco, torso erguido..
FIXED EQUIPMENT: two identical gray dumbbells and low rear-foot bench.
LOCKED CAMERA AND LATERALITY: fixed lateral side view; front leg always LEFT throughout.
LIME MUSCLE FILL: front quadriceps and gluteus maximus; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval at grounded foot and bench. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_bulgara; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Pie trasero en banco, torso erguido..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_bulgara_1.jpg 1024x1024 and matching thumbs/art_bulgara_1.jpg 192x192.
```

#### `art_bulgara_2` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Baja a media profundidad sobre la pierna delantera.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_bulgara image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Sentadilla búlgara. ASSET NAME: art_bulgara_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Baja a media profundidad sobre la pierna delantera..
FIXED EQUIPMENT: two identical gray dumbbells and low rear-foot bench.
LOCKED CAMERA AND LATERALITY: fixed lateral side view; front leg always LEFT throughout.
LIME MUSCLE FILL: front quadriceps and gluteus maximus; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval at grounded foot and bench. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_bulgara; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Baja a media profundidad sobre la pierna delantera..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_bulgara_2.jpg 1024x1024 and matching thumbs/art_bulgara_2.jpg 192x192.
```

#### `art_bulgara_3` — FAIL

**Problema:** Se invierte la dirección del ejercicio y cambia el lado del banco

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Rodilla trasera cerca del suelo; empuja para subir.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_bulgara image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Sentadilla búlgara. ASSET NAME: art_bulgara_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Rodilla trasera cerca del suelo; empuja para subir..
FIXED EQUIPMENT: two identical gray dumbbells and low rear-foot bench.
LOCKED CAMERA AND LATERALITY: fixed lateral side view; front leg always LEFT throughout.
LIME MUSCLE FILL: front quadriceps and gluteus maximus; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval at grounded foot and bench. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_bulgara; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Se invierte la dirección del ejercicio y cambia el lado del banco.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Rodilla trasera cerca del suelo; empuja para subir..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_bulgara_3.jpg 1024x1024 and matching thumbs/art_bulgara_3.jpg 192x192.
```


### 3. Arrancada — `art_cf_arrancada`

- **Equipo obligatorio:** one Olympic barbell with wide snatch grip and identical dark plates.
- **Cámara fija:** fixed three-quarter frontal view.
- **Lime:** quadriceps, glutes, deltoids and upper back.
- **Sombra:** floor shadow under shoes.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_arrancada.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_arrancada` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_arrancada image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Arrancada. ASSET NAME: art_cf_arrancada. FRAME: representative hero.
EXACT JOINT/GEAR POSE: bar caught securely overhead with wide grip, elbows locked, hips/knees strongly flexed in snatch reception.
FIXED EQUIPMENT: one Olympic barbell with wide snatch grip and identical dark plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter frontal view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and upper back; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor shadow under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_arrancada; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_arrancada.jpg 1024x1024 and matching thumbs/art_cf_arrancada.jpg 192x192.
```

#### `art_cf_arrancada_1` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Setup: barra sobre mediopié, AGARRE ANCHO de snatch, espalda plana.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_arrancada image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Arrancada. ASSET NAME: art_cf_arrancada_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Setup: barra sobre mediopié, AGARRE ANCHO de snatch, espalda plana..
FIXED EQUIPMENT: one Olympic barbell with wide snatch grip and identical dark plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter frontal view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and upper back; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor shadow under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_arrancada; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Setup: barra sobre mediopié, AGARRE ANCHO de snatch, espalda plana..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_arrancada_1.jpg 1024x1024 and matching thumbs/art_cf_arrancada_1.jpg 192x192.
```

#### `art_cf_arrancada_2` — FAIL

**Problema:** Fase de recepción casi igual al paso 3; falta tirón intermedio

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Métete bajo la barra tras la tirada: recibes hacia overhead squat.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_arrancada image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Arrancada. ASSET NAME: art_cf_arrancada_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Métete bajo la barra tras la tirada: recibes hacia overhead squat..
FIXED EQUIPMENT: one Olympic barbell with wide snatch grip and identical dark plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter frontal view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and upper back; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor shadow under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_arrancada; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Fase de recepción casi igual al paso 3; falta tirón intermedio.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Métete bajo la barra tras la tirada: recibes hacia overhead squat..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_arrancada_2.jpg 1024x1024 and matching thumbs/art_cf_arrancada_2.jpg 192x192.
```

#### `art_cf_arrancada_3` — FAIL

**Problema:** Segundo frame en sentadilla overhead prácticamente igual al paso 2

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Overhead squat profundo o de pie bloqueado, agarre ancho.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_arrancada image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Arrancada. ASSET NAME: art_cf_arrancada_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Overhead squat profundo o de pie bloqueado, agarre ancho..
FIXED EQUIPMENT: one Olympic barbell with wide snatch grip and identical dark plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter frontal view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and upper back; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor shadow under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_arrancada; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Segundo frame en sentadilla overhead prácticamente igual al paso 2.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Overhead squat profundo o de pie bloqueado, agarre ancho..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_arrancada_3.jpg 1024x1024 and matching thumbs/art_cf_arrancada_3.jpg 192x192.
```


### 4. Broad jump — `art_cf_broad`

- **Equipo obligatorio:** no equipment.
- **Cámara fija:** fixed side view facing RIGHT.
- **Lime:** quadriceps, glutes and calves.
- **Sombra:** NO floor oval or shadow while airborne.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_broad.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_broad` — WARN

**Problema:** Broad jump muestra zancada lateral muy abierta en vuelo

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_broad image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Broad jump. ASSET NAME: art_cf_broad. FRAME: representative hero.
EXACT JOINT/GEAR POSE: mid-flight two-foot broad jump forward with bent hips and knees, feet aligned rather than side split.
FIXED EQUIPMENT: no equipment.
LOCKED CAMERA AND LATERALITY: fixed side view facing RIGHT.
LIME MUSCLE FILL: quadriceps, glutes and calves; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval or shadow while airborne. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_broad; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Broad jump muestra zancada lateral muy abierta en vuelo.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_broad.jpg 1024x1024 and matching thumbs/art_cf_broad.jpg 192x192.
```


### 5. Burpee pull-up — `art_cf_burpee_pu`

- **Equipo obligatorio:** one fixed horizontal pull-up bar with identical supports in every phase.
- **Cámara fija:** fixed three-quarter view showing bar overhead.
- **Lime:** lats, biceps and core.
- **Sombra:** NO floor shadow during hang or jump.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_burpee_pu.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_burpee_pu` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_burpee_pu image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Burpee pull-up. ASSET NAME: art_cf_burpee_pu. FRAME: representative hero.
EXACT JOINT/GEAR POSE: athlete hanging from pull-up bar and pulling chin just above it; feet remain clear of the floor.
FIXED EQUIPMENT: one fixed horizontal pull-up bar with identical supports in every phase.
LOCKED CAMERA AND LATERALITY: fixed three-quarter view showing bar overhead.
LIME MUSCLE FILL: lats, biceps and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor shadow during hang or jump. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_burpee_pu; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_burpee_pu.jpg 1024x1024 and matching thumbs/art_cf_burpee_pu.jpg 192x192.
```

#### `art_cf_burpee_pu_1` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Pecho al suelo bajo la barra.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_burpee_pu image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Burpee pull-up. ASSET NAME: art_cf_burpee_pu_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Pecho al suelo bajo la barra..
FIXED EQUIPMENT: one fixed horizontal pull-up bar with identical supports in every phase.
LOCKED CAMERA AND LATERALITY: fixed three-quarter view showing bar overhead.
LIME MUSCLE FILL: lats, biceps and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor shadow during hang or jump. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_burpee_pu; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Pecho al suelo bajo la barra..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_burpee_pu_1.jpg 1024x1024 and matching thumbs/art_cf_burpee_pu_1.jpg 192x192.
```

#### `art_cf_burpee_pu_2` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Salta y agarra la barra.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_burpee_pu image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Burpee pull-up. ASSET NAME: art_cf_burpee_pu_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Salta y agarra la barra..
FIXED EQUIPMENT: one fixed horizontal pull-up bar with identical supports in every phase.
LOCKED CAMERA AND LATERALITY: fixed three-quarter view showing bar overhead.
LIME MUSCLE FILL: lats, biceps and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor shadow during hang or jump. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_burpee_pu; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Salta y agarra la barra..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_burpee_pu_2.jpg 1024x1024 and matching thumbs/art_cf_burpee_pu_2.jpg 192x192.
```

#### `art_cf_burpee_pu_3` — FAIL

**Problema:** Barra final distinta a la estructura de barra de los pasos anteriores

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Dominada: barbilla por encima de la barra.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_burpee_pu image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Burpee pull-up. ASSET NAME: art_cf_burpee_pu_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Dominada: barbilla por encima de la barra..
FIXED EQUIPMENT: one fixed horizontal pull-up bar with identical supports in every phase.
LOCKED CAMERA AND LATERALITY: fixed three-quarter view showing bar overhead.
LIME MUSCLE FILL: lats, biceps and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor shadow during hang or jump. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_burpee_pu; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Barra final distinta a la estructura de barra de los pasos anteriores.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Dominada: barbilla por encima de la barra..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_burpee_pu_3.jpg 1024x1024 and matching thumbs/art_cf_burpee_pu_3.jpg 192x192.
```


### 6. Cargada — `art_cf_cargada`

- **Equipo obligatorio:** one Olympic barbell with symmetrical charcoal plates.
- **Cámara fija:** fixed three-quarter frontal view.
- **Lime:** quadriceps, glutes, traps and core.
- **Sombra:** ground oval under shoes.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_cargada.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_cargada` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_cargada image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada. ASSET NAME: art_cf_cargada. FRAME: representative hero.
EXACT JOINT/GEAR POSE: athlete standing with same barbell in FRONT rack on anterior shoulders, elbows forward and high.
FIXED EQUIPMENT: one Olympic barbell with symmetrical charcoal plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter frontal view.
LIME MUSCLE FILL: quadriceps, glutes, traps and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_cargada; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_cargada.jpg 1024x1024 and matching thumbs/art_cf_cargada.jpg 192x192.
```

#### `art_cf_cargada_1` — FAIL

**Problema:** Atleta vestido con camiseta en fase inicial frente a frames sin camiseta

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Setup: barra sobre mediopié, agarre de clean.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_cargada image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada. ASSET NAME: art_cf_cargada_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Setup: barra sobre mediopié, agarre de clean..
FIXED EQUIPMENT: one Olympic barbell with symmetrical charcoal plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter frontal view.
LIME MUSCLE FILL: quadriceps, glutes, traps and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_cargada; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Atleta vestido con camiseta en fase inicial frente a frames sin camiseta.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Setup: barra sobre mediopié, agarre de clean..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_cargada_1.jpg 1024x1024 and matching thumbs/art_cf_cargada_1.jpg 192x192.
```

#### `art_cf_cargada_2` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Recibe en front squat: barra delante del cuello, codos altos, cadera baja.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_cargada image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada. ASSET NAME: art_cf_cargada_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Recibe en front squat: barra delante del cuello, codos altos, cadera baja..
FIXED EQUIPMENT: one Olympic barbell with symmetrical charcoal plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter frontal view.
LIME MUSCLE FILL: quadriceps, glutes, traps and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_cargada; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Recibe en front squat: barra delante del cuello, codos altos, cadera baja..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_cargada_2.jpg 1024x1024 and matching thumbs/art_cf_cargada_2.jpg 192x192.
```

#### `art_cf_cargada_3` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Párate en rack frontal bloqueado.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_cargada image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada. ASSET NAME: art_cf_cargada_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Párate en rack frontal bloqueado..
FIXED EQUIPMENT: one Olympic barbell with symmetrical charcoal plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter frontal view.
LIME MUSCLE FILL: quadriceps, glutes, traps and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_cargada; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Párate en rack frontal bloqueado..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_cargada_3.jpg 1024x1024 and matching thumbs/art_cf_cargada_3.jpg 192x192.
```


### 7. Cargada y envión — `art_cf_cj`

- **Equipo obligatorio:** one Olympic barbell, equal plates, no rack, no loose dumbbells or discs.
- **Cámara fija:** fixed three-quarter side view facing RIGHT.
- **Lime:** quadriceps, glutes, deltoids and triceps.
- **Sombra:** ground shadow under contacting shoes.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_cj.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_cj` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_cj image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada y envión. ASSET NAME: art_cf_cj. FRAME: representative hero.
EXACT JOINT/GEAR POSE: full clean-and-jerk finishing split or stable overhead lockout with the same barbell.
FIXED EQUIPMENT: one Olympic barbell, equal plates, no rack, no loose dumbbells or discs.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view facing RIGHT.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground shadow under contacting shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_cj; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_cj.jpg 1024x1024 and matching thumbs/art_cf_cj.jpg 192x192.
```

#### `art_cf_cj_1` — FAIL

**Problema:** Disco/maneral corto en lugar de misma barra olímpica del movimiento

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Rack frontal tras la cargada, de pie.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_cj image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada y envión. ASSET NAME: art_cf_cj_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Rack frontal tras la cargada, de pie..
FIXED EQUIPMENT: one Olympic barbell, equal plates, no rack, no loose dumbbells or discs.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view facing RIGHT.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground shadow under contacting shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_cj; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Disco/maneral corto en lugar de misma barra olímpica del movimiento.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Rack frontal tras la cargada, de pie..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_cj_1.jpg 1024x1024 and matching thumbs/art_cf_cj_1.jpg 192x192.
```

#### `art_cf_cj_2` — FAIL

**Problema:** Back rack de sentadilla con soporte de rack, en vez de front rack de cargada

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Dip-drive: flexión corta y empuje.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_cj image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada y envión. ASSET NAME: art_cf_cj_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Dip-drive: flexión corta y empuje..
FIXED EQUIPMENT: one Olympic barbell, equal plates, no rack, no loose dumbbells or discs.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view facing RIGHT.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground shadow under contacting shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_cj; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Back rack de sentadilla con soporte de rack, en vez de front rack de cargada.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Dip-drive: flexión corta y empuje..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_cj_2.jpg 1024x1024 and matching thumbs/art_cf_cj_2.jpg 192x192.
```

#### `art_cf_cj_3` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Bloquea overhead y recupera pies.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_cj image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada y envión. ASSET NAME: art_cf_cj_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Bloquea overhead y recupera pies..
FIXED EQUIPMENT: one Olympic barbell, equal plates, no rack, no loose dumbbells or discs.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view facing RIGHT.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground shadow under contacting shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_cj; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Bloquea overhead y recupera pies..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_cj_3.jpg 1024x1024 and matching thumbs/art_cf_cj_3.jpg 192x192.
```


### 8. Cluster — `art_cf_cluster`

- **Equipo obligatorio:** one Olympic barbell with matched charcoal weight plates.
- **Cámara fija:** fixed frontal three-quarter view.
- **Lime:** quadriceps, glutes, deltoids and triceps.
- **Sombra:** floor shadow under shoes.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_cluster.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_cluster` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_cluster image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cluster. ASSET NAME: art_cf_cluster. FRAME: representative hero.
EXACT JOINT/GEAR POSE: finish of squat clean plus thruster with barbell overhead, elbows locked and legs straight.
FIXED EQUIPMENT: one Olympic barbell with matched charcoal weight plates.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor shadow under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_cluster; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_cluster.jpg 1024x1024 and matching thumbs/art_cf_cluster.jpg 192x192.
```

#### `art_cf_cluster_1` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Rack frontal tras la cargada.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_cluster image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cluster. ASSET NAME: art_cf_cluster_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Rack frontal tras la cargada..
FIXED EQUIPMENT: one Olympic barbell with matched charcoal weight plates.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor shadow under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_cluster; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Rack frontal tras la cargada..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_cluster_1.jpg 1024x1024 and matching thumbs/art_cf_cluster_1.jpg 192x192.
```

#### `art_cf_cluster_2` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Sentadilla frontal profunda sin soltar el rack.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_cluster image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cluster. ASSET NAME: art_cf_cluster_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Sentadilla frontal profunda sin soltar el rack..
FIXED EQUIPMENT: one Olympic barbell with matched charcoal weight plates.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor shadow under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_cluster; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Sentadilla frontal profunda sin soltar el rack..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_cluster_2.jpg 1024x1024 and matching thumbs/art_cf_cluster_2.jpg 192x192.
```

#### `art_cf_cluster_3` — FAIL

**Problema:** Termina con mancuernas tras iniciar y bajar con barra olímpica

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Thruster a overhead en un solo tiempo.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_cluster image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cluster. ASSET NAME: art_cf_cluster_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Thruster a overhead en un solo tiempo..
FIXED EQUIPMENT: one Olympic barbell with matched charcoal weight plates.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor shadow under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_cluster; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Termina con mancuernas tras iniciar y bajar con barra olímpica.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Thruster a overhead en un solo tiempo..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_cluster_3.jpg 1024x1024 and matching thumbs/art_cf_cluster_3.jpg 192x192.
```


### 9. Chest to bar — `art_cf_ctb`

- **Equipo obligatorio:** one pull-up bar attached to stationary high supports.
- **Cámara fija:** fixed front three-quarter view, identical camera throughout.
- **Lime:** lats, scapular retractors and biceps.
- **Sombra:** NO ground oval or floor shadow.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_ctb.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_ctb` — FAIL

**Problema:** Chest-to-bar con torso vestido y pies apoyados en vez de suspendidos

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ctb image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Chest to bar. ASSET NAME: art_cf_ctb. FRAME: representative hero.
EXACT JOINT/GEAR POSE: chest touching the pull-up bar with elbows bent, both feet suspended and bare torso.
FIXED EQUIPMENT: one pull-up bar attached to stationary high supports.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view, identical camera throughout.
LIME MUSCLE FILL: lats, scapular retractors and biceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground oval or floor shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ctb; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Chest-to-bar con torso vestido y pies apoyados en vez de suspendidos.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ctb.jpg 1024x1024 and matching thumbs/art_cf_ctb.jpg 192x192.
```

#### `art_cf_ctb_1` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Cuelga con brazos extendidos y agarre firme.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ctb image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Chest to bar. ASSET NAME: art_cf_ctb_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Cuelga con brazos extendidos y agarre firme..
FIXED EQUIPMENT: one pull-up bar attached to stationary high supports.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view, identical camera throughout.
LIME MUSCLE FILL: lats, scapular retractors and biceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground oval or floor shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ctb; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Cuelga con brazos extendidos y agarre firme..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ctb_1.jpg 1024x1024 and matching thumbs/art_cf_ctb_1.jpg 192x192.
```

#### `art_cf_ctb_2` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Tira hasta la barbilla cerca de la barra.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ctb image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Chest to bar. ASSET NAME: art_cf_ctb_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Tira hasta la barbilla cerca de la barra..
FIXED EQUIPMENT: one pull-up bar attached to stationary high supports.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view, identical camera throughout.
LIME MUSCLE FILL: lats, scapular retractors and biceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground oval or floor shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ctb; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Tira hasta la barbilla cerca de la barra..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ctb_2.jpg 1024x1024 and matching thumbs/art_cf_ctb_2.jpg 192x192.
```

#### `art_cf_ctb_3` — FAIL

**Problema:** Chest to bar con piernas apoyadas; no está suspendido

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Lleva el pecho a tocar la barra y baja con control.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ctb image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Chest to bar. ASSET NAME: art_cf_ctb_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Lleva el pecho a tocar la barra y baja con control..
FIXED EQUIPMENT: one pull-up bar attached to stationary high supports.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view, identical camera throughout.
LIME MUSCLE FILL: lats, scapular retractors and biceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground oval or floor shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ctb; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Chest to bar con piernas apoyadas; no está suspendido.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Lleva el pecho a tocar la barra y baja con control..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ctb_3.jpg 1024x1024 and matching thumbs/art_cf_ctb_3.jpg 192x192.
```


### 10. GHD sit-up — `art_cf_ghd`

- **Equipo obligatorio:** one actual GHD bench with thigh pad and paired foot rollers.
- **Cámara fija:** fixed full-body side view.
- **Lime:** abdominals and hip flexors.
- **Sombra:** shadow only beneath GHD structure.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_ghd.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_ghd` — FAIL

**Problema:** Hero con camiseta

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ghd image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: GHD sit-up. ASSET NAME: art_cf_ghd. FRAME: representative hero.
EXACT JOINT/GEAR POSE: feet fixed in rollers, hips supported on GHD pad, trunk extended behind neutral line for starting GHD sit-up.
FIXED EQUIPMENT: one actual GHD bench with thigh pad and paired foot rollers.
LOCKED CAMERA AND LATERALITY: fixed full-body side view.
LIME MUSCLE FILL: abdominals and hip flexors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow only beneath GHD structure. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ghd; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Hero con camiseta.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ghd.jpg 1024x1024 and matching thumbs/art_cf_ghd.jpg 192x192.
```

#### `art_cf_ghd_1` — FAIL

**Problema:** Torso vestido y posición del aparato poco clara

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Fija los pies en los rodillos e inclina el tronco hacia atrás con control.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ghd image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: GHD sit-up. ASSET NAME: art_cf_ghd_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Fija los pies en los rodillos e inclina el tronco hacia atrás con control..
FIXED EQUIPMENT: one actual GHD bench with thigh pad and paired foot rollers.
LOCKED CAMERA AND LATERALITY: fixed full-body side view.
LIME MUSCLE FILL: abdominals and hip flexors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow only beneath GHD structure. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ghd; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Torso vestido y posición del aparato poco clara.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Fija los pies en los rodillos e inclina el tronco hacia atrás con control..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ghd_1.jpg 1024x1024 and matching thumbs/art_cf_ghd_1.jpg 192x192.
```

#### `art_cf_ghd_2` — FAIL

**Problema:** Torso vestido y movimiento poco diferenciado

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Flexiona el tronco y lleva los brazos hacia delante sin soltar el apoyo.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ghd image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: GHD sit-up. ASSET NAME: art_cf_ghd_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Flexiona el tronco y lleva los brazos hacia delante sin soltar el apoyo..
FIXED EQUIPMENT: one actual GHD bench with thigh pad and paired foot rollers.
LOCKED CAMERA AND LATERALITY: fixed full-body side view.
LIME MUSCLE FILL: abdominals and hip flexors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow only beneath GHD structure. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ghd; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Torso vestido y movimiento poco diferenciado.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Flexiona el tronco y lleva los brazos hacia delante sin soltar el apoyo..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ghd_2.jpg 1024x1024 and matching thumbs/art_cf_ghd_2.jpg 192x192.
```

#### `art_cf_ghd_3` — FAIL

**Problema:** Torso vestido y fase muy similar a la anterior

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Termina de incorporarte manteniendo la cadera sobre el apoyo de la máquina.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ghd image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: GHD sit-up. ASSET NAME: art_cf_ghd_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Termina de incorporarte manteniendo la cadera sobre el apoyo de la máquina..
FIXED EQUIPMENT: one actual GHD bench with thigh pad and paired foot rollers.
LOCKED CAMERA AND LATERALITY: fixed full-body side view.
LIME MUSCLE FILL: abdominals and hip flexors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow only beneath GHD structure. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ghd; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Torso vestido y fase muy similar a la anterior.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Termina de incorporarte manteniendo la cadera sobre el apoyo de la máquina..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ghd_3.jpg 1024x1024 and matching thumbs/art_cf_ghd_3.jpg 192x192.
```


### 11. Cargada colgante — `art_cf_hang_clean`

- **Equipo obligatorio:** one Olympic barbell with equal charcoal plates, NO squat rack.
- **Cámara fija:** fixed side three-quarter view.
- **Lime:** glutes, hamstrings, traps and quadriceps.
- **Sombra:** ground oval only for supported feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_hang_clean.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_hang_clean` — FAIL

**Problema:** Hero con camiseta

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_hang_clean image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada colgante. ASSET NAME: art_cf_hang_clean. FRAME: representative hero.
EXACT JOINT/GEAR POSE: standing tall with barbell in front rack on anterior deltoids and high elbows after a hang clean.
FIXED EQUIPMENT: one Olympic barbell with equal charcoal plates, NO squat rack.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: glutes, hamstrings, traps and quadriceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval only for supported feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_hang_clean; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Hero con camiseta.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_hang_clean.jpg 1024x1024 and matching thumbs/art_cf_hang_clean.jpg 192x192.
```

#### `art_cf_hang_clean_1` — FAIL

**Problema:** Torso vestido, contra la referencia canónica

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Barra en muslos, bisagra ligera, espalda plana.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_hang_clean image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada colgante. ASSET NAME: art_cf_hang_clean_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Barra en muslos, bisagra ligera, espalda plana..
FIXED EQUIPMENT: one Olympic barbell with equal charcoal plates, NO squat rack.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: glutes, hamstrings, traps and quadriceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval only for supported feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_hang_clean; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Torso vestido, contra la referencia canónica.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Barra en muslos, bisagra ligera, espalda plana..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_hang_clean_1.jpg 1024x1024 and matching thumbs/art_cf_hang_clean_1.jpg 192x192.
```

#### `art_cf_hang_clean_2` — FAIL

**Problema:** Torso vestido y sombra de suelo en fase aérea

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Extiende cadera y tira: barra sube pegada al cuerpo.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_hang_clean image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada colgante. ASSET NAME: art_cf_hang_clean_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Extiende cadera y tira: barra sube pegada al cuerpo..
FIXED EQUIPMENT: one Olympic barbell with equal charcoal plates, NO squat rack.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: glutes, hamstrings, traps and quadriceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval only for supported feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_hang_clean; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Torso vestido y sombra de suelo en fase aérea.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Extiende cadera y tira: barra sube pegada al cuerpo..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_hang_clean_2.jpg 1024x1024 and matching thumbs/art_cf_hang_clean_2.jpg 192x192.
```

#### `art_cf_hang_clean_3` — FAIL

**Problema:** Torso vestido, contra la referencia canónica

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Recibe en rack frontal (barra delante del cuello, codos altos) y párate.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_hang_clean image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada colgante. ASSET NAME: art_cf_hang_clean_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Recibe en rack frontal (barra delante del cuello, codos altos) y párate..
FIXED EQUIPMENT: one Olympic barbell with equal charcoal plates, NO squat rack.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: glutes, hamstrings, traps and quadriceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval only for supported feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_hang_clean; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Torso vestido, contra la referencia canónica.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Recibe en rack frontal (barra delante del cuello, codos altos) y párate..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_hang_clean_3.jpg 1024x1024 and matching thumbs/art_cf_hang_clean_3.jpg 192x192.
```


### 12. Hang power clean — `art_cf_hpc`

- **Equipo obligatorio:** one Olympic barbell with equal plates.
- **Cámara fija:** fixed front three-quarter view.
- **Lime:** glutes, quads and traps.
- **Sombra:** ground oval under planted feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_hpc.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_hpc` — FAIL

**Problema:** Hang power clean mostrado con barra detrás del cuello

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_hpc image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Hang power clean. ASSET NAME: art_cf_hpc. FRAME: representative hero.
EXACT JOINT/GEAR POSE: hang power clean reception in a shallow quarter squat with bar in FRONT rack, elbows high.
FIXED EQUIPMENT: one Olympic barbell with equal plates.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view.
LIME MUSCLE FILL: glutes, quads and traps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_hpc; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Hang power clean mostrado con barra detrás del cuello.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_hpc.jpg 1024x1024 and matching thumbs/art_cf_hpc.jpg 192x192.
```


### 13. Hang power snatch — `art_cf_hps`

- **Equipo obligatorio:** one Olympic barbell with WIDE snatch grip.
- **Cámara fija:** fixed three-quarter side view.
- **Lime:** glutes, quadriceps and deltoids.
- **Sombra:** floor oval under planted feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_hps.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_hps` — FAIL

**Problema:** Hang power snatch con barra tras la cabeza y pies despegados

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_hps image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Hang power snatch. ASSET NAME: art_cf_hps. FRAME: representative hero.
EXACT JOINT/GEAR POSE: hang power snatch reception upright and high with straight arms holding bar overhead; feet on floor.
FIXED EQUIPMENT: one Olympic barbell with WIDE snatch grip.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view.
LIME MUSCLE FILL: glutes, quadriceps and deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_hps; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Hang power snatch con barra tras la cabeza y pies despegados.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_hps.jpg 1024x1024 and matching thumbs/art_cf_hps.jpg 192x192.
```


### 14. HSPU — `art_cf_hspu`

- **Equipo obligatorio:** plain wall and floor, no barbell, no bench.
- **Cámara fija:** fixed strict lateral view, same wall in every frame.
- **Lime:** deltoids, triceps and serratus.
- **Sombra:** subtle floor shadow ONLY under palms.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_hspu.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_hspu` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_hspu image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: HSPU. ASSET NAME: art_cf_hspu. FRAME: representative hero.
EXACT JOINT/GEAR POSE: inverted handstand push-up facing wall, palms on floor, heels resting lightly against wall.
FIXED EQUIPMENT: plain wall and floor, no barbell, no bench.
LOCKED CAMERA AND LATERALITY: fixed strict lateral view, same wall in every frame.
LIME MUSCLE FILL: deltoids, triceps and serratus; nothing else highlighted in lime.
CONTACT / SHADOW RULE: subtle floor shadow ONLY under palms. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_hspu; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_hspu.jpg 1024x1024 and matching thumbs/art_cf_hspu.jpg 192x192.
```

#### `art_cf_hspu_1` — FAIL

**Problema:** Bloqueo de handstand duplicado en paso 3, sin pared estable

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Pino contra la pared, brazos bloqueados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_hspu image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: HSPU. ASSET NAME: art_cf_hspu_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Pino contra la pared, brazos bloqueados..
FIXED EQUIPMENT: plain wall and floor, no barbell, no bench.
LOCKED CAMERA AND LATERALITY: fixed strict lateral view, same wall in every frame.
LIME MUSCLE FILL: deltoids, triceps and serratus; nothing else highlighted in lime.
CONTACT / SHADOW RULE: subtle floor shadow ONLY under palms. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_hspu; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Bloqueo de handstand duplicado en paso 3, sin pared estable.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Pino contra la pared, brazos bloqueados..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_hspu_1.jpg 1024x1024 and matching thumbs/art_cf_hspu_1.jpg 192x192.
```

#### `art_cf_hspu_2` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Baja la cabeza hacia el suelo con codos flexionados ~90°.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_hspu image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: HSPU. ASSET NAME: art_cf_hspu_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Baja la cabeza hacia el suelo con codos flexionados ~90°..
FIXED EQUIPMENT: plain wall and floor, no barbell, no bench.
LOCKED CAMERA AND LATERALITY: fixed strict lateral view, same wall in every frame.
LIME MUSCLE FILL: deltoids, triceps and serratus; nothing else highlighted in lime.
CONTACT / SHADOW RULE: subtle floor shadow ONLY under palms. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_hspu; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Baja la cabeza hacia el suelo con codos flexionados ~90°..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_hspu_2.jpg 1024x1024 and matching thumbs/art_cf_hspu_2.jpg 192x192.
```

#### `art_cf_hspu_3` — FAIL

**Problema:** Fotograma prácticamente idéntico al paso 1, sin pared estable

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Empuja hasta bloquear otra vez en pino.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_hspu image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: HSPU. ASSET NAME: art_cf_hspu_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Empuja hasta bloquear otra vez en pino..
FIXED EQUIPMENT: plain wall and floor, no barbell, no bench.
LOCKED CAMERA AND LATERALITY: fixed strict lateral view, same wall in every frame.
LIME MUSCLE FILL: deltoids, triceps and serratus; nothing else highlighted in lime.
CONTACT / SHADOW RULE: subtle floor shadow ONLY under palms. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_hspu; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Fotograma prácticamente idéntico al paso 1, sin pared estable.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Empuja hasta bloquear otra vez en pino..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_hspu_3.jpg 1024x1024 and matching thumbs/art_cf_hspu_3.jpg 192x192.
```


### 15. Clean kettlebell — `art_cf_kb_clean`

- **Equipo obligatorio:** one single charcoal kettlebell, handle gripped with one hand throughout.
- **Cámara fija:** fixed side three-quarter view.
- **Lime:** glutes, hamstrings, upper back and deltoid.
- **Sombra:** floor shadow under both feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_kb_clean.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_kb_clean` — FAIL

**Problema:** Clean de kettlebell mostrado con dos manos en balanceo

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_kb_clean image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Clean kettlebell. ASSET NAME: art_cf_kb_clean. FRAME: representative hero.
EXACT JOINT/GEAR POSE: one-arm kettlebell clean with bell safely resting in rack next to forearm and chest, not a two-hand swing.
FIXED EQUIPMENT: one single charcoal kettlebell, handle gripped with one hand throughout.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: glutes, hamstrings, upper back and deltoid; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor shadow under both feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_kb_clean; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Clean de kettlebell mostrado con dos manos en balanceo.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_kb_clean.jpg 1024x1024 and matching thumbs/art_cf_kb_clean.jpg 192x192.
```


### 16. Snatch kettlebell — `art_cf_kb_snatch`

- **Equipo obligatorio:** one single kettlebell in same hand throughout; NO barbell.
- **Cámara fija:** fixed strict side view; kettle always in RIGHT hand.
- **Lime:** glutes, hamstrings, deltoid and core.
- **Sombra:** ground oval under planted shoes.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_kb_snatch.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_kb_snatch` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_kb_snatch image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Snatch kettlebell. ASSET NAME: art_cf_kb_snatch. FRAME: representative hero.
EXACT JOINT/GEAR POSE: single arm kettlebell snatch locked overhead with elbow straight and wrist neutral.
FIXED EQUIPMENT: one single kettlebell in same hand throughout; NO barbell.
LOCKED CAMERA AND LATERALITY: fixed strict side view; kettle always in RIGHT hand.
LIME MUSCLE FILL: glutes, hamstrings, deltoid and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under planted shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_kb_snatch; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_kb_snatch.jpg 1024x1024 and matching thumbs/art_cf_kb_snatch.jpg 192x192.
```

#### `art_cf_kb_snatch_1` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** KB entre los pies, bisagra de cadera.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_kb_snatch image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Snatch kettlebell. ASSET NAME: art_cf_kb_snatch_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: KB entre los pies, bisagra de cadera..
FIXED EQUIPMENT: one single kettlebell in same hand throughout; NO barbell.
LOCKED CAMERA AND LATERALITY: fixed strict side view; kettle always in RIGHT hand.
LIME MUSCLE FILL: glutes, hamstrings, deltoid and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under planted shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_kb_snatch; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): KB entre los pies, bisagra de cadera..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_kb_snatch_1.jpg 1024x1024 and matching thumbs/art_cf_kb_snatch_1.jpg 192x192.
```

#### `art_cf_kb_snatch_2` — FAIL

**Problema:** Bloqueo OH casi idéntico al paso 3; falta tirón

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Extiende y guía la KB cerca del cuerpo.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_kb_snatch image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Snatch kettlebell. ASSET NAME: art_cf_kb_snatch_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Extiende y guía la KB cerca del cuerpo..
FIXED EQUIPMENT: one single kettlebell in same hand throughout; NO barbell.
LOCKED CAMERA AND LATERALITY: fixed strict side view; kettle always in RIGHT hand.
LIME MUSCLE FILL: glutes, hamstrings, deltoid and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under planted shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_kb_snatch; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Bloqueo OH casi idéntico al paso 3; falta tirón.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Extiende y guía la KB cerca del cuerpo..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_kb_snatch_2.jpg 1024x1024 and matching thumbs/art_cf_kb_snatch_2.jpg 192x192.
```

#### `art_cf_kb_snatch_3` — FAIL

**Problema:** Misma postura OH del paso 2, solo cambia el brazo libre

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Bloquea overhead a brazo extendido.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_kb_snatch image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Snatch kettlebell. ASSET NAME: art_cf_kb_snatch_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Bloquea overhead a brazo extendido..
FIXED EQUIPMENT: one single kettlebell in same hand throughout; NO barbell.
LOCKED CAMERA AND LATERALITY: fixed strict side view; kettle always in RIGHT hand.
LIME MUSCLE FILL: glutes, hamstrings, deltoid and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under planted shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_kb_snatch; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Misma postura OH del paso 2, solo cambia el brazo libre.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Bloquea overhead a brazo extendido..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_kb_snatch_3.jpg 1024x1024 and matching thumbs/art_cf_kb_snatch_3.jpg 192x192.
```


### 17. Knees to elbows — `art_cf_kte`

- **Equipo obligatorio:** fixed horizontal pull-up bar overhead.
- **Cámara fija:** fixed front three-quarter view.
- **Lime:** abdominals, hip flexors and lats.
- **Sombra:** NO ground shadow for hanging body.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_kte.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_kte` — FAIL

**Problema:** Knees-to-elbows en suspensión con óvalo de suelo

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_kte image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Knees to elbows. ASSET NAME: art_cf_kte. FRAME: representative hero.
EXACT JOINT/GEAR POSE: hanging with knees lifted toward elbows without feet touching ground.
FIXED EQUIPMENT: fixed horizontal pull-up bar overhead.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view.
LIME MUSCLE FILL: abdominals, hip flexors and lats; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground shadow for hanging body. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_kte; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Knees-to-elbows en suspensión con óvalo de suelo.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_kte.jpg 1024x1024 and matching thumbs/art_cf_kte.jpg 192x192.
```


### 18. Muscle-up barra — `art_cf_mu_bar`

- **Equipo obligatorio:** one fixed horizontal high bar and unchanged support structure.
- **Cámara fija:** fixed three-quarter side view for every pose.
- **Lime:** lats, triceps, pecs and core.
- **Sombra:** NO floor oval or floor shadow.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_mu_bar.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_mu_bar` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_mu_bar image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Muscle-up barra. ASSET NAME: art_cf_mu_bar. FRAME: representative hero.
EXACT JOINT/GEAR POSE: completed bar muscle-up in high support above the bar, fully straight elbows, feet hanging freely.
FIXED EQUIPMENT: one fixed horizontal high bar and unchanged support structure.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view for every pose.
LIME MUSCLE FILL: lats, triceps, pecs and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval or floor shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_mu_bar; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_mu_bar.jpg 1024x1024 and matching thumbs/art_cf_mu_bar.jpg 192x192.
```

#### `art_cf_mu_bar_1` — WARN

**Problema:** Cámara posterior frente a cámaras laterales

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Cuélgate de la barra con los brazos largos y sin apoyar los pies.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_mu_bar image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Muscle-up barra. ASSET NAME: art_cf_mu_bar_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Cuélgate de la barra con los brazos largos y sin apoyar los pies..
FIXED EQUIPMENT: one fixed horizontal high bar and unchanged support structure.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view for every pose.
LIME MUSCLE FILL: lats, triceps, pecs and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval or floor shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_mu_bar; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Cámara posterior frente a cámaras laterales.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Cuélgate de la barra con los brazos largos y sin apoyar los pies..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_mu_bar_1.jpg 1024x1024 and matching thumbs/art_cf_mu_bar_1.jpg 192x192.
```

#### `art_cf_mu_bar_2` — WARN

**Problema:** La cámara cambia durante la transición

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Tira del torso sobre la barra y gira las muñecas durante la transición.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_mu_bar image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Muscle-up barra. ASSET NAME: art_cf_mu_bar_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Tira del torso sobre la barra y gira las muñecas durante la transición..
FIXED EQUIPMENT: one fixed horizontal high bar and unchanged support structure.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view for every pose.
LIME MUSCLE FILL: lats, triceps, pecs and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval or floor shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_mu_bar; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: La cámara cambia durante la transición.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Tira del torso sobre la barra y gira las muñecas durante la transición..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_mu_bar_2.jpg 1024x1024 and matching thumbs/art_cf_mu_bar_2.jpg 192x192.
```

#### `art_cf_mu_bar_3` — WARN

**Problema:** Soporte final desde otro ángulo

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Empuja la barra hasta quedar en soporte con los brazos completamente extendidos.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_mu_bar image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Muscle-up barra. ASSET NAME: art_cf_mu_bar_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Empuja la barra hasta quedar en soporte con los brazos completamente extendidos..
FIXED EQUIPMENT: one fixed horizontal high bar and unchanged support structure.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view for every pose.
LIME MUSCLE FILL: lats, triceps, pecs and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval or floor shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_mu_bar; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Soporte final desde otro ángulo.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Empuja la barra hasta quedar en soporte con los brazos completamente extendidos..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_mu_bar_3.jpg 1024x1024 and matching thumbs/art_cf_mu_bar_3.jpg 192x192.
```


### 19. Muscle-up anillas — `art_cf_mu_rings`

- **Equipo obligatorio:** two GRAY gymnastic rings with identical straps and height.
- **Cámara fija:** fixed front three-quarter view across whole sequence.
- **Lime:** lats, triceps, pecs and stabilizers.
- **Sombra:** NO ground oval or floor shadow.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_mu_rings.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_mu_rings` — FAIL

**Problema:** Anillas beige en vez de grises

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_mu_rings image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Muscle-up anillas. ASSET NAME: art_cf_mu_rings. FRAME: representative hero.
EXACT JOINT/GEAR POSE: gymnast above rings in support with both rings next to hips, elbows locked and both feet suspended.
FIXED EQUIPMENT: two GRAY gymnastic rings with identical straps and height.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view across whole sequence.
LIME MUSCLE FILL: lats, triceps, pecs and stabilizers; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground oval or floor shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_mu_rings; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Anillas beige en vez de grises.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_mu_rings.jpg 1024x1024 and matching thumbs/art_cf_mu_rings.jpg 192x192.
```

#### `art_cf_mu_rings_1` — FAIL

**Problema:** Óvalo bajo el deportista colgado; anillas fuera de paleta

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Cuélgate de las dos anillas con los brazos largos y los pies suspendidos.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_mu_rings image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Muscle-up anillas. ASSET NAME: art_cf_mu_rings_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Cuélgate de las dos anillas con los brazos largos y los pies suspendidos..
FIXED EQUIPMENT: two GRAY gymnastic rings with identical straps and height.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view across whole sequence.
LIME MUSCLE FILL: lats, triceps, pecs and stabilizers; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground oval or floor shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_mu_rings; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Óvalo bajo el deportista colgado; anillas fuera de paleta.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Cuélgate de las dos anillas con los brazos largos y los pies suspendidos..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_mu_rings_1.jpg 1024x1024 and matching thumbs/art_cf_mu_rings_1.jpg 192x192.
```

#### `art_cf_mu_rings_2` — FAIL

**Problema:** Óvalo en suspensión; cambio de ángulo y lateralidad

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Tira y acerca las anillas a la cintura mientras inclinas el torso hacia delante.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_mu_rings image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Muscle-up anillas. ASSET NAME: art_cf_mu_rings_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Tira y acerca las anillas a la cintura mientras inclinas el torso hacia delante..
FIXED EQUIPMENT: two GRAY gymnastic rings with identical straps and height.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view across whole sequence.
LIME MUSCLE FILL: lats, triceps, pecs and stabilizers; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground oval or floor shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_mu_rings; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Óvalo en suspensión; cambio de ángulo y lateralidad.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Tira y acerca las anillas a la cintura mientras inclinas el torso hacia delante..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_mu_rings_2.jpg 1024x1024 and matching thumbs/art_cf_mu_rings_2.jpg 192x192.
```

#### `art_cf_mu_rings_3` — FAIL

**Problema:** Óvalo bajo el soporte en anillas; equipo inconsistente

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Extiende los codos y mantente arriba con una anilla a cada lado del cuerpo.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_mu_rings image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Muscle-up anillas. ASSET NAME: art_cf_mu_rings_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Extiende los codos y mantente arriba con una anilla a cada lado del cuerpo..
FIXED EQUIPMENT: two GRAY gymnastic rings with identical straps and height.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view across whole sequence.
LIME MUSCLE FILL: lats, triceps, pecs and stabilizers; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground oval or floor shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_mu_rings; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Óvalo bajo el soporte en anillas; equipo inconsistente.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Extiende los codos y mantente arriba con una anilla a cada lado del cuerpo..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_mu_rings_3.jpg 1024x1024 and matching thumbs/art_cf_mu_rings_3.jpg 192x192.
```


### 20. Overhead squat — `art_cf_ohs`

- **Equipo obligatorio:** one Olympic barbell with wide grip and matched plates.
- **Cámara fija:** fixed side three-quarter view.
- **Lime:** quadriceps, glutes, deltoids and upper back.
- **Sombra:** soft oval under planted feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_ohs.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_ohs` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ohs image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Overhead squat. ASSET NAME: art_cf_ohs. FRAME: representative hero.
EXACT JOINT/GEAR POSE: deep overhead squat with bar vertically above midfoot, locked elbows and heels planted.
FIXED EQUIPMENT: one Olympic barbell with wide grip and matched plates.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and upper back; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ohs; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ohs.jpg 1024x1024 and matching thumbs/art_cf_ohs.jpg 192x192.
```

#### `art_cf_ohs_1` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Barra bloqueada overhead, agarre ancho, de pie.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ohs image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Overhead squat. ASSET NAME: art_cf_ohs_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Barra bloqueada overhead, agarre ancho, de pie..
FIXED EQUIPMENT: one Olympic barbell with wide grip and matched plates.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and upper back; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ohs; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Barra bloqueada overhead, agarre ancho, de pie..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ohs_1.jpg 1024x1024 and matching thumbs/art_cf_ohs_1.jpg 192x192.
```

#### `art_cf_ohs_2` — FAIL

**Problema:** Sentadilla overhead profunda casi idéntica a paso 3

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Siéntate profundo manteniendo la barra activa.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ohs image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Overhead squat. ASSET NAME: art_cf_ohs_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Siéntate profundo manteniendo la barra activa..
FIXED EQUIPMENT: one Olympic barbell with wide grip and matched plates.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and upper back; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ohs; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Sentadilla overhead profunda casi idéntica a paso 3.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Siéntate profundo manteniendo la barra activa..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ohs_2.jpg 1024x1024 and matching thumbs/art_cf_ohs_2.jpg 192x192.
```

#### `art_cf_ohs_3` — FAIL

**Problema:** Repetición de posición final profunda en lugar de cambio articular claro

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Levántate sin perder el bloqueo.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ohs image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Overhead squat. ASSET NAME: art_cf_ohs_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Levántate sin perder el bloqueo..
FIXED EQUIPMENT: one Olympic barbell with wide grip and matched plates.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and upper back; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ohs; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Repetición de posición final profunda en lugar de cambio articular claro.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Levántate sin perder el bloqueo..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ohs_3.jpg 1024x1024 and matching thumbs/art_cf_ohs_3.jpg 192x192.
```


### 21. Push jerk — `art_cf_push_jerk`

- **Equipo obligatorio:** one Olympic barbell with matched plates; no rack.
- **Cámara fija:** fixed three-quarter front view.
- **Lime:** quadriceps, deltoids and triceps.
- **Sombra:** ground oval under both feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_push_jerk.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_push_jerk` — FAIL

**Problema:** Push jerk representado como split jerk con piernas alternadas

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_push_jerk image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Push jerk. ASSET NAME: art_cf_push_jerk. FRAME: representative hero.
EXACT JOINT/GEAR POSE: power jerk finish: arms locked overhead, feet PARALLEL and shoulder-width, knees flexed slightly in receiving position; NOT a split jerk.
FIXED EQUIPMENT: one Olympic barbell with matched plates; no rack.
LOCKED CAMERA AND LATERALITY: fixed three-quarter front view.
LIME MUSCLE FILL: quadriceps, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under both feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_push_jerk; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Push jerk representado como split jerk con piernas alternadas.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_push_jerk.jpg 1024x1024 and matching thumbs/art_cf_push_jerk.jpg 192x192.
```


### 22. Fondos en anillas — `art_cf_ring_dip`

- **Equipo obligatorio:** two identical gray gymnastics rings suspended from straps.
- **Cámara fija:** fixed side three-quarter view.
- **Lime:** triceps, chest and anterior deltoids.
- **Sombra:** NO floor oval or shadow.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_ring_dip.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_ring_dip` — FAIL

**Problema:** Fondo en anillas en el aire con óvalo de suelo

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ring_dip image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Fondos en anillas. ASSET NAME: art_cf_ring_dip. FRAME: representative hero.
EXACT JOINT/GEAR POSE: body held up above rings by locked elbows, rings at hips and feet fully suspended.
FIXED EQUIPMENT: two identical gray gymnastics rings suspended from straps.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: triceps, chest and anterior deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval or shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ring_dip; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Fondo en anillas en el aire con óvalo de suelo.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ring_dip.jpg 1024x1024 and matching thumbs/art_cf_ring_dip.jpg 192x192.
```

#### `art_cf_ring_dip_1` — FAIL

**Problema:** Sombra debajo de anillas en aire y pose duplicada con paso 3

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Soporte en anillas: brazos bloqueados, anillas junto a cadera.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ring_dip image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Fondos en anillas. ASSET NAME: art_cf_ring_dip_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Soporte en anillas: brazos bloqueados, anillas junto a cadera..
FIXED EQUIPMENT: two identical gray gymnastics rings suspended from straps.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: triceps, chest and anterior deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval or shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ring_dip; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Sombra debajo de anillas en aire y pose duplicada con paso 3.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Soporte en anillas: brazos bloqueados, anillas junto a cadera..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ring_dip_1.jpg 1024x1024 and matching thumbs/art_cf_ring_dip_1.jpg 192x192.
```

#### `art_cf_ring_dip_2` — FAIL

**Problema:** Óvalo de suelo bajo cuerpo suspendido de anillas

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Baja hasta hombros por debajo de los codos.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ring_dip image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Fondos en anillas. ASSET NAME: art_cf_ring_dip_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Baja hasta hombros por debajo de los codos..
FIXED EQUIPMENT: two identical gray gymnastics rings suspended from straps.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: triceps, chest and anterior deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval or shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ring_dip; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Óvalo de suelo bajo cuerpo suspendido de anillas.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Baja hasta hombros por debajo de los codos..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ring_dip_2.jpg 1024x1024 and matching thumbs/art_cf_ring_dip_2.jpg 192x192.
```

#### `art_cf_ring_dip_3` — FAIL

**Problema:** Sombra debajo de anillas en aire y pose duplicada con paso 1

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Empuja de nuevo a soporte bloqueado.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_ring_dip image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Fondos en anillas. ASSET NAME: art_cf_ring_dip_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Empuja de nuevo a soporte bloqueado..
FIXED EQUIPMENT: two identical gray gymnastics rings suspended from straps.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: triceps, chest and anterior deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval or shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_ring_dip; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Sombra debajo de anillas en aire y pose duplicada con paso 1.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Empuja de nuevo a soporte bloqueado..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_ring_dip_3.jpg 1024x1024 and matching thumbs/art_cf_ring_dip_3.jpg 192x192.
```


### 23. Rope climb — `art_cf_rope`

- **Equipo obligatorio:** one thick vertically hanging gym rope only.
- **Cámara fija:** fixed side three-quarter view; same rope position.
- **Lime:** lats, biceps, core and forearms.
- **Sombra:** NO floor shadow for athlete suspended.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_rope.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_rope` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_rope image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Rope climb. ASSET NAME: art_cf_rope. FRAME: representative hero.
EXACT JOINT/GEAR POSE: mid-ascent rope climb, feet locked around rope, hands staggered vertically, torso upright, no floor contact.
FIXED EQUIPMENT: one thick vertically hanging gym rope only.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view; same rope position.
LIME MUSCLE FILL: lats, biceps, core and forearms; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor shadow for athlete suspended. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_rope; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_rope.jpg 1024x1024 and matching thumbs/art_cf_rope.jpg 192x192.
```

#### `art_cf_rope_1` — FAIL

**Problema:** Sombra/óvalo bajo el escalador suspendido

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Salta y agarra la cuerda alto.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_rope image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Rope climb. ASSET NAME: art_cf_rope_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Salta y agarra la cuerda alto..
FIXED EQUIPMENT: one thick vertically hanging gym rope only.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view; same rope position.
LIME MUSCLE FILL: lats, biceps, core and forearms; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor shadow for athlete suspended. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_rope; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Sombra/óvalo bajo el escalador suspendido.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Salta y agarra la cuerda alto..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_rope_1.jpg 1024x1024 and matching thumbs/art_cf_rope_1.jpg 192x192.
```

#### `art_cf_rope_2` — FAIL

**Problema:** Óvalo de suelo bajo la fase de escalada en aire

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Enrola piernas (J-hook/wrap) y estira.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_rope image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Rope climb. ASSET NAME: art_cf_rope_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Enrola piernas (J-hook/wrap) y estira..
FIXED EQUIPMENT: one thick vertically hanging gym rope only.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view; same rope position.
LIME MUSCLE FILL: lats, biceps, core and forearms; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor shadow for athlete suspended. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_rope; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Óvalo de suelo bajo la fase de escalada en aire.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Enrola piernas (J-hook/wrap) y estira..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_rope_2.jpg 1024x1024 and matching thumbs/art_cf_rope_2.jpg 192x192.
```

#### `art_cf_rope_3` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Sube a tramos y baja controlado.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_rope image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Rope climb. ASSET NAME: art_cf_rope_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Sube a tramos y baja controlado..
FIXED EQUIPMENT: one thick vertically hanging gym rope only.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view; same rope position.
LIME MUSCLE FILL: lats, biceps, core and forearms; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor shadow for athlete suspended. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_rope; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Sube a tramos y baja controlado..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_rope_3.jpg 1024x1024 and matching thumbs/art_cf_rope_3.jpg 192x192.
```


### 24. Sandbag over shoulder — `art_cf_sb_os`

- **Equipo obligatorio:** one dark charcoal cylindrical sandbag, no other equipment.
- **Cámara fija:** fixed side view facing RIGHT.
- **Lime:** glutes, traps and core.
- **Sombra:** ground oval under feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_sb_os.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_sb_os` — FAIL

**Problema:** Sandbag over shoulder dibujado como saco en hombros sin fase de lanzamiento

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_sb_os image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Sandbag over shoulder. ASSET NAME: art_cf_sb_os. FRAME: representative hero.
EXACT JOINT/GEAR POSE: sandbag being driven up and behind ONE shoulder, hips extended, torso braced, clear throw trajectory.
FIXED EQUIPMENT: one dark charcoal cylindrical sandbag, no other equipment.
LOCKED CAMERA AND LATERALITY: fixed side view facing RIGHT.
LIME MUSCLE FILL: glutes, traps and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_sb_os; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Sandbag over shoulder dibujado como saco en hombros sin fase de lanzamiento.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_sb_os.jpg 1024x1024 and matching thumbs/art_cf_sb_os.jpg 192x192.
```


### 25. SkiErg — `art_cf_skierg`

- **Equipo obligatorio:** single authentic upright SkiErg machine with two cables and handles.
- **Cámara fija:** fixed side three-quarter view.
- **Lime:** lats, abdominals and triceps.
- **Sombra:** shadow beneath feet and anchored machine.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_skierg.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_skierg` — WARN

**Problema:** Equipo SkiErg representado con plataforma y rueda de aspecto confuso

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_skierg image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: SkiErg. ASSET NAME: art_cf_skierg. FRAME: representative hero.
EXACT JOINT/GEAR POSE: athlete pulling TWO handles downward toward thighs from overhead, hinged at hips, no seated rowing or stationary bicycle.
FIXED EQUIPMENT: single authentic upright SkiErg machine with two cables and handles.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: lats, abdominals and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow beneath feet and anchored machine. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_skierg; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Equipo SkiErg representado con plataforma y rueda de aspecto confuso.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_skierg.jpg 1024x1024 and matching thumbs/art_cf_skierg.jpg 192x192.
```


### 26. Sled pull — `art_cf_sled_pull`

- **Equipo obligatorio:** one weighted sled with rope stretched from athlete to sled.
- **Cámara fija:** fixed side view facing RIGHT.
- **Lime:** lats, biceps, quads and glutes.
- **Sombra:** shadow under sled and contacting feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_sled_pull.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_sled_pull` — FAIL

**Problema:** Sled pull mostrado como empuje de trineo con las manos

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_sled_pull image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Sled pull. ASSET NAME: art_cf_sled_pull. FRAME: representative hero.
EXACT JOINT/GEAR POSE: athlete facing the sled and pulling attached rope hand over hand with backward lean and heels planted; not pushing the sled.
FIXED EQUIPMENT: one weighted sled with rope stretched from athlete to sled.
LOCKED CAMERA AND LATERALITY: fixed side view facing RIGHT.
LIME MUSCLE FILL: lats, biceps, quads and glutes; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow under sled and contacting feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_sled_pull; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Sled pull mostrado como empuje de trineo con las manos.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_sled_pull.jpg 1024x1024 and matching thumbs/art_cf_sled_pull.jpg 192x192.
```


### 27. Split jerk — `art_cf_split_jerk`

- **Equipo obligatorio:** one Olympic barbell with matched plates.
- **Cámara fija:** fixed three-quarter side view; LEFT leg forward in every frame.
- **Lime:** quadriceps, glutes, deltoids and triceps.
- **Sombra:** shadow under planted feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_split_jerk.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_split_jerk` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_split_jerk image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Split jerk. ASSET NAME: art_cf_split_jerk. FRAME: representative hero.
EXACT JOINT/GEAR POSE: split jerk finish: one foot in front, other behind, arms locked overhead and body aligned vertically.
FIXED EQUIPMENT: one Olympic barbell with matched plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view; LEFT leg forward in every frame.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_split_jerk; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_split_jerk.jpg 1024x1024 and matching thumbs/art_cf_split_jerk.jpg 192x192.
```

#### `art_cf_split_jerk_1` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Front rack, dip corto de piernas.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_split_jerk image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Split jerk. ASSET NAME: art_cf_split_jerk_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Front rack, dip corto de piernas..
FIXED EQUIPMENT: one Olympic barbell with matched plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view; LEFT leg forward in every frame.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_split_jerk; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Front rack, dip corto de piernas..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_split_jerk_1.jpg 1024x1024 and matching thumbs/art_cf_split_jerk_1.jpg 192x192.
```

#### `art_cf_split_jerk_2` — FAIL

**Problema:** Fase final split overhead casi idéntica al paso 3

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Drive y split: un pie delante, otro atrás, brazos bloqueados overhead.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_split_jerk image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Split jerk. ASSET NAME: art_cf_split_jerk_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Drive y split: un pie delante, otro atrás, brazos bloqueados overhead..
FIXED EQUIPMENT: one Olympic barbell with matched plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view; LEFT leg forward in every frame.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_split_jerk; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Fase final split overhead casi idéntica al paso 3.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Drive y split: un pie delante, otro atrás, brazos bloqueados overhead..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_split_jerk_2.jpg 1024x1024 and matching thumbs/art_cf_split_jerk_2.jpg 192x192.
```

#### `art_cf_split_jerk_3` — FAIL

**Problema:** Repetición de split overhead del paso 2; falta fase diferenciada

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Recupera pie delantero y luego el trasero bajo la barra.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_split_jerk image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Split jerk. ASSET NAME: art_cf_split_jerk_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Recupera pie delantero y luego el trasero bajo la barra..
FIXED EQUIPMENT: one Olympic barbell with matched plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view; LEFT leg forward in every frame.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_split_jerk; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Repetición de split overhead del paso 2; falta fase diferenciada.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Recupera pie delantero y luego el trasero bajo la barra..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_split_jerk_3.jpg 1024x1024 and matching thumbs/art_cf_split_jerk_3.jpg 192x192.
```


### 28. Simples de comba — `art_cf_su`

- **Equipo obligatorio:** jump rope with both handles and continuous thin rope, no other gear.
- **Cámara fija:** fixed frontal three-quarter view.
- **Lime:** calves, forearms and deltoids.
- **Sombra:** NO floor oval or floor shadow mid-jump.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_su.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_su` — FAIL

**Problema:** Salto a la comba con óvalo/sombra mientras está suspendido

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_su image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Simples de comba. ASSET NAME: art_cf_su. FRAME: representative hero.
EXACT JOINT/GEAR POSE: single-under rope jump in mid-air, feet together slightly off floor, rope traveling beneath shoes.
FIXED EQUIPMENT: jump rope with both handles and continuous thin rope, no other gear.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: calves, forearms and deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval or floor shadow mid-jump. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_su; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Salto a la comba con óvalo/sombra mientras está suspendido.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_su.jpg 1024x1024 and matching thumbs/art_cf_su.jpg 192x192.
```


### 29. Sumo high pull — `art_cf_sumo_hp`

- **Equipo obligatorio:** one standard Olympic barbell with narrow grip and matched discs.
- **Cámara fija:** fixed frontal three-quarter view.
- **Lime:** glutes, quads, trapezius and deltoids.
- **Sombra:** ground oval under planted feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_sumo_hp.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_sumo_hp` — FAIL

**Problema:** Sumo deadlift high pull representado como sentadilla overhead

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_sumo_hp image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Sumo high pull. ASSET NAME: art_cf_sumo_hp. FRAME: representative hero.
EXACT JOINT/GEAR POSE: sumo deadlift high pull: wide feet planted, bar pulled vertically to upper chest and elbows above wrists, NOT overhead squat.
FIXED EQUIPMENT: one standard Olympic barbell with narrow grip and matched discs.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: glutes, quads, trapezius and deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_sumo_hp; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Sumo deadlift high pull representado como sentadilla overhead.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_sumo_hp.jpg 1024x1024 and matching thumbs/art_cf_sumo_hp.jpg 192x192.
```


### 30. Turkish get-up — `art_cf_tgu`

- **Equipo obligatorio:** one single kettlebell always in RIGHT hand.
- **Cámara fija:** fixed side three-quarter view facing RIGHT; same working side.
- **Lime:** shoulder stabilizers, obliques and glutes.
- **Sombra:** soft oval only under supported body parts.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_tgu.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_tgu` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_tgu image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Turkish get-up. ASSET NAME: art_cf_tgu. FRAME: representative hero.
EXACT JOINT/GEAR POSE: Turkish get-up finishing upright, right arm locked vertically overhead and other arm down, kettlebell never changes hands.
FIXED EQUIPMENT: one single kettlebell always in RIGHT hand.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view facing RIGHT; same working side.
LIME MUSCLE FILL: shoulder stabilizers, obliques and glutes; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval only under supported body parts. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_tgu; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_tgu.jpg 1024x1024 and matching thumbs/art_cf_tgu.jpg 192x192.
```

#### `art_cf_tgu_1` — FAIL

**Problema:** Mancuerna en vez de la kettlebell de los pasos siguientes

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Túmbate y mantén una kettlebell sobre el hombro con el brazo totalmente extendido.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_tgu image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Turkish get-up. ASSET NAME: art_cf_tgu_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Túmbate y mantén una kettlebell sobre el hombro con el brazo totalmente extendido..
FIXED EQUIPMENT: one single kettlebell always in RIGHT hand.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view facing RIGHT; same working side.
LIME MUSCLE FILL: shoulder stabilizers, obliques and glutes; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval only under supported body parts. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_tgu; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Mancuerna en vez de la kettlebell de los pasos siguientes.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Túmbate y mantén una kettlebell sobre el hombro con el brazo totalmente extendido..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_tgu_1.jpg 1024x1024 and matching thumbs/art_cf_tgu_1.jpg 192x192.
```

#### `art_cf_tgu_2` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Apoya la mano libre, eleva la cadera y mantén la kettlebell vertical.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_tgu image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Turkish get-up. ASSET NAME: art_cf_tgu_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Apoya la mano libre, eleva la cadera y mantén la kettlebell vertical..
FIXED EQUIPMENT: one single kettlebell always in RIGHT hand.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view facing RIGHT; same working side.
LIME MUSCLE FILL: shoulder stabilizers, obliques and glutes; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval only under supported body parts. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_tgu; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Apoya la mano libre, eleva la cadera y mantén la kettlebell vertical..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_tgu_2.jpg 1024x1024 and matching thumbs/art_cf_tgu_2.jpg 192x192.
```

#### `art_cf_tgu_3` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Termina de pie con el mismo brazo bloqueado y la kettlebell sobre la cabeza.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_tgu image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Turkish get-up. ASSET NAME: art_cf_tgu_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Termina de pie con el mismo brazo bloqueado y la kettlebell sobre la cabeza..
FIXED EQUIPMENT: one single kettlebell always in RIGHT hand.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view facing RIGHT; same working side.
LIME MUSCLE FILL: shoulder stabilizers, obliques and glutes; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval only under supported body parts. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_tgu; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Termina de pie con el mismo brazo bloqueado y la kettlebell sobre la cabeza..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_tgu_3.jpg 1024x1024 and matching thumbs/art_cf_tgu_3.jpg 192x192.
```


### 31. Thruster — `art_cf_thruster`

- **Equipo obligatorio:** one Olympic barbell with matched charcoal plates, always same physical bar.
- **Cámara fija:** fixed frontal three-quarter view.
- **Lime:** quadriceps, glutes, deltoids and triceps.
- **Sombra:** ground oval under planted feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_thruster.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_thruster` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_thruster image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Thruster. ASSET NAME: art_cf_thruster. FRAME: representative hero.
EXACT JOINT/GEAR POSE: full standing thruster finished with barbell locked straight overhead, arms fully extended and feet planted.
FIXED EQUIPMENT: one Olympic barbell with matched charcoal plates, always same physical bar.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_thruster; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_thruster.jpg 1024x1024 and matching thumbs/art_cf_thruster.jpg 192x192.
```

#### `art_cf_thruster_1` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Sujeta la barra delante de los hombros y desciende hasta una sentadilla frontal.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_thruster image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Thruster. ASSET NAME: art_cf_thruster_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Sujeta la barra delante de los hombros y desciende hasta una sentadilla frontal..
FIXED EQUIPMENT: one Olympic barbell with matched charcoal plates, always same physical bar.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_thruster; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Sujeta la barra delante de los hombros y desciende hasta una sentadilla frontal..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_thruster_1.jpg 1024x1024 and matching thumbs/art_cf_thruster_1.jpg 192x192.
```

#### `art_cf_thruster_2` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Extiende caderas y rodillas al subir, manteniendo la barra sobre los hombros.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_thruster image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Thruster. ASSET NAME: art_cf_thruster_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Extiende caderas y rodillas al subir, manteniendo la barra sobre los hombros..
FIXED EQUIPMENT: one Olympic barbell with matched charcoal plates, always same physical bar.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_thruster; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Extiende caderas y rodillas al subir, manteniendo la barra sobre los hombros..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_thruster_2.jpg 1024x1024 and matching thumbs/art_cf_thruster_2.jpg 192x192.
```

#### `art_cf_thruster_3` — FAIL

**Problema:** Mancuernas en el bloqueo de un thruster con barra

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Impulsa la misma barra sobre la cabeza hasta extender los brazos por completo.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_thruster image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Thruster. ASSET NAME: art_cf_thruster_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Impulsa la misma barra sobre la cabeza hasta extender los brazos por completo..
FIXED EQUIPMENT: one Olympic barbell with matched charcoal plates, always same physical bar.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_thruster; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Mancuernas en el bloqueo de un thruster con barra.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Impulsa la misma barra sobre la cabeza hasta extender los brazos por completo..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_thruster_3.jpg 1024x1024 and matching thumbs/art_cf_thruster_3.jpg 192x192.
```


### 32. Triples de comba — `art_cf_tu`

- **Equipo obligatorio:** one ordinary jump rope with two handles and continuous rope.
- **Cámara fija:** fixed frontal three-quarter view.
- **Lime:** calves, wrists and shoulders.
- **Sombra:** NO ground shadow while airborne.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_tu.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_tu` — FAIL

**Problema:** Triple under con sombra de suelo mientras salta

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_tu image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Triples de comba. ASSET NAME: art_cf_tu. FRAME: representative hero.
EXACT JOINT/GEAR POSE: triple-under jump at peak in flight with legs together and rope arcing rapidly around athlete.
FIXED EQUIPMENT: one ordinary jump rope with two handles and continuous rope.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: calves, wrists and shoulders; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground shadow while airborne. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_tu; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Triple under con sombra de suelo mientras salta.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_tu.jpg 1024x1024 and matching thumbs/art_cf_tu.jpg 192x192.
```


### 33. Wall ball — `art_cf_wall_ball`

- **Equipo obligatorio:** one dark gray soft medicine ball; plain charcoal wall and visible round target.
- **Cámara fija:** fixed side three-quarter view oriented toward wall at RIGHT.
- **Lime:** quadriceps, glutes, deltoids and triceps.
- **Sombra:** shadow only when feet on floor.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_wall_ball.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_wall_ball` — WARN

**Problema:** Falta muro y diana en el hero

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_wall_ball image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Wall ball. ASSET NAME: art_cf_wall_ball. FRAME: representative hero.
EXACT JOINT/GEAR POSE: wall ball athlete in squatting catch or rising to throw, ball aligned to round target.
FIXED EQUIPMENT: one dark gray soft medicine ball; plain charcoal wall and visible round target.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view oriented toward wall at RIGHT.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow only when feet on floor. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_wall_ball; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Falta muro y diana en el hero.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_wall_ball.jpg 1024x1024 and matching thumbs/art_cf_wall_ball.jpg 192x192.
```

#### `art_cf_wall_ball_1` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Sujeta el balón frente al pecho y baja a sentadilla mirando la diana.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_wall_ball image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Wall ball. ASSET NAME: art_cf_wall_ball_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: Sujeta el balón frente al pecho y baja a sentadilla mirando la diana..
FIXED EQUIPMENT: one dark gray soft medicine ball; plain charcoal wall and visible round target.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view oriented toward wall at RIGHT.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow only when feet on floor. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_wall_ball; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Sujeta el balón frente al pecho y baja a sentadilla mirando la diana..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_wall_ball_1.jpg 1024x1024 and matching thumbs/art_cf_wall_ball_1.jpg 192x192.
```

#### `art_cf_wall_ball_2` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Extiende las piernas y lanza el balón hacia la diana con ambos brazos.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_wall_ball image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Wall ball. ASSET NAME: art_cf_wall_ball_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Extiende las piernas y lanza el balón hacia la diana con ambos brazos..
FIXED EQUIPMENT: one dark gray soft medicine ball; plain charcoal wall and visible round target.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view oriented toward wall at RIGHT.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow only when feet on floor. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_wall_ball; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Extiende las piernas y lanza el balón hacia la diana con ambos brazos..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_wall_ball_2.jpg 1024x1024 and matching thumbs/art_cf_wall_ball_2.jpg 192x192.
```

#### `art_cf_wall_ball_3` — WARN

**Problema:** Cambio de plano y balón alto; revisar fase de recepción

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Alza las manos y recibe el balón frente a la diana antes de volver a bajar.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_wall_ball image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Wall ball. ASSET NAME: art_cf_wall_ball_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Alza las manos y recibe el balón frente a la diana antes de volver a bajar..
FIXED EQUIPMENT: one dark gray soft medicine ball; plain charcoal wall and visible round target.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view oriented toward wall at RIGHT.
LIME MUSCLE FILL: quadriceps, glutes, deltoids and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow only when feet on floor. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_wall_ball; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Cambio de plano y balón alto; revisar fase de recepción.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Alza las manos y recibe el balón frente a la diana antes de volver a bajar..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_wall_ball_3.jpg 1024x1024 and matching thumbs/art_cf_wall_ball_3.jpg 192x192.
```


### 34. Yoke carry — `art_cf_yoke`

- **Equipo obligatorio:** real YOKE strongman frame with two vertical columns, crossbar, matched weight plates.
- **Cámara fija:** fixed frontal three-quarter view.
- **Lime:** quads, glutes, traps and core.
- **Sombra:** shadow below feet and yoke feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_cf_yoke.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_cf_yoke` — FAIL

**Problema:** Yoke carry representado con barra de pesas ordinaria sin yoke

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_cf_yoke image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Yoke carry. ASSET NAME: art_cf_yoke. FRAME: representative hero.
EXACT JOINT/GEAR POSE: athlete walking under yoke crossbar at upper back/shoulders while entire frame surrounds torso, not ordinary barbell.
FIXED EQUIPMENT: real YOKE strongman frame with two vertical columns, crossbar, matched weight plates.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: quads, glutes, traps and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow below feet and yoke feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_cf_yoke; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Yoke carry representado con barra de pesas ordinaria sin yoke.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_cf_yoke.jpg 1024x1024 and matching thumbs/art_cf_yoke.jpg 192x192.
```


### 35. Curl femoral — `art_curl_femoral`

- **Equipo obligatorio:** prone hamstring curl bench with ankle roller and padded supports.
- **Cámara fija:** fixed strict side view.
- **Lime:** hamstrings ONLY in lime, NO RED.
- **Sombra:** soft oval beneath bench.
- **Referencias:** `art_ab_wheel.jpg`, `art_curl_femoral.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_curl_femoral` — FAIL

**Problema:** Resaltado rojo no permitido; solo se admite lime

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_curl_femoral image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Curl femoral. ASSET NAME: art_curl_femoral. FRAME: representative hero.
EXACT JOINT/GEAR POSE: lying FACE DOWN on prone leg curl machine, knees flexed and ankles pressing roller upward toward glutes.
FIXED EQUIPMENT: prone hamstring curl bench with ankle roller and padded supports.
LOCKED CAMERA AND LATERALITY: fixed strict side view.
LIME MUSCLE FILL: hamstrings ONLY in lime, NO RED; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval beneath bench. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_curl_femoral; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Resaltado rojo no permitido; solo se admite lime.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_curl_femoral.jpg 1024x1024 and matching thumbs/art_curl_femoral.jpg 192x192.
```


### 36. Curl mancuernas — `art_curl_mancuernas`

- **Equipo obligatorio:** two individual gray dumbbells in each hand.
- **Cámara fija:** fixed frontal three-quarter view.
- **Lime:** biceps brachii and brachialis.
- **Sombra:** ground oval under feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_curl_mancuernas.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_curl_mancuernas` — FAIL

**Problema:** Curl mostrado con manos altas en postura de press de hombros

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_curl_mancuernas image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Curl mancuernas. ASSET NAME: art_curl_mancuernas. FRAME: representative hero.
EXACT JOINT/GEAR POSE: standing dumbbell curls with elbows close to sides, palms facing forward, dumbbells near lower chest; NOT overhead press.
FIXED EQUIPMENT: two individual gray dumbbells in each hand.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: biceps brachii and brachialis; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_curl_mancuernas; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Curl mostrado con manos altas en postura de press de hombros.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_curl_mancuernas.jpg 1024x1024 and matching thumbs/art_curl_mancuernas.jpg 192x192.
```


### 37. Curl martillo — `art_curl_martillo`

- **Equipo obligatorio:** two gray dumbbells in neutral hammer grip.
- **Cámara fija:** fixed frontal three-quarter view.
- **Lime:** brachialis, brachioradialis and biceps.
- **Sombra:** ground oval under feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_curl_martillo.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_curl_martillo` — FAIL

**Problema:** Curl martillo dibujado en postura de press de hombros

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_curl_martillo image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Curl martillo. ASSET NAME: art_curl_martillo. FRAME: representative hero.
EXACT JOINT/GEAR POSE: standing hammer curl with palms facing INWARD, elbows beside torso and dumbbells rising toward shoulders.
FIXED EQUIPMENT: two gray dumbbells in neutral hammer grip.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: brachialis, brachioradialis and biceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_curl_martillo; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Curl martillo dibujado en postura de press de hombros.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_curl_martillo.jpg 1024x1024 and matching thumbs/art_curl_martillo.jpg 192x192.
```


### 38. Elevaciones laterales — `art_elevaciones_laterales`

- **Equipo obligatorio:** two identical dumbbells in hands.
- **Cámara fija:** fixed frontal view.
- **Lime:** lateral deltoids.
- **Sombra:** ground oval under feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_elevaciones_laterales.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_elevaciones_laterales` — FAIL

**Problema:** Elevación lateral dibujada como press de hombros

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_elevaciones_laterales image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Elevaciones laterales. ASSET NAME: art_elevaciones_laterales. FRAME: representative hero.
EXACT JOINT/GEAR POSE: standing lateral raise with arms out to sides at shoulder level, softly bent elbows and thumbs neutral; NOT overhead press.
FIXED EQUIPMENT: two identical dumbbells in hands.
LOCKED CAMERA AND LATERALITY: fixed frontal view.
LIME MUSCLE FILL: lateral deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_elevaciones_laterales; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Elevación lateral dibujada como press de hombros.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_elevaciones_laterales.jpg 1024x1024 and matching thumbs/art_elevaciones_laterales.jpg 192x192.
```


### 39. Extensión de cuádriceps — `art_extension_cuad`

- **Equipo obligatorio:** proper seated leg extension machine with shin pad and backrest.
- **Cámara fija:** fixed three-quarter side view.
- **Lime:** quadriceps ONLY, not abs.
- **Sombra:** shadow below machine.
- **Referencias:** `art_ab_wheel.jpg`, `art_extension_cuad.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_extension_cuad` — WARN

**Problema:** Resaltado lime alcanza abdomen además de cuádriceps

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_extension_cuad image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Extensión de cuádriceps. ASSET NAME: art_extension_cuad. FRAME: representative hero.
EXACT JOINT/GEAR POSE: athlete seated against backrest, legs extended at knee and shins lifting roller pad.
FIXED EQUIPMENT: proper seated leg extension machine with shin pad and backrest.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view.
LIME MUSCLE FILL: quadriceps ONLY, not abs; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow below machine. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_extension_cuad; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Resaltado lime alcanza abdomen además de cuádriceps.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_extension_cuad.jpg 1024x1024 and matching thumbs/art_extension_cuad.jpg 192x192.
```


### 40. Fondos — `art_fondos`

- **Equipo obligatorio:** two parallel dip bars only, NO cable machine.
- **Cámara fija:** fixed three-quarter side view.
- **Lime:** triceps, pectorals and deltoids.
- **Sombra:** NO floor oval if feet suspended.
- **Referencias:** `art_ab_wheel.jpg`, `art_fondos.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_fondos` — FAIL

**Problema:** Fondos sustituidos por jalón de tríceps en polea

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_fondos image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Fondos. ASSET NAME: art_fondos. FRAME: representative hero.
EXACT JOINT/GEAR POSE: athlete on parallel bars, shoulders over hands, elbows bent midway through body-weight dip with feet suspended.
FIXED EQUIPMENT: two parallel dip bars only, NO cable machine.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view.
LIME MUSCLE FILL: triceps, pectorals and deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval if feet suspended. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_fondos; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Fondos sustituidos por jalón de tríceps en polea.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_fondos.jpg 1024x1024 and matching thumbs/art_fondos.jpg 192x192.
```


### 41. Elevación de gemelos — `art_gemelos`

- **Equipo obligatorio:** one stable weighted barbell in back-rack over shoulders and low calf step.
- **Cámara fija:** fixed strict side view.
- **Lime:** gastrocnemius and soleus ONLY in lime.
- **Sombra:** oval shadow under raised step.
- **Referencias:** `art_ab_wheel.jpg`, `art_gemelos.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gemelos` — WARN

**Problema:** Resaltado lime excesivo en espalda/brazos para elevación de gemelos

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gemelos image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Elevación de gemelos. ASSET NAME: art_gemelos. FRAME: representative hero.
EXACT JOINT/GEAR POSE: standing calf raise on raised step with heels above edge, rising onto toes; straight legs.
FIXED EQUIPMENT: one stable weighted barbell in back-rack over shoulders and low calf step.
LOCKED CAMERA AND LATERALITY: fixed strict side view.
LIME MUSCLE FILL: gastrocnemius and soleus ONLY in lime; nothing else highlighted in lime.
CONTACT / SHADOW RULE: oval shadow under raised step. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gemelos; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Resaltado lime excesivo en espalda/brazos para elevación de gemelos.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gemelos.jpg 1024x1024 and matching thumbs/art_gemelos.jpg 192x192.
```


### 42. Arch hold — `art_gy_arch`

- **Equipo obligatorio:** NO equipment; plain empty floor.
- **Cámara fija:** fixed side view.
- **Lime:** erector spinae, glutes and posterior deltoids.
- **Sombra:** subtle oval beneath torso touching floor.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_arch.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_arch` — FAIL

**Problema:** Arch hold de suelo sustituido por elevación de piernas colgado

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_arch image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Arch hold. ASSET NAME: art_gy_arch. FRAME: representative hero.
EXACT JOINT/GEAR POSE: ARCH HOLD on stomach: chest and thighs lifted slightly from floor, arms extended overhead, legs extended behind; NOT hanging from bar.
FIXED EQUIPMENT: NO equipment; plain empty floor.
LOCKED CAMERA AND LATERALITY: fixed side view.
LIME MUSCLE FILL: erector spinae, glutes and posterior deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: subtle oval beneath torso touching floor. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_arch; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Arch hold de suelo sustituido por elevación de piernas colgado.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_arch.jpg 1024x1024 and matching thumbs/art_gy_arch.jpg 192x192.
```


### 43. Archer pull-up — `art_gy_archer`

- **Equipo obligatorio:** one fixed pull-up bar with supports.
- **Cámara fija:** fixed frontal view.
- **Lime:** lats, biceps and rear deltoids.
- **Sombra:** NO floor shadow for hanging figure.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_archer.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_archer` — FAIL

**Problema:** Archer pull-up con ambos codos flexionados; falta brazo recto

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_archer image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Archer pull-up. ASSET NAME: art_gy_archer. FRAME: representative hero.
EXACT JOINT/GEAR POSE: archer pull-up at top: one elbow deeply flexed and shoulder toward gripping hand, opposite arm STRAIGHT along bar, feet suspended.
FIXED EQUIPMENT: one fixed pull-up bar with supports.
LOCKED CAMERA AND LATERALITY: fixed frontal view.
LIME MUSCLE FILL: lats, biceps and rear deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor shadow for hanging figure. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_archer; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Archer pull-up con ambos codos flexionados; falta brazo recto.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_archer.jpg 1024x1024 and matching thumbs/art_gy_archer.jpg 192x192.
```


### 44. Candlestick — `art_gy_candle`

- **Equipo obligatorio:** no equipment, no wall, no bars.
- **Cámara fija:** fixed side view.
- **Lime:** abdominals and hip flexors.
- **Sombra:** floor oval under shoulders.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_candle.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_candle` — FAIL

**Problema:** Candlestick sobre suelo mostrado como parada de manos

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_candle image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Candlestick. ASSET NAME: art_gy_candle. FRAME: representative hero.
EXACT JOINT/GEAR POSE: candlestick supine on floor with legs together pointing vertically overhead, shoulders and upper back grounded, hips elevated.
FIXED EQUIPMENT: no equipment, no wall, no bars.
LOCKED CAMERA AND LATERALITY: fixed side view.
LIME MUSCLE FILL: abdominals and hip flexors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under shoulders. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_candle; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Candlestick sobre suelo mostrado como parada de manos.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_candle.jpg 1024x1024 and matching thumbs/art_gy_candle.jpg 192x192.
```


### 45. False grip hang — `art_gy_false_grip`

- **Equipo obligatorio:** two GRAY gymnastic rings and matching gray straps.
- **Cámara fija:** fixed three-quarter front view.
- **Lime:** forearms, wrist flexors and lats.
- **Sombra:** NO ground oval or shadow.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_false_grip.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_false_grip` — WARN

**Problema:** Anillas doradas en vez de grises canónicos

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_false_grip image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: False grip hang. ASSET NAME: art_gy_false_grip. FRAME: representative hero.
EXACT JOINT/GEAR POSE: hanging from rings using false grip with wrists folded above the rings and arms long; feet not touching floor.
FIXED EQUIPMENT: two GRAY gymnastic rings and matching gray straps.
LOCKED CAMERA AND LATERALITY: fixed three-quarter front view.
LIME MUSCLE FILL: forearms, wrist flexors and lats; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground oval or shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_false_grip; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Anillas doradas en vez de grises canónicos.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_false_grip.jpg 1024x1024 and matching thumbs/art_gy_false_grip.jpg 192x192.
```


### 46. Front lever tuck — `art_gy_front_lev`

- **Equipo obligatorio:** one fixed overhead horizontal pull-up bar.
- **Cámara fija:** fixed side view.
- **Lime:** lats, abdominals and glutes.
- **Sombra:** NO floor oval or shadow.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_front_lev.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_front_lev` — FAIL

**Problema:** Front lever en suspensión con óvalo de sombra de suelo

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_front_lev image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Front lever tuck. ASSET NAME: art_gy_front_lev. FRAME: representative hero.
EXACT JOINT/GEAR POSE: front lever tuck: body hanging horizontally from straight arms, hips lifted and knees tucked while shoulders stay engaged.
FIXED EQUIPMENT: one fixed overhead horizontal pull-up bar.
LOCKED CAMERA AND LATERALITY: fixed side view.
LIME MUSCLE FILL: lats, abdominals and glutes; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval or shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_front_lev; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Front lever en suspensión con óvalo de sombra de suelo.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_front_lev.jpg 1024x1024 and matching thumbs/art_gy_front_lev.jpg 192x192.
```


### 47. GHD back extension — `art_gy_ghd_back`

- **Equipo obligatorio:** one GHD bench with hip pad and ankle/foot rollers, no barbell.
- **Cámara fija:** fixed side view.
- **Lime:** erector spinae and glutes.
- **Sombra:** ground shadow only below apparatus.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_ghd_back.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_ghd_back` — FAIL

**Problema:** Extensión GHD representada con barra de pesas elevada y banco equivocado

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_ghd_back image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: GHD back extension. ASSET NAME: art_gy_ghd_back. FRAME: representative hero.
EXACT JOINT/GEAR POSE: GHD back extension with ankles secured and hips supported, torso hinged forward then straightened level, no overhead bar.
FIXED EQUIPMENT: one GHD bench with hip pad and ankle/foot rollers, no barbell.
LOCKED CAMERA AND LATERALITY: fixed side view.
LIME MUSCLE FILL: erector spinae and glutes; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground shadow only below apparatus. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_ghd_back; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Extensión GHD representada con barra de pesas elevada y banco equivocado.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_ghd_back.jpg 1024x1024 and matching thumbs/art_gy_ghd_back.jpg 192x192.
```


### 48. Hollow hold — `art_gy_hollow_hold`

- **Equipo obligatorio:** no equipment, simple floor.
- **Cámara fija:** fixed side view.
- **Lime:** rectus abdominis and obliques.
- **Sombra:** small soft floor shadow beneath back.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_hollow_hold.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_hollow_hold` — WARN

**Problema:** Piernas parecen apoyadas en hollow hold, revisar

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_hollow_hold image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Hollow hold. ASSET NAME: art_gy_hollow_hold. FRAME: representative hero.
EXACT JOINT/GEAR POSE: static hollow hold lying face up with shoulders raised, lumbar region pressed into floor and arms/legs extended OFF floor.
FIXED EQUIPMENT: no equipment, simple floor.
LOCKED CAMERA AND LATERALITY: fixed side view.
LIME MUSCLE FILL: rectus abdominis and obliques; nothing else highlighted in lime.
CONTACT / SHADOW RULE: small soft floor shadow beneath back. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_hollow_hold; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Piernas parecen apoyadas en hollow hold, revisar.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_hollow_hold.jpg 1024x1024 and matching thumbs/art_gy_hollow_hold.jpg 192x192.
```


### 49. Jumping lunge — `art_gy_jump_lunge`

- **Equipo obligatorio:** no equipment.
- **Cámara fija:** fixed side view facing RIGHT.
- **Lime:** quadriceps and glutes.
- **Sombra:** NO floor shadow in mid-air.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_jump_lunge.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_jump_lunge` — WARN

**Problema:** Revisar sombra y postura de salto en jump lunge

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_jump_lunge image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Jumping lunge. ASSET NAME: art_gy_jump_lunge. FRAME: representative hero.
EXACT JOINT/GEAR POSE: mid-air jump lunge switching legs, front/back knees bent, feet fully detached from floor.
FIXED EQUIPMENT: no equipment.
LOCKED CAMERA AND LATERALITY: fixed side view facing RIGHT.
LIME MUSCLE FILL: quadriceps and glutes; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor shadow in mid-air. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_jump_lunge; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Revisar sombra y postura de salto en jump lunge.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_jump_lunge.jpg 1024x1024 and matching thumbs/art_gy_jump_lunge.jpg 192x192.
```


### 50. Fondos en paralelas — `art_gy_pb_dip`

- **Equipo obligatorio:** one fixed set of parallel dip bars, same geometry and height throughout.
- **Cámara fija:** fixed strict side view.
- **Lime:** triceps, chest and anterior deltoids.
- **Sombra:** NO ground oval for suspended body.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_pb_dip.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_pb_dip` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_pb_dip image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Fondos en paralelas. ASSET NAME: art_gy_pb_dip. FRAME: representative hero.
EXACT JOINT/GEAR POSE: body supported on two parallel bars with elbows straight, shoulders stable, feet suspended behind.
FIXED EQUIPMENT: one fixed set of parallel dip bars, same geometry and height throughout.
LOCKED CAMERA AND LATERALITY: fixed strict side view.
LIME MUSCLE FILL: triceps, chest and anterior deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground oval for suspended body. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_pb_dip; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_pb_dip.jpg 1024x1024 and matching thumbs/art_gy_pb_dip.jpg 192x192.
```

#### `art_gy_pb_dip_1` — WARN

**Problema:** Cámara y barras no consistentes con el paso 2

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Sujeta las paralelas con brazos extendidos, hombros estables y pies suspendidos.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_pb_dip image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Fondos en paralelas. ASSET NAME: art_gy_pb_dip_1. FRAME: step 1 of 2.
EXACT JOINT/GEAR POSE: Sujeta las paralelas con brazos extendidos, hombros estables y pies suspendidos..
FIXED EQUIPMENT: one fixed set of parallel dip bars, same geometry and height throughout.
LOCKED CAMERA AND LATERALITY: fixed strict side view.
LIME MUSCLE FILL: triceps, chest and anterior deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground oval for suspended body. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_pb_dip; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Cámara y barras no consistentes con el paso 2.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Sujeta las paralelas con brazos extendidos, hombros estables y pies suspendidos..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_pb_dip_1.jpg 1024x1024 and matching thumbs/art_gy_pb_dip_1.jpg 192x192.
```

#### `art_gy_pb_dip_2` — WARN

**Problema:** Cámara y barras no consistentes con el paso 1

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Flexiona los codos y baja el torso entre las barras sin apoyar los pies.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_pb_dip image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Fondos en paralelas. ASSET NAME: art_gy_pb_dip_2. FRAME: step 2 of 2.
EXACT JOINT/GEAR POSE: Flexiona los codos y baja el torso entre las barras sin apoyar los pies..
FIXED EQUIPMENT: one fixed set of parallel dip bars, same geometry and height throughout.
LOCKED CAMERA AND LATERALITY: fixed strict side view.
LIME MUSCLE FILL: triceps, chest and anterior deltoids; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground oval for suspended body. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_pb_dip; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Cámara y barras no consistentes con el paso 1.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Flexiona los codos y baja el torso entre las barras sin apoyar los pies..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_pb_dip_2.jpg 1024x1024 and matching thumbs/art_gy_pb_dip_2.jpg 192x192.
```


### 51. Pegboard — `art_gy_pegboard`

- **Equipo obligatorio:** one upright pegboard with multiple holes and two hand pegs.
- **Cámara fija:** fixed three-quarter front view.
- **Lime:** lats, biceps and forearms.
- **Sombra:** NO floor oval while suspended.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_pegboard.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_pegboard` — FAIL

**Problema:** Pegboard mostrado como dominada en barra sin tablero

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_pegboard image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Pegboard. ASSET NAME: art_gy_pegboard. FRAME: representative hero.
EXACT JOINT/GEAR POSE: gymnast climbing a vertical pegboard by gripping two inserted pegs, both feet clearly off floor.
FIXED EQUIPMENT: one upright pegboard with multiple holes and two hand pegs.
LOCKED CAMERA AND LATERALITY: fixed three-quarter front view.
LIME MUSCLE FILL: lats, biceps and forearms; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval while suspended. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_pegboard; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Pegboard mostrado como dominada en barra sin tablero.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_pegboard.jpg 1024x1024 and matching thumbs/art_gy_pegboard.jpg 192x192.
```


### 52. Press to handstand — `art_gy_press_hs`

- **Equipo obligatorio:** no equipment; hands on floor and shoes in air; no barbells anywhere.
- **Cámara fija:** fixed side view.
- **Lime:** deltoids, core and hip flexors.
- **Sombra:** shadow only under palms planted on floor.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_press_hs.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_press_hs` — FAIL

**Problema:** Press to handstand dibujado con barra olímpica en los pies

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_press_hs image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Press to handstand. ASSET NAME: art_gy_press_hs. FRAME: representative hero.
EXACT JOINT/GEAR POSE: press to handstand transition with shoulders stacked over palms, straight arms, hips opening as legs rise from pike to vertical.
FIXED EQUIPMENT: no equipment; hands on floor and shoes in air; no barbells anywhere.
LOCKED CAMERA AND LATERALITY: fixed side view.
LIME MUSCLE FILL: deltoids, core and hip flexors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow only under palms planted on floor. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_press_hs; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Press to handstand dibujado con barra olímpica en los pies.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_press_hs.jpg 1024x1024 and matching thumbs/art_gy_press_hs.jpg 192x192.
```


### 53. Soporte en anillas — `art_gy_ring_sup`

- **Equipo obligatorio:** two GRAY gymnastic rings with taut straps.
- **Cámara fija:** fixed front three-quarter view.
- **Lime:** triceps, pectorals and shoulder stabilizers.
- **Sombra:** NO floor oval or shadow.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_ring_sup.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_ring_sup` — FAIL

**Problema:** Soporte en anillas con óvalo de suelo bajo pies suspendidos

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_ring_sup image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Soporte en anillas. ASSET NAME: art_gy_ring_sup. FRAME: representative hero.
EXACT JOINT/GEAR POSE: strict ring support hold, body vertically above rings, elbows locked, rings next to hips and feet suspended.
FIXED EQUIPMENT: two GRAY gymnastic rings with taut straps.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view.
LIME MUSCLE FILL: triceps, pectorals and shoulder stabilizers; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval or shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_ring_sup; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Soporte en anillas con óvalo de suelo bajo pies suspendidos.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_ring_sup.jpg 1024x1024 and matching thumbs/art_gy_ring_sup.jpg 192x192.
```


### 54. Skin the cat — `art_gy_skin_cat`

- **Equipo obligatorio:** two gray hanging gymnastics rings with straps.
- **Cámara fija:** fixed side view.
- **Lime:** lats, shoulders and core.
- **Sombra:** NO floor shadow in suspension.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_skin_cat.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_skin_cat` — WARN

**Problema:** Skin-the-cat representado como simple hang sin rotación

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_skin_cat image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Skin the cat. ASSET NAME: art_gy_skin_cat. FRAME: representative hero.
EXACT JOINT/GEAR POSE: skin-the-cat controlled inversion through shoulders with hips tucked and feet traveling BEHIND line of arms; not ordinary hang.
FIXED EQUIPMENT: two gray hanging gymnastics rings with straps.
LOCKED CAMERA AND LATERALITY: fixed side view.
LIME MUSCLE FILL: lats, shoulders and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor shadow in suspension. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_skin_cat; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Skin-the-cat representado como simple hang sin rotación.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_skin_cat.jpg 1024x1024 and matching thumbs/art_gy_skin_cat.jpg 192x192.
```


### 55. Muscle-up estricto barra — `art_gy_strict_mubar`

- **Equipo obligatorio:** fixed single high horizontal bar.
- **Cámara fija:** fixed three-quarter side view.
- **Lime:** lats, triceps and pecs.
- **Sombra:** NO floor oval in support.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_strict_mubar.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_strict_mubar` — WARN

**Problema:** Muscle-up estricto dibujado como dominada con barbilla en barra

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_strict_mubar image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Muscle-up estricto barra. ASSET NAME: art_gy_strict_mubar. FRAME: representative hero.
EXACT JOINT/GEAR POSE: strict bar muscle-up finishing support above bar with straight elbows and hips close to bar; not a chin-up.
FIXED EQUIPMENT: fixed single high horizontal bar.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view.
LIME MUSCLE FILL: lats, triceps and pecs; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO floor oval in support. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_strict_mubar; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Muscle-up estricto dibujado como dominada con barbilla en barra.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_strict_mubar.jpg 1024x1024 and matching thumbs/art_gy_strict_mubar.jpg 192x192.
```


### 56. Toes to bar estrictos — `art_gy_strict_ttb`

- **Equipo obligatorio:** one fixed overhead pull-up bar.
- **Cámara fija:** fixed three-quarter side view.
- **Lime:** abdominals and hip flexors.
- **Sombra:** NO ground shadow.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_strict_ttb.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_strict_ttb` — FAIL

**Problema:** Toes-to-bar en suspensión con óvalo de suelo

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_strict_ttb image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Toes to bar estrictos. ASSET NAME: art_gy_strict_ttb. FRAME: representative hero.
EXACT JOINT/GEAR POSE: strict toes-to-bar with straight legs raised until toes touch bar, elbows straight, feet suspended.
FIXED EQUIPMENT: one fixed overhead pull-up bar.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view.
LIME MUSCLE FILL: abdominals and hip flexors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: NO ground shadow. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_strict_ttb; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Toes-to-bar en suspensión con óvalo de suelo.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_strict_ttb.jpg 1024x1024 and matching thumbs/art_gy_strict_ttb.jpg 192x192.
```


### 57. V-sit — `art_gy_vsit`

- **Equipo obligatorio:** no equipment or blocks, palms planted on floor beside hips.
- **Cámara fija:** fixed side three-quarter view.
- **Lime:** rectus abdominis, hip flexors and triceps.
- **Sombra:** shadow only immediately below planted palms.
- **Referencias:** `art_ab_wheel.jpg`, `art_gy_vsit.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_gy_vsit` — FAIL

**Problema:** V-sit sin apoyo de manos, parece V-up sobre suelo

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_gy_vsit image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: V-sit. ASSET NAME: art_gy_vsit. FRAME: representative hero.
EXACT JOINT/GEAR POSE: V-sit gymnastics HOLD supported entirely on both hands with hips off floor and both straight legs raised high forward.
FIXED EQUIPMENT: no equipment or blocks, palms planted on floor beside hips.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: rectus abdominis, hip flexors and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow only immediately below planted palms. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_gy_vsit; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: V-sit sin apoyo de manos, parece V-up sobre suelo.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_gy_vsit.jpg 1024x1024 and matching thumbs/art_gy_vsit.jpg 192x192.
```


### 58. Hip thrust — `art_hip_thrust`

- **Equipo obligatorio:** one standard Olympic barbell resting ACROSS pelvic crease, one fixed low flat bench.
- **Cámara fija:** fixed strict side view.
- **Lime:** glutes maximus, hamstrings.
- **Sombra:** shadow below bench and feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_hip_thrust.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_hip_thrust` — FAIL

**Problema:** Figura tumbada sobre banco como press, barra sobre pecho y no pelvis

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_hip_thrust image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Hip thrust. ASSET NAME: art_hip_thrust. FRAME: representative hero.
EXACT JOINT/GEAR POSE: hip thrust top: ONLY shoulders and upper back on bench, feet flat floor, knees bent, bar at pelvis and torso aligned with thighs.
FIXED EQUIPMENT: one standard Olympic barbell resting ACROSS pelvic crease, one fixed low flat bench.
LOCKED CAMERA AND LATERALITY: fixed strict side view.
LIME MUSCLE FILL: glutes maximus, hamstrings; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow below bench and feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_hip_thrust; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Figura tumbada sobre banco como press, barra sobre pecho y no pelvis.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_hip_thrust.jpg 1024x1024 and matching thumbs/art_hip_thrust.jpg 192x192.
```

#### `art_hip_thrust_1` — FAIL

**Problema:** El atleta yace en banco en vez de apoyar escápulas; barra sobre pecho

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Hombros en banco, barra en cadera, cadera BAJA cerca del suelo.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_hip_thrust image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Hip thrust. ASSET NAME: art_hip_thrust_1. FRAME: step 1 of 2.
EXACT JOINT/GEAR POSE: Hombros en banco, barra en cadera, cadera BAJA cerca del suelo..
FIXED EQUIPMENT: one standard Olympic barbell resting ACROSS pelvic crease, one fixed low flat bench.
LOCKED CAMERA AND LATERALITY: fixed strict side view.
LIME MUSCLE FILL: glutes maximus, hamstrings; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow below bench and feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_hip_thrust; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: El atleta yace en banco en vez de apoyar escápulas; barra sobre pecho.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Hombros en banco, barra en cadera, cadera BAJA cerca del suelo..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_hip_thrust_1.jpg 1024x1024 and matching thumbs/art_hip_thrust_1.jpg 192x192.
```

#### `art_hip_thrust_2` — FAIL

**Problema:** Misma postura incorrecta sobre banco, casi idéntica al frame 1

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Empuja cadera hasta alinear torso y muslos; aprieta glúteo.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_hip_thrust image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Hip thrust. ASSET NAME: art_hip_thrust_2. FRAME: step 2 of 2.
EXACT JOINT/GEAR POSE: Empuja cadera hasta alinear torso y muslos; aprieta glúteo..
FIXED EQUIPMENT: one standard Olympic barbell resting ACROSS pelvic crease, one fixed low flat bench.
LOCKED CAMERA AND LATERALITY: fixed strict side view.
LIME MUSCLE FILL: glutes maximus, hamstrings; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow below bench and feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_hip_thrust; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Misma postura incorrecta sobre banco, casi idéntica al frame 1.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Empuja cadera hasta alinear torso y muslos; aprieta glúteo..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_hip_thrust_2.jpg 1024x1024 and matching thumbs/art_hip_thrust_2.jpg 192x192.
```


### 59. Cargada desde bloques — `art_hl_block_clean`

- **Equipo obligatorio:** one Olympic barbell sitting on TWO matched lifting blocks either side; athlete stands on FLOOR.
- **Cámara fija:** fixed three-quarter side view.
- **Lime:** quadriceps, glutes and trapezius.
- **Sombra:** floor oval under shoes and lifting blocks.
- **Referencias:** `art_ab_wheel.jpg`, `art_hl_block_clean.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_hl_block_clean` — FAIL

**Problema:** El atleta sube a los bloques en lugar de empezar con la barra sobre ellos

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_hl_block_clean image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada desde bloques. ASSET NAME: art_hl_block_clean. FRAME: representative hero.
EXACT JOINT/GEAR POSE: block clean START: loaded barbell supported by raised lifting blocks near knee level, athlete grips bar from floor, never stands on blocks.
FIXED EQUIPMENT: one Olympic barbell sitting on TWO matched lifting blocks either side; athlete stands on FLOOR.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view.
LIME MUSCLE FILL: quadriceps, glutes and trapezius; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under shoes and lifting blocks. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_hl_block_clean; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: El atleta sube a los bloques en lugar de empezar con la barra sobre ellos.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_hl_block_clean.jpg 1024x1024 and matching thumbs/art_hl_block_clean.jpg 192x192.
```


### 60. Arrancada desde bloques — `art_hl_block_snatch`

- **Equipo obligatorio:** one Olympic barbell with WIDE grip and matched raised lifting blocks.
- **Cámara fija:** fixed three-quarter side view.
- **Lime:** quads, glutes and traps.
- **Sombra:** floor oval under shoes and blocks.
- **Referencias:** `art_ab_wheel.jpg`, `art_hl_block_snatch.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_hl_block_snatch` — FAIL

**Problema:** El atleta está sobre los bloques y no representa la salida

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_hl_block_snatch image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Arrancada desde bloques. ASSET NAME: art_hl_block_snatch. FRAME: representative hero.
EXACT JOINT/GEAR POSE: block snatch START: weight plates rest ON top of two blocks, athlete standing on floor between them, hands in wide grip.
FIXED EQUIPMENT: one Olympic barbell with WIDE grip and matched raised lifting blocks.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view.
LIME MUSCLE FILL: quads, glutes and traps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under shoes and blocks. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_hl_block_snatch; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: El atleta está sobre los bloques y no representa la salida.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_hl_block_snatch.jpg 1024x1024 and matching thumbs/art_hl_block_snatch.jpg 192x192.
```


### 61. Tirón de cargada — `art_hl_clean_pull`

- **Equipo obligatorio:** one Olympic barbell with equal plates.
- **Cámara fija:** fixed three-quarter side view.
- **Lime:** glutes, hamstrings and trapezius.
- **Sombra:** soft oval below shoes.
- **Referencias:** `art_ab_wheel.jpg`, `art_hl_clean_pull.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_hl_clean_pull` — FAIL

**Problema:** Barra detrás del cuello en vez de tirón de cargada

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_hl_clean_pull image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Tirón de cargada. ASSET NAME: art_hl_clean_pull. FRAME: representative hero.
EXACT JOINT/GEAR POSE: clean pull phase: bar close to thighs rising powerfully from hip/knee extension with arms long; NO front/back rack or overhead.
FIXED EQUIPMENT: one Olympic barbell with equal plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view.
LIME MUSCLE FILL: glutes, hamstrings and trapezius; nothing else highlighted in lime.
CONTACT / SHADOW RULE: soft oval below shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_hl_clean_pull; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Barra detrás del cuello en vez de tirón de cargada.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_hl_clean_pull.jpg 1024x1024 and matching thumbs/art_hl_clean_pull.jpg 192x192.
```


### 62. Cargada colgante completa — `art_hl_hang_sq_clean`

- **Equipo obligatorio:** one Olympic barbell with equal plates.
- **Cámara fija:** fixed front three-quarter view.
- **Lime:** quads, glutes and upper back.
- **Sombra:** floor oval under feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_hl_hang_sq_clean.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_hl_hang_sq_clean` — FAIL

**Problema:** Barra detrás del cuello en vez de rack frontal

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_hl_hang_sq_clean image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada colgante completa. ASSET NAME: art_hl_hang_sq_clean. FRAME: representative hero.
EXACT JOINT/GEAR POSE: hang squat clean caught in FULL FRONT squat, bar resting on anterior shoulders, elbows HIGH, never behind neck.
FIXED EQUIPMENT: one Olympic barbell with equal plates.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view.
LIME MUSCLE FILL: quads, glutes and upper back; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_hl_hang_sq_clean; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Barra detrás del cuello en vez de rack frontal.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_hl_hang_sq_clean.jpg 1024x1024 and matching thumbs/art_hl_hang_sq_clean.jpg 192x192.
```


### 63. Cargada con pausa — `art_hl_pause_clean`

- **Equipo obligatorio:** one Olympic barbell with equal plates.
- **Cámara fija:** fixed front three-quarter view.
- **Lime:** quads, glutes and spinal erectors.
- **Sombra:** floor oval under shoes.
- **Referencias:** `art_ab_wheel.jpg`, `art_hl_pause_clean.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_hl_pause_clean` — FAIL

**Problema:** Barra overhead en vez de cargada con pausa

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_hl_pause_clean image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Cargada con pausa. ASSET NAME: art_hl_pause_clean. FRAME: representative hero.
EXACT JOINT/GEAR POSE: clean with pause: bar stopped visibly at the knee with back neutral and arms long during first pull; NEVER overhead.
FIXED EQUIPMENT: one Olympic barbell with equal plates.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view.
LIME MUSCLE FILL: quads, glutes and spinal erectors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_hl_pause_clean; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Barra overhead en vez de cargada con pausa.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_hl_pause_clean.jpg 1024x1024 and matching thumbs/art_hl_pause_clean.jpg 192x192.
```


### 64. Sentadilla frontal con pausa — `art_hl_pause_fs`

- **Equipo obligatorio:** one Olympic barbell with equal plates.
- **Cámara fija:** fixed front three-quarter view.
- **Lime:** quadriceps and core.
- **Sombra:** floor oval under shoes.
- **Referencias:** `art_ab_wheel.jpg`, `art_hl_pause_fs.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_hl_pause_fs` — FAIL

**Problema:** Barra sobre la espalda en vez de rack frontal

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_hl_pause_fs image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Sentadilla frontal con pausa. ASSET NAME: art_hl_pause_fs. FRAME: representative hero.
EXACT JOINT/GEAR POSE: paused FRONT squat at bottom, bar lying across front shoulders, elbows pointing forward/up, hips below knees.
FIXED EQUIPMENT: one Olympic barbell with equal plates.
LOCKED CAMERA AND LATERALITY: fixed front three-quarter view.
LIME MUSCLE FILL: quadriceps and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_hl_pause_fs; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Barra sobre la espalda en vez de rack frontal.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_hl_pause_fs.jpg 1024x1024 and matching thumbs/art_hl_pause_fs.jpg 192x192.
```


### 65. Balance de arrancada — `art_hl_snatch_bal`

- **Equipo obligatorio:** one Olympic barbell wide grip with matched plates, NO belt or extra outfit.
- **Cámara fija:** fixed three-quarter view.
- **Lime:** quads, glutes, deltoids and upper back.
- **Sombra:** floor oval under shoes.
- **Referencias:** `art_ab_wheel.jpg`, `art_hl_snatch_bal.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_hl_snatch_bal` — WARN

**Problema:** Cinturón extra distinto del outfit canónico

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_hl_snatch_bal image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Balance de arrancada. ASSET NAME: art_hl_snatch_bal. FRAME: representative hero.
EXACT JOINT/GEAR POSE: snatch balance catch in deep overhead squat with fully straight arms and feet planted.
FIXED EQUIPMENT: one Olympic barbell wide grip with matched plates, NO belt or extra outfit.
LOCKED CAMERA AND LATERALITY: fixed three-quarter view.
LIME MUSCLE FILL: quads, glutes, deltoids and upper back; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_hl_snatch_bal; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Cinturón extra distinto del outfit canónico.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_hl_snatch_bal.jpg 1024x1024 and matching thumbs/art_hl_snatch_bal.jpg 192x192.
```


### 66. Tirón de arrancada — `art_hl_snatch_pull`

- **Equipo obligatorio:** one Olympic barbell with WIDE snatch grip.
- **Cámara fija:** fixed three-quarter side view.
- **Lime:** hamstrings, glutes and trapezius.
- **Sombra:** floor oval under grounded feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_hl_snatch_pull.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_hl_snatch_pull` — FAIL

**Problema:** Barra detrás del cuello en vez de tirón de arrancada

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_hl_snatch_pull image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Tirón de arrancada. ASSET NAME: art_hl_snatch_pull. FRAME: representative hero.
EXACT JOINT/GEAR POSE: snatch pull during explosive extension with bar rising close to thighs and elbows high and outside ONLY in finish; NO behind-neck rack or overhead.
FIXED EQUIPMENT: one Olympic barbell with WIDE snatch grip.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view.
LIME MUSCLE FILL: hamstrings, glutes and trapezius; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under grounded feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_hl_snatch_pull; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Barra detrás del cuello en vez de tirón de arrancada.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_hl_snatch_pull.jpg 1024x1024 and matching thumbs/art_hl_snatch_pull.jpg 192x192.
```


### 67. Tall clean — `art_hl_tall_clean`

- **Equipo obligatorio:** one Olympic barbell with matched plates, no squat rack.
- **Cámara fija:** fixed frontal three-quarter view.
- **Lime:** trapezius, quadriceps and shoulders.
- **Sombra:** floor oval under feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_hl_tall_clean.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_hl_tall_clean` — FAIL

**Problema:** Torso vestido

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_hl_tall_clean image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Tall clean. ASSET NAME: art_hl_tall_clean. FRAME: representative hero.
EXACT JOINT/GEAR POSE: tall clean catching bar into FRONT rack with elbows high in a shallow squat, upper body SHIRTLESS.
FIXED EQUIPMENT: one Olympic barbell with matched plates, no squat rack.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: trapezius, quadriceps and shoulders; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_hl_tall_clean; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Torso vestido.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_hl_tall_clean.jpg 1024x1024 and matching thumbs/art_hl_tall_clean.jpg 192x192.
```


### 68. Jalón al pecho — `art_jalon`

- **Equipo obligatorio:** one LAT PULLDOWN machine with overhead cable and single long light pull-down handle, NO plates attached to bar.
- **Cámara fija:** fixed frontal three-quarter view.
- **Lime:** latissimus dorsi and biceps.
- **Sombra:** floor oval below machine.
- **Referencias:** `art_ab_wheel.jpg`, `art_jalon.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_jalon` — FAIL

**Problema:** Polea unida a barra olímpica cargada de discos, equipo imposible

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_jalon image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Jalón al pecho. ASSET NAME: art_jalon. FRAME: representative hero.
EXACT JOINT/GEAR POSE: seated lat pulldown, thigh pads hold legs, elbows drawn to sides as cable handle touches upper chest.
FIXED EQUIPMENT: one LAT PULLDOWN machine with overhead cable and single long light pull-down handle, NO plates attached to bar.
LOCKED CAMERA AND LATERALITY: fixed frontal three-quarter view.
LIME MUSCLE FILL: latissimus dorsi and biceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval below machine. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_jalon; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Polea unida a barra olímpica cargada de discos, equipo imposible.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_jalon.jpg 1024x1024 and matching thumbs/art_jalon.jpg 192x192.
```


### 69. Pájaros — `art_pajaros`

- **Equipo obligatorio:** two small separate dumbbells and one bench for reverse fly, NO barbells.
- **Cámara fija:** fixed side three-quarter view.
- **Lime:** rear deltoids and upper back.
- **Sombra:** ground oval under planted feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_pajaros.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_pajaros` — FAIL

**Problema:** Pájaros representados como press con barra y mancuernas simultáneas

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_pajaros image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Pájaros. ASSET NAME: art_pajaros. FRAME: representative hero.
EXACT JOINT/GEAR POSE: bent-over reverse dumbbell fly: torso hinged, arms abducted laterally at shoulder height, softly bent elbows.
FIXED EQUIPMENT: two small separate dumbbells and one bench for reverse fly, NO barbells.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: rear deltoids and upper back; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under planted feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_pajaros; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Pájaros representados como press con barra y mancuernas simultáneas.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_pajaros.jpg 1024x1024 and matching thumbs/art_pajaros.jpg 192x192.
```


### 70. Peso muerto — `art_peso_muerto`

- **Equipo obligatorio:** one Olympic barbell with IDENTICAL plates in all frames.
- **Cámara fija:** fixed three-quarter side view.
- **Lime:** glutes, hamstrings and spinal erectors.
- **Sombra:** ground oval under feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_peso_muerto.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_peso_muerto` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_peso_muerto image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Peso muerto. ASSET NAME: art_peso_muerto. FRAME: representative hero.
EXACT JOINT/GEAR POSE: barbell deadlift finish: stand tall with bar touching front thighs, arms straight, hips and knees extended.
FIXED EQUIPMENT: one Olympic barbell with IDENTICAL plates in all frames.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view.
LIME MUSCLE FILL: glutes, hamstrings and spinal erectors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_peso_muerto; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_peso_muerto.jpg 1024x1024 and matching thumbs/art_peso_muerto.jpg 192x192.
```

#### `art_peso_muerto_1` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Barra sobre mediopié, agarre fuera de piernas, espalda plana.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_peso_muerto image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Peso muerto. ASSET NAME: art_peso_muerto_1. FRAME: step 1 of 2.
EXACT JOINT/GEAR POSE: Barra sobre mediopié, agarre fuera de piernas, espalda plana..
FIXED EQUIPMENT: one Olympic barbell with IDENTICAL plates in all frames.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view.
LIME MUSCLE FILL: glutes, hamstrings and spinal erectors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_peso_muerto; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Barra sobre mediopié, agarre fuera de piernas, espalda plana..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_peso_muerto_1.jpg 1024x1024 and matching thumbs/art_peso_muerto_1.jpg 192x192.
```

#### `art_peso_muerto_2` — FAIL

**Problema:** Barra y discos discontinuos respecto al paso 1

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Empuja el suelo y bloquea cadera de pie sin hiperextender.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_peso_muerto image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Peso muerto. ASSET NAME: art_peso_muerto_2. FRAME: step 2 of 2.
EXACT JOINT/GEAR POSE: Empuja el suelo y bloquea cadera de pie sin hiperextender..
FIXED EQUIPMENT: one Olympic barbell with IDENTICAL plates in all frames.
LOCKED CAMERA AND LATERALITY: fixed three-quarter side view.
LIME MUSCLE FILL: glutes, hamstrings and spinal erectors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_peso_muerto; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Barra y discos discontinuos respecto al paso 1.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Empuja el suelo y bloquea cadera de pie sin hiperextender..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_peso_muerto_2.jpg 1024x1024 and matching thumbs/art_peso_muerto_2.jpg 192x192.
```


### 71. Plancha — `art_plancha`

- **Equipo obligatorio:** NO equipment, ground only.
- **Cámara fija:** fixed side view.
- **Lime:** abdominals, transverse core and glutes.
- **Sombra:** floor oval under forearms and toes.
- **Referencias:** `art_ab_wheel.jpg`, `art_plancha.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_plancha` — FAIL

**Problema:** Plancha representada como apoyo en paralelas con cuerpo suspendido y cara hacia arriba

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_plancha image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Plancha. ASSET NAME: art_plancha. FRAME: representative hero.
EXACT JOINT/GEAR POSE: standard FOREARM plank facing floor, elbows directly under shoulders, body straight heel to head, toes on ground.
FIXED EQUIPMENT: NO equipment, ground only.
LOCKED CAMERA AND LATERALITY: fixed side view.
LIME MUSCLE FILL: abdominals, transverse core and glutes; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under forearms and toes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_plancha; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Plancha representada como apoyo en paralelas con cuerpo suspendido y cara hacia arriba.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_plancha.jpg 1024x1024 and matching thumbs/art_plancha.jpg 192x192.
```


### 72. Press banca declinado — `art_press_declinado`

- **Equipo obligatorio:** one Olympic barbell with matched plates and clearly DECLINED bench, head lower than hips.
- **Cámara fija:** fixed side three-quarter view.
- **Lime:** lower pectorals and triceps.
- **Sombra:** ground oval under declined bench.
- **Referencias:** `art_ab_wheel.jpg`, `art_press_declinado.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_press_declinado` — FAIL

**Problema:** Press declinado representado sobre banco inclinado hacia arriba

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_press_declinado image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Press banca declinado. ASSET NAME: art_press_declinado. FRAME: representative hero.
EXACT JOINT/GEAR POSE: decline bench press with athlete secured on downward-sloping decline bench, feet held in leg hooks, bar over lower pecs.
FIXED EQUIPMENT: one Olympic barbell with matched plates and clearly DECLINED bench, head lower than hips.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: lower pectorals and triceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under declined bench. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_press_declinado; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Press declinado representado sobre banco inclinado hacia arriba.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_press_declinado.jpg 1024x1024 and matching thumbs/art_press_declinado.jpg 192x192.
```


### 73. Press francés — `art_press_frances`

- **Equipo obligatorio:** one FREE short EZ curl bar with light gray plates and flat bench; NO cables.
- **Cámara fija:** fixed side three-quarter view.
- **Lime:** triceps only.
- **Sombra:** floor oval under bench.
- **Referencias:** `art_ab_wheel.jpg`, `art_press_frances.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_press_frances` — FAIL

**Problema:** Barra olímpica y cable de polea mezclados en press francés

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_press_frances image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Press francés. ASSET NAME: art_press_frances. FRAME: representative hero.
EXACT JOINT/GEAR POSE: lying skull crusher, upper arms vertical, elbows bent bringing FREE EZ bar toward forehead under control.
FIXED EQUIPMENT: one FREE short EZ curl bar with light gray plates and flat bench; NO cables.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: triceps only; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under bench. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_press_frances; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Barra olímpica y cable de polea mezclados en press francés.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_press_frances.jpg 1024x1024 and matching thumbs/art_press_frances.jpg 192x192.
```


### 74. Pullover — `art_pullover`

- **Equipo obligatorio:** one single moderate dumbbell and flat bench.
- **Cámara fija:** fixed side view.
- **Lime:** latissimus dorsi, serratus and pectorals; NO abs emphasis.
- **Sombra:** floor oval under bench.
- **Referencias:** `art_ab_wheel.jpg`, `art_pullover.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_pullover` — WARN

**Problema:** Activación abdominal demasiado dominante en pullover

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_pullover image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Pullover. ASSET NAME: art_pullover. FRAME: representative hero.
EXACT JOINT/GEAR POSE: lying on flat bench, dumbbell held in both hands traveling in an arc behind head with elbows slightly bent.
FIXED EQUIPMENT: one single moderate dumbbell and flat bench.
LOCKED CAMERA AND LATERALITY: fixed side view.
LIME MUSCLE FILL: latissimus dorsi, serratus and pectorals; NO abs emphasis; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under bench. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_pullover; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Activación abdominal demasiado dominante en pullover.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_pullover.jpg 1024x1024 and matching thumbs/art_pullover.jpg 192x192.
```


### 75. Peso muerto rumano — `art_rdl`

- **Equipo obligatorio:** one Olympic barbell with same weight plates across all frames.
- **Cámara fija:** fixed STRICT SIDE view facing RIGHT.
- **Lime:** hamstrings, glutes and spinal erectors.
- **Sombra:** floor oval under shoes.
- **Referencias:** `art_ab_wheel.jpg`, `art_rdl.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_rdl` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_rdl image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Peso muerto rumano. ASSET NAME: art_rdl. FRAME: representative hero.
EXACT JOINT/GEAR POSE: Romanian deadlift standing with bar close to thighs, soft knees, spine neutral and hips pushed backward.
FIXED EQUIPMENT: one Olympic barbell with same weight plates across all frames.
LOCKED CAMERA AND LATERALITY: fixed STRICT SIDE view facing RIGHT.
LIME MUSCLE FILL: hamstrings, glutes and spinal erectors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_rdl; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_rdl.jpg 1024x1024 and matching thumbs/art_rdl.jpg 192x192.
```

#### `art_rdl_1` — FAIL

**Problema:** Cámara frontal, incompatible con el frame lateral

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Colócate de pie con la barra frente a los muslos y las rodillas ligeramente flexionadas.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_rdl image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Peso muerto rumano. ASSET NAME: art_rdl_1. FRAME: step 1 of 2.
EXACT JOINT/GEAR POSE: Colócate de pie con la barra frente a los muslos y las rodillas ligeramente flexionadas..
FIXED EQUIPMENT: one Olympic barbell with same weight plates across all frames.
LOCKED CAMERA AND LATERALITY: fixed STRICT SIDE view facing RIGHT.
LIME MUSCLE FILL: hamstrings, glutes and spinal erectors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_rdl; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Cámara frontal, incompatible con el frame lateral.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Colócate de pie con la barra frente a los muslos y las rodillas ligeramente flexionadas..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_rdl_1.jpg 1024x1024 and matching thumbs/art_rdl_1.jpg 192x192.
```

#### `art_rdl_2` — FAIL

**Problema:** Cámara lateral y discos diferentes frente al primer frame

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Lleva la cadera atrás y baja la barra cerca de las piernas manteniendo la espalda neutra.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_rdl image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Peso muerto rumano. ASSET NAME: art_rdl_2. FRAME: step 2 of 2.
EXACT JOINT/GEAR POSE: Lleva la cadera atrás y baja la barra cerca de las piernas manteniendo la espalda neutra..
FIXED EQUIPMENT: one Olympic barbell with same weight plates across all frames.
LOCKED CAMERA AND LATERALITY: fixed STRICT SIDE view facing RIGHT.
LIME MUSCLE FILL: hamstrings, glutes and spinal erectors; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under shoes. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_rdl; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Cámara lateral y discos diferentes frente al primer frame.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Lleva la cadera atrás y baja la barra cerca de las piernas manteniendo la espalda neutra..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_rdl_2.jpg 1024x1024 and matching thumbs/art_rdl_2.jpg 192x192.
```


### 76. Remo máquina — `art_remo_erg`

- **Equipo obligatorio:** one recognizable Concept2-style rowing ergometer with long rail and flywheel.
- **Cámara fija:** fixed side view.
- **Lime:** upper back, lats and quads.
- **Sombra:** shadow under rower machine.
- **Referencias:** `art_ab_wheel.jpg`, `art_remo_erg.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_remo_erg` — FAIL

**Problema:** Remo ergómetro mezclado con barra olímpica cargada sobre la cabeza

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_remo_erg image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Remo máquina. ASSET NAME: art_remo_erg. FRAME: representative hero.
EXACT JOINT/GEAR POSE: seated rowing ergometer drive finish, legs extended, torso slightly back and both hands pull SINGLE cable handle to lower sternum; NO BARBELL.
FIXED EQUIPMENT: one recognizable Concept2-style rowing ergometer with long rail and flywheel.
LOCKED CAMERA AND LATERALITY: fixed side view.
LIME MUSCLE FILL: upper back, lats and quads; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow under rower machine. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_remo_erg; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Remo ergómetro mezclado con barra olímpica cargada sobre la cabeza.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_remo_erg.jpg 1024x1024 and matching thumbs/art_remo_erg.jpg 192x192.
```


### 77. Remo invertido — `art_remo_invertido`

- **Equipo obligatorio:** one low horizontal bar mounted at waist height, no high bar.
- **Cámara fija:** fixed side view.
- **Lime:** lats, rhomboids and biceps.
- **Sombra:** floor shadow under shoes, NOT airborne.
- **Referencias:** `art_ab_wheel.jpg`, `art_remo_invertido.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_remo_invertido` — FAIL

**Problema:** Remo invertido mostrado como dominada vertical

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_remo_invertido image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Remo invertido. ASSET NAME: art_remo_invertido. FRAME: representative hero.
EXACT JOINT/GEAR POSE: inverted horizontal row: heels planted on floor, torso straight face up underneath LOW bar, chest pulled toward bar.
FIXED EQUIPMENT: one low horizontal bar mounted at waist height, no high bar.
LOCKED CAMERA AND LATERALITY: fixed side view.
LIME MUSCLE FILL: lats, rhomboids and biceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor shadow under shoes, NOT airborne. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_remo_invertido; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Remo invertido mostrado como dominada vertical.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_remo_invertido.jpg 1024x1024 and matching thumbs/art_remo_invertido.jpg 192x192.
```


### 78. Remo sentado — `art_remo_sentado`

- **Equipo obligatorio:** one seated cable row machine with footplates, low pulley, single V-handle cable; NO barbells.
- **Cámara fija:** fixed side three-quarter view.
- **Lime:** latissimus dorsi, rhomboids and biceps.
- **Sombra:** shadow under cable station.
- **Referencias:** `art_ab_wheel.jpg`, `art_remo_sentado.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_remo_sentado` — FAIL

**Problema:** Remo sentado mostrado como press de banca con barra suspendida

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_remo_sentado image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Remo sentado. ASSET NAME: art_remo_sentado. FRAME: representative hero.
EXACT JOINT/GEAR POSE: seated upright cable row, feet braced and handle pulled to abdomen with elbows close to body.
FIXED EQUIPMENT: one seated cable row machine with footplates, low pulley, single V-handle cable; NO barbells.
LOCKED CAMERA AND LATERALITY: fixed side three-quarter view.
LIME MUSCLE FILL: latissimus dorsi, rhomboids and biceps; nothing else highlighted in lime.
CONTACT / SHADOW RULE: shadow under cable station. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_remo_sentado; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Remo sentado mostrado como press de banca con barra suspendida.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_remo_sentado.jpg 1024x1024 and matching thumbs/art_remo_sentado.jpg 192x192.
```


### 79. Sentadilla frontal — `art_sentadilla_frontal`

- **Equipo obligatorio:** one Olympic barbell with symmetrical plates.
- **Cámara fija:** fixed three-quarter frontal view.
- **Lime:** quads, glutes and core.
- **Sombra:** ground oval under feet.
- **Referencias:** `art_ab_wheel.jpg`, `art_sentadilla_frontal.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_sentadilla_frontal` — WARN

**Problema:** Codos demasiado bajos en posición frontal de barra

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_sentadilla_frontal image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Sentadilla frontal. ASSET NAME: art_sentadilla_frontal. FRAME: representative hero.
EXACT JOINT/GEAR POSE: front squat in FRONT rack with bar across anterior shoulders, elbows pointed FORWARD and up while squatting.
FIXED EQUIPMENT: one Olympic barbell with symmetrical plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter frontal view.
LIME MUSCLE FILL: quads, glutes and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_sentadilla_frontal; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: Codos demasiado bajos en posición frontal de barra.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_sentadilla_frontal.jpg 1024x1024 and matching thumbs/art_sentadilla_frontal.jpg 192x192.
```

#### `art_sentadilla_frontal_1` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Barra en rack frontal (delante del cuello), codos altos, de pie.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_sentadilla_frontal image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Sentadilla frontal. ASSET NAME: art_sentadilla_frontal_1. FRAME: step 1 of 2.
EXACT JOINT/GEAR POSE: Barra en rack frontal (delante del cuello), codos altos, de pie..
FIXED EQUIPMENT: one Olympic barbell with symmetrical plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter frontal view.
LIME MUSCLE FILL: quads, glutes and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_sentadilla_frontal; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Barra en rack frontal (delante del cuello), codos altos, de pie..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_sentadilla_frontal_1.jpg 1024x1024 and matching thumbs/art_sentadilla_frontal_1.jpg 192x192.
```

#### `art_sentadilla_frontal_2` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Baja a paralelo o más con torso vertical y codos altos; empuja el suelo y vuelve.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_sentadilla_frontal image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Sentadilla frontal. ASSET NAME: art_sentadilla_frontal_2. FRAME: step 2 of 2.
EXACT JOINT/GEAR POSE: Baja a paralelo o más con torso vertical y codos altos; empuja el suelo y vuelve..
FIXED EQUIPMENT: one Olympic barbell with symmetrical plates.
LOCKED CAMERA AND LATERALITY: fixed three-quarter frontal view.
LIME MUSCLE FILL: quads, glutes and core; nothing else highlighted in lime.
CONTACT / SHADOW RULE: ground oval under feet. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_sentadilla_frontal; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Baja a paralelo o más con torso vertical y codos altos; empuja el suelo y vuelve..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_sentadilla_frontal_2.jpg 1024x1024 and matching thumbs/art_sentadilla_frontal_2.jpg 192x192.
```


### 80. Zancadas — `art_zancadas`

- **Equipo obligatorio:** two matching dumbbells at athlete's sides.
- **Cámara fija:** fixed SIDE view facing RIGHT, SAME left-foot-forward side for ALL three frames.
- **Lime:** quads and glutes.
- **Sombra:** floor oval under feet in contact.
- **Referencias:** `art_ab_wheel.jpg`, `art_zancadas.jpg` original y todos sus frames `_1…N` cuando existan; corregir las poses, no copiar los defectos.

#### `art_zancadas` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_zancadas image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Zancadas. ASSET NAME: art_zancadas. FRAME: representative hero.
EXACT JOINT/GEAR POSE: dumbbell walking lunge with one foot in front, back knee close to floor, torso upright.
FIXED EQUIPMENT: two matching dumbbells at athlete's sides.
LOCKED CAMERA AND LATERALITY: fixed SIDE view facing RIGHT, SAME left-foot-forward side for ALL three frames.
LIME MUSCLE FILL: quads and glutes; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under feet in contact. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_zancadas; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_zancadas.jpg 1024x1024 and matching thumbs/art_zancadas.jpg 192x192.
```

#### `art_zancadas_1` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** De pie con mancuernas a los lados.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_zancadas image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Zancadas. ASSET NAME: art_zancadas_1. FRAME: step 1 of 3.
EXACT JOINT/GEAR POSE: De pie con mancuernas a los lados..
FIXED EQUIPMENT: two matching dumbbells at athlete's sides.
LOCKED CAMERA AND LATERALITY: fixed SIDE view facing RIGHT, SAME left-foot-forward side for ALL three frames.
LIME MUSCLE FILL: quads and glutes; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under feet in contact. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_zancadas; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): De pie con mancuernas a los lados..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_zancadas_1.jpg 1024x1024 and matching thumbs/art_zancadas_1.jpg 192x192.
```

#### `art_zancadas_2` — CONTINUIDAD

**Problema:** No tiene defecto confirmado; rehacer para coherencia con los frames modificados.

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Da el paso y baja a media zancada.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_zancadas image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Zancadas. ASSET NAME: art_zancadas_2. FRAME: step 2 of 3.
EXACT JOINT/GEAR POSE: Da el paso y baja a media zancada..
FIXED EQUIPMENT: two matching dumbbells at athlete's sides.
LOCKED CAMERA AND LATERALITY: fixed SIDE view facing RIGHT, SAME left-foot-forward side for ALL three frames.
LIME MUSCLE FILL: quads and glutes; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under feet in contact. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_zancadas; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Da el paso y baja a media zancada..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_zancadas_2.jpg 1024x1024 and matching thumbs/art_zancadas_2.jpg 192x192.
```

#### `art_zancadas_3` — WARN

**Problema:** La cámara se desplaza de tres cuartos a lateral

**Pie de foto actual (alinear o corregir en código si la pose exige otro):** Rodilla trasera cerca del suelo; empuja para volver.

```text
GYMBRO / ONE IMAGE ONLY. Reference canonical art_ab_wheel.jpg AND original art_zancadas image(s) for matching gray shirtless faceless athlete; maintain identical male proportions, charcoal short hair, charcoal shorts, gray sneakers, matte near-black empty charcoal background, clean flat anatomical vector style, 1024x1024 SQUARE, figure AND ALL equipment fully visible with comfortable margins. Exactly ONE pose, no multi-panel image, no words, no arrows, no logos.

EXERCISE: Zancadas. ASSET NAME: art_zancadas_3. FRAME: step 3 of 3.
EXACT JOINT/GEAR POSE: Rodilla trasera cerca del suelo; empuja para volver..
FIXED EQUIPMENT: two matching dumbbells at athlete's sides.
LOCKED CAMERA AND LATERALITY: fixed SIDE view facing RIGHT, SAME left-foot-forward side for ALL three frames.
LIME MUSCLE FILL: quads and glutes; nothing else highlighted in lime.
CONTACT / SHADOW RULE: floor oval under feet in contact. No airborne oval shadows.
EXTRA QA: Keep equipment and character EXACTLY the same as siblings of art_zancadas; do not mix barbells and dumbbells, do not change gym equipment, and ensure large unmistakable joint-position difference between phases. No shirt, no realistic face, no colored equipment and no clutter.
REPAIR THE CONFIRMED AUDIT ERROR: La cámara se desplaza de tres cuartos a lateral.
SPANISH CAPTION TO MATCH VISUALLY (DO NOT DRAW TEXT): Rodilla trasera cerca del suelo; empuja para volver..
EXPORT ONLY this image: Apps/Gymbro/Resources/ExerciseArt/art_zancadas_3.jpg 1024x1024 and matching thumbs/art_zancadas_3.jpg 192x192.
```


## Verificación y exportación de cada stem

1. Generar **una imagen individual**, jamás lámina 4×4 ni cuadrícula con textos.
2. Revisar personaje idéntico; torso desnudo; short+zapatillas; misma cámara y lateralidad entre hero y frames; equipo único; fase biomecánica correcta; highlight lime localizado; sombra según contactos.
3. Corregir cualquier `FAIL` o `WARN`, repetir el conjunto de la familia si un cambio de personaje/equipamiento rompe la continuidad.
4. Exportar desde raíz del repo (no basta generar JPG temporal):

```bash
.venv-art/bin/python scripts/export_generated_art.py /ruta/al/generado.jpg <stem>
.venv-art/bin/python scripts/audit_exercise_art.py
swift test --package-path Packages/GymbroDomain
```

5. Verificar `ExerciseArt/<stem>.jpg` (1024×1024) y `ExerciseArt/thumbs/<stem>.jpg` (192×192).
6. Comparar la pose `_i` con `CatalogSpanish.spanishInstructions[i - 1]`; retocar el texto si es necesario, 8–16 palabras, imperativo español y una acción por paso.
7. Recalcular hashes/CSV de auditoría, retirar del código `quarantinedHeroes` / `quarantinedSequences` solo una vez aprobados, y completar la auditoría visual de los 182 stems inicialmente pendientes.

**Importante:** Este documento es un encargo de generación, no evidencia de que el trabajo se haya realizado.
