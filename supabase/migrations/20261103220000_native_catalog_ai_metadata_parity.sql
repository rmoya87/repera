-- Add native catalog movements after the 2026-10 metadata mapping.
-- Safe for repeated deployment, preserves curated records and existing owners.
-- These are SPORTING muscle regions, not medical predictions.
INSERT INTO public.business_exercise_catalog(catalog_key,name,category) VALUES
 ('catalog:Tirón alto de arrancada','Tirón alto de arrancada','Halterofilia'),
 ('catalog:Tirón alto de cargada','Tirón alto de cargada','Halterofilia'),
 ('catalog:Peso muerto de cargada','Peso muerto de cargada','Halterofilia'),
 ('catalog:Envión en sentadilla','Envión en sentadilla','Halterofilia'),
 ('catalog:Dip y drive de envión','Dip y drive de envión','Halterofilia'),
 ('catalog:Arrancada de potencia desde bloques','Arrancada de potencia desde bloques','Halterofilia'),
 ('catalog:Cargada de potencia desde bloques','Cargada de potencia desde bloques','Halterofilia'),
 ('catalog:Push press con agarre de arrancada','Push press con agarre de arrancada','Halterofilia'),
 ('catalog:Burpee to target','Burpee to target','CrossFit')
ON CONFLICT (catalog_key) DO NOTHING;

INSERT INTO public.training_exercise_metadata(
  catalog_key,primary_muscles,secondary_muscles,equipment,metadata_source
) VALUES
 ('catalog:Tirón alto de arrancada',ARRAY['trapezius','gluteal']::text[],ARRAY['hamstring','deltoids']::text[],ARRAY['Barra']::text[],'native:CatalogHalterofilia'),
 ('catalog:Tirón alto de cargada',ARRAY['trapezius','gluteal']::text[],ARRAY['hamstring','deltoids']::text[],ARRAY['Barra']::text[],'native:CatalogHalterofilia'),
 ('catalog:Peso muerto de cargada',ARRAY['hamstring','gluteal']::text[],ARRAY['quadriceps','abs']::text[],ARRAY['Barra']::text[],'native:CatalogHalterofilia'),
 ('catalog:Envión en sentadilla',ARRAY['deltoids','quadriceps']::text[],ARRAY['triceps','abs']::text[],ARRAY['Barra']::text[],'native:CatalogHalterofilia'),
 ('catalog:Dip y drive de envión',ARRAY['quadriceps','gluteal']::text[],ARRAY['deltoids','abs']::text[],ARRAY['Barra']::text[],'native:CatalogHalterofilia'),
 ('catalog:Arrancada de potencia desde bloques',ARRAY['quadriceps','gluteal']::text[],ARRAY['trapezius','deltoids']::text[],ARRAY['Barra']::text[],'native:CatalogHalterofilia'),
 ('catalog:Cargada de potencia desde bloques',ARRAY['quadriceps','gluteal']::text[],ARRAY['trapezius','abs']::text[],ARRAY['Barra']::text[],'native:CatalogHalterofilia'),
 ('catalog:Push press con agarre de arrancada',ARRAY['deltoids']::text[],ARRAY['triceps','quadriceps','trapezius']::text[],ARRAY['Barra']::text[],'native:CatalogHalterofilia'),
 ('catalog:Burpee to target',ARRAY['chest','quadriceps']::text[],ARRAY['deltoids','abs']::text[],ARRAY['Diana elevada']::text[],'native:CatalogCrossFit')
ON CONFLICT (catalog_key) DO UPDATE SET
  primary_muscles = EXCLUDED.primary_muscles,
  secondary_muscles = EXCLUDED.secondary_muscles,
  equipment = EXCLUDED.equipment,
  metadata_source = EXCLUDED.metadata_source,
  updated_at = now()
WHERE public.training_exercise_metadata.metadata_source = 'unmapped';

-- Metadata remains under the pre-existing SELECT-only RLS policy.
-- Fail early if a new native entry has no muscle mapping.
DO $verify$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.business_exercise_catalog c
    LEFT JOIN public.training_exercise_metadata m ON m.catalog_key = c.catalog_key
    WHERE c.catalog_key IN ('catalog:Tirón alto de arrancada','catalog:Tirón alto de cargada','catalog:Peso muerto de cargada','catalog:Envión en sentadilla','catalog:Dip y drive de envión','catalog:Arrancada de potencia desde bloques','catalog:Cargada de potencia desde bloques','catalog:Push press con agarre de arrancada','catalog:Burpee to target')
      AND (m.catalog_key IS NULL OR cardinality(m.primary_muscles || m.secondary_muscles) = 0)
  ) THEN
    RAISE EXCEPTION 'Unmapped native exercise in metadata parity migration';
  END IF;
END
$verify$;
