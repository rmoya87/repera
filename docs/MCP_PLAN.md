# Repera IA — tokens personales, planificación y MCP

## Recepción automática en primer plano (21/10/2026)

- Ajustes → **Acceso IA** muestra creación y revocación de tokens sin tarjeta de inicio de sesión Apple, sin textos auxiliares debajo de las tarjetas ni botón manual de actualización de planes. El login y recuperación de sesión corresponden al arranque habitual de Repera.
- **Supabase Realtime**: la migración `20261021171000_ai_training_plans_realtime_publication.sql` publica únicamente `public.ai_training_plans` bajo `supabase_realtime`; la tabla aplica RLS de SELECT para `owner_id = auth.uid()` y no expone tokens ni entrenamientos históricos.
- `AITrainingInboxStore.startRealtime(store:)` escucha inserciones del propietario autenticado con `InsertAction` y `filter: .eq("owner_id", value: uid)`, y relee desde la base de datos tras establecer la suscripción para evitar perder eventos durante la conexión. El evento no incluye datos de otros usuarios.
- Al recibir un entrenamiento, se importa mediante el flujo actual `saveRoutine` (sin reemplazar sesiones de ese día) y Repera muestra un aviso flotante breve. Diario e Inicio observan el estado del calendario.
- La suscripción se detiene al dejar el primer plano o cerrar sesión y se vuelve a establecer cuando regresa la app; `Sincronizar ahora` en **Cuenta** sigue sincronizando explícitamente iCloud, entrenamientos y planes IA pendientes.
- **Límite**: una app iOS suspendida o terminada no recibe eventos Realtime en segundo plano; al volver se realiza `sync` y backfill. Para alertas en pantalla de bloqueo con la app cerrada se necesita APNs/Push de servidor (fuera de esta migración); no anunciar notificaciones push hasta implementarlas.
- Validación SQL transaccional: propietario ve su plan de prueba; otro usuario no lo ve; rollback conserva datos. Pendiente prueba de iPhone físico y entrega desde un cliente MCP.



**Rama**: `feat/repera-mcp-training-data` — **Proyecto Supabase**: `uvzgujlrqohreoucirms` — **Fecha**: 21/10/2026.

## Estado aplicado

- [x] Eliminadas las 5 tablas vacías obsoletas del prototipo (sin `CASCADE`). Conservar `athlete_workout_mirror` físico: la app iOS publicada aún escribe mediante `upsert`. Exponer `athlete_workouts` y `training_exercise_catalog` como vistas `security_invoker`.
- [x] Verificados 3 entrenamientos privados, 20 entradas de ejercicio, 58 series y 189 ejercicios del catálogo profesional; no se han trasladado datos Apple Salud ni GPS.
- [x] Migración `20261021163724_ai_personal_tokens_training_inbox` aplicada: `ai_access_tokens` y `ai_training_plans`, RLS, derechos de columnas mínimos.
- [x] Migración `20261021164545_retire_oauth_client_grants_for_personal_tokens` aplicada: OAuth web y grants antiguos retirados. Los JWT con `client_id` no pueden acceder al espejo personal por Data API.
- [x] `repera-ai-tokens` Edge Function ACTIVE: emite tokens `rep_ai_…` de 32 bytes mediante RNG criptográfico, verifica JWT de usuario con Auth, y almacena **solo SHA-256 del token**, metadatos de vencimiento y prefijo en claro.
- [x] `repera-mcp` Edge Function ACTIVE v3: verifica el hash del token en cada petición, comprueba caducidad/revocación y accede a Supabase exclusivamente en el backend, filtrando **TODAS** las consultas/escrituras privadas por `owner_id` derivado de la credencial.
- [x] Herramientas MCP: `get_workout_history`, `analyze_muscle_balance`, `get_exercise_progress`, `search_training_exercises`, `get_ai_training_plans`, `create_workout`, `create_training_plan`.
- [x] iOS: Ajustes → Datos → Acceso IA; crear token con nombre/7,30,90,365 días o ilimitado; mostrar una sola vez; copia de portapapeles con caducidad; listado enmascarado y revocación.
- [x] Receptor iOS `AITrainingInboxStore`: convierte bloques tipados de fuerza, RIR, series, WOD, EMOM, AMRAP, For Time, Tabata y otros formatos a `Routine`, `RoutineBlock` y `WODMovement`; importa una vez por ID, confirma recepción al backend, sincroniza con iCloud vía `saveRoutine`.
- [x] Inicio ya soporta `Routine.scheduledDate`; Diario muestra ahora una sección «Entrenamientos con fecha».
- [x] Si ya hay entrenamiento en esa fecha, NO reemplazar: mantener el plan IA pendiente e informar en Acceso IA.
- [x] «Sincronizar ahora»: mostrar exclusivamente texto de éxito o error, sin recuentos ni fecha.
- [x] Prueba SQL transaccional: una sesión propietaria lee/revoca metadatos del token y confirma planes; otro usuario no accede; el hash nunca es seleccionable con privilegios authenticated. La transacción se revierte y deja 0 tokens de prueba.
- [ ] Compilar Repera con Xcode iOS 27 y ejecutar test de TestFlight/iPhone real. Los GitHub Actions disponibles fallan ANTES del primer step (logs no disponibles), por lo que una deploy exitosa no significa compilación validada.
- [ ] Prueba MCP real con un PAT emitido desde Ajustes, incluida rotación/revocación, caducidad y escritura de un WOD; comprobar que iPhone hace la importación y el ACK.
- [ ] Validar el esquema de herramientas MCP contra el cliente de IA elegido; algunos conectores solo aceptan OAuth interactivo y no un `Authorization: Bearer` personalizado.
- [ ] Medir rendimiento/rate-limit, evitar repetición de tool calls y definir cuota de planes y observabilidad antes de comercializar.

