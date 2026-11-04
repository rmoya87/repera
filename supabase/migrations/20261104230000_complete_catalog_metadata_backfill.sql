-- Complete catalog metadata backfill: mobile text/equip/sport + skill_level + alternatives
-- Source: android catalog_seed.json (mirrors Catalog.seed) + editorial heuristics. Own-words already in seed.

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Press de banca en banco plano: bajas la barra al pecho y la empujas a bloqueo. Pecho, hombros y tríceps.',
  mobile_instructions = ARRAY['Túmbate, pies firmes: baja la barra al pecho medio con codos ~45°.','Empuja a bloqueo sin arquear la lumbar: barra sobre el pecho, brazos extendidos.','Túmbate en banco plano con ojos bajo la barra; pies firmes en el suelo y glúteos apoyados.','Agarre prono un poco más ancho que los hombros; saca la barra y bloquea sobre el pecho con omóplatos retraídos.','Inhala y baja la barra en línea controlada hasta el pecho medio, codos ~45° respecto al torso (no 90° abiertos).','Sin rebotar, empuja la barra arriba hasta extender los brazos; exhala al pasar el punto difícil.','Error típico: arquear la lumbar o abrir excesivamente los codos. Mantén muñecas apiladas sobre los antebrazos.','Estándar: cada rep toca el pecho (o llega al rango seguro) y termina en bloqueo completo.']::text[],
  mobile_equipment = NULLIF('Barra, Banco',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('chest',''),
  mobile_muscle_group = NULLIF('Pecho','')
WHERE catalog_key = 'catalog:Press banca';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest']::text[])>0 THEN ARRAY['chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','deltoids']::text[])>0 THEN ARRAY['triceps','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra, Banco','') IS NOT NULL THEN ARRAY['Barra, Banco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Press banca';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Press en banco inclinado (30–45°): más énfasis en pecho alto y deltoides anterior.',
  mobile_instructions = ARRAY['Banco 30–45°: baja la barra a pecho alto/clavícula, omóplatos retraídos.','Empuja a bloqueo en línea con el pecho alto.','Ajusta el banco a 30–45°. Túmbate con pies firmes y omóplatos pegados al banco.','Agarre prono; desbloquea la barra y colócala sobre el pecho alto / clavícula, no sobre la cara.','Baja controlado hacia pecho alto manteniendo codos bajo la barra.','Empuja en diagonal ligera hasta bloqueo; no dejes que las muñecas se quiebren atrás.','Error típico: inclinación demasiado vertical (se convierte en press de hombro) o rebotar en el pecho.','Si eres principiante, empieza ligero y prioriza el contacto estable en pecho alto.']::text[],
  mobile_equipment = NULLIF('Barra, Banco',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('chest',''),
  mobile_muscle_group = NULLIF('Pecho','')
WHERE catalog_key = 'catalog:Press banca inclinada';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest']::text[])>0 THEN ARRAY['chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','deltoids']::text[])>0 THEN ARRAY['triceps','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra, Banco','') IS NOT NULL THEN ARRAY['Barra, Banco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Press banca inclinada';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Press con mancuernas en banco plano: mayor rango y estabilización que con barra.',
  mobile_instructions = ARRAY['Túmbate en banco plano; sube las mancuernas a los lados del pecho con ayuda de las rodillas si hace falta.','Muñecas apiladas sobre los codos, palmas al frente; omóplatos retraídos y pies firmes.','Baja las mancuernas hasta estirar el pecho (aprox. 90° de codo), sin abrir en exceso.','Empuja arriba juntando ligeramente las mancuernas al final, sin chocarlas con violencia.','Error típico: arquear lumbar o perder el control en el descenso. Exhala al empujar.','Ventaja vs barra: mayor rango y detección precoz de asimetrías; iguala ambos lados.']::text[],
  mobile_equipment = NULLIF('Mancuernas, Banco',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('chest',''),
  mobile_muscle_group = NULLIF('Pecho','')
WHERE catalog_key = 'catalog:Press mancuernas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest']::text[])>0 THEN ARRAY['chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','deltoids']::text[])>0 THEN ARRAY['triceps','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas, Banco','') IS NOT NULL THEN ARRAY['Mancuernas, Banco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Press mancuernas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Aperturas en banco inclinado: abres y cierras en arco con codos blandos para estirar y contraer el pecho.',
  mobile_instructions = ARRAY['Abre en arco amplio hasta estirar el pecho, mancuernas a la altura del torso, codos blandos.','Recoge el arco con codos abiertos y mancuernas sobre el pecho, sin convertir el movimiento en press.','Banco inclinado ~30°; mancuernas sobre el pecho con codos blandos (nunca bloqueados).','Abre en arco amplio hasta sentir estiramiento en el pecho; mancuernas a la altura del torso.','Mantén el mismo ángulo de codo durante todo el movimiento (es un vuelo, no un press).','Cierra el arco juntando las mancuernas sobre el pecho sin convertir el final en press vertical.','Error típico: bajar demasiado y forzar el hombro, o flexionar/extender el codo a cada rep.','Carga moderada: si no puedes controlar el arco, reduce el peso.']::text[],
  mobile_equipment = NULLIF('Mancuernas, Banco',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('chest',''),
  mobile_muscle_group = NULLIF('Pecho','')
WHERE catalog_key = 'catalog:Aperturas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest']::text[])>0 THEN ARRAY['chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','biceps']::text[])>0 THEN ARRAY['deltoids','biceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas, Banco','') IS NOT NULL THEN ARRAY['Mancuernas, Banco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Aperturas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Fondos en paralelas inclinando el torso: pecho y tríceps; más vertical = más tríceps.',
  mobile_instructions = ARRAY['Agarra las paralelas y súbete a soporte: brazos extendidos, hombros bajos y lejos de las orejas.','Inclina el torso ligeramente adelante si buscas más pecho; más vertical = más tríceps.','Baja flexionando codos hasta ~90° o hasta hombros a la altura de los codos, con control.','Empuja hasta bloqueo completo sin encoger trapecios ni balancear piernas.','Error típico: hundir el cuello entre los hombros o rebotar abajo. Para si duele la articulación.','Progresión: banda asistida → cuerpo completo → lastre. Marca siempre el mismo rango.']::text[],
  mobile_equipment = NULLIF('Paralelas',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('chest',''),
  mobile_muscle_group = NULLIF('Pecho','')
WHERE catalog_key = 'catalog:Fondos';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest','triceps']::text[])>0 THEN ARRAY['chest','triceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Paralelas','') IS NOT NULL THEN ARRAY['Paralelas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Fondos';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Dominadas: tiras el pecho hacia la barra. Dorsales, bíceps y agarre.',
  mobile_instructions = ARRAY['Cuelga muerto: brazos totalmente extendidos, hombros activos.','Tira hasta que la barbilla pase la barra, pecho arriba.','Cuelga muerto de la barra: brazos totalmente extendidos, hombros activos (ligera depresión escapular).','Inicia el tirón llevando los codos abajo y atrás; pecho hacia la barra, no la barbilla al frente.','Sube hasta que la barbilla pase claramente la barra; aprieta dorsales un instante.','Baja en 2–3 segundos hasta extensión completa de brazos antes de la siguiente rep.','Error típico: kipping no pedido, o cortar el rango abajo. Si no llegas, usa banda o negativo.','Agarre prono al ancho de hombros (o un poco más); aprieta la barra y mantén piernas quietas.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Dominadas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dominadas butterfly','Dominadas estrictas','Dominadas kipping','Dominadas lastradas','Jumping Pull-Up','L Pull Up','Negative Pull Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','forearm','trapezius']::text[])>0 THEN ARRAY['biceps','forearm','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dominadas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Jalón al pecho sentado: tiras la barra a la clavícula/pecho alto. Dorsales y espalda media.',
  mobile_instructions = ARRAY['Ajusta asiento y rodilleras; torso erguido con ligera inclinación atrás (no balanceo).','Agarre prono un poco más ancho que hombros; inicia el tirón desde la espalda, no desde los brazos.','Lleva la barra a pecho alto / clavícula apretando omóplatos; codos abajo.','Extiende los brazos con control hasta el estiramiento, sin soltar del todo la tensión del dorsal.','Error típico: tirar con impulso de tronco o llevar la barra detrás de la nuca sin movilidad.','Exhala al tirar; mantén costillas abajo para no arquear la lumbar.']::text[],
  mobile_equipment = NULLIF('Polea',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Jalón al pecho';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','forearm','trapezius']::text[])>0 THEN ARRAY['biceps','forearm','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Polea','') IS NOT NULL THEN ARRAY['Polea']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Jalón al pecho';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Remo con barra inclinado: tiras la barra al abdomen. Espalda media/dorsal y bíceps.',
  mobile_instructions = ARRAY['Pies al ancho de cadera; bisagra de cadera hasta torso ~45°, barra colgando a brazos largos.','Espalda plana, abdomen firme; agarre prono al ancho de hombros (o semi-supino si lo prefieres).','Tira la barra hacia el ombligo / abdomen bajo, codos cerca del cuerpo, apretando omóplatos.','Pausa breve arriba y baja sin redondear la lumbar ni usar impulso de cadera.','Error típico: convertirlo en peso muerto con tirón: la cadera no debe extenderse a cada rep.','Si la lumbar se redondea, sube el torso un poco o reduce la carga.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Remo con barra';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','deltoids','forearm','lower-back']::text[])>0 THEN ARRAY['biceps','deltoids','forearm','lower-back']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Remo con barra';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Remo a una mano apoyado en banco: dorsal y espalda media con buen estiramiento.',
  mobile_instructions = ARRAY['Apoya una rodilla y la mano del mismo lado en el banco; tronco casi paralelo al suelo.','Mancuerna colgando a brazo largo, hombro activo; mirada al suelo para cuello neutro.','Tira el codo hacia la cadera hasta la costilla; aprieta el dorsal sin rotar el tronco.','Baja con control hasta estirar; completa la serie y cambia de lado.','Error típico: girar el torso o encoger el hombro hacia la oreja al tirar.','Usa un espejo o vídeo de lado para comprobar que la cadera permanece quieta.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Remo mancuerna';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','deltoids','forearm']::text[])>0 THEN ARRAY['biceps','deltoids','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Remo mancuerna';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto convencional: bisagra y extensión de cadera hasta de pie. Posterior completo y agarre.',
  mobile_instructions = ARRAY['Barra sobre mediopié, agarre fuera de piernas, espalda plana.','Empuja el suelo y bloquea cadera de pie sin hiperextender.','Barra sobre mediopié; pies al ancho de cadera. Bisagra y agarra justo por fuera de las piernas.','Pecho alto, espalda plana, omóplatos ligeramente retraídos; inhala y bracea el abdomen contra el cinturón (si usas).','Empuja el suelo con los pies y extiende rodillas y cadera a la vez; barra pegada a las piernas.','Bloquea de pie con cadera extendida y hombros sobre la barra; no te inclines atrás en hiperextensión.','Baja empujando la cadera atrás y luego flexionando rodillas; deja la barra con control.','Error típico: redondear lumbar o separar la barra del cuerpo. Si falla la técnica, baja el peso.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Peso muerto';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Deficit Deadlift','Dumbbell Deadlift','Dumbbell Romanian Deadlift','Kettlebell Deadlift','Peso muerto rumano','Peso muerto sumo','Trap Bar Deadlift']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','hamstring','lower-back']::text[])>0 THEN ARRAY['gluteal','hamstring','lower-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','quadriceps','forearm','trapezius']::text[])>0 THEN ARRAY['upper-back','quadriceps','forearm','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Peso muerto';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto rumano: bisagra con poca flexión de rodilla; isquios y glúteos.',
  mobile_instructions = ARRAY['Colócate de pie con la barra frente a los muslos y las rodillas ligeramente flexionadas.','Lleva la cadera atrás y baja la barra cerca de las piernas manteniendo la espalda neutra.','De pie con la barra en las caderas, agarre prono (o mixto); rodillas blandas fijas.','Empuja la cadera atrás manteniendo la barra cerca de los muslos; espalda plana.','Baja hasta sentir un buen estiramiento de isquios (normalmente por debajo de la rodilla), sin redondear.','Extiende la cadera para volver, apretando glúteos arriba; no bloquees de golpe las rodillas.','Error típico: flexionarse demasiado de rodillas (se vuelve sentadilla) o mirar al techo arqueando lumbar.','Tempo recomendado: 3 segundos de bajada, 1 arriba. Carga subordinada a la bisagra limpia.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Peso muerto rumano';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Deficit Deadlift','Dumbbell Deadlift','Dumbbell Romanian Deadlift','Kettlebell Deadlift','Peso muerto','Peso muerto sumo','Trap Bar Deadlift']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['lower-back','forearm']::text[])>0 THEN ARRAY['lower-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Peso muerto rumano';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla con barra en espalda: bajas a paralelo o más y te levantas. Cuádriceps, glúteos y core.',
  mobile_instructions = ARRAY['Barra sobre trapecios, pies al ancho de hombros, pecho alto.','Baja a paralelo o más, rodillas alinea con pies, y empuja para subir.','Barra sobre trapecios (high-bar) o deltoides posteriores (low-bar); pies al ancho de hombros, punta ligeramente afuera.','Desbloquea cadera y rodillas a la vez; pecho alto, mirada al frente; inhala y bracea antes de bajar.','Baja hasta paralelo o más (cresta ilíaca bajo la rótula) manteniendo rodillas alineadas con las puntas.','Empuja el suelo, extiende cadera y rodillas, y exhala al subir; termina de pie sin hiperextender lumbar.','Error típico: rodillas que colapsan adentro, talones que se levantan, o cortar profundidad.','Progresión: goblet → front → back squat. Marca siempre la misma profundidad.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Sentadilla';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Box Squat','Dumbbell Front Squat','Goblet squat','Sandbag Squat','Sentadilla frontal','Zercher Squat']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','adductors','abs','calves']::text[])>0 THEN ARRAY['hamstring','adductors','abs','calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sentadilla';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla frontal: barra en rack frontal, torso vertical; énfasis en cuádriceps.',
  mobile_instructions = ARRAY['Barra en rack frontal (delante del cuello), codos altos, de pie.','Baja a paralelo o más con torso vertical y codos altos; empuja el suelo y vuelve.','Barra en rack frontal (codos altos, barra sobre deltoides anteriores); torso más vertical que en back squat.','Pies al ancho de hombros; inhala y bracea. Mantén los codos altos para no perder el rack.','Baja entre las rodillas hasta paralelo o más; talones pegados al suelo.','Empuja para subir manteniendo el pecho alto; no dejes que los codos caigan.','Error típico: codos bajos (la barra rueda) o inclinarte demasiado adelante.','Si falta movilidad de muñeca, usa cross-arm rack o straps; la barra debe quedar estable.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Sentadilla frontal';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Box Squat','Dumbbell Front Squat','Goblet squat','Sandbag Squat','Sentadilla','Zercher Squat']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','abs','upper-back']::text[])>0 THEN ARRAY['gluteal','abs','upper-back']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sentadilla frontal';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Prensa de piernas: empujas la plataforma. Cuádriceps y glúteos con trayectoria guiada.',
  mobile_instructions = ARRAY['Siéntate con lumbar y pelvis pegadas al respaldo; pies al ancho de hombros en la plataforma.','Desbloquea con control; baja flexionando rodillas sin despegar la zona lumbar del asiento.','Profundidad: muslos cerca de 90° o el rango que mantenga talones y lumbar estables.','Empuja hasta casi extender sin bloquear de golpe las rodillas; exhala al empujar.','Error típico: poner los pies demasiado altos/bajos o rebotar en el fondo con la lumbar redondeada.','Ajusta la plataforma para que el recorrido trabaje cuádriceps/glúteos sin dolor de rodilla.']::text[],
  mobile_equipment = NULLIF('Máquina prensa de piernas',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Prensa';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','calves']::text[])>0 THEN ARRAY['hamstring','calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Máquina prensa de piernas','') IS NOT NULL THEN ARRAY['Máquina prensa de piernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Prensa';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancadas: paso adelante o caminando; trabajo unilateral de piernas y estabilidad.',
  mobile_instructions = ARRAY['De pie con mancuernas a los lados.','Da el paso y baja a media zancada.','Rodilla trasera cerca del suelo; empuja para volver.','Mancuernas a los lados (o barra); torso erguido, mirada al frente.','Da un paso largo adelante y baja hasta rodilla delantera ~90° y rodilla trasera cerca del suelo.','Rodilla delantera sobre el mediopié (no muy por delante de la punta); peso repartido.','Empuja con la pierna delantera para volver o para el siguiente paso (walking lunge).','Error típico: inclinarte en exceso, pasos cortos que sobrecargan la rodilla, o tobillo inestable.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Zancadas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','calves']::text[])>0 THEN ARRAY['hamstring','calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Zancadas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Extensión de cuádriceps en máquina: aísla la cara anterior del muslo.',
  mobile_instructions = ARRAY['Ajusta el asiento para que la rodilla quede alineada con el eje de la máquina.','Coloca el rodillo sobre la tibia distal (no sobre el tobillo sensible); espalda apoyada.','Extiende las rodillas hasta casi bloqueo apretando cuádriceps; no arquees la lumbar.','Baja en 2–3 segundos hasta el rango cómodo; no rebotes abajo.','Error típico: usar impulso de cadera o carga que te haga despegar la pelvis.','Ideal como aislamiento al final de pierna; controla el pico de contracción arriba.']::text[],
  mobile_equipment = NULLIF('Máquina de extensión de cuádriceps',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Extensión de cuádriceps';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip-flexors']::text[])>0 THEN ARRAY['hip-flexors']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Máquina de extensión de cuádriceps','') IS NOT NULL THEN ARRAY['Máquina de extensión de cuádriceps']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Extensión de cuádriceps';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Curl femoral en máquina: flexión de rodilla para isquiotibiales.',
  mobile_instructions = ARRAY['Ajusta almohadillas para que la rodilla coincida con el pivote; cadera estable.','Flexiona rodillas llevando el rodillo hacia los glúteos; aprieta isquios arriba.','No levantes la pelvis ni arquees la lumbar para «ayudar».','Extiende con control hasta casi estirar, manteniendo tensión.','Error típico: rango incompleto o carga que te hace usar la lumbar.','Sirve sentado o tumbado según la máquina; prioriza el contacto mental isquio.']::text[],
  mobile_equipment = NULLIF('Máquina de curl femoral',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Curl femoral';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring']::text[])>0 THEN ARRAY['hamstring']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','calves']::text[])>0 THEN ARRAY['gluteal','calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Máquina de curl femoral','') IS NOT NULL THEN ARRAY['Máquina de curl femoral']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Curl femoral';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Elevación de gemelos de pie o en máquina: extensión de tobillo.',
  mobile_instructions = ARRAY['Antepié en el borde de la plataforma; tobillos libres para estirar abajo.','Sube lo más alto posible sobre las puntas; pausa 1 s apretando gemelos.','Baja talones por debajo del nivel del apoyo con control (estiramiento).','Rodillas casi extendidas en la versión de pie; flexionadas si buscas más sóleo.','Error típico: rebotar abajo o usar impulso de rodillas. Tempo lento.','Progresión: a una pierna o con pausa larga arriba cuando domines el rango.']::text[],
  mobile_equipment = NULLIF('Máquina de gemelos',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('lower legs',''),
  mobile_muscle_group = NULLIF('Gemelos','')
WHERE catalog_key = 'catalog:Elevación de gemelos';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['tibialis']::text[])>0 THEN ARRAY['tibialis']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Máquina de gemelos','') IS NOT NULL THEN ARRAY['Máquina de gemelos']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Elevación de gemelos';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Press militar de pie: empujas la barra desde hombros a overhead. Deltoides y tríceps.',
  mobile_instructions = ARRAY['Barra a hombros/front rack, torso rígido.','Empuja a bloqueo overhead sin arquear lumbar.','Barra a la altura de clavícula/front rack o desde rack a hombros; pies al ancho de cadera.','Glúteos y abdomen firmes; muñecas apiladas. Inhala y bracea antes de empujar.','Presiona la barra en línea vertical cerca de la cara; pasa la cabeza cuando la barra lo permita.','Bloquea overhead con bíceps junto a las orejas, hombros activos; exhala arriba.','Baja a hombros con control. Error típico: hiperextender lumbar o abrir excesivamente los codos.','Versión estricta: sin dip de rodillas. Si usas push press, el dip debe ser corto y vertical.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Press militar';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','chest','abs','trapezius']::text[])>0 THEN ARRAY['triceps','chest','abs','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Press militar';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Elevaciones laterales: aíslan el deltoides medio hasta la altura del hombro.',
  mobile_instructions = ARRAY['Mancuernas a los lados, torso quieto, codos ligeramente flexionados (fijos).','Eleva en arco hasta ~altura de hombros; meñiques ligeramente más altos que los pulgares.','No encogas trapecios ni balancees el cuerpo; el deltoides medio mueve el peso.','Baja en 2–3 segundos manteniendo tensión; no dejes caer las mancuernas.','Error típico: cargar demasiado y convertir el movimiento en encogimiento + balanceo.','Series de 10–15 reps con control suelen enseñar mejor el patrón que el peso máximo.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Elevaciones laterales';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius']::text[])>0 THEN ARRAY['trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Elevaciones laterales';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Pájaros / elevaciones posteriores: deltoides posterior y espalda alta.',
  mobile_instructions = ARRAY['Inclina el torso ~45° (o tumba boca abajo en banco); mancuernas colgando, codos blandos.','Abre los brazos en cruz apretando omóplatos; apunta a deltoides posterior, no a trapecio alto.','Llega a la línea de los hombros sin hiperextender la lumbar ni girar el tronco.','Baja con control. Mantén el cuello alineado (mira al suelo si estás inclinado).','Error típico: usar demasiado peso y remar con la espalda media en vez de abrir en vuelo.','Ideal para salud de hombro y postura; prioriza la calidad del apretón escapular.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Pájaros';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','trapezius']::text[])>0 THEN ARRAY['upper-back','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Pájaros';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Curl de bíceps con barra: flexión de codo sin balanceo de tronco.',
  mobile_instructions = ARRAY['Agarre supino al ancho de hombros; codos pegados a las costillas; torso erguido.','Flexiona solo el codo subiendo la barra sin balancear cadera ni hombros.','Aprieta bíceps arriba; muñecas neutras (no las quiebres atrás).','Baja en 2–3 s hasta casi extender, sin soltar toda la tensión.','Error típico: cheat con swing de tronco. Si lo necesitas, baja el peso.','Puedes usar EZ bar si te molestan las muñecas; el patrón de codo fijo no cambia.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper arms',''),
  mobile_muscle_group = NULLIF('Bíceps','')
WHERE catalog_key = 'catalog:Curl barra';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps']::text[])>0 THEN ARRAY['biceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearm']::text[])>0 THEN ARRAY['forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Curl barra';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Curl con mancuernas: permite rotación y mayor rango que la barra.',
  mobile_instructions = ARRAY['Mancuernas a los lados; puedes alternar o subir ambas a la vez.','Curl sin balanceo; codos fijos. Opcional: rota a supinación al subir.','Aprieta arriba y baja con control hasta extensión casi completa.','Mantén hombros bajos; no dejes que el codo viaje hacia delante en exceso.','Error típico: usar impulso o rotar el tronco a cada lado.','Trabaja el rango completo; si falla un lado, reduce carga y equilibra.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper arms',''),
  mobile_muscle_group = NULLIF('Bíceps','')
WHERE catalog_key = 'catalog:Curl mancuernas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps']::text[])>0 THEN ARRAY['biceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearm']::text[])>0 THEN ARRAY['forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Curl mancuernas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Curl martillo: agarre neutro; bíceps, braquial y antebrazo.',
  mobile_instructions = ARRAY['Agarre neutro (palmas mirándose); codos pegados al torso.','Sube las mancuernas hacia el hombro sin abrir los codos hacia fuera.','Pausa breve arriba; baja lento enfatizando braquial y antebrazo.','Torso quieto; no balancees.','Error típico: convertir el final en press o encoger hombros.','Buena opción si el curl supino te irrita el codo; mantén muñecas firmes.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper arms',''),
  mobile_muscle_group = NULLIF('Bíceps','')
WHERE catalog_key = 'catalog:Curl martillo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps']::text[])>0 THEN ARRAY['biceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearm']::text[])>0 THEN ARRAY['forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Curl martillo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Fondos en banco: tríceps con manos en el borde y pies al frente.',
  mobile_instructions = ARRAY['Manos en el borde del banco, dedos al frente; glúteos cerca del banco, pies apoyados.','Hombros bajos; baja flexionando codos hasta ~90° con el pecho abierto.','Empuja a extensión de brazos sin encoger el cuello entre los hombros.','Cuanto más lejos pongas los pies, más difícil; acerca pies o flexiona rodillas para facilitar.','Error típico: alejarte demasiado del banco y sobrecargar la cara anterior del hombro.','Si duele el hombro, reduce el rango o cambia a extensión en polea.']::text[],
  mobile_equipment = NULLIF('Banco',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper arms',''),
  mobile_muscle_group = NULLIF('Tríceps','')
WHERE catalog_key = 'catalog:Fondos en banco';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps']::text[])>0 THEN ARRAY['triceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest','deltoids']::text[])>0 THEN ARRAY['chest','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Banco','') IS NOT NULL THEN ARRAY['Banco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Fondos en banco';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Extensión de tríceps en polea alta: aísla la cara posterior del brazo.',
  mobile_instructions = ARRAY['Polea alta; codos pegados al cuerpo, antebrazos paralelos al suelo al inicio.','Extiende solo el codo llevando barra o cuerda abajo; torso quieto.','Aprieta tríceps abajo 1 s; vuelve con control hasta el estiramiento cómodo.','No muevas hombros ni uses la lumbar para empujar.','Error típico: abrir los codos o cargar de más y hacer press de pecho.','Con cuerda, separa ligeramente las manos abajo para un pico de contracción.']::text[],
  mobile_equipment = NULLIF('Polea',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper arms',''),
  mobile_muscle_group = NULLIF('Tríceps','')
WHERE catalog_key = 'catalog:Extensión tríceps polea';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps']::text[])>0 THEN ARRAY['triceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearm','deltoids']::text[])>0 THEN ARRAY['forearm','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Polea','') IS NOT NULL THEN ARRAY['Polea']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Extensión tríceps polea';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Press banca agarre cerrado: más énfasis en tríceps, pecho como secundario.',
  mobile_instructions = ARRAY['Banco plano; agarre al ancho de hombros o ligeramente más estrecho (no excesivo).','Omóplatos retraídos; baja la barra al pecho medio con codos cerca del torso.','Empuja a bloqueo priorizando tríceps; muñecas apiladas.','No abras los codos como en press ancho; mantén el recorrido estable.','Error típico: agarre demasiado estrecho que fuerza muñecas, o rebotar en el pecho.','Es un híbrido pecho-tríceps: el estándar de bloqueo completo sigue aplicando.']::text[],
  mobile_equipment = NULLIF('Barra, Banco',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper arms',''),
  mobile_muscle_group = NULLIF('Tríceps','')
WHERE catalog_key = 'catalog:Press cerrado';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','chest']::text[])>0 THEN ARRAY['triceps','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra, Banco','') IS NOT NULL THEN ARRAY['Barra, Banco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Press cerrado';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Plancha isométrica: cuerpo en línea, abdomen y glúteos activos.',
  mobile_instructions = ARRAY['Antebrazos o manos bajo los hombros; cuerpo en línea desde nuca hasta talones.','Activa abdomen y glúteos; pelvis neutra (ni hundir lumbar ni elevar cadera en pico).','Hombros lejos de las orejas; mirada al suelo; respira de forma continua.','Mantén el tiempo objetivo sin perder la línea. Si tiemblas, reduce tiempo y suma series.','Error típico: cadera caída (lumbar cargada) o cadera muy alta (dejas de trabajar core).','Progresión: plancha alta → antebrazos → elevación de pie → lastre en espalda.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Plancha';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques','deltoids','gluteal']::text[])>0 THEN ARRAY['obliques','deltoids','gluteal']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Plancha';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Crunch: flexionas el tronco acercando costillas a pelvis sin tirar del cuello.',
  mobile_instructions = ARRAY['Tumbado, rodillas flexionadas, lumbar apoyada; manos junto a sienes (no tires del cuello).','Enrolla costillas hacia pelvis; omóplatos despegan poco del suelo.','Aprieta abdomen arriba 1 s; baja controlado sin soltar del todo la tensión.','No uses impulso de cadera ni tireones de cabeza.','Error típico: crunch de cuello. Piensa «acortar distancia costillas-cadera».','Rango corto y calidad > muchas reps con balanceo.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Crunch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip-flexors']::text[])>0 THEN ARRAY['hip-flexors']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Crunch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Elevación de piernas: abdominales inferiores y flexores de cadera.',
  mobile_instructions = ARRAY['Tumbado (manos bajo glúteos) o colgado; prensa la lumbar (si estás tumbado) al suelo.','Eleva piernas juntas hasta ~90° o el máximo sin arquear la espalda.','Baja despacio sin soltar el abdomen; no dejes caer las piernas al final.','Si es difícil, flexiona ligeramente las rodillas (tuck) y progresa a piernas rectas.','Error típico: usar solo flexores de cadera con lumbar arqueada.','Exhala al subir; controla la bajada 3 segundos.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Elevación de piernas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip-flexors']::text[])>0 THEN ARRAY['hip-flexors']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Elevación de piernas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Hip thrust: empuje de cadera con espalda en banco; glúteos como motor principal.',
  mobile_instructions = ARRAY['Hombros en banco, barra en cadera, cadera BAJA cerca del suelo.','Empuja cadera hasta alinear torso y muslos; aprieta glúteo.','Espalda alta apoyada en el banco; barra acolchada sobre la cadera; pies al ancho de cadera.','Baja la cadera con control; barbilla ligeramente metida, costillas abajo.','Empuja con los talones hasta alinear hombros-cadera-rodillas; aprieta glúteos 1 s arriba.','No hiperextiendas la lumbar arriba: el movimiento termina cuando la cadera está neutra-extendida.','Error típico: empujar con los dedos de los pies o arching excesivo.','Progresión: puente a suelo → hip thrust con mancuerna → barra.']::text[],
  mobile_equipment = NULLIF('Barra, Banco',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Hip thrust';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal']::text[])>0 THEN ARRAY['gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra, Banco','') IS NOT NULL THEN ARRAY['Barra, Banco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hip thrust';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Face pull: tiras hacia la cara con codos altos; deltoides posterior y estabilizadores.',
  mobile_instructions = ARRAY['Polea o banda a altura de cara; agarre neutro/cuerda; un paso atrás para crear tensión.','Tira hacia la cara con codos altos y abiertos; separa las manos al llegar.','Aprieta omóplatos y deltoides posteriores; cuello relajado.','Vuelve sin dejar que los hombros se redondeen hacia delante.','Error típico: convertirlo en jalón bajo o usar demasiado trapecio superior.','Excelente para salud de hombro; series controladas 12–20 reps.']::text[],
  mobile_equipment = NULLIF('Polea',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Face pull';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','trapezius']::text[])>0 THEN ARRAY['upper-back','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Polea','') IS NOT NULL THEN ARRAY['Polea']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Face pull';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Remo al mentón: tiras la barra hacia el pecho con codos altos; hombros y trapecio.',
  mobile_instructions = ARRAY['Barra o mancuernas delante de muslos; agarre prono al ancho cómodo (no excesivamente estrecho).','Tira hacia arriba guiando con los codos hasta pecho alto / clavícula.','Mantén la carga cerca del cuerpo; hombros lejos de las orejas.','Baja con control. Usa carga moderada: el hombro manda sobre el ego.','Error típico: agarre muy estrecho + tirón hacia la cara que irrita el hombro.','Si molesta, sustituye por face pull o elevaciones laterales parciales.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Remo al mentón';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','trapezius']::text[])>0 THEN ARRAY['deltoids','trapezius']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','upper-back']::text[])>0 THEN ARRAY['biceps','upper-back']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Remo al mentón';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Buenos días: bisagra de cadera con barra en espalda; isquios y lumbares.',
  mobile_instructions = ARRAY['Barra sobre trapecios; pies al ancho de cadera; rodillas blandas fijas.','Bisagra de cadera empujando glúteos atrás; espalda plana, mirada neutra.','Baja hasta sentir isquios (torso ~horizontal o un poco antes); no redondees.','Extiende cadera para volver apretando glúteos; no bloquees de golpe.','Error típico: flexionar demasiado las rodillas o cargar de más sin dominio de bisagra.','Aprende primero con stick/banda; luego barra ligera.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Buenos días';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['lower-back','abs']::text[])>0 THEN ARRAY['lower-back','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Buenos días';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Hack squat: sentadilla guiada con énfasis en cuádriceps.',
  mobile_instructions = ARRAY['Espalda y hombros en los pads; pies al ancho cómodo en la plataforma.','Desbloquea y baja en sentadilla controlada hasta profundidad segura con talones pegados.','Empuja la plataforma sin despegar lumbar ni rodillas colapsadas.','Casi extiende arriba sin golpe de bloqueo.','Error típico: pies demasiado bajos que fuerzan rodillas, o rebotar en el fondo.','Ajusta stance (más alto = más glúteo; más bajo = más cuádriceps) según objetivo.']::text[],
  mobile_equipment = NULLIF('Máquina Hack squat',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Hack squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','hamstring']::text[])>0 THEN ARRAY['gluteal','hamstring']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Máquina Hack squat','') IS NOT NULL THEN ARRAY['Máquina Hack squat']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hack squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Pullover con mancuerna: dorsales y pecho con brazos semi-extendidos.',
  mobile_instructions = ARRAY['Tumbado en banco; mancuerna a dos manos sobre el pecho, brazos casi extendidos.','Baja la carga atrás en arco hasta estirar dorsal/pecho; lumbar estable.','Vuelve sobre el pecho apretando dorsales; codos blandos fijos.','No conviertas el movimiento en press francés (no flexiones el codo a propósito).','Error típico: arquear lumbar o usar demasiado peso y perder el arco.','Rango cómodo de hombro: para si sientes pinchazo anterior.']::text[],
  mobile_equipment = NULLIF('Mancuernas, Banco',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Pullover';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest','triceps','abs']::text[])>0 THEN ARRAY['chest','triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas, Banco','') IS NOT NULL THEN ARRAY['Mancuernas, Banco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Pullover';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Carrera en cinta u outdoor: cardio de piernas y resistencia.',
  mobile_instructions = ARRAY['Calienta 3–5 min andando; sube velocidad de forma progresiva.','Postura alta, mirada al frente, brazos relajados en oposición a las piernas.','Pasos relativamente cortos bajo la cadera; aterriza suave (no talonees fuerte).','Respira rítmica; mantén un ritmo donde puedas hablar frases cortas (zona aeróbica) o el intervalo pedido.','Error típico: agarrarse a los laterales de la cinta o inclinación excesiva innecesaria.','Enfría 2–3 min andando. Hidrátate y progresa volumen antes que velocidad.']::text[],
  mobile_equipment = NULLIF('Cinta de correr',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('cardio',''),
  mobile_muscle_group = NULLIF('Cardio','')
WHERE catalog_key = 'catalog:Cinta / carrera';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','calves']::text[])>0 THEN ARRAY['quadriceps','calves']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Cinta de correr','') IS NOT NULL THEN ARRAY['Cinta de correr']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Cinta / carrera';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Bici estática: cardio de piernas con bajo impacto.',
  mobile_instructions = ARRAY['Ajusta sillín: rodilla casi extendida en el punto bajo del pedal, sin bloquear.','Manos suaves en el manillar; pedalea «redondo» (empuja y tira).','Elige resistencia que permita cadencia estable (p. ej. 80–100 rpm) según objetivo.','Torso estable; no te balancees lateralmente.','Error típico: sillín bajo (molestia de rodilla) o resistencia tan alta que empujas a tirones.','Incluye calentamiento y enfriamiento; usa intervalos si el plan lo pide.']::text[],
  mobile_equipment = NULLIF('Bicicleta estática',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('cardio',''),
  mobile_muscle_group = NULLIF('Cardio','')
WHERE catalog_key = 'catalog:Bici estática';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal','calves']::text[])>0 THEN ARRAY['hamstring','gluteal','calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Bicicleta estática','') IS NOT NULL THEN ARRAY['Bicicleta estática']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Bici estática';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Remoergómetro: cardio de cuerpo completo (piernas + tirón).',
  mobile_instructions = ARRAY['Pies fijados; agarra el mango con brazos extendidos y espalda neutra.','Secuencia: empuja con piernas → bisagra de cadera → tira el mango a costillas bajas.','Recupera en orden inverso: brazos → cadera → rodillas. Cadencia suave.','No redondees la espalda al llegar adelante; mantén los hombros activos.','Error típico: tirar solo de brazos o abrir demasiado pronto la espalda.','Piensa «piernas-cadera-brazos» al remada y lo contrario al recuperar.']::text[],
  mobile_equipment = NULLIF('Remoergómetro',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('cardio',''),
  mobile_muscle_group = NULLIF('Cardio','')
WHERE catalog_key = 'catalog:Remo máquina';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','quadriceps']::text[])>0 THEN ARRAY['upper-back','quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal','abs','biceps']::text[])>0 THEN ARRAY['hamstring','gluteal','abs','biceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Remoergómetro','') IS NOT NULL THEN ARRAY['Remoergómetro']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Remo máquina';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Paseo del granjero: caminas erguido con carga en cada mano; agarre, core y postura.',
  mobile_instructions = ARRAY['Coge las cargas, párate alto: hombros abajo y atrás, abdomen firme, mirada al frente.','Camina con pasos cortos y firmes; agarre máximo sin encoger trapecios.','Evita inclinarte a un lado; si una carga tira, reduce peso o distancia.','Respira; no aguantes la respiración todo el trayecto.','Error típico: pasos largos inestables o dejar que las cargas te desvíen la postura.','Estándar: distancia o tiempo con postura neutra; deja las cargas con control.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Farmer walk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Bear Hug Carry','Double Kettlebell Farmers Carry','Dumbbell Carry','Farmer carry','Sandbag Carry','Suitcase Carry']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearm','abs','trapezius']::text[])>0 THEN ARRAY['forearm','abs','trapezius']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','calves','obliques']::text[])>0 THEN ARRAY['gluteal','calves','obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Farmer walk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Press banca declinado: más énfasis en pecho inferior y tríceps.',
  mobile_instructions = ARRAY['Asegura pies en el banco declinado; omóplatos retraídos, glúteos estables.','Baja la barra al pecho bajo/medio con control; codos ~45°.','Empuja a bloqueo sobre el pecho; no rebotes en el esternón.','Rango completo y muñecas apiladas.','Error típico: declinación excesiva o carga que no puedes controlar arriba.','Si no tienes banco declinado, el cruce de poleas bajos puede aproximar el énfasis inferior.']::text[],
  mobile_equipment = NULLIF('Barra, Banco',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('chest',''),
  mobile_muscle_group = NULLIF('Pecho','')
WHERE catalog_key = 'catalog:Press banca declinado';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest']::text[])>0 THEN ARRAY['chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','deltoids']::text[])>0 THEN ARRAY['triceps','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra, Banco','') IS NOT NULL THEN ARRAY['Barra, Banco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Press banca declinado';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cruce de poleas: aperturas con tensión constante sobre el pecho.',
  mobile_instructions = ARRAY['Poleas altas o medias; da un paso adelante con torso estable y ligera inclinación.','Brazos semi-extendidos; cierra en arco hacia el centro del pecho.','Aprieta pecho al juntar las manos; vuelve abriendo hasta estirar sin arquear lumbar.','Codos blandos fijos (vuelo). Exhala al cerrar.','Error típico: press con flexión de codo o balanceo de tronco.','Ajusta altura de poleas: altas enfatizan pecho inferior; medias, porción media.']::text[],
  mobile_equipment = NULLIF('Polea',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('chest',''),
  mobile_muscle_group = NULLIF('Pecho','')
WHERE catalog_key = 'catalog:Cruce de poleas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest']::text[])>0 THEN ARRAY['chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','biceps']::text[])>0 THEN ARRAY['deltoids','biceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Polea','') IS NOT NULL THEN ARRAY['Polea']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Cruce de poleas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Remo sentado en polea: espalda media y dorsales con torso estable.',
  mobile_instructions = ARRAY['Pies en la plataforma; torso erguido con ligera inclinación; agarre neutro o prono.','Tira el agarre al abdomen, codos atrás, apretando omóplatos.','No uses balanceo de tronco; el movimiento nace de la espalda.','Extiende brazos con control manteniendo pecho alto.','Error típico: encoger hombros a las orejas o tirar solo de bíceps.','Pausa 1 s en contracción mejora el control escapular.']::text[],
  mobile_equipment = NULLIF('Polea',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Remo sentado';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','deltoids','forearm']::text[])>0 THEN ARRAY['biceps','deltoids','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Polea','') IS NOT NULL THEN ARRAY['Polea']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Remo sentado';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto sumo: stance ancho; glúteos, aductores y cuádriceps.',
  mobile_instructions = ARRAY['Pies anchos, puntas afuera; barra cerca de las espinillas; agarre dentro de las piernas.','Pecho alto, espalda plana; inhala y bracea. Empuja el suelo separando el suelo con los pies.','Extiende rodillas y cadera juntos; barra pegada. Bloquea sin hiperextender.','Baja con control manteniendo la misma postura de espalda.','Error típico: empezar con cadera demasiado alta o redondear al tirar.','El stance ancho pide movilidad de cadera: abre solo lo que puedas controlar.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Peso muerto sumo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Deficit Deadlift','Dumbbell Deadlift','Dumbbell Romanian Deadlift','Kettlebell Deadlift','Peso muerto','Peso muerto rumano','Trap Bar Deadlift']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','quadriceps','adductors']::text[])>0 THEN ARRAY['gluteal','quadriceps','adductors']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','upper-back','trapezius']::text[])>0 THEN ARRAY['hamstring','upper-back','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Peso muerto sumo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla búlgara: pierna trasera elevada; cuádriceps y glúteo de la pierna delantera.',
  mobile_instructions = ARRAY['Pie trasero en banco, torso erguido.','Baja a media profundidad sobre la pierna delantera.','Rodilla trasera cerca del suelo; empuja para subir.','Pie trasero elevado en banco; pie delantero lo bastante adelante para bajar vertical.','Torso erguido; baja hasta que la rodilla trasera se acerque al suelo y el muslo delantero ~paralelo.','Empuja con el pie delantero para subir; la pierna trasera estabiliza, no empuja de más.','Mancuernas a los lados o goblet; mira al frente.','Error típico: pie delantero demasiado cerca (rodilla viaja en exceso) o inclinarte desplomado.']::text[],
  mobile_equipment = NULLIF('Mancuernas, Banco',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Sentadilla búlgara';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas, Banco','') IS NOT NULL THEN ARRAY['Mancuernas, Banco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sentadilla búlgara';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Curl predicador: bíceps con brazos apoyados; menos trampa de balanceo.',
  mobile_instructions = ARRAY['Brazos apoyados en el pad; axilas cerca del borde superior; agarre cómodo.','Curl sin despegar los brazos del apoyo; controla el tramo inferior (más difícil).','No hiperextiendas del todo abajo si te molesta el codo; usa rango seguro.','Sube apretando bíceps; baja 3 s.','Error típico: despegar los codos del pad para hacer trampa.','Ideal para aislar; carga moderada y técnica estricta.']::text[],
  mobile_equipment = NULLIF('Barra, Banco predicador',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper arms',''),
  mobile_muscle_group = NULLIF('Bíceps','')
WHERE catalog_key = 'catalog:Curl predicador';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps']::text[])>0 THEN ARRAY['biceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearm']::text[])>0 THEN ARRAY['forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra, Banco predicador','') IS NOT NULL THEN ARRAY['Barra, Banco predicador']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Curl predicador';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Press francés / skull crusher: extensión de tríceps tumbado.',
  mobile_instructions = ARRAY['Tumbado; barra EZ o mancuerna sobre el pecho, brazos verticales, codos apuntando al techo.','Flexiona solo los codos bajando la carga hacia la frente/sien; brazos superiores quietos.','Extiende a bloqueo apretando tríceps; no abras los codos hacia fuera.','Exhala al extender. Controla el descenso.','Error típico: mover los hombros (se vuelve pullover) o cargar de más.','Si duele el codo, reduce rango o cambia a extensión en polea.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper arms',''),
  mobile_muscle_group = NULLIF('Tríceps','')
WHERE catalog_key = 'catalog:Press francés';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps']::text[])>0 THEN ARRAY['triceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearm','deltoids']::text[])>0 THEN ARRAY['forearm','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Press francés';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Elevaciones frontales: deltoides anterior hasta la altura de los ojos.',
  mobile_instructions = ARRAY['Mancuernas delante de muslos; agarre prono o neutro; torso quieto.','Eleva hasta altura de ojos con codos blandos; no balancees cadera.','Baja en 2–3 s. Alterna brazos si te ayuda a controlar.','Hombros lejos de las orejas; evita encoger trapecios.','Error típico: peso excesivo y swing. El deltoides anterior no necesita cargas enormes.','Combina con laterales y face pull para un hombro equilibrado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Elevaciones frontales';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest','trapezius']::text[])>0 THEN ARRAY['chest','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Elevaciones frontales';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rueda abdominal: rollout de core manteniendo pelvis neutra.',
  mobile_instructions = ARRAY['De rodillas, rueda bajo los hombros; pelvis neutra y costillas abajo.','Rueda hacia delante manteniendo el abdomen firme; solo hasta donde controles la lumbar.','Vuelve tirando con el core (no solo con los hombros) hasta la posición inicial.','Respira: exhala al salir, no aguantes en apnea forzada.','Error típico: hundir la lumbar al final del recorrido. Acorta el rango antes que forzar.','Progresión: rango corto → más largo → de pie (avanzado).']::text[],
  mobile_equipment = NULLIF('Rueda abdominal',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Ab wheel';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques','upper-back','deltoids','hip-flexors']::text[])>0 THEN ARRAY['obliques','upper-back','deltoids','hip-flexors']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Rueda abdominal','') IS NOT NULL THEN ARRAY['Rueda abdominal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Ab wheel';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Pasos laterales con banda: glúteo medio y estabilidad de cadera.',
  mobile_instructions = ARRAY['Banda sobre rodillas o tobillos; media sentadilla con torso alto.','Pasos laterales cortos sin juntar del todo los pies; tensión constante en la banda.','Rodillas alineadas con las puntas; no dejes que colapsen adentro.','Cambia de dirección a mitad de serie; mantén la altura de cadera estable.','Error típico: enderezarte a cada paso o dar zancadas demasiado largas.','Excelente activación de glúteo medio antes de sentadillas o como finisher.']::text[],
  mobile_equipment = NULLIF('Banda elástica',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Paso lateral con banda';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal']::text[])>0 THEN ARRAY['gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','obliques']::text[])>0 THEN ARRAY['abs','obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Banda elástica','') IS NOT NULL THEN ARRAY['Banda elástica']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Paso lateral con banda';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Remo invertido: remo con peso corporal bajo una barra o mesa.',
  mobile_instructions = ARRAY['Cuelga bajo una barra o mesa en plancha invertida: cuerpo recto, talones al suelo.','Tira el pecho a la barra apretando omóplatos; codos ~45°.','Baja a brazos extendidos sin hundir cadera.','Cuanto más horizontal el cuerpo, más difícil; sube la barra para facilitar.','Error típico: tirar solo de brazos o romper la plancha (cadera caída).','Progresión sólida hacia dominadas estrictas.']::text[],
  mobile_equipment = NULLIF('Barra fija',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Remo invertido';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','abs']::text[])>0 THEN ARRAY['biceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra fija','') IS NOT NULL THEN ARRAY['Barra fija']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Remo invertido';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Press Arnold: press con rotación de mancuernas; las tres cabezas del hombro.',
  mobile_instructions = ARRAY['Sentado o de pie; mancuernas a la altura de hombros con palmas hacia ti.','Presiona arriba rotando las palmas hacia delante de forma fluida.','Bloquea sin encoger trapecios; costillas abajo.','Baja rotando de nuevo a palmas hacia ti; controla el descenso.','Error típico: arching lumbar o rotación brusca con demasiado peso.','Cubre bien las tres cabezas del deltoides; empieza ligero para pulir la rotación.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Press Arnold';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','chest']::text[])>0 THEN ARRAY['triceps','chest']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Press Arnold';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Arrancada completa: del suelo a overhead en un tiempo, recepción en squat.',
  mobile_instructions = ARRAY['Setup: barra sobre mediopié, AGARRE ANCHO de snatch, espalda plana.','Tirón: extiende cadera y rodillas; barra sube pegada con agarre ancho.','Bloquea overhead de pie, brazos extendidos, agarre ancho.','Setup: barra sobre mediopié, agarre ancho, cadera sobre rodillas, espalda plana.','Primer tirón: empuja el suelo hasta rodillas con la barra pegada; torso aún inclinado.','Segundo tirón: extiende cadera/rodillas/tobillos; los brazos terminan el encogimiento.','Pasa bajo la barra a squat overhead (o power) y bloquea; levántate a pie.','Error típico: tirar temprano de brazos o alejar la barra del cuerpo.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Alternating Dumbbell Snatch','Dumbbell Power Snatch','Dumbbell Snatch','Hang Snatch','Kettlebell Snatch','Power Snatch']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','trapezius','abs']::text[])>0 THEN ARRAY['deltoids','trapezius','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancada inversa con barra apoyada en la espalda alta (back rack): da un paso atrás y baja la rodilla de forma controlada, manteniendo el tronco estable. Trabajo unilateral de cuádriceps, glúteos y equilibrio.',
  mobile_instructions = ARRAY['Ajusta la barra sobre los trapecios (back rack) con las manos equidistantes, hombros activos y abdomen firme antes de dar el primer paso atrás.','Da un paso hacia atrás suficientemente largo para apoyar la punta del pie y repartir la carga: el pie delantero debe permanecer plano y estable.','Inhala y desciende con control hasta acercar la rodilla trasera al suelo; mantén la columna neutra y la rodilla delantera alineada con los dedos del pie.','Empuja el suelo con el pie delantero y exhala al volver a la posición de inicio; alterna las piernas solo si así lo indica la programación.','Error típico: inclinar demasiado el torso, dejar caer la rodilla de atrás de golpe o perder el equilibrio por separar poco los pies.','Estándar: cadera y rodilla se extienden por completo al terminar cada repetición, sin apoyar la barra sobre el cuello ni permitir que el talón delantero se levante.','Si no puedes mantener el equilibrio, practica primero reverse lunges sin carga y después con barra vacía; progresión: carga ligera y repeticiones simétricas por pierna.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Back rack reverse lunge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Back rack reverse lunge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Arrancada recibida en semi-flexión (power), no squat profundo.',
  mobile_instructions = ARRAY['Desde suelo: primer tirón controlado, segundo tirón explosivo, recepción en cuarto/medio squat (cadera sobre rodillas).','Agarre ancho de arrancada; barra cerca del cuerpo; brazos largos hasta el encogimiento.','Recibe con brazos bloqueados overhead y párate.','Error típico: recepción demasiado profunda (ya no es power) o brazos que tiran pronto.','Estándar power: cadera por encima de la rodilla al atrapar. Progresión a arrancada completa cuando el power sea sólido.','Inhala antes del tirón; exhala al estabilizar arriba.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Power Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Alternating Dumbbell Snatch','Dumbbell Power Snatch','Hang Snatch','Snatch']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','trapezius']::text[])>0 THEN ARRAY['deltoids','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Power Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Arrancada desde hang (barra en muslos).',
  mobile_instructions = ARRAY['Levanta la barra a hang (típicamente sobre rodillas): bisagra, espalda tensa, hombros sobre la barra, brazos largos.','Desde hang, extiende cadera y rodillas con fuerza (triple extensión); barra pegada a los muslos.','Encoge y tira codos altos; pasa bajo la barra a recepción overhead en sentadilla completa.','Bloquea brazos, estabiliza y levántate. Baja a hang o suelo según la serie.','Error típico: flexionar brazos pronto o ‘colar’ sin extensión completa. Salta vertical antes de tirar bajo.','Estándar: recepción estable overhead con cadera bajo rodillas. Empieza ligero desde hang alto.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Hang Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Alternating Dumbbell Snatch','Dumbbell Power Snatch','Power Snatch','Snatch']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hang Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Hang snatch recibida en squat profundo.',
  mobile_instructions = ARRAY['Hang + recepción en overhead squat completa (no power). Misma mecánica de extensión y tirón bajo.','Mantén pecho alto en el fondo overhead; hombros activos ‘empujando’ la barra al techo.','Pies a ancho de sentadilla al recibir; mira al frente.','Levántate con control hasta de pie con barra bloqueada.','Error típico: cortar profundidad o perder el equilibrio adelante. Usa OHS ligeros como preparación.','Si no llegas al fondo, trabaja movilidad de tobillo/hombro y drop snatch.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Hang Squat Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hang Squat Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Hang snatch recibida en power.',
  mobile_instructions = ARRAY['Hang sobre rodillas: pecho alto, espalda tensa, hombros sobre la barra, brazos largos, peso en mediopié.','Extiende cadera y rodillas con fuerza (piensa ‘salta vertical’); barra pegada; brazos siguen largos hasta el shrug.','Tira bajo y recibe overhead en cuarto/medio squat (cadera sobre rodillas); bloquea y párate.','Error típico: flexionar brazos pronto o colarte sin extensión completa. Primero extensión, luego tirón bajo.','Estándar power: recepción parcial con brazos bloqueados. Carga ligera al aprender el hang.','Si pierdes la barra adelante, mantén hombros sobre la barra más tiempo en el tirón.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Hang power snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius']::text[])>0 THEN ARRAY['trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hang power snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Muscle snatch: tirón continuo sin sentadilla bajo la barra.',
  mobile_instructions = ARRAY['Desde suelo o hang, tira la barra a overhead SIN flexionarte bajo ella: casi un press alto con impulso de piernas.','Extiende cadera, encoge y ‘barre’ la barra arriba con brazos; pies quietos o apenas se mueven.','Bloquea overhead de pie; no hay squat de recepción.','Error típico: colarte en semi-sentadilla (ya no es muscular). Usa carga ligera.','Sirve para enseñar trayectoria cercana y fuerza de tirón. No es el estándar de competición de snatch.','Si no puedes, haz snatch-grip high pull + press.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Muscle Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','trapezius']::text[])>0 THEN ARRAY['deltoids','trapezius']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps']::text[])>0 THEN ARRAY['triceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Muscle Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Arrancada con barra elevada en bloques.',
  mobile_instructions = ARRAY['Barra sobre bloques a la altura elegida (rodilla/mid-thigh). Pies bajo barra, espalda tensa, hombros sobre la carga.','Empuja el suelo y completa el segundo/tercer tirón sin el primer tirón completo del suelo.','Recibe overhead (power o squat según programación) y levántate.','Baja la barra a los bloques con control; no la sueltes de golpe.','Error típico: inclinarte demasiado o perder contacto barra–muslo. Mantén dorsal activo.','Ideal para reforzar la zona débil del tirón. Carga submáxima al aprender.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Block Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','trapezius']::text[])>0 THEN ARRAY['deltoids','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Block Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Arrancada con pausa en posición (rodilla/muslo) según indicación.',
  mobile_instructions = ARRAY['Desde suelo o hang, haz una pausa deliberada en el punto técnico (rodilla o mid-thigh) 1–2 s.','Mantén espalda tensa y hombros sobre la barra durante la pausa; no redondees.','Tras la pausa, completa extensión explosiva y recepción overhead.','La pausa enseña posiciones; carga moderada (técnica > kilos).','Error típico: ‘saltar’ la pausa o rebotar. Reloj interno estricto.','Úsala para corregir segundo tirón flojo o despegue prematuro.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Pause Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','abs']::text[])>0 THEN ARRAY['quadriceps','abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Pause Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'OHS desde soportes o drop a squat overhead (snatch balance).',
  mobile_instructions = ARRAY['Barra en espalda o desde press a overhead; pies a ancho de squat; baja a OHS manteniendo barra alineada sobre mediopié.','Empuja la barra ‘al techo’ con hombros activos; torso vertical.','Sube y baja en el fondo sin perder el equilibrio; pausa opcional abajo.','Error típico: barra delante de la cabeza o talones que se levantan.','Trabaja movilidad de hombro/tobillo. Carga ligera, reps técnicas.','Transfiere a recepción de arrancada: misma postura overhead.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Snatch Balance';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Snatch Balance';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Desde espalda, drop a squat overhead sin tirón de piernas.',
  mobile_instructions = ARRAY['Barra en espalda (o desde soporte); sin tirón de piernas fuerte, ‘déjate caer’ a OHS con brazos bloqueando overhead.','Pies abren a squat; barra queda sobre mediopié; párate.','Error típico: press-out o caer sin bloquear. Empuja la barra al techo al bajar.','Carga ligera. Excelente para confianza overhead y velocidad bajo la barra.','Si pierdes el equilibrio adelante, trabaja OHS y movilidad.','No es un push press: las piernas caen, no empujan la barra arriba primero.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Drop snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Drop snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Snatch desde posición alta (puntillas/tall) enfatizando velocidad bajo la barra.',
  mobile_instructions = ARRAY['De pie, barra en muslos altos; shrug y tira bajo a OHS/power overhead sin gran bisagra previa.','Velocidad bajo la barra y trayectoria cercana. Carga ligera.','Error típico: press a overhead. Debes caerte bajo la barra.','Drill clásico de tercer tirón. Combina con drop snatch.','Si pierdes la barra adelante, enfatiza ‘codos altos y afuera’.','Estándar: recepción overhead estable desde tall.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Tall snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','abs']::text[])>0 THEN ARRAY['trapezius','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Tall snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Recepción de arrancada en split (tijera).',
  mobile_instructions = ARRAY['Tirón de arrancada completo; en la recepción abre en zancada (split) en vez de squat simétrico.','Un pie adelante, otro atrás; barra bloqueada overhead; torso vertical.','Recupera pies al ancho de hombros y párate con la barra arriba.','Error típico: split demasiado estrecho o rodilla delantera que se pasa de la punta del pie en exceso.','Practica el split sin carga (overhead lunges) antes de cargar.','Útil si la movilidad de squat overhead limita; no sustituye el trabajo de OHS.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Split Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal']::text[])>0 THEN ARRAY['gluteal']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Split Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Tirón de arrancada sin recepción overhead.',
  mobile_instructions = ARRAY['Como arrancada pero sin recepción overhead: extiende y encoge con barra ancha; la barra sube alto y baja.','Espalda tensa; barra cerca; brazos largos hasta el shrug.','Error típico: convertir en remo. Es un salto vertical con barra.','Entrena fuerza del pull. Carga > snatch técnico a menudo, pero con forma.','No hace falta squat bajo. Controla la bajada.','Estándar: triple extensión clara + barra alta cerca del cuerpo.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Snatch Pull';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','gluteal']::text[])>0 THEN ARRAY['trapezius','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','forearm']::text[])>0 THEN ARRAY['hamstring','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Snatch Pull';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto con agarre ancho de arrancada.',
  mobile_instructions = ARRAY['Agarre ancho de snatch; peso muerto con espalda tensa hasta de pie; barra cerca de las piernas.','Hombros sobre la barra más tiempo que en un DL convencional; no redondees.','Baja con control por la misma trayectoria.','Error típico: tirar con los brazos o separar la barra de las piernas.','Entrena posición de arrancada. Carga < snatch max habitualmente.','Estándar: extensión completa de cadera arriba, espalda neutra.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Snatch-Grip Deadlift';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Snatch-Grip Deadlift';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada completa a rack frontal en squat.',
  mobile_instructions = ARRAY['Setup: barra sobre mediopié, agarre de clean.','Recibe en front squat: barra delante del cuello, codos altos, cadera baja.','Párate en rack frontal bloqueado.','Setup: agarre al ancho de hombros, barra sobre mediopié, espalda tensa.','Tirón con barra cerca; extiende cadera y encoge hacia el rack frontal.','Recibe en squat (o power) con codos altos; párate a extensión completa.','Baja o suelta la barra según el contexto.','Error típico: codos bajos en la recepción o profundidad incompleta.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Clean','Dumbbell Power Clean','Hang Clean','Kettlebell Clean','Power Clean','Sandbag clean']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','deltoids','abs']::text[])>0 THEN ARRAY['trapezius','deltoids','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada recibida en power.',
  mobile_instructions = ARRAY['Clean desde suelo o hang con recepción en cuarto/medio squat (cadera sobre rodillas), barra en rack frontal.','Tirón vertical, codos rápidos alrededor de la barra; párate.','Error típico: press de brazos o recepción con torso desplomado.','Estándar power: cadera sobre rodilla al atrapar. Puente a clean completo después.','Inhala antes del tirón; exhala al fijar el rack.','Si los codos no suben, aligera y haz tall cleans.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Power Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Clean','Dumbbell Power Clean','Hang Clean']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','deltoids']::text[])>0 THEN ARRAY['trapezius','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Power Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada colgante: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Barra en muslos, bisagra ligera, espalda plana.','Extiende cadera y tira: barra sube pegada al cuerpo.','Recibe en rack frontal (barra delante del cuello, codos altos) y párate.','Barra en hang (muslos): espalda plana, brazos largos, abdomen firme.','Bisagra ligera y tirón: extiende cadera hacia rack frontal.','Recibe con codos altos y párate a extensión completa.','Devuelve la barra al hang con control.','Error típico: hang demasiado alto o recepción con torso desplomado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Hang Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Clean','Dumbbell Power Clean','Power Clean']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','abs']::text[])>0 THEN ARRAY['trapezius','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hang Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Hang clean a squat profundo.',
  mobile_instructions = ARRAY['Desde hang, clean completo a squat frontal (cadera bajo rodillas) con barra en rack, codos altos.','Extensión completa antes de tirar bajo; recibe y levántate a front squat.','Error típico: power clean disfrazado (no bajas) o codos bajos en el rack.','Pausa en hang para fijar postura. Carga técnica primero.','Estándar: recepción en squat completo + de pie con barra en rack.','Si el rack duele, trabaja movilidad de muñeca/hombro y front squat.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Hang Squat Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Hang Squat Clean']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','trapezius']::text[])>0 THEN ARRAY['gluteal','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hang Squat Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Hang clean a recepción power.',
  mobile_instructions = ARRAY['Barra en hang (sobre rodillas); espalda tensa; extiende y recibe en rack en power (cadera sobre rodillas).','Codos rápidos; torso alto en la recepción; párate.','Error típico: hang demasiado alto sin tensión de isquios, o recepción desplomada.','Excelente para el segundo tirón. Carga técnica primero.','Estándar power + rack sólido.','Si los codos fallan, tall clean.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Hang power clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Hang Power Clean']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius']::text[])>0 THEN ARRAY['trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hang power clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Muscle clean sin sentadilla bajo la barra.',
  mobile_instructions = ARRAY['Tira la barra a rack frontal SIN sentarte bajo ella: impulso de piernas + encogimiento + codos altos.','Pies casi fijos; termina de pie en rack.','Error típico: colarte en squat. Usa poco peso.','Entrena trayectoria y velocidad de codos. No reemplaza el clean completo.','Si no llega al rack, haz high pull + front squat por separado.','Mantén la barra cerca del cuerpo todo el recorrido.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Muscle Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius']::text[])>0 THEN ARRAY['trapezius']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','biceps']::text[])>0 THEN ARRAY['deltoids','biceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Muscle Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada desde bloques.',
  mobile_instructions = ARRAY['Barra en bloques; organiza espalda y hombros sobre la carga; tirón y recepción en rack.','Enfoca la porción del pull que entrenas (mid-thigh → extensión).','Baja a bloques con control.','Error típico: empezar con cadera demasiado alta o redondear.','Carga submáxima al aprender la posición de bloques.','Útil cuando el primer tirón del suelo es el limitante.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Block Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius']::text[])>0 THEN ARRAY['trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Block Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada con pausa técnica.',
  mobile_instructions = ARRAY['Pausa 1–2 s en la posición marcada (suelo, rodilla o hang) manteniendo espalda tensa.','Completa el tirón y la recepción en rack (power o squat).','La pausa corrige despegue y posición de hombros sobre la barra.','Error típico: acortar la pausa bajo fatiga. Sé estricto con el tiempo.','Carga moderada. Combina con tirones de cargada.','Si redondeas en la pausa, baja kilos.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Pause Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','abs']::text[])>0 THEN ARRAY['quadriceps','abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius']::text[])>0 THEN ARRAY['trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Pause Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Clean desde posición tall.',
  mobile_instructions = ARRAY['De pie con barra en muslos altos; sin bisagra profunda, encoge y tira codos a rack; recibe con poca flexión.','Entrena velocidad de codos y recepción. Carga ligera.','Error típico: convertir en power clean con dip grande. Quédate ‘alto’.','Útil como drill. No sustituye cleans completos.','Si los codos no giran, baja peso y haz front rack transitions.','Estándar: rack sólido desde posición tall.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Tall clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius']::text[])>0 THEN ARRAY['trapezius']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Tall clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Tirón de clean sin recepción en rack.',
  mobile_instructions = ARRAY['Igual que el clean pull: DL + extensión explosiva + shrug, sin rack.','Barra cerca; espalda neutra; termina alto de pie.','Error típico: remo de codos temprano. Brazos largos.','Sirve para sobrecargar el tirón. Baja la barra con control.','Combina con tall cleans. Exhala en la extensión.','Estándar: extensión completa y barra que sigue subiendo tras la cadera.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Clean Pull';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','gluteal']::text[])>0 THEN ARRAY['trapezius','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring']::text[])>0 THEN ARRAY['hamstring']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Clean Pull';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Clean + press estricto.',
  mobile_instructions = ARRAY['Clean a rack frontal; sin pausa larga, press estricto a overhead (sin dip de piernas).','Bloquea arriba con torso firme; baja a rack o suelo según el WOD.','Error típico: convertir el press en push press sin querer. Piernas quietas en el press.','Si el press falla, baja la carga del clean o haz push press programado.','Estándar: rack sólido + bloqueo overhead completo.','Respira: exhala al press.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Clean and Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Clean and Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada y envión: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Rack frontal tras la cargada, de pie.','Dip-drive: flexión corta y empuje.','Bloquea overhead y recupera pies.','Cargada a rack frontal estable; recompón la respiración si hace falta.','Dip corto vertical, drive y jerk (split o power) a overhead.','Bloquea con brazos extendidos; recupera los pies en línea y demuestra control.','Baja a hombros o suelo según la norma.','Error típico: dip hacia delante o recepción con pies inestables.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Clean and Jerk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Dumbbell Clean and Jerk','Kettlebell Clean and Jerk','Log Clean And Jerk']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','triceps','abs']::text[])>0 THEN ARRAY['deltoids','triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Clean and Jerk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Dip-drive y press con impulso de piernas.',
  mobile_instructions = ARRAY['Rack frontal; dip corto de piernas y drive; press la barra a overhead usando ese impulso; piernas se extienden, no hay recepción en squat.','Bloquea arriba; baja a hombros con control.','Error típico: dip hacia adelante o no usar piernas (se vuelve strict press flojo).','Puente al jerk. Exhala al subir.','Estándar: bloqueo overhead; piernas ayudan pero no hay split/power receive profundo.','Si el hombro falla, baja carga.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Push press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Dumbbell Push Press','Dumbbell Strict Press','Kettlebell Press','Kettlebell Push Press','Strict press']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','quadriceps']::text[])>0 THEN ARRAY['triceps','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Push press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Jerk con recepción en semi-flexión (no split).',
  mobile_instructions = ARRAY['Rack frontal; dip-drive; recibe con ligera flexión de rodillas y brazos bloqueados overhead; párate.','Más recepción que el push press (que no se sienta bajo la barra).','Error típico: no sentarte nada (press) o press-out.','Dip vertical; barra camino recto.','Estándar: lockout overhead estable tras la recepción.','Si fallas el timing, practica dip-drive sin soltar el rack.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Push jerk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Push Jerk']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','quadriceps']::text[])>0 THEN ARRAY['triceps','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Push jerk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Split jerk: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Front rack, dip corto de piernas.','Drive y split: un pie delante, otro atrás, brazos bloqueados overhead.','Recupera pie delantero y luego el trasero bajo la barra.','Desde front rack: dip corto, drive y split delante/atrás.','Recibe overhead con brazos bloqueados; rodilla delantera ~vertical.','Recupera pie delantero y luego el trasero, barra aún arriba.','Demuestra estabilidad antes de bajar la barra.','Error típico: split mal medido o codos blandos.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Split jerk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','quadriceps']::text[])>0 THEN ARRAY['triceps','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Split jerk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Jerk power (pies en línea).',
  mobile_instructions = ARRAY['Desde rack frontal: dip corto, drive vertical, recibe en cuarto squat con brazos bloqueados overhead (pies simétricos).','Sin split. Párate con la barra arriba.','Error típico: press-out o dip hacia adelante. Dip vertical.','Puente entre push press y split jerk.','Si no bloqueas, baja carga o haz push press.','Estándar: recepción power + lockout claro.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Power jerk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps']::text[])>0 THEN ARRAY['triceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Power jerk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Jerk balance / práctica de recepción overhead.',
  mobile_instructions = ARRAY['Desde rack frontal o espalda, dip corto y drive; recibe en split o power con brazos bloqueados overhead.','Enfócate en el dip-drive vertical y el bloqueo rápido, no en el peso máximo.','Pies firmes; recupera a posición de pie.','Error típico: press-out (brazos no bloquean al recibir) o dip hacia adelante.','Drill: jerk balance con pausas. Si no bloqueas, baja carga.','Estándar: recepción estable sin press-out.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Jerk Balance';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Jerk Balance';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Press militar estricto sin dip de piernas.',
  mobile_instructions = ARRAY['Barra en rack frontal; pies firmes; press a overhead sin impulso de piernas; bloquea y baja a hombros.','Glúteos y abdomen apretados; no arquees lumbar para terminar la rep.','Error típico: push press oculto (rodillas). Grábate de lado.','Exhala al press. Agarre al ancho de hombros.','Si no bloqueas, baja carga o usa push press programado.','Estándar: piernas quietas + lockout overhead.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Strict press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Axle Press','Dumbbell Push Press','Dumbbell Strict Press','Kettlebell Press','Kettlebell Push Press','Log Press','Push press']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Strict press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Press desde nuca (movilidad de hombro requerida).',
  mobile_instructions = ARRAY['Barra detrás de la nuca (agarre ancho cómodo); press a overhead y baja detrás de la cabeza.','Solo con buena movilidad; torso firme; no fuerces dolor de hombro.','Error típico: arquear lumbar para ‘acabar’ la rep.','Alternativa más segura: press frontal / push press.','Carga moderada. Si pinza, abandona la variante.','Estándar: bloqueo arriba y control detrás de nuca abajo.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Behind-the-Neck Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','trapezius']::text[])>0 THEN ARRAY['triceps','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Behind-the-Neck Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Jerk desde nuca.',
  mobile_instructions = ARRAY['Barra en espalda alta (detrás de nuca); dip corto, drive y recibe overhead (split o power).','Movilidad de hombro exigente: solo si tienes OHS cómodo.','Bloquea arriba y recupera pies.','Error típico: press-out o dolor anterior de hombro. Abandona si pinza.','Alternativa más segura: jerk desde frontal. Carga moderada.','Estándar: bloqueo overhead estable desde detrás de nuca.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Behind-the-Neck Jerk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','quadriceps']::text[])>0 THEN ARRAY['triceps','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Behind-the-Neck Jerk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Press en squat profundo (front o OH).',
  mobile_instructions = ARRAY['En squat profundo (barra en espalda o frontal), press a overhead y baja manteniendo el fondo de squat.','Movilidad extrema de hombro y torso; carga muy ligera.','Error típico: subir del squat para poder press. Quédate abajo.','Excelente para OHS y recepción de snatch. Si no llega, press en squat parcial.','Para si hay dolor de hombro. Prioriza calidad.','Estándar: press completo sin salir de la profundidad de squat.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Sots press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps']::text[])>0 THEN ARRAY['triceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sots press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Overhead squat: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Barra bloqueada overhead, agarre ancho, de pie.','Siéntate profundo manteniendo la barra activa.','Levántate sin perder el bloqueo.','Barra bloqueada overhead, agarre ancho, hombros activos.','Baja a squat profundo con la barra sobre mediopié; torso vertical.','Rodillas alineadas con pies; talones abajo.','Sube sin perder el bloqueo; termina de pie con control.','Error típico: barra que se adelanta por falta de movilidad o core flojo.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Overhead squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Dumbbell Overhead Squat']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Overhead squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancada con barra en rack frontal.',
  mobile_instructions = ARRAY['Barra en rack frontal, codos altos; da un paso y baja a zancada (rodilla trasera cerca del suelo).','Torso vertical; empuja para volver; alterna o camina.','Error típico: codos que caen o rodilla delantera que colapsa adentro.','Usa carga que te permita mantener el rack. Inhala al bajar, exhala al subir.','Progresión: reverse lunge sin barra → goblet → front rack.','Estándar: rodilla trasera baja y recuperación de pie con rack intacto.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Front rack lunge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Double Kettlebell Front Rack Lunge','Dumbbell Front Rack Lunge','Kettlebell Front Rack Lunge']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','abs']::text[])>0 THEN ARRAY['gluteal','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Front rack lunge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Front squat con pausa abajo.',
  mobile_instructions = ARRAY['Front squat; pausa 1–3 s en el fondo con codos altos y torso vertical; luego sube.','No rebotes; mantén tensión en la pausa.','Error típico: codos que caen en la pausa o perder el aire. Bracea antes de bajar.','Carga menor que el front squat normal. Excelente para fuerza en el hoyo.','Estándar: profundidad legal + pausa completa + stand.','Si el rack duele, usa crossed-arm o straps de clean.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Pause Front Squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','abs']::text[])>0 THEN ARRAY['quadriceps','abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal']::text[])>0 THEN ARRAY['gluteal']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Pause Front Squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'High pull con stance sumo.',
  mobile_instructions = ARRAY['Stance sumo; agarra la barra; extiende cadera y tira la barra alto hacia el pecho/mentón con codos altos.','Barra cerca del cuerpo; no redondees al despegar.','Baja con control. Exhala al pull.','Error típico: remo de brazos sin extensión de cadera, o abrir codos detrás de la línea.','Carga moderada por estrés de hombro. Alternativa: KB sumo high pull.','Estándar: cadera extendida + barra a altura de pecho/mentón.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Sumo high pull';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','gluteal']::text[])>0 THEN ARRAY['trapezius','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','quadriceps']::text[])>0 THEN ARRAY['deltoids','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sumo high pull';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Variante del snatch pull con agarre amplio que añade un tirón alto de codos después de la extensión completa de piernas y cadera. No incluye recepción de la barra.',
  mobile_instructions = ARRAY['Sitúa la barra sobre el mediopié con agarre amplio de arrancada, hombros ligeramente por delante y el tronco firme antes de iniciar el movimiento.','Realiza la primera tirada manteniendo la barra próxima a las piernas y sostén una trayectoria equilibrada durante la extensión progresiva de rodillas y cadera.','Extiende completamente piernas y cadera antes de permitir la subida de los codos; no conviertas el inicio en un remo de brazos desde el suelo.','Lleva los codos altos y hacia los lados con la barra cerca del cuerpo, sin intentar introducirte debajo ni estabilizarla overhead.','Desciende de forma controlada, recupera la posición de salida y utiliza una carga que te permita repetir el patrón sin acelerar a costa de perder técnica.','Error típico: flexionar los brazos demasiado pronto o alejar la barra del cuerpo. Progresión: domina primero el tirón de arrancada sin tirón alto.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Snatch High Pull';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','gluteal']::text[])>0 THEN ARRAY['trapezius','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','deltoids']::text[])>0 THEN ARRAY['hamstring','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Snatch High Pull';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Derivado de la cargada con tirón alto de codos tras la extensión de cadera y rodillas. Desarrolla la trayectoria y velocidad del tirón sin realizar la recepción en rack.',
  mobile_instructions = ARRAY['Adopta la salida de cargada con agarre algo más ancho que los hombros, barra sobre mediopié, espalda activa y presión uniforme de ambos pies.','Eleva la barra manteniéndola junto al cuerpo, con hombros y cadera coordinados durante la primera tirada hasta superar las rodillas.','Extiende con fuerza rodillas y cadera y termina la extensión antes de añadir un tirón de codos altos; evita encoger el tronco hacia atrás.','Eleva los codos manteniendo la barra cerca de la línea del cuerpo, sin girar las muñecas para recibirla en rack frontal.','Baja la barra de manera controlada y repite con una carga que permita conservar la altura y la velocidad prescritas en todas las repeticiones.','Error típico: intentar subir la barra a fuerza de bíceps desde el suelo. Progresión: tirón de cargada clásico antes de añadir el tirón alto.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Clean High Pull';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','gluteal']::text[])>0 THEN ARRAY['trapezius','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','deltoids']::text[])>0 THEN ARRAY['hamstring','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Clean High Pull';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto específico con salida, agarre y posiciones del primer tirón de cargada. La finalidad es reforzar la salida y el control postural, no realizar una cargada.',
  mobile_instructions = ARRAY['Coloca los pies bajo las caderas y la barra sobre el mediopié; utiliza agarre de cargada y prepara un tronco firme con la espalda neutra.','Antes de despegar, crea tensión sobre la barra y empuja el suelo con toda la planta para iniciar la subida sin que la cadera se dispare hacia arriba.','Supera las rodillas manteniendo hombros por delante de la barra y el recorrido cerca de las piernas, tal como harías en el primer tirón de cargada.','Finaliza de pie por extensión de cadera y rodillas sin encogimiento excesivo, salto ni giro de codos; no existe recepción en rack.','Desciende sin perder postura y restablece la posición de salida; trabaja con cargas acordes al objetivo técnico y nunca persigas un máximo sin control.','Error típico: convertirlo en un peso muerto convencional cambiando la posición inicial y el ángulo del tronco. Progresión: variantes desde bloques.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Clean Deadlift';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','abs']::text[])>0 THEN ARRAY['quadriceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Clean Deadlift';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Variante del jerk con impulso vertical y recepción de la barra en sentadilla overhead profunda. Exige buena movilidad y estabilidad; no es la misma recepción que push jerk.',
  mobile_instructions = ARRAY['Parte con la barra estable en rack frontal y el abdomen activo; confirma que tienes la movilidad necesaria para una sentadilla profunda con brazos overhead.','Realiza una flexión corta y vertical de rodillas con talones apoyados, manteniendo el torso erguido antes de impulsar la barra con las piernas.','Empuja la barra hacia arriba y desciende activamente debajo de ella, llevando los codos al bloqueo y los hombros a una posición estable.','Recibe en una sentadilla overhead profunda con el peso equilibrado entre ambos pies, controlando la barra sobre el centro de apoyo.','Extiende las piernas hasta quedar erguido con los brazos bloqueados, estabiliza la barra y bájala únicamente cuando la recepción esté controlada.','Error típico: empujar la barra hacia delante o perder estabilidad al descender. Si falta movilidad, practica primero jerk convencional y overhead squat.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Squat Jerk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','quadriceps']::text[])>0 THEN ARRAY['deltoids','quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Squat Jerk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Drill de envión sin recepción final overhead: practicas una flexión vertical corta y una extensión explosiva manteniendo equilibrio y trayectoria de la barra.',
  mobile_instructions = ARRAY['Coloca la barra en rack frontal con codos cómodos, pies bajo las caderas y tronco vertical; mira al frente antes de comenzar la secuencia.','Flexiona rodillas unos pocos centímetros sin mover el pecho hacia delante ni levantar los talones: es un dip vertical y equilibrado.','Desde el fondo del dip, empuja el suelo y extiende con intención explosiva tobillos, rodillas y cadera manteniendo la barra próxima a su línea vertical.','Permite que la barra se eleve por el impulso, pero no la recibas overhead: este ejercicio aísla el inicio del envión y su trayectoria.','Amortigua la barra en rack con control, restablece tu posición y practica varias repeticiones limpias antes de aumentar la carga.','Error típico: inclinar el tronco o adelantar las rodillas perdiendo equilibrio. Progresión: dip estático, dip y drive, y después jerk.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Jerk Dip and Drive';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Jerk Dip and Drive';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Arrancada que comienza con la barra sobre bloques y se recibe arriba de la paralela. Se diferencia de la arrancada desde bloques con recepción profunda.',
  mobile_instructions = ARRAY['Sitúa la barra en bloques estables a la altura prescrita; coloca agarre amplio de arrancada y verifica que el espacio de recepción está despejado.','Adopta la postura de inicio con hombros activos y barra cerca del cuerpo sin golpear los bloques durante el primer impulso.','Empuja fuerte contra el suelo y extiende cadera y piernas manteniendo el recorrido cercano, evitando tirar prematuramente de brazos.','Recibe la barra overhead con brazos bloqueados por encima del paralelo, amortiguando con rodillas flexionadas y hombros activos.','Termina erguido, estabiliza overhead y devuelve la barra de forma segura a bloques; adapta la altura de salida al propósito de la sesión.','Error típico: recibir en sentadilla profunda, lo que lo convertiría en otra variante. Progresión: domina primero la arrancada de potencia básica.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Block Power Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','deltoids']::text[])>0 THEN ARRAY['trapezius','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Block Power Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada desde bloques sólidos que termina en rack frontal por encima del paralelo. Se diferencia de la cargada desde bloques con recepción profunda.',
  mobile_instructions = ARRAY['Coloca la barra sobre bloques sólidos a la altura indicada y adopta agarre de cargada con el tronco firme y los pies preparados para recibir.','Extiende rodillas y cadera sin separar la barra del cuerpo, manteniendo presión sobre el suelo antes del tramo explosivo.','Tras completar la extensión, gira los codos con rapidez y guía la barra al rack frontal en vez de levantarla solo con los brazos.','Recibe la cargada en una flexión de rodillas por encima del paralelo y estabiliza la barra cerca de la clavícula con el pecho erguido.','Recupera la posición erguida, baja o devuelve la barra a los bloques con control y repite respetando la altura de salida programada.','Error típico: recibir por debajo del paralelo o alejar la barra. Progresión: consolidar la cargada de potencia desde el suelo antes de usar bloques.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Block Power Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','abs']::text[])>0 THEN ARRAY['trapezius','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Block Power Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Press con impulso de piernas, agarre ancho de arrancada y barra situada en la espalda alta. La estabilidad overhead y la movilidad de hombro condicionan la carga.',
  mobile_instructions = ARRAY['Sitúa la barra en la espalda alta con agarre ancho de arrancada, muñecas cómodas y hombros capaces de alcanzar bloqueo overhead sin compensar la espalda.','Flexiona rodillas ligeramente con torso vertical y talones apoyados, sin convertir el dip en una sentadilla profunda.','Extiende piernas y cadera con fuerza y transmite el impulso a la barra, manteniendo el recorrido controlado desde la nuca.','Termina extendiendo los codos y estabiliza la barra sobre el centro del cuerpo, con abdomen firme y hombros activos.','Baja la barra de manera controlada a la parte alta de la espalda y repite sin forzar un rango que genere dolor o pérdida de estabilidad.','Error típico: arquear demasiado la zona lumbar o soltar el control al bajar. Progresión: usa una pica y confirma movilidad antes de añadir carga.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('Halterofilia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Snatch-Grip Push Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','quadriceps','trapezius']::text[])>0 THEN ARRAY['triceps','quadriceps','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Snatch-Grip Push Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Dominada estricta con lastre externo y control escapular: aumenta la dificultad del tirón vertical. Prioriza rango completo, agarre seguro y una carga que no comprometa hombros ni codos.',
  mobile_instructions = ARRAY['Asegura el cinturón o chaleco de lastre y comprueba que la carga no balancea; cuélgate de la barra con agarre firme y hombros activos.','Inicia la tracción deprimiendo las escápulas y lleva el pecho hacia la barra sin usar impulso excesivo de piernas o cadera.','Sube con control hasta superar la referencia acordada con la barbilla, sin proyectar el cuello hacia delante ni perder la tensión abdominal.','Desciende de forma deliberada hasta el rango completo permitido, manteniendo los codos y hombros estables y evitando una caída brusca.','Error típico: elegir demasiado lastre, acortar el recorrido o balancearse; baja la carga si no mantienes técnica estricta.','Progresión: domina primero las dominadas sin carga y añade el lastre gradualmente. Exhala al subir; detente ante dolor articular.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas, Lastre',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Dominadas lastradas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dominadas','Dominadas butterfly','Dominadas estrictas','Dominadas kipping','Jumping Pull-Up','L Pull Up','Negative Pull Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','biceps']::text[])>0 THEN ARRAY['upper-back','biceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearm','abs']::text[])>0 THEN ARRAY['forearm','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas, Lastre','') IS NOT NULL THEN ARRAY['Barra de dominadas, Lastre']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dominadas lastradas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Remo horizontal explosivo con pies elevados y anillas: tracción rápida del pecho hacia las manos, recepción controlada y cuerpo en bloque. Requiere dominar primero el remo estricto en anillas.',
  mobile_instructions = ARRAY['Ajusta las anillas a una altura estable, apoya los talones elevados y coloca el cuerpo recto desde los hombros hasta los tobillos.','Activa abdomen y glúteos para evitar que la cadera se hunda; mantén los hombros organizados antes de cada tracción explosiva.','Tira de las anillas hacia el costado del pecho con intención rápida, acercando los codos al tronco sin perder la alineación corporal.','Permite una liberación o transferencia mínima de tensión solo si dominas el gesto y recupera las anillas con agarre seguro y controlado.','Error típico: lanzar la cabeza, flexionar la cadera o perder las anillas; vuelve al remo estricto con pies en el suelo si ocurre.','Estándar: cada repetición comienza y termina con control. Usa progresión de remo en anillas, luego pies elevados y solo al final velocidad.']::text[],
  mobile_equipment = NULLIF('Anillas, Plataforma elevada',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Remo pliométrico en anillas pies elevados';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','deltoids','abs']::text[])>0 THEN ARRAY['biceps','deltoids','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas, Plataforma elevada','') IS NOT NULL THEN ARRAY['Anillas, Plataforma elevada']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Remo pliométrico en anillas pies elevados';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Dominada sin kipping: solo fuerza de tirón.',
  mobile_instructions = ARRAY['Cuelgue muerto, brazos extendidos, sin kipping; tira hasta barbilla sobre barra.','Baja en 2–3 s a extensión completa. Hombros activos desde el inicio.','Error típico: impulso de piernas oculto o rango incompleto abajo.','Si no puedes 1, usa banda, jackknife o negativos.','Estándar: sin kip, barbilla clara sobre la barra, brazos largos abajo.','Exhala al tirar; inhala arriba o en el descenso controlado.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Dominadas estrictas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dominadas','Dominadas butterfly','Dominadas kipping','Dominadas lastradas','Jumping Pull-Up','L Pull Up','Negative Pull Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','upper-back']::text[])>0 THEN ARRAY['upper-back','upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','abs']::text[])>0 THEN ARRAY['biceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dominadas estrictas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Dominada con impulso de kip.',
  mobile_instructions = ARRAY['Genera kip arch-hollow; usa la extensión de cadera para ayudar el tirón; barbilla sobre barra.','No tires de brazos antes de tiempo; el kip carga el pull.','Baja y reenlaza el kip para la siguiente si buscas ciclo.','Error típico: ‘tirón temprano’ o kip solo de piernas sin hollow.','Practica kip swings antes. Si hombros duelen, vuelve a strict o reduce volumen.','Estándar WOD: barbilla sobre barra; a menudo se permite kip salvo que diga strict.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Dominadas kipping';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dominadas','Dominadas butterfly','Dominadas estrictas','Dominadas lastradas','Jumping Pull-Up','L Pull Up','Negative Pull Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','deltoids']::text[])>0 THEN ARRAY['abs','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dominadas kipping';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Butterfly pull-up de alta cadencia.',
  mobile_instructions = ARRAY['Kip circular continuo: arch-hollow enlazado sin pausa; barbilla sobre barra cada ciclo.','Hombros activos; no te desplomes en el cuelgue muerto entre reps si buscas ciclo butterfly.','Error típico: perder el ritmo y convertir en kipping irregular o en strict fallido.','Aprende primero kip swing + kipping pull-up antes del butterfly.','Si no, kipping o strict. La calidad del ciclo > cantidad fea.','Estándar típico: barbilla sobre barra; extensión de brazos abajo según WOD.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Dominadas butterfly';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dominadas','Dominadas estrictas','Dominadas kipping','Dominadas lastradas','Jumping Pull-Up','L Pull Up','Negative Pull Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dominadas butterfly';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Dominada con agarre supino (chin-up).',
  mobile_instructions = ARRAY['Agarre supino (palmas a ti), ancho de hombros o algo más estrecho; cuelgue muerto.','Tira pecho a la barra; barbilla sobre; baja controlado.','Más bíceps y dorsal inferior que prono. No balancees.','Error típico: acortar el rango abajo. Extiende del todo.','Progresión: banda → full. Alternativa: australian chin-ups.','Estándar: mismo criterio de barbilla y extensión que dominadas.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('upper arms',''),
  mobile_muscle_group = NULLIF('Bíceps','')
WHERE catalog_key = 'catalog:Dominadas supinas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','upper-back']::text[])>0 THEN ARRAY['biceps','upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dominadas supinas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Chest to bar: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Cuelga con brazos extendidos y agarre firme.','Tira hasta la barbilla cerca de la barra.','Lleva el pecho a tocar la barra y baja con control.','Cuelga prono, hombros activos; kip o tirón estricto según el estándar.','Tira hasta que el pecho contacte la barra (no solo la barbilla).','Baja a extensión completa entre reps si se exige.','Piernas juntas; no cortes el contacto.','Error típico: contar chin-over-bar como C2B.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Chest to bar';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','upper-back']::text[])>0 THEN ARRAY['upper-back','upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','abs']::text[])>0 THEN ARRAY['biceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Chest to bar';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Dominada en anillas (inestables).',
  mobile_instructions = ARRAY['Anillas a la altura; cuelga con agarre neutro/prono según setup; tira pecho a anillas.','Estabiliza anillas (no dejes que se abran mucho); baja a extensión completa.','Error típico: balanceo excesivo o anillas que se van adelante.','Más inestable que barra: usa menos reps o asistencia al inicio.','Progresión: ring row → negatives → full.','Aprieta abdomen; piernas quietas en strict.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Dominadas en anillas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','abs']::text[])>0 THEN ARRAY['biceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dominadas en anillas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Remo invertido en anillas.',
  mobile_instructions = ARRAY['Anillas bajas; cuerpo en plancha invertida; tira pecho a anillas apretando omóplatos.','Cuerpo rígido; talones al suelo; codos cerca.','Baja con control a brazos extendidos.','Error típico: pikear cadera o encoger cuello. Más horizontal = más difícil.','Progresión a dominadas en anillas. Ajusta altura de anillas.','Estándar: pecho toca o llega cerca de anillas cada rep.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Remo en anillas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','biceps']::text[])>0 THEN ARRAY['upper-back','biceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Remo en anillas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Dominada arquero: un brazo más cargado.',
  mobile_instructions = ARRAY['Cuelga con agarre ancho; un brazo hace la mayor parte del tirón, el otro se extiende al lado como ‘arco’.','Tira hasta que la barbilla pase la barra hacia el lado del brazo de trabajo.','Baja controlado a cuelgue muerto y alterna o completa el lado antes de cambiar.','Hombros activos; evita balanceo excesivo salvo kip permitido.','Error típico: girar todo el torso en vez de desplazar el peso al brazo fuerte.','Progresión: asistencia con banda → archer negativo → archer completo. Si no, dominada asistida unilateral.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Archer pull-up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','deltoids']::text[])>0 THEN ARRAY['biceps','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Archer pull-up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Muscle-up barra: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Cuélgate de la barra con los brazos largos y sin apoyar los pies.','Tira del torso sobre la barra y gira las muñecas durante la transición.','Empuja la barra hasta quedar en soporte con los brazos completamente extendidos.','Cuelga muerto; kip o tirón estricto llevando la cadera a la barra.','Transición: pecho sobre la barra y muñecas a soporte.','Fondos hasta bloqueo completo sobre la barra.','Baja a hang con control; marca tirón, transición y fondo.','Error típico: intentar la transición sin altura de tirón.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Muscle-up barra';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Burpee Muscle-Up','Muscle-up anillas','Muscle-up estricto anillas','Muscle-up estricto barra']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','upper-back']::text[])>0 THEN ARRAY['upper-back','upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','chest','abs']::text[])>0 THEN ARRAY['triceps','chest','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Muscle-up barra';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Muscle-up anillas: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Cuélgate de las dos anillas con los brazos largos y los pies suspendidos.','Tira y acerca las anillas a la cintura mientras inclinas el torso hacia delante.','Extiende los codos y mantente arriba con una anilla a cada lado del cuerpo.','False grip si puedes; anillas estables y hombros activos.','Tirón alto al pecho y transición a soporte (anillas a las caderas).','Fondos a bloqueo con anillas cerca del cuerpo.','Baja a hang con control.','Error típico: abrir anillas en la transición o cortar el fondo.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Muscle-up anillas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Burpee Muscle-Up','Muscle-up barra','Muscle-up estricto anillas','Muscle-up estricto barra']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','chest','deltoids']::text[])>0 THEN ARRAY['triceps','chest','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Muscle-up anillas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Muscle-up en barra sin kip.',
  mobile_instructions = ARRAY['Cuelgue muerto; tira alto (pecho a barra) sin kip; transición llevando hombros sobre la barra; dip a bloqueo.','Mantén hollow; muñecas rotan en la transición; no te quedes tirando abajo de la barra.','Error típico: tirar demasiado pronto o transición incompleta (pecho no supera la barra).','Progresión: chest-to-bar strict → negatives lentos de transición → banded → full.','Si no, kipping MU o fuerza por partes (pull + dip).','Estándar: sin kip; soporte con brazos extendidos sobre la barra.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Muscle-up estricto barra';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Burpee Muscle-Up','Muscle-up anillas','Muscle-up barra','Muscle-up estricto anillas']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','triceps']::text[])>0 THEN ARRAY['upper-back','triceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest','abs']::text[])>0 THEN ARRAY['chest','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Muscle-up estricto barra';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Muscle-up en anillas sin kip.',
  mobile_instructions = ARRAY['False grip; cuelgue; tira pecho a anillas sin kip; transición a soporte; fondo hasta bloqueo.','Anillas cerca del cuerpo; false grip firme en la transición.','Error típico: perder false grip o usar kip oculto. Filmate.','Progresión: false grip hang → ring chest pull → transition drills → banded MU → full.','Si no, muscle-up con kip o dips + pull-ups por separado.','Estándar strict: sin impulso de piernas; soporte bloqueado arriba.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Muscle-up estricto anillas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Burpee Muscle-Up','Muscle-up anillas','Muscle-up barra','Muscle-up estricto barra']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','triceps']::text[])>0 THEN ARRAY['upper-back','triceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest']::text[])>0 THEN ARRAY['chest']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Muscle-up estricto anillas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Pullover a soporte sobre la barra.',
  mobile_instructions = ARRAY['Desde cuelgue o con impulso, lleva piernas/cadera sobre la barra y rota a soporte encima (pullover).','Tirón de abdomen y dorsal; finaliza en soporte con brazos extendidos o en posición pedida.','Error típico: quedarte a medias bajo la barra. Usa banda o salto asistido al aprender.','Progresión: toes to bar + soporte → pullover negativo.','Cuidado con la lumbar al rotar; controla el descenso.','No es un muscle-up: la trayectoria es alrededor de la barra.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Pull-over barra';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','abs']::text[])>0 THEN ARRAY['upper-back','abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest']::text[])>0 THEN ARRAY['chest']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Pull-over barra';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Toes to bar: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Cuelga con hombros activos.','Lleva piernas en pike hacia la barra.','Toca la barra con los pies y baja controlado.','Cuelga con hombros activos; kip arch-hollow o elevación estricta.','Pike hasta tocar la barra con ambos pies.','Baja a hang con control; no sueltes el agarre.','Brazos largos; el movimiento nace de cadera y core.','Error típico: un solo pie o swing sin contacto.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Toes to bar';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Toes to rings']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors','forearm']::text[])>0 THEN ARRAY['hip flexors','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Toes to bar';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'T2B sin kip excesivo; piernas a la barra.',
  mobile_instructions = ARRAY['Cuelgue; sin kip, eleva pies hasta tocar la barra con los dedos; baja controlado.','Piernas pueden ir semirrectas; pelvis posterior; no balancees.','Error típico: impulso oculto o tocar con tibia. Pies a la barra.','Progresión: knee raise → V-up colgado → TTB strict. Si no, K2E.','Estándar strict: sin kip, toque claro de pies en la barra.','Exhala al subir los pies.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Toes to bar estrictos';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Toes to bar estrictos';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rodillas a codos colgado.',
  mobile_instructions = ARRAY['Desde cuelgue (strict o kip), lleva rodillas a tocar codos o cerca según estándar.','Controla el descenso; reenlaza el kip si aplica.','Error típico: solo balancear sin elevar pelvis. Piensa en ‘cerrar’ el abdomen.','Progresión: knee raises → K2E → TTB.','Si no llegas, usa kip o reduce a hanging knee raise.','Estándar frecuente: rodillas claramente sobre la cadera / toque de codo.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Knees to elbows';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Knees to elbows';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Pies a anillas.',
  mobile_instructions = ARRAY['Cuelga de anillas; eleva pies a tocar anillas (strict o kip según WOD).','Anillas estables; abdomen activo; baja con control.','Error típico: balanceo lateral de anillas. Aprieta hacia adentro.','Más inestable que TTB en barra. Empieza strict corto.','Progresión: knees to rings → toes to rings.','Estándar: toque de pies en anillas.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Toes to rings';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Toes to bar']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Toes to rings';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cadera a la barra (kipping).',
  mobile_instructions = ARRAY['Desde cuelgue, kip o strict: eleva pies/cadera hasta tocar la barra con las caderas.','Piernas relativamente rectas o según estándar; no uses solo balanceo sin control.','Baja con control y reenlaza.','Error típico: tocar con muslos en vez de cadera, o kipping descontrolado.','Progresión: knees to elbows → toes to bar → hip to bar.','Si no, toes to bar estrictos o K2E.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Hip to bar';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','upper-back']::text[])>0 THEN ARRAY['abs','upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hip to bar';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Balanceo de kip en barra/anillas.',
  mobile_instructions = ARRAY['Cuelga; alterna arch (pecho adelante, pies atrás) y hollow (pecho atrás, pies adelante) con hombros activos.','El movimiento nace de hombros y core, no de solo flexionar rodillas.','Mantén piernas relativamente tensas; ritmo fluido.','Error típico: ‘tijera’ de piernas sin hollow/arch reales.','Base de toes-to-bar, MU y kipping pull-ups. Practica 5–10 swings de calidad.','Si hombros fatigan, paras y reposas; no balancies muerto.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Kip swing';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','upper-back']::text[])>0 THEN ARRAY['deltoids','upper-back']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kip swing';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'HSPU: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Pino contra la pared, brazos bloqueados.','Baja la cabeza hacia el suelo con codos flexionados ~90°.','Empuja hasta bloquear otra vez en pino.','Pino a pared (o libre): manos al ancho de hombros, cuerpo hueco.','Baja hasta que la cabeza toque el suelo (o el déficit pedido).','Empuja a bloqueo completo; orejas entre los brazos.','Evita el banana excesivo de lumbar.','Error típico: rango corto o codos muy abiertos.']::text[],
  mobile_equipment = NULLIF('Pared',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:HSPU';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['HSPU deficit','HSPU libre','Kipping Handstand Push Up','Parallette Handstand Push Up','Ring Handstand Push Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','trapezius']::text[])>0 THEN ARRAY['triceps','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pared','') IS NOT NULL THEN ARRAY['Pared']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:HSPU';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'HSPU con manos elevadas (deficit).',
  mobile_instructions = ARRAY['Manos sobre placas/paraletas (déficit); cabeza baja más profundo que HSPU estándar antes de empujar a handstand.','Pared o freestanding según programación; core firme; cabeza neutra.','Error típico: arqueo lumbar excesivo o rango incompleto en el déficit.','Solo si el HSPU normal es sólido. Empieza con poco déficit.','Progresión: pike deficit → wall deficit → full.','Si duele el cuello/hombro, elimina el déficit.']::text[],
  mobile_equipment = NULLIF('Pared, Paralelas bajas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:HSPU deficit';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['HSPU','HSPU libre','Kipping Handstand Push Up','Parallette Handstand Push Up','Ring Handstand Push Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps']::text[])>0 THEN ARRAY['triceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pared, Paralelas bajas','') IS NOT NULL THEN ARRAY['Pared, Paralelas bajas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:HSPU deficit';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'HSPU sin apoyo de pared (freestanding).',
  mobile_instructions = ARRAY['Handstand push-up sin muro: equilibra, baja cabeza al suelo (o mat) y empuja a bloqueo.','Requiere equilibrio y fuerza; practica contra pared primero.','Error típico: perder el balance en el fondo. Usa deficit bajo o paralletes con pared como puente.','Core hueco; mirá entre las manos.','Si no, HSPU a pared. No sacrifiques el cuello.','Estándar: bloqueo completo de brazos en vertical.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:HSPU libre';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['HSPU','HSPU deficit','Kipping Handstand Push Up','Parallette Handstand Push Up','Ring Handstand Push Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps']::text[])>0 THEN ARRAY['triceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:HSPU libre';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Flexión en pica: progresión a HSPU.',
  mobile_instructions = ARRAY['En pica (cadera alta, manos en suelo): baja la cabeza hacia el suelo entre las manos y empuja arriba.','Hombros y tríceps cargan; mirada entre manos; core firme.','Error típico: convertir en flexión horizontal (cadera baja). Mantén la pica.','Progresión a HSPU. Eleva pies a cajón para más verticalidad.','Si es difícil, reduce ROM o haz contra pared inclinada.','Estándar: cabeza cerca del suelo + brazos extendidos arriba.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Pike push-up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps']::text[])>0 THEN ARRAY['triceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Pike push-up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Mantener pino (pared o libre).',
  mobile_instructions = ARRAY['Vertical contra pared o libre: muñecas bajo hombros, cuerpo en línea, glúteos y abdomen activos.','Empuja el suelo (o el aire) con los hombros; mirada entre manos o ligera al suelo.','Respira; no encojas orejas. Mantén el tiempo.','Error típico: arco lumbar grande o hombros cerrados.','Progresión: espalda a pared → cara a pared → libre. Si no, pike hold.','Baja a pies con control.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Handstand hold';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Handstand hold';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Caminar en pino.',
  mobile_instructions = ARRAY['Desde handstand, desplaza el peso de una mano a otra; pasos cortos de manos; cadera sobre hombros.','Mirada entre manos; core firme; no arches en exceso.','Error típico: pasos largos que te tiran o hombros detrás de las muñecas.','Practica shoulder taps y holds antes. Usa línea en el suelo.','Si caes, salta a pies de forma segura. Empieza con distancia corta.','Estándar: metros o toque de línea sin caer.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Handstand walk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','trapezius']::text[])>0 THEN ARRAY['abs','trapezius']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Handstand walk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Wall walk: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Plancha con pies cerca de la pared.','Camina manos hacia la pared subiendo los pies.','Pino pecho a la pared; baja con control.','Desde plancha con pies a la pared, camina con las manos hacia la pared.','Llega a pecho cerca de la pared / pino según el estándar.','Desciende caminando con las manos hasta la plancha.','Abdomen y glúteos activos; no dejes caer la cadera.','Error típico: manos muy abiertas o arco excesivo.']::text[],
  mobile_equipment = NULLIF('Pared',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Wall walk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','triceps']::text[])>0 THEN ARRAY['abs','triceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pared','') IS NOT NULL THEN ARRAY['Pared']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Wall walk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Press a pino desde soporte o suelo.',
  mobile_instructions = ARRAY['Desde soporte en suelo o parada de pica, press el cuerpo a handstand (straddle o pike) con control.','Hombros sobre muñecas al final; core firme.','Error típico: impulso de salto disfrazado. Usa fuerza de hombro.','Progresión: wall walks → pike press → freestanding.','Si no, HSPU a pared + holds.','Baja con control a la posición inicial.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Press to handstand';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps']::text[])>0 THEN ARRAY['triceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Press to handstand';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Fondo en anillas con ayuda de impulso controlado de cadera. Es una variante avanzada que exige estabilidad de hombro, recepción segura y dominio previo de fondos estrictos.',
  mobile_instructions = ARRAY['Antes de comenzar, comprueba que las anillas estén estables y domina el soporte con codos extendidos y hombros activos.','Baja a una profundidad que puedas controlar manteniendo las anillas próximas al cuerpo, sin colapsar el hombro hacia delante.','Coordina un impulso pequeño y controlado de cadera con la extensión de brazos para regresar arriba sin balanceo desordenado.','Estabiliza el bloqueo superior antes de la siguiente repetición; evita que las anillas se separen y que los hombros rueden hacia delante.','Error típico: intentar compensar una falta de fuerza con un kip grande; reduce amplitud o vuelve a fondos estrictos asistidos.','Progresión: soporte en anillas, fondos estrictos, control de balanceo y por último kipping. Interrumpe el ejercicio ante molestias de hombro.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('upper arms',''),
  mobile_muscle_group = NULLIF('Tríceps','')
WHERE catalog_key = 'catalog:Fondos en anillas kipping';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Fondos en anillas']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','chest']::text[])>0 THEN ARRAY['triceps','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Fondos en anillas kipping';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Fondos en anillas: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Soporte en anillas: brazos bloqueados, anillas junto a cadera.','Baja hasta hombros por debajo de los codos.','Empuja de nuevo a soporte bloqueado.','Soporte: brazos bloqueados, anillas junto a caderas, hombros abajo.','Baja hasta hombros por debajo de los codos (o el estándar), anillas estables.','Empuja a soporte bloqueado sin abrir las anillas.','Cuerpo hueco; sin balanceo de piernas.','Error típico: anillas abiertas o rango corto.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('upper arms',''),
  mobile_muscle_group = NULLIF('Tríceps','')
WHERE catalog_key = 'catalog:Fondos en anillas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Fondos en anillas kipping','Fondos en paralelas','Hand Release Push Up','Push Up','Ring Push Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','chest']::text[])>0 THEN ARRAY['triceps','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Fondos en anillas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Fondos en paralelas: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Sujeta las paralelas con brazos extendidos, hombros estables y pies suspendidos.','Flexiona los codos y baja el torso entre las barras sin apoyar los pies.','Soporte en paralelas, brazos extendidos, hombros bajos.','Baja a ~90° de codo (o hombros a altura de codos).','Empuja a bloqueo completo.','Piernas quietas; descenso controlado.','Error típico: encoger trapecios o rebotar abajo.','Añade lastre solo con bloqueo sólido.']::text[],
  mobile_equipment = NULLIF('Paralelas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('upper arms',''),
  mobile_muscle_group = NULLIF('Tríceps','')
WHERE catalog_key = 'catalog:Fondos en paralelas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Fondos en anillas','Hand Release Push Up','Push Up','Ring Push Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','chest']::text[])>0 THEN ARRAY['triceps','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Paralelas','') IS NOT NULL THEN ARRAY['Paralelas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Fondos en paralelas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Soporte bloqueado en anillas.',
  mobile_instructions = ARRAY['Anillas a soporte: brazos extendidos, cuerpo hueco o neutro, anillas pegadas al cuerpo (no abiertas).','Hombros abajo y adelante ligeramente (apoyo gimnástico); mantén el tiempo.','Error típico: anillas abiertas o hombros encogidos. Aprieta como si aplastaras las anillas hacia adentro.','Base de dips y muscle-up. Progresión: holds más largos → L-sit → dips.','Si tiemblas mucho, baja un poco el tiempo y suma series.','Sal bajando pies al suelo con control.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Soporte en anillas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','triceps']::text[])>0 THEN ARRAY['deltoids','triceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Soporte en anillas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cuelga en false grip (anillas).',
  mobile_instructions = ARRAY['En anillas: muñeca flexionada sobre el anillo (false grip) antes de colgar; cuelga manteniendo ese agarre.','Hombros activos; torso hollow ligero; no dejes que la muñeca se escape al agarre normal.','Mantén tiempo objetivo; baja a soporte o suelta con control.','Error típico: false grip flojo que se pierde al fatigar. Usa tiza y anillas bajas para aprender.','Base del muscle-up en anillas. Progresión: hang → false grip pull → transición.','Si duelen las muñecas, acorta holds y moviliza.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('forearms',''),
  mobile_muscle_group = NULLIF('Antebrazos','')
WHERE catalog_key = 'catalog:False grip hang';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearm']::text[])>0 THEN ARRAY['forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:False grip hang';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Skin the cat en anillas.',
  mobile_instructions = ARRAY['Desde cuelgue en anillas/barra, pasa los pies entre los brazos a German hang y vuelve (o al contrario).','Movimiento lento y controlado; hombros activos; no te sueltes en el fondo.','Error típico: impulso descontrolado. Usa anillas bajas y asistencia de suelo al aprender.','Progresión a back lever. Para si hay dolor de hombro (no es lo mismo que estiramiento).','Respira; series de pocas reps de calidad.','Sal siempre a cuelgue o suelo con control.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Skin the cat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','upper-back']::text[])>0 THEN ARRAY['deltoids','upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Skin the cat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'German hang: estiramiento/control en anillas.',
  mobile_instructions = ARRAY['Desde skin the cat o asistencia: cuelga en dislocación de hombro controlada, pecho abierto, pies hacia atrás/abajo.','Rango pasivo de hombro; intensidad baja; sal subiendo a tuck o con asistencia.','Error típico: soltarse de golpe o forzar dolor articular. Solo molestia de estiramiento leve.','Holds cortos (10–20 s). Calienta hombros antes.','Progresión a back lever. Si duele (pinzamiento), para.','Nunca rebotes en el fondo.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:German hang';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest']::text[])>0 THEN ARRAY['chest']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:German hang';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Front lever agrupado.',
  mobile_instructions = ARRAY['Cuelga; tira a posición horizontal con espalda al suelo, rodillas al pecho (tuck), cuerpo paralelo al suelo.','Hombros retraídos; brazos extendidos; mantén sin pikear cadera.','Error típico: cadera caída o flexión de brazos. Baja el tiempo y suma series.','Progresión: tuck → advanced tuck → one-leg → full.','Si no, scapular pulls + tuck hangs.','Sal del hold bajando con control a cuelgue.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Front lever tuck';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','abs']::text[])>0 THEN ARRAY['upper-back','abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Front lever tuck';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Back lever agrupado.',
  mobile_instructions = ARRAY['En anillas o barra: desde cuelgue, lleva rodillas al pecho y rota a espaldas al suelo, cadera a la altura de los hombros.','Brazos extendidos o casi; hombros retraídos; cuerpo en tuck compacto.','Mantén el tiempo objetivo sin abrir las caderas antes de tiempo.','Sal del hold con control (skin the cat asistido si hace falta).','Error típico: hombros abiertos o lumbar en exceso. Prioriza escápulas activas.','Progresión: tuck → advanced tuck → straddle → full. Si no, German hang corto.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Back lever tuck';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','upper-back']::text[])>0 THEN ARRAY['deltoids','upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Back lever tuck';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Planche tuck sobre suelo/paralelas.',
  mobile_instructions = ARRAY['En suelo o paralelas: inclina hombros adelante, rodillas al pecho, pies despegados; cuerpo en tuck planche.','Brazos extendidos; empuja el suelo; mantén.','Error típico: flexionar codos o no desplazar hombros adelante.','Progresión: lean planche → tuck → advanced tuck.','Muy exigente de hombro: calienta y usa volumen bajo.','Si no, planche lean holds.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Planche tuck';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps']::text[])>0 THEN ARRAY['triceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Planche tuck';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'L-sit: piernas horizontales en soporte.',
  mobile_instructions = ARRAY['En paralelas, suelo o anillas: soporte con brazos extendidos; eleva piernas rectas a 90° con el torso.','Hombros abajo (depresionados); pecho abierto; no encojas.','Mantén; respira. Si no llegan rectas, one-leg o tuck L-sit.','Error típico: hombros encogidos o piernas flexionadas sin control.','Progresión: support hold → tuck → one leg → full L.','Sal bajando piernas con control, no te desplomes.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:L-sit';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','deltoids']::text[])>0 THEN ARRAY['triceps','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:L-sit';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'V-sit: piernas más altas que L-sit.',
  mobile_instructions = ARRAY['Sentado o en soporte: piernas y torso forman V; equilibrio sobre isquiones o manos.','Piernas extendidas si puedes; abdomen activo; pecho alto.','Mantén el tiempo; respira. Si no, tuck V-sit.','Error típico: redondear lumbar. Prioriza pelvis controlada.','Progresión a L-sit. Alternativa: boat pose en suelo.','Sal bajando piernas con control.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:V-sit';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:V-sit';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Hollow body hold isométrico.',
  mobile_instructions = ARRAY['Tumbado: lumbar pegada al suelo, hombros y piernas elevadas en hollow (forma de plátano invertido).','Brazos arriba o a los lados; aprieta abdomen; respira corto.','Si la lumbar se despega, flexiona rodillas (tuck hollow).','Error típico: solo elevar piernas con arco lumbar. Prioriza lumbar pegada.','Base del kip y la gimnasia. Progresión: tuck → advanced → full → rock.','Mantén tiempo en series; calidad > duración con lumbar floja.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Hollow hold';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hollow hold';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Balanceo en hollow manteniendo forma.',
  mobile_instructions = ARRAY['Desde hollow hold, balancea de hombros a glúteos manteniendo la forma hollow rígida.','No abras ni pierdas el contacto lumbar ‘imaginario’; el cuerpo se mueve como bloque.','Error típico: flexionar/extender cadera a cada rock (se vuelve crunch).','Empieza con rocks pequeños. Si se rompe, vuelve a hollow hold.','Exhala en el ritmo del rock.','Transferencia directa al kip.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Hollow rock';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hollow rock';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Arch/superman hold boca abajo.',
  mobile_instructions = ARRAY['Boca abajo o colgado: abre el pecho, eleva hombros y piernas en arco controlado (posición de arch).','Glúteos y lumbar activos; mirada neutra; no hiperextiendas el cuello.','Mantén la línea del arco sin balanceo; respira corto y continuo.','Si estás en el suelo, solo pecho y muslos despegan; si cuelgas, el pecho va adelante y las piernas atrás.','Error típico: solo elevar piernas o solo pecho. El arch es cuerpo completo.','Úsalo como posición base del kip. Progresión: holds cortos → arch-to-hollow dinámico.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Arch hold';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['lower-back','gluteal']::text[])>0 THEN ARRAY['lower-back','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Arch hold';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Candlestick / shoulder stand controlado.',
  mobile_instructions = ARRAY['Desde suelo o de pie: rueda a la espalda hasta quedar sobre hombros/nuca con piernas arriba (como vela), luego vuelve a pie o a la posición pedida.','Manos pueden apoyar en el suelo cerca de las orejas para controlar.','Core activo; no golpees la cervical: peso en hombros altos, no en cuello.','Error típico: enrollar sobre el cuello. Usa colchoneta y rango cómodo.','Drill de movilidad y control. Progresión: candlestick + stand-up.','Si mareas, reduce reps y usa asistencia de manos.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Candlestick';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Candlestick';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla a una pierna (pistol).',
  mobile_instructions = ARRAY['De pie a una pierna, la otra extendida al frente y brazos adelante.','Baja con control hasta la mitad; talon pegado y rodilla alineada.','Fondo: muslo sobre la pantorrilla y pierna libre estirada; sube sin apoyar.','A una pierna: baja a squat profundo con la otra pierna extendida al frente; sube sin apoyar.','Talón pegado; rodilla alineada; brazos al frente para equilibrar.','Error típico: colapso de rodilla o talón que se levanta. Usa agarre a soporte.','Progresión: box pistol → assisted → full. Movilidad de tobillo clave.','Si no, shrimp o squat búlgaro.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Pistol squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','abs']::text[])>0 THEN ARRAY['gluteal','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Pistol squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Shrimp squat: sentadilla unilateral con pie trasero sujeto.',
  mobile_instructions = ARRAY['A una pierna: sujeta el pie trasero con la mano; baja hasta que la rodilla trasera acerque el suelo; sube.','Torso controlado; rodilla delantera estable.','Error típico: soltar el pie o inclinarte demasiado adelante.','Progresión: elevar la rodilla trasera sobre un pad → full. Asistencia de TRX.','Alternativa a pistol con más énfasis en cuádriceps.','Si duele la rodilla trasera, usa pad y reduce ROM.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Shrimp squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal']::text[])>0 THEN ARRAY['gluteal']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Shrimp squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla cossack lateral.',
  mobile_instructions = ARRAY['Pies muy anchos; baja hacia un lado flexionando esa rodilla, la otra pierna queda extendida con punta arriba o talón al suelo según movilidad.','Torso lo más alto posible; talón del lado de trabajo pegado.','Empuja para volver al centro y cambia de lado o completa reps por lado.','Error típico: rodilla que se va adentro o talón que se levanta.','Usa apoyo de manos o TRX si hace falta. Profundidad gradual.','Excelente para adductor y movilidad. No fuerces dolor de rodilla.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Cossack squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','adductors']::text[])>0 THEN ARRAY['quadriceps','adductors']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal']::text[])>0 THEN ARRAY['gluteal']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Cossack squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla sin carga.',
  mobile_instructions = ARRAY['De pie, pies al ancho de hombros y brazos al frente para equilibrar.','Baja con control: cadera atrás y rodillas sobre la línea de los pies.','Abajo: cadera bajo la rótula, talones pegados; empuja el suelo para subir.','Pies al ancho de hombros, puntas ligeramente afuera; brazos al frente para equilibrar.','Inhala, bracea y baja hasta que la cresta ilíaca pase bajo la rótula (paralelo o más).','Rodillas siguen la línea de los pies; talones pegados al suelo; pecho alto.','Empuja el suelo y exhala al subir hasta extensión completa de cadera y rodillas.','Error típico: rodillas que colapsan adentro o talones que se levantan. Reduce profundidad si hace falta y mejora movilidad.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Air squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Air squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla con salto.',
  mobile_instructions = ARRAY['Squat profundo: carga abajo con pecho alto y brazos atras.','Salto: extension completa de cadera, rodillas y tobillos en el aire.','Aterriza suave en media sentadilla y enlaza la siguiente.','Squat completo o a paralelo; extiende explosivo y salta; aterriza suave y baja otra vez.','Pecho alto; rodillas alineadas; no dejes que choquen al aterrizar.','Error típico: cortar profundidad o aterrizar con talones duros.','Manos pueden ayudar el balance. Empieza con saltos bajos.','Progresión: air squat rápido → jump squat → loaded if ready.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Jumping squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Jumping squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancada con salto alterno.',
  mobile_instructions = ARRAY['Zancada profunda con la pierna derecha adelante: rodilla trasera cerca del suelo sin apoyar, torso alto.','Salta y cambia las piernas en el aire.','Aterriza suave en la zancada contraria: la pierna izquierda queda adelante.','Desde zancada, salta e intercambia piernas en el aire; aterriza en zancada del otro lado.','Torso alto; aterrizaje suave; rodilla trasera cerca del suelo.','Error típico: aterrizaje rígido o rodilla que se va adentro.','Si el impacto es alto, alternating reverse lunges sin salto.','Usa brazos para equilibrar. Exhala en el salto.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Jumping lunge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','calves']::text[])>0 THEN ARRAY['gluteal','calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Jumping lunge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'GHD sit-up: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Fija los pies en los rodillos e inclina el tronco hacia atrás con control.','Flexiona el tronco y lleva los brazos hacia delante sin soltar el apoyo.','Termina de incorporarte manteniendo la cadera sobre el apoyo de la máquina.','Caderas sobre el pad del GHD; pies fijados en rodillos.','Baja el torso atrás con control hasta el rango pedido.','Sube hasta pasar la horizontal y tocar pies/marca.','Sin rebote al fondo; controla la lumbar.','Error típico: solo psoas con rango inseguro o máquina mal ajustada.']::text[],
  mobile_equipment = NULLIF('GHD',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:GHD sit-up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors','quadriceps']::text[])>0 THEN ARRAY['hip flexors','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('GHD','') IS NOT NULL THEN ARRAY['GHD']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:GHD sit-up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Extensión de espalda en GHD.',
  mobile_instructions = ARRAY['Ajusta GHD: cadera al borde del pad; ancla pies; cruz de brazos o disco al pecho.','Baja el torso con control flexionando cadera; sube hasta línea neutra (no hiperextiendas lumbar).','Aprieta glúteos arriba; tempo controlado.','Error típico: arquear lumbar arriba o usar impulso. Rango = bisagra de cadera.','Empieza sin carga. Si no hay GHD, good mornings ligeros o reverse hyper.','Exhala al subir.']::text[],
  mobile_equipment = NULLIF('GHD',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:GHD back extension';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['lower-back','gluteal']::text[])>0 THEN ARRAY['lower-back','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring']::text[])>0 THEN ARRAY['hamstring']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('GHD','') IS NOT NULL THEN ARRAY['GHD']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:GHD back extension';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sit-up completo (hombros pasan la cadera).',
  mobile_instructions = ARRAY['Tumbado, rodillas flexionadas o anclado; sube el torso hasta sentado; baja con control.','Manos al pecho o ancla ligera; no tires del cuello.','Error típico: impulso de brazos o lumbar que se despega con dolor. Rango cómodo.','Exhala al subir. Progresión: crunch → sit-up → GHD sit-up.','Si la cadera flexora domina, prioriza crunch/hollow.','Estándar: omóplatos tocan abajo y torso vertical o toque de pies arriba según WOD.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Sit-up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sit-up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'V-up: manos y pies se encuentran arriba.',
  mobile_instructions = ARRAY['Tumbado; eleva piernas y torso a la vez hasta tocar pies (o cerca) en V; baja con control.','Lumbar controlada; no tires del cuello.','Error típico: solo subir piernas o solo torso. Ambos extremos se encuentran.','Exhala al subir. Progresión: tuck-up → V-up → weighted.','Si la lumbar molesta, hollow rocks o dead bugs.','Estándar: toque o aproximación clara pies–manos arriba.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:V-up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:V-up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rope climb: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Salta y agarra la cuerda alto.','Enrola piernas (J-hook/wrap) y estira.','Sube a tramos y baja controlado.','Salta y agarra la cuerda alto; eleva rodillas.','Enrola piernas (J-hook/wrap) y estira el cuerpo para subir.','Reagarra más arriba; cuerda cerca del cuerpo.','Baja tramo a tramo; no te sueltes en caída libre.','Error típico: solo brazos sin lock de piernas.']::text[],
  mobile_equipment = NULLIF('Cuerda de trepa',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Rope climb';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','abs']::text[])>0 THEN ARRAY['biceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Cuerda de trepa','') IS NOT NULL THEN ARRAY['Cuerda de trepa']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rope climb';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Subida de cuerda sin piernas.',
  mobile_instructions = ARRAY['Escala la cuerda solo con brazos (sin tijera de piernas); técnica de tracción y reagarre.','Core firme; no te balancees en exceso; baja con control (no te deslices quemando manos).','Error típico: paniqueo y agarre panza. Usa pies en la bajada si el WOD lo permite para seguridad.','Progresión: rope con pies → legless parcial → full. Fuerza de pull-up estricta ayuda.','Tiza en manos. Altura baja al aprender.','Estándar: tocar la marca arriba sin ayuda de piernas.']::text[],
  mobile_equipment = NULLIF('Cuerda de trepa',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Rope climb legless';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','biceps']::text[])>0 THEN ARRAY['upper-back','biceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearm','abs']::text[])>0 THEN ARRAY['forearm','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Cuerda de trepa','') IS NOT NULL THEN ARRAY['Cuerda de trepa']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rope climb legless';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Pegboard: trepa con clavijas.',
  mobile_instructions = ARRAY['Sube el pegboard insertando clavijas al subir; core y tracción de brazos; pies pueden ayudar según reglas.','Mantén cadera cerca del tablero; no te alejes en exceso.','Baja con control insertando clavijas o según estándar del event.','Error típico: pies que resbalan o paniqueo arriba. Practica altura baja.','Fuerza de agarre y pull críticas. Usa tiza.','Si no hay pegboard, rope climb o towel pull-ups como estímulo.']::text[],
  mobile_equipment = NULLIF('Pegboard',''),
  mobile_sport_tag = NULLIF('Gimnasia',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Pegboard';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','deltoids']::text[])>0 THEN ARRAY['upper-back','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pegboard','') IS NOT NULL THEN ARRAY['Pegboard']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Pegboard';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Subida unilateral a un cajón con kettlebell sostenida delante del pecho en posición goblet. Entrena piernas, glúteos y estabilidad del tronco, sin impulsarse con la pierna que queda en el suelo.',
  mobile_instructions = ARRAY['Elige un cajón estable y de altura adecuada; sujeta la kettlebell en posición goblet frente al pecho, con codos cercanos al tronco.','Coloca un pie entero encima del cajón y mantén el tronco alto mientras generas fuerza principalmente con la pierna adelantada.','Extiende cadera y rodilla hasta quedar erguido sobre el cajón, manteniendo la carga cerca del pecho y las rodillas alineadas.','Desciende de manera controlada, sin dejarte caer ni empujarte con la pierna de atrás para completar la repetición.','Error típico: apoyar solo la punta del pie, impulsarse desde abajo o encorvar la espalda por exceso de peso o altura.','Alterna piernas según la prescripción; empieza sin carga y aumenta primero el control, después la altura o la kettlebell.']::text[],
  mobile_equipment = NULLIF('Cajón, Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Kettlebell Goblet Box Step-Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Cajón, Kettlebell','') IS NOT NULL THEN ARRAY['Cajón, Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Goblet Box Step-Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Carrera continua, por distancia o intervalos, con zancada cómoda, postura erguida y respiración controlada. La intensidad depende del entrenamiento; ajusta ritmo y terreno a tu nivel.',
  mobile_instructions = ARRAY['Comienza con calentamiento de marcha y trote suave; adopta una postura erguida, mirada al frente y brazos relajados cerca del tronco.','Corre con pasos cómodos debajo del centro de masas y evita alargar en exceso la zancada para ganar velocidad artificialmente.','Mantén el ritmo que permita completar la distancia o el intervalo prescrito; ajusta respiración y cadencia según la intensidad.','En cambios de dirección y terreno irregular, reduce la velocidad y controla el apoyo antes de acelerar de nuevo.','Error típico: salir demasiado rápido, endurecer hombros o ignorar la fatiga; usa un ritmo sostenible y progresivo.','Progresión: alterna marcha y carrera si hace falta, incrementa volumen gradualmente e hidrátate según las condiciones ambientales.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('cardio',''),
  mobile_muscle_group = NULLIF('Cardio','')
WHERE catalog_key = 'catalog:Run';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['cardiovascular system']::text[])>0 THEN ARRAY['cardiovascular system']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','calves','gluteal']::text[])>0 THEN ARRAY['quadriceps','calves','gluteal']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Run';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Front squat + press en un solo movimiento continuo.',
  mobile_instructions = ARRAY['Sujeta la barra delante de los hombros y desciende hasta una sentadilla frontal.','Extiende caderas y rodillas al subir, manteniendo la barra sobre los hombros.','Impulsa la misma barra sobre la cabeza hasta extender los brazos por completo.','Barra en rack frontal: codos altos, barra en deltoides, pies al ancho de sentadilla.','Baja a sentadilla frontal completa manteniendo torso alto y talones abajo.','Al subir, extiende cadera y rodillas; enlaza el press overhead sin dejar la barra parada en los hombros.','Bloquea overhead con brazos extendidos y cabeza a través; vuelve a rack para la siguiente rep.','Error típico: press prematuro (antes de extender cadera) o perder el rack en el fondo.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Thruster';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Thruster','Kettlebell Thruster','Single Arm Dumbbell Thruster','Single Arm Kettlebell Thruster']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','triceps','abs']::text[])>0 THEN ARRAY['gluteal','triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Thruster';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Thruster con mancuernas en rack frontal.',
  mobile_instructions = ARRAY['De pie, mancuernas en rack sobre los hombros, pecho alto.','Squat profundo con talones abajo y mancuernas en rack.','Al subir, press a bloqueo con las mancuernas sobre la cabeza.','Mancuernas en rack a hombros; squat profundo; al subir press a bloqueo overhead.','Muñecas neutras o palmas al frente; torso alto.','Error típico: arco lumbar al press o cortar profundidad.','Útil cuando la barra no es opción. Exhala al subir.','Si el press falla, baja peso o haz push press + squat separados.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Thruster';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Kettlebell Thruster','Single Arm Dumbbell Thruster','Single Arm Kettlebell Thruster','Thruster']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps']::text[])>0 THEN ARRAY['triceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Thruster';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Thruster con una o dos kettlebells en rack.',
  mobile_instructions = ARRAY['De pie, kettlebell en rack a la altura del hombro, codo pegado.','Squat profundo con talones abajo y kettlebell en rack.','Al subir, press a bloqueo con la kettlebell sobre la cabeza.','KB en rack (una o dos); squat completo; al subir enlaza press a overhead hasta bloqueo.','Codos y antebrazos organizan el rack; talones abajo en el fondo.','Error típico: press antes de extender cadera. Primero piernas, luego brazos.','Baja a rack y squat de nuevo. Exhala al press.','Progresión: goblet squat + press por separado → thruster.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Kettlebell Thruster';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Thruster','Single Arm Dumbbell Thruster','Single Arm Kettlebell Thruster','Thruster']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Thruster';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Clean a rack + thruster (cargada y envío overhead).',
  mobile_instructions = ARRAY['Rack frontal tras la cargada.','Sentadilla frontal profunda sin soltar el rack.','Thruster a overhead en un solo tiempo.','Cargada hasta rack frontal estable (codos altos).','Sin demorar, sentadilla frontal y thruster a overhead en un solo enlace.','Bloquea arriba con brazos extendidos; baja a rack o suelo según el WOD.','Mantén la barra cerca en el tirón; no te separes en el thruster.','Error típico: pausas largas entre clean y thruster, o sentadilla corta.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Cluster';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','triceps']::text[])>0 THEN ARRAY['gluteal','triceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Cluster';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada de mancuerna hasta el hombro seguida de envío overhead con impulso de piernas. Controla el recorrido de la carga, cambia de lado según la prescripción y estabiliza el bloqueo antes de repetir.',
  mobile_instructions = ARRAY['Coloca la mancuerna junto al pie, prepara una bisagra de cadera estable y mantén la espalda neutra antes de agarrar la carga.','Extiende piernas y cadera para elevar la mancuerna cerca del cuerpo hasta el hombro, recibiéndola con rodillas suaves.','Desde la posición de rack, realiza una pequeña flexión vertical de piernas y empuja el suelo para impulsar la mancuerna overhead.','Bloquea el brazo sobre el hombro con abdomen activo y pies estabilizados; controla la carga antes de bajarla a la siguiente repetición.','Error típico: tirar solo de brazo, arquear la zona lumbar o perder el control al recibir. Baja el peso si se altera el recorrido.','Progresión: practica primero clean y push press por separado; exhala al estabilizar el bloqueo y alterna brazos según el WOD.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Dumbbell Clean and Jerk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Clean and Jerk','Kettlebell Clean and Jerk','Log Clean And Jerk']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','quadriceps']::text[])>0 THEN ARRAY['deltoids','quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','triceps']::text[])>0 THEN ARRAY['gluteal','triceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Clean and Jerk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cualquier forma legal de llevar la carga del suelo a overhead.',
  mobile_instructions = ARRAY['Cualquier forma legal: snatch, o clean + jerk/press, para llevar la carga del suelo a bloqueo overhead.','Elige la variante que puedas hacer con control a la carga del WOD.','Bloquea arriba con brazos extendidos y torso estable antes de bajar.','Error típico: press-out flojo o redondear al despegar del suelo.','Si la snatch no sale, clean + push jerk suele ser más fiable bajo fatiga.','Estándar: placas/peso del suelo → overhead lockout claro.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Ground to overhead';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','abs']::text[])>0 THEN ARRAY['trapezius','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Ground to overhead';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Disco del suelo a overhead.',
  mobile_instructions = ARRAY['Disco en el suelo; agárralo por los bordes; llévalo a hombros o snatch a overhead; bloquea.','Mantén la espalda tensa al despegar; no redondees por el diámetro del disco.','Baja con control. Exhala al lockout.','Error típico: press con lumbar arqueada o agarre inseguro.','Usa disco con borde agarreable. Alternativa: DB ground to overhead.','Estándar: disco del suelo a brazos extendidos arriba.']::text[],
  mobile_equipment = NULLIF('Disco',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Plate ground to overhead';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','quadriceps']::text[])>0 THEN ARRAY['abs','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Disco','') IS NOT NULL THEN ARRAY['Disco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Plate ground to overhead';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Burpee: pecho al suelo, salto y palmada.',
  mobile_instructions = ARRAY['Pecho y muslos al suelo: manos a los lados, cuerpo plano.','Salta los pies hacia las manos y quédate en cuclillas con el pecho alto.','Extiende cadera y salta con palmada arriba.','Manos al suelo y cuerpo a plancha; pecho y muslos tocan el suelo.','Salta los pies hacia las manos hasta una cuclilla con pecho alto.','Extiende cadera y salta con palmada (o el estándar pedido) por encima de la cabeza.','Aterriza suave y encadena sin colapsar la lumbar en la plancha.','Error típico: no tocar pecho/muslos, o saltar sin extensión de cadera.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Pecho','')
WHERE catalog_key = 'catalog:Burpee';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest','quadriceps']::text[])>0 THEN ARRAY['chest','quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Burpee';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Burpee completo seguido de un salto vertical para tocar la diana elevada. El atleta debe cumplir el contacto con el objetivo y aterrizar con control; la altura y la mano exigidas dependen del estándar del WOD.',
  mobile_instructions = ARRAY['Comprueba la altura y el contacto exigido para la diana según el estándar del WOD; deja espacio suficiente para saltar sin chocar con otros atletas.','Desde una posición de pie, coloca las manos al suelo y lleva el pecho y los muslos a tocarlo manteniendo el abdomen firme durante el descenso.','Recoge los pies hacia las manos, levanta el pecho y estabiliza ambos apoyos antes de comenzar el salto vertical.','Extiende las caderas, rodillas y tobillos de forma coordinada y busca el objetivo con la mano o manos indicadas sin arquear excesivamente la zona lumbar.','Toca la diana y aterriza amortiguando con ambos pies, rodillas alineadas y torso estable. Exhala al saltar y recupera la respiración antes de la siguiente repetición.','Error típico: saltar sin tocar la marca, apoyar solo las manos en el suelo o perder la alineación de las rodillas durante la caída; no cuentes esa repetición.','Progresión: domina primero el burpee, después realiza saltos verticales controlados y aumenta la altura de la diana gradualmente sin sacrificar el rango.']::text[],
  mobile_equipment = NULLIF('Diana elevada',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Pecho','')
WHERE catalog_key = 'catalog:Burpee to target';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest','quadriceps']::text[])>0 THEN ARRAY['chest','quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Diana elevada','') IS NOT NULL THEN ARRAY['Diana elevada']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Burpee to target';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Burpee seguido de salto al cajón y paso al otro lado. Exige controlar la recepción y la bajada, mantener la trayectoria libre de obstáculos y adaptar la altura al dominio de cada atleta.',
  mobile_instructions = ARRAY['Comprueba que el cajón no se mueva y deja espacio libre a ambos lados; adapta la altura a tu capacidad de salto y recepción.','Realiza el burpee bajando al suelo con control y vuelve a ponerte de pie con los pies suficientemente cerca del cajón.','Salta con ambos pies al cajón y aterriza con rodillas flexionadas y apoyo estable; confirma el equilibrio antes de cruzar.','Pasa al lado opuesto del cajón siguiendo el estándar del WOD; baja con un paso seguro si está permitido, evitando saltos descontrolados.','Error típico: acercarse demasiado al borde, aterrizar rígido o girar en el aire sin control; prioriza un salto y descenso seguros.','Progresión: separa burpee y subida al cajón, domina primero el step-over y aumenta la velocidad solo cuando la técnica sea consistente.']::text[],
  mobile_equipment = NULLIF('Cajón',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Burpee box jump over';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','chest']::text[])>0 THEN ARRAY['quadriceps','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','abs']::text[])>0 THEN ARRAY['gluteal','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Cajón','') IS NOT NULL THEN ARRAY['Cajón']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Burpee box jump over';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Burpee completo terminado en salto al cajón.',
  mobile_instructions = ARRAY['Fondo del burpee: pecho y muslos al suelo frente al cajon.','Salta y aterriza sobre el cajon en media sentadilla.','Bipedestacion completa arriba: cadera y rodillas extendidas.','Burpee completo (pecho al suelo) frente al cajón; luego salto o step-up al cajón y extensión de cadera arriba.','Baja del cajón con control (step-down si hace falta) y repite.','Error típico: no extender cadera sobre el cajón o saltar sin terminar el burpee.','Elige altura que permita aterrizaje seguro. Inhala en el suelo, exhala al subir al box.','Si el salto falla, step-up mantiene el estímulo con menos impacto.']::text[],
  mobile_equipment = NULLIF('Cajón',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Burpee Box Jump';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest','abs']::text[])>0 THEN ARRAY['chest','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Cajón','') IS NOT NULL THEN ARRAY['Cajón']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Burpee Box Jump';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Burpee de cara a la barra, a menudo saltando sobre ella.',
  mobile_instructions = ARRAY['De pie mirando la barra en el suelo; pecho y muslos tocan el suelo; salto o paso atrás/adelante.','Al subir, salta y abre pies/cadera; las manos pueden tocar o no según WOD; pasa sobre la barra sin tocarla.','Aterriza al otro lado y gira o sigue según el estándar del workout.','Error típico: no tocar pecho al suelo o rozar la barra.','Si el salto es pesado, step-over permitido solo si el WOD lo autoriza.','Ritmo: burpees sostenibles; no sacrifiques el contacto con el suelo.']::text[],
  mobile_equipment = NULLIF('Barra (obstáculo)',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Pecho','')
WHERE catalog_key = 'catalog:Bar facing burpee';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest','quadriceps']::text[])>0 THEN ARRAY['chest','quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra (obstáculo)','') IS NOT NULL THEN ARRAY['Barra (obstáculo)']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Bar facing burpee';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Burpee pull-up: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Pecho al suelo bajo la barra.','Agarra la barra y cuelga con brazos extendidos.','Dominada: barbilla por encima de la barra.','Burpee bajo la barra: pecho al suelo y vuelta a pie.','Salta a la barra y cuelga con brazos extendidos si se exige.','Dominada con barbilla sobre la barra.','Baja y encadena el siguiente burpee.','Error típico: hang incompleto o barbilla corta.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Burpee pull-up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','chest']::text[])>0 THEN ARRAY['upper-back','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','quadriceps']::text[])>0 THEN ARRAY['abs','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Burpee pull-up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Salto al cajón: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Pies firmes frente al cajón, carga de piernas.','Salta: rodillas arriba, sobre el cajón en el aire.','De pie sobre el cajón, cadera extendida.','Pies al ancho de cadera; flexiona cargando brazos atrás.','Salta al cajón; aterriza con ambos pies completos y cadera extendida arriba.','Baja paso a paso o salta abajo según el WOD; absorbe suave.','Altura que permita aterrizaje silencioso y estable.','Error típico: media planta en el cajón o rodillas que colapsan.']::text[],
  mobile_equipment = NULLIF('Cajón',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Box Jump';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Cajón','') IS NOT NULL THEN ARRAY['Cajón']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Box Jump';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Subida al cajón con una mancuerna en cada mano. Trabaja la estabilidad y la extensión de la pierna de apoyo sin impulsarte con el pie que queda en el suelo.',
  mobile_instructions = ARRAY['Coloca un cajón de altura que te permita apoyar toda la planta del pie sin perder la posición neutra de espalda y pelvis.','Sujeta una mancuerna en cada mano, brazos a los lados; mantén hombros estables y el abdomen activo antes de subir.','Apoya el pie completo encima del cajón e impulsa el cuerpo principalmente con esa pierna; evita saltar con el pie de abajo.','Extiende la cadera y la rodilla arriba hasta quedar erguido, sin inclinarte hacia delante ni abrir la rodilla hacia dentro.','Baja con control apoyando el pie que desciende y alterna la pierna de inicio cuando la prescripción lo indique.','Error típico: ganar altura empujando con la pierna del suelo. Si no controlas el movimiento, reduce carga o altura y trabaja la progresión sin mancuernas.']::text[],
  mobile_equipment = NULLIF('Cajón, Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Double Dumbbell Step Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Barbell Step Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Cajón, Mancuernas','') IS NOT NULL THEN ARRAY['Cajón, Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Double Dumbbell Step Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Subida al cajón paso a paso.',
  mobile_instructions = ARRAY['Pie completo sobre el cajón; empuja con la pierna de arriba (no impulsos excesivos del suelo).','Extiende cadera arriba; baja con control y alterna.','Error típico: empujar casi solo con la pierna de abajo. Carga la pierna del box.','Altura que permita control. Mancuernas opcionales a los lados.','Progresión a box jump. Si duele la rodilla, baja altura.','Estándar: bipedestación completa sobre el cajón cada rep.']::text[],
  mobile_equipment = NULLIF('Cajón',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Box Step-Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Box Step Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring']::text[])>0 THEN ARRAY['hamstring']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Cajón','') IS NOT NULL THEN ARRAY['Cajón']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Box Step-Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Box jump over: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Flexiona frente al cajón, brazos atrás.','Salta pasando POR ENCIMA del cajón.','Aterriza al otro lado en el suelo, suave.','Salta pasando al otro lado del cajón (encima y abajo, o por encima), según el estándar.','Aterriza suave al otro lado; date la vuelta y repite.','No rasques el cajón con las espinillas: elige altura realista.','Bajo fatiga prioriza aterrizajes seguros.','Error típico: contar un salto que no supera claramente el cajón.']::text[],
  mobile_equipment = NULLIF('Cajón',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Box jump over';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','calves']::text[])>0 THEN ARRAY['gluteal','calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Cajón','') IS NOT NULL THEN ARRAY['Cajón']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Box jump over';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Salto horizontal a máxima distancia.',
  mobile_instructions = ARRAY['Carga: bisagra atras, brazos atras, listo para saltar.','Vuelo: extension completa, brazos adelante.','Aterrizaje suave con rodillas flexionadas y pecho alto.','Pies al ancho de cadera; bisagra ligera, brazos atrás; salta lo más lejos posible aterrizando suave.','Extiende cadera/rodillas/tobillos; brazos adelante en el vuelo.','Aterriza con rodillas blandas, pecho alto; párate estable antes de la siguiente.','Error típico: aterrizaje rígido o caer sentado. Prioriza recepción atlética.','Mide distancia o marca. No es un burpee: no hace falta pecho al suelo.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Broad jump';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','quadriceps']::text[])>0 THEN ARRAY['gluteal','quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Broad jump';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancadas caminando en línea.',
  mobile_instructions = ARRAY['Zancadas caminando: paso adelante, baja rodilla trasera, empuja y da el siguiente paso.','Torso alto; mancuernas opcionales; rodilla alineada con el pie.','Error típico: pasos demasiado cortos o rodilla que sobrepasa en exceso con talón levantado.','Distancia o pasos objetivo. Exhala al subir de cada zancada.','Si el equilibrio falla, reverse lunges estáticos.','Estándar: cada paso es una zancada completa controlada.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Walking lunge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Walking Lunge']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring']::text[])>0 THEN ARRAY['hamstring']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Walking lunge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Desplazamiento a cuatro puntos con rodillas elevadas.',
  mobile_instructions = ARRAY['A cuatro patas: rodillas elevadas unos cm, manos bajo hombros, core firme.','Avanza mano y pie opuestos; cadera baja y estable, sin balanceo lateral exagerado.','Pasos cortos; respira; mira al suelo unos cm delante.','Error típico: cadera muy alta (se vuelve pike) o arrastrar los pies.','Distancia o tiempo objetivo. Progresión: más lento con control → más rápido manteniendo forma.','Si no puedes, gateo con rodillas apoyadas y luego eleva.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Bear crawl';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','deltoids']::text[])>0 THEN ARRAY['abs','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','chest']::text[])>0 THEN ARRAY['quadriceps','chest']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Bear crawl';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Swing ruso: bisagra hasta altura de pecho/ojos.',
  mobile_instructions = ARRAY['Bisagra: KB atrás entre las piernas, cadera cargada y espalda neutra.','Snap de cadera: extiende con fuerza; la KB sube a la altura de la cadera.','Arriba: KB a pecho/hombros con el cuerpo en plancha vertical, glúteos apretados.','Bisagra: KB entre piernas; extiende cadera con fuerza hasta que la KB llegue a altura de pecho/hombros (ruso).','Brazos relajados; aprieta glúteos arriba; no hiperestes lumbar.','Inhala en la bisagra, exhala al snap de cadera.','Error típico: squat-swing o levantar con hombros. Piensa ‘empuja el suelo y cierra cadera’.','Progresión: deadlift KB → swing ruso → americano.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Kettlebell Swing';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Single Arm Kettlebell Swing']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','hamstring']::text[])>0 THEN ARRAY['gluteal','hamstring']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','deltoids']::text[])>0 THEN ARRAY['abs','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Swing';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Swing hasta overhead completo.',
  mobile_instructions = ARRAY['KB swing hasta overhead (brazos alineados con la cabeza); bisagra de cadera, no squat.','Arriba: KB sobre la cabeza con hombros activos; abajo: KB pasa entre piernas con espalda neutra.','Error típico: press de hombros o lumbar arqueada arriba. La cadera lanza; los brazos dirigen.','Más exigente que el ruso (a pecho). Empieza con ruso si eres nuevo.','Estándar americano: KB claramente overhead cada rep.','Exhala al subir.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:American Kettlebell Swing';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal']::text[])>0 THEN ARRAY['gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:American Kettlebell Swing';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Snatch kettlebell: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['KB entre los pies, bisagra de cadera.','Extiende y guía la KB cerca del cuerpo.','Bloquea overhead a brazo extendido.','KB entre los pies; bisagra y hike pass atrás.','Extiende cadera y guía la KB cerca del cuerpo hasta overhead.','Bloquea el brazo con hombro activo; KB sobre el antebrazo.','Baja a hang o swing; cambia de mano si se pide.','Error típico: press lento desde el hombro o arco lumbar al bloquear.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Kettlebell Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Alternating Dumbbell Snatch','Dumbbell Snatch','Snatch']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','deltoids']::text[])>0 THEN ARRAY['gluteal','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Kettlebell a rack frontal.',
  mobile_instructions = ARRAY['Bisagra: kettlebell en el suelo entre los pies, espalda plana.','Extension de cadera y tiron pegado al cuerpo.','Rack estable: codo pegado, campana apoyada suave en el antebrazo.','KB entre pies o ligeramente delante; bisagra, agarra el mango, extiende cadera y guía la KB a rack (codo pegado, mango en pecho).','No golpees el antebrazo: ‘enrosca’ la mano alrededor del mango en la recepción.','Párate estable en rack; baja a swing o suelo con control.','Error típico: curlar con el brazo o chocar el antebrazo. Cadera genera el impulso.','Empieza con KB ligera. Alterna lados o haz doble KB si está programado.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Kettlebell Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Clean','Dumbbell Clean','Sandbag clean']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal']::text[])>0 THEN ARRAY['gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','deltoids']::text[])>0 THEN ARRAY['trapezius','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Turkish get-up: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Túmbate y mantén una kettlebell sobre el hombro con el brazo totalmente extendido.','Apoya la mano libre, eleva la cadera y mantén la kettlebell vertical.','Termina de pie con el mismo brazo bloqueado y la kettlebell sobre la cabeza.','Tumbado; carga en un brazo bloqueado vertical; mirada a la carga.','Secuencia: codo → mano → cadera alta → rodilla → pie → de pie, brazo siempre extendido.','Cada transición lenta y estable; empuja la carga al techo.','Invierte los pasos para tumbarte; cambia de lado.','Error típico: apresurar y perder la verticalidad.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Turkish get-up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','deltoids']::text[])>0 THEN ARRAY['abs','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','quadriceps']::text[])>0 THEN ARRAY['gluteal','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Turkish get-up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla con KB/DB pegada al pecho.',
  mobile_instructions = ARRAY['De pie, KB vertical junto al pecho con codos abajo y adentro.','Baja con control: pecho alto, rodillas sobre la línea de los pies, talones abajo.','Abajo: mantén los talones apoyados y los codos entre las rodillas; empuja el suelo para subir.','Sujeta una KB o mancuerna vertical junto al pecho (codos abajo/adentro); pies al ancho de squat.','Baja a profundidad cómoda con pecho alto y codos entre rodillas; talones abajo.','Empuja el suelo y sube a extensión completa; la carga actúa como contrapeso.','Error típico: dejar caer el peso adelante o redondear lumbar.','Ideal para aprender squat. Inhala al bajar, exhala al subir.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Goblet squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY['Box Squat','Dumbbell Front Squat','Sandbag Squat','Sentadilla','Sentadilla frontal','Zercher Squat']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','abs']::text[])>0 THEN ARRAY['gluteal','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Goblet squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Devil press: ejecuta el movimiento con rango completo, core firme y control.',
  mobile_instructions = ARRAY['Pecho al suelo entre las mancuernas.','Salta a cuclillas agarrando las mancuernas.','Snatch ambas overhead en un movimiento.','Pecho al suelo entre las mancuernas (burpee).','Salta a cuclillas agarrando las mancuernas; espalda plana.','Snatch ambas a overhead en un movimiento con bloqueo.','Baja y encadena; abdomen firme en el snatch.','Error típico: no tocar pecho, o clean+press lento cuando se pide snatch.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Devil press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','gluteal']::text[])>0 THEN ARRAY['deltoids','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest','abs']::text[])>0 THEN ARRAY['chest','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Devil press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Remo + flexión + clean y press con mancuernas.',
  mobile_instructions = ARRAY['Plancha alta con manos en las mancuernas y cuerpo en linea.','Flexion completa hasta el pecho cerca del suelo.','Remo a un lado con la cadera cuadrada; repite al otro lado.','Salta los pies adelante y clean: mancuernas a los hombros.','Thruster: baja en squat con las mancuernas en los hombros.','Al subir, press a bloqueo overhead.','Mancuernas al ancho de hombros; plancha con agarre en los mangos, cuerpo en línea.','Flexión de pecho (push-up) completa; luego remo a cada lado con cadera cuadrada (sin rotar).']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Pecho','')
WHERE catalog_key = 'catalog:Man maker';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest','deltoids']::text[])>0 THEN ARRAY['chest','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','abs']::text[])>0 THEN ARRAY['upper-back','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Man maker';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Arrancada con mancuerna a overhead en un tiempo.',
  mobile_instructions = ARRAY['Bisagra: mancuerna en el suelo entre los pies, espalda plana.','Extension de cadera y tiron: la mancuerna sube pegada al cuerpo.','Recibe a bloqueo overhead, de pie y estable.','Mancuerna entre pies; tirón de cadera y recibe overhead a un brazo (power o squat) con bloqueo.','La mancuerna viaja cerca del cuerpo; puño cerrado y hombro activo arriba.','Baja a hombro o suelo con control; cambia de mano según serie.','Error típico: press muscular sin extensión de cadera, o hombro sin packing arriba.','Empieza ligero. Progresión: hang DB snatch → suelo.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Dumbbell Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Alternating Dumbbell Snatch','Kettlebell Snatch','Snatch']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','deltoids']::text[])>0 THEN ARRAY['gluteal','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada de mancuerna(s) a hombros.',
  mobile_instructions = ARRAY['Mancuerna(s) entre pies; tirón de cadera y recepción en rack a hombros (una o dos manos).','Codos altos o neutros según agarre; piernas absorben la carga.','Párate y baja con control.','Error típico: remo de brazo sin extensión de cadera.','Progresión: hang DB clean → desde suelo. Si no, goblet clean a pecho.','Mantén la mancuerna cerca del cuerpo.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Clean','Kettlebell Clean','Sandbag clean']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','deltoids']::text[])>0 THEN ARRAY['trapezius','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Wall ball: sentadilla con balón y lanzamiento a diana.',
  mobile_instructions = ARRAY['Sujeta el balón frente al pecho y baja a sentadilla mirando la diana.','Extiende las piernas y lanza el balón hacia la diana con ambos brazos.','Alza las manos y recibe el balón frente a la diana antes de volver a bajar.','Balón al pecho, pies de sentadilla, cara a la diana.','Sentadilla completa con el balón pegado al pecho.','Al subir, extiende cadera y lanza a la diana; recibe amortiguando.','Encadena la siguiente sentadilla sin pausar el balón caído.','Error típico: sentadilla corta o lanzar solo con brazos.']::text[],
  mobile_equipment = NULLIF('Wall Ball',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Wall ball';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','abs']::text[])>0 THEN ARRAY['gluteal','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Wall Ball','') IS NOT NULL THEN ARRAY['Wall Ball']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Wall ball';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Golpea el balón al suelo desde overhead.',
  mobile_instructions = ARRAY['De pie, balon al pecho con ambas manos y core firme.','Sube el balon a extension completa sobre la cabeza.','Golpea el balon contra el suelo con bisagra de cadera y brazos.','Medball a la altura del pecho o overhead; pies al ancho de hombros, core firme.','Extiende a overhead (si el estándar lo pide) y golpea el balón al suelo con fuerza de cadera y brazos.','Agarra el bote o recoge y repite; no redondees la lumbar al recoger.','Exhala al slam. Mantén la mirada y el pecho organizados.','Error típico: solo brazos sin bisagra de cadera, o perder el balón en el rebote.']::text[],
  mobile_equipment = NULLIF('Slam Ball',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Ball slam';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','upper-back']::text[])>0 THEN ARRAY['abs','upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Slam Ball','') IS NOT NULL THEN ARRAY['Slam Ball']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Ball slam';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada con balón medicinal a hombros.',
  mobile_instructions = ARRAY['Balón en el suelo; bisagra, cógelo y llévalo a rack/pecho con extensión de cadera (como clean ligero).','Párate alto con el balón en el pecho; baja a suelo con control o lanza según WOD.','Error típico: curlar el balón con la espalda redonda. Piernas y cadera primero.','Pies estables; exhala al subir.','Progresión: deadlift del balón → clean a squat. Si no, goblet desde el suelo.','Estándar: balón del suelo a pecho/rack claro.']::text[],
  mobile_equipment = NULLIF('Balón medicinal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Medball clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Balón medicinal','') IS NOT NULL THEN ARRAY['Balón medicinal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Medball clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada de saco a hombros o abrazo.',
  mobile_instructions = ARRAY['Sandbag en el suelo; abraza/agarra; extensión de cadera y llévalo a hombros o rack de pecho.','Abdomen firme; no redondees al despegar. Párate alto.','Baja el saco con control o suéltalo si el WOD lo permite de forma segura.','Error típico: curlar con lumbar. Piernas primero.','Progresión: abrazo a cadera → hombro. Si no, medball clean.','Estándar: saco del suelo a hombros/pecho estable.']::text[],
  mobile_equipment = NULLIF('Saco',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Sandbag clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Clean','Dumbbell Clean','Kettlebell Clean']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','upper-back']::text[])>0 THEN ARRAY['quadriceps','upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Saco','') IS NOT NULL THEN ARRAY['Saco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sandbag clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Saco del suelo a pasar sobre un hombro.',
  mobile_instructions = ARRAY['Sandbag del suelo a un hombro pasando por el torso; extensión de cadera; cambia de hombro cada rep si se pide.','Abraza el saco; no lo balances con la espalda redonda.','Error típico: girar lumbar bajo carga. Gira con pies y torso juntos.','Deja el saco al suelo con control entre reps.','Carga y altura de hombro claras. Exhala al pasar el hombro.','Si es muy pesado, clean a hombro y pausa.']::text[],
  mobile_equipment = NULLIF('Saco',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Sandbag over shoulder';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','abs']::text[])>0 THEN ARRAY['quadriceps','abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Saco','') IS NOT NULL THEN ARRAY['Saco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sandbag over shoulder';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte del yoke sobre trapecios caminando.',
  mobile_instructions = ARRAY['Yugo sobre trapecios; párate alto; camina con pasos cortos bajo carga pesada.','Core firme; mirada al frente; no trotes. Deja el yugo con control en los soportes.','Error típico: inclinarte o acelerar y perder el equilibrio. Peso que permita marcha estable.','Calienta con farmer walks. Distancia corta al inicio.','Si no hay yoke, farmer o sandbag carry.','Estándar: distancia completada con el yugo sobre los hombros.']::text[],
  mobile_equipment = NULLIF('Yoke',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Yoke carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','trapezius']::text[])>0 THEN ARRAY['abs','trapezius']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Yoke','') IS NOT NULL THEN ARRAY['Yoke']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Yoke carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Double unders: la comba pasa dos veces por salto.',
  mobile_instructions = ARRAY['Comba ligera; muñecas generan el giro doble por cada salto; saltos bajos y rebotes de antepié.','Mirada al frente; codos cerca del cuerpo; no abracees con los hombros.','Ritmo: un salto, dos giros. Empieza con singles rápidos → singles altos → dobles.','Error típico: saltar demasiado alto o girar con los brazos enteros.','Si fallas, practica el ‘penguin tap’ o singles con mayor cadencia.','Estándar: cada rep = dos pasos de comba bajo los pies por salto.']::text[],
  mobile_equipment = NULLIF('Comba',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('cardio',''),
  mobile_muscle_group = NULLIF('Cardio','')
WHERE catalog_key = 'catalog:Double-Under';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Single-Under']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['cardiovascular system']::text[])>0 THEN ARRAY['cardiovascular system']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves','forearm']::text[])>0 THEN ARRAY['calves','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Comba','') IS NOT NULL THEN ARRAY['Comba']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Double-Under';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Single unders: un paso de comba por salto.',
  mobile_instructions = ARRAY['Un giro de comba por salto; rebotes bajos de antepié; muñecas hacen el trabajo.','Codos cerca; mirada al frente; ritmo constante.','Error típico: saltar demasiado alto o girar con hombros.','Base para dobles. Practica 30–60 s sin fallo.','Si fallas, salta sin comba a tempo y luego añade la comba.','Estándar: cada salto = un paso de comba.']::text[],
  mobile_equipment = NULLIF('Comba',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('cardio',''),
  mobile_muscle_group = NULLIF('Cardio','')
WHERE catalog_key = 'catalog:Single-Under';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Double-Under']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['cardiovascular system']::text[])>0 THEN ARRAY['cardiovascular system']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Comba','') IS NOT NULL THEN ARRAY['Comba']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Single-Under';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Triple unders: tres pasos de comba por salto.',
  mobile_instructions = ARRAY['Tres giros de comba por un salto; muñecas muy rápidas; salto un poco más alto que en dobles.','Relaja hombros; antepié; mirá al frente.','Error típico: tensar todo el brazo. Solo muñecas.','Progresión: dobles sólidos → intentos de triples con singles de recuperación.','Volumen bajo al aprender. Parar antes de fallar por fatiga de gemelos.','Estándar: tres pasos de comba bajo los pies por salto.']::text[],
  mobile_equipment = NULLIF('Comba',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('cardio',''),
  mobile_muscle_group = NULLIF('Cardio','')
WHERE catalog_key = 'catalog:Triple-Under';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['cardiovascular system']::text[])>0 THEN ARRAY['cardiovascular system']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves','forearm']::text[])>0 THEN ARRAY['calves','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Comba','') IS NOT NULL THEN ARRAY['Comba']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Triple-Under';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Bici/Assault o Echo: pedaleo + brazos.',
  mobile_instructions = ARRAY['Ajusta sillín: al pedal abajo la rodilla queda casi extendida sin bloquear. Agarra los manillares móviles.','Pedalea con empuje y tiro de brazos a la vez; tronco estable, mirada al frente.','Cadencia alta con resistencia moderada; no rebotes en el asiento.','Inhala/exhala de forma rítmica; si te faltan brazos, baja un poco la resistencia.','Error típico: solo empujar con piernas o balancear el torso. Usa el tren completo.','Estándar: ritmo constante en el intervalo; progresión = más vatios o misma potencia con menos fatiga.']::text[],
  mobile_equipment = NULLIF('Air Bike',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('cardio',''),
  mobile_muscle_group = NULLIF('Cardio','')
WHERE catalog_key = 'catalog:Air bike';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['cardiovascular system']::text[])>0 THEN ARRAY['cardiovascular system']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal','deltoids']::text[])>0 THEN ARRAY['quadriceps','gluteal','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Air Bike','') IS NOT NULL THEN ARRAY['Air Bike']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Air bike';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Echo bike: cardio de cuerpo completo.',
  mobile_instructions = ARRAY['Asiento ajustado; pedalea con brazos y piernas; tronco estable.','Resistencia por aire: más velocidad = más dureza. Elige cadencia sostenible al intervalo.','No te levantes del asiento salvo sprint corto; evita balanceo lateral.','Error típico: solo piernas. Usa el push-pull de brazos.','Calienta 2–3 min. Enfría pedaleando suave.','Métrica: calorías o vatios; progresión = más output con misma RPE.']::text[],
  mobile_equipment = NULLIF('Echo Bike',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('cardio',''),
  mobile_muscle_group = NULLIF('Cardio','')
WHERE catalog_key = 'catalog:Echo bike';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['cardiovascular system']::text[])>0 THEN ARRAY['cardiovascular system']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Echo Bike','') IS NOT NULL THEN ARRAY['Echo Bike']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Echo bike';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'SkiErg: tirones verticales de trineo.',
  mobile_instructions = ARRAY['Agarra los mangos; bisagra de cadera y tira abajo con dorsales y triceps; piernas estabilizan.','Extiende cadera al final del tirón; recupera con control arriba.','Cadencia fluida; no te encorves. Exhala en el tirón.','Error típico: solo brazos sin bisagra, o rebotar en la recuperación.','Ajusta resistencia del ventilador. Calienta suave.','Métrica: calorías/vatios. Progresión = más output estable.']::text[],
  mobile_equipment = NULLIF('SkiErg',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('cardio',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:SkiErg';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('SkiErg','') IS NOT NULL THEN ARRAY['SkiErg']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:SkiErg';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Carreras cortas de ida y vuelta.',
  mobile_instructions = ARRAY['Sprint corto ida y vuelta entre marcas; toca la línea con mano o pie según regla; cambia de dirección bajo.','Acelera y frena con pasos cortos; no te deslices.','Error típico: curvas amplias que alargan la distancia. Gira bajos y cercanos a la línea.','Zapatilla con agarre. Respira en el tramo.','Progresión: más toques o menos tiempo. Si no, row/bike por calorías.','Estándar: tocar cada línea en cada shuttle.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('cardio',''),
  mobile_muscle_group = NULLIF('Cardio','')
WHERE catalog_key = 'catalog:Shuttle run';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['cardiovascular system']::text[])>0 THEN ARRAY['cardiovascular system']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','calves']::text[])>0 THEN ARRAY['quadriceps','calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Shuttle run';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje de trineo.',
  mobile_instructions = ARRAY['Manos en posts altos o bajos; ángulo de ataque; empuja el sled con pasos cortos y poderosos.','Cadera detrás de los hombros; mira al frente unos metros.','Error típico: posts demasiado altos con torso erecto (pierdes potencia) o talones que se levantan siempre.','Carga que permita avanzar sin parar cada paso. Respira en ritmo.','Progresión: más peso. Alternativa: prowler o hill sprints.','Estándar: distancia completada; sled no se detiene por técnica rota.']::text[],
  mobile_equipment = NULLIF('Trineo',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Sled push';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves','abs']::text[])>0 THEN ARRAY['calves','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Trineo','') IS NOT NULL THEN ARRAY['Trineo']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sled push';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Tirón de trineo con cuerda o arnés.',
  mobile_instructions = ARRAY['Arnés o cuerda; tira del sled caminando hacia atrás o tirando de cuerda según setup.','Tronco inclinado, pasos firmes; brazos o arnés transmiten la fuerza.','Error típico: redondear lumbar o pasos deslizantes. Peso que permita marcha sólida.','Exhala en los pasos difíciles. Distancia o idas objetivo.','Progresión: más peso o más metros. Si no hay sled, rower hard pulls.','Estándar: sled se mueve continuamente sin paradas largas.']::text[],
  mobile_equipment = NULLIF('Trineo',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Sled pull';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','hamstring']::text[])>0 THEN ARRAY['upper-back','hamstring']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','forearm']::text[])>0 THEN ARRAY['biceps','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Trineo','') IS NOT NULL THEN ARRAY['Trineo']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sled pull';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte de cargas a los lados caminando.',
  mobile_instructions = ARRAY['Cargas a los lados (mancuernas, kettlebells o farmer handles); párate alto, hombros abajo, core firme.','Camina con pasos cortos y rápidos; mirada al frente; no te inclines a un lado.','Aprieta agarre; respira; deja la carga con control al terminar la distancia.','Error típico: encoger trapecios o bambolear lateralmente.','Progresión: más peso o más metros. Si el agarre falla, tiza o straps solo si el objetivo no es grip.','Estándar: postura alta todo el recorrido.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Farmer carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Bear Hug Carry','Double Kettlebell Farmers Carry','Dumbbell Carry','Farmer walk','Sandbag Carry','Suitcase Carry']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Farmer carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'BikeErg Concept2 por calorías, metros o tiempo.',
  mobile_instructions = ARRAY['Ajusta sillín y damper del BikeErg antes de empezar el intervalo o el WOD.','Pedalea con torso estable, pies anclados y ritmo que puedas sostener.','Inhala en la fase fácil y exhala cuando aprietes el damper o la cadencia.','Error típico: damper al máximo desde el inicio y perder ritmo a mitad de serie.','Registra calorías o metros según el estándar del WOD; no inventes repeticiones.','Progresión: más Cal/min o menos descanso. Si no hay BikeErg, Echo o Air bike.','Estándar: máquina en movimiento continuo hasta completar la dosis prescrita.']::text[],
  mobile_equipment = NULLIF('BikeErg',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('cardio',''),
  mobile_muscle_group = NULLIF('Cardio','')
WHERE catalog_key = 'catalog:Bike Erg';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['cardiovascular system']::text[])>0 THEN ARRAY['cardiovascular system']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','hamstring','gluteal']::text[])>0 THEN ARRAY['quadriceps','hamstring','gluteal']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('BikeErg','') IS NOT NULL THEN ARRAY['BikeErg']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Bike Erg';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sit-up con AbMat: hombros al suelo y tocar pies o diana.',
  mobile_instructions = ARRAY['Coloca el AbMat bajo la zona lumbar para permitir el rango completo.','Hombros y omóplatos tocan el suelo en cada repetición antes de subir.','Sube hasta tocar los pies, los muslos o la diana que marque el WOD.','Exhala al subir; evita tirar del cuello con las manos detrás de la cabeza.','Error típico: no tocar el suelo con los hombros o rebotar en la bajada.','Progresión: más repeticiones o lastre en el pecho. Si no hay AbMat, sit-up clásico.','Estándar: hombros abajo y contacto arriba en cada rep contada.']::text[],
  mobile_equipment = NULLIF('AbMat',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Ab Mat Sit-Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('AbMat','') IS NOT NULL THEN ARRAY['AbMat']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Ab Mat Sit-Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancada con barra bloqueada por encima de la cabeza.',
  mobile_instructions = ARRAY['Bloquea la barra overhead con codos extendidos y muñecas firmes antes de zancar.','Da una zancada manteniendo el lockout: la barra no debe viajar delante ni atrás.','Rodilla trasera cerca del suelo con control; inhala abajo y exhala al empujar.','Error típico: perder el overhead en el paso o inclinarte en exceso hacia delante.','Empuja con la pierna delantera para volver y alterna según el WOD.','Progresión: más carga o zancadas caminando. Si no controlas OH, front rack lunge.','Estándar: cada zancada con barra bloqueada y pie estable en el suelo.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Overhead Lunge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Overhead Lunge','Kettlebell Overhead Lunge']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','abs']::text[])>0 THEN ARRAY['gluteal','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Overhead Lunge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Arrancada con mancuerna alternando el brazo.',
  mobile_instructions = ARRAY['Coloca la mancuerna entre los pies, espalda neutra y talones apoyados.','Extiende cadera con potencia y recibe overhead con el brazo bloqueado.','Baja la mancuerna al suelo con control; cambia de mano según el estándar.','Exhala en la extensión; no gires el tronco de más al recibir arriba.','Error típico: press-out lento o redondear lumbar en el tirón desde el suelo.','Progresión: más peso o densificar reps. Si no, snatch a un solo brazo sin alternar.','Estándar: mancuerna del suelo a overhead bloqueado en cada repetición contada.']::text[],
  mobile_equipment = NULLIF('Mancuerna',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Alternating Dumbbell Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Dumbbell Power Snatch','Dumbbell Snatch','Hang Snatch','Kettlebell Snatch','Power Snatch','Snatch']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','gluteal']::text[])>0 THEN ARRAY['deltoids','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuerna','') IS NOT NULL THEN ARRAY['Mancuerna']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Alternating Dumbbell Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancada con mancuerna(s) bloqueada(s) overhead.',
  mobile_instructions = ARRAY['Lleva la mancuerna o el par a overhead bloqueado antes del primer paso.','Zancada sin perder el lockout; tronco vertical y mirada al frente.','Inhala en la bajada y exhala al recuperar la posición de pie.','Error típico: inclinar el torso o dejar caer el codo en el overhead.','Alterna piernas o camina según el WOD; si usas una sola mancuerna, evita ladearte.','Progresión: más carga o distancia. Si no controlas OH, front rack lunge con DB.','Estándar: cada zancada con carga bloqueada arriba y pies firmes.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Overhead Lunge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Kettlebell Overhead Lunge','Overhead Lunge']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','gluteal']::text[])>0 THEN ARRAY['abs','gluteal']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Overhead Lunge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Suspensión de la barra con brazos extendidos.',
  mobile_instructions = ARRAY['Agarra la barra con brazos extendidos y pies fuera del suelo desde el inicio.','Elige hang activo (hombros empaquetados) o pasivo según lo que diga la pizarra.','Respira calmado; exhala si notas que te balanceas y vuelve al centro.','Error típico: balanceo excesivo o soltar antes de completar los segundos.','Registra el tiempo continuo; no cuentes reps inventadas.','Progresión: más segundos o agarre más exigente. Si no aguantas, scrapes o hangs asistidos.','Estándar: suspensión continua con brazos extendidos durante el tiempo prescrito.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Antebrazos','')
WHERE catalog_key = 'catalog:Dead Hang';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearm']::text[])>0 THEN ARRAY['forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','deltoids']::text[])>0 THEN ARRAY['upper-back','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dead Hang';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Paso sobre el cajón hasta el otro lado, sin exigir salto.',
  mobile_instructions = ARRAY['Coloca un pie completo sobre el cajón y transfiere el peso con control.','Pasa al otro lado hasta apoyar ambos pies en el suelo; no exige extensión de salto.','Inhala al subir y exhala al aterrizar al otro lado con estabilización.','Error típico: empujar el cajón o no pasar completamente al otro lado.','Alterna la pierna de ataque si el WOD lo prescribe; elige altura según estándar.','Progresión: cajón más alto o más ritmo. Si no, step-up al cajón sin pasar al otro lado.','Estándar: cada rep termina con ambos pies en el suelo del lado contrario.']::text[],
  mobile_equipment = NULLIF('Cajón',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Box Step-Over';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Cajón','') IS NOT NULL THEN ARRAY['Cajón']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Box Step-Over';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada de D-ball hasta pecho u hombros.',
  mobile_instructions = ARRAY['Abraza el D-ball desde el suelo con pecho cerca del balón y espalda neutra.','Extiende cadera y recibe el balón en pecho u hombros con tronco firme.','Exhala en la extensión; no rebotes el balón si el WOD lo prohíbe.','Error típico: redondear lumbar o soltar el abrazo antes de la recepción.','Devuelve el balón al suelo con control antes de la siguiente repetición.','Progresión: balón más pesado. Si no hay D-ball, sandbag clean de peso similar.','Estándar: balón del suelo a recepción alta en cada rep contada.']::text[],
  mobile_equipment = NULLIF('D-ball',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:D-Ball Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','deltoids']::text[])>0 THEN ARRAY['abs','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('D-ball','') IS NOT NULL THEN ARRAY['D-ball']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:D-Ball Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'D-ball del suelo pasando por encima del hombro.',
  mobile_instructions = ARRAY['Levanta el D-ball desde el suelo manteniendo la lumbar neutra y el abrazo firme.','Pasa el balón por encima de un hombro hasta que cruce claramente al otro lado.','Exhala al pasar el hombro; controla el espacio para no golpear a nadie.','Error típico: no completar el pase sobre el hombro o girar en exceso la columna.','Alterna hombro si el WOD lo indica; deja el balón listo para la siguiente.','Progresión: más peso o más densificación. Si no, sandbag over shoulder.','Estándar: cada rep pasa el balón completamente sobre el hombro prescrito.']::text[],
  mobile_equipment = NULLIF('D-ball',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:D-Ball Over Shoulder';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','deltoids']::text[])>0 THEN ARRAY['abs','deltoids']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('D-ball','') IS NOT NULL THEN ARRAY['D-ball']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:D-Ball Over Shoulder';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Salto al cajón partiendo desde sentado.',
  mobile_instructions = ARRAY['Siéntate en un cajón o banco bajo estable con los pies delante y listos para empujar.','Sin balanceo excesivo, salta al cajón objetivo y extiende cadera arriba.','Exhala en el despegue; aterriza con control antes de bajar otra vez.','Error típico: usar impulso de brazos ilegal o no llegar a extensión en el cajón alto.','Baja y vuelve a la posición sentada completa entre repeticiones.','Progresión: cajón más alto. Si no controlas, box jump de pie o step-up.','Estándar: cada rep parte sentado y termina de pie sobre el cajón objetivo.']::text[],
  mobile_equipment = NULLIF('Cajón',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Seated Box Jump';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Cajón','') IS NOT NULL THEN ARRAY['Cajón']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Seated Box Jump';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla con mancuernas en rack frontal.',
  mobile_instructions = ARRAY['Coloca las mancuernas en rack sobre los hombros con codos altos y pecho erguido.','Pies a la anchura de hombros; baja en sentadilla con torso vertical.','Inhala al bajar y exhala al subir extendiendo cadera y rodillas.','Error típico: dejar caer los codos o desplazar las rodillas hacia dentro.','Mantén los talones apoyados y la mirada al frente durante toda la serie.','Progresión: más peso o pausa abajo. Si no, goblet squat con una KB.','Estándar: profundidad y rack estables en cada repetición contada.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Front Squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Box Squat','Goblet squat','Sandbag Squat','Sentadilla','Sentadilla frontal','Zercher Squat']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps']::text[])>0 THEN ARRAY['quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','abs']::text[])>0 THEN ARRAY['gluteal','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Front Squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancada con mancuernas en front rack.',
  mobile_instructions = ARRAY['Mancuernas en front rack estable con torso alto antes del primer paso.','Da una zancada con control de rodilla y cadera; rodilla trasera cerca del suelo.','Inhala en la bajada y exhala al recuperar; no dejes que el rack se caiga.','Error típico: inclinarte hacia delante o dar pasos demasiado cortos e inestables.','Vuelve y alterna o camina según el WOD manteniendo el pecho alto.','Progresión: más carga o zancadas caminando. Si no, zancada con goblet.','Estándar: cada zancada con rack firme y pie delantero estable.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Front Rack Lunge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Double Kettlebell Front Rack Lunge','Front rack lunge','Kettlebell Front Rack Lunge']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Front Rack Lunge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Arrancada de potencia con mancuerna: recepción overhead sin sentadilla profunda.',
  mobile_instructions = ARRAY['Prepara el material (Mancuerna) y la postura inicial de arrancada de potencia con mancuerna.','Mancuerna entre los pies.','Extiende y recibe overhead en media sentadilla.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Dumbbell Power Snatch.']::text[],
  mobile_equipment = NULLIF('Mancuerna',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Dumbbell Power Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Alternating Dumbbell Snatch','Hang Snatch','Power Snatch','Snatch']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','gluteal']::text[])>0 THEN ARRAY['deltoids','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuerna','') IS NOT NULL THEN ARRAY['Mancuerna']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Power Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada de potencia con mancuerna a rack, sin sentadilla profunda.',
  mobile_instructions = ARRAY['Prepara el material (Mancuerna) y la postura inicial de cargada de potencia con mancuerna.','Mancuerna en el suelo.','Extiende cadera y recibe en rack al hombro.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Dumbbell Power Clean.']::text[],
  mobile_equipment = NULLIF('Mancuerna',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Power Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Clean','Hang Clean','Power Clean']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','abs']::text[])>0 THEN ARRAY['trapezius','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuerna','') IS NOT NULL THEN ARRAY['Mancuerna']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Power Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Push press con mancuernas: dip de piernas e impulso a overhead.',
  mobile_instructions = ARRAY['Prepara el material (Mancuernas) y la postura inicial de push press con mancuernas.','Mancuernas en rack.','Dip corto y drive.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Dumbbell Push Press.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Dumbbell Push Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Strict Press','Kettlebell Press','Kettlebell Push Press','Push press','Strict press']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','gluteal']::text[])>0 THEN ARRAY['triceps','gluteal']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Push Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Push jerk con mancuernas: dip, drive y recepción con pies en paralelo.',
  mobile_instructions = ARRAY['Prepara el material (Mancuernas) y la postura inicial de push jerk con mancuernas.','Mancuernas en rack.','Dip y drive.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Dumbbell Push Jerk.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Dumbbell Push Jerk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Push jerk']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','quadriceps']::text[])>0 THEN ARRAY['deltoids','quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Push Jerk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla con mancuernas bloqueadas overhead.',
  mobile_instructions = ARRAY['Prepara el material (Mancuernas) y la postura inicial de sentadilla overhead con mancuernas.','Mancuernas overhead bloqueadas.','Sentadilla profunda con torso vertical.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Dumbbell Overhead Squat.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Overhead Squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Overhead squat']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','abs']::text[])>0 THEN ARRAY['gluteal','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Overhead Squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancadas caminando con mancuernas a los lados o en rack.',
  mobile_instructions = ARRAY['Prepara el material (Mancuernas) y la postura inicial de zancadas caminando con mancuernas.','Mancuernas a los lados o en rack.','Zancada caminando con control.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Dumbbell Walking Lunge.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Walking Lunge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Walking lunge']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Walking Lunge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Desde hang: cargada a rack y envión overhead con mancuernas.',
  mobile_instructions = ARRAY['Prepara el material (Mancuernas) y la postura inicial de cargada y envión colgante con mancuernas.','Desde hang, carga a rack.','Dip y envía overhead.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Dumbbell Hang Clean and Jerk.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Dumbbell Hang Clean and Jerk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','quadriceps']::text[])>0 THEN ARRAY['deltoids','quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','triceps','abs']::text[])>0 THEN ARRAY['gluteal','triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Hang Clean and Jerk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Caminata con dos kettlebells en front rack.',
  mobile_instructions = ARRAY['Prepara el material (Kettlebells) y la postura inicial de porte en rack frontal con dos kettlebells.','Dos KB en rack frontal.','Camina alto sin dejar caer los codos.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Double Kettlebell Front Rack Carry.']::text[],
  mobile_equipment = NULLIF('Kettlebells',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Double Kettlebell Front Rack Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','deltoids']::text[])>0 THEN ARRAY['abs','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','forearm']::text[])>0 THEN ARRAY['quadriceps','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebells','') IS NOT NULL THEN ARRAY['Kettlebells']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Double Kettlebell Front Rack Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Caminata con dos kettlebells bloqueadas overhead.',
  mobile_instructions = ARRAY['Prepara el material (Kettlebells) y la postura inicial de porte overhead con dos kettlebells.','KB bloqueadas overhead.','Camina sin perder el lockout.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Double Kettlebell Overhead Carry.']::text[],
  mobile_equipment = NULLIF('Kettlebells',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Double Kettlebell Overhead Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Overhead Carry']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','abs']::text[])>0 THEN ARRAY['deltoids','abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','forearm']::text[])>0 THEN ARRAY['trapezius','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebells','') IS NOT NULL THEN ARRAY['Kettlebells']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Double Kettlebell Overhead Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Cargada a rack y envión overhead con kettlebell (un brazo o alternando).',
  mobile_instructions = ARRAY['Prepara el material (Kettlebell) y la postura inicial de cargada y envión con kettlebell.','KB del suelo a rack.','Dip y envía overhead.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Kettlebell Clean and Jerk.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Kettlebell Clean and Jerk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Clean and Jerk','Dumbbell Clean and Jerk','Log Clean And Jerk']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','quadriceps']::text[])>0 THEN ARRAY['deltoids','quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','triceps','abs']::text[])>0 THEN ARRAY['gluteal','triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Clean and Jerk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancada con kettlebell bloqueada overhead.',
  mobile_instructions = ARRAY['Prepara el material (Kettlebell) y la postura inicial de zancada overhead con kettlebell.','KB overhead bloqueada.','Zancada sin perder lockout.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Kettlebell Overhead Lunge.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Kettlebell Overhead Lunge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Overhead Lunge','Overhead Lunge']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','abs']::text[])>0 THEN ARRAY['gluteal','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Overhead Lunge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Push press con kettlebell: dip e impulso a overhead.',
  mobile_instructions = ARRAY['Prepara el material (Kettlebell) y la postura inicial de push press con kettlebell.','KB en rack.','Dip corto y drive.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Kettlebell Push Press.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Kettlebell Push Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Push Press','Dumbbell Strict Press','Kettlebell Press','Push press','Strict press']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids']::text[])>0 THEN ARRAY['deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','gluteal']::text[])>0 THEN ARRAY['triceps','gluteal']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Push Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Dominada asistida con salto de piernas hasta que la barbilla pase la barra.',
  mobile_instructions = ARRAY['Prepara el material (Barra) y la postura inicial de dominada con salto.','Salta y tira a la vez.','Barbilla por encima de la barra.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Jumping Pull-Up.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Jumping Pull-Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dominadas','Dominadas butterfly','Dominadas estrictas','Dominadas kipping','Dominadas lastradas','L Pull Up','Negative Pull Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','deltoids','calves']::text[])>0 THEN ARRAY['biceps','deltoids','calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Jumping Pull-Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Burpee seguido de muscle-up a barra (o anillas según WOD).',
  mobile_instructions = ARRAY['Prepara el material (Barra) y la postura inicial de burpee a muscle-up.','Burpee completo.','Salta a la barra y completa el muscle-up.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Burpee Muscle-Up.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Burpee Muscle-Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Burpee Bar Muscle Up','Muscle-up anillas','Muscle-up barra','Muscle-up estricto anillas','Muscle-up estricto barra']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','chest']::text[])>0 THEN ARRAY['upper-back','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','quadriceps','abs']::text[])>0 THEN ARRAY['deltoids','quadriceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Burpee Muscle-Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Caminata abrazando un saco, D-ball u objeto pesado al pecho.',
  mobile_instructions = ARRAY['Prepara el material (Saco) y la postura inicial de porte en abrazo de oso.','Abraza la carga al pecho.','Camina con pasos cortos.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Bear Hug Carry.']::text[],
  mobile_equipment = NULLIF('Saco',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Bear Hug Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Double Kettlebell Farmers Carry','Dumbbell Carry','Farmer carry','Farmer walk','Sandbag Carry','Suitcase Carry']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','quadriceps']::text[])>0 THEN ARRAY['abs','quadriceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['gluteal','forearm','upper-back']::text[])>0 THEN ARRAY['gluteal','forearm','upper-back']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Saco','') IS NOT NULL THEN ARRAY['Saco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Bear Hug Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla con barra hasta sentarse brevemente en un cajón y subir.',
  mobile_instructions = ARRAY['Prepara el material (Barra) y la postura inicial de sentadilla a cajón.','Barra en espalda.','Baja hasta el cajón con control.','Error típico: perder la posición o usar impulso ilegal.','Inhala en la preparación y exhala en el esfuerzo principal.','Progresión: más carga o más densidad. Si no, usa una variante más simple del mismo patrón.','Estándar: cada repetición cumple el rango y el lockout/recepción de Box Squat.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Box Squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Front Squat','Goblet squat','Sandbag Squat','Sentadilla','Sentadilla frontal','Zercher Squat']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Box Squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Atlas Stone Over Shoulder: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Atlas Stone Over Shoulder cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Odd object',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Atlas Stone Over Shoulder';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Odd object','') IS NOT NULL THEN ARRAY['Odd object']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Atlas Stone Over Shoulder';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto con barbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Axle Deadlift cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Axle',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Axle Deadlift';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Deadlift','Kettlebell Deadlift']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Axle','') IS NOT NULL THEN ARRAY['Axle']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Axle Deadlift';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con barbell hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Axle Press cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Axle',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Axle Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Strict Press','Kettlebell Press','Log Press','Strict press']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Axle','') IS NOT NULL THEN ARRAY['Axle']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Axle Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancada o step-up con barbell: rodilla alineada y control del tronco.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Back Rack Lunge cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Back Rack Lunge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Back Rack Lunge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla con barbell: profundidad controlada y torso estable.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Barbell Squat Jump cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Barbell Squat Jump';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Barbell Squat Jump';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancada o step-up con barbell: rodilla alineada y control del tronco.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Barbell Step Up cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Barbell Step Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Double Dumbbell Step Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Barbell Step Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Odd-object o acondicionamiento (Battle Rope) con peso corporal; potencia y control.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Battle Rope cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Cuerda',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Battle Rope';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Cuerda','') IS NOT NULL THEN ARRAY['Cuerda']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Battle Rope';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Bird Dog: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Bird Dog cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Bird Dog';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Bird Dog';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con barbell hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Bodyweight Clean And Jerk cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Bodyweight Clean And Jerk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Bodyweight Clean And Jerk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con barbell hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Bradford Press cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Bradford Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Bradford Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Burpee con el obstáculo o implemento indicado; pecho al suelo y extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Burpee Bar Muscle Up cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Burpee Bar Muscle Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Burpee Muscle-Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','forearm']::text[])>0 THEN ARRAY['biceps','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Burpee Bar Muscle Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Burpee con el obstáculo o implemento indicado; pecho al suelo y extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Burpee Over Dumbbell cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Burpee Over Dumbbell';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY['Burpee Over The Bar']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Burpee Over Dumbbell';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Burpee con el obstáculo o implemento indicado; pecho al suelo y extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Burpee Over The Bar cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Burpee Over The Bar';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY['Burpee Over Dumbbell']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Burpee Over The Bar';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Isométrico o control de tronco (Copenhagen Plank): línea estable sin compensar.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Copenhagen Plank cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Copenhagen Plank';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Copenhagen Plank';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Crab Walk cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Crab Walk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Crab Walk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Crossover Single Under: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Crossover Single Under cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Crossover Single Under';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Crossover Single Under';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Isométrico o control de tronco (Dead Bug): línea estable sin compensar.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dead Bug cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Dead Bug';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dead Bug';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto con barbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Deficit Deadlift cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Deficit Deadlift';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Deadlift','Dumbbell Romanian Deadlift','Kettlebell Deadlift','Peso muerto','Peso muerto rumano','Peso muerto sumo','Trap Bar Deadlift']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Deficit Deadlift';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con kettlebell: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Double Kettlebell Farmers Carry cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Double Kettlebell Farmers Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Bear Hug Carry','Dumbbell Carry','Farmer carry','Farmer walk','Sandbag Carry','Suitcase Carry']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Double Kettlebell Farmers Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancada o step-up con kettlebell: rodilla alineada y control del tronco.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Double Kettlebell Front Rack Lunge cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Double Kettlebell Front Rack Lunge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Front Rack Lunge','Front rack lunge','Kettlebell Front Rack Lunge']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Double Kettlebell Front Rack Lunge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con dumbbell hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Bench Press cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Dumbbell Bench Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Bench Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancada o step-up con dumbbell: rodilla alineada y control del tronco.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Box Step Up cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Box Step Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Box Step-Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Box Step Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto con dumbbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Burpee Deadlift cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Dumbbell Burpee Deadlift';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Burpee Deadlift';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con dumbbell: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Carry cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Dumbbell Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Bear Hug Carry','Double Kettlebell Farmers Carry','Farmer carry','Farmer walk','Log Carry','Sandbag Carry','Suitcase Carry']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto con dumbbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Deadlift cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Dumbbell Deadlift';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Axle Deadlift','Deficit Deadlift','Dumbbell Romanian Deadlift','Kettlebell Deadlift','Peso muerto','Peso muerto rumano','Peso muerto sumo','Trap Bar Deadlift']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Deadlift';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con dumbbell hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Floor Press cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Dumbbell Floor Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Floor Press']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Floor Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Olímpico/híbrido con dumbbell: recepción estable y marca clara en cada rep.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Hang Clean To Overhead cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Hang Clean To Overhead';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','gluteal','abs']::text[])>0 THEN ARRAY['trapezius','gluteal','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Hang Clean To Overhead';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Olímpico/híbrido con dumbbell: recepción estable y marca clara en cada rep.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Hang Power Clean cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Hang Power Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Hang power clean']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','gluteal','abs']::text[])>0 THEN ARRAY['trapezius','gluteal','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Hang Power Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Olímpico/híbrido con dumbbell: recepción estable y marca clara en cada rep.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Hang Split Snatch cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Hang Split Snatch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Hang Split Snatch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla con dumbbell: profundidad controlada y torso estable.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Hang Squat Clean cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Hang Squat Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Hang Squat Clean']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Hang Squat Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con dumbbell: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Overhead Carry cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Dumbbell Overhead Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Double Kettlebell Overhead Carry']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Overhead Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto con dumbbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Romanian Deadlift cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Dumbbell Romanian Deadlift';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Deficit Deadlift','Dumbbell Deadlift','Kettlebell Deadlift','Peso muerto','Peso muerto rumano','Peso muerto sumo','Trap Bar Deadlift']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Romanian Deadlift';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con dumbbell hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Shoulder Press cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Dumbbell Shoulder Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Shoulder Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Dumbbell Shoulder To Overhead: patrón de entrenamiento con dumbbell, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Shoulder To Overhead cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Dumbbell Shoulder To Overhead';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Shoulder To Overhead';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Olímpico/híbrido con dumbbell: recepción estable y marca clara en cada rep.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Split Clean cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Split Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Split Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla con dumbbell: profundidad controlada y torso estable.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Squat Clean cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Squat Clean';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Squat Clean';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla con dumbbell: profundidad controlada y torso estable.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Squat Clean Thruster cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Dumbbell Squat Clean Thruster';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Squat Clean Thruster';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con dumbbell hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Strict Press cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Dumbbell Strict Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Axle Press','Dumbbell Push Press','Kettlebell Press','Kettlebell Push Press','Log Press','Push press','Strict press']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Strict Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con dumbbell: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Dumbbell Waiters Walk cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Dumbbell Waiters Walk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dumbbell Waiters Walk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con barbell hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Floor Press cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Floor Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Floor Press']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Floor Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Flutter Kick: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Flutter Kick cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Flutter Kick';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Flutter Kick';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Isométrico o control de tronco (Glute Bridge): línea estable sin compensar.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Glute Bridge cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Glute Bridge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Glute Bridge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Glute Ham Raise: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Glute Ham Raise cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Glute Ham Raise';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Glute Ham Raise';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Flexión de brazos (Hand Release Push Up): pecho cerca del suelo y codos en extensión arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Hand Release Push Up cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Hand Release Push Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY['Fondos en anillas','Fondos en paralelas','Push Up','Ring Push Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hand Release Push Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Hang High Pull: patrón de entrenamiento con barbell, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Hang High Pull cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Hang High Pull';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','deltoids']::text[])>0 THEN ARRAY['quadriceps','deltoids']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','gluteal','abs']::text[])>0 THEN ARRAY['trapezius','gluteal','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hang High Pull';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Hanging Hip Touch: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Hanging Hip Touch cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Hanging Hip Touch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hanging Hip Touch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Hanging Knee Raise: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Hanging Knee Raise cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Hanging Knee Raise';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Hanging Knee Raise';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Husafell Carry cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Odd object',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Husafell Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Odd object','') IS NOT NULL THEN ARRAY['Odd object']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Husafell Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Jefferson Curl: patrón de entrenamiento con barbell, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Jefferson Curl cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Jefferson Curl';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Jefferson Curl';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Jerry Bag Carry cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Odd object',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Jerry Bag Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Odd object','') IS NOT NULL THEN ARRAY['Odd object']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Jerry Bag Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Salto pliométrico (Jumping Jack): aterrizaje suave y cadera extendida.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Jumping Jack cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Jumping Jack';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Jumping Jack';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Keg Carry cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Odd object',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Keg Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Odd object','') IS NOT NULL THEN ARRAY['Odd object']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Keg Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto con kettlebell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Kettlebell Deadlift cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Kettlebell Deadlift';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Axle Deadlift','Deficit Deadlift','Dumbbell Deadlift','Dumbbell Romanian Deadlift','Peso muerto','Peso muerto rumano','Peso muerto sumo','Trap Bar Deadlift']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Deadlift';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancada o step-up con kettlebell: rodilla alineada y control del tronco.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Kettlebell Front Rack Lunge cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Kettlebell Front Rack Lunge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Double Kettlebell Front Rack Lunge','Dumbbell Front Rack Lunge','Front rack lunge']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Front Rack Lunge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Trabajo de tronco/hombros con kettlebell: control anti-rotación o movilidad cargada.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Kettlebell Halo cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Kettlebell Halo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Halo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con kettlebell hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Kettlebell Press cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Kettlebell Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Axle Press','Dumbbell Push Press','Dumbbell Strict Press','Kettlebell Push Press','Log Press','Push press','Strict press']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto con kettlebell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Kettlebell Sumo Deadlift High Pull cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Kettlebell Sumo Deadlift High Pull';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Sumo Deadlift High Pull';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Trabajo de tronco/hombros con kettlebell: control anti-rotación o movilidad cargada.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Kettlebell Windmill cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Kettlebell Windmill';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kettlebell Windmill';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Variante de pino/HSPU (Kipping Handstand Push Up): control de línea y bloqueo de codos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Kipping Handstand Push Up cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Kipping Handstand Push Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['HSPU','HSPU deficit','HSPU libre','Parallette Handstand Push Up','Ring Handstand Push Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Kipping Handstand Push Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Variante de dominada (L Pull Up): tirón controlado hasta el estándar de rango.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de L Pull Up cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:L Pull Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dominadas','Dominadas butterfly','Dominadas estrictas','Dominadas kipping','Dominadas lastradas','Jumping Pull-Up','Negative Pull Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','forearm']::text[])>0 THEN ARRAY['biceps','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:L Pull Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con barbell hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Landmine Press cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Landmine',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Landmine Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Landmine','') IS NOT NULL THEN ARRAY['Landmine']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Landmine Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Burpee con el obstáculo o implemento indicado; pecho al suelo y extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Lateral Burpee cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Lateral Burpee';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Lateral Burpee';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancada o step-up con peso corporal: rodilla alineada y control del tronco.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Lateral Lunge cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Lateral Lunge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Lateral Lunge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Log Carry cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Tronco',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Log Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Carry','Sandbag Carry']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Tronco','') IS NOT NULL THEN ARRAY['Tronco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Log Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con peso corporal hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Log Clean And Jerk cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Tronco',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Log Clean And Jerk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Clean and Jerk','Dumbbell Clean and Jerk','Kettlebell Clean and Jerk']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Tronco','') IS NOT NULL THEN ARRAY['Tronco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Log Clean And Jerk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con peso corporal hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Log Press cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Tronco',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Log Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Axle Press','Dumbbell Strict Press','Kettlebell Press','Strict press']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Tronco','') IS NOT NULL THEN ARRAY['Tronco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Log Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Medicine Ball Box Step Over: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Medicine Ball Box Step Over cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Balón medicinal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Medicine Ball Box Step Over';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Balón medicinal','') IS NOT NULL THEN ARRAY['Balón medicinal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Medicine Ball Box Step Over';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Medicine Ball Sit Up: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Medicine Ball Sit Up cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Balón medicinal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Medicine Ball Sit Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Balón medicinal','') IS NOT NULL THEN ARRAY['Balón medicinal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Medicine Ball Sit Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Remo con peso corporal: codos atrás y omóplatos activos al final del tirón.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Medicine Ball Throw cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Balón medicinal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Medicine Ball Throw';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','forearm']::text[])>0 THEN ARRAY['biceps','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Balón medicinal','') IS NOT NULL THEN ARRAY['Balón medicinal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Medicine Ball Throw';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Odd-object o acondicionamiento (Mountain Climber) con peso corporal; potencia y control.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Mountain Climber cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Mountain Climber';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Mountain Climber';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Variante de dominada (Negative Pull Up): tirón controlado hasta el estándar de rango.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Negative Pull Up cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Negative Pull Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dominadas','Dominadas butterfly','Dominadas estrictas','Dominadas kipping','Dominadas lastradas','Jumping Pull-Up','L Pull Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','forearm']::text[])>0 THEN ARRAY['biceps','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Negative Pull Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Nordic Curl: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Nordic Curl cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Nordic Curl';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Nordic Curl';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con barbell: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Overhead Walk cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Overhead Walk';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Overhead Walk';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con peso corporal hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Pallof Press cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Pallof Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Pallof Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Parallel Bar Traverse: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Parallel Bar Traverse cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Parallel Bar Traverse';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','forearm']::text[])>0 THEN ARRAY['biceps','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Parallel Bar Traverse';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Variante de pino/HSPU (Parallette Handstand Push Up): control de línea y bloqueo de codos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Parallette Handstand Push Up cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Parallettes',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Parallette Handstand Push Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['HSPU','HSPU deficit','HSPU libre','Kipping Handstand Push Up','Ring Handstand Push Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Parallettes','') IS NOT NULL THEN ARRAY['Parallettes']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Parallette Handstand Push Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Remo con barbell: codos atrás y omóplatos activos al final del tirón.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Pendlay Row cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Pendlay Row';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Pendlay Row';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Plate Carry cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Plate Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Plate Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Flexión de brazos (Push Up): pecho cerca del suelo y codos en extensión arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Push Up cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Push Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY['Fondos en anillas','Fondos en paralelas','Hand Release Push Up','Ring Push Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Push Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Remo con dumbbell: codos atrás y omóplatos activos al final del tirón.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Renegade Row cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Renegade Row';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','forearm']::text[])>0 THEN ARRAY['biceps','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Renegade Row';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Reverse Hyper: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Reverse Hyper cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Reverse Hyper';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Reverse Hyper';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Ring Hamstring Curl: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Ring Hamstring Curl cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Ring Hamstring Curl';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Ring Hamstring Curl';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Variante de pino/HSPU (Ring Handstand Push Up): control de línea y bloqueo de codos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Ring Handstand Push Up cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Ring Handstand Push Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['HSPU','HSPU deficit','HSPU libre','Kipping Handstand Push Up','Parallette Handstand Push Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Ring Handstand Push Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Ring Lower: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Ring Lower cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Ring Lower';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps','forearm']::text[])>0 THEN ARRAY['biceps','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Ring Lower';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Flexión de brazos (Ring Push Up): pecho cerca del suelo y codos en extensión arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Ring Push Up cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Anillas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Ring Push Up';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Fondos en anillas','Fondos en paralelas','Hand Release Push Up','Push Up']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Anillas','') IS NOT NULL THEN ARRAY['Anillas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Ring Push Up';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Trabajo de tronco/hombros con peso corporal: control anti-rotación o movilidad cargada.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Russian Twist cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Russian Twist';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Russian Twist';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Sandbag Carry cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Saco',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Sandbag Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Bear Hug Carry','Double Kettlebell Farmers Carry','Dumbbell Carry','Farmer carry','Farmer walk','Log Carry','Suitcase Carry']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Saco','') IS NOT NULL THEN ARRAY['Saco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sandbag Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sandbag Ground To Shoulder: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Sandbag Ground To Shoulder cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Saco',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Sandbag Ground To Shoulder';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Saco','') IS NOT NULL THEN ARRAY['Saco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sandbag Ground To Shoulder';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sandbag Load To Box: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Sandbag Load To Box cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Saco',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Sandbag Load To Box';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Saco','') IS NOT NULL THEN ARRAY['Saco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sandbag Load To Box';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sandbag Over Log: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Sandbag Over Log cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Tronco',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Sandbag Over Log';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Tronco','') IS NOT NULL THEN ARRAY['Tronco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sandbag Over Log';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla con peso corporal: profundidad controlada y torso estable.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Sandbag Squat cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Saco',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Sandbag Squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Box Squat','Dumbbell Front Squat','Goblet squat','Sentadilla','Sentadilla frontal','Zercher Squat']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Saco','') IS NOT NULL THEN ARRAY['Saco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sandbag Squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Isométrico o control de tronco (Side Plank): línea estable sin compensar.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Side Plank cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Side Plank';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Side Plank';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Olímpico/híbrido con dumbbell: recepción estable y marca clara en cada rep.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Single Arm Dumbbell Thruster cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Single Arm Dumbbell Thruster';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Thruster','Kettlebell Thruster','Single Arm Kettlebell Thruster','Thruster']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Single Arm Dumbbell Thruster';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Balanceo de cadera con kettlebell; potencia desde la cadena posterior.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Single Arm Kettlebell Swing cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Single Arm Kettlebell Swing';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Kettlebell Swing']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Single Arm Kettlebell Swing';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Olímpico/híbrido con kettlebell: recepción estable y marca clara en cada rep.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Single Arm Kettlebell Thruster cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Kettlebell',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Single Arm Kettlebell Thruster';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Dumbbell Thruster','Kettlebell Thruster','Single Arm Dumbbell Thruster','Thruster']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Kettlebell','') IS NOT NULL THEN ARRAY['Kettlebell']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Single Arm Kettlebell Thruster';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Isométrico o control de tronco (Single Leg Glute Bridge): línea estable sin compensar.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Single Leg Glute Bridge cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Single Leg Glute Bridge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Single Leg Glute Bridge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto con barbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Single Leg Romanian Deadlift cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Single Leg Romanian Deadlift';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Single Leg Romanian Deadlift';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Salto pliométrico (Skater Jump): aterrizaje suave y cadera extendida.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Skater Jump cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Skater Jump';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Skater Jump';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sled Drag: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Sled Drag cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Trineo',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Sled Drag';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Trineo','') IS NOT NULL THEN ARRAY['Trineo']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sled Drag';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Odd-object o acondicionamiento (Sledgehammer Strike) con peso corporal; potencia y control.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Sledgehammer Strike cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Trineo',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Sledgehammer Strike';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Trineo','') IS NOT NULL THEN ARRAY['Trineo']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sledgehammer Strike';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto con barbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Stiff Legged Deadlift cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Stiff Legged Deadlift';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Stiff Legged Deadlift';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Strict Knee Raise: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Strict Knee Raise cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Strict Knee Raise';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Strict Knee Raise';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Strict Knees To Chest: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Strict Knees To Chest cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Strict Knees To Chest';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Strict Knees To Chest';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con dumbbell: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Suitcase Carry cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Mancuernas',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Suitcase Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY['Bear Hug Carry','Double Kettlebell Farmers Carry','Dumbbell Carry','Farmer carry','Farmer walk','Sandbag Carry']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Mancuernas','') IS NOT NULL THEN ARRAY['Mancuernas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Suitcase Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Isométrico o control de tronco (Superman): línea estable sin compensar.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Superman cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Superman';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Superman';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Odd-object o acondicionamiento (Tire Flip) con peso corporal; potencia y control.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Tire Flip cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Neumático',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Tire Flip';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Neumático','') IS NOT NULL THEN ARRAY['Neumático']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Tire Flip';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto con barbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Trap Bar Deadlift cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra hex',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Trap Bar Deadlift';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY['Deficit Deadlift','Dumbbell Deadlift','Dumbbell Romanian Deadlift','Kettlebell Deadlift','Peso muerto','Peso muerto rumano','Peso muerto sumo']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra hex','') IS NOT NULL THEN ARRAY['Barra hex']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Trap Bar Deadlift';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Salto pliométrico (Tuck Jump): aterrizaje suave y cadera extendida.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Tuck Jump cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Tuck Jump';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Tuck Jump';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Odd-object o acondicionamiento (Wall Climb) con peso corporal; potencia y control.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Wall Climb cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Wall Climb';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Wall Climb';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Odd-object o acondicionamiento (Wall Climb Over) con peso corporal; potencia y control.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Wall Climb Over cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Wall Climb Over';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Wall Climb Over';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Wall Sit: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Wall Sit cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Wall Sit';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Wall Sit';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Empuje con barbell hasta bloqueo overhead o extensión completa.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Z Press cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Z Press';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['deltoids','chest']::text[])>0 THEN ARRAY['deltoids','chest']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps','abs']::text[])>0 THEN ARRAY['triceps','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Z Press';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Porte o caminata con barbell: postura alta, núcleo firme y pasos cortos.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Zercher Carry cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Zercher Carry';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs','forearm']::text[])>0 THEN ARRAY['abs','forearm']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['trapezius','quadriceps']::text[])>0 THEN ARRAY['trapezius','quadriceps']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Zercher Carry';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Peso muerto con barbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Zercher Deadlift cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Zercher Deadlift';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','gluteal']::text[])>0 THEN ARRAY['hamstring','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back','forearm']::text[])>0 THEN ARRAY['upper-back','forearm']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Zercher Deadlift';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Sentadilla con barbell: profundidad controlada y torso estable.',
  mobile_instructions = ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.','Error típico: acortar el recorrido o perder la línea del tronco.','Inhala al preparar y exhala en el esfuerzo principal.','Progresión: sube carga o densidad solo si la técnica se mantiene limpia.','Estándar: cada repetición de Zercher Squat cumple el rango acordado.']::text[],
  mobile_equipment = NULLIF('Barra',''),
  mobile_sport_tag = NULLIF('CrossFit',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Zercher Squat';

UPDATE public.training_exercise_metadata SET
  skill_level = 'advanced',
  alternatives = ARRAY['Box Squat','Dumbbell Front Squat','Goblet squat','Sandbag Squat','Sentadilla','Sentadilla frontal']::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra','') IS NOT NULL THEN ARRAY['Barra']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Zercher Squat';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Burpee seguido de un salto horizontal con los dos pies. En HYROX se avanza una distancia total, no un número de repeticiones; controla la longitud del salto y la recepción.',
  mobile_instructions = ARRAY['Apoya las manos en el suelo, lleva las piernas atrás y desciende el pecho hasta tocar el suelo con control, sin dejar caer la zona lumbar.','Recoge los pies cerca de las manos y prepárate para impulsarte hacia delante. Evita dar pasos adicionales que alteren el estándar del movimiento.','Salta horizontalmente con ambos pies al mismo tiempo, aterrizando sobre ambos pies con rodillas flexionadas para amortiguar el impacto.','Sitúate tras la línea marcada y comprueba que tienes espacio libre para avanzar. Mantén los pies firmes antes de iniciar el primer burpee.','Repite la secuencia de burpee y salto hasta cubrir los metros prescritos. Comprueba que terminas la distancia señalada sin acortar el movimiento.','Error típico: saltar desde una posición inestable o redondear la espalda al levantarse. Si no dominas el impacto, progresa con burpees y saltos cortos.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('HYROX',''),
  mobile_body_part = NULLIF('full body',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Burpee Broad Jump';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['chest','abs']::text[])>0 THEN ARRAY['chest','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Burpee Broad Jump';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Zancadas caminando con un saco apoyado sobre los hombros. En HYROX se recorre una distancia acumulada, manteniendo alternancia de piernas, rodilla trasera al suelo y tronco estable.',
  mobile_instructions = ARRAY['Colócate erguido con el saco sobre los hombros, activa el abdomen e inicia una zancada hacia delante que te permita mantener el equilibrio y el talón delantero apoyado.','Desciende hasta que la rodilla trasera entre en contacto con el suelo de forma controlada. Mantén la rodilla delantera alineada con el pie.','Elige un saco apropiado y colócalo sobre los hombros con ambas manos sujetándolo de forma segura, evitando que se deslice durante el avance.','Extiende la cadera y la rodilla para avanzar, alternando la pierna de cada zancada y manteniendo el saco estable sobre los hombros.','Continúa hasta completar la distancia prescrita, sin intercambiar pasos incompletos por zancadas válidas. Exhala cuando vuelvas a levantarte.','Error típico: inclinarse en exceso o golpear el suelo con la rodilla. Si no puedes mantener la técnica, reduce la carga y practica sin saco.']::text[],
  mobile_equipment = NULLIF('Saco',''),
  mobile_sport_tag = NULLIF('HYROX',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Sandbag Lunges';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quadriceps','gluteal']::text[])>0 THEN ARRAY['quadriceps','gluteal']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstring','abs']::text[])>0 THEN ARRAY['hamstring','abs']::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Saco','') IS NOT NULL THEN ARRAY['Saco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sandbag Lunges';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Flexión cervical controlada sin resistencia. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Lleva la barbilla hacia el pecho sin levantar los hombros.','Vuelve despacio al centro.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Flexión cervical suave';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['traps']::text[])>0 THEN ARRAY['traps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Flexión cervical suave';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Extensión cervical en amplitud cómoda. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Eleva la mirada suavemente sin comprimir la nuca.','Regresa a neutro con control.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Extensión cervical suave';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['traps']::text[])>0 THEN ARRAY['traps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Extensión cervical suave';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotación activa de cuello. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Mira despacio por encima de un hombro.','Vuelve al centro y alterna sin rebotes.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Rotación cervical';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['traps']::text[])>0 THEN ARRAY['traps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rotación cervical';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Inclinación lateral de la cabeza. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Acerca una oreja al hombro sin elevarlo.','Alterna los lados despacio.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Inclinación lateral cervical';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['traps']::text[])>0 THEN ARRAY['traps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Inclinación lateral cervical';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Control de la posición de cabeza y cuello. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Desliza la barbilla hacia atrás sin bajar la mirada.','Suelta lentamente.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Retracción cervical';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['traps']::text[])>0 THEN ARRAY['traps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Retracción cervical';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Círculos controlados del cuello. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Dibuja un círculo pequeño y continuo.','Cambia el sentido sin forzar el rango.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:CARs de cuello';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['traps']::text[])>0 THEN ARRAY['traps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:CARs de cuello';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotación de hombros y escápulas. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Eleva hombros y llévalos hacia atrás y abajo.','Invierte el sentido con el tronco estable.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Círculos de hombros';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['delts']::text[])>0 THEN ARRAY['delts']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Círculos de hombros';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotación controlada completa de hombro. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Dibuja un círculo con brazo extendido y tronco quieto.','Alterna sentidos y lados lentamente.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:CARs de hombro';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['delts']::text[])>0 THEN ARRAY['delts']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:CARs de hombro';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad de hombro con agarre amplio. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Lleva la pica de delante hacia atrás por encima de la cabeza.','Abre el agarre cuanto necesites y evita forzar.','Antes de empezar, prepara Pica en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Pica',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Pasadas de hombros con pica';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['delts']::text[])>0 THEN ARRAY['delts']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pica','') IS NOT NULL THEN ARRAY['Pica']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Pasadas de hombros con pica';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Flexión de hombros con control escapular. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Apoya espalda y brazos en la pared.','Desliza los brazos arriba sin arquear lumbares.','Antes de empezar, prepara Pared en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Pared',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Deslizamientos en pared';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['delts']::text[])>0 THEN ARRAY['delts']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pared','') IS NOT NULL THEN ARRAY['Pared']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Deslizamientos en pared';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Apertura torácica y de hombros. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Coloca espalda contra la pared y codos flexionados.','Abre y eleva los brazos sin despegar la pelvis.','Antes de empezar, prepara Pared en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Pared',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Ángeles en pared';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['delts']::text[])>0 THEN ARRAY['delts']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pared','') IS NOT NULL THEN ARRAY['Pared']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Ángeles en pared';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotación externa activa de hombro. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Mantén el codo pegado al costado.','Gira el antebrazo hacia fuera sin mover el tronco.','Antes de empezar, prepara Banda elástica en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Banda elástica',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Rotación externa de hombro con banda';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['delts']::text[])>0 THEN ARRAY['delts']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Banda elástica','') IS NOT NULL THEN ARRAY['Banda elástica']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rotación externa de hombro con banda';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Trabajo suave de rotación interna. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Mueve el antebrazo hacia dentro con el codo estable.','Evita girar el tronco para compensar.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Rotación interna de hombro';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['delts']::text[])>0 THEN ARRAY['delts']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rotación interna de hombro';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Flexión de hombros y apertura dorsal. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Apoya los codos en un banco y desciende el pecho.','Mantén abdomen activo para proteger lumbares.','Antes de empezar, prepara Banco en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Banco',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Estiramiento de dorsal en banco';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Banco','') IS NOT NULL THEN ARRAY['Banco']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Estiramiento de dorsal en banco';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Apertura del pectoral y hombro anterior. Ejercicio de movilidad controlada para pecho. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Apoya el antebrazo en un marco.','Da un paso corto adelante sin provocar dolor.','Antes de empezar, prepara Marco de puerta en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Marco de puerta',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('chest',''),
  mobile_muscle_group = NULLIF('Pecho','')
