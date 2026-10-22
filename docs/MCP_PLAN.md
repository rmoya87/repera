# Repera IA — tokens personales, planificación y MCP

## IA conversacional, material y sincronización de Apple (21/10/2026)

- Se eliminó la pantalla `AITrainingProfileView`. `get_training_profile` devuelve la frecuencia **observada** (no la disponibilidad supuesta), movimientos frecuentes, calidad de la muestra y preguntas necesarias; el usuario confirma objetivos, días, tiempo y material por chat mediante `set_training_preferences`. Las sesiones antiguas no se sobrescriben.
- `training_exercise_metadata.required_equipment` codifica material tangible (barra, mancuernas, gomas, anillas, cajón, comba, ergómetros, etc.) en 188 fichas; la ficha restante permanece desconocida. `joint_demands` detalla demandas articulares generales en 21 ejercicios concretos y está vacío donde no hay una clasificación fundada. La herramienta `find_equipment_alternatives` filtra por disponibilidad confirmada y coincidencia muscular, **no** promete equivalencia mecánica ni seguridad para una lesión.
- Apple/Supabase: migración `20261021235500_apple_profile_avatar_storage.sql` crea `profiles.avatar_url`, el bucket JPEG de 2 MiB y políticas del propietario. Se elimina el error de perfil del apartado Centro/Entrenamiento; Cuenta → Sincronizar ahora indica por separado los componentes pendientes, restaura sesión cacheada y espera trabajos automáticos en curso. No se interpreta permiso nuevo de Apple Salud como concedido ni pendiente obligatorio: sueño/ciclo requieren activación expresa.
- Pruebas de privacidad de perfil por RLS en Supabase: lectura y actualización desde su propio JWT; otra identidad no puede leerlo; transacción revertida. La validación con iPhone real sigue siendo pendiente.

## Catálogo completo sin modificar la app (21/10/2026)

Migración `20261021235000_complete_ai_catalog_muscle_mappings.sql` aplicada, reproducida literalmente desde `CatalogHalterofilia` (40), `CatalogGimnasia` (56), `CatalogCrossFit` (44) y las 52 fichas anteriores de `CatalogEnrichment`. De los 140 registros de las tres nuevas fuentes, 137 eran filas del catálogo profesional pendientes de anatomía; tres nombres no tienen una fila idéntica y no se duplican. Resultado SQL: **189/189 fichas con procedencia**, **183 con músculos principales** y **6 de cardio solo con músculos secundarios** (Air bike, Echo bike, simples/dobles/triples de comba y Shuttle run). Se normalizan `lats → upper-back` y `hip flexors → hip-flexors` conforme a `MuscleTaxonomy`. Los tests de paridad `tests/test_ai_catalog_metadata.py` detectan deriva entre Swift y SQL. La fuente verificada aquí es **el catálogo de código de Repera**, no un consenso clínico o estudio biomecánico independiente.

## Evolución: Coach IA con programas y contexto deportivo (21/10/2026)

**Cambios implementados (aditivos, compatibles con el espejo iOS):**
- `athlete_training_profiles`: objetivos deportivos, experiencia, días, minutos, material y opt-in de coaching. No existe formulario obligatorio: el MCP extrae hábitos observados de 90 días de historial y pregunta por objetivos y material disponibles en la conversación; excluye Apple Salud, lesiones, rutas, medidas físicas y notas privadas.
- `athlete_training_calendar_snapshots`: fotografía atómica de rutinas **personales** fechadas y recurrentes hasta 90 días. La app sube únicamente título, identidad de ejercicio, series previstas y formato WOD; no sube el objeto bruto `Routine`, notas ni GPS. Se actualiza con la sesión, iCloud y el botón Cuenta → Sincronizar ahora. El iPhone sigue siendo fuente de verdad y el MCP avisa si falta la fotografía.
- `training_exercise_metadata`: tabla común unida al catálogo profesional (189 entradas), con campos de alias, músculos, equipamiento y variantes. Las 189 entradas usan los metadatos de los catálogos nativos: 183 con músculos principales y 6 movimientos de cardio sin músculo principal (pero con músculos secundarios). Los 50 IDs nativos existentes siguen enlazados. `metadata_source` registra la procedencia y los slugs siguen `MuscleTaxonomy`. `search_training_exercises_enriched` y `get_exercise_performance` resuelven ambas identidades; `get_exercise_alternatives` nunca inventa variantes no curadas.
- `athlete_training_programs`: macrociclos persistentes propuestos/activos/pausados, duración 1–52 semanas, fases con progresión, revisión optimista por `revision`, y vinculación opcional a los planes diarios mediante `ai_training_plans.program_id`. Repera permite ver y activar programas desde Ajustes. Una fase de meses **no inserta cientos de entrenamientos** automáticamente: el asistente envía las siguientes 1–14 sesiones con `create_training_plan`.
- El MCP incorpora `get_training_profile`, `get_training_calendar`, `get_training_analysis`, `get_exercise_performance`, `get_exercise_alternatives`, `search_training_exercises_enriched`, `get_training_programs`, `create_training_program`, `review_training_program` y `adjust_training_program`. No entrena un modelo propio: usa métricas reproducibles y deja al asistente el razonamiento y la explicación.
- `create_workout` y `create_training_plan` aceptan `idempotencyKey` UUID. La base de datos evita repeticiones de fecha en el mismo lote; una petición repetida no sobreescribe la original. Para vincular sesiones a un macrociclo se usa `programId`.

