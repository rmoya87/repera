# Funcionalidades Repera

Última actualización: 2026-10-21 (cap sin rondas implícitas, flecha azul de teclado y entrada Cal H/M)

## Tabs

### Inicio (`HomeView`)

- Topbar fijo arriba (`ogFixedTopBar`): «repera» + fecha; icono de **mensajes** (liquid glass, solo si hay centro/entrenador vinculado) + avatar → Ajustes. Sin «+» en Inicio (el alta va por **Añadir entreno** / tab Crear).
- **Carrusel de días**: swipe horizontal (o chevrons) entre semanas; al cambiar de semana se conserva el weekday. Al tocar un día pinta al instante sin esperar HealthKit.
- Card **Racha de N semanas** (como openGym `streakWeeks`): cuenta Repera **y** Apple Salud; toque → **Historial** unificado.
- Métricas del día: tiempo; **kcal = max(energía activa del día en Salud, suma de chips Repera+Salud del día)**. Por entreno: kcal de sesión = Watch/Salud **solo si la energía es creíble**; si en la franja solo hay ambiente (p. ej. 2 kcal), manda el **estimado Repera** (MET / time caps). **Tiempo mostrado = inicio→fin**. Detalle alineado con Inicio. Recalc al arrancar (v2026_10_19e).
- Lista de entrenos Repera del día + actividades externas de Salud (etiqueta «DÍA · hora» misma tipografía; chips min/kcal/**nota**/PR como Historial; tile del día «Nota» en lugar de nº de ejercicios). Notas recalculadas al arrancar si cambia la fórmula (`sessionReviewFormulaVersion`).
- Acciones: empezar, **Añadir entreno** (`DayPlusSheet`), escanear pizarra → revisión como **página** (no modal) titulada «Añadir entreno».
- Swipe en filas de entreno: círculo rojo + papelera; **toda la card (chips incluidos)** se desliza. El gesto solo nace fuera del carrusel (sobre chips solo scroll); confirmación glass. La capa UIKit del swipe remite explícitamente los toques de la zona revelada a `onDelete`, para que la papelera funcione pese a la vista hospedada superpuesta.
- También en **entrenos planificados** del día (aún sin registro): swipe borra el suelto o quita la plantilla del weekday (igual que desde el detalle).

### Diario (`PlanView`)

- Selector **Programado · Rutinas**. En Programado aparecen la semana Lu–Do y, si hay vínculo, los entrenos publicados por el entrenador/centro. Rutinas conserva las plantillas locales.

- Título arriba (`ogFixedTopBar`) + menú ⋯ en la misma fila (Programado).
- Plan semanal por weekday: tocar un entreno asignado abre la misma vista previa y acción Comenzar que Inicio; deslizar a la izquierda permite quitarlo con acción roja. Solo los días sin entreno abren el selector de asignación Liquid Glass.
- Crear y Editar usan **DayEditorView**, con los mismos controles. El nombre del bloque tiene a su derecha **⋯ Liquid Glass** (sin papelera inmediata): **Eliminar bloque** y **Reordenar**. Reordenar abre una **página push a pantalla completa** y usa `ScrollView` con **zonas de inserción reales y visibles entre cada bloque y ejercicio** (en vez de soltar encima de las filas de `List`). El destino se ilumina en verde durante el arrastre. Permite mover ejercicios entre bloques (conversión fuerza ↔ WOD preservando series); los menús de bloques y ejercicios incluyen **Subir/Bajar**, **Mover a otro bloque** y **Eliminar** según corresponda. El check es un único círculo verde, sin doble glass en la toolbar. Los nuevos bloques se denominan **Bloque 1**, **Bloque 2**...
- **Elegir WOD**: catálogo seed de benchmarks conocidos (`CatalogWODs`: Fran, Cindy, Murph…). Detalle con miniaturas de movimientos, tiempo típico y músculos → Usar.
- **Formato opcional en cualquier bloque**: fuerza y WOD importado admiten AMRAP, EMOM, For Time, Tabata, etc., o **Sin formato**. Duración, intervalos, trabajo/descanso y rondas se editan en una sola fila de celdas numéricas, sin +/− y con el mismo teclado de números que las series (**Siguiente** al próximo campo, **✓** al último). **El selector de formato y sus parámetros forman una única fila agrupada dentro de la tarjeta del bloque**, sin divisores entre los parámetros. El time cap es opcional cuando procede. No existe «Crear WOD»: «Añadir bloque» crea un bloque libre y se selecciona el formato después.
- Día → asignar rutina: sin X; selección con check blanco en círculo verde.
- Favoritos de rutinas.
- Overrides de día.
- **Copiar semana pasada**: clona entrenos sueltos de la semana ISO anterior a la actual (nuevos IDs).
- **Editor de ejercicio de fuerza con carga** (`RoutineExerciseEditor`): card **Referencia** con última sesión (series + TOP) y **carga sugerida** (kg grande) según reps + RIR de la 1.ª serie (Epley / 1RM·e1RM); **Aplicar** rellena pesos; **Copiar última sesión** clona series.

