# Funcionalidades Repera

Última actualización: 2026-10-20 (lugar MapKit al apuntar/editar; tap ejercicio → ficha)

## Tabs

### Inicio (`HomeView`)

- Topbar fijo arriba (`ogFixedTopBar`): «repera» + fecha; icono de **mensajes** (liquid glass, solo si hay centro/entrenador vinculado) + avatar → Ajustes. Sin «+» en Inicio (el alta va por **Añadir entreno** / tab Crear).
- **Carrusel de días**: swipe horizontal (o chevrons) entre semanas; al cambiar de semana se conserva el weekday. Al tocar un día pinta al instante sin esperar HealthKit.
- Card **Racha de N semanas** (como openGym `streakWeeks`): cuenta Repera **y** Apple Salud; toque → **Historial** unificado.
- Métricas del día: tiempo; **kcal = max(energía activa del día en Salud, suma de chips Repera+Salud del día)**. Por entreno: kcal de sesión = Watch/Salud **solo si la energía es creíble**; si en la franja solo hay ambiente (p. ej. 2 kcal), manda el **estimado Repera** (MET / time caps). **Tiempo mostrado = inicio→fin**. Detalle alineado con Inicio. Recalc al arrancar (v2026_10_19e).
- Lista de entrenos Repera del día + actividades externas de Salud (etiqueta «DÍA · hora» misma tipografía; chips min/kcal/**nota**/PR como Historial; tile del día «Nota» en lugar de nº de ejercicios). Notas recalculadas al arrancar si cambia la fórmula (`sessionReviewFormulaVersion`).
- Acciones: empezar, **Añadir entreno** (`DayPlusSheet`), escanear pizarra → revisión como **página** (no modal) titulada «Añadir entreno».
- Swipe en filas de entreno: círculo rojo + papelera; **toda la card (chips incluidos)** se desliza. El gesto solo nace fuera del carrusel (sobre chips solo scroll); confirmación glass.
- También en **entrenos planificados** del día (aún sin registro): swipe borra el suelto o quita la plantilla del weekday (igual que desde el detalle).

### Diario (`PlanView`)

- Selector **Programado · Rutinas**. En Programado aparecen la semana Lu–Do y, si hay vínculo, los entrenos publicados por el entrenador/centro. Rutinas conserva las plantillas locales.

- Título arriba (`ogFixedTopBar`) + menú ⋯ en la misma fila (Programado).
- Plan semanal por weekday.
- Edición de rutinas / bloques (fuerza + WOD): modal con **check** (swipe para cerrar); desde Entreno → Editar, **volver** (sin X) + check. Al añadir un bloque, el título por defecto es **Bloque 1**, **Bloque 2**, … (secuencial).
- **Elegir WOD**: catálogo seed de benchmarks conocidos (`CatalogWODs`: Fran, Cindy, Murph…). Detalle con miniaturas de movimientos, tiempo típico y músculos → Usar.
- **Crear WOD**: formato vacío (AMRAP, EMOM, RFT…) en página push con volver arriba y título large debajo; también los selectores de ejercicio/movimiento y la creación de movimiento libre son páginas push.
- Día → asignar rutina: sin X; selección con check blanco en círculo verde.
- Favoritos de rutinas.
- Overrides de día.
- **Copiar semana pasada**: clona entrenos sueltos de la semana ISO anterior a la actual (nuevos IDs).
- **Editor de ejercicio** (`RoutineExerciseEditor`): card **Referencia** con última sesión (series + TOP) y **carga sugerida** (kg grande) según reps + RIR de la 1.ª serie (Epley / 1RM·e1RM); **Aplicar** rellena pesos; **Copiar última sesión** clona series.

### Crear / Center (pestaña central)

- **Sin** gimnasio ni entrenador vinculados (ni invitación pendiente): la pestaña central es **Crear** (`StartHubSheet`), como antes.
- **Con** centro/entrenador o invitación: la pestaña pasa a **Center** (clases, citas, reservas).
- La tarjeta **Añadir entreno** del día y la tab **Crear** concentran alta/escáner; Inicio ya no lleva «+» en la topbar.

