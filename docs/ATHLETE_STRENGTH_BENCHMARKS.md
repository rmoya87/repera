# Comparativas deportivas y progresión adaptativa (Repera atleta)

Última actualización: 2026-11-09 (Élite OPL nov-2026 + Amateur 14 lifts FV).

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

Bundle + Supabase (**1132** distribuciones: **914** Élite + **218** Amateur).
`strengthReferenceFrame` (default **Amateur**) filtra por `source` y nunca mezcla
marcos. Clientes sincronizan vía `StrengthBenchmarkRemoteStore`.

### Élite — OpenPowerlifting (CC0)

- Rebuild offline desde CSV `openpowerlifting-latest` (dump 2026-11-07,
  revisión `openpowerlifting-2026-11-09-…`) con script
  `scripts/import_liftgauge_opl_seed.py --from-csv DOWNLOAD`.
- Alternativa: cubo LiftGauge CC0 (`--liftgauge`).
- Sentadilla / press banca / peso muerto *raw*, clases IPF, edad exacta +
  «todas las edades»; ≥100 meets; sin extrapolación.
- `sampleCount` = observaciones de meet (no personas únicas).

### Amateur — seed gym (SymmetricStrength / FitnessVolt CC BY)

- **218** cohortes: 14 lifts × sexo × clases de peso (≥100), edad 14–100, raw.
- Lifts: SBD + front squat, sumo, power clean, incline/OHP/push/snatch press,
  dip, chin-up, pull-up, Pendlay row.
- `sourceRevision` = `fitnessvolt-gym-seed-2026-11-09-all-lifts`.
- Atribución CC BY en web; sin API FV en runtime.

### UI Rendimiento

- En **Evolución Pro**, el bloque **Rendimiento** va **después** de la gráfica
  de registros. Un 1RM anotado tiene prioridad; si no, **e1RM estimado**
  (accesibilidad, no pie bajo el eje). Nunca se llama marca oficial.
- Una sola campana ilustrativa + `Pxx` del marco elegido en Ajustes →
  Entrenamiento → **Nivel** (Amateur / Élite).
- Sin cobertura: silueta apagada + mensaje, sin inventar percentil.
- **Género**, **Nivel** y **año de nacimiento** solo en Ajustes → Entrenamiento
  (snapshot sincronizado); el peso reciente se reutiliza de Progreso.

### Supabase

Esquema + seed **aplicados** en Repera: **914** OPL + **218** SS. RPCs
bootstrap/delta, aportes autenticados e inbox; aggregate `service_role`.

**Fuente de verdad:** Supabase (`strength_benchmark_bootstrap` / delta).
iOS/Android sincronizan a caché local al iniciar sesión / foreground; el JSON
empaquetado solo arranca offline la primera vez. Sin APIs a FitnessVolt ni OPL
en runtime.

**Opt-in Amateur:** Ajustes → «Mejorar Amateur (anónimo)» (default on). Al
guardar un **1RM probado** de sentadilla/banca/peso muerto (con género, edad y
peso), la app llama `submit_strength_benchmark_contribution` (bandas anónimas,
sin user id en el inbox, rate limit 30/día). `service_role` puede ejecutar
`strength_benchmark_aggregate_contributions` (≥100 muestras/cohorte) para
publicar cuantiles `SymmetricStrength` con revisión `repera-optin-YYYY-MM-DD`.
Élite (OPL) no se mezcla. Sin lift o sin cohorte → bloque oculto/vacío, nunca
Pxx inventado.

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
