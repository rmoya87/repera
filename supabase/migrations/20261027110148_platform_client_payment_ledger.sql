-- Client-to-business transactions are distinct from Repera's B2B subscriptions.
-- Payment events must be ingested by a trusted provider webhook / service role,
-- not confirmed by a browser or a success-page redirect.
create table if not exists public.business_client_payments(
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null references public.organizations(id) on delete restrict,
 client_id uuid references public.clients(id) on delete set null,
 provider text not null check(provider in ('stripe_connect','external_verified')),
 external_payment_id text not null,
 amount_cents bigint not null check(amount_cents>=0),
 currency text not null default 'EUR' check(currency ~ '^[A-Z]{3}$'),
 status text not null check(status in ('pending','paid','failed','refunded','partially_refunded')),
 created_at timestamptz not null default now(),paid_at timestamptz,
 unique(provider,external_payment_id)
);
create index if not exists business_client_payments_org_date_idx on public.business_client_payments(org_id,created_at desc);
alter table public.business_client_payments enable row level security;
revoke all on public.business_client_payments from public,anon,authenticated;
grant select,insert,update on public.business_client_payments to service_role;
create policy business_client_payments_deny_browser on public.business_client_payments
 for all to authenticated using(false) with check(false);
-- Explicit deny policies document the intention and suppress the 'no policy' advisor notice.
create policy platform_org_controls_deny_browser on public.platform_org_controls
 for all to authenticated using(false) with check(false);
create policy platform_admin_events_deny_browser on public.platform_admin_events
 for all to authenticated using(false) with check(false);
create policy platform_org_provisioning_deny_browser on public.platform_org_provisioning
 for all to authenticated using(false) with check(false);
create policy platform_admin_delegations_deny_browser on public.platform_admin_delegations
 for all to authenticated using(false) with check(false);
create policy platform_billing_payments_deny_browser on public.platform_billing_payments
 for all to authenticated using(false) with check(false);

create or replace function private.platform_admin_finances()
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501'; end if;
 return jsonb_build_object(
  'payments',coalesce((select jsonb_agg(jsonb_build_object(
   'id',p.id,'org_id',p.org_id,'amount_cents',p.amount_cents,'currency',p.currency,
   'status',p.status,'provider',p.provider,'created_at',p.created_at,'paid_at',p.paid_at
   ) order by p.created_at desc) from public.platform_billing_payments p),'[]'::jsonb),
  'client_payments',coalesce((select jsonb_agg(jsonb_build_object(
   'id',c.id,'org_id',c.org_id,'amount_cents',c.amount_cents,'currency',c.currency,
   'status',c.status,'provider',c.provider,'created_at',c.created_at,'paid_at',c.paid_at
   ) order by c.created_at desc) from public.business_client_payments c),'[]'::jsonb),
  'intents',coalesce((select jsonb_agg(jsonb_build_object(
    'id',i.id,'org_id',i.org_id,'plan_key',i.plan_key,'status',i.status,'created_at',i.created_at
   ) order by i.created_at desc) from public.business_subscription_intents i),'[]'::jsonb)
 );
end $$;
notify pgrst,'reload schema';
