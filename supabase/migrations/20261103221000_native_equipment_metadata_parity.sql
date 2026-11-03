-- New forward-only migration. Keep previously applied migration files immutable.
-- Native gymnastics and CrossFit metadata is authoritative; preserve unrelated curated sources.
WITH source_rows(catalog_key,primary_muscles,secondary_muscles,equipment,native_source) AS (
 VALUES
  ('catalog:Dominadas lastradas', ARRAY['upper-back','biceps']::text[], ARRAY['forearm','abs']::text[], ARRAY['Barra de dominadas, Lastre']::text[], 'native:CatalogGimnasia'),
  ('catalog:Remo pliométrico en anillas pies elevados', ARRAY['upper-back']::text[], ARRAY['biceps','deltoids','abs']::text[], ARRAY['Anillas, Plataforma elevada']::text[], 'native:CatalogGimnasia'),
  ('catalog:Dominadas estrictas', ARRAY['upper-back']::text[], ARRAY['biceps','abs']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Dominadas kipping', ARRAY['upper-back']::text[], ARRAY['abs','deltoids']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Dominadas butterfly', ARRAY['upper-back']::text[], ARRAY['abs']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Dominadas supinas', ARRAY['biceps','upper-back']::text[], ARRAY[]::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Chest to bar', ARRAY['upper-back']::text[], ARRAY['biceps','abs']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Dominadas en anillas', ARRAY['upper-back']::text[], ARRAY['biceps','abs']::text[], ARRAY['Anillas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Remo en anillas', ARRAY['upper-back']::text[], ARRAY['biceps']::text[], ARRAY['Anillas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Archer pull-up', ARRAY['upper-back']::text[], ARRAY['biceps','deltoids']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Muscle-up barra', ARRAY['upper-back']::text[], ARRAY['triceps','chest','abs']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Muscle-up anillas', ARRAY['upper-back']::text[], ARRAY['triceps','chest','deltoids']::text[], ARRAY['Anillas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Muscle-up estricto barra', ARRAY['upper-back','triceps']::text[], ARRAY['chest','abs']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Muscle-up estricto anillas', ARRAY['upper-back','triceps']::text[], ARRAY['chest']::text[], ARRAY['Anillas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Pull-over barra', ARRAY['upper-back','abs']::text[], ARRAY['chest']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Toes to bar', ARRAY['abs']::text[], ARRAY['hip-flexors','forearm']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Toes to bar estrictos', ARRAY['abs']::text[], ARRAY['hip-flexors']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Knees to elbows', ARRAY['abs']::text[], ARRAY['hip-flexors']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Toes to rings', ARRAY['abs']::text[], ARRAY['hip-flexors']::text[], ARRAY['Anillas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Hip to bar', ARRAY['abs','upper-back']::text[], ARRAY['hip-flexors']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Kip swing', ARRAY['abs']::text[], ARRAY['deltoids','upper-back']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:HSPU', ARRAY['deltoids']::text[], ARRAY['triceps','trapezius']::text[], ARRAY['Pared']::text[], 'native:CatalogGimnasia'),
  ('catalog:HSPU deficit', ARRAY['deltoids']::text[], ARRAY['triceps']::text[], ARRAY['Pared, Paralelas bajas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Wall walk', ARRAY['deltoids','chest']::text[], ARRAY['abs','triceps']::text[], ARRAY['Pared']::text[], 'native:CatalogGimnasia'),
  ('catalog:Fondos en anillas kipping', ARRAY['triceps','chest']::text[], ARRAY['deltoids','abs']::text[], ARRAY['Anillas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Fondos en anillas', ARRAY['triceps','chest']::text[], ARRAY['deltoids','abs']::text[], ARRAY['Anillas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Fondos en paralelas', ARRAY['triceps','chest']::text[], ARRAY['deltoids']::text[], ARRAY['Paralelas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Soporte en anillas', ARRAY['deltoids','triceps']::text[], ARRAY['abs']::text[], ARRAY['Anillas']::text[], 'native:CatalogGimnasia'),
  ('catalog:False grip hang', ARRAY['forearm']::text[], ARRAY['upper-back']::text[], ARRAY['Anillas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Skin the cat', ARRAY['deltoids','upper-back']::text[], ARRAY['abs']::text[], ARRAY['Anillas']::text[], 'native:CatalogGimnasia'),
  ('catalog:German hang', ARRAY['deltoids']::text[], ARRAY['chest']::text[], ARRAY['Anillas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Front lever tuck', ARRAY['upper-back','abs']::text[], ARRAY['deltoids']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:Back lever tuck', ARRAY['deltoids','upper-back']::text[], ARRAY['abs']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogGimnasia'),
  ('catalog:GHD sit-up', ARRAY['abs']::text[], ARRAY['hip-flexors','quadriceps']::text[], ARRAY['GHD']::text[], 'native:CatalogGimnasia'),
  ('catalog:GHD back extension', ARRAY['lower-back','gluteal']::text[], ARRAY['hamstring']::text[], ARRAY['GHD']::text[], 'native:CatalogGimnasia'),
  ('catalog:Rope climb', ARRAY['upper-back','forearm']::text[], ARRAY['biceps','abs']::text[], ARRAY['Cuerda de trepa']::text[], 'native:CatalogGimnasia'),
  ('catalog:Rope climb legless', ARRAY['upper-back','biceps']::text[], ARRAY['forearm','abs']::text[], ARRAY['Cuerda de trepa']::text[], 'native:CatalogGimnasia'),
  ('catalog:Pegboard', ARRAY['upper-back','deltoids']::text[], ARRAY['abs','forearm']::text[], ARRAY['Pegboard']::text[], 'native:CatalogGimnasia'),
  ('catalog:Step-up al cajón con kettlebell goblet', ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Cajón, Kettlebell']::text[], 'native:CatalogCrossFit'),
  ('catalog:Carrera', ARRAY[]::text[], ARRAY['quadriceps','calves','gluteal']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogCrossFit'),
  ('catalog:Burpee box jump over', ARRAY['quadriceps','chest']::text[], ARRAY['gluteal','abs']::text[], ARRAY['Cajón']::text[], 'native:CatalogCrossFit'),
  ('catalog:Burpee al cajón', ARRAY['quadriceps','gluteal']::text[], ARRAY['chest','abs']::text[], ARRAY['Cajón']::text[], 'native:CatalogCrossFit'),
  ('catalog:Bar facing burpee', ARRAY['chest','quadriceps']::text[], ARRAY['abs']::text[], ARRAY['Barra (obstáculo)']::text[], 'native:CatalogCrossFit'),
  ('catalog:Burpee pull-up', ARRAY['upper-back','chest']::text[], ARRAY['abs','quadriceps']::text[], ARRAY['Barra de dominadas']::text[], 'native:CatalogCrossFit'),
  ('catalog:Salto al cajón', ARRAY['quadriceps','gluteal']::text[], ARRAY['calves']::text[], ARRAY['Cajón']::text[], 'native:CatalogCrossFit'),
  ('catalog:Step-up al cajón', ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring']::text[], ARRAY['Cajón']::text[], 'native:CatalogCrossFit'),
  ('catalog:Box jump over', ARRAY['quadriceps']::text[], ARRAY['gluteal','calves']::text[], ARRAY['Cajón']::text[], 'native:CatalogCrossFit'),
  ('catalog:Wall ball', ARRAY['quadriceps','deltoids']::text[], ARRAY['gluteal','abs']::text[], ARRAY['Wall Ball']::text[], 'native:CatalogCrossFit'),
  ('catalog:Ball slam', ARRAY['abs','upper-back']::text[], ARRAY['deltoids']::text[], ARRAY['Slam Ball']::text[], 'native:CatalogCrossFit'),
  ('catalog:Air bike', ARRAY[]::text[], ARRAY['quadriceps','gluteal','deltoids']::text[], ARRAY['Air Bike']::text[], 'native:CatalogCrossFit'),
  ('catalog:Echo bike', ARRAY[]::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['Echo Bike']::text[], 'native:CatalogCrossFit'),
  ('catalog:SkiErg', ARRAY['upper-back']::text[], ARRAY['triceps','abs']::text[], ARRAY['SkiErg']::text[], 'native:CatalogCrossFit')
)
UPDATE public.training_exercise_metadata AS m
SET primary_muscles = src.primary_muscles,
    secondary_muscles = src.secondary_muscles,
    equipment = src.equipment,
    metadata_source = CASE WHEN m.metadata_source = 'unmapped' THEN src.native_source ELSE m.metadata_source END,
    updated_at = now()
FROM source_rows src
WHERE m.catalog_key = src.catalog_key
 AND (
   m.metadata_source = src.native_source OR m.metadata_source = 'unmapped'
   OR (m.metadata_source LIKE 'photo:%' AND src.catalog_key IN (
     'catalog:Dominadas lastradas',
     'catalog:Remo pliométrico en anillas pies elevados',
     'catalog:Step-up al cajón con kettlebell goblet',
     'catalog:Carrera'
   ))
 )
 AND (m.primary_muscles,m.secondary_muscles,m.equipment)
     IS DISTINCT FROM (src.primary_muscles,src.secondary_muscles,src.equipment);
