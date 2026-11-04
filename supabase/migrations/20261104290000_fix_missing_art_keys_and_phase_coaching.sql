-- OTA (sin App Store): art_keys a stems ya empaquetados + coaching por fase.
-- Carrusel: mobile_art_keys = frames; los N primeros mobile_instructions = caption 1:1.
-- 2026-11-04. Remaps E/F/G y huecos sin imagen dedicada.

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_prensa']::text[],
  mobile_instructions = ARRAY['Siéntate con la espalda apoyada; almohadillas en la cara EXTERNA de rodillas/muslos (abres hacia fuera).','Abre las piernas contra la resistencia sin arquear la lumbar ni empujar con los pies.','Vuelve al centro con control hasta el tope cómodo de la máquina.','Error típico: inclinarte adelante o confundir con aducción (cerrar piernas).','Exhala al abrir. Trabaja glúteo medio.','Progresión: más peso o pausa en apertura. Alternativa: almeja con banda.','Estándar: apertura controlada; pelvis quieta.']::text[]
WHERE catalog_key = 'catalog:Abducción de cadera en máquina' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_curl_femoral']::text[],
  mobile_instructions = ARRAY['Siéntate con almohadillas en la cara INTERNA de rodillas/muslos (cierras hacia dentro).','Cierra las piernas contra la resistencia de forma controlada; espalda pegada.','Abre de nuevo sin dejar que el peso tire de golpe.','Error típico: rebotar al cierre o confundir con abducción (abrir piernas).','Exhala al cerrar. Trabaja aductores internos.','Progresión: más peso. Alternativa: aducción en polea baja.','Estándar: cierre completo y apertura controlada.']::text[]
WHERE catalog_key = 'catalog:Aducción de cadera en máquina' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_prensa']::text[],
  mobile_instructions = ARRAY['De lado; rodillas ~90°; banda encima de rodillas; pies juntos; pelvis apilada.','Abre la rodilla de arriba como una almeja sin separar pies ni rotar la pelvis.','Baja casi a tocar sin perder tensión; completa el lado y cambia.','Error típico: rodar la cadera atrás o abrir con el lumbar.','Exhala al abrir.','Progresión: banda más fuerte o tempo. Alternativa: abducción en máquina.','Estándar: pelvis quieta y apertura completa.']::text[]
WHERE catalog_key = 'catalog:Almeja con banda' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_pajaros']::text[],
  mobile_instructions = ARRAY['Banda a altura de pecho; brazos extendidos delante; tensión ligera al inicio.','Abre hacia los lados apretando omóplatos; vuelve sin perder tensión.','Error típico: encoger trapecios o flexionar demasiado los codos.','Exhala al abrir.','Progresión: banda más fuerte. Alternativa: pájaros con mancuernas.','Estándar: apertura completa con omóplatos activos.']::text[]
WHERE catalog_key = 'catalog:Aperturas con banda' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_crunch']::text[],
  mobile_instructions = ARRAY['De rodillas o de pie ante polea alta; cuerda detrás de la cabeza o a los lados del cuello.','Enrolla costillas hacia pelvis sin tirar del cuello; vuelve con control.','Error típico: flexionar solo de cadera o usar los brazos.','Exhala al enrollar.','Progresión: más peso. Alternativa: crunch en suelo.','Estándar: flexión de tronco con pelvis estable.']::text[]
WHERE catalog_key = 'catalog:Crunch en polea' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_curl_mancuernas']::text[],
  mobile_instructions = ARRAY['Sentado; codo interno apoyado en el muslo; mancuerna colgando.','Curl sin balancear el torso; aprieta arriba; baja hasta estirar.','Error típico: despegar el codo del muslo o girar el tronco.','Exhala al subir; completa el lado.','Progresión: más peso. Alternativa: curl con mancuernas.','Estándar: codo fijo y rango completo.']::text[]
WHERE catalog_key = 'catalog:Curl concentrado' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_curl_barra_1','art_curl_barra_2']::text[],
  mobile_instructions = ARRAY['Antebrazos apoyados; muñecas libres sobre el borde; agarre de barra/mancuerna.','Flexiona solo la muñeca hacia arriba; baja hasta estirar con control.','Error típico: mover los codos o usar demasiado peso.','Exhala al flexionar.','Progresión: más reps o peso ligero. Alternativa: curl inverso de antebrazo.','Estándar: solo muñeca; antebrazo quieto.']::text[]
