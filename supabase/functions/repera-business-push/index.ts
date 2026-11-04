// Claims due booking reminders and delivers them via FCM HTTP v1 (Android / FCM tokens)
// and APNs token auth (iOS raw device tokens). Invoked only by the scheduler with
// `x-repera-cron`; providers without secrets leave jobs pending instead of marking them sent.
import {
  aggregate,
  constantTimeEqual,
  type DeviceRow,
  isUuid,
  providerFor,
  reminderMessage,
  type SendResult,
} from "./delivery.ts";
import { ApnsSender, FcmSender } from "./providers.ts";

const project = Deno.env.get("SUPABASE_URL") || "";
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
const cronSecret = Deno.env.get("REPERA_PUSH_CRON_SECRET") || "";
const fcm = FcmSender.fromEnv(Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") || "", Deno.env.get("FCM_PROJECT_ID") || "");
const apns = ApnsSender.fromEnv(
  Deno.env.get("APNS_KEY_ID") || "",
  Deno.env.get("APNS_TEAM_ID") || "",
  Deno.env.get("APNS_PRIVATE_KEY") || "",
  Deno.env.get("APNS_BUNDLE_ID") || "com.app.repera",
);
const MAX_ATTEMPTS = 5;
const BATCH = 40;

const json = (obj: unknown, status = 200) =>
  new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });

const headers = (extra: Record<string, string> = {}) => ({
  apikey: serviceKey,
  Authorization: `Bearer ${serviceKey}`,
  ...extra,
});

async function rpc(name: string, body: Record<string, unknown>) {
  const res = await fetch(`${project}/rest/v1/rpc/${name}`, {
    method: "POST",
    headers: headers({ "Content-Type": "application/json" }),
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`rpc_${name}_${res.status}`);
  return await res.json().catch(() => null);
}

async function selectOne(table: string, id: string, columns: string) {
  if (!isUuid(id)) return null;
  const res = await fetch(`${project}/rest/v1/${table}?id=eq.${id}&select=${columns}`, { headers: headers() });
  if (!res.ok) throw new Error(`select_${table}_${res.status}`);
  const rows = await res.json();
  return Array.isArray(rows) ? rows[0] ?? null : null;
}

async function tokensFor(userId: string): Promise<DeviceRow[]> {
  if (!isUuid(userId)) return [];
  const res = await fetch(
    `${project}/rest/v1/device_push_tokens?user_id=eq.${userId}&revoked_at=is.null&select=id,token,platform,environment&limit=10`,
    { headers: headers() },
  );
  if (!res.ok) throw new Error(`select_tokens_${res.status}`);
  const rows = await res.json();
  return Array.isArray(rows) ? rows : [];
}

async function recordAttempt(outboxId: string, deviceId: string | null, provider: string, result: SendResult) {
  await fetch(`${project}/rest/v1/notification_attempts`, {
    method: "POST",
    headers: headers({ "Content-Type": "application/json", Prefer: "return=minimal" }),
    body: JSON.stringify({
      outbox_id: outboxId,
      device_token_id: deviceId,
      success: result.kind === "delivered",
      provider,
      provider_code: result.code,
    }),
  });
}

const finish = (id: string, lease: string, outcome: string, code: string | null) =>
  rpc("finish_reminder_delivery", {
    p_outbox: id,
    p_lease: lease,
    p_outcome: outcome,
    p_code: code,
    p_max_attempts: MAX_ATTEMPTS,
  });

type Job = {
  id: string;
  user_id: string;
  org_id: string;
  booking_id: string;
  occurrence_id: string;
  kind: string;
  lease_owner: string;
};

async function deliver(job: Job, counters: Record<string, number>) {
  const booking = await selectOne("service_bookings", job.booking_id, "id,status");
  if (!booking || booking.status !== "booked") {
    await finish(job.id, job.lease_owner, "cancelled", "BOOKING_INACTIVE");
    counters.cancelled++;
    return;
  }
  const occ = await selectOne("service_occurrences", job.occurrence_id, "id,title,starts_at,status");
  if (!occ || occ.status !== "active") {
    await finish(job.id, job.lease_owner, "cancelled", "OCCURRENCE_INACTIVE");
    counters.cancelled++;
    return;
  }
  const startsAt = Date.parse(occ.starts_at);
  if (!Number.isFinite(startsAt) || startsAt <= Date.now()) {
    await finish(job.id, job.lease_owner, "expired", "STARTED");
    counters.expired++;
    return;
  }

  const devices = await tokensFor(job.user_id);
  const message = {
    ...reminderMessage(job.kind, occ.title),
    collapseId: job.id,
    expiresAt: startsAt,
    data: {
      type: "business_reminder",
      kind: job.kind,
      org_id: job.org_id,
      booking_id: job.booking_id,
      occurrence_id: job.occurrence_id,
    },
  };

  const results: SendResult[] = [];
  for (const device of devices) {
    const provider = providerFor(device);
    const sender = provider === "apns" ? apns : provider === "fcm" ? fcm : null;
    let result: SendResult;
    if (!provider) {
      result = { kind: "invalid_token", code: "UNSUPPORTED_TOKEN" };
    } else if (!sender) {
      result = { kind: "not_configured", code: `${provider.toUpperCase()}_NOT_CONFIGURED` };
    } else {
      result = await sender.send(device, message);
    }
    results.push(result);
    if (result.kind !== "not_configured") await recordAttempt(job.id, device.id, provider ?? "none", result);
    if (result.kind === "invalid_token") {
      await rpc("invalidate_push_device", { p_device: device.id, p_reason: result.code });
      counters.invalidTokens++;
    }
  }

  const { outcome, code } = aggregate(results);
  const status = await finish(job.id, job.lease_owner, outcome, code);
  if (outcome === "sent") counters.sent++;
  else if (outcome === "skipped") counters.skipped++;
  else if (status === "failed") counters.failed++;
  else counters.retried++;
}

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);
  if (!project || !serviceKey || !cronSecret) return json({ error: "SERVICE_UNAVAILABLE" }, 503);
  if (!(await constantTimeEqual(request.headers.get("x-repera-cron") || "", cronSecret))) {
    return json({ error: "FORBIDDEN" }, 403);
  }

  const counters = { sent: 0, cancelled: 0, expired: 0, skipped: 0, failed: 0, retried: 0, invalidTokens: 0, errors: 0 };
  let claimed: Job[];
  try {
    const due = await rpc("claim_due_reminders", { p_limit: BATCH, p_lease_seconds: 120 });
    claimed = Array.isArray(due) ? due : [];
  } catch (e) {
    console.error("push claim failed", (e as Error).message);
    return json({ error: "CLAIM_FAILED" }, 502);
  }

  for (const job of claimed) {
    try {
      await deliver(job, counters);
    } catch (e) {
      counters.errors++;
      console.error("push job failed", (e as Error).message);
      // Lease expiry returns the job to the queue if this also fails.
      await finish(job.id, job.lease_owner, "retry", "INTERNAL").catch(() => undefined);
    }
  }

  return json({
    claimed: claimed.length,
    ...counters,
    fcm_configured: Boolean(fcm),
    apns_configured: Boolean(apns),
  });
});
