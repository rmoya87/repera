-- Athletes create debit/credit ledger entries when booking or cancelling.
-- Detach the identity without losing the original historical actor.
alter table public.service_credit_ledger
  add column if not exists created_by_deleted_user_id uuid;
alter table public.service_credit_ledger
  alter column created_by drop not null;
alter table public.service_credit_ledger
  drop constraint if exists service_credit_ledger_created_by_fkey;
alter table public.service_credit_ledger
  add constraint service_credit_ledger_created_by_fkey
    foreign key (created_by) references auth.users(id) on delete set null;
alter table public.service_credit_ledger
  drop constraint if exists service_credit_ledger_actor_recorded_check;
alter table public.service_credit_ledger
  add constraint service_credit_ledger_actor_recorded_check
    check (created_by is not null or created_by_deleted_user_id is not null);
