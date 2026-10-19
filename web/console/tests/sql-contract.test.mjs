import test from 'node:test';import assert from 'node:assert/strict';import {readFileSync} from 'node:fs';
const root=new URL('../../../supabase/repera-greenfield/',import.meta.url);
const initial=readFileSync(new URL('0001_business_foundation.sql',root),'utf8');
const booking=readFileSync(new URL('0002_booking_transactions.sql',root),'utf8');
test('esquema no contiene permisos globales legados en la nueva base',()=>{
 assert.doesNotMatch(initial,/current_role\s*\(/);assert.doesNotMatch(initial,/profiles_select_own_or_staff|workouts_owner_all/);
 for(const table of ['profiles','organizations','org_members','clients','program_assignments','classes','class_bookings','client_passes','credit_ledger','business_payments'])assert.ok(initial.includes(`'${table}'`),table);
});
test('reserva SQL usa bloqueo por clase, autorización, ledger e idempotencia',()=>{
 for(const clause of ['for update','auth.uid()','public.is_booking_operator','public.idempotency_keys','public.credit_ledger','public.audit_events','NO_VALID_PASS','ALREADY_BOOKED'])assert.ok(booking.toLowerCase().includes(clause.toLowerCase()),clause);
 assert.match(booking,/revoke all on function public\.book_class/);
 assert.match(booking,/revoke all on function public\.cancel_class_booking/);
});
test('RLS de notificaciones y permisos de campos sensibles',()=>{
 assert.match(booking,/alter table public\.notification_outbox enable row level security/);
 assert.match(booking,/PROTECTED_ORGANIZATION_FIELD/);
 assert.match(booking,/private_notes_read/);
 assert.match(booking,/staff_client_assignments/);
});