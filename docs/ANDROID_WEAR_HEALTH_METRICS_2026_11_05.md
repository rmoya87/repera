# Android y Wear OS — reconciliación de entrenamientos y Health Connect

**Fecha:** 2026-11-05 (fallback clase sin plan → gimnasio/HIIT; matriz de dueños)  
**Motivo:** registro de caminatas con GPS pero energía/ritmo ausentes y divergencia móvil–reloj.

## Propietarios y origen de cada medición

Los tres tipos (plan programado, Comenzar, clase/Center) entran en el mismo
modelo; la diferencia respecto a Apple es el dueño cuando el **teléfono**
inicia con Wear alcanzable (Android conserva GPS en el móvil; Apple hace
handoff `HKWorkout` al Watch).

| Tipo | Desde Wear | Desde Android (Wear alcanzable) |
|---|---|---|
| Entreno programado (plan del día / rutina) | Wear dueño (`ExerciseClient` + UUID) | Teléfono dueño de la sesión; Wear companion FC/kcal |
| Comenzar (deporte libre) | Wear dueño + `watchOwned` | Teléfono dueño GPS/tiempos; Wear companion |
| Clase (Center / reserva con plan) | Si llega como plan de hoy → igual que programado | Play con plan → preview/sesión móvil; Wear espeja |
| Clase / cita **sin plan** | `FallbackActivityKind` → Comenzar fuerza o HIIT en Wear | Play → Comenzar fuerza o HIIT (`startFallbackGymOrHIIT`) |

- Actividad iniciada **en Wear OS**: Repera Watch registra deporte y sensores con
  Health Services `ExerciseClient`, GPS y pausas en el reloj. El teléfono recibe
  la sesión final mediante UUID y la guarda en el historial local; no inicia
  otra grabación para la misma ejecución. Sin plan descargable, Wear arranca
  Comenzar con `FallbackActivityKind` (gimnasio / HIIT según título), nunca idle
  ni tipo HC «other» ambiguo.
- Actividad iniciada **en Android**: el teléfono registra GPS/recorrido/tiempos
  con `LiveActivityRuntime`. Wear OS usa `ExerciseClient` como fuente de
  pulso y energía; no utiliza GPS en paralelo en este modo. Si el reloj no
  soporta ese registro puede intentar `MeasureClient`, que proporciona
  pulso pero **no calorías**. El móvil muestra pulsaciones recientes con
  caducidad a los 20 s; conserva promedios y energía total realmente recibidos
  hasta guardar la actividad.
- Entrenamiento programado o clase: Wear OS identifica WOD/HIIT y tipo
  específico cuando existe. La ejecución se envía al móvil con UUID
  estable; los datos terminales de sensores se conservan en el outbox de
  finalización, para repetir en caso de desconexión. `sessionHealthSportId`
  y `HealthConnectWriter.exerciseTypeFor` resuelven título → fuerza/HIIT
  (`FallbackActivityKind`) si no hay deporte ni WOD.

## Semántica de energía (importante)

`Health Services DataType.CALORIES_TOTAL` registra energía **total**,
incluidas calorías basales. Nunca se copia a `appleActiveEnergyKcal`,
`ActiveCaloriesBurnedRecord` ni se etiqueta «activas». Se guarda como
`wearTotalEnergyKcal`, y se presenta expresamente «kcal totales».
`appleActiveEnergyKcal` sigue siendo exclusivamente una medición activa
válida procedente de Health Connect.

La FC media en Wear se calcula usando muestras auténticas (en lugar de
guardar como media la última FC instantánea), sin inventar una serie
de pulsaciones ni sobrescribir datos de otra sesión.

## Escritura y lectura en Health Connect

- Cada `ExerciseSessionRecord` usa identidad estable del entrenamiento.
  `HealthConnectWriter` adopta sesiones externas inequívocas y no escribe
  otra si hay ambigüedad o si el mismo UUID ya está guardado.
- El mapa `ExerciseRoute` no aporta una distancia numérica. Con permiso,
  una actividad de exterior y metros GPS verificados, se puede escribir
  `DistanceRecord`, **solo si** la lectura confirma que ningún proveedor
  ha escrito ya distancia en ese intervalo. Sin permiso o si la lectura
  falla, se mantiene el recorrido en Repera y no se inventan kilómetros.
- Si Wear aporta kcal totales medidas, la app puede escribir
  `TotalCaloriesBurnedRecord` con ID estable, permiso de lectura/escritura
  y ausencia verificable de otros registros para ese intervalo. Nunca
  exporta como kcal activas ni escribe una cifra derivada de MET o pulso.
- La sincronización Android mantiene `wearTotalEnergyKcal` y
  `wearAverageHeartRateBpm` en el historial local, Home y detalle,
  aunque Health Connect todavía no tenga disponibles los datos.
- Los permisos son opcionales y se solicitan a petición del usuario.
  La falta de permisos no debe impedir conservar la actividad local.

## Matriz de comprobación de regresiones

1. Caminar 10 min desde Wear conectado / desconectado. Comprobar
   `WALKING`, ruta, km, ritmo, energía total del reloj y FC media en móvil,
   una sola actividad y reenvíos idempotentes.
2. Iniciar caminata desde Android con Wear conectado. Confirmar que GPS
   procede del móvil y pulso/kcal de Wear; pausar/reanudar, bloquear
   ambas pantallas, guardar desde Android.
3. Repetir carrera, bici, senderismo, fuerza, CrossFit/HYROX,
   WOD programado y clase/bono del gimnasio.
4. Retirar permisos de Health Connect (Exercise, Route, Distance, Total
   Calories) y repetir. No generar ceros fisiológicos, ni duplicar
   datos, ni perder el workout local.
5. Forzar desconexión y dos ACK/reintentos de misma sesión. Verificar
   que solo cambia el UUID correspondiente y que la energía total
   nunca se suma dos veces.
6. Revisar `tests/test_android_wear_health_metrics_contract.py` y
   `WearMeasuredEnergyTest.kt`; compilar `:domain:test`,
   `:mobile:assembleDebug`, `:wear:assembleDebug` y ejecutar
   pruebas en Pixel/Pixel Watch o Samsung/Galaxy Watch reales.

**Límites:** Health Connect no garantiza que un reloj publiquen
todas las métricas; el registro depende del hardware, Health Services,
versión de Play Services y permisos efectivos. La escritura de un
`TotalCaloriesBurnedRecord` puede estar bloqueada si existe ya la
medición de otro proveedor. El icono mostrado en apps de terceros
depende de ese proveedor y del APK firmado. Se requiere prueba física,
especialmente para pausas, energía total, kilómetro y recuento de sesiones.

**No alterar automáticamente históricos:** una sesión anterior sin
muestras no se reconstruye por estimación.
