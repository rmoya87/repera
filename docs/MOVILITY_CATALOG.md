# Catálogo de movilidad de Repera

Última actualización: 2026-10-23

**82 ejercicios** de movilidad controlada, estiramiento y rango articular. Fuente canónica: [`CatalogMovilidad.swift`](../Packages/ReperaDomain/Sources/ReperaDomain/CatalogMovilidad.swift). El catálogo se integra en el selector **Ejercicios → Filtro → Movilidad** de iOS; mantiene nombre en español y alias de búsqueda en inglés. La categoría se identifica mediante `sportTag = "Movilidad"` mientras `muscleGroup` continúa siendo anatómico.

## Cuello (6)

| Ejercicio | Búsqueda en inglés |
|---|---|
| Flexión cervical suave | Neck flexion stretch |
| Extensión cervical suave | Neck extension mobility |
| Rotación cervical | Neck rotations |
| Inclinación lateral cervical | Neck lateral flexion |
| Retracción cervical | Chin tucks |
| CARs de cuello | Neck CARs |

## Hombros, escápulas y pecho (15)

| Ejercicio | Búsqueda en inglés |
|---|---|
| Círculos de hombros | Shoulder circles |
| CARs de hombro | Shoulder CARs |
| Pasadas de hombros con pica | PVC pass throughs, Shoulder pass throughs |
| Deslizamientos en pared | Wall slides |
| Ángeles en pared | Wall angels |
| Rotación externa de hombro con banda | Banded shoulder external rotations |
| Rotación interna de hombro | Shoulder internal rotation stretch |
| Estiramiento de dorsal en banco | Bench lat stretch |
| Estiramiento pectoral en puerta | Doorway pec stretch |
| Estiramiento de hombro cruzado | Cross body shoulder stretch |
| Elevaciones escapulares | Scapular elevations |
| Protracción y retracción escapular | Scapular protraction retraction |
| Flexiones escapulares | Scapular push ups |
| Colgado pasivo | Passive dead hang |
| Colgado activo | Active hang |

## Columna torácica y lumbar (12)

| Ejercicio | Búsqueda en inglés |
|---|---|
| Gato-vaca | Cat cow |
| Rotación torácica en cuadrupedia | Quadruped thoracic rotation |
| Enhebrar la aguja | Thread the needle |
| Libro abierto | Open book stretch |
| Extensión torácica con rodillo | Foam roller thoracic extension |
| Rotación torácica sentado | Seated thoracic rotation |
| Rotación torácica en pared | Wall thoracic rotation |
| Flexión segmentaria de columna | Segmental spinal flexion |
| Postura de la esfinge | Sphinx pose |
| Postura del niño | Child's pose |
| Postura del niño lateral | Side reaching child's pose |
| Inclinación lateral de tronco | Standing side bend stretch |

## Cadera y aductores (17)

| Ejercicio | Búsqueda en inglés |
|---|---|
| CARs de cadera | Hip CARs |
| 90/90 de cadera | 90 90 hip switches, 90/90 hip mobility |
| 90/90 con inclinación frontal | 90 90 hip forward fold |
| 90/90 con elevación de rodilla | 90 90 hip lift off |
| Estiramiento del flexor de cadera | Half kneeling hip flexor stretch |
| Couch stretch | Couch stretch |
| Figura cuatro tumbado | Supine figure four stretch |
| Postura de la paloma | Pigeon pose |
| Frog stretch | Frog stretch |
| Rockback de aductores | Adductor rock backs |
| Mariposa sentada | Butterfly stretch |
| Sentadilla Cossack de movilidad | Cossack squat mobility |
| Sentadilla profunda sostenida | Deep squat hold, Squat pry |
| Sentadilla profunda con balanceo | Deep squat prying |
| Flexión activa de cadera de pie | Standing hip flexion |
| Extensión activa de cadera de pie | Standing hip extension mobility |
| Rotación interna de cadera sentado | Seated hip internal rotation |

## Rodillas y tobillos (12)