## Modelo de seguridad de token

**No es OAuth 2.1 interactivo**: es un *personal access token* (PAT), compatible con clientes MCP que permiten configurar un encabezado `Authorization: Bearer rep_ai_…`. No prometer conexión nativa a ChatGPT sin comprobar soporte de autenticación personalizada.

- **Nunca guardar el token reversible**, aunque esté cifrado: para verificarlo es más seguro un hash SHA-256 irreversible, con 256 bits de entropía. TLS en tránsito, valor completo una única vez en el dispositivo, revocación y expiración controlados desde Supabase.
- `repera-ai-tokens`: acepta únicamente la sesión real de Supabase Auth, nunca un PAT ni una llamada anónima. El token se genera en backend, máximo 10 tokens activos por usuario, y solo su `token_prefix` es visible al volver a abrir Ajustes.
- `repera-mcp`: el entorno Supabase mantiene la clave privilegiada solo en Edge, nunca en iOS ni en un agente. El servicio valida hash, revocación, vencimiento y `owner_id` en **cada llamada**. No confiar en IDs de usuario incluidos por el agente.
- RLS de `ai_access_tokens`: owner SELECT sin hash, owner UPDATE exclusivamente `revoked_at`, nunca owner INSERT. RLS de `ai_training_plans`: owner SELECT y confirmación de estado pendiente→aplicado/descartado. La IA solamente escribe a través de su servidor propietario, en el buzón pendiente.
- Todas las llamadas MCP se efectúan con credencial PAT, no con tokens de Apple Salud, contraseñas de usuario ni `service_role` enviado al cliente.
- No dar a las herramientas acceso a HealthKit, rutas de GPS, peso corporal, sueño, frecuencia cardíaca, ni notas privadas de la sesión.

## Contrato de creación de entrenamientos para IA

La herramienta `create_training_plan` acepta hasta 14 entrenamientos con fecha `scheduledDate` (`YYYY-MM-DD`), título y bloques ordenados. `create_workout` utiliza exactamente el mismo modelo para una fecha.

```json
{
  "title": "Fuerza y acondicionamiento",
  "scheduledDate": "2026-10-23",
  "scheduledTimeMinutes": 540,
  "blocks": [
    {
      "title": "Fuerza",
      "kind": "strength",
      "exercises": [
        {
          "name": "Back squat",
          "plannedSets": [
            {"reps": 5, "weightKg": 60, "rir": 2},
            {"reps": 5, "weightKg": 60, "rir": 2},
            {"reps": 5, "weightKg": 60, "rir": 2}
          ],
          "restSeconds": 120
        }
      ]
    },
    {
      "title": "Metcon",
      "kind": "wod",
      "wodFormat": "amrap",
      "timeCapMinutes": 12,
      "movements": [{"name": "Burpees", "reps": 10}, {"name": "Air squat", "reps": 15}]
    }
  ]
}
```

- Cada ejercicio puede incluir `catalogKey`. La app intenta unirlo al catálogo local o por nombre normalizado (ES/EN); los libres se crean como movimientos personalizados, sin inventar metadatos musculares.
- Cada bloque `strength` requiere `exercises` con `plannedSets`; cada bloque `wod` requiere `wodFormat` y `movements`. El servidor rechaza estructura incoherente, pesos/repeticiones o fechas fuera de límites, y WOD desconocidos.
- La app convierte al modelo `ReperaDomain`; `saveRoutine` lo coloca en calendario y en iCloud. Si falta el ACK de Supabase no se reimporta ni se pisan los cambios que haya hecho el usuario.
- Ninguna operación MCP escribe una sesión terminada o altera las marcas/series ya realizadas.

## Secuencia de verificación antes de integrar en main

1. Ejecutar build iOS, `swift test`, tests del paquete de negocio y comprobar logs de Edge Functions.
2. Crear token de corta duración desde un iPhone real y probar `tools/list`, `get_workout_history`, `create_workout`, `create_training_plan` y revocación.
3. Comprobar, tras abrir iPhone, presencia en **Inicio** para el día y sección **Diario → Programado → Entrenamientos con fecha**.
4. Probar ejercicio libre, movimiento de catálogo ES/EN, WOD RFT/EMOM/tabata, series con RIR, time cap y orden de bloques.
5. Simular dos cuentas y múltiples tokens; comprobar que no hay acceso cruzado ni escritura sobre sesiones terminadas.
6. Resolver los avisos preexistentes del asesor Supabase: SECURITY DEFINER en búsqueda de organizaciones y comprobación de contraseñas filtradas.
