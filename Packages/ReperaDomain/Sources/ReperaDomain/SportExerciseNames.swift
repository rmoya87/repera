import Foundation

/// Nombre canónico EN de CrossFit/halterofilia y alias ES de búsqueda.
/// Las equivalencias se aplican en la hidratación sin reemplazar los UUID existentes.
public enum SportExerciseNames {
    private static let legacySpanishToEnglish: [String: String] = [
        "Arrancada": "Snatch",
        "Tirón alto de arrancada": "Snatch High Pull",
        "Tirón alto de cargada": "Clean High Pull",
        "Peso muerto de cargada": "Clean Deadlift",
        "Envión en sentadilla": "Squat Jerk",
        "Dip y drive de envión": "Jerk Dip and Drive",
        "Arrancada de potencia desde bloques": "Block Power Snatch",
        "Cargada de potencia desde bloques": "Block Power Clean",
        "Push press con agarre de arrancada": "Snatch-Grip Push Press",
        "Arrancada colgante": "Hang Snatch",
        "Arrancada colgante completa": "Hang Squat Snatch",
        "Arrancada con pausa": "Pause Snatch",
        "Arrancada de potencia": "Power Snatch",
        "Arrancada desde bloques": "Block Snatch",
        "Arrancada en split": "Split Snatch",
        "Arrancada muscular": "Muscle Snatch",
        "Balance de arrancada": "Snatch Balance",
        "Balance de envión": "Jerk Balance",
        "Burpee al cajón": "Burpee Box Jump",
        "Cargada": "Clean",
        "Cargada colgante": "Hang Clean",
        "Cargada colgante completa": "Hang Squat Clean",
        "Cargada con pausa": "Pause Clean",
        "Cargada de potencia": "Power Clean",
        "Cargada desde bloques": "Block Clean",
        "Cargada muscular": "Muscle Clean",
        "Cargada y envión": "Clean and Jerk",
        "Cargada y envión con mancuerna": "Dumbbell Clean and Jerk",
        "Cargada y press": "Clean and Press",
        "Carrera": "Run",
        "Clean kettlebell": "Kettlebell Clean",
        "Clean mancuerna": "Dumbbell Clean",
        "Dobles de comba": "Double-Under",
        "Envión detrás de nuca": "Behind-the-Neck Jerk",
        "Peso muerto agarre arrancada": "Snatch-Grip Deadlift",
        "Press detrás de nuca": "Behind-the-Neck Press",
        "Salto al cajón": "Box Jump",
        "Sentadilla frontal con pausa": "Pause Front Squat",
        "Simples de comba": "Single-Under",
        "Snatch kettlebell": "Kettlebell Snatch",
        "Snatch mancuerna": "Dumbbell Snatch",
        "Step-up al cajón": "Box Step-Up",
        "Step-up al cajón con doble mancuerna": "Double Dumbbell Step Up",
        "Step-up al cajón con kettlebell goblet": "Kettlebell Goblet Box Step-Up",
        "Swing americano": "American Kettlebell Swing",
        "Swing kettlebell": "Kettlebell Swing",
        "Thruster kettlebell": "Kettlebell Thruster",
        "Thruster mancuernas": "Dumbbell Thruster",
        "Tirón de arrancada": "Snatch Pull",
        "Tirón de cargada": "Clean Pull",
        "Triples de comba": "Triple-Under",
        "Zancadas inversas con barra": "Back rack reverse lunge",
    ]

