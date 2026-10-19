-- REPera Business · SQL para un PROYECTO INDEPENDIENTE de Repera.
-- Migration 0002 is design-ready, NOT verified against a running Postgres yet.
-- NEVER execute against Cafesito or an existing production database.
begin;

create table public.notification_outbox (
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null,client_id uuid not null,
 kind text not null check(length(kind) between 1 and 80),
 body text not null check(length(body) between 1 and 500),
 deep_link text not null check(deep_link ~ '^repera://(today|diary|classes|passes)/[A-Za-z0-9-]+$'),
 state text not null default 'queued' check(state in ('queued','processing','sent','failed','cancelled')),
 attempts integer not null default 0 check(attempts between 0 and 30),
 created_at timestamptz not null default now(),
 foreign key (org_id,client_id) references public.clients(org_id,id)
);
create index on public.notification_outbox(org_id,state,created_at);
alter table public.notification_outbox enable row level security;
create policy notices_read on public.notification_outbox for select to authenticated
 using(public.can_manage_org(org_id) or public.is_linked_client(client_id));
-- No browser writes: push scheduling and dispatch need privileged functions + user notification preferences.

create or replace function public.is_booking_operator(_org uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select exists (select 1 from public.org_members m where m.org_id=_org and m.user_id=(select auth.uid())
   and m.status='active' and m.role in ('owner','manager','coach','reception'));
$$;
revoke all on function public.is_booking_operator(uuid) from public,anon;
grant execute on function public.is_booking_operator(uuid) to authenticated;

-- Transactional seat allocation; lock on the class row serializes all bookings/cancellations for that class.
-- Everything executes with authenticated actor context. No arbitrary elevated user switching.
create or replace function public.book_class(
 _org uuid,_class uuid,_client uuid,_request uuid
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
 v_actor uuid := (select auth.uid());v_class public.classes%rowtype;
 v_pass public.client_passes%rowtype;v_mode text;v_balance bigint;
 v_count bigint;v_booking uuid;v_result jsonb;v_scope text;
begin
 if v_actor is null or _request is null then raise exception 'AUTH_REQUIRED' using errcode='28000';end if;
 if not (public.is_booking_operator(_org) or exists(select 1 from public.clients c where c.id=_client and c.org_id=_org and c.user_id=v_actor))
 then raise exception 'NOT_AUTHORIZED' using errcode='42501';end if;
 v_scope:='class_booking:'||_org::text||':'||v_actor::text;
 -- Serialize idempotency checks + class transactions.
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_scope||':'||_request::text,0));
 select k.result into v_result from public.idempotency_keys k where k.scope=v_scope and k.key=_request::text;
 if found then return v_result;end if;
 select * into v_class from public.classes c where c.id=_class and c.org_id=_org for update;
 if not found then raise exception 'CLASS_NOT_FOUND';end if;
 if v_class.status<>'scheduled' or v_class.starts_at<=now() then raise exception 'CLASS_NOT_BOOKABLE';end if;
 if not exists(select 1 from public.clients c where c.id=_client and c.org_id=_org and c.status in ('trial','active'))
 then raise exception 'CLIENT_NOT_ACTIVE';end if;
 if exists(select 1 from public.class_bookings b where b.org_id=_org and b.class_id=_class and b.client_id=_client and b.status in ('confirmed','waitlist'))
 then raise exception 'ALREADY_BOOKED';end if;
 -- Lock pass row(s) before checking credits; prevents overspending across multiple class rows.
 select p.* into v_pass from public.client_passes p
 join public.products prod on prod.id=p.product_id and prod.org_id=p.org_id
 where p.org_id=_org and p.client_id=_client and p.status='active'
   and p.starts_on <= (v_class.starts_at at time zone (select o.timezone from public.organizations o where o.id=_org))::date
   and p.ends_on >= (v_class.starts_at at time zone (select o.timezone from public.organizations o where o.id=_org))::date
   and (prod.mode='unlimited' or (prod.mode='credits' and coalesce((select sum(l.delta) from public.credit_ledger l where l.pass_id=p.id),0)>0))
 order by p.ends_on,p.id limit 1 for update of p;
 if not found then raise exception 'NO_VALID_PASS';end if;
 select mode into v_mode from public.products where id=v_pass.product_id and org_id=_org;
 if v_mode='credits' then
   select coalesce(sum(delta),0) into v_balance from public.credit_ledger where pass_id=v_pass.id;
   if v_balance<1 then raise exception 'NO_CREDITS';end if;
 end if;
 select count(*) into v_count from public.class_bookings b where b.org_id=_org and b.class_id=_class and b.status in ('confirmed','attended','no_show');
 v_booking:=gen_random_uuid();
 insert into public.class_bookings(id,org_id,class_id,client_id,pass_id,status)
 values(v_booking,_org,_class,_client,v_pass.id,case when v_count < v_class.capacity then 'confirmed' else 'waitlist' end);
 if v_count < v_class.capacity and v_mode='credits' then
   insert into public.credit_ledger(org_id,pass_id,delta,event_type,event_key)
   values(_org,v_pass.id,-1,'booking','booking:'||v_booking::text);
 end if;
 v_result:=pg_catalog.jsonb_build_object('booking_id',v_booking,'status',case when v_count < v_class.capacity then 'confirmed' else 'waitlist' end);
 insert into public.idempotency_keys(scope,key,result) values(v_scope,_request::text,v_result);
 insert into public.audit_events(org_id,actor_id,action,resource_type,resource_id)
 values(_org,v_actor,'class.book','class_bookings',v_booking);
 return v_result;
