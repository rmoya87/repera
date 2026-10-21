-- Broad, NON-CLINICAL joint demands for the 189 sport movements.
-- Derived conservatively from established muscle-region mappings and name-based
-- movement patterns. This describes joints likely involved, not contraindications,
-- pain, injury risks, pathology or individualized exercise safety.
-- Document source so the assistant never mistakes it for a medical assessment.
ALTER TABLE public.training_exercise_metadata
  ADD COLUMN IF NOT EXISTS joint_demands_source text NOT NULL DEFAULT 'unknown';

UPDATE public.training_exercise_metadata AS m
SET joint_demands = ARRAY(
 SELECT DISTINCT joint FROM (
  SELECT unnest(m.joint_demands) AS joint
  UNION ALL SELECT CASE
    WHEN muscle IN ('chest','deltoids','upper-back','lats','serratus','trapezius') THEN 'shoulder'
    WHEN muscle IN ('biceps','triceps') THEN 'elbow'
    WHEN muscle IN ('forearm') THEN 'wrist'
    WHEN muscle IN ('gluteal','hamstring','adductors','hip-flexors') THEN 'hip'
    WHEN muscle IN ('quadriceps') THEN 'knee'
    WHEN muscle IN ('calves','tibialis') THEN 'ankle'
    WHEN muscle IN ('abs','obliques','lower-back') THEN 'spine'
    ELSE NULL END AS joint
    FROM unnest(m.primary_muscles || m.secondary_muscles) AS muscle
 ) derived WHERE joint IS NOT NULL ORDER BY joint
),
joint_demands_source = CASE
 WHEN cardinality(m.joint_demands)>0 THEN 'movement_specific_plus_muscle_heuristic_v1'
 ELSE 'muscle_region_heuristic_v1' END,
updated_at=now()
WHERE cardinality(m.primary_muscles||m.secondary_muscles)>0;

-- Explicit named monostructural/cardio or overhead movement demands:
-- do not assume an empty primary muscle means "no joints".
UPDATE public.training_exercise_metadata m
SET joint_demands=ARRAY(SELECT DISTINCT x FROM unnest(joint_demands || ARRAY['hip','knee','ankle']::text[]) x ORDER BY x),
joint_demands_source='movement_specific_plus_muscle_heuristic_v1'
FROM public.business_exercise_catalog c
WHERE c.catalog_key=m.catalog_key
 AND (c.name ILIKE '%run%' OR c.name ILIKE '%carrera%' OR c.name ILIKE '%shuttle%'
 OR c.name ILIKE '%squat%' OR c.name ILIKE '%sentadilla%'
 OR c.name ILIKE '%step up%' OR c.name ILIKE '%step-up%');

UPDATE public.training_exercise_metadata m
SET joint_demands=ARRAY(SELECT DISTINCT x FROM unnest(joint_demands || ARRAY['shoulder','elbow','wrist']::text[]) x ORDER BY x),
joint_demands_source='movement_specific_plus_muscle_heuristic_v1'
FROM public.business_exercise_catalog c
WHERE c.catalog_key=m.catalog_key
 AND (c.name ILIKE '%jerk%' OR c.name ILIKE '%press%' OR c.name ILIKE '%hspu%'
 OR c.name ILIKE '%handstand%' OR c.name ILIKE '%snatch%' OR c.name ILIKE '%arrancada%');

DO $$ BEGIN
  IF (SELECT count(*) FROM public.training_exercise_metadata WHERE cardinality(joint_demands)=0) > 0 THEN
   RAISE EXCEPTION 'Unclassified joint metadata present';
  END IF;
END $$;
