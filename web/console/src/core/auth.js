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
 async platformOverview(){
  return this.#authorized('rpc/platform_business_overview',{method:'POST',body:{}});
 }
 async myProfile(){
  const user=await this.currentUser();if(!user?.id)return null;
  const rows=await this.#authorized('profiles?select=id,role,display_name&id=eq.'+encodeURIComponent(user.id));
  return rows?.[0]||null;
 }
 async organizations(){
  return this.#authorized('organizations?select=id,name,slug,kind,public_email,phone,website,address,description,timezone,created_at&order=created_at.desc');
 }
 async clients(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  return this.#authorized('clients?select=id,org_id,user_id,name,email,phone,notes,avatar_url,status,created_at&org_id=eq.'+encodeURIComponent(orgId)+'&order=created_at.desc');
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
  return this.#authorized('professional_training_sessions?select=id,org_id,client_id,coach_user_id,scheduled_date,title,instructions,prescription,status&org_id=eq.'+orgId+'&order=scheduled_date.asc&limit=200');
 }
 async publishProfessionalSession({orgId,clientId,date,title,instructions='',prescription,requestId=globalThis.crypto?.randomUUID?.()}){
  title=String(title||'').trim();instructions=String(instructions||'');
  if(![orgId,clientId,requestId].every(id=>/^[0-9a-f-]{36}$/i.test(id||''))||title.length<2
    ||title.length>120||instructions.length>10000||!/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/.test(date||''))
      throw Error('Planificación inválida');
  return this.#authorized('rpc/publish_professional_session_v2',{method:'POST',body:{p_org:orgId,p_client:clientId,p_day:date,p_title:title,p_instructions:instructions,p_request:requestId,p_prescription:prescription}});
 }
 async assignCoachClient({orgId,clientId,coachId}){
  if(![orgId,clientId,coachId].every(id=>/^[0-9a-f-]{36}$/i.test(id||'')))throw Error('Asignación inválida');
  return this.#authorized('rpc/assign_coach_client',{method:'POST',body:{p_org:orgId,p_client:clientId,p_coach:coachId}});
 }
 async serviceOccurrences(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  return this.#authorized('service_occurrences?select=id,org_id,kind,title,starts_at,ends_at,capacity,status,coach_user_id&org_id=eq.'+orgId+'&order=starts_at.asc&limit=100');
 }
 async servicePasses(orgId){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||''))throw Error('Organización inválida');
  return this.#authorized('service_passes?select=id,org_id,client_id,kind,total_credits,remaining_credits,valid_from,valid_until,status,issuance_type&org_id=eq.'+orgId+'&order=created_at.desc');
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
 async updateProfessionalSession({id,date,title,instructions='',prescription}){
  if(!/^[0-9a-f-]{36}$/i.test(id||''))throw Error('Sesión inválida');
  return this.#authorized('rpc/update_professional_session_v2',{method:'POST',body:{p_session:id,p_day:date,p_title:String(title||'').trim(),p_instructions:instructions,p_prescription:prescription}});
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
 async updateOrganization({orgId,name,publicEmail='',phone='',website='',address='',description='',timezone='Europe/Madrid'}){
  if(!/^[0-9a-f-]{36}$/i.test(orgId||'')||String(name||'').trim().length<2)throw Error('Datos del negocio inválidos');
  const body={name:String(name).trim().slice(0,120),public_email:String(publicEmail).trim().slice(0,180)||null,
    phone:String(phone).trim().slice(0,40)||null,website:String(website).trim().slice(0,255)||null,
    address:String(address).trim().slice(0,300)||null,description:String(description).trim().slice(0,2000)||null,
    timezone:String(timezone).trim().slice(0,80)||'Europe/Madrid'};
  return this.#authorized('organizations?id=eq.'+encodeURIComponent(orgId)+'&select=id,name,slug,kind,public_email,phone,website,address,description,timezone',
    {method:'PATCH',prefer:'return=representation',body});
 }

 async organizationTrial(orgId){
  return this.#authorized('organization_trials?select=org_id,trial_started_at,trial_ends_at,paid_plan,paid_until&org_id=eq.'+encodeURIComponent(orgId));
 }
 async subscriptionIntent({orgId,planKey,userId}){
  const valid=['trainer_5','trainer_50','trainer_75','gym_basic','gym_advanced','gym_expert'];
  if(!valid.includes(planKey))throw Error('Plan desconocido');
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
 async classDetails(orgId){return this.#authorized('service_occurrence_details?select=occurrence_id,org_id,description,location,image_url,color,repeat_rule&org_id=eq.'+encodeURIComponent(orgId));}
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
 async enrollManagedClient({occurrenceId,clientId,passId,requestId=globalThis.crypto?.randomUUID?.()}){
  return this.#authorized('rpc/enroll_managed_client',{method:'POST',body:{p_occ:occurrenceId,p_client:clientId,p_pass:passId,p_request:requestId}});
 }
 async removeManagedClient(id){return this.#authorized('rpc/remove_managed_client',{method:'POST',body:{p_booking:id}});}
 async sendClientNotice({orgId,clientId,title,body}){
  return this.#authorized('rpc/send_business_client_notice',{method:'POST',body:{p_org:orgId,p_client:clientId,p_title:title,p_body:body}});
 }
 async sharedClientHistory({orgId,clientId}) {
  return this.sharedAthleteResults({orgId,clientId,limit:100});
 }
 async changeCourtesyCredits(id,action,amount=0,until=null){
  return this.#authorized('rpc/manage_complimentary_pass',{method:'POST',body:{p_pass:id,p_action:action,p_amount:amount||null,p_until:until?new Date(until).toISOString():null}});
 }
 async publishClassTraining({occurrenceId,title,instructions='',prescription}){
  if(!/^[0-9a-f-]{36}$/i.test(occurrenceId||''))throw Error('Clase inválida');
  return this.#authorized('rpc/publish_class_training',{method:'POST',body:{p_occurrence:occurrenceId,p_title:title,p_instructions:instructions,p_prescription:prescription}});
 }

 async addClassSeries({orgId,coachId,kind,title,start,end,capacity,repeat='none',count=1}){
  return this.#authorized('rpc/create_service_series',{method:'POST',body:{p_org:orgId,p_coach:coachId,p_kind:kind,p_title:title,p_start:new Date(start).toISOString(),p_end:new Date(end).toISOString(),p_capacity:Number(capacity),p_repeat:repeat,p_count:Number(count)}});
 }

}
