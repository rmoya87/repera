-- PT: aceptar clases de gym asignadas + billing_model en tarifas (sin Stripe).

alter table public.service_occurrences
  add column if not exists coach_ack text not null default 'accepted'
  check (coach_ack in ('pending','accepted','declined'));

alter table public.business_pass_offers
  add column if not exists billing_model text not null default 'session_pack'
  check (billing_model in ('session_pack','monthly','unlimited'));

-- Al crear clase con coach distinto del actor → pendiente de aceptar.
create or replace function private.mark_coach_ack_pending()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if new.coach_user_id is distinct from auth.uid()
     and new.kind='class'
     and tg_op='INSERT' then
    new.coach_ack := 'pending';
  end if;
  return new;
end $$;
drop trigger if exists service_occurrence_coach_ack on public.service_occurrences;
create trigger service_occurrence_coach_ack
 before insert on public.service_occurrences
 for each row execute function private.mark_coach_ack_pending();

create or replace function public.list_my_coach_assignments()
returns table(
  id uuid, org_id uuid, org_name text, title text, starts_at timestamptz,
  ends_at timestamptz, status text, coach_ack text, capacity int, kind text
) language sql stable security definer set search_path='' as $$
  select o.id, o.org_id, org.name, o.title, o.starts_at, o.ends_at, o.status,
         o.coach_ack, o.capacity, o.kind
  from public.service_occurrences o
  join public.organizations org on org.id=o.org_id
  where o.coach_user_id=auth.uid()
    and o.status='active'
    and org.kind in ('gym','sports_center')
    and private.has_org_role(o.org_id, array['owner','admin','coach']::public.organization_role[])
  order by o.starts_at asc
  limit 200;
$$;
revoke all on function public.list_my_coach_assignments() from public,anon;
grant execute on function public.list_my_coach_assignments() to authenticated;

create or replace function public.coach_ack_occurrence(p_occurrence uuid, p_ack text)
returns void language plpgsql security definer set search_path='' as $$
declare v_row public.service_occurrences%rowtype;
begin
  if auth.uid() is null or p_ack not in ('accepted','declined') then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  select * into v_row from public.service_occurrences where id=p_occurrence for update;
  if not found or v_row.coach_user_id is distinct from auth.uid() then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  if not private.has_org_role(v_row.org_id, array['owner','admin','coach']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  update public.service_occurrences
     set coach_ack=p_ack,
         status=case when p_ack='declined' then 'cancelled' else status end
   where id=p_occurrence;
end $$;
revoke all on function public.coach_ack_occurrence(uuid,text) from public,anon;
grant execute on function public.coach_ack_occurrence(uuid,text) to authenticated;

-- Ampliar check de créditos en ofertas si existía tope 1000 vía constraint de app;
-- la tabla no limita credits en SQL habitualmente.
