-- Repera Business v1: tenant-scoped schedule, reservations and distinct service credit wallets.
-- No payment capture or automatic subscription claims are implemented by this migration.
create table public.service_occurrences (
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null references public.organizations(id) on delete cascade,
 coach_user_id uuid not null,
 kind text not null check(kind in ('class','appointment')),
 title text not null check(length(btrim(title)) between 2 and 120),
 starts_at timestamptz not null,
 ends_at timestamptz not null,
 capacity int not null default 1 check(capacity between 1 and 200),
 status text not null default 'active' check(status in ('active','cancelled')),
 created_at timestamptz not null default now(),
 unique(org_id,id),
 foreign key (org_id,coach_user_id)
   references public.organization_memberships(organization_id,user_id),
 check(ends_at>starts_at and ends_at<=starts_at+interval '12 hours'),
 check(kind<>'appointment' or capacity=1)
);
create index service_occurrences_period_idx on public.service_occurrences(org_id,starts_at) where status='active';

create table public.service_passes (
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null,
 client_id uuid not null,
 kind text not null check(kind in ('class','appointment')),
 total_credits int not null check(total_credits between 1 and 1000),
 remaining_credits int not null check(remaining_credits>=0 and remaining_credits<=total_credits),
 valid_from timestamptz not null default now(),
 valid_until timestamptz not null,
 status text not null default 'active' check(status in ('active','paused','cancelled')),
 issued_by uuid not null references auth.users(id) on delete restrict,
 issuance_type text not null default 'complimentary' check(issuance_type='complimentary'),
 created_at timestamptz not null default now(),
 unique(org_id,id),
 foreign key (org_id,client_id) references public.clients(org_id,id) on delete cascade,
 check(valid_until>valid_from)
);
create index service_passes_client_idx on public.service_passes(org_id,client_id,status);

create table public.service_bookings (
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null,
 occurrence_id uuid not null,
 client_id uuid not null,
 pass_id uuid not null,
 requested_by uuid not null references auth.users(id),
 request_id uuid not null unique,
 cancel_request_id uuid unique,
 status text not null default 'booked' check(status in ('booked','cancelled')),
 booked_at timestamptz not null default now(),
 cancelled_at timestamptz,
 credited_on_cancel boolean not null default false,
 unique(org_id,id),
 foreign key(org_id,occurrence_id) references public.service_occurrences(org_id,id),
 foreign key(org_id,client_id) references public.clients(org_id,id),
 foreign key(org_id,pass_id) references public.service_passes(org_id,id),
 check ((status='booked' and cancelled_at is null)
     or (status='cancelled' and cancelled_at is not null))
);
create unique index service_bookings_one_active_per_client
 on public.service_bookings(occurrence_id,client_id) where status='booked';
create index service_bookings_occ_status on public.service_bookings(occurrence_id,status);

create table public.service_credit_ledger (
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null,
 pass_id uuid not null,
 booking_id uuid,
 event text not null check(event in ('complimentary_grant','booking_debit','cancellation_credit')),
 amount int not null,
 created_at timestamptz not null default now(),
 created_by uuid not null references auth.users(id),
 foreign key(org_id,pass_id) references public.service_passes(org_id,id),
 foreign key(org_id,booking_id) references public.service_bookings(org_id,id),
 constraint service_ledger_amount_ck check(
   (event='complimentary_grant' and amount between 1 and 1000 and booking_id is null) or
   (event='booking_debit' and amount=-1 and booking_id is not null) or
   (event='cancellation_credit' and amount=1 and booking_id is not null)
 )
);
create unique index service_credit_ledger_once_booking_event
 on public.service_credit_ledger(booking_id,event) where booking_id is not null;

