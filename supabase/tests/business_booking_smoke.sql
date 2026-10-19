-- Safe v1 booking smoke with temporary identities, role impersonation and ROLLBACK.
begin;
insert into auth.users(id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at) values
('00000000-0000-4000-a000-000000000921','00000000-0000-0000-0000-000000000000','authenticated','authenticated','coach-921@example.invalid','',now(),now(),now()),
('00000000-0000-4000-a000-000000000922','00000000-0000-0000-0000-000000000000','authenticated','authenticated','athlete-922@example.invalid','',now(),now(),now());
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000921',true);
insert into public.organizations(id,name,slug,kind,created_by) values
('00000000-0000-4000-a000-000000000923','Gym Booking Smoke','gym-booking-smoke','gym','00000000-0000-4000-a000-000000000921');
select public.issue_org_invitation('00000000-0000-4000-a000-000000000923','athlete-922@example.invalid','athlete');
insert into public.service_occurrences(org_id,coach_user_id,kind,title,starts_at,ends_at,capacity) values
('00000000-0000-4000-a000-000000000923','00000000-0000-4000-a000-000000000921','class','Clase CrossFit',now()+interval '3 days',now()+interval '3 days 1 hour',1),
('00000000-0000-4000-a000-000000000923','00000000-0000-4000-a000-000000000921','appointment','Sesion 1 a 1',now()+interval '4 days',now()+interval '4 days 1 hour',1);
do $$ begin
 begin
 insert into public.service_occurrences(org_id,coach_user_id,kind,title,starts_at,ends_at,capacity)
 values('00000000-0000-4000-a000-000000000923','00000000-0000-4000-a000-000000000921','appointment','Solapamiento',now()+interval '3 days 15 minutes',now()+interval '3 days 45 minutes',1);
 raise exception 'coach overlap accepted';
 exception when exclusion_violation then null; end;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000922',true);
select public.accept_org_invitation((select id from public.organization_invitations where organization_id='00000000-0000-4000-a000-000000000923'));
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000921',true);
select public.grant_complimentary_pass('00000000-0000-4000-a000-000000000923',(select id from public.clients where org_id='00000000-0000-4000-a000-000000000923'),'class',2,now()+interval '60 days');
select public.grant_complimentary_pass('00000000-0000-4000-a000-000000000923',(select id from public.clients where org_id='00000000-0000-4000-a000-000000000923'),'appointment',1,now()+interval '60 days');
select set_config('request.jwt.claim.sub','00000000-0000-4000-a000-000000000922',true);
select public.book_service_occurrence((select id from public.service_occurrences where kind='class'),(select id from public.service_passes where kind='class'),'00000000-0000-4000-a000-000000000926');
select public.book_service_occurrence((select id from public.service_occurrences where kind='class'),(select id from public.service_passes where kind='class'),'00000000-0000-4000-a000-000000000926');
do $$ begin
 if (select count(*) from public.service_bookings where status='booked')<>1 then raise exception 'idempotency failed'; end if;
 if (select remaining_credits from public.service_passes where kind='class')<>1 then raise exception 'double debit'; end if;
 if (select remaining_credits from public.service_passes where kind='appointment')<>1 then raise exception 'wrong wallet debited'; end if;
 begin perform public.book_service_occurrence((select id from public.service_occurrences where kind='class'),(select id from public.service_passes where kind='class'),'00000000-0000-4000-a000-000000000927');
 raise exception 'double booking accepted'; exception when unique_violation then null; end;
end $$;
select public.cancel_service_booking((select id from public.service_bookings),'00000000-0000-4000-a000-000000000928');
do $$ begin
 if (select remaining_credits from public.service_passes where kind='class')<>2 then raise exception 'credit not refunded'; end if;
 if (select count(*) from public.service_credit_ledger where event='booking_debit')<>1 then raise exception 'incorrect debit ledger'; end if;
 if (select count(*) from public.service_credit_ledger where event='cancellation_credit')<>1 then raise exception 'missing refund ledger'; end if;
end $$;
rollback;
select 'business_booking_smoke_pass' as result,
 (select count(*) from public.service_bookings)::int as persisted_bookings,
 (select count(*) from public.service_passes)::int as persisted_passes;
