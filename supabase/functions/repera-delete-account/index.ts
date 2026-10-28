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
const businessBlockers = [
  ["organizations", "created_by"],
  ["clients", "created_by"],
  ["organization_invitations", "invited_by"],
  ["service_passes", "issued_by"],
  ["organization_memberships", "user_id", "owner"],
] as const;

async function businessResponsibilities(userID: string): Promise<boolean> {
  for (const [table, column, ownerRole] of businessBlockers) {
    let query = admin.from(table).select("*", { count: "exact", head: true }).eq(column, userID);
    if (ownerRole) query = query.eq("role", ownerRole);
    const { count, error } = await query;
    if (error) throw error;
    if ((count ?? 0) > 0) return true;
  }
  return false;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return respond(405, { error: "Método no permitido" });
  const bearer = /^Bearer ([\\w.-]+)$/.exec(req.headers.get("authorization") ?? "");
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
        error: "Esta cuenta mantiene un centro, clientes o responsabilidades profesionales. Transfiere primero la propiedad o contacta con soporte para eliminarla sin afectar a terceros.",
      });
    }
    if (action === "preflight") return respond(200, { ok: true });

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
