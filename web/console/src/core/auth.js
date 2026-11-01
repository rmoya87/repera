import {uniqueSlug,publicBusinessValues,legalProfileValues} from './business-profile.js';
/**
 * Repera's limited, dependency-free GoTrue/PostgREST adapter for a STATIC console.
 * Only intended for https://uvzgujlrqohreoucirms.supabase.co.
 * Browser tokens live in sessionStorage (this tab only); Auth, not this code, grants roles.
 */
import {browserFetch,wrapFetcher} from './http.js';
const URL_REPERA='https://uvzgujlrqohreoucirms.supabase.co';
const SESSION_KEY='repera-business-supabase-session-v1';
const emptyStorage={getItem:()=>null,setItem:()=>{},removeItem:()=>{}};
const allowedKind=new Set(['personal_trainer','gym','sports_center']);
export class ReperaAuthAPI {
 constructor({baseUrl=URL_REPERA,publishableKey,fetcher=browserFetch,storage=null,clock=()=>Date.now()}={}){
  if(baseUrl!==URL_REPERA)throw Error('Proyecto Supabase no autorizado para Repera');
  if(!/^sb_publishable_[A-Za-z0-9_-]+$/.test(publishableKey||''))throw Error('Se requiere clave pública moderna; nunca service_role');
  const store=storage||(typeof globalThis.sessionStorage!=='undefined'?globalThis.sessionStorage:emptyStorage);
  this.base=baseUrl;this.key=publishableKey;this.fetcher=wrapFetcher(fetcher);this.storage=store;this.clock=clock;this.refreshing=null;
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
   const raw=String(data?.msg||data?.message||data?.error_description||data?.error||`Error HTTP ${res.status}`);
   const mapped=res.status===401?'Tu sesión ha caducado'
    :/TRIAL_EXPIRED/i.test(raw)?'La prueba del centro ha caducado. Renueva el plan en Ajustes → Plan.'
    :/COACH_NOT_AUTHORIZED/i.test(raw)?'El entrenador elegido no es miembro activo del equipo. Elige un coach/owner de la lista (no uses cuentas de soporte).'
    :/INVALID_SERIES/i.test(raw)?'Revisa horario (debe ser futuro), duración (máx. 12 h), repetición y aforo.'
    :/organization_legal_profiles/i.test(raw)?'No se pudieron guardar los datos fiscales (permiso denegado). La foto del centro se puede reintentar aparte; si sigue fallando, pide a soporte que revise la RPC legal.'
    :/NOT_AUTHORIZED/i.test(raw)?'No tienes permiso: solo propietario o administrador pueden hacerlo.'
    :/WHATSAPP_INVALID/i.test(raw)?'Número de WhatsApp inválido. Usa prefijo país, p. ej. +34600111222.'
    :/CLIENT_ALREADY_LINKED/i.test(raw)?'Este correo ya está vinculado a una cuenta en tu centro.'
    :/ALREADY_A_MEMBER/i.test(raw)?'Esta persona ya forma parte de tu centro.'
    :/clients_org_email_uq|duplicate key.*clients_org_email/i.test(raw)?'Este correo ya tiene ficha en tu centro.'
    :/INVALID_EMAIL/i.test(raw)?'Revisa el correo electrónico.'
    :/INVALID_NAME/i.test(raw)?'Indica un nombre de al menos 2 caracteres.'
    :/TOO_MANY_OCCURRENCES/i.test(raw)?'Máximo 40 clases por asignación.'
    :/NO_OCCURRENCES/i.test(raw)?'Selecciona al menos una clase futura.'
    :/CLASS_NOT_EDITABLE/i.test(raw)?'Alguna clase no admite entreno (pasada, cancelada o no es clase).'
    :/INVALID_PRESCRIPTION/i.test(raw)?'Revisa el entrenamiento: necesita bloques válidos y un título de 2–120 caracteres.'
    :res.status===403&&!raw? 'No tienes permiso para esta operación'
    :raw;
   const err=new Error(mapped);
   err.status=res.status;err.code=raw;throw err;
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
 async platformAdminDirectory(){return this.#authorized('rpc/platform_admin_directory',{method:'POST',body:{}});}
 async platformAdminAthletes(){return this.#authorized('rpc/platform_admin_athletes',{method:'POST',body:{}});}
 async platformAdminCenterDetail(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Centro inválido');
  return this.#authorized('rpc/platform_admin_center_detail',{method:'POST',body:{p_org:orgId}});
 }
 async platformAdminAthleteDetail(athleteId){
  if(!/^[0-9a-f-]{36}$/i.test(athleteId||''))throw Error('Cuenta inválida');
  return this.#authorized('rpc/platform_admin_athlete_detail',{method:'POST',body:{p_athlete:athleteId}});
 }
 async platformAdminAthleteActivity(athleteId,month){
  if(!/^[0-9a-f-]{36}$/i.test(athleteId||'')||!/^[0-9]{4}-[0-9]{2}$/.test(month||''))throw Error('Mes inválido');
  return this.#authorized('rpc/platform_admin_athlete_activity',{method:'POST',
    body:{p_athlete:athleteId,p_month:month+'-01'}});
 }
 async platformAdminAthleteDay(athleteId,day){
  if(!/^[0-9a-f-]{36}$/i.test(athleteId||'')||!/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/.test(day||''))throw Error('Día inválido');
  return this.#authorized('rpc/platform_admin_athlete_day',{method:'POST',
    body:{p_athlete:athleteId,p_day:day}});
 }
 async platformAdminAthleteWorkouts(athleteId,offset=0,limit=30){
  if(!/^[0-9a-f-]{36}$/i.test(athleteId||'')||!Number.isInteger(offset)||offset<0||
    !Number.isInteger(limit)||limit<1||limit>50)throw Error('Paginación de entrenamientos inválida');
  return this.#authorized('rpc/platform_admin_athlete_workouts',{method:'POST',
    body:{p_athlete:athleteId,p_limit:limit,p_offset:offset}});
 }

 async platformAdminSettings(){return this.#authorized('rpc/platform_admin_settings',{method:'POST',body:{}});}
 async platformAdminSaveTrialDays(days){
  const d=Number(days);
  if(!Number.isInteger(d)||d<1||d>60)throw Error('El periodo debe ser de 1 a 60 días');
  return this.#authorized('rpc/platform_admin_save_trial_days',{method:'POST',body:{p_days:d}});
 }
 async platformAdminSaveSettings(values){
  const safe=key=>String(values[key]||'').trim();
  return this.#authorized('rpc/platform_admin_update_settings',{method:'POST',body:{
   p_support_email:safe('support_email'),p_support_url:safe('support_url'),
   p_billing_email:safe('billing_email'),p_privacy_url:safe('privacy_url'),p_terms_url:safe('terms_url')}});
 }
 async platformAdminAttachBranding({provisioningId,url}){
  return this.#authorized('rpc/platform_admin_attach_branding',{method:'POST',
    body:{p_provision:provisioningId,p_avatar_url:url}});
 }
 async uploadPlatformPendingBrand({provisioningId,kind,file}){
  if(!/^[0-9a-f-]{36}$/i.test(provisioningId||'')||!['gym','personal_trainer'].includes(kind))throw Error('Alta inválida');
  const blob=await this.#compressAvatar(file,1048576);
  const filename=kind==='personal_trainer'?'trainer.jpg':'logo.jpg';
  const objectPath='pending/'+provisioningId+'/'+filename;
  const url=await this.#uploadStorage('business-branding',objectPath,blob,false);
  await this.platformAdminAttachBranding({provisioningId,url});
  return url;
 }
 async updateOwnProfile({displayName}){
  const name=String(displayName||'').trim(),user=await this.currentUser();
  if(!user?.id||name.length<2||name.length>100)throw Error('Indica un nombre de 2 a 100 caracteres');
  return this.#authorized('profiles?id=eq.'+encodeURIComponent(user.id)+'&select=id,display_name,avatar_url',
   {method:'PATCH',prefer:'return=representation',body:{display_name:name}});
 }
 async changeOwnEmail(email){
  const address=String(email||'').trim().toLowerCase();
  if(!/^[^ @]+@[^ @]+[.][^ @]+$/.test(address)||address.length>180)
   throw Error('Introduce un correo electrónico válido');
  const token=await this.token();if(!token)throw Error('Inicia sesión');
  return this.#request('/auth/v1/user',{method:'PUT',token,body:{email:address}});
 }
 async uploadOwnAvatar(file){
  const user=await this.currentUser();if(!user?.id)throw Error('Inicia sesión');
  const blob=await this.#compressAvatar(file,2097152);
  const objectPath=user.id+'/avatar.jpg';
  const url=await this.#uploadStorage('profile-avatars',objectPath,blob,true);
  const result=await this.#authorized('profiles?id=eq.'+encodeURIComponent(user.id)+'&select=id,avatar_url',
   {method:'PATCH',prefer:'return=representation',body:{avatar_url:url+'?v='+Date.now()}});
  if(!result?.length)throw Error('No se pudo actualizar el perfil con la foto');
  return url;
 }
 async #compressAvatar(file,maxBytes){
  if(!file?.size||!['image/jpeg','image/png','image/webp'].includes(file.type)||file.size>8*1024*1024)
   throw Error('Elige una imagen JPG, PNG o WebP de hasta 8 MB');
  const bitmap=await createImageBitmap(file);
  const scale=Math.min(1,900/Math.max(bitmap.width,bitmap.height));
  const canvas=document.createElement('canvas');
  canvas.width=Math.max(1,Math.round(bitmap.width*scale));canvas.height=Math.max(1,Math.round(bitmap.height*scale));
  canvas.getContext('2d').drawImage(bitmap,0,0,canvas.width,canvas.height);bitmap.close?.();
  const blob=await new Promise(resolve=>canvas.toBlob(resolve,'image/jpeg',0.78));
  if(!blob||blob.size>maxBytes)throw Error('La imagen supera el tamaño máximo permitido');
  return blob;
 }
 async #uploadStorage(bucket,path,blob,upsert){
  const jwt=await this.token();if(!jwt)throw Error('Inicia sesión');
  const response=await this.fetcher(this.base+'/storage/v1/object/'+bucket+'/'+path,{
   method:'POST',headers:{apikey:this.key,Authorization:'Bearer '+jwt,'Content-Type':'image/jpeg',...(upsert?{'x-upsert':'true'}:{})},body:blob});
  if(!response.ok){let msg='No se pudo subir la imagen';try{const body=await response.json();msg=body?.message||body?.error||msg;}catch{}throw Error(msg);}
  return this.base+'/storage/v1/object/public/'+bucket+'/'+path;
 }
 async platformAdminFinances(){return this.#authorized('rpc/platform_admin_finances',{method:'POST',body:{}});}
 async platformAdminHistory(){return this.#authorized('rpc/platform_admin_history',{method:'POST',body:{}});}
 async platformAdminPending(){return this.#authorized('rpc/platform_admin_pending',{method:'POST',body:{}});}
 async claimPlatformProvisioning(){return this.#authorized('rpc/claim_platform_provisioning',{method:'POST',body:{}});}
 async platformAdminProvision({name,kind,email,plan=null}){
  const n=String(name||'').trim(),address=String(email||'').trim().toLowerCase();
  if(n.length<2||n.length>120||!['gym','personal_trainer'].includes(kind)||!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(address)||address.length>180)
   throw Error('Revisa el nombre, el tipo y el correo del propietario');
  return this.#authorized('rpc/platform_admin_provision',{method:'POST',
   body:{p_name:n,p_kind:kind,p_email:address,p_plan:plan||null}});
 }
 async platformAdminSetVisibility({orgId,visible}){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||'')||typeof visible!=='boolean')throw Error('Visibilidad inválida');
  return this.#authorized('rpc/platform_admin_set_visibility',{method:'POST',
   body:{p_org:orgId,p_visible:visible}});
 }
 async platformAdminSetStatus({orgId,status,reason}){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||'')||!['active','suspended'].includes(status)||String(reason||'').trim().length<8)
   throw Error('Indica un estado y un motivo válido');
  return this.#authorized('rpc/platform_admin_set_status',{method:'POST',
   body:{p_org:orgId,p_status:status,p_reason:String(reason).trim()}});
 }
 async platformAdminDelegate({orgId,reason}){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||'')||String(reason||'').trim().length<12)
   throw Error('Indica el negocio y un motivo de al menos 12 caracteres');
  return this.#authorized('rpc/platform_admin_delegate',{method:'POST',
   body:{p_org:orgId,p_reason:String(reason).trim()}});
 }
 async platformAdminCurrentDelegation(){return this.#authorized('rpc/platform_admin_current_delegation',{method:'POST',body:{}});}
 async platformAdminEndDelegation(){
  return this.#authorized('rpc/platform_admin_end_delegation',{method:'POST',body:{},prefer:'return=minimal'});
 }
 async platformOverview(){
  return this.#authorized('rpc/platform_business_overview',{method:'POST',body:{}});
 }
 async myProfile(){
  const user=await this.currentUser();if(!user?.id)return null;
  const rows=await this.#authorized('profiles?select=id,role,display_name,avatar_url&id=eq.'+encodeURIComponent(user.id));
  return rows?.[0]||null;
 }
 async organizations(){
  return this.#authorized('organizations?select=id,name,slug,kind,avatar_url,tagline,is_discoverable,public_email,phone,website,address,description,timezone,whatsapp_e164,whatsapp_connected_at,class_booking_open_hours,created_at&order=created_at.desc');
 }
 async enrollmentRequests(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Centro inválido');
  const raw=await this.#authorized('rpc/business_enrollment_requests',{method:'POST',body:{p_org:orgId}});
  if(Array.isArray(raw))return raw;
  if(typeof raw==='string'){
   try{const parsed=JSON.parse(raw);return Array.isArray(parsed)?parsed:[];}catch{return [];}
  }
  return [];
 }
 async decideEnrollment(requestId,accept){
  if(!/^[0-9a-f-]{36}$/i.test(requestId||'')||typeof accept!=='boolean')throw Error('Solicitud inválida');
  const raw=await this.#authorized('rpc/business_decide_enrollment',{method:'POST',body:{p_request:requestId,p_accept:accept}});
  // Compat: migraciones antiguas devolvían uuid; la nueva devuelve {org_id,client_id,accepted}.
  if(typeof raw==='string'&&/^[0-9a-f-]{36}$/i.test(raw))return {org_id:raw,client_id:null,accepted:!!accept};
  if(raw&&typeof raw==='object')return {
   org_id:raw.org_id||null,
   client_id:raw.client_id||null,
   accepted:raw.accepted===true||!!accept,
   request_id:raw.request_id||requestId,
  };
  return {org_id:null,client_id:null,accepted:!!accept};
 }
 async bulkPublishCustomTraining({orgId,clientIds,start,end,weekdays,title,instructions='',prescription,requestId=globalThis.crypto?.randomUUID?.()}){
  const uid=id=>/^[0-9a-f-]{36}$/i.test(id||'');
  if(!uid(orgId)||!uid(requestId)||!Array.isArray(clientIds)||
   !clientIds.length||clientIds.length>20||clientIds.some(c=>!uid(c))||
   !Array.isArray(weekdays)||!weekdays.length||weekdays.some(x=>!Number.isInteger(x)||x<1||x>7)||
   !/^\d{4}-\d{2}-\d{2}$/.test(start||'')||!/^\d{4}-\d{2}-\d{2}$/.test(end||'')||
   String(title).trim().length<2||String(title).length>120||String(instructions).length>10000)
   throw Error('Completa los clientes, fechas y entrenamiento');
  return this.#authorized('rpc/business_publish_custom_training_bulk',{method:'POST',body:{
   p_org:orgId,p_clients:clientIds,p_start:start,p_end:end,p_weekdays:weekdays,
   p_title:String(title).trim(),p_instructions:String(instructions),p_prescription:prescription,
   p_request:requestId}});
 }
 async bulkPublishTraining({orgId,templateId,clientIds,start,end,weekdays,requestId}){
  const validId=id=>/^[0-9a-f-]{36}$/i.test(id||'');
  if(!validId(orgId)||!validId(templateId)||!validId(requestId)||!Array.isArray(clientIds)||
    clientIds.length<1||clientIds.length>20||clientIds.some(id=>!validId(id))||
    !/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/.test(start||'')||
    !/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/.test(end||'')||
    !Array.isArray(weekdays)||!weekdays.length||weekdays.some(x=>!Number.isInteger(x)||x<1||x>7))
   throw Error('Revisa fechas, plantilla y atletas seleccionados');
  return this.#authorized('rpc/business_publish_training_bulk',{method:'POST',body:{
   p_org:orgId,p_template:templateId,p_clients:clientIds,p_start:start,p_end:end,
   p_weekdays:weekdays,p_request:requestId}});
 }
 async clients(orgId,{basic=false}={}){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  // Minimize the payload for non-manager workspaces. RLS enforces which
  // rows are visible; this endpoint also avoids loading notes/phone at all.
  const fields=basic?'id,org_id,user_id,name,email,avatar_url,status,account_deleted_at,created_at,updated_at':
   'id,org_id,user_id,name,email,phone,notes,avatar_url,status,account_deleted_at,created_at,updated_at';
  return this.#authorized('clients?select='+fields+'&org_id=eq.'+encodeURIComponent(orgId)+'&order=updated_at.desc');
 }
 async clientAvatars(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  return this.#authorized('rpc/business_client_avatars',{method:'POST',body:{p_org:orgId}});
 }
 async addClient({orgId,name,email,userId,phone=''}){
  name=String(name||'').trim();email=String(email||'').trim().toLowerCase();
  const phoneVal=String(phone||'').trim().slice(0,40);
  if(!/^[0-9a-f-]{36}$/i.test(orgId||'')||name.length<2||name.length>120||!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))throw Error('Revisa los datos del cliente');
  const rows=await this.#authorized('clients?select=id,name,email,phone,status',{method:'POST',prefer:'return=representation',
   body:{org_id:orgId,name,email,status:'lead',created_by:userId}});
  const created=Array.isArray(rows)?rows[0]:rows;
  if(created?.id&&phoneVal){
   try{
    await this.updateClientProfile({orgId,id:created.id,name,email,phone:phoneVal,status:created.status||'lead'});
    created.phone=phoneVal;
   }catch{/* phone opcional; la ficha ya existe */}
  }
  return rows;
 }
 /** Crea o reutiliza ficha lead + invitación athlete; opcional prueba o bono cobrado. */
 async inviteAthleteClient({
  orgId,name,email,phone='',
  passMode='none',trialCredits=null,trialKind=null,trialDays=30,
  offerId=null,paymentMethod='cash',paidAmountCents=null,paymentNote='',passRequest=null,
 }={}){
  name=String(name||'').trim();email=String(email||'').trim().toLowerCase();
  const phoneVal=String(phone||'').trim().slice(0,40);
  const mode=String(passMode||'none');
  if(!/^[0-9a-f-]{36}$/i.test(orgId||'')||name.length<2||name.length>120||!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
   throw Error('Revisa los datos del cliente');
  if(!['none','trial','paid'].includes(mode))throw Error('Elige cómo configurar el acceso');
  const body={
   p_org:orgId,p_name:name,p_email:email,p_phone:phoneVal||null,
   p_pass_mode:mode,
  };
  if(mode==='trial'){
   const credits=Number(trialCredits);
   if(!Number.isInteger(credits)||credits<1||credits>100)throw Error('Indica de 1 a 100 sesiones de prueba');
   body.p_trial_credits=credits;
   body.p_trial_kind=['class','appointment'].includes(trialKind)?trialKind:null;
   body.p_trial_days=Math.max(1,Math.min(365,Number(trialDays)||30));
  }
  if(mode==='paid'){
   if(!/^[0-9a-f-]{36}$/i.test(offerId||''))throw Error('Elige un bono o tarifa');
   if(!['card','transfer','cash','other'].includes(paymentMethod))throw Error('Forma de pago no válida');
   body.p_offer_id=offerId;
   body.p_payment_method=paymentMethod;
   body.p_pass_request=passRequest||(globalThis.crypto?.randomUUID?.()||null);
   if(!body.p_pass_request)throw Error('No se pudo preparar la asignación del bono');
   if(paidAmountCents!=null&&Number.isFinite(Number(paidAmountCents)))
    body.p_paid_amount_cents=Math.round(Number(paidAmountCents));
   if(paymentNote)body.p_payment_note=String(paymentNote).slice(0,400);
  }
  return this.#authorized('rpc/invite_athlete_client',{method:'POST',body});
 }
 async invitations(){
  return this.#authorized('organization_invitations?select=id,organization_id,email,invited_role,expires_at,accepted_at,cancelled_at,created_at&order=created_at.desc');
 }
 async sendOwnerRegistrationEmail(provisioningId){
  if(!/^[0-9a-f-]{36}$/i.test(provisioningId||''))throw Error('Alta de centro inválida');
  const token=await this.token();if(!token)throw Error('Inicia sesión');
  try{
   const result=await this.#request('/functions/v1/repera-business-invite',{
    method:'POST',token,body:{provisioningId}});
   return {sent:result?.sent===true};
  }catch(e){
   if(e.status===503)return {sent:false,reason:'Proveedor de correo pendiente de configurar'};
   if(e.status===502)return {sent:false,reason:'El proveedor no ha confirmado el envío'};
   throw e;
  }
 }
 async sendInvitationEmail(invitationId){
  if(!/^[0-9a-f-]{36}$/i.test(invitationId||''))throw Error('Invitación inválida');
  const token=await this.token();if(!token)throw Error('Inicia sesión');
  try{
   const result=await this.#request('/functions/v1/repera-business-invite',{
    method:'POST',token,body:{invitationId}});
   if(result?.sent===true)return {sent:true,reason:''};
   return {sent:false,reason:result?.error||'El servidor no confirmó el envío'};
  }catch(e){
   if(e.status===503)return {sent:false,reason:'Proveedor de correo (Resend) sin configurar en el servidor'};
   if(e.status===502)return {sent:false,reason:'Resend no ha confirmado la entrega'};
   if(e.status===401)return {sent:false,reason:'Sesión no válida para enviar el correo'};
   if(e.status===403)return {sent:false,reason:'Sin permiso para enviar esta invitación'};
   if(e.status===400)return {sent:false,reason:e.message||'Invitación no disponible'};
   return {sent:false,reason:e.message||'Envío no confirmado'};
  }
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
 async sharedAthleteResults({orgId,clientId,limit=40}){
  if(![orgId,clientId].every(id=>/^[0-9a-f-]{36}$/i.test(id||''))||
     !Number.isInteger(limit)||limit<1||limit>100)throw Error('Identificadores de resultados inválidos');
  // The SECURITY INVOKER wrapper checks active staff role, assignment and
  // explicit athlete consent. The browser never queries workout-mirror rows.
  return this.#authorized('rpc/get_shared_athlete_results',{method:'POST',
   body:{p_org:orgId,p_client:clientId,p_limit:limit}});
 }
 async professionalSessions(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  return this.#authorized('professional_training_sessions?select=id,org_id,client_id,coach_user_id,scheduled_date,scheduled_time_minutes,source_occurrence_id,title,instructions,prescription,status&org_id=eq.'+orgId+'&order=scheduled_date.asc&limit=200');
 }
 async publishProfessionalSession({orgId,clientId,date,title,instructions='',prescription,requestId=globalThis.crypto?.randomUUID?.()}){
  title=String(title||'').trim();instructions=String(instructions||'');
  if(![orgId,clientId,requestId].every(id=>/^[0-9a-f-]{36}$/i.test(id||''))||title.length<2
    ||title.length>120||instructions.length>10000||!/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/.test(date||''))
      throw Error('Planificación inválida');
  return this.#authorized('rpc/publish_professional_session_v2',{method:'POST',body:{p_org:orgId,p_client:clientId,p_day:date,p_title:title,p_instructions:instructions,p_request:requestId,p_prescription:prescription}});
 }
 async setProfessionalSessionTime(sessionId,hhmm){
  if(!/^[0-9a-f-]{36}$/i.test(sessionId||''))throw Error('Sesión inválida');
  if(hhmm!==''&&!/^([01]\\d|2[0-3]):[0-5]\\d$/.test(hhmm||''))throw Error('Hora no válida');
  const minutes=hhmm===''?null:Number(hhmm.slice(0,2))*60+Number(hhmm.slice(3,5));
  return this.#authorized('rpc/set_professional_session_time',{method:'POST',body:{p_session:sessionId,p_minutes:minutes}});
 }
 async assignCoachClient({orgId,clientId,coachId}){
  if(![orgId,clientId,coachId].every(id=>/^[0-9a-f-]{36}$/i.test(id||'')))throw Error('Asignación inválida');
  return this.#authorized('rpc/assign_coach_client',{method:'POST',body:{p_org:orgId,p_client:clientId,p_coach:coachId}});
 }
 async serviceOccurrences(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  return this.#authorized('service_occurrences?select=id,org_id,kind,title,starts_at,ends_at,capacity,status,coach_user_id&org_id=eq.'+orgId+'&status=neq.deleted&order=starts_at.asc&limit=500');
 }
 async servicePasses(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  const base='service_passes?select=id,org_id,client_id,offer_id,kind,total_credits,remaining_credits,valid_from,valid_until,status,issuance_type,created_at';
  const pay=',payment_method,paid_at,paid_amount_cents,payment_note';
  const slot=',billing_model,access_scope,slot_weekdays,slot_start_minute,slot_end_minute';
  const tail='&org_id=eq.'+orgId+'&order=created_at.desc';
  try{
   return await this.#authorized(base+pay+slot+tail);
  }catch(e){
   const msg=String(e.message||e);
   if(/billing_model|access_scope|slot_|column/i.test(msg)){
    try{return await this.#authorized(base+pay+tail);}
    catch(e2){
     if(/payment_method|paid_at|paid_amount|column/i.test(String(e2.message||e2)))
      return this.#authorized(base+tail);
     throw e2;
    }
   }
   if(/payment_method|paid_at|paid_amount|column/i.test(msg))
    return this.#authorized(base+tail);
   throw e;
  }
 }
 async servicePassManagementEvents(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  return this.#authorized('service_pass_management_events?select=id,org_id,pass_id,action,previous_remaining,new_remaining,previous_expiry,new_expiry,created_at&org_id=eq.'+orgId+'&order=created_at.desc&limit=200');
 }
 async servicePassOffers(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  const cols='id,org_id,name,kind,credits,validity_days,price_cents,currency,is_active,billing_model,access_scope,slot_weekdays,slot_start_minute,slot_end_minute';
  try{
   return await this.#authorized('business_pass_offers?select='+cols+'&org_id=eq.'+orgId+'&order=created_at.desc');
  }catch(e){
   if(/billing_model|access_scope|slot_|column/i.test(String(e.message||e)))
    return this.#authorized('business_pass_offers?select=id,org_id,name,kind,credits,validity_days,price_cents,currency,is_active&org_id=eq.'+orgId+'&order=created_at.desc');
   throw e;
  }
 }
 async createServicePassOffer({orgId,name,kind,credits,validityDays,priceCents,billingModel='session_pack',
  accessScope='trainer_appointments',slotWeekdays=[1,2,3,4,5],slotStartMinute=540,slotEndMinute=720}){
  name=String(name||'').trim();
  const billing=['session_pack','monthly','unlimited','time_slot'].includes(billingModel)?billingModel:'session_pack';
  const scope=accessScope==='gym_access'?'gym_access':'trainer_appointments';
  const days=[...new Set((slotWeekdays||[]).map(Number).filter(n=>n>=1&&n<=7))];
  if(!/^[0-9a-f-]{36}$/i.test(orgId||'')||name.length<2||name.length>120||
     !['class','appointment'].includes(kind)||!Number.isInteger(credits)||credits<1||credits>9999||
     !Number.isInteger(validityDays)||validityDays<1||validityDays>730||
     !Number.isInteger(priceCents)||priceCents<0||priceCents>10000000)
    throw Error('Datos de bono o tarifa inválidos');
  if(billing==='time_slot'){
   if(!days.length||!Number.isInteger(slotStartMinute)||!Number.isInteger(slotEndMinute)
      ||slotStartMinute<0||slotEndMinute>1440||slotEndMinute<=slotStartMinute)
    throw Error('Franja horaria no válida');
  }
  // RPC evita fallos de schema cache de PostgREST al INSERT con columnas nuevas.
  try{
   const id=await this.#authorized('rpc/business_create_pass_offer',{method:'POST',body:{
    p_org:orgId,p_name:name,p_kind:kind,p_credits:credits,p_validity_days:validityDays,
    p_price_cents:priceCents,p_billing_model:billing,p_access_scope:scope,
    p_slot_weekdays:billing==='time_slot'?days:[1,2,3,4,5],
    p_slot_start_minute:billing==='time_slot'?slotStartMinute:540,
    p_slot_end_minute:billing==='time_slot'?slotEndMinute:720,
   }});
   return [{id}];
  }catch(e){
   const msg=String(e.message||e);
   if(!/Could not find the function|PGRST202|schema cache/i.test(msg))throw e;
   // Fallback legacy REST sin columnas nuevas (solo session_pack básico).
   return this.#authorized('business_pass_offers?select=id,name',{method:'POST',prefer:'return=representation',body:{
    org_id:orgId,name,kind,credits,validity_days:validityDays,price_cents:priceCents,
    currency:'EUR',is_active:true}});
  }
 }
 async listCoachAssignments(){
  return this.#authorized('rpc/list_my_coach_assignments',{method:'POST',body:{}});
 }
 async coachAckOccurrence({occurrenceId,ack}){
  if(!/^[0-9a-f-]{36}$/i.test(occurrenceId||'')||!['accepted','declined'].includes(ack))
   throw Error('Asignación inválida');
  return this.#authorized('rpc/coach_ack_occurrence',{method:'POST',body:{p_occurrence:occurrenceId,p_ack:ack}});
 }
 async coachRescheduleOccurrence({occurrenceId,start,end}){
  if(!/^[0-9a-f-]{36}$/i.test(occurrenceId||'')||!start||!end)
   throw Error('Horario de clase inválido');
  return this.#authorized('rpc/coach_reschedule_occurrence',{method:'POST',body:{
   p_occurrence:occurrenceId,p_start:new Date(start).toISOString(),p_end:new Date(end).toISOString()}});
 }
 async coachCancelOccurrence(occurrenceId){
  if(!/^[0-9a-f-]{36}$/i.test(occurrenceId||''))throw Error('Clase inválida');
  return this.#authorized('rpc/coach_cancel_occurrence',{method:'POST',body:{p_occurrence:occurrenceId}});
 }
 async issueOfflinePass({orgId,clientId,offerId,requestId=globalThis.crypto?.randomUUID?.(),
  paymentMethod='other',paidAt=null,paidAmountCents=null,paymentNote=''}){
  if(![orgId,clientId,offerId,requestId].every(id=>/^[0-9a-f-]{36}$/i.test(id||'')))
   throw Error('Cliente, bono o solicitud no válidos');
  if(!['card','transfer','cash','other','complimentary'].includes(paymentMethod))
   throw Error('Forma de pago no válida');
  const body={
   p_org:orgId,p_client:clientId,p_offer:offerId,p_request:requestId,
   p_payment_method:paymentMethod,
  };
  if(paidAt)body.p_paid_at=new Date(paidAt).toISOString();
  if(paidAmountCents!=null&&Number.isFinite(Number(paidAmountCents)))
   body.p_paid_amount_cents=Math.round(Number(paidAmountCents));
  if(paymentNote)body.p_payment_note=String(paymentNote).slice(0,400);
  try{
   return await this.#authorized('rpc/business_issue_offline_pass',{method:'POST',body});
  }catch(e){
   // Compat: RPC antiguo de 4 args si aún no está la migración de cobro.
   if(/Could not find the function|PGRST202|payment_method/i.test(String(e.message||e))){
    return this.#authorized('rpc/business_issue_offline_pass',{method:'POST',body:{
     p_org:orgId,p_client:clientId,p_offer:offerId,p_request:requestId}});
   }
   throw e;
  }
 }
 async recordTrainerAttendance({orgId,clientId,passId,occurrenceId=null,note='',requestId=globalThis.crypto?.randomUUID?.()}){
  if(![orgId,clientId,passId,requestId].every(id=>/^[0-9a-f-]{36}$/i.test(id||''))||
     occurrenceId&&!/^[0-9a-f-]{36}$/i.test(occurrenceId)||String(note).length>1000)
    throw Error('Datos de sesión no válidos');
  return this.#authorized('rpc/business_record_trainer_attendance',{method:'POST',body:{
   p_org:orgId,p_client:clientId,p_pass:passId,p_occurrence:occurrenceId,
   p_note:String(note),p_request:requestId}});
 }
 async markClassAttendance({bookingId,status,requestId=globalThis.crypto?.randomUUID?.()}){
  if(!/^[0-9a-f-]{36}$/i.test(bookingId||'')||!/^[0-9a-f-]{36}$/i.test(requestId||'')||
     !['attended','no_show'].includes(status))
   throw Error('Asistencia no válida');
  return this.#authorized('rpc/business_mark_class_attendance',{method:'POST',body:{
   p_booking:bookingId,p_status:status,p_request:requestId}});
 }
 async trainerAttendance(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  return this.#authorized('business_trainer_attendance?select=id,org_id,client_id,pass_id,booking_id,occurrence_id,performed_at,note&org_id=eq.'+orgId+'&order=performed_at.desc&limit=200');
 }
 async updateOrgBookingWindow({orgId,hours}){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  const h=Number(hours);
  if(!Number.isInteger(h)||h<1||h>8760)throw Error('Antelación no válida');
  return this.#authorized('rpc/update_org_booking_window',{method:'POST',body:{p_org:orgId,p_hours:h}});
 }
 async changeServicePassOffer({id,isActive}){
  if(!/^[0-9a-f-]{36}$/i.test(id||'')||typeof isActive!=='boolean')throw Error('Oferta inválida');
  return this.#authorized('business_pass_offers?id=eq.'+id,{method:'PATCH',prefer:'return=representation',body:{is_active:isActive}});
 }
 async updateServicePassOffer({
  id,name,kind,credits,validityDays,priceCents,isActive,
  billingModel='session_pack',accessScope='trainer_appointments',
  slotWeekdays=[1,2,3,4,5],slotStartMinute=540,slotEndMinute=720,
 }){
  if(!/^[0-9a-f-]{36}$/i.test(id||''))throw Error('Plan inválido');
  name=String(name||'').trim();
  const billing=['session_pack','monthly','unlimited','time_slot'].includes(billingModel)?billingModel:'session_pack';
  const scope=accessScope==='gym_access'?'gym_access':'trainer_appointments';
  const days=[...new Set((slotWeekdays||[]).map(Number).filter(n=>n>=1&&n<=7))];
  if(name.length<2||name.length>120||!['class','appointment'].includes(kind)||
     !Number.isInteger(credits)||credits<1||credits>9999||
     !Number.isInteger(validityDays)||validityDays<1||validityDays>730||
     !Number.isInteger(priceCents)||priceCents<0||priceCents>10000000||
     typeof isActive!=='boolean')
   throw Error('Datos del plan inválidos');
  if(billing==='time_slot'&&(!days.length||slotEndMinute<=slotStartMinute))
   throw Error('Franja horaria no válida');
  const body={
   name,kind,credits,validity_days:validityDays,price_cents:priceCents,is_active:isActive,
   billing_model:billing,access_scope:scope,
   slot_weekdays:billing==='time_slot'?days:[1,2,3,4,5],
   slot_start_minute:billing==='time_slot'?slotStartMinute:540,
   slot_end_minute:billing==='time_slot'?slotEndMinute:720,
   updated_at:new Date().toISOString(),
  };
  return this.#authorized('business_pass_offers?id=eq.'+id,{method:'PATCH',prefer:'return=representation',body});
 }
 async serviceBookings(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  return this.#authorized('service_bookings?select=id,org_id,client_id,occurrence_id,pass_id,status,booked_at&org_id=eq.'+orgId+'&order=booked_at.desc&limit=300');
 }
 async addServiceOccurrence({orgId,coachId,kind,title,start,end,capacity}){
  title=String(title||'').trim();
  const begins=new Date(start),ends=new Date(end);
  if(!/^[0-9a-f-]{36}$/i.test(orgId||'')||!/^[0-9a-f-]{36}$/i.test(coachId||'')
     ||!['class','appointment'].includes(kind)||title.length<2||title.length>120
     ||!Number.isFinite(begins.getTime())||!Number.isFinite(ends.getTime())||ends<=begins
     ||begins<=new Date()||ends-begins>12*3600*1000||!Number.isInteger(capacity)
     ||capacity<1||capacity>200||(kind==='appointment'&&capacity!==1))
      throw Error('Horario, entrenador, tipo o aforo inválido');
  return this.#authorized('service_occurrences?select=id,title,kind,starts_at',{method:'POST',prefer:'return=representation',
   body:{org_id:orgId,coach_user_id:coachId,kind,title,starts_at:begins.toISOString(),ends_at:ends.toISOString(),capacity}});
 }
 async grantCourtesyPass({orgId,clientId,kind,credits,validUntil}){
  const until=new Date(validUntil);
  if(!/^[0-9a-f-]{36}$/i.test(orgId||'')||!/^[0-9a-f-]{36}$/i.test(clientId||'')
    ||!['class','appointment'].includes(kind)||!Number.isInteger(credits)||credits<1||credits>1000
    ||!Number.isFinite(until.getTime())||until<=new Date())throw Error('Bono de cortesía inválido');
  return this.#authorized('rpc/grant_complimentary_pass',{method:'POST',
   body:{p_org:orgId,p_client:clientId,p_kind:kind,p_credits:credits,p_valid_until:until.toISOString()}});
 }
 async bookService({occurrenceId,passId,requestId}){
  if(![occurrenceId,passId,requestId].every(x=>/^[0-9a-f-]{36}$/i.test(x||'')))throw Error('Reserva inválida');
  return this.#authorized('rpc/book_service_occurrence',{method:'POST',body:{p_occurrence:occurrenceId,p_pass:passId,p_request:requestId}});
 }
 async cancelService({bookingId,requestId}){
  if(![bookingId,requestId].every(x=>/^[0-9a-f-]{36}$/i.test(x||'')))throw Error('Cancelación inválida');
  return this.#authorized('rpc/cancel_service_booking',{method:'POST',body:{p_booking:bookingId,p_request:requestId}});
 }
 async memberships(){
  return this.#authorized('organization_memberships?select=organization_id,user_id,role,status');
 }
 async createOrganization({name,slug=null,kind,userId,publicValues={}}){
  const publicData=publicBusinessValues({name,...publicValues});
  const generatedSlug=slug?String(slug).trim():uniqueSlug(publicData.name);
  if(!/^[a-z0-9][a-z0-9-]{2,62}$/.test(generatedSlug)||!allowedKind.has(kind))throw Error('Comprueba nombre y tipo de negocio');
  if(!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId||''))throw Error('Identidad no validada');
  return this.#authorized('organizations?select=id,name,slug,kind',{method:'POST',prefer:'return=representation',
   body:{...publicData,slug:generatedSlug,kind,created_by:userId}});
 }
  async renameOrganization(orgId,name){
  name=String(name||'').trim();
  if(name.length<2||name.length>120||!/^[0-9a-f-]{36}$/i.test(orgId))throw Error('Datos de organización inválidos');
  // SQL permits only UPDATE(name), restricted by owner/admin membership.
  return this.#authorized('organizations?id=eq.'+encodeURIComponent(orgId)+'&select=id,name,slug,kind,avatar_url,tagline',{method:'PATCH',prefer:'return=representation',body:{name}});
 }
 async updateOrganizationBranding({orgId,avatarUrl,tagline,isDiscoverable}){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Negocio inválido');
  // Avatar vía RPC (has_org_role + owner postgres); tagline/discoverable siguen en PATCH.
  let avatarRow=null;
  if(avatarUrl!==undefined){
   avatarRow=await this.#authorized('rpc/update_organization_avatar',{method:'POST',body:{
    p_org:orgId,p_avatar_url:String(avatarUrl||'').trim()||null}});
   if(!avatarRow?.avatar_url&&String(avatarUrl||'').trim())
    throw Error('No se pudo vincular la imagen al perfil del centro');
  }
  const body={};
  if(tagline!==undefined)body.tagline=String(tagline||'').trim()||null;
  if(isDiscoverable!==undefined)body.is_discoverable=!!isDiscoverable;
  if(!Object.keys(body).length)return avatarRow?[avatarRow]:[];
  const rows=await this.#authorized('organizations?id=eq.'+encodeURIComponent(orgId)+'&select=id,avatar_url,tagline,is_discoverable',
   {method:'PATCH',prefer:'return=representation',body});
  if(!rows?.length)throw Error('No se pudo actualizar la identidad del centro');
  return rows;
 }
 async updateProfessionalSession({id,date,title,instructions='',prescription}){
  if(!/^[0-9a-f-]{36}$/i.test(id||''))throw Error('Sesión inválida');
  return this.#authorized('rpc/update_professional_session_v2',{method:'POST',body:{p_session:id,p_day:date,p_title:String(title||'').trim(),p_instructions:instructions,p_prescription:prescription}});
 }
 async cancelProfessionalSession(id){
  if(!/^[0-9a-f-]{36}$/i.test(id||''))throw Error('Entrenamiento inválido');
  const result=await this.#authorized('rpc/cancel_professional_session',{method:'POST',body:{p_session:id}});
  if(result!==true)throw Error('El servidor no ha confirmado la cancelación');
  return true;
 }
 async workoutTemplates(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  return this.#authorized('professional_workout_templates?select=id,org_id,name,description,prescription,created_by,updated_at&org_id=eq.'+encodeURIComponent(orgId)+'&order=updated_at.desc');
 }
 async createWorkoutTemplate({orgId,name,description='',prescription,userId}){
  if(![orgId,userId].every(id=>/^[0-9a-f-]{36}$/i.test(id||''))||String(name||'').trim().length<2)throw Error('Plantilla inválida');
  return this.#authorized('professional_workout_templates?select=id,name,description',{method:'POST',prefer:'return=representation',
    body:{org_id:orgId,created_by:userId,name:String(name).trim().slice(0,120),description:String(description).slice(0,1000),prescription}});
 }
 async updateWorkoutTemplate({id,orgId,name,description='',prescription}){
  if(![id,orgId].every(x=>/^[0-9a-f-]{36}$/i.test(x||'')))throw Error('Plantilla inválida');
  return this.#authorized('professional_workout_templates?id=eq.'+encodeURIComponent(id)+'&org_id=eq.'+encodeURIComponent(orgId),
    {method:'PATCH',prefer:'return=representation',body:{name:String(name||'').trim().slice(0,120),description:String(description).slice(0,1000),prescription,updated_at:new Date().toISOString()}});
 }
 async deleteWorkoutTemplate({id,orgId}){
  if(![id,orgId].every(x=>/^[0-9a-f-]{36}$/i.test(x||'')))throw Error('Plantilla inválida');
  return this.#authorized('professional_workout_templates?id=eq.'+encodeURIComponent(id)+'&org_id=eq.'+encodeURIComponent(orgId),{method:'DELETE'});
 }
 async updateOrganization({orgId,name,publicEmail='',phone='',website='',address='',description='',timezone='Europe/Madrid',publicValues={}}){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Datos del negocio inválidos');
  const body=publicBusinessValues({name,public_email:publicEmail,phone,website,address,description,timezone,...publicValues});
  return this.#authorized('organizations?id=eq.'+encodeURIComponent(orgId)+'&select=id,name,slug,kind,public_email,phone,website,address,description,timezone,whatsapp_e164,whatsapp_connected_at',
    {method:'PATCH',prefer:'return=representation',body});
 }
 async connectOrgWhatsapp({orgId,e164}){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Negocio inválido');
  return this.#authorized('rpc/connect_org_whatsapp',{method:'POST',body:{p_org:orgId,p_e164:String(e164||'')}});
 }
 async disconnectOrgWhatsapp(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Negocio inválido');
  return this.#authorized('rpc/disconnect_org_whatsapp',{method:'POST',body:{p_org:orgId}});
 }
 async legalProfile(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Negocio inválido');
  // Preferir RPC (SECURITY DEFINER) para no depender de grants de tabla en SELECT.
  try{
   const row=await this.#authorized('rpc/get_organization_legal_profile',{method:'POST',body:{p_org:orgId}});
   return row||null;
  }catch(e){
   if(!/Could not find the function|PGRST202|404/i.test(String(e.message||e.code||'')))throw e;
   const rows=await this.#authorized('organization_legal_profiles?select=org_id,entity_type,legal_name,tax_id,representative_name,contact_name,billing_email,billing_address,postal_code,city,province,country&org_id=eq.'+encodeURIComponent(orgId));
   return rows?.[0]||null;
  }
 }
 async upsertLegalProfile(orgId,values){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Negocio inválido');
  const v=legalProfileValues(values);
  return this.#authorized('rpc/upsert_organization_legal_profile',{method:'POST',body:{
   p_org:orgId,
   p_entity_type:v.entity_type,
   p_legal_name:v.legal_name,
   p_tax_id:v.tax_id,
   p_representative_name:v.representative_name,
   p_contact_name:v.contact_name,
   p_billing_email:v.billing_email,
   p_billing_address:v.billing_address,
   p_postal_code:v.postal_code,
   p_city:v.city,
   p_province:v.province,
   p_country:v.country
  }});
 }
 async businessPlans(){
  return this.#authorized('business_plans?select=plan_key,audience,title,description,monthly_price_cents,max_clients,discount_percent,discount_months,is_active,display_order&order=audience.asc,display_order.asc');
 }
 async saveBusinessPlan(v,{newPlan=false}={}){
  const key=String(v.plan_key||'').trim().toLowerCase(),title=String(v.title||'').trim();
  const audience=String(v.audience||''),price=Number(v.price),cents=Math.round(price*100);
  const clients=v.max_clients===''||v.max_clients==null?null:Number(v.max_clients);
  const discount=Number(v.discount_percent||0),months=Number(v.discount_months||0),order=Number(v.display_order||0);
  if(!/^[a-z][a-z0-9_]{2,39}$/.test(key)||title.length<2||title.length>70||!['gym','personal_trainer'].includes(audience)
    ||!Number.isFinite(price)||cents<0||cents>10000000||Math.abs(price*100-cents)>0.001
    ||(clients!==null&&(!Number.isInteger(clients)||clients<1||clients>100000))
    ||!Number.isInteger(discount)||discount<0||discount>90||!Number.isInteger(months)||months<0||months>12
    ||!Number.isInteger(order)||order<-999||order>999)throw Error('Revisa los datos del plan');
  const body={audience,title,description:String(v.description||'').trim().slice(0,250),monthly_price_cents:cents,
   max_clients:clients,discount_percent:discount,discount_months:months,
   is_active:v.is_active!==false&&v.is_active!=='false',display_order:order};
  return this.#authorized(newPlan?'business_plans?select=plan_key':
   'business_plans?plan_key=eq.'+encodeURIComponent(key)+'&select=plan_key',
   {method:newPlan?'POST':'PATCH',prefer:'return=representation',body:newPlan?{plan_key:key,...body}:body});
 }
 async uploadBrandImage({orgId,kind,file}){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Negocio inválido');
  if(!file?.size)return null;
  if(!['image/jpeg','image/png','image/webp'].includes(file.type)||file.size>8*1024*1024)throw Error('Selecciona JPG, PNG o WebP hasta 8 MB.');
  const bitmap=await createImageBitmap(file),scale=Math.min(1,900/Math.max(bitmap.width,bitmap.height));
  const canvas=document.createElement('canvas');
  canvas.width=Math.max(1,Math.round(bitmap.width*scale));canvas.height=Math.max(1,Math.round(bitmap.height*scale));
  canvas.getContext('2d').drawImage(bitmap,0,0,canvas.width,canvas.height);bitmap.close?.();
  const blob=await new Promise(resolve=>canvas.toBlob(resolve,'image/jpeg',0.78));
  if(!blob||blob.size>1048576)throw Error('La foto sigue ocupando demasiado. Usa una imagen más pequeña.');
  const jwt=await this.token();if(!jwt)throw Error('Inicia sesión para subir la imagen');
  const filename=kind==='personal_trainer'?'trainer.jpg':'logo.jpg',objectPath=orgId+'/'+filename;
  const response=await this.fetcher(this.base+'/storage/v1/object/business-branding/'+objectPath,{
   method:'POST',headers:{apikey:this.key,Authorization:'Bearer '+jwt,'Content-Type':'image/jpeg','x-upsert':'true'},
   body:blob});
  if(!response.ok){const problem=await response.json().catch(()=>({}));throw Error(problem.message||problem.error||'No se pudo subir la imagen');}
  // URL estable sin query: el cache-bust lo hacen los clientes; la RPC valida https + longitud.
  const url=this.base+'/storage/v1/object/public/business-branding/'+objectPath;
  const linked=await this.updateOrganizationBranding({orgId,avatarUrl:url+'?v='+Date.now()});
  const saved=linked?.[0]?.avatar_url||url;
  return saved;
 }
  async organizationTrial(orgId){
  return this.#authorized('organization_trials?select=org_id,trial_started_at,trial_ends_at,paid_plan,paid_until&org_id=eq.'+encodeURIComponent(orgId));
 }
 async subscriptionIntent({orgId,planKey,userId}){
  if(!/^[a-z][a-z0-9_]{2,39}$/.test(planKey||''))throw Error('Plan desconocido');
  return this.#authorized('business_subscription_intents',{method:'POST',body:{org_id:orgId,plan_key:planKey,actor:userId}});
 }
 async groupMembers(orgId){
  return this.#authorized('business_training_group_members?select=org_id,group_id,client_id&org_id=eq.'+encodeURIComponent(orgId));
 }
 async updateBusinessGroup({groupId,name,description='',clientIds=[]}){
  return this.#authorized('rpc/manage_business_group',{method:'POST',body:{p_group:groupId,p_name:name,p_description:description,p_clients:clientIds}});
 }
 async groupList(orgId){return this.#authorized('business_training_groups?select=id,org_id,name,description&org_id=eq.'+encodeURIComponent(orgId)+'&order=name.asc');}
 async addGroup({orgId,name,description='',userId}){
  return this.#authorized('business_training_groups?select=id,name',{method:'POST',prefer:'return=representation',body:{org_id:orgId,name,description,created_by:userId}});
 }
 async classDetails(orgId){return this.#authorized('service_occurrence_details?select=occurrence_id,org_id,description,location,image_url,color,repeat_rule,training_title,training_instructions,prescription&org_id=eq.'+encodeURIComponent(orgId));}
 async clientNotifications(orgId){return this.#authorized('business_client_notifications?select=id,org_id,client_id,title,body,created_at&org_id=eq.'+encodeURIComponent(orgId)+'&order=created_at.desc&limit=100');}
 async updateClientProfile({orgId,id,name,email,phone='',notes='',avatar='',status}){
  if(![id,orgId].every(v=>/^[0-9a-f-]{36}$/i.test(v||'')))throw Error('Cliente inválido');
  const allowed=['lead','trial','active','paused','cancelled'];
  if(!allowed.includes(status)||String(name||'').trim().length<2||String(notes).length>2000)throw Error('Ficha inválida');
  return this.#authorized('clients?org_id=eq.'+encodeURIComponent(orgId)+'&id=eq.'+encodeURIComponent(id),
    {method:'PATCH',prefer:'return=representation',body:{name:String(name).trim(),email:String(email).trim().toLowerCase(),phone:phone||null,notes:notes||null,avatar_url:avatar||null,status}});
 }
 async manageOccurrence({id,title,start,end,capacity,description='',location='',color='#22834d',image=''}) {
  return this.#authorized('rpc/manage_service_occurrence',{method:'POST',body:{p_id:id,p_title:title,p_start:new Date(start).toISOString(),p_end:new Date(end).toISOString(),p_capacity:Number(capacity),p_description:description,p_location:location,p_color:color,p_image:image||null}});
 }
 async cancelManagedOccurrence(id){return this.#authorized('rpc/cancel_managed_occurrence',{method:'POST',body:{p_id:id}});}
 async deleteManagedOccurrence(id){return this.#authorized('rpc/delete_managed_occurrence',{method:'POST',body:{p_id:id}});}
 async enrollManagedClient({occurrenceId,clientId,passId,requestId=globalThis.crypto?.randomUUID?.()}){
  return this.#authorized('rpc/enroll_managed_client',{method:'POST',body:{p_occ:occurrenceId,p_client:clientId,p_pass:passId,p_request:requestId}});
 }
 async removeManagedClient(id){return this.#authorized('rpc/remove_managed_client',{method:'POST',body:{p_booking:id}});}
 async sendClientNotice({orgId,clientId,title,body}){
  return this.#authorized('rpc/send_business_client_notice',{method:'POST',body:{p_org:orgId,p_client:clientId,p_title:title,p_body:body}});
 }
 async listThread({orgId,clientId,before=null,limit=50}){
  if(![orgId,clientId].every(id=>/^[0-9a-f-]{36}$/i.test(id||'')))throw Error('Hilo inválido');
  // No enviar p_before=null: PostgREST puede no casar la firma con defaults.
  const body={p_org:orgId,p_client:clientId,p_limit:Math.min(Math.max(Number(limit)||50,1),100)};
  if(before)body.p_before=before;
  try{
   return await this.#authorized('rpc/business_list_thread',{method:'POST',body});
  }catch(e){
   const msg=String(e.message||e);
   if(/schema cache|Could not find the function.*business_list_thread/i.test(msg))
    throw Error('El chat aún no está activo en este centro. Aplica la migración de mensajes o recarga el schema de PostgREST.');
   throw e;
  }
 }
 async sendChatMessage({orgId,clientId,body}){
  if(![orgId,clientId].every(id=>/^[0-9a-f-]{36}$/i.test(id||''))||String(body||'').trim().length<1)
   throw Error('Mensaje inválido');
  return this.#authorized('rpc/business_send_message',{method:'POST',body:{
   p_org:orgId,p_client:clientId,p_body:String(body).trim()}});
 }
 async sendBroadcast({orgId,body,allActive=false,clientIds=null,occurrenceId=null,groupId=null}){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||'')||String(body||'').trim().length<1)throw Error('Aviso inválido');
  return this.#authorized('rpc/business_send_broadcast',{method:'POST',body:{
   p_org:orgId,p_body:String(body).trim(),p_all_active:!!allActive,
   p_client_ids:clientIds,p_occurrence:occurrenceId,p_group:groupId}});
 }
 async markThreadRead({orgId,clientId}){
  return this.#authorized('rpc/business_mark_thread_read',{method:'POST',body:{p_org:orgId,p_client:clientId}});
 }
 async declineInvitation(id){
  if(!/^[0-9a-f-]{36}$/i.test(id||''))throw Error('Invitación inválida');
  return this.#authorized('rpc/decline_org_invitation',{method:'POST',body:{p_invitation_id:id}});
 }
 async effectiveEntitlements(){
  return this.#authorized('rpc/get_my_effective_entitlements',{method:'POST',body:{}});
 }
 async archivedAthleteResults({orgId,clientId}){
  if(![orgId,clientId].every(id=>/^[0-9a-f-]{36}$/i.test(id||'')))throw Error('Cliente histórico inválido');
  // RLS grants ONLY active professional staff read-only access.
  const rows=await this.#authorized(
    'business_athlete_workout_snapshots?select=workout_id,title,started_at,finished_at,payload'
    +'&org_id=eq.'+encodeURIComponent(orgId)
    +'&client_id=eq.'+encodeURIComponent(clientId)
    +'&order=finished_at.desc&limit=100');
  return (rows||[]).map(row=>({
    id:row.workout_id,title:row.title,
    started_at:row.started_at,finished_at:row.finished_at,result:row.payload
  }));
 }
 async sharedClientHistory({orgId,clientId}) {
  return this.sharedAthleteResults({orgId,clientId,limit:100});
 }
 async changeCourtesyCredits(id,action,amount=0,until=null){
  return this.#authorized('rpc/manage_complimentary_pass',{method:'POST',body:{p_pass:id,p_action:action,p_amount:amount||null,p_until:until?new Date(until).toISOString():null}});
 }
 async finalizeServicePass(passId){
  if(!/^[0-9a-f-]{36}$/i.test(passId||''))throw Error('Bono inválido');
  return this.#authorized('rpc/finalize_service_pass',{method:'POST',body:{p_pass:passId}});
 }
 async manageOrgMember({orgId,userId,action,role=null}){
  if(![orgId,userId].every(id=>/^[0-9a-f-]{36}$/i.test(id||'')))throw Error('Miembro inválido');
  if(!['set_role','revoke'].includes(action))throw Error('Acción no válida');
  const body={p_org:orgId,p_user:userId,p_action:action};
  if(action==='set_role')body.p_role=role;
  return this.#authorized('rpc/manage_org_member',{method:'POST',body});
 }
 async deleteBusinessGroup(groupId){
  if(!/^[0-9a-f-]{36}$/i.test(groupId||''))throw Error('Grupo inválido');
  return this.#authorized('rpc/delete_business_group',{method:'POST',body:{p_group:groupId}});
 }
 async publishClassTraining({occurrenceId,title,instructions='',prescription}){
  if(!/^[0-9a-f-]{36}$/i.test(occurrenceId||''))throw Error('Clase inválida');
  return this.#authorized('rpc/publish_class_training',{method:'POST',body:{p_occurrence:occurrenceId,p_title:title,p_instructions:instructions,p_prescription:prescription}});
 }
 /** Mismo entreno a varias clases (máx. 40). Devuelve {occurrences, athletes}. */
 async publishClassTrainingBulk({occurrenceIds,title,instructions='',prescription}){
  const ids=[...new Set((occurrenceIds||[]).filter(id=>/^[0-9a-f-]{36}$/i.test(id)))];
  if(!ids.length)throw Error('Selecciona al menos una clase');
  if(ids.length>40)throw Error('Máximo 40 clases por asignación');
  return this.#authorized('rpc/publish_class_training_bulk',{method:'POST',body:{
   p_occurrences:ids,p_title:title,p_instructions:instructions,p_prescription:prescription,
  }});
 }
 /** Quita la plantilla de la clase y cancela sesiones fan-out aún programadas. */
 async clearClassTraining({occurrenceId}){
  if(!/^[0-9a-f-]{36}$/i.test(occurrenceId||''))throw Error('Clase inválida');
  return this.#authorized('rpc/clear_class_training',{method:'POST',body:{p_occurrence:occurrenceId}});
 }

 async addClassSeries({orgId,coachId=null,kind,title,start,end,capacity,repeat='none',count=1,
  color='#22834d',intervalDays=null,location='',description=''}){
  const coach=/^[0-9a-f-]{36}$/i.test(coachId||'')?coachId:null;
  const body={
   p_org:orgId,p_coach:coach,p_kind:kind,p_title:title,
   p_start:new Date(start).toISOString(),p_end:new Date(end).toISOString(),
   p_capacity:Number(capacity),p_repeat:repeat,p_count:Number(count),
   p_color:color||'#22834d',
  };
  if(intervalDays!=null&&Number(intervalDays)>0)body.p_interval_days=Number(intervalDays);
  if(location)body.p_location=String(location).slice(0,250);
  if(description)body.p_description=String(description).slice(0,2000);
  return this.#authorized('rpc/create_service_series',{method:'POST',body});
 }

}
