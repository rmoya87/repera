# Guía de pruebas — Repera

Última actualización: 2026-10-19 (monetización Freemium / Pro)

Checklist manual por feature. Preferible dispositivo real para Live Activity y Watch.

## Monetización (Gratis / Pro)

Detalle: [MONETIZATION.md](MONETIZATION.md).

- [ ] Sin `RevenueCatPublicAPIKey` → StoreKit 2 carga productos reales de App Store Connect; si Apple no los ofrece, mostrar motivo en el paywall, sin conceder Pro.
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

- [ ] **Crear → Apuntar series** → elige ejercicio → modal de series → guardar → aparece en Inicio / Historial.
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

- [ ] Foto con EMOM 8’ @6-8 + 2 HIGH HSQ SNATCH → ejercicio correcto.
- [ ] Foto con EVERY 2’ X 4 + 4-3-3-2 BACK SQUAT @6-8 → fuerza: 4 series de 4/3/3/2; conservar la indicación de RPE, sin inventar RIR.
- [ ] Foto con 4 RFT (TC 12’) + POWER SNATCH 40/25 + BOB + BACK RACK R. LUNGES 40/25 + 1’ REST → cuatro movimientos, orden intacto, pesos M/F, 4 rondas, cap 12' y descanso de 60 s.
- [ ] Buscar Back Squat/sentadilla, power snatch/arrancada, high hsq snatch/arrancada colgante y lunges/zancadas; resultados pertinentes con imágenes o placeholder explícito.
- [ ] En editor: Crear WOD, Elegir WOD, Añadir ejercicio, Añadir movimiento libre → push de derecha a izquierda, topbar con volver y título debajo. Volver preserva formulario existente.
- [ ] JPG presentes en bundle tanto como ExerciseArt/<nombre>.jpg como aplanados en raíz: miniaturas visibles en picker y al configurar entreno.
- [ ] TestFlight: ver mensual/anual con precios Apple, completar compra sandbox, restaurar, cancelar, comprobar Pro tras relanzar y denegación tras caducar. Sin tarjetas/cargos reales y sin habilitar Pro por compra pendiente.
- [ ] ASC primera suscripción: confirmar que ambas se envían a revisión con una nueva versión y tienen localizaciones, disponibilidad, precios y contrato de pago configurados.

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
