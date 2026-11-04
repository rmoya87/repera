-- Funnel Center: reservas vs asistencia (sin nombres de clase/org).
-- Requiere exportación GA4 → BigQuery.
SELECT
  event_date,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'origin_platform') AS origin_platform,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'service_kind') AS service_kind,
  event_name,
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `PROJECT.DATASET.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name IN (
    'class_booking_requested',
    'class_booking_confirmed',
    'class_waitlist_joined',
    'class_booking_cancelled',
    'class_attended',
    'appointment_confirmed'
  )
GROUP BY 1, 2, 3, 4
ORDER BY 1 DESC, 5 DESC;
