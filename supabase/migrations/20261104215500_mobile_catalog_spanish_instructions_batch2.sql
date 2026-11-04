-- Tandas 2 y 3 de carruseles: los pasos 1-3 (captions del carrusel 1:1 con los
-- frames) de 11 ejercicios de halterofilia se reescribieron en el seed nativo
-- para describir la fase visible de cada frame. Esta migración replica esos
-- textos en el catálogo remoto; el trigger de business_exercise_catalog
-- publica el evento y la app lo aplica en caliente. Solo toca
-- mobile_instructions. Idempotente.
-- Verificación posterior sugerida:
--   select catalog_key, array_length(mobile_instructions,1)
--   from public.business_exercise_catalog
--   where catalog_key in (
    'catalog:Arrancada colgante completa',
    'catalog:Arrancada con pausa',
    'catalog:Arrancada de potencia',
    'catalog:Arrancada desde bloques',
    'catalog:Arrancada en split',
    'catalog:Cargada colgante completa',
    'catalog:Cargada con pausa',
    'catalog:Cargada de potencia',
    'catalog:Cargada muscular',
    'catalog:Cargada y press',
    'catalog:Hang power clean');


update public.business_exercise_catalog
set mobile_instructions = array[
  'Desde hang sobre las rodillas: bisagra de cadera, espalda tensa, hombros sobre la barra y brazos largos con agarre ancho.',
  'Extiende cadera y rodillas con fuerza; barra pegada a los muslos, encogimiento y codos altos para pasar bajo la barra.',
  'Recibe overhead en sentadilla profunda (no en power): pecho alto, hombros activos empujando la barra al techo.',
  'Levántate con control hasta de pie con barra bloqueada.',
  'Error típico: cortar profundidad o perder el equilibrio adelante. Usa OHS ligeros como preparación.',
  'Si no llegas al fondo, trabaja movilidad de tobillo/hombro y drop snatch.'
]::text[]
where catalog_key = 'catalog:Arrancada colgante completa';

update public.business_exercise_catalog
set mobile_instructions = array[
  'Desde el suelo o hang, sube la barra y haz una pausa deliberada de 1–2 s a la altura de la rodilla, espalda tensa y hombros sobre la barra.',
  'Tras la pausa, completa una extensión explosiva de cadera y rodillas con la barra pegada al cuerpo.',
  'Encoge, tira con codos altos y recibe overhead en sentadilla con los brazos bloqueados.',
  'La pausa enseña posiciones; carga moderada (técnica > kilos).',
  'Error típico: ‘saltar’ la pausa o rebotar. Reloj interno estricto.',
  'Úsala para corregir segundo tirón flojo o despegue prematuro.'
]::text[]
where catalog_key = 'catalog:Arrancada con pausa';

update public.business_exercise_catalog
set mobile_instructions = array[
  'Desde el suelo con agarre ancho: primer tirón controlado, barra cerca de las piernas y espalda tensa.',
  'Segundo tirón explosivo: extiende cadera y rodillas, encoge con los brazos largos y la barra pegada.',
  'Recibe overhead en cuarto o media sentadilla (cadera sobre rodillas) con brazos bloqueados y párate.',
  'Error típico: recepción demasiado profunda (ya no es power) o brazos que tiran pronto.',
  'Estándar power: cadera por encima de la rodilla al atrapar. Progresión a arrancada completa cuando el power sea sólido.',
  'Inhala antes del tirón; exhala al estabilizar arriba.'
]::text[]
where catalog_key = 'catalog:Arrancada de potencia';

update public.business_exercise_catalog
set mobile_instructions = array[
  'Barra sobre bloques a la altura elegida (rodilla o medio muslo): pies bajo la barra, espalda tensa y hombros sobre ella.',
  'Empuja el suelo y completa el segundo y tercer tirón desde los bloques, sin el primer tirón del suelo.',
  'Recibe overhead (power o squat según la programación) con brazos bloqueados y levántate.',
  'Baja la barra a los bloques con control; no la sueltes de golpe.',
  'Error típico: inclinarte demasiado o perder contacto barra–muslo. Mantén dorsal activo.',
  'Ideal para reforzar la zona débil del tirón. Carga submáxima al aprender.'
]::text[]
where catalog_key = 'catalog:Arrancada desde bloques';

