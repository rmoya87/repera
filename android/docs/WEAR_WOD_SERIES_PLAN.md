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

## Trabajo de implementacion (lote futuro, sin prisa)
1. WatchSessionSummary: exponer capture (perMovementSets) y blockId del ejercicio actual.
2. canLogOnWatch: true para WOD con capture==perMovementSets y modo soportado.
3. queueSet: permitir wodFormatLabel != null solo si capture==perMovementSets; cero reps
   mantiene la regla actual (saltar/avanzar, nunca registrar).
4. Payload /repera/log-set: añadir intervalIndex (derivado del reloj del bloque en el
   reloj, como Apple: elapsed%intervalo) y flag wodMovement.
5. logWearSet: si blockKind=="wod" && capture==perMovementSets -> enrutar a
   recordWodMovement (mapear exerciseIndex del reloj al currentIndex/movimiento del
   bloque en el telefono) en vez de rechazar; mantener dedup setId y ack saved/rejected.
6. Tests: phone (logWearSet WOD enruta a recordWodMovement, dedup, rechazo formato
   global), watch-side logic donde sea testeable en JVM.
7. Validacion visual/runtime Wear ABIERTA (sin emulador KVM).

## Riesgos / preguntas abiertas
- recordWodMovement opera sobre currentIndex del telefono: confirmar como se mapea un
  movimiento no actual del bloque (movementIndex vs indice global de exercises).
- Intervalo derivado en reloj vs telefono: usar el reloj del bloque (WodTimerStore) o
  el timestamp; Apple usa su blockElapsed local.
- El reloj Wear no tiene reloj de bloque WOD propio (WearWodTimerScope existe - revisar alcance).