WHERE catalog_key = 'catalog:Estiramiento pectoral en puerta';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['pectorals']::text[])>0 THEN ARRAY['pectorals']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Marco de puerta','') IS NOT NULL THEN ARRAY['Marco de puerta']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Estiramiento pectoral en puerta';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Apertura posterior de hombro. Ejercicio de movilidad controlada para hombros. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Lleva un brazo por delante del pecho.','Acércalo con el otro brazo sin subir el hombro.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('shoulders',''),
  mobile_muscle_group = NULLIF('Hombros','')
WHERE catalog_key = 'catalog:Estiramiento de hombro cruzado';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['delts']::text[])>0 THEN ARRAY['delts']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Estiramiento de hombro cruzado';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad de elevación escapular. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Sube los hombros sin inclinar el cuello.','Bájalos lentamente sin balanceos.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Elevaciones escapulares';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['traps']::text[])>0 THEN ARRAY['traps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Elevaciones escapulares';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Control escapular sin movimiento de brazos. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Separa los omóplatos empujando hacia delante.','Vuelve acercándolos sin arquear la espalda.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Protracción y retracción escapular';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper back']::text[])>0 THEN ARRAY['upper back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Protracción y retracción escapular';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Control de escápulas en plancha. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Mantén los codos extendidos.','Acerca y separa los omóplatos controlando el tronco.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Flexiones escapulares';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper back']::text[])>0 THEN ARRAY['upper back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Flexiones escapulares';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad de hombros con suspensión gradual. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Agarra una barra y transfiere peso poco a poco.','Sal de la posición de forma controlada.','Antes de empezar, prepara Barra de dominadas en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Colgado pasivo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Colgado pasivo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Control de escápulas en suspensión. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Desde el colgado activa los hombros alejándolos de las orejas.','Relaja parcialmente sin perder el agarre.','Antes de empezar, prepara Barra de dominadas en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Barra de dominadas',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Colgado activo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Barra de dominadas','') IS NOT NULL THEN ARRAY['Barra de dominadas']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Colgado activo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Flexión y extensión segmentaria de columna. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['En cuadrupedia redondea la espalda metiendo barbilla.','Invierte la curva despacio en un rango cómodo.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Gato-vaca';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['lower back']::text[])>0 THEN ARRAY['lower back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Gato-vaca';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotación dorsal manteniendo la pelvis. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Lleva una mano detrás de la cabeza.','Gira el codo hacia arriba sin mover las caderas.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Rotación torácica en cuadrupedia';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper back']::text[])>0 THEN ARRAY['upper back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rotación torácica en cuadrupedia';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotación torácica desde cuadrupedia. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Desliza un brazo por debajo del cuerpo.','Vuelve y abre el brazo hacia el techo.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Enhebrar la aguja';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper back']::text[])>0 THEN ARRAY['upper back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Enhebrar la aguja';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotación dorsal tumbado de lado. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Flexiona las rodillas y fija la pelvis.','Abre el brazo superior siguiendo la mano con la mirada.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Libro abierto';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper back']::text[])>0 THEN ARRAY['upper back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Libro abierto';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Extensión torácica sobre espuma. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Coloca el rodillo bajo la zona dorsal.','Extiende el tórax con cabeza apoyada en las manos.','Antes de empezar, prepara Rodillo en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Rodillo',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Extensión torácica con rodillo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper back']::text[])>0 THEN ARRAY['upper back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Rodillo','') IS NOT NULL THEN ARRAY['Rodillo']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Extensión torácica con rodillo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotación de tronco desde asiento. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Siéntate alto con pelvis fija.','Gira la caja torácica sin tirar del cuello.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Rotación torácica sentado';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper back']::text[])>0 THEN ARRAY['upper back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rotación torácica sentado';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotación dorsal asistida por referencia visual. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Sitúate de lado junto a una pared.','Abre el brazo siguiendo un arco sin arquear lumbares.','Antes de empezar, prepara Pared en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Pared',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Rotación torácica en pared';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper back']::text[])>0 THEN ARRAY['upper back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pared','') IS NOT NULL THEN ARRAY['Pared']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rotación torácica en pared';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Articulación progresiva de la columna. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Desciende vértebra a vértebra con rodillas suaves.','Vuelve lentamente a la posición erguida.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Flexión segmentaria de columna';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['lower back']::text[])>0 THEN ARRAY['lower back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Flexión segmentaria de columna';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Extensión lumbar moderada en apoyo. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Túmbate boca abajo y apoya antebrazos.','Eleva el pecho sin forzar la zona lumbar.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Postura de la esfinge';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['lower back']::text[])>0 THEN ARRAY['lower back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Postura de la esfinge';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Flexión de cadera y apertura dorsal. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Lleva la cadera hacia los talones.','Alarga los brazos mientras respiras tranquilo.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Postura del niño';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Postura del niño';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Apertura lateral de dorsales. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Desde la postura del niño camina las manos a un lado.','Mantén la pelvis atrás y alterna.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Postura del niño lateral';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['upper-back']::text[])>0 THEN ARRAY['upper-back']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Postura del niño lateral';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad de costado y tronco. Ejercicio de movilidad controlada para core. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Eleva un brazo e inclínate al lado contrario.','Evita girar el pecho y alterna.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Inclinación lateral de tronco';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Inclinación lateral de tronco';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotación controlada de cadera. Ejercicio de movilidad controlada para glúteos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Con apoyo estable eleva la rodilla y dibuja un círculo.','Evita que la pelvis gire.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:CARs de cadera';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['glutes']::text[])>0 THEN ARRAY['glutes']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:CARs de cadera';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotaciones internas y externas de cadera. Ejercicio de movilidad controlada para glúteos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Siéntate con rodillas a noventa grados.','Pasa ambas rodillas al otro lado sin impulso.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:90/90 de cadera';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['glutes']::text[])>0 THEN ARRAY['glutes']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:90/90 de cadera';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad de rotación externa de cadera. Ejercicio de movilidad controlada para glúteos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Coloca las piernas en 90/90.','Inclínate desde caderas hacia la espinilla delantera.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:90/90 con inclinación frontal';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['glutes']::text[])>0 THEN ARRAY['glutes']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:90/90 con inclinación frontal';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Control de rotación interna de cadera. Ejercicio de movilidad controlada para glúteos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Mantén el tronco vertical en 90/90.','Eleva ligeramente la rodilla trasera sin apoyarte en manos.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:90/90 con elevación de rodilla';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['glutes']::text[])>0 THEN ARRAY['glutes']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:90/90 con elevación de rodilla';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Apertura anterior de cadera en media rodilla. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Coloca una rodilla abajo y adelanta el otro pie.','Activa glúteo y lleva pelvis adelante suavemente.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Estiramiento del flexor de cadera';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Estiramiento del flexor de cadera';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Apertura del cuádriceps y flexor de cadera. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Apoya la espinilla posterior contra pared o banco.','Eleva el tronco manteniendo glúteo activo.','Antes de empezar, prepara Pared en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Pared',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Couch stretch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pared','') IS NOT NULL THEN ARRAY['Pared']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Couch stretch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Apertura de rotadores externos de cadera. Ejercicio de movilidad controlada para glúteos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Cruza un tobillo sobre la rodilla opuesta.','Acerca la pierna de apoyo al pecho.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Figura cuatro tumbado';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['glutes']::text[])>0 THEN ARRAY['glutes']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Figura cuatro tumbado';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotación externa de cadera en suelo. Ejercicio de movilidad controlada para glúteos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Lleva una pierna flexionada delante y la otra atrás.','Apoya el peso evitando molestias en la rodilla.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Postura de la paloma';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['glutes']::text[])>0 THEN ARRAY['glutes']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Postura de la paloma';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Apertura suave de aductores. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Apoya antebrazos con rodillas separadas.','Lleva caderas atrás sin perder estabilidad.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Frog stretch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['adductors']::text[])>0 THEN ARRAY['adductors']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Frog stretch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad dinámica de aductores. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Extiende una pierna lateral desde cuadrupedia.','Lleva caderas atrás y vuelve con control.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Rockback de aductores';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['adductors']::text[])>0 THEN ARRAY['adductors']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rockback de aductores';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Apertura de aductores desde el suelo. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Junta las plantas de los pies sentado.','Deja descender rodillas sin empujarlas.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Mariposa sentada';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['adductors']::text[])>0 THEN ARRAY['adductors']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Mariposa sentada';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad lateral de cadera y tobillos. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Flexiona una rodilla hacia un lado en posición amplia.','Alterna sin perder equilibrio.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Sentadilla Cossack de movilidad';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['adductors']::text[])>0 THEN ARRAY['adductors']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sentadilla Cossack de movilidad';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad combinada de tobillos caderas y rodillas. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Desciende a sentadilla profunda con talones apoyados.','Respira y separa ligeramente las rodillas.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Sentadilla profunda sostenida';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quads']::text[])>0 THEN ARRAY['quads']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sentadilla profunda sostenida';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Exploración controlada de sentadilla baja. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Desde abajo desplaza suavemente el peso entre pies.','Mantén rodillas alineadas y evita rebotes.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Sentadilla profunda con balanceo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quads']::text[])>0 THEN ARRAY['quads']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Sentadilla profunda con balanceo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Amplitud activa de flexión de cadera. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Con apoyo levanta una rodilla sin inclinar la espalda.','Baja lentamente y alterna.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Flexión activa de cadera de pie';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Flexión activa de cadera de pie';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Extensión de cadera con tronco estable. Ejercicio de movilidad controlada para glúteos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Lleva una pierna atrás con abdomen firme.','Vuelve sin arquear las lumbares.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Extensión activa de cadera de pie';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['glutes']::text[])>0 THEN ARRAY['glutes']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Extensión activa de cadera de pie';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Control específico de rotación interna de cadera. Ejercicio de movilidad controlada para glúteos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Siéntate con pies separados y rodillas flexionadas.','Deja caer una rodilla hacia dentro sin girar la pelvis.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Rotación interna de cadera sentado';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['glutes']::text[])>0 THEN ARRAY['glutes']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rotación interna de cadera sentado';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Dorsiflexión de tobillo con el talón apoyado. Ejercicio de movilidad controlada para gemelos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Coloca un pie delante de la pared.','Acerca la rodilla al muro sin levantar el talón.','Antes de empezar, prepara Pared en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Pared',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower legs',''),
  mobile_muscle_group = NULLIF('Gemelos','')
