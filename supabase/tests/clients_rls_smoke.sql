-- Repera roster isolation smoke. Run on staging or controlled DB with baseline + clients migrations.
-- Creates temporary Auth identities in a transaction; does not persist data.
begin;
insert into auth.users(id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at)
values
('00000000-0000-4000-a000-000000000301','00000000-0000-0000-0000-000000000000','authenticated','authenticated','roster-a@example.invalid','',now(),now(),now()),
('00000000-0000-4000-a000-000000000302','00000000-0000-0000-0000-000000000000','authenticated','authenticated','roster-b@example.invalid','',now(),now(),now());
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000301',true);
insert into public.organizations(id,name,slug,kind,created_by)
values ('00000000-0000-4000-a000-000000000303','Roster test A','roster-test-a','gym','00000000-0000-4000-a000-000000000301');
insert into public.clients(org_id,created_by,name,email)
values('00000000-0000-4000-a000-000000000303','00000000-0000-4000-a000-000000000301','Cliente de A','a-client@example.invalid');
do $$ begin
 if (select count(*) from public.clients) <> 1 then raise exception 'owner cannot read roster'; end if;
 if has_column_privilege(current_user,'public.clients','user_id','UPDATE') then raise exception 'unsafe user linking'; end if;
 if has_table_privilege(current_user,'public.staff_client_assignments','INSERT') then raise exception 'unsafe assignment insert'; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000302',true);
do $$ begin
 if (select count(*) from public.clients) <> 0 then raise exception 'cross tenant clients leak'; end if;
 begin
 insert into public.clients(org_id,created_by,name,email)
 values('00000000-0000-4000-a000-000000000303','00000000-0000-4000-a000-000000000302','Cliente inyectado','bad@example.invalid');
 raise exception 'cross tenant insert accepted';
 exception when insufficient_privilege then null; end;
end $$;
rollback;
select 'clients_rls_smoke_pass' as result,(select count(*) from public.clients)::int as persisted_clients;