    private static let originalEnglishAliases: [String: String] = [
        "Box Jump": "Salto al cajón",
        "Box Step-Up": "Step-up al cajón",
        "Burpee Box Jump": "Burpee al cajón",
        "Double-Under": "Dobles de comba",
        "Single-Under": "Simples de comba",
        "Triple-Under": "Triples de comba",
        "Run": "Carrera",
        "American Kettlebell Swing": "Swing americano",
        "Kettlebell Swing": "Swing kettlebell",
        "Dumbbell Clean": "Clean mancuerna",
        "Dumbbell Snatch": "Snatch mancuerna",
        "Dumbbell Thruster": "Thruster mancuernas",
        "Dumbbell Clean and Jerk": "Cargada y envión con mancuerna",
        "Kettlebell Clean": "Clean kettlebell",
        "Kettlebell Snatch": "Snatch kettlebell",
        "Kettlebell Thruster": "Thruster kettlebell",
        "Burpee Broad Jump": "Burpee con salto de longitud",
        "Sandbag Lunges": "Zancadas con saco",
        "Air bike": "Bicicleta de aire",
        "Ball slam": "Golpeo de balón al suelo",
        "Bar facing burpee": "Burpee frente a la barra",
        "Bear crawl": "Gateo del oso",
        "Box jump over": "Salto sobre cajón",
        "Broad jump": "Salto de longitud",
        "Burpee": "Burpi",
        "Burpee to target": "Burpee a diana",
        "Burpee box jump over": "Burpee con salto sobre cajón",
        "Burpee pull-up": "Burpee con dominada",
        "Cluster": "Cargada y thruster",
        "Devil press": "Press del diablo",
        "Drop snatch": "Arrancada bajo la barra",
        "Echo bike": "Bicicleta Echo",
        "Farmer carry": "Paseo del granjero",
        "Front rack lunge": "Zancada con barra en rack frontal",
        "Goblet squat": "Sentadilla goblet",
        "Ground to overhead": "Del suelo a encima de la cabeza",
        "Hang power clean": "Cargada de potencia desde colgado",
        "Hang power snatch": "Arrancada de potencia desde colgado",
        "Man maker": "Hombre máquina",
        "Medball clean": "Cargada con balón medicinal",
        "Overhead squat": "Sentadilla por encima de la cabeza",
        "Plate ground to overhead": "Disco del suelo a encima de la cabeza",
        "Power jerk": "Envión de potencia",
        "Push jerk": "Envión de fuerza",
        "Push press": "Press con impulso",
        "Sandbag clean": "Cargada con saco",
        "Sandbag over shoulder": "Saco sobre el hombro",
        "Shuttle run": "Carrera de ida y vuelta",
        "SkiErg": "Esquí ergómetro",
        "Sled pull": "Arrastre de trineo",
        "Sled push": "Empuje de trineo",
        "Sots press": "Press Sots",
        "Split jerk": "Envión en tijera",
        "Strict press": "Press estricto",
        "Sumo high pull": "Tirón alto sumo",
        "Tall clean": "Cargada desde extensión",
        "Tall snatch": "Arrancada desde extensión",
        "Thruster": "Sentadilla frontal con press",
        "Turkish get-up": "Levantamiento turco",
        "Walking lunge": "Zancadas caminando",
        "Wall ball": "Lanzamiento de balón a pared",
        "Yoke carry": "Paseo con yugo",
        "Bike Erg": "Bici ergómetro",
        "Ab Mat Sit-Up": "Sit-up con AbMat",
        "Overhead Lunge": "Zancada overhead",
        "Alternating Dumbbell Snatch": "Arrancada alterna con mancuerna",
        "Dumbbell Overhead Lunge": "Zancada overhead con mancuerna",
        "Dead Hang": "Suspensión en barra",
        "Box Step-Over": "Paso sobre cajón",
        "D-Ball Clean": "Cargada con D-ball",
        "D-Ball Over Shoulder": "D-ball sobre el hombro",
        "Seated Box Jump": "Salto al cajón desde sentado",
        "Dumbbell Front Squat": "Sentadilla frontal con mancuernas",
        "Dumbbell Front Rack Lunge": "Zancada con mancuernas en rack frontal",
        "Dumbbell Power Snatch": "Arrancada de potencia con mancuerna",
        "Dumbbell Power Clean": "Cargada de potencia con mancuerna",
        "Dumbbell Push Press": "Push press con mancuernas",
        "Dumbbell Push Jerk": "Push jerk con mancuernas",
        "Dumbbell Overhead Squat": "Sentadilla overhead con mancuernas",
        "Dumbbell Walking Lunge": "Zancadas caminando con mancuernas",
        "Dumbbell Hang Clean and Jerk": "Cargada y envión colgante con mancuernas",
        "Double Kettlebell Front Rack Carry": "Porte en rack frontal con dos kettlebells",
        "Double Kettlebell Overhead Carry": "Porte overhead con dos kettlebells",
        "Kettlebell Clean and Jerk": "Cargada y envión con kettlebell",
        "Kettlebell Overhead Lunge": "Zancada overhead con kettlebell",
        "Kettlebell Push Press": "Push press con kettlebell",
        "Jumping Pull-Up": "Dominada con salto",
        "Burpee Muscle-Up": "Burpee a muscle-up",
        "Bear Hug Carry": "Porte en abrazo de oso",
        "Box Squat": "Sentadilla a cajón",
        "Atlas Stone Over Shoulder": "Piedra atlas al hombro",
        "Axle Deadlift": "Peso muerto con axle",
        "Axle Press": "Press con axle",
        "Back Rack Lunge": "Zancada con barra en espalda",
        "Barbell Squat Jump": "Salto en sentadilla con barra",
        "Barbell Step Up": "Step-up con barra",
        "Battle Rope": "Cuerda de batalla",
        "Bird Dog": "Bird dog",
        "Bodyweight Clean And Jerk": "Cargada y envión a peso corporal",
        "Bradford Press": "Press Bradford",
        "Burpee Bar Muscle Up": "Burpee a muscle-up de barra",
        "Burpee Over Dumbbell": "Burpee sobre mancuerna",
        "Burpee Over The Bar": "Burpee sobre la barra",
        "Copenhagen Plank": "Plancha Copenhagen",
        "Crab Walk": "Caminata de cangrejo",
        "Crossover Single Under": "Crossover Single Under",
        "Dead Bug": "Dead bug",
        "Deficit Deadlift": "Peso muerto en déficit",
        "Double Kettlebell Farmers Carry": "Farmer carry con dos kettlebells",
        "Double Kettlebell Front Rack Lunge": "Zancada en rack con dos kettlebells",
        "Dumbbell Bench Press": "Press banca con mancuernas",
        "Dumbbell Box Step Up": "Step-up con mancuerna",
        "Dumbbell Burpee Deadlift": "Burpee a peso muerto con mancuernas",
        "Dumbbell Carry": "Porte con mancuernas",
        "Dumbbell Deadlift": "Peso muerto con mancuernas",
        "Dumbbell Floor Press": "Press de suelo con mancuernas",
        "Dumbbell Hang Clean To Overhead": "Cargada colgante a overhead con mancuerna",
        "Dumbbell Hang Power Clean": "Cargada de potencia colgante con mancuerna",
        "Dumbbell Hang Split Snatch": "Arrancada colgante en split con mancuerna",
        "Dumbbell Hang Squat Clean": "Cargada completa colgante con mancuerna",
        "Dumbbell Overhead Carry": "Porte overhead con mancuernas",
        "Dumbbell Romanian Deadlift": "Peso muerto rumano con mancuernas",
        "Dumbbell Shoulder Press": "Press de hombros con mancuernas",
        "Dumbbell Shoulder To Overhead": "Hombro a overhead con mancuernas",
        "Dumbbell Split Clean": "Cargada en split con mancuerna",
        "Dumbbell Squat Clean": "Cargada completa con mancuerna",
        "Dumbbell Squat Clean Thruster": "Cargada completa a thruster con mancuerna",
        "Dumbbell Strict Press": "Press estricto con mancuernas",
        "Dumbbell Waiters Walk": "Porte de camarero con mancuerna",
        "Floor Press": "Press de suelo con barra",
        "Flutter Kick": "Patada de flutter",
        "Glute Bridge": "Puente de glúteos",
        "Glute Ham Raise": "Glute-ham raise",
        "Hand Release Push Up": "Flexiones con despegue de manos",
        "Hang High Pull": "Tirón alto desde hang",
        "Hanging Hip Touch": "Toque de cadera colgado",
        "Hanging Knee Raise": "Elevación de rodillas colgado",
        "Husafell Carry": "Porte Husafell",
        "Jefferson Curl": "Curl Jefferson",
        "Jerry Bag Carry": "Porte con jerry bag",
        "Jumping Jack": "Jumping jacks",
        "Keg Carry": "Porte con barril",
        "Kettlebell Deadlift": "Peso muerto con kettlebell",
        "Kettlebell Front Rack Lunge": "Zancada en rack con kettlebell",
        "Kettlebell Halo": "Halo con kettlebell",
        "Kettlebell Press": "Press con kettlebell",
        "Kettlebell Sumo Deadlift High Pull": "Sumo deadlift high pull con kettlebell",
        "Kettlebell Windmill": "Molino con kettlebell",
        "Kipping Handstand Push Up": "HSPU con kipping",
        "L Pull Up": "Dominada en L",
        "Landmine Press": "Press landmine",
        "Lateral Burpee": "Burpee lateral",
        "Lateral Lunge": "Zancada lateral",
        "Log Carry": "Porte con tronco",
        "Log Clean And Jerk": "Cargada y envión con tronco",
        "Log Press": "Press con tronco",
        "Medicine Ball Box Step Over": "Paso sobre cajón con balón medicinal",
        "Medicine Ball Sit Up": "Sit-up con balón medicinal",
        "Medicine Ball Throw": "Lanzamiento de balón medicinal",
        "Mountain Climber": "Escaladores",
        "Negative Pull Up": "Dominada negativa",
        "Nordic Curl": "Curl nórdico",
        "Overhead Walk": "Caminata overhead",
        "Pallof Press": "Press Pallof",
        "Parallel Bar Traverse": "Travesía en barras paralelas",
        "Parallette Handstand Push Up": "HSPU en parallettes",
        "Pendlay Row": "Remo Pendlay",
        "Plate Carry": "Porte con disco",
        "Push Up": "Flexiones",
        "Renegade Row": "Remo renegade",
        "Reverse Hyper": "Reverse hyper",
        "Ring Hamstring Curl": "Curl femoral en anillas",
        "Ring Handstand Push Up": "HSPU en anillas",
        "Ring Lower": "Descenso en anillas",
        "Ring Push Up": "Flexiones en anillas",
        "Russian Twist": "Giro ruso",
        "Sandbag Carry": "Porte con saco",
        "Sandbag Ground To Shoulder": "Saco del suelo al hombro",
        "Sandbag Load To Box": "Carga de saco al cajón",
        "Sandbag Over Log": "Saco por encima del tronco",
        "Sandbag Squat": "Sentadilla con saco",
        "Side Plank": "Plancha lateral",
        "Single Arm Dumbbell Thruster": "Thruster a un brazo con mancuerna",
        "Single Arm Kettlebell Swing": "Swing a un brazo con kettlebell",
        "Single Arm Kettlebell Thruster": "Thruster a un brazo con kettlebell",
        "Single Leg Glute Bridge": "Puente de glúteos a una pierna",
        "Single Leg Romanian Deadlift": "Peso muerto rumano a una pierna",
        "Skater Jump": "Salto de patinador",
        "Sled Drag": "Arrastre de trineo",
        "Sledgehammer Strike": "Golpes con maza",
        "Stiff Legged Deadlift": "Peso muerto de piernas rígidas",
        "Strict Knee Raise": "Elevación de rodillas estricta",
        "Strict Knees To Chest": "Rodillas al pecho estrictas",
        "Suitcase Carry": "Porte de maleta",
        "Superman": "Superman",
        "Tire Flip": "Vuelco de neumático",
        "Trap Bar Deadlift": "Peso muerto con barra hex",
        "Tuck Jump": "Salto con rodillas al pecho",
        "Wall Climb": "Escalada de muro",
        "Wall Climb Over": "Paso por encima del muro",
        "Wall Sit": "Sentadilla isométrica en pared",
        "Z Press": "Z press",
        "Zercher Carry": "Porte Zercher",
        "Zercher Deadlift": "Peso muerto Zercher",
        "Zercher Squat": "Sentadilla Zercher",
    ]

