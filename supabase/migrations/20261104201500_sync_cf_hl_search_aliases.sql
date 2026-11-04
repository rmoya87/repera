-- Sync CrossFit/Halterofilia search aliases (ES formal + jerga + acrónimos EN/ES).
-- Title names stay English; catalog_key unchanged. cardinality(aliases)<=30.
-- Triggers emit mobile_exercise_catalog_events on metadata update.

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Arrancada','Snatch','full snatch','squat snatch','snatch completo','arrancada completa','arrancada olímpica','arrancada olimpica','sn','sq snatch']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Arrancada';

UPDATE public.business_exercise_catalog AS b
SET name = 'Snatch',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Snatch'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Arrancada'
  AND (b.name IS DISTINCT FROM 'Snatch'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Zancadas inversas con barra','Back rack reverse lunge','br reverse lunge','back rack r lunges','back rack reverse lunges','zancada inversa back rack','reverse lunge back rack']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Zancadas inversas con barra';

UPDATE public.business_exercise_catalog AS b
SET name = 'Back rack reverse lunge',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Back rack reverse lunge'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Zancadas inversas con barra'
  AND (b.name IS DISTINCT FROM 'Back rack reverse lunge'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Arrancada de potencia','Power Snatch','p snatch','psn','power snatches','arrancada alta','arrancada power','power arrancada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Arrancada de potencia';

UPDATE public.business_exercise_catalog AS b
SET name = 'Power Snatch',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Power Snatch'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Arrancada de potencia'
  AND (b.name IS DISTINCT FROM 'Power Snatch'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Arrancada colgante','Hang Snatch','hang sn','hang snatches','hsn','arrancada desde colgado','arrancada hang','hang arrancada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Arrancada colgante';

UPDATE public.business_exercise_catalog AS b
SET name = 'Hang Snatch',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Hang Snatch'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Arrancada colgante'
  AND (b.name IS DISTINCT FROM 'Hang Snatch'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Arrancada colgante completa','Hang Squat Snatch','hang full snatch','hs snatch','hssn','high hang squat snatch','hsq snatch','arrancada colgante profunda','arrancada hang squat']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Arrancada colgante completa';

UPDATE public.business_exercise_catalog AS b
SET name = 'Hang Squat Snatch',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Hang Squat Snatch'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Arrancada colgante completa'
  AND (b.name IS DISTINCT FROM 'Hang Squat Snatch'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Arrancada de potencia desde colgado','Hang power snatch','hpsn','hang p snatch','power snatch from hang','arrancada potencia colgante','hang power arrancada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Hang power snatch';

UPDATE public.business_exercise_catalog AS b
SET name = 'Hang power snatch',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Hang power snatch'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Hang power snatch'
  AND (b.name IS DISTINCT FROM 'Hang power snatch'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Arrancada muscular','Muscle Snatch','m snatch','muscle sn','arrancada sin recepción profunda','arrancada muscle']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Arrancada muscular';

UPDATE public.business_exercise_catalog AS b
SET name = 'Muscle Snatch',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Muscle Snatch'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Arrancada muscular'
  AND (b.name IS DISTINCT FROM 'Muscle Snatch'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Arrancada desde bloques','Block Snatch','snatch from blocks','block squat snatch','arrancada desde tacos','snatch bloques']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Arrancada desde bloques';

UPDATE public.business_exercise_catalog AS b
SET name = 'Block Snatch',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Block Snatch'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Arrancada desde bloques'
  AND (b.name IS DISTINCT FROM 'Block Snatch'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Arrancada con pausa','Pause Snatch','paused snatch','snatch with pause','arrancada pausada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Arrancada con pausa';

UPDATE public.business_exercise_catalog AS b
SET name = 'Pause Snatch',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Pause Snatch'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Arrancada con pausa'
  AND (b.name IS DISTINCT FROM 'Pause Snatch'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Balance de arrancada','Snatch Balance','sb snatch','snatch balance behind neck','recepcion arrancada con impulso','snatch bal']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Balance de arrancada';

UPDATE public.business_exercise_catalog AS b
SET name = 'Snatch Balance',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Snatch Balance'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Balance de arrancada'
  AND (b.name IS DISTINCT FROM 'Snatch Balance'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Arrancada bajo la barra','Drop snatch','snatch drop','drop into snatch','caida de arrancada','drop arrancada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Drop snatch';

UPDATE public.business_exercise_catalog AS b
SET name = 'Drop snatch',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Drop snatch'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Drop snatch'
  AND (b.name IS DISTINCT FROM 'Drop snatch'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Arrancada desde extensión','Tall snatch','tall sn','tall squat snatch','arrancada tall','arrancada de extensión']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Tall snatch';

UPDATE public.business_exercise_catalog AS b
SET name = 'Tall snatch',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Tall snatch'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Tall snatch'
  AND (b.name IS DISTINCT FROM 'Tall snatch'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Arrancada en split','Split Snatch','split sn','arrancada en tijera','split arrancada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Arrancada en split';

UPDATE public.business_exercise_catalog AS b
SET name = 'Split Snatch',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Split Snatch'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Arrancada en split'
  AND (b.name IS DISTINCT FROM 'Split Snatch'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Tirón de arrancada','Snatch Pull','sn pull','snatch pulls','tiron de arrancada','tiron de arrancada completo']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Tirón de arrancada';

UPDATE public.business_exercise_catalog AS b
SET name = 'Snatch Pull',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Snatch Pull'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Tirón de arrancada'
  AND (b.name IS DISTINCT FROM 'Snatch Pull'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Peso muerto agarre arrancada','Snatch-Grip Deadlift','snatch grip dl','sgdl','deadlift snatch grip','peso muerto agarre ancho','dl agarre arrancada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Peso muerto agarre arrancada';

UPDATE public.business_exercise_catalog AS b
SET name = 'Snatch-Grip Deadlift',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Snatch-Grip Deadlift'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Peso muerto agarre arrancada'
  AND (b.name IS DISTINCT FROM 'Snatch-Grip Deadlift'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada','Clean','full clean','squat clean','squat cleans','cargada completa','cargada olímpica','cargada olimpica','sq clean']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Cargada';

UPDATE public.business_exercise_catalog AS b
SET name = 'Clean',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Clean'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Cargada'
  AND (b.name IS DISTINCT FROM 'Clean'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada de potencia','Power Clean','pc','p clean','power cleans','cargada alta','cargada power']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Cargada de potencia';

UPDATE public.business_exercise_catalog AS b
SET name = 'Power Clean',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Power Clean'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Cargada de potencia'
  AND (b.name IS DISTINCT FROM 'Power Clean'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada colgante','Hang Clean','hang cleans','cargada desde colgado','hc','hang cargada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Cargada colgante';

UPDATE public.business_exercise_catalog AS b
SET name = 'Hang Clean',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Hang Clean'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Cargada colgante'
  AND (b.name IS DISTINCT FROM 'Hang Clean'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada colgante completa','Hang Squat Clean','hsc','hang full clean','hhsc','high hang squat clean','cargada colgante profunda']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Cargada colgante completa';

UPDATE public.business_exercise_catalog AS b
SET name = 'Hang Squat Clean',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Hang Squat Clean'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Cargada colgante completa'
  AND (b.name IS DISTINCT FROM 'Hang Squat Clean'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada de potencia desde colgado','Hang power clean','hpc','hang p clean','power clean from hang','cargada potencia colgante']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Hang power clean';

UPDATE public.business_exercise_catalog AS b
SET name = 'Hang power clean',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Hang power clean'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Hang power clean'
  AND (b.name IS DISTINCT FROM 'Hang power clean'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada muscular','Muscle Clean','m clean','cargada sin sentadilla']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Cargada muscular';

UPDATE public.business_exercise_catalog AS b
SET name = 'Muscle Clean',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Muscle Clean'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Cargada muscular'
  AND (b.name IS DISTINCT FROM 'Muscle Clean'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada desde bloques','Block Clean','clean from blocks','block squat clean','cargada desde tacos']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Cargada desde bloques';

UPDATE public.business_exercise_catalog AS b
SET name = 'Block Clean',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Block Clean'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Cargada desde bloques'
  AND (b.name IS DISTINCT FROM 'Block Clean'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada con pausa','Pause Clean','paused clean','clean with pause','cargada pausada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Cargada con pausa';

UPDATE public.business_exercise_catalog AS b
SET name = 'Pause Clean',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Pause Clean'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Cargada con pausa'
  AND (b.name IS DISTINCT FROM 'Pause Clean'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada desde extensión','Tall clean','tall c','cargada desde extension','tall cargada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Tall clean';

UPDATE public.business_exercise_catalog AS b
SET name = 'Tall clean',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Tall clean'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Tall clean'
  AND (b.name IS DISTINCT FROM 'Tall clean'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Tirón de cargada','Clean Pull','clean pull from floor','clean pulls','tiron de cargada','tiron de cargada completo']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Tirón de cargada';

UPDATE public.business_exercise_catalog AS b
SET name = 'Clean Pull',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Clean Pull'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Tirón de cargada'
  AND (b.name IS DISTINCT FROM 'Clean Pull'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada y press','Clean and Press','c&p','clean & press','cargada y press estricto']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Cargada y press';

UPDATE public.business_exercise_catalog AS b
SET name = 'Clean and Press',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Clean and Press'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Cargada y press'
  AND (b.name IS DISTINCT FROM 'Clean and Press'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada y envión','Clean and Jerk','c&j','cj','c+j','clean & jerk','clean & jerks','c and j','cargada y envion','dos tiempos','dos tiempos olímpicos','dos tiempos olimpicos','cargada y envion olimpico','c&j olímpico']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Cargada y envión';

UPDATE public.business_exercise_catalog AS b
SET name = 'Clean and Jerk',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Clean and Jerk'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Cargada y envión'
  AND (b.name IS DISTINCT FROM 'Clean and Jerk'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Press con impulso','Push press','pp','push presses','press de impulso','press con piernas']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Push press';

UPDATE public.business_exercise_catalog AS b
SET name = 'Push press',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Push press'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Push press'
  AND (b.name IS DISTINCT FROM 'Push press'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Envión de fuerza','Push jerk','pj','push jerks','jerk en paralelo','envion de fuerza','envion con pies paralelos']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Push jerk';

UPDATE public.business_exercise_catalog AS b
SET name = 'Push jerk',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Push jerk'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Push jerk'
  AND (b.name IS DISTINCT FROM 'Push jerk'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Envión en tijera','Split jerk','sj','split jerks','jerk en split','jerk en tijera','envion en tijera','envion split']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Split jerk';

UPDATE public.business_exercise_catalog AS b
SET name = 'Split jerk',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Split jerk'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Split jerk'
  AND (b.name IS DISTINCT FROM 'Split jerk'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Envión de potencia','Power jerk','power j','power jerks','jerk de potencia','envion potencia']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Power jerk';

UPDATE public.business_exercise_catalog AS b
SET name = 'Power jerk',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Power jerk'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Power jerk'
  AND (b.name IS DISTINCT FROM 'Power jerk'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Balance de envión','Jerk Balance','jerk balance drill','balance de jerk','balance de envion']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Balance de envión';

UPDATE public.business_exercise_catalog AS b
SET name = 'Jerk Balance',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Jerk Balance'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Balance de envión'
  AND (b.name IS DISTINCT FROM 'Jerk Balance'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Press estricto','Strict press','sp','strict overhead press','military press','press estricto de pie','press militar estricto']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Strict press';

UPDATE public.business_exercise_catalog AS b
SET name = 'Strict press',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Strict press'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Strict press'
  AND (b.name IS DISTINCT FROM 'Strict press'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Press detrás de nuca','Behind-the-Neck Press','btn press','press tras nuca','press detras de nuca']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Press detrás de nuca';

UPDATE public.business_exercise_catalog AS b
SET name = 'Behind-the-Neck Press',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Behind-the-Neck Press'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Press detrás de nuca'
  AND (b.name IS DISTINCT FROM 'Behind-the-Neck Press'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Envión detrás de nuca','Behind-the-Neck Jerk','btn jerk','jerk btn','jerk desde nuca','envion detras de nuca']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Envión detrás de nuca';

UPDATE public.business_exercise_catalog AS b
SET name = 'Behind-the-Neck Jerk',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Behind-the-Neck Jerk'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Envión detrás de nuca'
  AND (b.name IS DISTINCT FROM 'Behind-the-Neck Jerk'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Press Sots','Sots press','sots','sots overhead press','press en sentadilla frontal']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Sots press';

UPDATE public.business_exercise_catalog AS b
SET name = 'Sots press',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Sots press'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Sots press'
  AND (b.name IS DISTINCT FROM 'Sots press'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Sentadilla por encima de la cabeza','Overhead squat','ohs','ohsq','overhead squats','sentadilla overhead','sentadilla sobre cabeza','oh squat']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Overhead squat';

UPDATE public.business_exercise_catalog AS b
SET name = 'Overhead squat',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Overhead squat'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Overhead squat'
  AND (b.name IS DISTINCT FROM 'Overhead squat'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Zancada con barra en rack frontal','Front rack lunge','fr lunge','fr lunges','front rack lunges','zancada rack frontal']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Front rack lunge';

UPDATE public.business_exercise_catalog AS b
SET name = 'Front rack lunge',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Front rack lunge'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Front rack lunge'
  AND (b.name IS DISTINCT FROM 'Front rack lunge'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Sentadilla frontal con pausa','Pause Front Squat','paused fs','pause fs','pfs','sentadilla frontal pausada','pause front squats']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Sentadilla frontal con pausa';

UPDATE public.business_exercise_catalog AS b
SET name = 'Pause Front Squat',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Pause Front Squat'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Sentadilla frontal con pausa'
  AND (b.name IS DISTINCT FROM 'Pause Front Squat'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Tirón alto sumo','Sumo high pull','sdhp','sumo deadlift high pull','tiron alto sumo','tiron alto sumo deadlift','sumo HP']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Sumo high pull';

UPDATE public.business_exercise_catalog AS b
SET name = 'Sumo high pull',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Sumo high pull'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Sumo high pull'
  AND (b.name IS DISTINCT FROM 'Sumo high pull'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Sentadilla frontal con press','Thruster','thrusters','front squat press','squat and press','thruster barra']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Thruster';

UPDATE public.business_exercise_catalog AS b
SET name = 'Thruster',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Thruster'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Thruster'
  AND (b.name IS DISTINCT FROM 'Thruster'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Thruster mancuernas','Dumbbell Thruster','db thruster','db thrusters','thruster con mancuernas','thrusters db']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Thruster mancuernas';

UPDATE public.business_exercise_catalog AS b
SET name = 'Thruster mancuernas',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Thruster mancuernas'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Thruster mancuernas'
  AND (b.name IS DISTINCT FROM 'Thruster mancuernas'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Thruster kettlebell','Kettlebell Thruster','kb thruster','kb thrusters','thruster con kettlebell','thruster kb']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Thruster kettlebell';

UPDATE public.business_exercise_catalog AS b
SET name = 'Thruster kettlebell',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Thruster kettlebell'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Thruster kettlebell'
  AND (b.name IS DISTINCT FROM 'Thruster kettlebell'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada y thruster','Cluster','clusters','clean thruster','cluster barra','squat clean thruster']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Cluster';

UPDATE public.business_exercise_catalog AS b
SET name = 'Cluster',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Cluster'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Cluster'
  AND (b.name IS DISTINCT FROM 'Cluster'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Del suelo a encima de la cabeza','Ground to overhead','gtoh','g2oh','g2o','ground 2 overhead','ground-to-overhead','suelo a overhead','suelo sobre cabeza']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Ground to overhead';

UPDATE public.business_exercise_catalog AS b
SET name = 'Ground to overhead',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Ground to overhead'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Ground to overhead'
  AND (b.name IS DISTINCT FROM 'Ground to overhead'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Disco del suelo a encima de la cabeza','Plate ground to overhead','plate gtoh','plate g2oh','disco suelo a overhead','plate to overhead']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Plate ground to overhead';

UPDATE public.business_exercise_catalog AS b
SET name = 'Plate ground to overhead',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Plate ground to overhead'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Plate ground to overhead'
  AND (b.name IS DISTINCT FROM 'Plate ground to overhead'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Burpi','Burpee','burpees','burpis','berpie','burpee completo']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Burpee';

UPDATE public.business_exercise_catalog AS b
SET name = 'Burpee',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Burpee'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Burpee'
  AND (b.name IS DISTINCT FROM 'Burpee'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Burpee a diana','Burpee to target','btt','burpees to target','burpee al target','burpee target']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Burpee to target';

UPDATE public.business_exercise_catalog AS b
SET name = 'Burpee to target',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Burpee to target'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Burpee to target'
  AND (b.name IS DISTINCT FROM 'Burpee to target'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Burpee al cajón','Burpee Box Jump','bbj box','burpee box jumps','burpee + box jump']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Burpee al cajón';

UPDATE public.business_exercise_catalog AS b
SET name = 'Burpee al cajón',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Burpee al cajón'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Burpee al cajón'
  AND (b.name IS DISTINCT FROM 'Burpee al cajón'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Burpee frente a la barra','Bar facing burpee','bfb','bar-facing burpees','burpee facing bar','burpees over the bar','burpee sobre barra']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Bar facing burpee';

UPDATE public.business_exercise_catalog AS b
SET name = 'Bar facing burpee',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Bar facing burpee'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Bar facing burpee'
  AND (b.name IS DISTINCT FROM 'Bar facing burpee'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Burpee con dominada','Burpee pull-up','burpee pull up','burpee pullups','burpee + pull-up']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Burpee pull-up';

UPDATE public.business_exercise_catalog AS b
SET name = 'Burpee pull-up',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Burpee pull-up'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Burpee pull-up'
  AND (b.name IS DISTINCT FROM 'Burpee pull-up'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Salto al cajón','Box Jump','bj','box jumps','salto al cajon','saltos al cajón']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Salto al cajón';

UPDATE public.business_exercise_catalog AS b
SET name = 'Salto al cajón',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Salto al cajón'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Salto al cajón'
  AND (b.name IS DISTINCT FROM 'Salto al cajón'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Step-up al cajón','Box Step-Up','box step up','step-ups','step up al cajon','subidas al cajón']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Step-up al cajón';

UPDATE public.business_exercise_catalog AS b
SET name = 'Step-up al cajón',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Step-up al cajón'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Step-up al cajón'
  AND (b.name IS DISTINCT FROM 'Step-up al cajón'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Step-up al cajón con doble mancuerna','Double Dumbbell Step Up','ddb step up','ddb box step up','double dumbbell box step up','step up con dos mancuernas']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Step-up al cajón con doble mancuerna';

UPDATE public.business_exercise_catalog AS b
SET name = 'Double Dumbbell Step Up',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Double Dumbbell Step Up'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Step-up al cajón con doble mancuerna'
  AND (b.name IS DISTINCT FROM 'Double Dumbbell Step Up'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Salto sobre cajón','Box jump over','bjo','box jump overs','box jumps over','salto sobre cajon']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Box jump over';

UPDATE public.business_exercise_catalog AS b
SET name = 'Box jump over',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Box jump over'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Box jump over'
  AND (b.name IS DISTINCT FROM 'Box jump over'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Salto de longitud','Broad jump','broad jumps','standing long jump','salto horizontal']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Broad jump';

UPDATE public.business_exercise_catalog AS b
SET name = 'Broad jump',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Broad jump'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Broad jump'
  AND (b.name IS DISTINCT FROM 'Broad jump'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Zancadas caminando','Walking lunge','walking lunges','walk lunges','zancadas andando','lunges caminando']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Walking lunge';

UPDATE public.business_exercise_catalog AS b
SET name = 'Walking lunge',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Walking lunge'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Walking lunge'
  AND (b.name IS DISTINCT FROM 'Walking lunge'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Gateo del oso','Bear crawl','bear crawls','oso gateo','crawl oso']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Bear crawl';

UPDATE public.business_exercise_catalog AS b
SET name = 'Bear crawl',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Bear crawl'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Bear crawl'
  AND (b.name IS DISTINCT FROM 'Bear crawl'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Swing kettlebell','Kettlebell Swing','kb swing','kbs','rkbs','russian kettlebell swing','russian kb swing','swing ruso','swing de pesa rusa','balanceo kb']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Swing kettlebell';

UPDATE public.business_exercise_catalog AS b
SET name = 'Swing kettlebell',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Swing kettlebell'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Swing kettlebell'
  AND (b.name IS DISTINCT FROM 'Swing kettlebell'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Swing americano','American Kettlebell Swing','akbs','akb','american kb swing','american kettlebell swings','swing kb americano','american swing']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Swing americano';

UPDATE public.business_exercise_catalog AS b
SET name = 'Swing americano',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Swing americano'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Swing americano'
  AND (b.name IS DISTINCT FROM 'Swing americano'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Snatch kettlebell','Kettlebell Snatch','kb snatch','kb snatches','arrancada con kettlebell','arrancada kb','pesa rusa snatch']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Snatch kettlebell';

UPDATE public.business_exercise_catalog AS b
SET name = 'Snatch kettlebell',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Snatch kettlebell'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Snatch kettlebell'
  AND (b.name IS DISTINCT FROM 'Snatch kettlebell'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Clean kettlebell','Kettlebell Clean','kb clean','kb cleans','cargada con kettlebell','cargada kb']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Clean kettlebell';

UPDATE public.business_exercise_catalog AS b
SET name = 'Clean kettlebell',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Clean kettlebell'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Clean kettlebell'
  AND (b.name IS DISTINCT FROM 'Clean kettlebell'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Levantamiento turco','Turkish get-up','tgu','turkish get up','turkish getups','get-up turco','getup turco']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Turkish get-up';

UPDATE public.business_exercise_catalog AS b
SET name = 'Turkish get-up',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Turkish get-up'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Turkish get-up'
  AND (b.name IS DISTINCT FROM 'Turkish get-up'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Sentadilla goblet','Goblet squat','goblet squats','kb goblet squat','sentadilla cáliz','sentadilla caliz']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Goblet squat';

UPDATE public.business_exercise_catalog AS b
SET name = 'Goblet squat',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Goblet squat'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Goblet squat'
  AND (b.name IS DISTINCT FROM 'Goblet squat'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Press del diablo','Devil press','devil presses','db devil press','devil db press']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Devil press';

UPDATE public.business_exercise_catalog AS b
SET name = 'Devil press',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Devil press'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Devil press'
  AND (b.name IS DISTINCT FROM 'Devil press'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Hombre máquina','Man maker','manmakers','man-maker','hombre maquina','db man maker']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Man maker';

UPDATE public.business_exercise_catalog AS b
SET name = 'Man maker',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Man maker'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Man maker'
  AND (b.name IS DISTINCT FROM 'Man maker'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Snatch mancuerna','Dumbbell Snatch','db snatch','db sn','db snatches','snatch con mancuerna','arrancada con mancuerna','alt db snatch']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Snatch mancuerna';

UPDATE public.business_exercise_catalog AS b
SET name = 'Snatch mancuerna',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Snatch mancuerna'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Snatch mancuerna'
  AND (b.name IS DISTINCT FROM 'Snatch mancuerna'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Clean mancuerna','Dumbbell Clean','db clean','db cleans','cargada con mancuerna','dumbbell cleans']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Clean mancuerna';

UPDATE public.business_exercise_catalog AS b
SET name = 'Clean mancuerna',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Clean mancuerna'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Clean mancuerna'
  AND (b.name IS DISTINCT FROM 'Clean mancuerna'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Lanzamiento de balón a pared','Wall ball','wb','wbs','wall balls','wallball','wall ball shot','lanzamientos a diana','balón a pared','ballon wall']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Wall ball';

UPDATE public.business_exercise_catalog AS b
SET name = 'Wall ball',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Wall ball'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Wall ball'
  AND (b.name IS DISTINCT FROM 'Wall ball'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Golpeo de balón al suelo','Ball slam','ball slams','medball slam','slam ball','slams','balón slam']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Ball slam';

UPDATE public.business_exercise_catalog AS b
SET name = 'Ball slam',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Ball slam'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Ball slam'
  AND (b.name IS DISTINCT FROM 'Ball slam'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada con balón medicinal','Medball clean','med ball clean','medicine ball clean','mb clean','cargada medball']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Medball clean';

UPDATE public.business_exercise_catalog AS b
SET name = 'Medball clean',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Medball clean'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Medball clean'
  AND (b.name IS DISTINCT FROM 'Medball clean'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada con saco','Sandbag clean','sand bag clean','sb clean','clean con saco']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Sandbag clean';

UPDATE public.business_exercise_catalog AS b
SET name = 'Sandbag clean',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Sandbag clean'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Sandbag clean'
  AND (b.name IS DISTINCT FROM 'Sandbag clean'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Saco sobre el hombro','Sandbag over shoulder','sb over shoulder','sandbag overs','saco al hombro']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Sandbag over shoulder';

UPDATE public.business_exercise_catalog AS b
SET name = 'Sandbag over shoulder',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Sandbag over shoulder'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Sandbag over shoulder'
  AND (b.name IS DISTINCT FROM 'Sandbag over shoulder'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Paseo con yugo','Yoke carry','yoke walk','yoke carries','yugo carry','yoke']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Yoke carry';

UPDATE public.business_exercise_catalog AS b
SET name = 'Yoke carry',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Yoke carry'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Yoke carry'
  AND (b.name IS DISTINCT FROM 'Yoke carry'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Dobles de comba','Double-Under','du','dus','double unders','double-unders','dobles','doble comba','doble unders']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Dobles de comba';

UPDATE public.business_exercise_catalog AS b
SET name = 'Dobles de comba',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Dobles de comba'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Dobles de comba'
  AND (b.name IS DISTINCT FROM 'Dobles de comba'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Simples de comba','Single-Under','su','sus','single unders','simples','comba simple']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Simples de comba';

UPDATE public.business_exercise_catalog AS b
SET name = 'Simples de comba',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Simples de comba'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Simples de comba'
  AND (b.name IS DISTINCT FROM 'Simples de comba'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Triples de comba','Triple-Under','tu','tus','triple unders','triples']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Triples de comba';

UPDATE public.business_exercise_catalog AS b
SET name = 'Triples de comba',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Triples de comba'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Triples de comba'
  AND (b.name IS DISTINCT FROM 'Triples de comba'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Bicicleta de aire','Air bike','assault bike','abike','airbike','fan bike','bici de aire','assault']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Air bike';

UPDATE public.business_exercise_catalog AS b
SET name = 'Air bike',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Air bike'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Air bike'
  AND (b.name IS DISTINCT FROM 'Air bike'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Bicicleta Echo','Echo bike','echo','echo erg','echo bikes','bici echo']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Echo bike';

UPDATE public.business_exercise_catalog AS b
SET name = 'Echo bike',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Echo bike'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Echo bike'
  AND (b.name IS DISTINCT FROM 'Echo bike'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Esquí ergómetro','SkiErg','ski erg','ski ergometer','ski-erg','esqui ergometro','esqui nordico ergometro','ski']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:SkiErg';

UPDATE public.business_exercise_catalog AS b
SET name = 'SkiErg',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'SkiErg'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:SkiErg'
  AND (b.name IS DISTINCT FROM 'SkiErg'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Carrera de ida y vuelta','Shuttle run','shuttle runs','shuttles','suiza','ida y vuelta']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Shuttle run';

UPDATE public.business_exercise_catalog AS b
SET name = 'Shuttle run',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Shuttle run'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Shuttle run'
  AND (b.name IS DISTINCT FROM 'Shuttle run'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Empuje de trineo','Sled push','sledpush','prowler push','empujar trineo','sled pushes']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Sled push';

UPDATE public.business_exercise_catalog AS b
SET name = 'Sled push',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Sled push'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Sled push'
  AND (b.name IS DISTINCT FROM 'Sled push'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Arrastre de trineo','Sled pull','sledpull','prowler pull','tirar de trineo','sled pulls']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Sled pull';

UPDATE public.business_exercise_catalog AS b
SET name = 'Sled pull',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Sled pull'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Sled pull'
  AND (b.name IS DISTINCT FROM 'Sled pull'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Paseo del granjero','Farmer carry','farmers carry','farmer walk','farmers walk','paseo granjero','farmer carries']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Farmer carry';

UPDATE public.business_exercise_catalog AS b
SET name = 'Farmer carry',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Farmer carry'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Farmer carry'
  AND (b.name IS DISTINCT FROM 'Farmer carry'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Step-up al cajón con kettlebell goblet','Kettlebell Goblet Box Step-Up','kb goblet box step up','goblet alt box step up','goblet alternating box step up','step up goblet kb']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Step-up al cajón con kettlebell goblet';

UPDATE public.business_exercise_catalog AS b
SET name = 'Step-up al cajón con kettlebell goblet',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Step-up al cajón con kettlebell goblet'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Step-up al cajón con kettlebell goblet'
  AND (b.name IS DISTINCT FROM 'Step-up al cajón con kettlebell goblet'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Carrera','Run','running','jogging','correr','runs','trote','footing']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Carrera';

UPDATE public.business_exercise_catalog AS b
SET name = 'Carrera',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Carrera'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Carrera'
  AND (b.name IS DISTINCT FROM 'Carrera'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada y envión con mancuerna','Dumbbell Clean and Jerk','db c&j','db cj','dumbbell clean & jerk','cargada y envion mancuerna','db clean and jerk']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Cargada y envión con mancuerna';

UPDATE public.business_exercise_catalog AS b
SET name = 'Cargada y envión con mancuerna',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Cargada y envión con mancuerna'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Cargada y envión con mancuerna'
  AND (b.name IS DISTINCT FROM 'Cargada y envión con mancuerna'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Burpee con salto sobre cajón','Burpee box jump over','bbjo','burpee box jumps over','burpee sobre cajon','burpee box over']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Burpee box jump over';

UPDATE public.business_exercise_catalog AS b
SET name = 'Burpee box jump over',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Burpee box jump over'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'CrossFit')
WHERE b.catalog_key = 'catalog:Burpee box jump over'
  AND (b.name IS DISTINCT FROM 'Burpee box jump over'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Tirón alto de arrancada','Snatch High Pull','shp','snatch highpull','high pull de arrancada','tiron alto de arrancada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Tirón alto de arrancada';

UPDATE public.business_exercise_catalog AS b
SET name = 'Snatch High Pull',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Snatch High Pull'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Tirón alto de arrancada'
  AND (b.name IS DISTINCT FROM 'Snatch High Pull'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Tirón alto de cargada','Clean High Pull','chp','clean highpull','high pull de cargada','tiron alto de cargada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Tirón alto de cargada';

UPDATE public.business_exercise_catalog AS b
SET name = 'Clean High Pull',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Clean High Pull'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Tirón alto de cargada'
  AND (b.name IS DISTINCT FROM 'Clean High Pull'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Peso muerto de cargada','Clean Deadlift','clean grip deadlift','cgdl','peso muerto agarre cargada','dl agarre cargada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Peso muerto de cargada';

UPDATE public.business_exercise_catalog AS b
SET name = 'Clean Deadlift',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Clean Deadlift'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Peso muerto de cargada'
  AND (b.name IS DISTINCT FROM 'Clean Deadlift'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Envión en sentadilla','Squat Jerk','squat j','sj squat','jerk en sentadilla','envion en sentadilla']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Envión en sentadilla';

UPDATE public.business_exercise_catalog AS b
SET name = 'Squat Jerk',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Squat Jerk'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Envión en sentadilla'
  AND (b.name IS DISTINCT FROM 'Squat Jerk'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Dip y drive de envión','Jerk Dip and Drive','jerk dip drive','dip & drive','dip drive','jerk dip + drive','impulso de envion','dip and drive']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Dip y drive de envión';

UPDATE public.business_exercise_catalog AS b
SET name = 'Jerk Dip and Drive',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Jerk Dip and Drive'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Dip y drive de envión'
  AND (b.name IS DISTINCT FROM 'Jerk Dip and Drive'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Arrancada de potencia desde bloques','Block Power Snatch','bpsn','power snatch off blocks','arrancada potencia desde tacos']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Arrancada de potencia desde bloques';

UPDATE public.business_exercise_catalog AS b
SET name = 'Block Power Snatch',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Block Power Snatch'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Arrancada de potencia desde bloques'
  AND (b.name IS DISTINCT FROM 'Block Power Snatch'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Cargada de potencia desde bloques','Block Power Clean','bpc','power clean off blocks','cargada potencia desde tacos']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Cargada de potencia desde bloques';

UPDATE public.business_exercise_catalog AS b
SET name = 'Block Power Clean',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Block Power Clean'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Cargada de potencia desde bloques'
  AND (b.name IS DISTINCT FROM 'Block Power Clean'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY['Push press con agarre de arrancada','Snatch-Grip Push Press','sgpp','snatch grip pp','push press ancho','pp agarre arrancada']::text[],
    updated_at = now()
WHERE m.catalog_key = 'catalog:Push press con agarre de arrancada';

UPDATE public.business_exercise_catalog AS b
SET name = 'Snatch-Grip Push Press',
    display_name_en = coalesce(nullif(b.display_name_en, ''), 'Snatch-Grip Push Press'),
    mobile_sport_tag = coalesce(b.mobile_sport_tag, 'Halterofilia')
WHERE b.catalog_key = 'catalog:Push press con agarre de arrancada'
  AND (b.name IS DISTINCT FROM 'Snatch-Grip Push Press'
       OR b.mobile_sport_tag IS NULL
       OR coalesce(b.display_name_en, '') = '');

DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM public.training_exercise_metadata
  WHERE catalog_key IN (SELECT catalog_key FROM public.business_exercise_catalog
                        WHERE category IN ('CrossFit','Halterofilia'))
    AND cardinality(aliases) = 0;
  IF bad > 0 THEN
    RAISE EXCEPTION 'CF/HL rows without aliases: %', bad;
  END IF;
END $$;
