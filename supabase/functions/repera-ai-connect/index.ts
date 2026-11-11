import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.58.0';
import { projectURL, uuidPattern, connectionCatalogEntry } from '../_shared/ai-oauth.ts';

const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
  auth: { autoRefreshToken: false, persistSession: false },
});
const site = 'https://repera.app';
const publicMcp = 'https://repera.app/mcp';
const headers = { 'content-type': 'application/json', 'cache-control': 'no-store',
  'access-control-allow-origin': site, 'access-control-allow-headers': 'authorization,content-type',
  'access-control-allow-methods': 'GET,POST,OPTIONS', 'vary': 'Origin' };
const reply = (status: number, data: unknown) => new Response(JSON.stringify(data), { status, headers });

// Supabase Auth hands the frontend an opaque authorization_id (crypto.SecureAlphanumeric(32):
// 32 lowercase base32 chars, a-z2-7), not a UUID. uuidPattern stays for user/grant IDs.
const authorizationIdPattern = /^[a-z2-7]{32}$/;
// Setup codes from repera-ai-tokens: URL-safe base64 without padding (length 32).
const setupCodePattern = /^[A-Za-z0-9_-]{20,64}$/;

function b64urlToBytes(value: string): Uint8Array {
  const padded = value + '='.repeat((4 - (value.length % 4)) % 4);
  const binary = atob(padded.replace(/-/g, '+').replace(/_/g, '/'));
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}
async function sha256(value: string): Promise<string> {
  const hash = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value));
  return Array.from(new Uint8Array(hash), (byte) => byte.toString(16).padStart(2, '0')).join('');
}
async function decryptReveal(ciphertext: string, setupCode: string): Promise<string> {
  const packed = b64urlToBytes(ciphertext);
  if (packed.length < 13) throw new Error('reveal');
  const iv = packed.slice(0, 12);
  const data = packed.slice(12);
  const keyHash = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(`repera-setup-v1:${setupCode}`),
  );
  const key = await crypto.subtle.importKey('raw', keyHash, 'AES-GCM', false, ['decrypt']);
  const plain = await crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, data);
  return new TextDecoder().decode(plain);
}

async function authRequest(jwt: string, path: string, method = 'GET', body?: unknown) {
  const result = await fetch(`${projectURL}/auth/v1/${path}`, {
    method, headers: { authorization: `Bearer ${jwt}`, apikey: Deno.env.get('SUPABASE_ANON_KEY')!,
      'content-type': 'application/json' }, body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(8000),
  });
  if (!result.ok) throw new Error('No se pudo completar la autorización. Abre de nuevo la conexión desde tu asistente.');
  return result.status === 204 ? {} : await result.json();
}