WHERE catalog_key = 'catalog:Curl de muñeca' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_curl_femoral']::text[],
  mobile_instructions = ARRAY['Siéntate; rodillo sobre la tibia distal; espalda y muslos fijados.','Flexiona rodillas llevando el rodillo hacia abajo/atrás; pausa; extiende con control.','Error típico: despegar la pelvis o rebotar abajo.','Exhala al flexionar.','Progresión: más peso. Alternativa: curl femoral tumbado.','Estándar: rango completo sin levantar la cadera.']::text[]
WHERE catalog_key = 'catalog:Curl femoral sentado' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_curl_femoral']::text[],
  mobile_instructions = ARRAY['Boca abajo; rodillo sobre los tobillos; cadera pegada al banco.','Flexiona llevando talones hacia glúteos; baja controlado hasta casi estirar.','Error típico: arquear lumbar o levantar la pelvis.','Exhala al flexionar.','Progresión: más peso. Alternativa: curl femoral sentado.','Estándar: cadera quieta y flexión completa.']::text[]
WHERE catalog_key = 'catalog:Curl femoral tumbado' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_curl_mancuernas']::text[],
  mobile_instructions = ARRAY['Banco a ~45–60°; espalda pegada, mancuernas colgando con brazos largos.','Curl sin balancear; codos estables bajo los hombros; baja hasta estirar el bíceps.','Error típico: arquear la lumbar o subir los hombros.','Exhala al subir.','Progresión: más peso o tempo lento. Alternativa: curl con mancuernas de pie.','Estándar: rango largo abajo y control arriba.']::text[]
WHERE catalog_key = 'catalog:Curl inclinado con mancuernas' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_dominadas_1','art_dominadas_2']::text[],
  mobile_instructions = ARRAY['Agarre prono; rodillas o pies en la asistencia; hombros activos abajo.','Tira pecho a la barra; baja hasta casi extensión sin soltar dorsales.','Error típico: balancear piernas o encoger el cuello.','Exhala al subir.','Progresión: menos asistencia. Alternativa: jalón al pecho.','Estándar: mentón sobre barra y bajada controlada.']::text[]
WHERE catalog_key = 'catalog:Dominadas asistidas' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_gy_hollow_hold']::text[],
  mobile_instructions = ARRAY['En banco; agarra el borde detrás de la cabeza; hombros anclados.','Eleva el cuerpo rígido (hombros a pies) casi vertical; baja en línea sin romper cadera.','Controla hasta el ángulo que mantengas rígido; no dejes caer la lumbar.','Error típico: picar de cadera o flexionar solo de rodillas.','Exhala en la bajada controlada.','Progresión: negatives lentos o rodillas recogidas. Alternativa: hollow hold.','Estándar: línea recta hombros-cadera-tobillos.']::text[]
WHERE catalog_key = 'catalog:Dragon flag' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_elevaciones_laterales']::text[],
  mobile_instructions = ARRAY['Polea baja; de lado a la máquina; agarre con el brazo externo; codo blando.','Eleva en arco hasta ~altura de hombro; baja en 2–3 s sin encoger trapecio.','Error típico: balancear el torso o subir por encima de la oreja.','Exhala al subir; completa el lado.','Progresión: más peso o tempo. Alternativa: elevaciones con mancuernas.','Estándar: arco lateral limpio hasta la línea del hombro.']::text[]
WHERE catalog_key = 'catalog:Elevaciones laterales en polea' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_remo_barra_1','art_remo_barra_2']::text[],
  mobile_instructions = ARRAY['Barra (o mancuernas) colgando a brazos extendidos; pies al ancho de cadera.','Encoge trapecios elevando hombros hacia las orejas; pausa; baja con control.','Error típico: rizar los codos o girar la cabeza.','Exhala al subir.','Progresión: más peso. Alternativa: shrug en máquina.','Estándar: elevación escapular completa sin flexionar codos.']::text[]
