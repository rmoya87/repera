-- Ensure trial expiry also blocks indirect reservations, courtesy passes and group creation.
-- Existing bookings may still be cancelled and refunded after expiry.
create trigger trial_gate_new_bookings
 before insert on public.service_bookings
 for each row execute function private.assert_business_trial();

create trigger trial_gate_new_passes
 before insert on public.service_passes
 for each row execute function private.assert_business_trial();

create trigger trial_gate_new_groups
 before insert on public.business_training_groups
 for each row execute function private.assert_business_trial();

create trigger trial_gate_group_members
 before insert on public.business_training_group_members
 for each row execute function private.assert_business_trial();