    /// Aliases de box/halterofilia: ES formal, jerga, diminutivos y acrónimos EN/ES.
    /// No cambian el título visible EN ni el UUID. Evitar siglas ambiguas (p. ej. «PS»).
    private static let supplementalAliases: [String: [String]] = [
        "Snatch": ["full snatch", "squat snatch", "snatch completo", "arrancada", "arrancada completa",
            "arrancada olímpica", "arrancada olimpica", "sn", "sq snatch", "Snatch"],
        "Power Snatch": ["p snatch", "psn", "power snatches", "arrancada de potencia",
            "arrancada alta", "arrancada power", "power arrancada", "Power Snatch"],
        "Hang Snatch": ["hang sn", "hang snatches", "hsn", "arrancada colgante",
            "arrancada desde colgado", "arrancada hang", "hang arrancada", "Hang Snatch"],
        "Hang Squat Snatch": [
            "hang full snatch", "hs snatch", "hssn", "high hang squat snatch", "hsq snatch",
            "arrancada colgante completa", "arrancada colgante profunda", "arrancada hang squat"
        ],
        "Hang power snatch": ["hpsn", "hang p snatch", "power snatch from hang",
            "arrancada potencia colgante", "arrancada de potencia desde colgado", "hang power arrancada", "Hang Power Snatch"],
        "Muscle Snatch": ["m snatch", "muscle sn", "arrancada muscular",
            "arrancada sin recepción profunda", "arrancada muscle", "Muscle Snatch"],
        "Block Snatch": [
            "snatch from blocks", "block squat snatch", "arrancada desde bloques",
            "arrancada desde tacos", "snatch bloques"
        ],
        "Pause Snatch": [
            "paused snatch", "snatch with pause", "arrancada con pausa", "arrancada pausada"
        ],
        "Snatch Balance": ["sb snatch", "snatch balance behind neck", "balance de arrancada",
            "recepcion arrancada con impulso", "snatch bal", "Snatch Balance"],
        "Drop snatch": [
            "snatch drop", "drop into snatch", "caida de arrancada", "arrancada bajo la barra",
            "drop arrancada"
        ],
        "Tall snatch": [
            "tall sn", "tall squat snatch", "arrancada desde extensión", "arrancada tall",
            "arrancada de extensión"
        ],
        "Split Snatch": [
            "split sn", "arrancada en split", "arrancada en tijera", "split arrancada"
        ],
        "Snatch Pull": ["sn pull", "snatch pulls", "tirón de arrancada",
            "tiron de arrancada", "tiron de arrancada completo", "Snatch Pull"],
        "Snatch High Pull": [
            "shp", "snatch highpull", "high pull de arrancada", "tirón alto de arrancada",
            "tiron alto de arrancada"
        ],
        "Snatch-Grip Deadlift": ["snatch grip dl", "sgdl", "deadlift snatch grip",
            "peso muerto agarre arrancada", "peso muerto agarre ancho", "dl agarre arrancada", "Snatch Grip Deadlift"],
        "Block Power Snatch": [
            "bpsn", "power snatch off blocks", "arrancada de potencia desde bloques",
            "arrancada potencia desde tacos"
        ],
        "Clean": ["full clean", "squat clean", "squat cleans", "cargada",
            "cargada completa", "cargada olímpica", "cargada olimpica", "sq clean", "Clean"],
        "Power Clean": ["pc", "p clean", "power cleans",
            "cargada de potencia", "cargada alta", "cargada power", "Power Clean"],
        "Hang Clean": ["hang cleans", "cargada colgante", "cargada desde colgado", "hc", "hang cargada", "Hang Clean"],
        "Hang Squat Clean": ["hsc", "hang full clean", "hhsc",
            "high hang squat clean", "cargada colgante completa", "cargada colgante profunda", "Hang Squat Clean"],
        "Hang power clean": ["hpc", "hang p clean", "power clean from hang",
            "cargada potencia colgante", "cargada de potencia desde colgado", "Hang Power Clean"],
        "Muscle Clean": ["m clean", "cargada muscular", "cargada sin sentadilla", "Muscle Clean"],
        "Block Clean": [
            "clean from blocks", "block squat clean", "cargada desde bloques", "cargada desde tacos"
        ],
        "Pause Clean": [
            "paused clean", "clean with pause", "cargada con pausa", "cargada pausada"
        ],
        "Tall clean": ["tall c", "cargada desde extension", "cargada desde extensión", "tall cargada", "Tall Clean"],
        "Clean Pull": ["clean pull from floor", "clean pulls", "tirón de cargada",
            "tiron de cargada", "tiron de cargada completo", "Clean Pull"],
        "Clean High Pull": [
            "chp", "clean highpull", "high pull de cargada", "tirón alto de cargada",
            "tiron alto de cargada"
        ],
        "Clean Deadlift": [
            "clean grip deadlift", "cgdl", "peso muerto de cargada", "peso muerto agarre cargada",
            "dl agarre cargada"
        ],
        "Block Power Clean": [
            "bpc", "power clean off blocks", "cargada de potencia desde bloques",
            "cargada potencia desde tacos"
        ],
        "Clean and Jerk": ["c&j", "cj", "c+j", "clean & jerk", "clean & jerks", "c and j", "cargada y envión",
            "cargada y envion", "dos tiempos", "dos tiempos olímpicos", "dos tiempos olimpicos", "cargada y envion olimpico", "c&j olímpico", "Clean And Jerk"],
        "Clean and Press": [
            "c&p", "clean & press", "cargada y press", "cargada y press estricto"
        ],
        "Push Press": [
            "pp", "push presses", "press con impulso", "press de impulso", "press con piernas",
            "push press"
        ],
        "Push jerk": ["pj", "push jerks", "jerk en paralelo", "envión de fuerza",
            "envion de fuerza", "envion con pies paralelos", "Jerk", "Push Jerk"],
        "Split jerk": ["sj", "split jerks", "jerk en split", "jerk en tijera",
            "envión en tijera", "envion en tijera", "envion split", "Split Jerk"],
        "Power jerk": [
            "power j", "power jerks", "jerk de potencia", "envión de potencia", "envion potencia"
        ],
        "Squat Jerk": ["squat j", "sj squat", "jerk en sentadilla",
            "envión en sentadilla", "envion en sentadilla", "Squat Jerk"],
        "Jerk Balance": [
            "jerk balance drill", "balance de envión", "balance de jerk", "balance de envion"
        ],
        "Jerk Dip and Drive": [
            "jerk dip drive", "dip & drive", "dip drive", "jerk dip + drive",
            "dip y drive de envión", "impulso de envion", "dip and drive"
        ],
        "Behind-the-Neck Jerk": ["btn jerk", "jerk btn", "jerk desde nuca",
            "envión detrás de nuca", "envion detras de nuca", "Behind The Neck Jerk"],
        "Strict press": ["sp", "strict overhead press", "military press",
            "press estricto", "press estricto de pie", "press militar estricto", "Strict Press"],
        "Behind-the-Neck Press": [
            "btn press", "press tras nuca", "press detrás de nuca", "press detras de nuca"
        ],
        "Sots press": ["sots", "sots overhead press", "press sots", "press en sentadilla frontal", "Sots Press"],
        "Snatch-Grip Push Press": [
            "sgpp", "snatch grip pp", "push press ancho", "push press con agarre de arrancada",
            "pp agarre arrancada"
        ],
        "Overhead squat": ["ohs", "ohsq", "overhead squats", "sentadilla overhead",
            "sentadilla por encima de la cabeza", "sentadilla sobre cabeza", "oh squat", "Overhead Squat"],
        "Pause Front Squat": [
            "paused fs", "pause fs", "pfs", "sentadilla frontal con pausa", "sentadilla frontal pausada",
            "pause front squats"
        ],
        "Front Rack Lunge": [
            "fr lunge", "fr lunges", "front rack lunges", "zancada rack frontal",
            "zancada con barra en rack frontal", "front rack lunge"
        ],
        "Back rack reverse lunge": [
            "br reverse lunge", "back rack r lunges", "back rack reverse lunges",
            "zancadas inversas con barra", "zancada inversa back rack", "reverse lunge back rack"
        ],
        "Sumo high pull": [
            "sdhp", "sumo deadlift high pull", "tirón alto sumo", "tiron alto sumo",
            "tiron alto sumo deadlift", "sumo HP"
        ],
        "Run": [
            "running", "jogging", "correr", "carrera", "runs", "trote", "footing"
        ],
        "SkiErg": [
            "ski erg", "ski ergometer", "ski-erg", "esquí ergómetro", "esqui ergometro",
            "esqui nordico ergometro", "ski"
        ],
        "Remo máquina": ["rowerg", "row erg", "rowing erg", "rower", "rowing",
            "ergómetro remo", "ergometro remo", "remoerg", "calo remo", "Row"],
        "Burpee Broad Jump": ["bbj", "burpee broad jumps", "burpee long jump",
            "burpee salto longitud", "burpee con salto de longitud", "broad jump burpee", "Burpee Broad Jump"],
        "Sandbag Lunges": [
            "sandbag walking lunges", "sb lunges", "zancadas con saco", "lunges con saco",
            "sandbag lunge"
        ],
        "Wall ball": ["wb", "wbs", "wall balls", "wallball", "wall ball shot",
            "lanzamiento de balón a pared", "lanzamientos a diana", "balón a pared", "ballon wall", "wall ball"],
        "Bar facing burpee": ["bfb", "bar-facing burpees", "burpee facing bar",
            "burpees over the bar", "burpee frente a la barra", "burpee sobre barra", "Bar Facing Burpee"],
        "Burpee box jump over": ["bbjo", "burpee box jumps over", "burpee sobre cajon",
            "burpee con salto sobre cajón", "burpee box over", "Burpee Box Jump Over"],
        "Double-Under": [
            "du", "dus", "double unders", "double-unders", "dobles", "dobles de comba",
            "doble comba", "doble unders"
        ],
        "Single-Under": [
            "su", "sus", "single unders", "simples", "simples de comba", "comba simple"
        ],
        "Triple-Under": [
            "tu", "tus", "triple unders", "triples", "triples de comba"
        ],
        "Toes to bar": ["t2b", "ttb", "t2bs", "t 2 b", "toes-to-bar",
            "toes to bars", "pies a barra", "pies a la barra", "puntas a barra", "Toes To Bar", "toes to bar"],
        "Burpee to target": [
            "btt", "burpees to target", "burpee a diana", "burpee al target", "burpee target"
        ],
        "Chest to bar": ["c2b", "ctb", "c2bs", "chest-to-bar",
            "chest to bars", "dominadas al pecho", "dominada pecho a barra", "pull-up pecho", "Chest To Bar Pull Up"],
        "Muscle-up barra": ["bmu", "bar mu", "bar muscle up", "bar muscle-up",
            "bar muscle ups", "muscle up de barra", "muscle-up de barra", "mu barra", "Muscle Up"],
        "Muscle-up anillas": [
            "rmu", "ring mu", "ring muscle up", "ring muscle-up", "ring muscle ups",
            "muscle up de anillas", "muscle-up de anillas", "mu anillas"
        ],
        "HSPU": ["handstand push up", "handstand push-up", "handstand push ups", "hspus", "flexiones en pino", "pino flexión",
            "pino flexiones", "hs push up", "hspu", "Strict Handstand Push Up", "Wall Facing Handstand Push Up", "chest-to-wall handstand push-up"],
        "HSPU deficit": ["deficit hspu", "def hspu", "deficit handstand push-up",
            "pino con deficit", "hspu con déficit", "hspu con deficit", "Deficit Handstand Push Up"],
        "GHD sit-up": ["ghd su", "ghdsu", "ghd situps", "situp ghd",
            "sit-up ghd", "abdominales ghd", "Ghd Sit Up", "ghd sit-up"],
        "Knees to elbows": ["k2e", "kte", "knees-to-elbows", "knees to elbow",
            "rodillas a codos", "rodilla a codo", "Knees To Elbows", "knees to elbows"],
        "Farmer carry": [
            "farmers carry", "farmer walk", "farmers walk", "paseo del granjero",
            "paseo granjero", "farmer carries"
        ],
        "Ground to overhead": ["gtoh", "g2oh", "g2o", "ground 2 overhead",
            "ground-to-overhead", "suelo a overhead", "del suelo a encima de la cabeza", "suelo sobre cabeza", "Ground To Overhead"],
        "Dumbbell Snatch": [
            "db snatch", "db sn", "db snatches", "snatch mancuerna", "snatch con mancuerna",
            "arrancada con mancuerna", "alt db snatch"
        ],
        "Dumbbell Clean and Jerk": [
            "db c&j", "db cj", "dumbbell clean & jerk", "cargada y envión con mancuerna",
            "cargada y envion mancuerna", "db clean and jerk"
        ],
        "Dumbbell Clean": [
            "db clean", "db cleans", "clean mancuerna", "cargada con mancuerna", "dumbbell cleans"
        ],
        "Dumbbell Thruster": [
            "db thruster", "db thrusters", "thruster mancuernas", "thruster con mancuernas",
            "thrusters db"
        ],
        "Double Dumbbell Step Up": [
            "ddb step up", "ddb box step up", "double dumbbell box step up",
            "step-up al cajón con doble mancuerna", "step up con dos mancuernas"
        ],
        "Kettlebell Swing": [
            "kb swing", "kbs", "rkbs", "russian kettlebell swing", "russian kb swing",
            "swing kettlebell", "swing ruso", "swing de pesa rusa", "balanceo kb"
        ],
        "American Kettlebell Swing": [
            "akbs", "akb", "american kb swing", "american kettlebell swings",
            "swing americano", "swing kb americano", "american swing"
        ],
        "Kettlebell Snatch": [
            "kb snatch", "kb snatches", "snatch kettlebell", "arrancada con kettlebell",
            "arrancada kb", "pesa rusa snatch"
        ],
        "Kettlebell Clean": [
            "kb clean", "kb cleans", "clean kettlebell", "cargada con kettlebell", "cargada kb"
        ],
        "Kettlebell Thruster": [
            "kb thruster", "kb thrusters", "thruster kettlebell", "thruster con kettlebell",
            "thruster kb"
        ],
        "Kettlebell Goblet Box Step-Up": [
            "kb goblet box step up", "goblet alt box step up", "goblet alternating box step up",
            "step-up al cajón con kettlebell goblet", "step up goblet kb"
        ],
        "Air bike": ["assault bike", "abike", "airbike", "fan bike", "bicicleta de aire",
            "bici de aire", "assault", "assaultbike", "echo bike", "Bike"],
        "Echo bike": ["echo", "echo erg", "echo bikes", "bicicleta echo", "bici echo", "Echo Bike"],
        "Sled push": ["sledpush", "prowler push", "empujar trineo", "empuje de trineo", "sled pushes", "Sled Push"],
        "Sled pull": ["sledpull", "prowler pull", "tirar de trineo", "arrastre de trineo", "sled pulls", "Sled Pull"],
        "Thruster": ["thrusters", "sentadilla frontal con press", "front squat press",
            "squat and press", "thruster barra", "Thruster"],
        "Cluster": ["clusters", "clean thruster", "cargada y thruster",
            "cluster barra", "squat clean thruster", "Cluster"],
        "Burpee": ["burpees", "burpi", "burpis", "berpie", "burpee completo", "Burpee"],
        "Burpee Box Jump": [
            "bbj box", "burpee box jump", "burpee al cajón", "burpee box jumps", "burpee + box jump"
        ],
        "Burpee pull-up": [
            "burpee pull up", "burpee pullups", "burpee con dominada", "burpee + pull-up"
        ],
        "Box Jump": [
            "bj", "box jumps", "salto al cajón", "salto al cajon", "saltos al cajón"
        ],
        "Box jump over": ["bjo", "box jump overs", "box jumps over", "salto sobre cajón", "salto sobre cajon", "Box Jump Over"],
        "Box Step-Up": [
            "box step up", "step-ups", "step-up al cajón", "step up al cajon", "subidas al cajón"
        ],
        "Broad jump": ["broad jumps", "standing long jump", "salto de longitud", "salto horizontal", "Broad Jump"],
        "Ball slam": ["ball slams", "medball slam", "slam ball",
            "golpeo de balón al suelo", "slams", "balón slam", "Ball Slam"],
        "Bear crawl": ["bear crawls", "gateo del oso", "oso gateo", "crawl oso", "Bear Crawl"],
        "Devil press": ["devil presses", "db devil press", "press del diablo", "devil db press",
            "devil's press", "devils press", "Devils Press", "Devil's Press"],
        "Goblet squat": ["goblet squats", "kb goblet squat", "sentadilla goblet", "sentadilla cáliz", "sentadilla caliz",
            "dumbbell goblet squat", "db goblet squat", "Dumbbell Goblet Squat", "goblet squat mancuerna", "Goblet Squat", "kettlebell goblet squat"],
        "Walking lunge": ["walking lunges", "walk lunges", "zancadas caminando",
            "zancadas andando", "lunges caminando", "Walking Lunge"],
        "Man maker": ["manmakers", "man-maker", "hombre máquina", "hombre maquina", "db man maker", "Man Maker"],
        "Medball clean": [
            "med ball clean", "medicine ball clean", "mb clean", "cargada con balón medicinal",
            "cargada medball"
        ],
        "Plate ground to overhead": ["plate gtoh", "plate g2oh", "disco del suelo a encima de la cabeza",
            "disco suelo a overhead", "plate to overhead", "Plate Ground To Overhead"],
        "Sandbag clean": ["sand bag clean", "sb clean", "cargada con saco", "clean con saco", "Sandbag Clean"],
        "Sandbag over shoulder": [
            "sb over shoulder", "sandbag overs", "saco sobre el hombro", "saco al hombro"
        ],
        "Shuttle run": ["shuttle runs", "shuttles", "carrera de ida y vuelta",
            "suiza", "ida y vuelta", "Shuttle Run", "Shuttle Sprint"],
        "Turkish get-up": [
            "tgu", "turkish get up", "turkish getups", "levantamiento turco", "get-up turco",
            "getup turco"
        ],
        "Yoke carry": ["yoke walk", "yoke carries", "paseo con yugo", "yugo carry", "yoke", "Yoke Carry"],
        "Bike Erg": ["bikeerg", "bike-erg", "c2 bike", "concept2 bike",
            "bici ergometro", "bicicleta ergometro", "bike calories", "Bike Erg"],
        "Ab Mat Sit-Up": ["abmat sit-up", "abmat situp", "ab mat situps",
            "sit-up abmat", "situp con abmat", "abdominales abmat", "Ab Mat Sit Up"],
        "Overhead Lunge": ["oh lunge", "oh lunges", "overhead lunges", "zancada overhead",
            "zancadas overhead", "barbell overhead lunge", "bb overhead lunge", "oh lunge barra", "Overhead Walking Lunge"],
        "Alternating Dumbbell Snatch": ["alt db snatch", "alternating db snatch", "db alt snatch",
            "arrancada alterna mancuerna", "snatch mancuerna alterna", "Alternating Dumbbell Power Snatch", "Alternating Dumbbell Snatch"],
        "Dumbbell Overhead Lunge": ["db oh lunge", "db overhead lunges",
            "zancada overhead mancuerna", "overhead lunge db", "Dumbbell Overhead Lunge"],
        "Dead Hang": [
            "dead hangs", "passive hang", "hang hold", "suspension barra",
            "colgado en barra", "hang estático"
        ],
        "Box Step-Over": [
            "box step over", "step overs", "step-over", "paso sobre cajon",
            "pasos sobre cajón"
        ],
        "D-Ball Clean": [
            "dball clean", "d ball clean", "medicine ball clean heavy",
            "cargada dball", "cargada d-ball"
        ],
        "D-Ball Over Shoulder": [
            "dball over shoulder", "d ball over shoulder", "dball overs",
            "d-ball al hombro", "dball sobre hombro"
        ],
        "Seated Box Jump": [
            "seated box jumps", "box jump from seated", "salto cajon sentado",
            "box jump sentado"
        ],
        "Dumbbell Front Squat": ["db front squat", "db front squats", "sentadilla frontal mancuernas",
            "front squat mancuernas", "Dumbbell Front Rack Squat", "Dumbbell Front Squat"],
        "Dumbbell Front Rack Lunge": ["db front rack lunge", "db fr lunge",
            "zancada rack mancuernas", "front rack lunge db", "Dumbbell Front Rack Lunge"],
        "Dumbbell Power Snatch": [
            "db power snatch", "power snatch mancuerna", "arrancada potencia mancuerna",
            "db p snatch", "Arrancada de potencia con mancuerna", "Dumbbell Power Snatch"
        ],
        "Dumbbell Power Clean": [
            "db power clean", "power clean mancuerna", "cargada potencia mancuerna",
            "db pc", "Cargada de potencia con mancuerna", "Dumbbell Power Clean"
        ],
        "Dumbbell Push Press": [
            "db push press", "push press mancuernas", "pp mancuernas",
            "db pp", "Push press con mancuernas", "Dumbbell Push Press"
        ],
        "Dumbbell Push Jerk": [
            "db push jerk", "push jerk mancuernas", "db pj",
            "jerk mancuernas paralelo", "Push jerk con mancuernas", "Dumbbell Push Jerk"
        ],
        "Dumbbell Overhead Squat": [
            "db ohs", "db overhead squat", "ohs mancuernas",
            "sentadilla overhead mancuernas", "Sentadilla overhead con mancuernas", "Dumbbell Overhead Squat"
        ],
        "Dumbbell Walking Lunge": [
            "db walking lunge", "walking lunge mancuernas", "zancadas mancuernas",
            "db walk lunges", "Zancadas caminando con mancuernas", "Dumbbell Walking Lunge"
        ],
        "Dumbbell Hang Clean and Jerk": [
            "db hang c&j", "db hang clean and jerk", "hang c&j mancuernas",
            "cargada envion colgante mancuernas", "Cargada y envión colgante con mancuernas", "Dumbbell Hang Clean and Jerk"
        ],
        "Double Kettlebell Front Rack Carry": [
            "double kb front rack carry", "2 kb front rack carry", "farmer rack kb",
            "porte rack dos kb", "Porte en rack frontal con dos kettlebells", "Double Kettlebell Front Rack Carry"
        ],
        "Double Kettlebell Overhead Carry": [
            "double kb overhead carry", "2 kb oh carry", "porte overhead dos kb",
            "kb waiters walk doble", "Porte overhead con dos kettlebells", "Double Kettlebell Overhead Carry"
        ],
        "Kettlebell Clean and Jerk": [
            "kb c&j", "kb clean and jerk", "kettlebell c&j",
            "cargada envion kb", "Cargada y envión con kettlebell", "Kettlebell Clean and Jerk"
        ],
        "Kettlebell Overhead Lunge": [
            "kb oh lunge", "kb overhead lunge", "zancada overhead kb",
            "overhead lunge kettlebell", "Zancada overhead con kettlebell", "Kettlebell Overhead Lunge"
        ],
        "Kettlebell Push Press": [
            "kb push press", "push press kb", "kb pp",
            "pressa impulso kb", "Push press con kettlebell", "Kettlebell Push Press"
        ],
        "Jumping Pull-Up": [
            "jumping pull up", "jumping pullups", "dominadas con salto",
            "kipping jump pull-up", "Dominada con salto", "Jumping Pull-Up"
        ],
        "Burpee Muscle-Up": [
            "burpee muscle up", "burpee mu",
            "burpee bar muscle up", "burpee a muscle-up", "Burpee Muscle-Up"
        ],
        "Bear Hug Carry": [
            "bear hug carry", "bearhug carry",
            "porte abrazo oso", "sandbag bear hug", "Porte en abrazo de oso"
        ],
        "Box Squat": [
            "box squat", "sentadilla al cajon", "sentadilla cajón", "box squats", "Sentadilla a cajón"
        ],
        "Atlas Stone Over Shoulder": [
            "atlas stone", "Piedra atlas al hombro"
        ],
        "Axle Deadlift": [
            "Peso muerto con axle"
        ],
        "Axle Press": [
            "Press con axle"
        ],
        "Back Rack Lunge": [
            "Zancada con barra en espalda"
        ],
        "Barbell Squat Jump": [
            "Salto en sentadilla con barra"
        ],
        "Barbell Step Up": [
            "Step-up con barra"
        ],
        "Battle Rope": [
            "Cuerda de batalla"
        ],
        "Bird Dog": [
            "Bird dog"
        ],
        "Bodyweight Clean And Jerk": [
            "Cargada y envión a peso corporal"
        ],
        "Bradford Press": [
            "Press Bradford"
        ],
        "Burpee Bar Muscle Up": [
            "Burpee a muscle-up de barra"
        ],
        "Burpee Over Dumbbell": [
            "Burpee sobre mancuerna", "burpee over db"
        ],
        "Burpee Over The Bar": [
            "lateral burpee over the bar", "Burpee sobre la barra"
        ],
        "Copenhagen Plank": [
            "Plancha Copenhagen"
        ],
        "Crab Walk": [
            "Caminata de cangrejo"
        ],
        "Crossover Single Under": [
            
        ],
        "Dead Bug": [
            "Dead bug"
        ],
        "Deficit Deadlift": [
            "Peso muerto en déficit"
        ],
        "Double Kettlebell Farmers Carry": [
            "Farmer carry con dos kettlebells", "double kb farmers carry"
        ],
        "Double Kettlebell Front Rack Lunge": [
            "Zancada en rack con dos kettlebells", "double kb front rack lunge"
        ],
        "Dumbbell Bench Press": [
            "Press banca con mancuernas", "db bench press"
        ],
        "Dumbbell Box Step Up": [
            "Step-up con mancuerna", "db box step up"
        ],
        "Dumbbell Burpee Deadlift": [
            "Burpee a peso muerto con mancuernas", "db burpee deadlift"
        ],
        "Dumbbell Carry": [
            "Porte con mancuernas", "db carry"
        ],
        "Dumbbell Deadlift": [
            "Peso muerto con mancuernas", "db deadlift"
        ],
        "Dumbbell Floor Press": [
            "Press de suelo con mancuernas", "db floor press"
        ],
        "Dumbbell Hang Clean To Overhead": [
            "Cargada colgante a overhead con mancuerna", "db hang clean to overhead"
        ],
        "Dumbbell Hang Power Clean": [
            "Cargada de potencia colgante con mancuerna", "db hang power clean"
        ],
        "Dumbbell Hang Split Snatch": [
            "Arrancada colgante en split con mancuerna", "db hang split snatch"
        ],
        "Dumbbell Hang Squat Clean": [
            "Cargada completa colgante con mancuerna", "db hang squat clean"
        ],
        "Dumbbell Overhead Carry": [
            "Porte overhead con mancuernas", "db overhead carry"
        ],
        "Dumbbell Romanian Deadlift": [
            "Peso muerto rumano con mancuernas", "db romanian deadlift"
        ],
        "Dumbbell Shoulder Press": [
            "Press de hombros con mancuernas", "db shoulder press"
        ],
        "Dumbbell Shoulder To Overhead": [
            "Hombro a overhead con mancuernas", "db shoulder to overhead"
        ],
        "Dumbbell Split Clean": [
            "Cargada en split con mancuerna", "db split clean"
        ],
        "Dumbbell Squat Clean": [
            "Cargada completa con mancuerna", "db squat clean"
        ],
        "Dumbbell Squat Clean Thruster": [
            "Cargada completa a thruster con mancuerna", "db squat clean thruster"
        ],
        "Dumbbell Strict Press": [
            "Press estricto con mancuernas", "db strict press"
        ],
        "Dumbbell Waiters Walk": [
            "Porte de camarero con mancuerna", "db waiters walk"
        ],
        "Floor Press": [
            "Press de suelo con barra"
        ],
        "Flutter Kick": [
            "Patada de flutter"
        ],
        "Glute Bridge": [
            "Puente de glúteos"
        ],
        "Glute Ham Raise": [
            "ghr", "Glute-ham raise"
        ],
        "Hand Release Push Up": [
            "Flexiones con despegue de manos"
        ],
        "Hang High Pull": [
            "Tirón alto desde hang"
        ],
        "Hanging Hip Touch": [
            "Toque de cadera colgado"
        ],
        "Hanging Knee Raise": [
            "Elevación de rodillas colgado"
        ],
        "Husafell Carry": [
            "Porte Husafell"
        ],
        "Jefferson Curl": [
            "Curl Jefferson"
        ],
        "Jerry Bag Carry": [
            "Porte con jerry bag"
        ],
        "Jumping Jack": [
            "Jumping jacks"
        ],
        "Keg Carry": [
            "Porte con barril"
        ],
        "Kettlebell Deadlift": [
            "Peso muerto con kettlebell", "kb deadlift"
        ],
        "Kettlebell Front Rack Lunge": [
            "Zancada en rack con kettlebell", "kb front rack lunge"
        ],
        "Kettlebell Halo": [
            "Halo con kettlebell", "kb halo"
        ],
        "Kettlebell Press": [
            "Press con kettlebell", "kb press"
        ],
        "Kettlebell Sumo Deadlift High Pull": [
            "Sumo deadlift high pull con kettlebell", "kb sumo deadlift high pull"
        ],
        "Kettlebell Windmill": [
            "Molino con kettlebell", "kb windmill"
        ],
        "Kipping Handstand Push Up": [
            "HSPU con kipping"
        ],
        "L Pull Up": [
            "Dominada en L"
        ],
        "Landmine Press": [
            "Press landmine"
        ],
        "Lateral Burpee": [
            "Burpee lateral"
        ],
        "Lateral Lunge": [
            "Zancada lateral"
        ],
        "Log Carry": [
            "Porte con tronco"
        ],
        "Log Clean And Jerk": [
            "Cargada y envión con tronco"
        ],
        "Log Press": [
            "Press con tronco"
        ],
        "Medicine Ball Box Step Over": [
            "Paso sobre cajón con balón medicinal"
        ],
        "Medicine Ball Sit Up": [
            "Sit-up con balón medicinal"
        ],
        "Medicine Ball Throw": [
            "Lanzamiento de balón medicinal"
        ],
        "Mountain Climber": [
            "Escaladores"
        ],
        "Negative Pull Up": [
            "Dominada negativa"
        ],
        "Nordic Curl": [
            "Curl nórdico"
        ],
        "Overhead Walk": [
            "Caminata overhead"
        ],
        "Pallof Press": [
            "Press Pallof"
        ],
        "Parallel Bar Traverse": [
            "Travesía en barras paralelas"
        ],
        "Parallette Handstand Push Up": [
            "HSPU en parallettes"
        ],
        "Pendlay Row": [
            "Remo Pendlay"
        ],
        "Plate Carry": [
            "Porte con disco"
        ],
        "Push Up": [
            "Flexiones"
        ],
        "Renegade Row": [
            "Remo renegade"
        ],
        "Reverse Hyper": [
            "Reverse hyper"
        ],
        "Ring Hamstring Curl": [
            "Curl femoral en anillas"
        ],
        "Ring Handstand Push Up": [
            "HSPU en anillas"
        ],
        "Ring Lower": [
            "Descenso en anillas"
        ],
        "Ring Push Up": [
            "Flexiones en anillas"
        ],
        "Russian Twist": [
            "Giro ruso"
        ],
        "Sandbag Carry": [
            "Porte con saco"
        ],
        "Sandbag Ground To Shoulder": [
            "Saco del suelo al hombro"
        ],
        "Sandbag Load To Box": [
            "Carga de saco al cajón"
        ],
        "Sandbag Over Log": [
            "Saco por encima del tronco"
        ],
        "Sandbag Squat": [
            "Sentadilla con saco"
        ],
        "Side Plank": [
            "Plancha lateral"
        ],
        "Single Arm Dumbbell Thruster": [
            "Thruster a un brazo con mancuerna", "single arm db thruster"
        ],
        "Single Arm Kettlebell Swing": [
            "Swing a un brazo con kettlebell", "single arm kb swing"
        ],
        "Single Arm Kettlebell Thruster": [
            "Thruster a un brazo con kettlebell", "single arm kb thruster"
        ],
        "Single Leg Glute Bridge": [
            "Puente de glúteos a una pierna"
        ],
        "Single Leg Romanian Deadlift": [
            "single leg rdl", "single leg deadlift", "Peso muerto rumano a una pierna"
        ],
        "Skater Jump": [
            "Salto de patinador"
        ],
        "Sled Drag": [
            "Arrastre de trineo"
        ],
        "Sledgehammer Strike": [
            "sledgehammer", "Golpes con maza"
        ],
        "Stiff Legged Deadlift": [
            "stiff leg deadlift", "Peso muerto de piernas rígidas"
        ],
        "Strict Knee Raise": [
            "Elevación de rodillas estricta"
        ],
        "Strict Knees To Chest": [
            "strict knee to chest", "Rodillas al pecho estrictas"
        ],
        "Suitcase Carry": [
            "Porte de maleta"
        ],
        "Superman": [
            "superman hold", "supermans", "Extensión lumbar Superman"
        ],
        "Tire Flip": [
            "Vuelco de neumático"
        ],
        "Trap Bar Deadlift": [
            "Peso muerto con barra hex"
        ],
        "Tuck Jump": [
            "Salto con rodillas al pecho"
        ],
        "Wall Climb": [
            "wall walk", "Escalada de muro"
        ],
        "Wall Climb Over": [
            "Paso por encima del muro"
        ],
        "Wall Sit": [
            "Sentadilla isométrica en pared"
        ],
        "Z Press": [
            "Z press"
        ],
        "Zercher Carry": [
            "Porte Zercher"
        ],
        "Zercher Deadlift": [
            "Peso muerto Zercher"
        ],
        "Zercher Squat": [
            "Sentadilla Zercher"
        ],
        "Crunch en polea": [
            "Cable Crunch", "cable crunch", "crunch polea", "crunch en cable"
        ],
        "Elevaciones laterales en polea": [
            "Cable Lateral Raise", "cable lateral raise", "elevaciones laterales polea"
        ],
        "Remo con apoyo de pecho": [
            "Chest Supported Row", "chest supported row", "remo pecho apoyado", "remo banco inclinado"
        ],
        "Curl femoral sentado": [
            "Seated Leg Curl", "seated leg curl", "curl femoral máquina sentado"
        ],
        "Curl femoral tumbado": [
            "Lying Leg Curl", "lying leg curl", "curl femoral máquina tumbado"
        ],
        "Pec deck": [
            "Pec Deck", "pec deck", "mariposa máquina", "butterfly machine", "aperturas máquina"
        ],
        "Abducción de cadera en máquina": [
            "Hip Abduction Machine", "hip abduction", "abduccion cadera"
        ],
        "Aducción de cadera en máquina": [
            "Hip Adduction Machine", "hip adduction", "aduccion cadera"
        ],
        "Sentadilla en Smith": [
            "Smith Machine Squat", "smith squat", "sentadilla smith"
        ],
        "Remo en T": [
            "T-Bar Row", "t-bar row", "t bar row", "remo tierra", "landmine row"
        ],
        "Curl inclinado con mancuernas": [
            "Incline Dumbbell Curl", "incline db curl", "curl inclinado"
        ],
        "Sentadilla a cajón con mancuernas": [
            "Box Squat Dumbbell", "db box squat", "box squat mancuernas"
        ],
        "Sentadilla búlgara con mancuernas": [
            "Bulgarian Split Squat Dumbbell", "db bulgarian", "bulgara mancuernas"
        ],
        "Woodchop en polea": [
            "Cable Woodchop", "woodchop", "wood chop", "chop polea"
        ],
        "Encogimientos": [
            "Barbell Shrug", "barbell shrug", "shrug", "encogimientos de trapecio", "Dumbbell Shrug", "dumbbell shrug", "Cable Shrugs", "cable shrug"
        ],
        "Gemelos sentado": [
            "Seated Calf Raise", "seated calf raise", "gemelos en máquina sentado", "Barbell Seated Calf Raise"
        ],
        "Press pecho en máquina": [
            "Machine Chest Press", "Seated Chest Press", "seated chest press", "Leverage Chest Press", "Cable Chest Press", "press de pecho en máquina"
        ],
        "Press hombro en máquina": [
            "Machine Shoulder Press", "Seated Shoulder Press", "Leverage Shoulder Press", "Smith Machine Shoulder Press", "press de hombros en máquina"
        ],
        "Dominadas asistidas": [
            "Assisted Pull-Up", "assisted pull-up", "Band Assisted Pull-Up", "dominada asistida", "pull-up asistida"
        ],
        "Fondos asistidos": [
            "Assisted Dip", "Machine Dip", "assisted dip", "fondos en máquina", "dips asistidos"
        ],
        "Curl concentrado": [
            "Concentration Curl", "Dumbbell Concentration Curl", "concentration curl", "curl de concentración", "Cable Concentration Curl"
        ],
        "Kickback de tríceps": [
            "Triceps Kickback", "Dumbbell Kickback", "Cable Kickback", "kickback", "patada de tríceps"
        ],
        "Zancada inversa": [
            "Reverse Lunge", "Barbell Reverse Lunge", "Dumbbell Reverse Lunge", "reverse lunges", "zancadas inversas", "Alternating Reverse Lunges"
        ],
        "Tirón de rack": [
            "Rack Pull", "Rack Pulls", "rack pulls", "tiron de rack", "partial deadlift"
        ],
        "Seal row": [
            "Seal Row", "seal row", "prone row", "remo foca", "bench seal row"
        ],
        "Extensión tríceps overhead": [
            "Overhead Triceps Extension", "Dumbbell Overhead Extension", "Cable Overhead Triceps Extension", "extensión overhead de tríceps", "french press overhead"
        ],
        "Jalón a brazos rectos": [
            "Straight Arm Pulldown", "Straight-Arm Pulldown", "straight arm pulldown", "jalón brazos rectos", "pulldown a brazos extendidos"
        ],
        "Hip extension": [
            "Hip Extension", "Back Extension", "45 Degree Hip Extension", "roman chair hip extension", "hiperextensión 45", "Ghd Hip Extension"
        ],
        "Sissy squat": [
            "Sissy Squat", "sissy squat", "sissy squats", "sentadilla sissy"
        ],
        "Sentadilla con safety bar": [
            "Safety Bar Squat", "safety squat bar", "SSB squat", "sentadilla safety bar", "safety squat"
        ],
        "Meadows row": [
            "Meadows Row", "meadows row", "landmine row a un brazo", "remo Meadows"
        ],
        "Spider curl": [
            "Spider Curl", "spider curl", "prone incline curl", "curl araña"
        ],
        "Curl de muñeca": [
            "Wrist Curl", "wrist curl", "Reverse Wrist Curl", "curl de antebrazo", "wrist curls"
        ],
        "Gemelos de burro": [
            "Donkey Calf Raise", "donkey calf", "gemelos burro", "donkey calves"
        ],
        "Zancada en cortesía": [
            "Curtsy Lunge", "curtsy lunge", "curtsy lunges", "zancada cruzada atrás"
        ],
        "Step-down": [
            "Step Down", "Step-Down", "box step down", "bajada de cajón a una pierna"
        ],
        "Aperturas con banda": [
            "Band Pull Apart", "band pull-apart", "band pull aparts", "aperturas de banda", "face pull con banda corto"
        ],
        "Almeja con banda": [
            "Clamshell", "Clamshells", "Banded Clamshell", "banded clamshell", "almeja", "almejas", "clamshell con banda"
        ],
        "Hidrante con banda": [
            "Fire Hydrant", "Fire hydrant", "Banded Fire Hydrant", "fire hydrants", "hidrante", "hidrante de fuego"
        ],
        "TKE con banda": [
            "TKE", "Terminal Knee Extension", "Banded Terminal Knee Extension", "banded TKE", "extensión terminal de rodilla"
        ],
        "Windshield wipers": [
            "Windshield Wipers", "Supine Windshield Wipers", "windshield wiper", "limpiaparabrisas", "limpiaparabrisas tumbado"
        ],
        "Dragon flag": [
            "Dragon Flag", "dragon flags", "bandera del dragón", "dragonflag"
        ],
        "Planche lean": [
            "Planche Lean", "planche lean", "lean planche", "inclinación de planche", "planche lean hold"
        ],
    ]

