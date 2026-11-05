# Progreso y preparación: fuentes verificadas

Última actualización: 2026-11-05 (nota 0–10 full-width; carga log; FC selección ×3).

## Organización del hub (chips, 04/11/2026)

- Navegación por **chips horizontales** (no segmentado Entreno/Actividad/Recuperación): **Entreno · Fuerza · Físico · Corazón · Recuperación · Deportes**.
- Iconos propios Repera (bolt, mancuerna, caminar, ECG, **luna**, bandera); **sin** anillos Activity ni set de Apple Salud.
- Chip: icono + título en la misma fila; valor debajo. Seleccionado = verde sólido + texto/icono negros (sin borde). Fila de chips con fondo transparente; iOS = Liquid Glass en no seleccionados.
- Valores glance: Entreno (nota/sesiones), Fuerza (PR all-time), Físico (**media diaria** de estímulo en 7 días), Corazón (LPM real), Recuperación (nota de preparación 0–10, nunca «·»), Deportes (nº de salidas En vivo **de los últimos 7 días**).
- **Sin calendario** de periodo global: el hub usa siempre la ventana móvil **Últimos 7 días** (hoy + 6 anteriores, no lun–dom). Pro añade bloques «A largo plazo» y resúmenes **«Este mes»** / **Media mes** embebidos, no cambia el subtítulo del hub a mes.
- Subtítulos: Entreno/Fuerza/Físico/Deportes = **Últimos 7 días**; Corazón y Recuperación = **Ahora**.
- Cierre estilo Apple Salud: bloque **«Este mes»** al final de Físico / Corazón / Recuperación / Deportes (mes calendario aunque el hub mire 7 días).
- Acentos: Recuperación = azul oscuro violáceo (noche); Deportes = teal (no morado).
- Fondos = tokens de app (`OG.bg` / `surface` / Material `background`), no tintados en verde. Chevron solo en destinos navegables.
- **Pro en Progreso:** StoreKit/Play **o** `business_sponsored_pro` vía `get_my_effective_entitlements`. iOS re-cablea gates al cambiar entitlements; Android aplica `setBusinessSponsoredAccess` tras el refresh de Center. Caché local del último Pro StoreKit verificado (offline / arranque).

## Qué se considera actividad terminada

- Entrenamientos registrados y finalizados en Repera.
- Sesiones `Comenzar`/Apple Watch/Wear OS terminadas y guardadas.
- Actividades de Salud externas (evitando coincidencia con sesiones Repera).
- Reservas de clases o citas con estado `attended`, incluida la asistencia histórica. `booked`, `waitlist`, `cancelled` y `no_show` no suman.
- La asistencia se cuenta una sola vez; si existe una sesión realizada vinculada, o una medición de Salud/Watch con solapamiento suficiente, esta prevalece.

**Regla de evidencia:** asistencia no equivale a duración efectiva, calorías, frecuencia cardíaca, intensidad, series, tonelaje o esfuerzo. La asistencia sin mediciones aporta frecuencia de sesiones, días y rachas, no métricas fisiológicas ficticias. Una clase con un entreno guardado aporta las métricas del entrenamiento, sin duplicarlas.

La información de clases se carga por usuario autenticado desde `BusinessDataStore`, respetando los permisos y los vínculos existentes en Supabase.

## Organización de Progreso (iOS y Android, 04/11/2026)