end $$;
revoke all on function public.book_class(uuid,uuid,uuid,uuid) from public,anon;
grant execute on function public.book_class(uuid,uuid,uuid,uuid) to authenticated;

create or replace function public.cancel_class_booking(
 _org uuid,_booking uuid,_request uuid
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
 v_actor uuid:=(select auth.uid());v_class public.classes%rowtype;v_booking public.class_bookings%rowtype;
 v_next public.class_bookings%rowtype;v_pass public.client_passes%rowtype;v_mode text;v_balance bigint;
 v_result jsonb;v_scope text;v_date date;
begin
 if v_actor is null or _request is null then raise exception 'AUTH_REQUIRED' using errcode='28000';end if;
 v_scope:='booking_cancel:'||_org::text||':'||v_actor::text;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_scope||':'||_request::text,0));
 select k.result into v_result from public.idempotency_keys k where k.scope=v_scope and k.key=_request::text;
 if found then return v_result;end if;
 select * into v_booking from public.class_bookings b where b.org_id=_org and b.id=_booking;
 if not found then raise exception 'BOOKING_NOT_FOUND';end if;
 if not (public.is_booking_operator(_org) or exists(select 1 from public.clients c where c.id=v_booking.client_id and c.org_id=_org and c.user_id=v_actor))
 then raise exception 'NOT_AUTHORIZED' using errcode='42501';end if;
 select * into v_class from public.classes c where c.id=v_booking.class_id and c.org_id=_org for update;
 -- Acquiring the class lock before re-reading the booking prevents racing another cancellation / promotion.
 select * into v_booking from public.class_bookings b where b.org_id=_org and b.id=_booking for update;
 if v_booking.status not in ('confirmed','waitlist') then raise exception 'NOT_CANCELLABLE';end if;
 update public.class_bookings set status='cancelled',cancelled_at=now() where id=_booking;
 if v_booking.status='confirmed' then
   select * into v_pass from public.client_passes where id=v_booking.pass_id and org_id=_org for update;
   select mode into v_mode from public.products where id=v_pass.product_id and org_id=_org;
   if v_mode='credits' and exists(select 1 from public.credit_ledger where pass_id=v_pass.id and event_key='booking:'||_booking::text) then
     insert into public.credit_ledger(org_id,pass_id,delta,event_type,event_key)
     values(_org,v_pass.id,1,'booking_cancel','booking_cancel:'||_booking::text)
     on conflict (org_id,pass_id,event_key) do nothing;
   end if;
   v_date:=(v_class.starts_at at time zone (select o.timezone from public.organizations o where o.id=_org))::date;
   -- Skip no-longer-eligible waitlist members and promote first valid member.
   for v_next in select * from public.class_bookings b where b.org_id=_org and b.class_id=v_class.id and b.status='waitlist' order by b.created_at,b.id for update loop
     select * into v_pass from public.client_passes p where p.id=v_next.pass_id and p.org_id=_org and p.client_id=v_next.client_id
       and p.status='active' and p.starts_on<=v_date and p.ends_on>=v_date for update;
     if not found then continue;end if;
     select mode into v_mode from public.products where id=v_pass.product_id and org_id=_org;
     if v_mode='credits' then
       select coalesce(sum(delta),0) into v_balance from public.credit_ledger where pass_id=v_pass.id;
       if v_balance<1 then continue;end if;
       insert into public.credit_ledger(org_id,pass_id,delta,event_type,event_key)
       values(_org,v_pass.id,-1,'booking','booking:'||v_next.id::text)
       on conflict(org_id,pass_id,event_key) do nothing;
     elsif v_mode<>'unlimited' then continue;
     end if;
     update public.class_bookings set status='confirmed' where id=v_next.id;
     exit;
   end loop;
 end if;
 v_result:=pg_catalog.jsonb_build_object('booking_id',_booking,'status','cancelled');
 insert into public.idempotency_keys(scope,key,result) values(v_scope,_request::text,v_result);
 insert into public.audit_events(org_id,actor_id,action,resource_type,resource_id)
 values(_org,v_actor,'class.booking_cancel','class_bookings',_booking);
 return v_result;
