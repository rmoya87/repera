# Auditoría de fiabilidad y seguridad — 04/11/2026

Última actualización: 2026-11-04.

## Alcance

Análisis y correcciones en iOS, watchOS, Android, Wear OS y backend Supabase
compartido (rama `fix/reliability-security-audit-20261104`). El objetivo es
hacer la app lo más fiable y óptima posible: rendimiento, bugs, UX y seguridad.

Una inspección de fuente y builds locales **no** acredita pruebas en dispositivos
reales (Always On, GPS de carrera larga, Data Layer con móvil en primer plano,
R8 en instalación Play, FCM/APNs con secretos de producción).

## Correcciones principales (código)

### Optimización
- iOS: checkpoints de ruta GPS en Application Support (no UserDefaults),
  observación reducida en En vivo, caché de Historial, formatters estáticos,
  rest feedback sin tick cada segundo, memoización de arte.
- Android: lectura/parseo de `app_state.json` fuera del hilo principal,
  R8 + shrinkResources en release, opt-in Material3 a nivel módulo, claves en
  listas Lazy, `collectAsStateWithLifecycle`, Pro = false hasta snapshot.
- Apple Watch: `distanceFilter` GPS, envío de rutas grandes por `transferFile`,
  tokens `WatchTheme`, Always On con `isLuminanceReduced`.
- Wear OS: acelerómetro solo al contar reps, notificaciones FGS throttled,
  ticks a 1 s, AmbientLifecycleObserver, strings/haptics/touch targets.

### Bugs / incidencias
- Wear: ACK `/repera/live-start-ack` también desde `MainActivity` (foreground);
  fin companion solo tras confirmación del móvil.
- Apple Watch: recuperación HK con UUID externo, ACK de outbox, companion
  inicia Salud con el start real del snapshot.
- iOS: descartes de revisión en Inicio aislados por cuenta; OCR de pizarra
  solo en DEBUG; errores Business / GPX / push más visibles.
- Documentación: sesión vacía WC **no** cierra el reloj (terminal por id).

### UX
- Always On / Ambient en ambos relojes (métricas clave).
- Detalle de entreno iOS: `ogPinnedTransparentNav`.
- Center se mantiene como nombre de producto; accesibilidad «Actualizar centros».
- Android: Agenda unificada, invitaciones `repera://invitation/{uuid}`,
  strings/colores hacia recursos, TalkBack, tablets.

### Seguridad
- `repera-business-push`: falla cerrado sin `REPERA_PUSH_CRON_SECRET`; entrega
  FCM/APNs cuando hay secretos (código listo; **no desplegado** desde aquí).
- MCP: rate limit por token/herramienta; CORS de invite con allowlist.
- `.mcp.json` / `.cursor/mcp.json` en `.gitignore`.
- RevenueCat: runtime trata el placeholder como no disponible; el archive
  Release falla si sigue el placeholder (`project.yml` preBuildScripts).
- Contratos `BusinessAgenda.source` alineados Swift/Kotlin.
- Espejo de entrenos: sync por cursor / índice (migración nueva, no aplicada).

## Pendiente de despliegue / operación (humano)

1. Configurar `REPERA_PUSH_CRON_SECRET` (+ credenciales FCM/APNs) y desplegar
   `repera-business-push` / MCP actualizados.
2. Revisar y aplicar migraciones nuevas (`20261104102807_*`,
   `20261104103112_*`, `20261104104041_*`) y el plan de reconciliación de las
   ~30 versiones solo en git (`docs/SUPABASE_MIGRATION_RECONCILIATION_2026-11-04.md`).
   **No** hacer `supabase db push` masivo.
3. Inyectar `RevenueCatPublicAPIKey` real en CI/xcconfig antes de archive.
4. Validar en dispositivos reales el checklist de Always On, live-start con
   app abierta, GPS largo, R8 install y doble escritura Salud/Health Connect.

## Verificaciones locales

- iOS: `xcodebuild` Repera → BUILD SUCCEEDED (varias pasadas).
- Android: `:mobile:assembleRelease` → BUILD SUCCESSFUL (R8).
- `Packages/ReperaDomain` swift test: 145 Swift Testing OK; 1 XCTest de
  rendimiento flaky (`testRankPerfUnder3ms`) bajo carga.

No se han aplicado migraciones ni desplegado Edge Functions desde este entorno.
