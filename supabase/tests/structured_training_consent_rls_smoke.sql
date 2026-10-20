-- Rollback-only smoke: actual privileges, consent, structured publishing, RLS.
begin;
insert into auth.users(id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at) values
('00000000-0000-4000-a000-000000000981','00000000-0000-0000-0000-000000000000','authenticated','authenticated','owner981@example.invalid','',now(),now(),now()),
('00000000-0000-4000-a000-000000000982','00000000-0000-0000-0000-000000000000','authenticated','authenticated','athlete982@example.invalid','',now(),now(),now()),
('00000000-0000-4000-a000-000000000983','00000000-0000-0000-0000-000000000000','authenticated','authenticated','outsider983@example.invalid','',now(),now(),now());
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000981',true);
insert into public.organizations(id,name,slug,kind,created_by)
values('00000000-0000-4000-a000-000000000984','Entrenos QA','entrenos-qa-981','gym','00000000-0000-4000-a000-000000000981');
insert into public.clients(org_id,created_by,name,email,status)
values('00000000-0000-4000-a000-000000000984','00000000-0000-4000-a000-000000000981','Atleta Prueba','athlete982@example.invalid','lead');
select public.issue_org_invitation('00000000-0000-4000-a000-000000000984','athlete982@example.invalid','athlete');
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000982',true);
select public.accept_org_invitation((select id from public.organization_invitations where organization_id='00000000-0000-4000-a000-000000000984' and invited_role='athlete' limit 1));
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000981',true);
select public.publish_structured_professional_session(
 '00000000-0000-4000-a000-000000000984',(select id from public.clients where org_id='00000000-0000-4000-a000-000000000984' and email='athlete982@example.invalid'),
 current_date+1,'Fuerza y WOD','RIR 2','00000000-0000-4000-a000-000000000986','{"schemaVersion":1,"blocks":[{"id":"fef9e3f2-2dc8-4c3b-a47e-6e87fe088169","title":"Fuerza","kind":"strength","exercises":[{"id":"14d3f3aa-73f7-4cc9-a18f-0948fc97925a","source":"catalog","catalogKey":"catalog:Press banca","name":"Press banca","plannedSets":[{"id":"aed5bb0b-d757-474f-aa9c-547ab5b021a3","targetReps":8,"targetRir":2}]}],"movements":[]},{"id":"2fa16dbd-ddd8-4f27-8afc-ddc08d23f958","title":"WOD","kind":"wod","wodFormat":"forTime","rounds":4,"exercises":[],"movements":[{"id":"661ca10d-1c31-45d3-82d0-aed2192fc949","source":"free","name":"Movimiento personalizado","reps":10}]}]}'::jsonb);
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000982',true);
do $$begin
 if (select count(*) from public.professional_training_sessions where org_id='00000000-0000-4000-a000-000000000984' and prescription->>'schemaVersion'='1')<>1 then
 raise exception 'Athlete cannot see structured session';end if;
end$$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000983',true);
do $$begin
 if exists(select 1 from public.professional_training_sessions where org_id='00000000-0000-4000-a000-000000000984') then
 raise exception 'Stranger can see private prescription';end if;
end$$;
rollback;
select 'structured_training_consent_rls_pass' as result;
