-- Repera native iOS CrossFit/weightlifting display names are English.
-- Keep historical catalog_key and catalog.name unchanged: production constraint
-- enforces catalog_key = 'catalog:' || name and many training records reference keys.
-- Add bilingual aliases for MCP/web lookup without rewriting client references.
CREATE TEMP TABLE repera_sport_alias_source (
  legacy_name text PRIMARY KEY,
  english_name text NOT NULL,
  spanish_alias text NOT NULL
) ON COMMIT DROP;
INSERT INTO repera_sport_alias_source (legacy_name,english_name,spanish_alias) VALUES
  ('Arrancada','Snatch','Arrancada'),
  ('Arrancada colgante','Hang Snatch','Arrancada colgante'),
  ('Arrancada colgante completa','Hang Squat Snatch','Arrancada colgante completa'),
  ('Arrancada con pausa','Pause Snatch','Arrancada con pausa'),
  ('Arrancada de potencia','Power Snatch','Arrancada de potencia'),
  ('Arrancada desde bloques','Block Snatch','Arrancada desde bloques'),
  ('Arrancada en split','Split Snatch','Arrancada en split'),
  ('Arrancada muscular','Muscle Snatch','Arrancada muscular'),
  ('Balance de arrancada','Snatch Balance','Balance de arrancada'),
  ('Balance de envión','Jerk Balance','Balance de envión'),
  ('Burpee al cajón','Burpee Box Jump','Burpee al cajón'),
  ('Cargada','Clean','Cargada'),
  ('Cargada colgante','Hang Clean','Cargada colgante'),
  ('Cargada colgante completa','Hang Squat Clean','Cargada colgante completa'),
  ('Cargada con pausa','Pause Clean','Cargada con pausa'),
  ('Cargada de potencia','Power Clean','Cargada de potencia'),
  ('Cargada desde bloques','Block Clean','Cargada desde bloques'),
  ('Cargada muscular','Muscle Clean','Cargada muscular'),
  ('Cargada y envión','Clean and Jerk','Cargada y envión'),
  ('Cargada y envión con mancuerna','Dumbbell Clean and Jerk','Cargada y envión con mancuerna'),
  ('Cargada y press','Clean and Press','Cargada y press'),
  ('Carrera','Run','Carrera'),
  ('Clean kettlebell','Kettlebell Clean','Clean kettlebell'),
  ('Clean mancuerna','Dumbbell Clean','Clean mancuerna'),
  ('Dobles de comba','Double-Under','Dobles de comba'),
  ('Envión detrás de nuca','Behind-the-Neck Jerk','Envión detrás de nuca'),
  ('Peso muerto agarre arrancada','Snatch-Grip Deadlift','Peso muerto agarre arrancada'),
  ('Press detrás de nuca','Behind-the-Neck Press','Press detrás de nuca'),
  ('Salto al cajón','Box Jump','Salto al cajón'),
  ('Sentadilla frontal con pausa','Pause Front Squat','Sentadilla frontal con pausa'),
  ('Simples de comba','Single-Under','Simples de comba'),
  ('Snatch kettlebell','Kettlebell Snatch','Snatch kettlebell'),
  ('Snatch mancuerna','Dumbbell Snatch','Snatch mancuerna'),
  ('Step-up al cajón','Box Step-Up','Step-up al cajón'),
  ('Step-up al cajón con kettlebell goblet','Kettlebell Goblet Box Step-Up','Step-up al cajón con kettlebell goblet'),
  ('Swing americano','American Kettlebell Swing','Swing americano'),
  ('Swing kettlebell','Kettlebell Swing','Swing kettlebell'),
  ('Thruster kettlebell','Kettlebell Thruster','Thruster kettlebell'),
  ('Thruster mancuernas','Dumbbell Thruster','Thruster mancuernas'),
  ('Tirón de arrancada','Snatch Pull','Tirón de arrancada'),
  ('Tirón de cargada','Clean Pull','Tirón de cargada'),
  ('Triples de comba','Triple-Under','Triples de comba'),
  ('Zancadas inversas con barra','Back rack reverse lunge','Zancadas inversas con barra'),
  ('Air bike','Air bike','Bicicleta de aire'),
  ('Ball slam','Ball slam','Golpeo de balón al suelo'),
  ('Bar facing burpee','Bar facing burpee','Burpee frente a la barra'),
  ('Bear crawl','Bear crawl','Gateo del oso'),
  ('Box jump over','Box jump over','Salto sobre cajón'),
  ('Broad jump','Broad jump','Salto de longitud'),
  ('Burpee','Burpee','Burpi'),
  ('Burpee box jump over','Burpee box jump over','Burpee con salto sobre cajón'),
  ('Burpee pull-up','Burpee pull-up','Burpee con dominada'),
  ('Cluster','Cluster','Cargada y thruster'),
  ('Devil press','Devil press','Press del diablo'),
  ('Drop snatch','Drop snatch','Arrancada bajo la barra'),
  ('Echo bike','Echo bike','Bicicleta Echo'),
  ('Farmer carry','Farmer carry','Paseo del granjero'),
  ('Front rack lunge','Front rack lunge','Zancada con barra en rack frontal'),
  ('Goblet squat','Goblet squat','Sentadilla goblet'),
  ('Ground to overhead','Ground to overhead','Del suelo a encima de la cabeza'),
  ('Hang power clean','Hang power clean','Cargada de potencia desde colgado'),
  ('Hang power snatch','Hang power snatch','Arrancada de potencia desde colgado'),
  ('Man maker','Man maker','Hombre máquina'),
  ('Medball clean','Medball clean','Cargada con balón medicinal'),
  ('Overhead squat','Overhead squat','Sentadilla por encima de la cabeza'),
  ('Plate ground to overhead','Plate ground to overhead','Disco del suelo a encima de la cabeza'),
  ('Power jerk','Power jerk','Envión de potencia'),
  ('Push jerk','Push jerk','Envión de fuerza'),
  ('Push press','Push press','Press con impulso'),
  ('Sandbag clean','Sandbag clean','Cargada con saco'),
  ('Sandbag over shoulder','Sandbag over shoulder','Saco sobre el hombro'),
  ('Shuttle run','Shuttle run','Carrera de ida y vuelta'),
  ('SkiErg','SkiErg','Esquí ergómetro'),
  ('Sled pull','Sled pull','Arrastre de trineo'),
  ('Sled push','Sled push','Empuje de trineo'),
  ('Sots press','Sots press','Press Sots'),
  ('Split jerk','Split jerk','Envión en tijera'),
  ('Strict press','Strict press','Press estricto'),
  ('Sumo high pull','Sumo high pull','Tirón alto sumo'),
  ('Tall clean','Tall clean','Cargada desde extensión'),
  ('Tall snatch','Tall snatch','Arrancada desde extensión'),
  ('Thruster','Thruster','Sentadilla frontal con press'),
  ('Turkish get-up','Turkish get-up','Levantamiento turco'),
  ('Walking lunge','Walking lunge','Zancadas caminando'),
  ('Wall ball','Wall ball','Lanzamiento de balón a pared'),
  ('Yoke carry','Yoke carry','Paseo con yugo');

