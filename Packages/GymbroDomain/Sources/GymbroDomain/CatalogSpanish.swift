import Foundation

/// Localización ES del catálogo seed (descripciones + cómo hacerlo).
public enum CatalogSpanish {
    public static func localize(
        name: String,
        description: String?,
        instructions: [String]
    ) -> (description: String?, instructions: [String]) {
        let desc = spanishByName[name] ?? description.map(translateSentence)
        let steps = spanishInstructions[name] ?? instructions.map(translateSentence)
        return (desc, steps)
    }

    public static func description(forName name: String) -> String? {
        spanishByName[name]
    }

    public static func instructions(forName name: String) -> [String]? {
        spanishInstructions[name]
    }

    public static func translateSentence(_ raw: String) -> String {
        let lower = raw.lowercased()
        let looksSpanish = lower.contains(" el ") || lower.contains(" la ") || lower.contains(" los ")
            || lower.contains(" las ") || lower.contains(" con ") || lower.contains(" hacia ")
            || lower.contains("túmbate") || lower.contains("mantén") || lower.contains("ponte")
            || lower.hasPrefix("baja ") || lower.hasPrefix("empuja ") || lower.hasPrefix("agarra ")
            || lower.hasPrefix("sujeta ") || lower.hasPrefix("siéntate ")
        if looksSpanish { return raw }

        var s = raw
        for (en, es) in phrasePairs {
            s = s.replacingOccurrences(of: en, with: es, options: .caseInsensitive)
        }
        return s
    }

    private static let phrasePairs: [(String, String)] = [
        ("Lie flat on a bench with your feet flat on the ground and your back pressed against the bench.", "Túmbate en un banco con los pies apoyados y la espalda pegada al banco."),
        ("Lie flat on a bench", "Túmbate en un banco"),
        ("with your feet flat on the ground", "con los pies apoyados en el suelo"),
        ("Grasp the barbell with an overhand grip slightly wider than shoulder-width apart.", "Agarra la barra en pronación un poco más ancha que los hombros."),
        ("Lift the barbell off the rack and hold it directly above your chest with your arms fully extended.", "Saca la barra del rack y manténla sobre el pecho con los brazos extendidos."),
        ("Lower the barbell slowly towards your chest, keeping your elbows tucked in.", "Baja la barra despacio hacia el pecho, con los codos cerca del cuerpo."),
        ("Pause for a moment when the barbell touches your chest.", "Haz una pausa cuando la barra toque el pecho."),
        ("Push the barbell back up to the starting position by extending your arms.", "Empuja la barra hacia arriba extendiendo los brazos."),
        ("Repeat for the desired number of repetitions.", "Repite el número de repeticiones deseado."),
        ("Hold a dumbbell in each hand", "Sujeta una mancuerna en cada mano"),
        ("Lower the dumbbells slowly", "Baja las mancuernas despacio"),
        ("Push the dumbbells back up", "Empuja las mancuernas hacia arriba"),
        ("A chest fly with chains adding load.", "Aperturas de pecho con mancuernas: abres y cierras los brazos para trabajar el pectoral."),
        ("The classic flat bench press.", "El press de banca clásico en banco plano."),
        ("Lower the bar to your chest and press it up to build the chest, shoulders and triceps.", "Baja la barra al pecho y empújala arriba: pecho, hombros y tríceps."),
        ("Stand with your feet shoulder-width apart", "Ponte de pie con los pies al ancho de hombros"),
        ("Keep your back straight", "Mantén la espalda recta"),
        ("Engage your core", "Activa el core"),
        ("Hold the position", "Mantén la posición"),
        ("Slowly", "Despacio"),
        ("Pause for a moment", "Haz una pausa breve"),
        ("shoulder-width apart", "al ancho de hombros"),
        ("feet flat on the ground", "pies apoyados en el suelo"),
        ("keeping your elbows", "manteniendo los codos"),
        ("starting position", "posición inicial"),
        ("desired number of repetitions", "número de repeticiones deseado"),
    ]

