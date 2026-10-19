-- REPERA NUEVO PROYECTO ÚNICAMENTE · base de datos greenfield
-- ¡NO EJECUTAR SOBRE CAFESITO! ¡NO CONCATENAR CON LA MIGRACIÓN LEGACY!
-- 2026-10-19. Sin integración de pagos reales; escrituras de dinero/reservas vía RPC/Edge.
-- Ejecutar con rol postgres en el nuevo proyecto Repera independiente, tras revisión.
begin;
create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.platform_admins (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  enabled boolean not null default true,
  granted_at timestamptz not null default now()
);
create table public.organizations (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.profiles(id),
 kind text not null check (kind in ('gym','coach')),
 name text not null check (length(trim(name)) between 2 and 150),
 email text, vat_number text, timezone text not null default 'Europe/Madrid',
 status text not null default 'active' check (status in ('active','suspended','closed')),
 stripe_connect_account_id text unique, created_at timestamptz not null default now(),
 unique(id,owner_id)
);
create table public.org_members (
 org_id uuid not null references public.organizations(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 role text not null check(role in ('owner','manager','coach','reception','billing')),
 status text not null default 'active' check(status in ('active','invited','revoked')),
 created_at timestamptz not null default now(), primary key(org_id,user_id)
);

-- SECURITY DEFINER lee únicamente la pertenencia. Nunca usar user_metadata como fuente de permisos.
create function public.is_org_staff(_org uuid) returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.org_members m where m.org_id=_org and m.user_id=(select auth.uid()) and m.status='active');
$$;
create function public.can_manage_org(_org uuid) returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.org_members m where m.org_id=_org and m.user_id=(select auth.uid()) and m.status='active' and m.role in ('owner','manager'));
$$;
create function public.can_finance_org(_org uuid) returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.org_members m where m.org_id=_org and m.user_id=(select auth.uid()) and m.status='active' and m.role in ('owner','manager','billing'));
$$;
create function public.is_platform_admin() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.platform_admins a where a.user_id=(select auth.uid()) and a.enabled);
$$;

create function public.create_profile_for_auth_user() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'display_name','')) on conflict(id) do nothing;
 return new;
end; $$;
create trigger auth_profile_created after insert on auth.users for each row execute function public.create_profile_for_auth_user();
create function public.bootstrap_org_owner() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.org_members(org_id,user_id,role,status) values(new.id,new.owner_id,'owner','active');
 return new;
end; $$;
create trigger org_owner_created after insert on public.organizations for each row execute function public.bootstrap_org_owner();

