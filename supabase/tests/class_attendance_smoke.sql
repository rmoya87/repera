-- Smoke lógico (documentación): aplicar en staging con ROLLBACK.
-- No ejecutar contra producción. Valida transiciones booked → attended/no_show
-- sin segundo booking_debit.

-- begin;
-- ... fixtures org/client/occurrence/pass/booking status=booked ...
-- select public.business_mark_class_attendance(v_booking,'attended',gen_random_uuid());
-- -- repetir mismo p_request → mismo id
-- -- segundo status distinto → ALREADY_RECORDED
-- -- cancel_service_booking sobre attended → ATTENDANCE_ALREADY_RECORDED
-- rollback;

select 'class_attendance_smoke_doc_ready' as status;
