# Catálogo remoto incremental de ejercicios

Última actualización: 2026-11-05 (ficha iOS: copy vía `CatalogSpanish.resolved*` prioriza campos del `Exercise` mergeado; `CatalogSeedHydration` no pisa textos/`artKeys` remotos). **Autoridad viva = Supabase**; `Catalog.seed()` solo bootstrap. Payload canónico ampliado (`skill_level`, `movement_pattern`, `alternatives`, `art_keys`) + bucket Storage `exercise-art`. Merge en `RemoteExerciseCatalogMerge`. Sync invisible (BGAppRefresh / WorkManager). **`mobile_art_keys` en las 476 fichas activas** (`292000` backfill + `290000` E/F/G); textos ES/HL (`213000`/`215500`); Aducción→Piernas (`291000`). Proyecto `uvzgujlrqohreoucirms`. Enriquecimiento: [CATALOG_OPEN_SOURCES.md](CATALOG_OPEN_SOURCES.md).

## Contrato de autoridad

| Capa | Rol |
|------|-----|
| `Catalog.seed()` | Bootstrap offline / primera instalación. **No** es requisito para publicar altas o correcciones. |
| `business_exercise_catalog` + `training_exercise_metadata` | Fuente editorial viva (escritura admin/SQL). |
| `mobile_exercise_catalog_events` | Feed incremental de solo lectura para apps autenticadas. |
| `exercise_catalog_remote_v1.json` | Caché en disco; usable sin cobertura tras sync. |

Campos canónicos en el feed (arrays/textos estables en SQL; la app transforma a UI):

| Payload | Origen SQL | Uso en app |
|---------|------------|------------|
| `aliases`, `primary_muscles`, `secondary_muscles`, `equipment` | `training_exercise_metadata` | búsqueda, taxonomía, string de equipo |
| `equipment_override` | `business_exercise_catalog.mobile_equipment` | material visible preciso |
| `description`, `instructions`, `body_part`, `muscle_group`, `sport_tag` | `mobile_*` | ficha / biblioteca |
| `skill_level`, `movement_pattern`, `alternatives` | metadata | nivel, patrón, sustitutos editoriales |
| `art_keys` | `mobile_art_keys` | stems JPG (hero + frames); vacío = nameMap del binario |

Publicados no vacíos **pisan** el seed; `null`/vacío no borra. Altas nuevas → UUID estable + caché offline. Logging (kg×reps…) sigue **derivado** en la app a partir de nombre/equipo.

**Textos de ficha (iOS):** `ExerciseCopy` / carrusel usan `CatalogSpanish.resolvedDescription` y `resolvedInstructions`: primero `detailDescription` / `instructions` del `Exercise` (tras merge remoto), y solo si están vacíos el diccionario embebido. Android ya lee esos campos del catálogo mergeado. La hidratación del seed (`CatalogSeedHydration` / `mergeCatalogOffMain`) **no** sobrescribe copy, `artKeys`, skill/patrón ni alternatives ya presentes.

**Arte remoto:** bucket público `exercise-art` (`{stem}.jpg`). Apps prefetch a disco (`ExerciseArtRemote` / `exercise-art-remote`) tras sync **aunque el stem exista en el binario** (OTA no queda bloqueada). En listas/thumbs la UI **prioriza el JPG remoto en disco** frente al empaquetado.

Publicar **no** exige App Store. Subir JPG nuevos al bucket + `mobile_art_keys` en SQL basta para arte de altas nuevas (tras aplicar la migración). CMS: fuera de alcance.

## Fuente editorial

La fuente de datos es `public.business_exercise_catalog` unida a `public.training_exercise_metadata`, **no** otro catálogo nuevo. La migración `20261024223050_mobile_exercise_catalog_events.sql` (y `…equipment_override`) añade campos `mobile_*` y el registro `public.mobile_exercise_catalog_events`.

La tabla de eventos es de **solo lectura para clientes autenticados** (RLS). No se autorizan INSERT/UPDATE/DELETE desde la app, ni se distribuyen claves de servicio. Dos triggers publican revisión monotónica `id`, con `catalog_key`, `operation=upsert|delete` y `payload`. `is_active=false` o borrado editorial → lápida.

## Flujo offline-first (iPhone / Android)

