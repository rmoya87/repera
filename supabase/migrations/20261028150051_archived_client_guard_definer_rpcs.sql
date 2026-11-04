-- A SECURITY DEFINER RPC runs as postgres, but retains the caller's JWT.
-- Guard on the verified end-user identity rather than current_user, which
-- could otherwise let a staff API bypass the immutable snapshot guard.
create or replace function public.repera_reject_archived_client_changes()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if old.account_deleted_at is not null and (select auth.uid()) is not null then
    raise exception 'Este cliente es un registro histórico de solo lectura.'
      using errcode = '42501';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;
revoke all on function public.repera_reject_archived_client_changes() from public;
