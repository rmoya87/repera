## Actualización 11/11/2026 — barra de FC en Always On / Ambient

- watchOS: con `isLuminanceReduced`, `WatchHeartRateZoneBar` permanece (parámetro `attenuated`); el `TimelineView` sigue en cadencia lenta (~60 s). No se sustituye la barra por una fila de texto ni se oculta en el reloj del plan.
- Wear live: LPM centrado (`WearHeartRateBpmLabel`); zonas en arco del bisel inferior derecho (`rimBottomRight` / `WearHeartRateZoneRim`) para liberar columna central.
- Wear ambient: `WearAmbientScreen` sigue con `WearHeartRateZoneBar(attenuated = true)` lineal y bpm congelado del snapshot.
- Contrato: `tests/test_watch_wear_swipe_ambient_hr_contract.py`.

## Actualización 05/11/2026 — visibilidad persistente, bloqueo y maquetación de Tramo

### Apple Watch
- La app watchOS declara expresamente `WKSupportsAlwaysOnDisplay=true`. El sistema puede mantener su interfaz en Always On siempre que exista `HKWorkoutSession` en ejecución y el usuario no salga manualmente.
- Nunca usar el antiguo `isFrontmostTimeoutExtended` para simular una sesión: Apple lo dejó bajo control del usuario desde watchOS 7.
- La vista companion muestra el error nativo de HealthKit si no arrancan los sensores. Sin autorización/sesión HK activa, la app no puede garantizar por código que la esfera no reaparezca.
- El ajuste del usuario puede comprobarse en Apple Watch > Ajustes > General > Volver al reloj > Repera; y Ajustes > Pantalla y brillo > Siempre activada. La corona es una salida manual respetada.

### Wear OS
- `WearHealthService` incluye `androidx.wear:wear-ongoing:1.1.0` y aplica `OngoingActivity` a su *foreground notification* mientras exista un sensor workout asociado a la sesión.
- Se conservan la actividad en pausa, el icono monocromo en esfera y el `PendingIntent` local para volver al entrenamiento. Al finalizar/descartar se retira el foreground y la Ongoing Activity.
- **Entreno activo (live recording/paused o plan counting):** `View.keepScreenOn` + no sustituir la UI por `WearAmbientScreen` (paridad con Apple Watch: la cara del entreno no se oculta). Ambient mínimo solo con hub idle.
- Sin entreno activo el hub sí usa AmbientLifecycleObserver / `WearAmbientScreen` (sin forzar brillo constante).

### iPhone
- En la Live Activity del entrenamiento libre, `Tramo` pasa a una tarjeta centrada bajo la fila de indicadores y con márgenes simétricos e inferiores.
- Se reutiliza el mismo componente visual en el área expandida de Dynamic Island y en el formato compacto de la Smart Stack. Las sesiones planificadas conservan su subtítulo independiente.
- El tramo se muestra exclusivamente cuando Repera tiene un dato real de parcial; no se generan valores estimados.

### Bloqueo de pantalla móvil (05/11/2026)

En `Comenzar` la pantalla móvil permanece activa al bloquearse la interacción táctil durante una sesión iniciada o en pausa. iOS se integra con `TimerScreenAwake` para que los demás temporizadores no pierdan el permiso. Android aplica `View.keepScreenOn` mientras el bloqueo de Comenzar sigue activo. El sistema puede apagar la pantalla por orden manual del usuario, llamada o restricción de energía: no es una anulación del botón de encendido. El desbloqueo exige mantener el candado durante 1 s.

Watch Always On atenúa la misma UI. Wear con entreno activo mantiene la cara live (`keepScreenOn`); sin entreno, ambiente del hub. Con instrucciones reales: Navegación → Métricas; swipe Controles ↔ Now Playing.

### Validación de hardware
1. Empezar paseo desde reloj y desde móvil, bajar la muñeca al menos 3 minutos y regresar: pantalla de sesión/Always On, no esfera. Probar activo y pausado.
2. Pulsar corona para volver manualmente a la esfera: comprobar acceso inmediato a la sesión mediante indicador Ongoing (Wear) o indicador del workout (Watch).
3. Terminar/descartar: se retira Ongoing y regresan los tiempos normales del reloj.
4. Probar sesión sin permiso HealthKit, Always On desactivado o modo teatro: mostrar feedback adecuado y documentar límites del sistema.
5. En iPhone probar Live Activity tras varios parciales y rutas con y sin banner de indicaciones; evitar que `Tramo` quede pegado al margen inferior.
