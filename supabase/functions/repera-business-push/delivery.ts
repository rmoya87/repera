export type DevicePlatform = "ios" | "android";
export type DeviceRow = { id: string; token: string; platform: DevicePlatform; environment?: string };
export type Provider = "fcm" | "apns";

/** Result of a single provider call, normalised so policy can be unit-tested. */
export type SendResult =
  | { kind: "delivered"; code: string }
  | { kind: "invalid_token"; code: string }
  | { kind: "retry"; code: string }
  | { kind: "not_configured"; code: string };

export type JobOutcome = "sent" | "retry" | "failed" | "skipped";

const APNS_HEX = /^[0-9A-Fa-f]{64,200}$/;
const FCM_TOKEN = /^[A-Za-z0-9_:-]{100,4096}$/;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export const isUuid = (value: unknown): value is string => typeof value === "string" && UUID.test(value);

/** iOS without Firebase registers raw APNs hex tokens; FCM tokens go through FCM on any platform. */
export function providerFor(device: DeviceRow): Provider | null {
  if (device.platform === "ios" && APNS_HEX.test(device.token)) return "apns";
  if (FCM_TOKEN.test(device.token)) return "fcm";
  return null;
}

export function classifyFcm(status: number, body: unknown): SendResult {
  if (status >= 200 && status < 300) return { kind: "delivered", code: "FCM_OK" };
  const error = (body as { error?: { status?: string; message?: string; details?: unknown[] } })?.error;
  const details = Array.isArray(error?.details) ? error!.details : [];
  const fcmCode = details
    .map((d) => (d as { errorCode?: string })?.errorCode)
    .find((c): c is string => typeof c === "string");
  if (status === 404 || fcmCode === "UNREGISTERED") return { kind: "invalid_token", code: "FCM_UNREGISTERED" };
  if (status === 400 && (fcmCode === "INVALID_ARGUMENT" || error?.status === "INVALID_ARGUMENT") &&
    /registration token/i.test(error?.message ?? "")) {
    return { kind: "invalid_token", code: "FCM_INVALID_TOKEN" };
  }
  if (fcmCode === "SENDER_ID_MISMATCH") return { kind: "invalid_token", code: "FCM_SENDER_MISMATCH" };
  if (status === 401 || status === 403) return { kind: "retry", code: "FCM_AUTH" };
  if (status === 429 || status >= 500) return { kind: "retry", code: `FCM_${status}` };
  return { kind: "retry", code: `FCM_${status}` };
}

export function classifyApns(status: number, reason: string | undefined): SendResult {
  if (status === 200) return { kind: "delivered", code: "APNS_OK" };
  if (status === 410) return { kind: "invalid_token", code: "APNS_UNREGISTERED" };
  if (status === 400 && (reason === "BadDeviceToken" || reason === "DeviceTokenNotForTopic")) {
    return { kind: "invalid_token", code: `APNS_${reason}` };
  }
  if (status === 403) return { kind: "retry", code: `APNS_${reason || "AUTH"}` };
  return { kind: "retry", code: `APNS_${status}${reason ? `_${reason}` : ""}`.slice(0, 64) };
}

/** Any delivery wins; otherwise transient errors retry, unconfigured providers wait, dead tokens fail. */
export function aggregate(results: SendResult[]): { outcome: JobOutcome; code: string } {
  if (!results.length) return { outcome: "failed", code: "NO_DEVICES" };
  const delivered = results.find((r) => r.kind === "delivered");
  if (delivered) return { outcome: "sent", code: delivered.code };
  const retry = results.find((r) => r.kind === "retry");
  if (retry) return { outcome: "retry", code: retry.code };
  const notConfigured = results.find((r) => r.kind === "not_configured");
  if (notConfigured) return { outcome: "skipped", code: notConfigured.code };
  return { outcome: "failed", code: "ALL_TOKENS_INVALID" };
}

export type ReminderKind = "class_reminder_60" | "appointment_reminder_60" | "starts_soon";

export function reminderMessage(kind: string, occurrenceTitle: unknown): { title: string; body: string } {
  const name = typeof occurrenceTitle === "string" && occurrenceTitle.trim()
    ? occurrenceTitle.trim().slice(0, 80)
    : null;
  switch (kind) {
    case "appointment_reminder_60":
      return { title: "Tu cita empieza en 1 hora", body: name ?? "Revisa los detalles en Repera." };
    case "starts_soon":
      return { title: "Tu sesión empieza pronto", body: name ?? "Revisa los detalles en Repera." };
    default:
      return { title: "Tu clase empieza en 1 hora", body: name ?? "Revisa los detalles en Repera." };
  }
}

async function digest(value: string): Promise<Uint8Array> {
  return new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value)));
}

/** Compares fixed-length digests so timing does not leak the secret length or prefix. */
export async function constantTimeEqual(a: string, b: string): Promise<boolean> {
  const [x, y] = await Promise.all([digest(a), digest(b)]);
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i];
  return diff === 0;
}
