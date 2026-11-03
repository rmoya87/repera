# Progreso y preparación: fuentes verificadas (03/11/2026)

## Qué se considera actividad terminada

- Entrenamientos registrados y finalizados en Repera.
- Sesiones `Comenzar`/Apple Watch/Wear OS terminadas y guardadas.
- Actividades de Salud externas (evitando coincidencia con sesiones Repera).
- Reservas de clases o citas con estado `attended`, incluida la asistencia histórica. `booked`, `waitlist`, `cancelled` y `no_show` no suman.
- La asistencia se cuenta una sola vez; si existe una sesión realizada vinculada, o una medición de Salud/Watch con solapamiento suficiente, esta prevalece.

**Regla de evidencia:** asistencia no equivale a duración efectiva, calorías, frecuencia cardíaca, intensidad, series, tonelaje o esfuerzo. La asistencia sin mediciones aporta frecuencia de sesiones, días y rachas, no métricas fisiológicas ficticias. Una clase con un entreno guardado aporta las métricas del entrenamiento, sin duplicarlas.

La información de clases se carga por usuario autenticado desde `BusinessDataStore`, respetando los permisos y los vínculos existentes en Supabase.

## Organización de Progreso (iOS y Android, 03/11/2026)

- **Entreno:** tarjetas resumen Entrenos/Tiempo/Racha, **Entrenamiento** (anillo y evolución de puntuaciones verificadas), Equilibrio muscular, Movilidad, Progreso por ejercicio, Récords, Deportes e Historial. En pantallas Duo/tablet, puntuación y mapa muscular se muestran en dos columnas. La cuadrícula de KPI ocupa todo el ancho.
- **Actividad:** Días activos (heatmap de tiempo/volumen), **Frecuencia cardíaca** diaria (mínima, media y máxima), Calorías y Peso; son datos de movimiento y Salud generales, no notas de rendimiento deportivo. En pantallas grandes, calendario ancho y gráficas en cuadrícula adaptativa.
- **Recuperación:** **Recuperación** (estado actual), **Evolución** (tendencia), **Sueño** y **Constantes**, más Ciclo si existe información. Las dos primeras y las dos siguientes forman parejas en Duo.
- **Cardio de entrenamiento:** iOS consulta zonas y carga cardiovascular **del entrenamiento asociado** en Apple Salud dentro de Entreno; Actividad no las duplica. Android muestra, si existe, FC media y energía de sesión **medidas**; no inventa límites ni tiempos en zonas cuando Health Connect no aporta un desglose verificable. La opción de pruebas con zonas sintéticas no aparece en sesiones reales.
- **Gratis/Pro:** las vistas gratuitas conservan contenido real permitido y previsualizaciones explícitamente identificadas como «Ejemplo» para las funciones bloqueadas; no se mezclan muestras ficticias con registros reales.

## Entrenamiento (puntuación personal)

Solo se muestran valoraciones verificadas `scoreBasis == personalHistory`, calculadas sobre mediciones deportivas reales y comparaciones de rendimiento propio. No se suman puntos por la cantidad de series anotadas ni por datos fisiológicos.

- Fuerza y WOD: mediana de hasta cinco días personales comparables en los últimos 180 días; se exigen al menos **2 días anteriores** en el mismo ejercicio y contexto (o equivalencias conservadoras), y **≥60% de cobertura** de las unidades de rendimiento prescritas. Un estímulo WOD calibrado de otra sesión compatible exige **3 días anteriores**. La nota usa `clamp(round(7 + 11 × ln(actual/referencia)), 1, 10)` con pesos por nivel de evidencia.
- Salidas GPS desde Comenzar: distancia real de al menos 500 m, tiempo activo y **2 días anteriores** del mismo deporte y distancia comparable (±20%, dentro de los 180 días previos). La mediana personal sirve de referencia.
- Sin referencias suficientes: **sin nota**, no un cero ni una estimación. Se muestra «Repera está aprendiendo de ti» con los mínimos de **2/3 días comparables**, según el tipo de evaluación.
- En **Progreso → Entreno**, la tarjeta **Entrenamiento** presenta **Última nota, Mejor nota y Días evaluados a la izquierda**, la puntuación media del periodo en un **anillo a la derecha** y la **confianza del último entrenamiento evaluable en una barra segmentada debajo**. No existe un cálculo de confianza media del periodo.
- En el detalle post-entreno, los KPI **Evolución personal, Rendimiento y Cobertura** aparecen a la izquierda del anillo global. **Rendimiento** es un nombre transversal para resultados de fuerza, WOD o actividad deportiva comparable, no una nota de WOD impuesta a otras sesiones. La confianza se presenta con cuatro niveles (*Aprendiendo, Baja, Media, Alta*), destacando el nivel real. No hay control «Ver cómo se calcula» ni nota ilustrativa. Un temporizador sin rendimiento comparable **no recibe puntuación inventada**.
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

Si el rango actual no contiene pesajes, se muestra el historial real hasta hoy, con fecha visible del último registro. Un único registro aparece como punto sin línea artificial; los intervalos sin registros no se rellenan. En periodos con pesajes se conserva el filtrado habitual. El eje temporal se adapta a los puntos que se muestran.

## Editor

Fecha `dd/MM/yyyy` en línea única, con prioridad sobre Hora y duración conservada. Revisar con Dynamic Type y iPhone compacto.

## Verificación pendiente de entorno

Validar en simuladores y dispositivos físicos (iOS / Android), confirmar que la vinculación `routineId` de clases profesionales se conserva en todas las rutas de ejecución y comprobar CI de ambas plataformas antes de publicar nuevas builds en tiendas. Las confirmaciones de GitHub no equivalen a una compilación local.
