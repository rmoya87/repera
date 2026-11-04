-- Assign sportTag to former gym-untagged enrichment rows (2026-11-04).
-- Halterofilia/Gimnasia also surface in CrossFit via disciplineTags; Cardio via muscleGroup.

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Gimnasia'
WHERE name = 'Ab wheel' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Abducción de cadera en máquina' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Aducción de cadera en máquina' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Aperturas' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Bici estática' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Halterofilia'
WHERE name = 'Buenos días' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Cinta / carrera' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Cruce de poleas' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Crunch' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Crunch en polea' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Curl barra' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Curl femoral' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Curl femoral sentado' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Curl femoral tumbado' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Curl inclinado con mancuernas' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Curl mancuernas' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Curl martillo' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Curl predicador' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Gimnasia'
WHERE name = 'Dominadas' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Elevaciones frontales' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Elevaciones laterales' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Elevaciones laterales en polea' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Elevación de gemelos' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Gimnasia'
WHERE name = 'Elevación de piernas' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Extensión de cuádriceps' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Extensión tríceps polea' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Face pull' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Farmer walk' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Gimnasia'
WHERE name = 'Fondos' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Fondos en banco' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Hack squat' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Hip thrust' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Jalón al pecho' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Paso lateral con banda' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Pec deck' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Halterofilia'
WHERE name = 'Peso muerto' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Halterofilia'
WHERE name = 'Peso muerto rumano' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Halterofilia'
WHERE name = 'Peso muerto sumo' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Gimnasia'
WHERE name = 'Plancha' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Prensa' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Press Arnold' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Press banca' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Press banca declinado' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Press banca inclinada' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Press cerrado' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Press francés' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Press mancuernas' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Halterofilia'
WHERE name = 'Press militar' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Pullover' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Pájaros' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Remo al mentón' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Remo con apoyo de pecho' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Remo con barra' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Remo en T' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Gimnasia'
WHERE name = 'Remo invertido' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Remo mancuerna' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Remo máquina' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Remo sentado' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Halterofilia'
WHERE name = 'Sentadilla' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Halterofilia'
WHERE name = 'Sentadilla a cajón con mancuernas' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Sentadilla búlgara' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Sentadilla búlgara con mancuernas' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Halterofilia'
WHERE name = 'Sentadilla en Smith' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'Halterofilia'
WHERE name = 'Sentadilla frontal' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Woodchop en polea' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

UPDATE public.business_exercise_catalog
SET mobile_sport_tag = 'CrossFit'
WHERE name = 'Zancadas' AND is_active
  AND COALESCE(NULLIF(btrim(mobile_sport_tag), ''), '') = '';