create table public.locations (
 id uuid primary key default gen_random_uuid(),org_id uuid not null references public.organizations(id),
 name text not null,capacity integer not null default 1 check(capacity>0),address text,
 created_at timestamptz not null default now(),unique(org_id,id)
);
create table public.clients (
 id uuid primary key default gen_random_uuid(),org_id uuid not null references public.organizations(id),
 user_id uuid references public.profiles(id),full_name text not null, email text, phone text,
 status text not null default 'trial' check(status in ('lead','trial','active','paused','cancelled')),
 private_notes text, created_at timestamptz not null default now(),
 unique(org_id,id),unique(org_id,user_id)
);
create unique index clients_email_per_org on public.clients(org_id,lower(email)) where email is not null;
create table public.client_data_shares (
 id uuid primary key default gen_random_uuid(),org_id uuid not null,
 client_id uuid not null,user_id uuid not null references public.profiles(id),
 scope text not null check(scope in ('workout_history','progress','body_metrics')),
 granted_at timestamptz not null default now(),revoked_at timestamptz,
 foreign key(org_id,client_id) references public.clients(org_id,id) on delete cascade,
 unique(org_id,client_id,scope)
);
create table public.coaching_groups (
 id uuid primary key default gen_random_uuid(),org_id uuid not null references public.organizations(id),
 name text not null, created_at timestamptz not null default now(),unique(org_id,id)
);
create table public.coaching_group_clients (
 org_id uuid not null,group_id uuid not null,client_id uuid not null,
 primary key(org_id,group_id,client_id),
 foreign key(org_id,group_id) references public.coaching_groups(org_id,id) on delete cascade,
 foreign key(org_id,client_id) references public.clients(org_id,id) on delete cascade
);
create table public.program_templates (
 id uuid primary key default gen_random_uuid(),org_id uuid not null references public.organizations(id),
 title text not null,weeks smallint not null check(weeks between 1 and 52),
 content jsonb not null default '[]'::jsonb check(jsonb_typeof(content)='array'),
 status text not null default 'draft' check(status in ('draft','published','archived')),
 revision integer not null default 1 check(revision>0), created_by uuid references public.profiles(id),
 created_at timestamptz not null default now(),unique(org_id,id)
);
create table public.program_assignments (
 id uuid primary key default gen_random_uuid(),org_id uuid not null,client_id uuid not null,template_id uuid not null,
 starts_on date not null,ends_on date,status text not null default 'active' check(status in ('active','paused','ended')),
 overrides jsonb not null default '{}'::jsonb check(jsonb_typeof(overrides)='object'),
 assigned_by uuid references public.profiles(id),created_at timestamptz not null default now(),
 foreign key(org_id,client_id) references public.clients(org_id,id),
 foreign key(org_id,template_id) references public.program_templates(org_id,id),
 check(ends_on is null or ends_on>=starts_on),unique(org_id,client_id,template_id,starts_on)
);
-- iOS/Android: registro de entrenamientos realizado por deportista, no editable por profesional.
create table public.athlete_workout_entries (
 id uuid primary key, owner_id uuid not null references public.profiles(id),
 assignment_id uuid references public.program_assignments(id) on delete set null,
 date date not null, payload jsonb not null,
 device_revision bigint not null default 0, updated_at timestamptz not null default now(),
 unique(owner_id,id)
);
create table public.classes (
 id uuid primary key default gen_random_uuid(),org_id uuid not null references public.organizations(id),
 title text not null,starts_at timestamptz not null,ends_at timestamptz not null,
 capacity smallint not null check(capacity between 1 and 1000),
 location_id uuid, instructor_id uuid references public.profiles(id),
 status text not null default 'scheduled' check(status in ('scheduled','cancelled','finished')),
 created_at timestamptz not null default now(),
 check(ends_at>starts_at),unique(org_id,id),
 foreign key(org_id,location_id) references public.locations(org_id,id)
);
create table public.products (
 id uuid primary key default gen_random_uuid(),org_id uuid not null references public.organizations(id),
 title text not null,mode text not null check(mode in ('credits','unlimited','days_per_week','appointments','drop_in','course')),
 currency text not null default 'EUR',price_cents bigint not null check(price_cents>=0),
 credits integer check(credits>0),validity_days integer not null check(validity_days between 1 and 1095),
 rules jsonb not null default '{}'::jsonb check(jsonb_typeof(rules)='object'),
 auto_renew boolean not null default false,active boolean not null default true,
 created_at timestamptz not null default now(),unique(org_id,id)
);
create table public.client_passes (
 id uuid primary key default gen_random_uuid(),org_id uuid not null,client_id uuid not null,product_id uuid not null,
 starts_on date not null,ends_on date not null,
 status text not null default 'pending' check(status in ('pending','active','frozen','expired','cancelled')),
 stripe_subscription_id text unique,created_at timestamptz not null default now(),unique(org_id,id),
 check(ends_on>=starts_on),
 foreign key(org_id,client_id) references public.clients(org_id,id),
 foreign key(org_id,product_id) references public.products(org_id,id)
);
create table public.credit_ledger (
 id uuid primary key default gen_random_uuid(),org_id uuid not null,pass_id uuid not null,
 delta integer not null check(delta<>0),event_type text not null,
 event_key text not null, created_at timestamptz not null default now(),
 foreign key(org_id,pass_id) references public.client_passes(org_id,id),unique(org_id,pass_id,event_key)
);
create table public.class_bookings (
 id uuid primary key default gen_random_uuid(),org_id uuid not null,class_id uuid not null,
 client_id uuid not null,pass_id uuid,
 status text not null check(status in ('confirmed','waitlist','cancelled','attended','no_show')),
 created_at timestamptz not null default now(),cancelled_at timestamptz,
 foreign key(org_id,class_id) references public.classes(org_id,id),
 foreign key(org_id,client_id) references public.clients(org_id,id),
 foreign key(org_id,pass_id) references public.client_passes(org_id,id),unique(org_id,id)
);
create unique index unique_active_booking on public.class_bookings(org_id,class_id,client_id) where status in ('confirmed','waitlist');
create table public.business_payments (
 id uuid primary key default gen_random_uuid(),org_id uuid not null,client_id uuid not null,
 amount_cents bigint not null check(amount_cents>=0),currency text not null default 'EUR',
 status text not null default 'pending' check(status in ('pending','paid','failed','refunded','partially_refunded')),
 provider text not null check(provider in ('stripe','cash','transfer','external')),
 provider_payment_id text unique,external_reference text,created_at timestamptz not null default now(),
 foreign key(org_id,client_id) references public.clients(org_id,id),unique(org_id,id)
);
create table public.invoice_drafts (
 id uuid primary key default gen_random_uuid(),org_id uuid not null,payment_id uuid,
 client_id uuid not null,body jsonb not null default '{}'::jsonb,
 status text not null default 'draft' check(status in ('draft','ready','cancelled')),
 created_at timestamptz not null default now(),
 foreign key(org_id,payment_id) references public.business_payments(org_id,id),
 foreign key(org_id,client_id) references public.clients(org_id,id)
);
-- Facturas emitidas: SOLO el servicio fiscal integrado, con registros inmutables/versionados.
create table public.issued_invoices (
 id uuid primary key default gen_random_uuid(),org_id uuid not null references public.organizations(id),
 provider text not null,external_id text not null,serie text not null,number text not null,
 issued_at timestamptz not null, gross_cents bigint not null,
 immutable_payload jsonb not null,created_at timestamptz not null default now(),
 unique(org_id,serie,number),unique(provider,external_id)
);
create table public.audit_events (
 id bigint generated always as identity primary key,org_id uuid references public.organizations(id),
 actor_id uuid references public.profiles(id),action text not null,
 resource_type text,resource_id uuid,metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table public.idempotency_keys (
 scope text not null,key text not null,result jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),primary key(scope,key)
);

