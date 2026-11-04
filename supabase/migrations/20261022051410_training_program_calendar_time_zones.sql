-- Program and calendar dates are civil dates belonging to a declared IANA zone,
-- NOT implicitly UTC timestamps. Historical rows remain null/unknown.
ALTER TABLE public.athlete_training_programs
 ADD COLUMN start_time_zone text;
ALTER TABLE public.athlete_training_calendar_snapshots
 ADD COLUMN time_zone text;
ALTER TABLE public.ai_training_plans
 DROP CONSTRAINT ai_plan_time_zone_format;
ALTER TABLE public.ai_training_plans
 ADD CONSTRAINT ai_plan_time_zone_length CHECK (
   scheduled_time_zone IS NULL OR
   (char_length(scheduled_time_zone) BETWEEN 3 AND 80 AND
    scheduled_time_zone !~ '[[:cntrl:]]')
 );
ALTER TABLE public.athlete_training_programs
 ADD CONSTRAINT ai_program_time_zone_length CHECK (
  start_time_zone IS NULL OR (char_length(start_time_zone) BETWEEN 3 AND 80
  AND start_time_zone !~ '[[:cntrl:]]')
 );
ALTER TABLE public.athlete_training_calendar_snapshots
 ADD CONSTRAINT ai_calendar_time_zone_length CHECK (
  time_zone IS NULL OR (char_length(time_zone) BETWEEN 3 AND 80
  AND time_zone !~ '[[:cntrl:]]')
 );
