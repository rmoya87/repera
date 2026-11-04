-- Phase D: Open WOD gaps + material variants + alias/pattern enrich (own-words ES)
-- Catalog 318 → 433. Near-dups only as aliases.

-- Alias enrich → Ab Mat Sit-Up
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Ab Mat Sit Up','abmat sit-up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Ab Mat Sit-Up';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Ab Mat Sit-Up: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Ab Mat Sit Up')
WHERE catalog_key = 'catalog:Ab Mat Sit-Up'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Ab wheel
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Ab Wheel']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Ab wheel';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Ab wheel: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Ab Wheel')
WHERE catalog_key = 'catalog:Ab wheel'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Air squat
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Air Squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Air squat';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Air squat: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Air Squat')
WHERE catalog_key = 'catalog:Air squat'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Alternating Dumbbell Snatch
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Alternating Dumbbell Power Snatch']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Alternating Dumbbell Snatch';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Alternating Dumbbell Snatch: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Alternating Dumbbell Power Snatch')
WHERE catalog_key = 'catalog:Alternating Dumbbell Snatch'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Alternating Dumbbell Snatch
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Alternating Dumbbell Snatch']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Alternating Dumbbell Snatch';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Alternating Dumbbell Snatch: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Alternating Dumbbell Snatch')
WHERE catalog_key = 'catalog:Alternating Dumbbell Snatch'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Swing americano
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['American Kettlebell Swing','kettlebell swing (american)']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:Swing americano';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Swing americano: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'American Kettlebell Swing')
WHERE catalog_key = 'catalog:Swing americano'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Air bike
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Assault Bike']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Air bike';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Air bike: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Assault Bike')
WHERE catalog_key = 'catalog:Air bike'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → GHD back extension
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Back Extension']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:GHD back extension';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'GHD back extension: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Back Extension')
WHERE catalog_key = 'catalog:GHD back extension'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Sentadilla
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Back Squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Sentadilla';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Sentadilla: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Back Squat')
WHERE catalog_key = 'catalog:Sentadilla'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Ball slam
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Ball Slam','slam ball']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Ball slam';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Ball slam: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Ball Slam')
WHERE catalog_key = 'catalog:Ball slam'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Fondos en paralelas
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Bar Dip']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Fondos en paralelas';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Fondos en paralelas: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Bar Dip')
WHERE catalog_key = 'catalog:Fondos en paralelas'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Bar facing burpee
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Bar Facing Burpee']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Bar facing burpee';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Bar facing burpee: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Bar Facing Burpee')
WHERE catalog_key = 'catalog:Bar facing burpee'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Muscle-up barra
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Bar Muscle Up','bmu']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Muscle-up barra';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Muscle-up barra: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Bar Muscle Up')
WHERE catalog_key = 'catalog:Muscle-up barra'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Bear crawl
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Bear Crawl']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Bear crawl';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Bear crawl: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Bear Crawl')
WHERE catalog_key = 'catalog:Bear crawl'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Bear Hug Carry
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Bear Hug Carry']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'carry')
WHERE catalog_key = 'catalog:Bear Hug Carry';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Bear Hug Carry: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Bear Hug Carry')
WHERE catalog_key = 'catalog:Bear Hug Carry'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Behind-the-Neck Jerk
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Behind The Neck Jerk']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Behind-the-Neck Jerk';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Behind-the-Neck Jerk: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Behind The Neck Jerk')
WHERE catalog_key = 'catalog:Behind-the-Neck Jerk'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Press banca
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Bench Press']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Press banca';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Press banca: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Bench Press')
WHERE catalog_key = 'catalog:Press banca'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Remo con barra
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Bent Over Row','barbell row']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Remo con barra';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Remo con barra: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Bent Over Row')
WHERE catalog_key = 'catalog:Remo con barra'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Curl mancuernas
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Bicep Curl']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Curl mancuernas';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Curl mancuernas: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Bicep Curl')
WHERE catalog_key = 'catalog:Curl mancuernas'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Air bike
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Bike']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Air bike';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Air bike: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Bike')
WHERE catalog_key = 'catalog:Air bike'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Bike Erg
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Bike Erg']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Bike Erg';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Bike Erg: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Bike Erg')
WHERE catalog_key = 'catalog:Bike Erg'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Salto al cajón
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Box Jump']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Salto al cajón';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Salto al cajón: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Box Jump')
WHERE catalog_key = 'catalog:Salto al cajón'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Box jump over
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Box Jump Over']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Box jump over';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Box jump over: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Box Jump Over')
WHERE catalog_key = 'catalog:Box jump over'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Box Squat
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Box Squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Box Squat';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Box Squat: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Box Squat')
WHERE catalog_key = 'catalog:Box Squat'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Step-up al cajón
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Box Step Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Step-up al cajón';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Step-up al cajón: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Box Step Up')
WHERE catalog_key = 'catalog:Step-up al cajón'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Broad jump
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Broad Jump']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Broad jump';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Broad jump: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Broad Jump')
WHERE catalog_key = 'catalog:Broad jump'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Sentadilla búlgara
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Bulgarian Split Squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Sentadilla búlgara';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Sentadilla búlgara: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Bulgarian Split Squat')
WHERE catalog_key = 'catalog:Sentadilla búlgara'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Burpee
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Burpee']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Burpee';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Burpee: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Burpee')
WHERE catalog_key = 'catalog:Burpee'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Burpee al cajón
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Burpee Box Jump']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Burpee al cajón';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Burpee al cajón: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Burpee Box Jump')
WHERE catalog_key = 'catalog:Burpee al cajón'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Burpee box jump over
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Burpee Box Jump Over']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Burpee box jump over';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Burpee box jump over: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Burpee Box Jump Over')
WHERE catalog_key = 'catalog:Burpee box jump over'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Burpee Broad Jump
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Burpee Broad Jump']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Burpee Broad Jump';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Burpee Broad Jump: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Burpee Broad Jump')
WHERE catalog_key = 'catalog:Burpee Broad Jump'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Burpee Muscle-Up
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Burpee Muscle Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Burpee Muscle-Up';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Burpee Muscle-Up: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Burpee Muscle Up')
WHERE catalog_key = 'catalog:Burpee Muscle-Up'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Burpee pull-up
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Burpee Pull Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Burpee pull-up';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Burpee pull-up: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Burpee Pull Up')
WHERE catalog_key = 'catalog:Burpee pull-up'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dominadas butterfly
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Butterfly Pull Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Dominadas butterfly';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dominadas butterfly: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Butterfly Pull Up')
WHERE catalog_key = 'catalog:Dominadas butterfly'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Elevación de gemelos
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Calf Raise']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Elevación de gemelos';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Elevación de gemelos: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Calf Raise')
WHERE catalog_key = 'catalog:Elevación de gemelos'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Chest to bar
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Chest To Bar Pull Up','chest-to-bar','c2b']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Chest to bar';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Chest to bar: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Chest To Bar Pull Up')
WHERE catalog_key = 'catalog:Chest to bar'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dominadas supinas
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Chin Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Dominadas supinas';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dominadas supinas: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Chin Up')
WHERE catalog_key = 'catalog:Dominadas supinas'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Clean
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Clean';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Clean: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Clean')
WHERE catalog_key = 'catalog:Clean'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Clean and Jerk
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Clean And Jerk','c&j']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Clean and Jerk';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Clean and Jerk: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Clean And Jerk')
WHERE catalog_key = 'catalog:Clean and Jerk'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Clean Pull
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Clean Pull']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Clean Pull';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Clean Pull: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Clean Pull')
WHERE catalog_key = 'catalog:Clean Pull'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Press cerrado
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Close Grip Bench Press']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Press cerrado';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Press cerrado: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Close Grip Bench Press')
WHERE catalog_key = 'catalog:Press cerrado'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Cluster
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Cluster']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Cluster';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Cluster: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Cluster')
WHERE catalog_key = 'catalog:Cluster'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Cossack squat
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Cossack Squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Cossack squat';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Cossack squat: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Cossack Squat')
WHERE catalog_key = 'catalog:Cossack squat'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → D-Ball Clean
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['D Ball Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:D-Ball Clean';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'D-Ball Clean: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'D Ball Clean')
WHERE catalog_key = 'catalog:D-Ball Clean'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → D-Ball Over Shoulder
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['D Ball Over Shoulder']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:D-Ball Over Shoulder';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'D-Ball Over Shoulder: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'D Ball Over Shoulder')
WHERE catalog_key = 'catalog:D-Ball Over Shoulder'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Peso muerto
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Deadlift']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:Peso muerto';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Peso muerto: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Deadlift')
WHERE catalog_key = 'catalog:Peso muerto'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → HSPU deficit
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Deficit Handstand Push Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:HSPU deficit';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'HSPU deficit: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Deficit Handstand Push Up')
WHERE catalog_key = 'catalog:HSPU deficit'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Devil press
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Devils Press','devil''s press']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Devil press';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Devil press: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Devils Press')
WHERE catalog_key = 'catalog:Devil press'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Double Kettlebell Front Rack Carry
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Double Kettlebell Front Rack Carry']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'carry')
WHERE catalog_key = 'catalog:Double Kettlebell Front Rack Carry';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Double Kettlebell Front Rack Carry: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Double Kettlebell Front Rack Carry')
WHERE catalog_key = 'catalog:Double Kettlebell Front Rack Carry'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Double Kettlebell Overhead Carry
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Double Kettlebell Overhead Carry']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'carry')
WHERE catalog_key = 'catalog:Double Kettlebell Overhead Carry';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Double Kettlebell Overhead Carry: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Double Kettlebell Overhead Carry')
WHERE catalog_key = 'catalog:Double Kettlebell Overhead Carry'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dobles de comba
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Double Under','du','dubs']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Dobles de comba';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dobles de comba: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Double Under')
WHERE catalog_key = 'catalog:Dobles de comba'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Clean mancuerna
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Clean mancuerna';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Clean mancuerna: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Clean')
WHERE catalog_key = 'catalog:Clean mancuerna'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Cargada y envión con mancuerna
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Clean And Jerk']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Cargada y envión con mancuerna';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Cargada y envión con mancuerna: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Clean And Jerk')
WHERE catalog_key = 'catalog:Cargada y envión con mancuerna'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dumbbell Front Rack Lunge
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Front Rack Lunge']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Dumbbell Front Rack Lunge';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dumbbell Front Rack Lunge: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Front Rack Lunge')
WHERE catalog_key = 'catalog:Dumbbell Front Rack Lunge'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dumbbell Front Squat
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Front Rack Squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Dumbbell Front Squat';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dumbbell Front Squat: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Front Rack Squat')
WHERE catalog_key = 'catalog:Dumbbell Front Squat'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dumbbell Front Squat
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Front Squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Dumbbell Front Squat';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dumbbell Front Squat: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Front Squat')
WHERE catalog_key = 'catalog:Dumbbell Front Squat'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dumbbell Hang Clean and Jerk
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Hang Clean And Jerk']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Dumbbell Hang Clean and Jerk';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dumbbell Hang Clean and Jerk: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Hang Clean And Jerk')
WHERE catalog_key = 'catalog:Dumbbell Hang Clean and Jerk'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dumbbell Overhead Lunge
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Overhead Lunge']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Dumbbell Overhead Lunge';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dumbbell Overhead Lunge: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Overhead Lunge')
WHERE catalog_key = 'catalog:Dumbbell Overhead Lunge'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dumbbell Overhead Squat
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Overhead Squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Dumbbell Overhead Squat';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dumbbell Overhead Squat: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Overhead Squat')
WHERE catalog_key = 'catalog:Dumbbell Overhead Squat'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dumbbell Power Clean
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Power Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Dumbbell Power Clean';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dumbbell Power Clean: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Power Clean')
WHERE catalog_key = 'catalog:Dumbbell Power Clean'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dumbbell Power Snatch
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Power Snatch']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Dumbbell Power Snatch';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dumbbell Power Snatch: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Power Snatch')
WHERE catalog_key = 'catalog:Dumbbell Power Snatch'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dumbbell Push Jerk
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Push Jerk']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Dumbbell Push Jerk';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dumbbell Push Jerk: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Push Jerk')
WHERE catalog_key = 'catalog:Dumbbell Push Jerk'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dumbbell Push Press
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Push Press']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Dumbbell Push Press';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dumbbell Push Press: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Push Press')
WHERE catalog_key = 'catalog:Dumbbell Push Press'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Remo mancuerna
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Row']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Remo mancuerna';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Remo mancuerna: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Row')
WHERE catalog_key = 'catalog:Remo mancuerna'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Snatch mancuerna
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Snatch']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Snatch mancuerna';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Snatch mancuerna: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Snatch')
WHERE catalog_key = 'catalog:Snatch mancuerna'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Thruster mancuernas
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Thruster']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Thruster mancuernas';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Thruster mancuernas: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Thruster')
WHERE catalog_key = 'catalog:Thruster mancuernas'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dumbbell Walking Lunge
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Walking Lunge']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Dumbbell Walking Lunge';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dumbbell Walking Lunge: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Walking Lunge')
WHERE catalog_key = 'catalog:Dumbbell Walking Lunge'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Echo bike
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Echo Bike']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Echo bike';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Echo bike: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Echo Bike')
WHERE catalog_key = 'catalog:Echo bike'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Face pull
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Face Pull']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Face pull';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Face pull: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Face Pull')
WHERE catalog_key = 'catalog:Face pull'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Farmer carry
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Farmers Carry']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'carry')
WHERE catalog_key = 'catalog:Farmer carry';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Farmer carry: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Farmers Carry')
WHERE catalog_key = 'catalog:Farmer carry'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → HSPU libre
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Freestanding Handstand Push Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:HSPU libre';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'HSPU libre: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Freestanding Handstand Push Up')
WHERE catalog_key = 'catalog:HSPU libre'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Front rack lunge
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Front Rack Lunge']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Front rack lunge';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Front rack lunge: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Front Rack Lunge')
WHERE catalog_key = 'catalog:Front rack lunge'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Elevaciones frontales
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Front Raise']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Elevaciones frontales';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Elevaciones frontales: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Front Raise')
WHERE catalog_key = 'catalog:Elevaciones frontales'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Sentadilla frontal
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Front Squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Sentadilla frontal';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Sentadilla frontal: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Front Squat')
WHERE catalog_key = 'catalog:Sentadilla frontal'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → GHD back extension
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Ghd Hip Extension']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:GHD back extension';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'GHD back extension: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Ghd Hip Extension')
WHERE catalog_key = 'catalog:GHD back extension'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → GHD sit-up
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Ghd Sit Up','ghd sit-up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:GHD sit-up';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'GHD sit-up: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Ghd Sit Up')
WHERE catalog_key = 'catalog:GHD sit-up'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Goblet squat
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Goblet Squat','kettlebell goblet squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Goblet squat';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Goblet squat: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Goblet Squat')
WHERE catalog_key = 'catalog:Goblet squat'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Buenos días
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Good Morning']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:Buenos días';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Buenos días: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Good Morning')
WHERE catalog_key = 'catalog:Buenos días'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Ground to overhead
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Ground To Overhead']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Ground to overhead';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Ground to overhead: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Ground To Overhead')
WHERE catalog_key = 'catalog:Ground to overhead'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Curl martillo
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Hammer Curl']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Curl martillo';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Curl martillo: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Hammer Curl')
WHERE catalog_key = 'catalog:Curl martillo'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Handstand hold
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Handstand']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Handstand hold';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Handstand hold: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Handstand')
WHERE catalog_key = 'catalog:Handstand hold'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Handstand hold
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Handstand Hold']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Handstand hold';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Handstand hold: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Handstand Hold')
WHERE catalog_key = 'catalog:Handstand hold'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → HSPU
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Handstand Push Up','hspu']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:HSPU';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'HSPU: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Handstand Push Up')
WHERE catalog_key = 'catalog:HSPU'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Handstand walk
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Handstand Walk','hs walk']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Handstand walk';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Handstand walk: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Handstand Walk')
WHERE catalog_key = 'catalog:Handstand walk'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Hang Clean
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Hang Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Hang Clean';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Hang Clean: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Hang Clean')
WHERE catalog_key = 'catalog:Hang Clean'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Hang power clean
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Hang Power Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Hang power clean';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Hang power clean: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Hang Power Clean')
WHERE catalog_key = 'catalog:Hang power clean'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Hang power snatch
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Hang Power Snatch']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Hang power snatch';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Hang power snatch: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Hang Power Snatch')
WHERE catalog_key = 'catalog:Hang power snatch'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Hang Snatch
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Hang Snatch']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Hang Snatch';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Hang Snatch: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Hang Snatch')
WHERE catalog_key = 'catalog:Hang Snatch'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Hang Squat Clean
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Hang Squat Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Hang Squat Clean';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Hang Squat Clean: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Hang Squat Clean')
WHERE catalog_key = 'catalog:Hang Squat Clean'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Carrera
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['High Knees']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Carrera';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Carrera: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'High Knees')
WHERE catalog_key = 'catalog:Carrera'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → GHD back extension
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Hip Extension']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:GHD back extension';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'GHD back extension: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Hip Extension')
WHERE catalog_key = 'catalog:GHD back extension'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Hip thrust
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Hip Thrust']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:Hip thrust';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Hip thrust: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Hip Thrust')
WHERE catalog_key = 'catalog:Hip thrust'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Hollow hold
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Hollow Hold']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Hollow hold';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Hollow hold: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Hollow Hold')
WHERE catalog_key = 'catalog:Hollow hold'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Hollow rock
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Hollow Rock']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Hollow rock';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Hollow rock: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Hollow Rock')
WHERE catalog_key = 'catalog:Hollow rock'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Inchworm
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Inchworm']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Inchworm';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Inchworm: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Inchworm')
WHERE catalog_key = 'catalog:Inchworm'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Press banca inclinada
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Incline Bench Press']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Press banca inclinada';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Press banca inclinada: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Incline Bench Press')
WHERE catalog_key = 'catalog:Press banca inclinada'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Push jerk
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Jerk']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Push jerk';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Push jerk: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Jerk')
WHERE catalog_key = 'catalog:Push jerk'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Jumping lunge
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Jumping Lunge']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Jumping lunge';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Jumping lunge: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Jumping Lunge')
WHERE catalog_key = 'catalog:Jumping lunge'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Jumping Pull-Up
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Jumping Pull Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Jumping Pull-Up';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Jumping Pull-Up: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Jumping Pull Up')
WHERE catalog_key = 'catalog:Jumping Pull-Up'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Clean kettlebell
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Kettlebell Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Clean kettlebell';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Clean kettlebell: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Kettlebell Clean')
WHERE catalog_key = 'catalog:Clean kettlebell'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Kettlebell Clean and Jerk
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Kettlebell Clean And Jerk']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Kettlebell Clean and Jerk';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Kettlebell Clean and Jerk: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Kettlebell Clean And Jerk')
WHERE catalog_key = 'catalog:Kettlebell Clean and Jerk'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Kettlebell Overhead Lunge
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Kettlebell Overhead Lunge']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Kettlebell Overhead Lunge';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Kettlebell Overhead Lunge: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Kettlebell Overhead Lunge')
WHERE catalog_key = 'catalog:Kettlebell Overhead Lunge'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Kettlebell Push Press
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Kettlebell Push Press']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Kettlebell Push Press';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Kettlebell Push Press: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Kettlebell Push Press')
WHERE catalog_key = 'catalog:Kettlebell Push Press'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Snatch kettlebell
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Kettlebell Snatch']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Snatch kettlebell';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Snatch kettlebell: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Kettlebell Snatch')
WHERE catalog_key = 'catalog:Snatch kettlebell'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Swing kettlebell
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Kettlebell Swing','kb swing']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:Swing kettlebell';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Swing kettlebell: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Kettlebell Swing')
WHERE catalog_key = 'catalog:Swing kettlebell'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dominadas kipping
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Kipping Pull Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Dominadas kipping';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dominadas kipping: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Kipping Pull Up')
WHERE catalog_key = 'catalog:Dominadas kipping'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Knees to elbows
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Knees To Elbows','k2e']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Knees to elbows';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Knees to elbows: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Knees To Elbows')
WHERE catalog_key = 'catalog:Knees to elbows'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → L-sit
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['L Sit']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:L-sit';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'L-sit: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'L Sit')
WHERE catalog_key = 'catalog:L-sit'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Elevaciones laterales
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Lateral Raise']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Elevaciones laterales';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Elevaciones laterales: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Lateral Raise')
WHERE catalog_key = 'catalog:Elevaciones laterales'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Rope climb legless
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Legless Rope Climb']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Rope climb legless';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Rope climb legless: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Legless Rope Climb')
WHERE catalog_key = 'catalog:Rope climb legless'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Man maker
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Man Maker']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Man maker';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Man maker: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Man Maker')
WHERE catalog_key = 'catalog:Man maker'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Medball clean
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Medicine Ball Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Medball clean';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Medball clean: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Medicine Ball Clean')
WHERE catalog_key = 'catalog:Medball clean'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Muscle Clean
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Muscle Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Muscle Clean';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Muscle Clean: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Muscle Clean')
WHERE catalog_key = 'catalog:Muscle Clean'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Muscle Snatch
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Muscle Snatch']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Muscle Snatch';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Muscle Snatch: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Muscle Snatch')
WHERE catalog_key = 'catalog:Muscle Snatch'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Muscle-up barra
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Muscle Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Muscle-up barra';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Muscle-up barra: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Muscle Up')
WHERE catalog_key = 'catalog:Muscle-up barra'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Overhead squat
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Overhead Squat','ohs']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Overhead squat';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Overhead squat: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Overhead Squat')
WHERE catalog_key = 'catalog:Overhead squat'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Overhead Lunge
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Overhead Walking Lunge']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Overhead Lunge';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Overhead Lunge: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Overhead Walking Lunge')
WHERE catalog_key = 'catalog:Overhead Lunge'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Pegboard
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Pegboard','peg board']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Pegboard';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Pegboard: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Pegboard')
WHERE catalog_key = 'catalog:Pegboard'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Pike push-up
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Pike Push Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Pike push-up';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Pike push-up: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Pike Push Up')
WHERE catalog_key = 'catalog:Pike push-up'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Pistol squat
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Pistol','single-leg squat','pistol squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Pistol squat';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Pistol squat: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Pistol')
WHERE catalog_key = 'catalog:Pistol squat'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Plancha
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Plank']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Plancha';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Plancha: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Plank')
WHERE catalog_key = 'catalog:Plancha'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Plate ground to overhead
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Plate Ground To Overhead']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Plate ground to overhead';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Plate ground to overhead: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Plate Ground To Overhead')
WHERE catalog_key = 'catalog:Plate ground to overhead'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Power Clean
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Power Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Power Clean';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Power Clean: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Power Clean')
WHERE catalog_key = 'catalog:Power Clean'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Power Snatch
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Power Snatch']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Power Snatch';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Power Snatch: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Power Snatch')
WHERE catalog_key = 'catalog:Power Snatch'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Pullover
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Pull Over']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Pullover';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Pullover: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Pull Over')
WHERE catalog_key = 'catalog:Pullover'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dominadas
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Pull Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Dominadas';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dominadas: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Pull Up')
WHERE catalog_key = 'catalog:Dominadas'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Push jerk
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Push Jerk']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Push jerk';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Push jerk: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Push Jerk')
WHERE catalog_key = 'catalog:Push jerk'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Push press
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Push Press']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Push press';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Push press: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Push Press')
WHERE catalog_key = 'catalog:Push press'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Zancadas
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Reverse Lunge']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Zancadas';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Zancadas: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Reverse Lunge')
WHERE catalog_key = 'catalog:Zancadas'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Fondos en anillas
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Ring Dip']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Fondos en anillas';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Fondos en anillas: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Ring Dip')
WHERE catalog_key = 'catalog:Fondos en anillas'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Muscle-up anillas
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Ring Muscle Up','rmu']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Muscle-up anillas';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Muscle-up anillas: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Ring Muscle Up')
WHERE catalog_key = 'catalog:Muscle-up anillas'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Remo en anillas
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Ring Row']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Remo en anillas';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Remo en anillas: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Ring Row')
WHERE catalog_key = 'catalog:Remo en anillas'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Peso muerto rumano
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Romanian Deadlift']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:Peso muerto rumano';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Peso muerto rumano: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Romanian Deadlift')
WHERE catalog_key = 'catalog:Peso muerto rumano'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Rope climb
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Rope Climb']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Rope climb';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Rope climb: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Rope Climb')
WHERE catalog_key = 'catalog:Rope climb'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Remo máquina
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Row']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Remo máquina';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Remo máquina: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Row')
WHERE catalog_key = 'catalog:Remo máquina'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Carrera
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Run']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Carrera';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Carrera: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Run')
WHERE catalog_key = 'catalog:Carrera'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Carrera
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Run Backward']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Carrera';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Carrera: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Run Backward')
WHERE catalog_key = 'catalog:Carrera'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Swing kettlebell
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Russian Kettlebell Swing','kettlebell swing (russian)']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:Swing kettlebell';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Swing kettlebell: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Russian Kettlebell Swing')
WHERE catalog_key = 'catalog:Swing kettlebell'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Sandbag clean
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Sandbag Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Sandbag clean';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Sandbag clean: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Sandbag Clean')
WHERE catalog_key = 'catalog:Sandbag clean'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Sandbag Lunges
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Sandbag Lunge']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Sandbag Lunges';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Sandbag Lunges: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Sandbag Lunge')
WHERE catalog_key = 'catalog:Sandbag Lunges'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Push press
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Shoulder To Overhead']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Push press';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Push press: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Shoulder To Overhead')
WHERE catalog_key = 'catalog:Push press'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Shrimp squat
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Shrimp Squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Shrimp squat';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Shrimp squat: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Shrimp Squat')
WHERE catalog_key = 'catalog:Shrimp squat'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Shuttle run
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Shuttle Run']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Shuttle run';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Shuttle run: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Shuttle Run')
WHERE catalog_key = 'catalog:Shuttle run'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Shuttle run
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Shuttle Sprint']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Shuttle run';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Shuttle run: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Shuttle Sprint')
WHERE catalog_key = 'catalog:Shuttle run'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Simples de comba
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Single Under','jump rope']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Simples de comba';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Simples de comba: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Single Under')
WHERE catalog_key = 'catalog:Simples de comba'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Sit-up
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Sit Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Sit-up';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Sit-up: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Sit Up')
WHERE catalog_key = 'catalog:Sit-up'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → SkiErg
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Ski Erg','ski']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:SkiErg';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'SkiErg: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Ski Erg')
WHERE catalog_key = 'catalog:SkiErg'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Press francés
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Skull Crusher']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Press francés';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Press francés: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Skull Crusher')
WHERE catalog_key = 'catalog:Press francés'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Sled pull
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Sled Pull']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Sled pull';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Sled pull: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Sled Pull')
WHERE catalog_key = 'catalog:Sled pull'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Sled push
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Sled Push']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Sled push';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Sled push: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Sled Push')
WHERE catalog_key = 'catalog:Sled push'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Snatch
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Snatch']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Snatch';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Snatch: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Snatch')
WHERE catalog_key = 'catalog:Snatch'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Snatch Balance
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Snatch Balance']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Snatch Balance';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Snatch Balance: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Snatch Balance')
WHERE catalog_key = 'catalog:Snatch Balance'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Snatch-Grip Deadlift
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Snatch Grip Deadlift']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:Snatch-Grip Deadlift';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Snatch-Grip Deadlift: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Snatch Grip Deadlift')
WHERE catalog_key = 'catalog:Snatch-Grip Deadlift'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Snatch Pull
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Snatch Pull']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Snatch Pull';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Snatch Pull: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Snatch Pull')
WHERE catalog_key = 'catalog:Snatch Pull'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Sots press
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Sots Press']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Sots press';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Sots press: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Sots Press')
WHERE catalog_key = 'catalog:Sots press'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Split jerk
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Split Jerk']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Split jerk';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Split jerk: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Split Jerk')
WHERE catalog_key = 'catalog:Split jerk'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Sentadilla búlgara
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Split Squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Sentadilla búlgara';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Sentadilla búlgara: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Split Squat')
WHERE catalog_key = 'catalog:Sentadilla búlgara'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Carrera
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Sprint']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Carrera';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Carrera: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Sprint')
WHERE catalog_key = 'catalog:Carrera'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Clean
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Squat Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Clean';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Clean: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Squat Clean')
WHERE catalog_key = 'catalog:Clean'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Squat Jerk
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Squat Jerk']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Squat Jerk';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Squat Jerk: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Squat Jerk')
WHERE catalog_key = 'catalog:Squat Jerk'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Jumping squat
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Squat Jump','jump squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now()
WHERE catalog_key = 'catalog:Jumping squat';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Jumping squat: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Squat Jump')
WHERE catalog_key = 'catalog:Jumping squat'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Snatch
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Squat Snatch']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Snatch';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Snatch: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Squat Snatch')
WHERE catalog_key = 'catalog:Snatch'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Carrera
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Stair Climb']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Carrera';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Carrera: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Stair Climb')
WHERE catalog_key = 'catalog:Carrera'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Fondos en paralelas
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Strict Dip']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Fondos en paralelas';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Fondos en paralelas: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Strict Dip')
WHERE catalog_key = 'catalog:Fondos en paralelas'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → HSPU
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Strict Handstand Push Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:HSPU';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'HSPU: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Strict Handstand Push Up')
WHERE catalog_key = 'catalog:HSPU'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Muscle-up estricto barra
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Strict Muscle Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Muscle-up estricto barra';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Muscle-up estricto barra: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Strict Muscle Up')
WHERE catalog_key = 'catalog:Muscle-up estricto barra'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Strict press
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Strict Press']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Strict press';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Strict press: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Strict Press')
WHERE catalog_key = 'catalog:Strict press'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dominadas estrictas
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Strict Pull Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Dominadas estrictas';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dominadas estrictas: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Strict Pull Up')
WHERE catalog_key = 'catalog:Dominadas estrictas'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Peso muerto sumo
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Sumo Deadlift']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:Peso muerto sumo';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Peso muerto sumo: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Sumo Deadlift')
WHERE catalog_key = 'catalog:Peso muerto sumo'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Sumo high pull
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Sumo Deadlift High Pull','sdhp']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'hinge')
WHERE catalog_key = 'catalog:Sumo high pull';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Sumo high pull: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Sumo Deadlift High Pull')
WHERE catalog_key = 'catalog:Sumo high pull'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Tall clean
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Tall Clean']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'olympic')
WHERE catalog_key = 'catalog:Tall clean';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Tall clean: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Tall Clean')
WHERE catalog_key = 'catalog:Tall clean'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Thruster
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Thruster']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Thruster';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Thruster: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Thruster')
WHERE catalog_key = 'catalog:Thruster'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Toes to bar
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Toes To Bar','t2b']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Toes to bar';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Toes to bar: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Toes To Bar')
WHERE catalog_key = 'catalog:Toes to bar'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Toes to rings
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Toes To Ring']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Toes to rings';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Toes to rings: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Toes To Ring')
WHERE catalog_key = 'catalog:Toes to rings'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Extensión tríceps polea
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Tricep Extension']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Extensión tríceps polea';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Extensión tríceps polea: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Tricep Extension')
WHERE catalog_key = 'catalog:Extensión tríceps polea'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Triples de comba
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Triple Under']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'monostructural')
WHERE catalog_key = 'catalog:Triples de comba';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Triples de comba: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Triple Under')
WHERE catalog_key = 'catalog:Triples de comba'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Turkish get-up
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Turkish Get Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:Turkish get-up';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Turkish get-up: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Turkish Get Up')
WHERE catalog_key = 'catalog:Turkish get-up'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → V-up
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['V Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'core')
WHERE catalog_key = 'catalog:V-up';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'V-up: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'V Up')
WHERE catalog_key = 'catalog:V-up'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Walking lunge
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Walking Lunge']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Walking lunge';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Walking lunge: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Walking Lunge')
WHERE catalog_key = 'catalog:Walking lunge'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Wall ball
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Wall Ball Shot','wall ball']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Wall ball';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Wall ball: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Wall Ball Shot')
WHERE catalog_key = 'catalog:Wall ball'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → HSPU
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Wall Facing Handstand Push Up','chest-to-wall handstand push-up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:HSPU';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'HSPU: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Wall Facing Handstand Push Up')
WHERE catalog_key = 'catalog:HSPU'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Dominadas lastradas
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Weighted Pull Up']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Dominadas lastradas';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Dominadas lastradas: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Weighted Pull Up')
WHERE catalog_key = 'catalog:Dominadas lastradas'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Yoke carry
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Yoke Carry','yoke walk']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'carry')
WHERE catalog_key = 'catalog:Yoke carry';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Yoke carry: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Yoke Carry')
WHERE catalog_key = 'catalog:Yoke carry'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Press Arnold
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Arnold Press']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'push')
WHERE catalog_key = 'catalog:Press Arnold';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Press Arnold: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Arnold Press')
WHERE catalog_key = 'catalog:Press Arnold'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Overhead Lunge
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Barbell Overhead Lunge']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'lunge')
WHERE catalog_key = 'catalog:Overhead Lunge';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Overhead Lunge: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Barbell Overhead Lunge')
WHERE catalog_key = 'catalog:Overhead Lunge'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Goblet squat
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Dumbbell Goblet Squat']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Goblet squat';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Goblet squat: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Dumbbell Goblet Squat')
WHERE catalog_key = 'catalog:Goblet squat'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Thruster kettlebell
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Kettlebell Thruster']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'squat')
WHERE catalog_key = 'catalog:Thruster kettlebell';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Thruster kettlebell: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Kettlebell Thruster')
WHERE catalog_key = 'catalog:Thruster kettlebell'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Jalón al pecho
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Lat Pulldown']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Jalón al pecho';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Jalón al pecho: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Lat Pulldown')
WHERE catalog_key = 'catalog:Jalón al pecho'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Alias enrich → Remo sentado
UPDATE public.training_exercise_metadata
SET aliases = (
  SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(aliases, ARRAY[]::text[]) || ARRAY['Seated Row']::text[]))
),
    metadata_source = COALESCE(metadata_source,'') || '+phase_d_alias_20261104',
    updated_at = now(),
    movement_pattern = COALESCE(NULLIF(movement_pattern,''), 'pull')
