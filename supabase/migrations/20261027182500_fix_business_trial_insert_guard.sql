-- Fix existing trigger: OLD.status has no row during INSERT.
-- Keep trial enforcement exactly as before, except cancelled updates remain permitted.
create or replace function private.assert_business_trial()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_op='UPDATE' then
  if tg_table_name='service_occurrences'
   and old.status='active' and new.status='cancelled' then return new;end if;
  if tg_table_name='professional_training_sessions'
   and old.status='scheduled' and new.status='cancelled' then return new;end if;
 end if;
 if not exists(select 1 from public.organization_trials t where t.org_id=new.org_id
  and (t.trial_ends_at>now() or (t.paid_until>now() and t.paid_plan is not null)))
 then raise exception 'TRIAL_EXPIRED_PAYMENT_REQUIRED' using errcode='42501';end if;
 return new;
end $$;