### Crear / Center (pestaña central)

- **Sin** gimnasio ni entrenador vinculados (ni invitación pendiente): la pestaña central es **Crear** (`StartHubSheet`), como antes.
- **Con** centro/entrenador o invitación: la pestaña pasa a **Center** (clases, citas, reservas).
- La tarjeta **Añadir entreno** del día y la tab **Crear** concentran alta/escáner; Inicio ya no lleva «+» en la topbar.

### Herramientas de Crear (`StartHubSheet`)

- Título arriba (`ogFixedTopBar`), sin franja vacía encima.
- **Crear mi entreno**: sesión completa (bloques, WOD, pizarra). No asigna día del plan (solo Diario).
- **Apuntar series** (log rápido): picker → modal de series (`QuickLogSheet`) → guardar (≠ Crear completo).
- Pickers / lista de ejercicios: búsqueda bilingüe ES/EN (`ExerciseSearch` + `CrossFitGlossary`); aliases EN indexados por ejercicio (p. ej. «back squat» → Sentadilla). En pestaña WODs, si la query no pega con ningún WOD, se muestran ejercicios.
- Favoritos, timer standalone.
- Cámara / galería → escáner de pizarra → página **Añadir entreno** (cards/thumbs) → toolbar **Guardar** / **Empezar** (iconos). Reconoce los mismos aliases EN→variante que la búsqueda (`CrossFitGlossary` + `ExerciseSearch`). Detalle en `docs/BOARD_SCAN.md`.

### Center (`CenterView`)

- Solo visible en la tab bar si hay vínculo (o invitación) a un centro/entrenador. Selector **Clases · Citas**.
- **Clases**: horarios grupales, saldo de bono, reservas/cancelaciones por RPC segura cuando existe sesión Supabase. Lista de espera aún pendiente.
- **Citas**: horarios de sesiones individuales ofrecidas por entrenadores, reservas/cancelaciones y bono independiente del de clases; pendiente validación real iOS/Apple Auth.
- **Estado real actual:** siete migraciones Supabase desplegadas; consulta iOS nativa desde `BusinessDataStore` implementada pero sin validación compilada/Apple OAuth E2E. No muestra horarios ni cuotas ficticios.
- Los centros vinculados, plazas, reservas confirmadas/espera y saldos se integrarán en esta vista cuando existan los endpoints autenticados y controles RLS.
- Las **clases y citas individuales confirmadas** deberán reflejarse también en **Inicio** al completar la integración. No está operativo todavía.

### Progreso (`StatsView`)

