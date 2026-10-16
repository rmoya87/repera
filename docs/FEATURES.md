# Funcionalidades Gymbro

Última actualización: 2026-10-16 (QA carruseles + instrucciones PT con landmark `imagen:`)

## Tabs

### Inicio (`HomeView`)

- Topbar fijo arriba (`ogFixedTopBar`): «gymbro» + fecha debajo; avatar a la derecha → Ajustes.
- Selector de semana / día.
- Card **Racha de N semanas** (como openGym `streakWeeks`): cuenta Gymbro **y** Apple Salud; toque → **Historial** unificado.
- Métricas del día: tiempo, kcal (Salud manda), ejercicios.
- Lista de entrenos Gymbro del día + actividades externas de Salud.
- Acciones: empezar, planificar día (`DayPlusSheet`), escanear pizarra.
- Swipe en filas de entreno para eliminar (confirmación glass).

### Diario (`PlanView`)

- Título arriba (`ogFixedTopBar`) + menú ⋯ en la misma fila (Programado).
- Plan semanal por weekday.
- Edición de rutinas / bloques (fuerza + WOD): modal con **check blanco en círculo verde** (sin X; swipe para cerrar).
- Día → asignar rutina: sin X; selección con check blanco en círculo verde.
- Favoritos de rutinas.
- Overrides de día.
- **Copiar semana pasada**: clona entrenos sueltos de la semana ISO anterior a la actual (nuevos IDs).

### Crear (`StartHubSheet`)

- Título arriba (`ogFixedTopBar`), sin franja vacía encima.
- **Crear mi entreno**: sesión completa (bloques, WOD, pizarra). No asigna día del plan (solo Diario).
- **Apuntar series** (log rápido): picker → modal de series (`QuickLogSheet`) → guardar (≠ Crear completo).
- Favoritos, timer standalone.
- Cámara / galería → escáner de pizarra → revisión → guardar o empezar.

### Progreso (`StatsView`)

- Título arriba + periodo como subtítulo; calendario a la derecha (`ogFixedTopBar`).
- Títulos de sección grises encima de cada card (actividad, cardio, peso, equilibrio…).
- Filtro: **Hoy / Esta semana / Este mes / 90 / 180 / 360 días** (sin «Todo»). Modal fitted + glass.
- Gráficas: día en periodos cortos; **media semanal** en 90/180; **media mensual** en 360.
- Tiles: entrenos, tiempo medio, **FC media (lpm de Salud)**, racha.
- Racha: semanas consecutivas con ≥1 entreno ≈ openGym `streakWeeks`.
- **Cardio / calorías:** series precalculadas en background al cambiar periodo (`ProgressChartBuilder`, máx. 48 pts); curvas `catmullRom`.
- Agregación al pintar: día (hoy/semana), media semanal (mes/90/180), media mensual (360).
- Calorías: días con dato; Salud o fallback Gymbro/externos.
- Salud: caché diaria ≤360d. Trazas `category:Progress` (`prepare …ms`, `HK fetch`).
- Heatmap, equilibrio muscular, progreso por ejercicio y PRs; enlace a historial.

### Ejercicios (`LibraryView`)

- Buscador **nativo** (`.searchable` + `navigationBarDrawer(displayMode: .always)`) bajo título / filtro / +.
- Al foco: sin animaciones de List (`isSearching`), `NavigationLink(value:)` (sin destinos eager) y thumbs solo desde cache.
- Búsqueda **semántica con pesos** (`ExerciseSearch.ranked` + índice); «press de banca» → Press banca y derivados.
- Thumbs precargados + cache; trazas DEBUG `LibrarySearch` (`rebuild` / `rank top`).
- Arte ejercicios: ilustraciones anatómicas generadas (gris + lime sobre charcoal); full **1024px**; `ExerciseArt/thumbs/` **192px** para listas. Export limpio: `scripts/export_generated_art.py` (thumbs: `scripts/homogenize_exercise_art.py`).
- Carrusel de técnica (híbrido):
  1. Pasos propios `base_1…N` si existen (≥2) — poses distintas del mismo movimiento (gimnasia Lote 1, HL Lote 2, gym clásico Lote 3, CF Lote 4). Lote 3: fondos, presses, RDL, zancadas, hip thrust, remos, jalón, sentadilla frontal/búlgara, curl barra; press francés sigue en `movementFrames` (gens no distinguían el bottom).
  2. Si no, `movementFrames` en `ExerciseArt.swift` reutiliza héroes ya existentes con poses distintas (~109 ejercicios HL/CF/gimnasia dinámica/gym).
  3. Si no, un solo hero.
