-- Phase F: selective FED/OEDB gym gaps + optionals (23)
-- Catalog 447 → 470. No third-party media.


INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Encogimientos', 'Encogimientos', 'Gym', 'Barbell Shrug', 'Encogimientos de trapecio con barra: eleva los hombros hacia las orejas sin flexionar codos.',
  ARRAY['Barra colgando a brazos extendidos; pies al ancho de cadera.','Encoge trapecios elevando los hombros; pausa breve arriba.','Baja con control sin redondear la cervical.','Error típico: rizar los codos o girar la cabeza.','Exhala al subir.','Progresión: más peso o mancuernas. Alternativa: shrug en máquina.','Estándar: rango completo de elevación escapular en cada rep.']::text[], 'back', 'Espalda', 'CrossFit',
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
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Encogimientos', ARRAY['Barbell Shrug','barbell shrug','shrug','encogimientos de trapecio','Dumbbell Shrug','dumbbell shrug','Cable Shrugs','cable shrug','Encogimientos']::text[], ARRAY['trapezius']::text[], ARRAY['forearm']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Gemelos sentado', 'Gemelos sentado', 'Gym', 'Seated Calf Raise', 'Elevación de gemelos sentado en máquina: énfasis en sóleo con rodilla flexionada.',
  ARRAY['Siéntate; almohadilla sobre muslos; antepié en el borde.','Extiende tobillos elevando los talones; pausa arriba.','Baja hasta estirar el sóleo sin rebotar.','Error típico: usar impulso de rodillas o rango corto.','Exhala al subir.','Progresión: más peso o una pierna. Alternativa: gemelos de pie.','Estándar: extensión completa de tobillo en cada rep.']::text[], 'lower legs', 'Gemelos', 'CrossFit',
  'Máquina', true
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
  'catalog:Gemelos sentado', ARRAY['Seated Calf Raise','seated calf raise','gemelos en máquina sentado','Barbell Seated Calf Raise','Gemelos sentado']::text[], ARRAY['calves']::text[], ARRAY[]::text[], ARRAY['Máquina']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Press pecho en máquina', 'Press pecho en máquina', 'Gym', 'Machine Chest Press', 'Press de pecho sentado en máquina; trayectoria guiada para pecho y tríceps.',
  ARRAY['Ajusta asiento para que los agarres queden a la altura del pecho medio.','Empuja hasta extensión casi completa sin bloquear de golpe.','Vuelve con control hasta el tope de la máquina.','Error típico: encoger trapecios o despegar la espalda del respaldo.','Exhala al empujar.','Progresión: más peso. Alternativa: press banca o press mancuernas.','Estándar: rango completo y pecho activo en cada rep.']::text[], 'chest', 'Pecho', 'CrossFit',
  'Máquina', true
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
  'catalog:Press pecho en máquina', ARRAY['Machine Chest Press','Seated Chest Press','seated chest press','Leverage Chest Press','Cable Chest Press','press de pecho en máquina','Press pecho en máquina']::text[], ARRAY['chest']::text[], ARRAY['triceps','deltoids']::text[], ARRAY['Máquina']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Press hombro en máquina', 'Press hombro en máquina', 'Gym', 'Machine Shoulder Press', 'Press de hombros sentado en máquina; deltoides con recorrido guiado.',
  ARRAY['Asiento alto; agarres a la altura de los hombros; espalda pegada.','Empuja overhead hasta casi bloqueo sin encoger trapecios.','Baja con control hasta el tope inferior cómodo.','Error típico: arching lumbar o subir el peso con impulso de piernas.','Exhala al subir.','Progresión: más peso. Alternativa: press militar o press Arnold.','Estándar: extensión alta controlada en cada rep.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Máquina', true
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
  'catalog:Press hombro en máquina', ARRAY['Machine Shoulder Press','Seated Shoulder Press','Leverage Shoulder Press','Smith Machine Shoulder Press','press de hombros en máquina','Press hombro en máquina']::text[], ARRAY['deltoids']::text[], ARRAY['triceps']::text[], ARRAY['Máquina']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Dominadas asistidas', 'Dominadas asistidas', 'Gym', 'Assisted Pull-Up', 'Dominada con asistencia de máquina o banda; progresión hacia dominada estricta.',
  ARRAY['Elige asistencia que permita 5–8 reps controladas.','Agarre prono; tira pecho a la barra/agarres con codos abajo.','Baja a extensión casi completa sin soltar la escápula.','Error típico: kipping o no completar el rango abajo.','Exhala al subir.','Progresión: menos asistencia. Alternativa: remo invertido.','Estándar: mentón sobre la barra y bajada controlada.']::text[], 'back', 'Espalda', 'Gimnasia',
  'Máquina asistida', true
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
  'catalog:Dominadas asistidas', ARRAY['Assisted Pull-Up','assisted pull-up','Band Assisted Pull-Up','dominada asistida','pull-up asistida','Dominadas asistidas']::text[], ARRAY['upper-back']::text[], ARRAY['biceps']::text[], ARRAY['Máquina asistida']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Fondos asistidos', 'Fondos asistidos', 'Gym', 'Assisted Dip', 'Fondos en máquina asistida o con banda; pecho y tríceps con ayuda escalable.',
  ARRAY['Ajusta asistencia; agarra paralelas o pads; torso ligeramente inclinado.','Baja hasta ~90° de codo; empuja a bloqueo sin encoger trapecios.','Controla la bajada; no rebotes abajo.','Error típico: hombros encogidos o rango incompleto.','Exhala al subir.','Progresión: menos asistencia. Alternativa: fondos en banco.','Estándar: profundidad marcada y extensión arriba.']::text[], 'chest', 'Pecho', 'Gimnasia',
  'Máquina asistida', true
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
  'catalog:Fondos asistidos', ARRAY['Assisted Dip','Machine Dip','assisted dip','fondos en máquina','dips asistidos','Fondos asistidos']::text[], ARRAY['chest','triceps']::text[], ARRAY['deltoids']::text[], ARRAY['Máquina asistida']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Curl concentrado', 'Curl concentrado', 'Gym', 'Concentration Curl', 'Curl de bíceps con codo apoyado en el muslo; aísla el pico del bíceps.',
  ARRAY['Sentado; codo interno apoyado en el muslo interno; mancuerna colgando.','Flexiona el codo sin balancear el torso; aprieta arriba.','Baja hasta extensión casi completa.','Error típico: levantar el hombro o usar impulso de cadera.','Exhala al subir.','Progresión: más peso o tempo. Alternativa: curl predicador.','Estándar: codo fijo y rango completo en cada rep.']::text[], 'upper arms', 'Bíceps', 'CrossFit',
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
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Curl concentrado', ARRAY['Concentration Curl','Dumbbell Concentration Curl','concentration curl','curl de concentración','Cable Concentration Curl','Curl concentrado']::text[], ARRAY['biceps']::text[], ARRAY['forearm']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Kickback de tríceps', 'Kickback de tríceps', 'Gym', 'Triceps Kickback', 'Kickback de tríceps con mancuerna o polea; extensión de codo con húmero paralelo al suelo.',
  ARRAY['Bisagra; brazo superior pegado al torso y paralelo al suelo.','Extiende el codo hacia atrás hasta bloqueo; pausa.','Flexiona con control sin mover el hombro.','Error típico: balancear el brazo completo o abrir el codo.','Exhala al extender.','Progresión: más peso o kickback en polea. Alternativa: extensión tríceps polea.','Estándar: bloqueo completo con húmero estable.']::text[], 'upper arms', 'Tríceps', 'CrossFit',
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
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Kickback de tríceps', ARRAY['Triceps Kickback','Dumbbell Kickback','Cable Kickback','kickback','patada de tríceps','Kickback de tríceps']::text[], ARRAY['triceps']::text[], ARRAY[]::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Zancada inversa', 'Zancada inversa', 'Gym', 'Reverse Lunge', 'Zancada hacia atrás: paso atrás y bajada controlada; menos estrés de frenado que la zancada adelante.',
  ARRAY['De pie erguido; da un paso largo atrás.','Baja hasta rodilla trasera cerca del suelo; tibia delantera vertical.','Empuja con el pie delantero y vuelve a la postura inicial.','Error típico: truncar el paso o inclinarte en exceso.','Exhala al subir; alterna piernas.','Progresión: mancuernas o barra. Alternativa: zancadas caminando.','Estándar: profundidad marcada y equilibrio en cada rep.']::text[], 'upper legs', 'Piernas', 'CrossFit',
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
  'catalog:Zancada inversa', ARRAY['Reverse Lunge','Barbell Reverse Lunge','Dumbbell Reverse Lunge','reverse lunges','zancadas inversas','Alternating Reverse Lunges','Zancada inversa']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Tirón de rack', 'Tirón de rack', 'Gym', 'Rack Pull', 'Peso muerto parcial desde pins/rack a altura de rodilla o superior; carga alta y bloqueo de cadera.',
  ARRAY['Coloca la barra en pins a la altura prescrita; stance de peso muerto.','Bracea; tira hasta extensión completa de cadera y rodillas.','Baja con control hasta los pins; no rebotes.','Error típico: redondear lumbar o hiperextender arriba.','Inhala y bracea antes de tirar; exhala al bloqueo.','Progresión: más peso. Alternativa: peso muerto completo.','Estándar: bloqueo completo arriba en cada rep.']::text[], 'back', 'Espalda', 'Halterofilia',
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
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Tirón de rack', ARRAY['Rack Pull','Rack Pulls','rack pulls','tiron de rack','partial deadlift','Tirón de rack']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','trapezius','forearm']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Seal row', 'Seal row', 'Gym', 'Seal Row', 'Remo tumbado boca abajo en banco elevado (seal row); elimina impulso de torso.',
  ARRAY['Banco alto o apoyado; pecho pegado; mancuernas o barra colgando.','Tira hacia la cadera/costillas apretando omóplatos.','Baja hasta estirar sin despegar el pecho.','Error típico: arrancar el pecho o usar demasiado peso y acortar rango.','Exhala al tirar.','Progresión: más peso. Alternativa: remo con apoyo de pecho.','Estándar: pecho pegado y contacto al torso en cada rep.']::text[], 'back', 'Espalda', 'CrossFit',
  'Mancuernas, Banco', true
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
  'catalog:Seal row', ARRAY['Seal Row','seal row','prone row','remo foca','bench seal row','Seal row']::text[], ARRAY['upper-back']::text[], ARRAY['biceps','deltoids']::text[], ARRAY['Mancuernas, Banco']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Extensión tríceps overhead', 'Extensión tríceps overhead', 'Gym', 'Overhead Triceps Extension', 'Extensión de tríceps por encima de la cabeza (mancuerna, EZ o polea); énfasis en la cabeza larga.',
  ARRAY['Sentado o de pie; peso overhead con codos altos y juntos.','Flexiona solo los codos bajando el peso detrás de la cabeza.','Extiende hasta bloqueo sin abrir los codos hacia fuera.','Error típico: abrir codos o arquear la lumbar.','Exhala al extender.','Progresión: más peso o polea. Alternativa: press francés.','Estándar: bloqueo overhead con codos estables.']::text[], 'upper arms', 'Tríceps', 'CrossFit',
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
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Extensión tríceps overhead', ARRAY['Overhead Triceps Extension','Dumbbell Overhead Extension','Cable Overhead Triceps Extension','extensión overhead de tríceps','french press overhead','Extensión tríceps overhead']::text[], ARRAY['triceps']::text[], ARRAY[]::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Jalón a brazos rectos', 'Jalón a brazos rectos', 'Gym', 'Straight Arm Pulldown', 'Jalón en polea alta con brazos casi extendidos; aísla dorsales sin flexión fuerte de codo.',
  ARRAY['De pie ante polea alta; barra o cuerda a brazos largos.','Lleva la barra hacia los muslos con dorsales; codos suaves.','Vuelve arriba con control manteniendo tensión.','Error típico: flexionar demasiado los codos (se vuelve jalón) o balancear.','Exhala al bajar la barra.','Progresión: más peso. Alternativa: jalón al pecho.','Estándar: recorrido completo con brazos largos.']::text[], 'back', 'Espalda', 'CrossFit',
  'Polea', true
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
  'catalog:Jalón a brazos rectos', ARRAY['Straight Arm Pulldown','Straight-Arm Pulldown','straight arm pulldown','jalón brazos rectos','pulldown a brazos extendidos','Jalón a brazos rectos']::text[], ARRAY['upper-back']::text[], ARRAY['abs']::text[], ARRAY['Polea']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Hip extension', 'Hip extension', 'Gym', 'Hip Extension', 'Extensión de cadera en banco 45° o máquina (no GHD): glúteos e isquios con pelvis controlada.',
  ARRAY['Ajusta el pad en la cadera; tobillos fijados; torso alineado.','Extiende la cadera subiendo el tronco hasta la línea del cuerpo.','Baja con control sin redondear de golpe la lumbar.','Error típico: hiperextender arriba o usar solo lumbar.','Exhala al extender.','Progresión: más rango o disco en pecho. Alternativa: GHD back extension.','Estándar: extensión de cadera completa y controlada.']::text[], 'upper legs', 'Glúteos', 'CrossFit',
  'Máquina / banco 45°', true
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
  'catalog:Hip extension', ARRAY['Hip Extension','Back Extension','45 Degree Hip Extension','roman chair hip extension','hiperextensión 45','Ghd Hip Extension','Hip extension']::text[], ARRAY['gluteal','hamstring']::text[], ARRAY['lower-back']::text[], ARRAY['Máquina / banco 45°']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Sissy squat', 'Sissy squat', 'Gym', 'Sissy Squat', 'Sissy squat: sentadilla con énfasis en cuádriceps, torso y rodillas hacia delante con control.',
  ARRAY['Agarra un apoyo si hace falta; pies fijos; torso erguido.','Lleva rodillas delante y cuerpo atrás en diagonal; talones bajos.','Vuelve extendiendo rodillas sin empujar con impulso.','Error típico: perder el equilibrio o flexionar demasiado la cadera.','Exhala al subir.','Progresión: más rango o peso ligero. Alternativa: extensión de cuádriceps.','Estándar: tensión continua en cuádriceps en cada rep.']::text[], 'upper legs', 'Piernas', 'CrossFit',
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
  'catalog:Sissy squat', ARRAY['Sissy Squat','sissy squat','sissy squats','sentadilla sissy','Sissy squat']::text[], ARRAY['quadriceps']::text[], ARRAY['abs']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Sentadilla con safety bar', 'Sentadilla con safety bar', 'Gym', 'Safety Bar Squat', 'Sentadilla con safety squat bar: agarres delanteros y carga más cómoda para hombros/torso.',
  ARRAY['Safety bar sobre trapecios; manos en los agarres; torso más vertical.','Baja a profundidad prescrita con rodillas alineadas.','Empuja el suelo hasta extensión completa.','Error típico: dejar caer los codos o cortar profundidad.','Inhala al bajar; exhala al subir.','Progresión: más peso. Alternativa: sentadilla con barra.','Estándar: profundidad y bloqueo arriba en cada rep.']::text[], 'upper legs', 'Piernas', 'Halterofilia',
  'Safety bar', true
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
  'catalog:Sentadilla con safety bar', ARRAY['Safety Bar Squat','safety squat bar','SSB squat','sentadilla safety bar','safety squat','Sentadilla con safety bar']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Safety bar']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Meadows row', 'Meadows row', 'Gym', 'Meadows Row', 'Remo Meadows a un brazo en landmine; dorsal y espalda media con torso en bisagra.',
  ARRAY['Barra en landmine; stance en staggered; torso inclinado.','Tira el codo hacia la cadera con el brazo cercano a la placa.','Baja hasta estirar sin rotar en exceso el tronco.','Error típico: girar todo el torso o usar impulso de piernas.','Exhala al tirar; completa el lado antes de cambiar.','Progresión: más discos. Alternativa: remo mancuerna.','Estándar: rango completo a un brazo en cada rep.']::text[], 'back', 'Espalda', 'CrossFit',
  'Barra landmine', true
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
  'catalog:Meadows row', ARRAY['Meadows Row','meadows row','landmine row a un brazo','remo Meadows','Meadows row']::text[], ARRAY['upper-back']::text[], ARRAY['biceps','deltoids']::text[], ARRAY['Barra landmine']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Spider curl', 'Spider curl', 'Gym', 'Spider Curl', 'Curl en banco inclinado boca abajo (spider curl); bíceps sin impulso de cadera.',
  ARRAY['Pecho en banco inclinado; brazos colgando por delante.','Curl sin balancear; aprieta arriba con codos fijos.','Baja hasta extensión completa.','Error típico: acortar el rango abajo o despegar el pecho.','Exhala al subir.','Progresión: más peso. Alternativa: curl inclinado.','Estándar: pecho pegado y extensión completa abajo.']::text[], 'upper arms', 'Bíceps', 'CrossFit',
  'Mancuernas, Banco', true
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
  'catalog:Spider curl', ARRAY['Spider Curl','spider curl','prone incline curl','curl araña','Spider curl']::text[], ARRAY['biceps']::text[], ARRAY['forearm']::text[], ARRAY['Mancuernas, Banco']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Curl de muñeca', 'Curl de muñeca', 'Gym', 'Wrist Curl', 'Curl de muñeca con barra o mancuernas; flexores del antebrazo.',
  ARRAY['Antebrazos apoyados en banco o muslos; muñecas fuera del borde; agarre prono o supino según variante.','Flexiona solo las muñecas elevando la barra.','Baja hasta estirar con control.','Error típico: mover los codos o usar demasiado peso.','Exhala al flexionar.','Progresión: más peso o reverse wrist curl. Alternativa: farmer carry.','Estándar: solo movimiento de muñeca en cada rep.']::text[], 'lower arms', 'Antebrazos', 'CrossFit',
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
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Curl de muñeca', ARRAY['Wrist Curl','wrist curl','Reverse Wrist Curl','curl de antebrazo','wrist curls','Curl de muñeca']::text[], ARRAY['forearm']::text[], ARRAY[]::text[], ARRAY['Barra']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Gemelos de burro', 'Gemelos de burro', 'Gym', 'Donkey Calf Raise', 'Elevación de gemelos tipo burro (cadera flexionada); estiramiento largo del gemelo.',
  ARRAY['Cadera flexionada; antepié en el borde; carga sobre cadera/espalda baja según máquina.','Extiende tobillos hasta elevación máxima; pausa.','Baja hasta estirar gemelos sin rebotar.','Error típico: flexionar rodillas o rango corto.','Exhala al subir.','Progresión: más peso. Alternativa: gemelos de pie.','Estándar: extensión completa de tobillo.']::text[], 'lower legs', 'Gemelos', 'CrossFit',
  'Máquina', true
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
  'catalog:Gemelos de burro', ARRAY['Donkey Calf Raise','donkey calf','gemelos burro','donkey calves','Gemelos de burro']::text[], ARRAY['calves']::text[], ARRAY[]::text[], ARRAY['Máquina']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Zancada en cortesía', 'Zancada en cortesía', 'Gym', 'Curtsy Lunge', 'Curtsy lunge: paso atrás cruzado; glúteo medio y estabilidad de cadera.',
  ARRAY['De pie; cruza un pie atrás y hacia el lado contrario.','Baja hasta muslo delantero paralelo; torso erguido.','Vuelve al centro empujando el pie delantero.','Error típico: rotar en exceso la rodilla delantera o perder el equilibrio.','Exhala al subir; alterna.','Progresión: mancuernas. Alternativa: zancada lateral.','Estándar: cruce claro y profundidad controlada.']::text[], 'upper legs', 'Piernas', 'CrossFit',
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
  'catalog:Zancada en cortesía', ARRAY['Curtsy Lunge','curtsy lunge','curtsy lunges','zancada cruzada atrás','Zancada en cortesía']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['adductors','abs']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Step-down', 'Step-down', 'Gym', 'Step Down', 'Bajada controlada desde cajón a una pierna (step-down); fuerza excéntrica y control de rodilla.',
  ARRAY['Un pie en el cajón; el otro libre; torso erguido.','Flexiona la pierna de apoyo hasta tocar el suelo con el talón libre (o cerca).','Extiende la pierna de apoyo y vuelve arriba con control.','Error típico: dejar caer la cadera o colapsar la rodilla hacia dentro.','Exhala al subir; completa el lado.','Progresión: cajón más alto o peso. Alternativa: step-up.','Estándar: toque controlado y rodilla alineada.']::text[], 'upper legs', 'Piernas', 'CrossFit',
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
  metadata_source, skill_level, updated_at
) VALUES (
  'catalog:Step-down', ARRAY['Step Down','Step-Down','box step down','bajada de cajón a una pierna','Step-down']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Cajón']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
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
  'catalog:Aperturas con banda', 'Aperturas con banda', 'Gym', 'Band Pull Apart', 'Band pull-apart: abre la banda a la altura del pecho; deltoides posterior y escapulares.',
  ARRAY['Banda a la altura del pecho; brazos extendidos delante.','Abre hacia los lados apretando omóplatos; banda toca el pecho.','Vuelve con control sin perder tensión.','Error típico: encoger trapecios o flexionar demasiado los codos.','Exhala al abrir.','Progresión: banda más fuerte o más reps. Alternativa: pájaros.','Estándar: apertura completa con omóplatos activos.']::text[], 'shoulders', 'Hombros', 'Movilidad',
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
  'catalog:Aperturas con banda', ARRAY['Band Pull Apart','band pull-apart','band pull aparts','aperturas de banda','face pull con banda corto','Aperturas con banda']::text[], ARRAY['deltoids']::text[], ARRAY['upper-back']::text[], ARRAY['Banda']::text[],
  'open_sources:phase_f_fed_20261104', 'intermediate', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases = EXCLUDED.aliases,
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  skill_level = EXCLUDED.skill_level,
  updated_at = now();