- Título arriba + periodo como subtítulo; calendario a la derecha (`ogFixedTopBar`).
- **Gratis · Entreno:** periodo **Esta semana** (tiles entrenos/tiempo/racha + heatmap + teaser Pro). Los tiles **no** se repiten en Actividad.
- **Gratis · Actividad:** preview ondulada (no rectas) de cardio/kcal/peso dentro del plot + teaser; sin tiles duplicados.
- **Gratis · Recuperación:** sueño acotado al **periodo** de Progreso (media si hay >1 noche); gráfica nocturna a borde; fases en la barra (sin tiles); Inicio solo con datos y mismo icono luna.
- **Pro:** todos los periodos y métricas avanzadas.
- Selector visible: periodos largos marcados Pro → paywall.
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
- Modo **WODs**: lista de benchmarks (`CatalogWODs`; favoritos arriba) con detalle: movimientos con **miniatura**, músculo, tiempo típico, progresión (`wodResults` por `wodTemplateId`). Topbar: **play** (empezar ya) y **★** (`AppSettings.favoriteWODTemplateIds`); se elimina «Apuntar resultado».
- **Músculo** = grupo anatómico (Pecho, Piernas…). CrossFit / Halterofilia / Gimnasia no son grupos musculares: van en **Deporte** (`sportTag`) y el ejercicio se asigna al músculo principal para métricas.
- Ficha: descripción + guía **Cómo hacerlo** (tono entrenador: setup, ejecución, error típico, estándar) para los **188**. Con carrusel, N captions de fase + coaching debajo.
- Alta de ejercicio custom: página push (`navigationDestination`, `ogPinnedTransparentNav`), no sheet.
- **Sin** botón «+ Plan» en filas.

#### Ficha de ejercicio (`ExerciseDetailView`)

- Topbar fijo transparente: nombre del ejercicio + favorito / **+** en toolbar.
- **+** abre modal de series (`QuickLogSheet`: series, nota, guardar / cancelar = X), sin sesión completa.
- **Gratis:** última sesión + récord / e1RM básico + teaser «Tu evolución» (sin gráfica ni historial completo). El historial empareja por id, `catalogId` o nombre (entrenos WOD/pizarra con UUID huérfano siguen contando).
- Desde el detalle de un entreno, el toque en nombre/imagen resuelve al ejercicio de catálogo (no «Ejercicio no encontrado»).
- Detalle WOD: movimientos del bloque en **una card** separados por línea; chevron dentro; un toque → una ficha (`navigationDestination`).
- Ficha desde entreno terminado → **Esta sesión**: WOD de catálogo = score **global**; WOD libre/series = movimiento vs anterior.
- **Pro — Evolución:** fuerza → Tope/e1RM/top set; comba/erg → Mejor/Total/Tiempo · gráfica · resumen + **Historial**.
- Campos solo numéricos (`OGNumericTextField`, series, formatos, movimiento libre, peso H/M y resultados): teclado **personalizado Repera 4×4** como vista real `inputView` de UIKit, sin letras ABC/DEF: filas `1 2 3 ocultar`, `4 5 6 +`, `7 8 9 −`, `. 0 borrar acción`; **flecha azul** al pasar de campo y **✓ verde** en el último. El primero consolida el campo sin cerrar el teclado y pasa al de la derecha; el último confirma y lo cierra. El tiempo admite `:` desde el accesorio. Los steppers heredados pueden seguir ofreciendo ± fuera de las tablas compactas, pero al tocar su valor usan el mismo teclado y confirmación.
- **Músculos y equipo**: subsecciones (Músculo / También / Equipo / Deporte); chips con `OGFlowLayout` a todo el ancho de la card.
- Arte **edge-to-edge**; pie de foto del paso actual si hay carrusel.
- **Carga sugerida**: slider 50–95% (paso 5) → kg según Tope 1RM de Evolución o e1RM (sin duplicar el editor de 1RM).

## Sesión de entreno