- **Entreno:** consistencia **«Últimos 7 días»** primero; después tiles **Media mes / Racha / Entrenos / Tiempo** (mes calendario). Puntuación verificada + confianza; **equilibrio muscular = estado actual** (fatiga retenida); movilidad; largo plazo (Pro) e Historial.
- **Fuerza:** insight «Carga y marcas»: héroe = nº de PR **all-time**; caption = kg de volumen de los **últimos 7 días** (sin línea «Hoy N ses. · kg · PR»). Barras = **volumen diario** de esos mismos 7 días con escala **log1p** respecto al pico (un outlier no aplasta el resto). Las actividades sin series con peso registrado cuentan en Entreno/Físico, pero nunca generan kg ni PR sintéticos. Tiles **Sesiones fuerza / Ejercicios** = solo sesiones con series de fuerza confirmadas en esos 7 días. **Progreso por ejercicio** y **récords** = mejores marcas de siempre. Teasers en gratis.
- **Físico — Estímulo activo (7d):** héroe = **media diaria** = `minutos totales (Repera terminados + Salud/HC) / 7` (ventana fija; días sin estímulo cuentan como 0 min de actividad, no son ceros fisiológicos). Mini gráfica = **barras desde la base** con los minutos/día de la ventana de 7 días (`ProgressMiniFillBars` / `FILL`). Caption «media diaria» alineada abajo con la gráfica; el sobrante bajo el título es el dato grande. Unidad corta **m** (no «min»). Nunca sesiones abiertas (en iOS `durationMinutes` con `finishedAt ?? now` inflaría el total). Duración en **h + m** si ≥ 60 min.
- **Físico — Este mes:** héroe = **media por semana** = `minutos del mes / (días transcurridos del mes / 7)`; caption «media semana» (sin «N sesiones»); barras fill minutos/día del mes; mismo layout título → dato grande → caption alineado a la base de la gráfica. Heatmap, calorías y peso aparte.
- **Calorías (Pro, hub 7d):** fuente = **energía activa de Apple Salud / Health Connect** (y kcal de actividades externas HK/HC; nunca MET inventados de Repera). El eje X muestra siempre los **7 días** de la ventana (ticks de calendario); días sin kcal = **hueco** (no se inventa 0 kcal fisiológico). Media/día = media solo sobre días **con** dato. iOS: `ProgressChartBuilder.mergedDailyCalories` → `ProgressCaloriesChartCard`; Android: `ProgressChartBuilder` → `ProgressCaloriesPlot`.
- **Peso:** puntos filtrados al **último año (~365 días)** respecto a hoy (`buildWeightPoints` / snapshot Android). Si el periodo del hub no tiene pesajes, se muestra el historial real dentro de ese año. Sin interpolar huecos.
- **Corazón:** FC de **últimos 7 días** (Apple Salud / Health Connect) como **cápsulas a la derecha** dibujadas en Canvas de Y(min lpm)→Y(max lpm) sobre un dominio holgado (p.ej. mín−12…máx+12): un día 58…120 **flota** a media altura; **no nace en el eje X**. Héroe = media reciente; tiles Mín./Máx. 7 d. **Sin placeholders**. **Este mes (Cardio):** media **semanal** + mismos rangos. Android Gratis: teaser; número del hub usa HC real.
- **Recuperación:** subtítulo **Ahora**; preparación actual; **evolución y sueño en 7 días**; constantes y ciclo. Textos vacíos cortos («Aprendiendo · …», 1 línea). Sueño **Horas por noche**: área + línea con degradado nocturno en marco redondeado (no barras), sin padding lateral en el área de datos y con guías horizontales punteadas de horas. Cierre «Este mes».
- **Deportes:** tiles (salidas, plan, tiempo En vivo) = **últimos 7 días**. **Evolución y récords** = valor + minigráfica (sin narrativa larga ni caption «historial · mejores marcas»). **Progresión en ejercicios** = mismo héroe grande que «Resumen por actividad» (número + «al alza») + lista e1RM. Cierre **Este mes** = resumen por actividad con **nombre a la izquierda** y **dato grande (km/tiempo) a la derecha**; subtítulo `N× · Más larga…`. Android: `ExternalHealthHistoryEntry.distanceMeters` solo si el permiso `DistanceRecord` ya está concedido (mismo fail-closed que `readSessionMovement`: origen de la sesión preferente; si no, un único origen en ventana).
- **Gratis/Pro:** hub siempre Últimos 7 días (+ resumen «Este mes» + teasers «Ejemplo» en gratis); Pro añade largo plazo real. Sin selector de periodo en el hub.

## Entrenamiento (puntuación personal)

