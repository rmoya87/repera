-- Stop creating new client activity after an account is frozen.
-- Existing company-owned records remain readable for legitimate history.
do $do$
declare target text;
begin
  foreach target in array array[
    'business_client_notifications',
    'business_client_payments',
    'business_trainer_attendance',
    'business_training_group_members',
    'staff_client_assignments'
  ] loop
    execute format('drop trigger if exists trg_repera_archive_guard on public.%I', target);
    execute format(
      'create trigger trg_repera_archive_guard before insert on public.%I for each row execute function public.repera_reject_archived_client_activity()',
      target
    );
  end loop;
end
$do$;