WHERE catalog_key = 'catalog:Remo sentado';

UPDATE public.business_exercise_catalog
SET mobile_description = COALESCE(NULLIF(mobile_description,''), 'Remo sentado: patrón habitual de WOD; ejecutar con el estándar de rango y control de Repera.'),
    display_name_en = COALESCE(NULLIF(display_name_en,''), 'Seated Row')
WHERE catalog_key = 'catalog:Remo sentado'
  AND (mobile_description IS NULL OR btrim(mobile_description)='');

-- Atlas Stone Over Shoulder
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Atlas Stone Over Shoulder', 'Atlas Stone Over Shoulder', 'CrossFit', 'Atlas Stone Over Shoulder', 'Atlas Stone Over Shoulder: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Odd object', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Atlas Stone Over Shoulder', ARRAY['atlas stone','Piedra atlas al hombro','Atlas Stone Over Shoulder']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Odd object']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['odd_object']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Axle Deadlift
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Axle Deadlift', 'Axle Deadlift', 'CrossFit', 'Axle Deadlift', 'Peso muerto con barbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Axle', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Axle Deadlift', ARRAY['Peso muerto con axle','Axle Deadlift']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Axle']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Axle Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Axle Press', 'Axle Press', 'CrossFit', 'Axle Press', 'Empuje con barbell hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Axle', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Axle Press', ARRAY['Press con axle','Axle Press']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Axle']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Back Rack Lunge
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Back Rack Lunge', 'Back Rack Lunge', 'CrossFit', 'Back Rack Lunge', 'Zancada o step-up con barbell: rodilla alineada y control del tronco.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Back Rack Lunge', ARRAY['Zancada con barra en espalda','Back Rack Lunge']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'lunge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Barbell Squat Jump
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Barbell Squat Jump', 'Barbell Squat Jump', 'CrossFit', 'Barbell Squat Jump', 'Sentadilla con barbell: profundidad controlada y torso estable.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Barbell Squat Jump', ARRAY['Salto en sentadilla con barra','Barbell Squat Jump']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['calves']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'squat', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Barbell Step Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Barbell Step Up', 'Barbell Step Up', 'CrossFit', 'Barbell Step Up', 'Zancada o step-up con barbell: rodilla alineada y control del tronco.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Barbell Step Up', ARRAY['Step-up con barra','Barbell Step Up']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'lunge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Battle Rope
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Battle Rope', 'Battle Rope', 'CrossFit', 'Battle Rope', 'Odd-object o acondicionamiento (Battle Rope) con peso corporal; potencia y control.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Cuerda', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Battle Rope', ARRAY['Cuerda de batalla','Battle Rope']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Cuerda']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY['battle_rope']::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Bird Dog
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Bird Dog', 'Bird Dog', 'CrossFit', 'Bird Dog', 'Bird Dog: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Bird Dog', ARRAY['Bird dog']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Bodyweight Clean And Jerk
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Bodyweight Clean And Jerk', 'Bodyweight Clean And Jerk', 'CrossFit', 'Bodyweight Clean And Jerk', 'Empuje con barbell hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Bodyweight Clean And Jerk', ARRAY['Cargada y envión a peso corporal','Bodyweight Clean And Jerk']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'olympic', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Bradford Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Bradford Press', 'Bradford Press', 'CrossFit', 'Bradford Press', 'Empuje con barbell hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Bradford Press', ARRAY['Press Bradford','Bradford Press']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Burpee Bar Muscle Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Burpee Bar Muscle Up', 'Burpee Bar Muscle Up', 'CrossFit', 'Burpee Bar Muscle Up', 'Burpee con el obstáculo o implemento indicado; pecho al suelo y extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'back', 'Espalda', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Burpee Bar Muscle Up', ARRAY['Burpee a muscle-up de barra','Burpee Bar Muscle Up']::text[], ARRAY['upper-back']::text[], ARRAY['biceps','forearm']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Burpee Over Dumbbell
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Burpee Over Dumbbell', 'Burpee Over Dumbbell', 'CrossFit', 'Burpee Over Dumbbell', 'Burpee con el obstáculo o implemento indicado; pecho al suelo y extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Burpee Over Dumbbell', ARRAY['Burpee sobre mancuerna','Burpee Over Dumbbell','burpee over db']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Burpee Over The Bar
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Burpee Over The Bar', 'Burpee Over The Bar', 'CrossFit', 'Burpee Over The Bar', 'Burpee con el obstáculo o implemento indicado; pecho al suelo y extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Burpee Over The Bar', ARRAY['lateral burpee over the bar','Burpee sobre la barra','Burpee Over The Bar']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Copenhagen Plank
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Copenhagen Plank', 'Copenhagen Plank', 'CrossFit', 'Copenhagen Plank', 'Isométrico o control de tronco (Copenhagen Plank): línea estable sin compensar.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Copenhagen Plank', ARRAY['Plancha Copenhagen','Copenhagen Plank']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Crab Walk
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Crab Walk', 'Crab Walk', 'CrossFit', 'Crab Walk', 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Crab Walk', ARRAY['Caminata de cangrejo','Crab Walk']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Crossover Single Under
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Crossover Single Under', 'Crossover Single Under', 'CrossFit', 'Crossover Single Under', 'Crossover Single Under: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Crossover Single Under', ARRAY['Crossover Single Under']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'monostructural', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dead Bug
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dead Bug', 'Dead Bug', 'CrossFit', 'Dead Bug', 'Isométrico o control de tronco (Dead Bug): línea estable sin compensar.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dead Bug', ARRAY['Dead bug']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Deficit Deadlift
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Deficit Deadlift', 'Deficit Deadlift', 'CrossFit', 'Deficit Deadlift', 'Peso muerto con barbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Deficit Deadlift', ARRAY['Peso muerto en déficit','Deficit Deadlift']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Double Kettlebell Farmers Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Double Kettlebell Farmers Carry', 'Double Kettlebell Farmers Carry', 'CrossFit', 'Double Kettlebell Farmers Carry', 'Porte o caminata con kettlebell: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Kettlebell', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Double Kettlebell Farmers Carry', ARRAY['Farmer carry con dos kettlebells','Double Kettlebell Farmers Carry','double kb farmers carry']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Kettlebell']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY['kettlebell']::text[], 'editorial_phase_d_v1',
  'carry', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Double Kettlebell Front Rack Lunge
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Double Kettlebell Front Rack Lunge', 'Double Kettlebell Front Rack Lunge', 'CrossFit', 'Double Kettlebell Front Rack Lunge', 'Zancada o step-up con kettlebell: rodilla alineada y control del tronco.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Kettlebell', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Double Kettlebell Front Rack Lunge', ARRAY['Zancada en rack con dos kettlebells','Double Kettlebell Front Rack Lunge','double kb front rack lunge']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Kettlebell']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['kettlebell']::text[], 'editorial_phase_d_v1',
  'lunge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Bench Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Bench Press', 'Dumbbell Bench Press', 'CrossFit', 'Dumbbell Bench Press', 'Empuje con dumbbell hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Bench Press', ARRAY['Press banca con mancuernas','Dumbbell Bench Press','db bench press']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Box Step Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Box Step Up', 'Dumbbell Box Step Up', 'CrossFit', 'Dumbbell Box Step Up', 'Zancada o step-up con dumbbell: rodilla alineada y control del tronco.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Box Step Up', ARRAY['Step-up con mancuerna','Dumbbell Box Step Up','db box step up']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'lunge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Burpee Deadlift
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Burpee Deadlift', 'Dumbbell Burpee Deadlift', 'CrossFit', 'Dumbbell Burpee Deadlift', 'Peso muerto con dumbbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Burpee Deadlift', ARRAY['Burpee a peso muerto con mancuernas','Dumbbell Burpee Deadlift','db burpee deadlift']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Carry', 'Dumbbell Carry', 'CrossFit', 'Dumbbell Carry', 'Porte o caminata con dumbbell: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Carry', ARRAY['Porte con mancuernas','Dumbbell Carry','db carry']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'carry', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Deadlift
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Deadlift', 'Dumbbell Deadlift', 'CrossFit', 'Dumbbell Deadlift', 'Peso muerto con dumbbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Deadlift', ARRAY['Peso muerto con mancuernas','Dumbbell Deadlift','db deadlift']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Floor Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Floor Press', 'Dumbbell Floor Press', 'CrossFit', 'Dumbbell Floor Press', 'Empuje con dumbbell hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Floor Press', ARRAY['Press de suelo con mancuernas','Dumbbell Floor Press','db floor press']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Hang Clean To Overhead
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Hang Clean To Overhead', 'Dumbbell Hang Clean To Overhead', 'CrossFit', 'Dumbbell Hang Clean To Overhead', 'Olímpico/híbrido con dumbbell: recepción estable y marca clara en cada rep.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Hombros', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Hang Clean To Overhead', ARRAY['Cargada colgante a overhead con mancuerna','Dumbbell Hang Clean To Overhead','db hang clean to overhead']::text[], ARRAY['quadriceps','deltoids']::text[], ARRAY['trapezius','gluteal','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','shoulder','spine']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'olympic', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Hang Power Clean
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Hang Power Clean', 'Dumbbell Hang Power Clean', 'CrossFit', 'Dumbbell Hang Power Clean', 'Olímpico/híbrido con dumbbell: recepción estable y marca clara en cada rep.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Hombros', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Hang Power Clean', ARRAY['Cargada de potencia colgante con mancuerna','Dumbbell Hang Power Clean','db hang power clean']::text[], ARRAY['quadriceps','deltoids']::text[], ARRAY['trapezius','gluteal','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','shoulder','spine']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'olympic', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Hang Split Snatch
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Hang Split Snatch', 'Dumbbell Hang Split Snatch', 'CrossFit', 'Dumbbell Hang Split Snatch', 'Olímpico/híbrido con dumbbell: recepción estable y marca clara en cada rep.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Hang Split Snatch', ARRAY['Arrancada colgante en split con mancuerna','Dumbbell Hang Split Snatch','db hang split snatch']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'olympic', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Hang Squat Clean
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Hang Squat Clean', 'Dumbbell Hang Squat Clean', 'CrossFit', 'Dumbbell Hang Squat Clean', 'Sentadilla con dumbbell: profundidad controlada y torso estable.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Hang Squat Clean', ARRAY['Cargada completa colgante con mancuerna','Dumbbell Hang Squat Clean','db hang squat clean']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'olympic', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Overhead Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Overhead Carry', 'Dumbbell Overhead Carry', 'CrossFit', 'Dumbbell Overhead Carry', 'Porte o caminata con dumbbell: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Overhead Carry', ARRAY['Porte overhead con mancuernas','Dumbbell Overhead Carry','db overhead carry']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'carry', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Romanian Deadlift
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Romanian Deadlift', 'Dumbbell Romanian Deadlift', 'CrossFit', 'Dumbbell Romanian Deadlift', 'Peso muerto con dumbbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Romanian Deadlift', ARRAY['Peso muerto rumano con mancuernas','Dumbbell Romanian Deadlift','db romanian deadlift']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Shoulder Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Shoulder Press', 'Dumbbell Shoulder Press', 'CrossFit', 'Dumbbell Shoulder Press', 'Empuje con dumbbell hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Shoulder Press', ARRAY['Press de hombros con mancuernas','Dumbbell Shoulder Press','db shoulder press']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Shoulder To Overhead
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Shoulder To Overhead', 'Dumbbell Shoulder To Overhead', 'CrossFit', 'Dumbbell Shoulder To Overhead', 'Dumbbell Shoulder To Overhead: patrón de entrenamiento con dumbbell, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Shoulder To Overhead', ARRAY['Hombro a overhead con mancuernas','Dumbbell Shoulder To Overhead','db shoulder to overhead']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Split Clean
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Split Clean', 'Dumbbell Split Clean', 'CrossFit', 'Dumbbell Split Clean', 'Olímpico/híbrido con dumbbell: recepción estable y marca clara en cada rep.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Split Clean', ARRAY['Cargada en split con mancuerna','Dumbbell Split Clean','db split clean']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'olympic', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Squat Clean
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Squat Clean', 'Dumbbell Squat Clean', 'CrossFit', 'Dumbbell Squat Clean', 'Sentadilla con dumbbell: profundidad controlada y torso estable.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Squat Clean', ARRAY['Cargada completa con mancuerna','Dumbbell Squat Clean','db squat clean']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'olympic', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Squat Clean Thruster
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Squat Clean Thruster', 'Dumbbell Squat Clean Thruster', 'CrossFit', 'Dumbbell Squat Clean Thruster', 'Sentadilla con dumbbell: profundidad controlada y torso estable.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Squat Clean Thruster', ARRAY['Cargada completa a thruster con mancuerna','Dumbbell Squat Clean Thruster','db squat clean thruster']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'olympic', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Strict Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Strict Press', 'Dumbbell Strict Press', 'CrossFit', 'Dumbbell Strict Press', 'Empuje con dumbbell hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Strict Press', ARRAY['Press estricto con mancuernas','Dumbbell Strict Press','db strict press']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Dumbbell Waiters Walk
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Dumbbell Waiters Walk', 'Dumbbell Waiters Walk', 'CrossFit', 'Dumbbell Waiters Walk', 'Porte o caminata con dumbbell: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Dumbbell Waiters Walk', ARRAY['Porte de camarero con mancuerna','Dumbbell Waiters Walk','db waiters walk']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'carry', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Floor Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Floor Press', 'Floor Press', 'CrossFit', 'Floor Press', 'Empuje con barbell hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Floor Press', ARRAY['Press de suelo con barra','Floor Press']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Flutter Kick
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Flutter Kick', 'Flutter Kick', 'CrossFit', 'Flutter Kick', 'Flutter Kick: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Flutter Kick', ARRAY['Patada de flutter','Flutter Kick']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Glute Bridge
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Glute Bridge', 'Glute Bridge', 'CrossFit', 'Glute Bridge', 'Isométrico o control de tronco (Glute Bridge): línea estable sin compensar.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Glute Bridge', ARRAY['Puente de glúteos','Glute Bridge']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Glute Ham Raise
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Glute Ham Raise', 'Glute Ham Raise', 'CrossFit', 'Glute Ham Raise', 'Glute Ham Raise: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Glute Ham Raise', ARRAY['ghr','Glute-ham raise','Glute Ham Raise']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Hand Release Push Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Hand Release Push Up', 'Hand Release Push Up', 'CrossFit', 'Hand Release Push Up', 'Flexión de brazos (Hand Release Push Up): pecho cerca del suelo y codos en extensión arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Hand Release Push Up', ARRAY['Flexiones con despegue de manos','Hand Release Push Up']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Hang High Pull
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Hang High Pull', 'Hang High Pull', 'CrossFit', 'Hang High Pull', 'Hang High Pull: patrón de entrenamiento con barbell, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Hombros', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Hang High Pull', ARRAY['Tirón alto desde hang','Hang High Pull']::text[], ARRAY['quadriceps','deltoids']::text[], ARRAY['trapezius','gluteal','abs']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','shoulder','spine']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'olympic', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Hanging Hip Touch
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Hanging Hip Touch', 'Hanging Hip Touch', 'CrossFit', 'Hanging Hip Touch', 'Hanging Hip Touch: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Hanging Hip Touch', ARRAY['Toque de cadera colgado','Hanging Hip Touch']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Hanging Knee Raise
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Hanging Knee Raise', 'Hanging Knee Raise', 'CrossFit', 'Hanging Knee Raise', 'Hanging Knee Raise: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Hanging Knee Raise', ARRAY['Elevación de rodillas colgado','Hanging Knee Raise']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Husafell Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Husafell Carry', 'Husafell Carry', 'CrossFit', 'Husafell Carry', 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Odd object', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Husafell Carry', ARRAY['Porte Husafell','Husafell Carry']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Odd object']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY['odd_object']::text[], 'editorial_phase_d_v1',
  'carry', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Jefferson Curl
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Jefferson Curl', 'Jefferson Curl', 'CrossFit', 'Jefferson Curl', 'Jefferson Curl: patrón de entrenamiento con barbell, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Jefferson Curl', ARRAY['Curl Jefferson','Jefferson Curl']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Jerry Bag Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Jerry Bag Carry', 'Jerry Bag Carry', 'CrossFit', 'Jerry Bag Carry', 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Odd object', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Jerry Bag Carry', ARRAY['Porte con jerry bag','Jerry Bag Carry']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Odd object']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY['odd_object']::text[], 'editorial_phase_d_v1',
  'carry', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Jumping Jack
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Jumping Jack', 'Jumping Jack', 'CrossFit', 'Jumping Jack', 'Salto pliométrico (Jumping Jack): aterrizaje suave y cadera extendida.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Jumping Jack', ARRAY['Jumping jacks','Jumping Jack']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['calves']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'monostructural', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Keg Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Keg Carry', 'Keg Carry', 'CrossFit', 'Keg Carry', 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Odd object', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Keg Carry', ARRAY['Porte con barril','Keg Carry']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Odd object']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY['odd_object']::text[], 'editorial_phase_d_v1',
  'carry', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Kettlebell Deadlift
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Kettlebell Deadlift', 'Kettlebell Deadlift', 'CrossFit', 'Kettlebell Deadlift', 'Peso muerto con kettlebell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Kettlebell', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Kettlebell Deadlift', ARRAY['Peso muerto con kettlebell','Kettlebell Deadlift','kb deadlift']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Kettlebell']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['kettlebell']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Kettlebell Front Rack Lunge
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Kettlebell Front Rack Lunge', 'Kettlebell Front Rack Lunge', 'CrossFit', 'Kettlebell Front Rack Lunge', 'Zancada o step-up con kettlebell: rodilla alineada y control del tronco.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Kettlebell', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Kettlebell Front Rack Lunge', ARRAY['Zancada en rack con kettlebell','Kettlebell Front Rack Lunge','kb front rack lunge']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Kettlebell']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['kettlebell']::text[], 'editorial_phase_d_v1',
  'lunge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Kettlebell Halo
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Kettlebell Halo', 'Kettlebell Halo', 'CrossFit', 'Kettlebell Halo', 'Trabajo de tronco/hombros con kettlebell: control anti-rotación o movilidad cargada.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Kettlebell', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Kettlebell Halo', ARRAY['Halo con kettlebell','Kettlebell Halo','kb halo']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Kettlebell']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY['kettlebell']::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Kettlebell Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Kettlebell Press', 'Kettlebell Press', 'CrossFit', 'Kettlebell Press', 'Empuje con kettlebell hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Kettlebell', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Kettlebell Press', ARRAY['Press con kettlebell','Kettlebell Press','kb press']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Kettlebell']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['kettlebell']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Kettlebell Sumo Deadlift High Pull
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Kettlebell Sumo Deadlift High Pull', 'Kettlebell Sumo Deadlift High Pull', 'CrossFit', 'Kettlebell Sumo Deadlift High Pull', 'Peso muerto con kettlebell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Kettlebell', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Kettlebell Sumo Deadlift High Pull', ARRAY['Sumo deadlift high pull con kettlebell','Kettlebell Sumo Deadlift High Pull','kb sumo deadlift high pull']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Kettlebell']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['kettlebell']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Kettlebell Windmill
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Kettlebell Windmill', 'Kettlebell Windmill', 'CrossFit', 'Kettlebell Windmill', 'Trabajo de tronco/hombros con kettlebell: control anti-rotación o movilidad cargada.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Kettlebell', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Kettlebell Windmill', ARRAY['Molino con kettlebell','Kettlebell Windmill','kb windmill']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Kettlebell']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY['kettlebell']::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Kipping Handstand Push Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Kipping Handstand Push Up', 'Kipping Handstand Push Up', 'CrossFit', 'Kipping Handstand Push Up', 'Variante de pino/HSPU (Kipping Handstand Push Up): control de línea y bloqueo de codos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Kipping Handstand Push Up', ARRAY['HSPU con kipping','Kipping Handstand Push Up']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- L Pull Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:L Pull Up', 'L Pull Up', 'CrossFit', 'L Pull Up', 'Variante de dominada (L Pull Up): tirón controlado hasta el estándar de rango.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'back', 'Espalda', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:L Pull Up', ARRAY['Dominada en L','L Pull Up']::text[], ARRAY['upper-back']::text[], ARRAY['biceps','forearm']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'pull', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Landmine Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Landmine Press', 'Landmine Press', 'CrossFit', 'Landmine Press', 'Empuje con barbell hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Landmine', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Landmine Press', ARRAY['Press landmine','Landmine Press']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Landmine']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Lateral Burpee
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Lateral Burpee', 'Lateral Burpee', 'CrossFit', 'Lateral Burpee', 'Burpee con el obstáculo o implemento indicado; pecho al suelo y extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Lateral Burpee', ARRAY['Burpee lateral','Lateral Burpee']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Lateral Lunge
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Lateral Lunge', 'Lateral Lunge', 'CrossFit', 'Lateral Lunge', 'Zancada o step-up con peso corporal: rodilla alineada y control del tronco.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Lateral Lunge', ARRAY['Zancada lateral','Lateral Lunge']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'lunge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Log Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Log Carry', 'Log Carry', 'CrossFit', 'Log Carry', 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Tronco', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Log Carry', ARRAY['Porte con tronco','Log Carry']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Tronco']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY['log']::text[], 'editorial_phase_d_v1',
  'carry', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Log Clean And Jerk
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Log Clean And Jerk', 'Log Clean And Jerk', 'CrossFit', 'Log Clean And Jerk', 'Empuje con peso corporal hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Tronco', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Log Clean And Jerk', ARRAY['Cargada y envión con tronco','Log Clean And Jerk']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Tronco']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['log']::text[], 'editorial_phase_d_v1',
  'olympic', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Log Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Log Press', 'Log Press', 'CrossFit', 'Log Press', 'Empuje con peso corporal hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Tronco', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Log Press', ARRAY['Press con tronco','Log Press']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Tronco']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['log']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Medicine Ball Box Step Over
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Medicine Ball Box Step Over', 'Medicine Ball Box Step Over', 'CrossFit', 'Medicine Ball Box Step Over', 'Medicine Ball Box Step Over: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Balón medicinal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Medicine Ball Box Step Over', ARRAY['Paso sobre cajón con balón medicinal','Medicine Ball Box Step Over']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Balón medicinal']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['medicine_ball']::text[], 'editorial_phase_d_v1',
  'lunge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Medicine Ball Sit Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Medicine Ball Sit Up', 'Medicine Ball Sit Up', 'CrossFit', 'Medicine Ball Sit Up', 'Medicine Ball Sit Up: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Balón medicinal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Medicine Ball Sit Up', ARRAY['Sit-up con balón medicinal','Medicine Ball Sit Up']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Balón medicinal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY['medicine_ball']::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Medicine Ball Throw
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Medicine Ball Throw', 'Medicine Ball Throw', 'CrossFit', 'Medicine Ball Throw', 'Remo con peso corporal: codos atrás y omóplatos activos al final del tirón.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'back', 'Espalda', 'CrossFit',
  'Balón medicinal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Medicine Ball Throw', ARRAY['Lanzamiento de balón medicinal','Medicine Ball Throw']::text[], ARRAY['upper-back']::text[], ARRAY['biceps','forearm']::text[], ARRAY['Balón medicinal']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow','spine']::text[], ARRAY['medicine_ball']::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Mountain Climber
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Mountain Climber', 'Mountain Climber', 'CrossFit', 'Mountain Climber', 'Odd-object o acondicionamiento (Mountain Climber) con peso corporal; potencia y control.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Mountain Climber', ARRAY['Escaladores','Mountain Climber']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Negative Pull Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Negative Pull Up', 'Negative Pull Up', 'CrossFit', 'Negative Pull Up', 'Variante de dominada (Negative Pull Up): tirón controlado hasta el estándar de rango.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'back', 'Espalda', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Negative Pull Up', ARRAY['Dominada negativa','Negative Pull Up']::text[], ARRAY['upper-back']::text[], ARRAY['biceps','forearm']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'pull', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Nordic Curl
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Nordic Curl', 'Nordic Curl', 'CrossFit', 'Nordic Curl', 'Nordic Curl: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Nordic Curl', ARRAY['Curl nórdico','Nordic Curl']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Overhead Walk
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Overhead Walk', 'Overhead Walk', 'CrossFit', 'Overhead Walk', 'Porte o caminata con barbell: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Overhead Walk', ARRAY['Caminata overhead','Overhead Walk']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'carry', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Pallof Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Pallof Press', 'Pallof Press', 'CrossFit', 'Pallof Press', 'Empuje con peso corporal hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Pallof Press', ARRAY['Press Pallof','Pallof Press']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Parallel Bar Traverse
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Parallel Bar Traverse', 'Parallel Bar Traverse', 'CrossFit', 'Parallel Bar Traverse', 'Parallel Bar Traverse: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'back', 'Espalda', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Parallel Bar Traverse', ARRAY['Travesía en barras paralelas','Parallel Bar Traverse']::text[], ARRAY['upper-back']::text[], ARRAY['biceps','forearm']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'pull', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Parallette Handstand Push Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Parallette Handstand Push Up', 'Parallette Handstand Push Up', 'CrossFit', 'Parallette Handstand Push Up', 'Variante de pino/HSPU (Parallette Handstand Push Up): control de línea y bloqueo de codos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Parallettes', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Parallette Handstand Push Up', ARRAY['HSPU en parallettes','Parallette Handstand Push Up']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Parallettes']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['parallettes']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Pendlay Row
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Pendlay Row', 'Pendlay Row', 'CrossFit', 'Pendlay Row', 'Remo con barbell: codos atrás y omóplatos activos al final del tirón.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Pendlay Row', ARRAY['Remo Pendlay','Pendlay Row']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'pull', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Plate Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Plate Carry', 'Plate Carry', 'CrossFit', 'Plate Carry', 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Plate Carry', ARRAY['Porte con disco','Plate Carry']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'carry', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Push Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Push Up', 'Push Up', 'CrossFit', 'Push Up', 'Flexión de brazos (Push Up): pecho cerca del suelo y codos en extensión arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Push Up', ARRAY['Flexiones','Push Up']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Renegade Row
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Renegade Row', 'Renegade Row', 'CrossFit', 'Renegade Row', 'Remo con dumbbell: codos atrás y omóplatos activos al final del tirón.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'back', 'Espalda', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Renegade Row', ARRAY['Remo renegade','Renegade Row']::text[], ARRAY['upper-back']::text[], ARRAY['biceps','forearm']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow','spine']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'pull', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Reverse Hyper
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Reverse Hyper', 'Reverse Hyper', 'CrossFit', 'Reverse Hyper', 'Reverse Hyper: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Reverse Hyper', ARRAY['Reverse hyper']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Ring Hamstring Curl
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Ring Hamstring Curl', 'Ring Hamstring Curl', 'CrossFit', 'Ring Hamstring Curl', 'Ring Hamstring Curl: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Anillas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Ring Hamstring Curl', ARRAY['Curl femoral en anillas','Ring Hamstring Curl']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Anillas']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['gym_rings']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Ring Handstand Push Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Ring Handstand Push Up', 'Ring Handstand Push Up', 'CrossFit', 'Ring Handstand Push Up', 'Variante de pino/HSPU (Ring Handstand Push Up): control de línea y bloqueo de codos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Anillas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Ring Handstand Push Up', ARRAY['HSPU en anillas','Ring Handstand Push Up']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Anillas']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['gym_rings']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Ring Lower
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Ring Lower', 'Ring Lower', 'CrossFit', 'Ring Lower', 'Ring Lower: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'back', 'Espalda', 'CrossFit',
  'Anillas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Ring Lower', ARRAY['Descenso en anillas','Ring Lower']::text[], ARRAY['upper-back']::text[], ARRAY['biceps','forearm']::text[], ARRAY['Anillas']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['gym_rings']::text[], 'editorial_phase_d_v1',
  'pull', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Ring Push Up
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Ring Push Up', 'Ring Push Up', 'CrossFit', 'Ring Push Up', 'Flexión de brazos (Ring Push Up): pecho cerca del suelo y codos en extensión arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Anillas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Ring Push Up', ARRAY['Flexiones en anillas','Ring Push Up']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Anillas']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['gym_rings']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Russian Twist
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Russian Twist', 'Russian Twist', 'CrossFit', 'Russian Twist', 'Trabajo de tronco/hombros con peso corporal: control anti-rotación o movilidad cargada.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Russian Twist', ARRAY['Giro ruso','Russian Twist']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Sandbag Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Sandbag Carry', 'Sandbag Carry', 'CrossFit', 'Sandbag Carry', 'Porte o caminata con peso corporal: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Saco', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Sandbag Carry', ARRAY['Porte con saco','Sandbag Carry']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Saco']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY['sandbag']::text[], 'editorial_phase_d_v1',
  'carry', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Sandbag Ground To Shoulder
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Sandbag Ground To Shoulder', 'Sandbag Ground To Shoulder', 'CrossFit', 'Sandbag Ground To Shoulder', 'Sandbag Ground To Shoulder: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Saco', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Sandbag Ground To Shoulder', ARRAY['Saco del suelo al hombro','Sandbag Ground To Shoulder']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Saco']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['sandbag']::text[], 'editorial_phase_d_v1',
  'olympic', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Sandbag Load To Box
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Sandbag Load To Box', 'Sandbag Load To Box', 'CrossFit', 'Sandbag Load To Box', 'Sandbag Load To Box: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Saco', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Sandbag Load To Box', ARRAY['Carga de saco al cajón','Sandbag Load To Box']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Saco']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['sandbag']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Sandbag Over Log
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Sandbag Over Log', 'Sandbag Over Log', 'CrossFit', 'Sandbag Over Log', 'Sandbag Over Log: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Tronco', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Sandbag Over Log', ARRAY['Saco por encima del tronco','Sandbag Over Log']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Tronco']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['log']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Sandbag Squat
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Sandbag Squat', 'Sandbag Squat', 'CrossFit', 'Sandbag Squat', 'Sentadilla con peso corporal: profundidad controlada y torso estable.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Saco', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Sandbag Squat', ARRAY['Sentadilla con saco','Sandbag Squat']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Saco']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['sandbag']::text[], 'editorial_phase_d_v1',
  'squat', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Side Plank
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Side Plank', 'Side Plank', 'CrossFit', 'Side Plank', 'Isométrico o control de tronco (Side Plank): línea estable sin compensar.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Side Plank', ARRAY['Plancha lateral','Side Plank']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Single Arm Dumbbell Thruster
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Single Arm Dumbbell Thruster', 'Single Arm Dumbbell Thruster', 'CrossFit', 'Single Arm Dumbbell Thruster', 'Olímpico/híbrido con dumbbell: recepción estable y marca clara en cada rep.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Single Arm Dumbbell Thruster', ARRAY['Thruster a un brazo con mancuerna','Single Arm Dumbbell Thruster','single arm db thruster']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'squat', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Single Arm Kettlebell Swing
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Single Arm Kettlebell Swing', 'Single Arm Kettlebell Swing', 'CrossFit', 'Single Arm Kettlebell Swing', 'Balanceo de cadera con kettlebell; potencia desde la cadena posterior.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Kettlebell', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Single Arm Kettlebell Swing', ARRAY['Swing a un brazo con kettlebell','Single Arm Kettlebell Swing','single arm kb swing']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Kettlebell']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['kettlebell']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Single Arm Kettlebell Thruster
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Single Arm Kettlebell Thruster', 'Single Arm Kettlebell Thruster', 'CrossFit', 'Single Arm Kettlebell Thruster', 'Olímpico/híbrido con kettlebell: recepción estable y marca clara en cada rep.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Kettlebell', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Single Arm Kettlebell Thruster', ARRAY['Thruster a un brazo con kettlebell','Single Arm Kettlebell Thruster','single arm kb thruster']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Kettlebell']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['kettlebell']::text[], 'editorial_phase_d_v1',
  'squat', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Single Leg Glute Bridge
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Single Leg Glute Bridge', 'Single Leg Glute Bridge', 'CrossFit', 'Single Leg Glute Bridge', 'Isométrico o control de tronco (Single Leg Glute Bridge): línea estable sin compensar.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Single Leg Glute Bridge', ARRAY['Puente de glúteos a una pierna','Single Leg Glute Bridge']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Single Leg Romanian Deadlift
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Single Leg Romanian Deadlift', 'Single Leg Romanian Deadlift', 'CrossFit', 'Single Leg Romanian Deadlift', 'Peso muerto con barbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Single Leg Romanian Deadlift', ARRAY['single leg rdl','single leg deadlift','Peso muerto rumano a una pierna','Single Leg Romanian Deadlift']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Skater Jump
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Skater Jump', 'Skater Jump', 'CrossFit', 'Skater Jump', 'Salto pliométrico (Skater Jump): aterrizaje suave y cadera extendida.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Skater Jump', ARRAY['Salto de patinador','Skater Jump']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['calves']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'conditioning', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Sled Drag
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Sled Drag', 'Sled Drag', 'CrossFit', 'Sled Drag', 'Sled Drag: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Trineo', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Sled Drag', ARRAY['Arrastre de trineo','Sled Drag']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Trineo']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY['sled']::text[], 'editorial_phase_d_v1',
  'pull', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Sledgehammer Strike
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Sledgehammer Strike', 'Sledgehammer Strike', 'CrossFit', 'Sledgehammer Strike', 'Odd-object o acondicionamiento (Sledgehammer Strike) con peso corporal; potencia y control.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Trineo', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Sledgehammer Strike', ARRAY['sledgehammer','Golpes con maza','Sledgehammer Strike']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Trineo']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY['sled']::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Stiff Legged Deadlift
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Stiff Legged Deadlift', 'Stiff Legged Deadlift', 'CrossFit', 'Stiff Legged Deadlift', 'Peso muerto con barbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Stiff Legged Deadlift', ARRAY['stiff leg deadlift','Peso muerto de piernas rígidas','Stiff Legged Deadlift']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Strict Knee Raise
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Strict Knee Raise', 'Strict Knee Raise', 'CrossFit', 'Strict Knee Raise', 'Strict Knee Raise: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Strict Knee Raise', ARRAY['Elevación de rodillas estricta','Strict Knee Raise']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Strict Knees To Chest
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Strict Knees To Chest', 'Strict Knees To Chest', 'CrossFit', 'Strict Knees To Chest', 'Strict Knees To Chest: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'waist', 'Core', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Strict Knees To Chest', ARRAY['strict knee to chest','Rodillas al pecho estrictas','Strict Knees To Chest']::text[], ARRAY['abs']::text[], ARRAY['obliques']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','hip']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'core', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Suitcase Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Suitcase Carry', 'Suitcase Carry', 'CrossFit', 'Suitcase Carry', 'Porte o caminata con dumbbell: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Mancuernas', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Suitcase Carry', ARRAY['Porte de maleta','Suitcase Carry']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Mancuernas']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY['dumbbell']::text[], 'editorial_phase_d_v1',
  'carry', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Superman
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Superman', 'Superman', 'CrossFit', 'Superman', 'Isométrico o control de tronco (Superman): línea estable sin compensar.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Superman', ARRAY['Superman']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Tire Flip
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Tire Flip', 'Tire Flip', 'CrossFit', 'Tire Flip', 'Odd-object o acondicionamiento (Tire Flip) con peso corporal; potencia y control.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Neumático', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Tire Flip', ARRAY['Vuelco de neumático','Tire Flip']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Neumático']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['tire']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Trap Bar Deadlift
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Trap Bar Deadlift', 'Trap Bar Deadlift', 'CrossFit', 'Trap Bar Deadlift', 'Peso muerto con barbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Barra hex', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Trap Bar Deadlift', ARRAY['Peso muerto con barra hex','Trap Bar Deadlift']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Barra hex']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['trap_bar']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Tuck Jump
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Tuck Jump', 'Tuck Jump', 'CrossFit', 'Tuck Jump', 'Salto pliométrico (Tuck Jump): aterrizaje suave y cadera extendida.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Tuck Jump', ARRAY['Salto con rodillas al pecho','Tuck Jump']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['calves']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'conditioning', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Wall Climb
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Wall Climb', 'Wall Climb', 'CrossFit', 'Wall Climb', 'Odd-object o acondicionamiento (Wall Climb) con peso corporal; potencia y control.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Wall Climb', ARRAY['wall walk','Escalada de muro','Wall Climb']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Wall Climb Over
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Wall Climb Over', 'Wall Climb Over', 'CrossFit', 'Wall Climb Over', 'Odd-object o acondicionamiento (Wall Climb Over) con peso corporal; potencia y control.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Wall Climb Over', ARRAY['Paso por encima del muro','Wall Climb Over']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Wall Sit
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Wall Sit', 'Wall Sit', 'CrossFit', 'Wall Sit', 'Wall Sit: patrón de entrenamiento con peso corporal, orientado a fuerza o acondicionamiento.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Peso corporal', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Wall Sit', ARRAY['Sentadilla isométrica en pared','Wall Sit']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Peso corporal']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY[]::text[], 'editorial_phase_d_v1',
  'squat', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Z Press
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Z Press', 'Z Press', 'CrossFit', 'Z Press', 'Empuje con barbell hasta bloqueo overhead o extensión completa.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'shoulders', 'Hombros', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Z Press', ARRAY['Z press']::text[], ARRAY['deltoids','chest']::text[], ARRAY['triceps','abs']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['shoulder','elbow']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'push', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Zercher Carry
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Zercher Carry', 'Zercher Carry', 'CrossFit', 'Zercher Carry', 'Porte o caminata con barbell: postura alta, núcleo firme y pasos cortos.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'full body', 'Core', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Zercher Carry', ARRAY['Porte Zercher','Zercher Carry']::text[], ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['spine','shoulder','hip','knee','ankle']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'carry', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Zercher Deadlift
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Zercher Deadlift', 'Zercher Deadlift', 'CrossFit', 'Zercher Deadlift', 'Peso muerto con barbell: bisagra de cadera, espalda neutra y bloqueo arriba.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Isquios', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Zercher Deadlift', ARRAY['Peso muerto Zercher','Zercher Deadlift']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back','forearm']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','spine','knee']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'hinge', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

