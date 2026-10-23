import Foundation

/// Ejercicios de movilidad articular: separados de la fuerza para fatiga y filtros.
enum CatalogMovilidad {
    private struct Item: Sendable {
        let seed: EnrichedSeed
        let englishAliases: [String]
    }

    private static let items: [Item] = [
        move("Flexión cervical suave", english: "Neck flexion stretch", group: "Hombros", target: "traps", equipment: "Peso corporal", description: "Flexión cervical controlada sin resistencia.", steps: ["Lleva la barbilla hacia el pecho sin levantar los hombros.", "Vuelve despacio al centro."], key: 1),
        move("Extensión cervical suave", english: "Neck extension mobility", group: "Hombros", target: "traps", equipment: "Peso corporal", description: "Extensión cervical en amplitud cómoda.", steps: ["Eleva la mirada suavemente sin comprimir la nuca.", "Regresa a neutro con control."], key: 2),
        move("Rotación cervical", english: "Neck rotations", group: "Hombros", target: "traps", equipment: "Peso corporal", description: "Rotación activa de cuello.", steps: ["Mira despacio por encima de un hombro.", "Vuelve al centro y alterna sin rebotes."], key: 3),
        move("Inclinación lateral cervical", english: "Neck lateral flexion", group: "Hombros", target: "traps", equipment: "Peso corporal", description: "Inclinación lateral de la cabeza.", steps: ["Acerca una oreja al hombro sin elevarlo.", "Alterna los lados despacio."], key: 4),
        move("Retracción cervical", english: "Chin tucks", group: "Hombros", target: "traps", equipment: "Peso corporal", description: "Control de la posición de cabeza y cuello.", steps: ["Desliza la barbilla hacia atrás sin bajar la mirada.", "Suelta lentamente."], key: 5),
        move("CARs de cuello", english: "Neck CARs", group: "Hombros", target: "traps", equipment: "Peso corporal", description: "Círculos controlados del cuello.", steps: ["Dibuja un círculo pequeño y continuo.", "Cambia el sentido sin forzar el rango."], key: 6),
        move("Círculos de hombros", english: "Shoulder circles", group: "Hombros", target: "delts", equipment: "Peso corporal", description: "Rotación de hombros y escápulas.", steps: ["Eleva hombros y llévalos hacia atrás y abajo.", "Invierte el sentido con el tronco estable."], key: 7),
        move("CARs de hombro", english: "Shoulder CARs", group: "Hombros", target: "delts", equipment: "Peso corporal", description: "Rotación controlada completa de hombro.", steps: ["Dibuja un círculo con brazo extendido y tronco quieto.", "Alterna sentidos y lados lentamente."], key: 8),
        move("Pasadas de hombros con pica", english: "PVC pass throughs;Shoulder pass throughs", group: "Hombros", target: "delts", equipment: "Pica", description: "Movilidad de hombro con agarre amplio.", steps: ["Lleva la pica de delante hacia atrás por encima de la cabeza.", "Abre el agarre cuanto necesites y evita forzar."], key: 9),
        move("Deslizamientos en pared", english: "Wall slides", group: "Hombros", target: "delts", equipment: "Pared", description: "Flexión de hombros con control escapular.", steps: ["Apoya espalda y brazos en la pared.", "Desliza los brazos arriba sin arquear lumbares."], key: 10),
        move("Ángeles en pared", english: "Wall angels", group: "Hombros", target: "delts", equipment: "Pared", description: "Apertura torácica y de hombros.", steps: ["Coloca espalda contra la pared y codos flexionados.", "Abre y eleva los brazos sin despegar la pelvis."], key: 11),
        move("Rotación externa de hombro con banda", english: "Banded shoulder external rotations", group: "Hombros", target: "delts", equipment: "Banda elástica", description: "Rotación externa activa de hombro.", steps: ["Mantén el codo pegado al costado.", "Gira el antebrazo hacia fuera sin mover el tronco."], key: 12),
        move("Rotación interna de hombro", english: "Shoulder internal rotation stretch", group: "Hombros", target: "delts", equipment: "Peso corporal", description: "Trabajo suave de rotación interna.", steps: ["Mueve el antebrazo hacia dentro con el codo estable.", "Evita girar el tronco para compensar."], key: 13),
        move("Estiramiento de dorsal en banco", english: "Bench lat stretch", group: "Espalda", target: "lats", equipment: "Banco", description: "Flexión de hombros y apertura dorsal.", steps: ["Apoya los codos en un banco y desciende el pecho.", "Mantén abdomen activo para proteger lumbares."], key: 14),
        move("Estiramiento pectoral en puerta", english: "Doorway pec stretch", group: "Pecho", target: "pectorals", equipment: "Marco de puerta", description: "Apertura del pectoral y hombro anterior.", steps: ["Apoya el antebrazo en un marco.", "Da un paso corto adelante sin provocar dolor."], key: 15),
        move("Estiramiento de hombro cruzado", english: "Cross body shoulder stretch", group: "Hombros", target: "delts", equipment: "Peso corporal", description: "Apertura posterior de hombro.", steps: ["Lleva un brazo por delante del pecho.", "Acércalo con el otro brazo sin subir el hombro."], key: 16),
        move("Elevaciones escapulares", english: "Scapular elevations", group: "Espalda", target: "traps", equipment: "Peso corporal", description: "Movilidad de elevación escapular.", steps: ["Sube los hombros sin inclinar el cuello.", "Bájalos lentamente sin balanceos."], key: 17),
        move("Protracción y retracción escapular", english: "Scapular protraction retraction", group: "Espalda", target: "upper back", equipment: "Peso corporal", description: "Control escapular sin movimiento de brazos.", steps: ["Separa los omóplatos empujando hacia delante.", "Vuelve acercándolos sin arquear la espalda."], key: 18),
        move("Flexiones escapulares", english: "Scapular push ups", group: "Espalda", target: "upper back", equipment: "Peso corporal", description: "Control de escápulas en plancha.", steps: ["Mantén los codos extendidos.", "Acerca y separa los omóplatos controlando el tronco."], key: 19),
        move("Colgado pasivo", english: "Passive dead hang", group: "Espalda", target: "lats", equipment: "Barra", description: "Movilidad de hombros con suspensión gradual.", steps: ["Agarra una barra y transfiere peso poco a poco.", "Sal de la posición de forma controlada."], key: 20),
        move("Colgado activo", english: "Active hang", group: "Espalda", target: "lats", equipment: "Barra", description: "Control de escápulas en suspensión.", steps: ["Desde el colgado activa los hombros alejándolos de las orejas.", "Relaja parcialmente sin perder el agarre."], key: 21),
        move("Gato-vaca", english: "Cat cow", group: "Espalda", target: "lower back", equipment: "Peso corporal", description: "Flexión y extensión segmentaria de columna.", steps: ["En cuadrupedia redondea la espalda metiendo barbilla.", "Invierte la curva despacio en un rango cómodo."], key: 22),
        move("Rotación torácica en cuadrupedia", english: "Quadruped thoracic rotation", group: "Espalda", target: "upper back", equipment: "Peso corporal", description: "Rotación dorsal manteniendo la pelvis.", steps: ["Lleva una mano detrás de la cabeza.", "Gira el codo hacia arriba sin mover las caderas."], key: 23),
        move("Enhebrar la aguja", english: "Thread the needle", group: "Espalda", target: "upper back", equipment: "Peso corporal", description: "Rotación torácica desde cuadrupedia.", steps: ["Desliza un brazo por debajo del cuerpo.", "Vuelve y abre el brazo hacia el techo."], key: 24),
        move("Libro abierto", english: "Open book stretch", group: "Espalda", target: "upper back", equipment: "Peso corporal", description: "Rotación dorsal tumbado de lado.", steps: ["Flexiona las rodillas y fija la pelvis.", "Abre el brazo superior siguiendo la mano con la mirada."], key: 25),
        move("Extensión torácica con rodillo", english: "Foam roller thoracic extension", group: "Espalda", target: "upper back", equipment: "Rodillo", description: "Extensión torácica sobre espuma.", steps: ["Coloca el rodillo bajo la zona dorsal.", "Extiende el tórax con cabeza apoyada en las manos."], key: 26),
        move("Rotación torácica sentado", english: "Seated thoracic rotation", group: "Espalda", target: "upper back", equipment: "Peso corporal", description: "Rotación de tronco desde asiento.", steps: ["Siéntate alto con pelvis fija.", "Gira la caja torácica sin tirar del cuello."], key: 27),
        move("Rotación torácica en pared", english: "Wall thoracic rotation", group: "Espalda", target: "upper back", equipment: "Pared", description: "Rotación dorsal asistida por referencia visual.", steps: ["Sitúate de lado junto a una pared.", "Abre el brazo siguiendo un arco sin arquear lumbares."], key: 28),
        move("Flexión segmentaria de columna", english: "Segmental spinal flexion", group: "Espalda", target: "lower back", equipment: "Peso corporal", description: "Articulación progresiva de la columna.", steps: ["Desciende vértebra a vértebra con rodillas suaves.", "Vuelve lentamente a la posición erguida."], key: 29),
        move("Postura de la esfinge", english: "Sphinx pose", group: "Espalda", target: "lower back", equipment: "Peso corporal", description: "Extensión lumbar moderada en apoyo.", steps: ["Túmbate boca abajo y apoya antebrazos.", "Eleva el pecho sin forzar la zona lumbar."], key: 30),
        move("Postura del niño", english: "Child's pose", group: "Espalda", target: "lats", equipment: "Peso corporal", description: "Flexión de cadera y apertura dorsal.", steps: ["Lleva la cadera hacia los talones.", "Alarga los brazos mientras respiras tranquilo."], key: 31),
        move("Postura del niño lateral", english: "Side reaching child's pose", group: "Espalda", target: "lats", equipment: "Peso corporal", description: "Apertura lateral de dorsales.", steps: ["Desde la postura del niño camina las manos a un lado.", "Mantén la pelvis atrás y alterna."], key: 32),
        move("Inclinación lateral de tronco", english: "Standing side bend stretch", group: "Core", target: "obliques", equipment: "Peso corporal", description: "Movilidad de costado y tronco.", steps: ["Eleva un brazo e inclínate al lado contrario.", "Evita girar el pecho y alterna."], key: 33),
        move("CARs de cadera", english: "Hip CARs", group: "Glúteos", target: "glutes", equipment: "Peso corporal", description: "Rotación controlada de cadera.", steps: ["Con apoyo estable eleva la rodilla y dibuja un círculo.", "Evita que la pelvis gire."], key: 34),
        move("90/90 de cadera", english: "90 90 hip switches;90/90 hip mobility", group: "Glúteos", target: "glutes", equipment: "Peso corporal", description: "Rotaciones internas y externas de cadera.", steps: ["Siéntate con rodillas a noventa grados.", "Pasa ambas rodillas al otro lado sin impulso."], key: 35),
        move("90/90 con inclinación frontal", english: "90 90 hip forward fold", group: "Glúteos", target: "glutes", equipment: "Peso corporal", description: "Movilidad de rotación externa de cadera.", steps: ["Coloca las piernas en 90/90.", "Inclínate desde caderas hacia la espinilla delantera."], key: 36),
        move("90/90 con elevación de rodilla", english: "90 90 hip lift off", group: "Glúteos", target: "glutes", equipment: "Peso corporal", description: "Control de rotación interna de cadera.", steps: ["Mantén el tronco vertical en 90/90.", "Eleva ligeramente la rodilla trasera sin apoyarte en manos."], key: 37),
        move("Estiramiento del flexor de cadera", english: "Half kneeling hip flexor stretch", group: "Piernas", target: "hip flexors", equipment: "Peso corporal", description: "Apertura anterior de cadera en media rodilla.", steps: ["Coloca una rodilla abajo y adelanta el otro pie.", "Activa glúteo y lleva pelvis adelante suavemente."], key: 38),
        move("Couch stretch", english: "Couch stretch", group: "Piernas", target: "hip flexors", equipment: "Pared", description: "Apertura del cuádriceps y flexor de cadera.", steps: ["Apoya la espinilla posterior contra pared o banco.", "Eleva el tronco manteniendo glúteo activo."], key: 39),
        move("Figura cuatro tumbado", english: "Supine figure four stretch", group: "Glúteos", target: "glutes", equipment: "Peso corporal", description: "Apertura de rotadores externos de cadera.", steps: ["Cruza un tobillo sobre la rodilla opuesta.", "Acerca la pierna de apoyo al pecho."], key: 40),
        move("Postura de la paloma", english: "Pigeon pose", group: "Glúteos", target: "glutes", equipment: "Peso corporal", description: "Rotación externa de cadera en suelo.", steps: ["Lleva una pierna flexionada delante y la otra atrás.", "Apoya el peso evitando molestias en la rodilla."], key: 41),
        move("Frog stretch", english: "Frog stretch", group: "Piernas", target: "adductors", equipment: "Peso corporal", description: "Apertura suave de aductores.", steps: ["Apoya antebrazos con rodillas separadas.", "Lleva caderas atrás sin perder estabilidad."], key: 42),
        move("Rockback de aductores", english: "Adductor rock backs", group: "Piernas", target: "adductors", equipment: "Peso corporal", description: "Movilidad dinámica de aductores.", steps: ["Extiende una pierna lateral desde cuadrupedia.", "Lleva caderas atrás y vuelve con control."], key: 43),
        move("Mariposa sentada", english: "Butterfly stretch", group: "Piernas", target: "adductors", equipment: "Peso corporal", description: "Apertura de aductores desde el suelo.", steps: ["Junta las plantas de los pies sentado.", "Deja descender rodillas sin empujarlas."], key: 44),
        move("Sentadilla Cossack de movilidad", english: "Cossack squat mobility", group: "Piernas", target: "adductors", equipment: "Peso corporal", description: "Movilidad lateral de cadera y tobillos.", steps: ["Flexiona una rodilla hacia un lado en posición amplia.", "Alterna sin perder equilibrio."], key: 45),
        move("Sentadilla profunda sostenida", english: "Deep squat hold;Squat pry", group: "Piernas", target: "quads", equipment: "Peso corporal", description: "Movilidad combinada de tobillos caderas y rodillas.", steps: ["Desciende a sentadilla profunda con talones apoyados.", "Respira y separa ligeramente las rodillas."], key: 46),
        move("Sentadilla profunda con balanceo", english: "Deep squat prying", group: "Piernas", target: "quads", equipment: "Peso corporal", description: "Exploración controlada de sentadilla baja.", steps: ["Desde abajo desplaza suavemente el peso entre pies.", "Mantén rodillas alineadas y evita rebotes."], key: 47),
        move("Flexión activa de cadera de pie", english: "Standing hip flexion", group: "Piernas", target: "hip flexors", equipment: "Peso corporal", description: "Amplitud activa de flexión de cadera.", steps: ["Con apoyo levanta una rodilla sin inclinar la espalda.", "Baja lentamente y alterna."], key: 48),
        move("Extensión activa de cadera de pie", english: "Standing hip extension mobility", group: "Glúteos", target: "glutes", equipment: "Peso corporal", description: "Extensión de cadera con tronco estable.", steps: ["Lleva una pierna atrás con abdomen firme.", "Vuelve sin arquear las lumbares."], key: 49),
        move("Rotación interna de cadera sentado", english: "Seated hip internal rotation", group: "Glúteos", target: "glutes", equipment: "Peso corporal", description: "Control específico de rotación interna de cadera.", steps: ["Siéntate con pies separados y rodillas flexionadas.", "Deja caer una rodilla hacia dentro sin girar la pelvis."], key: 50),
        move("Rodilla a pared para tobillo", english: "Knee to wall ankle mobility", group: "Gemelos", target: "calves", equipment: "Pared", description: "Dorsiflexión de tobillo con el talón apoyado.", steps: ["Coloca un pie delante de la pared.", "Acerca la rodilla al muro sin levantar el talón."], key: 51),
        move("Dorsiflexión de tobillo con banda", english: "Banded ankle dorsiflexion", group: "Gemelos", target: "calves", equipment: "Banda elástica", description: "Movilidad de dorsiflexión con banda suave.", steps: ["Ancla una banda alrededor del tobillo.", "Lleva rodilla adelante conservando talón apoyado."], key: 52),
        move("Círculos de tobillo", english: "Ankle circles", group: "Gemelos", target: "calves", equipment: "Peso corporal", description: "Rotaciones articulares libres de tobillo.", steps: ["Levanta el pie del suelo.", "Dibuja círculos lentos en ambos sentidos."], key: 53),
        move("CARs de tobillo", english: "Ankle CARs", group: "Gemelos", target: "calves", equipment: "Peso corporal", description: "Control de recorrido articular de tobillo.", steps: ["Dibuja un círculo lento con el pie.", "Evita girar la pierna durante el movimiento."], key: 54),
        move("Flexión plantar de tobillo", english: "Plantar flexion mobility", group: "Gemelos", target: "calves", equipment: "Peso corporal", description: "Amplitud activa de flexión plantar.", steps: ["Aleja los dedos de la tibia apuntando el pie.", "Regresa lentamente."], key: 55),
        move("Inversión y eversión de tobillo", english: "Ankle inversion eversion", group: "Gemelos", target: "calves", equipment: "Peso corporal", description: "Movilidad lateral del tobillo.", steps: ["Gira suavemente la planta hacia dentro.", "Muévela luego hacia fuera sin girar la pierna."], key: 56),
        move("Elevación de tibial anterior", english: "Tibialis raises", group: "Gemelos", target: "tibialis", equipment: "Pared", description: "Fortalecimiento ligero del rango de dorsiflexión.", steps: ["Apóyate en la pared con talones en suelo.", "Eleva la punta de los pies y baja lento."], key: 57),
        move("Rodilla sobre dedos controlada", english: "Knee over toes ankle rocks", group: "Piernas", target: "quads", equipment: "Peso corporal", description: "Movilidad combinada de rodilla y tobillo.", steps: ["En zancada avanza rodilla sobre dedos del pie.", "Vuelve sin despegar el talón."], key: 58),
        move("Flexión de rodilla en apoyo", english: "Supported knee flexion mobility", group: "Piernas", target: "quads", equipment: "Peso corporal", description: "Flexión activa de rodilla con apoyo.", steps: ["Agárrate a soporte estable y lleva talón al glúteo.", "Extiende lentamente."], key: 59),
        move("Estiramiento de cuádriceps de pie", english: "Standing quad stretch", group: "Piernas", target: "quads", equipment: "Peso corporal", description: "Apertura del muslo anterior.", steps: ["Sujeta el empeine detrás del cuerpo.", "Acerca el talón manteniendo pelvis neutra."], key: 60),
        move("Estiramiento de gemelo en pared", english: "Wall calf stretch", group: "Gemelos", target: "calves", equipment: "Pared", description: "Apertura de gemelo con rodilla extendida.", steps: ["Apoya manos en pared y lleva pierna atrás.", "Presiona talón hacia el suelo."], key: 61),
        move("Estiramiento de sóleo en pared", english: "Bent knee soleus stretch", group: "Gemelos", target: "calves", equipment: "Pared", description: "Movilidad de tobillo con rodilla doblada.", steps: ["Flexiona la rodilla adelantada manteniendo talón apoyado.", "Evita que el arco del pie colapse."], key: 62),
        move("Bisagra de cadera sin carga", english: "Hip hinge drill", group: "Isquios", target: "hamstrings", equipment: "Peso corporal", description: "Patrón de bisagra desde cadera.", steps: ["Empuja glúteos atrás con rodillas suaves.", "Extiende caderas conservando columna neutra."], key: 63),
        move("Estiramiento dinámico de isquios", english: "Dynamic hamstring stretch", group: "Isquios", target: "hamstrings", equipment: "Peso corporal", description: "Movilidad activa de cadena posterior.", steps: ["Estira una pierna delante con talón apoyado.", "Lleva la cadera atrás y vuelve."], key: 64),
        move("Deslizamiento neural suave", english: "Sciatic nerve glide", group: "Isquios", target: "hamstrings", equipment: "Peso corporal", description: "Movimiento neural suave sin buscar tensión intensa.", steps: ["Sentado extiende lentamente rodilla y mueve el tobillo.", "Vuelve si aparecen molestias."], key: 65),
        move("Buenos días con pica", english: "PVC good mornings", group: "Isquios", target: "hamstrings", equipment: "Pica", description: "Bisagra guiada con pica.", steps: ["Apoya pica en espalda y flexiona desde caderas.", "Conserva contacto en cabeza espalda y sacro."], key: 66),
        move("Estiramiento de isquios con banda", english: "Supine band hamstring stretch", group: "Isquios", target: "hamstrings", equipment: "Banda elástica", description: "Elevación asistida de pierna.", steps: ["Túmbate y coloca banda alrededor del pie.", "Eleva la pierna manteniendo la pelvis apoyada."], key: 67),
        move("Perro boca abajo dinámico", english: "Downward dog pedal", group: "Isquios", target: "hamstrings", equipment: "Peso corporal", description: "Movilidad de pantorrillas e isquios.", steps: ["Forma una V invertida apoyando manos y pies.", "Flexiona alternativamente las rodillas."], key: 68),
        move("Movilidad de muñeca en extensión", english: "Wrist extension rocks", group: "Antebrazos", target: "forearms", equipment: "Peso corporal", description: "Movilidad de extensión de muñeca con apoyo.", steps: ["Apoya las palmas con dedos hacia delante.", "Desplaza ligeramente hombros sobre manos."], key: 69),
        move("Movilidad de muñeca en flexión", english: "Wrist flexion stretch", group: "Antebrazos", target: "forearms", equipment: "Peso corporal", description: "Flexión de muñeca sin carga intensa.", steps: ["Extiende el brazo y lleva dedos hacia abajo.", "Alterna sin forzar articulación."], key: 70),
        move("Círculos de muñecas", english: "Wrist circles", group: "Antebrazos", target: "forearms", equipment: "Peso corporal", description: "Circunducción de muñeca.", steps: ["Deja los brazos quietos y cierra los puños.", "Dibuja círculos en ambos sentidos."], key: 71),
        move("Pronación y supinación de antebrazo", english: "Forearm pronation supination", group: "Antebrazos", target: "forearms", equipment: "Peso corporal", description: "Rotación activa del antebrazo.", steps: ["Flexiona un codo a noventa grados.", "Gira palma arriba y abajo con hombro inmóvil."], key: 72),
        move("Extensión controlada de codo", english: "Elbow extension mobility", group: "Tríceps", target: "triceps", equipment: "Peso corporal", description: "Recorrido activo de extensión de codo.", steps: ["Flexiona el codo cerca del cuerpo.", "Extiéndelo lentamente sin impulso."], key: 73),
        move("Flexión controlada de codo", english: "Elbow flexion mobility", group: "Bíceps", target: "biceps", equipment: "Peso corporal", description: "Recorrido activo de flexión de codo.", steps: ["Lleva la mano hacia el hombro sin elevarlo.", "Extiende lento."], key: 74),
        move("World's Greatest Stretch", english: "Worlds greatest stretch;World's greatest stretch", group: "Piernas", target: "hip flexors", equipment: "Peso corporal", description: "Secuencia global de zancada cadera y tórax.", steps: ["Adopta una zancada con ambas manos junto al pie.", "Rota el brazo interior hacia arriba y alterna."], key: 75),
        move("Zancada Spiderman con rotación", english: "Spiderman lunge with rotation", group: "Piernas", target: "hip flexors", equipment: "Peso corporal", description: "Movilidad de cadera y rotación dorsal.", steps: ["Coloca el pie junto a la mano del mismo lado.", "Abre el pecho y gira hacia la pierna adelantada."], key: 76),
        move("Inchworm", english: "Inchworm walkout", group: "Core", target: "abs", equipment: "Peso corporal", description: "Movilidad posterior y hombros con apoyo dinámico.", steps: ["Desde de pie camina manos hasta plancha.", "Lleva pies hacia manos y vuelve a levantarte."], key: 77),
        move("Bear sit con rotación", english: "Bear sit rotations", group: "Glúteos", target: "glutes", equipment: "Peso corporal", description: "Movilidad de cadera y tronco sentado.", steps: ["Siéntate con rodillas abiertas y talones delante.", "Gira el pecho alternando lados."], key: 78),
        move("Puente de glúteo articulado", english: "Articulating glute bridge", group: "Glúteos", target: "glutes", equipment: "Peso corporal", description: "Control de extensión de cadera y columna.", steps: ["Túmbate con pies apoyados y eleva pelvis lentamente.", "Desciende vértebra a vértebra."], key: 79),
        move("Respiración diafragmática 90/90", english: "90 90 breathing", group: "Core", target: "abs", equipment: "Peso corporal", description: "Control costal con postura 90/90.", steps: ["Túmbate con rodillas y caderas a noventa grados.", "Inspira abriendo costillas y exhala suavemente."], key: 80),
        move("Rotación de tronco tumbado", english: "Supine spinal twists", group: "Espalda", target: "obliques", equipment: "Peso corporal", description: "Rotación lumbar suave con hombros estables.", steps: ["Boca arriba deja caer las rodillas juntas a un lado.", "Vuelve al centro y alterna."], key: 81),
        move("Rockback global en cuadrupedia", english: "Quadruped rock backs", group: "Glúteos", target: "glutes", equipment: "Peso corporal", description: "Coordinación de cadera y espalda.", steps: ["En cuadrupedia lleva caderas hacia talones.", "Vuelve adelante sin balanceos."], key: 82),
    ]