**Interpretación de métricas:** `get_training_analysis` agrega por semanas el volumen de fuerza, repeticiones, kg, RIR disponible y máximos estimados mediante Epley (solo series de 1–12 repeticiones con carga). Ningún dato describe recuperación fisiológica o riesgo médico. Los RIR ausentes, cargas inexistentes y ejercicios sin ID se identifican como calidad faltante. Las clases profesionales y entrenamientos aún no sincronizados desde iCloud pueden faltar; se indica frescura y limitaciones del calendario.

**Seguridad:** RLS con `owner_id=auth.uid()` en perfil, calendario y programas; clientes OAuth con `client_id` no pueden leer las tablas personales nuevas; el MCP PAT resuelve el `owner_id` a partir de un hash de token y filtra todas las lecturas y escrituras; solo publica Realtime `ai_training_plans`. Prueba SQL de privacidad con dos identidades simuladas, en transacción revertida.

**Pendiente de aceptar como lanzamiento:** compilar Swift y prueba de dispositivo real, autorización de un PAT real y flujo E2E; contrastar las métricas del servidor con `StatsEngine`, `ProgressionEngine` y `MuscleTaxonomy` de Swift; mantener las 189 fichas alineadas con la biblioteca Swift, auditar biomecánicamente las asignaciones y revisar alias/alternativas; conectar el calendario profesional para que quede completo; desarrollar gestión de revisiones y avisos push si se desea coaching autónomo con la app cerrada. Este hito no afirma que exista un entrenador autónomo en segundo plano.


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

## MCP v0.4 · edición segura, permisos y paginación (22/10/2026)

- Las entradas del MCP usan `z.strictObject` a todos los niveles definidos (rechazar campos desconocidos, también series/bloques, no ignorarlos); `get_exercise_performance` requiere **exactamente uno** de `catalogKey` o `name`. `create_training_plan` valida bloques, unidades y fechas antes de insertar. Fechas `scheduledDate` son días del **calendario local del atleta**; `scheduledTimeMinutes` son minutos desde medianoche local, no instantes UTC. No mezclar con zonas horarias sin un campo explícito futuro.
- Nuevas herramientas `update_ai_training_plan`, `archive_ai_training_plan`, `restore_ai_training_plan`, `update_training_program`, `archive_training_program`, `restore_training_program` con RLS lógica por `owner_id`, revisión optimista `expectedRevision` y errores estructurados `{error:{code,field,message}}`. Solo editan propuestas aún `pending`, **nunca** rutinas aplicadas al iPhone; archivar es soft-delete reversible, no borrado irreversible de entrenamiento real. `destructiveHint:true` para edición/archivo; creación y deshacer no destructivos. Las respuestas MCP de error pueden legítimamente viajar con HTTP 200 y `isError:true` según JSON-RPC; no implica éxito.
- `get_workout_history`, `get_ai_training_plans`, `get_training_programs` devuelven `{items,hasMore,nextCursor}` para recorrer páginas. El cursor es posición codificada en base64; ante escrituras concurrentes es posible que la paginación por offset cambie, por lo que para máxima consistencia sería preferible cursor de clave/fecha. Las métricas derivadas mantienen límites propios: no confundir un análisis abreviado con historial exhaustivo.
- PAT HTTPS: `training:read` y opcional `training:write` desde Ajustes → Acceso IA. Nuevos tokens admiten modo solo lectura. Tokens previos conservan lectura/escritura, caducidad y revocación desde app. `get_mcp_access_info` devuelve permisos, expiración y semántica de fechas sin revelar el secreto; no existe OAuth 2.1 ni autorización delegada de terceros implementada aquí. Para integraciones públicas se deberá diseñar OAuth real (PKCE/scopes/consent/refresh/AS discovery).
- Catálogo compartido ampliado a **193 ejercicios** (cuatro detectados en pizarras de otros boxes), con demandas articulares **estimadas, no clínicas**, en 193 fichas; fuentes `joint_demands_source` distinguen las basadas en músculo de las combinadas con reglas del movimiento. Identificados **192/193** requisitos de material. No usar esta taxonomía para contraindicar lesiones o prescribir rehabilitación.


