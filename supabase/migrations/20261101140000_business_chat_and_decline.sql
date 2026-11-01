-- Chat 1:1 atleta↔ negocio, avisos masivos y rechazo de invitación por el atleta.
-- No incluye Stripe ni push remoto.

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
create index if not exists business_messages_batch_idx
  on public.business_conversation_messages(org_id, batch_id)
  where batch_id is not null;
create index if not exists business_messages_unread_idx
  on public.business_conversation_messages(org_id, client_id, created_at desc)
  where read_at is null;

alter table public.business_conversation_messages enable row level security;
revoke all on public.business_conversation_messages from public, anon, authenticated;
grant select on public.business_conversation_messages to authenticated;

create policy business_messages_read on public.business_conversation_messages
 for select to authenticated using (
  private.has_org_role(org_id, array['owner','admin','coach','reception']::public.organization_role[])
  or private.owns_org_client(org_id, client_id)
 );

-- ---- list thread ----
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
create or replace function public.business_list_thread(
  p_org uuid, p_client uuid, p_before timestamptz default null, p_limit int default 50
) returns setof public.business_conversation_messages
language sql security invoker set search_path='' as $$
  select * from private.business_list_thread(p_org, p_client, p_before, p_limit)
$$;
revoke all on function public.business_list_thread(uuid,uuid,timestamptz,int) from public,anon;
grant execute on function public.business_list_thread(uuid,uuid,timestamptz,int) to authenticated;

-- ---- send 1:1 ----
create or replace function private.business_send_message(
  p_org uuid, p_client uuid, p_body text
) returns uuid language plpgsql security definer set search_path='' as $$
declare
  v_actor uuid := auth.uid();
  v_body text := btrim(coalesce(p_body,''));
  v_role text;
  v_id uuid;
begin
  if v_actor is null or length(v_body) not between 1 and 2000 then
    raise exception 'INVALID_MESSAGE' using errcode='22023';
  end if;
  if not exists (
    select 1 from public.clients c
    where c.id=p_client and c.org_id=p_org and c.status='active' and c.user_id is not null
      and c.account_deleted_at is null
  ) then raise exception 'CLIENT_UNAVAILABLE' using errcode='22023'; end if;

  if private.owns_org_client(p_org, p_client)
     and private.has_org_role(p_org, array['athlete']::public.organization_role[]) then
    v_role := 'athlete';
  elsif private.has_org_role(p_org, array['owner','admin','coach','reception']::public.organization_role[]) then
    v_role := 'staff';
  else
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;

  insert into public.business_conversation_messages(
    org_id, client_id, sender_user_id, sender_role, body
  ) values (p_org, p_client, v_actor, v_role, v_body)
  returning id into v_id;
  return v_id;
end $$;
revoke all on function private.business_send_message(uuid,uuid,text) from public,anon,authenticated;
grant execute on function private.business_send_message(uuid,uuid,text) to authenticated;
create or replace function public.business_send_message(p_org uuid, p_client uuid, p_body text)
returns uuid language sql security invoker set search_path='' as $$
  select private.business_send_message(p_org, p_client, p_body)
$$;
revoke all on function public.business_send_message(uuid,uuid,text) from public,anon;
grant execute on function public.business_send_message(uuid,uuid,text) to authenticated;

-- ---- broadcast ----
create or replace function private.business_send_broadcast(
  p_org uuid,
  p_body text,
  p_all_active boolean default false,
  p_client_ids uuid[] default null,
  p_occurrence uuid default null,
  p_group uuid default null
) returns uuid language plpgsql security definer set search_path='' as $$
declare
  v_actor uuid := auth.uid();
  v_body text := btrim(coalesce(p_body,''));
  v_batch uuid := gen_random_uuid();
  v_targets uuid[];
  v_recent int;