WHERE catalog_key = 'catalog:Encogimientos' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_triceps_polea']::text[],
  mobile_instructions = ARRAY['Mancuerna/barra/cuerda sobre la cabeza; codos altos junto a las orejas.','Flexiona solo el codo bajando la carga detrás; extiende a bloqueo sin abrir codos.','Error típico: abrir los codos o arquear la lumbar.','Exhala al extender.','Progresión: más peso. Alternativa: jalón de tríceps en polea.','Estándar: codos fijos y rango completo overhead.']::text[]
WHERE catalog_key = 'catalog:Extensión tríceps overhead' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_fondos']::text[],
  mobile_instructions = ARRAY['Agarre en paralelas o máquina; asistencia en rodillas/pies; torso ligeramente inclinado.','Baja a ~90° de codo; empuja a bloqueo sin encoger trapecios.','Error típico: hombros adelante o rebotar abajo.','Exhala al empujar.','Progresión: menos asistencia. Alternativa: fondos en banco.','Estándar: rango controlado y bloqueo arriba.']::text[]
WHERE catalog_key = 'catalog:Fondos asistidos' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_gemelos_1','art_gemelos_2']::text[],
  mobile_instructions = ARRAY['Cadera flexionada (apoyo o máquina); antepié en borde; tobillos libres.','Sube a punta máxima; baja talones por debajo del apoyo con control.','Error típico: rebotar o flexionar/extender rodillas de más.','Exhala al subir.','Progresión: más carga. Alternativa: gemelos de pie.','Estándar: rango completo con cadera fija.']::text[]
WHERE catalog_key = 'catalog:Gemelos de burro' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_gemelos_1','art_gemelos_2']::text[],
  mobile_instructions = ARRAY['Siéntate; almohadilla sobre muslos/rodillas; antepié en la plataforma; tobillos libres.','Sube a punta máxima; pausa; baja talones por debajo del apoyo (sóleo).','Error típico: rebotar abajo o usar impulso de tronco.','Exhala al subir.','Progresión: más peso. Alternativa: gemelos de pie.','Estándar: rango completo con rodillas flexionadas.']::text[]
WHERE catalog_key = 'catalog:Gemelos sentado' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_curl_femoral']::text[],
  mobile_instructions = ARRAY['A cuatro apoyos; banda encima de rodillas; espalda neutra; mirada al suelo.','Eleva una rodilla al lado manteniendo la cadera cuadrada; pie flexionado.','Baja con control; completa el lado sin arching lumbar.','Error típico: rotar el torso o subir la rodilla con la lumbar.','Exhala al subir.','Progresión: banda más fuerte o pausa arriba. Alternativa: almeja con banda.','Estándar: rodilla a altura de cadera sin perder el cuadrúpedo.']::text[]
WHERE catalog_key = 'catalog:Hidrante con banda' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_gy_ghd_back']::text[],
  mobile_instructions = ARRAY['En GHD o máquina; cadera en el borde; torso alineado; pies fijados.','Baja el torso con control; extiende cadera hasta línea recta apretando glúteos.','Error típico: hiperextender lumbar o usar impulso.','Exhala al subir.','Progresión: peso en pecho o tempo. Alternativa: back extension.','Estándar: línea recta arriba sin arquear de más.']::text[]
WHERE catalog_key = 'catalog:Hip extension' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_jalon_1','art_jalon_2']::text[],
  mobile_instructions = ARRAY['Polea alta; barra o cuerda; brazos casi extendidos; bisagra ligera.','Lleva la barra a los muslos apretando dorsales; vuelve arriba con control.','Error típico: flexionar mucho los codos o balancear el tronco.','Exhala al bajar.','Progresión: más peso. Alternativa: pull-over con mancuerna.','Estándar: brazos largos y cierre de dorsal abajo.']::text[]
WHERE catalog_key = 'catalog:Jalón a brazos rectos' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_triceps_polea']::text[],
  mobile_instructions = ARRAY['Bisagra o apoyo en banco; brazo superior paralelo al suelo; codo alto y fijo.','Extiende solo el codo atrás hasta bloqueo; vuelve sin mover el hombro.','Error típico: balancear el brazo entero o bajar el codo.','Exhala al extender; completa el lado.','Progresión: más peso. Alternativa: extensión en polea.','Estándar: codo quieto y extensión completa.']::text[]
