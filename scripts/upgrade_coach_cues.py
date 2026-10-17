#!/usr/bin/env python3
"""Upgrade CatalogSpanish instructions to trainer-quality coaching.

Keeps the first N carousel phase captions when present; appends 5–6 coaching cues.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CS = ROOT / "Packages/GymbroDomain/Sources/GymbroDomain/CatalogSpanish.swift"

CAROUSEL = {
    "Press banca": 2, "Press banca inclinada": 2, "Aperturas": 2, "Dominadas": 2,
    "Peso muerto": 2, "Peso muerto rumano": 2, "Sentadilla": 2, "Sentadilla frontal": 2,
    "Zancadas": 3, "Sentadilla búlgara": 3, "Press militar": 2, "Hip thrust": 2,
    "Cargada": 3, "Cargada colgante": 3, "Arrancada": 3, "Cargada y envión": 3,
    "Split jerk": 3, "Overhead squat": 3, "Thruster": 3, "Cluster": 3, "Burpee": 3,
    "Salto al cajón": 3, "Muscle-up barra": 3, "Muscle-up anillas": 3, "Toes to bar": 3,
    "Chest to bar": 3, "HSPU": 3, "Wall walk": 3, "Fondos en anillas": 3, "Rope climb": 3,
    "GHD sit-up": 3, "Snatch kettlebell": 3, "Turkish get-up": 3, "Wall ball": 3,
    "Devil press": 3, "Fondos en paralelas": 2, "Burpee pull-up": 3, "Box jump over": 3,
}

# name -> 5–6 coaching steps (trainer voice: clear for beginners, precise for advanced)
COACH: dict[str, list[str]] = {
    "Press banca": [
        "Túmbate en banco plano con ojos bajo la barra; pies firmes en el suelo y glúteos apoyados.",
        "Agarre prono un poco más ancho que los hombros; saca la barra y bloquea sobre el pecho con omóplatos retraídos.",
        "Inhala y baja la barra en línea controlada hasta el pecho medio, codos ~45° respecto al torso (no 90° abiertos).",
        "Sin rebotar, empuja la barra arriba hasta extender los brazos; exhala al pasar el punto difícil.",
        "Error típico: arquear la lumbar o abrir excesivamente los codos. Mantén muñecas apiladas sobre los antebrazos.",
        "Estándar: cada rep toca el pecho (o llega al rango seguro) y termina en bloqueo completo.",
    ],
    "Press banca inclinada": [
        "Ajusta el banco a 30–45°. Túmbate con pies firmes y omóplatos pegados al banco.",
        "Agarre prono; desbloquea la barra y colócala sobre el pecho alto / clavícula, no sobre la cara.",
        "Baja controlado hacia pecho alto manteniendo codos bajo la barra.",
        "Empuja en diagonal ligera hasta bloqueo; no dejes que las muñecas se quiebren atrás.",
        "Error típico: inclinación demasiado vertical (se convierte en press de hombro) o rebotar en el pecho.",
        "Si eres principiante, empieza ligero y prioriza el contacto estable en pecho alto.",
    ],
    "Press mancuernas": [
        "Túmbate en banco plano; sube las mancuernas a los lados del pecho con ayuda de las rodillas si hace falta.",
        "Muñecas apiladas sobre los codos, palmas al frente; omóplatos retraídos y pies firmes.",
        "Baja las mancuernas hasta estirar el pecho (aprox. 90° de codo), sin abrir en exceso.",
        "Empuja arriba juntando ligeramente las mancuernas al final, sin chocarlas con violencia.",
        "Error típico: arquear lumbar o perder el control en el descenso. Exhala al empujar.",
        "Ventaja vs barra: mayor rango y detección precoz de asimetrías; iguala ambos lados.",
    ],
    "Aperturas": [
        "Banco inclinado ~30°; mancuernas sobre el pecho con codos blandos (nunca bloqueados).",
        "Abre en arco amplio hasta sentir estiramiento en el pecho; mancuernas a la altura del torso.",
        "Mantén el mismo ángulo de codo durante todo el movimiento (es un vuelo, no un press).",
        "Cierra el arco juntando las mancuernas sobre el pecho sin convertir el final en press vertical.",
        "Error típico: bajar demasiado y forzar el hombro, o flexionar/extender el codo a cada rep.",
        "Carga moderada: si no puedes controlar el arco, reduce el peso.",
    ],
    "Fondos": [
        "Agarra las paralelas y súbete a soporte: brazos extendidos, hombros bajos y lejos de las orejas.",
        "Inclina el torso ligeramente adelante si buscas más pecho; más vertical = más tríceps.",
        "Baja flexionando codos hasta ~90° o hasta hombros a la altura de los codos, con control.",
        "Empuja hasta bloqueo completo sin encoger trapecios ni balancear piernas.",
        "Error típico: hundir el cuello entre los hombros o rebotar abajo. Para si duele la articulación.",
        "Progresión: banda asistida → cuerpo completo → lastre. Marca siempre el mismo rango.",
    ],
    "Dominadas": [
        "Cuelga muerto de la barra: brazos totalmente extendidos, hombros activos (ligera depresión escapular).",
        "Inicia el tirón llevando los codos abajo y atrás; pecho hacia la barra, no la barbilla al frente.",
        "Sube hasta que la barbilla pase claramente la barra; aprieta dorsales un instante.",
        "Baja en 2–3 segundos hasta extensión completa de brazos antes de la siguiente rep.",
        "Error típico: kipping no pedido, o cortar el rango abajo. Si no llegas, usa banda o negativo.",
        "Agarre prono al ancho de hombros (o un poco más); aprieta la barra y mantén piernas quietas.",
    ],
    "Jalón al pecho": [
        "Ajusta asiento y rodilleras; torso erguido con ligera inclinación atrás (no balanceo).",
        "Agarre prono un poco más ancho que hombros; inicia el tirón desde la espalda, no desde los brazos.",
        "Lleva la barra a pecho alto / clavícula apretando omóplatos; codos abajo.",
        "Extiende los brazos con control hasta el estiramiento, sin soltar del todo la tensión del dorsal.",
        "Error típico: tirar con impulso de tronco o llevar la barra detrás de la nuca sin movilidad.",
        "Exhala al tirar; mantén costillas abajo para no arquear la lumbar.",
    ],
    "Remo con barra": [
        "Pies al ancho de cadera; bisagra de cadera hasta torso ~45°, barra colgando a brazos largos.",
        "Espalda plana, abdomen firme; agarre prono al ancho de hombros (o semi-supino si lo prefieres).",
        "Tira la barra hacia el ombligo / abdomen bajo, codos cerca del cuerpo, apretando omóplatos.",
        "Pausa breve arriba y baja sin redondear la lumbar ni usar impulso de cadera.",
        "Error típico: convertirlo en peso muerto con tirón: la cadera no debe extenderse a cada rep.",
        "Si la lumbar se redondea, sube el torso un poco o reduce la carga.",
    ],
    "Remo mancuerna": [
        "Apoya una rodilla y la mano del mismo lado en el banco; tronco casi paralelo al suelo.",
        "Mancuerna colgando a brazo largo, hombro activo; mirada al suelo para cuello neutro.",
        "Tira el codo hacia la cadera hasta la costilla; aprieta el dorsal sin rotar el tronco.",
        "Baja con control hasta estirar; completa la serie y cambia de lado.",
        "Error típico: girar el torso o encoger el hombro hacia la oreja al tirar.",
        "Usa un espejo o vídeo de lado para comprobar que la cadera permanece quieta.",
    ],
    "Peso muerto": [
        "Barra sobre mediopié; pies al ancho de cadera. Bisagra y agarra justo por fuera de las piernas.",
        "Pecho alto, espalda plana, omóplatos ligeramente retraídos; inhala y bracea el abdomen contra el cinturón (si usas).",
        "Empuja el suelo con los pies y extiende rodillas y cadera a la vez; barra pegada a las piernas.",
        "Bloquea de pie con cadera extendida y hombros sobre la barra; no te inclines atrás en hiperextensión.",
        "Baja empujando la cadera atrás y luego flexionando rodillas; deja la barra con control.",
        "Error típico: redondear lumbar o separar la barra del cuerpo. Si falla la técnica, baja el peso.",
    ],
    "Peso muerto rumano": [
        "De pie con la barra en las caderas, agarre prono (o mixto); rodillas blandas fijas.",
        "Empuja la cadera atrás manteniendo la barra cerca de los muslos; espalda plana.",
        "Baja hasta sentir un buen estiramiento de isquios (normalmente por debajo de la rodilla), sin redondear.",
        "Extiende la cadera para volver, apretando glúteos arriba; no bloquees de golpe las rodillas.",
        "Error típico: flexionarse demasiado de rodillas (se vuelve sentadilla) o mirar al techo arqueando lumbar.",
        "Tempo recomendado: 3 segundos de bajada, 1 arriba. Carga subordinada a la bisagra limpia.",
    ],
    "Sentadilla": [
        "Barra sobre trapecios (high-bar) o deltoides posteriores (low-bar); pies al ancho de hombros, punta ligeramente afuera.",
        "Desbloquea cadera y rodillas a la vez; pecho alto, mirada al frente; inhala y bracea antes de bajar.",
        "Baja hasta paralelo o más (cresta ilíaca bajo la rótula) manteniendo rodillas alineadas con las puntas.",
        "Empuja el suelo, extiende cadera y rodillas, y exhala al subir; termina de pie sin hiperextender lumbar.",
        "Error típico: rodillas que colapsan adentro, talones que se levantan, o cortar profundidad.",
        "Progresión: goblet → front → back squat. Marca siempre la misma profundidad.",
    ],
    "Sentadilla frontal": [
        "Barra en rack frontal (codos altos, barra sobre deltoides anteriores); torso más vertical que en back squat.",
        "Pies al ancho de hombros; inhala y bracea. Mantén los codos altos para no perder el rack.",
        "Baja entre las rodillas hasta paralelo o más; talones pegados al suelo.",
        "Empuja para subir manteniendo el pecho alto; no dejes que los codos caigan.",
        "Error típico: codos bajos (la barra rueda) o inclinarte demasiado adelante.",
        "Si falta movilidad de muñeca, usa cross-arm rack o straps; la barra debe quedar estable.",
    ],
    "Prensa": [
        "Siéntate con lumbar y pelvis pegadas al respaldo; pies al ancho de hombros en la plataforma.",
        "Desbloquea con control; baja flexionando rodillas sin despegar la zona lumbar del asiento.",
        "Profundidad: muslos cerca de 90° o el rango que mantenga talones y lumbar estables.",
        "Empuja hasta casi extender sin bloquear de golpe las rodillas; exhala al empujar.",
        "Error típico: poner los pies demasiado altos/bajos o rebotar en el fondo con la lumbar redondeada.",
        "Ajusta la plataforma para que el recorrido trabaje cuádriceps/glúteos sin dolor de rodilla.",
    ],
    "Zancadas": [
        "Mancuernas a los lados (o barra); torso erguido, mirada al frente.",
        "Da un paso largo adelante y baja hasta rodilla delantera ~90° y rodilla trasera cerca del suelo.",
        "Rodilla delantera sobre el mediopié (no muy por delante de la punta); peso repartido.",
        "Empuja con la pierna delantera para volver o para el siguiente paso (walking lunge).",
        "Error típico: inclinarte en exceso, pasos cortos que sobrecargan la rodilla, o tobillo inestable.",
        "Alterna piernas con el mismo rango; si eres principiante, hazlas estáticas antes de caminar.",
    ],
    "Extensión de cuádriceps": [
        "Ajusta el asiento para que la rodilla quede alineada con el eje de la máquina.",
        "Coloca el rodillo sobre la tibia distal (no sobre el tobillo sensible); espalda apoyada.",
        "Extiende las rodillas hasta casi bloqueo apretando cuádriceps; no arquees la lumbar.",
        "Baja en 2–3 segundos hasta el rango cómodo; no rebotes abajo.",
        "Error típico: usar impulso de cadera o carga que te haga despegar la pelvis.",
        "Ideal como aislamiento al final de pierna; controla el pico de contracción arriba.",
    ],
    "Curl femoral": [
        "Ajusta almohadillas para que la rodilla coincida con el pivote; cadera estable.",
        "Flexiona rodillas llevando el rodillo hacia los glúteos; aprieta isquios arriba.",
        "No levantes la pelvis ni arquees la lumbar para «ayudar».",
        "Extiende con control hasta casi estirar, manteniendo tensión.",
        "Error típico: rango incompleto o carga que te hace usar la lumbar.",
        "Sirve sentado o tumbado según la máquina; prioriza el contacto mental isquio.",
    ],
    "Elevación de gemelos": [
        "Antepié en el borde de la plataforma; tobillos libres para estirar abajo.",
        "Sube lo más alto posible sobre las puntas; pausa 1 s apretando gemelos.",
        "Baja talones por debajo del nivel del apoyo con control (estiramiento).",
        "Rodillas casi extendidas en la versión de pie; flexionadas si buscas más sóleo.",
        "Error típico: rebotar abajo o usar impulso de rodillas. Tempo lento.",
        "Progresión: a una pierna o con pausa larga arriba cuando domines el rango.",
    ],
    "Press militar": [
        "Barra a la altura de clavícula/front rack o desde rack a hombros; pies al ancho de cadera.",
        "Glúteos y abdomen firmes; muñecas apiladas. Inhala y bracea antes de empujar.",
        "Presiona la barra en línea vertical cerca de la cara; pasa la cabeza cuando la barra lo permita.",
        "Bloquea overhead con bíceps junto a las orejas, hombros activos; exhala arriba.",
        "Baja a hombros con control. Error típico: hiperextender lumbar o abrir excesivamente los codos.",
        "Versión estricta: sin dip de rodillas. Si usas push press, el dip debe ser corto y vertical.",
    ],
    "Elevaciones laterales": [
        "Mancuernas a los lados, torso quieto, codos ligeramente flexionados (fijos).",
        "Eleva en arco hasta ~altura de hombros; meñiques ligeramente más altos que los pulgares.",
        "No encogas trapecios ni balancees el cuerpo; el deltoides medio mueve el peso.",
        "Baja en 2–3 segundos manteniendo tensión; no dejes caer las mancuernas.",
        "Error típico: cargar demasiado y convertir el movimiento en encogimiento + balanceo.",
        "Series de 10–15 reps con control suelen enseñar mejor el patrón que el peso máximo.",
    ],
    "Pájaros": [
        "Inclina el torso ~45° (o tumba boca abajo en banco); mancuernas colgando, codos blandos.",
        "Abre los brazos en cruz apretando omóplatos; apunta a deltoides posterior, no a trapecio alto.",
        "Llega a la línea de los hombros sin hiperextender la lumbar ni girar el tronco.",
        "Baja con control. Mantén el cuello alineado (mira al suelo si estás inclinado).",
        "Error típico: usar demasiado peso y remar con la espalda media en vez de abrir en vuelo.",
        "Ideal para salud de hombro y postura; prioriza la calidad del apretón escapular.",
    ],
    "Curl barra": [
        "Agarre supino al ancho de hombros; codos pegados a las costillas; torso erguido.",
        "Flexiona solo el codo subiendo la barra sin balancear cadera ni hombros.",
        "Aprieta bíceps arriba; muñecas neutras (no las quiebres atrás).",
        "Baja en 2–3 s hasta casi extender, sin soltar toda la tensión.",
        "Error típico: cheat con swing de tronco. Si lo necesitas, baja el peso.",
        "Puedes usar EZ bar si te molestan las muñecas; el patrón de codo fijo no cambia.",
    ],
    "Curl mancuernas": [
        "Mancuernas a los lados; puedes alternar o subir ambas a la vez.",
        "Curl sin balanceo; codos fijos. Opcional: rota a supinación al subir.",
        "Aprieta arriba y baja con control hasta extensión casi completa.",
        "Mantén hombros bajos; no dejes que el codo viaje hacia delante en exceso.",
        "Error típico: usar impulso o rotar el tronco a cada lado.",
        "Trabaja el rango completo; si falla un lado, reduce carga y equilibra.",
    ],
    "Curl martillo": [
        "Agarre neutro (palmas mirándose); codos pegados al torso.",
        "Sube las mancuernas hacia el hombro sin abrir los codos hacia fuera.",
        "Pausa breve arriba; baja lento enfatizando braquial y antebrazo.",
        "Torso quieto; no balancees.",
        "Error típico: convertir el final en press o encoger hombros.",
        "Buena opción si el curl supino te irrita el codo; mantén muñecas firmes.",
    ],
    "Fondos en banco": [
        "Manos en el borde del banco, dedos al frente; glúteos cerca del banco, pies apoyados.",
        "Hombros bajos; baja flexionando codos hasta ~90° con el pecho abierto.",
        "Empuja a extensión de brazos sin encoger el cuello entre los hombros.",
        "Cuanto más lejos pongas los pies, más difícil; acerca pies o flexiona rodillas para facilitar.",
        "Error típico: alejarte demasiado del banco y sobrecargar la cara anterior del hombro.",
        "Si duele el hombro, reduce el rango o cambia a extensión en polea.",
    ],
    "Extensión tríceps polea": [
        "Polea alta; codos pegados al cuerpo, antebrazos paralelos al suelo al inicio.",
        "Extiende solo el codo llevando barra o cuerda abajo; torso quieto.",
        "Aprieta tríceps abajo 1 s; vuelve con control hasta el estiramiento cómodo.",
        "No muevas hombros ni uses la lumbar para empujar.",
        "Error típico: abrir los codos o cargar de más y hacer press de pecho.",
        "Con cuerda, separa ligeramente las manos abajo para un pico de contracción.",
    ],
    "Press cerrado": [
        "Banco plano; agarre al ancho de hombros o ligeramente más estrecho (no excesivo).",
        "Omóplatos retraídos; baja la barra al pecho medio con codos cerca del torso.",
        "Empuja a bloqueo priorizando tríceps; muñecas apiladas.",
        "No abras los codos como en press ancho; mantén el recorrido estable.",
        "Error típico: agarre demasiado estrecho que fuerza muñecas, o rebotar en el pecho.",
        "Es un híbrido pecho-tríceps: el estándar de bloqueo completo sigue aplicando.",
    ],
    "Plancha": [
        "Antebrazos o manos bajo los hombros; cuerpo en línea desde nuca hasta talones.",
        "Activa abdomen y glúteos; pelvis neutra (ni hundir lumbar ni elevar cadera en pico).",
        "Hombros lejos de las orejas; mirada al suelo; respira de forma continua.",
        "Mantén el tiempo objetivo sin perder la línea. Si tiemblas, reduce tiempo y suma series.",
        "Error típico: cadera caída (lumbar cargada) o cadera muy alta (dejas de trabajar core).",
        "Progresión: plancha alta → antebrazos → elevación de pie → lastre en espalda.",
    ],
    "Crunch": [
        "Tumbado, rodillas flexionadas, lumbar apoyada; manos junto a sienes (no tires del cuello).",
        "Enrolla costillas hacia pelvis; omóplatos despegan poco del suelo.",
        "Aprieta abdomen arriba 1 s; baja controlado sin soltar del todo la tensión.",
        "No uses impulso de cadera ni tireones de cabeza.",
        "Error típico: crunch de cuello. Piensa «acortar distancia costillas-cadera».",
        "Rango corto y calidad > muchas reps con balanceo.",
    ],
    "Elevación de piernas": [
        "Tumbado (manos bajo glúteos) o colgado; prensa la lumbar (si estás tumbado) al suelo.",
        "Eleva piernas juntas hasta ~90° o el máximo sin arquear la espalda.",
        "Baja despacio sin soltar el abdomen; no dejes caer las piernas al final.",
        "Si es difícil, flexiona ligeramente las rodillas (tuck) y progresa a piernas rectas.",
        "Error típico: usar solo flexores de cadera con lumbar arqueada.",
        "Exhala al subir; controla la bajada 3 segundos.",
    ],
    "Hip thrust": [
        "Espalda alta apoyada en el banco; barra acolchada sobre la cadera; pies al ancho de cadera.",
        "Baja la cadera con control; barbilla ligeramente metida, costillas abajo.",
        "Empuja con los talones hasta alinear hombros-cadera-rodillas; aprieta glúteos 1 s arriba.",
        "No hiperextiendas la lumbar arriba: el movimiento termina cuando la cadera está neutra-extendida.",
        "Error típico: empujar con los dedos de los pies o arching excesivo.",
        "Progresión: puente a suelo → hip thrust con mancuerna → barra.",
    ],
    "Face pull": [
        "Polea o banda a altura de cara; agarre neutro/cuerda; un paso atrás para crear tensión.",
        "Tira hacia la cara con codos altos y abiertos; separa las manos al llegar.",
        "Aprieta omóplatos y deltoides posteriores; cuello relajado.",
        "Vuelve sin dejar que los hombros se redondeen hacia delante.",
        "Error típico: convertirlo en jalón bajo o usar demasiado trapecio superior.",
        "Excelente para salud de hombro; series controladas 12–20 reps.",
    ],
    "Remo al mentón": [
        "Barra o mancuernas delante de muslos; agarre prono al ancho cómodo (no excesivamente estrecho).",
        "Tira hacia arriba guiando con los codos hasta pecho alto / clavícula.",
        "Mantén la carga cerca del cuerpo; hombros lejos de las orejas.",
        "Baja con control. Usa carga moderada: el hombro manda sobre el ego.",
        "Error típico: agarre muy estrecho + tirón hacia la cara que irrita el hombro.",
        "Si molesta, sustituye por face pull o elevaciones laterales parciales.",
    ],
    "Buenos días": [
        "Barra sobre trapecios; pies al ancho de cadera; rodillas blandas fijas.",
        "Bisagra de cadera empujando glúteos atrás; espalda plana, mirada neutra.",
        "Baja hasta sentir isquios (torso ~horizontal o un poco antes); no redondees.",
        "Extiende cadera para volver apretando glúteos; no bloquees de golpe.",
        "Error típico: flexionar demasiado las rodillas o cargar de más sin dominio de bisagra.",
        "Aprende primero con stick/banda; luego barra ligera.",
    ],
    "Hack squat": [
        "Espalda y hombros en los pads; pies al ancho cómodo en la plataforma.",
        "Desbloquea y baja en sentadilla controlada hasta profundidad segura con talones pegados.",
        "Empuja la plataforma sin despegar lumbar ni rodillas colapsadas.",
        "Casi extiende arriba sin golpe de bloqueo.",
        "Error típico: pies demasiado bajos que fuerzan rodillas, o rebotar en el fondo.",
        "Ajusta stance (más alto = más glúteo; más bajo = más cuádriceps) según objetivo.",
    ],
    "Pullover": [
        "Tumbado en banco; mancuerna a dos manos sobre el pecho, brazos casi extendidos.",
        "Baja la carga atrás en arco hasta estirar dorsal/pecho; lumbar estable.",
        "Vuelve sobre el pecho apretando dorsales; codos blandos fijos.",
        "No conviertas el movimiento en press francés (no flexiones el codo a propósito).",
        "Error típico: arquear lumbar o usar demasiado peso y perder el arco.",
        "Rango cómodo de hombro: para si sientes pinchazo anterior.",
    ],
    "Cinta / carrera": [
        "Calienta 3–5 min andando; sube velocidad de forma progresiva.",
        "Postura alta, mirada al frente, brazos relajados en oposición a las piernas.",
        "Pasos relativamente cortos bajo la cadera; aterriza suave (no talonees fuerte).",
        "Respira rítmica; mantén un ritmo donde puedas hablar frases cortas (zona aeróbica) o el intervalo pedido.",
        "Error típico: agarrarse a los laterales de la cinta o inclinación excesiva innecesaria.",
        "Enfría 2–3 min andando. Hidrátate y progresa volumen antes que velocidad.",
    ],
    "Bici estática": [
        "Ajusta sillín: rodilla casi extendida en el punto bajo del pedal, sin bloquear.",
        "Manos suaves en el manillar; pedalea «redondo» (empuja y tira).",
        "Elige resistencia que permita cadencia estable (p. ej. 80–100 rpm) según objetivo.",
        "Torso estable; no te balancees lateralmente.",
        "Error típico: sillín bajo (molestia de rodilla) o resistencia tan alta que empujas a tirones.",
        "Incluye calentamiento y enfriamiento; usa intervalos si el plan lo pide.",
    ],
    "Remo máquina": [
        "Pies fijados; agarra el mango con brazos extendidos y espalda neutra.",
        "Secuencia: empuja con piernas → bisagra de cadera → tira el mango a costillas bajas.",
        "Recupera en orden inverso: brazos → cadera → rodillas. Cadencia suave.",
        "No redondees la espalda al llegar adelante; mantén los hombros activos.",
        "Error típico: tirar solo de brazos o abrir demasiado pronto la espalda.",
        "Piensa «piernas-cadera-brazos» al remada y lo contrario al recuperar.",
    ],
    "Farmer walk": [
        "Coge las cargas, párate alto: hombros abajo y atrás, abdomen firme, mirada al frente.",
        "Camina con pasos cortos y firmes; agarre máximo sin encoger trapecios.",
        "Evita inclinarte a un lado; si una carga tira, reduce peso o distancia.",
        "Respira; no aguantes la respiración todo el trayecto.",
        "Error típico: pasos largos inestables o dejar que las cargas te desvíen la postura.",
        "Estándar: distancia o tiempo con postura neutra; deja las cargas con control.",
    ],
    "Press banca declinado": [
        "Asegura pies en el banco declinado; omóplatos retraídos, glúteos estables.",
        "Baja la barra al pecho bajo/medio con control; codos ~45°.",
        "Empuja a bloqueo sobre el pecho; no rebotes en el esternón.",
        "Rango completo y muñecas apiladas.",
        "Error típico: declinación excesiva o carga que no puedes controlar arriba.",
        "Si no tienes banco declinado, el cruce de poleas bajos puede aproximar el énfasis inferior.",
    ],
    "Cruce de poleas": [
        "Poleas altas o medias; da un paso adelante con torso estable y ligera inclinación.",
        "Brazos semi-extendidos; cierra en arco hacia el centro del pecho.",
        "Aprieta pecho al juntar las manos; vuelve abriendo hasta estirar sin arquear lumbar.",
        "Codos blandos fijos (vuelo). Exhala al cerrar.",
        "Error típico: press con flexión de codo o balanceo de tronco.",
        "Ajusta altura de poleas: altas enfatizan pecho inferior; medias, porción media.",
    ],
    "Remo sentado": [
        "Pies en la plataforma; torso erguido con ligera inclinación; agarre neutro o prono.",
        "Tira el agarre al abdomen, codos atrás, apretando omóplatos.",
        "No uses balanceo de tronco; el movimiento nace de la espalda.",
        "Extiende brazos con control manteniendo pecho alto.",
        "Error típico: encoger hombros a las orejas o tirar solo de bíceps.",
        "Pausa 1 s en contracción mejora el control escapular.",
    ],
    "Peso muerto sumo": [
        "Pies anchos, puntas afuera; barra cerca de las espinillas; agarre dentro de las piernas.",
        "Pecho alto, espalda plana; inhala y bracea. Empuja el suelo separando el suelo con los pies.",
        "Extiende rodillas y cadera juntos; barra pegada. Bloquea sin hiperextender.",
        "Baja con control manteniendo la misma postura de espalda.",
        "Error típico: empezar con cadera demasiado alta o redondear al tirar.",
        "El stance ancho pide movilidad de cadera: abre solo lo que puedas controlar.",
    ],
    "Sentadilla búlgara": [
        "Pie trasero elevado en banco; pie delantero lo bastante adelante para bajar vertical.",
        "Torso erguido; baja hasta que la rodilla trasera se acerque al suelo y el muslo delantero ~paralelo.",
        "Empuja con el pie delantero para subir; la pierna trasera estabiliza, no empuja de más.",
        "Mancuernas a los lados o goblet; mira al frente.",
        "Error típico: pie delantero demasiado cerca (rodilla viaja en exceso) o inclinarte desplomado.",
        "Haz el mismo número de reps por pierna; empieza por la pierna más débil.",
    ],
    "Curl predicador": [
        "Brazos apoyados en el pad; axilas cerca del borde superior; agarre cómodo.",
        "Curl sin despegar los brazos del apoyo; controla el tramo inferior (más difícil).",
        "No hiperextiendas del todo abajo si te molesta el codo; usa rango seguro.",
        "Sube apretando bíceps; baja 3 s.",
        "Error típico: despegar los codos del pad para hacer trampa.",
        "Ideal para aislar; carga moderada y técnica estricta.",
    ],
    "Press francés": [
        "Tumbado; barra EZ o mancuerna sobre el pecho, brazos verticales, codos apuntando al techo.",
        "Flexiona solo los codos bajando la carga hacia la frente/sien; brazos superiores quietos.",
        "Extiende a bloqueo apretando tríceps; no abras los codos hacia fuera.",
        "Exhala al extender. Controla el descenso.",
        "Error típico: mover los hombros (se vuelve pullover) o cargar de más.",
        "Si duele el codo, reduce rango o cambia a extensión en polea.",
    ],
    "Elevaciones frontales": [
        "Mancuernas delante de muslos; agarre prono o neutro; torso quieto.",
        "Eleva hasta altura de ojos con codos blandos; no balancees cadera.",
        "Baja en 2–3 s. Alterna brazos si te ayuda a controlar.",
        "Hombros lejos de las orejas; evita encoger trapecios.",
        "Error típico: peso excesivo y swing. El deltoides anterior no necesita cargas enormes.",
        "Combina con laterales y face pull para un hombro equilibrado.",
    ],
    "Ab wheel": [
        "De rodillas, rueda bajo los hombros; pelvis neutra y costillas abajo.",
        "Rueda hacia delante manteniendo el abdomen firme; solo hasta donde controles la lumbar.",
        "Vuelve tirando con el core (no solo con los hombros) hasta la posición inicial.",
        "Respira: exhala al salir, no aguantes en apnea forzada.",
        "Error típico: hundir la lumbar al final del recorrido. Acorta el rango antes que forzar.",
        "Progresión: rango corto → más largo → de pie (avanzado).",
    ],
    "Paso lateral con banda": [
        "Banda sobre rodillas o tobillos; media sentadilla con torso alto.",
        "Pasos laterales cortos sin juntar del todo los pies; tensión constante en la banda.",
        "Rodillas alineadas con las puntas; no dejes que colapsen adentro.",
        "Cambia de dirección a mitad de serie; mantén la altura de cadera estable.",
        "Error típico: enderezarte a cada paso o dar zancadas demasiado largas.",
        "Excelente activación de glúteo medio antes de sentadillas o como finisher.",
    ],
    "Remo invertido": [
        "Cuelga bajo una barra o mesa en plancha invertida: cuerpo recto, talones al suelo.",
        "Tira el pecho a la barra apretando omóplatos; codos ~45°.",
        "Baja a brazos extendidos sin hundir cadera.",
        "Cuanto más horizontal el cuerpo, más difícil; sube la barra para facilitar.",
        "Error típico: tirar solo de brazos o romper la plancha (cadera caída).",
        "Progresión sólida hacia dominadas estrictas.",
    ],
    "Press Arnold": [
        "Sentado o de pie; mancuernas a la altura de hombros con palmas hacia ti.",
        "Presiona arriba rotando las palmas hacia delante de forma fluida.",
        "Bloquea sin encoger trapecios; costillas abajo.",
        "Baja rotando de nuevo a palmas hacia ti; controla el descenso.",
        "Error típico: arching lumbar o rotación brusca con demasiado peso.",
        "Cubre bien las tres cabezas del deltoides; empieza ligero para pulir la rotación.",
    ],
    "Thruster": [
        "Barra en rack frontal: codos altos, barra en deltoides, pies al ancho de sentadilla.",
        "Baja a sentadilla frontal completa manteniendo torso alto y talones abajo.",
        "Al subir, extiende cadera y rodillas; enlaza el press overhead sin dejar la barra parada en los hombros.",
        "Bloquea overhead con brazos extendidos y cabeza a través; vuelve a rack para la siguiente rep.",
        "Error típico: press prematuro (antes de extender cadera) o perder el rack en el fondo.",
        "En series largas prioriza profundidad y bloqueo consistentes sobre la velocidad.",
    ],
    "Cluster": [
        "Cargada hasta rack frontal estable (codos altos).",
        "Sin demorar, sentadilla frontal y thruster a overhead en un solo enlace.",
        "Bloquea arriba con brazos extendidos; baja a rack o suelo según el WOD.",
        "Mantén la barra cerca en el tirón; no te separes en el thruster.",
        "Error típico: pausas largas entre clean y thruster, o sentadilla corta.",
        "Domina clean y thruster por separado antes de enlazarlos a alta intensidad.",
    ],
    "Burpee": [
        "Manos al suelo y cuerpo a plancha; pecho y muslos tocan el suelo.",
        "Salta los pies hacia las manos hasta una cuclilla con pecho alto.",
        "Extiende cadera y salta con palmada (o el estándar pedido) por encima de la cabeza.",
        "Aterriza suave y encadena sin colapsar la lumbar en la plancha.",
        "Error típico: no tocar pecho/muslos, o saltar sin extensión de cadera.",
        "Respira en la plancha; no sacrifiques el rango por velocidad.",
    ],
    "Wall ball": [
        "Balón al pecho, pies de sentadilla, cara a la diana.",
        "Sentadilla completa con el balón pegado al pecho.",
        "Al subir, extiende cadera y lanza a la diana; recibe amortiguando.",
        "Encadena la siguiente sentadilla sin pausar el balón caído.",
        "Error típico: sentadilla corta o lanzar solo con brazos.",
        "Elige peso y altura que permitan mecánica limpia bajo fatiga.",
    ],
    "Arrancada": [
        "Setup: barra sobre mediopié, agarre ancho, cadera sobre rodillas, espalda plana.",
        "Primer tirón: empuja el suelo hasta rodillas con la barra pegada; torso aún inclinado.",
        "Segundo tirón: extiende cadera/rodillas/tobillos; los brazos terminan el encogimiento.",
        "Pasa bajo la barra a squat overhead (o power) y bloquea; levántate a pie.",
        "Error típico: tirar temprano de brazos o alejar la barra del cuerpo.",
        "Aprende con stick y hang snatch; movilidad overhead y de tobillo suelen limitar.",
    ],
    "Cargada": [
        "Setup: agarre al ancho de hombros, barra sobre mediopié, espalda tensa.",
        "Tirón con barra cerca; extiende cadera y encoge hacia el rack frontal.",
        "Recibe en squat (o power) con codos altos; párate a extensión completa.",
        "Baja o suelta la barra según el contexto.",
        "Error típico: codos bajos en la recepción o profundidad incompleta.",
        "Si el rack se cae, no subas kilos: trabaja movilidad de front rack.",
    ],
    "Cargada y envión": [
        "Cargada a rack frontal estable; recompón la respiración si hace falta.",
        "Dip corto vertical, drive y jerk (split o power) a overhead.",
        "Bloquea con brazos extendidos; recupera los pies en línea y demuestra control.",
        "Baja a hombros o suelo según la norma.",
        "Error típico: dip hacia delante o recepción con pies inestables.",
        "Entrena push press y footwork de jerk aparte del clean.",
    ],
    "Split jerk": [
        "Desde front rack: dip corto, drive y split delante/atrás.",
        "Recibe overhead con brazos bloqueados; rodilla delantera ~vertical.",
        "Recupera pie delantero y luego el trasero, barra aún arriba.",
        "Demuestra estabilidad antes de bajar la barra.",
        "Error típico: split mal medido o codos blandos.",
        "Practica footwork sin barra antes de cargar.",
    ],
    "Overhead squat": [
        "Barra bloqueada overhead, agarre ancho, hombros activos.",
        "Baja a squat profundo con la barra sobre mediopié; torso vertical.",
        "Rodillas alineadas con pies; talones abajo.",
        "Sube sin perder el bloqueo; termina de pie con control.",
        "Error típico: barra que se adelanta por falta de movilidad o core flojo.",
        "Usa stick/barra ligera hasta que el fondo sea estable.",
    ],
    "Muscle-up barra": [
        "Cuelga muerto; kip o tirón estricto llevando la cadera a la barra.",
        "Transición: pecho sobre la barra y muñecas a soporte.",
        "Fondos hasta bloqueo completo sobre la barra.",
        "Baja a hang con control; marca tirón, transición y fondo.",
        "Error típico: intentar la transición sin altura de tirón.",
        "Progresión: dominadas explosivas → C2B → drills de transición.",
    ],
    "Muscle-up anillas": [
        "False grip si puedes; anillas estables y hombros activos.",
        "Tirón alto al pecho y transición a soporte (anillas a las caderas).",
        "Fondos a bloqueo con anillas cerca del cuerpo.",
        "Baja a hang con control.",
        "Error típico: abrir anillas en la transición o cortar el fondo.",
        "Domina soporte y fondos en anillas antes del muscle-up.",
    ],
    "Chest to bar": [
        "Cuelga prono, hombros activos; kip o tirón estricto según el estándar.",
        "Tira hasta que el pecho contacte la barra (no solo la barbilla).",
        "Baja a extensión completa entre reps si se exige.",
        "Piernas juntas; no cortes el contacto.",
        "Error típico: contar chin-over-bar como C2B.",
        "Si no llegas, usa banda o drills de tirón alto.",
    ],
    "Turkish get-up": [
        "Tumbado; carga en un brazo bloqueado vertical; mirada a la carga.",
        "Secuencia: codo → mano → cadera alta → rodilla → pie → de pie, brazo siempre extendido.",
        "Cada transición lenta y estable; empuja la carga al techo.",
        "Invierte los pasos para tumbarte; cambia de lado.",
        "Error típico: apresurar y perder la verticalidad.",
        "Aprende sin peso o con un objeto ligero en la palma.",
    ],
    "HSPU": [
        "Pino a pared (o libre): manos al ancho de hombros, cuerpo hueco.",
        "Baja hasta que la cabeza toque el suelo (o el déficit pedido).",
        "Empuja a bloqueo completo; orejas entre los brazos.",
        "Evita el banana excesivo de lumbar.",
        "Error típico: rango corto o codos muy abiertos.",
        "Progresión: pike push-up → caja → pared → déficit.",
    ],
    "Toes to bar": [
        "Cuelga con hombros activos; kip arch-hollow o elevación estricta.",
        "Pike hasta tocar la barra con ambos pies.",
        "Baja a hang con control; no sueltes el agarre.",
        "Brazos largos; el movimiento nace de cadera y core.",
        "Error típico: un solo pie o swing sin contacto.",
        "Progresión: knees-to-chest → knees-to-elbows → T2B.",
    ],
    "GHD sit-up": [
        "Caderas sobre el pad del GHD; pies fijados en rodillos.",
        "Baja el torso atrás con control hasta el rango pedido.",
        "Sube hasta pasar la horizontal y tocar pies/marca.",
        "Sin rebote al fondo; controla la lumbar.",
        "Error típico: solo psoas con rango inseguro o máquina mal ajustada.",
        "Empieza con rango parcial: es un movimiento exigente.",
    ],
    "Rope climb": [
        "Salta y agarra la cuerda alto; eleva rodillas.",
        "Enrola piernas (J-hook/wrap) y estira el cuerpo para subir.",
        "Reagarra más arriba; cuerda cerca del cuerpo.",
        "Baja tramo a tramo; no te sueltes en caída libre.",
        "Error típico: solo brazos sin lock de piernas.",
        "Practica el wrap a poca altura antes de la marca.",
    ],
    "Salto al cajón": [
        "Pies al ancho de cadera; flexiona cargando brazos atrás.",
        "Salta al cajón; aterriza con ambos pies completos y cadera extendida arriba.",
        "Baja paso a paso o salta abajo según el WOD; absorbe suave.",
        "Altura que permita aterrizaje silencioso y estable.",
        "Error típico: media planta en el cajón o rodillas que colapsan.",
        "Progresión: step-up → cajón bajo → altura objetivo.",
    ],
    "Box jump over": [
        "Salta pasando al otro lado del cajón (encima y abajo, o por encima), según el estándar.",
        "Aterriza suave al otro lado; date la vuelta y repite.",
        "No rasques el cajón con las espinillas: elige altura realista.",
        "Bajo fatiga prioriza aterrizajes seguros.",
        "Error típico: contar un salto que no supera claramente el cajón.",
        "Misma mecánica de extensión de cadera que el box jump.",
    ],
    "Devil press": [
        "Pecho al suelo entre las mancuernas (burpee).",
        "Salta a cuclillas agarrando las mancuernas; espalda plana.",
        "Snatch ambas a overhead en un movimiento con bloqueo.",
        "Baja y encadena; abdomen firme en el snatch.",
        "Error típico: no tocar pecho, o clean+press lento cuando se pide snatch.",
        "Cargas que permitan snatch con hombros sanos.",
    ],
    "Snatch kettlebell": [
        "KB entre los pies; bisagra y hike pass atrás.",
        "Extiende cadera y guía la KB cerca del cuerpo hasta overhead.",
        "Bloquea el brazo con hombro activo; KB sobre el antebrazo.",
        "Baja a hang o swing; cambia de mano si se pide.",
        "Error típico: press lento desde el hombro o arco lumbar al bloquear.",
        "Aprende swing y clean de KB antes del snatch.",
    ],
    "Fondos en anillas": [
        "Soporte: brazos bloqueados, anillas junto a caderas, hombros abajo.",
        "Baja hasta hombros por debajo de los codos (o el estándar), anillas estables.",
        "Empuja a soporte bloqueado sin abrir las anillas.",
        "Cuerpo hueco; sin balanceo de piernas.",
        "Error típico: anillas abiertas o rango corto.",
        "Progresión: soporte → negativos → fondos → lastre.",
    ],
    "Fondos en paralelas": [
        "Soporte en paralelas, brazos extendidos, hombros bajos.",
        "Baja a ~90° de codo (o hombros a altura de codos).",
        "Empuja a bloqueo completo.",
        "Piernas quietas; descenso controlado.",
        "Error típico: encoger trapecios o rebotar abajo.",
        "Añade lastre solo con bloqueo sólido.",
    ],
    "Wall walk": [
        "Desde plancha con pies a la pared, camina con las manos hacia la pared.",
        "Llega a pecho cerca de la pared / pino según el estándar.",
        "Desciende caminando con las manos hasta la plancha.",
        "Abdomen y glúteos activos; no dejes caer la cadera.",
        "Error típico: manos muy abiertas o arco excesivo.",
        "Marca una línea en el suelo para profundidad consistente.",
    ],
    "Burpee pull-up": [
        "Burpee bajo la barra: pecho al suelo y vuelta a pie.",
        "Salta a la barra y cuelga con brazos extendidos si se exige.",
        "Dominada con barbilla sobre la barra.",
        "Baja y encadena el siguiente burpee.",
        "Error típico: hang incompleto o barbilla corta.",
        "Barra a altura que permita salto seguro.",
    ],
    "Cargada colgante": [
        "Barra en hang (muslos): espalda plana, brazos largos, abdomen firme.",
        "Bisagra ligera y tirón: extiende cadera hacia rack frontal.",
        "Recibe con codos altos y párate a extensión completa.",
        "Devuelve la barra al hang con control.",
        "Error típico: hang demasiado alto o recepción con torso desplomado.",
        "El hang enseña el segundo tirón: barra pegada al cuerpo.",
    ],
}


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def coach_for(name: str, desc: str) -> list[str]:
    if name in COACH:
        return COACH[name]
    d = desc.rstrip(".")
    return [
        f"Posición inicial de {name}: coloca pies, agarre y puntos de apoyo antes de añadir intensidad. Si no conoces el movimiento, haz 2–3 reps de ensayo sin fatiga.",
        f"Intención: {d}. Visualiza el inicio y el final de cada repetición (bloqueo, contacto o profundidad) antes de empezar la serie.",
        "Bracea el abdomen y organiza hombros/cadera. Inicia el movimiento con el patrón correcto; evita atajos de impulso salvo que el ejercicio sea kipping o pliométrico a propósito.",
        "Ejecuta el rango completo con tempo controlado en la fase difícil. Cada rep debe cumplir el mismo estándar de arriba y abajo.",
        "Error típico: acelerar y acortar el recorrido cuando aparece la fatiga. Si la forma se rompe, baja carga, altura o usa asistencia y termina la serie limpia.",
        "Criterio de calidad (principiante y avanzado): repeticiones repetibles y estables. La carga o la velocidad solo suben cuando puedes mantener ese estándar.",
    ]


def main() -> None:
    phases = json.loads(Path("/tmp/gymbro_phases.json").read_text())
    cs = CS.read_text()
    # descriptions
    a = cs.find("private static let spanishByName")
    b = cs.find("private static let spanishInstructions")
    descs = dict(re.findall(r'"([^"]+)":\s*"((?:[^"\\]|\\.)*)"', cs[a:b]))

    names = list(phases.keys())
    assert len(names) == 188

    new_instr: dict[str, list[str]] = {}
    for name in names:
        old = phases[name]
        n_phase = CAROUSEL.get(name, 0)
        if n_phase:
            if len(old) < n_phase:
                raise SystemExit(f"{name}: need {n_phase} phases, have {len(old)}")
            phase = old[:n_phase]
            coach = coach_for(name, descs.get(name, name))
            new_instr[name] = phase + coach
        else:
            # Replace thin steps entirely with coaching
            new_instr[name] = coach_for(name, descs.get(name, name))

    # rebuild instructions dict in file
    head = cs[:b]
    # keep comment before spanishInstructions if present
    # find comment block just before spanishInstructions
    comment_start = cs.rfind("// Si un ejercicio tiene arte", 0, b)
    if comment_start >= 0:
        head = cs[:comment_start]

    lines = [
        "    // Si un ejercicio tiene arte `base_1…N`, los N primeros textos son captions de fase del carrusel;",
        "    // a continuación van los pasos de coaching («Cómo hacerlo»).",
        "    private static let spanishInstructions: [String: [String]] = [",
    ]
    for name in names:
        lines.append(f'        "{esc(name)}": [')
        for s in new_instr[name]:
            lines.append(f'            "{esc(s)}",')
        lines.append("        ],")
    lines.append("    ]")
    lines.append("}")
    CS.write_text(head + "\n".join(lines) + "\n")

    # stats
    coach_only = [new_instr[n][CAROUSEL.get(n, 0):] for n in names]
    avg = sum(sum(len(x) for x in c) for c in coach_only) / len(coach_only)
    print(f"OK {len(names)} exercises; avg coaching chars {avg:.0f}")
    for n in ["Press banca", "Thruster", "Arrancada", "Goblet squat", "Plancha"]:
        print(n, "total steps", len(new_instr[n]), "coach", len(new_instr[n]) - CAROUSEL.get(n, 0))


if __name__ == "__main__":
    main()
