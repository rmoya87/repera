# Integraciones nativas iOS / Android / Watch / Wear — 4 nov 2026

## Alcance / estado de este PR

Implementación incremental, NO cierre de las cuatro fases. El repositorio ya cuenta con GPS, HealthKit/Health Connect, Health Services, mirroring de sesiones, ActivityKit, notificaciones, complicaciones watchOS y un Tile de Wear OS. No se duplican esas capas.

### Implementado aquí

- **Fase 1, entrada segura:** accesos externos de navegación (no inicio automático de entrenamiento), rutas permitidas, app intents, comprobación de hidratación e identidad en los flujos existentes. La capa de registro y sus garantías previas se conservan.
- **Fase 2, iOS:** App Intents/App Shortcuts para Entreno de hoy, Comenzar, herramientas y Ejercicios; WidgetKit de inicio con accesos para iPhone, sin exponer datos sanitarios a extensiones.
- **Fase 2, Android:** accesos directos del launcher, dos Quick Settings Tiles y un Glance AppWidget con comprobación de sesión y acceso a Comenzar / Inicio. Todas las acciones abren la actividad autenticada; nunca se ejecutan sensores ni guardados desde un receiver.
- **Fase 2, Apple Watch:** el botón principal de avance de sesión activa admite doble toque en modelos compatibles, deshabilitado al finalizar o cuando no se puede confirmar. Probar en reloj real y verificar que no interfiere con scroll.
- **Fase 3, relojes:** el Tile de Wear OS muestra primero la sesión activa; la complicación de watchOS aporta relevancia de sesión a Smart Stack. La aparición efectiva depende del sistema.
- **Fase 4, iOS:** compartir una ruta GPS real como GPX desde el mapa histórico ampliado, con lat/lon validadas, tiempo original y separación de huecos >30 s. No se inventan coordenadas.

### Pendiente para completar las cuatro fases

**Fase 1:** auditoría integral de durabilidad de comandos entre dispositivos, conflictos multiusuario y reinicios; optimización energética validada por dispositivos y versión.

**Fase 2:** controles App Intents interactivos en Dynamic Island / pantalla bloqueada, Control Center de iOS, Action Button de Apple Watch Ultra, Google Assistant App Actions con configuración/validación de Play, y accesos de terceros dependientes del fabricante.

**Fase 3:** indexación profunda con Core Spotlight/AppSearch, dictado de series con confirmación, recordatorios fiables de clases vía backend, sugerencias de lugar contextuales completas, relevancia temporal adicional de Smart Stack/Tiles.

**Fase 4:** objetivos deportivos activos por disciplina, WorkoutKit para exportación estructurada a Entreno de Apple, share extensions/importación externa con validación, mejorar escrituras y conciliación Health Connect/HealthKit con pruebas en hardware.

No se debe marcar como finalizada la ejecución de las cuatro fases solo por integrar esta PR.

## Validaciones necesarias

1. CI iOS, Swift watchOS, Android/Wear OS; pruebas unitarias y de UI.
2. iPhone: widgets de 2 tamaños y Siri, app fría/caliente, onboarding, cuenta cerrada, sesión activa; no empezar sesión sin permiso.
3. Android 15–17: Glance widget, Quick Tiles, atajos y enlaces con móvil bloqueado, Chrome/default launcher, background restrictions y sesión vencida.
4. Apple Watch Series 9+/Ultra 2+: doble toque real y desplazamiento con corona, sin confirmar series al hacer scroll ni finalizar.
5. Wear OS: Tile en entrenamiento activo, plan descargado y sin plan; reloj desconectado.
6. GPX: distintas longitudes, cortes, coordenadas inválidas, orden temporal y compartir a Archivos/otra app. Ningún archivo se transmite sin una acción explícita del usuario.

Criterios de UX de las skills instaladas de Emil Kowalski: claridad sobre animación, controles accesibles, estados vacíos, transiciones nativas y test en hardware. Mantener verde Repera y no duplicar lógica de sensores.
