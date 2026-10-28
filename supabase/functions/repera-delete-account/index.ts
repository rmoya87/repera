import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.58.0";

// Only a verified personal session may delete its OWN account.
// The service role is server-side exclusively; never ship it in mobile builds.
const url = Deno.env.get("SUPABASE_URL") ?? "";
const secret = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const admin = createClient(url, secret, {
  auth: { autoRefreshToken: false, persistSession: false },
});
const respond = (status: number, data: Record<string, unknown>) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store" },
  });

// Deleting a professional owner without transferring their business would
// break other athletes' bookings/payments. Refuse rather than cascade those.
const businessBlockers: Array<{ table: string; column: string; ownerRole?: string }> = [
  { table: "organizations", column: "created_by" },
  { table: "clients", column: "created_by" },
  { table: "organization_invitations", column: "invited_by" },
  { table: "service_passes", column: "issued_by" },
  { table: "organization_memberships", column: "user_id", ownerRole: "owner" },
  // Professional/business audit authors cannot be erased without transferring
  // legal responsibility for documents held by other people.
  { table: "professional_training_sessions", column: "coach_user_id" },
  { table: "business_client_notifications", column: "sender_user_id" },
  { table: "business_bulk_training_batches", column: "created_by" },
  { table: "business_invitation_email_attempts", column: "actor_id" },
  { table: "business_pass_offers", column: "created_by" },
  { table: "business_subscription_intents", column: "actor" },
  { table: "business_trainer_attendance", column: "recorded_by" },
  { table: "business_training_groups", column: "created_by" },
  { table: "professional_workout_templates", column: "created_by" },
  { table: "service_credit_ledger", column: "created_by" },
  { table: "service_pass_management_events", column: "actor" },
];

async function businessResponsibilities(userID: string): Promise<boolean> {
  for (const { table, column, ownerRole } of businessBlockers) {
    let query = admin.from(table).select("*", { count: "exact", head: true }).eq(column, userID);
    if (ownerRole) query = query.eq("role", ownerRole);
    const { count, error } = await query;
    if (error) throw error;
    if ((count ?? 0) > 0) return true;
  }
  return false;
}

type LinkedClient = { id: string; org_id: string };