    /// Fichas técnicas completas; el proyecto exige al menos cinco indicaciones
    /// específicas en español y un volumen suficiente de coaching.
    static let rows: [EnrichedSeed] = items.map { item in
        var seed = item.seed
        seed.description = detailedDescription(item.seed)
        seed.instructions = detailedInstructions(item.seed)
        return seed
    }

    static func description(forName name: String) -> String? {
        rows.first(where: { $0.name == name })?.description
    }

    static func instructions(forName name: String) -> [String]? {
        rows.first(where: { $0.name == name })?.instructions
    }

    private static func detailedDescription(_ seed: EnrichedSeed) -> String {
        let original = seed.description ?? seed.name
        return original + " Ejercicio de movilidad controlada para " +
            seed.muscleGroup.lowercased() +
            ". Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga."
    }

    private static func detailedInstructions(_ seed: EnrichedSeed) -> [String] {
        let names = seed.name.lowercased()
        let staticHold = [
            "mobility-14", "mobility-15", "mobility-16", "mobility-20", "mobility-21",
            "mobility-30", "mobility-31", "mobility-32", "mobility-36", "mobility-38",
            "mobility-39", "mobility-40", "mobility-41", "mobility-42", "mobility-44",
            "mobility-46", "mobility-60", "mobility-61", "mobility-62",
            "mobility-67", "mobility-70", "mobility-80"
        ].contains(seed.catalogId ?? "")
        let hasExternalEquipment = seed.equipment != "Peso corporal"
        let setup: String = hasExternalEquipment
            ? "Antes de empezar, prepara " + (seed.equipment ?? "el material") +
              " en una superficie estable. Comprueba que no se deslice, ajusta la posición corporal y empieza con una amplitud fácil de controlar."
            : "Sitúate sobre una superficie estable y busca una posición equilibrada. Antes de ampliar el recorrido, comprueba que puedes activar el tronco y respirar sin tensión excesiva."
        let main = Array(seed.instructions.prefix(2))
        let breath = staticHold
            ? "Inhala por la nariz y exhala con calma mientras mantienes la postura, sin bloquear la respiración. Cuenta solo los segundos que puedas sostener sin compensaciones ni molestias."
            : "Inhala para preparar el movimiento y exhala durante la fase más exigente. Alterna recorridos lentos y continuos; evita tirones, rebotes y movimientos hechos por inercia."
        let control = "Error típico: buscar más amplitud girando el tronco, arqueando la espalda o perdiendo la alineación articular. Reduce el rango y prioriza la calidad de cada repetición."
        let adapt = staticHold
            ? "Progresión: comienza con intervalos cortos de 15 a 30 segundos y aumenta solo si mantienes la postura estable. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio."
            : "Progresión: comienza con pocas repeticiones y un recorrido cómodo. Aumenta gradualmente la amplitud, nunca la velocidad. Si hay dolor, hormigueo o mareo, interrumpe el ejercicio."
        _ = names // La técnica individual procede de los dos pasos del propio ejercicio.
        return [setup] + main + [breath, control, adapt]
    }

