-- 2026-10-23 · HYROX stations and bilingual aliases.
-- Idempotent data migration. Existing CrossFit/Fuerza catalog identity and sessions remain unchanged.
INSERT INTO public.business_exercise_catalog(catalog_key,name,category)
VALUES
 ('catalog:Burpee Broad Jump','Burpee Broad Jump','HYROX'),
 ('catalog:Sandbag Lunges','Sandbag Lunges','HYROX')
ON CONFLICT (catalog_key) DO NOTHING;

INSERT INTO public.training_exercise_catalog(catalog_key,name,category)
SELECT src.catalog_key, src.name, src.category
FROM (VALUES
 ('catalog:Burpee Broad Jump','Burpee Broad Jump','HYROX'),
 ('catalog:Sandbag Lunges','Sandbag Lunges','HYROX')
) AS src(catalog_key,name,category)
WHERE NOT EXISTS (
 SELECT 1 FROM public.training_exercise_catalog existing
 WHERE existing.catalog_key=src.catalog_key
);

INSERT INTO public.training_exercise_metadata
 (catalog_key,aliases,primary_muscles,secondary_muscles,equipment,
  movement_pattern,required_equipment,metadata_source)
VALUES
 ('catalog:Burpee Broad Jump',
  ARRAY['Burpee Broad Jump','Burpee Broad Jumps','Burpees con salto de longitud','Burpee con salto de longitud'],
  ARRAY['quadriceps','gluteal'],ARRAY['chest','abs'],
  ARRAY['Peso corporal'],'conditioning',ARRAY['bodyweight'],'native:CatalogHyrox'),
 ('catalog:Sandbag Lunges',
  ARRAY['Sandbag Lunges','Sandbag Lunge','Zancadas con saco','Zancadas caminando con saco'],
  ARRAY['quadriceps','gluteal'],ARRAY['hamstring','abs'],
  ARRAY['Saco'],'lunge',ARRAY['sandbag'],'native:CatalogHyrox')
ON CONFLICT (catalog_key) DO NOTHING;

-- Existing named exercises remain shared across CrossFit and HYROX.
UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY(
  SELECT DISTINCT alias FROM unnest(m.aliases ||
    CASE m.catalog_key
      WHEN 'catalog:Remo máquina' THEN ARRAY['RowErg','Rowing','Remo ergómetro']::text[]
      WHEN 'catalog:Farmer carry' THEN ARRAY['Farmers Carry','Paseo del granjero con kettlebells']::text[]
      ELSE ARRAY[]::text[]
    END
  ) AS alias
), updated_at=now()
WHERE m.catalog_key IN ('catalog:Remo máquina','catalog:Farmer carry');
