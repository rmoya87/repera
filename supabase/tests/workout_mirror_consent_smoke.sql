-- Run as postgres in Supabase Repera. Temporary identities and all state roll back.
begin;
insert into auth.users(id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at) values
('10000000-0000-4000-a000-000000000701','00000000-0000-0000-0000-000000000000','authenticated','authenticated','workoutowner@example.invalid','',now(),now(),now()),
('10000000-0000-4000-a000-000000000702','00000000-0000-0000-0000-000000000000','authenticated','authenticated','workoutathlete@example.invalid','',now(),now(),now()),
('10000000-0000-4000-a000-000000000703','00000000-0000-0000-0000-000000000000','authenticated','authenticated','workoutstranger@example.invalid','',now(),now(),now());
insert into public.organizations(id,name,slug,kind,created_by) values
('10000000-0000-4000-a000-000000000704','QA Gym','qa-gym-workout','gym','10000000-0000-4000-a000-000000000701');
insert into public.organization_memberships(organization_id,user_id,role,status) values
('10000000-0000-4000-a000-000000000704','10000000-0000-4000-a000-000000000702','athlete','active');
insert into public.clients(id,org_id,created_by,user_id,name,email,status) values
('10000000-0000-4000-a000-000000000705','10000000-0000-4000-a000-000000000704',
 '10000000-0000-4000-a000-000000000701','10000000-0000-4000-a000-000000000702',
 'QA Athlete','workoutathlete@example.invalid','active');
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-a000-000000000702',true);
insert into public.athlete_workout_mirror(id,owner_id,title,payload,started_at,finished_at) values
('10000000-0000-4000-a000-000000000706','10000000-0000-4000-a000-000000000702',
'Entrenamiento QA','{"exercises":[{"exercise":{"name":"Press banca"},"loggedSets":[{"reps":8,"weightKg":35}]}],"wodResults":[],"notes":"privado","routePoints":[1,2]}',now()-interval '1 hour',now());
do $$ begin if (select count(*) from public.athlete_workout_mirror)!=1 then raise exception 'own mirror invisible'; end if; end $$;
select set_config('request.jwt.claim.sub','10000000-0000-4000-a000-000000000701',true);
do $$ begin
 if (select count(*) from public.athlete_workout_mirror)!=0 then raise exception 'manager read raw mirror'; end if;
 if exists(select 1 from public.get_shared_athlete_results('10000000-0000-4000-a000-000000000704','10000000-0000-4000-a000-000000000705')) then raise exception 'default sharing was not off'; end if;
end $$;
select set_config('request.jwt.claim.sub','10000000-0000-4000-a000-000000000702',true);
insert into public.athlete_workout_sharing(athlete_id,org_id,enabled) values
('10000000-0000-4000-a000-000000000702','10000000-0000-4000-a000-000000000704',true);
select set_config('request.jwt.claim.sub','10000000-0000-4000-a000-000000000701',true);
do $$ begin
 if (select count(*) from public.get_shared_athlete_results('10000000-0000-4000-a000-000000000704','10000000-0000-4000-a000-000000000705'))<>1 then raise exception 'consent not honored'; end if;
 if exists(select 1 from public.get_shared_athlete_results('10000000-0000-4000-a000-000000000704','10000000-0000-4000-a000-000000000705') where result ? 'notes' or result ? 'routePoints')
 then raise exception 'sensitive data disclosed'; end if;
end $$;
select set_config('request.jwt.claim.sub','10000000-0000-4000-a000-000000000703',true);
do $$ begin
 begin
  perform * from public.get_shared_athlete_results('10000000-0000-4000-a000-000000000704','10000000-0000-4000-a000-000000000705');
  raise exception 'third party bypassed authorization';
 exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub','10000000-0000-4000-a000-000000000702',true);
update public.athlete_workout_sharing set enabled=false where org_id='10000000-0000-4000-a000-000000000704';
select set_config('request.jwt.claim.sub','10000000-0000-4000-a000-000000000701',true);
do $$ begin
 if exists(select 1 from public.get_shared_athlete_results('10000000-0000-4000-a000-000000000704','10000000-0000-4000-a000-000000000705'))
 then raise exception 'revocation failed'; end if;
end $$;
rollback;
select 'workout_private_consent_rls_pass' result, (select count(*) from auth.users)::int as persisted_users;
