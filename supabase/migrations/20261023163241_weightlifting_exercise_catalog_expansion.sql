-- Ocho derivados técnicos de halterofilia ausentes en el catálogo inicial.
-- Migración aditiva, idempotente: mismos catalog_key en iOS, web, MCP y Supabase.
-- No se sobrescriben movimientos compartidos, sesiones, marcas ni sus UUID.
WITH source(catalog_key,name,english,primary_muscle,secondary_muscle,pattern) AS (
 VALUES
  ('catalog:Tirón alto de arrancada','Tirón alto de arrancada','Snatch High Pull','trapezius','gluteal','snatch_high_pull'),
  ('catalog:Tirón alto de cargada','Tirón alto de cargada','Clean High Pull','trapezius','gluteal','clean_high_pull'),
  ('catalog:Peso muerto de cargada','Peso muerto de cargada','Clean Deadlift','hamstring','gluteal','clean_deadlift'),
  ('catalog:Envión en sentadilla','Envión en sentadilla','Squat Jerk','deltoids','quadriceps','squat_jerk'),
  ('catalog:Dip y drive de envión','Dip y drive de envión','Jerk Dip and Drive','quadriceps','gluteal','jerk_dip_drive'),
  ('catalog:Arrancada de potencia desde bloques','Arrancada de potencia desde bloques','Block Power Snatch','quadriceps','deltoids','block_power_snatch'),
  ('catalog:Cargada de potencia desde bloques','Cargada de potencia desde bloques','Block Power Clean','quadriceps','trapezius','block_power_clean'),
  ('catalog:Push press con agarre de arrancada','Push press con agarre de arrancada','Snatch-Grip Push Press','deltoids','triceps','snatch_grip_push_press')
)
INSERT INTO public.business_exercise_catalog(catalog_key,name,category)
SELECT catalog_key,name,'Halterofilia' FROM source
ON CONFLICT (catalog_key) DO NOTHING;

WITH source(catalog_key,name) AS (
 VALUES
  ('catalog:Tirón alto de arrancada','Tirón alto de arrancada'),
  ('catalog:Tirón alto de cargada','Tirón alto de cargada'),
  ('catalog:Peso muerto de cargada','Peso muerto de cargada'),
  ('catalog:Envión en sentadilla','Envión en sentadilla'),
  ('catalog:Dip y drive de envión','Dip y drive de envión'),
  ('catalog:Arrancada de potencia desde bloques','Arrancada de potencia desde bloques'),
  ('catalog:Cargada de potencia desde bloques','Cargada de potencia desde bloques'),
  ('catalog:Push press con agarre de arrancada','Push press con agarre de arrancada')
)
INSERT INTO public.training_exercise_catalog(catalog_key,name,category)
SELECT s.catalog_key,s.name,'Halterofilia'
FROM source s
WHERE NOT EXISTS (SELECT 1 FROM public.training_exercise_catalog t WHERE t.catalog_key=s.catalog_key);

WITH source(catalog_key,name,english,primary_muscle,secondary_muscle,pattern) AS (
 VALUES
  ('catalog:Tirón alto de arrancada','Tirón alto de arrancada','Snatch High Pull','trapezius','gluteal','snatch_high_pull'),
  ('catalog:Tirón alto de cargada','Tirón alto de cargada','Clean High Pull','trapezius','gluteal','clean_high_pull'),
  ('catalog:Peso muerto de cargada','Peso muerto de cargada','Clean Deadlift','hamstring','gluteal','clean_deadlift'),
  ('catalog:Envión en sentadilla','Envión en sentadilla','Squat Jerk','deltoids','quadriceps','squat_jerk'),
  ('catalog:Dip y drive de envión','Dip y drive de envión','Jerk Dip and Drive','quadriceps','gluteal','jerk_dip_drive'),
  ('catalog:Arrancada de potencia desde bloques','Arrancada de potencia desde bloques','Block Power Snatch','quadriceps','deltoids','block_power_snatch'),
  ('catalog:Cargada de potencia desde bloques','Cargada de potencia desde bloques','Block Power Clean','quadriceps','trapezius','block_power_clean'),
  ('catalog:Push press con agarre de arrancada','Push press con agarre de arrancada','Snatch-Grip Push Press','deltoids','triceps','snatch_grip_push_press')
)
INSERT INTO public.training_exercise_metadata
(catalog_key,aliases,primary_muscles,secondary_muscles,equipment,required_equipment,movement_pattern,metadata_source)
SELECT catalog_key,ARRAY[name,english]::text[],ARRAY[primary_muscle]::text[],
ARRAY[secondary_muscle]::text[],ARRAY['Barra']::text[],ARRAY['barbell']::text[],
pattern,'native:CatalogHalterofilia'
FROM source
ON CONFLICT (catalog_key) DO NOTHING;
