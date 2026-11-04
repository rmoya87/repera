# Repera · Acciones nativas (04/11/2026)

Rama de implementación: `feat/native-platform-actions-2026-11-04`. Alcance solicitado: 10, 11, 13, 14, 17, 1, 3, 4 y 5.

## Qué cambia

| Número | Implementación en esta rama | Límites explícitos |
| --- | --- | --- |
| 10 · Reloj/móvil | Wear reintenta la cola persistida de series con UUID y ACK mientras la actividad está visible. Se conserva el mirroring HealthKit, WatchConnectivity y los guardas ya implementados. | No se ha añadido sincronización permanente en segundo plano; hardware real pendiente. |
| 11 · Lugar | Coincidencia del GPS actual con sitios elegidos previamente a ≤50 m, priorizada frente a buscar nuevos POI en iOS. Preselección en Play interior iOS y buscador Android. | No cambia el lugar de una ruta GPS registrada ni usa geofencing permanente. Sin permiso GPS, no hay sugerencia. |
| 13 · Recordatorios | Aviso local una hora antes para reservas `booked` de clase/cita, filtradas por cliente, con límite de 40, gestión de cancelaciones y cuenta. Android WorkManager; iOS UserNotifications. | WorkManager/Doze puede retrasar Android; para hora garantizada sería necesario backend/push. No solicitar permisos al programar. |
| 14 · Salud | La implementación existente de HealthKit y Health Connect se conserva; se añade revalidación de identidad antes de adjuntar una ruta a un registro existente de Health Connect. | No se solicitan nuevas métricas ni se envía información clínica al backend. |
| 17 · Batería | Android reduce repintados de notificación persistente (5 s normal / 15 s en ahorro), sin alterar el GPS, sensores ni la cola de series. | Medición real de batería pendiente; no se modifica frecuencia de grabación. |
| 1 · Voz | App Intents de Siri/Atajos iOS para abrir Comenzar y entrenamiento activo; Android accesos dinámicos de lanzador. | Android App Actions/Assistant dedicado aún no configurado; los atajos no empiezan sensores en segundo plano. |
| 3 · Controles | Centro de Control en iOS con WidgetKit ControlWidget para abrir Repera, y Quick Settings Tile Android para Comenzar. | iOS abre la app, no inicia la grabación desde el control. |
| 4 · Bloqueo | Android 16+ solicita promoción del entrenamiento a Live Update; en versiones anteriores se conserva notificación con acciones existentes. Las Live Activities de iOS se mantienen. | La promoción depende del SO/usuario. No hay nuevos botones interactivos dentro de Dynamic Island. |
| 5 · Doble toque | En Apple Watch se asigna `.handGestureShortcut(.primaryAction)` a siguiente serie válida y salto de descanso. | No permite finalizar ni descartar por gesto; sólo hardware compatible. |

## Reglas

- Un inicio desde un acceso del sistema abre la pantalla existente; comprobar y conceder permisos ocurre dentro de la app.
- Ningún acceso creará por sí mismo un `HKWorkout`/sesión Health Services adicional.
- La cola Wear conserva identificadores hasta obtener confirmación.
- Un origen de salud sólo se reutiliza si pertenece a la sesión y la identidad autorizada.
- Los recordatorios corresponden a reservas propias; un cambio de identidad cancela el calendario local.
- El GPS no se infiere cuando no hay coordenadas reales.

## Validación pendiente

1. Compilación Xcode iPhone y Apple Watch con firma, compilación Android/Wear y CI en PR.
2. Apple Watch real con doble toque, series + descanso y caso de última serie.
3. iPhone físico: Siri/Atajos, galería de controles, permisos denegados y sesión ya activa.
4. Android 14–17: tiles, permiso de notificaciones, Live Update disponible y comportamiento con teléfono bloqueado.
5. Reserva creada/cancelada/cambio de cuenta, husos horarios y modo avión.
6. Wear sin enlace 30 minutos, reintento al recuperar conectividad, ACK duplicados y cambio de usuario.
7. Comprobar carga de batería y GPS con el sistema en ahorro.
8. Localización interior sin permiso, lugar reciente a <50m, lugar lejano y ruta GPS inmutable.

No declarar paridad completa ni validación funcional sin ejecutar estas comprobaciones.
