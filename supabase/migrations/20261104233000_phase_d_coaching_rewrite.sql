-- Phase D coaching rewrite: specific cómo hacerlo + muscles/equipment (2026-11-04)

UPDATE public.business_exercise_catalog
SET mobile_description = 'Piedra Atlas del suelo por encima del hombro hasta soltarla al otro lado.',
    mobile_instructions = ARRAY['Coloca la piedra entre los pies; cadera baja y lumbar neutra.','Abraza la piedra al torso y extiende cadera hasta de pie.','Pásala por encima de un hombro hasta que caiga claramente al otro lado.','Error típico: redondear la lumbar al arrancar o no completar el pase.','Exhala al pasar el hombro; controla el espacio alrededor.','Progresión: más peso. Alternativa: D-ball o sandbag over shoulder.','Estándar: cada rep pasa la piedra completamente sobre el hombro prescrito.']::text[],
    mobile_equipment = 'Piedra Atlas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Atlas Stone Over Shoulder' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal']::text[],
    secondary_muscles = ARRAY['upper-back','forearm','abs']::text[],
    equipment = ARRAY['Piedra Atlas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Atlas Stone Over Shoulder' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Peso muerto con axle (barra gruesa): bisagra, espalda neutra y bloqueo arriba.',
    mobile_instructions = ARRAY['Axle sobre el empeine; agarre firme (la barra gruesa exige más grip).','Pecho alto, lumbar neutra; empuja el suelo y extiende cadera hasta de pie.','Bloquea arriba sin hiperextender; baja con control.','Error típico: redondear la lumbar o perder el agarre a media subida.','Inhala y bracea antes de tirar; exhala al bloqueo.','Progresión: más peso o straps solo si el WOD lo permite.','Estándar: extensión completa de cadera y rodillas arriba.']::text[],
    mobile_equipment = 'Axle',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Axle Deadlift' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal']::text[],
    secondary_muscles = ARRAY['upper-back','forearm','abs']::text[],
    equipment = ARRAY['Axle']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Axle Deadlift' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Press overhead con axle desde rack de hombros hasta bloqueo.',
    mobile_instructions = ARRAY['Axle en rack frontal o detrás según el estándar.','Press o push press hasta bloquear codos overhead.','Cabeza a través; muñecas firmes sobre la barra gruesa.','Error típico: no completar lockout o arching excesivo.','Exhala al subir; baja a rack con control.','Progresión: más peso o strict press.','Estándar: bloqueo overhead estable en cada rep.']::text[],
    mobile_equipment = 'Axle',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Axle Press' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids']::text[],
    secondary_muscles = ARRAY['triceps','abs']::text[],
    equipment = ARRAY['Axle']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Axle Press' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Zancada con barra en espalda.',
    mobile_instructions = ARRAY['Barra en trapecios; torso erguido.','Baja o sube con la rodilla delante alineada al pie; controla el tronco.','Extiende la pierna de apoyo por completo en la parte alta.','Error típico: empujar con la pierna de atrás o dejar colapsar la rodilla.','Exhala al extender; alterna piernas según el WOD.','Progresión: más carga o caja más alta.','Estándar: rango completo y control en cada zancada/step.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Back Rack Lunge' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','gluteal']::text[],
    secondary_muscles = ARRAY['hamstring','abs']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Back Rack Lunge' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Sentadilla con barra seguida de salto vertical (carga ligera).',
    mobile_instructions = ARRAY['Barra en espalda con carga moderada; pies al ancho de hombros.','Baja en sentadilla y salta extendiendo cadera y tobillos.','Aterriza suave y absorbe con las rodillas antes de la siguiente.','Error típico: carga excesiva o aterrizaje rígido.','Exhala en el salto; mantén el pecho alto.','Progresión: más altura de salto o jumping squat sin barra.','Estándar: extensión completa en el aire y recepción controlada.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Barbell Squat Jump' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','gluteal']::text[],
    secondary_muscles = ARRAY['calves','abs']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Barbell Squat Jump' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Step-up al cajón con barra en espalda.',
    mobile_instructions = ARRAY['Barra en espalda; un pie completo sobre el cajón.','Baja o sube con la rodilla delante alineada al pie; controla el tronco.','Extiende la pierna de apoyo por completo en la parte alta.','Error típico: empujar con la pierna de atrás o dejar colapsar la rodilla.','Exhala al extender; alterna piernas según el WOD.','Progresión: más carga o caja más alta.','Estándar: rango completo y control en cada zancada/step.']::text[],
    mobile_equipment = 'Barra, Cajón',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Barbell Step Up' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','gluteal']::text[],
    secondary_muscles = ARRAY['hamstring','abs']::text[],
    equipment = ARRAY['Barra, Cajón']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Barbell Step Up' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Ondas, slams o patrones con cuerda de batalla por tiempo o reps.',
    mobile_instructions = ARRAY['Pies firmes, rodillas semiflexionadas y torso estable; agarra ambos extremos.','Genera ondas alternas, dobles o slams según lo prescrito.','Mantén la amplitud de la cuerda; no te quedes corto de recorrido.','Error típico: encorvar la espalda o mover solo las muñecas.','Respira en ritmo con las ondas; no aguantes la respiración.','Progresión: más tiempo, más densidad o cuerda más pesada.','Estándar: el patrón prescrito se mantiene durante todo el intervalo.']::text[],
    mobile_equipment = 'Cuerda de batalla',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Battle Rope' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids','abs']::text[],
    secondary_muscles = ARRAY['forearm','upper-back','quadriceps']::text[],
    equipment = ARRAY['Cuerda de batalla']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Battle Rope' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Cuadrupedia: extiende brazo y pierna contrarios con pelvis estable.',
    mobile_instructions = ARRAY['A cuatro patas; columna neutra.','Extiende brazo y pierna opuestos sin rotar la cadera.','Vuelve y alterna.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Bird Dog mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'waist',
    mobile_muscle_group = 'Core'
WHERE name = 'Bird Dog' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs']::text[],
    secondary_muscles = ARRAY['obliques']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Bird Dog' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Simulación de clean & jerk a peso corporal (técnica / calentamiento).',
    mobile_instructions = ARRAY['Desde «suelo» imaginario, carga a rack sin peso.','Dip y jerk a overhead con bloqueo de brazos.','Enfócate en timing de piernas y recepción.','Error típico: pressear sin extensión de cadera o no marcar el bloqueo.','Exhala en el tirón/envión principal.','Progresión: añade mancuernas/barra cuando la técnica sea limpia.','Estándar: cada fase de Bodyweight Clean And Jerk queda marcada antes de seguir.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Bodyweight Clean And Jerk' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','deltoids']::text[],
    secondary_muscles = ARRAY['gluteal','trapezius','abs']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Bodyweight Clean And Jerk' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Press Bradford: barra pasa de delante a detrás de la cabeza en arcos cortos.',
    mobile_instructions = ARRAY['Barra a la altura de la frente/clavícula; agarre algo más ancho.','Sube la barra solo lo necesario para pasarla por encima de la cabeza.','Alterna rack frontal y detrás de la nuca sin lockout completo.','Error típico: bajar demasiado detrás de la nuca o usar peso excesivo.','Movimiento continuo y controlado; no rebotes en los hombros.','Progresión: más reps o peso ligero-moderado.','Estándar: cada paso delante↔detrás cuenta según el esquema del WOD.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Bradford Press' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids']::text[],
    secondary_muscles = ARRAY['triceps','trapezius']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Bradford Press' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Burpee + muscle-up a barra.',
    mobile_instructions = ARRAY['Pecho y muslos al suelo (o estándar del WOD) en la parte baja.','Tras el burpee, salta a la barra y completa el muscle-up.','Extiende cadera arriba; marca el lockout o el cruce del obstáculo.','Error típico: no tocar el suelo con el pecho o acortar el muscle-up/cruce.','Exhala en el esfuerzo principal (salto, tirón o deadlift).','Progresión: más densidad. Escala a burpee + pull-up si hace falta.','Estándar: pecho abajo y final completo de Burpee Bar Muscle Up en cada rep.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Cardio'
WHERE name = 'Burpee Bar Muscle Up' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['chest','quadriceps']::text[],
    secondary_muscles = ARRAY['upper-back','abs','deltoids']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Burpee Bar Muscle Up' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Burpee y salto lateral sobre la mancuerna.',
    mobile_instructions = ARRAY['Pecho y muslos al suelo (o estándar del WOD) en la parte baja.','Tras pecho al suelo, salta lateralmente sobre la mancuerna.','Extiende cadera arriba; marca el lockout o el cruce del obstáculo.','Error típico: no tocar el suelo con el pecho o acortar el muscle-up/cruce.','Exhala en el esfuerzo principal (salto, tirón o deadlift).','Progresión: más densidad. Escala a burpee + pull-up si hace falta.','Estándar: pecho abajo y final completo de Burpee Over Dumbbell en cada rep.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Cardio'
WHERE name = 'Burpee Over Dumbbell' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['chest','quadriceps']::text[],
    secondary_muscles = ARRAY['upper-back','abs','deltoids']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Burpee Over Dumbbell' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Burpee y paso/salto sobre la barra en el suelo.',
    mobile_instructions = ARRAY['Pecho y muslos al suelo (o estándar del WOD) en la parte baja.','Tras el burpee, cruza la barra al otro lado.','Extiende cadera arriba; marca el lockout o el cruce del obstáculo.','Error típico: no tocar el suelo con el pecho o acortar el muscle-up/cruce.','Exhala en el esfuerzo principal (salto, tirón o deadlift).','Progresión: más densidad. Escala a burpee + pull-up si hace falta.','Estándar: pecho abajo y final completo de Burpee Over The Bar en cada rep.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Cardio'
WHERE name = 'Burpee Over The Bar' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['chest','quadriceps']::text[],
    secondary_muscles = ARRAY['upper-back','abs','deltoids']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Burpee Over The Bar' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Plancha lateral con apoyo de pierna superior en banco (aductores).',
    mobile_instructions = ARRAY['Antebrazo en el suelo; pierna de arriba en banco.','Eleva cadera; pierna inferior puede colgar o apoyar según nivel.','Mantén el cuerpo alineado; cambia de lado.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Copenhagen Plank mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'waist',
    mobile_muscle_group = 'Core'
WHERE name = 'Copenhagen Plank' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs']::text[],
    secondary_muscles = ARRAY['obliques']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Copenhagen Plank' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Desplazamiento en posición de cangrejo (cadera alta).',
    mobile_instructions = ARRAY['Sentado; manos detrás y pies apoyados; eleva cadera.','Camina delante/atrás o lateral manteniendo cadera alta.','No dejes caer la pelvis.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Crab Walk mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Glúteos'
WHERE name = 'Crab Walk' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['gluteal','triceps']::text[],
    secondary_muscles = ARRAY['abs']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Crab Walk' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Comba: simple con cruce de brazos (crossover).',
    mobile_instructions = ARRAY['Salta a ritmo de single-under.','Cruza los brazos delante del cuerpo y descruza entre saltos.','Mantén saltos bajos y muñecas activas.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Crossover Single Under mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Cardio'
WHERE name = 'Crossover Single Under' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['calves','deltoids']::text[],
    secondary_muscles = ARRAY['abs']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Crossover Single Under' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Boca arriba: brazo y pierna contrarios con lumbar pegada al suelo.',
    mobile_instructions = ARRAY['Boca arriba, brazos arriba y rodillas a 90°.','Extiende un brazo y la pierna opuesta sin arching lumbar.','Vuelve y alterna.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Dead Bug mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'waist',
    mobile_muscle_group = 'Core'
WHERE name = 'Dead Bug' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs']::text[],
    secondary_muscles = ARRAY['obliques']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dead Bug' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Peso muerto de pie sobre un deficit (discos/plataforma) para más rango.',
    mobile_instructions = ARRAY['Colócate sobre el deficit estable; barra sobre el empeine.','Bisagra con lumbar neutra; el rango es mayor — no redondees.','Extiende hasta de pie y baja con control hasta el suelo.','Error típico: cortar profundidad del deficit o redondear al inicio.','Inhala y bracea; exhala al bloqueo.','Progresión: más peso o más altura de deficit (con técnica).','Estándar: placas tocan el suelo y extensión completa arriba.']::text[],
    mobile_equipment = 'Barra, Deficit',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Deficit Deadlift' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal']::text[],
    secondary_muscles = ARRAY['upper-back','forearm','abs']::text[],
    equipment = ARRAY['Barra, Deficit']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Deficit Deadlift' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Caminata con una KB en cada mano; pasos cortos y torso estable.',
    mobile_instructions = ARRAY['Carga el implemento (Kettlebell) a la posición prescrita.','Camina erguido con pasos cortos; no dejes que la carga se deslice.','Mantén hombros activos y core firme durante todo el tramo.','Error típico: inclinarte en exceso o depositar la carga antes de la marca.','Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.','Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.','Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.']::text[],
    mobile_equipment = 'Kettlebell',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Double Kettlebell Farmers Carry' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','forearm','upper-back']::text[],
    equipment = ARRAY['Kettlebell']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Double Kettlebell Farmers Carry' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Zancada con dos KB en front rack.',
    mobile_instructions = ARRAY['Dos KB en rack; torso compacto.','Baja o sube con la rodilla delante alineada al pie; controla el tronco.','Extiende la pierna de apoyo por completo en la parte alta.','Error típico: empujar con la pierna de atrás o dejar colapsar la rodilla.','Exhala al extender; alterna piernas según el WOD.','Progresión: más carga o caja más alta.','Estándar: rango completo y control en cada zancada/step.']::text[],
    mobile_equipment = 'Kettlebell',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Double Kettlebell Front Rack Lunge' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','gluteal']::text[],
    secondary_muscles = ARRAY['hamstring','abs']::text[],
    equipment = ARRAY['Kettlebell']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Double Kettlebell Front Rack Lunge' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Press banca con mancuernas: baja a pecho y extiende arriba.',
    mobile_instructions = ARRAY['Túmbate en banco con una mancuerna en cada mano sobre el pecho.','Baja con control hasta cerca del pecho; codos ~45°.','Empuja hasta extender sin chocar las mancuernas con violencia.','Error típico: arching excesivo o no completar el lockout.','Exhala al empujar; core firme.','Progresión: más peso o tempo. Alternativa: press con barra.','Estándar: extensión completa arriba en cada rep.']::text[],
    mobile_equipment = 'Mancuernas, Banco',
    mobile_body_part = 'chest',
    mobile_muscle_group = 'Pecho'
WHERE name = 'Dumbbell Bench Press' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['chest','triceps']::text[],
    secondary_muscles = ARRAY['deltoids']::text[],
    equipment = ARRAY['Mancuernas, Banco']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Bench Press' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Step-up al cajón con mancuernas.',
    mobile_instructions = ARRAY['Mancuernas a los lados o en rack; pie completo en el cajón.','Baja o sube con la rodilla delante alineada al pie; controla el tronco.','Extiende la pierna de apoyo por completo en la parte alta.','Error típico: empujar con la pierna de atrás o dejar colapsar la rodilla.','Exhala al extender; alterna piernas según el WOD.','Progresión: más carga o caja más alta.','Estándar: rango completo y control en cada zancada/step.']::text[],
    mobile_equipment = 'Mancuernas, Cajón',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Dumbbell Box Step Up' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','gluteal']::text[],
    secondary_muscles = ARRAY['hamstring','abs']::text[],
    equipment = ARRAY['Mancuernas, Cajón']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Box Step Up' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Burpee agarrando mancuernas + peso muerto al subir.',
    mobile_instructions = ARRAY['Pecho y muslos al suelo (o estándar del WOD) en la parte baja.','Manos en mancuernas; pecho abajo, luego deadlift a de pie.','Extiende cadera arriba; marca el lockout o el cruce del obstáculo.','Error típico: no tocar el suelo con el pecho o acortar el muscle-up/cruce.','Exhala en el esfuerzo principal (salto, tirón o deadlift).','Progresión: más densidad. Escala a burpee + pull-up si hace falta.','Estándar: pecho abajo y final completo de Dumbbell Burpee Deadlift en cada rep.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Cardio'
WHERE name = 'Dumbbell Burpee Deadlift' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['chest','quadriceps']::text[],
    secondary_muscles = ARRAY['upper-back','abs','deltoids']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Burpee Deadlift' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Caminata con una o dos mancuernas; pasos cortos y torso estable.',
    mobile_instructions = ARRAY['Carga el implemento (Mancuernas) a la posición prescrita.','Camina erguido con pasos cortos; no dejes que la carga se deslice.','Mantén hombros activos y core firme durante todo el tramo.','Error típico: inclinarte en exceso o depositar la carga antes de la marca.','Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.','Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.','Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Dumbbell Carry' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','forearm','upper-back']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Carry' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Peso muerto con mancuernas a los lados o delante.',
    mobile_instructions = ARRAY['Mancuernas fuera de los pies o delante; bisagra con lumbar neutra.','Extiende cadera y rodillas hasta de pie; mancuernas rozan las piernas.','Baja con control hasta tocar el suelo o la altura prescrita.','Error típico: redondear la lumbar o rotar la cadera.','Exhala al extender la cadera.','Progresión: más carga o más rango controlado.','Estándar: bisagra limpia y extensión completa arriba.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Dumbbell Deadlift' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal']::text[],
    secondary_muscles = ARRAY['abs','upper-back']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Deadlift' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Press de suelo con mancuernas: tríceps al suelo y lockout.',
    mobile_instructions = ARRAY['Túmbate en el suelo con mancuernas sobre el pecho.','Baja hasta que tríceps toquen el suelo; pausa breve.','Empuja hasta extender los codos.','Error típico: arching excesivo o no completar el lockout.','Exhala al empujar; core firme.','Progresión: más peso o tempo. Alternativa: press con barra.','Estándar: extensión completa arriba en cada rep.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'chest',
    mobile_muscle_group = 'Pecho'
WHERE name = 'Dumbbell Floor Press' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['chest','triceps']::text[],
    secondary_muscles = ARRAY['deltoids']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Floor Press' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Cargada desde hang + envío a overhead (press/jerk).',
    mobile_instructions = ARRAY['Hang clean a rack.','De rack a overhead por press, push press o jerk.','Bloquea arriba antes de bajar.','Error típico: pressear sin extensión de cadera o no marcar el bloqueo.','Exhala en el tirón/envión principal.','Progresión: añade mancuernas/barra cuando la técnica sea limpia.','Estándar: cada fase de Dumbbell Hang Clean To Overhead queda marcada antes de seguir.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Dumbbell Hang Clean To Overhead' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','deltoids']::text[],
    secondary_muscles = ARRAY['gluteal','trapezius','abs']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Hang Clean To Overhead' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Cargada de potencia con mancuernas desde hang (sin sentadilla profunda).',
    mobile_instructions = ARRAY['Mancuernas a mitad de muslo; bisagra corta.','Extiende cadera y recibe en rack parcial (power).','Baja a hang y repite.','Error típico: pressear sin extensión de cadera o no marcar el bloqueo.','Exhala en el tirón/envión principal.','Progresión: añade mancuernas/barra cuando la técnica sea limpia.','Estándar: cada fase de Dumbbell Hang Power Clean queda marcada antes de seguir.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Dumbbell Hang Power Clean' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','deltoids']::text[],
    secondary_muscles = ARRAY['gluteal','trapezius','abs']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Hang Power Clean' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Arrancada desde hang con mancuernas recibiendo en split.',
    mobile_instructions = ARRAY['Desde hang, tirón y recibe overhead en split.','Bloquea codos; recupera pies.','Baja a hang o hombros según el WOD.','Error típico: pressear sin extensión de cadera o no marcar el bloqueo.','Exhala en el tirón/envión principal.','Progresión: añade mancuernas/barra cuando la técnica sea limpia.','Estándar: cada fase de Dumbbell Hang Split Snatch queda marcada antes de seguir.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Dumbbell Hang Split Snatch' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','deltoids']::text[],
    secondary_muscles = ARRAY['gluteal','trapezius','abs']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Hang Split Snatch' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Cargada completa con mancuernas desde hang a sentadilla.',
    mobile_instructions = ARRAY['Desde hang, extiende y recibe en front rack bajo.','Sentadilla profunda con mancuernas en hombros; sube a de pie.','Vuelve a hang para la siguiente.','Error típico: pressear sin extensión de cadera o no marcar el bloqueo.','Exhala en el tirón/envión principal.','Progresión: añade mancuernas/barra cuando la técnica sea limpia.','Estándar: cada fase de Dumbbell Hang Squat Clean queda marcada antes de seguir.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Dumbbell Hang Squat Clean' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','deltoids']::text[],
    secondary_muscles = ARRAY['gluteal','trapezius','abs']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Hang Squat Clean' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Caminata con mancuerna(s) bloqueada(s) overhead; pasos cortos y torso estable.',
    mobile_instructions = ARRAY['Carga el implemento (Mancuernas) a la posición prescrita.','Camina erguido con pasos cortos; no dejes que la carga se deslice.','Mantén hombros activos y core firme durante todo el tramo.','Error típico: inclinarte en exceso o depositar la carga antes de la marca.','Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.','Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.','Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Dumbbell Overhead Carry' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','forearm','upper-back']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Overhead Carry' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'RDL con mancuernas: bisagra y estiramiento de isquios.',
    mobile_instructions = ARRAY['De pie con mancuernas delante de los muslos; suave flexión de rodilla.','Cadera atrás; baja hasta sentir isquios con espalda neutra.','Extiende cadera hasta de pie sin hiperextender.','Error típico: redondear la lumbar o rotar la cadera.','Exhala al extender la cadera.','Progresión: más carga o más rango controlado.','Estándar: bisagra limpia y extensión completa arriba.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Dumbbell Romanian Deadlift' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal']::text[],
    secondary_muscles = ARRAY['abs','upper-back']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Romanian Deadlift' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Press de hombros con mancuernas hasta bloqueo overhead.',
    mobile_instructions = ARRAY['Mancuernas a la altura de las orejas, muñecas firmes.','Empuja overhead hasta extender; no choques las mancuernas.','Baja con control a la altura de las orejas.','Error típico: arching excesivo o no completar el lockout.','Exhala al empujar; core firme.','Progresión: más peso o tempo. Alternativa: press con barra.','Estándar: extensión completa arriba en cada rep.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Dumbbell Shoulder Press' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids']::text[],
    secondary_muscles = ARRAY['triceps','abs']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Shoulder Press' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'De hombros a overhead con mancuernas (press, push press o jerk).',
    mobile_instructions = ARRAY['Mancuernas en rack frontal.','Llévalas overhead por cualquier forma legal (press/push press/jerk).','Bloquea arriba antes de bajar a hombros.','Error típico: arching excesivo o no completar el lockout.','Exhala al empujar; core firme.','Progresión: más peso o tempo. Alternativa: press con barra.','Estándar: extensión completa arriba en cada rep.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Dumbbell Shoulder To Overhead' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids']::text[],
    secondary_muscles = ARRAY['triceps','abs']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Shoulder To Overhead' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Cargada con mancuernas recibiendo en split (tijera).',
    mobile_instructions = ARRAY['Desde suelo o hang, extiende y recibe en split.','Recupera pies a paralelo con mancuernas en rack.','Repite alternando pierna si se prescribe.','Error típico: pressear sin extensión de cadera o no marcar el bloqueo.','Exhala en el tirón/envión principal.','Progresión: añade mancuernas/barra cuando la técnica sea limpia.','Estándar: cada fase de Dumbbell Split Clean queda marcada antes de seguir.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Dumbbell Split Clean' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','deltoids']::text[],
    secondary_muscles = ARRAY['gluteal','trapezius','abs']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Split Clean' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Cargada completa con mancuernas desde el suelo a sentadilla.',
    mobile_instructions = ARRAY['Desde el suelo, carga a rack y recibe en sentadilla.','Sube a de pie con mancuernas en hombros.','Baja al suelo para la siguiente rep.','Error típico: pressear sin extensión de cadera o no marcar el bloqueo.','Exhala en el tirón/envión principal.','Progresión: añade mancuernas/barra cuando la técnica sea limpia.','Estándar: cada fase de Dumbbell Squat Clean queda marcada antes de seguir.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Dumbbell Squat Clean' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','deltoids']::text[],
    secondary_muscles = ARRAY['gluteal','trapezius','abs']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Squat Clean' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Squat clean con mancuernas + thruster en continuidad.',
    mobile_instructions = ARRAY['Carga a sentadilla y, al subir, press overhead (thruster).','Bloquea arriba; baja a rack/hang según el esquema.','No separes clean y thruster si el WOD pide complejo continuo.','Error típico: pressear sin extensión de cadera o no marcar el bloqueo.','Exhala en el tirón/envión principal.','Progresión: añade mancuernas/barra cuando la técnica sea limpia.','Estándar: cada fase de Dumbbell Squat Clean Thruster queda marcada antes de seguir.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Dumbbell Squat Clean Thruster' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','deltoids']::text[],
    secondary_muscles = ARRAY['gluteal','trapezius','abs']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Squat Clean Thruster' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Press estricto con mancuernas: sin impulso de piernas.',
    mobile_instructions = ARRAY['Mancuernas en rack; glúteos y piernas quietos.','Press solo de hombro/tríceps hasta bloqueo.','Si usas dip de piernas, ya no es estricto.','Error típico: arching excesivo o no completar el lockout.','Exhala al empujar; core firme.','Progresión: más peso o tempo. Alternativa: press con barra.','Estándar: extensión completa arriba en cada rep.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Dumbbell Strict Press' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids']::text[],
    secondary_muscles = ARRAY['triceps','abs']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Strict Press' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Caminata con mancuerna en waiter (palm up overhead); pasos cortos y torso estable.',
    mobile_instructions = ARRAY['Carga el implemento (Mancuernas) a la posición prescrita.','Camina erguido con pasos cortos; no dejes que la carga se deslice.','Mantén hombros activos y core firme durante todo el tramo.','Error típico: inclinarte en exceso o depositar la carga antes de la marca.','Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.','Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.','Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Dumbbell Waiters Walk' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','forearm','upper-back']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Waiters Walk' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Press de banca en el suelo: rango corto y control de codos.',
    mobile_instructions = ARRAY['Túmbate en el suelo con barra o mancuernas sobre el pecho.','Baja hasta que tríceps toquen el suelo; pausa breve.','Empuja hasta extender los codos sin rebotar.','Error típico: rebotar los codos o abrirlos en exceso.','Exhala al empujar; omóplatos estables.','Progresión: más peso. Alternativa: press banca o dumbbell floor press.','Estándar: tríceps al suelo y lockout completo arriba.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'chest',
    mobile_muscle_group = 'Pecho'
WHERE name = 'Floor Press' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['chest','triceps']::text[],
    secondary_muscles = ARRAY['deltoids']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Floor Press' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Patada de flutter boca arriba con lumbar controlada.',
    mobile_instructions = ARRAY['Boca arriba; cabeza y hombros ligeramente elevados si se prescribe.','Patadas cortas alternas con piernas extendidas.','No dejes que la lumbar se separe del suelo.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Flutter Kick mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'waist',
    mobile_muscle_group = 'Core'
WHERE name = 'Flutter Kick' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs']::text[],
    secondary_muscles = ARRAY['obliques']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Flutter Kick' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Puente de glúteos boca arriba.',
    mobile_instructions = ARRAY['Boca arriba, pies cerca de glúteos.','Extiende cadera hasta línea hombros-rodillas; aprieta glúteos.','Baja sin perder el contacto de los pies.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Glute Bridge mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Glúteos'
WHERE name = 'Glute Bridge' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['gluteal']::text[],
    secondary_muscles = ARRAY['abs']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Glute Bridge' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'GHR: extensión de rodilla/cadera en banco GHD para isquios y glúteos.',
    mobile_instructions = ARRAY['Ajusta el GHD; rodillas en el pad y tobillos seguros.','Baja el torso con control y vuelve extendiendo rodillas/cadera.','Mantén una línea limpia; evita hiperextender la lumbar.','Error típico: usar impulso de brazos o acortar el rango.','Exhala al subir.','Progresión: más rango o lastre. Escala a nordic asistido.','Estándar: rango completo controlado en cada rep.']::text[],
    mobile_equipment = 'GHD',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Glute Ham Raise' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal']::text[],
    secondary_muscles = ARRAY['calves','abs']::text[],
    equipment = ARRAY['GHD']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Glute Ham Raise' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Flexión con despegue de manos del suelo abajo del todo.',
    mobile_instructions = ARRAY['Plancha; baja hasta pecho y muslos al suelo.','Levanta ambas manos claramente del suelo.','Vuelve a colocar las manos y empuja hasta lockout.','Error típico: no despegar las manos o no extender arriba.','Exhala al empujar.','Progresión: más reps. Escala a push-up clásico.','Estándar: pecho abajo, manos libres y extensión completa arriba.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'chest',
    mobile_muscle_group = 'Pecho'
WHERE name = 'Hand Release Push Up' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['chest']::text[],
    secondary_muscles = ARRAY['triceps','deltoids','abs']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hand Release Push Up' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Tirón alto desde hang con barra o DB hasta cerca del pecho.',
    mobile_instructions = ARRAY['Desde hang, extiende cadera y tira codos altos.','La barra/DB llega alto sin recibir en squat.','Baja a hang con control.','Error típico: pressear sin extensión de cadera o no marcar el bloqueo.','Exhala en el tirón/envión principal.','Progresión: añade mancuernas/barra cuando la técnica sea limpia.','Estándar: cada fase de Hang High Pull queda marcada antes de seguir.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Hang High Pull' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','deltoids']::text[],
    secondary_muscles = ARRAY['gluteal','trapezius','abs']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hang High Pull' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Colgado, toque de mano a cadera/ilíaco (estándar de algunos WODs).',
    mobile_instructions = ARRAY['Cuelga activo de la barra.','Lleva una o ambas manos a tocar la cadera/ilíaco según el WOD.','Vuelve a colgar de la barra sin caer.','Error típico: no hacer contacto claro o soltar ambos agarres a la vez sin control.','Mantén el cuerpo quieto; evita balanceo excesivo.','Progresión: más toques seguidos.','Estándar: contacto claro mano-cadera en cada rep.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'waist',
    mobile_muscle_group = 'Core'
WHERE name = 'Hanging Hip Touch' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs']::text[],
    secondary_muscles = ARRAY['forearm','deltoids']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hanging Hip Touch' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Elevación de rodillas colgado de la barra hasta arriba del ombligo/pecho.',
    mobile_instructions = ARRAY['Cuelga activo (hombros abajo) de la barra.','Lleva las rodillas arriba sin balanceo excesivo.','Baja con control a piernas extendidas.','Error típico: kip descontrolado o no subir las rodillas lo suficiente.','Exhala al subir.','Progresión: toes to bar o strict knees to chest.','Estándar: rodillas a la altura prescrita en cada rep.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'waist',
    mobile_muscle_group = 'Core'
WHERE name = 'Hanging Knee Raise' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs']::text[],
    secondary_muscles = ARRAY['forearm']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hanging Knee Raise' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Caminata con piedra Husafell o réplica al pecho; pasos cortos y torso estable.',
    mobile_instructions = ARRAY['Carga el implemento (Husafell / réplica) a la posición prescrita.','Camina erguido con pasos cortos; no dejes que la carga se deslice.','Mantén hombros activos y core firme durante todo el tramo.','Error típico: inclinarte en exceso o depositar la carga antes de la marca.','Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.','Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.','Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.']::text[],
    mobile_equipment = 'Husafell / réplica',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Husafell Carry' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','forearm','upper-back']::text[],
    equipment = ARRAY['Husafell / réplica']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Husafell Carry' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Curl de Jefferson: flexión vertebral segmentada con carga ligera.',
    mobile_instructions = ARRAY['De pie con carga ligera; pies juntos o semijuntos.','Flexiona vértebra a vértebra hacia delante hasta el rango cómodo.','Enróllate de vuelta a erguido con control.','Error típico: carga excesiva o movimiento brusco.','Respira continuo; no fuerces dolor.','Progresión: más rango con poca carga. No es un peso muerto convencional.','Estándar: flexión y extensión segmentada controladas.']::text[],
    mobile_equipment = 'Barra / KB ligera',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Jefferson Curl' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring']::text[],
    secondary_muscles = ARRAY['upper-back','abs']::text[],
    equipment = ARRAY['Barra / KB ligera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Jefferson Curl' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Caminata con bidón/jerry bag; pasos cortos y torso estable.',
    mobile_instructions = ARRAY['Carga el implemento (Jerry bag) a la posición prescrita.','Camina erguido con pasos cortos; no dejes que la carga se deslice.','Mantén hombros activos y core firme durante todo el tramo.','Error típico: inclinarte en exceso o depositar la carga antes de la marca.','Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.','Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.','Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.']::text[],
    mobile_equipment = 'Jerry bag',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Jerry Bag Carry' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','forearm','upper-back']::text[],
    equipment = ARRAY['Jerry bag']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Jerry Bag Carry' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Salto tijera: abre y cierra piernas y brazos.',
    mobile_instructions = ARRAY['De pie; salta abriendo piernas y brazos por encima.','Vuelve a posición cerrada en el siguiente salto.','Aterriza suave; ritmo constante.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Jumping Jack mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Cardio'
WHERE name = 'Jumping Jack' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','deltoids']::text[],
    secondary_muscles = ARRAY['abs']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Jumping Jack' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Caminata con barril en bear hug o hombro; pasos cortos y torso estable.',
    mobile_instructions = ARRAY['Carga el implemento (Barril) a la posición prescrita.','Camina erguido con pasos cortos; no dejes que la carga se deslice.','Mantén hombros activos y core firme durante todo el tramo.','Error típico: inclinarte en exceso o depositar la carga antes de la marca.','Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.','Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.','Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.']::text[],
    mobile_equipment = 'Barril',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Keg Carry' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','forearm','upper-back']::text[],
    equipment = ARRAY['Barril']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Keg Carry' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Peso muerto con kettlebell entre los pies o delante.',
    mobile_instructions = ARRAY['KB entre los pies; cadera atrás y pecho alto.','Empuja el suelo y bloquea cadera arriba.','Baja la KB al suelo con control.','Error típico: redondear la lumbar o rotar la cadera.','Exhala al extender la cadera.','Progresión: más carga o más rango controlado.','Estándar: bisagra limpia y extensión completa arriba.']::text[],
    mobile_equipment = 'Kettlebell',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Kettlebell Deadlift' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal']::text[],
    secondary_muscles = ARRAY['abs','upper-back']::text[],
    equipment = ARRAY['Kettlebell']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kettlebell Deadlift' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Zancada con KB en front rack.',
    mobile_instructions = ARRAY['KB en rack frontal; codos altos.','Baja o sube con la rodilla delante alineada al pie; controla el tronco.','Extiende la pierna de apoyo por completo en la parte alta.','Error típico: empujar con la pierna de atrás o dejar colapsar la rodilla.','Exhala al extender; alterna piernas según el WOD.','Progresión: más carga o caja más alta.','Estándar: rango completo y control en cada zancada/step.']::text[],
    mobile_equipment = 'Kettlebell',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Kettlebell Front Rack Lunge' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','gluteal']::text[],
    secondary_muscles = ARRAY['hamstring','abs']::text[],
    equipment = ARRAY['Kettlebell']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kettlebell Front Rack Lunge' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Halo de kettlebell alrededor de la cabeza con core estable.',
    mobile_instructions = ARRAY['Sujeta la KB por las cuernos invertidos a la altura del pecho.','Circunda la cabeza con la KB cerca del cráneo, sin golpear.','Alterna dirección; torso quieto y costillas abajo.','Error típico: mover el tronco con la KB o acercar demasiado la nuca.','Respira continuo; hombros relajados.','Progresión: KB más pesada o más círculos lentos.','Estándar: círculo completo alrededor de la cabeza en cada rep.']::text[],
    mobile_equipment = 'Kettlebell',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Kettlebell Halo' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids']::text[],
    secondary_muscles = ARRAY['abs','upper-back']::text[],
    equipment = ARRAY['Kettlebell']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kettlebell Halo' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Press de kettlebell a un brazo o dos hasta bloqueo overhead.',
    mobile_instructions = ARRAY['KB en rack (antebrazo vertical, muñeca recta).','Press hasta bloquear el codo con bíceps junto a la oreja.','Baja a rack con control; no dejes caer la KB.','Error típico: arching excesivo o no completar el lockout.','Exhala al empujar; core firme.','Progresión: más peso o tempo. Alternativa: press con barra.','Estándar: extensión completa arriba en cada rep.']::text[],
    mobile_equipment = 'Kettlebell',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Kettlebell Press' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids']::text[],
    secondary_muscles = ARRAY['triceps','abs']::text[],
    equipment = ARRAY['Kettlebell']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kettlebell Press' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Peso muerto sumo con KB seguido de tirón alto hasta cerca de la barbilla.',
    mobile_instructions = ARRAY['KB entre los pies en stance sumo; pecho alto.','Extiende cadera y, en continuidad, tira de la KB hasta cerca del pecho/barbilla.','Codos altos; baja a extensión y al suelo según el WOD.','Error típico: remo de brazos sin extensión de cadera o encoger el cuello.','Exhala en el tirón alto.','Progresión: KB más pesada. Alternativa: sumo high pull con barra.','Estándar: cadera extendida y KB a altura de pecho/barbilla en cada rep.']::text[],
    mobile_equipment = 'Kettlebell',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Kettlebell Sumo Deadlift High Pull' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal','deltoids']::text[],
    secondary_muscles = ARRAY['upper-back','trapezius']::text[],
    equipment = ARRAY['Kettlebell']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kettlebell Sumo Deadlift High Pull' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Molino con KB: una mano overhead y bisagra hacia la pierna libre.',
    mobile_instructions = ARRAY['KB bloqueada overhead; pies algo girados; mirada a la KB.','Desliza la mano libre por la pierna mientras empujas la cadera afuera.','Mantén el brazo overhead vertical; vuelve a erguido.','Error típico: flexionar el codo overhead o redondear la espalda.','Respira de forma continua; no fuerces el rango.','Progresión: KB más pesada o más profundidad controlada.','Estándar: brazo overhead bloqueado en todo el recorrido.']::text[],
    mobile_equipment = 'Kettlebell',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Kettlebell Windmill' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','deltoids']::text[],
    secondary_muscles = ARRAY['hamstring','gluteal']::text[],
    equipment = ARRAY['Kettlebell']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kettlebell Windmill' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'HSPU con kipping: impulso de piernas hacia el bloqueo.',
    mobile_instructions = ARRAY['En pino apoyado; baja la cabeza al suelo (o deficit).','Kip de piernas y extiende brazos hasta lockout.','Controla la bajada; no rebotes la cabeza.','Error típico: acortar el rango o perder la línea del cuerpo.','Exhala en el esfuerzo principal; no contengas la respiración.','Progresión: más rango o menos asistencia. Escala a versión strict o parcial.','Estándar: cada rep de Kipping Handstand Push Up cumple el rango acordado.']::text[],
    mobile_equipment = 'Pared',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Kipping Handstand Push Up' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids','triceps']::text[],
    secondary_muscles = ARRAY['abs','trapezius']::text[],
    equipment = ARRAY['Pared']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kipping Handstand Push Up' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Dominada manteniendo posición en L (piernas horizontales).',
    mobile_instructions = ARRAY['Cuelga en L-sit (piernas extendidas a 90°).','Tira hasta barbilla sobre la barra sin perder la L.','Baja con control manteniendo piernas altas.','Error típico: acortar el rango o perder la línea del cuerpo.','Exhala en el esfuerzo principal; no contengas la respiración.','Progresión: más rango o menos asistencia. Escala a versión strict o parcial.','Estándar: cada rep de L Pull Up cumple el rango acordado.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'back',
    mobile_muscle_group = 'Espalda'
WHERE name = 'L Pull Up' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['upper-back','abs']::text[],
    secondary_muscles = ARRAY['biceps']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'L Pull Up' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Press en landmine (barra anclada) a un brazo o dos, en pie o medio arrodillado.',
    mobile_instructions = ARRAY['Ancla la barra; sujeta el extremo libre a la altura del hombro.','Empuja en diagonal arriba y adelante hasta extender el codo.','No gires en exceso el tronco; core firme.','Error típico: abrir la costilla o empujar solo con el brazo sin piernas/core.','Exhala al empujar; baja con control a la altura del hombro.','Progresión: más peso o half-kneeling. Alternativa: dumbbell press.','Estándar: extensión completa del brazo en cada rep.']::text[],
    mobile_equipment = 'Barra (landmine)',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Landmine Press' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids','chest']::text[],
    secondary_muscles = ARRAY['triceps','abs']::text[],
    equipment = ARRAY['Barra (landmine)']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Landmine Press' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Burpee con desplazamiento lateral.',
    mobile_instructions = ARRAY['Pecho y muslos al suelo (o estándar del WOD) en la parte baja.','Pecho al suelo y desplázate lateralmente entre reps.','Extiende cadera arriba; marca el lockout o el cruce del obstáculo.','Error típico: no tocar el suelo con el pecho o acortar el muscle-up/cruce.','Exhala en el esfuerzo principal (salto, tirón o deadlift).','Progresión: más densidad. Escala a burpee + pull-up si hace falta.','Estándar: pecho abajo y final completo de Lateral Burpee en cada rep.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Cardio'
WHERE name = 'Lateral Burpee' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['chest','quadriceps']::text[],
    secondary_muscles = ARRAY['upper-back','abs','deltoids']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Lateral Burpee' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Zancada lateral con cadera atrás y rodilla alineada.',
    mobile_instructions = ARRAY['Pies paralelos; da un paso lateral amplio.','Baja o sube con la rodilla delante alineada al pie; controla el tronco.','Extiende la pierna de apoyo por completo en la parte alta.','Error típico: empujar con la pierna de atrás o dejar colapsar la rodilla.','Exhala al extender; alterna piernas según el WOD.','Progresión: más carga o caja más alta.','Estándar: rango completo y control en cada zancada/step.']::text[],
    mobile_equipment = 'Peso corporal / carga',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Lateral Lunge' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','gluteal']::text[],
    secondary_muscles = ARRAY['hamstring','abs']::text[],
    equipment = ARRAY['Peso corporal / carga']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Lateral Lunge' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Caminata con tronco/log; pasos cortos y torso estable.',
    mobile_instructions = ARRAY['Carga el implemento (Tronco) a la posición prescrita.','Camina erguido con pasos cortos; no dejes que la carga se deslice.','Mantén hombros activos y core firme durante todo el tramo.','Error típico: inclinarte en exceso o depositar la carga antes de la marca.','Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.','Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.','Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.']::text[],
    mobile_equipment = 'Tronco',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Log Carry' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','forearm','upper-back']::text[],
    equipment = ARRAY['Tronco']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Log Carry' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Cargada de tronco a rack y envión hasta bloqueo overhead.',
    mobile_instructions = ARRAY['Desde el suelo, carga el tronco a los hombros (rack de log).','Dip corto e impulsa a overhead hasta bloquear codos.','Recibe estable con pies al ancho de hombros.','Error típico: press lento sin dip o no bloquear arriba.','Exhala en el jerk; baja a rack o al suelo con control.','Progresión: más peso. Alternativa: axle clean and jerk.','Estándar: bloqueo overhead claro en cada rep.']::text[],
    mobile_equipment = 'Tronco',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Log Clean And Jerk' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','triceps','abs']::text[],
    equipment = ARRAY['Tronco']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Log Clean And Jerk' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Press de tronco desde rack de hombros hasta bloqueo overhead.',
    mobile_instructions = ARRAY['Tronco en rack sobre los hombros, codos delante.','Press o push press hasta extender los codos por completo.','Bloquea arriba con la cabeza «a través» del tronco.','Error típico: hiperextender la lumbar o no completar el lockout.','Exhala al subir; baja a rack con control.','Progresión: más peso o strict press.','Estándar: lockout overhead estable en cada rep.']::text[],
    mobile_equipment = 'Tronco',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Log Press' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids']::text[],
    secondary_muscles = ARRAY['triceps','abs']::text[],
    equipment = ARRAY['Tronco']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Log Press' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Step-over al cajón con medball.',
    mobile_instructions = ARRAY['Sujeta el medball; pisa el cajón y cruza al otro lado.','Baja o sube con la rodilla delante alineada al pie; controla el tronco.','Extiende la pierna de apoyo por completo en la parte alta.','Error típico: empujar con la pierna de atrás o dejar colapsar la rodilla.','Exhala al extender; alterna piernas según el WOD.','Progresión: más carga o caja más alta.','Estándar: rango completo y control en cada zancada/step.']::text[],
    mobile_equipment = 'Balón medicinal, Cajón',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Medicine Ball Box Step Over' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','gluteal']::text[],
    secondary_muscles = ARRAY['hamstring','abs']::text[],
    equipment = ARRAY['Balón medicinal, Cajón']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Medicine Ball Box Step Over' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Sit-up con balón medicinal en el pecho o en extensión de brazos.',
    mobile_instructions = ARRAY['Túmbate con medball en el pecho o brazos extendidos.','Sit-up hasta torso vertical; el balón puede tocar los pies si se prescribe.','Baja con control hasta hombros al suelo.','Error típico: tirar del cuello o no tocar abajo/arriba.','Exhala al subir.','Progresión: balón más pesado o AbMat sit-up.','Estándar: hombros abajo y torso arriba en cada rep.']::text[],
    mobile_equipment = 'Balón medicinal',
    mobile_body_part = 'waist',
    mobile_muscle_group = 'Core'
WHERE name = 'Medicine Ball Sit Up' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs']::text[],
    secondary_muscles = ARRAY[]::text[],
    equipment = ARRAY['Balón medicinal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Medicine Ball Sit Up' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Lanzamiento de balón medicinal (pecho, overhead o al suelo según WOD).',
    mobile_instructions = ARRAY['Sujeta el balón; adopta el patrón prescrito (chest pass, overhead slam, rotational).','Genera potencia desde piernas y tronco; suelta el balón con intención.','Recoge o recibe según el estándar y repite.','Error típico: lanzar solo con brazos o no usar la cadera.','Exhala en el lanzamiento.','Progresión: balón más pesado o más distancia.','Estándar: cada lanzamiento cumple distancia/altura/pared prescrita.']::text[],
    mobile_equipment = 'Balón medicinal',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Medicine Ball Throw' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids','abs']::text[],
    secondary_muscles = ARRAY['quadriceps','chest']::text[],
    equipment = ARRAY['Balón medicinal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Medicine Ball Throw' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Escalador en plancha: rodillas al pecho en alternancia.',
    mobile_instructions = ARRAY['Plancha alta con hombros sobre las muñecas.','Alterna rodillas al pecho a ritmo; cadera estable.','No piques ni subas de más la pelvis.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Mountain Climber mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'waist',
    mobile_muscle_group = 'Core'
WHERE name = 'Mountain Climber' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['obliques']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Mountain Climber' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Dominada negativa: solo la fase excéntrica controlada.',
    mobile_instructions = ARRAY['Salta o asistete hasta la barbilla por encima de la barra.','Baja en 3–5 s hasta brazos extendidos.','No te dejes caer en el último tercio.','Error típico: acortar el rango o perder la línea del cuerpo.','Exhala en el esfuerzo principal; no contengas la respiración.','Progresión: más rango o menos asistencia. Escala a versión strict o parcial.','Estándar: cada rep de Negative Pull Up cumple el rango acordado.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'back',
    mobile_muscle_group = 'Espalda'
WHERE name = 'Negative Pull Up' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['upper-back']::text[],
    secondary_muscles = ARRAY['biceps','forearm']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Negative Pull Up' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Curl nórdico: excéntrico de isquios con tobillos fijados.',
    mobile_instructions = ARRAY['Arrodíllate con tobillos fijados (pareja, banco o anclaje).','Baja el torso hacia delante lo más lento posible resistiendo con isquios.','Empuja el suelo con las manos al fallar y vuelve a la vertical.','Error típico: caer de golpe o flexionar de más la cadera.','Exhala en la bajada controlada.','Progresión: más rango sin manos. Escala con banda.','Estándar: excéntrico controlado hasta el fallo técnico.']::text[],
    mobile_equipment = 'Anclaje / pareja',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Nordic Curl' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring']::text[],
    secondary_muscles = ARRAY['gluteal','abs']::text[],
    equipment = ARRAY['Anclaje / pareja']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Nordic Curl' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Caminata con carga bloqueada overhead; pasos cortos y torso estable.',
    mobile_instructions = ARRAY['Carga el implemento (Barra / odd object) a la posición prescrita.','Camina erguido con pasos cortos; no dejes que la carga se deslice.','Mantén hombros activos y core firme durante todo el tramo.','Error típico: inclinarte en exceso o depositar la carga antes de la marca.','Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.','Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.','Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.']::text[],
    mobile_equipment = 'Barra / odd object',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Overhead Walk' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','forearm','upper-back']::text[],
    equipment = ARRAY['Barra / odd object']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Overhead Walk' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Press anti-rotación con cable o banda a la altura del pecho.',
    mobile_instructions = ARRAY['De lado a la ancla; agarra el mango al pecho.','Extiende los brazos al frente sin girar el tronco.','Vuelve al pecho con control; cambia de lado.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Pallof Press mantiene la posición correcta.']::text[],
    mobile_equipment = 'Cable / banda',
    mobile_body_part = 'waist',
    mobile_muscle_group = 'Core'
WHERE name = 'Pallof Press' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs']::text[],
    secondary_muscles = ARRAY['obliques']::text[],
    equipment = ARRAY['Cable / banda']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pallof Press' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Desplazamiento lateral/avance en barras paralelas en soporte.',
    mobile_instructions = ARRAY['Soporte en paralelas con codos bloqueados.','Avanza o cruza lateralmente moviendo una mano cada vez.','Mantén el cuerpo hueco; no balancees en exceso.','Error típico: acortar el rango o perder la línea del cuerpo.','Exhala en el esfuerzo principal; no contengas la respiración.','Progresión: más rango o menos asistencia. Escala a versión strict o parcial.','Estándar: cada rep de Parallel Bar Traverse cumple el rango acordado.']::text[],
    mobile_equipment = 'Paralelas',
    mobile_body_part = 'back',
    mobile_muscle_group = 'Tríceps'
WHERE name = 'Parallel Bar Traverse' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['triceps','abs']::text[],
    secondary_muscles = ARRAY['deltoids','chest']::text[],
    equipment = ARRAY['Paralelas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Parallel Bar Traverse' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'HSPU sobre parallettes (mayor rango).',
    mobile_instructions = ARRAY['Pino sobre parallettes; baja hasta orejas/hombros según estándar.','Empuja (strict o kipping) hasta lockout sobre las barras.','No dejes que los parallettes basculen.','Error típico: acortar el rango o perder la línea del cuerpo.','Exhala en el esfuerzo principal; no contengas la respiración.','Progresión: más rango o menos asistencia. Escala a versión strict o parcial.','Estándar: cada rep de Parallette Handstand Push Up cumple el rango acordado.']::text[],
    mobile_equipment = 'Parallettes',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Parallette Handstand Push Up' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids','triceps']::text[],
    secondary_muscles = ARRAY['abs']::text[],
    equipment = ARRAY['Parallettes']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Parallette Handstand Push Up' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Remo Pendlay: cada rep parte del suelo con espalda paralela.',
    mobile_instructions = ARRAY['Barra en el suelo; bisagra hasta espalda casi paralela.','Tira explosivo al bajo pecho/abdomen y toca; baja al suelo sin rebote.','Cada rep es desde parado en el suelo (no hang continuo).','Error típico: usar impulso de torso o no apoyar la barra entre reps.','Exhala al tirar; mantén la lumbar neutra.','Progresión: más peso. Alternativa: remo con barra.','Estándar: barra al suelo y contacto al torso en cada rep.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'back',
    mobile_muscle_group = 'Espalda'
WHERE name = 'Pendlay Row' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['upper-back']::text[],
    secondary_muscles = ARRAY['biceps','abs']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pendlay Row' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Caminata con disco(s) en farmer o hug; pasos cortos y torso estable.',
    mobile_instructions = ARRAY['Carga el implemento (Disco) a la posición prescrita.','Camina erguido con pasos cortos; no dejes que la carga se deslice.','Mantén hombros activos y core firme durante todo el tramo.','Error típico: inclinarte en exceso o depositar la carga antes de la marca.','Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.','Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.','Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.']::text[],
    mobile_equipment = 'Disco',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Plate Carry' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','forearm','upper-back']::text[],
    equipment = ARRAY['Disco']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Plate Carry' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Flexión de brazos: pecho cerca del suelo y codos extendidos arriba.',
    mobile_instructions = ARRAY['Plancha con manos bajo los hombros y cuerpo en línea.','Baja hasta pecho cerca del suelo; codos ~45°.','Empuja hasta extender los codos sin hundir la lumbar.','Error típico: no bajar el pecho o picar con la cadera.','Exhala al subir.','Progresión: lastradas o hand-release. Escala a rodillas si hace falta.','Estándar: pecho abajo y lockout arriba en cada rep.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'chest',
    mobile_muscle_group = 'Pecho'
WHERE name = 'Push Up' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['chest']::text[],
    secondary_muscles = ARRAY['triceps','deltoids','abs']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Push Up' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Remo en plancha con mancuernas: una fila por lado sin rotar de más.',
    mobile_instructions = ARRAY['Plancha sobre mancuernas; pies algo abiertos para estabilidad.','Rema una mancuerna al costado manteniendo cadera cuadrada.','Baja y alterna; minimiza el balanceo.','Error típico: abrir la cadera o encoger el cuello.','Exhala al remar.','Progresión: más peso o push-up + row.','Estándar: cada remo llega al costado con plancha estable.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'back',
    mobile_muscle_group = 'Espalda'
WHERE name = 'Renegade Row' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['upper-back','abs']::text[],
    secondary_muscles = ARRAY['biceps','deltoids']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Renegade Row' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Hiperextensión inversa: piernas atrás/arriba con torso fijo.',
    mobile_instructions = ARRAY['Torso sobre el banco/reverse hyper; agarra los agarres.','Eleva las piernas atrás hasta línea con el torso o algo más.','Baja con control sin balanceo excesivo.','Error típico: hiperextender lumbar con impulso.','Exhala al subir; glúteos e isquios activos.','Progresión: más carga en el aparato.','Estándar: extensión de cadera controlada en cada rep.']::text[],
    mobile_equipment = 'Reverse hyper',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Glúteos'
WHERE name = 'Reverse Hyper' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['gluteal','hamstring']::text[],
    secondary_muscles = ARRAY['upper-back']::text[],
    equipment = ARRAY['Reverse hyper']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Reverse Hyper' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Curl femoral en anillas: talones en anillas y cadera alta.',
    mobile_instructions = ARRAY['Boca arriba; talones en anillas y cadera en puente.','Flexiona rodillas acercando los talones sin dejar caer la cadera.','Extiende de nuevo con control.','Error típico: hundir la pelvis o abrir las rodillas.','Exhala al flexionar.','Progresión: más extensión de partida (más difícil).','Estándar: cadera alta y flexión completa de rodilla.']::text[],
    mobile_equipment = 'Anillas',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Ring Hamstring Curl' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring']::text[],
    secondary_muscles = ARRAY['gluteal','abs']::text[],
    equipment = ARRAY['Anillas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Ring Hamstring Curl' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'HSPU en anillas (avanzado): estabilidad y lockout.',
    mobile_instructions = ARRAY['Pino en anillas con soporte o libre según nivel.','Baja y empuja hasta turn-out/lockout prescrito.','Mantén anillas cerca del cuerpo.','Error típico: acortar el rango o perder la línea del cuerpo.','Exhala en el esfuerzo principal; no contengas la respiración.','Progresión: más rango o menos asistencia. Escala a versión strict o parcial.','Estándar: cada rep de Ring Handstand Push Up cumple el rango acordado.']::text[],
    mobile_equipment = 'Anillas',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Ring Handstand Push Up' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids','triceps']::text[],
    secondary_muscles = ARRAY['abs','upper-back']::text[],
    equipment = ARRAY['Anillas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Ring Handstand Push Up' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Descenso controlado en anillas desde soporte o muscle-up.',
    mobile_instructions = ARRAY['Desde soporte en anillas o cima de muscle-up.','Baja excéntrico hasta cuelgue o posición prescrita.','Hombros activos; no te desplomes.','Error típico: acortar el rango o perder la línea del cuerpo.','Exhala en el esfuerzo principal; no contengas la respiración.','Progresión: más rango o menos asistencia. Escala a versión strict o parcial.','Estándar: cada rep de Ring Lower cumple el rango acordado.']::text[],
    mobile_equipment = 'Anillas',
    mobile_body_part = 'back',
    mobile_muscle_group = 'Espalda'
WHERE name = 'Ring Lower' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['upper-back','chest']::text[],
    secondary_muscles = ARRAY['triceps','abs']::text[],
    equipment = ARRAY['Anillas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Ring Lower' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Flexión en anillas: mayor inestabilidad y rango.',
    mobile_instructions = ARRAY['Anillas a altura de push-up; cuerpo en plancha.','Baja con control (pecho a altura de anillas o más); codos cerca.','Empuja hasta extender; anillas estables junto al cuerpo.','Error típico: abrir en exceso las anillas o hundir la cadera.','Exhala al subir; hombros activos.','Progresión: más profundidad o anillas más bajas.','Estándar: rango completo y lockout con anillas quietas.']::text[],
    mobile_equipment = 'Anillas',
    mobile_body_part = 'chest',
    mobile_muscle_group = 'Pecho'
WHERE name = 'Ring Push Up' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['chest']::text[],
    secondary_muscles = ARRAY['triceps','deltoids','abs']::text[],
    equipment = ARRAY['Anillas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Ring Push Up' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Giro de torso sentado con o sin carga.',
    mobile_instructions = ARRAY['Sentado, torso atrás a ~45°; pies elevados o apoyados.','Gira el torso y toca el suelo/carga a cada lado.','Gira desde el tronco, no solo los brazos.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Russian Twist mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'waist',
    mobile_muscle_group = 'Core'
WHERE name = 'Russian Twist' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs']::text[],
    secondary_muscles = ARRAY['obliques']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Russian Twist' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Caminata con saco en bear hug, rack u hombro; pasos cortos y torso estable.',
    mobile_instructions = ARRAY['Carga el implemento (Saco) a la posición prescrita.','Camina erguido con pasos cortos; no dejes que la carga se deslice.','Mantén hombros activos y core firme durante todo el tramo.','Error típico: inclinarte en exceso o depositar la carga antes de la marca.','Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.','Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.','Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.']::text[],
    mobile_equipment = 'Saco',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Sandbag Carry' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','forearm','upper-back']::text[],
    equipment = ARRAY['Saco']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sandbag Carry' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Saco del suelo a un hombro con recepción estable.',
    mobile_instructions = ARRAY['Bisagra limpia, agarra el saco y llévalo al torso.','Extiende cadera y asienta el saco sobre un hombro.','Marca la recepción antes de bajar o soltar.','Error típico: no asentar el saco o girar en exceso la lumbar.','Exhala al asentar; alterna hombro si el WOD lo indica.','Progresión: más peso. Alternativa: D-ball over shoulder.','Estándar: saco claramente sobre el hombro en cada rep.']::text[],
    mobile_equipment = 'Saco',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Sandbag Ground To Shoulder' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal']::text[],
    secondary_muscles = ARRAY['upper-back','abs']::text[],
    equipment = ARRAY['Saco']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sandbag Ground To Shoulder' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Carga el saco del suelo y deposítalo estable sobre un cajón.',
    mobile_instructions = ARRAY['Levanta el saco con bisagra limpia hasta pecho o hombro.','Acércate al cajón y deposítalo encima con control.','El saco debe quedar estable sobre la caja antes de soltar.','Error típico: lanzar sin control o no dejarlo completamente sobre la caja.','Exhala al depositar; vuelve a por el saco según el estándar.','Progresión: saco más pesado o caja más alta.','Estándar: saco apoyado sobre la caja en cada rep.']::text[],
    mobile_equipment = 'Saco, Cajón',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Sandbag Load To Box' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','gluteal']::text[],
    secondary_muscles = ARRAY['hamstring','upper-back','abs']::text[],
    equipment = ARRAY['Saco, Cajón']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sandbag Load To Box' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Pasa el saco por encima de un tronco u obstáculo similar.',
    mobile_instructions = ARRAY['Levanta el saco y acércalo al tronco.','Pásalo por encima hasta que quede o caiga al otro lado.','Mantén la lumbar neutra en la carga inicial.','Error típico: no superar la altura del tronco.','Exhala al pasar el obstáculo.','Progresión: saco más pesado o tronco más alto.','Estándar: el saco supera claramente el tronco en cada rep.']::text[],
    mobile_equipment = 'Saco, Tronco',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Sandbag Over Log' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal']::text[],
    secondary_muscles = ARRAY['quadriceps','upper-back']::text[],
    equipment = ARRAY['Saco, Tronco']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sandbag Over Log' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Sentadilla abrazando un saco al pecho (bear hug) o en rack de saco.',
    mobile_instructions = ARRAY['Abraza el saco al pecho con codos altos y torso erguido.','Baja hasta la profundidad prescrita (paralelo o más).','Empuja el suelo y vuelve a de pie sin soltar el saco.','Error típico: inclinarte en exceso o cortar profundidad.','Inhala al bajar y exhala al subir.','Progresión: más peso o pausa abajo. Alternativa: goblet squat.','Estándar: profundidad marcada y extensión completa arriba.']::text[],
    mobile_equipment = 'Saco',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Sandbag Squat' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','gluteal']::text[],
    secondary_muscles = ARRAY['abs','upper-back']::text[],
    equipment = ARRAY['Saco']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sandbag Squat' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Plancha lateral apoyada en antebrazo o mano.',
    mobile_instructions = ARRAY['Apoyo en antebrazo/mano y canto del pie; cuerpo en línea.','Mantén cadera alta sin hundir ni rotar.','Respira; cambia de lado al terminar el intervalo.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Side Plank mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'waist',
    mobile_muscle_group = 'Core'
WHERE name = 'Side Plank' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs']::text[],
    secondary_muscles = ARRAY['obliques']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Side Plank' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Thruster a una mancuerna: sentadilla + press overhead.',
    mobile_instructions = ARRAY['Una mancuerna en rack; la mano libre ayuda al equilibrio.','Sentadilla completa y, al subir, press a overhead hasta bloqueo.','Baja a rack y repite; cambia de lado si el WOD lo pide.','Error típico: press anticipado o cortar profundidad.','Exhala al subir/press.','Progresión: más carga o thruster a dos manos.','Estándar: profundidad de squat y lockout overhead en cada rep.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Single Arm Dumbbell Thruster' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','deltoids']::text[],
    secondary_muscles = ARRAY['triceps','gluteal','abs']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Single Arm Dumbbell Thruster' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Swing de kettlebell a una mano (ruso o americano según WOD).',
    mobile_instructions = ARRAY['KB a una mano; hinge y hike pass entre las piernas.','Extiende cadera de forma explosiva; el brazo guía la KB.','Hasta pecho (ruso) u overhead (americano) según estándar.','Error típico: levantar con el hombro o flexionar de más las rodillas tipo squat.','Exhala en el pop de cadera; cambia de mano si se prescribe.','Progresión: KB más pesada o más reps. Alternativa: swing a dos manos.','Estándar: altura prescrita y cadera extendida en cada swing.']::text[],
    mobile_equipment = 'Kettlebell',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Single Arm Kettlebell Swing' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal']::text[],
    secondary_muscles = ARRAY['abs','deltoids','forearm']::text[],
    equipment = ARRAY['Kettlebell']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Single Arm Kettlebell Swing' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Thruster a una kettlebell: squat + press.',
    mobile_instructions = ARRAY['KB en rack a un lado; antebrazo vertical.','Sentadilla completa y, al subir, press a overhead hasta bloqueo.','Baja a rack y repite; cambia de lado si el WOD lo pide.','Error típico: press anticipado o cortar profundidad.','Exhala al subir/press.','Progresión: más carga o thruster a dos manos.','Estándar: profundidad de squat y lockout overhead en cada rep.']::text[],
    mobile_equipment = 'Kettlebell',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Single Arm Kettlebell Thruster' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','deltoids']::text[],
    secondary_muscles = ARRAY['triceps','gluteal','abs']::text[],
    equipment = ARRAY['Kettlebell']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Single Arm Kettlebell Thruster' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Puente de glúteos a una pierna.',
    mobile_instructions = ARRAY['Una pierna apoyada; la otra extendida o flexionada al pecho.','Extiende cadera sin rotar la pelvis.','Baja con control y completa las reps antes de cambiar.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Single Leg Glute Bridge mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Glúteos'
WHERE name = 'Single Leg Glute Bridge' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['gluteal']::text[],
    secondary_muscles = ARRAY['abs']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Single Leg Glute Bridge' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'RDL a una pierna (peso corporal, mancuerna o KB).',
    mobile_instructions = ARRAY['Apoyo en una pierna; ligera flexión de rodilla; carga opcional en la mano libre.','Bisagra hacia delante mientras la pierna libre va atrás; cadera cuadrada.','Vuelve a de pie sin torcer la pelvis.','Error típico: redondear la lumbar o rotar la cadera.','Exhala al extender la cadera.','Progresión: más carga o más rango controlado.','Estándar: bisagra limpia y extensión completa arriba.']::text[],
    mobile_equipment = 'Mancuernas',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Single Leg Romanian Deadlift' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal']::text[],
    secondary_muscles = ARRAY['abs','upper-back']::text[],
    equipment = ARRAY['Mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Single Leg Romanian Deadlift' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Saltos laterales tipo patinador con recepción a una pierna.',
    mobile_instructions = ARRAY['Salta lateralmente de un pie al otro.','Recibe con control e inclina ligeramente el torso.','El pie libre puede rozar atrás para equilibrio.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Skater Jump mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Glúteos'
WHERE name = 'Skater Jump' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['gluteal','quadriceps']::text[],
    secondary_muscles = ARRAY['abs']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Skater Jump' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Arrastre de trineo (hacia atrás, adelante o lateral) por distancia o tiempo.',
    mobile_instructions = ARRAY['Engancha el trineo y adopta la dirección prescrita (atrás/adelante/lateral).','Mantén el torso firme y tira o empuja con zancadas cortas y potentes.','No dejes que el trineo se detenga si el WOD pide ritmo continuo.','Error típico: redondear la espalda o dar zancadas demasiado largas e inestables.','Exhala en cada impulso; usa el agarre o arnés según el setup.','Progresión: más peso o más metros. Alternativa: prowler push.','Estándar: completa la distancia/tiempo con el trineo en movimiento controlado.']::text[],
    mobile_equipment = 'Trineo',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Sled Drag' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','gluteal']::text[],
    secondary_muscles = ARRAY['hamstring','calves','abs']::text[],
    equipment = ARRAY['Trineo']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sled Drag' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Golpes de maza sobre neumático: potencia de cadera y control del implemento.',
    mobile_instructions = ARRAY['Coloca el neumático estable; agarra la maza con manos alternas o juntas.','Lleva la maza por encima de la cabeza y golpea el neumático con drive de cadera.','Alterna lado o patrón según el WOD; recupera la maza con control.','Error típico: golpear solo con brazos o perder el agarre al rebotar.','Exhala en el impacto; mantén los pies firmes.','Progresión: maza más pesada o más golpes por minuto.','Estándar: cada golpe contacta el neumático con rango completo del swing.']::text[],
    mobile_equipment = 'Maza, Neumático',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Sledgehammer Strike' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','deltoids']::text[],
    secondary_muscles = ARRAY['upper-back','gluteal','forearm']::text[],
    equipment = ARRAY['Maza, Neumático']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sledgehammer Strike' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Peso muerto de piernas rígidas: bisagra con mínima flexión de rodilla.',
    mobile_instructions = ARRAY['Barra a la altura de muslos; rodillas casi bloqueadas pero no hiperextendidas.','Empuja la cadera atrás y baja la barra rozando las piernas.','Estira isquios con espalda neutra; vuelve extendiendo cadera.','Error típico: flexionar demasiado las rodillas o redondear la lumbar.','Exhala al subir; no tires con la zona lumbar.','Progresión: más peso o RDL. Alternativa: good morning.','Estándar: bisagra clara y extensión de cadera completa arriba.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Stiff Legged Deadlift' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal']::text[],
    secondary_muscles = ARRAY['upper-back','abs']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Stiff Legged Deadlift' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Elevación de rodillas estricta (sin kip) colgado.',
    mobile_instructions = ARRAY['Cuelga activo sin impulso de piernas.','Sube rodillas solo con abdomen/flexores; sin balanceo.','Baja lento a extensión.','Error típico: usar kip o balanceo de hombros.','Exhala al subir.','Progresión: strict T2B. Escala a foot-supported raises.','Estándar: sin kip y rodillas a altura prescrita.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'waist',
    mobile_muscle_group = 'Core'
WHERE name = 'Strict Knee Raise' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs']::text[],
    secondary_muscles = ARRAY['forearm']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Strict Knee Raise' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Rodillas al pecho estrictas colgado de la barra.',
    mobile_instructions = ARRAY['Cuelga activo; sin balanceo previo.','Lleva rodillas hasta tocar o acercar al pecho.','Baja con control a piernas largas.','Error típico: kip oculto o no acercar rodillas al pecho.','Exhala al subir.','Progresión: strict T2B.','Estándar: rodillas al pecho sin impulso.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'waist',
    mobile_muscle_group = 'Core'
WHERE name = 'Strict Knees To Chest' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs']::text[],
    secondary_muscles = ARRAY['forearm']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Strict Knees To Chest' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Caminata con carga a un solo lado; pasos cortos y torso estable.',
    mobile_instructions = ARRAY['Carga el implemento (Mancuerna / kettlebell) a la posición prescrita.','Camina erguido con pasos cortos; no dejes que la carga se deslice.','Mantén hombros activos y core firme durante todo el tramo.','Error típico: inclinarte en exceso o depositar la carga antes de la marca.','Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.','Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.','Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.']::text[],
    mobile_equipment = 'Mancuerna / kettlebell',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Suitcase Carry' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','forearm','upper-back']::text[],
    equipment = ARRAY['Mancuerna / kettlebell']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Suitcase Carry' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Boca abajo: eleva brazos y piernas (extensión lumbar/glúteos).',
    mobile_instructions = ARRAY['Boca abajo, brazos delante.','Eleva pecho, brazos y piernas a la vez; pausa breve.','Baja con control sin rebotar.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Superman mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Espalda'
WHERE name = 'Superman' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['upper-back','gluteal']::text[],
    secondary_muscles = ARRAY['abs']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Superman' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Vuelco de neumático con drive de piernas y cadera hasta dejarlo plano.',
    mobile_instructions = ARRAY['Pecho cerca del neumático; agarra el borde inferior con lumbar neutra.','Extiende cadera y rodillas, da un paso y empuja hasta voltearlo.','El impulso sale de piernas/cadera, no solo de brazos.','Error típico: redondear la espalda o empujar con brazos antes de extender cadera.','Exhala en el vuelco; reubica los pies tras cada flip.','Progresión: neumático más pesado o más flips seguidos.','Estándar: el neumático queda plano al otro lado en cada rep.']::text[],
    mobile_equipment = 'Neumático',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Tire Flip' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal','quadriceps']::text[],
    secondary_muscles = ARRAY['upper-back','deltoids']::text[],
    equipment = ARRAY['Neumático']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Tire Flip' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Peso muerto con barra hex/trap: empuje de piernas y bloqueo alto.',
    mobile_instructions = ARRAY['Pisa el centro de la hex; agarra las asas al mismo alto.','Cadera atrás, pecho alto; empuja el suelo hasta de pie.','Bloquea cadera y rodillas; baja con control hasta tocar el suelo.','Error típico: tirar con la espalda o desnivelar las asas.','Inhala y bracea; exhala al bloqueo.','Progresión: más peso o deficit. Alternativa: peso muerto convencional.','Estándar: extensión completa arriba y placas al suelo abajo.']::text[],
    mobile_equipment = 'Barra hex / trap',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Trap Bar Deadlift' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','gluteal']::text[],
    secondary_muscles = ARRAY['hamstring','upper-back','forearm']::text[],
    equipment = ARRAY['Barra hex / trap']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Trap Bar Deadlift' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Salto vertical llevando rodillas al pecho.',
    mobile_instructions = ARRAY['Salta y lleva rodillas arriba; pecho erguido.','Aterriza suave con ligera flexión.','No te desplomes en la recepción.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Tuck Jump mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Tuck Jump' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','calves']::text[],
    secondary_muscles = ARRAY['abs']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Tuck Jump' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Ascenso por la pared desde plancha hasta pino apoyado.',
    mobile_instructions = ARRAY['Plancha con pies cerca de la pared.','Camina pies arriba y manos atrás hasta pino en la pared.','Desciende con control o baja según el WOD.','Error típico: acortar el rango o perder la línea del cuerpo.','Exhala en el esfuerzo principal; no contengas la respiración.','Progresión: más rango o menos asistencia. Escala a versión strict o parcial.','Estándar: cada rep de Wall Climb cumple el rango acordado.']::text[],
    mobile_equipment = 'Pared',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Wall Climb' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids','abs']::text[],
    secondary_muscles = ARRAY['triceps','upper-back']::text[],
    equipment = ARRAY['Pared']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Wall Climb' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Wall climb hasta pino y cruce/bajada al otro lado del obstáculo o pared baja.',
    mobile_instructions = ARRAY['Escala a pino como en wall climb.','Supera el borde o gira según el estándar del evento.','Aterriza o desciende controlado al otro lado.','Error típico: acortar el rango o perder la línea del cuerpo.','Exhala en el esfuerzo principal; no contengas la respiración.','Progresión: más rango o menos asistencia. Escala a versión strict o parcial.','Estándar: cada rep de Wall Climb Over cumple el rango acordado.']::text[],
    mobile_equipment = 'Pared / obstáculo',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Wall Climb Over' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids','abs']::text[],
    secondary_muscles = ARRAY['triceps','quadriceps']::text[],
    equipment = ARRAY['Pared / obstáculo']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Wall Climb Over' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Isométrico de sentadilla contra la pared.',
    mobile_instructions = ARRAY['Espalda pegada a la pared; muslos paralelos al suelo.','Mantén rodillas a 90° y talones abajo.','No te apoyes en las manos; respira continuo.','Error típico: perder la alineación o usar impulso que invalide el patrón.','Respira de forma continua; no bloquees el aire.','Progresión: más tiempo, más reps o más control/tempo.','Estándar: cada rep o segundo de Wall Sit mantiene la posición correcta.']::text[],
    mobile_equipment = 'Peso corporal',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Wall Sit' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps']::text[],
    secondary_muscles = ARRAY['abs']::text[],
    equipment = ARRAY['Peso corporal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Wall Sit' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Press overhead sentado en el suelo con piernas extendidas (sin respaldo).',
    mobile_instructions = ARRAY['Siéntate en el suelo con piernas abiertas/extendidas y torso erguido.','Barra o mancuernas a hombros; press hasta bloqueo overhead.','No uses impulso de piernas ni te recuestes.','Error típico: arching excesivo o no bloquear codos.','Exhala al subir; core muy firme.','Progresión: más peso o strict seated press en banco.','Estándar: lockout overhead con glúteos en el suelo.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'shoulders',
    mobile_muscle_group = 'Hombros'
WHERE name = 'Z Press' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['deltoids']::text[],
    secondary_muscles = ARRAY['triceps','abs']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Z Press' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Caminata con barra en pliegue de codos; pasos cortos y torso estable.',
    mobile_instructions = ARRAY['Carga el implemento (Barra) a la posición prescrita.','Camina erguido con pasos cortos; no dejes que la carga se deslice.','Mantén hombros activos y core firme durante todo el tramo.','Error típico: inclinarte en exceso o depositar la carga antes de la marca.','Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.','Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.','Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'full body',
    mobile_muscle_group = 'Core'
WHERE name = 'Zercher Carry' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['abs','quadriceps']::text[],
    secondary_muscles = ARRAY['gluteal','forearm','upper-back']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Zercher Carry' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Peso muerto con la barra en el pliegue de los codos.',
    mobile_instructions = ARRAY['Barra en el pliegue de los codos; cadera atrás y lumbar neutra.','Extiende cadera y rodillas hasta de pie con torso erguido.','Baja con control manteniendo la posición Zercher.','Error típico: redondear la lumbar o dejar caer los codos.','Inhala antes de tirar; exhala al bloqueo.','Progresión: más peso. Alternativa: Zercher squat.','Estándar: extensión completa de cadera arriba en cada rep.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Isquios'
WHERE name = 'Zercher Deadlift' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['hamstring','gluteal']::text[],
    secondary_muscles = ARRAY['quadriceps','upper-back','abs']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Zercher Deadlift' AND c.is_active;

UPDATE public.business_exercise_catalog
SET mobile_description = 'Sentadilla con la barra en el pliegue de los codos.',
    mobile_instructions = ARRAY['Barra en Zercher, codos altos y pecho arriba.','Baja en sentadilla hasta la profundidad prescrita.','Sube empujando el suelo sin perder la barra del pliegue.','Error típico: inclinarte en exceso o abrir los codos.','Inhala al bajar; exhala al subir.','Progresión: más peso o pausa abajo.','Estándar: profundidad y extensión completa arriba.']::text[],
    mobile_equipment = 'Barra',
    mobile_body_part = 'upper legs',
    mobile_muscle_group = 'Piernas'
WHERE name = 'Zercher Squat' AND is_active;

UPDATE public.training_exercise_metadata m
SET primary_muscles = ARRAY['quadriceps','gluteal']::text[],
    secondary_muscles = ARRAY['abs','upper-back']::text[],
    equipment = ARRAY['Barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_coaching_rewrite_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Zercher Squat' AND c.is_active;

