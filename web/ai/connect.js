import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.118.0';
import { SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY } from '../console/src/core/config.js';

const auth = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: { flowType: 'pkce', storage: sessionStorage, storageKey: 'repera-ai-consent', detectSessionInUrl: true },
});
const params = new URLSearchParams(location.search);
const authorizationId = params.get('authorization_id') || sessionStorage.getItem('repera-ai-authorization');
const setupCode = params.get('code') || sessionStorage.getItem('repera-ai-setup-code');
// Supabase Auth issues opaque authorization IDs: 32 lowercase base32 chars (a-z2-7), not UUIDs.
const validAuthId = /^[a-z2-7]{32}$/;
const validSetupCode = /^[A-Za-z0-9_-]{20,64}$/;
const status = document.querySelector('#status');
function message(text, error = false) { status.textContent = text; status.classList.toggle('error', error); }
function busy(value) { document.querySelectorAll('button').forEach(button => { button.disabled = value; }); }
function hideAll() {
  for (const id of ['login', 'consent', 'setup-reveal', 'unavailable']) {
    document.querySelector(`#${id}`).hidden = true;
  }
}
async function request(action, extra = {}) {
  const { data: { session }, error } = await auth.auth.getSession();
  if (error || !session) throw new Error('Vuelve a iniciar sesión en Repera.');
  const response = await fetch(`${SUPABASE_URL}/functions/v1/repera-ai-connect/${action}`, {
    method: 'POST', headers: { authorization: `Bearer ${session.access_token}`, 'content-type': 'application/json' },
    body: JSON.stringify(extra), signal: AbortSignal.timeout(15000),
  });
  const data = await response.json();
  if (!response.ok) throw new Error(typeof data.error === 'string' ? data.error : 'No se pudo conectar. Inténtalo de nuevo.');
  return data;
}
async function copyText(value) {
  await navigator.clipboard.writeText(value);
}
async function loadSetup() {
  if (!setupCode || !validSetupCode.test(setupCode)) {
    message('Abre la conexión desde la app Repera.', true);
    document.querySelector('#unavailable').hidden = false;
    return;
  }
  sessionStorage.setItem('repera-ai-setup-code', setupCode);
  const { data: { session }, error } = await auth.auth.getSession();
  if (error) throw error;
  history.replaceState(null, '', `${location.pathname}?code=${encodeURIComponent(setupCode)}`);
  if (!session) {
    message('Entra para revelar el token de setup (15 minutos).');
    document.querySelector('#login').hidden = false;
    return;
  }
  const data = await request('redeem-setup', { code: setupCode });
  sessionStorage.removeItem('repera-ai-setup-code');
  history.replaceState(null, '', location.pathname);
  const mcpUrl = data.mcpUrl || 'https://repera.app/mcp';
  const token = data.token || '';
  document.querySelector('#setup-label').textContent = data.label ? `Token · ${data.label}` : 'Token listo';
  document.querySelector('#setup-mcp').textContent = mcpUrl;
  document.querySelector('#setup-token').textContent = token;
  document.querySelector('#cursor-config').textContent = JSON.stringify(
    { mcpServers: { Repera: { url: mcpUrl, headers: { Authorization: `Bearer ${token}` } } } }, null, 2);
  document.querySelector('#setup-reveal').hidden = false;
  message('Copia el token ahora. Solo se muestra una vez.');
}
async function loadOAuth() {
  if (!authorizationId || !validAuthId.test(authorizationId)) {
    message('Abre la conexión desde tu asistente.');
    document.querySelector('#unavailable').hidden = false;
    return;
  }
  sessionStorage.setItem('repera-ai-authorization', authorizationId);
  const { data: { session }, error } = await auth.auth.getSession();
  if (error) throw error;
  history.replaceState(null, '', `${location.pathname}?authorization_id=${encodeURIComponent(authorizationId)}`);
  if (!session) {
    message('Solo tendrás que autorizar el acceso una vez.');
    document.querySelector('#login').hidden = false;
    return;
  }
  const details = await request('details', { authorizationId });
  document.querySelector('#client-name').textContent = `Conectar ${details.name}`;
  document.querySelector('#account').textContent = `Cuenta de Repera: ${details.account}`;
  const scopes = (details.scope || '').split(' ').filter(Boolean);
  const labels = { openid: 'Identificar tu cuenta', email: 'Compartir tu correo', profile: 'Compartir tu perfil básico', phone: 'Compartir tu teléfono' };
  document.querySelector('#identity').textContent = scopes.length ? `La conexión también solicita: ${scopes.map(s => labels[s] || s).join(', ')}.` : '';
  document.querySelector('#login').hidden = true;
  document.querySelector('#consent').hidden = false;
  message('Elige qué puede hacer tu asistente.');
}
async function load() {
  hideAll();
  if (setupCode && validSetupCode.test(setupCode)) return loadSetup();
  if (authorizationId && validAuthId.test(authorizationId)) return loadOAuth();
  message('Abre la conexión desde Repera o desde tu asistente.');
  document.querySelector('#unavailable').hidden = false;
}
for (const button of document.querySelectorAll('[data-provider]')) {
  button.addEventListener('click', async () => {
    busy(true);
    try {
      const redirectTo = setupCode && validSetupCode.test(setupCode)
        ? `${location.origin}/ai/?code=${encodeURIComponent(setupCode)}`
        : `${location.origin}/ai/?authorization_id=${encodeURIComponent(authorizationId)}`;
      const { error } = await auth.auth.signInWithOAuth({ provider: button.dataset.provider,
        options: { redirectTo } });
      if (error) throw error;
    } catch { message('No se pudo iniciar sesión. Inténtalo de nuevo.', true); busy(false); }
  });
}
document.querySelector('#email-login').addEventListener('submit', async (event) => {
  event.preventDefault();
  busy(true);
  try {
    const email = document.querySelector('#login-email').value.trim();
    const password = document.querySelector('#login-password').value;
    const { error } = await auth.auth.signInWithPassword({ email, password });
    if (error) throw error;
    location.reload();
  } catch { message('Correo o contraseña incorrectos.', true); busy(false); }
});
for (const action of ['approve', 'deny']) {
  document.querySelector(`#${action}`).addEventListener('click', async () => {
    busy(true);
    try {
      const data = await request(action, action === 'approve'
        ? { authorizationId, canWrite: document.querySelector('#can-write').checked }
        : { authorizationId });
      const target = new URL(data.redirect_url);
      if (target.protocol !== 'https:' || target.username || target.password) throw new Error('No se pudo volver al asistente.');
      sessionStorage.removeItem('repera-ai-authorization');
      message(action === 'approve' ? 'Acceso autorizado. Volviendo a tu asistente…' : 'Conexión cancelada.');
      location.assign(target.href);
    } catch (error) { message(error.message, true); busy(false); }
  });
}
document.querySelector('#copy-mcp').addEventListener('click', async () => {
  try {
    await copyText(document.querySelector('#setup-mcp').textContent);
    message('URL MCP copiada.');
  } catch { message('No se pudo copiar.', true); }
});
document.querySelector('#copy-token').addEventListener('click', async () => {
  try {
    await copyText(document.querySelector('#setup-token').textContent);
    message('Token copiado. No lo pegues en el chat.');
  } catch { message('No se pudo copiar.', true); }
});
document.querySelector('#add-cursor').addEventListener('click', () => {
  const mcpUrl = document.querySelector('#setup-mcp').textContent;
  const token = document.querySelector('#setup-token').textContent;
  const config = btoa(JSON.stringify(
    { Repera: { url: mcpUrl, headers: { Authorization: `Bearer ${token}` } } }));
  location.assign(`cursor://anysphere.cursor-deeplink/mcp/install?name=Repera&config=${encodeURIComponent(config)}`);
  message('Abriendo Cursor… Si no pasa nada, copia la configuración de abajo a mano.');
});
document.querySelector('#copy-cursor').addEventListener('click', async () => {
  try {
    await copyText(document.querySelector('#cursor-config').textContent);
    message('Configuración copiada. Pégala en ~/.cursor/mcp.json.');
  } catch { message('No se pudo copiar.', true); }
});
for (const id of ['switch-account', 'setup-switch']) {
  document.querySelector(`#${id}`).addEventListener('click', async () => {
    busy(true);
    try {
      const { error } = await auth.auth.signOut({ scope: 'local' });
      if (error) throw error;
      location.reload();
    } catch { message('No se pudo cerrar esta sesión. Inténtalo de nuevo.', true); busy(false); }
  });
}
load().catch(() => {
  message('No se pudo cargar. Vuelve a abrir el enlace desde Repera.', true);
  document.querySelector('#unavailable').hidden = false;
});
