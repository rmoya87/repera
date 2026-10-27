-- Avatar del deportista: solo clientes de la organización y profesionales autorizados.
-- Los perfiles ajenos, las relaciones canceladas y los profesionales no asignados quedan excluidos.
create or replace function public.business_client_avatars(p_org uuid)
returns table(client_id uuid, avatar_url text)
language sql stable security definer set search_path = ''
as $$
 select c.id, p.avatar_url
 from public.clients c
 join public.profiles p on p.id = c.user_id
 where c.org_id = p_org
   and c.status in ('active','trial','paused')
   and p.avatar_url is not null and p.avatar_url <> ''
   and auth.uid() is not null
   and (
     private.has_org_role(c.org_id, array['owner','admin','reception']::public.organization_role[])
     or private.is_assigned_coach(c.org_id, c.id)
   );
$$;
revoke all on function public.business_client_avatars(uuid) from public, anon;
grant execute on function public.business_client_avatars(uuid) to authenticated;
