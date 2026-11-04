-- Trainer-authored prices are catalog entries, NOT evidence of a payment.
-- Do not issue service_passes from these records without a verified PSP webhook.
create table if not exists public.business_pass_offers(
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  name text not null check (length(btrim(name)) between 2 and 120),
  kind text not null check (kind in ('class','appointment')),
  credits integer not null check (credits between 1 and 1000),
  validity_days integer not null check (validity_days between 1 and 730),
  price_cents integer not null check (price_cents between 0 and 10000000),
  currency text not null default 'EUR' check (currency='EUR'),
  is_active boolean not null default true,
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists business_pass_offers_org_active
  on public.business_pass_offers(org_id,is_active);
alter table public.business_pass_offers enable row level security;
revoke all on public.business_pass_offers from public,anon,authenticated;
grant select,insert,update on public.business_pass_offers to authenticated;
create policy business_pass_offers_read on public.business_pass_offers
for select to authenticated using(
  (is_active and exists (select 1 from public.organization_memberships m
    where m.organization_id=org_id and m.user_id=(select auth.uid())
      and m.status='active'))
  or private.has_org_role(org_id,array['owner','admin']::public.organization_role[])
);
create policy business_pass_offers_insert on public.business_pass_offers
for insert to authenticated with check(
  created_by=(select auth.uid())
  and private.has_org_role(org_id,array['owner','admin']::public.organization_role[])
);
create policy business_pass_offers_update on public.business_pass_offers
for update to authenticated
using(private.has_org_role(org_id,array['owner','admin']::public.organization_role[]))
with check(private.has_org_role(org_id,array['owner','admin']::public.organization_role[]));
notify pgrst,'reload schema';