- Preview (`SessionPreviewView`): **Play** (único botón prominente verde con icono blanco) inicia el registro; **Editar** está exclusivamente dentro de ⋯, sin lápiz duplicado, y abre `DayEditorView`. El subtítulo queda alineado a la izquierda, junto al título y sin margen de lista excesivo. Ya no existe el flujo «Apuntar resultado».
- Crear entreno desde «Añadir entreno» abre editor de pantalla completa con navegación propia, no dentro del sheet compacto.
- En el detalle de entreno, el tile de calorías se omite cuando Salud no aporta una medición auténtica.
- **Series de fuerza / WOD** en Crear, Editar y Play: misma retícula **Serie (número circular) | Anterior | KG, tiempo o cantidad | Reps | RIR** (si procede), sin +/−. El número circular no parece editable y RIR se ajusta en la misma fila. Los ejercicios de máquina/cardiovascular usan **Cal o metros**, nunca KG cuando su estilo de registro no utiliza carga; en bloques de fuerza y movimientos WOD se puede elegir Cal/Metros con selector segmentado; la unidad queda guardada y se respeta en Play. El teclado 4×4 utiliza flecha negra / ✓ verde y funciona igual en creación, edición y ejecución. Los registros anteriores se muestran si existen.
- **En sesión activa** la tabla añade un **check verde a la derecha** para marcar cada serie, por orden, iniciando el descanso correspondiente. Las técnicas de dropset y rest-pause se despliegan **dentro del bloque actual**, no en una sección global más estrecha. Los objetivos sin completar no aparecen como registrados. En edición no se muestra el check de completar.
- **Teclado de series**: foco en el valor izquierdo; flecha negra integrada en el teclado consolida y enfoca el valor a la derecha; el **✓ verde** del último consolida y, durante Play, completa esa serie. Las teclas muestran solo números, decimal, borrar y ±; el punto se transforma en `:` para tiempos.
- **Play** muestra bloques agrupados como Editar, omitiendo configuración inicial de rutina, hora, progresión y Favorito. Los nombres de bloque son fijos; el reloj a su derecha carga la modalidad configurada o cronómetro libre. Los ejercicios y series se expanden dentro del bloque: tocar un ejercicio cerrado abre sus series; tocar la miniatura o el nombre cuando está abierto navega a `ExerciseDetailView` con esa sesión resaltada. La toolbar muestra **Anterior ←** y **Siguiente →** para navegar sin dar por realizado el ejercicio; el check final guarda el entreno. Desde ⋯ se puede **Editar entreno en una página de navegación a pantalla completa** (sin hoja modal), conservando las series anotadas. El **nombre real del entreno aparece en la barra superior en modo inline**, sin subtítulo separado.
- **Notas en Play**: se muestran siempre como `TextEditor` dentro de la pantalla, sin modal. Se guardan de manera automática (con breve espera durante la escritura) y al abandonar el campo.
- **Favorito** es la etiqueta única del toggle en el editor. En Play el menú ⋯ incluye **Cancelar entreno**: descarta la sesión en curso, sin guardarla.
- Series planificadas / logueadas, superseries, WOD clocks.
- **Escáner de pizarras:** interpreta `AMRAP 16'` y `FOR TIME (TC 14')` como bloques separados. `TC` es **time cap del bloque completo**, nunca 14 series por ejercicio; For Time sin rondas explícitas tiene `rounds=nil` y preserva el orden real de movimientos repetidos. Los alias ES/EN/acrónimos `GTOH`, `BMU`, `C2B`, `AKBS`, `DU`, `SU` vinculan ejercicios del catálogo. `20/16 CAL*` se registra en Air Bike como **20 cal** (16 cal femeninas en notas), nunca kg. Las escalas BMU/C2B/Pull-ups y DU/SU se preservan; `REST BTWN` se configura como descanso entre rondas y la anotación original permanece en notas. Tests con esa pizarra en `BoardScanLiteParserTests` y `BoardImportParserTests`.
- **Temporizador por bloque (WOD o fuerza)**: AMRAP → countdown a la duración → confirmar rondas + reps; For Time / Chipper / AFAP → count-up con límite opcional y resultado de tiempo; EMOM/Circuito/Tabata → intervalos y descansos configurados; Ladder → tiempo ascendente; sin formato → cronómetro libre ascendente. El botón reloj del encabezado presenta el temporizador en `fullScreenCover`, con **fondo negro también por encima de la safe area y status bar**, y botón de cerrar blanco, conservando cuenta previa y modo configurado. En For Time el TC muestra aviso al alcanzarse pero el reloj **continúa contando tiempo real**; el atleta confirma su resultado al terminar, antes o después del cap, sin imponer ni inventar tiempo final.
- En Play se pueden **registrar series manualmente** sin activar el reloj; el temporizador es una acción opcional por bloque. Al concluir un intervalo cronometrado se marca el bloque completado sin inventar pesos, series ni repeticiones; los ejercicios siguientes permanecen pendientes.
- Peso/tiempo y repeticiones se disponen en una fila compacta, con columna de registro anterior; el menú RIR queda debajo y la confirmación se muestra solo durante la ejecución.
- **Finalización:** tanto el score del WOD (`WODResultConfirmSheet`) como el resumen de nota (`SessionReviewSheet`) son **hojas con fondo de modal y altura intrínseca ajustada al contenido**, usando `ogFittedHeight` y `ogFittedSheet` en vez de detents medium/large. El resultado numérico comparte el teclado **Siguiente / ✓**.
- La función histórica «Apuntar resultado» ya no tiene acción, vista ni ruta dedicada: para registrar un entreno planificado se usa **Play** y sus controles de series y scores WOD.
- AMRAP: primero **Rondas** (completas), luego **Reps** (ronda incompleta), p. ej. 12 + 5. `OGRepeatStepper` editable a mano.
- Estilo de apunte por ejercicio (`ExerciseLoggingStyle`): comba → **veces + tiempo** (p. ej. 50 dobles en 1:00); Air bike / Echo / SkiErg / remoerg / cinta → **tiempo + Cal o m**; dominadas/muscle-up → **lastre kg** (0 = sin lastre) + reps; HSPU → **déficit cm** + reps; resto PC → solo reps; barra/DB/KB → kg + reps. `LoggedSet.deficitCm` / `quantityUnit` / `durationSeconds`.
- Menú **⋯**: favorito, nota y **Cancelar entreno** (descarta sin guardar).
- Sesión en curso: swipe rojo (solo icono) para descartar.
- Borrar un entreno guardado también lo elimina de Apple Salud.
- Confirmaciones: `OGConfirmSheet` (liquid glass).
- Rest feedback (sonido / háptico según settings).
- **Live Activity** de descanso (isla / pantalla bloqueo; `NSSupportsLiveActivities`).
- Watch: confirmar ejercicio, conteo, **+1 serie** / log rápido del último ejercicio.
- **Resultado post-entreno** (`SessionReviewEngine`): nota 1–10 por **rendimiento** (bandas → ritmos → típico → formato). Si Salud aporta **FC media/máx** (y/o kcal), `SessionCardioEffort` afina la nota ±2 según el esfuerzo real y lo explica en el texto. El **nivel** va como subtítulo bajo la nota. Recálculo al subir `sessionReviewFormulaVersion`.

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
- **Detalle de entreno:** fecha + Tiempo/Kcal/Volumen + nota en un bloque continuo (sin título «Resultado»). Sección **Salud** solo con métricas auténticas (FC, ruta, ritmo). Series: RIR solo a la derecha. Al **Editar**, chevron → **X** (cancelar). Toque en **nombre o imagen** del movimiento → `ExerciseDetailView`.
- **Lugar (entrenos propios, opcional):** tocar nombre o mapa abre el sheet con ese sitio; papelera quita, buscador cambia, check guarda. Sin sitio: búsqueda desde tu ubicación (se puede cerrar sin elegir). Recientes/resultados bajo el buscador. Icono = categoría (no mini-mapa). Ruta Salud tiene prioridad y bloquea pin manual.

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


