import { createClient } from "https://esm.sh/@supabase/supabase-js@2.118.0";
import { SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY } from "../../console/src/core/config.js";

const client = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: { autoRefreshToken: true, persistSession: true, detectSessionInUrl: true },
});
const authorizationId = new URL(location.href).searchParams.get("authorization_id");
const byId = (id) => document.getElementById(id);
const setStatus = (message, error = false) => {
  byId("status").textContent = message;
  byId("status").className = error ? "error" : "";
};
const busy = (value) => {
  for (const id of ["approve", "deny", "signin"]) byId(id).disabled = value;
};

let details = null;
async function start() {
  if (!authorizationId || authorizationId.length > 500) {
    setStatus("La solicitud OAuth no contiene un identificador válido.", true);
    return;
  }
  const { data: { user }, error: loginError } = await client.auth.getUser();
  if (loginError || !user) {
    byId("client").textContent = "Autenticación requerida";
    byId("login").classList.remove("hidden");
    return;
  }
  const { data, error } = await client.auth.oauth.getAuthorizationDetails(authorizationId);
  if (error || !data) {
    setStatus("No se pudo verificar el cliente OAuth: " + (error?.message ?? "solicitud incorrecta"), true);
    return;
  }
  if (!("authorization_id" in data)) {
    // Supabase can auto-approve an existing OAuth grant. A separate Repera
    // mcp_user_consents grant is still required for any MCP workout read.
    location.assign(data.redirect_url);
    return;
  }
  if (!data.client?.id || data.user?.id !== user.id) {
    setStatus("La identidad o el cliente autorizado no coincide.", true);
    return;
  }
  details = data;
  byId("client").textContent = data.client.name || "Aplicación externa";
  byId("consent").classList.remove("hidden");
}

byId("signin").addEventListener("click", async () => {
  busy(true);
  setStatus("Iniciando sesión con Apple…");
  // OAuth web login must be configured in Supabase's Apple provider as well
  // as the native iOS Sign in with Apple integration.
  const { error } = await client.auth.signInWithOAuth({
    provider: "apple",
    options: { redirectTo: location.href },
  });
  if (error) {
    setStatus("No se pudo iniciar sesión: " + error.message, true);
    busy(false);
  }
});

byId("approve").addEventListener("click", async () => {
  if (!details) return;
  busy(true);
  setStatus("Guardando tu autorización…");
  const { data: { user } } = await client.auth.getUser();
  if (user?.id !== details.user?.id) {
    setStatus("La sesión ha cambiado. Vuelve a iniciar la autorización.", true);
    busy(false);
    return;
  }
  const clientId = details.client.id;
  // Record a separate sporting-data grant while using a normal login session;
  // RLS blocks OAuth agent tokens from self-granting permissions.
  const { data: previous, error: previousError } = await client
    .from("mcp_user_consents")
    .select("enabled")
    .eq("user_id", user.id)
    .eq("client_id", clientId)
    .maybeSingle();
  if (previousError) {
    setStatus("No se pudo comprobar el permiso: " + previousError.message, true);
    busy(false);
    return;
  }
  const { error: grantError } = await client.from("mcp_user_consents").upsert({
    user_id: user.id, client_id: clientId, enabled: true, updated_at: new Date().toISOString(),
  }, { onConflict: "user_id,client_id" });
  if (grantError) {
    setStatus("No se pudo registrar el permiso deportivo: " + grantError.message, true);
    busy(false);
    return;
  }
  const { data: approval, error: approvalError } = await client.auth.oauth.approveAuthorization(authorizationId);
  if (approvalError || !approval?.redirect_url) {
    // Undo the new/changed grant if OAuth itself was not approved.
    if (previous == null) {
      await client.from("mcp_user_consents").delete()
        .eq("user_id", user.id).eq("client_id", clientId);
    } else {
      await client.from("mcp_user_consents").update({
        enabled: previous.enabled, updated_at: new Date().toISOString(),
      }).eq("user_id", user.id).eq("client_id", clientId);
    }
    setStatus("No se pudo completar OAuth: " + (approvalError?.message ?? "respuesta incorrecta"), true);
    busy(false);
    return;
  }
  location.assign(approval.redirect_url);
});

byId("deny").addEventListener("click", async () => {
  if (!details) return;
  busy(true);
  const { data, error } = await client.auth.oauth.denyAuthorization(authorizationId);
  if (error || !data?.redirect_url) {
    setStatus("No se pudo cancelar la solicitud: " + (error?.message ?? "respuesta incorrecta"), true);
    busy(false);
    return;
  }
  location.assign(data.redirect_url);
});

start().catch((error) => setStatus("No se pudo abrir la autorización: " + error.message, true));
