# Repera MCP + datos deportivos — plan de trabajo

**Inicio:** 21/10/2026. **Proyecto:** Supabase `uvzgujlrqohreoucirms`. **Rama:** `feat/repera-mcp-training-data`. 
**Estado:** infraestructura de lectura y seguridad implantada parcialmente; NO se considera lista para público ni clientes de IA reales.

## Estado de integración (21/10/2026)

La integración operativa usa **tokens personales Repera (PAT)**. En Ajustes → Acceso IA, el usuario puede crear un token aleatorio de 256 bits, elegir caducidad y revocarlo. El servicio `repera-ai-tokens` valida el JWT de la sesión nativa mediante Supabase Auth, almacena exclusivamente SHA-256 y devuelve el secreto una sola vez. El endpoint `repera-mcp` exige el PAT, rechaza expirados/revocados y restringe las consultas por `owner_id` resuelto a partir del hash. Puede devolver historial, progreso muscular y catálogo, además de recibir propuestas de planificación estructurada para la bandeja del iPhone. Todas las herramientas de escritura necesitan petición expresa del usuario en su asistente.

**Importante:** el modo PAT requiere un cliente MCP que permita configurar manualmente `Authorization: Bearer <token>`. No equivale a la conexión OAuth 2.1 nativa que un cliente pueda descubrir automáticamente. La pantalla `web/oauth/consent` es preparación para una futura conexión OAuth y no debe anunciarse como funcional ni habilitar registro dinámico sin auditar todas las RLS. `mcp_user_consents` protege el eventual flujo OAuth y no sustituye a los PAT.

En la entrega se incluyen `ai_access_tokens` y `ai_training_plans` con políticas RLS y permisos mínimos. El administrador no debe exponer el `SUPABASE_SERVICE_ROLE_KEY` ni configurar el endpoint para descargar tokens. Supabase contiene las funciones `repera-ai-tokens` y `repera-mcp`; la web OAuth no está publicada. La integración ha de validarse en un iPhone real y con un cliente MCP real antes del lanzamiento.

## 1. Situación comprobada

- Repera iOS es local-first y conserva JSON/iCloud como fuente principal; `BusinessWorkoutSyncStore` sube sesiones terminadas al espejo privado `athlete_workout_mirror`.
- En producción se comprobaron 1 identidad de Auth, 3 entrenos no borrados, 20 entradas de ejercicios, 58 series y 189 entradas del catálogo Business.
- Los tres payloads existentes carecen de claves HealthKit, kcal de Salud, rutas, GPS y notas privadas.
- Las cinco tablas `exercises`, `routines`, `routine_exercises`, `workouts`, `workout_sets` estaban vacías (0 filas), sin funciones SQL actuales que las consulten. Se eliminaron vía migración con comprobación de vacío y `DROP ... RESTRICT`, sin afectar los espejos.
- `athlete_workouts` es una VIEW de solo lectura y `security_invoker=true` de entrenamientos terminados, con campos `exercises` y `wod_results` exclusivamente deportivos. `training_exercise_catalog` es la vista de consulta del catálogo profesional existente.
- **NO renombrar físicamente `athlete_workout_mirror`** todavía: las versiones iOS existentes hacen upsert sobre esta tabla, y una VIEW no permite asumir semántica PostgREST `onConflict=id`. Migración expand → cambiar todos los clientes → comprobar dispositivos antiguos → retirar alias físico.
- `mcp_user_consents` almacena consentimiento revocable de cada pareja usuario/cliente OAuth. Solo una sesión normal, sin claim OAuth `client_id`, puede otorgar/revocar ese consentimiento. Las políticas RLS impiden leer historial con un cliente no autorizado y prohíben escrituras por tokens OAuth.
- El servidor `repera-mcp` está desplegado como Edge Function con validación OAuth en middleware, doble comprobación de consentimiento y herramientas **exclusivamente de lectura**. El flag `verify_jwt=false` de la gateway es necesario para discovery OAuth, **pero la función autentica mediante `withSupabase({auth:'user'})`**; nunca usa `service_role`.

## 2. Trabajo realizado en esta rama

- [x] Auditoría de tablas heredadas, datos reales, funciones y RLS.
- [x] Migración aplicada en Supabase: `20261021161255_training_schema_cleanup_readonly_aliases`.
- [x] Migración aplicada en Supabase: `20261021161538_mcp_training_explicit_consent_guards`.
- [x] Test RLS negativo: OAuth client `unapproved-mcp-agent` obtiene **0** entrenamientos en `athlete_workouts`.
- [x] Edge Function `repera-mcp` desplegada ACTIVE v2, inaccesible sin token OAuth y consentimiento explícito.
- [x] Contrato MCP inicial: `get_workout_history`, `analyze_muscle_balance`, `get_exercise_progress`, `search_training_exercises`.
- [x] Corregir «Sincronizar ahora»: no marcar éxito si falta sesión, sincronización iCloud o subida de entrenamientos. Mostrar recuentos y errores.
- [x] Formularios de autorización web Apple/OAuth preparados en `web/oauth/consent/` (todavía no desplegados a IONOS).
- [x] Pantalla de Ajustes para consultar y revocar permisos de asistentes; compilación nativa pendiente.
- [x] Simulación SQL transaccional: usuario sin client_id ve 3 sesiones, OAuth con permiso temporal ve 3, cliente distinto ve 0; cambios de prueba revertidos.
- [ ] Ejecutar suite iOS/Xcode/SwiftUI sobre la rama y E2E real con iPhone.
- [ ] Pruebas reales del endpoint con un token válido y otro revocado, y del ciclo OAuth completo.

