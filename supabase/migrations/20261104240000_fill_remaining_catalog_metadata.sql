-- Fill remaining metadata: aliases, movement_pattern, alternatives (no art).
-- 2026-11-04

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Alternating Dumbbell Power Snatch','Alternating Dumbbell Snatch','alt db snatch','arrancada alterna mancuerna','alt db power snatch']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Alternating Dumbbell Snatch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['flyes','dumbbell fly','aperturas mancuernas','chest fly']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Aperturas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['arch hold','superman hold','arch body hold']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Arch hold' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['archer pull up','archer pullup','dominada arquero']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Archer pull-up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['tuck back lever','back lever en tuck']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Back lever tuck' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['stationary bike','exercise bike','bici indoor','bike erg static']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Bici estática' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['candlestick stretch','candlestick mobility']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Candlestick' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['treadmill','cinta de correr','treadmill run']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Cinta / carrera' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['cable crossover','cable cross over','crossover polea']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Cruce de poleas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['abdominal crunch','crunches','crunch abdominal']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Crunch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['barbell curl','curl con barra','BB curl']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl barra' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['leg curl','hamstring curl','curl de femoral']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl femoral' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Bicep Curl','biceps curl']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl mancuernas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Pull Up','pull-up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dominadas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Butterfly Pull Up','butterfly pull-up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dominadas butterfly' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['ring pull up','ring pull-up','pull up rings']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dominadas en anillas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Strict Pull Up','strict pull-up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dominadas estrictas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Kipping Pull Up','kipping pull-up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dominadas kipping' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Weighted Pull Up','Weighted Pull-ups','weighted pull-up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dominadas lastradas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Chin Up','chin-up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dominadas supinas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Dumbbell Front Rack Squat','db front squat','sentadilla frontal mancuernas','Dumbbell Front Squat','db front rack squat']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Front Squat' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['leg raise','lying leg raise','elevaciones de piernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Elevación de piernas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Triceps Pushdown','tricep pushdown','Tricep Extension','triceps pushdown','triceps extension']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Extensión tríceps polea' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['false grip hang','cuelgue false grip']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'False grip hang' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['farmer walk','farmer carries','paseo granjero','Paseo del granjero','Farmers Carry','Farmer carry','farmers walk','farmers carry','farmer''s carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Farmer carry' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['farmer walk','farmers walk','farmer''s walk']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Farmer walk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['dips','dip','fondos paralelas genérico']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Fondos' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['kipping ring dip','ring dip kipping']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Fondos en anillas kipping' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['bench dip','bench dips','fondos banco']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Fondos en banco' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['tuck front lever','front lever en tuck']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Front lever tuck' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['german hang','skin the cat hang']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'German hang' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Freestanding Handstand Push Up','freestanding HSPU']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'HSPU libre' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['hack squat','hack squats','sentadilla hack']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hack squat' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['hip to bar','HTB','hips to bar']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hip to bar' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['kip swing','kipping swing','balanceo kip']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kip swing' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['ring mu','Ring Muscle Up','rmu','muscle up de anillas','ring muscle up','Muscle-up anillas','ring muscle-up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Muscle-up anillas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['strict ring muscle up','strict ring MU']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Muscle-up estricto anillas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Strict Muscle Up','strict muscle-up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Muscle-up estricto barra' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['lateral band walk','monster walk','band side step']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Paso lateral con banda' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Romanian Deadlift','RDL']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Peso muerto rumano' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['tuck planche','planche en tuck']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Planche tuck' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['leg press','prensa de piernas','machine leg press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Prensa' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['decline bench press','press declinado']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press banca declinado' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Incline Bench Press','incline bench']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press banca inclinada' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Close Grip Bench Press','close grip bench']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press cerrado' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['dumbbell press','db press','press con mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press mancuernas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['military press','overhead press','OHP','press de hombros barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press militar' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['press to handstand','press handstand','press a pino']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press to handstand' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['barbell pullover','pull over barra','pullover barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pull-over barra' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Pull Over','pullover']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pullover' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Push press','press de impulso','Shoulder To Overhead','pp','press con piernas','push presses','Press con impulso','Push Press','STO']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Push press' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['reverse fly','rear delt fly','pajaritos']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pájaros' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['upright row','remo mentón','remo vertical']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo al mentón' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['inverted row','australian pull up','remo australiano']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo invertido' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Dumbbell Row','db row']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo mancuerna' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['Remo máquina','row erg','RowErg','Rowing','rowing erg','rowerg','Row','Remo ergómetro','ergometro remo','rower']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo máquina' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['esqui ergometro','Esquí ergómetro','esqui nordico ergometro','ski ergometer','ski erg','Ski Erg','ski-erg','ski','SkiErg','ski erg']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'SkiErg' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['skin the cat','skin the cats']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Skin the cat' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['ring support','support hold rings','soporte anillas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Soporte en anillas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['strict toes to bar','strict T2B','T2B estrictos']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Toes to bar estrictos' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['v sit','v-sit hold','ve sit']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'V-sit' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET aliases = ARRAY['wall walk','wall walks','caminata por pared']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Wall walk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'squat',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Abducción de cadera en máquina' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'squat',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Aducción de cadera en máquina' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Aperturas' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Arch hold' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'pull',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Archer pull-up' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Back lever tuck' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'lunge',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Back rack reverse lunge' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Behind-the-Neck Jerk' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Behind-the-Neck Press' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'monostructural',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Bici estática' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Block Clean' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Block Snatch' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Box Jump' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Box Step-Over' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Box jump over' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Broad jump' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Burpee to target' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Candlestick' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'monostructural',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Cinta / carrera' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Clean' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Clean Pull' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Clean and Jerk' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Clean and Press' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Cruce de poleas' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'core',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Crunch' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'core',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Crunch en polea' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'pull',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl barra' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'hinge',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl femoral' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'hinge',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl femoral sentado' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'hinge',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl femoral tumbado' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'pull',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl inclinado con mancuernas' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'pull',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl predicador' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dead Hang' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'pull',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dominadas en anillas' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'lunge',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Double Dumbbell Step Up' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Drop snatch' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Elevaciones laterales en polea' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'squat',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Elevación de gemelos' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Elevación de piernas' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'core',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Extensión de cuádriceps' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'False grip hang' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'carry',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Farmer walk' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Fondos' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Fondos en anillas kipping' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Fondos en banco' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Front lever tuck' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'German hang' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'squat',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hack squat' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hang Clean' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hang Snatch' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hang Squat Clean' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hang Squat Snatch' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hip to bar' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Jerk Balance' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'squat',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Jumping squat' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'hinge',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kip swing' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Muscle Clean' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Muscle Snatch' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'pull',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Muscle-up estricto anillas' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Paso lateral con banda' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pause Clean' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'squat',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pause Front Squat' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pause Snatch' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pec deck' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Planche tuck' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Power Clean' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Power Snatch' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Power jerk' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'squat',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Prensa' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press banca declinado' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press mancuernas' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press militar' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press to handstand' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'pull',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pull-over barra' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pájaros' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'pull',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo al mentón' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'pull',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo con apoyo de pecho' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'pull',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo en T' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'pull',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo invertido' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sandbag over shoulder' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Seated Box Jump' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sentadilla a cajón con mancuernas' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'lunge',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sentadilla búlgara con mancuernas' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'push',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sentadilla en Smith' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'monostructural',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Skin the cat' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Snatch' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Snatch Balance' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Snatch Pull' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Snatch-Grip Deadlift' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'conditioning',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Soporte en anillas' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Split Snatch' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'olympic',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Tall snatch' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'core',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Toes to bar estrictos' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'core',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'V-sit' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'carry',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Wall walk' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET movement_pattern = 'core',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Woodchop en polea' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera','CARs de cuello']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = '90/90 con elevación de rodilla' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera','CARs de cuello']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = '90/90 con inclinación frontal' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera','CARs de cuello']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = '90/90 de cadera' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel','Side Plank']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Ab Mat Sit-Up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Side Plank']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Ab wheel' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aducción de cadera en máquina','Air squat','Barbell Squat Jump','Box Squat','Cossack squat','Dumbbell Front Squat','Dumbbell Overhead Squat','Dumbbell Thruster']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Abducción de cadera en máquina' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Abducción de cadera en máquina','Air squat','Barbell Squat Jump','Box Squat','Cossack squat','Dumbbell Front Squat','Dumbbell Overhead Squat','Dumbbell Thruster']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Aducción de cadera en máquina' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Press banca declinado','Pec deck','Press banca inclinada','Press banca','Dumbbell Bench Press','Floor Press','Dumbbell Floor Press','Axle Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Aperturas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Dumbbell Hang Split Snatch','Hanging Knee Raise','False grip hang','Candlestick','Dumbbell Hang Squat Clean','Dead Hang']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Arch hold' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Dominadas supinas','Burpee pull-up','Dominadas kipping','Dominadas','Burpee Muscle-Up','Jalón al pecho','Negative Pull Up','Burpee Bar Muscle Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Archer pull-up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sandbag Carry','Sandbag Ground To Shoulder','Sandbag over shoulder','Sandbag clean','Log Carry','Sandbag Squat','Sandbag Lunges','Keg Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Atlas Stone Over Shoulder' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press','Dumbbell Push Jerk']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Axle Press' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla búlgara','Dumbbell Box Step Up','Zancadas','Sandbag Lunges','Back rack reverse lunge','Front rack lunge','Kettlebell Front Rack Lunge','Kettlebell Goblet Box Step-Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Back Rack Lunge' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Arch hold','Dumbbell Hang Split Snatch','Hanging Knee Raise','False grip hang','Candlestick','Dumbbell Hang Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Back lever tuck' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla búlgara','Dumbbell Box Step Up','Zancadas','Sandbag Lunges','Front rack lunge','Kettlebell Front Rack Lunge','Kettlebell Goblet Box Step-Up','Box Step-Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Back rack reverse lunge' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Bar facing burpee','Battle Rope','Bear crawl','Bird Dog','Burpee','Burpee Bar Muscle Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Ball slam' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Burpee pull-up','Burpee to target','Burpee Broad Jump','Lateral Burpee','Burpee Muscle-Up','Burpee Over The Bar','Burpee Bar Muscle Up','Dumbbell Burpee Deadlift']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Bar facing burpee' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Barbell Squat Jump' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla búlgara','Dumbbell Box Step Up','Zancadas','Sandbag Lunges','Back rack reverse lunge','Front rack lunge','Kettlebell Front Rack Lunge','Kettlebell Goblet Box Step-Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Barbell Step Up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope','Bird Dog','Burpee','Burpee Bar Muscle Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Bear crawl' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera','CARs de cuello']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Bear sit con rotación' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Alternating Dumbbell Snatch','Block Clean','Block Snatch','Bodyweight Clean And Jerk','Clean','Clean and Jerk','Clean and Press','Clean Pull']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Behind-the-Neck Jerk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press','Dumbbell Push Jerk']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Behind-the-Neck Press' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Echo bike','Remo con apoyo de pecho','Jalón al pecho','Air bike','Bike Erg','Cinta / carrera','Crossover Single Under','Jumping Jack']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Bici estática' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope','Bear crawl','Burpee','Burpee Bar Muscle Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Bird Dog' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Buenos días con pica','CARs de cadera','CARs de cuello']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Bisagra de cadera sin carga' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Block Clean' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Block Power Clean' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Snatch Pull','Snatch Balance','Snatch High Pull','Snatch-Grip Deadlift','Dumbbell Hang Split Snatch','Pause Snatch']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Block Power Snatch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Snatch Pull','Snatch Balance','Snatch High Pull','Snatch-Grip Deadlift','Dumbbell Hang Split Snatch','Pause Snatch']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Block Snatch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean','Dumbbell Squat Clean Thruster']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Bodyweight Clean And Jerk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Air bike','Arch hold','Back lever tuck','Box jump over','Broad jump','Burpee Broad Jump','Burpee to target','Candlestick']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Box Jump' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press','Dumbbell Push Jerk']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Box Step-Over' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla búlgara','Dumbbell Box Step Up','Zancadas','Sandbag Lunges','Back rack reverse lunge','Front rack lunge','Kettlebell Front Rack Lunge','Kettlebell Goblet Box Step-Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Box Step-Up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Air bike','Arch hold','Back lever tuck','Box Jump','Broad jump','Burpee Broad Jump','Burpee to target','Candlestick']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Box jump over' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Press Arnold','Press militar','Push press','Push jerk','Dumbbell Push Press','Kettlebell Push Press','Dumbbell Shoulder Press','Strict press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Bradford Press' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Air bike','Arch hold','Back lever tuck','Box Jump','Box jump over','Burpee Broad Jump','Burpee to target','Candlestick']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Broad jump' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Curl femoral','Curl femoral sentado','Curl femoral tumbado','D-Ball Over Shoulder','Deficit Deadlift']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Buenos días' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','CARs de cadera','CARs de cuello']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Buenos días con pica' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Burpee pull-up','Burpee to target','Burpee Broad Jump','Lateral Burpee','Burpee Muscle-Up','Burpee Over The Bar','Burpee Bar Muscle Up','Dumbbell Burpee Deadlift']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Burpee' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Dominadas supinas','Burpee pull-up','Dominadas kipping','Dominadas','Burpee Muscle-Up','Jalón al pecho','Negative Pull Up','Dominadas butterfly']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Burpee Bar Muscle Up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Burpee pull-up','Burpee to target','Burpee Broad Jump','Lateral Burpee','Burpee Muscle-Up','Burpee Over The Bar','Burpee Bar Muscle Up','Dumbbell Burpee Deadlift']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Burpee Box Jump' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Burpee pull-up','Burpee to target','Lateral Burpee','Burpee Muscle-Up','Burpee Over The Bar','Burpee Bar Muscle Up','Dumbbell Burpee Deadlift','Burpee box jump over']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Burpee Broad Jump' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla a cajón con mancuernas','Dumbbell Overhead Squat','Curl inclinado con mancuernas','Dumbbell Front Squat','Dumbbell Squat Clean','Dumbbell Hang Split Snatch','Dumbbell Clean and Jerk','Dumbbell Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Burpee Over Dumbbell' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Burpee pull-up','Burpee to target','Burpee Broad Jump','Lateral Burpee','Burpee Muscle-Up','Burpee Bar Muscle Up','Dumbbell Burpee Deadlift','Burpee box jump over']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Burpee Over The Bar' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Burpee pull-up','Burpee to target','Burpee Broad Jump','Lateral Burpee','Burpee Muscle-Up','Burpee Over The Bar','Burpee Bar Muscle Up','Dumbbell Burpee Deadlift']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Burpee box jump over' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Dominadas supinas','Dominadas kipping','Dominadas','Burpee Muscle-Up','Jalón al pecho','Negative Pull Up','Burpee Bar Muscle Up','Dominadas butterfly']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Burpee pull-up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Burpee pull-up','Burpee Broad Jump','Lateral Burpee','Burpee Muscle-Up','Burpee Over The Bar','Burpee Bar Muscle Up','Dumbbell Burpee Deadlift','Burpee box jump over']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Burpee to target' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cuello']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'CARs de cadera' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'CARs de cuello' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'CARs de hombro' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'CARs de tobillo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Arch hold','Dumbbell Hang Split Snatch','Hanging Knee Raise','False grip hang','Dumbbell Hang Squat Clean','Dead Hang']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Candlestick' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Run','Shuttle run','Crunch en polea','Crunch','Bici estática','Bike Erg','Crossover Single Under','Jumping Jack']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Cinta / carrera' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Peso muerto','Trap Bar Deadlift','Snatch-Grip Deadlift','Axle Deadlift','Dumbbell Deadlift','Stiff Legged Deadlift','Zercher Deadlift','Dumbbell Burpee Deadlift']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Clean Deadlift' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean','Dumbbell Squat Clean Thruster']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Clean High Pull' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Clean Pull' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Clean and Press' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Colgado activo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Colgado pasivo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Copenhagen Plank' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Cossack squat' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Couch stretch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Zercher Carry','Suitcase Carry','Sandbag Carry','Log Carry','Handstand walk','Dumbbell Carry','Double Kettlebell Overhead Carry','Double Kettlebell Farmers Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Crab Walk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Triple-Under','Single-Under','Double-Under','Bici estática','Bike Erg','Cinta / carrera','Jumping Jack','Remo máquina']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Crossover Single Under' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Dumbbell Bench Press','Dumbbell Floor Press','Dumbbell Push Jerk']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Cruce de poleas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Crunch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Crunch en polea' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Curl inclinado con mancuernas','Curl predicador','Curl martillo','Curl mancuernas','Archer pull-up','Chest to bar','Dominadas','Dominadas butterfly']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl barra' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Curl femoral tumbado','Curl femoral sentado','Ring Hamstring Curl','Nordic Curl','American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl femoral' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Curl femoral','Curl femoral tumbado','Ring Hamstring Curl','Nordic Curl','American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl femoral sentado' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Curl femoral','Curl femoral sentado','Ring Hamstring Curl','Nordic Curl','American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl femoral tumbado' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla a cajón con mancuernas','Dumbbell Overhead Squat','Dumbbell Front Squat','Dumbbell Squat Clean','Dumbbell Hang Split Snatch','Dumbbell Clean and Jerk','Dumbbell Carry','Dumbbell Box Step Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl inclinado con mancuernas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla a cajón con mancuernas','Dumbbell Overhead Squat','Curl inclinado con mancuernas','Dumbbell Front Squat','Dumbbell Squat Clean','Dumbbell Hang Split Snatch','Dumbbell Clean and Jerk','Dumbbell Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl mancuernas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Curl barra','Curl inclinado con mancuernas','Curl predicador','Curl mancuernas','Archer pull-up','Chest to bar','Dominadas','Dominadas butterfly']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl martillo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Curl barra','Curl inclinado con mancuernas','Curl martillo','Curl mancuernas','Archer pull-up','Chest to bar','Dominadas','Dominadas butterfly']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Curl predicador' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Círculos de hombros' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Círculos de muñecas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Círculos de tobillo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Atlas Stone Over Shoulder','Sandbag Carry','Sandbag Ground To Shoulder','Sandbag over shoulder','Sandbag clean','Log Carry','Sandbag Squat','Sandbag Lunges']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'D-Ball Clean' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Atlas Stone Over Shoulder','Sandbag Carry','Sandbag Ground To Shoulder','Sandbag over shoulder','Sandbag clean','Log Carry','Sandbag Squat','Sandbag Lunges']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'D-Ball Over Shoulder' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope','Bear crawl','Bird Dog','Burpee']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dead Bug' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Arch hold','Dumbbell Hang Split Snatch','Hanging Knee Raise','False grip hang','Candlestick','Dumbbell Hang Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dead Hang' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Deslizamiento neural suave' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Deslizamientos en pared' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Alternating Dumbbell Snatch','Behind-the-Neck Jerk','Block Clean','Block Snatch','Bodyweight Clean And Jerk','Clean','Clean and Jerk','Clean and Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Devil press' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Dominadas supinas','Burpee pull-up','Dominadas kipping','Dominadas','Burpee Muscle-Up','Jalón al pecho','Negative Pull Up','Burpee Bar Muscle Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dominadas en anillas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Burpee pull-up','Dominadas kipping','Dominadas','Burpee Muscle-Up','Jalón al pecho','Negative Pull Up','Burpee Bar Muscle Up','Dominadas butterfly']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dominadas supinas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dorsiflexión de tobillo con banda' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla a cajón con mancuernas','Dumbbell Overhead Squat','Curl inclinado con mancuernas','Dumbbell Front Squat','Dumbbell Squat Clean','Dumbbell Hang Split Snatch','Dumbbell Clean and Jerk','Dumbbell Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Double Dumbbell Step Up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Zercher Carry','Suitcase Carry','Sandbag Carry','Log Carry','Handstand walk','Dumbbell Carry','Double Kettlebell Overhead Carry','Double Kettlebell Farmers Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Double Kettlebell Front Rack Carry' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla búlgara','Dumbbell Box Step Up','Zancadas','Sandbag Lunges','Back rack reverse lunge','Front rack lunge','Kettlebell Front Rack Lunge','Kettlebell Goblet Box Step-Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Double Kettlebell Front Rack Lunge' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Zercher Carry','Suitcase Carry','Sandbag Carry','Log Carry','Handstand walk','Dumbbell Carry','Double Kettlebell Farmers Carry','Keg Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Double Kettlebell Overhead Carry' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Snatch Pull','Snatch Balance','Snatch High Pull','Snatch-Grip Deadlift','Dumbbell Hang Split Snatch','Pause Snatch']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Drop snatch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla a cajón con mancuernas','Dumbbell Overhead Squat','Curl inclinado con mancuernas','Dumbbell Front Squat','Dumbbell Squat Clean','Dumbbell Hang Split Snatch','Dumbbell Clean and Jerk','Dumbbell Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Box Step Up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Peso muerto','Clean Deadlift','Trap Bar Deadlift','Snatch-Grip Deadlift','Axle Deadlift','Dumbbell Deadlift','Stiff Legged Deadlift','Zercher Deadlift']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Burpee Deadlift' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Hang Clean To Overhead' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Hang Clean and Jerk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Hang Power Clean' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Snatch Pull','Snatch Balance','Snatch High Pull','Snatch-Grip Deadlift','Pause Snatch','Snatch']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Hang Split Snatch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Hang Squat Clean' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Zercher Carry','Suitcase Carry','Sandbag Carry','Log Carry','Handstand walk','Dumbbell Carry','Double Kettlebell Overhead Carry','Double Kettlebell Farmers Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Overhead Carry' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean','Overhead squat']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Overhead Squat' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Press Arnold','Press militar','Push press','Push jerk','Bradford Press','Dumbbell Push Press','Kettlebell Push Press','Strict press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Shoulder Press' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla a cajón con mancuernas','Dumbbell Overhead Squat','Curl inclinado con mancuernas','Dumbbell Front Squat','Dumbbell Squat Clean','Dumbbell Hang Split Snatch','Dumbbell Clean and Jerk','Dumbbell Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Shoulder To Overhead' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Split Clean' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean','Dumbbell Squat Clean Thruster']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Squat Clean' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Cluster','Thruster','Single Arm Dumbbell Thruster','Dumbbell Thruster','Kettlebell Thruster','Single Arm Kettlebell Thruster','Clean Deadlift','Sandbag clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Squat Clean Thruster' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Zercher Carry','Suitcase Carry','Sandbag Carry','Log Carry','Handstand walk','Dumbbell Carry','Double Kettlebell Overhead Carry','Double Kettlebell Farmers Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Dumbbell Waiters Walk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Elevaciones escapulares' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Elevaciones frontales' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Elevaciones laterales' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Elevaciones laterales en polea' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Abducción de cadera en máquina','Aducción de cadera en máquina','Air squat','Barbell Squat Jump','Box Squat','Cossack squat','Dumbbell Front Squat','Dumbbell Overhead Squat']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Elevación de gemelos' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Elevación de piernas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Elevación de tibial anterior' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Enhebrar la aguja' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Estiramiento de cuádriceps de pie' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Estiramiento de dorsal en banco' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Estiramiento de gemelo en pared' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Estiramiento de hombro cruzado' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Estiramiento de isquios con banda' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Estiramiento de sóleo en pared' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Estiramiento del flexor de cadera' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Estiramiento dinámico de isquios' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Estiramiento pectoral en puerta' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Extensión activa de cadera de pie' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Extensión cervical suave' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Extensión controlada de codo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope','Bear crawl','Bird Dog','Burpee']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Extensión de cuádriceps' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Extensión torácica con rodillo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Extensión tríceps polea' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Remo pliométrico en anillas pies elevados','Remo máquina','Remo en anillas','Remo sentado','Renegade Row','Remo mancuerna','Remo con apoyo de pecho','Pendlay Row']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Face pull' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Arch hold','Dumbbell Hang Split Snatch','Hanging Knee Raise','Candlestick','Dumbbell Hang Squat Clean','Dead Hang']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'False grip hang' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Figura cuatro tumbado' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Flexiones escapulares' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Flexión activa de cadera de pie' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Flexión cervical suave' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Flexión controlada de codo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Flexión de rodilla en apoyo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Flexión plantar de tobillo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Flexión segmentaria de columna' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope','Bear crawl','Bird Dog','Burpee']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Flutter Kick' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jerk Dip and Drive','Fondos en anillas','Fondos en banco','Fondos en paralelas','Fondos en anillas kipping','Aperturas','Axle Press','Behind-the-Neck Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Fondos' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jerk Dip and Drive','Fondos en anillas','Fondos','Fondos en banco','Fondos en paralelas','Aperturas','Axle Press','Behind-the-Neck Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Fondos en anillas kipping' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jerk Dip and Drive','Fondos en anillas','Fondos','Fondos en paralelas','Fondos en anillas kipping','Aperturas','Axle Press','Behind-the-Neck Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Fondos en banco' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Frog stretch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Arch hold','Dumbbell Hang Split Snatch','Hanging Knee Raise','False grip hang','Candlestick','Dumbbell Hang Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Front lever tuck' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días','Curl femoral','Curl femoral sentado','Curl femoral tumbado','D-Ball Over Shoulder']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'GHD back extension' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','Toes to bar estrictos','Hanging Knee Raise','Ab wheel','Side Plank']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'GHD sit-up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Gato-vaca' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Arch hold','Dumbbell Hang Split Snatch','Hanging Knee Raise','False grip hang','Candlestick','Dumbbell Hang Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'German hang' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días','Curl femoral','Curl femoral sentado','Curl femoral tumbado','D-Ball Over Shoulder']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Glute Bridge' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días','Curl femoral','Curl femoral sentado','Curl femoral tumbado','D-Ball Over Shoulder']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Glute Ham Raise' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Alternating Dumbbell Snatch','Behind-the-Neck Jerk','Block Clean','Block Snatch','Bodyweight Clean And Jerk','Clean','Clean and Jerk','Clean and Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Ground to overhead' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hack squat' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope','Bear crawl','Bird Dog','Burpee']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Handstand hold' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Zercher Carry','Suitcase Carry','Sandbag Carry','Log Carry','Dumbbell Carry','Double Kettlebell Overhead Carry','Double Kettlebell Farmers Carry','Keg Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Handstand walk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Arch hold','Dumbbell Hang Split Snatch','Hanging Knee Raise','False grip hang','Candlestick','Dumbbell Hang Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hang High Pull' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Arch hold','Dumbbell Hang Split Snatch','Hanging Knee Raise','False grip hang','Candlestick','Dumbbell Hang Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hanging Hip Touch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Ab wheel','Side Plank']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hanging Knee Raise' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días','Curl femoral','Curl femoral sentado','Curl femoral tumbado','D-Ball Over Shoulder']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hip thrust' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hip to bar' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hollow hold' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel','Side Plank']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Hollow rock' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Zercher Carry','Suitcase Carry','Sandbag Carry','Log Carry','Handstand walk','Dumbbell Carry','Double Kettlebell Overhead Carry','Double Kettlebell Farmers Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Husafell Carry' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Inchworm' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Inclinación lateral cervical' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Inclinación lateral de tronco' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Inversión y eversión de tobillo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Echo bike','Remo con apoyo de pecho','Air bike','Bike Erg','Bici estática','Dominadas supinas','Burpee pull-up','Dominadas kipping']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Jalón al pecho' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días','Curl femoral','Curl femoral sentado','Curl femoral tumbado','D-Ball Over Shoulder']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Jefferson Curl' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Alternating Dumbbell Snatch','Behind-the-Neck Jerk','Block Clean','Block Snatch','Bodyweight Clean And Jerk','Clean','Clean and Jerk','Clean and Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Jerk Balance' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Fondos en anillas','Fondos','Fondos en banco','Fondos en paralelas','Fondos en anillas kipping']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Jerk Dip and Drive' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Zercher Carry','Suitcase Carry','Sandbag Carry','Log Carry','Handstand walk','Dumbbell Carry','Double Kettlebell Overhead Carry','Double Kettlebell Farmers Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Jerry Bag Carry' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Bici estática','Bike Erg','Cinta / carrera','Crossover Single Under','Remo máquina','SkiErg','Skin the cat']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Jumping Jack' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla búlgara','Dumbbell Box Step Up','Zancadas','Sandbag Lunges','Back rack reverse lunge','Front rack lunge','Kettlebell Front Rack Lunge','Kettlebell Goblet Box Step-Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Jumping lunge' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean','Overhead squat']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Jumping squat' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Zercher Carry','Suitcase Carry','Sandbag Carry','Log Carry','Handstand walk','Dumbbell Carry','Double Kettlebell Overhead Carry','Double Kettlebell Farmers Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Keg Carry' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kettlebell Clean and Jerk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla búlgara','Dumbbell Box Step Up','Zancadas','Sandbag Lunges','Back rack reverse lunge','Front rack lunge','Kettlebell Goblet Box Step-Up','Box Step-Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kettlebell Front Rack Lunge' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kettlebell Goblet Box Step-Up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Double Kettlebell Overhead Carry','Kettlebell Clean','Double Kettlebell Farmers Carry','Kettlebell Front Rack Lunge','Kettlebell Windmill','Kettlebell Goblet Box Step-Up','Kettlebell Swing','American Kettlebell Swing']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kettlebell Halo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Peso muerto','Clean Deadlift','Trap Bar Deadlift','Snatch-Grip Deadlift','Axle Deadlift','Dumbbell Deadlift','Stiff Legged Deadlift','Zercher Deadlift']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kettlebell Sumo Deadlift High Pull' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Kettlebell Halo','Double Kettlebell Overhead Carry','Kettlebell Clean','Double Kettlebell Farmers Carry','Kettlebell Front Rack Lunge','Kettlebell Goblet Box Step-Up','Kettlebell Swing','American Kettlebell Swing']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kettlebell Windmill' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Kettlebell Swing','American Kettlebell Swing','Single Arm Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días','Curl femoral','Curl femoral sentado']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Kip swing' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope','Bear crawl','Bird Dog','Burpee']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Knees to elbows' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope','Bear crawl','Bird Dog','Burpee']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'L-sit' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Landmine Press' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Burpee pull-up','Burpee to target','Burpee Broad Jump','Burpee Muscle-Up','Burpee Over The Bar','Burpee Bar Muscle Up','Dumbbell Burpee Deadlift','Burpee box jump over']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Lateral Burpee' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla búlgara','Dumbbell Box Step Up','Zancadas','Sandbag Lunges','Back rack reverse lunge','Front rack lunge','Kettlebell Front Rack Lunge','Kettlebell Goblet Box Step-Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Lateral Lunge' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Libro abierto' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Zercher Carry','Suitcase Carry','Sandbag Carry','Handstand walk','Dumbbell Carry','Double Kettlebell Overhead Carry','Double Kettlebell Farmers Carry','Keg Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Log Carry' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Atlas Stone Over Shoulder','Sandbag Carry','Sandbag Ground To Shoulder','Sandbag over shoulder','Sandbag clean','Log Carry','Sandbag Squat','Sandbag Lunges']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Log Clean And Jerk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Atlas Stone Over Shoulder','Sandbag Carry','Sandbag Ground To Shoulder','Sandbag over shoulder','Sandbag clean','Log Carry','Sandbag Squat','Sandbag Lunges']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Log Press' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Man maker' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Mariposa sentada' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Medball clean' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Back Rack Lunge','Back rack reverse lunge','Barbell Step Up','Box Step-Up','Double Dumbbell Step Up','Double Kettlebell Front Rack Lunge','Dumbbell Box Step Up','Dumbbell Front Rack Lunge']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Medicine Ball Box Step Over' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Medicine Ball Sit Up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Remo pliométrico en anillas pies elevados','Remo máquina','Remo en anillas','Remo sentado','Renegade Row','Remo mancuerna','Remo con apoyo de pecho','Pendlay Row']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Medicine Ball Throw' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope','Bear crawl','Bird Dog','Burpee']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Mountain Climber' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Movilidad de muñeca en extensión' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Movilidad de muñeca en flexión' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Curl femoral','Curl femoral tumbado','Curl femoral sentado','Ring Hamstring Curl','American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Nordic Curl' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Zercher Carry','Suitcase Carry','Sandbag Carry','Log Carry','Handstand walk','Dumbbell Carry','Double Kettlebell Overhead Carry','Double Kettlebell Farmers Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Overhead Walk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pallof Press' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Archer pull-up','Chest to bar','Curl barra','Curl inclinado con mancuernas','Curl mancuernas','Curl martillo','Curl predicador','Dominadas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Parallel Bar Traverse' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pasadas de hombros con pica' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Paso lateral con banda' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pause Clean' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pause Front Squat' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Snatch Pull','Snatch Balance','Snatch High Pull','Snatch-Grip Deadlift','Dumbbell Hang Split Snatch','Snatch']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pause Snatch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Press banca declinado','Press banca inclinada','Press banca','Dumbbell Bench Press','Aperturas','Floor Press','Dumbbell Floor Press','Axle Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pec deck' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Archer pull-up','Chest to bar','Curl barra','Curl inclinado con mancuernas','Curl mancuernas','Curl martillo','Curl predicador','Dominadas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pegboard' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Remo pliométrico en anillas pies elevados','Remo máquina','Remo en anillas','Remo sentado','Renegade Row','Remo mancuerna','Remo con apoyo de pecho','Remo con barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pendlay Row' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Perro boca abajo dinámico' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pistol squat' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel','Side Plank']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Plancha' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Arch hold','Dumbbell Hang Split Snatch','Hanging Knee Raise','False grip hang','Candlestick','Dumbbell Hang Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Planche tuck' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Alternating Dumbbell Snatch','Behind-the-Neck Jerk','Block Clean','Block Snatch','Bodyweight Clean And Jerk','Clean','Clean and Jerk','Clean and Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Plate ground to overhead' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Postura de la esfinge' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Postura de la paloma' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Postura del niño' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Postura del niño lateral' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Alternating Dumbbell Snatch','Behind-the-Neck Jerk','Block Clean','Block Snatch','Bodyweight Clean And Jerk','Clean','Clean and Jerk','Clean and Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Power jerk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Prensa' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Press militar','Push press','Push jerk','Bradford Press','Dumbbell Push Press','Kettlebell Push Press','Dumbbell Shoulder Press','Strict press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press Arnold' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Pec deck','Press banca inclinada','Press banca','Dumbbell Bench Press','Aperturas','Floor Press','Dumbbell Floor Press','Axle Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press banca declinado' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press cerrado' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press francés' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Press Arnold','Push press','Push jerk','Bradford Press','Dumbbell Push Press','Kettlebell Push Press','Dumbbell Shoulder Press','Strict press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press militar' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Press to handstand' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pronación y supinación de antebrazo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Protracción y retracción escapular' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Puente de glúteo articulado' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Archer pull-up','Chest to bar','Curl barra','Curl inclinado con mancuernas','Curl mancuernas','Curl martillo','Curl predicador','Dominadas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pull-over barra' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Archer pull-up','Chest to bar','Curl barra','Curl inclinado con mancuernas','Curl mancuernas','Curl martillo','Curl predicador','Dominadas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pullover' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Pájaros' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Remo pliométrico en anillas pies elevados','Remo máquina','Remo en anillas','Remo sentado','Renegade Row','Remo mancuerna','Remo con apoyo de pecho','Pendlay Row']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo al mentón' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Echo bike','Jalón al pecho','Air bike','Bike Erg','Bici estática','Remo pliométrico en anillas pies elevados','Remo máquina','Remo en anillas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo con apoyo de pecho' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Remo pliométrico en anillas pies elevados','Remo máquina','Remo en anillas','Remo sentado','Renegade Row','Remo mancuerna','Remo con apoyo de pecho','Pendlay Row']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo con barra' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Remo pliométrico en anillas pies elevados','Remo máquina','Remo en anillas','Remo sentado','Renegade Row','Remo mancuerna','Remo con apoyo de pecho','Pendlay Row']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo en T' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Remo pliométrico en anillas pies elevados','Remo máquina','Remo sentado','Renegade Row','Remo mancuerna','Remo con apoyo de pecho','Pendlay Row','Remo con barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo en anillas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Remo pliométrico en anillas pies elevados','Remo máquina','Remo en anillas','Remo sentado','Renegade Row','Remo mancuerna','Remo con apoyo de pecho','Pendlay Row']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo invertido' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla a cajón con mancuernas','Dumbbell Overhead Squat','Curl inclinado con mancuernas','Dumbbell Front Squat','Dumbbell Squat Clean','Dumbbell Hang Split Snatch','Dumbbell Clean and Jerk','Dumbbell Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo mancuerna' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Remo máquina','Remo en anillas','Remo sentado','Renegade Row','Remo mancuerna','Remo con apoyo de pecho','Pendlay Row','Remo con barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo pliométrico en anillas pies elevados' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Remo pliométrico en anillas pies elevados','Remo máquina','Remo en anillas','Renegade Row','Remo mancuerna','Remo con apoyo de pecho','Pendlay Row','Remo con barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Remo sentado' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Remo pliométrico en anillas pies elevados','Remo máquina','Remo en anillas','Remo sentado','Remo mancuerna','Remo con apoyo de pecho','Pendlay Row','Remo con barra']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Renegade Row' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Respiración diafragmática 90/90' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Retracción cervical' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días','Curl femoral','Curl femoral sentado','Curl femoral tumbado','D-Ball Over Shoulder']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Reverse Hyper' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Curl femoral','Curl femoral tumbado','Curl femoral sentado','Nordic Curl','American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Ring Hamstring Curl' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Archer pull-up','Chest to bar','Curl barra','Curl inclinado con mancuernas','Curl mancuernas','Curl martillo','Curl predicador','Dominadas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Ring Lower' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Rockback de aductores' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Rockback global en cuadrupedia' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Rodilla a pared para tobillo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Rodilla sobre dedos controlada' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Rotación cervical' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Rotación de tronco tumbado' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Rotación externa de hombro con banda' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Rotación interna de cadera sentado' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Rotación interna de hombro' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Rotación torácica en cuadrupedia' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Rotación torácica en pared' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Rotación torácica sentado' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope','Bear crawl','Bird Dog','Burpee']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Russian Twist' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Atlas Stone Over Shoulder','Sandbag Carry','Sandbag over shoulder','Sandbag clean','Log Carry','Sandbag Squat','Sandbag Lunges','Keg Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sandbag Ground To Shoulder' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Atlas Stone Over Shoulder','Sandbag Carry','Sandbag Ground To Shoulder','Sandbag over shoulder','Sandbag clean','Log Carry','Sandbag Squat','Sandbag Lunges']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sandbag Load To Box' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Atlas Stone Over Shoulder','Sandbag Carry','Sandbag Ground To Shoulder','Sandbag over shoulder','Sandbag clean','Log Carry','Sandbag Squat','Keg Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sandbag Lunges' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Atlas Stone Over Shoulder','Sandbag Carry','Sandbag Ground To Shoulder','Sandbag over shoulder','Sandbag clean','Log Carry','Sandbag Squat','Sandbag Lunges']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sandbag Over Log' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Atlas Stone Over Shoulder','Sandbag Carry','Sandbag Ground To Shoulder','Sandbag over shoulder','Sandbag clean','Log Carry','Sandbag Lunges','Keg Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sandbag Squat' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Atlas Stone Over Shoulder','Sandbag Carry','Sandbag Ground To Shoulder','Sandbag over shoulder','Log Carry','Sandbag Squat','Sandbag Lunges','Keg Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sandbag clean' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Atlas Stone Over Shoulder','Sandbag Carry','Sandbag Ground To Shoulder','Sandbag clean','Log Carry','Sandbag Squat','Sandbag Lunges','Keg Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sandbag over shoulder' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Air bike','Arch hold','Back lever tuck','Box Jump','Box jump over','Broad jump','Burpee Broad Jump','Burpee to target']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Seated Box Jump' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sentadilla Cossack de movilidad' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean','Overhead squat']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sentadilla a cajón con mancuernas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean','Overhead squat']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sentadilla búlgara' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sentadilla búlgara con mancuernas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sentadilla en Smith' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Dumbbell Squat Clean','Overhead squat']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sentadilla profunda con balanceo' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sentadilla profunda sostenida' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Shrimp squat' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Side Plank' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días','Curl femoral','Curl femoral sentado','Curl femoral tumbado','D-Ball Over Shoulder']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Single Leg Glute Bridge' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Peso muerto','Clean Deadlift','Trap Bar Deadlift','Snatch-Grip Deadlift','Axle Deadlift','Dumbbell Deadlift','Stiff Legged Deadlift','Zercher Deadlift']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Single Leg Romanian Deadlift' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sit-up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Air bike','Arch hold','Back lever tuck','Box Jump','Box jump over','Broad jump','Burpee Broad Jump','Burpee to target']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Skater Jump' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Arch hold','Dumbbell Hang Split Snatch','Hanging Knee Raise','False grip hang','Candlestick','Dumbbell Hang Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Skin the cat' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sledgehammer Strike','Sled push','Sled pull','Archer pull-up','Chest to bar','Curl barra','Curl inclinado con mancuernas','Curl mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sled Drag' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sledgehammer Strike','Sled push','Sled Drag','Archer pull-up','Chest to bar','Curl barra','Curl inclinado con mancuernas','Curl mancuernas']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sled pull' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sledgehammer Strike','Sled pull','Sled Drag','Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sled push' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sled push','Sled pull','Sled Drag','Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sledgehammer Strike' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Snatch Pull','Snatch High Pull','Snatch-Grip Deadlift','Dumbbell Hang Split Snatch','Pause Snatch','Snatch']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Snatch Balance' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Snatch Pull','Snatch Balance','Snatch-Grip Deadlift','Dumbbell Hang Split Snatch','Pause Snatch','Snatch']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Snatch High Pull' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Snatch Balance','Snatch High Pull','Snatch-Grip Deadlift','Dumbbell Hang Split Snatch','Pause Snatch','Snatch']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Snatch Pull' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Peso muerto','Clean Deadlift','Trap Bar Deadlift','Axle Deadlift','Dumbbell Deadlift','Stiff Legged Deadlift','Zercher Deadlift','Dumbbell Burpee Deadlift']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Snatch-Grip Deadlift' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Press Arnold','Press militar','Push press','Push jerk','Bradford Press','Dumbbell Push Press','Kettlebell Push Press','Dumbbell Shoulder Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Snatch-Grip Push Press' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Soporte en anillas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sots press' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Snatch Pull','Snatch Balance','Snatch High Pull','Snatch-Grip Deadlift','Dumbbell Hang Split Snatch','Pause Snatch']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Split Snatch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Split jerk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Squat Jerk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Peso muerto','Clean Deadlift','Trap Bar Deadlift','Snatch-Grip Deadlift','Axle Deadlift','Dumbbell Deadlift','Zercher Deadlift','Dumbbell Burpee Deadlift']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Stiff Legged Deadlift' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Strict Knee Raise' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope','Bear crawl','Bird Dog','Burpee']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Strict Knees To Chest' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días','Curl femoral','Curl femoral sentado','Curl femoral tumbado','D-Ball Over Shoulder']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Sumo high pull' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días','Curl femoral','Curl femoral sentado','Curl femoral tumbado','D-Ball Over Shoulder']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Superman' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Clean Deadlift','Sandbag clean','Bodyweight Clean And Jerk','Clean High Pull','Dumbbell Squat Clean','Dumbbell Clean and Jerk','Muscle Clean','Kettlebell Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Tall clean' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Hang power snatch','Hang Squat Snatch','Snatch Pull','Snatch Balance','Snatch High Pull','Snatch-Grip Deadlift','Dumbbell Hang Split Snatch','Pause Snatch']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Tall snatch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['American Kettlebell Swing','Atlas Stone Over Shoulder','Axle Deadlift','Buenos días','Curl femoral','Curl femoral sentado','Curl femoral tumbado','D-Ball Over Shoulder']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Tire Flip' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Toes to bar' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Hanging Knee Raise','Ab wheel','Side Plank']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Toes to bar estrictos' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Toes to rings' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Air bike','Arch hold','Back lever tuck','Box Jump','Box jump over','Broad jump','Burpee Broad Jump','Burpee to target']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Tuck Jump' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope','Bear crawl','Bird Dog','Burpee']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Turkish get-up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','Woodchop en polea','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'V-sit' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Ab wheel','Ball slam','Bar facing burpee','Battle Rope','Bear crawl','Bird Dog','Burpee']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'V-up' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Wall Climb' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Aperturas','Axle Press','Behind-the-Neck Press','Box Step-Over','Bradford Press','Cruce de poleas','Dumbbell Bench Press','Dumbbell Floor Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Wall Climb Over' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Wall Sit' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Abducción de cadera en máquina','Aducción de cadera en máquina','Air squat','Barbell Squat Jump','Box Squat','Cossack squat','Dumbbell Front Squat','Dumbbell Overhead Squat']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Wall ball' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Zercher Carry','Suitcase Carry','Sandbag Carry','Log Carry','Handstand walk','Dumbbell Carry','Double Kettlebell Overhead Carry','Double Kettlebell Farmers Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Wall walk' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Ab Mat Sit-Up','Hollow rock','Plancha','GHD sit-up','Toes to bar estrictos','Hanging Knee Raise','Ab wheel','Side Plank']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Woodchop en polea' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Ángeles en pared','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'World''s Greatest Stretch' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Press Arnold','Press militar','Push press','Push jerk','Bradford Press','Dumbbell Push Press','Kettlebell Push Press','Dumbbell Shoulder Press']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Z Press' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla búlgara','Dumbbell Box Step Up','Zancadas','Sandbag Lunges','Back rack reverse lunge','Front rack lunge','Kettlebell Front Rack Lunge','Kettlebell Goblet Box Step-Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Zancada Spiderman con rotación' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Sentadilla búlgara','Dumbbell Box Step Up','Sandbag Lunges','Back rack reverse lunge','Front rack lunge','Kettlebell Front Rack Lunge','Kettlebell Goblet Box Step-Up','Box Step-Up']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Zancadas' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Suitcase Carry','Sandbag Carry','Log Carry','Handstand walk','Dumbbell Carry','Double Kettlebell Overhead Carry','Double Kettlebell Farmers Carry','Keg Carry']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Zercher Carry' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Peso muerto','Clean Deadlift','Trap Bar Deadlift','Snatch-Grip Deadlift','Axle Deadlift','Dumbbell Deadlift','Stiff Legged Deadlift','Dumbbell Burpee Deadlift']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Zercher Deadlift' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['Jumping squat','Hang Squat Snatch','Sentadilla a cajón con mancuernas','Sentadilla búlgara','Dumbbell Overhead Squat','Dumbbell Front Squat','Sentadilla profunda con balanceo','Dumbbell Squat Clean']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Zercher Squat' AND c.is_active;

UPDATE public.training_exercise_metadata m
SET alternatives = ARRAY['90/90 con elevación de rodilla','90/90 con inclinación frontal','90/90 de cadera','Bear sit con rotación','Bisagra de cadera sin carga','Buenos días con pica','CARs de cadera','CARs de cuello']::text[],
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = 'Ángeles en pared' AND c.is_active;