DO $repera_alias_guard$
BEGIN
  IF (SELECT count(*) FROM repera_sport_alias_source) <> 86 THEN
    RAISE EXCEPTION 'Expected 86 iOS sport movements';
  END IF;
  IF EXISTS (
    SELECT 1 FROM repera_sport_alias_source s
    LEFT JOIN public.business_exercise_catalog c
      ON c.catalog_key='catalog:' || s.legacy_name
    WHERE c.catalog_key IS NULL
      AND s.legacy_name NOT IN ('Burpee box jump over','Cargada y envión con mancuerna')
  ) THEN
    RAISE EXCEPTION 'Unexpected missing catalog keys: refusing partial migration';
  END IF;
  IF EXISTS (
    SELECT 1 FROM repera_sport_alias_source s
    JOIN public.business_exercise_catalog c
      ON c.catalog_key='catalog:' || s.legacy_name
    WHERE c.category NOT IN ('CrossFit','Halterofilia')
  ) THEN
    RAISE EXCEPTION 'Unexpected sport classification; refusing migration';
  END IF;
END
$repera_alias_guard$;

-- Two native iOS movements absent from the production catalog.
-- Legacy names intentionally match the immutable catalog_key convention.
INSERT INTO public.business_exercise_catalog (catalog_key,name,category) VALUES
 ('catalog:Burpee box jump over','Burpee box jump over','CrossFit'),
 ('catalog:Cargada y envión con mancuerna','Cargada y envión con mancuerna','CrossFit')
ON CONFLICT (catalog_key) DO NOTHING;

-- Source verified against CatalogCrossFit.swift; do not invent anatomy.
INSERT INTO public.training_exercise_metadata
  (catalog_key,aliases,primary_muscles,secondary_muscles,equipment,required_equipment,metadata_source)
VALUES
 ('catalog:Burpee box jump over',ARRAY['Burpee box jump over','Burpee con salto sobre cajón']::text[],
  ARRAY['quadriceps','chest']::text[],ARRAY['gluteal','abs']::text[],
  ARRAY['Peso corporal']::text[],ARRAY[]::text[],'native_ios_catalog'),
 ('catalog:Cargada y envión con mancuerna',ARRAY['Dumbbell Clean and Jerk','Cargada y envión con mancuerna']::text[],
  ARRAY['deltoids','quadriceps']::text[],ARRAY['gluteal','triceps']::text[],
  ARRAY['Mancuernas']::text[],ARRAY['Mancuernas']::text[],'native_ios_catalog')
ON CONFLICT (catalog_key) DO NOTHING;

-- Preserve existing aliases and add both the canonical English name and Spanish alias.
UPDATE public.training_exercise_metadata AS m
SET aliases = ARRAY(
  SELECT DISTINCT u.alias
  FROM unnest(
    coalesce(m.aliases,'{}'::text[]) || ARRAY[s.english_name,s.spanish_alias]::text[]
  ) AS u(alias)
  WHERE length(btrim(u.alias)) > 0
  ORDER BY u.alias
), updated_at=now()
FROM repera_sport_alias_source AS s
WHERE m.catalog_key='catalog:' || s.legacy_name
  AND NOT (coalesce(m.aliases,'{}'::text[]) @> ARRAY[s.english_name,s.spanish_alias]::text[]);

DO $repera_alias_check$
BEGIN
  IF (
    SELECT count(*)
    FROM repera_sport_alias_source s
    JOIN public.business_exercise_catalog c
      ON c.catalog_key='catalog:' || s.legacy_name
    JOIN public.training_exercise_metadata m
      ON m.catalog_key=c.catalog_key
    WHERE c.category IN ('CrossFit','Halterofilia')
      AND m.aliases @> ARRAY[s.english_name,s.spanish_alias]::text[]
  ) <> 86 THEN
    RAISE EXCEPTION 'Bilingual catalogs not fully installed; rollback migration';
  END IF;
END
$repera_alias_check$;
