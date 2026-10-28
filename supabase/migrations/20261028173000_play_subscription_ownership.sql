-- DRAFT: production application waits for account recreation/retention decision.
create table if not exists public.play_subscription_purchases (
  token_hash text primary key check (token_hash ~ '^[0-9a-f]{64}$'),
  owner_id uuid references auth.users(id) on delete set null,
  product_id text,
  subscription_state text not null,
  expires_at timestamptz,
  linked_token_hash text,
  superseded boolean not null default false,
  verified_at timestamptz not null default now()
);
alter table public.play_subscription_purchases enable row level security;
revoke all on public.play_subscription_purchases from public, anon, authenticated;
grant select, insert, update on public.play_subscription_purchases to service_role;

create or replace function public.claim_play_subscription(
 p_token_hash text, p_owner uuid, p_linked_hash text,
 p_product text, p_state text, p_expiry timestamptz
) returns boolean language plpgsql security definer set search_path = '' as $$
declare current_owner uuid; is_superseded boolean; linked_owner uuid;
begin
 if p_owner is null or p_token_hash !~ '^[0-9a-f]{64}$' or
    (p_linked_hash is not null and p_linked_hash !~ '^[0-9a-f]{64}$') or
    p_token_hash = p_linked_hash then return false; end if;
 -- Lock the pair in lexical order to serialize replacement and restore races.
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(h,0))
 from (select distinct x as h from unnest(array[p_token_hash,p_linked_hash]) x
       where x is not null order by x) locks;
 select owner_id, superseded into current_owner,is_superseded
 from public.play_subscription_purchases where token_hash=p_token_hash for update;
 if found and (current_owner is distinct from p_owner or is_superseded) then return false; end if;
 if p_linked_hash is not null then
   select owner_id into linked_owner from public.play_subscription_purchases
    where token_hash=p_linked_hash for update;
   if found and linked_owner is distinct from p_owner then return false; end if;
   insert into public.play_subscription_purchases(token_hash,owner_id,subscription_state,superseded)
   values(p_linked_hash,p_owner,'REPLACED',true)
   on conflict(token_hash) do update set superseded=true,subscription_state='REPLACED',verified_at=now();
 end if;
 insert into public.play_subscription_purchases(token_hash,owner_id,product_id,subscription_state,expires_at,linked_token_hash)
 values(p_token_hash,p_owner,p_product,p_state,p_expiry,p_linked_hash)
 on conflict(token_hash) do update set product_id=excluded.product_id,
   subscription_state=excluded.subscription_state,expires_at=excluded.expires_at,
   linked_token_hash=excluded.linked_token_hash,verified_at=now();
 return true;
end;$$;
revoke all on function public.claim_play_subscription(text,uuid,text,text,text,timestamptz) from public,anon,authenticated;
grant execute on function public.claim_play_subscription(text,uuid,text,text,text,timestamptz) to service_role;
