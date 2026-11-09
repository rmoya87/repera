# Comparativas deportivas y progresión adaptativa (Repera atleta)

Última actualización: 2026-11-09 (marcos Amateur/Élite + semilla gym CC BY).

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

## Dataset de referencia (Amateur / Élite)

Atribución legal pública (CC BY FitnessVolt + OPL): `/privacy#strength-reference`
y `/terms` en la web estática (ES/EN). Importación **única** del seed Amateur
(`scripts/import_fitnessvolt_gym_seed.py`); **runtime sin llamadas a FitnessVolt**.

La app incorpora el mismo archivo `strength_benchmarks.json` en Apple y
Android (**813** distribuciones: **765** Élite + **48** Amateur). El ajuste
`strengthReferenceFrame` (default **Amateur**) filtra por `source` y nunca mezcla
marcos en la misma campana/`Pxx`.

### Élite — OpenPowerlifting (CC0)

- Origen primario **OpenPowerlifting**, transformación reutilizada del proyecto
  **LiftGauge** (datos CC0).
- Fuente: https://openpowerlifting.org/data
- Transformación/metodología: https://github.com/arvidfcjarfalla-prog/liftgauge-strength-data
- ID publicado: `openpowerlifting-2026-05-10-e97d116bb707065e-9dc7b0683085`.
- Ventana de resultados del cubo de percentiles: 2025-05-10 a 2026-05-10.
- Sentadilla, press banca y peso muerto *raw*, sexo y clases de peso.
- Se rechazan cohortes de menos de 100 **resultados de competición**, datos
  erróneos y extrapolación. Prefiere edad exacta con muestra suficiente; si no,
  «todas las edades».
- `sampleCount` cuenta observaciones de meet, **no personas únicas**. No es
  muestra de la población general.

### Amateur — seed gym (SymmetricStrength / FitnessVolt CC BY)

- 48 cohortes (3 lifts × 2 sexos × 8 clases de peso), edad 14–100, `equipment` raw.
- `source` = `SymmetricStrength`, `sourceRevision` = `fitnessvolt-gym-seed-2026-11-09`.
- Cuantiles de autoinforme de gimnasio; no certifica marcas oficiales.
- Atribución CC BY en web; no hay API ni descarga en runtime.

### UI Rendimiento

- En **Evolución Pro**, el bloque **Rendimiento** va **después** de la gráfica
  de registros. Un 1RM anotado tiene prioridad; si no, **e1RM estimado**
  (accesibilidad, no pie bajo el eje). Nunca se llama marca oficial.
- Una sola campana ilustrativa + `Pxx` del marco elegido en Ajustes →
  Entrenamiento → **Nivel** (Amateur / Élite).
- Sin cobertura: silueta apagada + mensaje, sin inventar percentil.
- **Género**, **Nivel** y **año de nacimiento** solo en Ajustes → Entrenamiento
  (snapshot sincronizado); el peso reciente se reutiliza de Progreso.

### Supabase (pendiente de aplicar)

Migración local `supabase/migrations/20261109160000_strength_benchmark_frames.sql`:
tablas de distribuciones + eventos, RPCs `strength_benchmark_bootstrap` /
`strength_benchmark_delta`, inbox de contribuciones (solo `service_role`).
**No aplicada en remoto** hasta confirmación humana. Mientras tanto el JSON
empaquetado es la fuente offline.

El script `scripts/build_strength_benchmarks.py` permite otros agregados OPL
desde CSV local; su deduplicación por nombre es aproximada y no es
intercambiable sin revalidar producto.

## Pruebas y distribución

Hay tests de dominio Swift, contratos Python (frame + assets) y prueba de
importación con fixtures. **La existencia de tests no equivale a ejecutarlos.**
No se han efectuado compilaciones nativas ni pruebas físicas certificadas
en esta sesión. Ejecutar `swift test`, XcodeGen/Gradle, emuladores y hardware
antes de publicar.

Los cambios en el repositorio **no** despliegan Supabase, no actualizan
App Store/TestFlight/Play y no ejecutan compras reales.
