# Plan: captura de series WOD por movimiento en Wear (44713457 GAP)

Estado: ANALISIS COMPLETO contra corte 0a640da8; implementacion NO iniciada (27 oct 15:57 CET).

## Comportamiento Apple (watchOS, corte vigente)
- wodUsesSeries = wodFormat.resultCapture == .perMovementSets (EMOM/Tabata/circuit/deathBy con series).
- confirmIntervalSet(): el atleta confirma cada intervalo con reps>0; el reloj NUNCA fabrica
  una serie ni asume repeticiones. Tras confirmar: reset draft, calcula restRemaining
  (Tabata: blockRestSeconds; resto: intervalo - elapsed%intervalo), haptic success.
- Cero reps: salta descanso y avanza de movimiento sin registrar nada (nunca serie falsa).
- reviewBlock al terminar: la revision vive en el telefono (Android ya equivalente).
- nextWODMovement(): navega entre movimientos del mismo bloque en el reloj.

## Estado Android actual (verificado en fuente)
- Watch gate 1: WearMainActivity WatchSessionSummary.canLogOnWatch = modo soportado
  AND blockKind != "wod" -> excluye TODO WOD.
- Watch gate 2: queueSet() retorna si session.wodFormatLabel != null (aunque canLogOnWatch).
- Watch ya tiene: restRemaining/skipRest, zero-path (cero nunca registra; salta/avanza/termina),
  WearPendingSetStore con setId unico, repsInput, allowsWeight.
- Phone ingestion: /repera/log-set -> WorkoutRepository.logWearSet con dedup por setId
  (busca en activeSession+history; adoptWearSession si hace falta).
- Phone gate: logWearSet hace check(blockKind != "wod") -> rechaza series WOD del reloj.
- Phone ya tiene recordWodMovement(movementIndex, intervalIndex, quantity, weightKg):
  valida formato PER_MOVEMENT_SETS, limites de intervalo contra routineBlocks. Opera
  sobre el ejercicio currentIndex del telefono.

## Trabajo de implementacion
HECHO unidad 1 (telefono, 466a45e1): logWearSet enruta WOD perMovementSets a
recordWodMovement (movementIndex derivado del exerciseIndex global dentro del
bloque; currentIndex del telefono puede ser otro movimiento del MISMO bloque);
setId del reloj = LoggedSet.id persistido (dedup por reintento); intervalIndex
requerido para WOD (payload /repera/log-set + validacion 0..100000 en MainActivity);
recordWodMovement acepta setId. Tests WearWodSetRoutingTest 6/6 REAL.
HECHO unidad 2 (reloj): WatchSessionSummary.wodUsesSeries; canLogOnWatch admite
WOD perMovementSets con modo soportado; queueSet deriva intervalIndex del reloj
del bloque publicado (/repera/wod-timer: spec completa + elapsed; funcion pura
wearWodIntervalIndex -> WodClock.activeIntervalIndex); SIN reloj activo no
registra y avisa ("Inicia el reloj del bloque...") - diferencia documentada vs
Apple (que registra sin intervalo); cero reps mantiene la regla (salta/avanza,
NUNCA registra); WearPendingSetStore lleva intervalIndex en el comando (fluye
verbatim al telefono). Tests WearWodSeriesTest 6/6 REAL (infra de test unitario
nueva en el modulo wear: junit+robolectric).
HECHO unidad 3 (descanso): wearWodRestAfterConfirmedSet - Tabata: blockRest
(10 por defecto, como Apple); resto formatos: lo que queda del intervalo (0 en
el borde); null sin reloj del bloque. queueSet lo usa para WOD en vez de
WatchStrengthRest. Tests +2 (8/8 reloj REAL).
HECHO UI Wear (2026-10-28): `WearHomeContent` muestra «Registrar serie» /
Confirmar en WOD `wodUsesSeries` cuando hay reloj de bloque matching; sin
reloj matching avisa «Inicia el reloj del bloque…».

PENDIENTE:
- Validacion visual/runtime Wear ABIERTA (sin emulador KVM): UI "Registrar serie"
  en bloque WOD, estado sin reloj, ack saved/rejected en reloj real.
- Diferencia funcional MANTENIDA (decision padre 16:00): sin reloj del bloque
  activo el reloj no registra; no se inventa intervalIndex.
- Cobertura relajamiento currentIndex (padre 16:00): tests 10/10 telefono -
  otro bloque misma sesion, otra sesion, bloque desplazado tras fuerza
  (movementIndex no posicional), reintento mismo setId, cero rechazado.

## Riesgos / preguntas abiertas
- recordWodMovement opera sobre currentIndex del telefono: confirmar como se mapea un
  movimiento no actual del bloque (movementIndex vs indice global de exercises).
- Intervalo derivado en reloj vs telefono: usar el reloj del bloque (WodTimerStore) o
  el timestamp; Apple usa su blockElapsed local.
- El reloj Wear no tiene reloj de bloque WOD propio (WearWodTimerScope existe - revisar alcance).
