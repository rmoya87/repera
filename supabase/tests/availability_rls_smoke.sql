-- Real RLS test, temporary users and ROLLBACK (no data persists).
begin;
insert into auth.users(id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at) values
('00000000-0000-4000-a000-000000000961','00000000-0000-0000-0000-000000000000','authenticated','authenticated','available-owner@example.invalid','',now(),now(),now()),
('00000000-0000-4000-a000-000000000962','00000000-0000-0000-0000-000000000000','authenticated','authenticated','available-stranger@example.invalid','',now(),now(),now());
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000961',true);
insert into public.organizations(id,name,slug,kind,created_by)
values('00000000-0000-4000-a000-000000000963','Capacity QA','capacity-qa','gym','00000000-0000-4000-a000-000000000961');
insert into public.service_occurrences(org_id,coach_user_id,kind,title,starts_at,ends_at,capacity)
values('00000000-0000-4000-a000-000000000963','00000000-0000-4000-a000-000000000961',
'class','Prueba plazas',now()+interval '10 days',now()+interval '10 days 1 hour',3);
do $$ begin
 if (select count(*) from public.get_service_availability('00000000-0000-4000-a000-000000000963'))<>1 then
  raise exception 'owner cannot see availability'; end if;
 if exists(select 1 from public.get_service_availability('00000000-0000-4000-a000-000000000963') where reserved<>0 or capacity<>3) then
  raise exception 'wrong empty capacity'; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000962',true);
do $$ begin
 begin
  perform * from public.get_service_availability('00000000-0000-4000-a000-000000000963');
  raise exception 'stranger read slots';
 exception when insufficient_privilege then null; end;
end $$;
rollback;
select 'availability_rls_smoke_pass' as result,(select count(*) from public.service_occurrences)::int as persisted;