### Herramientas de Crear (`StartHubSheet`)

- Título arriba (`ogFixedTopBar`), sin franja vacía encima.
- **Crear mi entreno**: sesión completa (bloques, WOD, pizarra). No asigna día del plan (solo Diario).
- **Apuntar series** (log rápido): picker → modal de series (`QuickLogSheet`) → guardar (≠ Crear completo).
- Pickers de ejercicio (`ExerciseCatalogSearchList`): búsqueda bilingüe ES/EN, nombres alternativos y abreviaturas CrossFit; índice/ranking off-main, prefetch de miniaturas solo de la ventana visible. El cargador encuentra JPG incluso si Xcode los copia a la raíz del bundle.
- Favoritos, timer standalone.
- Cámara / galería → escáner de pizarra → página **Añadir entreno** (cards/thumbs) → toolbar **Guardar** / **Empezar** (iconos). Detalle en `docs/BOARD_SCAN.md`.

### Center (`CenterView`)

- Solo visible en la tab bar si hay vínculo (o invitación) a un centro/entrenador. Selector **Clases · Citas**.
- **Clases**: horarios grupales, saldo de bono, reservas/cancelaciones por RPC segura cuando existe sesión Supabase. Lista de espera aún pendiente.
- **Citas**: horarios de sesiones individuales ofrecidas por entrenadores, reservas/cancelaciones y bono independiente del de clases; pendiente validación real iOS/Apple Auth.
- **Estado real actual:** siete migraciones Supabase desplegadas; consulta iOS nativa desde `BusinessDataStore` implementada pero sin validación compilada/Apple OAuth E2E. No muestra horarios ni cuotas ficticios.
- Los centros vinculados, plazas, reservas confirmadas/espera y saldos se integrarán en esta vista cuando existan los endpoints autenticados y controles RLS.
- Las **clases y citas individuales confirmadas** deberán reflejarse también en **Inicio** al completar la integración. No está operativo todavía.

### Progreso (`StatsView`)

- Título arriba + periodo como subtítulo; calendario a la derecha (`ogFixedTopBar`).
- **Gratis:** solo periodo **Esta semana** (entrenos, tiempo, racha + heatmap básico + teaser Pro). Selector visible: periodos largos marcados Pro → paywall.
- **Pro:** todos los periodos y métricas avanzadas.
- Títulos de sección grises encima de cada card (actividad, cardio, peso, equilibrio…).
- Filtro: **Hoy / Esta semana / Este mes / 90 / 180 / 360 días** (sin «Todo»). Modal fitted + glass.
- Gráficas: día en periodos cortos; **media semanal** en 90/180; **media mensual** en 360.
- Tiles: entrenos, tiempo medio, racha; **FC media** solo si hay lpm de Salud. Sin FC → 3 en una fila; con FC → 2×2. Cabecera **icono + etiqueta** en la misma fila; valor grande (y delta) debajo.
- Racha: semanas consecutivas con ≥1 entreno ≈ openGym `streakWeeks`.
- **Cardio / calorías / tiles / heatmap / músculo / PRs / peso:** un `ProgressSnapshot` por periodo (`ProgressDataEngine` off-main); `ProgressViewModel` cachea por periodo+revisión y cancela preps obsoletas.
- Selector de periodo responde al toque; si hay caché, pinta al instante; si no, loader solo en gráficas.
- Agregación: día (hoy/semana), media semanal (mes/90/180), media mensual (360); Charts ≤48 pts.
- Calorías: por día **max(energía activa Salud, chips Repera+externos)** — misma regla que Inicio; total de gráfica = `summary.totalKcal`.
- Salud: caché diaria ≤360d; match de sesiones indexado; sin sobrescribir ventanas grandes con refrescos cortos.
- Heatmap (tiempo/volumen precalculados), equilibrio (all/hard precalculados), progreso por ejercicio y PRs; enlace a historial.
- `VStack` en el scroll de Progreso (evita salto al subir desde el final por reciclado de LazyVStack).
- Equilibrio: mapa coloreado por **fatiga retenida** (`MuscleMapEngine`, vida media por músculo) — gris → verde → amarillo → naranja → rojo (Recuperado→Fatigado). Incluye entrenos Repera **y** Apple Salud (`HealthMuscleMapper`: correr, tenis/raqueta, bici, natación, HIIT, deportes de equipo, etc.). Barras = series del periodo; color de barra = fatiga. Toggle Todas/Duras.