Deno.serve(async request => {
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers });
  const action = new URL(request.url).pathname.split('/').pop();
  try {
    if (request.method === 'GET' && action === 'catalog') {
      const { data, error } = await db.from('ai_oauth_providers').select('id,name,enabled,client_id,directory_url');
      if (error) return reply(503, { error: 'No se pueden cargar las conexiones. Inténtalo de nuevo.' });
      return reply(200, { providers: (data ?? []).map(connectionCatalogEntry) });
    }
    if (request.method !== 'POST') return reply(405, { error: 'Método no permitido' });
    if (request.headers.has('origin') && request.headers.get('origin') !== site) return reply(403, { error: 'Origen no permitido' });
    const jwt = /^Bearer ([\w.-]+)$/.exec(request.headers.get('authorization') ?? '')?.[1];
    if (!jwt || jwt.length > 8192) return reply(401, { error: 'Inicia sesión en Repera' });
    const { data: { user }, error } = await db.auth.getUser(jwt);
    if (error || !user) return reply(401, { error: 'Vuelve a iniciar sesión en Repera' });
    // Decoding is ONLY used after Auth has verified this exact JWT.
    const claims = JSON.parse(atob(jwt.split('.')[1].replace(/-/g,'+').replace(/_/g,'/')));
    if (claims.client_id || claims.role !== 'authenticated' || claims.sub !== user.id)
      return reply(403, { error: 'Esta acción requiere tu sesión personal de Repera' });
    const raw = await request.text();
    if (raw.length > 2048) return reply(413, { error: 'Solicitud demasiado grande' });
    const body = JSON.parse(raw);
    if (!body || typeof body !== 'object' || Array.isArray(body)) return reply(400, { error: 'Solicitud inválida' });
    if (action === 'disconnect' || action === 'delete') {
      if (!uuidPattern.test(body.id ?? '') || Object.keys(body).some(k => k !== 'id')) return reply(400, { error: 'Acceso inválido' });
      const { data: grant, error: lookupError } = await db.from('ai_access_tokens').select('id,oauth_client_id,revoked_at')
        .eq('id',body.id).eq('owner_id',user.id).maybeSingle();
      if (lookupError) return reply(503,{error:'No se pudo comprobar el acceso'});
      if (!grant) return reply(404,{error:'Acceso no encontrado'});
      if (!grant.revoked_at) {
        const { error: revokeError } = await db.from('ai_access_tokens').update({revoked_at:new Date().toISOString()})
          .eq('id',grant.id).eq('owner_id',user.id);
        if (revokeError) return reply(503,{error: action === 'delete' ? 'No se pudo borrar' : 'No se pudo desconectar'});
      }
      // Local grant revocation is immediate, even if Auth is temporarily down.
      let reconnectRequired = false;
      if (grant.oauth_client_id) {
        try { await authRequest(jwt,`user/oauth/grants?client_id=${encodeURIComponent(grant.oauth_client_id)}`,'DELETE'); }
        catch { reconnectRequired = true; }
      }
      if (action === 'delete') {
        const { error: deleteError } = await db.from('ai_access_tokens').delete()
          .eq('id',grant.id).eq('owner_id',user.id);
        if (deleteError) return reply(503,{error:'No se pudo borrar'});
        return reply(200,{deleted:true,reconnectRequired});
      }
      return reply(200,{disconnected:true,reconnectRequired});
    }
    if (action === 'redeem-setup') {
      if (!setupCodePattern.test(body.code ?? '') || Object.keys(body).some(k => k !== 'code')) {
        return reply(400, { error: 'Código de setup inválido' });
      }
      const code = body.code as string;
      const setupHash = await sha256(`repera-setup-code:${code}`);
      const { data: row, error: lookupError } = await db.from('ai_access_tokens')
        .select('id,label,expires_at,revoked_at,setup_code_expires_at,setup_code_used_at,setup_reveal_ciphertext')
        .eq('owner_id', user.id).eq('setup_code_hash', setupHash).maybeSingle();
      if (lookupError) return reply(503, { error: 'No se pudo comprobar el código' });
      if (!row) return reply(404, { error: 'Código no encontrado o de otra cuenta' });
      if (row.revoked_at) return reply(410, { error: 'Esta conexión ya está revocada' });
      if (row.setup_code_used_at) return reply(410, { error: 'Este código ya se ha usado' });
      if (!row.setup_code_expires_at || Date.parse(row.setup_code_expires_at) <= Date.now()) {
        return reply(410, { error: 'Este código ha caducado (válido 15 minutos)' });
      }
      if (!row.setup_reveal_ciphertext) return reply(410, { error: 'Este código ya no puede revelar el token' });
      let token: string;
      try { token = await decryptReveal(row.setup_reveal_ciphertext, code); }
      catch { return reply(400, { error: 'No se pudo abrir el código de setup' }); }
      const { error: wipeError } = await db.from('ai_access_tokens').update({
        setup_code_used_at: new Date().toISOString(),
        setup_reveal_ciphertext: null,
      }).eq('id', row.id).eq('owner_id', user.id).is('setup_code_used_at', null);
      if (wipeError) return reply(503, { error: 'No se pudo canjear el código' });
      return reply(200, {
        label: row.label,
        token,
        mcpUrl: publicMcp,
        expiresAt: row.expires_at,
        warning: 'Copia el token ahora. No volverá a mostrarse.',
      });
    }
    if (!['details','approve','deny'].includes(action ?? '') || !authorizationIdPattern.test(body.authorizationId ?? '') ||
      Object.keys(body).some(k => !['authorizationId','canWrite'].includes(k)) ||
      (body.canWrite !== undefined && typeof body.canWrite !== 'boolean')) return reply(400,{error:'Solicitud inválida'});
    const path = `oauth/authorizations/${body.authorizationId}`;
    const details = await authRequest(jwt,path);
    if (!details.authorization_id) {
      // Do not trust redirect URLs supplied by a query string or the browser.
      // Existing provider consent can outlive a local disconnect: require a new
      // explicit flow instead of silently restoring a revoked Repera grant.
      return reply(409,{error:'Esta autorización ya se ha utilizado. Desconecta Repera en tu asistente y vuelve a conectarla.'});
    }
    const { data: provider, error: providerError } = await db.from('ai_oauth_providers')
      .select('id,name,client_id').eq('client_id',details.client.id).eq('enabled',true).maybeSingle();
    if (providerError || !provider || details.user.id !== user.id) return reply(403,{error:'Este asistente todavía no está disponible para conectar con Repera'});
    if (action === 'details') return reply(200,{name:provider.name,scope:details.scope,account:user.email ?? '',provider:provider.id});
    if (action === 'deny') return reply(200,await authRequest(jwt,`${path}/consent`,'POST',{action:'deny'}));
    // The generated digest has no corresponding bearer credential. OAuth grants
    // reuse the attribution IDs and revocation controls without minting a PAT.
    const random = crypto.getRandomValues(new Uint8Array(32));
    const hash = Array.from(random,b=>b.toString(16).padStart(2,'0')).join('');
    const { data: grantID, error: grantError } = await db.rpc('create_ai_oauth_grant',{
      p_owner:user.id,p_client:provider.client_id,p_write:body.canWrite === true,p_hash:hash,
    });
    if (grantError || !grantID) return reply(503,{error:'No se pudo autorizar el acceso'});
    try {
      return reply(200,await authRequest(jwt,`${path}/consent`,'POST',{action:'approve'}));
    } catch (error) {
      await db.from('ai_access_tokens').update({revoked_at:new Date().toISOString()}).eq('id',grantID).eq('owner_id',user.id);
      throw error;
    }
  } catch {
    return reply(400,{error:'No se pudo completar la conexión. Vuelve a abrirla desde tu asistente.'});
  }
});