1. Inicio: hidratar JSON personal + `Catalog.seed()` si hace falta. Ni red ni Supabase bloquean el arranque.
2. Tras iCloud (iOS): `restoreCached` aplica `exercise_catalog_remote_v1.json` sobre el seed.
3. Sync **invisible** (background + primer plano/login, sin botón): probe de `max(id)`; si no cambió, no descarga páginas (sí puede reaplicar caché).
4. Si el cursor es 0 o el lag es **> 300** eventos: RPC `mobile_exercise_catalog_bootstrap()` (1 round-trip con el estado canónico de ~476 fichas + `revision`). Si el lag es pequeño: páginas de **500** eventos. Solo tras completar se escribe el snapshot atómico y avanza el cursor.
5. `RemoteExerciseCatalogMerge` actualiza fichas sin cambiar UUID, favoritos, rutinas, sesiones ni récords.
6. Bajas → `isCatalogArchived=true` (ocultas en UI; historial sigue resolviendo).
7. Sin Internet / sin cuenta / error → se conserva caché + seed; no se borra información.

**Rendimiento:** I/O en actor/`AtomicFile`; merge off MainActor; BGAppRefresh oportunista (iOS) / WorkManager (Android). La caché remota **no** contiene entrenamientos ni Salud.

## Runbook SQL (publicación sin App Store)

Sesión administrativa / `service_role` o rol con escritura en tablas editoriales (nunca desde la app).

### Alta completa

Insertar la **misma** `catalog_key` inmutable en ambas tablas, con payload usable sin seed:

```sql
-- Ejemplo: sustituir valores; no reutilizar una clave archivada para otro movimiento.
insert into public.business_exercise_catalog (
  catalog_key, name, category, display_name_en,
  mobile_description, mobile_instructions,
  mobile_body_part, mobile_muscle_group, mobile_sport_tag,
  mobile_equipment, mobile_art_keys, is_active
) values (
  'catalog:Nuevo movimiento',
  'Nuevo movimiento',
  'Fuerza',
  'New Movement',
  'Descripción visible en la ficha.',
  array['Paso 1', 'Paso 2'],
  'Pecho', 'Pecho', null,
  'Barra, Banco',
  array['art_nuevo_movimiento', 'art_nuevo_movimiento_1'],
  true
);

insert into public.training_exercise_metadata (
  catalog_key, aliases, primary_muscles, secondary_muscles, equipment,
  skill_level, movement_pattern, alternatives, native_catalog_id
) values (
  'catalog:Nuevo movimiento',
  array['alias buscable'],
  array['Pecho'],
  array['Tríceps'],
  array['Barra', 'Banco'],
  'intermediate',
  'push',
  array['Press banca'],
  null
);
-- Subir art_nuevo_movimiento.jpg (+ frames) al bucket Storage exercise-art.
```

El trigger emite `upsert`. Tras sync en background, la app cachea la ficha y la usa offline.

### Edición de campos

- Ficha / textos / `mobile_equipment` / `is_active`: `update business_exercise_catalog …`
- Aliases, músculos, equipo genérico, `native_catalog_id`: `update training_exercise_metadata …`
- Preferir `mobile_equipment` (va a `equipment_override` en el payload) para material visible preciso; el array `equipment` de metadatos también actualiza la ficha si no hay override (ya no lo bloquea el seed).

### Baja

```sql
update public.business_exercise_catalog
set is_active = false
where catalog_key = 'catalog:…';
```

No reutilizar la clave. Rehabilitar con `is_active = true` (nueva revisión).

### Checklist manual

1. Insert/update en SQL → fila nueva en `mobile_exercise_catalog_events`.
2. App autenticada con cobertura → background o volver a primer plano → ficha actualizada / nueva en biblioteca.
3. Modo avión → la ficha cacheada sigue usable.
4. Favoritos, UUID e historial intactos; archivado oculta en pickers.

Se requiere revisión anatómica editorial; los metadatos no están verificados clínicamente.

## Despliegue y pruebas

1. Esquema de eventos ya debe estar aplicado en el proyecto remoto (no redeploy automático en este cambio de contrato). Verificar SELECT autenticado del feed y denegación `anon`.
2. Cola serializada: páginas no saltan cambios concurrentes confirmados.
3. QA: primer fetch no cambia UUID; corrección de nombre/material/instrucciones; alta solo-remota; offline tras sync; >150 eventos; archivado/reactivación; iCloud + caché remota.
4. `swift test --filter RemoteExerciseCatalogTests` en ReperaDomain; instrumented Android `RemoteExerciseCatalogInstrumentedTest` (incl. equipo por array sin override).

**Paridad Android/Wear:** misma tabla y caché vía `RemoteExerciseCatalog` + `RemoteExerciseCatalogWorker`. Watch vía WatchConnectivity desde el iPhone (sin cliente Supabase propio).
