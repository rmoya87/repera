# Progreso y preparación: fuentes verificadas (02/11/2026)

## Qué se considera actividad terminada

- Entrenamientos registrados y finalizados en Repera.
- Sesiones `Comenzar`/Apple Watch/Wear OS terminadas y guardadas.
- Actividades de Salud externas (evitando coincidencia con sesiones Repera).
- Reservas de clases o citas con estado `attended`, incluida la asistencia histórica. `booked`, `waitlist`, `cancelled` y `no_show` no suman.
- La asistencia se cuenta una sola vez; si existe una sesión realizada vinculada, o una medición de Salud/Watch con solapamiento suficiente, esta prevalece.

**Regla de evidencia:** asistencia no equivale a duración efectiva, calorías, frecuencia cardíaca, intensidad, series, tonelaje o esfuerzo. La asistencia sin mediciones aporta frecuencia de sesiones, días y rachas, no métricas fisiológicas ficticias. Una clase con un entreno guardado aporta las métricas del entrenamiento, sin duplicarlas.

La información de clases se carga por usuario autenticado desde `BusinessDataStore`, respetando los permisos y los vínculos existentes en Supabase.

## Puntuación de entrenamiento

Solo se muestran valoraciones verificadas `scoreBasis == personalHistory`:

- Fuerza y WOD: motor de comparación personal anterior.
- Salidas GPS desde Comenzar: distancia real (>=500 m), tiempo activo real, y al menos dos días anteriores del mismo deporte y distancia comparable (±20 %, en los 180 días anteriores). La mediana personal sirve como referencia.
- Sin historial o mediciones de rendimiento suficientes: **sin nota**, no un cero ni una puntuación estimada.
- El gráfico agrupa por fecha los entrenamientos puntuados.

La puntuación deportiva no constituye una recomendación médica ni mide el estado de salud.

## Preparación para entrenar

La tarjeta muestra cuatro factores (sueño, carga, VFC/FC en reposo, cardio) incluso si falta sueño en la última noche. Las lecturas históricas se etiquetan con fecha. Sin evidencia necesaria para la fórmula actual, el anillo indica «— / 10» sin valoración global inventada. La carga independiente puede mostrar minutos medidos recientes, distinguiéndolos de una valoración de fatiga validada.

## Peso corporal

Si el rango actual no contiene pesajes, se muestra el historial real hasta hoy, con fecha visible del último registro. Un único registro aparece como punto sin línea artificial; los intervalos sin registros no se rellenan. En periodos con pesajes se conserva el filtrado habitual. El eje temporal se adapta a los puntos que se muestran.

## Editor

Fecha `dd/MM/yyyy` en línea única, con prioridad sobre Hora y duración conservada. Revisar con Dynamic Type y iPhone compacto.

## Verificación pendiente de entorno

Validar en simuladores y dispositivos físicos (iOS / Android), confirmar que la vinculación `routineId` de clases profesionales se conserva en todas las rutas de ejecución y comprobar CI de ambas plataformas antes de publicar nuevas builds en tiendas. Las confirmaciones de GitHub no equivalen a una compilación local.
