import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.58.0";

const url = Deno.env.get("SUPABASE_URL")!;
const secret = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const db = createClient(url, secret, {
  auth: { autoRefreshToken: false, persistSession: false },
});
// Only this trusted Edge Function has the service-role key. No secrets in iOS.
const noStore = { "content-type": "application/json", "cache-control": "no-store" };
function reply(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), { status, headers: noStore });
}
function b64url(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
async function sha256(value: string): Promise<string> {
  const hash = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return Array.from(new Uint8Array(hash), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return reply(405, { error: "Method not allowed" });
  const bearer = /^Bearer ([\w.-]+)$/.exec(request.headers.get("authorization") ?? "");
  if (!bearer) return reply(401, { error: "Sesión de Repera requerida" });
  // Auth JWT is verified by the Supabase Auth server, not decoded blindly.
  const { data: { user }, error: authError } = await db.auth.getUser(bearer[1]);
  if (authError || !user) return reply(401, { error: "Sesión inválida" });
  // Only decode AFTER getUser verifies this exact JWT. Delegated assistants
  // must never exchange their access for an unrestricted personal token.
  try {
    const claims = JSON.parse(atob(bearer[1].split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
    if (claims.client_id || claims.role !== 'authenticated' || claims.sub !== user.id) {
      return reply(403, { error: "Se requiere la sesión personal de Repera" });
    }
  } catch { return reply(401, { error: "Sesión inválida" }); }
  if (Number(request.headers.get("content-length") || 0) > 2048) {
    return reply(413, { error: "Solicitud demasiado grande" });
  }
  let body: { label?: unknown; expiry?: unknown; canWrite?: unknown };
  try { body = await request.json(); } catch { return reply(400, { error: "JSON inválido" }); }
  if (!body || typeof body !== "object" || Object.keys(body).some(k => !["label","expiry","canWrite"].includes(k))) {
    return reply(400,{error:{code:"UNKNOWN_FIELD",field:"body",message:"Parámetro desconocido"}});
  }
  if (body.canWrite != null && typeof body.canWrite !== "boolean")
    return reply(400,{error:{code:"INVALID_SCOPE",field:"canWrite",message:"Debe ser un booleano"}});
  const scopes=body.canWrite === false ? ["training:read"] : ["training:read","training:write"];
  const label = typeof body.label === "string" ? body.label.trim() : "";
  const options = new Set(["7d", "30d", "90d", "365d", "unlimited"]);
  const expiry = body.expiry;
  if (label.length < 1 || label.length > 80 || typeof expiry !== "string" || !options.has(expiry)) {
    return reply(400, { error: "Indica nombre y caducidad válidos" });
  }
  const { count, error: countError } = await db.from("ai_access_tokens")
    .select("id", { count: "exact", head: true }).eq("owner_id", user.id)
    .is("revoked_at", null)
    .or("expires_at.is.null,expires_at.gt." + new Date().toISOString());
  if (countError) return reply(503, { error: "No se pudieron comprobar los tokens" });
  if ((count ?? 0) >= 10) return reply(409, { error: "Máximo 10 tokens activos por cuenta. Revoca uno para continuar." });
  const raw = new Uint8Array(32);
  crypto.getRandomValues(raw);
  const token = "rep_ai_" + b64url(raw);
  const hash = await sha256(token);
  const durations: Record<string, number> = { "7d": 7, "30d": 30, "90d": 90, "365d": 365 };
  const expires = expiry === "unlimited" ? null : new Date(Date.now() + durations[expiry] * 86_400_000).toISOString();
  const { data, error } = await db.from("ai_access_tokens")
    .insert({ owner_id: user.id, label, token_hash: hash, token_prefix: token.slice(0, 18), expires_at: expires, scopes })
    .select("id,label,token_prefix,created_at,expires_at,scopes").single();
  if (error || !data) return reply(503, { error: "No se pudo crear el token" });
  return reply(201, {
    ...data, token,
    warning: "Copia el token ahora. No volverá a mostrarse ni puede recuperarse.",
  });
});