- Criterio visual: cada frame debe ser la fase del mismo ejercicio (**mismo equipo con el mismo diseño** entre pasos; misma silueta de persona: pelo, ropa, zapatillas); cambio articular evidente entre pasos. Ropa obligatoria: **tank + shorts + zapatillas** (nunca torso desnudo ni sin shorts). Si el atleta está **en el aire** (cuelgue, soporte sobre barra/anillas, salto a mitad), **sin** óvalo/sombra de suelo — solo fondo charcoal vacío. Al regenerar: anclar con `reference_image_paths` al frame `_1` del mismo ejercicio.
- Holds estáticos (hollow hold, HS hold, L-sit, levers, planche tuck…) **sin** carrusel forzado.
- Pie de foto: los N primeros textos de `CatalogSpanish.instructions` describen la pose del frame i con tono de entrenador y landmark visual (`imagen:…`) en `ExerciseArtView`. Preferir fondos/lockouts claros frente a mid-reps ambiguos si el arte no los distingue. Si un `_1…N` engaña, quitarlo y usar `movementFrames`/hero.
- Filtro / orden: alfabético, músculo, deporte, favoritos (modal).
- **Músculo** = grupo anatómico (Pecho, Piernas…). CrossFit / Halterofilia / Gimnasia no son grupos musculares: van en **Deporte** (`sportTag`) y el ejercicio se asigna al músculo principal para métricas.
- Alta de ejercicio custom.
- **Sin** botón «+ Plan» en filas.

#### Ficha de ejercicio (`ExerciseDetailView`)

- Topbar fijo transparente: nombre del ejercicio + favorito / **+** en toolbar.
- **+** abre modal de series (`QuickLogSheet`: series, nota, guardar / cancelar = X), sin sesión completa.
- **Evolución** en la ficha: tiles 3+2 · tabs + gráfica · resumen (mejor/%/última) + fila **Historial** → listado completo del ejercicio (estilo historial global, abre el entreno).
- Steppers numéricos (`OGRepeatStepper`): ± fiables en scroll; toque en el número → teclado con **intro** (confirma y cierra; el pad puro de Apple no tiene return).
- **Músculos y equipo**: subsecciones (Músculo / También / Equipo / Deporte); chips con `OGFlowLayout` a todo el ancho de la card.
- Arte **edge-to-edge**; pie de foto del paso actual si hay carrusel.
- **Carga sugerida**: slider 50–95% (paso 5) → kg según Tope 1RM de Evolución o e1RM (sin duplicar el editor de 1RM).

## Sesión de entreno

- Preview (`SessionPreviewView`) → `WorkoutView`.
- **Apuntar series**: UI plana; **Terminar** = círculo verde + check blanco (mismo estilo topbar).
- Series planificadas / logueadas, superseries, WOD clocks.
- Menú **⋯**: favorito, nota, eliminar entrenamiento (sin guardar).
- Sesión en curso: swipe para eliminar.
- Borrar un entreno guardado también lo elimina de Apple Salud.
- Confirmaciones: `OGConfirmSheet` (liquid glass).
- Rest feedback (sonido / háptico según settings).
- **Live Activity** de descanso (isla / pantalla bloqueo; `NSSupportsLiveActivities`).
- Watch: confirmar ejercicio, conteo, **+1 serie** / log rápido del último ejercicio.

## Salud (Apple)

- Workouts externos → muestras diarias + estímulo muscular (`HealthMuscleMapper`); también en **Historial** (junto a Gymbro) y en la racha de Inicio.
- FC por día (min/avg/max) para gráfica Cardio.
- Energía activa diaria para gráfica Calorías.
- Empareja con sesiones Gymbro por UUID / solape temporal (no se duplican en Historial).
- Borrar entreno en app → intenta borrar workout en Salud.

## Ajustes

- Topbar fijo transparente en Ajustes, Historial, Peso y Rotación (mismo patrón que Ejercicios).
- Títulos de sección Form en gris encima de cada grupo.
- iCloud (nombre, foto, sync).
- Apple Salud (conectar / estado).
- Historial de entrenos (Gymbro + Apple Salud, agrupado por día; filas como Inicio: hora a la derecha + chips tiempo/kcal/ej.).
- **Peso corporal** (misma sección): pesajes + objetivo; un valor por día; sync Salud (muestra más reciente del día).
- Unidades, modo de plan / rotación, semana, descanso, esfuerzo, progresión, incremento.
- Export/import JSON, CSV Strong/Hevy, borrar datos.

## Temporizador

- `StandaloneTimerView`: up/down y modos WOD-like; favoritos de timer.

## Fuera de producto

- **Coach** (reglas locales / tips): eliminado; no aportaba acción real sobre los datos.
