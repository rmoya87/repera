import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.58.0";

const url = Deno.env.get("SUPABASE_URL")!;
const secret = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const db = createClient(url, secret, {
  auth: { autoRefreshToken: false, persistSession: false },
});
const publicMcp = "https://repera.app/mcp";
const setupTtlMs = 15 * 60 * 1000;
const noStore = { "content-type": "application/json", "cache-control": "no-store" };
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
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
async function encryptReveal(token: string, setupCode: string): Promise<string> {
  const keyHash = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(`repera-setup-v1:${setupCode}`),
  );
  const key = await crypto.subtle.importKey("raw", keyHash, "AES-GCM", false, ["encrypt"]);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const cipher = new Uint8Array(
    await crypto.subtle.encrypt({ name: "AES-GCM", iv }, key, new TextEncoder().encode(token)),
  );
  const packed = new Uint8Array(iv.length + cipher.length);
  packed.set(iv, 0);
  packed.set(cipher, iv.length);
  return b64url(packed);
}
function scopesFromFlags(canRead: boolean, canWrite: boolean, canDelete: boolean): string[] {
  // training:read is mandatory for MCP auth tools.
  const scopes = ["training:read"];
  if (canWrite) scopes.push("training:write");
  if (canDelete) scopes.push("training:delete");
  if (!canRead && !canWrite && !canDelete) return ["training:read"];
  return scopes;
}

Deno.serve(async (request) => {
  if (request.method !== "POST" && request.method !== "PATCH") {
    return reply(405, { error: "Method not allowed" });
  }
  const bearer = /^Bearer ([\w.-]+)$/.exec(request.headers.get("authorization") ?? "");
  if (!bearer) return reply(401, { error: "Sesión de Repera requerida" });
  const { data: { user }, error: authError } = await db.auth.getUser(bearer[1]);
  if (authError || !user) return reply(401, { error: "Sesión inválida" });
  try {
    const claims = JSON.parse(atob(bearer[1].split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
    if (claims.client_id || claims.role !== 'authenticated' || claims.sub !== user.id) {
      return reply(403, { error: "Se requiere la sesión personal de Repera" });
    }
  } catch { return reply(401, { error: "Sesión inválida" }); }
  if (Number(request.headers.get("content-length") || 0) > 2048) {
    return reply(413, { error: "Solicitud demasiado grande" });
  }
  let body: Record<string, unknown>;
  try { body = await request.json(); } catch { return reply(400, { error: "JSON inválido" }); }
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    return reply(400, { error: "Solicitud inválida" });
  }

  // PATCH / update existing connection metadata (label + scopes). Never re-emits the secret.
  if (request.method === "PATCH" || body.action === "update") {
    const allowed = new Set(["id", "label", "canRead", "canWrite", "canDelete", "action"]);
    if (Object.keys(body).some((k) => !allowed.has(k))) {
      return reply(400, { error: { code: "UNKNOWN_FIELD", field: "body", message: "Parámetro desconocido" } });
    }
    if (typeof body.id !== "string" || !uuidPattern.test(body.id)) {
      return reply(400, { error: "Conexión inválida" });
    }
    const label = typeof body.label === "string" ? body.label.trim() : "";
    if (label.length < 1 || label.length > 80) {
      return reply(400, { error: "Indica un nombre válido" });
    }
    for (const key of ["canRead", "canWrite", "canDelete"] as const) {
      if (body[key] != null && typeof body[key] !== "boolean") {
        return reply(400, { error: { code: "INVALID_SCOPE", field: key, message: "Debe ser un booleano" } });
      }
    }
    const canRead = body.canRead !== false;
    const canWrite = body.canWrite === true;
    const canDelete = body.canDelete === true;
    const scopes = scopesFromFlags(canRead, canWrite, canDelete);
    const { data, error } = await db.from("ai_access_tokens")
      .update({ label, scopes })
      .eq("id", body.id)
      .eq("owner_id", user.id)
      .is("revoked_at", null)
      .select("id,label,token_prefix,created_at,expires_at,scopes,oauth_client_id,last_used_at,revoked_at")
      .maybeSingle();
    if (error) return reply(503, { error: "No se pudo actualizar la conexión" });
    if (!data) return reply(404, { error: "Conexión no encontrada" });
    return reply(200, data);
  }

  const allowedCreate = new Set(["label", "expiry", "canWrite", "canDelete", "canRead"]);
  if (Object.keys(body).some((k) => !allowedCreate.has(k))) {
    return reply(400, { error: { code: "UNKNOWN_FIELD", field: "body", message: "Parámetro desconocido" } });
  }
  for (const key of ["canRead", "canWrite", "canDelete"] as const) {
    if (body[key] != null && typeof body[key] !== "boolean") {
      return reply(400, { error: { code: "INVALID_SCOPE", field: key, message: "Debe ser un booleano" } });
    }
  }
  // Default: read-only. canWrite/canDelete opt-in.
  const scopes = scopesFromFlags(body.canRead !== false, body.canWrite === true, body.canDelete === true);
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
  const setupRaw = new Uint8Array(24);
  crypto.getRandomValues(setupRaw);
  const setupCode = b64url(setupRaw);
  const setupHash = await sha256(`repera-setup-code:${setupCode}`);
  const setupExpiresAt = new Date(Date.now() + setupTtlMs).toISOString();
  const setupReveal = await encryptReveal(token, setupCode);
  const durations: Record<string, number> = { "7d": 7, "30d": 30, "90d": 90, "365d": 365 };
  const expires = expiry === "unlimited" ? null : new Date(Date.now() + durations[expiry] * 86_400_000).toISOString();
  const { data, error } = await db.from("ai_access_tokens")
    .insert({
      owner_id: user.id,
      label,
      token_hash: hash,
      token_prefix: token.slice(0, 18),
      expires_at: expires,
      scopes,
      setup_code_hash: setupHash,
      setup_code_expires_at: setupExpiresAt,
      setup_reveal_ciphertext: setupReveal,
    })
    .select("id,label,token_prefix,created_at,expires_at,scopes").single();
  if (error || !data) return reply(503, { error: "No se pudo crear el token" });
  const setupUrl = `https://repera.app/ai/?code=${encodeURIComponent(setupCode)}`;
  return reply(201, {
    ...data,
    token,
    mcpUrl: publicMcp,
    setupCode,
    setupUrl,
    setupExpiresAt,
    warning: "Copia el token ahora o abre el enlace de setup (15 min). No volverá a mostrarse el token salvo ese enlace.",
  });
});