-- Campos de identidad no se reasignan desde un navegador autenticado.
create function public.prevent_sensitive_relinks() returns trigger language plpgsql set search_path = '' as $$
begin
 if TG_TABLE_NAME = 'organizations' and new.owner_id is distinct from old.owner_id then
   raise exception 'Transferir el owner exige un procedimiento administrativo auditado';
 end if;
 if TG_TABLE_NAME = 'clients' and new.user_id is distinct from old.user_id then
   raise exception 'La vinculación del deportista requiere un flujo de aceptación verificado';
 end if;
 return new;
end; $$;
create trigger immutable_org_owner before update on public.organizations for each row execute function public.prevent_sensitive_relinks();
create trigger immutable_client_link before update on public.clients for each row execute function public.prevent_sensitive_relinks();

-- Índices de consultas comunes (no filtrar miles de filas en el navegador).
create index idx_client_org_status on public.clients(org_id,status);
create index idx_assign_client_date on public.program_assignments(client_id,starts_on,ends_on);
create index idx_class_org_start on public.classes(org_id,starts_at);
create index idx_booking_class_status on public.class_bookings(class_id,status);
create index idx_ledger_pass on public.credit_ledger(pass_id);
create index idx_payment_org_date on public.business_payments(org_id,created_at);
create index idx_audit_org_time on public.audit_events(org_id,created_at desc);

-- RLS DENY BY DEFAULT; las políticas no permiten escrituras financieras directas.
do $$ declare t text; begin
 foreach t in array array['profiles','platform_admins','organizations','org_members','locations','clients','client_data_shares','coaching_groups','coaching_group_clients','program_templates','program_assignments','athlete_workout_entries','classes','products','client_passes','credit_ledger','class_bookings','business_payments','invoice_drafts','issued_invoices','audit_events','idempotency_keys'] loop
 execute format('alter table public.%I enable row level security',t);
 end loop;