    /// Aliases ingleses para las búsquedas sin duplicar movimientos.
    static let englishAliasesByName: [String: [String]] =
        Dictionary(uniqueKeysWithValues: items.map { ($0.seed.name, $0.englishAliases) })

    private static let normalizedEnglishToSpanish: [String: String] = {
        var lookup: [String: String] = [:]
        for item in items {
            for alias in item.englishAliases {
                lookup[ExerciseSearch.normalize(alias)] = item.seed.name
            }
        }
        return lookup
    }()

    static func spanishName(forEnglish phrase: String) -> String? {
        normalizedEnglishToSpanish[ExerciseSearch.normalize(phrase)]
    }

    private static func move(
        _ name: String,
        english: String,
        group: String,
        target: String,
        equipment: String,
        description: String,
        steps: [String],
        key: Int
    ) -> Item {
        let aliases = english.split(separator: ";").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        let body: String
        switch group {
        case "Hombros": body = "shoulders"
        case "Espalda": body = "back"
        case "Pecho": body = "chest"
        case "Core": body = "waist"
        case "Glúteos", "Piernas", "Isquios": body = "upper legs"
        case "Gemelos": body = "lower legs"
        default: body = "lower arms"
        }
        return Item(
            seed: EnrichedSeed(
                name: name,
                muscleGroup: group,
                equipment: equipment,
                catalogId: "mobility-" + String(key),
                target: target,
                secondaryMuscles: [],
                bodyPart: body,
                description: description,
                instructions: steps,
                primaries: [target],
                secondaries: [],
                sportTag: "Movilidad"
            ),
            englishAliases: aliases
        )
    }
}
