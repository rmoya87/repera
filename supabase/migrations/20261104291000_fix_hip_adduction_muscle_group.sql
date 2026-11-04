-- Aducción ≠ Abducción: corregir grupo muscular visible (no son duplicados).
-- Abducción = glúteo medio (Glúteos). Aducción = aductores (Piernas).

UPDATE public.business_exercise_catalog
SET
  mobile_muscle_group = 'Piernas',
  mobile_description = 'Aducción de cadera sentado en máquina (aductores internos).'
WHERE catalog_key = 'catalog:Aducción de cadera en máquina'
  AND is_active;

UPDATE public.training_exercise_metadata
SET
  primary_muscles = ARRAY['adductors']::text[],
  secondary_muscles = ARRAY['abs']::text[],
  updated_at = now()
WHERE catalog_key = 'catalog:Aducción de cadera en máquina';

SELECT public.repera_emit_mobile_catalog_event('catalog:Aducción de cadera en máquina');
