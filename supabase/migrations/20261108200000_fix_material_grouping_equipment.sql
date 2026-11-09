-- Corrige material declarado para alinear chips / orden «Material» con el aparato real.
-- Back lever: Anillas (progresión German hang). Dominadas colgadas: Barra de dominadas
-- (no «Barra» olímpica). Step-ups con carga: Cajón primero. Couch stretch sigue en Pared.
-- Aplicar en remoto solo con confirmación humana.

UPDATE public.business_exercise_catalog
SET mobile_equipment = 'Anillas'
WHERE catalog_key = 'catalog:Back lever tuck';

UPDATE public.training_exercise_metadata m
SET equipment = ARRAY['Anillas']::text[],
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key
  AND c.catalog_key = 'catalog:Back lever tuck';

UPDATE public.business_exercise_catalog
SET mobile_equipment = 'Barra de dominadas'
WHERE catalog_key IN (
  'catalog:Dead Hang',
  'catalog:Jumping Pull-Up',
  'catalog:Burpee Muscle-Up',
  'catalog:Burpee Bar Muscle Up',
  'catalog:L Pull Up',
  'catalog:Negative Pull Up',
  'catalog:Hanging Hip Touch',
  'catalog:Hanging Knee Raise',
  'catalog:Strict Knee Raise',
  'catalog:Strict Knees To Chest'
);

UPDATE public.training_exercise_metadata m
SET equipment = ARRAY['Barra de dominadas']::text[],
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key
  AND c.catalog_key IN (
    'catalog:Dead Hang',
    'catalog:Jumping Pull-Up',
    'catalog:Burpee Muscle-Up',
    'catalog:Burpee Bar Muscle Up',
    'catalog:L Pull Up',
    'catalog:Negative Pull Up',
    'catalog:Hanging Hip Touch',
    'catalog:Hanging Knee Raise',
    'catalog:Strict Knee Raise',
    'catalog:Strict Knees To Chest'
  );

UPDATE public.business_exercise_catalog
SET mobile_equipment = 'Cajón, Mancuernas'
WHERE catalog_key = 'catalog:Dumbbell Box Step Up';

UPDATE public.training_exercise_metadata m
SET equipment = ARRAY['Cajón', 'Mancuernas']::text[],
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key
  AND c.catalog_key = 'catalog:Dumbbell Box Step Up';

UPDATE public.business_exercise_catalog
SET mobile_equipment = 'Cajón, Balón medicinal'
WHERE catalog_key = 'catalog:Medicine Ball Box Step Over';

UPDATE public.training_exercise_metadata m
SET equipment = ARRAY['Cajón', 'Balón medicinal']::text[],
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key
  AND c.catalog_key = 'catalog:Medicine Ball Box Step Over';

UPDATE public.business_exercise_catalog
SET mobile_equipment = 'Pared'
WHERE catalog_key = 'catalog:Couch stretch';

UPDATE public.training_exercise_metadata m
SET equipment = ARRAY['Pared']::text[],
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key
  AND c.catalog_key = 'catalog:Couch stretch';
