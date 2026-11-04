/**
 * Product metrics for Repera Business console (GA4 gtag when configured).
 * Allowlisted event names only — never class titles, org names, or PII.
 */
const ALLOWED = new Set([
  'login',
  'sign_up',
  'class_booking_confirmed',
  'class_booking_cancelled',
  'class_attended',
  'appointment_confirmed',
  'operation_failed',
  'ui_interaction'
]);

const ALLOWED_KEYS = new Set([
  'feature_area', 'result', 'service_kind', 'error_code',
  'interaction_type', 'component_id', 'action_name', 'entry_point'
]);

function sanitize(params = {}) {
  const out = {};
  for (const [key, value] of Object.entries(params)) {
    if (!ALLOWED_KEYS.has(key)) continue;
    if (typeof value !== 'string') continue;
    if (!/^[a-zA-Z0-9_]{1,40}$/.test(value)) continue;
    out[key] = value;
  }
  return out;
}

export function trackProductEvent(event, params = {}) {
  if (!ALLOWED.has(event)) return;
  const payload = sanitize(params);
  try {
    if (typeof window !== 'undefined' && typeof window.gtag === 'function') {
      window.gtag('event', event, payload);
    }
  } catch {
    // Telemetry must never break console workflows.
  }
}