WHERE catalog_key = 'catalog:Rodilla a pared para tobillo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pared','') IS NOT NULL THEN ARRAY['Pared']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rodilla a pared para tobillo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad de dorsiflexión con banda suave. Ejercicio de movilidad controlada para gemelos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Ancla una banda alrededor del tobillo.','Lleva rodilla adelante conservando talón apoyado.','Antes de empezar, prepara Banda elástica en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Banda elástica',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower legs',''),
  mobile_muscle_group = NULLIF('Gemelos','')
WHERE catalog_key = 'catalog:Dorsiflexión de tobillo con banda';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Banda elástica','') IS NOT NULL THEN ARRAY['Banda elástica']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Dorsiflexión de tobillo con banda';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotaciones articulares libres de tobillo. Ejercicio de movilidad controlada para gemelos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Levanta el pie del suelo.','Dibuja círculos lentos en ambos sentidos.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower legs',''),
  mobile_muscle_group = NULLIF('Gemelos','')
WHERE catalog_key = 'catalog:Círculos de tobillo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Círculos de tobillo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Control de recorrido articular de tobillo. Ejercicio de movilidad controlada para gemelos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Dibuja un círculo lento con el pie.','Evita girar la pierna durante el movimiento.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower legs',''),
  mobile_muscle_group = NULLIF('Gemelos','')
