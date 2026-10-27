-- Global administration: auditable, narrowly-scoped operational 360 views.
-- No passwords, session secrets, token hashes, IP logs, or private HealthKit data.
create or replace function private.platform_admin_center_detail(p_org uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 if not private.is_repera_platform_admin() then
  raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';
 end if;
 if not exists(select 1 from public.organizations where id=p_org) then
  raise exception 'CENTER_NOT_FOUND' using errcode='22023';
 end if;
 select jsonb_build_object(
  'legal',(select to_jsonb(l) from public.organization_legal_profiles l where l.org_id=p_org),
  'center',(select jsonb_build_object('name',o.name,'kind',o.kind,'created_at',o.created_at,
   'updated_at',o.updated_at,'is_discoverable',o.is_discoverable,'tagline',o.tagline,
   'avatar_url',o.avatar_url,'public_email',o.public_email,'phone',o.phone,
   'website',o.website,'address',o.address,'description',o.description,'timezone',o.timezone)
    from public.organizations o where o.id=p_org),
  'team',coalesce((select jsonb_agg(jsonb_build_object(
    'user_id',m.user_id,'name',coalesce(nullif(pr.display_name,''),u.raw_user_meta_data->>'name',u.email),
    'email',u.email,'avatar_url',coalesce(pr.avatar_url,u.raw_user_meta_data->>'avatar_url'),
    'role',m.role,'status',m.status,'since',m.created_at) order by m.created_at desc)
   from public.organization_memberships m join auth.users u on u.id=m.user_id
   left join public.profiles pr on pr.id=m.user_id where m.organization_id=p_org),'[]'::jsonb),
  'clients',coalesce((select jsonb_agg(jsonb_build_object(
   'id',c.id,'user_id',c.user_id,'name',c.name,'email',c.email,
   'phone',c.phone,'avatar_url',c.avatar_url,'status',c.status,'created_at',c.created_at)
   order by c.created_at desc) from public.clients c where c.org_id=p_org),'[]'::jsonb),
  'groups',coalesce((select jsonb_agg(jsonb_build_object(
   'id',g.id,'name',g.name,'description',g.description,'created_at',g.created_at)
   order by g.created_at desc) from public.business_training_groups g where g.org_id=p_org),'[]'::jsonb),
  'services',coalesce((select jsonb_agg(jsonb_build_object(
   'id',s.id,'title',s.title,'kind',s.kind,'status',s.status,'starts_at',s.starts_at,
   'ends_at',s.ends_at,'capacity',s.capacity) order by s.starts_at desc)
   from (select * from public.service_occurrences where org_id=p_org order by starts_at desc limit 100) s),'[]'::jsonb),
  'payments',coalesce((select jsonb_agg(jsonb_build_object('amount_cents',p.amount_cents,
   'currency',p.currency,'status',p.status,'paid_at',p.paid_at,'provider',p.provider)
   order by p.created_at desc)
   from (select * from public.platform_billing_payments where org_id=p_org
     order by created_at desc limit 50) p),'[]'::jsonb),
  'booking_count',(select count(*) from public.service_bookings b where b.org_id=p_org),
  'training_count',(select count(*) from public.professional_training_sessions t where t.org_id=p_org),
  'client_count',(select count(*) from public.clients c where c.org_id=p_org),
  'registration',(select jsonb_build_object('status',p.status,'email',p.owner_email,
     'created_at',p.created_at,'claimed_at',p.claimed_at)
   from public.platform_org_provisioning p where p.claimed_org_id=p_org
   order by p.created_at desc limit 1)
 ) into result;
 insert into public.platform_admin_events(actor_id,org_id,action,details)
 values(auth.uid(),p_org,'center.detail.read',jsonb_build_object('scope','business_360'));
 return result;
end $$;
revoke all on function private.platform_admin_center_detail(uuid) from public,anon,authenticated;
grant execute on function private.platform_admin_center_detail(uuid) to authenticated;
create or replace function public.platform_admin_center_detail(p_org uuid)
returns jsonb language sql security invoker set search_path='' as $$
 select private.platform_admin_center_detail(p_org)
$$;
revoke all on function public.platform_admin_center_detail(uuid) from public,anon;
grant execute on function public.platform_admin_center_detail(uuid) to authenticated;

create or replace function private.platform_admin_athlete_detail(p_athlete uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 if not private.is_repera_platform_admin() then
  raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';
 end if;
 if not exists(select 1 from auth.users where id=p_athlete) then
  raise exception 'ATHLETE_NOT_FOUND' using errcode='22023';
 end if;
 select jsonb_build_object(
  'account',(select jsonb_build_object('id',u.id,'email',u.email,
    'name',coalesce(nullif(pr.display_name,''),nullif(u.raw_user_meta_data->>'name',''),split_part(u.email,'@',1)),
    'avatar_url',coalesce(pr.avatar_url,u.raw_user_meta_data->>'avatar_url'),
    'role',pr.role,'created_at',u.created_at,'last_sign_in_at',u.last_sign_in_at,
    'email_confirmed_at',u.email_confirmed_at,'profile_updated_at',pr.updated_at)
    from auth.users u left join public.profiles pr on pr.id=u.id where u.id=p_athlete),
  'providers',coalesce((select jsonb_agg(distinct i.provider) from auth.identities i
    where i.user_id=p_athlete),'[]'::jsonb),
  'memberships',coalesce((select jsonb_agg(jsonb_build_object(
   'center_id',m.organization_id,'center_name',o.name,'kind',o.kind,
   'role',m.role,'status',m.status,'created_at',m.created_at)
   order by m.created_at desc) from public.organization_memberships m
   join public.organizations o on o.id=m.organization_id where m.user_id=p_athlete),'[]'::jsonb),
  'client_profiles',coalesce((select jsonb_agg(jsonb_build_object(
   'id',c.id,'center_id',c.org_id,'center_name',o.name,'name',c.name,
   'status',c.status,'created_at',c.created_at)
   order by c.created_at desc) from public.clients c join public.organizations o on o.id=c.org_id
    where c.user_id=p_athlete),'[]'::jsonb),
  'workout_count',(select count(*) from public.athlete_workouts w where w.owner_id=p_athlete),
  'mirror_count',(select count(*) from public.athlete_workout_mirror w where w.owner_id=p_athlete and w.deleted_at is null),
  'booking_count',(select count(*) from public.service_bookings b
     join public.clients c on c.id=b.client_id where c.user_id=p_athlete),
  'training_count',(select count(*) from public.professional_training_sessions t
     join public.clients c on c.id=t.client_id where c.user_id=p_athlete),
  'programs',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'title',a.title,
    'status',a.status,'primary_goal',a.primary_goal,'start_date',a.start_date,
    'duration_weeks',a.duration_weeks,'updated_at',a.updated_at) order by a.created_at desc)
    from public.athlete_training_programs a where a.owner_id=p_athlete),'[]'::jsonb),
  'training_profile',(select jsonb_build_object(
    'primary_goal',a.primary_goal,'experience_level',a.experience_level,
    'training_days_per_week',a.training_days_per_week,'session_minutes',a.session_minutes,
    'coaching_enabled',a.coaching_enabled,'updated_at',a.updated_at)
    from public.athlete_training_profiles a where a.owner_id=p_athlete),
  'reservations',coalesce((select jsonb_agg(jsonb_build_object(
    'id',r.id,'center_name',o.name,'status',r.status,'booked_at',r.booked_at,
    'cancelled_at',r.cancelled_at) order by r.booked_at desc)
    from (select b.* from public.service_bookings b
      join public.clients c on c.id=b.client_id where c.user_id=p_athlete
      order by b.booked_at desc limit 50) r
    join public.organizations o on o.id=r.org_id),'[]'::jsonb),
  'professional_sessions',coalesce((select jsonb_agg(jsonb_build_object(
   'title',s.title,'status',s.status,'scheduled_date',s.scheduled_date,
   'center_name',o.name,'created_at',s.created_at)
   order by s.scheduled_date desc) from (
     select t.* from public.professional_training_sessions t
     join public.clients c on c.id=t.client_id where c.user_id=p_athlete
     order by t.scheduled_date desc limit 50
   ) s join public.organizations o on o.id=s.org_id),'[]'::jsonb)
 ) into result;
 insert into public.platform_admin_events(actor_id,action,details)
 values(auth.uid(),'athlete.detail.read',jsonb_build_object('athlete_id',p_athlete,'scope','account_360'));
 return result;
