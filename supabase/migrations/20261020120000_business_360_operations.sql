
-- Repera Business 360: trial clock, secure admin bootstrap, class detail and private notifications.
-- All sensitive actions use authenticated role and per-org authorisation.
create table public.organization_trials (
  org_id uuid primary key references public.organizations(id) on delete cascade,
  trial_started_at timestamptz not null,
  trial_ends_at timestamptz not null,
  paid_plan text,
  paid_until timestamptz,
  created_at timestamptz not null default now(),
  check(trial_ends_at = trial_started_at + interval '7 days'),
  check(paid_plan is null or paid_plan in ('trainer_5','trainer_50','trainer_75','gym_basic','gym_advanced','gym_expert'))
);
alter table public.organization_trials enable row level security;
create policy organization_trials_read on public.organization_trials for select to authenticated
 using(private.has_org_role(org_id,array['owner','admin','coach','reception']::public.organization_role[]));
revoke all on public.organization_trials from public,anon,authenticated;
grant select on public.organization_trials to authenticated;
create function private.initialize_business_trial() returns trigger
language plpgsql security definer set search_path=''
as $$
begin
 insert into public.organization_trials(org_id,trial_started_at,trial_ends_at)
 values(new.id,new.created_at,new.created_at+interval '7 days') on conflict do nothing;
 return new;
end; $$;
revoke all on function private.initialize_business_trial() from public,anon,authenticated;
create trigger initialize_business_trial after insert on public.organizations
 for each row execute function private.initialize_business_trial();
insert into public.organization_trials(org_id,trial_started_at,trial_ends_at)
 select id,created_at,created_at+interval '7 days' from public.organizations on conflict do nothing;

-- Never trust a client-controlled role or an unverified email. Provision the explicitly
-- requested owner account only AFTER email verification by Supabase Auth.
create function private.bootstrap_repera_platform_admin() returns trigger
language plpgsql security definer set search_path=''
as $$
begin
 if lower(coalesce(new.email,'')) = 'rmoya87@gmail.com' and new.email_confirmed_at is not null then
  update public.profiles set role='platform_admin',updated_at=now() where id=new.id;
 elsif TG_OP='UPDATE' and lower(coalesce(old.email,''))='rmoya87@gmail.com'
      and new.email is distinct from old.email then
  update public.profiles set role='athlete',updated_at=now()
    where id=new.id and role='platform_admin';
 end if;
 return new;
end; $$;
revoke all on function private.bootstrap_repera_platform_admin() from public,anon,authenticated;
create trigger repera_admin_verified after insert or update of email,email_confirmed_at on auth.users
 for each row execute function private.bootstrap_repera_platform_admin();

alter table public.clients
 add column if not exists phone text,
 add column if not exists avatar_url text,
 add column if not exists notes text;
grant update(name,email,status,phone,notes,avatar_url) on public.clients to authenticated;

create table public.service_occurrence_details (
 occurrence_id uuid primary key references public.service_occurrences(id) on delete cascade,
 org_id uuid not null references public.organizations(id) on delete cascade,
 description text not null default '' check(length(description)<=2000),
 location text not null default '' check(length(location)<=250),
 image_url text,
 color text not null default '#22834d' check(color ~ '^#[0-9a-fA-F]{6}$'),
 repeat_rule text not null default 'none' check(repeat_rule in ('none','daily','weekly','weekdays')),
 created_at timestamptz not null default now(),
 foreign key(org_id,occurrence_id) references public.service_occurrences(org_id,id) on delete cascade
);
alter table public.service_occurrence_details enable row level security;
create policy service_details_read on public.service_occurrence_details for select to authenticated
 using(private.has_org_role(org_id,array['owner','admin','coach','reception','athlete']::public.organization_role[]));
revoke all on public.service_occurrence_details from public,anon,authenticated;
grant select on public.service_occurrence_details to authenticated;

create table public.business_client_notifications (
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null,
 client_id uuid not null,
 sender_user_id uuid not null references auth.users(id),
 title text not null check(length(btrim(title)) between 2 and 120),
 body text not null check(length(btrim(body)) between 2 and 1000),
 created_at timestamptz not null default now(),
 read_at timestamptz,
 foreign key(org_id,client_id) references public.clients(org_id,id) on delete cascade
);
alter table public.business_client_notifications enable row level security;
create policy client_notifications_read on public.business_client_notifications for select to authenticated
 using(private.owns_org_client(org_id,client_id)
   or private.has_org_role(org_id,array['owner','admin']::public.organization_role[])
   or private.is_assigned_coach(org_id,client_id));
revoke all on public.business_client_notifications from public,anon,authenticated;
grant select on public.business_client_notifications to authenticated;