WHERE catalog_key = 'catalog:CARs de tobillo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:CARs de tobillo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Amplitud activa de flexión plantar. Ejercicio de movilidad controlada para gemelos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Aleja los dedos de la tibia apuntando el pie.','Regresa lentamente.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower legs',''),
  mobile_muscle_group = NULLIF('Gemelos','')
WHERE catalog_key = 'catalog:Flexión plantar de tobillo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Flexión plantar de tobillo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad lateral del tobillo. Ejercicio de movilidad controlada para gemelos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Gira suavemente la planta hacia dentro.','Muévela luego hacia fuera sin girar la pierna.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower legs',''),
  mobile_muscle_group = NULLIF('Gemelos','')
WHERE catalog_key = 'catalog:Inversión y eversión de tobillo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Inversión y eversión de tobillo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Fortalecimiento ligero del rango de dorsiflexión. Ejercicio de movilidad controlada para gemelos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Apóyate en la pared con talones en suelo.','Eleva la punta de los pies y baja lento.','Antes de empezar, prepara Pared en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Pared',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower legs',''),
  mobile_muscle_group = NULLIF('Gemelos','')
WHERE catalog_key = 'catalog:Elevación de tibial anterior';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['tibialis']::text[])>0 THEN ARRAY['tibialis']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pared','') IS NOT NULL THEN ARRAY['Pared']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Elevación de tibial anterior';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad combinada de rodilla y tobillo. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['En zancada avanza rodilla sobre dedos del pie.','Vuelve sin despegar el talón.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Rodilla sobre dedos controlada';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quads']::text[])>0 THEN ARRAY['quads']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rodilla sobre dedos controlada';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Flexión activa de rodilla con apoyo. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Agárrate a soporte estable y lleva talón al glúteo.','Extiende lentamente.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Flexión de rodilla en apoyo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quads']::text[])>0 THEN ARRAY['quads']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Flexión de rodilla en apoyo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Apertura del muslo anterior. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Sujeta el empeine detrás del cuerpo.','Acerca el talón manteniendo pelvis neutra.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Estiramiento de cuádriceps de pie';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['quads']::text[])>0 THEN ARRAY['quads']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Estiramiento de cuádriceps de pie';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Apertura de gemelo con rodilla extendida. Ejercicio de movilidad controlada para gemelos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Apoya manos en pared y lleva pierna atrás.','Presiona talón hacia el suelo.','Antes de empezar, prepara Pared en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Pared',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower legs',''),
  mobile_muscle_group = NULLIF('Gemelos','')