## Sueño y ciclo (iOS 27)

- Progreso agrupa **Entreno**, **Actividad** y **Recuperación** con el segmented **fijo** bajo la barra (no hace scroll con el contenido).
- En Recuperación, **Sueño** es título de sección; **Ciclo** solo aparece si hay registros reales de menstruación. Si el periodo filtrado no tiene noches pero sí hay historial, se muestran las noches anteriores con una nota.
- Ajustes → **Salud conectada** (único acceso): entrenamientos/energía + sueño/ciclo. Punto rojo si faltan permisos por aceptar/rechazar; al abrir se listan. En Progreso → Recuperación, si aún no se decidió el sueño, aparece alerta Aceptar/Rechazar.
- Sueño: una sola fuente nocturna y fusión de intervalos solapados; tendencias con Swift Charts.
- Ciclo: muestras de menstruación y pruebas de ovulación, fase solo orientativa con historial suficiente. No permite confirmar ovulación ni prever fertilidad.
- Consejos locales durante el entrenamiento y al consultar resultados, sin modificar la nota real ni la prescripción profesional.
- Supabase no recibe horas o fases de sueño, datos menstruales, temperatura, notas médicas, calorías/duración de Apple Salud ni indicadores derivados.
- Se elimina el editor y la semántica de superseries; los campos antiguos se conservan solo para lectura compatible.
- Los editores desde Diario y la revisión del entreno se muestran mediante navegación push, no como hojas modales anidadas.
- La acción «Añadir serie» tiene área táctil de altura mínima 44 puntos y se alinea con las filas de series.