-- A manager may change only class metadata and future schedule. Coach assignment remains controlled.
create function private.manage_service_occurrence(
 p_id uuid,p_title text,p_start timestamptz,p_end timestamptz,p_capacity int,
 p_description text,p_location text,p_color text,p_image text
) returns boolean language plpgsql security definer set search_path=''
as $$
declare v public.service_occurrences%rowtype; occupied int;
begin
 select * into v from public.service_occurrences where id=p_id for update;
 if not found then raise exception 'CLASS_NOT_FOUND' using errcode='22023'; end if;
 if not private.has_org_role(v.org_id,array['owner','admin']::public.organization_role[]) then
   raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if v.starts_at<=now() or v.status<>'active' then
   raise exception 'CLASS_LOCKED' using errcode='22023'; end if;
 select count(*) into occupied from public.service_bookings where occurrence_id=p_id and status='booked';
 if p_start<=now() or p_end<=p_start or p_end>p_start+interval '12 hours'
 or length(btrim(coalesce(p_title,''))) not between 2 and 120
 or p_capacity<greatest(occupied,1) or p_capacity>200 then
   raise exception 'CLASS_INVALID' using errcode='22023'; end if;
 update public.service_occurrences set title=btrim(p_title), starts_at=p_start,ends_at=p_end,capacity=p_capacity where id=p_id;
 insert into public.service_occurrence_details(occurrence_id,org_id,description,location,color,image_url)
 values(p_id,v.org_id,left(coalesce(p_description,''),2000),left(coalesce(p_location,''),250),p_color,left(coalesce(p_image,''),2000))
 on conflict (occurrence_id) do update
 set description=excluded.description,location=excluded.location,color=excluded.color,image_url=excluded.image_url;
 return true;
end; $$;

-- Centre cancellation refunds ALL affected members, independently of the 12h athlete policy.
create function private.cancel_managed_occurrence(p_id uuid)
returns int language plpgsql security definer set search_path=''
as $$
declare v public.service_occurrences%rowtype; booking record; total int:=0;
begin
 select * into v from public.service_occurrences where id=p_id for update;
 if not found then raise exception 'CLASS_NOT_FOUND' using errcode='22023'; end if;
 if not private.has_org_role(v.org_id,array['owner','admin']::public.organization_role[]) then
   raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if v.status='cancelled' then return 0; end if;
 if v.starts_at <= now() then raise exception 'PAST_CLASS' using errcode='22023'; end if;
 update public.service_occurrences set status='cancelled' where id=p_id;
 for booking in select id,pass_id from public.service_bookings
  where occurrence_id=p_id and status='booked' order by id for update loop
  update public.service_bookings set status='cancelled',cancelled_at=now(),
    cancel_request_id=gen_random_uuid(),credited_on_cancel=true where id=booking.id;
  update public.service_passes set remaining_credits=remaining_credits+1 where id=booking.pass_id;
  insert into public.service_credit_ledger(org_id,pass_id,booking_id,event,amount,created_by)
  values(v.org_id,booking.pass_id,booking.id,'cancellation_credit',1,auth.uid());
  total:=total+1;
 end loop;
 return total;
end; $$;

create function private.enroll_managed_client(
 p_occ uuid,p_client uuid,p_pass uuid,p_request uuid
) returns uuid language plpgsql security definer set search_path=''
as $$
declare v public.service_occurrences%rowtype; pass public.service_passes%rowtype; row_id uuid;
begin
 if auth.uid() is null or p_request is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended('managed_enroll:'||p_request::text,0));
 if exists(select 1 from public.service_bookings where request_id=p_request and (occurrence_id<>p_occ or client_id<>p_client or pass_id<>p_pass or requested_by<>auth.uid())) then
  raise exception 'REQUEST_ID_REUSED' using errcode='23505'; end if;
 select id into row_id from public.service_bookings where request_id=p_request;
 if found then return row_id; end if;
 select * into v from public.service_occurrences where id=p_occ for update;
 if not found or v.status<>'active' or v.starts_at<=now() then
   raise exception 'CLASS_UNAVAILABLE' using errcode='22023'; end if;
 if not private.has_org_role(v.org_id,array['owner','admin']::public.organization_role[]) then
   raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 select * into pass from public.service_passes where id=p_pass and org_id=v.org_id and client_id=p_client for update;
 if not found or pass.status<>'active' or pass.kind<>v.kind or pass.remaining_credits<1
 or pass.valid_from>v.starts_at or pass.valid_until<v.starts_at then
   raise exception 'NO_VALID_PASS' using errcode='22023'; end if;
 if exists(select 1 from public.service_bookings where occurrence_id=p_occ and client_id=p_client and status='booked')
    or (select count(*) from public.service_bookings where occurrence_id=p_occ and status='booked')>=v.capacity then
   raise exception 'CLASS_FULL_OR_DUPLICATE' using errcode='22023'; end if;
 insert into public.service_bookings(org_id,occurrence_id,client_id,pass_id,requested_by,request_id)
 values(v.org_id,p_occ,p_client,p_pass,auth.uid(),p_request) returning id into row_id;
 update public.service_passes set remaining_credits=remaining_credits-1 where id=p_pass;
 insert into public.service_credit_ledger(org_id,pass_id,booking_id,event,amount,created_by)
 values(v.org_id,p_pass,row_id,'booking_debit',-1,auth.uid());
 return row_id;