| Ejercicio | Búsqueda en inglés |
|---|---|
| Rodilla a pared para tobillo | Knee to wall ankle mobility |
| Dorsiflexión de tobillo con banda | Banded ankle dorsiflexion |
| Círculos de tobillo | Ankle circles |
| CARs de tobillo | Ankle CARs |
| Flexión plantar de tobillo | Plantar flexion mobility |
| Inversión y eversión de tobillo | Ankle inversion eversion |
| Elevación de tibial anterior | Tibialis raises |
| Rodilla sobre dedos controlada | Knee over toes ankle rocks |
| Flexión de rodilla en apoyo | Supported knee flexion mobility |
| Estiramiento de cuádriceps de pie | Standing quad stretch |
| Estiramiento de gemelo en pared | Wall calf stretch |
| Estiramiento de sóleo en pared | Bent knee soleus stretch |

## Cadena posterior (6)

| Ejercicio | Búsqueda en inglés |
|---|---|
| Bisagra de cadera sin carga | Hip hinge drill |
| Estiramiento dinámico de isquios | Dynamic hamstring stretch |
| Deslizamiento neural suave | Sciatic nerve glide |
| Buenos días con pica | PVC good mornings |
| Estiramiento de isquios con banda | Supine band hamstring stretch |
| Perro boca abajo dinámico | Downward dog pedal |

## Muñecas y codos (6)

| Ejercicio | Búsqueda en inglés |
|---|---|
| Movilidad de muñeca en extensión | Wrist extension rocks |
| Movilidad de muñeca en flexión | Wrist flexion stretch |
| Círculos de muñecas | Wrist circles |
| Pronación y supinación de antebrazo | Forearm pronation supination |
| Extensión controlada de codo | Elbow extension mobility |
| Flexión controlada de codo | Elbow flexion mobility |

## Movilidad global (8)

| Ejercicio | Búsqueda en inglés |
|---|---|
| World's Greatest Stretch | Worlds greatest stretch, World's greatest stretch |
| Zancada Spiderman con rotación | Spiderman lunge with rotation |
| Inchworm | Inchworm walkout |
| Bear sit con rotación | Bear sit rotations |
| Puente de glúteo articulado | Articulating glute bridge |
| Respiración diafragmática 90/90 | 90 90 breathing |
| Rotación de tronco tumbado | Supine spinal twists |
| Rockback global en cuadrupedia | Quadruped rock backs |

## Comportamiento y límites

- **Registro iOS:** posturas mantenidas → segundos por serie (una unidad de postura); movilidad dinámica → repeticiones y segundos. Las fichas muestran mejor tiempo, repeticiones (cuando aplica), últimas marcas y sesiones. No hay carga sugerida, lastre ni RIR.
- **Configuración y Play iOS:** `PlannedSet.targetDurationSeconds` guarda los segundos por serie (opcional, compatible con versiones antiguas); el editor los muestra como «Tiempo (s)», Play usa esos segundos como valor inicial y guarda los segundos realmente anotados en `LoggedSet.durationSeconds`.
- **Progreso global iOS:** tiempo total de movilidad realmente registrado y número de sesiones con movilidad; aparece en Progreso junto a las fichas por ejercicio. Las sesiones no registradas no generan segundos ficticios ni afectan a fatiga o e1RM.
- Las fichas contienen descripción e instrucciones de ejecución; el volumen/tiempo se puede ajustar manualmente según el ejercicio y los límites personales.
- **Arte:** ninguno de los 82 movimientos nuevos tiene todavía una imagen técnica individual validada. Se muestra un placeholder anatómico y el icono de movilidad, nunca una ilustración de fuerza asignada por similitud. Queda pendiente generar, exportar y aprobar 82 imágenes propias (y secuencias dinámicas cuando sean pertinentes).
- **Paridad:** Android tiene una rama de catálogo y filtro `feat/android-mobility-aligned-20261023`, todavía sin medición específica de duración en Play y sin QA en dispositivo. Wear y MCP requieren revisar su contrato de duración antes de considerarlos alineados.