begin
  if v_actor is null
     or not private.has_org_role(p_org, array['owner','admin','coach']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  if length(v_body) not between 1 and 2000 then
    raise exception 'INVALID_MESSAGE' using errcode='22023';
  end if;

  select count(*) into v_recent
  from public.business_conversation_messages m
  where m.org_id=p_org and m.sender_user_id=v_actor and m.batch_id is not null
    and m.created_at > now() - interval '2 minutes';
  if v_recent > 500 then
    raise exception 'RATE_LIMITED' using errcode='54000';
  end if;

  if p_all_active then
    select coalesce(array_agg(c.id), '{}') into v_targets
    from public.clients c
    where c.org_id=p_org and c.status='active' and c.user_id is not null
      and c.account_deleted_at is null;
  elsif p_occurrence is not null then
    if not exists (
      select 1 from public.service_occurrences o where o.id=p_occurrence and o.org_id=p_org
    ) then raise exception 'OCCURRENCE_NOT_FOUND' using errcode='22023'; end if;
    select coalesce(array_agg(distinct b.client_id), '{}') into v_targets
    from public.service_bookings b
    where b.occurrence_id=p_occurrence and b.org_id=p_org
      and b.status in ('booked','attended');
  elsif p_group is not null then
    select coalesce(array_agg(distinct gm.client_id), '{}') into v_targets
    from public.business_training_group_members gm
    join public.business_training_groups g on g.id=gm.group_id
    where gm.group_id=p_group and g.org_id=p_org;
  elsif p_client_ids is not null and cardinality(p_client_ids) > 0 then
    if cardinality(p_client_ids) > 200 then
      raise exception 'TOO_MANY_RECIPIENTS' using errcode='22023';
    end if;
    select coalesce(array_agg(c.id), '{}') into v_targets
    from public.clients c
    where c.org_id=p_org and c.id = any(p_client_ids)
      and c.status='active' and c.user_id is not null and c.account_deleted_at is null;
  else
    raise exception 'NO_RECIPIENTS' using errcode='22023';
  end if;

  if v_targets is null or cardinality(v_targets)=0 then
    raise exception 'NO_RECIPIENTS' using errcode='22023';
  end if;

  insert into public.business_conversation_messages(
    org_id, client_id, sender_user_id, sender_role, body, batch_id, occurrence_id, group_id
  )
  select p_org, t, v_actor, 'staff', v_body, v_batch, p_occurrence, p_group
  from unnest(v_targets) as t;

  return v_batch;
end $$;
revoke all on function private.business_send_broadcast(uuid,text,boolean,uuid[],uuid,uuid)
  from public,anon,authenticated;
grant execute on function private.business_send_broadcast(uuid,text,boolean,uuid[],uuid,uuid)
  to authenticated;
create or replace function public.business_send_broadcast(
  p_org uuid,
  p_body text,
  p_all_active boolean default false,
  p_client_ids uuid[] default null,
  p_occurrence uuid default null,
  p_group uuid default null
) returns uuid language sql security invoker set search_path='' as $$
  select private.business_send_broadcast(p_org,p_body,p_all_active,p_client_ids,p_occurrence,p_group)
$$;
revoke all on function public.business_send_broadcast(uuid,text,boolean,uuid[],uuid,uuid)
  from public,anon;
grant execute on function public.business_send_broadcast(uuid,text,boolean,uuid[],uuid,uuid)
  to authenticated;

-- ---- mark read ----
create or replace function private.business_mark_thread_read(p_org uuid, p_client uuid)
returns int language plpgsql security definer set search_path='' as $$
declare v_n int; v_actor uuid:=auth.uid(); v_as_athlete boolean;
begin
  if v_actor is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
  v_as_athlete := private.owns_org_client(p_org, p_client);
  if not (
    v_as_athlete
    or private.has_org_role(p_org, array['owner','admin','coach','reception']::public.organization_role[])
  ) then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;

  -- Athlete marks staff messages; staff marks athlete messages.
  update public.business_conversation_messages m
  set read_at = now()
  where m.org_id=p_org and m.client_id=p_client and m.read_at is null
    and (
      (v_as_athlete and m.sender_role='staff')
      or (not v_as_athlete and m.sender_role='athlete')
    );
  get diagnostics v_n = row_count;
  return v_n;
end $$;
revoke all on function private.business_mark_thread_read(uuid,uuid) from public,anon,authenticated;
grant execute on function private.business_mark_thread_read(uuid,uuid) to authenticated;
create or replace function public.business_mark_thread_read(p_org uuid, p_client uuid)
returns int language sql security invoker set search_path='' as $$
  select private.business_mark_thread_read(p_org, p_client)
$$;
revoke all on function public.business_mark_thread_read(uuid,uuid) from public,anon;
grant execute on function public.business_mark_thread_read(uuid,uuid) to authenticated;

-- Inbox summary for athlete (latest per org)
create or replace function public.business_my_message_inbox(p_limit int default 40)
returns table (
  org_id uuid,
  org_name text,
  client_id uuid,
  last_body text,
  last_at timestamptz,
  unread_count bigint
) language plpgsql security definer set search_path='' as $$
declare v_actor uuid:=auth.uid(); v_limit int:=least(greatest(coalesce(p_limit,40),1),100);
begin
  if v_actor is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
  return query
  with mine as (
    select c.org_id, c.id as client_id, o.name as org_name
    from public.clients c
    join public.organizations o on o.id=c.org_id
    where c.user_id=v_actor and c.status='active' and c.account_deleted_at is null
  ),
  last_msg as (
    select distinct on (m.org_id, m.client_id)
      m.org_id, m.client_id, m.body, m.created_at
    from public.business_conversation_messages m
    join mine x on x.org_id=m.org_id and x.client_id=m.client_id
    order by m.org_id, m.client_id, m.created_at desc
  ),
  unread as (
    select m.org_id, m.client_id, count(*)::bigint as n
    from public.business_conversation_messages m
    join mine x on x.org_id=m.org_id and x.client_id=m.client_id
    where m.read_at is null and m.sender_role='staff'
    group by m.org_id, m.client_id
  )
  select mine.org_id, mine.org_name, mine.client_id,
         coalesce(last_msg.body,''), last_msg.created_at,
         coalesce(unread.n,0)
  from mine
  left join last_msg on last_msg.org_id=mine.org_id and last_msg.client_id=mine.client_id
  left join unread on unread.org_id=mine.org_id and unread.client_id=mine.client_id
  where last_msg.created_at is not null or coalesce(unread.n,0)>0
  order by coalesce(last_msg.created_at, '-infinity'::timestamptz) desc
  limit v_limit;
end $$;
revoke all on function public.business_my_message_inbox(int) from public,anon;
grant execute on function public.business_my_message_inbox(int) to authenticated;

-- ---- athlete declines invitation (cancel as recipient) ----
create or replace function private.decline_org_invitation(p_invitation_id uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare v_inv public.organization_invitations%rowtype; v_actor uuid:=auth.uid();
begin
  if v_actor is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
  select * into v_inv from public.organization_invitations where id=p_invitation_id for update;
  if not found then raise exception 'INVITATION_NOT_FOUND' using errcode='P0002'; end if;
  if not private.is_verified_invitation_recipient(v_inv.email) then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  if v_inv.accepted_at is not null or v_inv.cancelled_at is not null then
    return false;
  end if;
  if v_inv.expires_at < now() then
    update public.organization_invitations set cancelled_at=now() where id=p_invitation_id;
    return false;
  end if;
  update public.organization_invitations set cancelled_at=now() where id=p_invitation_id;
  return true;
end $$;
revoke all on function private.decline_org_invitation(uuid) from public,anon,authenticated;
grant execute on function private.decline_org_invitation(uuid) to authenticated;
create or replace function public.decline_org_invitation(p_invitation_id uuid)
returns boolean language sql security invoker set search_path='' as $$
  select private.decline_org_invitation(p_invitation_id)
$$;
revoke all on function public.decline_org_invitation(uuid) from public,anon;
grant execute on function public.decline_org_invitation(uuid) to authenticated;
