# Comparativas deportivas y progresión adaptativa (Repera atleta)

Última actualización: 2026-11-09.

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
3. **Recuperación C — Pro**: tarjeta de minutos reales de actividad de las
   últimas dos ventanas de siete días en Recuperación. Reutiliza el hub actual
   en iOS y Android; elimina coincidencias conocidas con Apple Salud y Health
   Connect. No se presenta como carga fisiológica, sobreentrenamiento ni
   recomendación clínica. El resto de métricas de recuperación previas
   conserva sus controles comerciales.
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
- Se compara la marca 1RM anotada por el usuario en Repera con resultados de
  competición solo de modo *orientativo*. No es un 1RM certificado en torneo
  ni un percentil de toda la población. **Nunca** usar e1RM calculado para
  presentarlo como marca oficialmente medida de competición.

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
