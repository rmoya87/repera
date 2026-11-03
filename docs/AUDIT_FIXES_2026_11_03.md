# Auditoría iOS, Android, watchOS y Wear OS — correcciones del 03/11/2026

## Alcance
Cambios en la rama `fix/multiplatform-ux-audit-20261103`. Una inspección de fuente y tests añadidos NO
acredita builds, interfaz visual ni pruebas reales de reloj. No fusionar
automáticamente en `main` hasta validación efectiva.

## Correcciones implementadas
- iOS: el delegado de notificaciones mantiene la presentación de avisos de
  descansos y sesiones; la revisión desde una notificación exige
  `awaitingResultEntry`, evitando reabrir una revisión ya cerrada.
- Android: el enlace de notificación de entrenamiento terminado también valida
  `awaitingResultEntry`. Inicio indica «Completar resultados» aun sin permiso
  para emitir notificaciones.
- Apple/Android: los resultados y la configuración del temporizador quedan
  aislados por cuenta; en Android los favoritos también. No se atribuyen
  automáticamente datos legados sin identidad conocida a otra cuenta.
- Wear OS: los controles de avance ya no aparecen habilitados mientras la
  sesión está pausada. El texto WOD indica que el resultado se registra en el reloj.
- iOS/Android: el panel de métricas del mapa muestra indicador de despliegue;
  en Android la denegación GPS exige una decisión explícita antes de registrar
  solo el tiempo.
- iOS: advertencia de borrado en Apple Salud, aviso de error tras fallo de
  eliminación, acción accesible de borrado y exclusión mutua de tarjetas por swipe.
- Android: las entradas fuera de rango en apuntar ejercicio bloquean Guardar
  en lugar de guardar valores truncados silenciosamente.
- Apple Watch y Wear OS: transporte y selección de varias sesiones en un mismo día;
  se conserva el contrato anterior de un plan para clientes antiguos.
- iOS/Android: máxima FC personalizada opcional (120–230 lpm), con fallback
  provisional de 190 lpm. Las muestras de pulso siguen siendo medidas, no sintéticas.
  iPhone transmite el máximo a WatchConnectivity; Android a Wear Data Layer.

## Verificaciones realizadas
- Revisión estática de rutas de código y comprobación de sustituciones de fuente.
- Tests añadidos (todavía no ejecutados) para aislamiento de cuentas, límites
  numéricos y compatibilidad de FC máxima.
- Los jobs remotos del branch no aportan logs/pasos ejecutados legibles; un
  estado «failure» por sí solo no acredita causa ni ejecución real de tests.

## Checklist obligatoria para integrar
1. Xcode build iOS + watchOS y `swift test` de ReperaDomain, tests UI/compilación
   y comprobación del código Swift 6 bajo aislamiento de actor.
2. Android Gradle test + assemble, tests instrumentados móvil y Wear; verificar
   serialización JSON heredada, clases profesionales y selección de rutinas.
3. iPhone + Apple Watch reales: 2+ sesiones del día, pausa, corona, FC reciente,
   permisos rechazados, bloqueos, reconexión y finalización idempotente.
4. Android + Wear OS reales: Data Layer con dos planes, mismo UUID tras
   reconexión, permisos denegados y ausencia de doble escritura sanitaria.
5. Dos cuentas: confirmar que una no lee los favoritos, ubicación ni resultado
   pendiente de la otra; comprobar comportamiento de datos legados sin dueño.
6. Dynamic Type, VoiceOver, TalkBack, modo oscuro, pantallas compactas,
   iPad/DUO/tablet, estados vacíos, conexión lenta y VoiceOver swipe de borrar.
7. Verificar que aviso de borrado de Apple Salud se muestra tanto desde Inicio
   como desde Historial, y que se informa un fallo asíncrono.
8. Confirmar zonas FC personalizadas en las cuatro plataformas y el fallback
   provisional sin sensores de pulso.
9. Revisar regresiones al cruzar medianoche y límite de tamaño de los payloads
   con múltiples sesiones complejas. No publicar una sesión incorrecta si un
   snapshot Watch llega tarde.
10. Verificar permisos de avisos y segundo plano: el rechazo del permiso de
    notificaciones no debe ocultar la vía manual «Completar resultados».

## Pendiente de validación
No se han realizado compilaciones locales ni emulaciones físicas desde este
entorno. Los tests nuevos son cobertura propuesta, no evidencia de ejecución.
Tampoco se ha verificado la migración de datos antiguos sin propietario conocido:
por privacidad no se realiza una adopción automática insegura.
