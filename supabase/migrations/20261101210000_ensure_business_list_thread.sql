-- Reexpone business_list_thread / send / mark_read por si la migración de chat
-- no llegó al schema cache de PostgREST (error típico en ficha → Mensajes).

create table if not exists public.business_conversation_messages (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  client_id uuid not null,
  sender_user_id uuid not null references auth.users(id),
  sender_role text not null check (sender_role in ('athlete','staff')),
  body text not null check (length(btrim(body)) between 1 and 2000),
  created_at timestamptz not null default now(),
  read_at timestamptz,
  batch_id uuid,
  occurrence_id uuid references public.service_occurrences(id) on delete set null,
  group_id uuid,
  foreign key (org_id, client_id) references public.clients(org_id, id) on delete cascade
);
create index if not exists business_messages_thread_idx
  on public.business_conversation_messages(org_id, client_id, created_at desc);

alter table public.business_conversation_messages enable row level security;
revoke all on public.business_conversation_messages from public, anon, authenticated;
grant select on public.business_conversation_messages to authenticated;

drop policy if exists business_messages_read on public.business_conversation_messages;
create policy business_messages_read on public.business_conversation_messages
 for select to authenticated using (
  private.has_org_role(org_id, array['owner','admin','coach','reception']::public.organization_role[])
  or private.owns_org_client(org_id, client_id)
 );

create or replace function private.business_list_thread(
  p_org uuid, p_client uuid, p_before timestamptz, p_limit int
) returns setof public.business_conversation_messages
language plpgsql security definer set search_path='' as $$
declare v_limit int := least(greatest(coalesce(p_limit, 50), 1), 100);
begin
  if auth.uid() is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
  if not (
    private.has_org_role(p_org, array['owner','admin','coach','reception']::public.organization_role[])
    or private.owns_org_client(p_org, p_client)
  ) then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
  return query
  select m.* from public.business_conversation_messages m
  where m.org_id = p_org and m.client_id = p_client
    and (p_before is null or m.created_at < p_before)
  order by m.created_at desc
  limit v_limit;
end $$;
revoke all on function private.business_list_thread(uuid,uuid,timestamptz,int) from public,anon,authenticated;
grant execute on function private.business_list_thread(uuid,uuid,timestamptz,int) to authenticated;

drop function if exists public.business_list_thread(uuid,uuid,timestamptz,int);
create function public.business_list_thread(
  p_org uuid, p_client uuid, p_before timestamptz default null, p_limit int default 50
) returns setof public.business_conversation_messages
language sql security invoker set search_path='' as $$
  select * from private.business_list_thread(p_org, p_client, p_before, p_limit)
$$;
revoke all on function public.business_list_thread(uuid,uuid,timestamptz,int) from public,anon;
grant execute on function public.business_list_thread(uuid,uuid,timestamptz,int) to authenticated;

notify pgrst,'reload schema';
