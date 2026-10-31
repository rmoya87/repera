# Apple Watch → iPhone: una sola confirmación de actividad

## Contrato
- **Entrenamiento grabado por Watch**: la finalización se envía con UUID estable y se guarda de forma idempotente en el historial del iPhone, sin abrir una segunda valoración/revisión. Si el UUID real de Salud llega más tarde, actualizar solo métricas y el vínculo HK del mismo registro.
- **Comenzar grabado por iPhone y controlado desde Watch**: pulsar **Finalizar** en el reloj solicita guardado en iPhone. La respuesta `ok=true` se emite **después** de escribir el registro local. El reloj espera el ACK antes de enseñar «¡Bien hecho!», no da éxito por el mero envío del mensaje.
- La grabación del iPhone conserva UUID, fecha, tiempo activo, ruta GPS, distancia, parciales, condiciones y, si existe, el HKWorkout externo. Intenta archivar la ruta GPX como la acción Guardar del iPhone; una falla de archivo no borra los puntos del entrenamiento.
- Si falla la comunicación/guardado, mantener la revisión recuperable en iPhone y ofrecer **Reintentar guardar** en el reloj. No notificar éxito si el guardado duradero falla.
- **Finalizar directamente en iPhone** sigue abriendo la pantalla editable y el usuario puede pulsar Guardar o Descartar: este cambio solo afecta a la orden emitida desde Apple Watch.

## Validación en dispositivos
1. Watch con iPhone enlazado. Desde Watch iniciar Caminata (iPhone controla GPS), caminar con ruta y finalizar en Watch. Confirmar que aparece resultado en Watch, NO aparece «Guardar entreno» en iPhone, y hay exactamente un registro en Inicio/Historial con GPS/parciales.
2. Pulsar Finalizar repetidamente, entregar mensajes WCSession duplicados, volver a conectar Watch: un solo registro por UUID, sin HealthKit duplicado.
3. Sin cobertura de Watch/iPhone durante el comando: Watch muestra error y conserva la sesión. Recuperar alcance y reintentar; verificar guardado.
4. Con HealthKit y sin HealthKit; comprobar que kcal/FC mostradas nunca son estimaciones falsas y que se vincula HKWorkout real cuando corresponda.
5. Iniciar sesión directamente en Watch sin iPhone y finalizar. Tras reconexión: un registro en iPhone, sin segunda hoja de revisión, y posterior actualización de UUID y métricas de Salud si llega.
6. Iniciar y finalizar desde iPhone: la revisión habitual sigue presente. Una sesión de Watch distinta no debe finalizar una actividad activa no relacionada en iPhone.
7. En iPhone con `LocalStore.persistAndFlush` fallando, el reloj NO debe mostrar actividad guardada y se permite recuperación desde revisión.

## Limitaciones
- La recepción del ACK requiere que WatchConnectivity pueda entregar mensajes. Un dispositivo apagado u offline no puede confirmar al instante; no se comunica éxito hasta la respuesta.
- No se han sustituido las pruebas físicas de dos dispositivos por una mera compilación.
