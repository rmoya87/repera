-- Repera Business: private legal data, configurable subscription catalogue and branded photos.
-- Safe additive migration; subscriptions remain intents only, NEVER entitlements.
create table if not exists public.organization_legal_profiles (
  org_id uuid primary key references public.organizations(id) on delete cascade,
  entity_type text not null default 'self_employed' check (entity_type in ('self_employed','company')),
  legal_name text check (legal_name is null or length(btrim(legal_name)) between 2 and 180),
  tax_id text check (tax_id is null or tax_id ~ '^[A-Z0-9-]{5,24}$'),
  representative_name text check (representative_name is null or length(btrim(representative_name)) between 2 and 150),
  contact_name text check (contact_name is null or length(btrim(contact_name)) between 2 and 150),
  billing_email text check (billing_email is null or length(billing_email) <= 180),
  billing_address text check (billing_address is null or length(billing_address) <= 300),
  postal_code text check (postal_code is null or length(postal_code) <= 20),
  city text check (city is null or length(city) <= 100),
  province text check (province is null or length(province) <= 100),
  country text not null default 'ES' check (country ~ '^[A-Z]{2}$'),
  updated_at timestamptz not null default now()
);
alter table public.organization_legal_profiles enable row level security;
create policy business_legal_managers_read on public.organization_legal_profiles for select to authenticated
 using (private.has_org_role(org_id,array['owner','admin']::public.organization_role[]));
create policy business_legal_managers_insert on public.organization_legal_profiles for insert to authenticated
 with check (private.has_org_role(org_id,array['owner','admin']::public.organization_role[]));
create policy business_legal_managers_update on public.organization_legal_profiles for update to authenticated
 using (private.has_org_role(org_id,array['owner','admin']::public.organization_role[]))
 with check (private.has_org_role(org_id,array['owner','admin']::public.organization_role[]));
revoke all on public.organization_legal_profiles from public,anon,authenticated;
grant select on public.organization_legal_profiles to authenticated;
grant insert(org_id,entity_type,legal_name,tax_id,representative_name,contact_name,billing_email,billing_address,postal_code,city,province,country) on public.organization_legal_profiles to authenticated;
grant update(entity_type,legal_name,tax_id,representative_name,contact_name,billing_email,billing_address,postal_code,city,province,country) on public.organization_legal_profiles to authenticated;

-- Use the existing verified platform-admin trust root (not role selectors or user_metadata).
create or replace function private.is_repera_platform_admin()
returns boolean language sql stable security definer set search_path=''
as $$
 select auth.uid() is not null and exists (
   select 1 from public.profiles p join auth.users u on u.id=p.id
   where p.id=auth.uid() and p.role='platform_admin' and
         lower(u.email)='rmoya87@gmail.com' and u.email_confirmed_at is not null
 );
$$;
revoke all on function private.is_repera_platform_admin() from public,anon;
grant execute on function private.is_repera_platform_admin() to authenticated;

create table if not exists public.business_plans(
 plan_key text primary key check(plan_key ~ '^[a-z][a-z0-9_]{2,39}$'),
 audience text not null check(audience in ('personal_trainer','gym')),
 title text not null check(length(btrim(title)) between 2 and 70),
 description text not null default '' check(length(description)<=250),
 monthly_price_cents integer not null check(monthly_price_cents between 0 and 10000000),
 max_clients integer check(max_clients between 1 and 100000),
 discount_percent smallint not null default 0 check(discount_percent between 0 and 90),
 discount_months smallint not null default 0 check(discount_months between 0 and 12),
 is_active boolean not null default true,
 display_order smallint not null default 0,
 updated_at timestamptz not null default now()
);
alter table public.business_plans enable row level security;
create policy business_plans_read on public.business_plans for select to authenticated
 using (is_active or private.is_repera_platform_admin());
create policy business_plans_insert on public.business_plans for insert to authenticated
 with check (private.is_repera_platform_admin());
