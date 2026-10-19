/**
 * Production transport contract for Repera, NOT used by offline demo.
 * Client JWT is a verified Supabase Auth session issued through OAuth/email (never Apple userID).
 * A publishable Supabase key is safe in the static frontend; service_role and Stripe keys are not.
 * All authorization is enforced server-side by PostgreSQL RLS / RPC; browser context is untrusted.
 */
const VALID_REF=/^https:\/\/[a-z0-9-]+\.supabase\.co$/;
const TABLES=new Set(['organizations','org_members','clients','locations','coaching_groups','coaching_group_clients','program_templates','program_assignments','classes','class_bookings','products','client_passes','credit_ledger','business_payments','invoice_drafts','notification_outbox']);
const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export class SupabaseBusinessAPI {
 constructor({baseUrl,publishableKey,sessionProvider,fetcher=fetch}){
  if(!VALID_REF.test(baseUrl))throw Error('Supabase URL debe ser HTTPS y corresponder al proyecto independiente');
  if(!publishableKey||/service_role|sb_secret_/i.test(publishableKey))throw Error('Clave Supabase pública inválida');
  if(typeof sessionProvider!=='function')throw Error('Se requiere proveedor de sesión');
  this.base=baseUrl;this.key=publishableKey;this.sessionProvider=sessionProvider;this.fetcher=fetcher;
 }
 async send(path,{method='GET',body=null,headers={}}={}){
  const token=await this.sessionProvider();if(typeof token!=='string'||!token)throw Error('Inicia sesión para continuar');
  const response=await this.fetcher(`${this.base}/rest/v1/${path}`,{
   method,headers:{apikey:this.key,Authorization:`Bearer ${token}`,...(body===null?{}:{'Content-Type':'application/json'}),...headers},
   ...(body===null?{}:{body:JSON.stringify(body)})
  });
  if(!response.ok){const e=await response.json().catch(()=>({}));const err=new Error(response.status===403?'No autorizado':response.status===401?'Sesión caducada':e.message||`Error servidor ${response.status}`);err.status=response.status;throw err;}
  if(response.status===204)return null;return response.json();
 }
 async list(table,orgId,{limit=100,offset=0}={}){
  if(!TABLES.has(table))throw Error('Recurso no autorizado');
  if(!uuid.test(orgId))throw Error('Organización inválida');
  if(!Number.isInteger(limit)||limit<1||limit>200||!Number.isInteger(offset)||offset<0)throw Error('Paginación inválida');
  const query=new URLSearchParams({org_id:`eq.${orgId}`,select:'*',limit:String(limit),offset:String(offset)});
  return this.send(`${table}?${query}`);
 }
 async bookClass({orgId,classId,clientId,requestId}){
  for(const id of [orgId,classId,clientId,requestId])if(!uuid.test(id))throw Error('ID inválido');
  return this.send('rpc/book_class',{method:'POST',body:{_org:orgId,_class:classId,_client:clientId,_request:requestId}});
 }
 async cancelBooking({orgId,bookingId,requestId}){
  for(const id of [orgId,bookingId,requestId])if(!uuid.test(id))throw Error('ID inválido');
  return this.send('rpc/cancel_class_booking',{method:'POST',body:{_org:orgId,_booking:bookingId,_request:requestId}});
 }
}