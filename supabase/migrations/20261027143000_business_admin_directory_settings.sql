-- Repera Business: organisation branding pending registration and platform contacts.
alter table public.platform_org_provisioning add column if not exists avatar_url text;
create table if not exists public.platform_settings (
  id integer primary key default 1 check(id=1),
  support_email text, support_url text, billing_email text,
  privacy_url text, terms_url text,
  updated_by uuid references auth.users(id), updated_at timestamptz not null default now()
);
alter table public.platform_settings enable row level security;
revoke all on public.platform_settings from public, anon, authenticated;
create policy platform_settings_browser_denied on public.platform_settings
 for all to authenticated using(false) with check(false);