    private static func aliasKey(_ raw: String) -> String {
        let folded = key(raw)
        var result = ""
        for scalar in folded.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                result.unicodeScalars.append(scalar)
            } else if !result.hasSuffix(" ") {
                result.append(" ")
            }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    private static let normalizedSupplementalAliases: [String: String] = {
        var values: [String: String] = [:]
        for (canonical, aliases) in supplementalAliases {
            for alias in aliases {
                let normalized = aliasKey(alias)
                guard !normalized.isEmpty else { continue }
                if values[normalized] == nil {
                    values[normalized] = canonical
                }
            }
        }
        return values
    }()

    public static func searchAliases(for name: String) -> [String] {
        let canonical = canonicalName(name)
        let direct = supplementalAliases[canonical]
            ?? supplementalAliases.first(where: { key($0.key) == key(canonical) })?.value
            ?? []
        let spanish = spanishAlias(for: canonical).map { [$0] } ?? []
        return Array(Set(direct + spanish)).sorted()
    }

    /// Permite al buscador y al lector de pizarra resolver siglas sin modificar IDs.
    public static func canonicalName(forSearchAlias raw: String) -> String? {
        normalizedSupplementalAliases[aliasKey(raw)]
    }

    private static let englishToSpanish: [String: String] = {
        var aliases = originalEnglishAliases
        for (spanish, english) in legacySpanishToEnglish {
            aliases[english] = spanish
        }
        return aliases
    }()