end; $$;

create function private.remove_managed_client(p_booking uuid) returns boolean
language plpgsql security definer set search_path=''
as $$
declare b public.service_bookings%rowtype;
begin
 select * into b from public.service_bookings where id=p_booking for update;
 if not found then raise exception 'BOOKING_NOT_FOUND' using errcode='22023'; end if;
 if not private.has_org_role(b.org_id,array['owner','admin']::public.organization_role[]) then
  raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if b.status='cancelled' then return false; end if;
 update public.service_bookings set status='cancelled',cancelled_at=now(),
  cancel_request_id=gen_random_uuid(),credited_on_cancel=true where id=p_booking;
 update public.service_passes set remaining_credits=remaining_credits+1 where id=b.pass_id;
 insert into public.service_credit_ledger(org_id,pass_id,booking_id,event,amount,created_by)
 values(b.org_id,b.pass_id,b.id,'cancellation_credit',1,auth.uid());
 return true;
end; $$;

create function private.send_business_client_notice(p_org uuid,p_client uuid,p_title text,p_body text)
 returns uuid language plpgsql security definer set search_path=''
as $$
declare n uuid;
begin
 if auth.uid() is null or not (
 private.has_org_role(p_org,array['owner','admin']::public.organization_role[])
 or private.is_assigned_coach(p_org,p_client)) then
   raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if not exists(select 1 from public.clients where org_id=p_org and id=p_client and user_id is not null)
 or length(btrim(coalesce(p_title,''))) not between 2 and 120
 or length(btrim(coalesce(p_body,''))) not between 2 and 1000 then
   raise exception 'INVALID_NOTICE' using errcode='22023'; end if;
 insert into public.business_client_notifications(org_id,client_id,sender_user_id,title,body)
 values(p_org,p_client,auth.uid(),btrim(p_title),btrim(p_body)) returning id into n;
 return n;
end; $$;

revoke all on function private.manage_service_occurrence(uuid,text,timestamptz,timestamptz,int,text,text,text,text),
 private.cancel_managed_occurrence(uuid), private.enroll_managed_client(uuid,uuid,uuid,uuid),
 private.remove_managed_client(uuid), private.send_business_client_notice(uuid,uuid,text,text)
 from public,anon,authenticated;
grant execute on function private.manage_service_occurrence(uuid,text,timestamptz,timestamptz,int,text,text,text,text),
 private.cancel_managed_occurrence(uuid), private.enroll_managed_client(uuid,uuid,uuid,uuid),
 private.remove_managed_client(uuid), private.send_business_client_notice(uuid,uuid,text,text) to authenticated;
create function public.manage_service_occurrence(p_id uuid,p_title text,p_start timestamptz,p_end timestamptz,p_capacity int,p_description text,p_location text,p_color text,p_image text)
 returns boolean language sql security invoker set search_path=''
 as $$select private.manage_service_occurrence(p_id,p_title,p_start,p_end,p_capacity,p_description,p_location,p_color,p_image)$$;
create function public.cancel_managed_occurrence(p_id uuid)
 returns int language sql security invoker set search_path=''
 as $$select private.cancel_managed_occurrence(p_id)$$;
create function public.enroll_managed_client(p_occ uuid,p_client uuid,p_pass uuid,p_request uuid)
 returns uuid language sql security invoker set search_path=''
 as $$select private.enroll_managed_client(p_occ,p_client,p_pass,p_request)$$;
create function public.remove_managed_client(p_booking uuid)
 returns boolean language sql security invoker set search_path=''
 as $$select private.remove_managed_client(p_booking)$$;
create function public.send_business_client_notice(p_org uuid,p_client uuid,p_title text,p_body text)
 returns uuid language sql security invoker set search_path=''
 as $$select private.send_business_client_notice(p_org,p_client,p_title,p_body)$$;
revoke all on function public.manage_service_occurrence(uuid,text,timestamptz,timestamptz,int,text,text,text,text),
 public.cancel_managed_occurrence(uuid),public.enroll_managed_client(uuid,uuid,uuid,uuid),
 public.remove_managed_client(uuid),public.send_business_client_notice(uuid,uuid,text,text) from public,anon;
grant execute on function public.manage_service_occurrence(uuid,text,timestamptz,timestamptz,int,text,text,text,text),
 public.cancel_managed_occurrence(uuid),public.enroll_managed_client(uuid,uuid,uuid,uuid),
 public.remove_managed_client(uuid),public.send_business_client_notice(uuid,uuid,text,text) to authenticated;