### Ejercicios (`LibraryView`)

- Buscador **nativo** (`.searchable` + `navigationBarDrawer(displayMode: .always)`) bajo título / filtro / +.
- Al foco: sin animaciones de List (`isSearching`), `NavigationLink(value:)` (sin destinos eager) y thumbs solo desde cache.
- Búsqueda **semántica con pesos** (`ExerciseSearch.ranked` + índice); «press de banca» → Press banca y derivados.
- Thumbs precargados + cache; trazas DEBUG `LibrarySearch` (`rebuild` / `rank top`).
- Arte de ejercicios: hero y pasos con figura atlética gris, **torso descubierto**, pelo corto charcoal, short charcoal, zapatillas grises y lime solo en los músculos activos de la fase; fondo charcoal sin texto ni logos. Referencia visual: `art_ab_wheel.jpg`.
- Full `ExerciseArt/<stem>.jpg` a **1024×1024**, miniatura `ExerciseArt/thumbs/<stem>.jpg` a **192×192**. Exportar siempre con `scripts/export_generated_art.py` (sin homogenize para generaciones nuevas).
- Carrusel técnico: 1) pasos propios `<base>_1…N` con ≥2 imágenes, **si no están en cuarentena visual**; 2) `movementFrames` solo de ejercicios verificados explícitamente; 3) hero. En caso de texto y número de frames distintos, se muestra hero para no desalinear pies de foto.
- Los candidatos anteriores de `movementFrames` permanecen como referencia en el código, pero **no se habilitan sin QA visual**: distintos héroes no garantizan cámara, personaje ni equipamiento constantes.
- Los holds estáticos (hollow hold, handstand hold, L-sit, levers, planche tuck, false grip hang…) muestran hero sin carrusel.
- Cada frame debe mantener persona, proporciones, vestimenta, orientación, equipo y cámara. En suspensión (cuelgue, barra/anillas, salto) **no debe existir sombra/óvalo de suelo**. En apoyo sí puede aparecer uno suave.
- Captions de fase (carrusel): una acción por frase, preferiblemente 8–16 palabras, alineada al frame. Debajo, guía **Cómo hacerlo** con tono de entrenador (setup, ejecución, respiración, error típico, estándar/progresión). Sin notas editoriales (`imagen:`).
- QA: inventario por stem en `docs/EXERCISE_ART_AUDIT.csv`; auditoría reproducible con `.venv-art/bin/python scripts/audit_exercise_art.py`. Estados: `FAIL` (defecto confirmado), `WARN` (revisar), `PENDING_VISUAL_QA` (sin aprobar visualmente). No confundir existencia en disco con veredicto OK.
- Filtro / orden: alfabético, músculo, deporte, favoritos, **WODs** (modal).
- Modo **WODs**: lista de benchmarks (`CatalogWODs`; favoritos arriba) con detalle: movimientos con **miniatura**, músculo, tiempo típico, progresión (`wodResults` por `wodTemplateId`). Topbar: **play** (empezar ya), **+** (apuntar resultado), **★** (`AppSettings.favoriteWODTemplateIds`).
- **Músculo** = grupo anatómico (Pecho, Piernas…). CrossFit / Halterofilia / Gimnasia no son grupos musculares: van en **Deporte** (`sportTag`) y el ejercicio se asigna al músculo principal para métricas.
- Ficha: descripción + guía **Cómo hacerlo** (tono entrenador: setup, ejecución, error típico, estándar) para los **188**. Con carrusel, N captions de fase + coaching debajo.
- Alta de ejercicio custom: página push (`navigationDestination`, `ogPinnedTransparentNav`), no sheet.
- **Sin** botón «+ Plan» en filas.

