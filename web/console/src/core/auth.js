/**
 * Repera's limited, dependency-free GoTrue/PostgREST adapter for a STATIC console.
 * Only intended for https://uvzgujlrqohreoucirms.supabase.co.
 * Browser tokens live in sessionStorage (this tab only); Auth, not this code, grants roles.
 */
const URL_REPERA='https://uvzgujlrqohreoucirms.supabase.co';
const SESSION_KEY='repera-business-supabase-session-v1';
const emptyStorage={getItem:()=>null,setItem:()=>{},removeItem:()=>{}};
const allowedKind=new Set(['personal_trainer','gym','sports_center']);
export class ReperaAuthAPI {
 constructor({baseUrl=URL_REPERA,publishableKey,fetcher=globalThis.fetch,storage=globalThis.sessionStorage,clock=()=>Date.now()}={}){
  if(baseUrl!==URL_REPERA)throw Error('Proyecto Supabase no autorizado para Repera');
  if(!/^sb_publishable_[A-Za-z0-9_-]+$/.test(publishableKey||''))throw Error('Se requiere clave pública moderna; nunca service_role');
  if(typeof fetcher!=='function')throw Error('No hay cliente HTTP disponible');
  this.base=baseUrl;this.key=publishableKey;this.fetcher=fetcher;this.storage=storage||emptyStorage;this.clock=clock;this.refreshing=null;
  try {const saved=JSON.parse(this.storage.getItem(SESSION_KEY)||'null');this.session=this.#valid(saved)?saved:null;}catch{this.session=null;this.storage.removeItem(SESSION_KEY);}
 }
 #valid(value){return !!(value&&typeof value.access_token==='string'&&value.access_token.length>2&&typeof value.refresh_token==='string'&&value.refresh_token.length>2&&Number.isFinite(value.expires_at));}
 #save(result){
  const next={access_token:result?.access_token,refresh_token:result?.refresh_token,expires_at:this.clock()+Math.max(0,Number(result?.expires_in)||0)*1000};
  if(!this.#valid(next))throw Error('Supabase no ha proporcionado una sesión válida');
  this.session=next;this.storage.setItem(SESSION_KEY,JSON.stringify(next));return next;
 }
 clear(){this.session=null;this.storage.removeItem(SESSION_KEY);}
 async #request(path,{method='GET',body,token=null,prefer}={}){
  const headers={'apikey':this.key,...(token?{Authorization:`Bearer ${token}`}:{}),...(body===undefined?{}:{'Content-Type':'application/json'}),...(prefer?{Prefer:prefer}:{})};
  const res=await this.fetcher(this.base+path,{method,headers,...(body===undefined?{}:{body:JSON.stringify(body)})});
  let data=null;
  if(res.status!==204){const responseText=await res.text();if(responseText){try{data=JSON.parse(responseText);}catch{data=null;}}}
  if(!res.ok){
   const reason=(data?.msg||data?.message||data?.error_description||data?.error||`Error HTTP ${res.status}`);
   const err=new Error(res.status===401?'Tu sesión ha caducado':res.status===403?'No tienes permiso para esta operación':reason);
   err.status=res.status;throw err;
  }
  return data;
 }
 async signIn(email,password){const result=await this.#request('/auth/v1/token?grant_type=password',{method:'POST',body:{email,password}});this.#save(result);return this.currentUser();}
 async signUp(email,password,redirectTo){
  const q=redirectTo?`?redirect_to=${encodeURIComponent(redirectTo)}`:'';
  const result=await this.#request('/auth/v1/signup'+q,{method:'POST',body:{email,password}});
  if(result?.access_token)this.#save(result);
  return {confirmationRequired:!result?.access_token};
 }
 async requestPasswordReset(email,redirectTo){
  const q=redirectTo?`?redirect_to=${encodeURIComponent(redirectTo)}`:'';
  await this.#request('/auth/v1/recover'+q,{method:'POST',body:{email}});
 }
 async acceptRecoveryFragment(fragment){
  const p=new URLSearchParams((fragment||'').replace(/^#/,''));if(p.get('type')!=='recovery')return false;
  if(!p.get('access_token')||!p.get('refresh_token'))throw Error('El enlace de recuperación no es válido');
  this.#save({access_token:p.get('access_token'),refresh_token:p.get('refresh_token'),expires_in:Number(p.get('expires_in')||3600)});
  await this.currentUser();return true;
 }
 async changePassword(password){
  const token=await this.token();
  if(!token)throw Error('Sesión de recuperación no disponible');
  return this.#request('/auth/v1/user',{method:'PUT',body:{password},token});
 }
 async token(){
  if(!this.session)return null;
  if(this.session.expires_at>this.clock()+90_000)return this.session.access_token;
  if(!this.refreshing){
   this.refreshing=this.#request('/auth/v1/token?grant_type=refresh_token',{method:'POST',body:{refresh_token:this.session.refresh_token}})
    .then(r=>this.#save(r).access_token).catch(e=>{this.clear();throw e}).finally(()=>{this.refreshing=null;});
  }
  return this.refreshing;
 }
 async currentUser(){
  const access=await this.token();if(!access)return null;
  try{return await this.#request('/auth/v1/user',{token:access});}
  catch(e){if(e.status===401||e.status===403)this.clear();throw e;}
 }
 async signOut(){
  const access=this.session?.access_token;
  try {if(access)await this.#request('/auth/v1/logout?scope=local',{method:'POST',token:access});}
  finally {this.clear();}
 }
 async #authorized(path,options={}){
  const token=await this.token();if(!token)throw Error('Inicia sesión para continuar');
  try{return await this.#request('/rest/v1/'+path,{...options,token});}
  catch(e){if(e.status===401)this.clear();throw e;}
 }
 async organizations(){
  return this.#authorized('organizations?select=id,name,slug,kind,created_at&order=created_at.desc');
 }
 async clients(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  return this.#authorized('clients?select=id,org_id,name,email,status,created_at&org_id=eq.'+encodeURIComponent(orgId)+'&order=created_at.desc');
 }
 async addClient({orgId,name,email,userId}){
  name=String(name||'').trim();email=String(email||'').trim().toLowerCase();
  if(!/^[0-9a-f-]{36}$/i.test(orgId||'')||name.length<2||name.length>120||!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))throw Error('Revisa los datos del cliente');
  return this.#authorized('clients?select=id,name,email,status',{method:'POST',prefer:'return=representation',body:{org_id:orgId,name,email,status:'lead',created_by:userId}});
 }
 async invitations(){
  return this.#authorized('organization_invitations?select=id,organization_id,email,invited_role,expires_at,accepted_at,cancelled_at,created_at&order=created_at.desc');
 }
 async issueInvitation({orgId,email,role}){
  email=String(email||'').trim().toLowerCase();
  if(!/^[0-9a-f-]{36}$/i.test(orgId||'')||!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)||!['admin','coach','reception','athlete'].includes(role))throw Error('Invitación inválida');
  return this.#authorized('rpc/issue_org_invitation',{method:'POST',body:{p_org:orgId,p_email:email,p_role:role}});
 }
 async acceptInvitation(id){
  if(!/^[0-9a-f-]{36}$/i.test(id||''))throw Error('Invitación inválida');
  return this.#authorized('rpc/accept_org_invitation',{method:'POST',body:{p_invitation_id:id}});
 }
 async cancelInvitation(id){
  if(!/^[0-9a-f-]{36}$/i.test(id||''))throw Error('Invitación inválida');
  return this.#authorized('rpc/cancel_org_invitation',{method:'POST',body:{p_invitation_id:id}});
 }
 async memberships(){
  return this.#authorized('organization_memberships?select=organization_id,user_id,role,status');
 }
 async createOrganization({name,slug,kind,userId}){
  name=String(name||'').trim();slug=String(slug||'').trim();
  if(name.length<2||name.length>120||!(/^[a-z0-9][a-z0-9-]{2,62}$/).test(slug)||!allowedKind.has(kind))throw Error('Comprueba nombre, identificador y tipo del negocio');
  if(!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId||''))throw Error('Identidad no validada');
  // SQL RLS verifies created_by == auth.uid(). The owner membership is created by a protected DB trigger.
  return this.#authorized('organizations?select=id,name,slug,kind',{method:'POST',prefer:'return=representation',body:{name,slug,kind,created_by:userId}});
 }
 async renameOrganization(orgId,name){
  name=String(name||'').trim();
  if(name.length<2||name.length>120||!/^[0-9a-f-]{36}$/i.test(orgId))throw Error('Datos de organización inválidos');
  // SQL permits only UPDATE(name), restricted by owner/admin membership.
  return this.#authorized('organizations?id=eq.'+encodeURIComponent(orgId)+'&select=id,name,slug,kind',{method:'PATCH',prefer:'return=representation',body:{name}});
 }
}
