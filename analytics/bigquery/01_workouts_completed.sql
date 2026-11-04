-- Unique workout_completed events (dedupe by event_id if present; else user+date+params).
-- Denominator notes: only consented/configured clients emit; watch sync may arrive later.
SELECT
  PARSE_DATE('%Y%m%d', event_date) AS day,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'origin_platform') AS origin_platform,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'workout_type') AS workout_type,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'activity_type') AS activity_type,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'activity_family') AS activity_family,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'wod_format') AS wod_format,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_origin_platform') AS session_origin_platform,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'completion_platform') AS completion_platform,
  COUNT(*) AS events
FROM `project.dataset.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name = 'workout_completed'
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
ORDER BY 1 DESC, events DESC;
