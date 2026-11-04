-- Phase C: selective CrossFit gaps without duplicates + near-dup alias enrichments
-- Catalog grows 302 → 318. Near-dups become aliases on existing catalog_key.

-- Near-dup aliases → Overhead Lunge (catalog:Overhead Lunge)
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['barbell overhead lunge','bb overhead lunge','Barbell Overhead Lunge','oh lunge with barbell']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_c_near_dup_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Overhead Lunge';

-- Near-dup aliases → Air bike (catalog:Air bike)
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['assault bike','assaultbike','Assault Bike','echo bike','fan bike']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_c_near_dup_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Air bike';

-- Near-dup aliases → Devil press (catalog:Devil press)
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['devil''s press','devils press','Devils Press','Devil''s Press']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_c_near_dup_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Devil press';

-- Near-dup aliases → Goblet squat (catalog:Goblet squat)
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['dumbbell goblet squat','db goblet squat','Dumbbell Goblet Squat','goblet squat mancuerna']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_c_near_dup_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Goblet squat';

-- Near-dup aliases → Fondos en paralelas (catalog:Fondos en paralelas)
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['bar dip','bar dips','Bar Dip','dips en barra']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_c_near_dup_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Fondos en paralelas';

-- Near-dup aliases → Fondos en anillas (catalog:Fondos en anillas)
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['ring dip','ring dips','Ring Dip']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_c_near_dup_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Fondos en anillas';

-- Near-dup aliases → Dumbbell Snatch (catalog:Snatch mancuerna)
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['db snatch full','single arm db snatch']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_c_near_dup_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Snatch mancuerna';

-- Near-dup aliases → Dumbbell Clean (catalog:Clean mancuerna)
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['db clean full','single arm db clean']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_c_near_dup_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Clean mancuerna';

-- Near-dup aliases → Dumbbell Thruster (catalog:Thruster mancuernas)
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['db thrusters','dumbbell thrusters']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_c_near_dup_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Thruster mancuernas';

-- Near-dup aliases → Walking lunge (catalog:Walking lunge)
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['bodyweight walking lunge','walking lunges']::text[]))
),
    metadata_source = COALESCE(metadata_source, '') || '+phase_c_near_dup_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Walking lunge';