    private static let spanishByName: [String: String] = [
        "Press banca": "Press de banca clásico con barra: bajas la barra al pecho y la empujas arriba. Trabaja pecho, hombros y tríceps.",
        "Press banca inclinada": "Press en banco inclinado: más énfasis en la parte alta del pecho y los hombros.",
        "Press mancuernas": "Press con mancuernas en banco plano: mayor rango de movimiento que con barra.",
        "Aperturas": "Aperturas con mancuernas en banco plano: abres y cierras los brazos para estirar y contraer el pecho, con los codos ligeramente flexionados.",
        "Fondos": "Fondos en paralelas: bajas y subes el cuerpo con los brazos. Pecho o tríceps según la inclinación.",
        "Dominadas": "Dominadas: tiras el pecho hacia la barra. Trabaja espalda y brazos.",
        "Jalón al pecho": "Jalón al pecho en polea: tiras la barra hacia el pecho sentado. Dorsales y agarre.",
        "Remo con barra": "Remo con barra: tiras la barra hacia el abdomen con la espalda inclinada.",
        "Remo mancuerna": "Remo con mancuerna a una mano, apoyado en banco.",
        "Peso muerto": "Peso muerto con barra: bisagra de cadera hasta de pie. Posterior completo y agarre.",
        "Peso muerto rumano": "Peso muerto rumano: bisagra con poca flexión de rodilla; isquios y glúteos.",
        "Sentadilla": "Sentadilla con barra: bajas hasta paralelo o más y te levantas. Piernas y core.",
        "Sentadilla frontal": "Sentadilla frontal: barra en rack frontal, torso más vertical; cuádriceps.",
        "Prensa": "Prensa de piernas: empujas la plataforma con las piernas.",
        "Zancadas": "Zancadas: paso adelante o caminando; piernas unilateral.",
        "Extensión de cuádriceps": "Extensión de cuádriceps en máquina.",
        "Curl femoral": "Curl femoral: flexión de rodilla para isquiotibiales.",
        "Elevación de gemelos": "Elevación de gemelos de pie o sentado.",
        "Press militar": "Press militar / overhead: empujas la barra desde los hombros arriba.",
        "Elevaciones laterales": "Elevaciones laterales con mancuernas: deltoides medio.",
        "Pájaros": "Pájaros / elevaciones posteriores: deltoides posterior y espalda alta.",
        "Curl barra": "Curl de bíceps con barra.",
        "Curl mancuernas": "Curl de bíceps con mancuernas.",
        "Curl martillo": "Curl martillo: agarre neutro; bíceps y braquial.",
        "Fondos en banco": "Fondos en banco: tríceps con manos en el borde del banco.",
        "Extensión tríceps polea": "Extensión de tríceps en polea alta.",
        "Press cerrado": "Press banca agarre cerrado: más énfasis en tríceps.",
        "Plancha": "Plancha isométrica: cuerpo en línea, abdomen activo.",
        "Crunch": "Crunch abdominal: flexiona el tronco acercando costillas a pelvis.",
        "Elevación de piernas": "Elevación de piernas: abdominales inferiores.",
        "Hip thrust": "Hip thrust: empuje de cadera con espalda en banco; glúteos.",
        "Face pull": "Face pull en polea: deltoides posterior y estabilizadores del hombro.",
        "Remo al mentón": "Remo al mentón: tiras la barra hacia el pecho con codos altos.",
        "Buenos días": "Buenos días: bisagra de cadera con barra en espalda.",
        "Hack squat": "Hack squat en máquina: sentadilla guiada.",
        "Pullover": "Pullover con mancuerna: dorsales y pecho.",
        "Cinta / carrera": "Carrera en cinta o outdoor para cardio.",
        "Bici estática": "Bici estática: cardio de piernas.",
        "Remo máquina": "Remoergómetro: cardio de cuerpo completo.",
        "Farmer walk": "Paseo del granjero: camina erguido con carga en cada mano.",
        "Press banca declinado": "Press banca declinado: más énfasis en pecho inferior.",
        "Cruce de poleas": "Cruce de poleas: aperturas con tensión constante.",
        "Remo sentado": "Remo sentado en polea: espalda media.",
        "Peso muerto sumo": "Peso muerto sumo: stance ancho.",
        "Sentadilla búlgara": "Sentadilla búlgara: pierna trasera elevada.",
        "Curl predicador": "Curl predicador: bíceps con brazos apoyados.",
        "Press francés": "Press francés / extensión de tríceps tumbado.",
        "Elevaciones frontales": "Elevaciones frontales: deltoides anterior.",
        "Ab wheel": "Rueda abdominal: rollout de core.",
        "Paso lateral con banda": "Pasos laterales con banda: glúteo medio.",
        "Remo invertido": "Remo invertido: remo con peso corporal.",
        "Press Arnold": "Press Arnold: press con rotación de mancuernas.",
        "Burpee": "Burpee: pecho al suelo, salto y palmada.",
        "Thruster": "Thruster: sentadilla frontal + press overhead.",
        "Wall ball": "Wall ball: sentadilla con balón y lanzamiento a diana.",
        "Dobles de comba": "Double unders: la comba pasa dos veces por salto.",
        "Simples de comba": "Single unders: un paso de comba por salto.",
    ]

