#!/usr/bin/env python3
"""Generate corrected muscle metadata + full ES instructions/descriptions for Catalog."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOMAIN = ROOT / "Packages/GymbroDomain/Sources/GymbroDomain"

# name -> (group, equipment, target, secondaryMuscles, bodyPart, primaries, secondaries, desc_es)
# instructions_es handled separately (carousel-aware)
GYM: dict[str, dict] = {
    "Press banca": dict(
        group="Pecho", eq="Barra", target="pectorals", sec=["triceps", "shoulders"],
        body="chest", prim=["chest"], sec_r=["triceps", "deltoids"],
        desc="Press de banca en banco plano: bajas la barra al pecho y la empujas a bloqueo. Pecho, hombros y tríceps.",
    ),
    "Press banca inclinada": dict(
        group="Pecho", eq="Barra", target="pectorals", sec=["triceps", "shoulders"],
        body="chest", prim=["chest"], sec_r=["triceps", "deltoids"],
        desc="Press en banco inclinado (30–45°): más énfasis en pecho alto y deltoides anterior.",
    ),
    "Press mancuernas": dict(
        group="Pecho", eq="Mancuernas", target="pectorals", sec=["triceps", "shoulders"],
        body="chest", prim=["chest"], sec_r=["triceps", "deltoids"],
        desc="Press con mancuernas en banco plano: mayor rango y estabilización que con barra.",
    ),
    "Aperturas": dict(
        group="Pecho", eq="Mancuernas", target="pectorals", sec=["shoulders", "biceps"],
        body="chest", prim=["chest"], sec_r=["deltoids", "biceps"],
        desc="Aperturas en banco inclinado: abres y cierras en arco con codos blandos para estirar y contraer el pecho.",
    ),
    "Fondos": dict(
        group="Pecho", eq="Peso corporal", target="pectorals", sec=["triceps", "shoulders", "core"],
        body="chest", prim=["chest", "triceps"], sec_r=["deltoids", "abs"],
        desc="Fondos en paralelas inclinando el torso: pecho y tríceps; más vertical = más tríceps.",
    ),
    "Dominadas": dict(
        group="Espalda", eq="Peso corporal", target="lats", sec=["biceps", "upper back", "forearms"],
        body="back", prim=["upper-back"], sec_r=["biceps", "forearm", "trapezius"],
        desc="Dominadas: tiras el pecho hacia la barra. Dorsales, bíceps y agarre.",
    ),
    "Jalón al pecho": dict(
        group="Espalda", eq="Polea", target="lats", sec=["biceps", "forearms"],
        body="back", prim=["upper-back"], sec_r=["biceps", "forearm", "trapezius"],
        desc="Jalón al pecho sentado: tiras la barra a la clavícula/pecho alto. Dorsales y espalda media.",
    ),
    "Remo con barra": dict(
        group="Espalda", eq="Barra", target="lats", sec=["upper back", "biceps", "rear deltoids", "forearms"],
        body="back", prim=["upper-back"], sec_r=["biceps", "deltoids", "forearm", "lower-back"],
        desc="Remo con barra inclinado: tiras la barra al abdomen. Espalda media/dorsal y bíceps.",
    ),
    "Remo mancuerna": dict(
        group="Espalda", eq="Mancuernas", target="lats", sec=["upper back", "biceps", "rear deltoids"],
        body="back", prim=["upper-back"], sec_r=["biceps", "deltoids", "forearm"],
        desc="Remo a una mano apoyado en banco: dorsal y espalda media con buen estiramiento.",
    ),
    "Peso muerto": dict(
        group="Espalda", eq="Barra", target="glutes", sec=["hamstrings", "lower back", "upper back", "forearms"],
        body="upper legs", prim=["gluteal", "hamstring", "lower-back"], sec_r=["upper-back", "quadriceps", "forearm", "trapezius"],
        desc="Peso muerto convencional: bisagra y extensión de cadera hasta de pie. Posterior completo y agarre.",
    ),
    "Peso muerto rumano": dict(
        group="Isquios", eq="Barra", target="hamstrings", sec=["glutes", "lower back", "forearms"],
        body="upper legs", prim=["hamstring", "gluteal"], sec_r=["lower-back", "forearm"],
        desc="Peso muerto rumano: bisagra con poca flexión de rodilla; isquios y glúteos.",
    ),
    "Sentadilla": dict(
        group="Piernas", eq="Barra", target="quads", sec=["glutes", "hamstrings", "core", "calves"],
        body="upper legs", prim=["quadriceps", "gluteal"], sec_r=["hamstring", "adductors", "abs", "calves"],
        desc="Sentadilla con barra en espalda: bajas a paralelo o más y te levantas. Cuádriceps, glúteos y core.",
    ),
    "Sentadilla frontal": dict(
        group="Piernas", eq="Barra", target="quads", sec=["glutes", "core", "upper back"],
        body="upper legs", prim=["quadriceps"], sec_r=["gluteal", "abs", "upper-back"],
        desc="Sentadilla frontal: barra en rack frontal, torso vertical; énfasis en cuádriceps.",
    ),
    "Prensa": dict(
        group="Piernas", eq="Máquina", target="quads", sec=["glutes", "hamstrings", "calves"],
        body="upper legs", prim=["quadriceps", "gluteal"], sec_r=["hamstring", "calves"],
        desc="Prensa de piernas: empujas la plataforma. Cuádriceps y glúteos con trayectoria guiada.",
    ),
    "Zancadas": dict(
        group="Piernas", eq="Mancuernas", target="quads", sec=["glutes", "hamstrings", "calves"],
        body="upper legs", prim=["quadriceps", "gluteal"], sec_r=["hamstring", "calves"],
        desc="Zancadas: paso adelante o caminando; trabajo unilateral de piernas y estabilidad.",
    ),
    "Extensión de cuádriceps": dict(
        group="Piernas", eq="Máquina", target="quads", sec=["hip flexors"],
        body="upper legs", prim=["quadriceps"], sec_r=["hip-flexors"],
        desc="Extensión de cuádriceps en máquina: aísla la cara anterior del muslo.",
    ),
    "Curl femoral": dict(
        group="Isquios", eq="Máquina", target="hamstrings", sec=["glutes", "calves"],
        body="upper legs", prim=["hamstring"], sec_r=["gluteal", "calves"],
        desc="Curl femoral en máquina: flexión de rodilla para isquiotibiales.",
    ),
    "Elevación de gemelos": dict(
        group="Gemelos", eq="Máquina", target="calves", sec=["soleus"],
        body="lower legs", prim=["calves"], sec_r=["tibialis"],
        desc="Elevación de gemelos de pie o en máquina: extensión de tobillo.",
    ),
    "Press militar": dict(
        group="Hombros", eq="Barra", target="delts", sec=["triceps", "upper chest", "core"],
        body="shoulders", prim=["deltoids"], sec_r=["triceps", "chest", "abs", "trapezius"],
        desc="Press militar de pie: empujas la barra desde hombros a overhead. Deltoides y tríceps.",
    ),
    "Elevaciones laterales": dict(
        group="Hombros", eq="Mancuernas", target="delts", sec=["trapezius"],
        body="shoulders", prim=["deltoids"], sec_r=["trapezius"],
        desc="Elevaciones laterales: aíslan el deltoides medio hasta la altura del hombro.",
    ),
    "Pájaros": dict(
        group="Hombros", eq="Mancuernas", target="rear deltoids", sec=["upper back", "rhomboids"],
        body="shoulders", prim=["deltoids"], sec_r=["upper-back", "trapezius"],
        desc="Pájaros / elevaciones posteriores: deltoides posterior y espalda alta.",
    ),
    "Curl barra": dict(
        group="Bíceps", eq="Barra", target="biceps", sec=["forearms", "brachialis"],
        body="upper arms", prim=["biceps"], sec_r=["forearm"],
        desc="Curl de bíceps con barra: flexión de codo sin balanceo de tronco.",
    ),
    "Curl mancuernas": dict(
        group="Bíceps", eq="Mancuernas", target="biceps", sec=["forearms", "brachialis"],
        body="upper arms", prim=["biceps"], sec_r=["forearm"],
        desc="Curl con mancuernas: permite rotación y mayor rango que la barra.",
    ),
    "Curl martillo": dict(
        group="Bíceps", eq="Mancuernas", target="biceps", sec=["brachialis", "forearms"],
        body="upper arms", prim=["biceps"], sec_r=["forearm"],
        desc="Curl martillo: agarre neutro; bíceps, braquial y antebrazo.",
    ),
    "Fondos en banco": dict(
        group="Tríceps", eq="Peso corporal", target="triceps", sec=["chest", "shoulders"],
        body="upper arms", prim=["triceps"], sec_r=["chest", "deltoids"],
        desc="Fondos en banco: tríceps con manos en el borde y pies al frente.",
    ),
    "Extensión tríceps polea": dict(
        group="Tríceps", eq="Polea", target="triceps", sec=["forearms", "shoulders"],
        body="upper arms", prim=["triceps"], sec_r=["forearm", "deltoids"],
        desc="Extensión de tríceps en polea alta: aísla la cara posterior del brazo.",
    ),
    "Press cerrado": dict(
        group="Tríceps", eq="Barra", target="triceps", sec=["chest", "shoulders"],
        body="upper arms", prim=["triceps", "chest"], sec_r=["deltoids"],
        desc="Press banca agarre cerrado: más énfasis en tríceps, pecho como secundario.",
    ),
    "Plancha": dict(
        group="Core", eq="Peso corporal", target="abs", sec=["obliques", "shoulders", "glutes"],
        body="waist", prim=["abs"], sec_r=["obliques", "deltoids", "gluteal"],
        desc="Plancha isométrica: cuerpo en línea, abdomen y glúteos activos.",
    ),
    "Crunch": dict(
        group="Core", eq="Peso corporal", target="abs", sec=["hip flexors"],
        body="waist", prim=["abs"], sec_r=["hip-flexors"],
        desc="Crunch: flexionas el tronco acercando costillas a pelvis sin tirar del cuello.",
    ),
    "Elevación de piernas": dict(
        group="Core", eq="Peso corporal", target="abs", sec=["hip flexors"],
        body="waist", prim=["abs"], sec_r=["hip-flexors"],
        desc="Elevación de piernas: abdominales inferiores y flexores de cadera.",
    ),
    "Hip thrust": dict(
        group="Glúteos", eq="Barra", target="glutes", sec=["hamstrings", "core"],
        body="upper legs", prim=["gluteal"], sec_r=["hamstring", "abs"],
        desc="Hip thrust: empuje de cadera con espalda en banco; glúteos como motor principal.",
    ),
    "Face pull": dict(
        group="Hombros", eq="Polea", target="rear deltoids", sec=["upper back", "rotator cuff", "trapezius"],
        body="shoulders", prim=["deltoids"], sec_r=["upper-back", "trapezius"],
        desc="Face pull: tiras hacia la cara con codos altos; deltoides posterior y estabilizadores.",
    ),
    "Remo al mentón": dict(
        group="Hombros", eq="Barra", target="delts", sec=["trapezius", "biceps", "upper back"],
        body="shoulders", prim=["deltoids", "trapezius"], sec_r=["biceps", "upper-back"],
        desc="Remo al mentón: tiras la barra hacia el pecho con codos altos; hombros y trapecio.",
    ),
    "Buenos días": dict(
        group="Isquios", eq="Barra", target="hamstrings", sec=["glutes", "lower back", "core"],
        body="upper legs", prim=["hamstring", "gluteal"], sec_r=["lower-back", "abs"],
        desc="Buenos días: bisagra de cadera con barra en espalda; isquios y lumbares.",
    ),
    "Hack squat": dict(
        group="Piernas", eq="Máquina", target="quads", sec=["glutes", "hamstrings"],
        body="upper legs", prim=["quadriceps"], sec_r=["gluteal", "hamstring"],
        desc="Hack squat: sentadilla guiada con énfasis en cuádriceps.",
    ),
    "Pullover": dict(
        group="Espalda", eq="Mancuernas", target="lats", sec=["chest", "triceps", "core"],
        body="back", prim=["upper-back"], sec_r=["chest", "triceps", "abs"],
        desc="Pullover con mancuerna: dorsales y pecho con brazos semi-extendidos.",
    ),
    "Cinta / carrera": dict(
        group="Cardio", eq=None, target="cardiovascular system", sec=["quadriceps", "hamstrings", "glutes", "calves"],
        body="cardio", prim=["quadriceps", "calves"], sec_r=["hamstring", "gluteal"],
        desc="Carrera en cinta u outdoor: cardio de piernas y resistencia.",
    ),
    "Bici estática": dict(
        group="Cardio", eq=None, target="cardiovascular system", sec=["quadriceps", "hamstrings", "glutes"],
        body="cardio", prim=["quadriceps"], sec_r=["hamstring", "gluteal", "calves"],
        desc="Bici estática: cardio de piernas con bajo impacto.",
    ),
    "Remo máquina": dict(
        group="Cardio", eq="Máquina", target="cardiovascular system", sec=["lats", "quadriceps", "hamstrings", "core"],
        body="cardio", prim=["upper-back", "quadriceps"], sec_r=["hamstring", "gluteal", "abs", "biceps"],
        desc="Remoergómetro: cardio de cuerpo completo (piernas + tirón).",
    ),
    "Farmer walk": dict(
        group="Core", eq="Mancuernas", target="forearms", sec=["core", "traps", "glutes", "calves"],
        body="full body", prim=["forearm", "abs", "trapezius"], sec_r=["gluteal", "calves", "obliques"],
        desc="Paseo del granjero: caminas erguido con carga en cada mano; agarre, core y postura.",
    ),
    "Press banca declinado": dict(
        group="Pecho", eq="Barra", target="pectorals", sec=["triceps", "shoulders"],
        body="chest", prim=["chest"], sec_r=["triceps", "deltoids"],
        desc="Press banca declinado: más énfasis en pecho inferior y tríceps.",
    ),
    "Cruce de poleas": dict(
        group="Pecho", eq="Polea", target="pectorals", sec=["shoulders", "biceps"],
        body="chest", prim=["chest"], sec_r=["deltoids", "biceps"],
        desc="Cruce de poleas: aperturas con tensión constante sobre el pecho.",
    ),
    "Remo sentado": dict(
        group="Espalda", eq="Polea", target="lats", sec=["upper back", "biceps", "rear deltoids"],
        body="back", prim=["upper-back"], sec_r=["biceps", "deltoids", "forearm"],
        desc="Remo sentado en polea: espalda media y dorsales con torso estable.",
    ),
    "Peso muerto sumo": dict(
        group="Piernas", eq="Barra", target="glutes", sec=["quadriceps", "hamstrings", "adductors", "upper back"],
        body="upper legs", prim=["gluteal", "quadriceps", "adductors"], sec_r=["hamstring", "upper-back", "trapezius"],
        desc="Peso muerto sumo: stance ancho; glúteos, aductores y cuádriceps.",
    ),
    "Sentadilla búlgara": dict(
        group="Piernas", eq="Mancuernas", target="quads", sec=["glutes", "hamstrings", "core"],
        body="upper legs", prim=["quadriceps", "gluteal"], sec_r=["hamstring", "abs"],
        desc="Sentadilla búlgara: pierna trasera elevada; cuádriceps y glúteo de la pierna delantera.",
    ),
    "Curl predicador": dict(
        group="Bíceps", eq="Barra", target="biceps", sec=["forearms", "brachialis"],
        body="upper arms", prim=["biceps"], sec_r=["forearm"],
        desc="Curl predicador: bíceps con brazos apoyados; menos trampa de balanceo.",
    ),
    "Press francés": dict(
        group="Tríceps", eq="Barra", target="triceps", sec=["forearms", "shoulders"],
        body="upper arms", prim=["triceps"], sec_r=["forearm", "deltoids"],
        desc="Press francés / skull crusher: extensión de tríceps tumbado.",
    ),
    "Elevaciones frontales": dict(
        group="Hombros", eq="Mancuernas", target="delts", sec=["upper chest", "traps"],
        body="shoulders", prim=["deltoids"], sec_r=["chest", "trapezius"],
        desc="Elevaciones frontales: deltoides anterior hasta la altura de los ojos.",
    ),
    "Ab wheel": dict(
        group="Core", eq="Peso corporal", target="abs", sec=["lats", "shoulders", "hip flexors"],
        body="waist", prim=["abs"], sec_r=["obliques", "upper-back", "deltoids", "hip-flexors"],
        desc="Rueda abdominal: rollout de core manteniendo pelvis neutra.",
    ),
    "Paso lateral con banda": dict(
        group="Glúteos", eq=None, target="glutes", sec=["abductors", "core"],
        body="upper legs", prim=["gluteal"], sec_r=["abs", "obliques"],
        desc="Pasos laterales con banda: glúteo medio y estabilidad de cadera.",
    ),
    "Remo invertido": dict(
        group="Espalda", eq="Peso corporal", target="upper back", sec=["lats", "biceps", "core"],
        body="back", prim=["upper-back"], sec_r=["biceps", "abs"],
        desc="Remo invertido: remo con peso corporal bajo una barra o mesa.",
    ),
    "Press Arnold": dict(
        group="Hombros", eq="Mancuernas", target="delts", sec=["triceps", "upper chest"],
        body="shoulders", prim=["deltoids"], sec_r=["triceps", "chest"],
        desc="Press Arnold: press con rotación de mancuernas; las tres cabezas del hombro.",
    ),
}

# Default ES steps for non-carousel (4 cues). Carousel names keep existing captions.
DEFAULT_STEPS: dict[str, list[str]] = {
    "Press mancuernas": [
        "Túmbate en banco plano, pies firmes, mancuernas a los lados del pecho.",
        "Muñecas sobre los codos; omóplatos retraídos.",
        "Empuja arriba juntando ligeramente las mancuernas sin chocarlas.",
        "Baja controlado hasta estirar el pecho; no abras los codos en exceso.",
    ],
    "Fondos": [
        "Agarra las paralelas y súbete a soporte con brazos bloqueados.",
        "Inclina el torso ligeramente adelante y baja hasta ~90° de codo.",
        "Empuja a bloqueo sin encoger trapecios ni balancear piernas.",
        "Si buscas más pecho, inclina más; más vertical = más tríceps.",
    ],
    "Jalón al pecho": [
        "Siéntate con muslos fijados; agarre prono un poco más ancho que hombros.",
        "Inicia el tirón llevando los codos abajo y atrás.",
        "Lleva la barra a pecho alto / clavícula sin balancear el tronco.",
        "Extiende los brazos con control manteniendo tensión en dorsales.",
    ],
    "Remo con barra": [
        "Bisagra de cadera, espalda plana, barra colgando a brazos extendidos.",
        "Tira la barra hacia el ombligo / abdomen bajo, codos cerca del cuerpo.",
        "Aprieta omóplatos un segundo arriba.",
        "Baja sin redondear la lumbar; no uses impulso de cadera excesivo.",
    ],
    "Remo mancuerna": [
        "Apoya una rodilla y una mano en el banco; tronco casi paralelo.",
        "Mancuerna colgando a brazo largo; omóplato activo.",
        "Tira el codo hacia la cadera hasta la costilla.",
        "Baja con control y cambia de lado al terminar la serie.",
    ],
    "Prensa": [
        "Espalda y pelvis pegadas al respaldo; pies al ancho de hombros en la plataforma.",
        "Baja flexionando rodillas sin despegar la lumbar.",
        "Empuja hasta casi extender sin bloquear de golpe las rodillas.",
        "Controla el descenso; no dejes que la plataforma te aplaste el pecho.",
    ],
    "Extensión de cuádriceps": [
        "Ajusta el rodillo sobre la tibia distal; espalda apoyada.",
        "Extiende las rodillas hasta casi bloqueo sin arquear la lumbar.",
        "Pausa breve arriba apretando cuádriceps.",
        "Baja despacio hasta el rango cómodo; no rebotes abajo.",
    ],
    "Curl femoral": [
        "Ajusta almohadillas; cadera estable en la máquina.",
        "Flexiona rodillas llevando el rodillo hacia los glúteos.",
        "Aprieta isquios arriba sin levantar la pelvis.",
        "Extiende con control hasta casi estirar.",
    ],
    "Elevación de gemelos": [
        "Antepié en el borde o plataforma; tobillos libres.",
        "Sube lo más alto posible sobre las puntas.",
        "Pausa arriba; baja talones por debajo del nivel del apoyo.",
        "Rodillas casi extendidas (de pie) o flexionadas (sentado/sóleo).",
    ],
    "Elevaciones laterales": [
        "Mancuernas a los lados, codos blandos, torso quieto.",
        "Eleva en arco hasta ~altura de hombros, meñiques ligeramente arriba.",
        "No encogas trapecios ni balancees el cuerpo.",
        "Baja en 2–3 segundos manteniendo tensión.",
    ],
    "Pájaros": [
        "Inclina el torso o tumba boca abajo; mancuernas colgando.",
        "Abre los brazos en cruz con codos blandos, apretando omóplatos.",
        "Llega a la línea de los hombros sin hiperextender la lumbar.",
        "Baja controlado; prioriza deltoides posterior, no el peso.",
    ],
    "Curl barra": [
        "Agarre supino al ancho de hombros; codos pegados al torso.",
        "Sube la barra sin balancear cadera ni hombros.",
        "Aprieta bíceps arriba; muñecas neutras.",
        "Baja hasta casi extender sin soltar tensión.",
    ],
    "Curl mancuernas": [
        "Mancuernas a los lados, palmas al frente o semi-supinación.",
        "Curl sin balanceo; codos fijos junto a las costillas.",
        "Opcional: rota la palma arriba al subir (supinación).",
        "Baja controlado y alterna o haz ambas a la vez.",
    ],
    "Curl martillo": [
        "Agarre neutro (palmas mirándose); codos quietos.",
        "Sube las mancuernas hacia el hombro sin abrir los codos.",
        "Pausa breve arriba.",
        "Baja lento; trabaja braquial y antebrazo además del bíceps.",
    ],
    "Fondos en banco": [
        "Manos en el borde del banco, dedos al frente; glúteos cerca del banco.",
        "Baja flexionando codos hasta ~90° con hombros bajos.",
        "Empuja a extensión sin encoger el cuello.",
        "Mantén el pecho abierto; no te alejes demasiado del banco.",
    ],
    "Extensión tríceps polea": [
        "Codos pegados al cuerpo, antebrazos paralelos al suelo al inicio.",
        "Extiende solo el codo llevando la barra/cuerda abajo.",
        "Aprieta tríceps abajo; no muevas hombros ni tronco.",
        "Vuelve con control hasta el estiramiento cómodo.",
    ],
    "Press cerrado": [
        "Banco plano; agarre al ancho de hombros o un poco más estrecho.",
        "Baja la barra al pecho medio con codos cerca del cuerpo.",
        "Empuja a bloqueo priorizando tríceps.",
        "No abras los codos como en press ancho.",
    ],
    "Plancha": [
        "Antebrazos o manos bajo hombros; cuerpo en línea recta.",
        "Activa abdomen y glúteos; pelvis neutra (sin hundir lumbar).",
        "Mirada al suelo; hombros lejos de las orejas.",
        "Respira y mantén el tiempo objetivo sin elevar cadera.",
    ],
    "Crunch": [
        "Tumbado, rodillas flexionadas, lumbar apoyada.",
        "Manos junto a sienes (no tires del cuello).",
        "Enrolla costillas hacia pelvis; omóplatos despegan poco.",
        "Baja controlado; no uses impulso de cadera.",
    ],
    "Elevación de piernas": [
        "Tumbado o colgado; lumbar estable (presiona el suelo si estás tumbado).",
        "Eleva piernas juntas hasta ~90° o el rango sin arquear.",
        "Baja despacio sin soltar el abdomen.",
        "Si es difícil, flexiona ligeramente las rodillas.",
    ],
    "Face pull": [
        "Polea o banda a altura de cara; agarre neutro/cuerda.",
        "Tira hacia la cara con codos altos y abiertos.",
        "Separa las manos al llegar; aprieta omóplatos y deltoides posterior.",
        "Vuelve sin dejar que los hombros se redondeen.",
    ],
    "Remo al mentón": [
        "Barra o mancuernas delante de muslos; agarre prono.",
        "Tira hacia arriba guiando con los codos hasta pecho alto.",
        "Mantén la barra cerca del cuerpo; no encogas orejas.",
        "Baja controlado; usa carga moderada por el hombro.",
    ],
    "Buenos días": [
        "Barra sobre trapecios; pies al ancho de cadera.",
        "Bisagra de cadera empujando glúteos atrás, rodillas blandas.",
        "Baja hasta sentir isquios; espalda plana.",
        "Extiende cadera para volver; no redondees la lumbar.",
    ],
    "Hack squat": [
        "Espalda y hombros en los pads; pies al ancho cómodo.",
        "Baja en sentadilla controlada hasta profundidad segura.",
        "Empuja la plataforma sin despegar talones ni lumbar.",
        "No bloquees rodillas de golpe arriba.",
    ],
    "Pullover": [
        "Tumbado, mancuerna a dos manos sobre el pecho.",
        "Brazos casi extendidos; baja la carga atrás en arco.",
        "Siente el estiramiento en dorsal/pecho; no arquees lumbar.",
        "Vuelve sobre el pecho apretando dorsales.",
    ],
    "Cinta / carrera": [
        "Calienta caminando; sube velocidad de forma progresiva.",
        "Postura alta, mirada al frente, brazos relajados.",
        "Pasos cortos bajo la cadera; aterriza suave.",
        "Enfría 2–3 min andando al terminar.",
    ],
    "Bici estática": [
        "Ajusta sillín: rodilla casi extendida abajo del pedal.",
        "Pedalea redondo; torso estable, hombros relajados.",
        "Elige resistencia que permita ritmo constante.",
        "Incluye calentamiento y enfriamiento de 2–3 min.",
    ],
    "Remo máquina": [
        "Pies fijados; inicia el remada con empuje de piernas.",
        "Luego bisagra y tira el mango a costillas bajas.",
        "Recupera en orden inverso: brazos, cadera, rodillas.",
        "Cadencia suave; no redondees la espalda al llegar adelante.",
    ],
    "Farmer walk": [
        "Coge las cargas, párate alto, hombros abajo y atrás.",
        "Camina con pasos cortos y firmes; mirada al frente.",
        "Evita inclinarte lateralmente; aprieta el abdomen.",
        "Deja la carga con control al terminar la distancia.",
    ],
    "Press banca declinado": [
        "Asegura pies en el banco declinado; omóplatos retraídos.",
        "Baja la barra al pecho bajo/medio con control.",
        "Empuja a bloqueo sobre el pecho.",
        "No rebotes la barra en el esternón.",
    ],
    "Cruce de poleas": [
        "Poleas altas o medias; un paso adelante, torso estable.",
        "Brazos semi-extendidos; cierra en arco hacia el centro.",
        "Aprieta pecho al juntar las manos.",
        "Abre hasta estirar sin arquear la lumbar.",
    ],
    "Remo sentado": [
        "Pies en la plataforma; torso erguido, ligera inclinación.",
        "Tira el agarre al abdomen, codos atrás.",
        "Aprieta omóplatos; no uses balanceo de tronco.",
        "Extiende brazos con control manteniendo pecho alto.",
    ],
    "Peso muerto sumo": [
        "Pies anchos, puntas afuera; barra cerca de las espinillas.",
        "Agarre dentro de las piernas; pecho alto, espalda plana.",
        "Empuja el suelo y extiende rodillas y cadera a la vez.",
        "Bloquea arriba sin hiperextender; baja con control.",
    ],
    "Curl predicador": [
        "Brazos apoyados en el banco predicador; axilas al borde.",
        "Curl sin despegar los brazos del pad.",
        "No hiperextiendas del todo abajo si te duele el codo.",
        "Sube y baja en rango controlado.",
    ],
    "Press francés": [
        "Tumbado, barra o mancuerna sobre el pecho, brazos verticales.",
        "Flexiona solo codos bajando la carga hacia la frente/sien.",
        "Extiende a bloqueo apretando tríceps.",
        "Codos apuntando al techo; no abras hacia fuera.",
    ],
    "Elevaciones frontales": [
        "Mancuernas delante de muslos, agarre prono o neutro.",
        "Eleva hasta altura de ojos con codos blandos.",
        "Torso quieto; no uses impulso de cadera.",
        "Baja en 2–3 segundos.",
    ],
    "Ab wheel": [
        "De rodillas, rueda bajo los hombros, pelvis neutra.",
        "Rueda hacia delante manteniendo costillas abajo.",
        "Ve solo hasta donde controles sin hundir la lumbar.",
        "Vuelve tirando con el abdomen, no solo con los hombros.",
    ],
    "Paso lateral con banda": [
        "Banda sobre rodillas o tobillos; media sentadilla.",
        "Pasos laterales cortos sin juntar del todo los pies.",
        "Mantén rodillas alineadas con puntas; torso alto.",
        "Cambia de dirección a mitad de serie.",
    ],
    "Remo invertido": [
        "Cuelga bajo la barra en plancha invertida, cuerpo recto.",
        "Tira el pecho a la barra apretando omóplatos.",
        "Baja a brazos extendidos sin hundir cadera.",
        "Cuanto más horizontal, más difícil.",
    ],
    "Press Arnold": [
        "Mancuernas a la altura de hombros, palmas hacia ti.",
        "Presiona arriba rotando palmas hacia delante.",
        "Bloquea sin encoger trapecios.",
        "Baja rotando de nuevo a palmas hacia ti.",
    ],
}


def sport_defaults() -> dict[str, list[str]]:
    """Generic but clear 4-step cues for CF/HL/GY when no override exists."""
    return {}


def load_existing_es():
    instr = json.loads(Path("/tmp/gymbro_es_instr.json").read_text())
    desc = json.loads(Path("/tmp/gymbro_es_desc.json").read_text())
    return desc, instr


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


# Extra ES descriptions + steps for sport movements (name -> (desc, steps))
SPORT_ES: dict[str, tuple[str, list[str]]] = {}


def build_sport_es():
    # CrossFit-ish
    pairs = {
        "Thruster": ("Front squat + press en un solo movimiento continuo.", None),
        "Thruster mancuernas": ("Thruster con mancuernas en rack frontal.", [
            "Mancuernas en hombros, codos altos.",
            "Baja a sentadilla profunda manteniendo el torso alto.",
            "Al subir, extiende cadera y press overhead en un solo tiempo.",
            "Baja las mancuernas a rack y repite.",
        ]),
        "Thruster kettlebell": ("Thruster con una o dos kettlebells en rack.", [
            "KB en rack frontal pegadas al pecho.",
            "Sentadilla completa con codos altos.",
            "Extiende y press overhead hasta bloqueo.",
            "Recibe de nuevo en rack con control.",
        ]),
        "Cluster": ("Clean a rack + thruster (cargada y envío overhead).", [
            "Cargada desde suelo o hang hasta rack frontal.",
            "Sin pausa larga, squat y press overhead (thruster).",
            "Bloquea arriba con brazos extendidos.",
            "Baja según el estándar del WOD.",
        ]),
        "Ground to overhead": ("Cualquier forma legal de llevar la carga del suelo a overhead.", [
            "Elige snatch o clean + jerk/press según carga y WOD.",
            "Mantén la barra cerca del cuerpo en el tirón.",
            "Bloquea overhead con hombros activos.",
            "Baja con control a hombros o suelo.",
        ]),
        "Plate ground to overhead": ("Disco del suelo a overhead.", [
            "Agarra el disco por los bordes con agarre firme.",
            "Llévalo a hombros o snatch directo overhead.",
            "Bloquea con brazos extendidos y torso estable.",
            "Baja el disco con control.",
        ]),
        "Burpee al cajón": ("Burpee completo terminado en salto al cajón.", [
            "Pecho y muslos al suelo.",
            "Salta pies a manos y ponte de pie.",
            "Salta al cajón y extiende cadera arriba.",
            "Baja del cajón y repite.",
        ]),
        "Bar facing burpee": ("Burpee de cara a la barra, a menudo saltando sobre ella.", [
            "Pecho al suelo mirando la barra.",
            "Salta a pies y prepárate para el salto.",
            "Salta lateral o sobre la barra según el WOD.",
            "Aterriza estable y repite.",
        ]),
        "Step-up al cajón": ("Subida al cajón paso a paso.", [
            "Pie completo sobre el cajón.",
            "Empuja con la pierna de apoyo hasta extender cadera.",
            "Sube el otro pie; párate alto.",
            "Baja controlado y alterna piernas si se pide.",
        ]),
        "Broad jump": ("Salto horizontal a máxima distancia.", [
            "Flexiona cadera y rodillas cargando brazos atrás.",
            "Extiende potente y salta hacia delante.",
            "Aterriza con soft knees y control.",
            "Resetea la postura antes del siguiente salto.",
        ]),
        "Walking lunge": ("Zancadas caminando en línea.", [
            "Paso largo adelante bajando la rodilla trasera.",
            "Torso alto; rodilla delantera sobre el mediopié.",
            "Empuja para el siguiente paso sin arrastrar pies.",
            "Mantén pasos simétricos a izquierda y derecha.",
        ]),
        "Bear crawl": ("Desplazamiento a cuatro puntos con rodillas elevadas.", [
            "Manos bajo hombros, rodillas bajo cadera y un poco elevadas.",
            "Avanza mano y pie opuestos a la vez.",
            "Cadera baja y estable; no balancees el trasero.",
            "Mantén respiración constante.",
        ]),
        "Swing kettlebell": ("Swing ruso: bisagra hasta altura de pecho/ojos.", [
            "KB entre pies; bisagra y hike pass atrás.",
            "Extiende cadera en seco; brazos relajados.",
            "La KB flota hasta pecho/ojos; no hagas squat.",
            "Deja que vuelva atrás entre las piernas y repite.",
        ]),
        "Swing americano": ("Swing hasta overhead completo.", [
            "Misma bisagra que el ruso, con más potencia de cadera.",
            "La KB termina bloqueada overhead (brazos junto a orejas).",
            "Baja por el mismo arco sin arquear lumbar.",
            "Mantén costillas abajo en el bloqueo.",
        ]),
        "Clean kettlebell": ("Kettlebell a rack frontal.", [
            "Tira la KB cerca del cuerpo.",
            "Pasa el codo y recibe en rack (KB apoyada en antebrazo).",
            "Párate alto con torso firme.",
            "Baja a hang o suelo según el WOD.",
        ]),
        "Goblet squat": ("Sentadilla con KB/DB pegada al pecho.", [
            "Sujeta la carga contra el pecho, codos abajo.",
            "Baja entre las rodillas con torso alto.",
            "Profundidad cómoda manteniendo talones.",
            "Empuja el suelo para levantarte.",
        ]),
        "Man maker": ("Remo + flexión + clean y press con mancuernas.", [
            "En plancha, remo una mancuerna y luego la otra.",
            "Haz una flexión.",
            "Salta a clean y press overhead.",
            "Baja a plancha y repite con control.",
        ]),
        "Snatch mancuerna": ("Arrancada con mancuerna a overhead en un tiempo.", [
            "Mancuerna entre pies; tirón potente cerca del cuerpo.",
            "Pasa bajo la carga a bloqueo overhead.",
            "Párate estable con brazo extendido.",
            "Baja a hombro o suelo según el estándar.",
        ]),
        "Clean mancuerna": ("Cargada de mancuerna(s) a hombros.", [
            "Tira las mancuernas hacia los hombros.",
            "Recibe en rack con codos altos.",
            "Extiende cadera y párate.",
            "Baja con control.",
        ]),
        "Ball slam": ("Golpea el balón al suelo desde overhead.", [
            "Eleva el balón overhead con brazos extendidos.",
            "Bisagra y estrella el balón al suelo con potencia.",
            "Recoge el balón sin redondear en exceso.",
            "Repite manteniendo el core activo.",
        ]),
        "Medball clean": ("Cargada con balón medicinal a hombros.", [
            "Balón en suelo; tirón y recepción en squat/rack.",
            "Balón pegado al pecho, codos altos.",
            "Párate o según el WOD.",
            "Baja el balón con control.",
        ]),
        "Sandbag clean": ("Cargada de saco a hombros o abrazo.", [
            "Agarra el saco; tira cerca del cuerpo.",
            "Recibe en abrazo o a hombros.",
            "Extiende cadera y párate estable.",
            "Suelta o baja según el WOD.",
        ]),
        "Sandbag over shoulder": ("Saco del suelo a pasar sobre un hombro.", [
            "Agarra el saco y tira hacia la cadera.",
            "Extiende y carga el saco sobre un hombro.",
            "Deja que caiga al otro lado con control.",
            "Alterna hombros si se pide.",
        ]),
        "Yoke carry": ("Porte del yoke sobre trapecios caminando.", [
            "Coloca el yoke sobre trapecios y desbloquea.",
            "Camina con pasos cortos y estables.",
            "Mantén el torso rígido; no te inclines.",
            "Apoya el yoke con control al terminar.",
        ]),
        "Dobles de comba": ("Double unders: la comba pasa dos veces por salto.", [
            "Salto bajo y rápido; muñecas sueltas.",
            "Acelera la comba para dos pasos por salto.",
            "Mantén codos cerca del cuerpo.",
            "Si fallas, resetea el ritmo antes de seguir.",
        ]),
        "Simples de comba": ("Single unders: un paso de comba por salto.", [
            "Salto suave sobre el antepié.",
            "Un giro de comba por cada salto.",
            "Ritmo constante; hombros relajados.",
            "Respira y mantén la mirada al frente.",
        ]),
        "Triples de comba": ("Triple unders: tres pasos de comba por salto.", [
            "Salto un poco más alto que en doubles.",
            "Muñecas muy rápidas; tres giros por salto.",
            "Mantén el torso quieto.",
            "Usa solo cuando domines doubles sólidos.",
        ]),
        "Air bike": ("Bici/Assault o Echo: pedaleo + brazos.", [
            "Ajusta sillín; agarra las asas.",
            "Empuja y tira con brazos sincronizados a piernas.",
            "Elige ritmo sostenible o intervalos del WOD.",
            "Mantén torso estable; no te desplomes.",
        ]),
        "Echo bike": ("Echo bike: cardio de cuerpo completo.", [
            "Pies en pedales, manos en asas.",
            "Ciclo continuo piernas + brazos.",
            "Controla cadencia y resistencia.",
            "Enfría pedaleando suave al terminar.",
        ]),
        "SkiErg": ("SkiErg: tirones verticales de trineo.", [
            "Manos altas en las asas; core firme.",
            "Tira hacia abajo extendiendo cadera y brazos.",
            "Recupera subiendo las asas con control.",
            "Mantén ritmo parejo; no redondees la espalda.",
        ]),
        "Shuttle run": ("Carreras cortas de ida y vuelta.", [
            "Acelera en línea recta hasta la marca.",
            "Frena, toca o pivota según la regla.",
            "Vuelve al punto de inicio.",
            "Mantén cambios de dirección controlados.",
        ]),
        "Sled push": ("Empuje de trineo.", [
            "Manos en postes, cuerpo inclinado, brazos casi extendidos.",
            "Pasos cortos y potentes; empuja el suelo atrás.",
            "Mantén la cadera detrás de los hombros.",
            "No te pares entre pasos si el WOD es continuo.",
        ]),
        "Sled pull": ("Tirón de trineo con cuerda o arnés.", [
            "Cuerda hand-over-hand o marcha atrás con arnés.",
            "Tronco firme; tira con espalda y piernas.",
            "Pasos o agarres constantes.",
            "Mantén tensión en la cuerda.",
        ]),
        "Farmer carry": ("Porte de cargas a los lados caminando.", [
            "Cargas a los lados, postura alta.",
            "Pasos cortos; agarre firme.",
            "Hombros abajo; abdomen activo.",
            "Deja las cargas con control.",
        ]),
    }
    # Halterofilia / gimnasia — generic solid cues
    olympic = {
        "Arrancada": "Arrancada completa: del suelo a overhead en un tiempo, recepción en squat.",
        "Arrancada de potencia": "Arrancada recibida en semi-flexión (power), no squat profundo.",
        "Arrancada colgante": "Arrancada desde hang (barra en muslos).",
        "Arrancada colgante completa": "Hang snatch recibida en squat profundo.",
        "Hang power snatch": "Hang snatch recibida en power.",
        "Arrancada muscular": "Muscle snatch: tirón continuo sin sentadilla bajo la barra.",
        "Arrancada desde bloques": "Arrancada con barra elevada en bloques.",
        "Arrancada con pausa": "Arrancada con pausa en posición (rodilla/muslo) según indicación.",
        "Balance de arrancada": "OHS desde soportes o drop a squat overhead (snatch balance).",
        "Drop snatch": "Desde espalda, drop a squat overhead sin tirón de piernas.",
        "Tall snatch": "Snatch desde posición alta (puntillas/tall) enfatizando velocidad bajo la barra.",
        "Arrancada en split": "Recepción de arrancada en split (tijera).",
        "Tirón de arrancada": "Tirón de arrancada sin recepción overhead.",
        "Peso muerto agarre arrancada": "Peso muerto con agarre ancho de arrancada.",
        "Cargada": "Cargada completa a rack frontal en squat.",
        "Cargada de potencia": "Cargada recibida en power.",
        "Cargada colgante completa": "Hang clean a squat profundo.",
        "Hang power clean": "Hang clean a recepción power.",
        "Cargada muscular": "Muscle clean sin sentadilla bajo la barra.",
        "Cargada desde bloques": "Cargada desde bloques.",
        "Cargada con pausa": "Cargada con pausa técnica.",
        "Tall clean": "Clean desde posición tall.",
        "Tirón de cargada": "Tirón de clean sin recepción en rack.",
        "Cargada y press": "Clean + press estricto.",
        "Push press": "Dip-drive y press con impulso de piernas.",
        "Push jerk": "Jerk con recepción en semi-flexión (no split).",
        "Power jerk": "Jerk power (pies en línea).",
        "Balance de envión": "Jerk balance / práctica de recepción overhead.",
        "Strict press": "Press militar estricto sin dip de piernas.",
        "Press detrás de nuca": "Press desde nuca (movilidad de hombro requerida).",
        "Envión detrás de nuca": "Jerk desde nuca.",
        "Sots press": "Press en squat profundo (front o OH).",
        "Front rack lunge": "Zancada con barra en rack frontal.",
        "Sentadilla frontal con pausa": "Front squat con pausa abajo.",
        "Sumo high pull": "High pull con stance sumo.",
    }
    for name, desc in olympic.items():
        SPORT_ES[name] = (desc, [
            "Coloca pies y agarre según el patrón del levantamiento.",
            "Mantén la barra cerca; espalda tensa y abdomen activo.",
            "Acelera en el segundo tirón y muévete rápido bajo la barra.",
            "Recibe estable y levántate a bloqueo completo si aplica.",
        ])

    gym = {
        "Dominadas estrictas": "Dominada sin kipping: solo fuerza de tirón.",
        "Dominadas kipping": "Dominada con impulso de kip.",
        "Dominadas butterfly": "Butterfly pull-up de alta cadencia.",
        "Dominadas supinas": "Dominada con agarre supino (chin-up).",
        "Dominadas en anillas": "Dominada en anillas (inestables).",
        "Remo en anillas": "Remo invertido en anillas.",
        "Archer pull-up": "Dominada arquero: un brazo más cargado.",
        "Muscle-up estricto barra": "Muscle-up en barra sin kip.",
        "Muscle-up estricto anillas": "Muscle-up en anillas sin kip.",
        "Pull-over barra": "Pullover a soporte sobre la barra.",
        "Toes to bar estrictos": "T2B sin kip excesivo; piernas a la barra.",
        "Knees to elbows": "Rodillas a codos colgado.",
        "Toes to rings": "Pies a anillas.",
        "Hip to bar": "Cadera a la barra (kipping).",
        "Kip swing": "Balanceo de kip en barra/anillas.",
        "HSPU deficit": "HSPU con manos elevadas (deficit).",
        "HSPU libre": "HSPU sin apoyo de pared (freestanding).",
        "Pike push-up": "Flexión en pica: progresión a HSPU.",
        "Handstand hold": "Mantener pino (pared o libre).",
        "Handstand walk": "Caminar en pino.",
        "Press to handstand": "Press a pino desde soporte o suelo.",
        "Soporte en anillas": "Soporte bloqueado en anillas.",
        "False grip hang": "Cuelga en false grip (anillas).",
        "Skin the cat": "Skin the cat en anillas.",
        "German hang": "German hang: estiramiento/control en anillas.",
        "Front lever tuck": "Front lever agrupado.",
        "Back lever tuck": "Back lever agrupado.",
        "Planche tuck": "Planche tuck sobre suelo/paralelas.",
        "L-sit": "L-sit: piernas horizontales en soporte.",
        "V-sit": "V-sit: piernas más altas que L-sit.",
        "Hollow hold": "Hollow body hold isométrico.",
        "Hollow rock": "Balanceo en hollow manteniendo forma.",
        "Arch hold": "Arch/superman hold boca abajo.",
        "Candlestick": "Candlestick / shoulder stand controlado.",
        "Pistol squat": "Sentadilla a una pierna (pistol).",
        "Shrimp squat": "Shrimp squat: sentadilla unilateral con pie trasero sujeto.",
        "Cossack squat": "Sentadilla cossack lateral.",
        "Air squat": "Sentadilla sin carga.",
        "Jumping squat": "Sentadilla con salto.",
        "Jumping lunge": "Zancada con salto alterno.",
        "GHD back extension": "Extensión de espalda en GHD.",
        "Sit-up": "Sit-up completo (hombros pasan la cadera).",
        "V-up": "V-up: manos y pies se encuentran arriba.",
        "Rope climb legless": "Subida de cuerda sin piernas.",
        "Pegboard": "Pegboard: trepa con clavijas.",
    }
    for name, desc in gym.items():
        SPORT_ES[name] = (desc, [
            "Colócate en la posición inicial con hombros activos.",
            "Ejecuta el movimiento con el estándar del ejercicio (rango completo).",
            "Controla la fase excéntrica; no pierdas la tensión del core.",
            "Respira y mantén calidad antes que velocidad.",
        ])

    for name, (desc, steps) in pairs.items():
        SPORT_ES[name] = (desc, steps if steps else [
            "Adopta la postura inicial del movimiento.",
            "Ejecuta con rango completo y core firme.",
            "Bloquea o marca el estándar arriba/abajo.",
            "Repite con control según el WOD.",
        ])

    # Fill remaining CF names that have art captions already
    for name in [
        "Burpee", "Burpee pull-up", "Salto al cajón", "Box jump over", "Wall ball",
        "Devil press", "Snatch kettlebell", "Turkish get-up", "Thruster", "Cluster",
        "Chest to bar", "Muscle-up barra", "Muscle-up anillas", "Toes to bar", "HSPU",
        "Wall walk", "Fondos en anillas", "Fondos en paralelas", "Rope climb", "GHD sit-up",
        "Cargada", "Cargada colgante", "Arrancada", "Cargada y envión", "Split jerk",
        "Overhead squat", "Press banca", "Press banca inclinada", "Aperturas", "Dominadas",
        "Peso muerto", "Peso muerto rumano", "Sentadilla", "Sentadilla frontal", "Zancadas",
        "Sentadilla búlgara", "Press militar", "Hip thrust",
    ]:
        if name not in SPORT_ES and name in GYM:
            SPORT_ES[name] = (GYM[name]["desc"], None)  # type: ignore


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def swift_str_array(items: list[str]) -> str:
    if not items:
        return "[]"
    inner = ", ".join(f'"{esc(x)}"' for x in items)
    return f"[{inner}]"


def rewrite_enrichment():
    path = DOMAIN / "CatalogEnrichment.swift"
    text = path.read_text()

    def repl(match: re.Match) -> str:
        name = match.group(1)
        block = match.group(0)
        if name not in GYM:
            return block
        g = GYM[name]
        # Replace fields inside this EnrichedSeed block only
        def sub_field(key: str, value: str, src: str) -> str:
            return re.sub(rf'{key}:\s*(?:nil|"[^"]*"|true|false)', f"{key}: {value}", src, count=1)

        out = block
        out = sub_field("muscleGroup", f'"{esc(g["group"])}"', out)
        eq = "nil" if g["eq"] is None else f'"{esc(g["eq"])}"'
        out = re.sub(r"equipment:\s*(?:nil|\"[^\"]*\")", f"equipment: {eq}", out, count=1)
        out = sub_field("target", f'"{esc(g["target"])}"', out)
        out = re.sub(
            r"secondaryMuscles:\s*\[[^\]]*\]",
            f"secondaryMuscles: {swift_str_array(g['sec'])}",
            out,
            count=1,
        )
        out = sub_field("bodyPart", f'"{esc(g["body"])}"', out)
        out = sub_field("description", f'"{esc(g["desc"])}"', out)
        # Keep instructions array but replace with short EN placeholders matching ES quality
        # (CatalogSpanish overrides). Use Spanish directly so fallback is good.
        steps = DEFAULT_STEPS.get(name)
        if steps is None and name in CAROUSEL:
            # leave instructions; Spanish overlay handles display
            pass
        elif steps:
            out = re.sub(
                r"instructions:\s*\[[^\]]*\]",
                f"instructions: {swift_str_array(steps)}",
                out,
                count=1,
                flags=re.S,
            )
        out = re.sub(
            r"primaries:\s*\[[^\]]*\]",
            f"primaries: {swift_str_array(g['prim'])}",
            out,
            count=1,
        )
        out = re.sub(
            r"secondaries:\s*\[[^\]]*\]",
            f"secondaries: {swift_str_array(g['sec_r'])}",
            out,
            count=1,
        )
        return out

    new = re.sub(
        r'EnrichedSeed\(\s*name:\s*"([^"]+)"[\s\S]*?\n\s*\)',
        repl,
        text,
    )
    path.write_text(new)
    print("Updated CatalogEnrichment.swift")


def rewrite_catalog_spanish(all_names: list[str]):
    build_sport_es()
    old_desc, old_instr = load_existing_es()

    # Descriptions
    desc: dict[str, str] = {}
    for n in all_names:
        if n in GYM:
            desc[n] = GYM[n]["desc"]
        elif n in SPORT_ES:
            desc[n] = SPORT_ES[n][0]
        elif n in old_desc:
            desc[n] = old_desc[n]
        else:
            desc[n] = f"{n}: ejecuta el movimiento con rango completo, core firme y control."

    # Instructions
    instr: dict[str, list[str]] = {}
    for n in all_names:
        if n in CAROUSEL:
            # Preserve exact carousel captions
            if n not in old_instr or len(old_instr[n]) != CAROUSEL[n]:
                raise SystemExit(f"Missing carousel captions for {n}")
            instr[n] = old_instr[n]
        elif n in DEFAULT_STEPS:
            instr[n] = DEFAULT_STEPS[n]
        elif n in SPORT_ES and SPORT_ES[n][1]:
            instr[n] = SPORT_ES[n][1]
        elif n in old_instr and len(old_instr[n]) >= 3:
            instr[n] = old_instr[n]
        else:
            instr[n] = [
                f"Colócate en la posición inicial de {n.lower()}.",
                "Ejecuta el rango completo del movimiento con el abdomen activo.",
                "Marca el punto alto o bajo con control (sin rebotes).",
                "Repite priorizando la técnica sobre la velocidad.",
            ]

    # Read original file header (imports + helpers) and rebuild dicts
    path = DOMAIN / "CatalogSpanish.swift"
    original = path.read_text()
    # Keep everything before spanishByName
    head_end = original.find("private static let spanishByName")
    if head_end < 0:
        raise SystemExit("spanishByName not found")
    # Keep phrasePairs section: it's before spanishByName in current file? Check order.
    # Order: phrasePairs, spanishByName, spanishInstructions
    phrase_start = original.find("private static let phrasePairs")
    head = original[:phrase_start]

    # Extract phrasePairs block as-is
    phrase_m = re.search(
        r"private static let phrasePairs:.*?\]\n",
        original[phrase_start:],
        re.S,
    )
    phrase_block = phrase_m.group(0) if phrase_m else ""

    def emit_desc() -> str:
        lines = ["    private static let spanishByName: [String: String] = ["]
        for n in all_names:
            lines.append(f'        "{esc(n)}": "{esc(desc[n])}",')
        lines.append("    ]")
        return "\n".join(lines)

    def emit_instr() -> str:
        lines = [
            "",
            "    // Si un ejercicio tiene arte `base_1…N`, los N primeros textos describen",
            "    // la pose de cada imagen del carrusel (cues de entrenador + hitos visuales).",
            "    private static let spanishInstructions: [String: [String]] = [",
        ]
        for n in all_names:
            steps = instr[n]
            lines.append(f'        "{esc(n)}": [')
            for s in steps:
                lines.append(f'            "{esc(s)}",')
            lines.append("        ],")
        lines.append("    ]")
        return "\n".join(lines)

    # Reconstruct: head + phrasePairs + spanishByName + spanishInstructions + closing brace of enum
    # Find closing of enum CatalogSpanish
    new = head + phrase_block + "\n" + emit_desc() + "\n" + emit_instr() + "\n}\n"
    path.write_text(new)
    print(f"Updated CatalogSpanish.swift ({len(desc)} desc, {len(instr)} instr)")
    missing_car = [n for n, c in CAROUSEL.items() if len(instr[n]) != c]
    if missing_car:
        raise SystemExit(f"Carousel mismatch: {missing_car}")


def main():
    names = Path("/tmp/gymbro_all_names.txt").read_text().strip().splitlines()
    assert len(names) == 188
    rewrite_enrichment()
    rewrite_catalog_spanish(names)
    print("OK")


if __name__ == "__main__":
    main()
