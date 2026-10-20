# Sincronización privada de entrenamientos · Repera iOS + Supabase + Business

Implementación en `feat/repera-light-structured-training`. Migración real `20261020080139_athlete_workout_mirror_consent.sql`.

## Qué hace

1. Un usuario se autentica en Supabase con su **misma** identidad Apple. La app recupera primero local/iCloud y después sincroniza los entrenamientos **terminados** con su cuenta personal de Supabase, conservando los UUID originales. No sube sesiones incompletas ni durante una recuperación de iCloud todavía incierta.
2. Una cuenta antigua que solo tenía Apple/iCloud se vincula a Supabase mediante token Apple nuevo y nonce. La primera sincronización incorpora los entrenos históricos en lotes. Cada subida guarda su huella local para enviar posteriores modificaciones únicamente cuando cambian, y para evitar sobreescribir automáticamente con una copia obsoleta de otro dispositivo.
3. Un dispositivo nuevo descarga sesiones desconocidas y las añade a su historial local **sin sustituir** entrenos ya guardados. La app y iCloud siguen siendo el sistema principal del historial personal; ante un conflicto no se sobrescribe silenciosamente.
4. Una eliminación deja una marca persistente en cola local y una *tombstone* en Supabase, en vez de borrar físicamente el servidor; así evita revivir el entreno borrado desde otro dispositivo. Sin conexión, la cola se reintenta.
5. Por privacidad no se suben notas personales, valoración subjetiva, calorías medidas por Salud, identificadores HealthKit, ubicación ni ruta GPS; se sincronizan ejercicios, series, marcas, WOD y duración relevante. Los entrenos personales completos permanecen en iCloud. El espejo no es una exportación completa de HealthKit.

## Qué ve un gimnasio/entrenador

- **Por defecto nada**: RLS permite consultar `athlete_workout_mirror` únicamente al propietario. Aceptar una invitación de un gimnasio no comparte automáticamente el historial.
- En **Ajustes → Sincronización y privacidad de entrenamientos**, el deportista puede activar por separado «Compartir resultados con [centro]» y revocar cuando quiera. Solo puede consentir en organizaciones donde tenga vínculo activo como deportista y ficha de cliente vinculada a su usuario.
- La RPC `get_shared_athlete_results` verifica organización, entrenador asignado o propietario/administrador activo, cliente realmente vinculado y consentimiento actual. Solo devuelve resúmenes de ejercicios, series y puntuaciones WOD; **nunca la sesión íntegra ni información de Salud o GPS**.
- En el panel Business se accede a «Ver resultados» de un cliente vinculado; si no ha compartido o no tiene entrenos, no muestra nada. La revocación actúa inmediatamente.

## Seguridad y pruebas

- Tablas de mirror y consentimiento con RLS habilitada; solo `authenticated` puede leer/escribir datos propios. Sin INSERT/UPDATE/DELETE de otros deportistas, sin `service_role` en iOS/web.
- RPC `SECURITY DEFINER` está en `private`, wrapper expuesto `SECURITY INVOKER`. No concede SELECT de la tabla a empleados.
- `supabase/tests/workout_mirror_consent_smoke.sql` verifica lectura propia, denegación por defecto, opt-in, campos excluidos, tercero ajeno y revocación con usuarios ficticios y ROLLBACK. Ejecutado sobre Repera con resultado `workout_private_consent_rls_pass`; cero usuarios de prueba persistidos.
- Pendiente de validación E2E real: iPhone A/B, Watch, iCloud con modificaciones simultáneas, errores de red, borrado offline, revocación durante una lectura, rotación de sesión y distintos husos horarios.
- Los registros históricos locales anteriores siguen intactos si el primer enlace a Supabase o cualquier petición de red falla.

## Limitaciones

No se asignan automáticamente resultados a una sesión concreta del plan del entrenador hasta que el deportista ejecute una prescripción desde Diario; los resultados compartidos son por deportista y fecha, no una vinculación fiable por ID de sesión profesional. Tampoco se refleja en el perfil médico o Salut de Supabase. Sin E2E de dispositivos no presentar esta funcionalidad como garantía de backup total.
