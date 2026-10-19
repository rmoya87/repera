# Guía de pruebas — Repera

Última actualización: 2026-10-19 (monetización Freemium / Pro)

Checklist manual por feature. Preferible dispositivo real para Live Activity y Watch.

## Navegación deportista (2026-10-19)

- [ ] La barra muestra **Inicio · Diario · Center · Progreso · Ejercicios** (sin pestaña Crear).
- [ ] **Inicio → +** abre todas las acciones antiguas: crear entreno, apuntar series, favoritos, temporizador y escanear pizarra; iniciar/continuar entreno conserva la navegación.
- [ ] **Inicio → Añadir entreno** conserva su sheet por día y **Crear plan** abre Diario en «Personal».
- [ ] **Diario** abre en «Entrenador» con estado vacío honesto; «Personal» y «Rutinas» conservan datos y acciones del usuario.
- [ ] **Center** muestra estado sin clases sincronizadas, no inventa disponibilidad ni permite registrar una reserva ficticia.
- [ ] **Ajustes** separa centros/entrenadores, servicios externos y el plan «Repera Pro» de Apple.
- [ ] Con futuro backend: validar reservas, devolución de crédito, caducidad, notificaciones, varios centros y revocación, sin borrar historial local.

## Monetización (Gratis / Pro)

Detalle: [MONETIZATION.md](MONETIZATION.md).

- [ ] Sin `RevenueCatPublicAPIKey` → app en Gratis; paywall indica compras no disponibles.
- [ ] Debug → Ajustes → Debug Pro: simular Free / Pro mensual / anual / trial / gracia / caducada / offline.
- [ ] Crear 4ª rutina biblioteca → paywall; editar/borrar las 3 existentes OK.
- [ ] Crear 6º ejercicio custom → paywall; catálogo seed sin límite.
- [ ] 4 escaneos OK en el mes; 5º → paywall; fallo OCR / cancelar no consumen.
- [ ] Ficha ejercicio Gratis: última sesión + teaser; Pro: evolución completa.
- [ ] Progreso Gratis: solo «Esta semana»; periodos Pro abren paywall sin cambiar rango.
- [ ] WOD: registro libre; historial completo = Pro.
- [ ] Restaurar compras (sandbox) y gestionar suscripción (enlace Apple).
- [ ] Import JSON no activa Pro; export sigue incluyendo datos deportivos.

## Log rápido (Apuntar series)

- [ ] **Inicio → + → Apuntar series** → elige ejercicio → modal de series → guardar → aparece en Inicio / Historial.
- [ ] Racha en Inicio con Salud autorizada → Historial lista Repera **y** entrenos de Salud (sin duplicar vinculados).
- [ ] Distinto de **Crear mi entreno**: no pide bloques/WOD.
- [ ] **Ficha ejercicio → +** → mismo modal de series (no abre sesión completa).
- [ ] En modal: check (guardar) estilo topbar; cancelar = X.

## % → kg

- [ ] Ejercicio con historial de peso (e1RM) + pizarra con `#70%` → en revisión ves kg sugeridos.
- [ ] Ficha → **Carga sugerida**: slider % muestra kg.
- [ ] Ficha → toque en el número de un stepper → teclado + **intro** confirma y cierra (sin barra Listo).
- [ ] Ficha → **Evolución**: pulsar Tope 1RM edita a mano; al superar e1RM al guardar, el tope sube solo.
- [ ] Filtro **Músculo**: Thruster / Arrancada aparecen bajo Piernas/Hombros/… no bajo CrossFit; filtro **Deporte** sí agrupa CrossFit/Halterofilia/Gimnasia.

## Copiar semana pasada

- [ ] Diario → ⋯ → **Copiar semana pasada**.
- [ ] Con entrenos sueltos la semana ISO anterior → aparecen en esta semana (nuevos IDs).
- [ ] Sin datos → alerta «No había entrenos sueltos…».

## Progreso

- [ ] Periodo «Esta semana» → tiles muestran delta vs semana previa (sin switch).
- [ ] Con «Todo» no hay deltas.
- [ ] Cardio / kcal con Salud autorizada.
- [ ] **Peso**: gráfica + línea de meta si hay objetivo; Δ actual vs objetivo.
- [ ] Periodo corto → refresco Salud acotado (`healthFetchDayCount`).
- [ ] **Más detalle** colapsable; empty states si no hay ejercicios / PRs.
- [ ] Sin autorización Salud → card «Salud no conectada».

## Peso corporal

- [ ] Ajustes → Peso: registrar → un solo valor por día (re-registrar hoy actualiza).
- [ ] Objetivo en la misma sección; se refleja en Progreso.
- [ ] Tras sync Salud no aparecen varios pesajes del mismo día.

## Sesión / eliminación

- [ ] Menú ⋯ → eliminar entreno → `OGConfirmSheet` glass.
- [ ] Swipe en Inicio / sesión en curso → eliminar con confirmación.
- [ ] Borrar entreno guardado → desaparece también de Salud (si estaba enlazado).
- [ ] Terminar Apuntar series: check verde en círculo (sin doble círculo).

## Pizarra

- [ ] Pizarra con ≥2 bloques claros → «Análisis local» sin espera larga de IA.
- [ ] Imagen oscura (TV) → OCR legible (lienzo negro).

## Live Activity (dispositivo real)

- [ ] En sesión, inicia descanso → Live Activity / Dynamic Island con cuenta atrás.
- [ ] Al acabar el rest, la activity se cierra.

## Watch log rápido

- [ ] iPhone + Watch emparejados, app Watch abierta.
- [ ] Sin sesión: **Iniciar en iPhone** / **+1 serie** arranca log rápido del último ejercicio.
- [ ] Con sesión: **+1 serie** registra una serie en el ejercicio actual.

## Ajustes / navegación

- [ ] Avatar Inicio → Ajustes con botón volver.
- [ ] Historial / Peso / Rotación: topbar fijo transparente (como Ejercicios) + volver del sistema.
- [ ] No existe entrada Coach.

## Splash de lanzamiento (regresión)

- En iPhone pequeño y grande, cerrar por completo y abrir en vertical: personaje y logo mantienen la misma forma y tamaño relativo del LaunchScreen a la pantalla de espera.
- Repetir con sesión iniciada y onboarding pendiente: sin zoom, estiramiento, flash negro ni salto de posición.
- Girar a horizontal en dispositivo compatible: `scaleAspectFit` conserva la imagen entera, sin distorsión.
- Instalar una compilación nueva (5 o posterior) para invalidar la captura de lanzamiento cacheada por iOS.