WHERE catalog_key = 'catalog:Estiramiento de gemelo en pared';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pared','') IS NOT NULL THEN ARRAY['Pared']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Estiramiento de gemelo en pared';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad de tobillo con rodilla doblada. Ejercicio de movilidad controlada para gemelos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Flexiona la rodilla adelantada manteniendo talón apoyado.','Evita que el arco del pie colapse.','Antes de empezar, prepara Pared en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Pared',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower legs',''),
  mobile_muscle_group = NULLIF('Gemelos','')
WHERE catalog_key = 'catalog:Estiramiento de sóleo en pared';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['calves']::text[])>0 THEN ARRAY['calves']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pared','') IS NOT NULL THEN ARRAY['Pared']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Estiramiento de sóleo en pared';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Patrón de bisagra desde cadera. Ejercicio de movilidad controlada para isquios. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Empuja glúteos atrás con rodillas suaves.','Extiende caderas conservando columna neutra.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Bisagra de cadera sin carga';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstrings']::text[])>0 THEN ARRAY['hamstrings']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Bisagra de cadera sin carga';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad activa de cadena posterior. Ejercicio de movilidad controlada para isquios. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Estira una pierna delante con talón apoyado.','Lleva la cadera atrás y vuelve.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Estiramiento dinámico de isquios';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstrings']::text[])>0 THEN ARRAY['hamstrings']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Estiramiento dinámico de isquios';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movimiento neural suave sin buscar tensión intensa. Ejercicio de movilidad controlada para isquios. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Sentado extiende lentamente rodilla y mueve el tobillo.','Vuelve si aparecen molestias.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Deslizamiento neural suave';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstrings']::text[])>0 THEN ARRAY['hamstrings']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Deslizamiento neural suave';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Bisagra guiada con pica. Ejercicio de movilidad controlada para isquios. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Apoya pica en espalda y flexiona desde caderas.','Conserva contacto en cabeza espalda y sacro.','Antes de empezar, prepara Pica en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Pica',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Buenos días con pica';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstrings']::text[])>0 THEN ARRAY['hamstrings']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Pica','') IS NOT NULL THEN ARRAY['Pica']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Buenos días con pica';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Elevación asistida de pierna. Ejercicio de movilidad controlada para isquios. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Túmbate y coloca banda alrededor del pie.','Eleva la pierna manteniendo la pelvis apoyada.','Antes de empezar, prepara Banda elástica en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Banda elástica',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Estiramiento de isquios con banda';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstrings']::text[])>0 THEN ARRAY['hamstrings']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Banda elástica','') IS NOT NULL THEN ARRAY['Banda elástica']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Estiramiento de isquios con banda';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad de pantorrillas e isquios. Ejercicio de movilidad controlada para isquios. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Forma una V invertida apoyando manos y pies.','Flexiona alternativamente las rodillas.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Isquios','')
WHERE catalog_key = 'catalog:Perro boca abajo dinámico';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hamstrings']::text[])>0 THEN ARRAY['hamstrings']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Perro boca abajo dinámico';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad de extensión de muñeca con apoyo. Ejercicio de movilidad controlada para antebrazos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Apoya las palmas con dedos hacia delante.','Desplaza ligeramente hombros sobre manos.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower arms',''),
  mobile_muscle_group = NULLIF('Antebrazos','')
