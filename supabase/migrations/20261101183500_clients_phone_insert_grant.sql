-- Permitir guardar móvil al crear la ficha (invitaciones WhatsApp).
grant insert(org_id,created_by,name,email,phone,status) on public.clients to authenticated;