update public.business_exercise_catalog
set mobile_instructions = array[
  'Completa el tirón de arrancada: extensión plena, barra pegada y encogimiento con brazos largos.',
  'En la recepción abre en zancada (split) en lugar de sentadilla: un pie adelante y otro atrás, barra bloqueada overhead y torso vertical.',
  'Recupera los pies al ancho de hombros y párate con la barra arriba.',
  'Error típico: split demasiado estrecho o rodilla delantera que se pasa de la punta del pie en exceso.',
  'Practica el split sin carga (overhead lunges) antes de cargar.',
  'Útil si la movilidad de squat overhead limita; no sustituye el trabajo de OHS.'
]::text[]
where catalog_key = 'catalog:Arrancada en split';

update public.business_exercise_catalog
set mobile_instructions = array[
  'Posición colgante: barra sobre las rodillas, torso inclinado, espalda plana y hombros por delante de la barra.',
  'Extensión explosiva: cadera, rodillas y tobillos se extienden a la vez mientras encoges y la barra sube pegada al cuerpo.',
  'Recepción en squat frontal profundo: barra en rack sobre los hombros, codos altos y torso erguido.',
  'Pausa en hang para fijar postura. Carga técnica primero.',
  'Estándar: recepción en squat completo + de pie con barra en rack.',
  'Si el rack duele, trabaja movilidad de muñeca/hombro y front squat.'
]::text[]
where catalog_key = 'catalog:Cargada colgante completa';

update public.business_exercise_catalog
set mobile_instructions = array[
  'Pausa de 1–2 s con la barra a la altura de las rodillas: espalda tensa, hombros sobre la barra y peso en el mediopié.',
  'Tras la pausa, extensión explosiva completa: cadera, rodillas y tobillos, con la barra pegada al cuerpo.',
  'Recepción en squat frontal profundo: barra en rack, codos altos y torso firme; levántate con control.',
  'Error típico: acortar la pausa bajo fatiga. Sé estricto con el tiempo.',
  'Carga moderada. Combina con tirones de cargada.',
  'Si redondeas en la pausa, baja kilos.'
]::text[]
where catalog_key = 'catalog:Cargada con pausa';

update public.business_exercise_catalog
set mobile_instructions = array[
  'Salida desde el suelo: barra sobre el mediopié, cadera baja, espalda plana y hombros por delante de la barra.',
  'Extensión explosiva: triple extensión con encogimiento, la barra sube vertical y pegada.',
  'Recepción power en cuarto de squat: barra en rack frontal, codos altos y cadera por encima de las rodillas.',
  'Estándar power: cadera sobre rodilla al atrapar. Puente a clean completo después.',
  'Inhala antes del tirón; exhala al fijar el rack.',
  'Si los codos no suben, aligera y haz tall cleans.'
]::text[]
where catalog_key = 'catalog:Cargada de potencia';

update public.business_exercise_catalog
set mobile_instructions = array[
  'Salida desde el suelo: barra sobre el mediopié, cadera baja, espalda plana y hombros por delante de la barra.',
  'Tirón alto sin salto: extiende el cuerpo y tira con los codos altos, sin sentarte bajo la barra.',
  'Recepción de pie: barra en rack frontal con codos altos y piernas extendidas, sin squat.',
  'Entrena trayectoria y velocidad de codos. No reemplaza el clean completo.',
  'Si no llega al rack, haz high pull + front squat por separado.',
  'Mantén la barra cerca del cuerpo todo el recorrido.'
]::text[]
where catalog_key = 'catalog:Cargada muscular';

update public.business_exercise_catalog
set mobile_instructions = array[
  'Inicio en rack frontal: de pie con la barra sobre los hombros, codos ligeramente altos y pies a la anchura de la cadera.',
  'Press estricto: la barra sube por delante de la cara con las piernas bloqueadas y el torso vertical.',
  'Bloqueo overhead: brazos extendidos con la barra sobre el mediopié y la cabeza ligeramente adelantada.',
  'Si el press falla, baja la carga del clean o haz push press programado.',
  'Estándar: rack sólido + bloqueo overhead completo.',
  'Respira: exhala al press.'
]::text[]
where catalog_key = 'catalog:Cargada y press';

update public.business_exercise_catalog
set mobile_instructions = array[
  'Posición colgante: barra sobre las rodillas, torso inclinado, espalda plana y hombros por delante de la barra.',
  'Extensión explosiva: triple extensión con encogimiento, la barra sube pegada al cuerpo.',
  'Recepción power en cuarto de squat: barra en rack frontal, codos altos y cadera por encima de las rodillas.',
  'Excelente para el segundo tirón. Carga técnica primero.',
  'Estándar power + rack sólido.',
  'Si los codos fallan, tall clean.'
]::text[]
where catalog_key = 'catalog:Hang power clean';