WHERE catalog_key = 'catalog:Kickback de tríceps' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_remo_barra_1','art_remo_barra_2']::text[],
  mobile_instructions = ARRAY['Barra en landmine; stance de esgrima; agarre al extremo; torso inclinado.','Tira el codo atrás hacia la cadera; baja hasta estirar sin rotar de más.','Error típico: girar todo el tronco o encoger el cuello.','Exhala al tirar; completa el lado.','Progresión: más discos. Alternativa: remo a una mano.','Estándar: codo alto-atrás y torso estable.']::text[]
WHERE catalog_key = 'catalog:Meadows row' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_aperturas_1','art_aperturas_2']::text[],
  mobile_instructions = ARRAY['Espalda pegada; antebrazos en pads o agarres en manos; omóplatos bajos.','Cierra en arco hasta juntar delante del pecho; abre hasta estirar sin forzar hombro.','Error típico: empujar con trapecios o rebotar al cierre.','Exhala al cerrar.','Progresión: más peso. Alternativa: aperturas con mancuernas.','Estándar: cierre completo delante del pecho.']::text[]
WHERE catalog_key = 'catalog:Pec deck' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_gy_planche']::text[],
  mobile_instructions = ARRAY['Plancha alta; manos bajo hombros; body hollow (glúteos y abs activos).','Inclina hacia delante: hombros por delante de las muñecas sin hundir la lumbar.','Mantén o micro-pulsos; vuelve a plancha neutra con control.','Error típico: arquear la espalda o subir caderas en pica.','Exhala al inclinarte; respira corto en la retención.','Progresión: más lean o planche tuck. Alternativa: pike push-up.','Estándar: cuerpo rígido con proyección clara de hombros.']::text[]
WHERE catalog_key = 'catalog:Planche lean' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_press_militar_1','art_press_militar_2']::text[],
  mobile_instructions = ARRAY['Espalda al respaldo; agarres a la altura de hombros; codos bajo las muñecas.','Empuja arriba hasta casi extensión; baja con control hasta ~orejas/hombros.','Error típico: arquear lumbar o abrir demasiado los codos.','Exhala al empujar.','Progresión: más peso. Alternativa: press militar con mancuernas.','Estándar: trayectoria vertical y pelvis quieta.']::text[]
WHERE catalog_key = 'catalog:Press hombro en máquina' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_press_banca_1','art_press_banca_2']::text[],
  mobile_instructions = ARRAY['Espalda y omóplatos al respaldo; agarres a altura de pecho medio.','Empuja a extensión sin bloquear de golpe; vuelve hasta estirar el pecho.','Error típico: despegar la lumbar o encoger trapecios.','Exhala al empujar.','Progresión: más peso. Alternativa: press banca con mancuernas.','Estándar: rango completo con omóplatos fijos.']::text[]
WHERE catalog_key = 'catalog:Press pecho en máquina' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_remo_sentado']::text[],
  mobile_instructions = ARRAY['Pecho apoyado en el pad; agarre prono o neutro; brazos colgando.','Tira hacia el abdomen/pecho bajo apretando omóplatos; baja hasta estirar.','Error típico: despegar el pecho o usar impulso de cuello.','Exhala al tirar.','Progresión: más peso. Alternativa: remo sentado en polea.','Estándar: pecho pegado y retracción completa.']::text[]
WHERE catalog_key = 'catalog:Remo con apoyo de pecho' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_remo_barra_1','art_remo_barra_2']::text[],
  mobile_instructions = ARRAY['Agarra el mango de la barra T; bisagra con espalda neutra y pecho alto.','Tira el mango al pecho/abdomen apretando omóplatos; baja hasta estirar sin redondear.','Error típico: impulso de torso o encoger el cuello.','Exhala al tirar.','Progresión: más discos. Alternativa: remo con barra.','Estándar: contacto al torso y bajada controlada.']::text[]
