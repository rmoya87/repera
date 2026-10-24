import { createRemoteJWKSet, jwtVerify } from 'npm:jose@6.1.3';
import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.58.0';

export const projectURL = 'https://uvzgujlrqohreoucirms.supabase.co';
export const mcpResource = `${projectURL}/functions/v1/repera-mcp`;
export const metadataURL = `${mcpResource}/.well-known/oauth-protected-resource`;
const issuer = `${projectURL}/auth/v1`;
const jwks = createRemoteJWKSet(new URL(`${issuer}/.well-known/jwks.json`));
export const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function resourceMetadata() {
  return { resource: mcpResource, authorization_servers: [issuer],
    bearer_methods_supported: ['header'], scopes_supported: ['openid'],
    resource_name: 'Repera', resource_documentation: 'https://repera.app/ai/' };
}
export function challenge() {
  return `Bearer resource_metadata="${metadataURL}"`;
}
export function isMCPIdentity(claims: Record<string, unknown>): boolean {
  return claims.role === 'repera_mcp' &&
    ['sub','client_id','session_id'].every(k => typeof claims[k] === 'string' && uuidPattern.test(claims[k] as string));
}
export async function resolveOAuthToken(db: SupabaseClient, bearer: string) {
  // Never accept the ordinary app audience or an unverified decoded JWT.
  const { payload } = await jwtVerify(bearer, jwks, {
    issuer, audience: mcpResource, algorithms: ['ES256','RS256'],
    requiredClaims: ['exp','iat','sub','client_id','session_id','role'],
  });
  if (!isMCPIdentity(payload)) return null;
  const { data, error } = await db.rpc('resolve_ai_oauth_grant', {
    p_owner: payload.sub, p_client: payload.client_id, p_session: payload.session_id,
  }).maybeSingle();
  if (error) throw new Error('Authorization lookup unavailable');
  return data as { id: string; owner_id: string; expires_at: string | null; scopes: string[] } | null;
}

export function validDirectoryURL(provider: string, value: unknown): string | null {
  if (typeof value !== 'string') return null;
  try {
    const url = new URL(value);
    const hosts = provider === 'chatgpt' ? ['chatgpt.com'] : provider === 'claude' ? ['claude.ai','claude.com'] : [];
    if (url.protocol !== 'https:' || !hosts.includes(url.hostname) || url.username || url.password || url.port || url.pathname === '/') return null;
    return url.href;
  } catch { return null; }
}

export function connectionCatalogEntry(provider: {
  id: string; name: string; enabled: boolean; client_id: string | null; directory_url: string | null;
}) {
  // This is a public OAuth client identifier, never a bearer token or a secret.
  // Claude's manually configured client must use PKCE and token auth "none".
  const canGuideClaude = provider.id === 'claude' && provider.enabled &&
    typeof provider.client_id === 'string' && uuidPattern.test(provider.client_id);
  return {
    id: provider.id,
    name: provider.name,
    directoryURL: provider.enabled ? validDirectoryURL(provider.id, provider.directory_url) : null,
    setup: canGuideClaude ? { kind: 'claude_prompt', clientID: provider.client_id } : null,
  };
}
