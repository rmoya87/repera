-- Read-only acceptance smoke after complete_ai_catalog_muscle_mappings.
-- Cross-check native source parity with tests/test_ai_catalog_metadata.py.
DO $$
DECLARE
 total integer;
 mapped integer;
 conditioning integer;
 missing integer;
 invalid integer;
BEGIN
 SELECT count(*),
        count(*) FILTER (WHERE cardinality(primary_muscles) > 0),
        count(*) FILTER (WHERE cardinality(primary_muscles) = 0
                         AND movement_pattern='conditioning'
                         AND cardinality(secondary_muscles)>0),
        count(*) FILTER (WHERE metadata_source='unmapped')
   INTO total,mapped,conditioning,missing
 FROM public.training_exercise_metadata;
 IF total <> 189 OR mapped <> 183 OR conditioning <> 6 OR missing <> 0
 THEN
   RAISE EXCEPTION 'Unexpected catalog coverage: total %, mapped %, conditioning %, missing %',
     total,mapped,conditioning,missing;
 END IF;
 SELECT count(*) INTO invalid
 FROM (
   SELECT unnest(primary_muscles||secondary_muscles) slug
   FROM public.training_exercise_metadata
 ) s WHERE NOT slug = ANY(ARRAY[
   'trapezius','deltoids','chest','upper-back','serratus','biceps','triceps',
   'forearm','abs','obliques','lower-back','gluteal','quadriceps',
   'hamstring','adductors','hip-flexors','calves','tibialis'
 ]::text[]);
 IF invalid > 0 THEN
   RAISE EXCEPTION 'Invalid muscle slugs: %', invalid;
 END IF;
 IF (SELECT count(*) FROM public.athlete_workout_mirror WHERE deleted_at IS NULL) < 3
 THEN RAISE EXCEPTION 'Existing workouts unexpectedly missing'; END IF;
END $$;