WHERE catalog_key = 'catalog:Remo en T' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_remo_invertido']::text[],
  mobile_instructions = ARRAY['Boca abajo en banco alto; mancuernas o barra colgando; pecho apoyado.','Tira hacia las costillas apretando omóplatos; baja hasta estirar.','Error típico: despegar el pecho o usar impulso de cuello.','Exhala al tirar.','Progresión: más peso. Alternativa: remo con apoyo de pecho.','Estándar: pecho pegado y tirón completo.']::text[]
WHERE catalog_key = 'catalog:Seal row' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_prensa']::text[],
  mobile_instructions = ARRAY['Mancuernas a los lados o en goblet; caja detrás a altura de paralelo.','Siéntate en la caja con control (no te dejes caer); pausa breve y empuja a pie.','Error típico: rebotar en la caja o perder el pecho alto.','Inhala al bajar; exhala al subir.','Progresión: caja más baja o más carga. Alternativa: sentadilla libre.','Estándar: contacto suave en la caja y extensión completa arriba.']::text[]
WHERE catalog_key = 'catalog:Sentadilla a cajón con mancuernas' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_bulgara_1','art_bulgara_2','art_bulgara_3']::text[],
  mobile_instructions = ARRAY['Pie trasero en banco; pie delantero adelantado; mancuernas a los lados; torso alto.','Baja hasta muslo delantero ~paralelo; rodilla trasera cerca del suelo.','Empuja con el pie delantero hasta extensión; completa el lado y cambia.','Error típico: pie delantero demasiado cerca o inclinarte en exceso.','Inhala al bajar; exhala al subir.','Progresión: más peso o pausa abajo. Alternativa: zancada inversa.','Estándar: rodilla delantera estable y torso controlado.']::text[]
WHERE catalog_key = 'catalog:Sentadilla búlgara con mancuernas' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_sentadilla_1','art_sentadilla_2']::text[],
  mobile_instructions = ARRAY['Safety bar sobre trapecios; agarres en las asas; pies estables.','Baja a paralelo o más; empuja a extensión manteniendo pecho en la barra.','Error típico: dejar caer los agarres o cortar profundidad.','Inhala al bajar; exhala al subir.','Progresión: más peso. Alternativa: sentadilla trasera.','Estándar: profundidad marcada y torso controlado.']::text[]
WHERE catalog_key = 'catalog:Sentadilla con safety bar' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_sentadilla_1','art_sentadilla_2']::text[],
  mobile_instructions = ARRAY['Barra Smith sobre trapecios; pies algo adelantados; desengancha con control.','Baja a paralelo o más con rodillas alineadas; empuja a extensión y reengancha al terminar.','Error típico: pies demasiado atrás (dolor de rodilla) o cortar profundidad.','Inhala al bajar; exhala al subir.','Progresión: más peso. Alternativa: sentadilla libre con barra.','Estándar: profundidad marcada y extensión completa arriba.']::text[]
WHERE catalog_key = 'catalog:Sentadilla en Smith' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_sentadilla_1','art_sentadilla_2']::text[],
  mobile_instructions = ARRAY['Pies fijos; eleva talones si hace falta; torso y muslos en línea al inclinar.','Baja flexionando rodillas hacia delante con control; vuelve apretando cuádriceps.','Error típico: sentarte atrás (ya no es sissy) o perder el equilibrio.','Inhala al bajar; exhala al subir.','Progresión: más rango o carga ligera. Alternativa: extensión de cuádriceps.','Estándar: inclinación controlada y cuádriceps cargados.']::text[]
WHERE catalog_key = 'catalog:Sissy squat' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_curl_mancuernas']::text[],
  mobile_instructions = ARRAY['Boca abajo en banco inclinado; brazos colgando al frente del pad; agarre fijo.','Curl sin balancear; aprieta arriba; baja hasta estirar con control.','Error típico: despegar el pecho o usar impulso de hombros.','Exhala al subir.','Progresión: más peso. Alternativa: curl predicador.','Estándar: pecho pegado y rango completo.']::text[]