create function private.owns_org_client(p_org uuid,p_client uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select auth.uid() is not null and exists(
   select 1 from public.clients c
   join public.organization_memberships m
     on m.organization_id=c.org_id and m.user_id=auth.uid()
   where c.org_id=p_org and c.id=p_client and c.user_id=auth.uid()
     and m.status='active'::public.organization_membership_status
     and m.role='athlete'::public.organization_role
 );
$$;
revoke all on function private.owns_org_client(uuid,uuid) from public,anon;
grant execute on function private.owns_org_client(uuid,uuid) to authenticated;

-- Serialize concurrent writes for each coach; prevent overlapping class and 1:1 slots.
create function private.check_service_coach_schedule()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
 if not exists(
   select 1 from public.organization_memberships m
   where m.organization_id=new.org_id and m.user_id=new.coach_user_id
     and m.status='active'
     and m.role in ('owner','admin','coach')
 ) then raise exception 'COACH_NOT_ACTIVE' using errcode='42501'; end if;

 perform pg_advisory_xact_lock(hashtextextended('coach:'||new.coach_user_id::text,0));
 if new.status='active' and exists (
   select 1 from public.service_occurrences o
   where o.coach_user_id=new.coach_user_id
     and o.status='active' and o.id<>new.id
     and o.starts_at<new.ends_at and o.ends_at>new.starts_at
 ) then raise exception 'COACH_TIME_OVERLAP' using errcode='23P01'; end if;
 return new;
end; $$;
revoke all on function private.check_service_coach_schedule() from public,anon,authenticated;
create trigger ensure_service_coach_free before insert or update on public.service_occurrences
for each row execute function private.check_service_coach_schedule();

alter table public.service_occurrences enable row level security;
alter table public.service_passes enable row level security;
alter table public.service_bookings enable row level security;
alter table public.service_credit_ledger enable row level security;

create policy service_occurrence_read on public.service_occurrences
 for select to authenticated
 using ((select private.has_org_role(org_id,array['owner','admin','coach','reception','athlete']::public.organization_role[])));
create policy service_occurrence_create on public.service_occurrences
 for insert to authenticated
 with check ((select private.has_org_role(org_id,array['owner','admin']::public.organization_role[])));

create policy service_passes_read on public.service_passes
 for select to authenticated
 using ((select private.has_org_role(org_id,array['owner','admin','reception']::public.organization_role[]))
      or (select private.owns_org_client(org_id,client_id)));
create policy service_bookings_read on public.service_bookings
 for select to authenticated
 using ((select private.has_org_role(org_id,array['owner','admin','reception']::public.organization_role[]))
      or (select private.owns_org_client(org_id,client_id))
      or exists(select 1 from public.service_occurrences o
         where o.id=occurrence_id and o.coach_user_id=(select auth.uid())
           and (select private.has_org_role(org_id,array['coach']::public.organization_role[]))));
create policy service_ledger_read on public.service_credit_ledger
 for select to authenticated
 using ((select private.has_org_role(org_id,array['owner','admin']::public.organization_role[]))
     or exists(select 1 from public.service_passes p
                where p.id=pass_id and (select private.owns_org_client(p.org_id,p.client_id))));

revoke all on public.service_occurrences,public.service_passes,
  public.service_bookings,public.service_credit_ledger from public,anon,authenticated;
grant select on public.service_occurrences,public.service_passes,
 public.service_bookings,public.service_credit_ledger to authenticated;
grant insert(org_id,coach_user_id,kind,title,starts_at,ends_at,capacity)
  on public.service_occurrences to authenticated;

-- Complimentary grants are explicit, never represented as payments.
create function private.grant_complimentary_pass(
 p_org uuid,p_client uuid,p_kind text,p_credits int,p_valid_until timestamptz
) returns uuid language plpgsql security definer set search_path=''
as $$
declare v_actor uuid:=auth.uid(); v_id uuid;
begin
 if v_actor is null or not private.has_org_role(p_org,array['owner','admin']::public.organization_role[]) then
   raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if p_kind not in ('class','appointment') or p_credits not between 1 and 1000
    or p_valid_until<=now() or p_valid_until>now()+interval '2 years' then
   raise exception 'INVALID_PASS' using errcode='22023'; end if;
 if not exists(select 1 from public.clients c where c.org_id=p_org and c.id=p_client and c.user_id is not null and c.status='active') then
   raise exception 'CLIENT_NOT_LINKED' using errcode='22023'; end if;
 insert into public.service_passes(org_id,client_id,kind,total_credits,remaining_credits,valid_until,issued_by)
 values(p_org,p_client,p_kind,p_credits,p_credits,p_valid_until,v_actor)
 returning id into v_id;
 insert into public.service_credit_ledger(org_id,pass_id,event,amount,created_by)
 values(p_org,v_id,'complimentary_grant',p_credits,v_actor);
 return v_id;
end; $$;

create function private.book_service_occurrence(p_occurrence uuid,p_pass uuid,p_request uuid)
returns uuid language plpgsql security definer set search_path=''
as $$
declare
 v_actor uuid:=auth.uid();
 v_occ public.service_occurrences%rowtype;
 v_pass public.service_passes%rowtype;
 v_existing public.service_bookings%rowtype;
 v_client_id uuid;
 v_booking uuid;
begin
 if v_actor is null or p_request is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended('service_request:'||p_request::text,0));
 select * into v_existing from public.service_bookings where request_id=p_request;
 if found then
   if v_existing.requested_by<>v_actor or v_existing.occurrence_id<>p_occurrence or v_existing.pass_id<>p_pass then
     raise exception 'REQUEST_ID_REUSED' using errcode='23505';
   end if;
   return v_existing.id;
 end if;

 select * into v_occ from public.service_occurrences where id=p_occurrence for update;
 if not found or v_occ.status<>'active' or v_occ.starts_at<=now() then
   raise exception 'OCCURRENCE_UNAVAILABLE' using errcode='22023'; end if;
 if not private.has_org_role(v_occ.org_id,array['athlete']::public.organization_role[]) then
   raise exception 'NOT_A_MEMBER' using errcode='42501'; end if;

 select * into v_pass from public.service_passes where id=p_pass and org_id=v_occ.org_id for update;
 if not found or v_pass.kind<>v_occ.kind or v_pass.status<>'active'
    or v_pass.remaining_credits<1 or v_pass.valid_from>v_occ.starts_at
    or v_pass.valid_until<v_occ.starts_at then
   raise exception 'NO_VALID_PASS' using errcode='22023'; end if;
 v_client_id:=v_pass.client_id;
 if not private.owns_org_client(v_occ.org_id,v_client_id) then
   raise exception 'NOT_OWN_PASS' using errcode='42501'; end if;

 if exists(select 1 from public.service_bookings b
   where b.occurrence_id=v_occ.id and b.client_id=v_client_id and b.status='booked') then
   raise exception 'ALREADY_BOOKED' using errcode='23505'; end if;
 if (select count(*) from public.service_bookings b
       where b.occurrence_id=v_occ.id and b.status='booked')>=v_occ.capacity then
   raise exception 'NO_AVAILABILITY' using errcode='22023'; end if;

 insert into public.service_bookings(org_id,occurrence_id,client_id,pass_id,requested_by,request_id)
 values(v_occ.org_id,v_occ.id,v_client_id,v_pass.id,v_actor,p_request) returning id into v_booking;
 update public.service_passes set remaining_credits=remaining_credits-1 where id=v_pass.id;
 insert into public.service_credit_ledger(org_id,pass_id,booking_id,event,amount,created_by)
 values(v_occ.org_id,v_pass.id,v_booking,'booking_debit',-1,v_actor);
 return v_booking;
