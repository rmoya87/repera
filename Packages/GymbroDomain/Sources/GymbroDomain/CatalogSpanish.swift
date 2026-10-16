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
            "Pecho y muslos al suelo: manos a los lados, cuerpo plano (imagen: plancha baja, no plancha alta).",
            "Salta los pies hacia las manos y quédate en cuclillas con el pecho alto (imagen: squat sin peso, pies cerca de las manos).",
            "Extiende cadera y salta con palmada arriba (imagen: en el aire o aterrizando, brazos arriba; sin sombra de suelo si flotas).",
        ],
        "Press banca": [
            "Túmbate, pies firmes: baja la barra al pecho medio con codos ~45° (imagen: barra rozando el pecho).",
            "Empuja a bloqueo sin arquear la lumbar: barra sobre el pecho, brazos extendidos (imagen: lockout arriba).",
        ],
        "Press banca inclinada": [
            "Banco 30–45°: baja la barra a pecho alto/clavícula, omóplatos retraídos (imagen: fondo del press inclinado).",
            "Empuja a bloqueo en línea con el pecho alto (imagen: lockout arriba).",
        ],
        "Press mancuernas": [
            "Mancuernas a los lados del pecho, muñecas sobre codos (imagen: fondo del press).",
            "Extiende arriba juntando ligeramente las mancuernas (imagen: lockout sobre el pecho).",
        ],
        "Aperturas": [
            "Cierra el arco: mancuernas casi juntas sobre el esternón, codos blandos (imagen: arriba del fly, palmas enfrentadas).",
            "Abre en arco amplio hasta estirar el pecho, mancuernas a la altura del torso (imagen: brazos abiertos en fly).",
        ],
        "Fondos": [
            "Soporte: brazos bloqueados, hombros bajos, pecho abierto (imagen: arriba del fondo).",
            "Baja hasta ~90° de codo, torso ligero hacia delante (imagen: fondo del dip).",
            "Empuja a bloqueo sin encoger trapecios (imagen: vuelta al soporte).",
        ],
        "Dominadas": [
            "Cuelga muerto: brazos totalmente extendidos, hombros activos (imagen: cuerpo colgando; sin sombra de suelo).",
            "Tira hasta que la barbilla pase la barra, pecho arriba (imagen: barbilla sobre la barra; sin sombra de suelo).",
        ],
        "Chest to bar": [
            "Cuelga con brazos extendidos y agarre firme (imagen: hang; sin sombra).",
            "Tira hasta la barbilla cerca de la barra (imagen: pull alto; sin sombra).",
            "Lleva el pecho a tocar la barra y baja con control (imagen: pecho en contacto; sin sombra).",
        ],
        "Cargada colgante": [
            "Barra en muslos, bisagra ligera, espalda plana (imagen: hang encima de rodillas).",
            "Extiende cadera y tira: barra sube pegada al cuerpo (imagen: tirada / extensión).",
            "Recibe en rack frontal (barra delante del cuello, codos altos) y párate (imagen: front rack de pie).",
        ],
        "Fondos en anillas": [
            "Soporte en anillas: brazos bloqueados, anillas junto a cadera (imagen: support; sin sombra).",
            "Baja hasta hombros por debajo de los codos (imagen: fondo del dip; sin sombra).",
            "Empuja de nuevo a soporte bloqueado (imagen: lockout; sin sombra).",
        ],
        "GHD sit-up": [
            "Extiende el tronco hacia atrás con los pies sujetos a los rodillos.",
            "Eleva el tronco hasta la mitad del recorrido.",
            "Termina la subida y mantén la espalda larga antes de volver a bajar.",
        ],
        "Jalón al pecho": [
            "Brazos extendidos sujetando la barra alta (imagen: inicio del jalón).",
            "Tira a mitad hacia el pecho alto (imagen: recorrido medio).",
            "Barra al pecho apretando dorsales; sube con control (imagen: contracción abajo).",
        ],
        "Remo con barra": [
            "Bisagra, barra colgando, espalda plana (imagen: brazos extendidos).",
            "Tira a mitad hacia el abdomen (imagen: recorrido medio).",
            "Barra al abdomen, omóplatos juntos; baja con control (imagen: contracción arriba).",
        ],
        "Remo mancuerna": [
            "Apoyo en banco, mancuerna colgando a brazo largo (imagen: inicio).",
            "Tira el codo hacia la cadera a mitad (imagen: recorrido medio).",
            "Contracción arriba junto a la cadera; baja con control (imagen: top del remo).",
        ],
        "Peso muerto": [
            "Barra sobre mediopié, agarre fuera de piernas, espalda plana (imagen: setup en el suelo).",
            "Empuja el suelo y bloquea cadera de pie sin hiperextender (imagen: lockout erguido).",
        ],
        "Peso muerto rumano": [
            "Mantén la barra delante de los muslos con las rodillas ligeramente flexionadas.",
            "Lleva la cadera atrás y baja la barra rozando las piernas con la espalda recta.",
        ],
        "Sentadilla": [
            "Barra sobre trapecios, pies al ancho de hombros, pecho alto (imagen: de pie, back squat).",
            "Baja a paralelo o más, rodillas alinea con pies, y empuja para subir (imagen: fondo de sentadilla).",
        ],
        "Sentadilla frontal": [
            "Barra en rack frontal (delante del cuello), codos altos, de pie (imagen: front rack erguido).",
            "Baja a paralelo o más con torso vertical y codos altos; empuja el suelo y vuelve (imagen: fondo front squat).",
        ],
        "Prensa": [
            "Espalda apoyada, pies al ancho de hombros en la plataforma (imagen: setup).",
            "Empuja extendiendo piernas sin bloquear de golpe (imagen: extensión).",
            "Baja con control hasta ~90° de rodilla (imagen: fondo).",
        ],
        "Zancadas": [
            "De pie con mancuernas a los lados (imagen: stance erguido).",
            "Da el paso y baja a media zancada (imagen: rodillas a ~90°).",
            "Rodilla trasera cerca del suelo; empuja para volver (imagen: fondo profundo / retorno).",
        ],
        "Extensión de cuádriceps": [
            "Siéntate con el rodillo sobre los tobillos (imagen: inicio).",
            "Extiende las rodillas sin balanceo (imagen: piernas casi rectas).",
            "Baja con control (imagen: flexión de nuevo).",
        ],
        "Curl femoral": [
            "Tobillos bajo el rodillo (imagen: setup).",
            "Flexiona llevando talones a glúteos (imagen: contracción).",
            "Vuelve con control (imagen: extensión).",
        ],
        "Elevación de gemelos": [
            "Peso sobre hombros/muslos, pies firmes (imagen: inicio).",
            "Sube de puntillas al máximo (imagen: extensión de tobillo).",
            "Baja estirando el gemelo (imagen: dorsiflexión).",
        ],
        "Press militar": [
            "Barra a hombros/front rack, torso rígido (imagen: barra a clavículas).",
            "Empuja a bloqueo overhead sin arquear lumbar (imagen: brazos extendidos arriba).",
        ],
        "Elevaciones laterales": [
            "Mancuernas a los lados, codos blandos (imagen: inicio).",
            "Eleva hasta la altura de hombros (imagen: brazos en T).",
            "Baja con control (imagen: retorno).",
        ],
        "Pájaros": [
            "Inclínate con espalda plana (imagen: bisagra).",
            "Abre brazos apretando omóplatos (imagen: vuelo inverso).",
            "Baja con control (imagen: retorno).",
        ],
        "Curl barra": [
            "Barra colgando, codos pegados al torso (imagen: brazos extendidos).",
            "Curl a mitad sin balancear (imagen: antebrazos a 90°).",
            "Arriba cerca del pecho; baja con control (imagen: pico de contracción).",
        ],
        "Curl mancuernas": [
            "Mancuernas a los lados (imagen: inicio).",
            "Sube flexionando el codo sin mover el hombro (imagen: curl).",
            "Baja con control (imagen: retorno).",
        ],
        "Curl martillo": [
            "Agarre neutro, pulgares arriba (imagen: inicio).",
            "Sube sin rotar la muñeca (imagen: curl martillo).",
            "Baja con control (imagen: retorno).",
        ],
        "Fondos en banco": [
            "Manos en el borde del banco, pies delante (imagen: soporte).",
            "Baja flexionando codos (imagen: fondo).",
            "Empuja sin encoger hombros (imagen: arriba).",
        ],
        "Extensión tríceps polea": [
            "Agarra cuerda/barra en polea alta (imagen: codos flexionados).",
            "Extiende los codos hacia abajo (imagen: brazos rectos).",
            "Vuelve con control (imagen: retorno).",
        ],
        "Press cerrado": [
            "Agarre estrecho en banca (imagen: setup).",
            "Baja al pecho con codos cerca (imagen: fondo).",
            "Empuja enfatizando tríceps (imagen: lockout).",
        ],
        "Plancha": [
            "Antebrazos y puntas de pies (imagen: plancha baja).",
            "Cuerpo en línea: abdomen y glúteos activos (imagen: alineación).",
            "Mantén sin hundir la lumbar (imagen: hold).",
        ],
        "Crunch": [
            "Tumbado, rodillas flexionadas (imagen: inicio).",
            "Eleva el pecho hacia las rodillas (imagen: crunch).",
            "Baja con control (imagen: retorno).",
        ],
        "Elevación de piernas": [
            "Tumbado o colgado, piernas juntas (imagen: inicio).",
            "Eleva sin impulso excesivo (imagen: piernas altas).",
            "Baja con control (imagen: retorno).",
        ],
        "Hip thrust": [
            "Hombros en banco, barra en cadera, cadera BAJA cerca del suelo (imagen: fondo del thrust).",
            "Empuja cadera hasta alinear torso y muslos; aprieta glúteo (imagen: puente arriba bloqueado).",
        ],
        "Face pull": [
            "Cuerda a la altura de la cara (imagen: brazos extendidos).",
            "Tira a la cara abriendo codos (imagen: pull).",
            "Aprieta omóplatos y vuelve (imagen: contracción).",
        ],
        "Remo al mentón": [
            "Barra/mancuernas delante de muslos (imagen: inicio).",
            "Tira con codos altos hasta el pecho (imagen: remo vertical).",
            "Baja con control (imagen: retorno).",
        ],
        "Buenos días": [
            "Barra en espalda, pies firmes (imagen: erguido).",
            "Bisagra manteniendo espalda plana (imagen: torso inclinado).",
            "Vuelve extendiendo la cadera (imagen: erguido).",
        ],
        "Hack squat": [
            "Hombros bajo almohadillas, pies en plataforma (imagen: setup).",
            "Baja en sentadilla guiada (imagen: fondo).",
            "Empuja sin bloquear de golpe (imagen: extensión).",
        ],
        "Pullover": [
            "Tumbado, mancuerna sobre el pecho (imagen: inicio).",
            "Lleva la mancuerna atrás sobre la cabeza (imagen: estiramiento).",
            "Vuelve al pecho contrayendo (imagen: retorno).",
        ],
        "Cinta / carrera": [
            "Calienta a ritmo cómodo (imagen: trote suave).",
            "Mantén cadencia según el objetivo (imagen: carrera).",
            "Termina con minutos suaves (imagen: cool-down).",
        ],
        "Bici estática": [
            "Ajusta sillín y resistencia (imagen: setup).",
            "Pedalea a cadencia estable (imagen: pedaleo).",
            "Mantén el tronco erguido (imagen: postura).",
        ],
        "Remo máquina": [
            "Agarra el asa, espalda plana (imagen: catch).",
            "Empuja con piernas y luego tira con brazos (imagen: drive).",
            "Recupera en orden inverso (imagen: recovery).",
        ],
        "Farmer walk": [
            "Carga pesada en cada mano (imagen: setup).",
            "Camina erguido, pasos cortos, core activo (imagen: marcha).",
            "No dejes que las cargas te ladeen (imagen: postura estable).",
        ],
        "Press banca declinado": [
            "Banco en ligera declinación (imagen: setup).",
            "Baja la barra a la parte baja del pecho (imagen: fondo).",
            "Empuja hacia arriba con control (imagen: lockout).",
        ],
        "Cruce de poleas": [
            "Poleas altas, un asa en cada mano (imagen: abierto).",
            "Cierra juntando las manos delante (imagen: cruce).",
            "Mantén ligera flexión de codo (imagen: control).",
        ],
        "Remo sentado": [
            "Sentado frente a la polea, pecho erguido (imagen: brazos largos).",
            "Tira el asa hacia el abdomen (imagen: remo).",
            "Aprieta omóplatos y vuelve (imagen: contracción).",
        ],
        "Peso muerto sumo": [
            "Stance ancho, puntas fuera, barra cerca (imagen: setup).",
            "Levanta empujando el suelo (imagen: tirada).",
            "Bloquea cadera y baja con control (imagen: lockout).",
        ],
        "Sentadilla búlgara": [
            "Pie trasero en banco, torso erguido (imagen: stance split).",
            "Baja a media profundidad sobre la pierna delantera (imagen: semi-fondo).",
            "Rodilla trasera cerca del suelo; empuja para subir (imagen: fondo / retorno).",
        ],
        "Curl predicador": [
            "Brazos apoyados en el predicador (imagen: extensión).",
            "Sube flexionando el codo (imagen: curl).",
            "Baja con control casi a extensión (imagen: estiramiento).",
        ],
        "Press francés": [
            "Brazos extendidos, barra sobre el pecho (imagen: inicio).",
            "Flexiona codos bajando la barra (imagen: mitad).",
            "Barra cerca de la frente; extiende de nuevo (imagen: fondo / lockout).",
        ],
        "Elevaciones frontales": [
            "Mancuernas o disco delante de muslos (imagen: inicio).",
            "Eleva hasta la altura de hombros (imagen: brazos al frente).",
            "Baja con control (imagen: retorno).",
        ],
        "Ab wheel": [
            "De rodillas, rueda delante (imagen: inicio).",
            "Rueda hacia delante sin hundir lumbar (imagen: extensión).",
            "Vuelve contrayendo el abdomen (imagen: retorno).",
        ],
        "Paso lateral con banda": [
            "Banda en tobillos o rodillas (imagen: setup).",
            "Pasos laterales manteniendo tensión (imagen: paso).",
            "Rodillas alineadas con los pies (imagen: control).",
        ],
        "Remo invertido": [
            "Cuelga bajo la barra con cuerpo recto (imagen: hang horizontal; sin sombra si pies no apoyan).",
            "Tira el pecho a la barra (imagen: remo arriba).",
            "Baja con control (imagen: retorno).",
        ],
        "Press Arnold": [
            "Mancuernas delante del pecho, palmas hacia ti (imagen: inicio).",
            "Rota palmas hacia fuera mientras empujas (imagen: rotación mid-press).",
            "Baja rotando de nuevo al inicio (imagen: retorno).",
        ],

        // MARK: Gimnasia / skill
        "Muscle-up barra": [
            "Cuélgate de la barra con los brazos estirados y los pies en el aire.",
            "Lleva el pecho sobre la barra flexionando los codos y adelantando el torso.",
            "Empuja hasta sostenerte encima de la barra con los brazos extendidos.",
        ],
        "Muscle-up anillas": [
            "Cuelga de dos anillas en false grip (imagen: hang; sin sombra).",
            "Tira y pasa anillas hacia la cintura (imagen: transición; sin sombra).",
            "Soporte con brazos bloqueados, anillas a la cadera (imagen: support; sin sombra).",
        ],
        "Toes to bar": [
            "Cuelga con hombros activos (imagen: hang; sin sombra).",
            "Lleva piernas en pike hacia la barra (imagen: piernas subiendo; sin sombra).",
            "Toca la barra con los pies y baja controlado (imagen: pies en barra; sin sombra).",
        ],
        "HSPU": [
            "Pino contra la pared, brazos bloqueados (imagen: handstand lockout; sin óvalo de suelo).",
            "Baja la cabeza hacia el suelo con codos flexionados ~90° (imagen: fondo del HSPU, cabeza baja; sin óvalo).",
            "Empuja hasta bloquear otra vez en pino (imagen: lockout final; sin óvalo).",
        ],
        "Wall walk": [
            "Plancha con pies cerca de la pared (imagen: plank frente a pared).",
            "Camina manos hacia la pared subiendo los pies (imagen: diagonal / mid wall-walk).",
            "Pino pecho a la pared; baja con control (imagen: handstand en pared).",
        ],
        "Pull-over barra": [
            "Cuelga y lleva pies hacia la barra (imagen: pike colgado; sin sombra).",
            "Rueda caderas sobre la barra (imagen: hip over bar; sin sombra).",
            "Termina en soporte encima de la barra (imagen: support; sin sombra).",
        ],
        "Skin the cat": [
            "Cuelga de anillas/barra con agarre firme (imagen: hang; sin sombra).",
            "Pasa los pies entre los brazos en tuck hacia atrás (imagen: tuck invertido; sin sombra).",
            "Extiende o vuelve con control sin soltar (imagen: german hang / back-lever tuck; sin sombra).",
        ],
        "Kip swing": [
            "Cuelga en hollow: cuerpo cerrado, pies delante (imagen: hollow hang; sin sombra).",
            "Abre a arch: pecho y cadera delante, piernas atrás (imagen: arch hang; sin sombra).",
            "Alterna hollow–arch con hombros activos (imagen: swing dinámico; sin sombra).",
        ],
        "Fondos en paralelas": [
            "Sostente sobre las paralelas con los brazos estirados y los pies en el aire.",
            "Flexiona los codos y baja el pecho ligeramente hacia delante.",
        ],
        "Rope climb": [
            "Salta y agarra la cuerda alto (imagen: reach/hang en cuerda).",
            "Enrola piernas (J-hook/wrap) y estira (imagen: wrap + extensión).",
            "Sube a tramos y baja controlado (imagen: trepa alta).",
        ],

        // MARK: Halterofilia / CF
        "Arrancada": [
            "Setup: barra sobre mediopié, AGARRE ANCHO de snatch, espalda plana (imagen: suelo, manos cerca de discos).",
            "Métete bajo la barra tras la tirada: recibes hacia overhead squat (imagen: barra arriba, bajando a squat; no rack frontal).",
            "Overhead squat profundo o de pie bloqueado, agarre ancho (imagen: OHS / stand con barra overhead).",
        ],
        "Cargada": [
            "Setup: barra sobre mediopié, agarre de clean (imagen: suelo, grip de cargada).",
            "Recibe en front squat: barra delante del cuello, codos altos, cadera baja (imagen: catch en squat; NO back squat).",
            "Párate en rack frontal bloqueado (imagen: de pie, front rack).",
        ],
        "Split jerk": [
            "Front rack, dip corto de piernas (imagen: rodillas blandas, barra delante del cuello).",
            "Drive y split: un pie delante, otro atrás, brazos bloqueados overhead (imagen: split catch).",
            "Recupera pie delantero y luego el trasero bajo la barra (imagen: pies juntos, barra OH).",
        ],
        "Cargada y envión": [
            "Rack frontal tras la cargada, de pie (imagen: front rack).",
            "Dip-drive: flexión corta y empuje (imagen: dip en front rack, no back rack).",
            "Bloquea overhead y recupera pies (imagen: barra arriba bloqueada).",
        ],
        "Overhead squat": [
            "Barra bloqueada overhead, agarre ancho, de pie (imagen: stand OH).",
            "Siéntate profundo manteniendo la barra activa (imagen: OHS fondo).",
            "Levántate sin perder el bloqueo (imagen: stand OH de nuevo).",
        ],
        "Thruster": [
            "Sujeta la barra delante de los hombros y baja a una sentadilla profunda.",
            "Extiende las piernas manteniendo la barra cerca de los hombros.",
            "Empuja la barra sobre la cabeza hasta estirar los brazos.",
        ],
        "Turkish get-up": [
            "Túmbate boca arriba con la kettlebell sostenida en vertical.",
            "Apóyate en el antebrazo y eleva la cadera manteniendo la kettlebell arriba.",
            "Ponte de pie con el brazo de la kettlebell completamente extendido.",
        ],
        "Devil press": [
            "Pecho al suelo entre las mancuernas (imagen: chest-to-floor con DBs).",
            "Salta a cuclillas agarrando las mancuernas (imagen: squat con DBs).",
            "Snatch ambas overhead en un movimiento (imagen: DBs bloqueadas arriba).",
        ],
        "Wall ball": [
            "Sujeta el balón frente al pecho y baja a una sentadilla profunda.",
            "Lanza el balón hacia la diana al extender las piernas.",
            "Recibe el balón con las manos altas antes de iniciar otra sentadilla.",
        ],
        "Cluster": [
            "Rack frontal tras la cargada (imagen: front rack de pie).",
            "Sentadilla frontal profunda sin soltar el rack (imagen: front squat fondo).",
            "Thruster a overhead en un solo tiempo (imagen: barra OH bloqueada).",
        ],
        "Burpee pull-up": [
            "Pecho al suelo bajo la barra (imagen: chest-to-floor).",
            "Salta y agarra la barra (imagen: salto a hang; sin sombra si flotas).",
            "Dominada: barbilla por encima de la barra (imagen: chin-over-bar; sin sombra).",
        ],
        "Salto al cajón": [
            "Pies firmes frente al cajón, carga de piernas (imagen: squat corto frente al box).",
            "Salta: rodillas arriba, sobre el cajón en el aire (imagen: vuelo; sin sombra bajo el atleta).",
            "De pie sobre el cajón, cadera extendida (imagen: stand sobre el box).",
        ],
        "Box jump over": [
            "Flexiona frente al cajón, brazos atrás (imagen: carga; box a un lado).",
            "Salta pasando POR ENCIMA del cajón (imagen: vuelo sobre el box; sin sombra bajo el atleta).",
            "Aterriza al otro lado en el suelo, suave (imagen: land en suelo, box detrás).",
        ],
        "Snatch kettlebell": [
            "KB entre los pies, bisagra de cadera (imagen: setup en el suelo).",
            "Extiende y guía la KB cerca del cuerpo (imagen: tirada / float).",
            "Bloquea overhead a brazo extendido (imagen: KB arriba bloqueada).",
        ],
    ]

}
