-- Top sports by unique workout_completed (activity_type catalog IDs only).
SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'activity_type') AS activity_type,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'activity_family') AS activity_family,
  COUNT(*) AS completions
FROM `project.dataset.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name = 'workout_completed'
  AND (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'activity_type') IS NOT NULL
GROUP BY 1, 2
ORDER BY completions DESC
LIMIT 50;