end; $$;

create function private.cancel_service_booking(p_booking uuid,p_request uuid)
returns boolean language plpgsql security definer set search_path=''
as $$
declare
 v_actor uuid:=auth.uid(); v_booking public.service_bookings%rowtype;
 v_occ public.service_occurrences%rowtype;
 v_refund boolean;
begin
 if v_actor is null or p_request is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended('service_cancel:'||p_booking::text,0));
 select * into v_booking from public.service_bookings where id=p_booking for update;
 if not found then raise exception 'BOOKING_NOT_FOUND' using errcode='22023'; end if;
 if not (private.owns_org_client(v_booking.org_id,v_booking.client_id)
    or private.has_org_role(v_booking.org_id,array['owner','admin']::public.organization_role[])) then
   raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if v_booking.status='cancelled' then return v_booking.credited_on_cancel; end if;
 select * into v_occ from public.service_occurrences where id=v_booking.occurrence_id;
 -- Default provisional cancellation policy: 12h minimum notice for credit refund.
 v_refund:=v_occ.starts_at>now()+interval '12 hours';
 update public.service_bookings set status='cancelled',cancelled_at=now(),
   cancel_request_id=p_request,credited_on_cancel=v_refund
 where id=v_booking.id;
 if v_refund then
   update public.service_passes set remaining_credits=remaining_credits+1 where id=v_booking.pass_id;
   insert into public.service_credit_ledger(org_id,pass_id,booking_id,event,amount,created_by)
    values(v_booking.org_id,v_booking.pass_id,v_booking.id,'cancellation_credit',1,v_actor);
 end if;
 return v_refund;
end; $$;
revoke all on function private.grant_complimentary_pass(uuid,uuid,text,int,timestamptz),
 private.book_service_occurrence(uuid,uuid,uuid),private.cancel_service_booking(uuid,uuid)
 from public,anon;
grant execute on function private.grant_complimentary_pass(uuid,uuid,text,int,timestamptz),
 private.book_service_occurrence(uuid,uuid,uuid),private.cancel_service_booking(uuid,uuid) to authenticated;

-- SECURITY INVOKER wrappers only; definer functions stay out of exposed public schema.
create function public.grant_complimentary_pass(p_org uuid,p_client uuid,p_kind text,p_credits int,p_valid_until timestamptz)
returns uuid language sql security invoker set search_path=''
as $$ select private.grant_complimentary_pass(p_org,p_client,p_kind,p_credits,p_valid_until) $$;
create function public.book_service_occurrence(p_occurrence uuid,p_pass uuid,p_request uuid)
returns uuid language sql security invoker set search_path=''
as $$ select private.book_service_occurrence(p_occurrence,p_pass,p_request) $$;
create function public.cancel_service_booking(p_booking uuid,p_request uuid)
returns boolean language sql security invoker set search_path=''
as $$ select private.cancel_service_booking(p_booking,p_request) $$;

revoke all on function public.grant_complimentary_pass(uuid,uuid,text,int,timestamptz),
 public.book_service_occurrence(uuid,uuid,uuid),public.cancel_service_booking(uuid,uuid)
 from public,anon;
grant execute on function public.grant_complimentary_pass(uuid,uuid,text,int,timestamptz),
 public.book_service_occurrence(uuid,uuid,uuid),public.cancel_service_booking(uuid,uuid)
 to authenticated;
