-- Repera RLS smoke test. Execute against Repera staging/isolated DB as postgres.
-- Test users and organization are created in a transaction and rolled back.
-- Requires baseline migration 20261019190623_business_foundation_secure.
begin;
insert into auth.users (id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at)
values
('00000000-0000-4000-a000-000000000101','00000000-0000-0000-0000-000000000000','authenticated','authenticated','rls-check-a@example.invalid','',now(),now(),now()),
('00000000-0000-4000-a000-000000000102','00000000-0000-0000-0000-000000000000','authenticated','authenticated','rls-check-b@example.invalid','',now(),now(),now());
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000101',true);
insert into public.organizations(id,name,slug,kind,created_by) values
('00000000-0000-4000-a000-000000000201','Organizacion Test A','test-org-a-smoke','gym','00000000-0000-4000-a000-000000000101');
do $$ begin
 if (select count(*) from public.organizations) <> 1 then raise exception 'Owner cannot see own organization'; end if;
 if (select count(*) from public.organization_memberships where role='owner') <> 1 then raise exception 'Missing owner bootstrap'; end if;
 if (select count(*) from public.profiles) <> 1 then raise exception 'Profiles not scoped to self'; end if;
 if has_column_privilege(current_user,'public.profiles','role','UPDATE') then raise exception 'Profile role can be updated by authenticated'; end if;
 if has_table_privilege(current_user,'public.organization_memberships','INSERT') then raise exception 'Membership client insert enabled'; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000102',true);
do $$ begin
 if (select count(*) from public.organizations) <> 0 then raise exception 'Tenant B can see A organization'; end if;
 if (select count(*) from public.organization_memberships) <> 0 then raise exception 'Tenant B can see A membership'; end if;
 if (select count(*) from public.profiles) <> 1 then raise exception 'Tenant B profile visibility incorrect'; end if;
 begin
  insert into public.organizations(id,name,slug,kind,created_by) values
  ('00000000-0000-4000-a000-000000000202','Impersonated','test-forged-org-a','gym','00000000-0000-4000-a000-000000000101');
  raise exception 'Forged creation was accepted';
 exception
   when insufficient_privilege then null;
 end;
end $$;
rollback;
select 'rls_smoke_pass' as result, (select count(*) from public.organizations)::int as persisted_orgs;
