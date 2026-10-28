import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.58.0";
import { createSign } from "node:crypto";
import { OwnershipError, verifySubscription } from "./verification.ts";

/**
 * Verifies a Google Play subscription with purchases.subscriptionsv2.get.
 *
 * Secrets (Ramón / ops — never ship in the Android APK):
 * - SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY (standard Edge)
 * - PLAY_PACKAGE_NAME (e.g. com.app.repera)
 * - GOOGLE_PLAY_SERVICE_ACCOUNT_JSON (full SA key JSON)
 *
 * Without the Play SA secret the function returns 503 { configured:false }
 * so the app stays on UNKNOWN and does not grant Pro from a local token.
 *
 * Product IDs expected by the mobile client:
 * - com.app.repera.premium.monthly
 * - com.app.repera.premium.yearly
 */

const url = Deno.env.get("SUPABASE_URL") ?? "";
const secret = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const packageName = Deno.env.get("PLAY_PACKAGE_NAME") ?? "com.app.repera";
const serviceAccountJson = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON") ?? "";

const admin = createClient(url, secret, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const respond = (status: number, data: Record<string, unknown>) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store" },
  });

type ServiceAccount = {
  client_email: string;
  private_key: string;
  token_uri?: string;
};

function parseServiceAccount(): ServiceAccount | null {
  if (!serviceAccountJson.trim()) return null;
  try {
    const parsed = JSON.parse(serviceAccountJson) as ServiceAccount;
    if (!parsed.client_email || !parsed.private_key ||
      (parsed.token_uri && parsed.token_uri !== "https://oauth2.googleapis.com/token")) return null;
    return parsed;
  } catch {
    return null;
  }
}

function b64url(input: string | Buffer): string {
  const buf = typeof input === "string" ? Buffer.from(input) : input;
  return buf.toString("base64").replace(/=+$/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

async function googleAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claim}`;
  const signer = createSign("RSA-SHA256");
  signer.update(unsigned);
  signer.end();
  const signature = b64url(signer.sign(sa.private_key));
  const assertion = `${unsigned}.${signature}`;
  const body = new URLSearchParams({
    grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
    assertion,
  });
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body,
  });
  if (!tokenRes.ok) {
    throw new Error(`Google OAuth token HTTP ${tokenRes.status}`);
  }
  const json = await tokenRes.json() as { access_token?: string };
  if (!json.access_token) throw new Error("Google OAuth token missing");
  return json.access_token;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return respond(405, { error: "Método no permitido" });

  const sa = parseServiceAccount();
  if (!sa) {
    return respond(503, {
      configured: false,
      error:
        "Verificación Play no configurada: falta GOOGLE_PLAY_SERVICE_ACCOUNT_JSON en secretos del Edge Function. Pasos en android/docs/MONETIZATION_PLAY_BILLING.md.",
    });
  }

  const bearer = /^Bearer ([\w.-]+)$/.exec(req.headers.get("authorization") ?? "");
  if (!bearer) return respond(401, { error: "Inicia sesión antes de verificar la compra." });
  const { data: { user }, error } = await admin.auth.getUser(bearer[1]);
  if (error || !user) return respond(401, { error: "Sesión no válida." });
  try {
    const tokenBody = bearer[1].split(".")[1];
    const claims = JSON.parse(atob(tokenBody.replace(/-/g, "+").replace(/_/g, "/")));
    if (claims.sub !== user.id || claims.client_id || claims.role !== "authenticated") {
      return respond(403, { error: "Se necesita una sesión personal de Repera." });
    }
  } catch {
    return respond(401, { error: "Sesión no válida." });
  }

  let purchaseToken: unknown;
  try {
    ({ purchaseToken } = await req.json());
  } catch {
    return respond(400, { error: "Solicitud inválida." });
  }
  if (typeof purchaseToken !== "string" || !purchaseToken.trim() || purchaseToken.length > 8192) {
    return respond(400, { error: "purchaseToken obligatorio." });
  }
  try {
    const access = await googleAccessToken(sa);
    const result = await verifySubscription(user.id, purchaseToken, {
      getSubscription: async (token) => {
        const endpoint = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${
          encodeURIComponent(packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(token)}`;
        const res = await fetch(endpoint, {headers: {Authorization: `Bearer ${access}`}});
        if (res.status === 404) return null;
        if (!res.ok) throw new Error(`Play API HTTP ${res.status}`);
        return await res.json();
      },
      claim: async (record) => {
        const {data, error} = await admin.rpc("claim_play_subscription", {
          p_token_hash: record.tokenHash, p_owner: record.owner,
          p_linked_hash: record.linkedHash, p_product: record.product,
          p_state: record.state, p_expiry: record.expiry,
        });
        if (error) throw new Error("Purchase ownership storage unavailable");
        return data === true;
      },
      acknowledge: async (token, product) => {
        const endpoint = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${
          encodeURIComponent(packageName)}/purchases/subscriptions/${encodeURIComponent(product)}/tokens/${
          encodeURIComponent(token)}:acknowledge`;
        const res = await fetch(endpoint, {
          method: "POST", headers: {Authorization: `Bearer ${access}`, "Content-Type": "application/json"},
          body: "{}",
        });
        if (!res.ok) throw new Error(`Play acknowledgement HTTP ${res.status}`);
      },
    });
    return respond(200, {configured: true, ...result, userId: user.id});
  } catch (err) {
    if (err instanceof OwnershipError) return respond(200, {
      configured: true, status: "revoked", productId: null, expiryEpochMs: null,
      acknowledged: false, playState: "OWNERSHIP_REJECTED",
    });
    console.error("Play verify failed", err instanceof Error ? err.name : "error");
    return respond(503, {
      configured: true,
      error: "No se pudo verificar la suscripción con Google Play.",
    });
  }
});
