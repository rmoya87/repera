# Comparativas deportivas y progresión adaptativa (Repera atleta)

Última actualización: 2026-11-09 (bloque Rendimiento tras gráfica de Evolución).

## Alcance
Solo la aplicación de deportistas, con vistas nativas en iOS/iPadOS y Android. Se conserva la
arquitectura de watchOS y Wear OS (no se crean pantallas nuevas en los relojes). **Repera Business
fuera de alcance.** E (informe mensual) y F (compartir resultados) no forman parte de este trabajo.

## Implementado en la rama de integración

1. **Progresión A**: política opcional `adaptive` (Swift y Kotlin) sobre los
   `ProgressionEngine` existentes, ya sujetos al acceso Pro. Emite recomendaciones
   conservadoras basadas en al menos dos sesiones completadas, RIR realmente
   registrado, cambios de e1RM, separación temporal y fallos reiterados. No
   modifica entrenamiento ni escribe series hasta que el flujo ya existente
   de iniciar una rutina aplica la política. Un aumento está limitado por el
   incremento configurado y por el 5 % del peso. Nunca deducir RIR ausente.
   La recuperación fisiológica no se utiliza todavía automáticamente como
   entrada al engine; `AdaptiveLoadGuard` acepta ese dato para una integración
   posterior cuando se disponga de evidencia fiable y permisos.
2. **WOD B**: comparación de intentos con prescripción completa idéntica,
   formato compatible, escala RX o modificaciones registradas equivalentes,
   y resultado efectivo. AMRAP calcula rondas × reps/ronda + reps adicionales;
   For Time compara segundos solamente cuando no se alcanza el cap.
   En iOS la comparación se muestra en «Esta sesión», y en Android se deriva
   del archivo de entrenamiento y se muestra en la ficha del ejercicio; ambas
   vistas restringidas a Pro. Los WOD históricos sin RX/escalado explícito
   no se comparan, sin inventar su modalidad. Los editores permiten registrar
   RX/escala sin alterar el score original.
3. **Recuperación C — Pro**: gráfica de línea de **14 puntos diarios** de
   minutos de entrenamiento registrados, dentro del hub de Recuperación.
   Muestra dos resúmenes mínimos de siete días y elimina coincidencias
   conocidas con Salud/Health Connect. No es carga fisiológica, ni diagnóstico.
4. **Récords D**: mejores cargas realmente registradas en series de 3+, 5+
   y 10+ repeticiones, en Evolución de cada ejercicio (Pro). No incluye
   calentamientos, repeticiones prescritas pendientes, ni registros de
   calorías/metros. Los e1RM y topes probados existentes no se sustituyen.

## Dataset competitivo

La app incorpora el mismo archivo `strength_benchmarks.json` en Apple y
Android (765 distribuciones). Origen primario **OpenPowerlifting** (CC0),
con transformación reutilizada del proyecto **LiftGauge** (datos CC0).
- Fuente: https://openpowerlifting.org/data
- Transformación/metodología: https://github.com/arvidfcjarfalla-prog/liftgauge-strength-data
- ID publicado: `openpowerlifting-2026-05-10-e97d116bb707065e-9dc7b0683085`.
- Ventana de resultados del cubo de percentiles: 2025-05-10 a 2026-05-10.
- Incluye sentadilla, press banca y peso muerto con equipamiento *raw*, categoría
  de competición femenina/masculina y clases de peso. Se rechazan cohortes de
  menos de 100 **resultados de competición**, datos erróneos y extrapolación.
  Prefiere una edad exacta con muestra suficiente, en su defecto «todas las edades».
- Pueden aparecer varias competiciones de la misma persona: `sampleCount`
  cuenta observaciones, **no personas únicas**. No es una muestra de la población general.
- Se almacenan solo cuantiles agregados; no nombres ni otros registros individuales.
  Categoría, edad y peso del usuario se conservan localmente en preferencias.
- En **Evolución Pro**, el bloque se titula **Rendimiento** y va **después** de
  la gráfica de registros del ejercicio. Un 1RM anotado tiene prioridad; si no
  existe, se coloca el **e1RM estimado** de series reales (accesibilidad, no
  pie bajo el eje). Nunca se llama marca oficial. La curva ilustra mediana/IQR
  de cuantiles competitivos OpenPowerlifting (no solo élite profesional, ni
  población de gimnasio). Sin cobertura: silueta apagada + mensaje, sin inventar
  percentil.
- **Género** y **año de nacimiento** solo en Ajustes → Entrenamiento (snapshot
  sincronizado); el peso reciente se reutiliza de Progreso.

El script alternativo `scripts/build_strength_benchmarks.py` permite construir
otros agregados desde CSV local oficial, pero su método de deduplicación por
nombre es aproximado y sus cohortes no son intercambiables sin revisar la
metodología y volver a validar el producto.

## Pruebas y distribución

Hay tests de dominio Swift, Kotlin, prueba de importación con fixtures sintéticos
y contratos de RX/escala. **La existencia de tests no equivale a ejecutarlos.**
No se han efectuado compilaciones nativas ni pruebas físicas certificadas
en esta sesión. En la PR se observan workflows de GitHub Actions fallidos
con pasos vacíos/no disponibles: no demostrar que sea error de compilación,
pero tampoco afirmar compilación superada. Ejecutar `swift test`,
compilaciones XcodeGen y Gradle, emuladores y hardware antes de publicar.

Los cambios en el repositorio **no** despliegan Supabase, no actualizan
App Store/TestFlight/Play y no ejecutan compras reales.