WHERE catalog_key = 'catalog:Spider curl' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_cf_step_up']::text[],
  mobile_instructions = ARRAY['De pie en cajón/escalón; una pierna libre al frente; torso alto.','Baja el pie libre hacia el suelo con control (casi tocando); vuelve con la pierna de apoyo.','Error típico: dejar caer la cadera o empujar con el pie libre.','Exhala al subir; completa el lado.','Progresión: cajón más alto o tempo. Alternativa: step-up.','Estándar: cadera nivelada y control excéntrico.']::text[]
WHERE catalog_key = 'catalog:Step-down' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_extension_cuad']::text[],
  mobile_instructions = ARRAY['Ancla la banda detrás a altura de rodilla; pásala por detrás de la rodilla de trabajo; pie adelantado.','Parte con rodilla ligeramente flexionada; extiende a bloqueo suave contra la tensión.','Flexiona un poco y repite; alineación rodilla-pie; completa el lado.','Error típico: empujar con la cadera o hiperextender de golpe.','Exhala al extender.','Progresión: banda más fuerte. Alternativa: extensión de cuádriceps rango corto.','Estándar: extensión terminal controlada sin dolor.']::text[]
WHERE catalog_key = 'catalog:TKE con banda' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_peso_muerto_1','art_peso_muerto_2']::text[],
  mobile_instructions = ARRAY['Barra en rack a altura de espinillas/rodilla; agarre prono; espalda plana.','Empuja el suelo y extiende cadera/rodillas hasta bloqueo; baja a los pins con control.','Error típico: redondear lumbar o hiperextender arriba.','Exhala al subir.','Progresión: más peso. Alternativa: peso muerto convencional.','Estándar: bloqueo sólido y barra cerca del cuerpo.']::text[]
WHERE catalog_key = 'catalog:Tirón de rack' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_cf_vup_1','art_cf_vup_2']::text[],
  mobile_instructions = ARRAY['Tumbado, brazos en cruz (o colgado); piernas juntas extendidas o semi-flexionadas.','Baja las piernas a un lado sin despegar omóplatos; centro; al otro lado con control.','Error típico: impulso o levantar toda la espalda alta.','Exhala al bajar a cada lado.','Progresión: piernas más rectas o colgado. Alternativa: Russian twist.','Estándar: arco lado a lado con torso anclado.']::text[]
WHERE catalog_key = 'catalog:Windshield wipers' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_pajaros']::text[],
  mobile_instructions = ARRAY['Polea alta o media; agarre a dos manos; pies firmes, cadera al destino del movimiento.','Tira en diagonal de arriba-fuera hacia abajo-dentro rotando torso con brazos semi-extendidos.','Vuelve con control sin soltar el abdomen; cambia de lado.','Error típico: solo mover brazos o girar rodillas.','Exhala al cortar.','Progresión: más peso. Alternativa: woodchop con mancuerna/medball.','Estándar: rotación de tronco con cadera estable.']::text[]
WHERE catalog_key = 'catalog:Woodchop en polea' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[],
  mobile_instructions = ARRAY['De pie; da un paso atrás y cruzado detrás de la pierna de apoyo (cortesía).','Baja con control; empuja con la pierna de apoyo hasta extensión; completa el lado.','Mantén pelvis estable y rodilla delantera alineada.','Error típico: torcer la rodilla de apoyo o perder el equilibrio.','Inhala al bajar; exhala al subir.','Progresión: mancuernas. Alternativa: zancada inversa.','Estándar: paso cruzado controlado y torso alto.']::text[]
WHERE catalog_key = 'catalog:Zancada en cortesía' AND is_active;

UPDATE public.business_exercise_catalog
SET
  mobile_art_keys = ARRAY['art_zancadas_1','art_zancadas_2','art_zancadas_3']::text[],
  mobile_instructions = ARRAY['De pie alto; da un paso atrás y baja hasta rodilla trasera cerca del suelo.','Empuja con el pie delantero para volver; alterna o completa el lado.','Mantén torso alto y rodilla delantera estable sobre el pie.','Error típico: paso demasiado corto o inclinarte adelante.','Inhala al bajar; exhala al subir.','Progresión: mancuernas o tempo. Alternativa: zancada caminando.','Estándar: rodilla trasera cerca del suelo con control.']::text[]
WHERE catalog_key = 'catalog:Zancada inversa' AND is_active;