## Cardio exterior: altitud, meteorología y parciales

- En la ficha de **Entreno** y la ficha de Apple Salud, los recorridos GPS (carrera, caminar, senderismo, bici y otras actividades exterior con ruta) permiten alternar mediante selector segmentado nativo **Cardio / Altitud** dentro de la misma tarjeta; curvas suavizadas (`catmullRom`) y clip del plot. En **Altitud**, los tiles son **máx / mín / media** de altitud (m); en **Cardio**, FC y velocidades.
- La altitud procede de Core Location (solo muestras con precisión vertical válida), tanto de Apple Salud como de rutas nuevas grabadas por Repera; las rutas antiguas sin altitud muestran ausencia de datos, no desnivel inventado.
- El clima forma **parte de la misma card del mapa** (franja inferior). **No se guarda en el entreno**: WeatherKit se consulta al abrir el detalle (~1 km + atribución); fecha = `startedAt`/`finishedAt`. AQI histórico → «—».
- **Parciales:** columnas KM, Tiempo, **Ritmo** (valores `/km`) o `km/h` en bici, y **Frec. cardiaca** (valores en LPM). Sin pie explicativo bajo la tabla.
- En actividades sin GPS válido o con menos de 1 km no se inventan parciales. Natación y cardio de interior no muestran parciales estimados a partir del tiempo total.
- Son métricas **locales**: las rutas, altitudes, FC y datos meteorológicos/AQI no se añaden al espejo de Supabase.


### Configuración WeatherKit y límites actuales

- WeatherKit requiere que el propietario active **App Services → WeatherKit** y **App Capabilities → WeatherKit** en el identificador `com.app.repera` dentro de Apple Developer; el entitlement ya figura en `project.yml` / `Repera.entitlements`. Si la franja muestra «—» con pie de error de autorización, casi siempre falta ese servicio en el portal o el perfil no se regeneró. Tras habilitarlo, regenerar el perfil y instalar en iPhone (el simulador suele fallar).
- La localización del mapa se mantiene intacta y privada. Para solicitar el tiempo solo se transmite al servicio meteorológico de Apple una coordenada redondeada a 2 decimales (~1 km) y la fecha/hora del entreno.
- No se sustituye un índice de calidad del aire histórico por valores actuales: WeatherKit no ofrece AQI histórico mediante sus consultas nativas; conectar un proveedor alternativo requiere comprobar licencia comercial, cobertura de fechas y aceptación explícita del tratamiento de coordenadas. Mientras tanto, la caja indica «—».
- El valor de distancia en las tarjetas de resumen sustituye la repetición de «FC media» cuando existe ruta GPS. La FC media permanece visible en la cabecera de la gráfica.