end $$;
revoke all on function private.platform_admin_athlete_detail(uuid) from public,anon,authenticated;
grant execute on function private.platform_admin_athlete_detail(uuid) to authenticated;
create or replace function public.platform_admin_athlete_detail(p_athlete uuid)
 returns jsonb language sql security invoker set search_path='' as $$
 select private.platform_admin_athlete_detail(p_athlete)
$$;
revoke all on function public.platform_admin_athlete_detail(uuid) from public,anon;
grant execute on function public.platform_admin_athlete_detail(uuid) to authenticated;

create or replace function private.platform_admin_athlete_workouts(
 p_athlete uuid,p_limit integer default 30,p_offset integer default 0)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 if not private.is_repera_platform_admin() then
   raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';end if;
 if p_limit not between 1 and 50 or p_offset<0 or p_offset>100000 then
   raise exception 'INVALID_PAGINATION' using errcode='22023';end if;
 if not exists(select 1 from auth.users where id=p_athlete) then
   raise exception 'ATHLETE_NOT_FOUND' using errcode='22023';end if;
 select coalesce((select jsonb_agg(jsonb_build_object(
   'id',w.id,'title',w.title,'started_at',w.started_at,'finished_at',w.finished_at,
   'exercises',w.exercises,'wod_results',w.wod_results,
   'created_at',w.created_at,'updated_at',w.updated_at) order by w.started_at desc)
   from (select * from public.athlete_workouts where owner_id=p_athlete
      order by started_at desc limit p_limit offset p_offset) w),'[]'::jsonb) into result;
 insert into public.platform_admin_events(actor_id,action,details)
 values(auth.uid(),'athlete.workouts.read',jsonb_build_object('athlete_id',p_athlete,
  'limit',p_limit,'offset',p_offset));
 return result;
end $;
revoke all on function private.platform_admin_athlete_workouts(uuid,integer,integer)
 from public,anon,authenticated;
grant execute on function private.platform_admin_athlete_workouts(uuid,integer,integer) to authenticated;
create or replace function public.platform_admin_athlete_workouts(
 p_athlete uuid,p_limit integer default 30,p_offset integer default 0)
returns jsonb language sql security invoker set search_path='' as $$
 select private.platform_admin_athlete_workouts(p_athlete,p_limit,p_offset)
$$;
revoke all on function public.platform_admin_athlete_workouts(uuid,integer,integer)
 from public,anon;
grant execute on function public.platform_admin_athlete_workouts(uuid,integer,integer) to authenticated;
notify pgrst,'reload schema';