async function freezeBusinessHistory(ownerID: string): Promise<void> {
  const { data: linked, error: lookupError } = await admin.from("clients")
    .select("id,org_id").eq("user_id", ownerID);
  if (lookupError) throw lookupError;
  const timestamp = new Date().toISOString();
  for (const client of (linked ?? []) as LinkedClient[]) {
    // Only copy private mirrored results when the athlete explicitly granted
    // access and currently enabled history sharing with this exact center.
    const [{ data: consent, error: consentError }, { data: sharing, error: shareError }] =
      await Promise.all([
        admin.from("athlete_business_history_consents")
          .select("granted_at,revoked_at")
          .eq("athlete_user_id", ownerID).eq("org_id", client.org_id)
          .eq("client_id", client.id).maybeSingle(),
        admin.from("athlete_workout_sharing")
          .select("enabled")
          .eq("athlete_id", ownerID).eq("org_id", client.org_id).maybeSingle(),
      ]);
    if (consentError || shareError) throw consentError ?? shareError;
    if (consent?.granted_at && !consent.revoked_at && sharing?.enabled === true) {
      for (let offset = 0; ; offset += 500) {
        const { data: workouts, error: listError } = await admin
          .from("athlete_workout_mirror")
          .select("id,title,started_at,finished_at,payload")
          .eq("owner_id", ownerID)
          .is("deleted_at", null)
          .order("created_at", { ascending: true })
          .range(offset, offset + 499);
        if (listError) throw listError;
        if (!workouts?.length) break;
        const archived = workouts.map((workout) => ({
          org_id: client.org_id,
          client_id: client.id,
          workout_id: workout.id,
          title: workout.title,
          started_at: workout.started_at,
          finished_at: workout.finished_at,
          payload: workout.payload,
          frozen_at: timestamp,
        }));
        const { error: archiveError } = await admin
          .from("business_athlete_workout_snapshots")
          .upsert(archived, { onConflict: "org_id,client_id,workout_id" });
        if (archiveError) throw archiveError;
        if (workouts.length < 500) break;
      }
    }
    // Preserve the company-owned client card and its professional sessions.
    // Mark inert BEFORE dropping the identity connection.
    const { error: freezeError } = await admin.from("clients")
      .update({ status: "cancelled", account_deleted_at: timestamp, user_id: null })
      .eq("id", client.id).eq("user_id", ownerID);
    if (freezeError) throw freezeError;
  }

  // Bookings are legal historical documents: keep the original requester UUID
  // in a detached audit field, without letting it reference a live login.
  const { error: archiveBookingError } = await admin.from("service_bookings")
    .update({ requested_by_deleted_user_id: ownerID, requested_by: null })
    .eq("requested_by", ownerID);
  if (archiveBookingError) throw archiveBookingError;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return respond(405, { error: "Método no permitido" });
  const bearer = /^Bearer ([\w.-]+)$/.exec(req.headers.get("authorization") ?? "");
  if (!bearer) return respond(401, { error: "Inicia sesión antes de eliminar la cuenta." });
  const { data: { user }, error } = await admin.auth.getUser(bearer[1]);
  if (error || !user) return respond(401, { error: "Sesión no válida." });
  // A verified JWT must represent a real interactive user, not an AI token.
  try {
    const tokenBody = bearer[1].split(".")[1];
    const claims = JSON.parse(atob(tokenBody.replace(/-/g, "+").replace(/_/g, "/")));
    if (claims.sub !== user.id || claims.client_id || claims.role !== "authenticated") {
      return respond(403, { error: "Se necesita una sesión personal de Repera." });
    }
  } catch { return respond(401, { error: "Sesión no válida." }); }

  let action: unknown;
  try { ({ action } = await req.json()); }
  catch { return respond(400, { error: "Solicitud inválida." }); }
  if (action !== "preflight" && action !== "delete") {
    return respond(400, { error: "Operación no reconocida." });
  }
  try {
    if (await businessResponsibilities(user.id)) {
      return respond(409, {
        error: "Esta cuenta tiene responsabilidades profesionales o documentos de auditoría. Transfiere primero el centro o solicita una baja asistida para conservar los registros de terceros.",
      });
    }
    if (action === "preflight") return respond(200, { ok: true });

    // Snapshot business-accessible data before personal Supabase rows cascade.
    // The erased account cannot authenticate or mutate archived business records.
    await freezeBusinessHistory(user.id);

    // Remove personally owned Storage objects BEFORE deleting auth.users.
    // Shared business-branding is intentionally untouched.
    const { data: avatarObjects, error: listError } =
      await admin.storage.from("profile-avatars").list(user.id, { limit: 1000 });
    if (listError) throw listError;
    const ownPaths = (avatarObjects ?? []).filter((entry) => entry.id != null)
      .map((entry) => `${user.id}/${entry.name}`);
    if (ownPaths.length) {
      const { error: storageError } = await admin.storage.from("profile-avatars").remove(ownPaths);
      if (storageError) throw storageError;
    }
    // Personal consent has NO ACTION FK (rather than ON DELETE CASCADE).
    const { error: consentError } = await admin.from("athlete_business_history_consents")
      .delete().eq("athlete_user_id", user.id);
    if (consentError) throw consentError;
    // Deleting auth.users cascades personal mirror, AI tokens and profiles.
    const { error: deleteError } = await admin.auth.admin.deleteUser(user.id, false);
    if (deleteError) throw deleteError;
    return respond(200, { ok: true });
  } catch (error) {
    console.error("Account erasure failed", error instanceof Error ? error.name : "error");
    return respond(503, {
      error: "No se pudo completar la eliminación remota. No se ha confirmado el borrado de la cuenta. Inténtalo de nuevo o contacta con soporte.",
    });
  }
});
