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
- `repera-business-push`: falla cerrado sin `REPERA_PUSH_CRON_SECRET`; desplegada
  en prod con secreto + cron `pg_cron`/`pg_net` (vault). Entrega FCM/APNs solo
  cuando existan secretos de proveedor (`fcm_configured`/`apns_configured`).
- MCP: rate limit por token/herramienta desplegado (`consume_ai_mcp_quota`);
  CORS de invite con allowlist.
- `.mcp.json` / `.cursor/mcp.json` en `.gitignore`.
- Monetización: RevenueCat eliminado; iOS solo StoreKit 2 + paywall propio;
  Android Play Billing. Pro fail-closed sin snapshot verificado.
- Contratos `BusinessAgenda.source` alineados Swift/Kotlin.
- Espejo de entrenos: índice keyset `athlete_workout_mirror_owner_id_keyset_idx`
  aplicado en prod (`20261104104041`).

## Despliegue Supabase (04/11 tarde — hecho)

1. Migraciones aplicadas una a una (sin `db push` masivo) y registradas:
   `20261104102807`, `20261104103112`, `20261104104041`.
2. Edge: `repera-business-push` (nueva) y `repera-mcp` (redeploy) con
   `--no-verify-jwt` en push (auth por `x-repera-cron`).
3. Secreto `REPERA_PUSH_CRON_SECRET` en Edge Secrets + Vault; job cron cada
   minuto `repera-business-push`. Verificado: sin header / secreto malo → 403;
   con secreto → 200 (`claimed:0`, proveedores aún no configurados).

## Pendiente de operación (humano)

1. FCM/APNs de push: **configurados** (smoke `fcm_configured`/`apns_configured`).
2. Reconciliación de ~30 migraciones históricas: **cerrada** el 04/11
   (`docs/SUPABASE_MIGRATION_RECONCILIATION_2026-11-04.md`).
3. Validar en dispositivos reales el checklist de Always On, live-start con
   app abierta, GPS largo, R8 install, compra StoreKit sandbox y doble escritura
   Salud/Health Connect.

## Segunda pasada (04/11 tarde)

Hallazgo Alta restante cerrado en código:
- iPhone ahora implementa `WCSessionDelegate.session(_:didReceive:)` para
  `kind=finishedSession` + fusión de `routePoints` en `applyWatchSession` cuando
  el fichero llega tras el userInfo ligero (`routeViaFile`).
- `WatchTransportLimits` en decode de `PhoneConnectivity`.
- ProgressTab Android: fail-closed si `subscriptions == null`.
- Tope de bytes Wear en `MainActivity` / `WearLiveCommandListener`.
- Lectura de ajustes En vivo fuera del hilo principal.

## Verificaciones locales

- iOS: `xcodebuild` Repera → BUILD SUCCEEDED (varias pasadas).
- Android: `:mobile:assembleRelease` → BUILD SUCCESSFUL (R8).
- `Packages/ReperaDomain` swift test: 145 Swift Testing OK; 1 XCTest de
  rendimiento flaky (`testRankPerfUnder3ms`) bajo carga.

No se han aplicado migraciones ni desplegado Edge Functions desde este entorno.
