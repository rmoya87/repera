# Carruseles propios por tandas — estado y continuación

Pedido de Ramón (iMessage 2026-11-04 21:18): revisar ejercicios sin imagen, poner
primero la principal que lo representa, generar el carrusel paso a paso donde haga
falta y revisar el "cómo hacerlo". Se trabaja en origin/main (iOS + Android), sin
compilar ni publicar. Generación de imágenes limitada (~50/día): tandas nocturnas.

## Estado del catálogo (290 ejercicios, tras tanda 3)

- 0 ejercicios sin hero (resolver iOS/Android replicado).
- 152 con carrusel propio tras la tanda 3 (139 + 8 + 5; art_cf_power_clean sirve a 2 ejercicios).
- 33 holds estáticos con imagen única por diseño.
- 37 con carrusel PRESTADO (movementFrames "interim") — PENDIENTE, prioridad 1.
- 63 solo hero: monoestructurales/estáticos se quedan con 1 imagen (aprobado);
  dinámicos (Pájaros, Shrimp squat, Sled push/pull, Yoke carry, Cossack squat,
  Candlestick, comba dobles/triples, Walking lunge, Plate GTO, Bear crawl,
  Ab wheel, Press Arnold, Cruce de poleas, etc.) son prioridad 2.
- 73 imágenes antiguas sin miniatura en thumbs/ (audit CSV "Falta miniatura"):
  generar thumbs solo de las que faltan con scripts/homogenize_exercise_art.py
  adaptado (no regenerar las 537 existentes).

## Hecho

- Tanda 1 (commit 7143bb20): 4 heroes propios — peso muerto de cargada
  (art_hl_clean_dl), arrancada/cargada de potencia desde bloques
  (art_hl_block_power_snatch/clean), push press agarre arrancada
  (art_hl_snatch_grip_pp) + nameMap iOS/Android + pasos ES curados de
  Step-up al cajón con KB goblet, Cargada y envión con mancuerna y Carrera.
- Migración SQL (commit 26951803):
  supabase/migrations/20261104213000_mobile_catalog_spanish_instructions_batch1.sql
  — la aplica Ramón a mano; las imágenes NO se sirven desde Supabase.
- Tanda 2 (este commit): carruseles propios de 8 ejercicios de arrancada
  (frames _1.._3, QA visual por hojas de contacto): hang snatch, hang squat
  snatch, pause snatch, power snatch, block snatch, split snatch, muscle
  snatch, snatch balance. Pasos 1–3 reescritos donde no describían fases
  visuales (colgante completa, con pausa, de potencia, desde bloques, en split).

- Tanda 3: carruseles propios de 6 ejercicios de cargada (frames _1.._3, QA
  visual): cargada colgante completa (art_hl_hang_sq_clean), cargada con pausa
  (art_hl_pause_clean), cargada de potencia (art_cf_power_clean), cargada
  muscular (art_hl_muscle_clean), cargada y press (art_hl_clean_press), hang
  power clean (art_cf_hpc). Pasos 1-3 reescritos como captions 1:1.
  NOTA pipeline: al subir los frames propios _1..N, el resolver los prioriza
  solo sobre movementFrames (imageNames(for:) prueba base_1..8 primero); no
  hace falta tocar ExerciseArt.swift salvo nameMap para stems nuevos.

## Pipeline por ejercicio (repetir en la siguiente tanda)

1. Elegir 2-3 fases visuales; captions = los primeros N pasos de
   `mobile_instructions` / `Exercise.instructions` tras sync (en iOS la ficha
   usa `resolvedInstructions`; el diccionario `CatalogSpanish` solo es fallback).
   iOS y Android exigen nº pasos >= nº frames. Reescribir los pasos 1..N en
   Supabase si no describen la fase del frame.
2. Generar cada frame con tools image edit (smart, 1:1, 1K), referencias
   art_ab_wheel.jpg + hero del ejercicio; prompt maestro de
   docs/EXERCISE_ART_REGEN_PROMPTS.md (atleta gris sin rostro, torso desnudo,
   fondo carbón #101314, lime plano solo en músculos activos, sin sombra de
   suelo si está en el aire/colgado, cámara fija lateral).
3. QA visual obligatorio (hojas de contacto) antes de exportar.
4. Exportar: python3 scripts/export_generated_art.py <png> <stem> (full 1024 +
   thumb 192) y copiar ambos a android/mobile/src/main/assets/exercise-art(+thumbs).
5. nameMap solo si es un stem nuevo; los frames se detectan solos por sondeo.
6. Verificación: python3 scripts/audit_exercise_art.py (sin "Paso sin hero" ni
   "Falta miniatura" nuevos) + resolver replicado (/tmp/repera/inventory.py).
7. Push a origin/main y lista de ejercicios cubiertos al usuario.

## Pendiente inmediato (37 carruseles prestados)

Cargada desde bloques, Hang power snatch, Tall clean, Tall snatch, Tirón de
cargada, Peso muerto agarre arrancada, Drop snatch, Balance de envión, Envión
detrás de nuca, Press detrás de nuca, Power jerk, Push jerk, Push press, Sots
press, Sumo high pull,
Dominadas estrictas, Dominadas kipping, Dominadas butterfly, Dominadas supinas,
Dominadas en anillas, Muscle-up estricto barra, Muscle-up estricto anillas,
Toes to bar estrictos, Knees to elbows, Kip swing, Hip to bar, Pull-over barra,
HSPU libre, Handstand walk, Press to handstand, Rope climb legless, Fondos,
Step-up al cajón, Clean mancuerna, Ground to overhead, Medball clean, Sandbag
clean.

Nota: el seed Android (catalog_seed.json) NO se regenera con extract_catalog.py
tal cual (pierde ids); las instrucciones Android ya estaban curadas. Si se toca
texto que deba reflejarse, parchear el seed preservando id/orden y validar con
android/tools/check_catalog_parity.py.