WHERE catalog_key = 'catalog:Movilidad de muñeca en extensión';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearms']::text[])>0 THEN ARRAY['forearms']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Movilidad de muñeca en extensión';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Flexión de muñeca sin carga intensa. Ejercicio de movilidad controlada para antebrazos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Extiende el brazo y lleva dedos hacia abajo.','Alterna sin forzar articulación.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower arms',''),
  mobile_muscle_group = NULLIF('Antebrazos','')
WHERE catalog_key = 'catalog:Movilidad de muñeca en flexión';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearms']::text[])>0 THEN ARRAY['forearms']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Movilidad de muñeca en flexión';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Circunducción de muñeca. Ejercicio de movilidad controlada para antebrazos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Deja los brazos quietos y cierra los puños.','Dibuja círculos en ambos sentidos.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower arms',''),
  mobile_muscle_group = NULLIF('Antebrazos','')
WHERE catalog_key = 'catalog:Círculos de muñecas';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearms']::text[])>0 THEN ARRAY['forearms']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Círculos de muñecas';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotación activa del antebrazo. Ejercicio de movilidad controlada para antebrazos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Flexiona un codo a noventa grados.','Gira palma arriba y abajo con hombro inmóvil.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower arms',''),
  mobile_muscle_group = NULLIF('Antebrazos','')
