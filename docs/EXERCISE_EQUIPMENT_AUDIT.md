# Equipamiento del catálogo

Última actualización: 2026-11-08 (agrupación Material: equipo declarado primero)

## Regla funcional

El campo `Exercise.equipment` describe **material realmente necesario**, no la fuente de resistencia: un box jump usa el peso corporal como carga, pero **requiere cajón**. Los aparatos de soporte (cajones, anillas, barras de dominadas, cuerdas, GHD, paredes y bancos) no generan por sí solos kg en Play.

- **Variantes técnicas distintas**: se almacenan como ejercicios independientes, con nombre/identidad e historial propios. Ejemplo del catálogo existente: `Snatch` (barra), `Dumbbell Snatch` (mancuerna) y `Kettlebell Snatch` (kettlebell). No juntar estas variantes bajo una etiqueta «Barra o mancuernas».
- **Varios aparatos necesarios simultáneamente**: se separan por coma, por ejemplo `Cajón, Kettlebell` o `Barra, Banco`. La ficha muestra un chip y un SF Symbol por aparato. La ordenación «Material» usa el **primero** para evitar agrupar un press con barra en «Bancos».
- **Material opcional/alternativo**: no inventarlo como obligatorio. Si modifica el gesto o las métricas, merece otra variante; si solo sirve como apoyo equivalente, describir el soporte con precisión.

## Correcciones incluidas

Se revisaron las entradas seed de `Catalog` (476 fichas) y se especificaron los materiales que faltaban o estaban descritos como «Peso corporal» o «Máquina»:

- Box jump, box jump over, step-up y burpee sobre cajón → `Cajón`.
- Step-up goblet con kettlebell → `Cajón, Kettlebell`.
- Bar-facing burpee → `Barra (obstáculo)`; burpee pull-up → `Barra de dominadas`.
- Dominadas, chest-to-bar, toes-to-bar, muscle-up de barra → `Barra de dominadas`.
- Muscle-up, remos, fondos y trabajo colgado en anillas → `Anillas`; remo pliométrico con pies elevados → `Anillas, Plataforma elevada`.
- Rope climb → `Cuerda de trepa`; pegboard → `Pegboard`; fondos → `Paralelas`; ab wheel → `Rueda abdominal`.
- GHD, remoergómetro, bicicleta y SkiErg → máquina específica en vez de `Máquina` o `nil`.
- Press banca, press mancuernas, hip thrust, pullover y búlgaras → banco más implemento de carga cuando ambos son necesarios.
- Movilidad colgada → `Barra de dominadas`; ejercicios con pica, banda, rodillo o pared conservan su material preciso.

Estas correcciones actualizan el material de entradas existentes, **sin crear duplicados ni cambiar el nombre/ID**. Los metadatos seed se rehidratan en `ReperaStore.mergeCatalogOffMain` conservando el UUID local y favoritos. Los ejercicios creados por el usuario conservan su equipo editable.

## Presentación

`ExerciseCategorySymbols.equipmentSymbol(for:)` asigna iconos por aparato, dejando `dumbbell` como fallback. Incluye aparatos CrossFit/strongman (AbMat, parallettes, neumático, maza, Husafell, etc.) y **Colchoneta** (`rectangle.portrait`) en iOS y Android. `ExerciseEquipmentDisplay.chips` acorta frases largas del feed («Colchoneta o superficie acolchada estable» → `Colchoneta`; descarta «…variante C»). `ExerciseDetailView` presenta chips individuales; no vuelve a colocar iconos en subtítulos.

`ExerciseEquipmentGroup` (iOS + Android) ordena la biblioteca por **Material** así:

1. Aparato del **primer chip** de `equipment` (gana siempre si es específico).
2. Inferencia por **nombre** solo si el equipo es genérico (`Peso corporal`, `Máquina`, vacío).
3. `mat` no es substring libre: «Neumático» → grupo Neumáticos (no Colchonetas).

Correcciones 2026-11-08:

- **Back lever tuck** → `Anillas` (progresión German hang / skin the cat; barra solo alternativa en coaching). Front lever tuck sigue en `Barra de dominadas`.
- **Couch stretch** → `Pared` (banco solo alternativa en el texto; no material obligatorio).
- Dominadas colgadas mal etiquetadas como `Barra` → `Barra de dominadas` (Jumping/L/Negative Pull-Up, Dead Hang, hanging raises, Burpee Muscle-Up / Bar Muscle Up).
- Step-ups con carga: `Cajón` primero (`Dumbbell Box Step Up`, `Medicine Ball Box Step Over`).
- **Box Squat** con `Barra` se queda en Barras (el cajón es marca de profundidad, no pisa el primer chip).

Holds de suelo (Arch/Hollow/Candlestick) usan `Colchoneta` en el seed. Migración remota pendiente de confirmación humana: `20261108200000_fix_material_grouping_equipment.sql`.

## Validación

`ExerciseEquipmentAuditTests` comprueba el recuento de ejercicios, la presencia de material, box jump over, máquinas/cardio, equipos combinados, ausencia de kg en ejercicios de peso corporal y la separación de variantes de snatch. Son **tests añadidos al código**, pendientes de ejecución en CI/Xcode; este registro no acredita compilación ni pruebas en dispositivo.

Las imágenes del ejercicio se buscan por nombre y no se renombraron los movimientos, para no romper el mapeo de arte existente. Esto no certifica que cada movimiento tenga ilustración.
