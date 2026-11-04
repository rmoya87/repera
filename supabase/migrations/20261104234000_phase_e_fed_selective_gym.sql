-- Phase E: selective FED/OEDB gym gaps (14) + alias enrichments (2026-11-04)
-- Catalog 433 → 447. No third-party media.

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Crunch en polea', 'Crunch en polea', 'Gym', 'Cable Crunch', 'Crunch arrodillado en polea alta: codos hacia los muslos con tensión constante.',
  ARRAY['Arrodíllate bajo la polea alta con cuerda a ambos lados de la cabeza.','Flexiona el tronco llevando los codos hacia los muslos sin tirar de la nuca.','Vuelve arriba con control manteniendo tensión en el abdomen.','Error típico: usar solo brazos o redondear de golpe la lumbar.','Exhala al bajar el tronco.','Progresión: más peso o tempo lento. Alternativa: crunch en suelo.','Estándar: flexión clara de tronco en cada rep.']::text[], 'waist', 'Core', NULL,
  'Polea', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Crunch en polea', ARRAY['Cable Crunch','Crunch en polea','cable crunch']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Polea']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Elevaciones laterales en polea', 'Elevaciones laterales en polea', 'Gym', 'Cable Lateral Raise', 'Elevación lateral a una mano en polea baja; deltoides medio con tensión continua.',
  ARRAY['Ponte de lado a la polea baja; agarra el mango cruzando por delante del cuerpo.','Eleva el brazo en arco hasta la altura del hombro, codo suave.','Baja con control sin dejar caer el peso.','Error típico: encoger el trapecio o balancear el torso.','Exhala al subir.','Progresión: más peso o pausa arriba. Alternativa: elevaciones laterales con mancuerna.','Estándar: brazo a ~altura de hombro sin subir por encima de la oreja.']::text[], 'shoulders', 'Hombros', NULL,
  'Polea', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Elevaciones laterales en polea', ARRAY['Cable Lateral Raise','Elevaciones laterales en polea','cable lateral raise']::text[], ARRAY['shoulders']::text[], ARRAY['traps']::text[], ARRAY['Polea']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Remo con apoyo de pecho', 'Remo con apoyo de pecho', 'Gym', 'Chest Supported Row', 'Remo con pecho apoyado en banco inclinado; menos trampa lumbar que el remo libre.',
  ARRAY['Banco a ~30–45°; pecho pegado al respaldo, mancuernas colgando.','Tira las mancuernas hacia la cadera/costillas apretando omóplatos.','Baja con control hasta estirar sin despegar el pecho.','Error típico: arrancar el pecho del banco o encoger el cuello.','Exhala al tirar.','Progresión: más peso. Alternativa: remo mancuerna a un brazo.','Estándar: pecho apoyado y codos atrás en cada rep.']::text[], 'back', 'Espalda', NULL,
  'Banco, Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Remo con apoyo de pecho', ARRAY['Chest Supported Row','Remo con apoyo de pecho','chest supported row']::text[], ARRAY['upper-back']::text[], ARRAY['lats','biceps','rear deltoids']::text[], ARRAY['Banco, Mancuernas']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Curl femoral sentado', 'Curl femoral sentado', 'Gym', 'Seated Leg Curl', 'Curl femoral en máquina sentado: flexión de rodilla contra el rodillo.',
  ARRAY['Ajusta el respaldo y el rodillo sobre los tobillos.','Flexiona las rodillas llevando el rodillo hacia abajo/atrás.','Extiende con control sin dejar que los pesos choquen.','Error típico: levantarte del asiento o usar impulso.','Exhala al flexionar.','Progresión: más peso o una pierna. Alternativa: curl femoral tumbado.','Estándar: rango completo de flexión de rodilla en cada rep.']::text[], 'upper legs', 'Isquios', NULL,
  'Máquina', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Curl femoral sentado', ARRAY['Seated Leg Curl','Curl femoral sentado','seated leg curl']::text[], ARRAY['hamstrings']::text[], ARRAY['calves']::text[], ARRAY['Máquina']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Curl femoral tumbado', 'Curl femoral tumbado', 'Gym', 'Lying Leg Curl', 'Curl femoral en máquina tumbado boca abajo.',
  ARRAY['Túmbate boca abajo; rodillo sobre los tendones de Aquiles.','Flexiona las rodillas llevando los talones hacia los glúteos.','Baja con control hasta casi extensión sin bloquear de golpe.','Error típico: arching lumbar o levantar las caderas.','Exhala al flexionar.','Progresión: más peso. Alternativa: curl femoral sentado.','Estándar: talones cerca de glúteos y bajada controlada.']::text[], 'upper legs', 'Isquios', NULL,
  'Máquina', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Curl femoral tumbado', ARRAY['Lying Leg Curl','Curl femoral tumbado','lying leg curl']::text[], ARRAY['hamstrings']::text[], ARRAY['calves','glutes']::text[], ARRAY['Máquina']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Pec deck', 'Pec deck', 'Gym', 'Pec Deck', 'Aperturas en máquina pec deck / mariposa; pecho con trayectoria fija.',
  ARRAY['Siéntate con la espalda pegada; antebrazos en los pads o agarres en manos.','Cierra en arco hasta juntar los pads delante del pecho.','Abre con control hasta estirar sin forzar el hombro.','Error típico: empujar con los trapecios o rebotar al cierre.','Exhala al cerrar.','Progresión: más peso. Alternativa: aperturas con mancuernas.','Estándar: cierre completo delante del pecho en cada rep.']::text[], 'chest', 'Pecho', NULL,
  'Máquina', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Pec deck', ARRAY['Pec Deck','Pec deck','pec deck']::text[], ARRAY['chest']::text[], ARRAY['shoulders']::text[], ARRAY['Máquina']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Abducción de cadera en máquina', 'Abducción de cadera en máquina', 'Gym', 'Hip Abduction Machine', 'Abducción de cadera sentado en máquina (glúteo medio).',
  ARRAY['Siéntate con la espalda apoyada; almohadillas en la cara externa de las rodillas/muslos.','Abre las piernas contra la resistencia sin arching lumbar.','Vuelve al centro con control.','Error típico: empujar con los pies o inclinarte hacia delante.','Exhala al abrir.','Progresión: más peso o pausa en apertura.','Estándar: apertura controlada hasta el tope cómodo de la máquina.']::text[], 'upper legs', 'Glúteos', NULL,
  'Máquina', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Abducción de cadera en máquina', ARRAY['Hip Abduction Machine','Abducción de cadera en máquina','hip abduction machine']::text[], ARRAY['glutes']::text[], ARRAY['core']::text[], ARRAY['Máquina']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Aducción de cadera en máquina', 'Aducción de cadera en máquina', 'Gym', 'Hip Adduction Machine', 'Aducción de cadera sentado en máquina (aductores).',
  ARRAY['Siéntate con almohadillas en la cara interna de las rodillas/muslos.','Cierra las piernas contra la resistencia de forma controlada.','Abre de nuevo sin dejar que el peso tire de golpe.','Error típico: rebotar al cierre o despegar la espalda.','Exhala al cerrar.','Progresión: más peso.','Estándar: cierre completo y apertura controlada en cada rep.']::text[], 'upper legs', 'Glúteos', NULL,
  'Máquina', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Aducción de cadera en máquina', ARRAY['Hip Adduction Machine','Aducción de cadera en máquina','hip adduction machine']::text[], ARRAY['glutes']::text[], ARRAY['adductors','core']::text[], ARRAY['Máquina']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Sentadilla en Smith', 'Sentadilla en Smith', 'Gym', 'Smith Machine Squat', 'Sentadilla guiada en máquina Smith; trayectoria fija de la barra.',
  ARRAY['Coloca la barra Smith sobre trapecios; pies algo adelantados si la máquina lo pide.','Desengancha; baja a paralelo o más con rodillas alineadas.','Empuja hasta extensión y reengancha al terminar la serie.','Error típico: pies demasiado atrás (rodillas dolorosas) o cortar profundidad.','Inhala al bajar; exhala al subir.','Progresión: más peso. Alternativa: sentadilla libre con barra.','Estándar: profundidad marcada y extensión completa arriba.']::text[], 'upper legs', 'Piernas', NULL,
  'Smith', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Sentadilla en Smith', ARRAY['Smith Machine Squat','Sentadilla en Smith','smith machine squat']::text[], ARRAY['quads']::text[], ARRAY['glutes','hamstrings','core']::text[], ARRAY['Smith']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Remo en T', 'Remo en T', 'Gym', 'T-Bar Row', 'Remo en barra T o landmine; espalda media y dorsales.',
  ARRAY['Agarra el mango de la barra T; bisagra con espalda neutra.','Tira el mango al pecho/abdomen apretando omóplatos.','Baja con control hasta estirar sin redondear la lumbar.','Error típico: usar impulso de torso o encoger el cuello.','Exhala al tirar.','Progresión: más discos. Alternativa: remo con barra.','Estándar: contacto al torso y bajada controlada en cada rep.']::text[], 'back', 'Espalda', NULL,
  'Barra T / landmine', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Remo en T', ARRAY['T-Bar Row','Remo en T','t-bar row']::text[], ARRAY['upper-back']::text[], ARRAY['lats','biceps','rear deltoids']::text[], ARRAY['Barra T / landmine']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Curl inclinado con mancuernas', 'Curl inclinado con mancuernas', 'Gym', 'Incline Dumbbell Curl', 'Curl en banco inclinado: estiramiento largo del bíceps.',
  ARRAY['Banco a ~45–60°; espalda pegada, mancuernas colgando con brazos largos.','Curl sin balancear; codos estables bajo los hombros.','Baja hasta estirar por completo el bíceps.','Error típico: arching espalda o acortar el estiramiento abajo.','Exhala al subir.','Progresión: más peso o tempo. Alternativa: curl mancuernas de pie.','Estándar: rango completo con espalda en el banco.']::text[], 'upper arms', 'Bíceps', NULL,
  'Mancuernas, Banco', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Curl inclinado con mancuernas', ARRAY['Incline Dumbbell Curl','Curl inclinado con mancuernas','incline dumbbell curl']::text[], ARRAY['biceps']::text[], ARRAY['forearms']::text[], ARRAY['Mancuernas, Banco']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Sentadilla a cajón con mancuernas', 'Sentadilla a cajón con mancuernas', 'Gym', 'Dumbbell Box Squat', 'Sentadilla a cajón con mancuernas a los lados o en goblet.',
  ARRAY['Cajón detrás; mancuernas a los lados o una en goblet.','Baja hasta sentarte breve en el cajón sin desplomarte.','Sube sin rebote empujando el suelo.','Error típico: dejarte caer en el cajón o perder el pecho alto.','Inhala al bajar; exhala al subir.','Progresión: más peso o caja más baja. Alternativa: box squat con barra.','Estándar: contacto controlado con el cajón y extensión completa arriba.']::text[], 'upper legs', 'Piernas', NULL,
  'Mancuernas, Cajón', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Sentadilla a cajón con mancuernas', ARRAY['Dumbbell Box Squat','Sentadilla a cajón con mancuernas','dumbbell box squat']::text[], ARRAY['quads']::text[], ARRAY['glutes','hamstrings','core']::text[], ARRAY['Mancuernas, Cajón']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Sentadilla búlgara con mancuernas', 'Sentadilla búlgara con mancuernas', 'Gym', 'Dumbbell Bulgarian Split Squat', 'Búlgara con el pie de atrás elevado y mancuernas a los lados.',
  ARRAY['Pie trasero en banco; mancuernas a los lados; torso erguido.','Baja hasta el muslo delantero paralelo (o más) con rodilla alineada.','Empuja el suelo con el pie delantero hasta extensión.','Error típico: empujar con el pie de atrás o inclinarte en exceso.','Exhala al subir; completa el lado antes de cambiar.','Progresión: más peso. Alternativa: búlgara a peso corporal.','Estándar: profundidad marcada y control en cada rep.']::text[], 'upper legs', 'Piernas', NULL,
  'Mancuernas, Banco', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Sentadilla búlgara con mancuernas', ARRAY['Dumbbell Bulgarian Split Squat','Sentadilla búlgara con mancuernas','dumbbell bulgarian split squat']::text[], ARRAY['quads']::text[], ARRAY['glutes','hamstrings','core']::text[], ARRAY['Mancuernas, Banco']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Woodchop en polea', 'Woodchop en polea', 'Gym', 'Cable Woodchop', 'Chop en polea (alto-bajo o bajo-alto): oblicuos y anti-rotación.',
  ARRAY['Colócate de lado a la polea; agarra el mango con ambas manos.','Lleva el mango en diagonal cruzando el cuerpo (alto→bajo o bajo→alto).','Gira desde el tronco con cadera estable; brazos semi-extendidos.','Error típico: solo mover los brazos o despegar los pies.','Exhala en el corte diagonal.','Progresión: más peso o más control. Alternativa: Pallof press.','Estándar: diagonal completa a cada lado según el esquema.']::text[], 'waist', 'Core', NULL,
  'Polea', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Woodchop en polea', ARRAY['Cable Woodchop','Woodchop en polea','cable woodchop']::text[], ARRAY['core']::text[], ARRAY['shoulders','obliques']::text[], ARRAY['Polea']::text[],
  'open_sources:phase_e_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['leg extension','Leg Extension','machine leg extension']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_e_alias_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Extensión de cuádriceps';

UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['preacher curl','Preacher Curl']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_e_alias_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Curl predicador';

UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['tricep pushdown','triceps pushdown','Triceps Pushdown']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_e_alias_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Extensión tríceps polea';

UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['cable face pull','Cable Face Pull']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_e_alias_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Face pull';

UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['arnold press dumbbell','Arnold Press Dumbbell']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_e_alias_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Press Arnold';

UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['zancadas caminando','walking lunges','Walking Lunges']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_e_alias_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Walking lunge';

UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['bulgarian split squat','Bulgarian Split Squat']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_e_alias_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Sentadilla búlgara';