    private static func key(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
            .lowercased()
    }

    private static let normalizedSpanishToEnglish: [String: String] =
        Dictionary(uniqueKeysWithValues: legacySpanishToEnglish.map { (key($0.key), $0.value) })

    private static let normalizedEnglishToSpanish: [String: String] =
        Dictionary(uniqueKeysWithValues: englishToSpanish.map { (key($0.key), $0.value) })

    /// No modificar el catálogo general de musculación ni gimnasia.
    public static func displayName(_ name: String, sport: String?) -> String {
        guard sport == "CrossFit" || sport == "Halterofilia" else { return name }
        return canonicalName(name)
    }

    /// Puente de nombres antiguos en entrenos locales/cloud y en buscadores.
    public static func canonicalName(_ name: String) -> String {
        legacySpanishToEnglish[name] ?? normalizedSpanishToEnglish[key(name)] ?? name
    }

    /// Nombre español conservado como alias, sin alterar la identidad del ejercicio.
    public static func spanishAlias(for name: String) -> String? {
        normalizedEnglishToSpanish[key(name)] ?? (normalizedSpanishToEnglish[key(name)] == nil ? nil : name)
    }

    /// Título visible CrossFit/halterofilia: nombre típico EN («Clean and Jerk»).
    /// El español, jerga y acrónimos viven en aliases de búsqueda (`searchAliases` / OCR).
    /// Fuerza, gimnasia y movilidad no mapeados se dejan igual. No cambia IDs de catálogo.
    public static func localizedDisplayName(_ name: String) -> String {
        canonicalName(name)
    }

    /// Alias técnicos EN->ES para indexación o resolución inversa de la pizarra.
    public static func englishAlias(forSpanish name: String) -> String? {
        normalizedSpanishToEnglish[key(name)]
    }
}
