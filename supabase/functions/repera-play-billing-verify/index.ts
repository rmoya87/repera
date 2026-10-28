import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.58.0";
import { createSign } from "node:crypto";

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

const MONTHLY = "com.app.repera.premium.monthly";
const ANNUAL = "com.app.repera.premium.yearly";
const PRODUCT_IDS = new Set([MONTHLY, ANNUAL]);

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
    if (!parsed.client_email || !parsed.private_key) return null;
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
    aud: sa.token_uri ?? "https://oauth2.googleapis.com/token",
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
  const tokenRes = await fetch(sa.token_uri ?? "https://oauth2.googleapis.com/token", {
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

type PlaySub = {
  subscriptionState?: string;
  acknowledgementState?: string;
  lineItems?: Array<{
    productId?: string;
    expiryTime?: string;
    autoRenewingPlan?: unknown;
    prepaidPlan?: unknown;
    offerDetails?: { basePlanId?: string };
  }>;
  canceledStateContext?: unknown;
};

function mapStatus(sub: PlaySub, productId: string | null): {
  status: string;
  expiryEpochMs: number | null;
  productId: string | null;
} {
  const item = sub.lineItems?.find((li) => li.productId && PRODUCT_IDS.has(li.productId))
    ?? sub.lineItems?.[0];
  const resolvedProduct = (item?.productId && PRODUCT_IDS.has(item.productId)
    ? item.productId
    : productId && PRODUCT_IDS.has(productId) ? productId : item?.productId)
    ?? null;
  const expiryIso = item?.expiryTime ?? null;
  const expiryEpochMs = expiryIso ? Date.parse(expiryIso) : null;
  const state = (sub.subscriptionState ?? "").toUpperCase();

  if (state.includes("EXPIRED")) {
    return { status: "expired", expiryEpochMs, productId: resolvedProduct };
  }
  if (state.includes("REVOKED") || state.includes("PENDING_PURCHASE_CANCELED")) {
    return { status: "revoked", expiryEpochMs, productId: resolvedProduct };
  }
  if (state.includes("IN_GRACE") || state.includes("ON_HOLD")) {
    return { status: "gracePeriod", expiryEpochMs, productId: resolvedProduct };
  }
  if (
    state.includes("ACTIVE") ||
    state.includes("CANCELED") || // still entitled until expiry
    state.includes("IN_TRIAL")
  ) {
    const inTrial = state.includes("IN_TRIAL");
    if (inTrial) return { status: "trial", expiryEpochMs, productId: resolvedProduct };
    if (resolvedProduct === ANNUAL) {
      return { status: "proAnnual", expiryEpochMs, productId: resolvedProduct };
    }
    if (resolvedProduct === MONTHLY) {
      return { status: "proMonthly", expiryEpochMs, productId: resolvedProduct };
    }
    // Active but unknown product: still Pro monthly as conservative default only
    // when Play says ACTIVE; otherwise free.
    if (state.includes("ACTIVE")) {
      return { status: "proMonthly", expiryEpochMs, productId: resolvedProduct };
    }
  }
  return { status: "free", expiryEpochMs, productId: resolvedProduct };
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
  let productId: unknown;
  try {
    ({ purchaseToken, productId } = await req.json());
  } catch {
    return respond(400, { error: "Solicitud inválida." });
  }
  if (typeof purchaseToken !== "string" || !purchaseToken.trim()) {
    return respond(400, { error: "purchaseToken obligatorio." });
  }
  const productHint = typeof productId === "string" && PRODUCT_IDS.has(productId)
    ? productId
    : null;

  try {
    const access = await googleAccessToken(sa);
    const endpoint =
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${
        encodeURIComponent(packageName)
      }/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`;
    const playRes = await fetch(endpoint, {
      headers: { Authorization: `Bearer ${access}` },
    });
    if (playRes.status === 404) {
      return respond(200, {
        configured: true,
        status: "free",
        expiryEpochMs: null,
        productId: productHint,
        acknowledged: false,
        playState: "NOT_FOUND",
      });
    }
    if (!playRes.ok) {
      console.error("Play subscriptionsv2 HTTP", playRes.status);
      return respond(503, {
        configured: true,
        error: "Play Developer API no disponible ahora mismo.",
      });
    }
    const sub = await playRes.json() as PlaySub;
    const mapped = mapStatus(sub, productHint);
    const acknowledged = (sub.acknowledgementState ?? "").toUpperCase().includes("ACKNOWLEDGED");
    return respond(200, {
      configured: true,
      status: mapped.status,
      expiryEpochMs: mapped.expiryEpochMs,
      productId: mapped.productId,
      acknowledged,
      playState: sub.subscriptionState ?? null,
      userId: user.id,
    });
  } catch (err) {
    console.error("Play verify failed", err instanceof Error ? err.name : "error");
    return respond(503, {
      configured: true,
      error: "No se pudo verificar la suscripción con Google Play.",
    });
  }
});