Solo se muestran valoraciones verificadas `scoreBasis == personalHistory`, calculadas sobre mediciones deportivas reales y comparaciones de rendimiento propio. No se suman puntos por la cantidad de series anotadas ni por datos fisiológicos.

- Fuerza y WOD: mediana de hasta cinco días personales comparables en los últimos 180 días; se exigen al menos **2 días anteriores** en el mismo ejercicio y contexto (o equivalencias conservadoras), y **≥60% de cobertura** de las unidades de rendimiento prescritas. Un estímulo WOD calibrado de otra sesión compatible exige **3 días anteriores**. La nota usa `clamp(round(7 + 11 × ln(actual/referencia)), 1, 10)` con pesos por nivel de evidencia.
- Salidas GPS desde Comenzar: distancia real de al menos 500 m, tiempo activo y **2 días anteriores** del mismo deporte y distancia comparable (±20%, dentro de los 180 días previos). La mediana personal sirve de referencia.
- Sin referencias suficientes: **sin nota**, no un cero ni una estimación. Se muestra «Repera está aprendiendo de ti» con los mínimos de **2/3 días comparables**, según el tipo de evaluación.
- En **Progreso → Entreno**, la tarjeta presenta primero **Actividad** (última terminada entre Repera y Salud/Health Connect: título, duración y FC/kcal reales cuando están disponibles), aunque carezca de nota; después la columna de esfuerzo de la **última sesión con nota verificada**: **Rendimiento** (`±N %` vs mediana personal) y **Referencias** (días previos). El anillo es la **media** de notas del periodo; la barra de **confianza** es del último entreno evaluable. La gráfica inferior muestra hasta **7 sesiones con nota** en eje **0–10** (no duración en minutos). Sin textos explicativos bajo esas métricas.
- **Zonas cardíacas (iOS):** si Apple no expone `zoneGroup` del HKWorkout, se estiman tiempos por zona a partir de las **muestras reales de FC** del intervalo del entreno (umbrales 60/70/80/90 % FCmáx, misma regla que Comenzar). Sin muestras de pulso no se inventan zonas.
- **Recuperación → Evolución:** solo días con nota de preparación; la línea une esos puntos de forma continua (sin cortar el trazo por huecos de calendario).
- **Sueño:** eje Y con horas (`N h`) y eje X con fechas; al seleccionar una noche se muestra `horas · fecha`.
- **FC / kcal / peso:** la selección muestra el valor del día (FC = mín · media · máx).
- La etiqueta histórica «En construcción» no es un nivel de confianza: si la sesión ya tiene nota verificada, se visualiza **Media** (dos a cuatro referencias exactas, sin umbral de Alta); **Alta** exige al menos cinco referencias exactas y cobertura ≥80%. Los valores guardados se recalculan con la revisión de fórmula; ambas interfaces tratan el legado de forma coherente. En el detalle post-entreno, los KPI **Evolución personal, Rendimiento y Cobertura** aparecen a la izquierda del anillo global. **Rendimiento** es un nombre transversal para resultados de fuerza, WOD o actividad deportiva comparable, no una nota de WOD impuesta a otras sesiones. La confianza se presenta con cuatro niveles (*Aprendiendo, Baja, Media, Alta*), destacando el nivel real. No hay control «Ver cómo se calcula» ni nota ilustrativa. Un temporizador sin rendimiento comparable **no recibe puntuación inventada**.
- La gráfica agrupa por fecha los entrenamientos puntuados (media redondeada si hay varios) y separa tramos sin valores. No interpola días sin nota ni los rellena con 0.

La puntuación deportiva no constituye una recomendación médica ni mide el estado de salud o la calidad técnica del entrenamiento.

## Preparación para entrenar

La tarjeta muestra cuatro factores independientes (**sueño, entrenamiento medido en minutos, VFC/pulso en reposo y cardio**), aun sin sueño. Las muestras históricas se etiquetan con fecha; lo no medido se representa «—», nunca 0.

