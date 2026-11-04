-- Four distinct motions found on additional real CrossFit boxes' workout photos.
-- Created BOTH in the native Swift catalog and in the MCP-readable catalog.
-- Existing exercise IDs, training history and imported AI plans are untouched.
INSERT INTO public.business_exercise_catalog(catalog_key,name,category) VALUES
 ('catalog:Carrera','Carrera','CrossFit'),
 ('catalog:Dominadas lastradas','Dominadas lastradas','Gimnasia'),
 ('catalog:Remo pliométrico en anillas pies elevados','Remo pliométrico en anillas pies elevados','Gimnasia'),
 ('catalog:Step-up al cajón con kettlebell goblet','Step-up al cajón con kettlebell goblet','CrossFit')
ON CONFLICT(catalog_key) DO NOTHING;

INSERT INTO public.training_exercise_metadata(
 catalog_key,aliases,primary_muscles,secondary_muscles,equipment,
 required_equipment,joint_demands,joint_demands_source,
 metadata_source,movement_pattern
) VALUES
 ('catalog:Carrera',ARRAY['Run','Running','Correr']::text[],
 ARRAY[]::text[],ARRAY['quadriceps','calves','gluteal']::text[],
 ARRAY['Peso corporal']::text[],ARRAY['bodyweight']::text[],
 ARRAY['hip','knee','ankle']::text[],'movement_specific_plus_muscle_heuristic_v1',
 'photo:metcon_run_20261022','conditioning'),
 ('catalog:Dominadas lastradas',ARRAY['Weighted Pull Up','Weighted Pull-ups']::text[],
 ARRAY['upper-back','biceps']::text[],ARRAY['forearm','abs']::text[],
 ARRAY['Peso corporal']::text[],ARRAY['pullup_bar','weight_belt_or_vest']::text[],
 ARRAY['shoulder','elbow','wrist']::text[],'movement_specific_plus_muscle_heuristic_v1',
 'photo:pulling_strength_20261022','pull'),
 ('catalog:Remo pliométrico en anillas pies elevados',ARRAY['Plyo Ring Row','Plyo Ring Row Feet Elevated']::text[],
 ARRAY['upper-back']::text[],ARRAY['biceps','deltoids','abs']::text[],
 ARRAY['Peso corporal']::text[],ARRAY['gymnastic_rings','foot_elevation_platform']::text[],
 ARRAY['shoulder','elbow','wrist','spine']::text[],'movement_specific_plus_muscle_heuristic_v1',
 'photo:pulling_strength_20261022','pull'),
 ('catalog:Step-up al cajón con kettlebell goblet',ARRAY['KB Goblet Alt Box Step Up','Goblet Box Step-up']::text[],
 ARRAY['quadriceps','gluteal']::text[],ARRAY['hamstring','abs']::text[],
 ARRAY['Kettlebell']::text[],ARRAY['kettlebell','plyometric_box']::text[],
 ARRAY['hip','knee','ankle','spine']::text[],'movement_specific_plus_muscle_heuristic_v1',
 'photo:metcon_20261022','step_up')
ON CONFLICT(catalog_key) DO UPDATE SET
 aliases=EXCLUDED.aliases,primary_muscles=EXCLUDED.primary_muscles,
 secondary_muscles=EXCLUDED.secondary_muscles,
 required_equipment=EXCLUDED.required_equipment,
 joint_demands=EXCLUDED.joint_demands,joint_demands_source=EXCLUDED.joint_demands_source,
 metadata_source=EXCLUDED.metadata_source,movement_pattern=EXCLUDED.movement_pattern,
 updated_at=now();
