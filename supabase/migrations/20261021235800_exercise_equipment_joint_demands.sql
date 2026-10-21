-- Sporting metadata only: joint demands are non-clinical movement descriptors,
-- NOT diagnosis, pain safety or injury compatibility. Empty means unknown.
ALTER TABLE public.training_exercise_metadata
 ADD COLUMN joint_demands text[] NOT NULL DEFAULT '{}'::text[],
 ADD COLUMN required_equipment text[] NOT NULL DEFAULT '{}'::text[];
ALTER TABLE public.training_exercise_metadata
 ADD CONSTRAINT training_exercise_joint_vocabulary
 CHECK (joint_demands <@ ARRAY['shoulder','elbow','wrist','hip','knee','ankle','spine']::text[]
        AND cardinality(joint_demands)<=7);
ALTER TABLE public.training_exercise_metadata
 ADD CONSTRAINT training_exercise_equipment_bounded
 CHECK (cardinality(required_equipment)<=12);

UPDATE public.training_exercise_metadata m
 SET required_equipment = CASE
  WHEN equipment @> ARRAY['Barra']::text[] THEN ARRAY['barbell']::text[]
  WHEN equipment @> ARRAY['Mancuernas']::text[] THEN ARRAY['dumbbells']::text[]
  WHEN equipment @> ARRAY['Kettlebell']::text[] THEN ARRAY['kettlebell']::text[]
  WHEN equipment @> ARRAY['Polea']::text[] THEN ARRAY['cable_machine']::text[]
  WHEN equipment @> ARRAY['Comba']::text[] THEN ARRAY['jump_rope']::text[]
  WHEN equipment @> ARRAY['Balón medicinal']::text[] THEN ARRAY['medicine_ball']::text[]
  WHEN equipment @> ARRAY['Disco']::text[] THEN ARRAY['weight_plate']::text[]
  WHEN equipment @> ARRAY['Saco']::text[] THEN ARRAY['sandbag']::text[]
  WHEN equipment @> ARRAY['Trineo']::text[] THEN ARRAY['sled']::text[]
  WHEN equipment @> ARRAY['Yoke']::text[] THEN ARRAY['yoke']::text[]
  WHEN equipment @> ARRAY['Máquina']::text[] THEN ARRAY['gym_machine_unspecified']::text[]
  WHEN equipment @> ARRAY['Peso corporal']::text[] THEN ARRAY['bodyweight']::text[]
  ELSE ARRAY[]::text[] END;
-- Gear that the old native seed did not specify or stated only bodyweight.
UPDATE public.training_exercise_metadata SET required_equipment=ARRAY['air_bike']
 WHERE catalog_key='catalog:Air bike';
UPDATE public.training_exercise_metadata SET required_equipment=ARRAY['echo_bike']
 WHERE catalog_key='catalog:Echo bike';
UPDATE public.training_exercise_metadata SET required_equipment=ARRAY['stationary_bike']
 WHERE catalog_key='catalog:Bici estática';
UPDATE public.training_exercise_metadata SET required_equipment=ARRAY['resistance_band']
 WHERE catalog_key='catalog:Paso lateral con banda';
UPDATE public.training_exercise_metadata SET required_equipment=ARRAY['gymnastic_rings']
 WHERE catalog_key IN ('catalog:Dominadas en anillas','catalog:Fondos en anillas',
  'catalog:Muscle-up anillas','catalog:Muscle-up estricto anillas',
  'catalog:Remo en anillas','catalog:Soporte en anillas');
UPDATE public.training_exercise_metadata SET required_equipment=ARRAY['plyometric_box']
 WHERE catalog_key IN ('catalog:Box jump over','catalog:Burpee al cajón',
    'catalog:Salto al cajón','catalog:Step-up al cajón');
-- Limited, explicit movement joint taxonomy. Do not guess for all 189.
UPDATE public.training_exercise_metadata SET joint_demands=ARRAY['hip','knee','ankle']
 WHERE catalog_key IN ('catalog:Sentadilla','catalog:Sentadilla frontal',
 'catalog:Overhead squat','catalog:Air squat','catalog:Goblet squat',
 'catalog:Pistol squat','catalog:Sentadilla búlgara',
 'catalog:Zancadas inversas con barra');
UPDATE public.training_exercise_metadata SET joint_demands=ARRAY['hip','knee','spine']
 WHERE catalog_key IN ('catalog:Peso muerto','catalog:Peso muerto rumano','catalog:Sumo deadlift');
UPDATE public.training_exercise_metadata SET joint_demands=ARRAY['shoulder','elbow','wrist']
 WHERE catalog_key IN ('catalog:Press banca','catalog:Press banca inclinada',
 'catalog:Press mancuernas','catalog:Press militar','catalog:Press Arnold',
 'catalog:Dominadas','catalog:Dominadas estrictas','catalog:Dominadas kipping',
 'catalog:Dominadas butterfly','catalog:Fondos','catalog:Fondos en anillas');
-- Technical metadata is advisory; no automatic injury-safe classifications.
