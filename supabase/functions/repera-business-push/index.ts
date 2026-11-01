// Claim due booking reminders and attempt FCM HTTP v1 delivery.
// Without FCM_SERVICE_ACCOUNT_JSON / FCM_PROJECT_ID secrets, marks attempts as skipped (not delivered).
const project = Deno.env.get("SUPABASE_URL") || "";
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
const fcmProject = Deno.env.get("FCM_PROJECT_ID") || "";
const fcmJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") || "";
const json = (obj: unknown, status = 200) =>
  new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json" },
  });

async function claim(limit = 40) {
  const res = await fetch(`${project}/rest/v1/rpc/claim_due_reminders`, {
    method: "POST",
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ p_limit: limit, p_lease_seconds: 90 }),
  });
  if (!res.ok) throw new Error(`claim_failed_${res.status}`);
  return await res.json();
}

async function loadBooking(bookingId: string) {
  const res = await fetch(
    `${project}/rest/v1/service_bookings?id=eq.${bookingId}&select=id,status,client_id,occurrence_id,org_id`,
    {
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
      },
    },
  );
  const rows = await res.json();
  return Array.isArray(rows) ? rows[0] : null;
}

async function loadOccurrence(id: string) {
  const res = await fetch(
    `${project}/rest/v1/service_occurrences?id=eq.${id}&select=id,title,starts_at,status,kind`,
    {
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
      },
    },
  );
  const rows = await res.json();
  return Array.isArray(rows) ? rows[0] : null;
}

async function tokensFor(userId: string) {
  const res = await fetch(
    `${project}/rest/v1/device_push_tokens?user_id=eq.${userId}&revoked_at=is.null&select=id,token,platform`,
    {
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
      },
    },
  );
  const rows = await res.json();
  return Array.isArray(rows) ? rows : [];
}

async function patchOutbox(id: string, body: Record<string, unknown>) {
  await fetch(`${project}/rest/v1/notification_outbox?id=eq.${id}`, {
    method: "PATCH",
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    },
    body: JSON.stringify(body),
  });
}

async function recordAttempt(outboxId: string, deviceId: string | null, success: boolean, code: string) {
  await fetch(`${project}/rest/v1/notification_attempts`, {
    method: "POST",
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    },
    body: JSON.stringify({
      outbox_id: outboxId,
      device_token_id: deviceId,
      success,
      provider: "fcm",
      provider_code: code,
    }),
  });
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response(null, { status: 204 });
  if (request.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);
  if (!project || !serviceKey) return json({ error: "SERVICE_UNAVAILABLE" }, 503);

  // Optional shared cron secret
  const cronSecret = Deno.env.get("REPERA_PUSH_CRON_SECRET") || "";
  if (cronSecret) {
    const hdr = request.headers.get("x-repera-cron") || "";
    if (hdr !== cronSecret) return json({ error: "FORBIDDEN" }, 403);
  }

  try {
    const due = await claim(40);
    const rows = Array.isArray(due) ? due : [];
    let sent = 0, cancelled = 0, skipped = 0, failed = 0;
    const canSend = Boolean(fcmProject && fcmJson);

    for (const job of rows) {
      const booking = await loadBooking(job.booking_id);
      if (!booking || booking.status !== "booked") {
        await patchOutbox(job.id, { status: "cancelled", updated_at: new Date().toISOString() });
        cancelled++;
        continue;
      }
      const occ = await loadOccurrence(job.occurrence_id);
      if (!occ || occ.status !== "active") {
        await patchOutbox(job.id, { status: "cancelled", updated_at: new Date().toISOString() });
        cancelled++;
        continue;
      }

      const devices = await tokensFor(job.user_id);
      if (!devices.length || !canSend) {
        await recordAttempt(job.id, null, false, canSend ? "NO_DEVICES" : "FCM_NOT_CONFIGURED");
        await patchOutbox(job.id, {
          status: canSend ? "failed" : "pending",
          lease_owner: null,
          lease_until: null,
          updated_at: new Date().toISOString(),
        });
        if (canSend) failed++; else skipped++;
        continue;
      }

      // Delivery stub: without implementing full Google OAuth JWT here, record configured path.
      // Production must exchange FCM_SERVICE_ACCOUNT_JSON for an access token and POST to FCM v1.
      let ok = false;
      for (const d of devices) {
        await recordAttempt(job.id, d.id, false, "FCM_SEND_PENDING_IMPLEMENTATION");
      }
      await patchOutbox(job.id, {
        status: ok ? "sent" : "failed",
        updated_at: new Date().toISOString(),
        lease_owner: null,
        lease_until: null,
      });
      if (ok) sent++; else failed++;
    }

    return json({
      claimed: rows.length,
      sent,
      cancelled,
      skipped,
      failed,
      fcm_configured: canSend,
      note: canSend
        ? "FCM credentials present; wire OAuth access token for live send"
        : "Queue claimed; configure FCM_PROJECT_ID + FCM_SERVICE_ACCOUNT_JSON for delivery",
    });
  } catch (e) {
    return json({ error: String((e as Error).message || e) }, 500);
  }
});
