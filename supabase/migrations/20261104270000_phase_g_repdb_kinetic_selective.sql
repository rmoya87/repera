-- Phase G: selective RepDB/Kinetic gaps (6)
-- Catalog 470 → 476. Original coaching; RepDB attribution in app Settings. No third-party media.

INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Almeja con banda', 'Almeja con banda', 'Gym', 'Banded Clamshell', 'Clamshell con minibanda: tumbado de lado, abre la rodilla de arriba sin girar la pelvis; glúteo medio.',
  ARRAY['Túmbate de lado; rodillas flexionadas ~90°; banda encima de las rodillas; pies juntos.','Abre la rodilla de arriba como una almeja sin separar los pies ni rotar la pelvis.','Baja con control hasta casi tocar sin perder tensión de la banda.','Error típico: rodar la cadera atrás o abrir con el lumbar.','Exhala al abrir; completa el lado y cambia.','Progresión: banda más fuerte o tempo lento. Alternativa: abducción en máquina.','Estándar: pelvis quieta y apertura completa en cada rep.']::text[], 'upper legs', 'Glúteos', 'CrossFit',
  'Banda', true
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
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Almeja con banda', ARRAY['Clamshell','Clamshells','Banded Clamshell','banded clamshell','almeja','almejas','clamshell con banda','Almeja con banda']::text[], ARRAY['gluteal']::text[], ARRAY['abs']::text[], ARRAY['Banda']::text[],
  'open_sources:phase_g_repdb_kinetic_20261104', 'beginner', now()
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
  'catalog:Hidrante con banda', 'Hidrante con banda', 'Gym', 'Banded Fire Hydrant', 'Fire hydrant con banda: a cuatro apoyos, eleva la rodilla hacia el lado; glúteo medio y estabilidad de cadera.',
  ARRAY['A cuatro apoyos; banda encima de las rodillas; espalda neutra.','Eleva una rodilla hacia el lado manteniendo la cadera cuadrada; pie flexionado.','Baja con control sin tocar el suelo entre reps si buscas tensión continua.','Error típico: arching lumbar o abrir rotando todo el torso.','Exhala al subir; completa el lado.','Progresión: banda más fuerte o pausa arriba. Alternativa: almeja con banda.','Estándar: rodilla a la altura de la cadera sin perder el cuadrúpedo.']::text[], 'upper legs', 'Glúteos', 'CrossFit',
  'Banda', true
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
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Hidrante con banda', ARRAY['Fire Hydrant','Fire hydrant','Banded Fire Hydrant','fire hydrants','hidrante','hidrante de fuego','Hidrante con banda']::text[], ARRAY['gluteal']::text[], ARRAY['abs']::text[], ARRAY['Banda']::text[],
  'open_sources:phase_g_repdb_kinetic_20261104', 'beginner', now()
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
  'catalog:TKE con banda', 'TKE con banda', 'Gym', 'Banded Terminal Knee Extension', 'Terminal knee extension (TKE) con banda: extensión final de rodilla de pie; cuádriceps (VMO) y control de rodilla.',
  ARRAY['Ancla la banda detrás a la altura de la rodilla; pásala por detrás de la rodilla de trabajo; pie adelantado.','Parte con la rodilla ligeramente flexionada y extiende hasta bloqueo suave contra la tensión.','Flexiona un poco y repite sin perder la alineación rodilla-pie.','Error típico: empujar con la cadera o hiperextender de golpe.','Exhala al extender; completa el lado.','Progresión: banda más fuerte o más reps. Alternativa: extensión de cuádriceps en máquina con rango corto.','Estándar: extensión terminal controlada sin dolor de rodilla.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Banda', true
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
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:TKE con banda', ARRAY['TKE','Terminal Knee Extension','Banded Terminal Knee Extension','banded TKE','extensión terminal de rodilla','TKE con banda']::text[], ARRAY['quadriceps']::text[], ARRAY[]::text[], ARRAY['Banda']::text[],
  'open_sources:phase_g_repdb_kinetic_20261104', 'beginner', now()
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
  'catalog:Windshield wipers', 'Windshield wipers', 'Gym', 'Windshield Wipers', 'Limpiaparabrisas: tumbado o colgado, lleva las piernas de lado a lado con control; oblicuos y core.',
  ARRAY['Tumbado con brazos en cruz (o colgado de barra); piernas juntas extendidas o semi-flexionadas.','Baja las piernas hacia un lado sin despegar hombros/omóplatos; vuelve al centro y al otro lado.','Mantén el lumbar pegado o la pelvis controlada; no rebotes.','Error típico: usar impulso o rotar toda la espalda alta del suelo.','Exhala al bajar a cada lado.','Progresión: piernas más rectas o colgado. Alternativa: Russian twist.','Estándar: arco controlado lado a lado sin perder el anclaje de torso.']::text[], 'waist', 'Core', 'Gimnasia',
  'Peso corporal', true
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
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Windshield wipers', ARRAY['Windshield Wipers','Supine Windshield Wipers','windshield wiper','limpiaparabrisas','limpiaparabrisas tumbado','Windshield wipers']::text[], ARRAY['abs','obliques']::text[], ARRAY[]::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_g_repdb_kinetic_20261104', 'intermediate', now()
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
  'catalog:Dragon flag', 'Dragon flag', 'Gym', 'Dragon Flag', 'Dragon flag: cuerpo rígido en línea desde un anclaje de cabeza/hombros; anti-extensión avanzada de core.',
  ARRAY['Túmbate en banco; agarra el borde detrás de la cabeza; hombros anclados.','Eleva el cuerpo rígido (hombros a pies) hasta casi vertical; baja en línea sin romper la cadera.','Controla la bajada hasta el ángulo que mantengas rígido; no dejes caer la lumbar.','Error típico: picar de cadera o flexionar solo de rodillas.','Exhala en la bajada controlada.','Progresión: negatives lentos o rodillas recogidas. Alternativa: hollow rock / hollow hold.','Estándar: línea recta hombros-cadera-tobillos en todo el rango usable.']::text[], 'waist', 'Core', 'Gimnasia',
  'Peso corporal', true
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
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Dragon flag', ARRAY['Dragon Flag','dragon flags','bandera del dragón','dragonflag','Dragon flag']::text[], ARRAY['abs']::text[], ARRAY['gluteal','upper-back']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_g_repdb_kinetic_20261104', 'advanced', now()
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
  'catalog:Planche lean', 'Planche lean', 'Gym', 'Planche Lean', 'Planche lean: en plancha alta, proyecta los hombros delante de las muñecas; progresión hacia planche.',
  ARRAY['Plancha alta; manos bajo hombros; body hollow (glúteos y abs activos).','Inclina el cuerpo hacia delante llevando los hombros por delante de las muñecas sin hundir la lumbar.','Mantén o haz micro-pulsos; vuelve a la plancha neutra con control.','Error típico: arquear la espalda o subir las caderas en pica.','Exhala al inclinarte; respira corto en la retención.','Progresión: más lean o planche tuck. Alternativa: pike push-up / crow.','Estándar: línea de cuerpo rígida con proyección clara de hombros.']::text[], 'shoulders', 'Hombros', 'Gimnasia',
  'Peso corporal', true
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
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Planche lean', ARRAY['Planche Lean','planche lean','lean planche','inclinación de planche','planche lean hold','Planche lean']::text[], ARRAY['deltoids']::text[], ARRAY['chest','triceps','abs']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_g_repdb_kinetic_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();