#### Ficha de ejercicio (`ExerciseDetailView`)

- Topbar fijo transparente: nombre del ejercicio + favorito / **+** en toolbar.
- **+** abre modal de series (`QuickLogSheet`: series, nota, guardar / cancelar = X), sin sesión completa.
- **Gratis:** última sesión + récord / e1RM básico + teaser «Tu evolución» (sin gráfica ni historial completo).
- **Pro — Evolución:** fuerza → Tope/e1RM/top set; comba/erg → Mejor/Total/Tiempo · gráfica · resumen + **Historial**.
- Steppers numéricos (`OGRepeatStepper`): ± fiables en scroll; toque en el número → teclado con **intro** (confirma y cierra; el pad puro de Apple no tiene return).
- **Músculos y equipo**: subsecciones (Músculo / También / Equipo / Deporte); chips con `OGFlowLayout` a todo el ancho de la card.
- Arte **edge-to-edge**; pie de foto del paso actual si hay carrusel.
- **Carga sugerida**: slider 50–95% (paso 5) → kg según Tope 1RM de Evolución o e1RM (sin duplicar el editor de 1RM).

## Sesión de entreno

- Preview (`SessionPreviewView`) → `WorkoutView`.
- **Apuntar series**: UI plana; **Terminar** = círculo verde + check blanco (mismo estilo topbar).
- Series planificadas / logueadas, superseries, WOD clocks.
- **Play WOD por modalidad**: AMRAP → countdown al cap → confirmar **rondas + reps**; For Time / chipper / AFAP → cronómetro count-up → **Terminar** → confirmar tiempo; EMOM/Tabata → intervalos (series por movimiento).
- **Apuntar resultado** (`LogFinalResultsView`): misma captura (rondas+reps / tiempo / series) según `WODFormat.resultCapture`. Scores en `WODBlockResult` / `WorkoutSession.wodResults`. En series por movimiento: **cabeceras de columna** (Veces/Tiempo, Lastre/Reps, Déficit/Reps, Tiempo/Cal…) encima de los steppers; comba reparte **Veces | Tiempo** a ancho igual.
- AMRAP: primero **Rondas** (completas), luego **Reps** (ronda incompleta), p. ej. 12 + 5. `OGRepeatStepper` editable a mano.
- Estilo de apunte por ejercicio (`ExerciseLoggingStyle`): comba → **veces + tiempo** (p. ej. 50 dobles en 1:00); Air bike / Echo / SkiErg / remoerg / cinta → **tiempo + Cal o m**; dominadas/muscle-up → **lastre kg** (0 = sin lastre) + reps; HSPU → **déficit cm** + reps; resto PC → solo reps; barra/DB/KB → kg + reps. `LoggedSet.deficitCm` / `quantityUnit` / `durationSeconds`.
- Menú **⋯**: favorito, nota, eliminar entrenamiento (sin guardar).
- Sesión en curso: swipe rojo (solo icono) para descartar.
- Borrar un entreno guardado también lo elimina de Apple Salud.
- Confirmaciones: `OGConfirmSheet` (liquid glass).
- Rest feedback (sonido / háptico según settings).
- **Live Activity** de descanso (isla / pantalla bloqueo; `NSSupportsLiveActivities`).
- Watch: confirmar ejercicio, conteo, **+1 serie** / log rápido del último ejercicio.
- **Resultado post-entreno** (`SessionReviewEngine`): nota 1–10 por **rendimiento**. Prioridad: bandas publicadas → ritmos por movimiento/nivel → tiempo típico → formato. Blurb en frases naturales («Hiciste 9:24; el ritmo intermedio…»). Recálculo al subir `sessionReviewFormulaVersion`.

## Salud (Apple)

