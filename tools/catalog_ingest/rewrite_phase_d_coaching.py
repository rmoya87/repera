#!/usr/bin/env python3
"""Rewrite Fase D generic coaching (cómo hacerlo + músculos/equipo/desc) and emit patches.

Source of truth for apps: CatalogCrossFit.swift + CatalogSpanish.swift → seeds/JSON.
Also emits SQL for training_exercise_metadata backfill.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CF = ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/CatalogCrossFit.swift"
ES = ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/CatalogSpanish.swift"
SEED_ANDROID = ROOT / "android/mobile/src/main/assets/catalog_seed.json"
SEED_IOS = ROOT / "Apps/Repera/Resources/exercise-catalog.json"
OUT = ROOT / "tools/catalog_ingest/out"
GENERIC_START = "Colócate estable y prepara el material"

MUSCLE_GROUP = {
    "quads": "Piernas",
    "hamstrings": "Isquios",
    "glutes": "Glúteos",
    "chest": "Pecho",
    "shoulders": "Hombros",
    "upper-back": "Espalda",
    "lats": "Espalda",
    "triceps": "Tríceps",
    "biceps": "Bíceps",
    "forearms": "Antebrazos",
    "core": "Core",
    "abs": "Core",
    "calves": "Pantorrillas",
    "traps": "Trapecio",
    "cardiovascular system": "Cardio",
}


def steps(*xs: str) -> list[str]:
    return list(xs)


def put(store: dict, name: str, **kw) -> None:
    store[name] = kw


def family_content() -> dict[str, dict]:
    c: dict[str, dict] = {}

    # --- Strongman / odd object ---
    put(
        c,
        "Atlas Stone Over Shoulder",
        desc="Piedra Atlas del suelo por encima del hombro hasta soltarla al otro lado.",
        instr=steps(
            "Coloca la piedra entre los pies; cadera baja y lumbar neutra.",
            "Abraza la piedra al torso y extiende cadera hasta de pie.",
            "Pásala por encima de un hombro hasta que caiga claramente al otro lado.",
            "Error típico: redondear la lumbar al arrancar o no completar el pase.",
            "Exhala al pasar el hombro; controla el espacio alrededor.",
            "Progresión: más peso. Alternativa: D-ball o sandbag over shoulder.",
            "Estándar: cada rep pasa la piedra completamente sobre el hombro prescrito.",
        ),
        equipment="Piedra Atlas",
        target="hamstrings",
        secondary=["glutes", "upper-back", "core", "forearms"],
        body="full body",
        primaries=["hamstring", "gluteal"],
        secondaries=["upper-back", "forearm", "abs"],
    )
    put(
        c,
        "Tire Flip",
        desc="Vuelco de neumático con drive de piernas y cadera hasta dejarlo plano.",
        instr=steps(
            "Pecho cerca del neumático; agarra el borde inferior con lumbar neutra.",
            "Extiende cadera y rodillas, da un paso y empuja hasta voltearlo.",
            "El impulso sale de piernas/cadera, no solo de brazos.",
            "Error típico: redondear la espalda o empujar con brazos antes de extender cadera.",
            "Exhala en el vuelco; reubica los pies tras cada flip.",
            "Progresión: neumático más pesado o más flips seguidos.",
            "Estándar: el neumático queda plano al otro lado en cada rep.",
        ),
        equipment="Neumático",
        target="hamstrings",
        secondary=["quads", "glutes", "upper-back", "shoulders"],
        body="full body",
        primaries=["hamstring", "gluteal", "quadriceps"],
        secondaries=["upper-back", "deltoids"],
    )
    for name, eq, desc_extra in [
        ("Sandbag Carry", "Saco", "saco en bear hug, rack u hombro"),
        ("Husafell Carry", "Husafell / réplica", "piedra Husafell o réplica al pecho"),
        ("Jerry Bag Carry", "Jerry bag", "bidón/jerry bag"),
        ("Keg Carry", "Barril", "barril en bear hug o hombro"),
        ("Log Carry", "Tronco", "tronco/log"),
        ("Plate Carry", "Disco", "disco(s) en farmer o hug"),
        ("Dumbbell Carry", "Mancuernas", "una o dos mancuernas"),
        ("Dumbbell Overhead Carry", "Mancuernas", "mancuerna(s) bloqueada(s) overhead"),
        ("Dumbbell Waiters Walk", "Mancuernas", "mancuerna en waiter (palm up overhead)"),
        ("Suitcase Carry", "Mancuerna / kettlebell", "carga a un solo lado"),
        ("Double Kettlebell Farmers Carry", "Kettlebell", "una KB en cada mano"),
        ("Overhead Walk", "Barra / odd object", "carga bloqueada overhead"),
        ("Zercher Carry", "Barra", "barra en pliegue de codos"),
    ]:
        put(
            c,
            name,
            desc=f"Caminata con {desc_extra}; pasos cortos y torso estable.",
            instr=steps(
                f"Carga el implemento ({eq}) a la posición prescrita.",
                "Camina erguido con pasos cortos; no dejes que la carga se deslice.",
                "Mantén hombros activos y core firme durante todo el tramo.",
                "Error típico: inclinarte en exceso o depositar la carga antes de la marca.",
                "Respira en ritmo con los pasos; reajusta sin soltar del todo si hace falta.",
                "Progresión: más peso o más metros. Alternativa: farmer o sandbag carry.",
                "Estándar: distancia o tiempo prescritos sin tocar el suelo con la carga.",
            ),
            equipment=eq,
            target="core",
            secondary=["quads", "glutes", "forearms", "upper-back"],
            body="full body",
            primaries=["abs", "quadriceps"],
            secondaries=["gluteal", "forearm", "upper-back"],
        )

    put(
        c,
        "Sandbag Ground To Shoulder",
        desc="Saco del suelo a un hombro con recepción estable.",
        instr=steps(
            "Bisagra limpia, agarra el saco y llévalo al torso.",
            "Extiende cadera y asienta el saco sobre un hombro.",
            "Marca la recepción antes de bajar o soltar.",
            "Error típico: no asentar el saco o girar en exceso la lumbar.",
            "Exhala al asentar; alterna hombro si el WOD lo indica.",
            "Progresión: más peso. Alternativa: D-ball over shoulder.",
            "Estándar: saco claramente sobre el hombro en cada rep.",
        ),
        equipment="Saco",
        target="hamstrings",
        secondary=["glutes", "upper-back", "core"],
        body="full body",
        primaries=["hamstring", "gluteal"],
        secondaries=["upper-back", "abs"],
    )
    put(
        c,
        "Sandbag Load To Box",
        desc="Carga el saco del suelo y deposítalo estable sobre un cajón.",
        instr=steps(
            "Levanta el saco con bisagra limpia hasta pecho o hombro.",
            "Acércate al cajón y deposítalo encima con control.",
            "El saco debe quedar estable sobre la caja antes de soltar.",
            "Error típico: lanzar sin control o no dejarlo completamente sobre la caja.",
            "Exhala al depositar; vuelve a por el saco según el estándar.",
            "Progresión: saco más pesado o caja más alta.",
            "Estándar: saco apoyado sobre la caja en cada rep.",
        ),
        equipment="Saco, Cajón",
        target="quads",
        secondary=["hamstrings", "glutes", "upper-back", "core"],
        body="full body",
        primaries=["quadriceps", "gluteal"],
        secondaries=["hamstring", "upper-back", "abs"],
    )
    put(
        c,
        "Sandbag Over Log",
        desc="Pasa el saco por encima de un tronco u obstáculo similar.",
        instr=steps(
            "Levanta el saco y acércalo al tronco.",
            "Pásalo por encima hasta que quede o caiga al otro lado.",
            "Mantén la lumbar neutra en la carga inicial.",
            "Error típico: no superar la altura del tronco.",
            "Exhala al pasar el obstáculo.",
            "Progresión: saco más pesado o tronco más alto.",
            "Estándar: el saco supera claramente el tronco en cada rep.",
        ),
        equipment="Saco, Tronco",
        target="hamstrings",
        secondary=["glutes", "quads", "upper-back"],
        body="full body",
        primaries=["hamstring", "gluteal"],
        secondaries=["quadriceps", "upper-back"],
    )
    put(
        c,
        "Sandbag Squat",
        desc="Sentadilla abrazando un saco al pecho (bear hug) o en rack de saco.",
        instr=steps(
            "Abraza el saco al pecho con codos altos y torso erguido.",
            "Baja hasta la profundidad prescrita (paralelo o más).",
            "Empuja el suelo y vuelve a de pie sin soltar el saco.",
            "Error típico: inclinarte en exceso o cortar profundidad.",
            "Inhala al bajar y exhala al subir.",
            "Progresión: más peso o pausa abajo. Alternativa: goblet squat.",
            "Estándar: profundidad marcada y extensión completa arriba.",
        ),
        equipment="Saco",
        target="quads",
        secondary=["glutes", "core", "upper-back"],
        body="upper legs",
        primaries=["quadriceps", "gluteal"],
        secondaries=["abs", "upper-back"],
    )
    put(
        c,
        "Log Clean And Jerk",
        desc="Cargada de tronco a rack y envión hasta bloqueo overhead.",
        instr=steps(
            "Desde el suelo, carga el tronco a los hombros (rack de log).",
            "Dip corto e impulsa a overhead hasta bloquear codos.",
            "Recibe estable con pies al ancho de hombros.",
            "Error típico: press lento sin dip o no bloquear arriba.",
            "Exhala en el jerk; baja a rack o al suelo con control.",
            "Progresión: más peso. Alternativa: axle clean and jerk.",
            "Estándar: bloqueo overhead claro en cada rep.",
        ),
        equipment="Tronco",
        target="shoulders",
        secondary=["quads", "glutes", "triceps", "core"],
        body="full body",
        primaries=["deltoids", "quadriceps"],
        secondaries=["gluteal", "triceps", "abs"],
    )
    put(
        c,
        "Log Press",
        desc="Press de tronco desde rack de hombros hasta bloqueo overhead.",
        instr=steps(
            "Tronco en rack sobre los hombros, codos delante.",
            "Press o push press hasta extender los codos por completo.",
            "Bloquea arriba con la cabeza «a través» del tronco.",
            "Error típico: hiperextender la lumbar o no completar el lockout.",
            "Exhala al subir; baja a rack con control.",
            "Progresión: más peso o strict press.",
            "Estándar: lockout overhead estable en cada rep.",
        ),
        equipment="Tronco",
        target="shoulders",
        secondary=["triceps", "core"],
        body="shoulders",
        primaries=["deltoids"],
        secondaries=["triceps", "abs"],
    )
    put(
        c,
        "Zercher Deadlift",
        desc="Peso muerto con la barra en el pliegue de los codos.",
        instr=steps(
            "Barra en el pliegue de los codos; cadera atrás y lumbar neutra.",
            "Extiende cadera y rodillas hasta de pie con torso erguido.",
            "Baja con control manteniendo la posición Zercher.",
            "Error típico: redondear la lumbar o dejar caer los codos.",
            "Inhala antes de tirar; exhala al bloqueo.",
            "Progresión: más peso. Alternativa: Zercher squat.",
            "Estándar: extensión completa de cadera arriba en cada rep.",
        ),
        equipment="Barra",
        target="hamstrings",
        secondary=["glutes", "quads", "upper-back", "core"],
        body="upper legs",
        primaries=["hamstring", "gluteal"],
        secondaries=["quadriceps", "upper-back", "abs"],
    )
    put(
        c,
        "Zercher Squat",
        desc="Sentadilla con la barra en el pliegue de los codos.",
        instr=steps(
            "Barra en Zercher, codos altos y pecho arriba.",
            "Baja en sentadilla hasta la profundidad prescrita.",
            "Sube empujando el suelo sin perder la barra del pliegue.",
            "Error típico: inclinarte en exceso o abrir los codos.",
            "Inhala al bajar; exhala al subir.",
            "Progresión: más peso o pausa abajo.",
            "Estándar: profundidad y extensión completa arriba.",
        ),
        equipment="Barra",
        target="quads",
        secondary=["glutes", "core", "upper-back"],
        body="upper legs",
        primaries=["quadriceps", "gluteal"],
        secondaries=["abs", "upper-back"],
    )
    put(
        c,
        "Sled Drag",
        desc="Arrastre de trineo (hacia atrás, adelante o lateral) por distancia o tiempo.",
        instr=steps(
            "Engancha el trineo y adopta la dirección prescrita (atrás/adelante/lateral).",
            "Mantén el torso firme y tira o empuja con zancadas cortas y potentes.",
            "No dejes que el trineo se detenga si el WOD pide ritmo continuo.",
            "Error típico: redondear la espalda o dar zancadas demasiado largas e inestables.",
            "Exhala en cada impulso; usa el agarre o arnés según el setup.",
            "Progresión: más peso o más metros. Alternativa: prowler push.",
            "Estándar: completa la distancia/tiempo con el trineo en movimiento controlado.",
        ),
        equipment="Trineo",
        target="quads",
        secondary=["glutes", "hamstrings", "calves", "core"],
        body="upper legs",
        primaries=["quadriceps", "gluteal"],
        secondaries=["hamstring", "calves", "abs"],
    )
    put(
        c,
        "Sledgehammer Strike",
        desc="Golpes de maza sobre neumático: potencia de cadera y control del implemento.",
        instr=steps(
            "Coloca el neumático estable; agarra la maza con manos alternas o juntas.",
            "Lleva la maza por encima de la cabeza y golpea el neumático con drive de cadera.",
            "Alterna lado o patrón según el WOD; recupera la maza con control.",
            "Error típico: golpear solo con brazos o perder el agarre al rebotar.",
            "Exhala en el impacto; mantén los pies firmes.",
            "Progresión: maza más pesada o más golpes por minuto.",
            "Estándar: cada golpe contacta el neumático con rango completo del swing.",
        ),
        equipment="Maza, Neumático",
        target="core",
        secondary=["shoulders", "upper-back", "glutes", "forearms"],
        body="full body",
        primaries=["abs", "deltoids"],
        secondaries=["upper-back", "gluteal", "forearm"],
    )
    put(
        c,
        "Battle Rope",
        desc="Ondas, slams o patrones con cuerda de batalla por tiempo o reps.",
        instr=steps(
            "Pies firmes, rodillas semiflexionadas y torso estable; agarra ambos extremos.",
            "Genera ondas alternas, dobles o slams según lo prescrito.",
            "Mantén la amplitud de la cuerda; no te quedes corto de recorrido.",
            "Error típico: encorvar la espalda o mover solo las muñecas.",
            "Respira en ritmo con las ondas; no aguantes la respiración.",
            "Progresión: más tiempo, más densidad o cuerda más pesada.",
            "Estándar: el patrón prescrito se mantiene durante todo el intervalo.",
        ),
        equipment="Cuerda de batalla",
        target="shoulders",
        secondary=["core", "forearms", "upper-back", "legs"],
        body="full body",
        primaries=["deltoids", "abs"],
        secondaries=["forearm", "upper-back", "quadriceps"],
    )

    # --- Axle / trap / deficit deadlifts & presses ---
    put(
        c,
        "Axle Deadlift",
        desc="Peso muerto con axle (barra gruesa): bisagra, espalda neutra y bloqueo arriba.",
        instr=steps(
            "Axle sobre el empeine; agarre firme (la barra gruesa exige más grip).",
            "Pecho alto, lumbar neutra; empuja el suelo y extiende cadera hasta de pie.",
            "Bloquea arriba sin hiperextender; baja con control.",
            "Error típico: redondear la lumbar o perder el agarre a media subida.",
            "Inhala y bracea antes de tirar; exhala al bloqueo.",
            "Progresión: más peso o straps solo si el WOD lo permite.",
            "Estándar: extensión completa de cadera y rodillas arriba.",
        ),
        equipment="Axle",
        target="hamstrings",
        secondary=["glutes", "upper-back", "forearms", "core"],
        body="upper legs",
        primaries=["hamstring", "gluteal"],
        secondaries=["upper-back", "forearm", "abs"],
    )
    put(
        c,
        "Axle Press",
        desc="Press overhead con axle desde rack de hombros hasta bloqueo.",
        instr=steps(
            "Axle en rack frontal o detrás según el estándar.",
            "Press o push press hasta bloquear codos overhead.",
            "Cabeza a través; muñecas firmes sobre la barra gruesa.",
            "Error típico: no completar lockout o arching excesivo.",
            "Exhala al subir; baja a rack con control.",
            "Progresión: más peso o strict press.",
            "Estándar: bloqueo overhead estable en cada rep.",
        ),
        equipment="Axle",
        target="shoulders",
        secondary=["triceps", "core", "upper-chest"],
        body="shoulders",
        primaries=["deltoids"],
        secondaries=["triceps", "abs"],
    )
    put(
        c,
        "Trap Bar Deadlift",
        desc="Peso muerto con barra hex/trap: empuje de piernas y bloqueo alto.",
        instr=steps(
            "Pisa el centro de la hex; agarra las asas al mismo alto.",
            "Cadera atrás, pecho alto; empuja el suelo hasta de pie.",
            "Bloquea cadera y rodillas; baja con control hasta tocar el suelo.",
            "Error típico: tirar con la espalda o desnivelar las asas.",
            "Inhala y bracea; exhala al bloqueo.",
            "Progresión: más peso o deficit. Alternativa: peso muerto convencional.",
            "Estándar: extensión completa arriba y placas al suelo abajo.",
        ),
        equipment="Barra hex / trap",
        target="quads",
        secondary=["hamstrings", "glutes", "upper-back", "forearms"],
        body="upper legs",
        primaries=["quadriceps", "gluteal"],
        secondaries=["hamstring", "upper-back", "forearm"],
    )
    put(
        c,
        "Deficit Deadlift",
        desc="Peso muerto de pie sobre un deficit (discos/plataforma) para más rango.",
        instr=steps(
            "Colócate sobre el deficit estable; barra sobre el empeine.",
            "Bisagra con lumbar neutra; el rango es mayor — no redondees.",
            "Extiende hasta de pie y baja con control hasta el suelo.",
            "Error típico: cortar profundidad del deficit o redondear al inicio.",
            "Inhala y bracea; exhala al bloqueo.",
            "Progresión: más peso o más altura de deficit (con técnica).",
            "Estándar: placas tocan el suelo y extensión completa arriba.",
        ),
        equipment="Barra, Deficit",
        target="hamstrings",
        secondary=["glutes", "upper-back", "forearms", "core"],
        body="upper legs",
        primaries=["hamstring", "gluteal"],
        secondaries=["upper-back", "forearm", "abs"],
    )
    put(
        c,
        "Stiff Legged Deadlift",
        desc="Peso muerto de piernas rígidas: bisagra con mínima flexión de rodilla.",
        instr=steps(
            "Barra a la altura de muslos; rodillas casi bloqueadas pero no hiperextendidas.",
            "Empuja la cadera atrás y baja la barra rozando las piernas.",
            "Estira isquios con espalda neutra; vuelve extendiendo cadera.",
            "Error típico: flexionar demasiado las rodillas o redondear la lumbar.",
            "Exhala al subir; no tires con la zona lumbar.",
            "Progresión: más peso o RDL. Alternativa: good morning.",
            "Estándar: bisagra clara y extensión de cadera completa arriba.",
        ),
        equipment="Barra",
        target="hamstrings",
        secondary=["glutes", "upper-back", "core"],
        body="upper legs",
        primaries=["hamstring", "gluteal"],
        secondaries=["upper-back", "abs"],
    )
    put(
        c,
        "Floor Press",
        desc="Press de banca en el suelo: rango corto y control de codos.",
        instr=steps(
            "Túmbate en el suelo con barra o mancuernas sobre el pecho.",
            "Baja hasta que tríceps toquen el suelo; pausa breve.",
            "Empuja hasta extender los codos sin rebotar.",
            "Error típico: rebotar los codos o abrirlos en exceso.",
            "Exhala al empujar; omóplatos estables.",
            "Progresión: más peso. Alternativa: press banca o dumbbell floor press.",
            "Estándar: tríceps al suelo y lockout completo arriba.",
        ),
        equipment="Barra",
        target="chest",
        secondary=["triceps", "shoulders"],
        body="chest",
        primaries=["chest", "triceps"],
        secondaries=["deltoids"],
    )
    put(
        c,
        "Z Press",
        desc="Press overhead sentado en el suelo con piernas extendidas (sin respaldo).",
        instr=steps(
            "Siéntate en el suelo con piernas abiertas/extendidas y torso erguido.",
            "Barra o mancuernas a hombros; press hasta bloqueo overhead.",
            "No uses impulso de piernas ni te recuestes.",
            "Error típico: arching excesivo o no bloquear codos.",
            "Exhala al subir; core muy firme.",
            "Progresión: más peso o strict seated press en banco.",
            "Estándar: lockout overhead con glúteos en el suelo.",
        ),
        equipment="Barra",
        target="shoulders",
        secondary=["triceps", "core", "upper-back"],
        body="shoulders",
        primaries=["deltoids"],
        secondaries=["triceps", "abs"],
    )
    put(
        c,
        "Bradford Press",
        desc="Press Bradford: barra pasa de delante a detrás de la cabeza en arcos cortos.",
        instr=steps(
            "Barra a la altura de la frente/clavícula; agarre algo más ancho.",
            "Sube la barra solo lo necesario para pasarla por encima de la cabeza.",
            "Alterna rack frontal y detrás de la nuca sin lockout completo.",
            "Error típico: bajar demasiado detrás de la nuca o usar peso excesivo.",
            "Movimiento continuo y controlado; no rebotes en los hombros.",
            "Progresión: más reps o peso ligero-moderado.",
            "Estándar: cada paso delante↔detrás cuenta según el esquema del WOD.",
        ),
        equipment="Barra",
        target="shoulders",
        secondary=["triceps", "traps"],
        body="shoulders",
        primaries=["deltoids"],
        secondaries=["triceps", "trapezius"],
    )
    put(
        c,
        "Landmine Press",
        desc="Press en landmine (barra anclada) a un brazo o dos, en pie o medio arrodillado.",
        instr=steps(
            "Ancla la barra; sujeta el extremo libre a la altura del hombro.",
            "Empuja en diagonal arriba y adelante hasta extender el codo.",
            "No gires en exceso el tronco; core firme.",
            "Error típico: abrir la costilla o empujar solo con el brazo sin piernas/core.",
            "Exhala al empujar; baja con control a la altura del hombro.",
            "Progresión: más peso o half-kneeling. Alternativa: dumbbell press.",
            "Estándar: extensión completa del brazo en cada rep.",
        ),
        equipment="Barra (landmine)",
        target="shoulders",
        secondary=["chest", "triceps", "core"],
        body="shoulders",
        primaries=["deltoids", "chest"],
        secondaries=["triceps", "abs"],
    )
    put(
        c,
        "Pendlay Row",
        desc="Remo Pendlay: cada rep parte del suelo con espalda paralela.",
        instr=steps(
            "Barra en el suelo; bisagra hasta espalda casi paralela.",
            "Tira explosivo al bajo pecho/abdomen y toca; baja al suelo sin rebote.",
            "Cada rep es desde parado en el suelo (no hang continuo).",
            "Error típico: usar impulso de torso o no apoyar la barra entre reps.",
            "Exhala al tirar; mantén la lumbar neutra.",
            "Progresión: más peso. Alternativa: remo con barra.",
            "Estándar: barra al suelo y contacto al torso en cada rep.",
        ),
        equipment="Barra",
        target="upper-back",
        secondary=["lats", "biceps", "core"],
        body="back",
        primaries=["upper-back"],
        secondaries=["biceps", "abs"],
    )

    # --- Dumbbell / KB strength variants ---
    db_press = {
        "Dumbbell Bench Press": (
            "Press banca con mancuernas: baja a pecho y extiende arriba.",
            "Banco",
            "chest",
            ["triceps", "shoulders"],
            "Túmbate en banco con una mancuerna en cada mano sobre el pecho.",
            "Baja con control hasta cerca del pecho; codos ~45°.",
            "Empuja hasta extender sin chocar las mancuernas con violencia.",
        ),
        "Dumbbell Floor Press": (
            "Press de suelo con mancuernas: tríceps al suelo y lockout.",
            "Mancuernas",
            "chest",
            ["triceps", "shoulders"],
            "Túmbate en el suelo con mancuernas sobre el pecho.",
            "Baja hasta que tríceps toquen el suelo; pausa breve.",
            "Empuja hasta extender los codos.",
        ),
        "Dumbbell Shoulder Press": (
            "Press de hombros con mancuernas hasta bloqueo overhead.",
            "Mancuernas",
            "shoulders",
            ["triceps", "core"],
            "Mancuernas a la altura de las orejas, muñecas firmes.",
            "Empuja overhead hasta extender; no choques las mancuernas.",
            "Baja con control a la altura de las orejas.",
        ),
        "Dumbbell Strict Press": (
            "Press estricto con mancuernas: sin impulso de piernas.",
            "Mancuernas",
            "shoulders",
            ["triceps", "core"],
            "Mancuernas en rack; glúteos y piernas quietos.",
            "Press solo de hombro/tríceps hasta bloqueo.",
            "Si usas dip de piernas, ya no es estricto.",
        ),
        "Dumbbell Shoulder To Overhead": (
            "De hombros a overhead con mancuernas (press, push press o jerk).",
            "Mancuernas",
            "shoulders",
            ["triceps", "quads", "core"],
            "Mancuernas en rack frontal.",
            "Llévalas overhead por cualquier forma legal (press/push press/jerk).",
            "Bloquea arriba antes de bajar a hombros.",
        ),
        "Kettlebell Press": (
            "Press de kettlebell a un brazo o dos hasta bloqueo overhead.",
            "Kettlebell",
            "shoulders",
            ["triceps", "core"],
            "KB en rack (antebrazo vertical, muñeca recta).",
            "Press hasta bloquear el codo con bíceps junto a la oreja.",
            "Baja a rack con control; no dejes caer la KB.",
        ),
    }
    for name, (desc, eq, target, sec, s1, s2, s3) in db_press.items():
        put(
            c,
            name,
            desc=desc,
            instr=steps(
                s1,
                s2,
                s3,
                "Error típico: arching excesivo o no completar el lockout.",
                "Exhala al empujar; core firme.",
                "Progresión: más peso o tempo. Alternativa: press con barra.",
                "Estándar: extensión completa arriba en cada rep.",
            ),
            equipment=eq if eq != "Banco" else "Mancuernas, Banco",
            target=target,
            secondary=sec,
            body="chest" if target == "chest" else "shoulders",
            primaries=["chest", "triceps"] if target == "chest" else ["deltoids"],
            secondaries=["deltoids"] if target == "chest" else ["triceps", "abs"],
        )

    for name, desc, eq, setup, action, finish in [
        (
            "Dumbbell Deadlift",
            "Peso muerto con mancuernas a los lados o delante.",
            "Mancuernas",
            "Mancuernas fuera de los pies o delante; bisagra con lumbar neutra.",
            "Extiende cadera y rodillas hasta de pie; mancuernas rozan las piernas.",
            "Baja con control hasta tocar el suelo o la altura prescrita.",
        ),
        (
            "Dumbbell Romanian Deadlift",
            "RDL con mancuernas: bisagra y estiramiento de isquios.",
            "Mancuernas",
            "De pie con mancuernas delante de los muslos; suave flexión de rodilla.",
            "Cadera atrás; baja hasta sentir isquios con espalda neutra.",
            "Extiende cadera hasta de pie sin hiperextender.",
        ),
        (
            "Kettlebell Deadlift",
            "Peso muerto con kettlebell entre los pies o delante.",
            "Kettlebell",
            "KB entre los pies; cadera atrás y pecho alto.",
            "Empuja el suelo y bloquea cadera arriba.",
            "Baja la KB al suelo con control.",
        ),
        (
            "Single Leg Romanian Deadlift",
            "RDL a una pierna (peso corporal, mancuerna o KB).",
            "Mancuernas",
            "Apoyo en una pierna; ligera flexión de rodilla; carga opcional en la mano libre.",
            "Bisagra hacia delante mientras la pierna libre va atrás; cadera cuadrada.",
            "Vuelve a de pie sin torcer la pelvis.",
        ),
    ]:
        put(
            c,
            name,
            desc=desc,
            instr=steps(
                setup,
                action,
                finish,
                "Error típico: redondear la lumbar o rotar la cadera.",
                "Exhala al extender la cadera.",
                "Progresión: más carga o más rango controlado.",
                "Estándar: bisagra limpia y extensión completa arriba.",
            ),
            equipment=eq,
            target="hamstrings",
            secondary=["glutes", "core", "upper-back"],
            body="upper legs",
            primaries=["hamstring", "gluteal"],
            secondaries=["abs", "upper-back"],
        )

    put(
        c,
        "Kettlebell Sumo Deadlift High Pull",
        desc="Peso muerto sumo con KB seguido de tirón alto hasta cerca de la barbilla.",
        instr=steps(
            "KB entre los pies en stance sumo; pecho alto.",
            "Extiende cadera y, en continuidad, tira de la KB hasta cerca del pecho/barbilla.",
            "Codos altos; baja a extensión y al suelo según el WOD.",
            "Error típico: remo de brazos sin extensión de cadera o encoger el cuello.",
            "Exhala en el tirón alto.",
            "Progresión: KB más pesada. Alternativa: sumo high pull con barra.",
            "Estándar: cadera extendida y KB a altura de pecho/barbilla en cada rep.",
        ),
        equipment="Kettlebell",
        target="hamstrings",
        secondary=["glutes", "shoulders", "upper-back", "traps"],
        body="full body",
        primaries=["hamstring", "gluteal", "deltoids"],
        secondaries=["upper-back", "trapezius"],
    )
    put(
        c,
        "Single Arm Kettlebell Swing",
        desc="Swing de kettlebell a una mano (ruso o americano según WOD).",
        instr=steps(
            "KB a una mano; hinge y hike pass entre las piernas.",
            "Extiende cadera de forma explosiva; el brazo guía la KB.",
            "Hasta pecho (ruso) u overhead (americano) según estándar.",
            "Error típico: levantar con el hombro o flexionar de más las rodillas tipo squat.",
            "Exhala en el pop de cadera; cambia de mano si se prescribe.",
            "Progresión: KB más pesada o más reps. Alternativa: swing a dos manos.",
            "Estándar: altura prescrita y cadera extendida en cada swing.",
        ),
        equipment="Kettlebell",
        target="hamstrings",
        secondary=["glutes", "core", "shoulders", "forearms"],
        body="full body",
        primaries=["hamstring", "gluteal"],
        secondaries=["abs", "deltoids", "forearm"],
    )
    put(
        c,
        "Kettlebell Windmill",
        desc="Molino con KB: una mano overhead y bisagra hacia la pierna libre.",
        instr=steps(
            "KB bloqueada overhead; pies algo girados; mirada a la KB.",
            "Desliza la mano libre por la pierna mientras empujas la cadera afuera.",
            "Mantén el brazo overhead vertical; vuelve a erguido.",
            "Error típico: flexionar el codo overhead o redondear la espalda.",
            "Respira de forma continua; no fuerces el rango.",
            "Progresión: KB más pesada o más profundidad controlada.",
            "Estándar: brazo overhead bloqueado en todo el recorrido.",
        ),
        equipment="Kettlebell",
        target="core",
        secondary=["shoulders", "hamstrings", "glutes"],
        body="full body",
        primaries=["abs", "deltoids"],
        secondaries=["hamstring", "gluteal"],
    )
    put(
        c,
        "Kettlebell Halo",
        desc="Halo de kettlebell alrededor de la cabeza con core estable.",
        instr=steps(
            "Sujeta la KB por las cuernos invertidos a la altura del pecho.",
            "Circunda la cabeza con la KB cerca del cráneo, sin golpear.",
            "Alterna dirección; torso quieto y costillas abajo.",
            "Error típico: mover el tronco con la KB o acercar demasiado la nuca.",
            "Respira continuo; hombros relajados.",
            "Progresión: KB más pesada o más círculos lentos.",
            "Estándar: círculo completo alrededor de la cabeza en cada rep.",
        ),
        equipment="Kettlebell",
        target="shoulders",
        secondary=["core", "upper-back"],
        body="shoulders",
        primaries=["deltoids"],
        secondaries=["abs", "upper-back"],
    )

    # Olympic / hang DB variants
    for name, desc, s1, s2, s3 in [
        (
            "Dumbbell Hang Power Clean",
            "Cargada de potencia con mancuernas desde hang (sin sentadilla profunda).",
            "Mancuernas a mitad de muslo; bisagra corta.",
            "Extiende cadera y recibe en rack parcial (power).",
            "Baja a hang y repite.",
        ),
        (
            "Dumbbell Hang Squat Clean",
            "Cargada completa con mancuernas desde hang a sentadilla.",
            "Desde hang, extiende y recibe en front rack bajo.",
            "Sentadilla profunda con mancuernas en hombros; sube a de pie.",
            "Vuelve a hang para la siguiente.",
        ),
        (
            "Dumbbell Squat Clean",
            "Cargada completa con mancuernas desde el suelo a sentadilla.",
            "Desde el suelo, carga a rack y recibe en sentadilla.",
            "Sube a de pie con mancuernas en hombros.",
            "Baja al suelo para la siguiente rep.",
        ),
        (
            "Dumbbell Split Clean",
            "Cargada con mancuernas recibiendo en split (tijera).",
            "Desde suelo o hang, extiende y recibe en split.",
            "Recupera pies a paralelo con mancuernas en rack.",
            "Repite alternando pierna si se prescribe.",
        ),
        (
            "Dumbbell Hang Split Snatch",
            "Arrancada desde hang con mancuernas recibiendo en split.",
            "Desde hang, tirón y recibe overhead en split.",
            "Bloquea codos; recupera pies.",
            "Baja a hang o hombros según el WOD.",
        ),
        (
            "Dumbbell Hang Clean To Overhead",
            "Cargada desde hang + envío a overhead (press/jerk).",
            "Hang clean a rack.",
            "De rack a overhead por press, push press o jerk.",
            "Bloquea arriba antes de bajar.",
        ),
        (
            "Dumbbell Squat Clean Thruster",
            "Squat clean con mancuernas + thruster en continuidad.",
            "Carga a sentadilla y, al subir, press overhead (thruster).",
            "Bloquea arriba; baja a rack/hang según el esquema.",
            "No separes clean y thruster si el WOD pide complejo continuo.",
        ),
        (
            "Dumbbell Split Clean",
            "Cargada en split con mancuernas.",
            "Tirón y recepción en tijera con mancuernas en hombros.",
            "Recupera a stance paralelo.",
            "Mantén el torso erguido en la recepción.",
        ),
        (
            "Hang High Pull",
            "Tirón alto desde hang con barra o DB hasta cerca del pecho.",
            "Desde hang, extiende cadera y tira codos altos.",
            "La barra/DB llega alto sin recibir en squat.",
            "Baja a hang con control.",
        ),
        (
            "Bodyweight Clean And Jerk",
            "Simulación de clean & jerk a peso corporal (técnica / calentamiento).",
            "Desde «suelo» imaginario, carga a rack sin peso.",
            "Dip y jerk a overhead con bloqueo de brazos.",
            "Enfócate en timing de piernas y recepción.",
        ),
    ]:
        if name in c and name == "Dumbbell Split Clean":
            continue
        put(
            c,
            name,
            desc=desc,
            instr=steps(
                s1,
                s2,
                s3,
                "Error típico: pressear sin extensión de cadera o no marcar el bloqueo.",
                "Exhala en el tirón/envión principal.",
                "Progresión: añade mancuernas/barra cuando la técnica sea limpia.",
                f"Estándar: cada fase de {name} queda marcada antes de seguir.",
            ),
            equipment="Mancuernas" if "Dumbbell" in name else ("Barra" if "Hang High" in name else "Peso corporal"),
            target="quads",
            secondary=["shoulders", "glutes", "core", "traps"],
            body="full body",
            primaries=["quadriceps", "deltoids"],
            secondaries=["gluteal", "trapezius", "abs"],
        )

    for name, desc, setup in [
        (
            "Single Arm Dumbbell Thruster",
            "Thruster a una mancuerna: sentadilla + press overhead.",
            "Una mancuerna en rack; la mano libre ayuda al equilibrio.",
        ),
        (
            "Single Arm Kettlebell Thruster",
            "Thruster a una kettlebell: squat + press.",
            "KB en rack a un lado; antebrazo vertical.",
        ),
    ]:
        put(
            c,
            name,
            desc=desc,
            instr=steps(
                setup,
                "Sentadilla completa y, al subir, press a overhead hasta bloqueo.",
                "Baja a rack y repite; cambia de lado si el WOD lo pide.",
                "Error típico: press anticipado o cortar profundidad.",
                "Exhala al subir/press.",
                "Progresión: más carga o thruster a dos manos.",
                "Estándar: profundidad de squat y lockout overhead en cada rep.",
            ),
            equipment="Mancuernas" if "Dumbbell" in name else "Kettlebell",
            target="quads",
            secondary=["shoulders", "triceps", "glutes", "core"],
            body="full body",
            primaries=["quadriceps", "deltoids"],
            secondaries=["triceps", "gluteal", "abs"],
        )

    # Lunges / step-ups
    for name, eq, desc, rack in [
        ("Back Rack Lunge", "Barra", "Zancada con barra en espalda.", "Barra en trapecios; torso erguido."),
        ("Barbell Step Up", "Barra, Cajón", "Step-up al cajón con barra en espalda.", "Barra en espalda; un pie completo sobre el cajón."),
        ("Dumbbell Box Step Up", "Mancuernas, Cajón", "Step-up al cajón con mancuernas.", "Mancuernas a los lados o en rack; pie completo en el cajón."),
        ("Kettlebell Front Rack Lunge", "Kettlebell", "Zancada con KB en front rack.", "KB en rack frontal; codos altos."),
        ("Double Kettlebell Front Rack Lunge", "Kettlebell", "Zancada con dos KB en front rack.", "Dos KB en rack; torso compacto."),
        ("Lateral Lunge", "Peso corporal / carga", "Zancada lateral con cadera atrás y rodilla alineada.", "Pies paralelos; da un paso lateral amplio."),
        ("Medicine Ball Box Step Over", "Balón medicinal, Cajón", "Step-over al cajón con medball.", "Sujeta el medball; pisa el cajón y cruza al otro lado."),
    ]:
        put(
            c,
            name,
            desc=desc,
            instr=steps(
                rack,
                "Baja o sube con la rodilla delante alineada al pie; controla el tronco.",
                "Extiende la pierna de apoyo por completo en la parte alta.",
                "Error típico: empujar con la pierna de atrás o dejar colapsar la rodilla.",
                "Exhala al extender; alterna piernas según el WOD.",
                "Progresión: más carga o caja más alta.",
                "Estándar: rango completo y control en cada zancada/step.",
            ),
            equipment=eq,
            target="quads",
            secondary=["glutes", "hamstrings", "core"],
            body="upper legs",
            primaries=["quadriceps", "gluteal"],
            secondaries=["hamstring", "abs"],
        )

    put(
        c,
        "Barbell Squat Jump",
        desc="Sentadilla con barra seguida de salto vertical (carga ligera).",
        instr=steps(
            "Barra en espalda con carga moderada; pies al ancho de hombros.",
            "Baja en sentadilla y salta extendiendo cadera y tobillos.",
            "Aterriza suave y absorbe con las rodillas antes de la siguiente.",
            "Error típico: carga excesiva o aterrizaje rígido.",
            "Exhala en el salto; mantén el pecho alto.",
            "Progresión: más altura de salto o jumping squat sin barra.",
            "Estándar: extensión completa en el aire y recepción controlada.",
        ),
        equipment="Barra",
        target="quads",
        secondary=["glutes", "calves", "core"],
        body="upper legs",
        primaries=["quadriceps", "gluteal"],
        secondaries=["calves", "abs"],
    )

    # Burpee variants
    for name, desc, s2 in [
        ("Burpee Bar Muscle Up", "Burpee + muscle-up a barra.", "Tras el burpee, salta a la barra y completa el muscle-up."),
        ("Burpee Over Dumbbell", "Burpee y salto lateral sobre la mancuerna.", "Tras pecho al suelo, salta lateralmente sobre la mancuerna."),
        ("Burpee Over The Bar", "Burpee y paso/salto sobre la barra en el suelo.", "Tras el burpee, cruza la barra al otro lado."),
        ("Lateral Burpee", "Burpee con desplazamiento lateral.", "Pecho al suelo y desplázate lateralmente entre reps."),
        ("Dumbbell Burpee Deadlift", "Burpee agarrando mancuernas + peso muerto al subir.", "Manos en mancuernas; pecho abajo, luego deadlift a de pie."),
    ]:
        put(
            c,
            name,
            desc=desc,
            instr=steps(
                "Pecho y muslos al suelo (o estándar del WOD) en la parte baja.",
                s2,
                "Extiende cadera arriba; marca el lockout o el cruce del obstáculo.",
                "Error típico: no tocar el suelo con el pecho o acortar el muscle-up/cruce.",
                "Exhala en el esfuerzo principal (salto, tirón o deadlift).",
                "Progresión: más densidad. Escala a burpee + pull-up si hace falta.",
                f"Estándar: pecho abajo y final completo de {name} en cada rep.",
            ),
            equipment="Barra" if "Bar" in name and "Dumbbell" not in name else ("Mancuernas" if "Dumbbell" in name else "Peso corporal"),
            target="cardiovascular system",
            secondary=["chest", "quads", "upper-back", "core"],
            body="full body",
            primaries=["chest", "quadriceps"],
            secondaries=["upper-back", "abs", "deltoids"],
        )

    # Gymnastics / push / pull
    put(
        c,
        "Push Up",
        desc="Flexión de brazos: pecho cerca del suelo y codos extendidos arriba.",
        instr=steps(
            "Plancha con manos bajo los hombros y cuerpo en línea.",
            "Baja hasta pecho cerca del suelo; codos ~45°.",
            "Empuja hasta extender los codos sin hundir la lumbar.",
            "Error típico: no bajar el pecho o picar con la cadera.",
            "Exhala al subir.",
            "Progresión: lastradas o hand-release. Escala a rodillas si hace falta.",
            "Estándar: pecho abajo y lockout arriba en cada rep.",
        ),
        equipment="Peso corporal",
        target="chest",
        secondary=["triceps", "shoulders", "core"],
        body="chest",
        primaries=["chest"],
        secondaries=["triceps", "deltoids", "abs"],
    )
    put(
        c,
        "Hand Release Push Up",
        desc="Flexión con despegue de manos del suelo abajo del todo.",
        instr=steps(
            "Plancha; baja hasta pecho y muslos al suelo.",
            "Levanta ambas manos claramente del suelo.",
            "Vuelve a colocar las manos y empuja hasta lockout.",
            "Error típico: no despegar las manos o no extender arriba.",
            "Exhala al empujar.",
            "Progresión: más reps. Escala a push-up clásico.",
            "Estándar: pecho abajo, manos libres y extensión completa arriba.",
        ),
        equipment="Peso corporal",
        target="chest",
        secondary=["triceps", "shoulders", "core"],
        body="chest",
        primaries=["chest"],
        secondaries=["triceps", "deltoids", "abs"],
    )
    put(
        c,
        "Ring Push Up",
        desc="Flexión en anillas: mayor inestabilidad y rango.",
        instr=steps(
            "Anillas a altura de push-up; cuerpo en plancha.",
            "Baja con control (pecho a altura de anillas o más); codos cerca.",
            "Empuja hasta extender; anillas estables junto al cuerpo.",
            "Error típico: abrir en exceso las anillas o hundir la cadera.",
            "Exhala al subir; hombros activos.",
            "Progresión: más profundidad o anillas más bajas.",
            "Estándar: rango completo y lockout con anillas quietas.",
        ),
        equipment="Anillas",
        target="chest",
        secondary=["triceps", "shoulders", "core"],
        body="chest",
        primaries=["chest"],
        secondaries=["triceps", "deltoids", "abs"],
    )
    put(
        c,
        "Renegade Row",
        desc="Remo en plancha con mancuernas: una fila por lado sin rotar de más.",
        instr=steps(
            "Plancha sobre mancuernas; pies algo abiertos para estabilidad.",
            "Rema una mancuerna al costado manteniendo cadera cuadrada.",
            "Baja y alterna; minimiza el balanceo.",
            "Error típico: abrir la cadera o encoger el cuello.",
            "Exhala al remar.",
            "Progresión: más peso o push-up + row.",
            "Estándar: cada remo llega al costado con plancha estable.",
        ),
        equipment="Mancuernas",
        target="upper-back",
        secondary=["core", "biceps", "shoulders"],
        body="back",
        primaries=["upper-back", "abs"],
        secondaries=["biceps", "deltoids"],
    )

    for name, desc, eq, s1, s2, s3, target, prim, sec in [
        (
            "Kipping Handstand Push Up",
            "HSPU con kipping: impulso de piernas hacia el bloqueo.",
            "Pared",
            "En pino apoyado; baja la cabeza al suelo (o deficit).",
            "Kip de piernas y extiende brazos hasta lockout.",
            "Controla la bajada; no rebotes la cabeza.",
            "shoulders",
            ["deltoids", "triceps"],
            ["abs", "trapezius"],
        ),
        (
            "Parallette Handstand Push Up",
            "HSPU sobre parallettes (mayor rango).",
            "Parallettes",
            "Pino sobre parallettes; baja hasta orejas/hombros según estándar.",
            "Empuja (strict o kipping) hasta lockout sobre las barras.",
            "No dejes que los parallettes basculen.",
            "shoulders",
            ["deltoids", "triceps"],
            ["abs"],
        ),
        (
            "Ring Handstand Push Up",
            "HSPU en anillas (avanzado): estabilidad y lockout.",
            "Anillas",
            "Pino en anillas con soporte o libre según nivel.",
            "Baja y empuja hasta turn-out/lockout prescrito.",
            "Mantén anillas cerca del cuerpo.",
            "shoulders",
            ["deltoids", "triceps"],
            ["abs", "upper-back"],
        ),
        (
            "Negative Pull Up",
            "Dominada negativa: solo la fase excéntrica controlada.",
            "Barra",
            "Salta o asistete hasta la barbilla por encima de la barra.",
            "Baja en 3–5 s hasta brazos extendidos.",
            "No te dejes caer en el último tercio.",
            "upper-back",
            ["upper-back"],
            ["biceps", "forearm"],
        ),
        (
            "L Pull Up",
            "Dominada manteniendo posición en L (piernas horizontales).",
            "Barra",
            "Cuelga en L-sit (piernas extendidas a 90°).",
            "Tira hasta barbilla sobre la barra sin perder la L.",
            "Baja con control manteniendo piernas altas.",
            "upper-back",
            ["upper-back", "abs"],
            ["biceps"],
        ),
        (
            "Ring Lower",
            "Descenso controlado en anillas desde soporte o muscle-up.",
            "Anillas",
            "Desde soporte en anillas o cima de muscle-up.",
            "Baja excéntrico hasta cuelgue o posición prescrita.",
            "Hombros activos; no te desplomes.",
            "upper-back",
            ["upper-back", "chest"],
            ["triceps", "abs"],
        ),
        (
            "Parallel Bar Traverse",
            "Desplazamiento lateral/avance en barras paralelas en soporte.",
            "Paralelas",
            "Soporte en paralelas con codos bloqueados.",
            "Avanza o cruza lateralmente moviendo una mano cada vez.",
            "Mantén el cuerpo hueco; no balancees en exceso.",
            "triceps",
            ["triceps", "abs"],
            ["shoulders", "chest"],
        ),
        (
            "Wall Climb",
            "Ascenso por la pared desde plancha hasta pino apoyado.",
            "Pared",
            "Plancha con pies cerca de la pared.",
            "Camina pies arriba y manos atrás hasta pino en la pared.",
            "Desciende con control o baja según el WOD.",
            "shoulders",
            ["deltoids", "abs"],
            ["triceps", "upper-back"],
        ),
        (
            "Wall Climb Over",
            "Wall climb hasta pino y cruce/bajada al otro lado del obstáculo o pared baja.",
            "Pared / obstáculo",
            "Escala a pino como en wall climb.",
            "Supera el borde o gira según el estándar del evento.",
            "Aterriza o desciende controlado al otro lado.",
            "shoulders",
            ["deltoids", "abs"],
            ["triceps", "quadriceps"],
        ),
    ]:
        put(
            c,
            name,
            desc=desc,
            instr=steps(
                s1,
                s2,
                s3,
                "Error típico: acortar el rango o perder la línea del cuerpo.",
                "Exhala en el esfuerzo principal; no contengas la respiración.",
                "Progresión: más rango o menos asistencia. Escala a versión strict o parcial.",
                f"Estándar: cada rep de {name} cumple el rango acordado.",
            ),
            equipment=eq,
            target=target,
            secondary=["core"],
            body="shoulders" if target == "shoulders" else "back",
            primaries=prim,
            secondaries=sec,
        )

    put(
        c,
        "Hanging Knee Raise",
        desc="Elevación de rodillas colgado de la barra hasta arriba del ombligo/pecho.",
        instr=steps(
            "Cuelga activo (hombros abajo) de la barra.",
            "Lleva las rodillas arriba sin balanceo excesivo.",
            "Baja con control a piernas extendidas.",
            "Error típico: kip descontrolado o no subir las rodillas lo suficiente.",
            "Exhala al subir.",
            "Progresión: toes to bar o strict knees to chest.",
            "Estándar: rodillas a la altura prescrita en cada rep.",
        ),
        equipment="Barra",
        target="abs",
        secondary=["hip flexors", "forearms"],
        body="waist",
        primaries=["abs"],
        secondaries=["forearm"],
    )
    put(
        c,
        "Strict Knee Raise",
        desc="Elevación de rodillas estricta (sin kip) colgado.",
        instr=steps(
            "Cuelga activo sin impulso de piernas.",
            "Sube rodillas solo con abdomen/flexores; sin balanceo.",
            "Baja lento a extensión.",
            "Error típico: usar kip o balanceo de hombros.",
            "Exhala al subir.",
            "Progresión: strict T2B. Escala a foot-supported raises.",
            "Estándar: sin kip y rodillas a altura prescrita.",
        ),
        equipment="Barra",
        target="abs",
        secondary=["hip flexors", "forearms"],
        body="waist",
        primaries=["abs"],
        secondaries=["forearm"],
    )
    put(
        c,
        "Strict Knees To Chest",
        desc="Rodillas al pecho estrictas colgado de la barra.",
        instr=steps(
            "Cuelga activo; sin balanceo previo.",
            "Lleva rodillas hasta tocar o acercar al pecho.",
            "Baja con control a piernas largas.",
            "Error típico: kip oculto o no acercar rodillas al pecho.",
            "Exhala al subir.",
            "Progresión: strict T2B.",
            "Estándar: rodillas al pecho sin impulso.",
        ),
        equipment="Barra",
        target="abs",
        secondary=["hip flexors", "forearms"],
        body="waist",
        primaries=["abs"],
        secondaries=["forearm"],
    )
    put(
        c,
        "Hanging Hip Touch",
        desc="Colgado, toque de mano a cadera/ilíaco (estándar de algunos WODs).",
        instr=steps(
            "Cuelga activo de la barra.",
            "Lleva una o ambas manos a tocar la cadera/ilíaco según el WOD.",
            "Vuelve a colgar de la barra sin caer.",
            "Error típico: no hacer contacto claro o soltar ambos agarres a la vez sin control.",
            "Mantén el cuerpo quieto; evita balanceo excesivo.",
            "Progresión: más toques seguidos.",
            "Estándar: contacto claro mano-cadera en cada rep.",
        ),
        equipment="Barra",
        target="abs",
        secondary=["shoulders", "forearms"],
        body="waist",
        primaries=["abs"],
        secondaries=["forearm", "deltoids"],
    )

    # Core / floor
    for name, desc, s1, s2, s3, target, prim in [
        (
            "Bird Dog",
            "Cuadrupedia: extiende brazo y pierna contrarios con pelvis estable.",
            "A cuatro patas; columna neutra.",
            "Extiende brazo y pierna opuestos sin rotar la cadera.",
            "Vuelve y alterna.",
            "core",
            ["abs"],
        ),
        (
            "Dead Bug",
            "Boca arriba: brazo y pierna contrarios con lumbar pegada al suelo.",
            "Boca arriba, brazos arriba y rodillas a 90°.",
            "Extiende un brazo y la pierna opuesta sin arching lumbar.",
            "Vuelve y alterna.",
            "core",
            ["abs"],
        ),
        (
            "Flutter Kick",
            "Patada de flutter boca arriba con lumbar controlada.",
            "Boca arriba; cabeza y hombros ligeramente elevados si se prescribe.",
            "Patadas cortas alternas con piernas extendidas.",
            "No dejes que la lumbar se separe del suelo.",
            "abs",
            ["abs"],
        ),
        (
            "Russian Twist",
            "Giro de torso sentado con o sin carga.",
            "Sentado, torso atrás a ~45°; pies elevados o apoyados.",
            "Gira el torso y toca el suelo/carga a cada lado.",
            "Gira desde el tronco, no solo los brazos.",
            "abs",
            ["abs"],
        ),
        (
            "Side Plank",
            "Plancha lateral apoyada en antebrazo o mano.",
            "Apoyo en antebrazo/mano y canto del pie; cuerpo en línea.",
            "Mantén cadera alta sin hundir ni rotar.",
            "Respira; cambia de lado al terminar el intervalo.",
            "core",
            ["abs"],
        ),
        (
            "Superman",
            "Boca abajo: eleva brazos y piernas (extensión lumbar/glúteos).",
            "Boca abajo, brazos delante.",
            "Eleva pecho, brazos y piernas a la vez; pausa breve.",
            "Baja con control sin rebotar.",
            "upper-back",
            ["upper-back", "gluteal"],
        ),
        (
            "Glute Bridge",
            "Puente de glúteos boca arriba.",
            "Boca arriba, pies cerca de glúteos.",
            "Extiende cadera hasta línea hombros-rodillas; aprieta glúteos.",
            "Baja sin perder el contacto de los pies.",
            "glutes",
            ["gluteal"],
        ),
        (
            "Single Leg Glute Bridge",
            "Puente de glúteos a una pierna.",
            "Una pierna apoyada; la otra extendida o flexionada al pecho.",
            "Extiende cadera sin rotar la pelvis.",
            "Baja con control y completa las reps antes de cambiar.",
            "glutes",
            ["gluteal"],
        ),
        (
            "Copenhagen Plank",
            "Plancha lateral con apoyo de pierna superior en banco (aductores).",
            "Antebrazo en el suelo; pierna de arriba en banco.",
            "Eleva cadera; pierna inferior puede colgar o apoyar según nivel.",
            "Mantén el cuerpo alineado; cambia de lado.",
            "core",
            ["abs"],
        ),
        (
            "Wall Sit",
            "Isométrico de sentadilla contra la pared.",
            "Espalda pegada a la pared; muslos paralelos al suelo.",
            "Mantén rodillas a 90° y talones abajo.",
            "No te apoyes en las manos; respira continuo.",
            "quads",
            ["quadriceps"],
        ),
        (
            "Pallof Press",
            "Press anti-rotación con cable o banda a la altura del pecho.",
            "De lado a la ancla; agarra el mango al pecho.",
            "Extiende los brazos al frente sin girar el tronco.",
            "Vuelve al pecho con control; cambia de lado.",
            "core",
            ["abs"],
        ),
        (
            "Crab Walk",
            "Desplazamiento en posición de cangrejo (cadera alta).",
            "Sentado; manos detrás y pies apoyados; eleva cadera.",
            "Camina delante/atrás o lateral manteniendo cadera alta.",
            "No dejes caer la pelvis.",
            "glutes",
            ["gluteal", "triceps"],
        ),
        (
            "Mountain Climber",
            "Escalador en plancha: rodillas al pecho en alternancia.",
            "Plancha alta con hombros sobre las muñecas.",
            "Alterna rodillas al pecho a ritmo; cadera estable.",
            "No piques ni subas de más la pelvis.",
            "abs",
            ["abs", "quadriceps"],
        ),
        (
            "Jumping Jack",
            "Salto tijera: abre y cierra piernas y brazos.",
            "De pie; salta abriendo piernas y brazos por encima.",
            "Vuelve a posición cerrada en el siguiente salto.",
            "Aterriza suave; ritmo constante.",
            "cardiovascular system",
            ["quadriceps", "shoulders"],
        ),
        (
            "Skater Jump",
            "Saltos laterales tipo patinador con recepción a una pierna.",
            "Salta lateralmente de un pie al otro.",
            "Recibe con control e inclina ligeramente el torso.",
            "El pie libre puede rozar atrás para equilibrio.",
            "glutes",
            ["gluteal", "quadriceps"],
        ),
        (
            "Tuck Jump",
            "Salto vertical llevando rodillas al pecho.",
            "Salta y lleva rodillas arriba; pecho erguido.",
            "Aterriza suave con ligera flexión.",
            "No te desplomes en la recepción.",
            "quads",
            ["quadriceps", "calves"],
        ),
        (
            "Crossover Single Under",
            "Comba: simple con cruce de brazos (crossover).",
            "Salta a ritmo de single-under.",
            "Cruza los brazos delante del cuerpo y descruza entre saltos.",
            "Mantén saltos bajos y muñecas activas.",
            "cardiovascular system",
            ["calves", "shoulders"],
        ),
    ]:
        put(
            c,
            name,
            desc=desc,
            instr=steps(
                s1,
                s2,
                s3,
                "Error típico: perder la alineación o usar impulso que invalide el patrón.",
                "Respira de forma continua; no bloquees el aire.",
                "Progresión: más tiempo, más reps o más control/tempo.",
                f"Estándar: cada rep o segundo de {name} mantiene la posición correcta.",
            ),
            equipment="Peso corporal" if name != "Pallof Press" else "Cable / banda",
            target=target,
            secondary=["core"],
            body="waist" if target in ("abs", "core") else "full body",
            primaries=prim if isinstance(prim, list) else [prim],
            secondaries=["abs"] if "abs" not in (prim if isinstance(prim, list) else [prim]) else ["obliques"],
        )

    # Posterior chain machines / GHD-like
    put(
        c,
        "Glute Ham Raise",
        desc="GHR: extensión de rodilla/cadera en banco GHD para isquios y glúteos.",
        instr=steps(
            "Ajusta el GHD; rodillas en el pad y tobillos seguros.",
            "Baja el torso con control y vuelve extendiendo rodillas/cadera.",
            "Mantén una línea limpia; evita hiperextender la lumbar.",
            "Error típico: usar impulso de brazos o acortar el rango.",
            "Exhala al subir.",
            "Progresión: más rango o lastre. Escala a nordic asistido.",
            "Estándar: rango completo controlado en cada rep.",
        ),
        equipment="GHD",
        target="hamstrings",
        secondary=["glutes", "calves", "core"],
        body="upper legs",
        primaries=["hamstring", "gluteal"],
        secondaries=["calves", "abs"],
    )
    put(
        c,
        "Nordic Curl",
        desc="Curl nórdico: excéntrico de isquios con tobillos fijados.",
        instr=steps(
            "Arrodíllate con tobillos fijados (pareja, banco o anclaje).",
            "Baja el torso hacia delante lo más lento posible resistiendo con isquios.",
            "Empuja el suelo con las manos al fallar y vuelve a la vertical.",
            "Error típico: caer de golpe o flexionar de más la cadera.",
            "Exhala en la bajada controlada.",
            "Progresión: más rango sin manos. Escala con banda.",
            "Estándar: excéntrico controlado hasta el fallo técnico.",
        ),
        equipment="Anclaje / pareja",
        target="hamstrings",
        secondary=["glutes", "core"],
        body="upper legs",
        primaries=["hamstring"],
        secondaries=["gluteal", "abs"],
    )
    put(
        c,
        "Reverse Hyper",
        desc="Hiperextensión inversa: piernas atrás/arriba con torso fijo.",
        instr=steps(
            "Torso sobre el banco/reverse hyper; agarra los agarres.",
            "Eleva las piernas atrás hasta línea con el torso o algo más.",
            "Baja con control sin balanceo excesivo.",
            "Error típico: hiperextender lumbar con impulso.",
            "Exhala al subir; glúteos e isquios activos.",
            "Progresión: más carga en el aparato.",
            "Estándar: extensión de cadera controlada en cada rep.",
        ),
        equipment="Reverse hyper",
        target="glutes",
        secondary=["hamstrings", "lower-back"],
        body="upper legs",
        primaries=["gluteal", "hamstring"],
        secondaries=["upper-back"],
    )
    put(
        c,
        "Ring Hamstring Curl",
        desc="Curl femoral en anillas: talones en anillas y cadera alta.",
        instr=steps(
            "Boca arriba; talones en anillas y cadera en puente.",
            "Flexiona rodillas acercando los talones sin dejar caer la cadera.",
            "Extiende de nuevo con control.",
            "Error típico: hundir la pelvis o abrir las rodillas.",
            "Exhala al flexionar.",
            "Progresión: más extensión de partida (más difícil).",
            "Estándar: cadera alta y flexión completa de rodilla.",
        ),
        equipment="Anillas",
        target="hamstrings",
        secondary=["glutes", "core"],
        body="upper legs",
        primaries=["hamstring"],
        secondaries=["gluteal", "abs"],
    )
    put(
        c,
        "Jefferson Curl",
        desc="Curl de Jefferson: flexión vertebral segmentada con carga ligera.",
        instr=steps(
            "De pie con carga ligera; pies juntos o semijuntos.",
            "Flexiona vértebra a vértebra hacia delante hasta el rango cómodo.",
            "Enróllate de vuelta a erguido con control.",
            "Error típico: carga excesiva o movimiento brusco.",
            "Respira continuo; no fuerces dolor.",
            "Progresión: más rango con poca carga. No es un peso muerto convencional.",
            "Estándar: flexión y extensión segmentada controladas.",
        ),
        equipment="Barra / KB ligera",
        target="hamstrings",
        secondary=["upper-back", "core"],
        body="upper legs",
        primaries=["hamstring"],
        secondaries=["upper-back", "abs"],
    )

    # Medball
    put(
        c,
        "Medicine Ball Sit Up",
        desc="Sit-up con balón medicinal en el pecho o en extensión de brazos.",
        instr=steps(
            "Túmbate con medball en el pecho o brazos extendidos.",
            "Sit-up hasta torso vertical; el balón puede tocar los pies si se prescribe.",
            "Baja con control hasta hombros al suelo.",
            "Error típico: tirar del cuello o no tocar abajo/arriba.",
            "Exhala al subir.",
            "Progresión: balón más pesado o AbMat sit-up.",
            "Estándar: hombros abajo y torso arriba en cada rep.",
        ),
        equipment="Balón medicinal",
        target="abs",
        secondary=["hip flexors"],
        body="waist",
        primaries=["abs"],
        secondaries=[],
    )
    put(
        c,
        "Medicine Ball Throw",
        desc="Lanzamiento de balón medicinal (pecho, overhead o al suelo según WOD).",
        instr=steps(
            "Sujeta el balón; adopta el patrón prescrito (chest pass, overhead slam, rotational).",
            "Genera potencia desde piernas y tronco; suelta el balón con intención.",
            "Recoge o recibe según el estándar y repite.",
            "Error típico: lanzar solo con brazos o no usar la cadera.",
            "Exhala en el lanzamiento.",
            "Progresión: balón más pesado o más distancia.",
            "Estándar: cada lanzamiento cumple distancia/altura/pared prescrita.",
        ),
        equipment="Balón medicinal",
        target="shoulders",
        secondary=["core", "quads", "chest"],
        body="full body",
        primaries=["deltoids", "abs"],
        secondaries=["quadriceps", "chest"],
    )

    return c


def swift_str_list(xs: list[str]) -> str:
    inner = ", ".join(json.dumps(s, ensure_ascii=False) for s in xs)
    return f"[{inner}]"


def swift_cf_block(name: str, meta: dict) -> str:
    return (
        f'        cf("{name}", equipment: {json.dumps(meta["equipment"], ensure_ascii=False)}, '
        f'target: {json.dumps(meta["target"], ensure_ascii=False)},\n'
        f'           secondary: {swift_str_list(meta["secondary"])}, body: {json.dumps(meta["body"], ensure_ascii=False)},\n'
        f'           description: {json.dumps(meta["desc"], ensure_ascii=False)},\n'
        f'           instructions: {swift_str_list(meta["instr"])},\n'
        f'           primaries: {swift_str_list(meta["primaries"])}, secondaries: {swift_str_list(meta["secondaries"])}),'
    )


def patch_catalog_crossfit(content: dict[str, dict]) -> None:
    text = CF.read_text(encoding="utf-8")
    # Fix early-closed array: remove the stray ] after Box Squat block.
    text2 = re.sub(
        r'(primaries: \["quadriceps", "gluteal"\], secondaries: \["hamstring", "abs"\]\),\n)\s*\]\n(\n\s*// MARK: Fase D)',
        r"\1\2",
        text,
        count=1,
    )
    if text2 == text:
        # already fixed or different formatting
        if "// MARK: Fase D" in text and "\n    ]\n\n        // MARK: Fase D" in text:
            text2 = text.replace("\n    ]\n\n        // MARK: Fase D", "\n\n        // MARK: Fase D", 1)
    # Ensure closing bracket before private static func cf
    if re.search(r'cf\("Zercher Squat"[\s\S]*?\),\n\n    private static func cf', text2):
        text2 = re.sub(
            r'(cf\("Zercher Squat"[\s\S]*?\),)\n\n    private static func cf',
            r"\1\n    ]\n\n    private static func cf",
            text2,
            count=1,
        )
    elif "\n    ]\n\n    private static func cf" not in text2:
        text2 = text2.replace(
            "\n    private static func cf(",
            "\n    ]\n\n    private static func cf(",
            1,
        )

    for name, meta in content.items():
        pattern = re.compile(
            rf'        cf\("{re.escape(name)}",[\s\S]*?secondaries: \[[^\]]*\]\),',
            re.M,
        )
        block = swift_cf_block(name, meta)
        text2, n = pattern.subn(block, text2, count=1)
        if n != 1:
            print("WARN CF miss", name)

    CF.write_text(text2, encoding="utf-8")
    print("patched", CF)


def patch_catalog_spanish(content: dict[str, dict]) -> None:
    text = ES.read_text(encoding="utf-8")
    for name, meta in content.items():
        # description map
        desc_pat = re.compile(
            rf'        "{re.escape(name)}": "[^"]*",',
            re.M,
        )
        desc_line = f'        "{name}": {json.dumps(meta["desc"], ensure_ascii=False)},'
        text, n = desc_pat.subn(desc_line, text, count=1)
        if n != 1:
            # maybe multiline not applicable; try insert before closing of spanishByName if missing
            print("WARN ES desc", name, n)

        instr_pat = re.compile(
            rf'        "{re.escape(name)}": \[\n(?:            "[^"]*",\n)*            "[^"]*",\n        \],',
            re.M,
        )
        instr_block = (
            f'        "{name}": [\n'
            + "".join(f"            {json.dumps(s, ensure_ascii=False)},\n" for s in meta["instr"])
            + "        ],"
        )
        text, n = instr_pat.subn(instr_block, text, count=1)
        if n != 1:
            print("WARN ES instr", name, n)

    ES.write_text(text, encoding="utf-8")
    print("patched", ES)


def patch_seeds(content: dict[str, dict]) -> None:
    for path in (SEED_ANDROID, SEED_IOS):
        if not path.exists():
            print("skip missing", path)
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        by_name = {e["name"]: e for e in data}
        for name, meta in content.items():
            e = by_name.get(name)
            if not e:
                print("WARN seed miss", name, path.name)
                continue
            e["detailDescription"] = meta["desc"]
            e["instructions"] = meta["instr"]
            e["equipment"] = meta["equipment"]
            e["targetMuscle"] = meta["target"]
            e["muscleGroup"] = MUSCLE_GROUP.get(meta["target"], e.get("muscleGroup") or "Full body")
            e["secondaryMuscles"] = meta["secondary"]
            e["bodyPart"] = meta["body"]
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print("patched seed", path, len(content))


def emit_sql(content: dict[str, dict]) -> Path:
    lines = [
        "-- Auto-generated coaching rewrite for Fase D generics (2026-11-04).",
        "-- Applies description/instructions/equipment/primary_muscles; no new catalog rows.",
        "BEGIN;",
    ]
    for name, meta in sorted(content.items()):
        instr = meta["instr"]
        # postgres text[] literal
        instr_pg = "ARRAY[" + ",".join("'" + s.replace("'", "''") + "'" for s in instr) + "]"
        muscles = meta["primaries"] or [meta["target"]]
        muscles_pg = "ARRAY[" + ",".join("'" + m.replace("'", "''") + "'" for m in muscles) + "]"
        desc = meta["desc"].replace("'", "''")
        eq = meta["equipment"].replace("'", "''")
        lines.append(
            dedent_sql(
                f"""
            UPDATE training_exercise_metadata m
            SET description = '{desc}',
                instructions = {instr_pg},
                equipment = '{eq}',
                primary_muscles = {muscles_pg},
                updated_at = now()
            FROM business_exercise_catalog c
            WHERE m.catalog_key = c.catalog_key
              AND c.name = '{name.replace("'", "''")}'
              AND c.is_active;
            """
            )
        )
    lines.append("COMMIT;")
    out = ROOT / "supabase/migrations/20261104233000_phase_d_coaching_rewrite.sql"
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("wrote", out)
    return out


def dedent_sql(s: str) -> str:
    return "\n".join(line for line in s.strip().splitlines())


def curated_fed_phase_e() -> list[dict]:
    """High-value FED/OEDB gaps that are not near-duplicates of the 433."""
    # Keep tight: gym machines / isolation commonly searched, Spanish display name.
    return [
        {"name": "Cable Crunch", "name_es": "Crunch en polea", "equipment": "Polea", "target": "abs",
         "desc": "Crunch arrodillado en polea alta llevando los codos hacia los muslos.",
         "why": "FED machine core; no hay crunch en polea en el seed."},
        {"name": "Cable Lateral Raise", "name_es": "Elevaciones laterales en polea", "equipment": "Polea", "target": "shoulders",
         "desc": "Elevación lateral a una mano en polea baja.",
         "why": "Variante polea de elevaciones laterales."},
        {"name": "Chest Supported Row", "name_es": "Remo con apoyo de pecho", "equipment": "Banco, Mancuernas", "target": "upper-back",
         "desc": "Remo con pecho apoyado en banco inclinado; menos trampa lumbar.",
         "why": "Hueco claro vs remo mancuerna libre."},
        {"name": "Seated Leg Curl", "name_es": "Curl femoral sentado", "equipment": "Máquina", "target": "hamstrings",
         "desc": "Curl femoral en máquina sentado.",
         "why": "FED machine; el seed tiene curl femoral genérico pero no sentado."},
        {"name": "Lying Leg Curl", "name_es": "Curl femoral tumbado", "equipment": "Máquina", "target": "hamstrings",
         "desc": "Curl femoral en máquina tumbado.",
         "why": "Par del sentado; muy buscado en gym."},
        {"name": "Leg Extension", "name_es": "Extensión de cuádriceps", "equipment": "Máquina", "target": "quads",
         "desc": "Extensión de rodilla en máquina de cuádriceps.",
         "why": "Ya existe 'Extensión de cuádriceps' — ALIAS only."},
        {"name": "Pec Deck", "name_es": "Pec deck / mariposa máquina", "equipment": "Máquina", "target": "chest",
         "desc": "Aperturas en máquina pec deck.",
         "why": "Complementa Aperturas con mancuernas."},
        {"name": "Hip Abduction Machine", "name_es": "Abducción de cadera en máquina", "equipment": "Máquina", "target": "glutes",
         "desc": "Abducción de cadera sentado en máquina.",
         "why": "FED isolation glute/medio."},
        {"name": "Hip Adduction Machine", "name_es": "Aducción de cadera en máquina", "equipment": "Máquina", "target": "glutes",
         "desc": "Aducción de cadera sentado en máquina.",
         "why": "Par de abducción."},
        {"name": "Smith Machine Squat", "name_es": "Sentadilla en Smith", "equipment": "Smith", "target": "quads",
         "desc": "Sentadilla guiada en máquina Smith.",
         "why": "Variante de material muy habitual."},
        {"name": "T-Bar Row", "name_es": "Remo en T", "equipment": "Barra T / landmine", "target": "upper-back",
         "desc": "Remo en barra T o landmine con pecho algo inclinado.",
         "why": "Clásico gym ausente como ficha propia."},
        {"name": "Incline Dumbbell Curl", "name_es": "Curl inclinado con mancuernas", "equipment": "Mancuernas, Banco", "target": "biceps",
         "desc": "Curl en banco inclinado con estiramiento largo de bíceps.",
         "why": "Variante de curl mancuernas."},
        {"name": "Preacher Curl", "name_es": "Curl predicador", "equipment": "Banco predicador, Barra", "target": "biceps",
         "desc": "Curl en banco predicador.",
         "why": "Ya existe 'Curl predicador' — ALIAS only."},
        {"name": "Triceps Pushdown", "name_es": "Extensión de tríceps en polea", "equipment": "Polea", "target": "triceps",
         "desc": "Pushdown de tríceps en polea alta.",
         "why": "Cubre Extensión tríceps polea — ALIAS / confirm."},
        {"name": "Bulgarian Split Squat Dumbbell", "name_es": "Sentadilla búlgara con mancuernas", "equipment": "Mancuernas, Banco", "target": "quads",
         "desc": "Búlgara con mancuernas a los lados.",
         "why": "Material explícito sobre Sentadilla búlgara."},
        {"name": "Cable Face Pull", "name_es": "Face pull en polea", "equipment": "Polea", "target": "shoulders",
         "desc": "Face pull a la cara con cuerda en polea alta.",
         "why": "Ya existe Face pull — ALIAS."},
        {"name": "Walking Lunge", "name_es": "Zancadas caminando", "equipment": "Peso corporal / carga", "target": "quads",
         "desc": "Zancadas en desplazamiento hacia delante.",
         "why": "Patrón distinto a zancadas estáticas."},
        {"name": "Box Squat Dumbbell", "name_es": "Sentadilla a cajón con mancuernas", "equipment": "Mancuernas, Cajón", "target": "quads",
         "desc": "Sentadilla a cajón con mancuernas.",
         "why": "Variante DB de Box Squat."},
        {"name": "Arnold Press Dumbbell", "name_es": "Press Arnold", "equipment": "Mancuernas", "target": "shoulders",
         "desc": "Press Arnold con rotación de mancuernas.",
         "why": "ALIAS a Press Arnold."},
        {"name": "Cable Woodchop", "name_es": "Woodchop en polea", "equipment": "Polea", "target": "core",
         "desc": "Chop alto-bajo o bajo-alto en polea (anti-rotación/oblicuos).",
         "why": "Core rotacional ausente."},
    ]


def main() -> None:
    content = family_content()
    generic = json.loads((OUT / "phase_d_generic_names.json").read_text())
    missing = [n for n in generic if n not in content]
    extra = [n for n in content if n not in generic]
    print("content", len(content), "generic", len(generic), "missing", missing, "extra", extra)

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "phase_d_coaching_rewrite.json").write_text(
        json.dumps(content, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    phase_e = curated_fed_phase_e()
    (OUT / "phase_e_fed_shortlist.json").write_text(
        json.dumps(phase_e, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    if missing:
        raise SystemExit(f"Missing content for: {missing}")

    patch_catalog_crossfit(content)
    patch_catalog_spanish(content)
    patch_seeds(content)
    emit_sql(content)

    # sanity: no generic left in spanish instructions for these names
    es = ES.read_text(encoding="utf-8")
    still = [n for n in generic if GENERIC_START in es.split(f'"{n}": [', 1)[-1][:500]]
    print("still generic in ES after patch", len(still), still[:10])


if __name__ == "__main__":
    main()