- **Nota completa:** requiere sueño observado y carga de actividad realmente finalizada en los últimos **7 días**. Se calcula con sueño relativo al objetivo, fatiga muscular y de minutos recientes (48–96 horas), más penalizaciones conservadoras de constantes calibradas.
- **Estimación parcial sin sueño:** requiere carga medida reciente, una lectura matinal válida de **VFC, pulso en reposo o respiración** y al menos **7 días naturales distintos anteriores de esa misma señal dentro de 28 días**. No se mezclan días de señales diferentes. El resultado queda limitado a **7/10** y aparece como «Estimación parcial · sin sueño registrado».
- Sin evidencia suficiente el anillo muestra «— / 10» y el mensaje **«Repera está aprendiendo de ti»**, con requisito de al menos un entrenamiento finalizado en 7 días y/o el progreso de **N/7 días de constantes** cuando no hay sueño. La presencia de FC diaria sin referencia calibrada no habilita una nota de preparación.
- La evolución representa días con nota completa **o parcial** y separa los intervalos sin observaciones. Los valores parciales se mantienen diferenciados en la tarjeta actual; la tendencia no presupone sueño ni genera puntos por días vacíos.

Este índice es orientativo: no diagnostica ni sustituye la evaluación de sensaciones, descanso, fatiga o salud.

## Constantes fisiológicas y pulso en reposo

- **Tendencias:** se consulta la mediana de **todas** las muestras válidas de cada día en Apple Salud / Health Connect. No se limita el histórico a las 07:00. Para visualizar una tendencia se necesitan **2 días medidos**; antes, la interfaz indica «Repera está aprendiendo de ti» y el progreso de días disponibles.
- **Puntuación de preparación:** utiliza **solo las lecturas hasta las 07:00** (para no mezclar valores posteriores al entrenamiento). Para calibrar su referencia necesita **7 días anteriores de la misma señal**; por ello puede haber barra en el histórico pero no factor fisiológico calibrado para la preparación.
- Si Salud no registra una lectura, no concede permisos o no está sincronizada, ese día queda sin dato, nunca en cero. Las curvas se cortan al detectar días intermedios ausentes.
- VFC en Apple Salud utiliza **SDNN** y Health Connect puede proporcionar **RMSSD**: no se mezclan valores como si fueran la misma medida. Las lecturas fisiológicas siguen siendo locales y no se exportan a Supabase ni al historial de entrenamientos.
- La opción de datos ficticios para revisión visual de gráficas Android está desactivada en su flujo normal; las muestras de ejemplo identificadas como tales se reservan para vistas de demostración explícitas, no para sustituir ausencias reales.

## Peso corporal

Fuente: pesajes introducidos en Repera (`bodyWeights`). Ventana máxima de visualización: **últimos ~365 días**. Si el rango actual no contiene pesajes, se muestra el historial real de ese año hasta hoy, con fecha visible del último registro. Un único registro aparece como punto sin línea artificial; los intervalos sin registros no se rellenan. En periodos con pesajes se conserva el filtrado habitual. El eje temporal se adapta a los puntos que se muestran.

## Editor

Fecha `dd/MM/yyyy` en línea única, con prioridad sobre Hora y duración conservada. Revisar con Dynamic Type y iPhone compacto.

## Verificación pendiente de entorno

Validar en simuladores y dispositivos físicos (iOS / Android), confirmar que la vinculación `routineId` de clases profesionales se conserva en todas las rutas de ejecución y comprobar CI de ambas plataformas antes de publicar nuevas builds en tiendas. Las confirmaciones de GitHub no equivalen a una compilación local.

## Lugar histórico de entrenamientos

Los lugares automáticos solo se derivan de un pin o punto GPS registrado **durante** la sesión (teléfono o reloj). Consultar Historial, editar o recibir una finalización tardía **nunca** usa la ubicación actual del móvil para rellenar una sesión anterior. Sin evidencia GPS se muestra lugar sin registrar, no una posición aproximada inventada. Una elección manual explícita conserva prioridad sobre sugerencias automáticas.
