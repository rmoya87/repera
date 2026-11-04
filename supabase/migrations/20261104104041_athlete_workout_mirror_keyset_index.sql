-- Sync del espejo sin tope: listado por (owner_id, id) y descarga de payload por id.
-- Índice cubriente: el listado ligero (id, deleted_at) no toca el heap con payloads grandes.
create index if not exists athlete_workout_mirror_owner_id_keyset_idx
  on public.athlete_workout_mirror(owner_id, id) include (deleted_at);