create policy business_plans_update on public.business_plans for update to authenticated
 using (private.is_repera_platform_admin()) with check (private.is_repera_platform_admin());
revoke all on public.business_plans from public,anon,authenticated;
grant select on public.business_plans to authenticated;
grant insert(plan_key,audience,title,description,monthly_price_cents,max_clients,discount_percent,discount_months,is_active,display_order) on public.business_plans to authenticated;
grant update(audience,title,description,monthly_price_cents,max_clients,discount_percent,discount_months,is_active,display_order) on public.business_plans to authenticated;

insert into public.business_plans(plan_key,audience,title,description,monthly_price_cents,max_clients,discount_percent,discount_months,display_order) values
 ('trainer_5','personal_trainer','Inicio','Hasta 5 clientes',1400,5,0,0,10),
 ('trainer_50','personal_trainer','Profesional','Hasta 50 clientes',5000,50,0,0,20),
 ('trainer_75','personal_trainer','Crecimiento','Hasta 75 clientes',6500,75,0,0,30),
 ('gym_basic','gym','Básico','Hasta 35 usuarios',3900,35,50,2,10),
 ('gym_advanced','gym','Avanzado','Hasta 70 usuarios',6900,70,50,2,20),
 ('gym_expert','gym','Experto','Usuarios ilimitados · una sede',11900,null,50,2,30)
on conflict (plan_key) do nothing;

-- Existing subscription requests are still not purchases. Future custom keys are permitted
-- only when the plan exists and is offered to this professional category.
alter table public.business_subscription_intents drop constraint if exists business_subscription_intents_plan_key_check;
alter table public.business_subscription_intents
 add constraint business_subscription_intents_plan_fk foreign key(plan_key) references public.business_plans(plan_key);
drop policy if exists business_subscription_intents_insert on public.business_subscription_intents;
create policy business_subscription_intents_insert on public.business_subscription_intents
 for insert to authenticated with check(
 actor=auth.uid() and private.has_org_role(org_id,array['owner','admin']::public.organization_role[])
 and exists(select 1 from public.business_plans p join public.organizations o on o.id=business_subscription_intents.org_id
            where p.plan_key=business_subscription_intents.plan_key and p.is_active
            and p.audience=case when o.kind='personal_trainer' then 'personal_trainer' else 'gym' end)
);

-- Public columns are editable only by owners/managers under existing RLS.
grant update(name,public_email,phone,website,address,description,timezone,avatar_url,tagline,is_discoverable)
 on public.organizations to authenticated;

-- Branding is public by design (appears in the athlete directory), but only active owners/managers upload.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('business-branding','business-branding',true,1048576,array['image/jpeg']::text[])
on conflict(id) do update set public=excluded.public,file_size_limit=excluded.file_size_limit,
 allowed_mime_types=excluded.allowed_mime_types;
create policy business_branding_select on storage.objects for select to public
 using(bucket_id='business-branding');
create policy business_branding_insert on storage.objects for insert to authenticated
 with check(bucket_id='business-branding' and storage.filename(name) in ('logo.jpg','trainer.jpg')
 and exists(select 1 from public.organization_memberships m
   where m.organization_id::text=(storage.foldername(name))[1] and m.user_id=auth.uid()
     and m.role in ('owner','admin') and m.status='active'));
create policy business_branding_update on storage.objects for update to authenticated
 using(bucket_id='business-branding' and exists(select 1 from public.organization_memberships m
   where m.organization_id::text=(storage.foldername(name))[1] and m.user_id=auth.uid()
     and m.role in ('owner','admin') and m.status='active'))
 with check(bucket_id='business-branding' and storage.filename(name) in ('logo.jpg','trainer.jpg')
 and exists(select 1 from public.organization_memberships m
   where m.organization_id::text=(storage.foldername(name))[1] and m.user_id=auth.uid()
     and m.role in ('owner','admin') and m.status='active'));

notify pgrst,'reload schema';
