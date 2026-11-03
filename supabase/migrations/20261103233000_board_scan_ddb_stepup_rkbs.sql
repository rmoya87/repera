-- New native CrossFit variant, keeping existing catalog identities and history.
INSERT INTO public.business_exercise_catalog (catalog_key,name,category)
VALUES ('catalog:Step-up al cajón con doble mancuerna',
        'Step-up al cajón con doble mancuerna','CrossFit')
ON CONFLICT (catalog_key) DO NOTHING;

INSERT INTO public.training_exercise_metadata
  (catalog_key,aliases,primary_muscles,secondary_muscles,
   equipment,required_equipment,metadata_source)
VALUES
  ('catalog:Step-up al cajón con doble mancuerna',
   ARRAY['Double Dumbbell Step Up','DDB Step Up','DDB Box Step Up',
         'Double Dumbbell Box Step Up','Step-up al cajón con doble mancuerna']::text[],
   ARRAY['quadriceps','gluteal']::text[],ARRAY['hamstring','abs']::text[],
   ARRAY['Cajón','Mancuernas']::text[],ARRAY['Cajón','Mancuernas']::text[],
   'native_ios_catalog')
ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=(SELECT ARRAY(SELECT DISTINCT a FROM unnest(
    coalesce(public.training_exercise_metadata.aliases,'{}'::text[]) || excluded.aliases
  ) a ORDER BY a)),
  updated_at=now();

-- Existing Kettlebell Swing is the Russian (chest-height) technique.
-- Add nomenclature and shorthand, NOT a duplicate exercise/UUID.
UPDATE public.training_exercise_metadata AS m SET
  aliases=(SELECT ARRAY(SELECT DISTINCT a FROM unnest(
    coalesce(m.aliases,'{}'::text[]) ||
    ARRAY['RKBS','RKB','Russian Kettlebell Swing','Russian KB Swing',
          'Swing ruso','Kettlebell Swing']::text[]
  ) a ORDER BY a)),
  updated_at=now()
WHERE m.catalog_key='catalog:Swing kettlebell';