    // Si un ejercicio tiene arte `base_1…N`, los N primeros textos deben describir
    // exactamente la pose de cada imagen del carrusel (ver ExerciseArtView).
    // Si un ejercicio tiene arte `base_1…N`, los N primeros textos describen
    // la pose de cada imagen del carrusel (cues de entrenador + hitos visuales).
    private static let spanishInstructions: [String: [String]] = [
        "Burpee": [
            "Pecho y muslos al suelo: manos a los lados, cuerpo plano.",
            "Salta los pies hacia las manos y quédate en cuclillas con el pecho alto.",
            "Extiende cadera y salta con palmada arriba.",
        ],
        "Press banca": [
            "Túmbate, pies firmes: baja la barra al pecho medio con codos ~45°.",
            "Empuja a bloqueo sin arquear la lumbar: barra sobre el pecho, brazos extendidos.",
        ],
        "Press banca inclinada": [
            "Banco 30–45°: baja la barra a pecho alto/clavícula, omóplatos retraídos.",
            "Empuja a bloqueo en línea con el pecho alto.",
        ],
        "Press mancuernas": [
            "Mancuernas a los lados del pecho, muñecas sobre codos.",
            "Extiende arriba juntando ligeramente las mancuernas.",
        ],
        "Aperturas": [
            "Cierra el arco: mancuernas casi juntas sobre el esternón, codos blandos.",
            "Abre en arco amplio hasta estirar el pecho, mancuernas a la altura del torso.",
        ],
        "Fondos": [
            "Soporte: brazos bloqueados, hombros bajos, pecho abierto.",
            "Baja hasta ~90° de codo, torso ligero hacia delante.",
            "Empuja a bloqueo sin encoger trapecios.",
        ],
        "Dominadas": [
            "Cuelga muerto: brazos totalmente extendidos, hombros activos.",
            "Tira hasta que la barbilla pase la barra, pecho arriba.",
        ],
        "Chest to bar": [
            "Cuelga con brazos extendidos y agarre firme.",
            "Tira hasta la barbilla cerca de la barra.",
            "Lleva el pecho a tocar la barra y baja con control.",
        ],
        "Cargada colgante": [
            "Barra en muslos, bisagra ligera, espalda plana.",
            "Extiende cadera y tira: barra sube pegada al cuerpo.",
            "Recibe en rack frontal (barra delante del cuello, codos altos) y párate.",
        ],
        "Fondos en anillas": [
            "Soporte en anillas: brazos bloqueados, anillas junto a cadera.",
            "Baja hasta hombros por debajo de los codos.",
            "Empuja de nuevo a soporte bloqueado.",
        ],
        "GHD sit-up": [
            "Fija los pies en los rodillos e inclina el tronco hacia atrás con control.",
            "Flexiona el tronco y lleva los brazos hacia delante sin soltar el apoyo.",
            "Termina de incorporarte manteniendo la cadera sobre el apoyo de la máquina.",
        ],
        "Jalón al pecho": [
            "Brazos extendidos sujetando la barra alta.",
            "Tira a mitad hacia el pecho alto.",
            "Barra al pecho apretando dorsales; sube con control.",
        ],
        "Remo con barra": [
            "Bisagra, barra colgando, espalda plana.",
            "Tira a mitad hacia el abdomen.",
            "Barra al abdomen, omóplatos juntos; baja con control.",
        ],
        "Remo mancuerna": [
            "Apoyo en banco, mancuerna colgando a brazo largo.",
            "Tira el codo hacia la cadera a mitad.",
            "Contracción arriba junto a la cadera; baja con control.",
        ],
        "Peso muerto": [
            "Barra sobre mediopié, agarre fuera de piernas, espalda plana.",
            "Empuja el suelo y bloquea cadera de pie sin hiperextender.",
        ],
        "Peso muerto rumano": [
            "Colócate de pie con la barra frente a los muslos y las rodillas ligeramente flexionadas.",
            "Lleva la cadera atrás y baja la barra cerca de las piernas manteniendo la espalda neutra.",
        ],
        "Sentadilla": [
            "Barra sobre trapecios, pies al ancho de hombros, pecho alto.",
            "Baja a paralelo o más, rodillas alinea con pies, y empuja para subir.",
        ],
        "Sentadilla frontal": [
            "Barra en rack frontal (delante del cuello), codos altos, de pie.",
            "Baja a paralelo o más con torso vertical y codos altos; empuja el suelo y vuelve.",
        ],
        "Prensa": [
            "Espalda apoyada, pies al ancho de hombros en la plataforma.",
            "Empuja extendiendo piernas sin bloquear de golpe.",
            "Baja con control hasta ~90° de rodilla.",
        ],
        "Zancadas": [
            "De pie con mancuernas a los lados.",
            "Da el paso y baja a media zancada.",
            "Rodilla trasera cerca del suelo; empuja para volver.",
        ],
        "Extensión de cuádriceps": [
            "Siéntate con el rodillo sobre los tobillos.",
            "Extiende las rodillas sin balanceo.",
            "Baja con control.",
        ],
        "Curl femoral": [
            "Tobillos bajo el rodillo.",
            "Flexiona llevando talones a glúteos.",
            "Vuelve con control.",
        ],
        "Elevación de gemelos": [
            "Peso sobre hombros/muslos, pies firmes.",
            "Sube de puntillas al máximo.",
            "Baja estirando el gemelo.",
        ],
        "Press militar": [
            "Barra a hombros/front rack, torso rígido.",
            "Empuja a bloqueo overhead sin arquear lumbar.",
        ],
        "Elevaciones laterales": [
            "Mancuernas a los lados, codos blandos.",
            "Eleva hasta la altura de hombros.",
            "Baja con control.",
        ],
        "Pájaros": [
            "Inclínate con espalda plana.",
            "Abre brazos apretando omóplatos.",
            "Baja con control.",
        ],
        "Curl barra": [
            "Barra colgando, codos pegados al torso.",
            "Curl a mitad sin balancear.",
            "Arriba cerca del pecho; baja con control.",
        ],
        "Curl mancuernas": [
            "Mancuernas a los lados.",
            "Sube flexionando el codo sin mover el hombro.",
            "Baja con control.",
        ],
        "Curl martillo": [
            "Agarre neutro, pulgares arriba.",
            "Sube sin rotar la muñeca.",
            "Baja con control.",
        ],
        "Fondos en banco": [
            "Manos en el borde del banco, pies delante.",
            "Baja flexionando codos.",
            "Empuja sin encoger hombros.",
        ],
        "Extensión tríceps polea": [
            "Agarra cuerda/barra en polea alta.",
            "Extiende los codos hacia abajo.",
            "Vuelve con control.",
        ],
        "Press cerrado": [
            "Agarre estrecho en banca.",
            "Baja al pecho con codos cerca.",
            "Empuja enfatizando tríceps.",
        ],
        "Plancha": [
            "Antebrazos y puntas de pies.",
            "Cuerpo en línea: abdomen y glúteos activos.",
            "Mantén sin hundir la lumbar.",
        ],
        "Crunch": [
            "Tumbado, rodillas flexionadas.",
            "Eleva el pecho hacia las rodillas.",
            "Baja con control.",
        ],
        "Elevación de piernas": [
            "Tumbado o colgado, piernas juntas.",
            "Eleva sin impulso excesivo.",
            "Baja con control.",
        ],
        "Hip thrust": [
            "Hombros en banco, barra en cadera, cadera BAJA cerca del suelo.",
            "Empuja cadera hasta alinear torso y muslos; aprieta glúteo.",
        ],
        "Face pull": [
            "Cuerda a la altura de la cara.",
            "Tira a la cara abriendo codos.",
            "Aprieta omóplatos y vuelve.",
        ],
        "Remo al mentón": [
            "Barra/mancuernas delante de muslos.",
            "Tira con codos altos hasta el pecho.",
            "Baja con control.",
        ],
        "Buenos días": [
            "Barra en espalda, pies firmes.",
            "Bisagra manteniendo espalda plana.",
            "Vuelve extendiendo la cadera.",
        ],
        "Hack squat": [
            "Hombros bajo almohadillas, pies en plataforma.",
            "Baja en sentadilla guiada.",
            "Empuja sin bloquear de golpe.",
        ],
        "Pullover": [
            "Tumbado, mancuerna sobre el pecho.",
            "Lleva la mancuerna atrás sobre la cabeza.",
            "Vuelve al pecho contrayendo.",
        ],
        "Cinta / carrera": [
            "Calienta a ritmo cómodo.",
            "Mantén cadencia según el objetivo.",
            "Termina con minutos suaves.",
        ],
        "Bici estática": [
            "Ajusta sillín y resistencia.",
            "Pedalea a cadencia estable.",
            "Mantén el tronco erguido.",
        ],
        "Remo máquina": [
            "Agarra el asa, espalda plana.",
            "Empuja con piernas y luego tira con brazos.",
            "Recupera en orden inverso.",
        ],
        "Farmer walk": [
            "Carga pesada en cada mano.",
            "Camina erguido, pasos cortos, core activo.",
            "No dejes que las cargas te ladeen.",
        ],
        "Press banca declinado": [
            "Banco en ligera declinación.",
            "Baja la barra a la parte baja del pecho.",
            "Empuja hacia arriba con control.",
        ],
        "Cruce de poleas": [
            "Poleas altas, un asa en cada mano.",
            "Cierra juntando las manos delante.",
            "Mantén ligera flexión de codo.",
        ],
        "Remo sentado": [
            "Sentado frente a la polea, pecho erguido.",
            "Tira el asa hacia el abdomen.",
            "Aprieta omóplatos y vuelve.",
        ],
        "Peso muerto sumo": [
            "Stance ancho, puntas fuera, barra cerca.",
            "Levanta empujando el suelo.",
            "Bloquea cadera y baja con control.",
        ],
        "Sentadilla búlgara": [
            "Pie trasero en banco, torso erguido.",
            "Baja a media profundidad sobre la pierna delantera.",
            "Rodilla trasera cerca del suelo; empuja para subir.",
        ],
        "Curl predicador": [
            "Brazos apoyados en el predicador.",
            "Sube flexionando el codo.",
            "Baja con control casi a extensión.",
        ],
        "Press francés": [
            "Brazos extendidos, barra sobre el pecho.",
            "Flexiona codos bajando la barra.",
            "Barra cerca de la frente; extiende de nuevo.",
        ],
        "Elevaciones frontales": [
            "Mancuernas o disco delante de muslos.",
            "Eleva hasta la altura de hombros.",
            "Baja con control.",
        ],
        "Ab wheel": [
            "De rodillas, rueda delante.",
            "Rueda hacia delante sin hundir lumbar.",
            "Vuelve contrayendo el abdomen.",
        ],
        "Paso lateral con banda": [
            "Banda en tobillos o rodillas.",
            "Pasos laterales manteniendo tensión.",
            "Rodillas alineadas con los pies.",
        ],
        "Remo invertido": [
            "Cuelga bajo la barra con cuerpo recto.",
            "Tira el pecho a la barra.",
            "Baja con control.",
        ],
        "Press Arnold": [
            "Mancuernas delante del pecho, palmas hacia ti.",
            "Rota palmas hacia fuera mientras empujas.",
            "Baja rotando de nuevo al inicio.",
        ],

        // MARK: Gimnasia / skill
        "Muscle-up barra": [
            "Cuélgate de la barra con los brazos largos y sin apoyar los pies.",
            "Tira del torso sobre la barra y gira las muñecas durante la transición.",
            "Empuja la barra hasta quedar en soporte con los brazos completamente extendidos.",
        ],
        "Muscle-up anillas": [
            "Cuélgate de las dos anillas con los brazos largos y los pies suspendidos.",
            "Tira y acerca las anillas a la cintura mientras inclinas el torso hacia delante.",
            "Extiende los codos y mantente arriba con una anilla a cada lado del cuerpo.",
        ],
        "Toes to bar": [
            "Cuelga con hombros activos.",
            "Lleva piernas en pike hacia la barra.",
            "Toca la barra con los pies y baja controlado.",
        ],
        "HSPU": [
            "Pino contra la pared, brazos bloqueados.",
            "Baja la cabeza hacia el suelo con codos flexionados ~90°.",
            "Empuja hasta bloquear otra vez en pino.",
        ],
        "Wall walk": [
            "Plancha con pies cerca de la pared.",
            "Camina manos hacia la pared subiendo los pies.",
            "Pino pecho a la pared; baja con control.",
        ],
        "Pull-over barra": [
            "Cuelga y lleva pies hacia la barra.",
            "Rueda caderas sobre la barra.",
            "Termina en soporte encima de la barra.",
        ],
        "Skin the cat": [
            "Cuelga de anillas/barra con agarre firme.",
            "Pasa los pies entre los brazos en tuck hacia atrás.",
            "Extiende o vuelve con control sin soltar.",
        ],
        "Kip swing": [
            "Cuelga en hollow: cuerpo cerrado, pies delante.",
            "Abre a arch: pecho y cadera delante, piernas atrás.",
            "Alterna hollow–arch con hombros activos.",
        ],
        "Fondos en paralelas": [
            "Sujeta las paralelas con brazos extendidos, hombros estables y pies suspendidos.",
            "Flexiona los codos y baja el torso entre las barras sin apoyar los pies.",
        ],
        "Rope climb": [
            "Salta y agarra la cuerda alto.",
            "Enrola piernas (J-hook/wrap) y estira.",
            "Sube a tramos y baja controlado.",
        ],

        // MARK: Halterofilia / CF
        "Arrancada": [
            "Setup: barra sobre mediopié, AGARRE ANCHO de snatch, espalda plana.",
            "Tirón: extiende cadera y rodillas; barra sube pegada con agarre ancho.",
            "Bloquea overhead de pie, brazos extendidos, agarre ancho.",
        ],
        "Cargada": [
            "Setup: barra sobre mediopié, agarre de clean.",
            "Recibe en front squat: barra delante del cuello, codos altos, cadera baja.",
            "Párate en rack frontal bloqueado.",
        ],
        "Split jerk": [
            "Front rack, dip corto de piernas.",
            "Drive y split: un pie delante, otro atrás, brazos bloqueados overhead.",
            "Recupera pie delantero y luego el trasero bajo la barra.",
        ],
        "Cargada y envión": [
            "Rack frontal tras la cargada, de pie.",
            "Dip-drive: flexión corta y empuje.",
            "Bloquea overhead y recupera pies.",
        ],
        "Overhead squat": [
            "Barra bloqueada overhead, agarre ancho, de pie.",
            "Siéntate profundo manteniendo la barra activa.",
            "Levántate sin perder el bloqueo.",
        ],
        "Thruster": [
            "Sujeta la barra delante de los hombros y desciende hasta una sentadilla frontal.",
            "Extiende caderas y rodillas al subir, manteniendo la barra sobre los hombros.",
            "Impulsa la misma barra sobre la cabeza hasta extender los brazos por completo.",
        ],
        "Turkish get-up": [
            "Túmbate y mantén una kettlebell sobre el hombro con el brazo totalmente extendido.",
            "Apoya la mano libre, eleva la cadera y mantén la kettlebell vertical.",
            "Termina de pie con el mismo brazo bloqueado y la kettlebell sobre la cabeza.",
        ],
        "Devil press": [
            "Pecho al suelo entre las mancuernas.",
            "Salta a cuclillas agarrando las mancuernas.",
            "Snatch ambas overhead en un movimiento.",
        ],
        "Wall ball": [
            "Sujeta el balón frente al pecho y baja a sentadilla mirando la diana.",
            "Extiende las piernas y lanza el balón hacia la diana con ambos brazos.",
            "Alza las manos y recibe el balón frente a la diana antes de volver a bajar.",
        ],
        "Cluster": [
            "Rack frontal tras la cargada.",
            "Sentadilla frontal profunda sin soltar el rack.",
            "Thruster a overhead en un solo tiempo.",
        ],
        "Burpee pull-up": [
            "Pecho al suelo bajo la barra.",
            "Agarra la barra y cuelga con brazos extendidos.",
            "Dominada: barbilla por encima de la barra.",
        ],
        "Salto al cajón": [
            "Pies firmes frente al cajón, carga de piernas.",
            "Salta: rodillas arriba, sobre el cajón en el aire.",
            "De pie sobre el cajón, cadera extendida.",
        ],
        "Box jump over": [
            "Flexiona frente al cajón, brazos atrás.",
            "Salta pasando POR ENCIMA del cajón.",
            "Aterriza al otro lado en el suelo, suave.",
        ],
        "Snatch kettlebell": [
            "KB entre los pies, bisagra de cadera.",
            "Extiende y guía la KB cerca del cuerpo.",
            "Bloquea overhead a brazo extendido.",
        ],
    ]

}
