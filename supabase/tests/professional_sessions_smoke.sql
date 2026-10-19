-- Real Supabase RLS smoke: coach publishes to an invited athlete; no private history shared.
begin;
insert into auth.users(id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at) values
('00000000-0000-4000-a000-000000000951','00000000-0000-0000-0000-000000000000','authenticated','authenticated','coach-951@example.invalid','',now(),now(),now()),
('00000000-0000-4000-a000-000000000952','00000000-0000-0000-0000-000000000000','authenticated','authenticated','athlete-952@example.invalid','',now(),now(),now());
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000951',true);
insert into public.organizations(id,name,slug,kind,created_by) values
('00000000-0000-4000-a000-000000000953','Trainer 951','trainer-951','personal_trainer','00000000-0000-4000-a000-000000000951');
select public.issue_org_invitation('00000000-0000-4000-a000-000000000953','athlete-952@example.invalid','athlete');
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000952',true);
select public.accept_org_invitation((select id from public.organization_invitations));
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000951',true);
select public.publish_professional_session('00000000-0000-4000-a000-000000000953',(select id from public.clients where org_id='00000000-0000-4000-a000-000000000953'),current_date+1,'Fuerza de tren superior','3 rondas de 8 repeticiones','00000000-0000-4000-a000-000000000954');
select public.publish_professional_session('00000000-0000-4000-a000-000000000953',(select id from public.clients where org_id='00000000-0000-4000-a000-000000000953'),current_date+1,'Fuerza de tren superior','3 rondas de 8 repeticiones','00000000-0000-4000-a000-000000000954');
do $$ begin if (select count(*) from public.professional_training_sessions)<>1 then raise exception 'duplicate assignment'; end if; end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000952',true);
do $$ begin
 if (select count(*) from public.professional_training_sessions)<>1 then raise exception 'assignment not visible to athlete'; end if;
 begin
 perform public.publish_professional_session('00000000-0000-4000-a000-000000000953',(select id from public.clients),current_date+2,'Malicious session','not allowed','00000000-0000-4000-a000-000000000955');
 raise exception 'athlete published as coach'; exception when insufficient_privilege then null; end;
end $$;
rollback;
select 'professional_sessions_smoke_pass' as result,(select count(*) from public.professional_training_sessions)::int as persisted;
