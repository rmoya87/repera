# En vivo (iOS 27)

## Experiencia

La tercera pestaña es **En vivo**. Se puede seleccionar deporte y grabar una actividad libre sin crear una plantilla. Los deportes con GPS muestran mapa y métricas, mientras que los demás utilizan una pantalla simplificada con cronómetro. La grabación permite pausar, reanudar, finalizar, añadir un título y notas, y guardar.

El guardado llama a `ReperaStore.saveWorkout(_ :)`, creando un `WorkoutSession` con `phase = .finished`, `startedAt`, `finishedAt`, `liveSportID`, `activeDurationSeconds`, `recordedDistanceMeters` y `routePoints`. Se persiste con los mismos mecanismos local/iCloud que los entrenos habituales, incrementando `workoutsEpoch`. **Inicio agrupa los registros de En vivo por el día local de inicio** (no por el de finalización); al guardarlos vuelve a Inicio seleccionando esa fecha. Las tarjetas permiten consultar el detalle, el mapa y la distancia. Las actividades también se encuentran en Historial y Progreso.

## Ubicación y recorridos

`LiveActivityRecorder` es un `@MainActor @Observable` singleton que retiene la sesión independientemente de la vista. Solo se solicitan permisos de ubicación al iniciar un deporte con GPS. Usa `CLLocationManager` con soporte de actualización de ubicación en segundo plano mientras existe una sesión grabándose; en iOS se declara `UIBackgroundModes: location`.

Se filtran posiciones con poca precisión, fechas obsoletas y saltos implausibles. **La distancia registrada procede de posiciones aceptadas, nunca de la longitud de un GPX**. La grabación pausa la suma de distancia y tiempo activo durante descansos. Se guarda periódicamente una instantánea local para recuperar un registro tras una interrupción; al restaurar, la sesión queda **pausada** para no inventar tiempo.

La biblioteca de rutas se mantiene local mediante `LiveRoutesStore`. Se importan archivos GPX con `trkpt` o `rtept`, se dibuja el recorrido previsto sobre MapKit y se superpone la ruta real. Si el usuario está lejos de los puntos de la ruta se muestra un aviso básico; **no existe todavía navegación giro a giro, recalculado de trayectos ni mapas offline garantizados**. El modo de baja cobertura sigue registrando coordenadas si el sistema dispone de GPS y permiso, aunque los mapas base puedan requerir red.

## Apple Salud

`ReperaStore.syncWorkoutToHealth` envía el tipo de deporte y la ubicación indoor/outdoor apropiados a `HealthKitStore.finishWorkout`. Se conserva el emparejamiento por `ReperaSessionID` y la conciliación con el Watch para evitar duplicados. Las calorías y la frecuencia cardíaca **solo se presentan si Salud aporta datos auténticos**; el iPhone no genera estimaciones de sensores. Las pausas se conservan como duración activa de Repera, independientemente de la duración de pared que pueda tener un HKWorkout.

El recorrido registrado se guarda en el modelo de Repera y se visualiza en su detalle. **La exportación adicional del trazado como HKWorkoutRoute de Apple Salud queda pendiente**.

## Limitaciones y verificación en dispositivo

- Verificar en iPhone real permisos, GPS durante bloqueo de pantalla, retorno desde otras apps, pérdida de señal, avión/sin red, pausa/reanudación y desconexión del Watch.
- Confirmar que Apple Salud no duplica sesiones, y que una carrera se escribe como `running` y una bicicleta como `cycling`.
- Probar un GPX corto, uno largo, uno vacío o malformado y uno con coordenadas fuera de rango.
- Validar sesión empezada antes de medianoche y finalizada después: debe verse en Inicio en la fecha de inicio.
- Las clases y la edición avanzada de rutinas siguen entrando por Inicio/Diario. El centro profesional sigue accesible para perfiles vinculados.
