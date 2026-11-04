# Integraciones nativas iOS / Android / Watch / Wear — 4 nov 2026

## Alcance / estado de este PR

Implementación incremental, NO cierre de las cuatro fases. El repositorio ya cuenta con GPS, HealthKit/Health Connect, Health Services, mirroring de sesiones, ActivityKit, notificaciones, complicaciones watchOS y un Tile de Wear OS. No se duplican esas capas.

### Implementado aquí

- **Fase 1, entrada segura:** accesos externos de navegación, comprobación de hidratación e identidad; guardas de propiedad GPS idempotentes en Android para no perder muestras al reabrir la sesión. Actualización del widget de Android mediante WorkManager tras escritura atómica, aislando los fallos del widget del guardado y de la autenticación.
- **Fase 2, iOS:** App Intents/App Shortcuts para Entreno de hoy, Comenzar, herramientas y Ejercicios; WidgetKit de inicio con accesos para iPhone, sin exponer datos sanitarios a extensiones. Tres Control Widgets nativos para Centro de Control / pantalla bloqueada / Botón Acción compatibles, enviados a la escena de Repera a través de OpenIntent; no registran series en segundo plano.
- **Fase 2, Android:** accesos directos del launcher, dos Quick Settings Tiles y un Glance AppWidget con comprobación de sesión y acceso a Comenzar / Inicio / Ejercicios / Temporizador. Todas las acciones abren la actividad autenticada; nunca se ejecutan sensores ni guardados desde un receiver.
- **Fase 2, Apple Watch:** el botón principal de avance de sesión activa admite doble toque en modelos compatibles, deshabilitado al finalizar o cuando no se puede confirmar. Probar en reloj real y verificar que no interfiere con scroll.
- **Fase 3, relojes y búsqueda:** el Tile de Wear OS muestra primero la sesión activa; la complicación de watchOS aporta relevancia a Smart Stack. Core Spotlight indexa exclusivamente ejercicios públicos del catálogo, sin datos de salud/rutinas privadas; al abrir exige identidad e ID existente. La aparición efectiva de cada superficie depende del sistema.
- **Fase 4, iOS:** compartir una ruta GPS real como GPX desde el mapa histórico ampliado, con lat/lon validadas, tiempo original y separación de huecos >30 s. WorkoutKit: preparar objetivos de tiempo/distancia solo para deportes cardio admitidos y entregar el plan a Entreno de Apple Watch explícitamente, antes de iniciar la grabación Repera. No se inventan coordenadas ni se graban sesiones en paralelo.
- **Fase 4, Android:** compartir GPX desde el histórico de una sesión con recorrido GPS: un codec de dominio valida rango, elimina puntos inferidos y separa cortes, mientras FileProvider concede acceso de lectura temporal únicamente mediante el chooser del sistema. Incluye pruebas unitarias del codec.

### Pendiente para completar las cuatro fases

**Fase 1:** auditoría integral de durabilidad de comandos entre dispositivos, conflictos multiusuario y reinicios; optimización energética validada por dispositivos y versión. El tracker GPS de Android ahora evita preempción y realiza fallback a GPS/red si FUSED no está disponible.

**Fase 2:** controles de pausa/reanudación/serie interactivos en Dynamic Island y Live Activities con persistencia y seguridad; Apple Watch Ultra Action Button especializado (los Control Widgets de iPhone ya están codificados, pendientes de validar en iPhone); Google Assistant App Actions con configuración/validación de Play, y acciones de terceros dependientes del fabricante.

**Fase 3:** búsqueda profunda de rutinas privadas opt-in/Android AppSearch, dictado de series con confirmación, recordatorios fiables de clases vía backend, sugerencias de lugar contextuales editables y relevancia temporal adicional de Smart Stack/Tiles. Indexación de catálogo público en Spotlight ya codificada, falta la prueba de instalación real.

**Fase 4:** objetivos deportivos activos durante sesiones Repera, WorkoutKit avanzado para intervalos completos (la transferencia cardio básica ya está codificada), share extensions/importación externa con validación, mejorar escrituras y conciliación Health Connect/HealthKit con pruebas en hardware.

No se debe marcar como finalizada la ejecución de las cuatro fases solo por integrar esta PR.

## Validaciones necesarias

1. CI iOS, Swift watchOS, Android/Wear OS; pruebas unitarias y de UI.
2. iPhone: widgets de 2 tamaños y Siri, app fría/caliente, onboarding, cuenta cerrada, sesión activa; no empezar sesión sin permiso.
3. Android 15–17: Glance widget, Quick Tiles, atajos y enlaces con móvil bloqueado, Chrome/default launcher, background restrictions y sesión vencida.
4. Apple Watch Series 9+/Ultra 2+: doble toque real y desplazamiento con corona, sin confirmar series al hacer scroll ni finalizar.
5. Wear OS: Tile en entrenamiento activo, plan descargado y sin plan; reloj desconectado. Idempotencia del GPS Android frente a llamadas concurrentes o reentrantes.
6. GPX iOS/Android y WorkoutKit: distintas longitudes, cortes, coordenadas inválidas, puntos inferidos, orden temporal y compartir a Archivos/otra app. Con Watch enlazado: comprobar deporte/objetivo admitido y que no se inicia otra sesión Repera. Ningún archivo se transmite sin una acción explícita del usuario.

Criterios de UX de las skills instaladas de Emil Kowalski: claridad sobre animación, controles accesibles, estados vacíos, transiciones nativas y test en hardware. Mantener verde Repera y no duplicar lógica de sensores.
