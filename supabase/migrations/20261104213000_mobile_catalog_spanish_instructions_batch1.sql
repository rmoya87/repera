-- Textos "cómo hacerlo" (ES, paso a paso) de los 3 ejercicios que aún tenían
-- pasos crudos en el seed nativo. El trigger de business_exercise_catalog
-- publica el evento en mobile_exercise_catalog_events y la app lo aplica en
-- caliente (iOS y Android) sin nueva versión. Solo toca mobile_instructions.
-- Verificación posterior sugerida:
--   select catalog_key, array_length(mobile_instructions,1)
--   from public.business_exercise_catalog
--   where catalog_key in (
--     'catalog:Step-up al cajón con kettlebell goblet',
--     'catalog:Cargada y envión con mancuerna',
--     'catalog:Carrera');

update public.business_exercise_catalog
set mobile_instructions = array[
  'Colócate de pie frente al cajón con la kettlebell sujeta en goblet: ambas manos bajo las asas o el cuerpo de la pesa pegado al pecho, codos hacia abajo.',
  'Apoya un pie completo sobre el cajón, con la rodilla alineada sobre el tobillo y el tronco ligeramente inclinado hacia delante.',
  'Extiende la pierna de apoyo para subir hasta quedar erguido encima; evita impulsarte con la pierna que queda en el suelo.',
  'Baja con control por la misma pierna, sin dejar caer la cadera ni perder la kettlebell pegada al pecho.',
  'Alterna la pierna de apoyo en cada repetición o completa la serie de un lado según la prescripción.',
  'Error típico: empujar con el pie del suelo y convertirlo en un salto. Progresión: domina el step-up con peso corporal antes de añadir la kettlebell.'
]::text[]
where catalog_key = 'catalog:Step-up al cajón con kettlebell goblet';

update public.business_exercise_catalog
set mobile_instructions = array[
  'De pie, con la mancuerna colgando a un lado del cuerpo (hang), pies al ancho de cadera y tronco firme.',
  'Haz una bisagra de cadera breve y extiende piernas y cadera con fuerza para elevar la mancuerna cerca del cuerpo.',
  'Recibe la mancuerna sobre el hombro con el codo alto y las rodillas ligeramente flexionadas (cargada).',
  'Desde el hombro, hunde un poco cadera y rodillas y empuja con piernas y brazo hasta bloquear la mancuerna sobre la cabeza (envión).',
  'Estabiliza con el brazo extendido y el tronco vertical antes de bajar la mancuerna al hombro y luego al hang.',
  'Alterna el brazo en cada repetición si el WOD indica ALT; no gires el tronco para ayudar al bloqueo.',
  'Error típico: empujar solo con el brazo sin usar la extensión de cadera. Progresión: domina la cargada con mancuerna antes de añadir el envión.'
]::text[]
where catalog_key = 'catalog:Cargada y envión con mancuerna';

update public.business_exercise_catalog
set mobile_instructions = array[
  'Comienza con una zancada cómoda: aterriza bajo la cadera, con el tronco erguido y la mirada al frente.',
  'Mantén una cadencia constante y brazos activos a unos 90°, sin cruzarlos delante del pecho.',
  'Gestiona el ritmo según la distancia o el tiempo prescrito: reserva aire para los tramos finales.',
  'En tramos de metcon, entra y sale de la carrera con transiciones rápidas y controla la respiración al reincorporarte.',
  'Registra metros o tiempo según la prescripción; no anotes repeticiones ficticias.'
]::text[]
where catalog_key = 'catalog:Carrera';