WHERE catalog_key = 'catalog:Pronación y supinación de antebrazo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['forearms']::text[])>0 THEN ARRAY['forearms']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Pronación y supinación de antebrazo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Recorrido activo de extensión de codo. Ejercicio de movilidad controlada para tríceps. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Flexiona el codo cerca del cuerpo.','Extiéndelo lentamente sin impulso.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower arms',''),
  mobile_muscle_group = NULLIF('Tríceps','')
WHERE catalog_key = 'catalog:Extensión controlada de codo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['triceps']::text[])>0 THEN ARRAY['triceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Extensión controlada de codo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Recorrido activo de flexión de codo. Ejercicio de movilidad controlada para bíceps. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Lleva la mano hacia el hombro sin elevarlo.','Extiende lento.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('lower arms',''),
  mobile_muscle_group = NULLIF('Bíceps','')
WHERE catalog_key = 'catalog:Flexión controlada de codo';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['biceps']::text[])>0 THEN ARRAY['biceps']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Flexión controlada de codo';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Secuencia global de zancada cadera y tórax. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Adopta una zancada larga con ambas manos en el suelo enmarcando el pie delantero, la pierna trasera extendida y la cadera baja.','Manteniendo la zancada, baja el codo del lado delantero hacia el empeine y hunde un poco más la cadera sin despegar el talón.','Rota el tronco y abre el brazo del lado delantero hacia el techo siguiendo la mano con la mirada; vuelve con control y alterna lados.','Empieza con una zancada cómoda y amplía el recorrido solo si mantienes la pelvis estable y puedes respirar sin tensión excesiva.','Inhala para preparar cada cambio de fase y exhala al hundir la cadera o rotar; evita rebotes y movimientos hechos por inercia.','Error típico: levantar la cadera, rotar el brazo sin mover el tronco o perder el apoyo de las manos. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: sostén cada fase unas respiraciones antes de rotar. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:World''s Greatest Stretch';

