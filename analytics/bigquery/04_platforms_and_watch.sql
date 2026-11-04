-- Cortes por plataforma + comandos/ACK de reloj.
SELECT
  event_date,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'origin_platform') AS origin_platform,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_origin_platform') AS session_origin_platform,
  event_name,
  COUNT(*) AS events
FROM `PROJECT.DATASET.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name IN (
    'workout_completed',
    'watch_app_opened',
    'watch_command_used',
    'watch_sync_confirmed',
    'watch_sync_failed',
    'sync_completed',
    'sync_failed'
  )
GROUP BY 1, 2, 3, 4
ORDER BY 1 DESC, 5 DESC;