- Workouts externos → muestras diarias + estímulo muscular (`HealthMuscleMapper`) que alimenta **equilibrio/fatiga** y el heatmap; también en **Historial** (junto a Repera) y en la racha de Inicio.
- FC por día (min/avg/max) para gráfica Cardio.
- Energía activa diaria para gráfica Calorías (fusionada con estimados Repera como en Inicio).
- **Sin Apple Watch / kcal ambiente trivial:** estimación local MET (≈5.5 fuerza con carga, ≈7 metcon/PC, ≈9 cardio cronometrado) × peso corporal + volumen + reps; calorías de consola (bike/Ski) como **suelo** del estimado. Al terminar, el estimado del entreno gana frente a energía activa suelta de la franja; Watch/otra app solo si la energía es creíble.
- **Fatiga muscular:** series de máquina/cardio aportan estímulo por duración (no como reps de fuerza); el filtro «Duras» las excluye.
- Empareja con sesiones Repera por UUID / solape temporal (no se duplican en Historial).
- Borrar entreno en app → intenta borrar workout en Salud.
- **Caché en disco** del último snapshot (actividades/FC/kcal): al abrir la app se muestran datos al instante; HealthKit actualiza en segundo plano (anclado + observers).

## Ajustes: centros, entrenadores y contratos

- **Buscar centro o entrenador**: directorio descubrible + invitaciones; al vincularse se elige el bono deseado y la app pasa a **acceso completo** mientras exista el vínculo (sin freemium). Desvincular revoca ese acceso salvo Repera Pro por App Store.
- Ficha del centro vinculado: avatar, bonos/sesiones, planificación, compartir resultados y desvincular.
- **Sincronizar ahora** unifica iCloud + datos Business + espejo privado de entrenamientos.
- Mensajes en Inicio (topbar), no en Ajustes. Avatares de org en app y en Repera Business.

## Onboarding (primer acceso y usuarios existentes)

- Wizard full-screen antes de las tabs: **Sign in with Apple** (obligatorio, CTA en español) → **permisos** → **Gratis o Pro** (si aún no se vieron precios).
- Pantalla de login: fondo **blanco en modo día / negro en modo noche**; botón Apple **negro+texto blanco** de día y **blanco+texto negro** de noche.
- Puerta: **Apple → Supabase** en el primer acceso. Luego: onboarding + (sesión viva | refresh Keychain | binding). Si Apple Keychain se vacía (p. ej. `.revoked` espurio) pero Supabase/binding siguen, se entra igual; la identidad Apple también se espeja en UserDefaults. **No** se borra Apple Keychain en `getCredentialState(.revoked)`. Trazas Consola `com.app.repera`/`AuthSession` y DEBUG `🔐 AUTH`.
- Mascota Repera: saludo en login (`MascotWelcome`), thumbs-up en permisos (`MascotPermissions`); plan Pro usa `MascotHero` (PNG con fondo transparente). En permisos, tras conceder, el CTA pasa de «Permitir» a «Hecho».
- Plan Pro del onboarding: precios y cargos desde StoreKit / App Store Connect (RevenueCat si hay API key).
- Sin iCloud del sistema: usable en local; aviso para activarlo y poder recuperar tras reinstalar.
- Denegar permisos no bloquea el avance; se pueden reintentar en Ajustes.
- LaunchScreen: imageset `Splash` (PNG en asset catalog) centrado con constraint de aspecto 473∶1024 (no anclado a 4 bordes; evita el estirado del snapshot de SpringBoard) sobre verde `#002E24`.

## UI / chrome

- Lienzo `OG.bg` + cards/listas `OG.surface`: en **noche** negro + gris; en **día** gris agrupado + blanco (mismo contraste de secciones que en noche). Listas/Form `insetGrouped` nativos (`ogListChrome`).
- Campos numéricos al apuntar (`OGNumericTextField` / stepper): texto `OG.label` (negro en día, claro en noche); nunca blanco fijo sobre fondo claro.

## Ajustes

