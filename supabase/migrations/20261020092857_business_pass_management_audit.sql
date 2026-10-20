
-- Safely edit courtesy entitlements; never fabricate a monetary payment.
create table public.service_pass_management_events(
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null,
 pass_id uuid not null,
 actor uuid not null references auth.users(id),
 action text not null check(action in ('add_credits','reset_remaining','extend_validity')),
 previous_total int not null,
 previous_remaining int not null,
 new_total int not null,
 new_remaining int not null,
 previous_expiry timestamptz not null,
 new_expiry timestamptz not null,
 created_at timestamptz not null default now(),
 foreign key(org_id,pass_id) references public.service_passes(org_id,id)
);
alter table public.service_pass_management_events enable row level security;
create policy pass_changes_read on public.service_pass_management_events for select to authenticated
 using(private.has_org_role(org_id,array['owner','admin']::public.organization_role[]) or
 exists(select 1 from public.service_passes p where p.id=pass_id and private.owns_org_client(org_id,p.client_id)));
revoke all on public.service_pass_management_events from public,anon,authenticated;
grant select on public.service_pass_management_events to authenticated;
create function private.manage_complimentary_pass(p_pass uuid,p_action text,p_amount int,p_until timestamptz)
 returns boolean language plpgsql security definer set search_path=''
 as $$
declare p public.service_passes%rowtype; new_total int; new_remaining int; new_expiry timestamptz;
begin
 select * into p from public.service_passes where id=p_pass for update;
 if not found or p.issuance_type<>'complimentary' or p.status<>'active' then
  raise exception 'PASS_UNAVAILABLE' using errcode='22023';end if;
 if not private.has_org_role(p.org_id,array['owner','admin']::public.organization_role[]) then
  raise exception 'NOT_AUTHORIZED' using errcode='42501';end if;
 if not exists(select 1 from public.organization_trials where org_id=p.org_id
   and (trial_ends_at>now() or (paid_plan is not null and paid_until>now()))) then
  raise exception 'TRIAL_EXPIRED_PAYMENT_REQUIRED' using errcode='42501';end if;
 new_total:=p.total_credits;new_remaining:=p.remaining_credits;new_expiry:=p.valid_until;
 if p_action='add_credits' then
  if p_amount is null or p_amount not between 1 and 1000
    or p.total_credits+p_amount>1000 then raise exception 'INVALID_AMOUNT' using errcode='22023';end if;
  new_total:=p.total_credits+p_amount;new_remaining:=p.remaining_credits+p_amount;
 elsif p_action='reset_remaining' then
  new_remaining:=p.total_credits;
 elsif p_action='extend_validity' then
  if p_until is null or p_until<=p.valid_until or p_until<=now() then
   raise exception 'INVALID_EXPIRY' using errcode='22023';end if;
  new_expiry:=p_until;
 else raise exception 'INVALID_ACTION' using errcode='22023';end if;
 update public.service_passes set total_credits=new_total,remaining_credits=new_remaining,
  valid_until=new_expiry where id=p_pass;
 insert into public.service_pass_management_events(org_id,pass_id,actor,action,
  previous_total,previous_remaining,new_total,new_remaining,previous_expiry,new_expiry)
 values(p.org_id,p.id,auth.uid(),p_action,p.total_credits,p.remaining_credits,
  new_total,new_remaining,p.valid_until,new_expiry);
 return true;
end; $$;
revoke all on function private.manage_complimentary_pass(uuid,text,int,timestamptz)
 from public,anon,authenticated;
grant execute on function private.manage_complimentary_pass(uuid,text,int,timestamptz) to authenticated;
create function public.manage_complimentary_pass(p_pass uuid,p_action text,p_amount int,p_until timestamptz)
 returns boolean language sql security invoker set search_path=''
 as $$select private.manage_complimentary_pass(p_pass,p_action,p_amount,p_until)$$;
revoke all on function public.manage_complimentary_pass(uuid,text,int,timestamptz) from public,anon;
grant execute on function public.manage_complimentary_pass(uuid,text,int,timestamptz) to authenticated;

-- Even after trial expiry, cancellation and refunds must remain possible.
create or replace function private.assert_business_trial() returns trigger
language plpgsql security definer set search_path=''
as $$
begin
 if tg_op='UPDATE' and tg_table_name='service_occurrences'
  and old.status='active' and new.status='cancelled' then return new; end if;
 if tg_op='UPDATE' and tg_table_name='professional_training_sessions'
  and old.status='scheduled' and new.status='cancelled' then return new; end if;
 if not exists(select 1 from public.organization_trials t where t.org_id=new.org_id
  and (t.trial_ends_at>now() or (t.paid_until>now() and t.paid_plan is not null))) then
  raise exception 'TRIAL_EXPIRED_PAYMENT_REQUIRED' using errcode='42501';end if;
 return new;
end; $$;
