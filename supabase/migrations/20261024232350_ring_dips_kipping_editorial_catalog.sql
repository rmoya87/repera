-- Complete the 288 movement catalogue without changing any historical exercise IDs.
-- This gymnastic variation was present in the Android/iOS seed but absent in Supabase.
insert into public.business_exercise_catalog (
    catalog_key, name, category, mobile_description, mobile_instructions,
    mobile_body_part, mobile_muscle_group, mobile_sport_tag, mobile_equipment
) values (
    'catalog:Fondos en anillas kipping',
    'Fondos en anillas kipping',
    'Gimnasia',
    'Fondo en anillas con ayuda de impulso controlado de cadera. Es una variante avanzada que exige estabilidad de hombro, recepción segura y dominio previo de fondos estrictos.',
    array['Antes de comenzar, comprueba que las anillas estén estables y domina el soporte con codos extendidos y hombros activos.','Baja a una profundidad que puedas controlar manteniendo las anillas próximas al cuerpo, sin colapsar el hombro hacia delante.','Coordina un impulso pequeño y controlado de cadera con la extensión de brazos para regresar arriba sin balanceo desordenado.','Estabiliza el bloqueo superior antes de la siguiente repetición; evita que las anillas se separen y que los hombros rueden hacia delante.','Error típico: intentar compensar una falta de fuerza con un kip grande; reduce amplitud o vuelve a fondos estrictos asistidos.','Progresión: soporte en anillas, fondos estrictos, control de balanceo y por último kipping. Interrumpe el ejercicio ante molestias de hombro.']::text[],
    'upper arms',
    'Tríceps',
    'Gimnasia',
    'Anillas'
)
on conflict (catalog_key) do nothing;

insert into public.training_exercise_metadata (
    catalog_key, primary_muscles, secondary_muscles, equipment,
    metadata_source, required_equipment
) values (
    'catalog:Fondos en anillas kipping',
    array['triceps','chest']::text[],
    array['deltoids','abs']::text[],
    array['Anillas']::text[],
    'native:CatalogGimnasia',
    array['gymnastic_rings']::text[]
)
on conflict (catalog_key) do nothing;