- Subpágina con volver: título large **Ajustes** debajo del chevron (`ogPinnedTransparentNav`; barra del sistema visible tras venir de Inicio). Mismo patrón en Historial, Peso y Rotación.
- Títulos de sección Form en gris encima de cada grupo. Acciones e iconos en color de etiqueta (negro/blanco sistema), no verde.
- **Cuenta:** Sign in with Apple, nombre, foto, **Sincronizar ahora** (icono gira + «Sincronizando…»; debajo, fecha de la última sync; iCloud implícito sin fila de estado). Con Supabase: nombre/avatar a `profiles` + Storage. Cerrar sesión.
- **Centro y entrenador:** vinculados + **Buscar centro o entrenador** (directorio RPC `search_discoverable_organizations`).
- **Acceso:** completo por vínculo Business, o Repera Pro (App Store); restaurar compras si no hay patrocinio. **Debug Pro** solo en builds `#if DEBUG` (no en App Store).
- **Salud:** notificaciones, conexión Salud (kcal hoy), ubicación, Ajustes del sistema, **Peso** + objetivo (mismo color `OG.label`). Historial de peso con origen **Propio** / **Salud**. Al dar **Play** se pide ubicación si aún está pendiente.
- **Entrenamiento:** Historial de entrenos + unidades, modo de plan / rotación, semana, descanso, esfuerzo, progresión, incremento.
- Export/import JSON, CSV Strong/Hevy, borrar datos.

## Monetización

Ver [MONETIZATION.md](MONETIZATION.md). Resumen: 3 rutinas biblioteca, 5 custom, 4 escaneos/mes; Pro vía RevenueCat entitlement `pro`.
- Historial de entrenos (Repera + Apple Salud, agrupado por día): misma fila que Inicio — línea «ENTRENO · hora» / día · hora, título debajo; icono de fuerza en Historial y **check** en Inicio; chips idénticos vía `WorkoutRegisterChips` (min / kcal / nota / PR / Notas; Salud + distancia si hay).
- **Detalle de entreno:** resumen Tiempo/Kcal alineado con Inicio. Sección **Salud** solo con métricas auténticas (FC, ruta, ritmo); no muestra dispositivo/kcal si el origen es Repera. Series: RIR solo a la derecha, entero, sin duplicar entre paréntesis. Al **Editar**, el chevron vuelve se sustituye por **X** (cancelar). Las X de cierre usan `OG.label` (negro/blanco), no rojo. Sección **Resultado**: nota + frases naturales. Toque en **nombre o imagen** del movimiento → `ExerciseDetailView`.
- **Lugar (entrenos propios):** al **Apuntar resultado** o **Editar**, buscador MapKit (`MKLocalSearchCompleter` + `Marker(item:)`). Guarda `locationPin` (coords, nombre, id MapKit). En detalle se pinta el mapa centrado con el icono del sitio. Si hay **recorrido de Apple Salud**, ese mapa tiene prioridad y **no** se ofrece pin manual. Actividades solo-Salud no tienen selector de lugar.

## Temporizador

- `StandaloneTimerView`: up/down y modos WOD-like; favoritos de timer.

## Fuera de producto

- **Coach** (reglas locales / tips): eliminado; no aportaba acción real sobre los datos.

## Sitio web (`web/` → repera.app)

- Landing: hero (mascota en pose), pilares, cómo funciona, para quién, funciones, Apple Watch (otra pose), confianza/privacidad, Gratis vs Pro, precios, CTA.
- Legales: `privacy` (incl. cookies), `terms`, `faq` (JSON-LD FAQPage).
- Banner de cookies + preferencias (esenciales vs analítica opt-in); SEO (meta, OG, sitemap, robots).
- Responsive móvil/tablet (nav &lt; 900px) y animaciones de reveal respetando `prefers-reduced-motion`.
- Hosting IONOS (Apache): `web/pack-ionos.sh` genera `repera-ionos.zip` (incluye [`.htaccess`](../web/.htaccess): pretty URLs, gzip, cabeceras). Extraer en `htdocs`. Detalle en [`web/README.md`](../web/README.md).
