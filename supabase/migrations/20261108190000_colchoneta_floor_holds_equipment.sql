-- Floor gymnastics holds: material = Colchoneta (no «Peso corporal» genérico
-- ni frases largas tipo ExerciseDB). Aplicar en remoto con confirmación humana.
UPDATE public.business_exercise_catalog
SET mobile_equipment = 'Colchoneta',
    updated_at = now()
WHERE catalog_key IN (
  'catalog:Arch hold',
  'catalog:Hollow hold',
  'catalog:Hollow rock',
  'catalog:Candlestick'
);

UPDATE public.training_exercise_metadata m
SET equipment = ARRAY['Colchoneta']::text[],
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key
  AND c.catalog_key IN (
    'catalog:Arch hold',
    'catalog:Hollow hold',
    'catalog:Hollow rock',
    'catalog:Candlestick'
  );