## Solicitudes de CRUD y zona horaria (22/10/2026)

**Entrenamientos completados**: `update_workout` (título, correcciones de series por ID) y `delete_workout` generan registros en `ai_athlete_change_requests` con estado `pending`, no modifican directamente el espejo. Repera iOS muestra cada solicitud en Ajustes → Acceso IA; el deportista la **acepta o rechaza**. Antes de aceptar se verifica la revisión `expectedUpdatedAt` en el espejo; se aplica mediante `ReperaStore.saveWorkout` o `deleteWorkout` local-first. El borrado nativo puede afectar a su actividad enlazada de Apple Salud: la UI lo advierte. La siguiente sincronización propaga los cambios y tombstones. Una IA nunca borra registros históricos sin autorización en dispositivo. `get_workout_history` expone IDs de entradas/series y `updated_at` para crear parches precisos.

**Ejercicios**: `create_custom_exercise`, `update_custom_exercise`, `delete_custom_exercise` son solicitudes que requieren aprobación nativa y respetan el límite de ejercicios personalizados de la suscripción. `get_custom_exercises` consulta el espejo privado `athlete_custom_exercise_mirror`. El catálogo global de 193 ejercicios es curado y **no** puede alterarse mediante tokens de atletas. Ninguna ficha histórica registrada se reescribe si se elimina el ejercicio custom actual. `get_athlete_change_requests` expone estado/aplicación/rechazo y permite paginar.

**Esquema único**: `schema.ts` contiene `workout` y todos los objetos anidados estrictos. `update_ai_training_plan` reutiliza las mismas definiciones de bloques/series del creador y valida además las reglas cruzadas con `workout.safeParse`: ya no se admiten `blocks: [z.unknown()]` ni nombres de claves desconocidos.

**Zona horaria y DST**: las sesiones sin hora siguen usando fecha civil `scheduledDate`; si contienen `scheduledTimeMinutes`, requieren `scheduledTimeZone` (IANA) y `scheduledUtcOffsetMinutes` (minutos al este de UTC). `scheduledInstant` comprueba el offset y rechaza horas inexistentes al adelantar relojes; el offset selecciona una de las dos horas repetidas al atrasar relojes. Se persisten `scheduled_time_zone`, `scheduled_utc_offset_minutes` y `scheduled_at` (instante UTC). El iPhone proyecta el instante a su calendario local. `create_training_program` requiere `startTimeZone` y el espejo del calendario registra `time_zone`. Fechas históricas anteriores sin zona se conservan como tales y no se rellenan artificialmente.

**Seguridad**: dos tablas RLS privadas `ai_athlete_change_requests`, `athlete_custom_exercise_mirror`. La app solo puede **leer y decidir** solicitudes de IA; no insertar peticiones haciéndose pasar por asistente ni cambiar su contenido. Los tokens MCP respetan `training:write`. SQL smoke de dos identidades en transacción revertida, sin datos de prueba duraderos. Los errores de validación y conflicto se devuelven estructurados. En ausencia de una compilación Xcode y una prueba con usuario/device real, no afirmar que el E2E esté certificado.
