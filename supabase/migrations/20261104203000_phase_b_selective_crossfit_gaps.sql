-- Phase B: selective CrossFit gaps (Open WOD), EN titles + bilingual aliases

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Bike Erg', 'Bike Erg', 'CrossFit', 'Bike Erg', 'BikeErg Concept2 por calorías, metros o tiempo.',
  ARRAY['Ajusta sillín y damper del BikeErg.','Pedalea con torso estable y ritmo constante.','Registra calorías o metros según el WOD.']::text[], 'cardio', 'Cardio', 'CrossFit',
  'BikeErg', true
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
  'catalog:Bike Erg', ARRAY['bikeerg','c2 bike','bici ergometro','Bike Erg','Bici ergómetro']::text[], ARRAY[]::text[], ARRAY['quadriceps','hamstring','gluteal']::text[], ARRAY['BikeErg']::text[],
  'open_sources:phase_b_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['stationary_bike']::text[],
  'editorial_phase_b_v1', now()
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

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Ab Mat Sit-Up', 'Ab Mat Sit-Up', 'CrossFit', 'Ab Mat Sit-Up', 'Sit-up con AbMat: hombros al suelo y tocar pies o diana.',
  ARRAY['Coloca el AbMat bajo la zona lumbar.','Hombros y omóplatos tocan el suelo en cada repetición.','Sube hasta tocar los pies o la marca del WOD.']::text[], 'waist', 'Core', 'CrossFit',
  'AbMat', true
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
  'catalog:Ab Mat Sit-Up', ARRAY['abmat sit-up','sit-up abmat','Ab Mat Sit-Up','Sit-up con AbMat']::text[], ARRAY['abs']::text[], ARRAY[]::text[], ARRAY['AbMat']::text[],
  'open_sources:phase_b_20261104', ARRAY['hip','spine']::text[], ARRAY[]::text[],
  'editorial_phase_b_v1', now()
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

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Overhead Lunge', 'Overhead Lunge', 'CrossFit', 'Overhead Lunge', 'Zancada con barra bloqueada por encima de la cabeza.',
  ARRAY['Bloquea la barra overhead con codos extendidos.','Da una zancada manteniendo el lockout.','Rodilla trasera cerca del suelo con control.']::text[], 'full body', 'Piernas', 'CrossFit',
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
  'catalog:Overhead Lunge', ARRAY['oh lunge','overhead lunges','zancada overhead','Overhead Lunge']::text[], ARRAY['quadriceps','deltoids']::text[], ARRAY['gluteal','abs']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_b_20261104', ARRAY['shoulder','hip','knee','ankle','spine']::text[], ARRAY['barbell']::text[],
  'editorial_phase_b_v1', now()
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

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Alternating Dumbbell Snatch', 'Alternating Dumbbell Snatch', 'CrossFit', 'Alternating Dumbbell Snatch', 'Arrancada con mancuerna alternando el brazo.',
  ARRAY['Coloca la mancuerna entre los pies.','Extiende cadera y recibe overhead con un brazo.','Cambia de mano en el suelo o según el estándar.']::text[], 'full body', 'Hombros', 'CrossFit',
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
  'catalog:Alternating Dumbbell Snatch', ARRAY['alt db snatch','arrancada alterna mancuerna','Alternating Dumbbell Snatch']::text[], ARRAY['deltoids','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Mancuerna']::text[],
  'open_sources:phase_b_20261104', ARRAY['shoulder','hip','knee','spine']::text[], ARRAY['dumbbell']::text[],
  'editorial_phase_b_v1', now()
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

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Overhead Lunge', 'Dumbbell Overhead Lunge', 'CrossFit', 'Dumbbell Overhead Lunge', 'Zancada con mancuerna(s) bloqueada(s) overhead.',
  ARRAY['Lleva la mancuerna o el par a overhead bloqueado.','Zancada sin perder el lockout.','Alterna piernas o camina según el WOD.']::text[], 'full body', 'Piernas', 'CrossFit',
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
  'catalog:Dumbbell Overhead Lunge', ARRAY['db oh lunge','zancada overhead mancuerna','Dumbbell Overhead Lunge']::text[], ARRAY['quadriceps','deltoids']::text[], ARRAY['abs','gluteal']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_b_20261104', ARRAY['shoulder','hip','knee','ankle','spine']::text[], ARRAY['dumbbell']::text[],
  'editorial_phase_b_v1', now()
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

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dead Hang', 'Dead Hang', 'CrossFit', 'Dead Hang', 'Suspensión de la barra con brazos extendidos.',
  ARRAY['Agarra la barra con brazos extendidos.','Pies fuera del suelo; registra segundos.','Hombros activos o pasivos según la pizarra.']::text[], 'back', 'Antebrazos', 'CrossFit',
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
  'catalog:Dead Hang', ARRAY['dead hang','suspension barra','colgado en barra','Dead Hang','Suspensión en barra']::text[], ARRAY['forearm']::text[], ARRAY['upper-back','deltoids']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_b_20261104', ARRAY['shoulder','elbow','wrist']::text[], ARRAY['pullup_bar']::text[],
  'editorial_phase_b_v1', now()
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

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Box Step-Over', 'Box Step-Over', 'CrossFit', 'Box Step-Over', 'Paso sobre el cajón hasta el otro lado, sin exigir salto.',
  ARRAY['Coloca un pie sobre el cajón.','Pasa al otro lado hasta apoyar ambos pies en el suelo.','Alterna la pierna de ataque si se prescribe.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Cajón', true
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
  'catalog:Box Step-Over', ARRAY['box step over','paso sobre cajon','Box Step-Over','Paso sobre cajón']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['calves']::text[], ARRAY['Cajón']::text[],
  'open_sources:phase_b_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['plyometric_box']::text[],
  'editorial_phase_b_v1', now()
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

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:D-Ball Clean', 'D-Ball Clean', 'CrossFit', 'D-Ball Clean', 'Cargada de D-ball hasta pecho u hombros.',
  ARRAY['Abraza el D-ball desde el suelo.','Extiende cadera y recibe el balón en pecho u hombros.','Devuelve el balón al suelo con control.']::text[], 'full body', 'Piernas', 'CrossFit',
  'D-ball', true
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
  'catalog:D-Ball Clean', ARRAY['dball clean','cargada d-ball','D-Ball Clean','Cargada con D-ball']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['abs','deltoids']::text[], ARRAY['D-ball']::text[],
  'open_sources:phase_b_20261104', ARRAY['hip','knee','spine','shoulder']::text[], ARRAY['medicine_ball']::text[],
  'editorial_phase_b_v1', now()
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

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:D-Ball Over Shoulder', 'D-Ball Over Shoulder', 'CrossFit', 'D-Ball Over Shoulder', 'D-ball del suelo pasando por encima del hombro.',
  ARRAY['Levanta el D-ball desde el suelo.','Pasa el balón por encima de un hombro.','Alterna hombro si el WOD lo indica.']::text[], 'full body', 'Piernas', 'CrossFit',
  'D-ball', true
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
  'catalog:D-Ball Over Shoulder', ARRAY['dball over shoulder','d-ball al hombro','D-Ball Over Shoulder']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['abs','deltoids']::text[], ARRAY['D-ball']::text[],
  'open_sources:phase_b_20261104', ARRAY['hip','knee','spine','shoulder']::text[], ARRAY['medicine_ball']::text[],
  'editorial_phase_b_v1', now()
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

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Seated Box Jump', 'Seated Box Jump', 'CrossFit', 'Seated Box Jump', 'Salto al cajón partiendo desde sentado.',
  ARRAY['Siéntate en un cajón o banco bajo estable.','Salta al cajón objetivo y extiende cadera.','Baja y vuelve a la posición sentada.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Cajón', true
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
  'catalog:Seated Box Jump', ARRAY['seated box jump','salto cajon sentado','Seated Box Jump']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['calves']::text[], ARRAY['Cajón']::text[],
  'open_sources:phase_b_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['plyometric_box']::text[],
  'editorial_phase_b_v1', now()
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

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Front Squat', 'Dumbbell Front Squat', 'CrossFit', 'Dumbbell Front Squat', 'Sentadilla con mancuernas en rack frontal.',
  ARRAY['Coloca las mancuernas en rack sobre los hombros.','Baja en sentadilla con torso vertical.','Sube extendiendo cadera y rodillas.']::text[], 'upper legs', 'Piernas', 'CrossFit',
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
  'catalog:Dumbbell Front Squat', ARRAY['db front squat','sentadilla frontal mancuernas','Dumbbell Front Squat']::text[], ARRAY['quadriceps']::text[], ARRAY['gluteal','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_b_20261104', ARRAY['hip','knee','ankle','spine']::text[], ARRAY['dumbbell']::text[],
  'editorial_phase_b_v1', now()
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

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Front Rack Lunge', 'Dumbbell Front Rack Lunge', 'CrossFit', 'Dumbbell Front Rack Lunge', 'Zancada con mancuernas en front rack.',
  ARRAY['Mancuernas en front rack estable.','Da una zancada con control.','Alterna o camina según el WOD.']::text[], 'upper legs', 'Piernas', 'CrossFit',
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
  'catalog:Dumbbell Front Rack Lunge', ARRAY['db front rack lunge','zancada rack mancuernas','Dumbbell Front Rack Lunge']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_b_20261104', ARRAY['hip','knee','ankle','spine']::text[], ARRAY['dumbbell']::text[],
  'editorial_phase_b_v1', now()
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
