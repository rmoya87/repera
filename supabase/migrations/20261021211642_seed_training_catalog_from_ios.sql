-- Exercise anatomy/equipment source of truth: ReperaDomain CatalogEnrichment.swift.
-- Only update exactly matching catalog keys. No fabricated mappings or aliases.
-- Rows without verified matching names intentionally remain unmapped.
WITH source(catalog_key,primary_muscles,secondary_muscles,equipment) AS (
 VALUES
  ('catalog:Press banca', ARRAY['chest']::text[], ARRAY['triceps','deltoids']::text[], ARRAY['Barra']::text[]),
  ('catalog:Press banca inclinada', ARRAY['chest']::text[], ARRAY['triceps','deltoids']::text[], ARRAY['Barra']::text[]),
  ('catalog:Press mancuernas', ARRAY['chest']::text[], ARRAY['triceps','deltoids']::text[], ARRAY['Mancuernas']::text[]),
  ('catalog:Aperturas', ARRAY['chest']::text[], ARRAY['deltoids','biceps']::text[], ARRAY['Mancuernas']::text[]),
  ('catalog:Fondos', ARRAY['chest','triceps']::text[], ARRAY['deltoids','abs']::text[], ARRAY['Peso corporal']::text[]),
  ('catalog:Dominadas', ARRAY['upper-back']::text[], ARRAY['biceps','forearm','trapezius']::text[], ARRAY['Peso corporal']::text[]),
  ('catalog:Jalón al pecho', ARRAY['upper-back']::text[], ARRAY['biceps','forearm','trapezius']::text[], ARRAY['Polea']::text[]),
  ('catalog:Remo con barra', ARRAY['upper-back']::text[], ARRAY['biceps','deltoids','forearm','lower-back']::text[], ARRAY['Barra']::text[]),
  ('catalog:Remo mancuerna', ARRAY['upper-back']::text[], ARRAY['biceps','deltoids','forearm']::text[], ARRAY['Mancuernas']::text[]),
  ('catalog:Peso muerto', ARRAY['gluteal','hamstring','lower-back']::text[], ARRAY['upper-back','quadriceps','forearm','trapezius']::text[], ARRAY['Barra']::text[]),
  ('catalog:Peso muerto rumano', ARRAY['hamstring','gluteal']::text[], ARRAY['lower-back','forearm']::text[], ARRAY['Barra']::text[]),
  ('catalog:Sentadilla', ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','adductors','abs','calves']::text[], ARRAY['Barra']::text[]),
  ('catalog:Sentadilla frontal', ARRAY['quadriceps']::text[], ARRAY['gluteal','abs','upper-back']::text[], ARRAY['Barra']::text[]),
  ('catalog:Prensa', ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','calves']::text[], ARRAY['Máquina']::text[]),
  ('catalog:Zancadas', ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','calves']::text[], ARRAY['Mancuernas']::text[]),
  ('catalog:Extensión de cuádriceps', ARRAY['quadriceps']::text[], ARRAY['hip-flexors']::text[], ARRAY['Máquina']::text[]),
  ('catalog:Curl femoral', ARRAY['hamstring']::text[], ARRAY['gluteal','calves']::text[], ARRAY['Máquina']::text[]),
  ('catalog:Elevación de gemelos', ARRAY['calves']::text[], ARRAY['tibialis']::text[], ARRAY['Máquina']::text[]),
  ('catalog:Press militar', ARRAY['deltoids']::text[], ARRAY['triceps','chest','abs','trapezius']::text[], ARRAY['Barra']::text[]),
  ('catalog:Elevaciones laterales', ARRAY['deltoids']::text[], ARRAY['trapezius']::text[], ARRAY['Mancuernas']::text[]),
  ('catalog:Pájaros', ARRAY['deltoids']::text[], ARRAY['upper-back','trapezius']::text[], ARRAY['Mancuernas']::text[]),
  ('catalog:Curl barra', ARRAY['biceps']::text[], ARRAY['forearm']::text[], ARRAY['Barra']::text[]),
  ('catalog:Curl mancuernas', ARRAY['biceps']::text[], ARRAY['forearm']::text[], ARRAY['Mancuernas']::text[]),
  ('catalog:Curl martillo', ARRAY['biceps']::text[], ARRAY['forearm']::text[], ARRAY['Mancuernas']::text[]),
  ('catalog:Fondos en banco', ARRAY['triceps']::text[], ARRAY['chest','deltoids']::text[], ARRAY['Peso corporal']::text[]),
  ('catalog:Extensión tríceps polea', ARRAY['triceps']::text[], ARRAY['forearm','deltoids']::text[], ARRAY['Polea']::text[]),
  ('catalog:Press cerrado', ARRAY['triceps','chest']::text[], ARRAY['deltoids']::text[], ARRAY['Barra']::text[]),
  ('catalog:Plancha', ARRAY['abs']::text[], ARRAY['obliques','deltoids','gluteal']::text[], ARRAY['Peso corporal']::text[]),
  ('catalog:Crunch', ARRAY['abs']::text[], ARRAY['hip-flexors']::text[], ARRAY['Peso corporal']::text[]),
  ('catalog:Elevación de piernas', ARRAY['abs']::text[], ARRAY['hip-flexors']::text[], ARRAY['Peso corporal']::text[]),
  ('catalog:Hip thrust', ARRAY['gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Barra']::text[]),
  ('catalog:Face pull', ARRAY['deltoids']::text[], ARRAY['upper-back','trapezius']::text[], ARRAY['Polea']::text[]),
  ('catalog:Remo al mentón', ARRAY['deltoids','trapezius']::text[], ARRAY['biceps','upper-back']::text[], ARRAY['Barra']::text[]),
  ('catalog:Buenos días', ARRAY['hamstring','gluteal']::text[], ARRAY['lower-back','abs']::text[], ARRAY['Barra']::text[]),
  ('catalog:Hack squat', ARRAY['quadriceps']::text[], ARRAY['gluteal','hamstring']::text[], ARRAY['Máquina']::text[]),
  ('catalog:Pullover', ARRAY['upper-back']::text[], ARRAY['chest','triceps','abs']::text[], ARRAY['Mancuernas']::text[]),
  ('catalog:Cinta / carrera', ARRAY['quadriceps','calves']::text[], ARRAY['hamstring','gluteal']::text[], ARRAY[]::text[]),
  ('catalog:Bici estática', ARRAY['quadriceps']::text[], ARRAY['hamstring','gluteal','calves']::text[], ARRAY[]::text[]),
  ('catalog:Remo máquina', ARRAY['upper-back','quadriceps']::text[], ARRAY['hamstring','gluteal','abs','biceps']::text[], ARRAY['Máquina']::text[]),
  ('catalog:Farmer walk', ARRAY['forearm','abs','trapezius']::text[], ARRAY['gluteal','calves','obliques']::text[], ARRAY['Mancuernas']::text[]),
  ('catalog:Press banca declinado', ARRAY['chest']::text[], ARRAY['triceps','deltoids']::text[], ARRAY['Barra']::text[]),
  ('catalog:Cruce de poleas', ARRAY['chest']::text[], ARRAY['deltoids','biceps']::text[], ARRAY['Polea']::text[]),
  ('catalog:Remo sentado', ARRAY['upper-back']::text[], ARRAY['biceps','deltoids','forearm']::text[], ARRAY['Polea']::text[]),
  ('catalog:Peso muerto sumo', ARRAY['gluteal','quadriceps','adductors']::text[], ARRAY['hamstring','upper-back','trapezius']::text[], ARRAY['Barra']::text[]),
  ('catalog:Sentadilla búlgara', ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Mancuernas']::text[]),
  ('catalog:Curl predicador', ARRAY['biceps']::text[], ARRAY['forearm']::text[], ARRAY['Barra']::text[]),
  ('catalog:Press francés', ARRAY['triceps']::text[], ARRAY['forearm','deltoids']::text[], ARRAY['Barra']::text[]),
  ('catalog:Elevaciones frontales', ARRAY['deltoids']::text[], ARRAY['chest','trapezius']::text[], ARRAY['Mancuernas']::text[]),
  ('catalog:Ab wheel', ARRAY['abs']::text[], ARRAY['obliques','upper-back','deltoids','hip-flexors']::text[], ARRAY['Peso corporal']::text[]),
  ('catalog:Paso lateral con banda', ARRAY['gluteal']::text[], ARRAY['abs','obliques']::text[], ARRAY[]::text[]),
  ('catalog:Remo invertido', ARRAY['upper-back']::text[], ARRAY['biceps','abs']::text[], ARRAY['Peso corporal']::text[]),
  ('catalog:Press Arnold', ARRAY['deltoids']::text[], ARRAY['triceps','chest']::text[], ARRAY['Mancuernas']::text[])
)
UPDATE public.training_exercise_metadata m
SET primary_muscles=source.primary_muscles,
    secondary_muscles=source.secondary_muscles,
    equipment=source.equipment,
    updated_at=now()
FROM source WHERE m.catalog_key=source.catalog_key;
-- Verified normalized aliases and variants for common Repera/CrossFit queries:
UPDATE public.training_exercise_metadata SET aliases=ARRAY['BBJO','Burpee Box Jump Over','Burpee box jump']::text[], updated_at=now()
 WHERE catalog_key='catalog:Burpee al cajón';
UPDATE public.training_exercise_metadata SET aliases=ARRAY['Back squat','Barbell back squat']::text[],updated_at=now()
 WHERE catalog_key='catalog:Sentadilla';
UPDATE public.training_exercise_metadata SET aliases=ARRAY['Bench press','Barbell bench press']::text[],updated_at=now()
 WHERE catalog_key='catalog:Press banca';
UPDATE public.training_exercise_metadata SET aliases=ARRAY['Front squat']::text[],updated_at=now()
 WHERE catalog_key='catalog:Sentadilla frontal';
