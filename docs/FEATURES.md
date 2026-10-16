# Funcionalidades Gymbro

Última actualización: 2026-10-16

## Tabs

### Inicio (`HomeView`)

- Selector de semana / día.
- Métricas del día: tiempo, kcal (Salud manda), ejercicios.
- Lista de entrenos Gymbro del día + actividades externas de Salud.
- Acciones: empezar, planificar día (`DayPlusSheet`), escanear pizarra.
- Avatar → Ajustes: mismo alto que «gymbro» + fecha (`HomeHeaderAvatarLayout`), alineado arriba.
- Swipe en filas de entreno para eliminar (confirmación glass).

### Diario (`PlanView`)

- Plan semanal por weekday.
- Edición de rutinas / bloques (fuerza + WOD).
- Favoritos de rutinas.
- Overrides de día.
- **Copiar semana pasada**: clona entrenos sueltos de la semana ISO anterior a la actual (nuevos IDs).

### Crear (`StartHubSheet`)

- **Crear mi entreno**: sesión completa (bloques, WOD, pizarra). No asigna día del plan (solo Diario).
- **Apuntar series** (log rápido): picker → modal de series (`QuickLogSheet`) → guardar (≠ Crear completo).
- Favoritos, timer standalone.
- Cámara / galería → escáner de pizarra → revisión → guardar o empezar.

### Progreso (`StatsView`)

- Filtro global de periodo (`ProgressTimeRange`: hoy / semana / mes / 90d / todo). Modal fitted + glass.
- Tiles con **delta vs periodo anterior por defecto** (sin switch; oculto en «Todo»).
- Tiles: entrenos, tiempo medio, cardio (min), racha.
- **Cardio:** FC diaria min / media / máx (Salud) como 3 curvas.
- **Calorías:** energía activa diaria (anillo Movimiento / Salud).
- **Peso:** gráfica vs objetivo (`ProgressWeightChartCard`: línea de meta, Δ actual/objetivo).
- Refresco Salud acotado al periodo (`healthFetchDayCount`).
- Heatmap de actividad (strip o rejilla según periodo).
- Equilibrio muscular: BodyMap + barras (`MuscleBalanceCard`).
- Sección **Más detalle** colapsable (progreso por ejercicio, PRs) + empty states.
- Enlace a historial.

### Ejercicios (`LibraryView`)

- Lista con **buscador siempre visible** (`navigationBarDrawer(displayMode: .always)`).
- Filtro / orden: alfabético, músculo, deporte, favoritos (modal).
- Alta de ejercicio custom.
- **Sin** botón «+ Plan» en filas.

#### Ficha de ejercicio (`ExerciseDetailView`)

- Cabecera `OGBackPageHeader`: volver + **+** (derecha) + favorito glass (44pt).
- **+** abre modal de series (`QuickLogSheet`: series, nota, guardar / cancelar = X), sin sesión completa.
- Carga de discos: Por lado / Una pila / **Sin discos**.
- Tags músculo/equipo vía `LocalizedMuscle`.
- Arte **edge-to-edge**; técnica solo bajo la imagen.
- Subsecciones en `OGCard`: carga sugerida %→kg, discos, 1RM, progreso, historial.
- Títulos de caja: `OGCardSectionTitle`.

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

- Workouts externos → muestras diarias + estímulo muscular (`HealthMuscleMapper`).
- FC por día (min/avg/max) para gráfica Cardio.
- Energía activa diaria para gráfica Calorías.
- Empareja con sesiones Gymbro por UUID / solape temporal.
- Borrar entreno en app → intenta borrar workout en Salud.

## Ajustes

- Cabecera `OGBackPageHeader` en Ajustes y subpáginas (Historial, Peso, Rotación).
- iCloud (nombre, foto, sync).
- Apple Salud (conectar / estado).
- Historial de entrenos.
- **Peso corporal** (misma sección): pesajes + objetivo; un valor por día; sync Salud (muestra más reciente del día).
- Unidades, modo de plan / rotación, semana, descanso, esfuerzo, progresión, incremento.
- Barra y discos.
- Export/import JSON, CSV Strong/Hevy, borrar datos.

## Temporizador

- `StandaloneTimerView`: up/down y modos WOD-like; favoritos de timer.

## Fuera de producto

- **Coach** (reglas locales / tips): eliminado; no aportaba acción real sobre los datos.
