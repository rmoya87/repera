import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.118.0';
import { SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY } from '../console/src/core/config.js';

const auth = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: { flowType: 'pkce', storage: sessionStorage, storageKey: 'repera-ai-consent', detectSessionInUrl: true },
});
const params = new URLSearchParams(location.search);
const authorizationId = params.get('authorization_id') || sessionStorage.getItem('repera-ai-authorization');
const validId = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const status = document.querySelector('#status');
function message(text, error = false) { status.textContent = text; status.classList.toggle('error', error); }
function busy(value) { document.querySelectorAll('button').forEach(button => { button.disabled = value; }); }
async function request(action, extra = {}) {
  const { data: { session }, error } = await auth.auth.getSession();
  if (error || !session) throw new Error('Vuelve a iniciar sesión en Repera.');
  const response = await fetch(`${SUPABASE_URL}/functions/v1/repera-ai-connect/${action}`, {
    method: 'POST', headers: { authorization: `Bearer ${session.access_token}`, 'content-type': 'application/json' },
    body: JSON.stringify({ authorizationId, ...extra }), signal: AbortSignal.timeout(15000),
  });
  const data = await response.json();
  if (!response.ok) throw new Error(typeof data.error === 'string' ? data.error : 'No se pudo conectar. Inténtalo de nuevo.');
  return data;
}
async function load() {
  if (!authorizationId || !validId.test(authorizationId)) {
    message('Abre la conexión desde tu asistente.');
    document.querySelector('#unavailable').hidden = false;
    return;
  }
  sessionStorage.setItem('repera-ai-authorization', authorizationId);
  const { data: { session }, error } = await auth.auth.getSession();
  if (error) throw error;
  // Remove login codes from the visible URL once the SDK has consumed them.
  history.replaceState(null, '', `${location.pathname}?authorization_id=${encodeURIComponent(authorizationId)}`);
  if (!session) {
    message('Solo tendrás que autorizar el acceso una vez.');
    document.querySelector('#login').hidden = false;
    return;
  }
  const details = await request('details');
  document.querySelector('#client-name').textContent = `Conectar ${details.name}`;
  document.querySelector('#account').textContent = `Cuenta de Repera: ${details.account}`;
  const scopes = (details.scope || '').split(' ').filter(Boolean);
  const labels = { openid: 'Identificar tu cuenta', email: 'Compartir tu correo', profile: 'Compartir tu perfil básico', phone: 'Compartir tu teléfono' };
  document.querySelector('#identity').textContent = scopes.length ? `La conexión también solicita: ${scopes.map(s => labels[s] || s).join(', ')}.` : '';
  document.querySelector('#login').hidden = true;
  document.querySelector('#consent').hidden = false;
  message('Elige qué puede hacer tu asistente.');
}
for (const button of document.querySelectorAll('[data-provider]')) {
  button.addEventListener('click', async () => {
    busy(true);
    try {
      const { error } = await auth.auth.signInWithOAuth({ provider: button.dataset.provider,
        options: { redirectTo: `${location.origin}/ai/?authorization_id=${encodeURIComponent(authorizationId)}` } });
      if (error) throw error;
    } catch { message('No se pudo iniciar sesión. Inténtalo de nuevo.', true); busy(false); }
  });
}
for (const action of ['approve','deny']) {
  document.querySelector(`#${action}`).addEventListener('click', async () => {
    busy(true);
    try {
      const data = await request(action, action === 'approve' ? { canWrite: document.querySelector('#can-write').checked } : {});
      const target = new URL(data.redirect_url);
      if (target.protocol !== 'https:' || target.username || target.password) throw new Error('No se pudo volver al asistente.');
      sessionStorage.removeItem('repera-ai-authorization');
      message(action === 'approve' ? 'Acceso autorizado. Volviendo a tu asistente…' : 'Conexión cancelada.');
      location.assign(target.href);
    } catch (error) { message(error.message, true); busy(false); }
  });
}
document.querySelector('#switch-account').addEventListener('click', async () => {
  busy(true);
  try {
    const { error } = await auth.auth.signOut({ scope: 'local' });
    if (error) throw error;
    location.reload();
  } catch { message('No se pudo cerrar esta sesión. Inténtalo de nuevo.', true); busy(false); }
});
load().catch(error => { message(error.message || 'No se pudo comprobar la conexión.', true); });
