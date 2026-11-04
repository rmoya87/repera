-- Límite de uso MCP por token, propietario y herramienta (ventana fija). Solo service_role.

create schema if not exists private;

create table if not exists private.ai_mcp_rate_counters (
  key text primary key check (length(key) between 1 and 200),
  window_start timestamptz not null,
  hits int not null check (hits >= 0)
);
alter table private.ai_mcp_rate_counters enable row level security;
revoke all on private.ai_mcp_rate_counters from public, anon, authenticated;

create or replace function private.consume_ai_mcp_quota(
  p_keys text[], p_limits int[], p_windows int[], p_costs int[]
) returns int language plpgsql security definer set search_path='' as $$
declare
  n int := coalesce(array_length(p_keys, 1), 0);
  v_hits int;
  v_start timestamptz;
  v_retry int := 0;
begin
  if n = 0 or n > 20
     or n <> coalesce(array_length(p_limits, 1), 0)
     or n <> coalesce(array_length(p_windows, 1), 0)
     or n <> coalesce(array_length(p_costs, 1), 0) then
    raise exception 'INVALID_QUOTA' using errcode='22023';
  end if;
  for i in 1..n loop
    if p_keys[i] is null or length(p_keys[i]) not between 1 and 200
       or p_limits[i] is null or p_limits[i] not between 1 and 100000
       or p_windows[i] is null or p_windows[i] not between 1 and 86400
       or p_costs[i] is null or p_costs[i] not between 1 and 100 then
      raise exception 'INVALID_QUOTA' using errcode='22023';
    end if;
    insert into private.ai_mcp_rate_counters as c (key, window_start, hits)
    values (p_keys[i], now(), p_costs[i])
    on conflict (key) do update set
      hits = case when c.window_start + make_interval(secs => p_windows[i]) <= now()
                  then p_costs[i] else c.hits + p_costs[i] end,
      window_start = case when c.window_start + make_interval(secs => p_windows[i]) <= now()
                          then now() else c.window_start end
    returning c.hits, c.window_start into v_hits, v_start;
    if v_hits > p_limits[i] then
      v_retry := greatest(
        v_retry,
        ceil(extract(epoch from (v_start + make_interval(secs => p_windows[i]) - now())))::int,
        1
      );
    end if;
  end loop;
  return v_retry;
end $$;
revoke all on function private.consume_ai_mcp_quota(text[],int[],int[],int[]) from public, anon, authenticated;
grant execute on function private.consume_ai_mcp_quota(text[],int[],int[],int[]) to service_role;

create or replace function public.consume_ai_mcp_quota(
  p_keys text[], p_limits int[], p_windows int[], p_costs int[]
) returns int language sql security definer set search_path='' as $$
  select private.consume_ai_mcp_quota(p_keys, p_limits, p_windows, p_costs)
$$;
revoke all on function public.consume_ai_mcp_quota(text[],int[],int[],int[]) from public, anon, authenticated;
grant execute on function public.consume_ai_mcp_quota(text[],int[],int[],int[]) to service_role;

-- Consultas de get_professional_schedule (clients.user_id ya se usa en RLS).
create index if not exists clients_user_status_idx on public.clients(user_id, status) where user_id is not null;
create index if not exists service_bookings_client_status_idx on public.service_bookings(client_id, status);