## 3. Puerta de seguridad para activar OAuth real

**No habilitar acceso externo todavía.** Requiere obligatoriamente:

1. Entorno staging aislado, backup, CI verde y pruebas cruzadas con dos usuarios.
2. Auditar **TODAS** las políticas RLS y RPC accesibles con JWT que tenga claim `client_id`. El consentimiento del historial NO convierte en seguras otras tablas que den acceso a cualquier usuario autenticado. Aplicar denegación específica para OAuth a tablas sensibles o un rol/audience segregado antes de abrir registro dinámico de clientes.
3. En Supabase Auth → OAuth Server, habilitar OAuth 2.1, JWT asimétrico ES256/RS256, definir Authorization Path y registrar clientes confiables. La activación puede requerir operaciones manuales del administrador y no ha sido verificada.
4. Implementar y publicar pantalla web de login + consentimiento OAuth accesible desde iPhone y navegador; asociar grant explícito a `mcp_user_consents` usando **sesión de usuario normal**, no desde el propio agente. Añadir listado y revocación en Ajustes.
5. Comprobar discovery MCP, consentimiento rechazado, scopes limitados en aplicación (los scopes OAuth estándar actuales NO protegen tablas por sí solos), y expiración/refresco de tokens.
6. Inspeccionar los avisos actuales del linter Supabase: `public.search_discoverable_organizations` SECURITY DEFINER y protección de contraseñas filtradas desactivada. Tratar antes de publicación. 
7. Pruebas de fuzzing / paginación / límites, rate limit y cuotas; observabilidad y protección ante prompt injection. No implementar escrituras MCP sin confirmación explícita.

## 4. Plan de evolución

| Fase | Entregable | Aceptación |
|---|---|---|
| A — higiene y compatibilidad | Tablas vacías eliminadas, vistas canónicas, RLS, migraciones | 3 entrenos conservados, cliente no autorizado = 0 |
| B — sincronización | Estado de iCloud/Supabase, contadores local/remoto, backfill de sesiones terminadas | Igualdad de historiales, sin duplicados, sin falsa confirmación |
| C — catálogo | Unificar `Exercise` Swift ↔ catálogo servidor: claves, ES/EN, músculos, equipo, patrones y alternativas | No hay movimientos huérfanos en plan profesional ni IA |
| D — seguridad MCP | OAuth con consentimiento visible, política RLS global para clientes, revocación, MFA según perfil, límites | Aislamiento con 2 usuarios y varios clientes OAuth |
| E — análisis deportivo | Progresión, carga muscular con `MuscleTaxonomy` y validación frente a motores Swift | Métricas reproducibles, advertencia sobre estimación de fatiga |
| F — recomendaciones | Rutinas basadas en objetivos, días, historial, equipo y restricciones | Borrador explicable; el atleta aprueba antes de guardar |
| G — lanzamiento | E2E iOS + Supabase + MCP + despliegue controlado + documentación | CI verde y sin accesos indebidos |

## 5. Convenciones de privacidad

- Permitidos: título/fecha de entreno, ejercicio, catálogo, series, repeticiones, cargas, RIR, formato y puntuación WOD.
- Excluidos: HealthKit, sueño, FC, calorías de Apple Salud, peso corporal, fertilidad/ciclo, GPS/rutas, notas libres y perfiles fiscales.
- No copiar datos sanitarios ni `service_role` en OAuth/MCP.
- La fatiga que resulte de series/tiempo es **estimación deportiva** y no indica un diagnóstico o recuperación medida.
- Priorizar informes agregados y datos mínimos: el agente nunca necesita un volcado completo de la cuenta por defecto.

## 6. Comprobaciones previas a merge

- `swift test` y build iOS 27 con Xcode.
- Test en dispositivo con historial antiguo y carga nueva, internet intermitente y dos identidades Apple.
- Pruebas SQL: usuario A vs B, cliente OAuth no autorizado, cliente revocado, prohibición de OAuth UPDATE/INSERT.
- `get_advisors(security)` y documentación actualizada; no desactivar alertas.
- Refrescar el esquema de migraciones pendientes anteriores de Business en staging antes de reproducir producción.
