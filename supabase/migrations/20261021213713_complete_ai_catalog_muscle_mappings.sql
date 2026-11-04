-- Repera's own native movement sources are authoritative for catalog metadata.
-- Exactly 140 native seed entries from CatalogHalterofilia (40),
-- CatalogGimnasia (56) and CatalogCrossFit (44).
-- 137 match previously unannotated professional-catalog rows; three names
-- are deliberately absent from business catalog (no synthetic catalog entries).
-- Six cardio/conditioning movements intentionally have NO primary muscle
-- in the iOS source; they carry only declared secondary regions.
-- NO Swift/iOS data model changes. No invented anatomical regions.
ALTER TABLE public.training_exercise_metadata
  ADD COLUMN metadata_source text NOT NULL DEFAULT 'unmapped';

-- Existing 52 anatomically assigned rows originate from CatalogEnrichment.
UPDATE public.training_exercise_metadata
SET metadata_source = 'native:CatalogEnrichment'
WHERE metadata_source = 'unmapped' AND cardinality(primary_muscles) > 0;

-- Include source files in the migration for versioned, reproducible mapping.
WITH native_source(catalog_key,primary_muscles,secondary_muscles,equipment,source_tag,movement_kind) AS (
  VALUES
    ('catalog:Arrancada', ARRAY['quadriceps','gluteal']::text[], ARRAY['deltoids','trapezius','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Zancadas inversas con barra', ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Arrancada de potencia', ARRAY['quadriceps']::text[], ARRAY['deltoids','trapezius']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Arrancada colgante', ARRAY['hamstring','gluteal']::text[], ARRAY['deltoids']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Arrancada colgante completa', ARRAY['quadriceps']::text[], ARRAY['deltoids','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Hang power snatch', ARRAY['quadriceps','deltoids']::text[], ARRAY['trapezius']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Arrancada muscular', ARRAY['deltoids','trapezius']::text[], ARRAY['triceps']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Arrancada desde bloques', ARRAY['quadriceps']::text[], ARRAY['deltoids','trapezius']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Arrancada con pausa', ARRAY['quadriceps','abs']::text[], ARRAY['deltoids']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Balance de arrancada', ARRAY['quadriceps','deltoids']::text[], ARRAY['abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Drop snatch', ARRAY['quadriceps']::text[], ARRAY['deltoids']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Tall snatch', ARRAY['deltoids']::text[], ARRAY['trapezius','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Arrancada en split', ARRAY['quadriceps','deltoids']::text[], ARRAY['gluteal']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Tirón de arrancada', ARRAY['trapezius','gluteal']::text[], ARRAY['hamstring','forearm']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Peso muerto agarre arrancada', ARRAY['hamstring','gluteal']::text[], ARRAY['upper-back']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Cargada', ARRAY['quadriceps','gluteal']::text[], ARRAY['trapezius','deltoids','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Cargada de potencia', ARRAY['quadriceps','gluteal']::text[], ARRAY['trapezius','deltoids']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Cargada colgante', ARRAY['hamstring','gluteal']::text[], ARRAY['trapezius','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Cargada colgante completa', ARRAY['quadriceps']::text[], ARRAY['gluteal','trapezius']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Hang power clean', ARRAY['quadriceps','gluteal']::text[], ARRAY['trapezius']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Cargada muscular', ARRAY['trapezius']::text[], ARRAY['deltoids','biceps']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Cargada desde bloques', ARRAY['quadriceps']::text[], ARRAY['trapezius']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Cargada con pausa', ARRAY['quadriceps','abs']::text[], ARRAY['trapezius']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Tall clean', ARRAY['trapezius']::text[], ARRAY['deltoids','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Tirón de cargada', ARRAY['trapezius','gluteal']::text[], ARRAY['hamstring']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Cargada y press', ARRAY['quadriceps','deltoids']::text[], ARRAY['triceps','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Cargada y envión', ARRAY['quadriceps','gluteal']::text[], ARRAY['deltoids','triceps','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Push press', ARRAY['deltoids']::text[], ARRAY['triceps','quadriceps']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Push jerk', ARRAY['deltoids']::text[], ARRAY['triceps','quadriceps']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Split jerk', ARRAY['deltoids']::text[], ARRAY['triceps','quadriceps']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Power jerk', ARRAY['deltoids']::text[], ARRAY['triceps']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Balance de envión', ARRAY['deltoids']::text[], ARRAY['triceps','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Strict press', ARRAY['deltoids']::text[], ARRAY['triceps','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Press detrás de nuca', ARRAY['deltoids']::text[], ARRAY['triceps','trapezius']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Envión detrás de nuca', ARRAY['deltoids']::text[], ARRAY['triceps','quadriceps']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Sots press', ARRAY['deltoids','abs']::text[], ARRAY['triceps']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Overhead squat', ARRAY['quadriceps','gluteal']::text[], ARRAY['deltoids','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Front rack lunge', ARRAY['quadriceps']::text[], ARRAY['gluteal','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Sentadilla frontal con pausa', ARRAY['quadriceps','abs']::text[], ARRAY['gluteal']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Sumo high pull', ARRAY['trapezius','gluteal']::text[], ARRAY['deltoids','quadriceps']::text[], ARRAY['Barra']::text[], 'native:CatalogHalterofilia', 'mapped'),
    ('catalog:Dominadas estrictas', ARRAY['upper-back']::text[], ARRAY['biceps','abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Dominadas kipping', ARRAY['upper-back']::text[], ARRAY['abs','deltoids']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Dominadas butterfly', ARRAY['upper-back']::text[], ARRAY['abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Dominadas supinas', ARRAY['biceps','upper-back']::text[], ARRAY[]::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Chest to bar', ARRAY['upper-back']::text[], ARRAY['biceps','abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Dominadas en anillas', ARRAY['upper-back']::text[], ARRAY['biceps','abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Remo en anillas', ARRAY['upper-back']::text[], ARRAY['biceps']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Archer pull-up', ARRAY['upper-back']::text[], ARRAY['biceps','deltoids']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Muscle-up barra', ARRAY['upper-back']::text[], ARRAY['triceps','chest','abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Muscle-up anillas', ARRAY['upper-back']::text[], ARRAY['triceps','chest','deltoids']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Muscle-up estricto barra', ARRAY['upper-back','triceps']::text[], ARRAY['chest','abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Muscle-up estricto anillas', ARRAY['upper-back','triceps']::text[], ARRAY['chest']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Pull-over barra', ARRAY['upper-back','abs']::text[], ARRAY['chest']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Toes to bar', ARRAY['abs']::text[], ARRAY['hip-flexors','forearm']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Toes to bar estrictos', ARRAY['abs']::text[], ARRAY['hip-flexors']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Knees to elbows', ARRAY['abs']::text[], ARRAY['hip-flexors']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Toes to rings', ARRAY['abs']::text[], ARRAY['hip-flexors']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Hip to bar', ARRAY['abs','upper-back']::text[], ARRAY['hip-flexors']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Kip swing', ARRAY['abs']::text[], ARRAY['deltoids','upper-back']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:HSPU', ARRAY['deltoids']::text[], ARRAY['triceps','trapezius']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:HSPU deficit', ARRAY['deltoids']::text[], ARRAY['triceps']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:HSPU libre', ARRAY['deltoids','abs']::text[], ARRAY['triceps']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Pike push-up', ARRAY['deltoids']::text[], ARRAY['triceps']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Handstand hold', ARRAY['deltoids']::text[], ARRAY['abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Handstand walk', ARRAY['deltoids']::text[], ARRAY['abs','trapezius']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Wall walk', ARRAY['deltoids','chest']::text[], ARRAY['abs','triceps']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Press to handstand', ARRAY['deltoids','abs']::text[], ARRAY['triceps']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Fondos en anillas kipping', ARRAY['triceps','chest']::text[], ARRAY['deltoids','abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Fondos en anillas', ARRAY['triceps','chest']::text[], ARRAY['deltoids','abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Fondos en paralelas', ARRAY['triceps','chest']::text[], ARRAY['deltoids']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Soporte en anillas', ARRAY['deltoids','triceps']::text[], ARRAY['abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:False grip hang', ARRAY['forearm']::text[], ARRAY['upper-back']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Skin the cat', ARRAY['deltoids','upper-back']::text[], ARRAY['abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:German hang', ARRAY['deltoids']::text[], ARRAY['chest']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Front lever tuck', ARRAY['upper-back','abs']::text[], ARRAY['deltoids']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Back lever tuck', ARRAY['deltoids','upper-back']::text[], ARRAY['abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Planche tuck', ARRAY['deltoids','abs']::text[], ARRAY['triceps']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:L-sit', ARRAY['abs']::text[], ARRAY['triceps','deltoids']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:V-sit', ARRAY['abs']::text[], ARRAY['hip-flexors']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Hollow hold', ARRAY['abs']::text[], ARRAY['hip-flexors']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Hollow rock', ARRAY['abs']::text[], ARRAY['hip-flexors']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Arch hold', ARRAY['lower-back','gluteal']::text[], ARRAY['deltoids']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Candlestick', ARRAY['abs']::text[], ARRAY['deltoids']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Pistol squat', ARRAY['quadriceps']::text[], ARRAY['gluteal','abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Shrimp squat', ARRAY['quadriceps']::text[], ARRAY['gluteal']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Cossack squat', ARRAY['quadriceps','adductors']::text[], ARRAY['gluteal']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Air squat', ARRAY['quadriceps','gluteal']::text[], ARRAY['abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Jumping squat', ARRAY['quadriceps','gluteal']::text[], ARRAY['calves']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Jumping lunge', ARRAY['quadriceps']::text[], ARRAY['gluteal','calves']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:GHD sit-up', ARRAY['abs']::text[], ARRAY['hip-flexors','quadriceps']::text[], ARRAY['Máquina']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:GHD back extension', ARRAY['lower-back','gluteal']::text[], ARRAY['hamstring']::text[], ARRAY['Máquina']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Sit-up', ARRAY['abs']::text[], ARRAY['hip-flexors']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:V-up', ARRAY['abs']::text[], ARRAY['hip-flexors']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Rope climb', ARRAY['upper-back','forearm']::text[], ARRAY['biceps','abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Rope climb legless', ARRAY['upper-back','biceps']::text[], ARRAY['forearm','abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Pegboard', ARRAY['upper-back','deltoids']::text[], ARRAY['abs','forearm']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogGimnasia', 'mapped'),
    ('catalog:Thruster', ARRAY['quadriceps','deltoids']::text[], ARRAY['gluteal','triceps','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Thruster mancuernas', ARRAY['quadriceps','deltoids']::text[], ARRAY['triceps']::text[], ARRAY['Mancuernas']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Thruster kettlebell', ARRAY['quadriceps','deltoids']::text[], ARRAY['abs']::text[], ARRAY['Kettlebell']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Cluster', ARRAY['quadriceps','deltoids']::text[], ARRAY['gluteal','triceps']::text[], ARRAY['Barra']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Cargada y envión con mancuerna', ARRAY['deltoids','quadriceps']::text[], ARRAY['gluteal','triceps']::text[], ARRAY['Mancuernas']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Ground to overhead', ARRAY['quadriceps','deltoids']::text[], ARRAY['trapezius','abs']::text[], ARRAY['Barra']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Plate ground to overhead', ARRAY['deltoids']::text[], ARRAY['abs','quadriceps']::text[], ARRAY['Disco']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Burpee', ARRAY['chest','quadriceps']::text[], ARRAY['deltoids','abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Burpee box jump over', ARRAY['quadriceps','chest']::text[], ARRAY['gluteal','abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Burpee al cajón', ARRAY['quadriceps','gluteal']::text[], ARRAY['chest','abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Bar facing burpee', ARRAY['chest','quadriceps']::text[], ARRAY['abs']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Burpee pull-up', ARRAY['upper-back','chest']::text[], ARRAY['abs','quadriceps']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Salto al cajón', ARRAY['quadriceps','gluteal']::text[], ARRAY['calves']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Step-up al cajón', ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Box jump over', ARRAY['quadriceps']::text[], ARRAY['gluteal','calves']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Broad jump', ARRAY['gluteal','quadriceps']::text[], ARRAY['calves']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Walking lunge', ARRAY['quadriceps','gluteal']::text[], ARRAY['hamstring']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Bear crawl', ARRAY['abs','deltoids']::text[], ARRAY['quadriceps','chest']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Swing kettlebell', ARRAY['gluteal','hamstring']::text[], ARRAY['abs','deltoids']::text[], ARRAY['Kettlebell']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Swing americano', ARRAY['gluteal']::text[], ARRAY['deltoids','abs']::text[], ARRAY['Kettlebell']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Snatch kettlebell', ARRAY['gluteal','deltoids']::text[], ARRAY['abs','forearm']::text[], ARRAY['Kettlebell']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Clean kettlebell', ARRAY['gluteal']::text[], ARRAY['trapezius','deltoids']::text[], ARRAY['Kettlebell']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Turkish get-up', ARRAY['abs','deltoids']::text[], ARRAY['gluteal','quadriceps']::text[], ARRAY['Kettlebell']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Goblet squat', ARRAY['quadriceps']::text[], ARRAY['gluteal','abs']::text[], ARRAY['Kettlebell']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Devil press', ARRAY['deltoids','gluteal']::text[], ARRAY['chest','abs']::text[], ARRAY['Mancuernas']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Man maker', ARRAY['chest','deltoids']::text[], ARRAY['upper-back','abs']::text[], ARRAY['Mancuernas']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Snatch mancuerna', ARRAY['gluteal','deltoids']::text[], ARRAY['abs']::text[], ARRAY['Mancuernas']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Clean mancuerna', ARRAY['quadriceps']::text[], ARRAY['trapezius','deltoids']::text[], ARRAY['Mancuernas']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Wall ball', ARRAY['quadriceps','deltoids']::text[], ARRAY['gluteal','abs']::text[], ARRAY['Balón medicinal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Ball slam', ARRAY['abs','upper-back']::text[], ARRAY['deltoids']::text[], ARRAY['Balón medicinal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Medball clean', ARRAY['quadriceps']::text[], ARRAY['deltoids','abs']::text[], ARRAY['Balón medicinal']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Sandbag clean', ARRAY['quadriceps','upper-back']::text[], ARRAY['abs']::text[], ARRAY['Saco']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Sandbag over shoulder', ARRAY['quadriceps','abs']::text[], ARRAY['upper-back']::text[], ARRAY['Saco']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Yoke carry', ARRAY['abs','trapezius']::text[], ARRAY['quadriceps']::text[], ARRAY['Yoke']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Dobles de comba', ARRAY[]::text[], ARRAY['calves','forearm']::text[], ARRAY['Comba']::text[], 'native:CatalogCrossFit', 'conditioning'),
    ('catalog:Simples de comba', ARRAY[]::text[], ARRAY['calves']::text[], ARRAY['Comba']::text[], 'native:CatalogCrossFit', 'conditioning'),
    ('catalog:Triples de comba', ARRAY[]::text[], ARRAY['calves','forearm']::text[], ARRAY['Comba']::text[], 'native:CatalogCrossFit', 'conditioning'),
    ('catalog:Air bike', ARRAY[]::text[], ARRAY['quadriceps','gluteal','deltoids']::text[], ARRAY[]::text[], 'native:CatalogCrossFit', 'conditioning'),
    ('catalog:Echo bike', ARRAY[]::text[], ARRAY['quadriceps','gluteal']::text[], ARRAY[]::text[], 'native:CatalogCrossFit', 'conditioning'),
    ('catalog:SkiErg', ARRAY['upper-back']::text[], ARRAY['triceps','abs']::text[], ARRAY['Máquina']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Shuttle run', ARRAY[]::text[], ARRAY['quadriceps','calves']::text[], ARRAY['Peso corporal']::text[], 'native:CatalogCrossFit', 'conditioning'),
    ('catalog:Sled push', ARRAY['quadriceps','gluteal']::text[], ARRAY['calves','abs']::text[], ARRAY['Trineo']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Sled pull', ARRAY['upper-back','hamstring']::text[], ARRAY['biceps','forearm']::text[], ARRAY['Trineo']::text[], 'native:CatalogCrossFit', 'mapped'),
    ('catalog:Farmer carry', ARRAY['abs','forearm']::text[], ARRAY['trapezius','quadriceps']::text[], ARRAY['Mancuernas']::text[], 'native:CatalogCrossFit', 'mapped')
)
UPDATE public.training_exercise_metadata AS m
SET primary_muscles = s.primary_muscles,
    secondary_muscles = s.secondary_muscles,
    equipment = s.equipment,
    movement_pattern = CASE WHEN s.movement_kind = 'conditioning'
                            THEN 'conditioning' ELSE m.movement_pattern END,
    metadata_source = s.source_tag,
    updated_at = now()
FROM native_source AS s
WHERE m.catalog_key = s.catalog_key
  AND m.metadata_source = 'unmapped'
  AND cardinality(m.primary_muscles) = 0;

-- Defense against accidental drop of a movement, noncanonical name or
-- fabricated "muscle" value. Do not require cardio to have a primary.
DO $verify$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.business_exercise_catalog c
    LEFT JOIN public.training_exercise_metadata m ON m.catalog_key=c.catalog_key
    WHERE m.catalog_key IS NULL OR m.metadata_source = 'unmapped'
       OR (cardinality(m.primary_muscles) = 0 AND m.movement_pattern IS DISTINCT FROM 'conditioning')
       OR (cardinality(m.primary_muscles) = 0 AND cardinality(m.secondary_muscles) = 0)
  ) THEN
    RAISE EXCEPTION 'Uncovered movement in the 189-exercise Repera catalog';
  END IF;
  IF EXISTS (
    SELECT 1 FROM (
      SELECT unnest(primary_muscles || secondary_muscles) AS muscle
      FROM public.training_exercise_metadata
    ) s
    WHERE NOT s.muscle = ANY(ARRAY['trapezius','deltoids','chest','upper-back','serratus','biceps','triceps','forearm','abs','obliques','lower-back','gluteal','quadriceps','hamstring','adductors','hip-flexors','calves','tibialis']::text[])
  ) THEN
    RAISE EXCEPTION 'Invalid muscle taxonomy slug';
  END IF;
END
$verify$;
