-- Real occupied-capacity projection for the athlete without revealing other customers.
-- All final booking checks remain inside book_service_occurrence's locked transaction.
create function private.service_availability(p_org uuid)
returns table(occurrence_id uuid, reserved integer, capacity integer)
language plpgsql stable security definer set search_path=''
as $$
begin
  if auth.uid() is null
     or not private.has_org_role(
       p_org,array['owner','admin','coach','reception','athlete']::public.organization_role[]
     )
  then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  return query
    select o.id, count(b.id)::integer, o.capacity
      from public.service_occurrences o
      left join public.service_bookings b
        on b.occurrence_id=o.id and b.org_id=o.org_id and b.status='booked'
     where o.org_id=p_org and o.status='active'
       and o.starts_at>now() and o.starts_at<now()+interval '60 days'
     group by o.id,o.capacity,o.starts_at
     order by o.starts_at
     limit 500;
end;
$$;
revoke all on function private.service_availability(uuid) from public,anon;
grant execute on function private.service_availability(uuid) to authenticated;
create function public.get_service_availability(p_org uuid)
returns table(occurrence_id uuid, reserved integer, capacity integer)
language sql stable security invoker set search_path=''
as $$ select * from private.service_availability(p_org) $$;
revoke all on function public.get_service_availability(uuid) from public,anon;
grant execute on function public.get_service_availability(uuid) to authenticated;
