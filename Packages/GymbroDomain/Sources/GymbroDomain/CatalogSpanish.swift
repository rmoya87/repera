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

    private static let spanishInstructions: [String: [String]] = [
        "Press banca": [
            "Túmbate en el banco con los pies apoyados y la espalda pegada.",
            "Agarra la barra un poco más ancha que los hombros.",
            "Saca la barra y manténla sobre el pecho con brazos extendidos.",
            "Baja la barra controlada hasta el pecho, codos cerca del cuerpo.",
            "Empuja hacia arriba hasta extender los brazos.",
            "Repite el número de repeticiones deseado.",
        ],
        "Press banca inclinada": [
            "Coloca el banco a unos 30–45°.",
            "Túmbate y agarra la barra un poco más ancha que los hombros.",
            "Baja la barra hacia la parte alta del pecho.",
            "Empuja hacia arriba sin arquear la lumbar.",
            "Repite.",
        ],
        "Press mancuernas": [
            "Túmbate en banco plano con una mancuerna en cada mano sobre el pecho.",
            "Baja las mancuernas a los lados del pecho controlando el movimiento.",
            "Empuja hacia arriba hasta extender los brazos.",
            "Repite sin arquear la lumbar.",
        ],
        "Aperturas": [
            "Túmbate en un banco plano con una mancuerna en cada mano, brazos extendidos sobre el pecho y palmas enfrentadas.",
            "Con los codos ligeramente flexionados, abre los brazos hacia los lados hasta sentir el estiramiento en el pecho.",
            "Haz una pausa breve abajo sin forzar el hombro.",
            "Cierra los brazos juntando las mancuernas arriba, contrayendo el pecho.",
            "Repite sin arquear la zona lumbar.",
        ],
        "Fondos": [
            "Agárrate a las paralelas y súbete con los brazos extendidos.",
            "Inclínate ligeramente hacia delante y bloquea los hombros abajo.",
            "Baja flexionando los codos hasta sentir el pecho/tríceps.",
            "Empuja hacia arriba hasta extender los brazos.",
        ],
        "Dominadas": [
            "Cuelga de la barra con agarre pronado.",
            "Tira el pecho hacia la barra sin balanceo excesivo.",
            "Baja hasta extensión completa de brazos.",
        ],
        "Jalón al pecho": [
            "Ajusta el asiento y el soporte de rodillas.",
            "Siéntate erguido y agarra la barra ancha en pronación.",
            "Tira la barra hacia el pecho apretando omóplatos.",
            "Sube con control hasta extensión de brazos.",
        ],
        "Remo con barra": [
            "Bisagra de cadera, espalda plana, barra colgando.",
            "Tira la barra hacia el abdomen con los codos cerca.",
            "Aprieta omóplatos arriba y baja con control.",
        ],
        "Remo mancuerna": [
            "Apoya una rodilla y una mano en el banco.",
            "Tira la mancuerna hacia la cadera con el codo cerca.",
            "Baja con control y cambia de lado.",
        ],
        "Peso muerto": [
            "Barra sobre el mediopié, agarre fuera de las piernas.",
            "Espalda plana, brace el core.",
            "Empuja el suelo y levántate manteniendo la barra cerca.",
            "Bloquea cadera arriba sin hiperextender.",
            "Baja con control.",
        ],
        "Peso muerto rumano": [
            "Sujeta la barra a la altura de los muslos, rodillas blandas.",
            "Empuja la cadera atrás deslizando la barra por los muslos.",
            "Baja hasta sentir el estiramiento en isquios.",
            "Vuelve arriba empujando la cadera delante.",
        ],
        "Sentadilla": [
            "Barra sobre trapecios, pies al ancho de hombros.",
            "Baja flexionando cadera y rodillas hasta paralelo o más.",
            "Mantén el pecho alto y las rodillas alineadas con los pies.",
            "Empuja el suelo para levantarte.",
        ],
        "Sentadilla frontal": [
            "Barra en rack frontal, codos altos.",
            "Baja con torso vertical hasta paralelo.",
            "Empuja para levantarte manteniendo los codos altos.",
        ],
        "Prensa": [
            "Siéntate con la espalda apoyada y pies al ancho de hombros en la plataforma.",
            "Empuja la plataforma extendiendo las piernas sin bloquear de golpe.",
            "Baja con control hasta ~90° de rodilla.",
        ],
        "Zancadas": [
            "Da un paso adelante y baja la rodilla trasera hacia el suelo.",
            "Empuja con el pie delantero para volver.",
            "Alterna piernas o camina.",
        ],
        "Extensión de cuádriceps": [
            "Siéntate en la máquina con el rodillo sobre los tobillos.",
            "Extiende las rodillas sin balanceo.",
            "Baja con control.",
        ],
        "Curl femoral": [
            "Coloca los tobillos bajo el rodillo (tumbado o sentado).",
            "Flexiona las rodillas llevando los talones hacia los glúteos.",
            "Vuelve con control.",
        ],
        "Elevación de gemelos": [
            "Ponte de pie o siéntate con el peso sobre los hombros/muslos.",
            "Sube de puntillas lo más alto posible.",
            "Baja con control hasta estirar el gemelo.",
        ],
        "Press militar": [
            "Barra a la altura de los hombros, pies firmes.",
            "Empuja la barra arriba hasta extender los brazos.",
            "Baja con control hasta los hombros.",
        ],
        "Elevaciones laterales": [
            "Mancuernas a los lados, codos ligeramente flexionados.",
            "Eleva los brazos hasta la altura de los hombros.",
            "Baja con control.",
        ],
        "Pájaros": [
            "Inclínate hacia delante con espalda plana.",
            "Abre los brazos hacia los lados apretando omóplatos.",
            "Baja con control.",
        ],
        "Curl barra": [
            "Agarra la barra en supinación, codos pegados al cuerpo.",
            "Sube la barra flexionando los codos.",
            "Baja con control sin balanceo.",
        ],
        "Curl mancuernas": [
            "Mancuernas a los lados, palmas delante o neutras.",
            "Sube flexionando el codo sin mover el hombro.",
            "Baja con control.",
        ],
        "Curl martillo": [
            "Agarre neutro (pulgares arriba).",
            "Sube las mancuernas sin rotar la muñeca.",
            "Baja con control.",
        ],
        "Fondos en banco": [
            "Manos en el borde del banco, pies delante.",
            "Baja flexionando los codos.",
            "Empuja para subir sin encoger hombros.",
        ],
        "Extensión tríceps polea": [
            "Agarra la cuerda o barra en polea alta.",
            "Extiende los codos hacia abajo sin abrir los brazos.",
            "Vuelve con control.",
        ],
        "Press cerrado": [
            "Agarre más estrecho que en press banca.",
            "Baja la barra al pecho con codos cerca.",
            "Empuja hacia arriba enfatizando el tríceps.",
        ],
        "Plancha": [
            "Apóyate en antebrazos y puntas de los pies.",
            "Cuerpo en línea: abdomen y glúteos activos.",
            "Mantén sin hundir la lumbar.",
        ],
        "Crunch": [
            "Tumbado, rodillas flexionadas.",
            "Eleva el pecho hacia las rodillas contrayendo el abdomen.",
            "Baja con control.",
        ],
        "Elevación de piernas": [
            "Tumbado o colgado, piernas juntas.",
            "Eleva las piernas sin impulso excesivo.",
            "Baja con control.",
        ],
        "Hip thrust": [
            "Espalda alta apoyada en el banco, barra sobre la cadera.",
            "Empuja la cadera arriba hasta alinear torso y muslos.",
            "Baja con control.",
        ],
        "Face pull": [
            "Cuerda a la altura de la cara en polea.",
            "Tira hacia la cara abriendo los codos hacia fuera.",
            "Aprieta omóplatos y vuelve con control.",
        ],
        "Remo al mentón": [
            "Barra o mancuernas delante de los muslos.",
            "Tira hacia arriba con los codos altos hasta el pecho.",
            "Baja con control.",
        ],
        "Buenos días": [
            "Barra sobre la espalda, pies firmes.",
            "Bisagra de cadera manteniendo la espalda plana.",
            "Vuelve arriba extendiendo la cadera.",
        ],
        "Hack squat": [
            "Coloca los hombros bajo los almohadillados, pies en la plataforma.",
            "Baja en sentadilla guiada.",
            "Empuja para subir sin bloquear de golpe.",
        ],
        "Pullover": [
            "Tumbado, mancuerna sobre el pecho.",
            "Lleva la mancuerna atrás sobre la cabeza con codos blandos.",
            "Vuelve sobre el pecho contrayendo dorsales/pecho.",
        ],
        "Cinta / carrera": [
            "Calienta a ritmo cómodo.",
            "Mantén una cadencia constante según el objetivo.",
            "Termina con minutos suaves.",
        ],
        "Bici estática": [
            "Ajusta sillín y resistencia.",
            "Pedalea a cadencia estable.",
            "Mantén el tronco erguido.",
        ],
        "Remo máquina": [
            "Agarra el asa, espalda plana.",
            "Empuja con las piernas y luego tira con los brazos.",
            "Recupera en orden inverso.",
        ],
        "Farmer walk": [
            "Sujeta una carga pesada en cada mano.",
            "Camina erguido con pasos cortos y core activo.",
            "No dejes que las cargas te ladeen.",
        ],
        "Press banca declinado": [
            "Banco en ligera declinación.",
            "Baja la barra a la parte baja del pecho.",
            "Empuja hacia arriba con control.",
        ],
        "Cruce de poleas": [
            "Poleas altas, un asa en cada mano.",
            "Abre y cierra los brazos juntando las manos delante.",
            "Mantén una ligera flexión de codo.",
        ],
        "Remo sentado": [
            "Siéntate frente a la polea, pecho erguido.",
            "Tira el asa hacia el abdomen.",
            "Aprieta omóplatos y vuelve con control.",
        ],
        "Peso muerto sumo": [
            "Stance ancho, puntas hacia fuera, barra cerca.",
            "Coge la barra y levántate empujando el suelo.",
            "Bloquea cadera y baja con control.",
        ],
        "Sentadilla búlgara": [
            "Pie trasero elevado en banco, pie delantero firme.",
            "Baja la rodilla trasera hacia el suelo.",
            "Empuja con el pie delantero para subir.",
        ],
        "Curl predicador": [
            "Brazos apoyados en el banco predicador.",
            "Sube la barra o mancuerna flexionando el codo.",
            "Baja con control hasta casi extender.",
        ],
        "Press francés": [
            "Tumbado, barra o mancuerna sobre la frente/pecho.",
            "Flexiona solo los codos bajando la carga.",
            "Extiende los codos para subir.",
        ],
        "Elevaciones frontales": [
            "Mancuernas o disco delante de los muslos.",
            "Eleva hasta la altura de los hombros.",
            "Baja con control.",
        ],
        "Ab wheel": [
            "De rodillas, rueda delante.",
            "Extiende el cuerpo rodando hacia delante sin hundir la lumbar.",
            "Vuelve contrayendo el abdomen.",
        ],
        "Paso lateral con banda": [
            "Banda alrededor de tobillos o rodillas.",
            "Pasos laterales manteniendo tensión.",
            "Mantén las rodillas alineadas con los pies.",
        ],
        "Remo invertido": [
            "Cuelga bajo una barra con el cuerpo recto.",
            "Tira el pecho hacia la barra.",
            "Baja con control.",
        ],
        "Press Arnold": [
            "Mancuernas delante del pecho, palmas hacia ti.",
            "Rota las palmas hacia fuera mientras empujas arriba.",
            "Baja rotando de nuevo a la posición inicial.",
        ],
    ]
}