end $$;
revoke all on function public.cancel_class_booking(uuid,uuid,uuid) from public,anon;
grant execute on function public.cancel_class_booking(uuid,uuid,uuid) to authenticated;

-- Harden columns and staff scope BEFORE connecting the real console.
-- No client (including org owners) can silently rebind a Stripe payout destination.
create or replace function public.prevent_sensitive_relinks()
returns trigger language plpgsql set search_path = '' as $$
begin
 if TG_TABLE_NAME='organizations' then
   if new.owner_id is distinct from old.owner_id
     or new.stripe_connect_account_id is distinct from old.stripe_connect_account_id
     or new.status is distinct from old.status
     or new.kind is distinct from old.kind then
     raise exception 'PROTECTED_ORGANIZATION_FIELD';
   end if;
 end if;
 if TG_TABLE_NAME='clients' and new.user_id is distinct from old.user_id then
   raise exception 'CLIENT_LINK_REQUIRES_VERIFICATION';
 end if;
 return new;
end $$;

-- Private client notes in a separate row to prevent billing staff receiving them with SELECT *.
create table public.client_private_notes (
 org_id uuid not null, client_id uuid not null, notes text not null default '',
 updated_at timestamptz not null default now(),primary key(org_id,client_id),
 foreign key (org_id,client_id) references public.clients(org_id,id) on delete cascade
);
insert into public.client_private_notes(org_id,client_id,notes)
 select org_id,id,private_notes from public.clients where private_notes is not null and private_notes<>'';
alter table public.clients drop column private_notes;
alter table public.client_private_notes enable row level security;
create policy private_notes_read on public.client_private_notes for select to authenticated
 using(public.can_manage_org(org_id));
create policy private_notes_write on public.client_private_notes for all to authenticated
 using(public.can_manage_org(org_id)) with check(public.can_manage_org(org_id));

create table public.staff_client_assignments (
 org_id uuid not null, coach_id uuid not null, client_id uuid not null,
 primary key(org_id,coach_id,client_id),
 foreign key(org_id,coach_id) references public.org_members(org_id,user_id) on delete cascade,
 foreign key(org_id,client_id) references public.clients(org_id,id) on delete cascade
);
alter table public.staff_client_assignments enable row level security;
create policy staff_client_read on public.staff_client_assignments for select to authenticated
 using(public.can_manage_org(org_id) or coach_id=(select auth.uid()));
create policy staff_client_write on public.staff_client_assignments for all to authenticated
 using(public.can_manage_org(org_id)) with check(public.can_manage_org(org_id));

create or replace function public.can_coach_client(_org uuid,_client uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.org_members m
 join public.staff_client_assignments a on a.org_id=m.org_id and a.coach_id=m.user_id
 where m.org_id=_org and a.client_id=_client and m.user_id=(select auth.uid())
   and m.status='active' and m.role='coach');
$$;
revoke all on function public.can_coach_client(uuid) from public,anon;
grant execute on function public.can_coach_client(uuid) to authenticated;

-- Billing and reception can consult business roster, but never private notes. Coaches see assigned clients only.
drop policy if exists client_read on public.clients;
create policy client_read on public.clients for select to authenticated
 using(user_id=(select auth.uid()) or public.can_manage_org(org_id)
   or public.can_coach_client(org_id,id)
   or exists(select 1 from public.org_members m where m.org_id=clients.org_id
      and m.user_id=(select auth.uid()) and m.status='active' and m.role in ('reception','billing')));
drop policy if exists assignments_read on public.program_assignments;
create policy assignments_read on public.program_assignments for select to authenticated
 using(public.can_manage_org(org_id) or public.can_coach_client(org_id,client_id) or public.is_linked_client(client_id));
-- A coach may view but must not modify plans until a server-side scoped endpoint checks assignment.

-- Enforce workout lineage: an athlete may only link to their own accepted org/client assignment.
create or replace function public.validate_athlete_workout_assignment()
returns trigger language plpgsql set search_path='' as $$
begin
 if new.assignment_id is not null and not exists(
   select 1 from public.program_assignments a
   join public.clients c on c.id=a.client_id and c.org_id=a.org_id
   where a.id=new.assignment_id and c.user_id=new.owner_id
 ) then raise exception 'ASSIGNMENT_NOT_OWNED';end if;
 return new;
end $$;
create trigger athlete_workout_assignment_owner before insert or update of assignment_id,owner_id
 on public.athlete_workout_entries for each row execute function public.validate_athlete_workout_assignment();
commit;