-- Zercher Squat
INSERT INTO public.business_exercise_catalog (
  catalog_key, name, category, display_name_en, mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment, is_active
) VALUES (
  'catalog:Zercher Squat', 'Zercher Squat', 'CrossFit', 'Zercher Squat', 'Sentadilla con barbell: profundidad controlada y torso estable.',
  ARRAY['Colócate estable y prepara el material antes de la primera repetición.','Completa el rango con control; evita impulso que invalide el estándar.','Marca el bloqueo o la posición final antes de seguir.']::text[], 'upper legs', 'Piernas', 'CrossFit',
  'Barra', true
) ON CONFLICT (catalog_key) DO UPDATE SET
  name=EXCLUDED.name, display_name_en=EXCLUDED.display_name_en,
  mobile_description=EXCLUDED.mobile_description, mobile_instructions=EXCLUDED.mobile_instructions,
  mobile_body_part=EXCLUDED.mobile_body_part, mobile_muscle_group=EXCLUDED.mobile_muscle_group,
  mobile_sport_tag=EXCLUDED.mobile_sport_tag, mobile_equipment=EXCLUDED.mobile_equipment, is_active=true;

INSERT INTO public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  metadata_source, joint_demands, required_equipment, joint_demands_source,
  movement_pattern, updated_at
) VALUES (
  'catalog:Zercher Squat', ARRAY['Sentadilla Zercher','Zercher Squat']::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Barra']::text[],
  'open_sources:phase_d_20261104', ARRAY['hip','knee','ankle']::text[], ARRAY['barbell']::text[], 'editorial_phase_d_v1',
  'squat', now()
) ON CONFLICT (catalog_key) DO UPDATE SET
  aliases=EXCLUDED.aliases, primary_muscles=EXCLUDED.primary_muscles,
  secondary_muscles=EXCLUDED.secondary_muscles, equipment=EXCLUDED.equipment,
  joint_demands=EXCLUDED.joint_demands, required_equipment=EXCLUDED.required_equipment,
  metadata_source=EXCLUDED.metadata_source, joint_demands_source=EXCLUDED.joint_demands_source,
  movement_pattern=EXCLUDED.movement_pattern, updated_at=now();

