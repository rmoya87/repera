-- Recover idempotency guard missing from a partially applied historical attendance migration.
CREATE UNIQUE INDEX IF NOT EXISTS service_bookings_attendance_request_uidx
  ON public.service_bookings(attendance_request_id)
  WHERE attendance_request_id IS NOT NULL;