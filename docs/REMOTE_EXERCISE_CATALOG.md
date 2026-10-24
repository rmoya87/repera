# Catálogo remoto incremental de ejercicios

Última actualización: 2026-10-25. Implementación inicial para iPhone. **El deploy SQL y las pruebas de dispositivo se verifican por separado.**

## Fuente editorial

La fuente de datos es `public.business_exercise_catalog` unida a `public.training_exercise_metadata`, **no** otro catálogo nuevo. La migración `20261025003000_mobile_exercise_catalog_events.sql` añade campos opcionales de descripción, instrucciones, grupo, parte corporal y disciplina a la tabla editorial y un registro de eventos `public.mobile_exercise_catalog_events`.

La tabla de eventos es de **solo lectura para clientes autenticados** (RLS). No se autorizan INSERT/UPDATE/DELETE desde la app, ni se distribuyen claves de servicio. Dos triggers (cambios en ficha o metadatos) publican una revisión monotónica `id`, con `catalog_key`, `operation=upsert|delete` y `payload` del ejercicio. `is_active=false` o el borrado editorial generan una lápida. La migración publica una instantánea inicial para todas las claves existentes.

## Flujo offline-first iPhone

1. Inicio: `ReperaStore` hidrata el JSON personal y, como respaldo de primera instalación sin Internet, las fichas empaquetadas en `Catalog.seed()`. Ni red ni Supabase bloquean el arranque.
2. Después de recuperar iCloud, `RemoteExerciseCatalogStore.restoreCached` superpone la última instantánea remota persistida en Application Support (`exercise_catalog_remote_v1.json`).
3. Con una sesión de Supabase válida, se consulta **una fila** (`max(id)` mediante orden descendente y límite 1). Si no cambió, no se descarga el catálogo.
4. Si hay revisión posterior, se solicitan **solo los eventos nuevos** en páginas de 150 (`id > cursor` y `id <= revisionObjetivo`, orden ascendente). Solo tras recibir todas las páginas se escribe de forma atómica el snapshot y se avanza el cursor.
5. Se actualizan fichas sin cambiar UUID locales, favoritos, rutinas, sesiones ni récords. Las claves `catalog_key` se mantienen aunque cambie el nombre; para adopción inicial también se reconoce el nombre histórico en `catalog:NombreAnterior` y `native_catalog_id`.
6. Las bajas se marcan `isCatalogArchived=true`: desaparecen de biblioteca y selectores compartidos, pero las referencias históricas permanecen y siguen decodificándose. El reloj recibe el contexto actualizado de la sesión desde el iPhone.
7. En el primer plano se restaura la caché tras iCloud y se vuelve a comprobar la revisión remota. Sin Internet, sin cuenta Supabase o ante un error se conserva la copia local sin borrar información.

La caché remota **no** contiene entrenamientos ni datos de Salud. La sincronización del catálogo **no** es una sincronización de historias de usuario.

## Publicar cambios editoriales (sin nuevas versiones)

Con una sesión administrativa autorizada y un canal seguro de escritura a base de datos:

- Para corregir metadatos: actualizar `training_exercise_metadata`. Para el nombre, disciplina y campos de la ficha: actualizar `business_exercise_catalog`.
- Para publicar un ejercicio nuevo: insertar en **ambas** tablas con la **misma clave inmutable** `catalog_key`, nombre y categoría, principales/secundarios, equipo y, preferentemente, `mobile_description` y `mobile_instructions`. No crear dos claves para la misma variante. El trigger emite el cambio al instante.
- Para retirar un ejercicio: cambiar `business_exercise_catalog.is_active` a `false`. No reutilizar su clave en otro movimiento. Para rehabilitarlo volver a `true` (genera nueva revisión).
- Las instrucciones existentes del catálogo Swift se utilizan como respaldo mientras `mobile_description` / `mobile_instructions` sean NULL/vacías. Conviene trasladarlas gradualmente y verificar su fidelidad antes de dejar de empaquetar un seed.
- Se requiere revisión anatómica editorial; los metadatos antiguos representan el catálogo de Repera y no están verificados clínicamente.

## Despliegue y pruebas

1. Ejecutar migración SQL antes de distribuir la nueva aplicación. Verificar que la cuenta autenticada puede hacer SELECT del feed y que `anon` no puede. Comprobar 287 fichas iniciales o el recuento vigente antes del deploy.
2. iPhone con historial y favoritos: comprobar que el primer fetch no cambia UUID, que corregir nombre/material/instrucciones refleja el cambio y que los récords se conservan.
3. Probar sin conexión, reinstalación, segunda apertura sin cambios (una consulta ligera), actualización de más de 150 registros, renombrado de una clave estable, archivado y reactivación.
4. Probar iCloud restaurado de otro dispositivo (la caché remota debe prevalecer), inicio sin cuenta, cambio de sesión y fallo de Supabase.
5. Regenerar XcodeGen por el nuevo archivo Swift. Ejecutar `swift test` en ReperaDomain, compilar iOS/watchOS, hacer QA en iPhone y Apple Watch reales. No asumir compilación ni E2E con base de datos por el mero hecho de fusionar la rama.

**Paridad Android/Wear:** la rama Android se mantiene separada. La API SQL de eventos es consumible por Android, pero no se declara integrada hasta disponer de su propia caché y pruebas. El Watch no consulta el catálogo completo en la nube: mantiene su flujo nativo mediante WatchConnectivity desde el iPhone.