-- Dumbbell Power Snatch
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Power Snatch', 'Dumbbell Power Snatch', 'CrossFit', 'Dumbbell Power Snatch', 'Arrancada de potencia con mancuerna: recepción overhead sin sentadilla profunda.',
  ARRAY['Mancuerna entre los pies.','Extiende y recibe overhead en media sentadilla.','Baja y repite o cambia de mano.']::text[], 'full body', 'Hombros', 'CrossFit',
  'Mancuerna', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Dumbbell Power Snatch', ARRAY['db power snatch','power snatch mancuerna','arrancada potencia mancuerna','db p snatch','Arrancada de potencia con mancuerna','Dumbbell Power Snatch']::text[], ARRAY['deltoids','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Mancuerna']::text[],
  'open_sources:phase_c_20261104', ARRAY['shoulder','hip','knee','spine']::text[], ARRAY['dumbbell']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Dumbbell Power Clean
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Power Clean', 'Dumbbell Power Clean', 'CrossFit', 'Dumbbell Power Clean', 'Cargada de potencia con mancuerna a rack, sin sentadilla profunda.',
  ARRAY['Mancuerna en el suelo.','Extiende cadera y recibe en rack al hombro.','Párate bloqueado.']::text[], 'full body', 'Piernas', 'CrossFit',
  'Mancuerna', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Dumbbell Power Clean', ARRAY['db power clean','power clean mancuerna','cargada potencia mancuerna','db pc','Cargada de potencia con mancuerna','Dumbbell Power Clean']::text[], ARRAY['quadriceps','deltoids']::text[], ARRAY['trapezius','abs']::text[], ARRAY['Mancuerna']::text[],
  'open_sources:phase_c_20261104', ARRAY['hip','knee','shoulder','spine']::text[], ARRAY['dumbbell']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Dumbbell Push Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Push Press', 'Dumbbell Push Press', 'CrossFit', 'Dumbbell Push Press', 'Push press con mancuernas: dip de piernas e impulso a overhead.',
  ARRAY['Mancuernas en rack.','Dip corto y drive.','Bloquea overhead.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Dumbbell Push Press', ARRAY['db push press','push press mancuernas','pp mancuernas','db pp','Push press con mancuernas','Dumbbell Push Press']::text[], ARRAY['deltoids']::text[], ARRAY['triceps','gluteal']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_c_20261104', ARRAY['shoulder','elbow','hip','knee']::text[], ARRAY['dumbbell']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Dumbbell Push Jerk
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Push Jerk', 'Dumbbell Push Jerk', 'CrossFit', 'Dumbbell Push Jerk', 'Push jerk con mancuernas: dip, drive y recepción con pies en paralelo.',
  ARRAY['Mancuernas en rack.','Dip y drive.','Recibe con brazos bloqueados y pies paralelos.']::text[], 'full body', 'Hombros', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Dumbbell Push Jerk', ARRAY['db push jerk','push jerk mancuernas','db pj','jerk mancuernas paralelo','Push jerk con mancuernas','Dumbbell Push Jerk']::text[], ARRAY['deltoids','quadriceps']::text[], ARRAY['triceps','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_c_20261104', ARRAY['shoulder','elbow','hip','knee','ankle']::text[], ARRAY['dumbbell']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Dumbbell Overhead Squat
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Overhead Squat', 'Dumbbell Overhead Squat', 'CrossFit', 'Dumbbell Overhead Squat', 'Sentadilla con mancuernas bloqueadas overhead.',
  ARRAY['Mancuernas overhead bloqueadas.','Sentadilla profunda con torso vertical.','Sube manteniendo el lockout.']::text[], 'full body', 'Piernas', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Dumbbell Overhead Squat', ARRAY['db ohs','db overhead squat','ohs mancuernas','sentadilla overhead mancuernas','Sentadilla overhead con mancuernas','Dumbbell Overhead Squat']::text[], ARRAY['quadriceps','deltoids']::text[], ARRAY['gluteal','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_c_20261104', ARRAY['shoulder','hip','knee','ankle','spine']::text[], ARRAY['dumbbell']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Dumbbell Walking Lunge
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Walking Lunge', 'Dumbbell Walking Lunge', 'CrossFit', 'Dumbbell Walking Lunge', 'Zancadas caminando con mancuernas a los lados o en rack.',
  ARRAY['Mancuernas a los lados o en rack.','Zancada caminando con control.','Alterna piernas en cada paso.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Dumbbell Walking Lunge', ARRAY['db walking lunge','walking lunge mancuernas','zancadas mancuernas','db walk lunges','Zancadas caminando con mancuernas','Dumbbell Walking Lunge']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_c_20261104', ARRAY['hip','knee','ankle','spine']::text[], ARRAY['dumbbell']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Dumbbell Hang Clean and Jerk
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Hang Clean and Jerk', 'Dumbbell Hang Clean and Jerk', 'CrossFit', 'Dumbbell Hang Clean and Jerk', 'Desde hang: cargada a rack y envión overhead con mancuernas.',
  ARRAY['Desde hang, carga a rack.','Dip y envía overhead.','Bloquea y repite.']::text[], 'full body', 'Hombros', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Dumbbell Hang Clean and Jerk', ARRAY['db hang c&j','db hang clean and jerk','hang c&j mancuernas','cargada envion colgante mancuernas','Cargada y envión colgante con mancuernas','Dumbbell Hang Clean and Jerk']::text[], ARRAY['deltoids','quadriceps']::text[], ARRAY['gluteal','triceps','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_c_20261104', ARRAY['shoulder','hip','knee','elbow','spine']::text[], ARRAY['dumbbell']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Double Kettlebell Front Rack Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Double Kettlebell Front Rack Carry', 'Double Kettlebell Front Rack Carry', 'CrossFit', 'Double Kettlebell Front Rack Carry', 'Caminata con dos kettlebells en front rack.',
  ARRAY['Dos KB en rack frontal.','Camina alto sin dejar caer los codos.','Pasos cortos y controlados.']::text[], 'full body', 'Core', 'CrossFit',
  'Kettlebells', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Double Kettlebell Front Rack Carry', ARRAY['double kb front rack carry','2 kb front rack carry','farmer rack kb','porte rack dos kb','Porte en rack frontal con dos kettlebells','Double Kettlebell Front Rack Carry']::text[], ARRAY['abs','deltoids']::text[], ARRAY['quadriceps','forearm']::text[], ARRAY['Kettlebells']::text[],
  'open_sources:phase_c_20261104', ARRAY['shoulder','spine','hip','knee','ankle']::text[], ARRAY['kettlebell']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Double Kettlebell Overhead Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Double Kettlebell Overhead Carry', 'Double Kettlebell Overhead Carry', 'CrossFit', 'Double Kettlebell Overhead Carry', 'Caminata con dos kettlebells bloqueadas overhead.',
  ARRAY['KB bloqueadas overhead.','Camina sin perder el lockout.','Núcleo firme.']::text[], 'full body', 'Hombros', 'CrossFit',
  'Kettlebells', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Double Kettlebell Overhead Carry', ARRAY['double kb overhead carry','2 kb oh carry','porte overhead dos kb','kb waiters walk doble','Porte overhead con dos kettlebells','Double Kettlebell Overhead Carry']::text[], ARRAY['deltoids','abs']::text[], ARRAY['trapezius','forearm']::text[], ARRAY['Kettlebells']::text[],
  'open_sources:phase_c_20261104', ARRAY['shoulder','elbow','spine','wrist']::text[], ARRAY['kettlebell']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Kettlebell Clean and Jerk
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Kettlebell Clean and Jerk', 'Kettlebell Clean and Jerk', 'CrossFit', 'Kettlebell Clean and Jerk', 'Cargada a rack y envión overhead con kettlebell (un brazo o alternando).',
  ARRAY['KB del suelo a rack.','Dip y envía overhead.','Bloquea y baja a rack o suelo.']::text[], 'full body', 'Hombros', 'CrossFit',
  'Kettlebell', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Kettlebell Clean and Jerk', ARRAY['kb c&j','kb clean and jerk','kettlebell c&j','cargada envion kb','Cargada y envión con kettlebell','Kettlebell Clean and Jerk']::text[], ARRAY['deltoids','quadriceps']::text[], ARRAY['gluteal','triceps','abs']::text[], ARRAY['Kettlebell']::text[],
  'open_sources:phase_c_20261104', ARRAY['shoulder','hip','knee','elbow','spine']::text[], ARRAY['kettlebell']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Kettlebell Overhead Lunge
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Kettlebell Overhead Lunge', 'Kettlebell Overhead Lunge', 'CrossFit', 'Kettlebell Overhead Lunge', 'Zancada con kettlebell bloqueada overhead.',
  ARRAY['KB overhead bloqueada.','Zancada sin perder lockout.','Alterna o camina.']::text[], 'full body', 'Piernas', 'CrossFit',
  'Kettlebell', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Kettlebell Overhead Lunge', ARRAY['kb oh lunge','kb overhead lunge','zancada overhead kb','overhead lunge kettlebell','Zancada overhead con kettlebell','Kettlebell Overhead Lunge']::text[], ARRAY['quadriceps','deltoids']::text[], ARRAY['gluteal','abs']::text[], ARRAY['Kettlebell']::text[],
  'open_sources:phase_c_20261104', ARRAY['shoulder','hip','knee','ankle','spine']::text[], ARRAY['kettlebell']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Kettlebell Push Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Kettlebell Push Press', 'Kettlebell Push Press', 'CrossFit', 'Kettlebell Push Press', 'Push press con kettlebell: dip e impulso a overhead.',
  ARRAY['KB en rack.','Dip corto y drive.','Bloquea overhead.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Kettlebell', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Kettlebell Push Press', ARRAY['kb push press','push press kb','kb pp','pressa impulso kb','Push press con kettlebell','Kettlebell Push Press']::text[], ARRAY['deltoids']::text[], ARRAY['triceps','gluteal']::text[], ARRAY['Kettlebell']::text[],
  'open_sources:phase_c_20261104', ARRAY['shoulder','elbow','hip','knee']::text[], ARRAY['kettlebell']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Jumping Pull-Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Jumping Pull-Up', 'Jumping Pull-Up', 'CrossFit', 'Jumping Pull-Up', 'Dominada asistida con salto de piernas hasta que la barbilla pase la barra.',
  ARRAY['Salta y tira a la vez.','Barbilla por encima de la barra.','Baja con control.']::text[], 'back', 'Espalda', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Jumping Pull-Up', ARRAY['jumping pull up','jumping pullups','dominadas con salto','kipping jump pull-up','Dominada con salto','Jumping Pull-Up']::text[], ARRAY['upper-back']::text[], ARRAY['biceps','deltoids','calves']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_c_20261104', ARRAY['shoulder','elbow','hip','knee','ankle']::text[], ARRAY['pullup_bar']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Burpee Muscle-Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Burpee Muscle-Up', 'Burpee Muscle-Up', 'CrossFit', 'Burpee Muscle-Up', 'Burpee seguido de muscle-up a barra (o anillas según WOD).',
  ARRAY['Burpee completo.','Salta a la barra y completa el muscle-up.','Baja y repite.']::text[], 'full body', 'Espalda', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Burpee Muscle-Up', ARRAY['burpee muscle up','burpee mu','burpee bar muscle up','burpee a muscle-up','Burpee Muscle-Up']::text[], ARRAY['upper-back','chest']::text[], ARRAY['deltoids','quadriceps','abs']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_c_20261104', ARRAY['shoulder','elbow','hip','knee','spine']::text[], ARRAY['pullup_bar']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Bear Hug Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Bear Hug Carry', 'Bear Hug Carry', 'CrossFit', 'Bear Hug Carry', 'Caminata abrazando un saco, D-ball u objeto pesado al pecho.',
  ARRAY['Abraza la carga al pecho.','Camina con pasos cortos.','No dejes caer la carga.']::text[], 'full body', 'Core', 'CrossFit',
  'Saco', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Bear Hug Carry', ARRAY['bear hug carry','bearhug carry','porte abrazo oso','sandbag bear hug','Porte en abrazo de oso']::text[], ARRAY['abs','quadriceps']::text[], ARRAY['gluteal','forearm','upper-back']::text[], ARRAY['Saco']::text[],
  'open_sources:phase_c_20261104', ARRAY['spine','hip','knee','ankle']::text[], ARRAY['sandbag']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

-- Box Squat
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Box Squat', 'Box Squat', 'CrossFit', 'Box Squat', 'Sentadilla con barra hasta sentarse brevemente en un cajón y subir.',
  ARRAY['Barra en espalda.','Baja hasta el cajón con control.','Siéntate breve y sube sin rebote.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name = EXCLUDED.name,
  display_name_en = EXCLUDED.display_name_en,
  mobile_description = EXCLUDED.mobile_description,
  mobile_instructions = EXCLUDED.mobile_instructions,
  mobile_body_part = EXCLUDED.mobile_body_part,
  mobile_muscle_group = EXCLUDED.mobile_muscle_group,
  mobile_sport_tag = EXCLUDED.mobile_sport_tag,
  mobile_equipment = EXCLUDED.mobile_equipment,
  is_active = true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source, updated_at
) VALUES (
  'catalog:Box Squat', ARRAY['box squat','sentadilla al cajon','sentadilla cajón','box squats','Sentadilla a cajón']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_c_20261104', ARRAY['hip','knee','ankle','spine']::text[], ARRAY['barbell','plyometric_box']::text[],
  'editorial_phase_c_v1', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  joint_demands = EXCLUDED.joint_demands,
  required_equipment = EXCLUDED.required_equipment,
  metadata_source = EXCLUDED.metadata_source,
  joint_demands_source = EXCLUDED.joint_demands_source,
  updated_at = now();

