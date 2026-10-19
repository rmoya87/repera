-- Sólo Supabase local. pgTAP 9 casos con fixtures revertidos al terminar.
begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(9);

insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at)
values
('00000000-0000-0000-0000-000000000000','00000000-0000-4000-8000-000000000101','authenticated','authenticated','repera-a@invalid.example','',now(),now(),now()),
('00000000-0000-0000-0000-000000000000','00000000-0000-4000-8000-000000000102','authenticated','authenticated','repera-b@invalid.example','',now(),now(),now()),
('00000000-0000-0000-0000-000000000000','00000000-0000-4000-8000-000000000103','authenticated','authenticated','repera-coach@invalid.example','',now(),now(),now()),
('00000000-0000-0000-0000-000000000000','00000000-0000-4000-8000-000000000104','authenticated','authenticated','repera-manager@invalid.example','',now(),now(),now()),
('00000000-0000-0000-0000-000000000000','00000000-0000-4000-8000-000000000105','authenticated','authenticated','repera-other@invalid.example','',now(),now(),now());

insert into public.organizations (id,kind,name)
values ('10000000-0000-4000-8000-000000000101','gym','Gym test');

insert into public.organization_members(organization_id,user_id,role,status) values
('10000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000103','coach','active'),
('10000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000104','manager','active');

insert into public.client_relationships(id,organization_id,athlete_id,coach_id,service,status,share_workout_history)
values ('20000000-0000-4000-8000-000000000101','10000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000103','personal_training','active',false);

insert into public.workouts(id,owner_id,title) values
('30000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000101','Entrenamiento A'),
('30000000-0000-4000-8000-000000000102','00000000-0000-4000-8000-000000000102','Entrenamiento B');

set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000101',true);
select extensions.is((select count(*) from public.workouts),1::bigint,'Atleta A sólo ve su entreno');
select extensions.is((select count(*) from public.profiles),1::bigint,'Atleta A sólo ve su perfil');

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000103',true);
select extensions.is((select count(*) from public.workouts),0::bigint,'Coach sin permiso no ve historial');
select extensions.is((select count(*) from public.profiles),2::bigint,'Coach sí ve su perfil y cliente activo');

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000104',true);
select extensions.is((select count(*) from public.workouts),0::bigint,'Manager gimnasio no ve historiales');

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000105',true);
select extensions.is((select count(*) from public.workouts),0::bigint,'Usuario ajeno no ve entrenos');
select extensions.is((select count(*) from public.client_relationships),0::bigint,'Usuario ajeno no ve relaciones');

reset role;
update public.client_relationships set share_workout_history=true
where id='20000000-0000-4000-8000-000000000101';

set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000103',true);
select extensions.is((select count(*) from public.workouts),1::bigint,'Coach con consentimiento sí ve historial');

reset role;
update public.organization_members set status='suspended'
where user_id='00000000-0000-4000-8000-000000000103';
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000103',true);
select extensions.is((select count(*) from public.workouts),0::bigint,'Coach suspendido pierde acceso');

reset role;
select * from extensions.finish();
rollback;