end $$;
create policy profile_self_read on public.profiles for select to authenticated using(id=(select auth.uid()));
create policy profile_self_update on public.profiles for update to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
create policy admin_self_read on public.platform_admins for select to authenticated using(user_id=(select auth.uid()));
create policy org_read on public.organizations for select to authenticated using(public.is_org_staff(id));
create policy org_create on public.organizations for insert to authenticated with check(owner_id=(select auth.uid()));
create policy org_update on public.organizations for update to authenticated using(public.can_manage_org(id)) with check(public.can_manage_org(id));
create policy membership_read on public.org_members for select to authenticated using(user_id=(select auth.uid()) or public.can_manage_org(org_id));
-- Altas de trabajadores/roles únicamente por Edge Function con autorización, no por cliente.
create policy locations_read on public.locations for select to authenticated using(public.is_org_staff(org_id));
create policy locations_write on public.locations for all to authenticated using(public.can_manage_org(org_id)) with check(public.can_manage_org(org_id));
create function public.is_linked_client(_client uuid) returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.clients c where c.id=_client and c.user_id=(select auth.uid()));
$$;
create policy client_read on public.clients for select to authenticated using(public.is_org_staff(org_id) or user_id=(select auth.uid()));
create policy client_insert on public.clients for insert to authenticated with check(public.can_manage_org(org_id) and user_id is null);
create policy client_update on public.clients for update to authenticated using(public.can_manage_org(org_id)) with check(public.can_manage_org(org_id));
create policy shares_read on public.client_data_shares for select to authenticated using(user_id=(select auth.uid()) or public.can_manage_org(org_id));
-- Los consentimientos se registran mediante endpoint autenticado del propio deportista.
create policy groups_read on public.coaching_groups for select to authenticated using(public.is_org_staff(org_id));
create policy groups_write on public.coaching_groups for all to authenticated using(public.can_manage_org(org_id)) with check(public.can_manage_org(org_id));
create policy group_clients_read on public.coaching_group_clients for select to authenticated using(public.is_org_staff(org_id));
create policy group_clients_write on public.coaching_group_clients for all to authenticated using(public.can_manage_org(org_id)) with check(public.can_manage_org(org_id));
create policy programs_read on public.program_templates for select to authenticated using(public.is_org_staff(org_id));
create policy programs_write on public.program_templates for all to authenticated using(public.can_manage_org(org_id)) with check(public.can_manage_org(org_id));
create policy assignments_read on public.program_assignments for select to authenticated using(public.is_org_staff(org_id) or public.is_linked_client(client_id));
create policy assignments_write on public.program_assignments for all to authenticated using(public.can_manage_org(org_id)) with check(public.can_manage_org(org_id));
create policy athlete_workout_self_read on public.athlete_workout_entries for select to authenticated using(owner_id=(select auth.uid()));
create policy athlete_workout_self_insert on public.athlete_workout_entries for insert to authenticated with check(owner_id=(select auth.uid()));
create policy athlete_workout_self_update on public.athlete_workout_entries for update to authenticated using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()));
create policy classes_read on public.classes for select to authenticated using(public.is_org_staff(org_id) or exists(select 1 from public.clients c where c.org_id=classes.org_id and c.user_id=(select auth.uid())));
create policy classes_write on public.classes for all to authenticated using(public.can_manage_org(org_id)) with check(public.can_manage_org(org_id));
create policy product_read on public.products for select to authenticated using(public.is_org_staff(org_id) or exists(select 1 from public.clients c where c.org_id=products.org_id and c.user_id=(select auth.uid())));
create policy product_write on public.products for all to authenticated using(public.can_manage_org(org_id)) with check(public.can_manage_org(org_id));
create policy passes_read on public.client_passes for select to authenticated using(public.is_org_staff(org_id) or public.is_linked_client(client_id));
create policy ledger_read on public.credit_ledger for select to authenticated using(public.is_org_staff(org_id) or exists(select 1 from public.client_passes p where p.id=pass_id and public.is_linked_client(p.client_id)));
create policy booking_read on public.class_bookings for select to authenticated using(public.is_org_staff(org_id) or public.is_linked_client(client_id));
create policy payment_read on public.business_payments for select to authenticated using(public.can_finance_org(org_id) or public.is_linked_client(client_id));
create policy draft_read on public.invoice_drafts for select to authenticated using(public.can_finance_org(org_id) or public.is_linked_client(client_id));
create policy issued_read on public.issued_invoices for select to authenticated using(public.can_finance_org(org_id));
create policy audit_read on public.audit_events for select to authenticated using(public.can_manage_org(org_id));
-- Sin políticas INSERT/UPDATE/DELETE sobre payments, passes, bookings, ledger, issued_invoices,
-- platform_admins, audit, idempotency. Escribir vía endpoints/RPC transaccionales con controles.
-- Revocar EXECUTE de funciones sensibles por defecto, asignar sólo tras auditoría.
revoke all on function public.is_org_staff(uuid) from public;
revoke all on function public.can_manage_org(uuid) from public;
revoke all on function public.can_finance_org(uuid) from public;
revoke all on function public.is_platform_admin() from public;
revoke all on function public.is_linked_client(uuid) from public;
grant execute on function public.is_org_staff(uuid),public.can_manage_org(uuid),public.can_finance_org(uuid),public.is_platform_admin(),public.is_linked_client(uuid) to authenticated;
commit;