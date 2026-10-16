# Funcionalidades Gymbro

Última actualización: 2026-10-17 (auditoría visual y aislamiento de secuencias incorrectas)

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
- Arte de ejercicios: silueta masculina anatómica en grises, pelo charcoal, **torso descubierto**, shorts oscuros y zapatillas grises; músculos de cada fase en lime; fondo charcoal casi negro, sin texto ni logos.
- Recursos: full JPG **1024×1024** en `ExerciseArt/<stem>.jpg` y thumb JPG **192×192** en `ExerciseArt/thumbs/<stem>.jpg`. Exportar **solo** con `scripts/export_generated_art.py` desde el Python que tenga Pillow; no dejar generados temporales sin exportar.
- Orden de selección: pasos dedicados `base_1…N` (≥2) → `movementFrames` visualmente verificados → hero. **Ningún fallback antiguo mezclado está validado actualmente**, por lo que `movementFrames` permanece vacío temporalmente. Volverá a poblarse solo tras QA visual de cada reuso.
- Cuarentena preventiva de pasos: **Thruster** (`_3` cambia barra por mancuernas), **Muscle-up barra** (`_3` no es soporte) y **Cargada colgante** (atleta con camiseta). Se muestra el hero con el bloque de técnica hasta regenerar/exportar.
- Los holds estáticos solo muestran hero. En fases aéreas (cuelgue, soporte en barra/anillas o salto), **no dibujar sombra ni óvalo**; en apoyo sí se permite sombra de contacto.
- Dentro de un carrusel mantener **misma persona, cámara, encuadre, lateralidad y equipo**. Solo cambia la pose y el lime de los músculos activos.
- Pie de foto: exactamente **N** frases cortas, imperativas, en español para **N** frames; cada `instructions[i]` describe `_i+1`. Con hero único, la ficha presenta los pasos en bloque de técnica.
- Validación de archivos y reporte por ejercicio: `scripts/audit_exercise_art.py`. La revisión visual de todo el catálogo sigue siendo necesaria antes de declarar cada stem OK.
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
