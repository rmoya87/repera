-- Invitation, acceptance and user-link isolation. Run in a controlled project.
begin;
insert into auth.users(id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at)
values
('00000000-0000-4000-a000-000000000711','00000000-0000-0000-0000-000000000000','authenticated','authenticated','invite-owner@example.invalid','',now(),now(),now()),
('00000000-0000-4000-a000-000000000712','00000000-0000-0000-0000-000000000000','authenticated','authenticated','invite-athlete@example.invalid','',now(),now(),now()),
('00000000-0000-4000-a000-000000000713','00000000-0000-0000-0000-000000000000','authenticated','authenticated','invite-stranger@example.invalid','',now(),now(),now());
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000711',true);
insert into public.organizations(id,name,slug,kind,created_by)
values('00000000-0000-4000-a000-000000000714','Centro Invitaciones','centro-invitaciones','gym','00000000-0000-4000-a000-000000000711');
insert into public.clients(org_id,created_by,name,email)
values('00000000-0000-4000-a000-000000000714','00000000-0000-4000-a000-000000000711','Atleta invitado','invite-athlete@example.invalid');
select public.issue_org_invitation('00000000-0000-4000-a000-000000000714','INVITE-ATHLETE@EXAMPLE.INVALID','athlete');
do $$ begin
 if (select count(*) from public.organization_invitations)<>1 then raise exception 'owner invite unreadable'; end if;
 if has_table_privilege(current_user,'public.organization_invitations','INSERT') then raise exception 'direct invitation insert'; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000713',true);
do $$ begin
 if (select count(*) from public.organization_invitations)<>0 then raise exception 'invitation leaked'; end if;
 begin perform public.issue_org_invitation('00000000-0000-4000-a000-000000000714','other@example.invalid','coach');
 raise exception 'unauthorized issue allowed'; exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000712',true);
do $$ declare inv uuid; begin
 select id into inv from public.organization_invitations;
 if inv is null then raise exception 'recipient cannot read invitation'; end if;
 perform public.accept_org_invitation(inv);
 if not exists(select 1 from public.organization_memberships where organization_id='00000000-0000-4000-a000-000000000714' and user_id=auth.uid() and role='athlete' and status='active') then raise exception 'membership missing'; end if;
 if not exists(select 1 from public.clients where org_id='00000000-0000-4000-a000-000000000714' and user_id=auth.uid() and status='active') then raise exception 'client not linked'; end if;
 begin perform public.accept_org_invitation(inv);
 raise exception 'replay accepted'; exception when invalid_parameter_value then null; end;
end $$;
rollback;
select 'invitation_rls_smoke_pass' as result, (select count(*) from public.organization_invitations)::int as persisted_invites;