UPDATE public.training_exercise_metadata SET
  skill_level = 'intermediate',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:World''s Greatest Stretch';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad de cadera y rotación dorsal. Ejercicio de movilidad controlada para piernas. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Coloca el pie junto a la mano del mismo lado.','Abre el pecho y gira hacia la pierna adelantada.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Piernas','')
WHERE catalog_key = 'catalog:Zancada Spiderman con rotación';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['hip flexors']::text[])>0 THEN ARRAY['hip flexors']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Zancada Spiderman con rotación';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad posterior y hombros con apoyo dinámico. Ejercicio de movilidad controlada para core. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Desde de pie, flexiona el tronco hacia delante y apoya las manos en el suelo con las piernas casi extendidas.','Camina con las manos hacia delante hasta llegar a una plancha alta con el cuerpo en una sola línea y el abdomen firme.','Camina con los pies hacia las manos subiendo la cadera y vuelve a levantarte manteniendo las piernas largas.','Hazlo sobre una superficie estable y ajusta la distancia de las manos para no perder el equilibrio al caminar.','Inhala al flexionarte y exhala al caminar hacia la plancha; mueve las manos con pasos cortos y controlados, sin tirones.','Error típico: doblar en exceso las rodillas, dejar caer la cadera en la plancha o caminar con pasos bruscos. Ve más despacio antes que perder la alineación.','Progresión: empieza con medio recorrido y amplía cuando controles la plancha. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Inchworm';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Inchworm';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Movilidad de cadera y tronco sentado. Ejercicio de movilidad controlada para glúteos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Siéntate con rodillas abiertas y talones delante.','Gira el pecho alternando lados.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Bear sit con rotación';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['glutes']::text[])>0 THEN ARRAY['glutes']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Bear sit con rotación';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Control de extensión de cadera y columna. Ejercicio de movilidad controlada para glúteos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Túmbate con pies apoyados y eleva pelvis lentamente.','Desciende vértebra a vértebra.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Puente de glúteo articulado';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['glutes']::text[])>0 THEN ARRAY['glutes']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Puente de glúteo articulado';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Control costal con postura 90/90. Ejercicio de movilidad controlada para core. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Túmbate con rodillas y caderas a noventa grados.','Inspira abriendo costillas y exhala suavemente.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('waist',''),
  mobile_muscle_group = NULLIF('Core','')
WHERE catalog_key = 'catalog:Respiración diafragmática 90/90';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['abs']::text[])>0 THEN ARRAY['abs']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Respiración diafragmática 90/90';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Rotación lumbar suave con hombros estables. Ejercicio de movilidad controlada para espalda. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['Boca arriba deja caer las rodillas juntas a un lado.','Vuelve al centro y alterna.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('back',''),
  mobile_muscle_group = NULLIF('Espalda','')
WHERE catalog_key = 'catalog:Rotación de tronco tumbado';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['obliques']::text[])>0 THEN ARRAY['obliques']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rotación de tronco tumbado';

UPDATE public.business_exercise_catalog SET
  mobile_description = 'Coordinación de cadera y espalda. Ejercicio de movilidad controlada para glúteos. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.',
  mobile_instructions = ARRAY['En cuadrupedia lleva caderas hacia talones.','Vuelve adelante sin balanceos.','Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva.','Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia.','Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición.','Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio.']::text[],
  mobile_equipment = NULLIF('Peso corporal',''),
  mobile_sport_tag = NULLIF('Movilidad',''),
  mobile_body_part = NULLIF('upper legs',''),
  mobile_muscle_group = NULLIF('Glúteos','')
WHERE catalog_key = 'catalog:Rockback global en cuadrupedia';

UPDATE public.training_exercise_metadata SET
  skill_level = 'beginner',
  alternatives = ARRAY[]::text[],
  primary_muscles = CASE WHEN cardinality(COALESCE(primary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY['glutes']::text[])>0 THEN ARRAY['glutes']::text[] ELSE primary_muscles END,
  secondary_muscles = CASE WHEN cardinality(COALESCE(secondary_muscles,ARRAY[]::text[]))=0 AND cardinality(ARRAY[]::text[])>0 THEN ARRAY[]::text[] ELSE secondary_muscles END,
  equipment = CASE WHEN cardinality(COALESCE(equipment,ARRAY[]::text[]))=0 AND NULLIF('Peso corporal','') IS NOT NULL THEN ARRAY['Peso corporal']::text[] ELSE equipment END,
  metadata_source = COALESCE(metadata_source,'') || '+meta_complete_20261104',
  updated_at = now()
WHERE catalog_key = 'catalog:Rockback global en cuadrupedia';

