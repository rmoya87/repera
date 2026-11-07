-- Prepared change only: requires explicit human approval before remote migration.
-- OR across configurations, AND inside one configuration. NULL = legacy AND.
-- [] is NOT no-equipment; bodyweight must be an explicit configuration.
CREATE OR REPLACE FUNCTION public.valid_equipment_options(options jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog
AS $$
  SELECT CASE
    WHEN options IS NULL THEN true
    WHEN jsonb_typeof(options) <> 'array' THEN false
    WHEN jsonb_array_length(options) NOT BETWEEN 1 AND 12 THEN false
    ELSE NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(options) AS groups(value)
      WHERE CASE
        WHEN jsonb_typeof(groups.value) <> 'array' THEN true
        WHEN jsonb_array_length(groups.value) NOT BETWEEN 1 AND 12 THEN true
        ELSE EXISTS (
          SELECT 1 FROM jsonb_array_elements(groups.value) AS tokens(value)
          WHERE jsonb_typeof(tokens.value) <> 'string'
            OR (tokens.value #>> '{}') !~ '^[a-z][a-z0-9_]{1,79}$'
        )
      END
    )
  END
$$;

ALTER TABLE public.training_exercise_metadata
  ADD COLUMN required_equipment_options jsonb DEFAULT NULL,
  ADD CONSTRAINT training_exercise_equipment_options_valid
    CHECK (public.valid_equipment_options(required_equipment_options));
COMMENT ON COLUMN public.training_exercise_metadata.required_equipment_options IS
  'OR of nonempty equipment configurations; each configuration is AND. NULL preserves required_equipment legacy AND. Generic machine is not proof of specific gear.';

-- Only the two confirmed catalogue shapes; do not infer variants from prose.
-- Preserve the legacy array for old consumers; do not convert OR into AND/empty.
UPDATE public.training_exercise_metadata
SET required_equipment_options = '[["barbell"],["dumbbells"]]'::jsonb
WHERE catalog_key = 'catalog:Curl de muñeca'
  AND required_equipment = ARRAY['barbell']::text[]
  AND required_equipment_options IS NULL;
UPDATE public.training_exercise_metadata
SET required_equipment_options = '[["assisted_pullup_machine"],["pullup_bar","resistance_band"]]'::jsonb
WHERE catalog_key = 'catalog:Dominadas asistidas'
  AND required_equipment = ARRAY['gym_machine_unspecified']::text[]
  AND required_equipment_options IS NULL;
