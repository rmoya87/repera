import {SUPABASE_URL,SUPABASE_PUBLISHABLE_KEY} from '../core/config.js';
import {ReperaAuthAPI} from '../core/auth.js';
import {slugFromName,uniqueSlug,visiblePlans,priceLabel} from '../core/business-profile.js';
import {renderPlanOptions,renderOrganizationFields,renderOrganizationCreateForm,renderPlanAdministration} from './business-onboarding.js';
import {renderServicesPanel} from './connected-services.js';
import {renderProfessionalPlanning} from './connected-planning.js';
import {navIcon} from './nav-icons.js';
import {renderPlatformAdmin,paymentCSV} from './platform-admin.js';
import {renderBusinessHome,renderClient360,renderClasses360} from './management-360.js';
import {handleEditorClick,handleEditorSearch,readPrescription,validatePrescription,canonicalPrescription} from './workout-editor.js';
const app=document.querySelector('#app');
const auth=new ReperaAuthAPI({baseUrl:SUPABASE_URL,publishableKey:SUPABASE_PUBLISHABLE_KEY});
const escapeHTML=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let adminTab='home',adminSelectedOrg='',delegation=null,adminDirectory=[],adminAthletes=[],adminSettings={},
adminAccount={},adminEditPlan='',adminFinances={payments:[],intents:[]},adminPending=[],adminHistory=[],
adminSelectedAthlete='',adminCenterDetail=null,adminAthleteDetail=null,adminAthleteWorkouts=[],
adminActivityMonth='',adminActivityDays=[],adminActivityDay='',adminActivityWorkouts=null,adminActivityLoading=false,
adminNavCollapsed=(()=>{try{return localStorage.getItem('repera.admin.nav.collapsed')==='1';}catch{return false;}})();
let adminFilter={search:'',kind:'all',athleteSearch:'',status:'all',org:'all',paymentStatus:'all',paymentScope:'b2b',dateFrom:'',dateTo:''};
let user=null,platformRole=null,platformOrgs=[],organizations=[],memberships=[],invitations=[],clients=[],occurrences=[],passes=[],bookings=[],professionalSessions=[],templates=[],selectedOrg=null,trialRows=[],classDetails=[],groups=[],groupMembers=[],notices=[],enrollmentRequests=[],sharedHistory=[],selectedClientId=null,selectedClassId=null,selectedGroupId=null,classMode='calendar',calendarMonth='',classEditorId=null,planningClientId=null,activeTab='overview',selectedTemplateId=null,editingSessionId=null,legalProfile=null,planCatalog=[],view='login',busy=false,error='',notice='';
const kindLabel={gym:'Gimnasio',personal_trainer:'Entrenador personal',sports_center:'Gimnasio'};
const roleLabel={owner:'Propietario',admin:'Administrador',coach:'Entrenador',reception:'Recepción',athlete:'Deportista'};
const message=()=>`${error?`<p class="connected-error" role="alert">${escapeHTML(error)}</p>`:''}${notice?`<p class="connected-notice" role="status">${escapeHTML(notice)}</p>`:''}`;
const field=(label,name,type='text',extra='')=>`<label class="connected-field">${label}<input name="${name}" type="${type}" autocomplete="${name==='email'?'email':name==='password'?'current-password':'off'}" required ${extra}></label>`;
const redirectTo=()=>location.origin+location.pathname;

function trialStatus(){
 const rec=trialRows[0];if(!rec)return {active:false,days:0};
 const ms=new Date(rec.trial_ends_at)-Date.now();
 const paid=rec.paid_plan&&rec.paid_until&&new Date(rec.paid_until)>new Date();
 return {active:paid||ms>0,paid,days:Math.max(0,Math.ceil(ms/86400000)),rec};
}
function renderSubscriptions(org){
 const state=trialStatus(),trial=state.rec;
 const head=state.paid?`Plan ${escapeHTML(trial.paid_plan)} activo`:state.active?`Prueba gratuita · ${state.days} días restantes`:'Prueba finalizada · elige un plan';
 const rows=visiblePlans(planCatalog,org.kind).map(p=>`<article class="business-price"><h3>${escapeHTML(p.title)}</h3><strong>${escapeHTML(priceLabel(p.monthly_price_cents))}<small> / mes + IVA</small></strong><p>${escapeHTML(p.description||'')}${p.max_clients?` · Hasta ${p.max_clients} clientes`:' · Sin límite de clientes'}</p>${p.discount_percent&&p.discount_months?`<p>Promoción: ${p.discount_percent}% durante ${p.discount_months} meses.</p>`:''}<button type="button" class="connected-secondary" data-action="choose-plan" data-plan="${escapeHTML(p.plan_key)}">Seleccionar</button></article>`).join('');
 return `<section class="connected-card business-subscriptions"><span class="connected-tag">SUSCRIPCIÓN</span><h2>${head}</h2><p>Catálogo configurable por administración, precios sin IVA. Seleccionar solo registra el interés: no se cobra nada ni se activa el plan hasta integrar la pasarela de pago.</p><div class="business-prices">${rows||'<p>No hay planes publicados para esta actividad.</p>'}</div></section>`;
}
function enhanceWorkspace(own){
 const root=app.querySelector('.connected-workspace');if(!root)return;
 root.querySelector('.connected-next')?.remove();
 const org=organizations.find(o=>o.id===selectedOrg);
 const kind=org?.kind,trainer=kind==='personal_trainer',manager=['owner','admin'].includes(own.get(selectedOrg));
 const visibleOrganizations=delegation?organizations.filter(x=>x.id===delegation.org_id):organizations;
 const tabs=org?[['overview','Inicio','dashboard'],['clients','Clientes','clients'],['planning','Entrenamientos','planning'],['services',trainer?'Citas y reservas':'Clases y reservas','calendar'],['bonos','Bonos y tarifas','products'],['billing','Facturación','billing'],['analytics','Analíticas','analytics'],...(trainer?[]:[['team','Equipo y espacios','team']]),['settings','Configuración','settings'],...(platformRole==='platform_admin'&&!delegation?[['platform','Administración Repera','admin']]:[])]:[['overview','Inicio','dashboard'],...(platformRole==='platform_admin'?[['platform','Administración Repera','admin']]:[])];
 if(!tabs.some(t=>t[0]===activeTab))activeTab='overview';
 const nav=document.createElement('nav');nav.className='business-navigation';nav.setAttribute('aria-label','Menú profesional');
 nav.innerHTML=tabs.map(([id,label,icon])=>`<button type="button" data-workspace="${id}" aria-current="${activeTab===id?'page':'false'}">${navIcon(icon)}${escapeHTML(label)}</button>`).join('');
 const picker=document.createElement('label');picker.className='connected-field';picker.style.cssText='margin-left:auto;min-width:160px;max-width:240px';
 picker.innerHTML=`<span class="sr-only">Organización activa</span><select id="workspace-org-select"><option value="">Selecciona un negocio</option>${visibleOrganizations.map(o=>`<option value="${escapeHTML(o.id)}" ${o.id===selectedOrg?'selected':''}>${escapeHTML(o.name)}</option>`).join('')}</select>`;
 nav.append(picker);
 root.querySelector('.connected-heading')?.insertAdjacentElement('afterend',nav);
 if(!org){
  if(platformRole==='platform_admin'){
   const sec=document.createElement('section');sec.dataset.workspaceSection='platform';sec.className='connected-card';
   sec.innerHTML=`<h2>Administración Repera</h2><p>Consulta de negocios, sin acceso a historial privado.</p>${platformOrgs.map(o=>`<article class="connected-org"><strong>${escapeHTML(o.name)}</strong><small>${escapeHTML(o.kind)} · ${Number(o.client_count||0)} clientes</small></article>`).join('')||'<p>Sin organizaciones registradas.</p>'}`;
   sec.insertAdjacentHTML('beforeend',renderPlanAdministration(planCatalog));root.append(sec);root.querySelectorAll('[data-workspace-section]').forEach(el=>el.style.display=el.dataset.workspaceSection===activeTab?'':'none');
  }
  return;
 }
 root.querySelector('.connected-heading h1').textContent=org.name;
 // El panel legado no se utiliza como ficha ni agenda de operaciones.
 root.querySelector('.connected-grid')?.remove();
 root.querySelector('[data-workspace-section="clients"]')?.remove();
 root.querySelector('[data-workspace-section="services"]')?.remove();
 const attach=(tab,html)=>{const node=document.createElement('div');node.dataset.workspaceSection=tab;node.innerHTML=html;root.append(node);};
 attach('overview',renderBusinessHome({org,clients,occurrences,bookings,sessions:professionalSessions,templates,requests:enrollmentRequests,manager}));
 attach('clients',renderClient360({clients,selected:selectedClientId,passes,bookings,occurrences,sessions:professionalSessions,notices,sharedHistory,manager,role:own.get(selectedOrg)}));
 const members=memberships.filter(m=>m.organization_id===org.id&&m.status==='active'&&['owner','admin','coach'].includes(m.role)).map(m=>({user_id:m.user_id,label:m.user_id===user.id?'Mi cuenta':'Profesional '+m.user_id.slice(0,8)}));
 // A pre-registration center has no real owner/staff yet. The real actor can operate
 // its workspace as Repera support; we never label this account as the future trainer.
 if(delegation&&!members.some(m=>m.user_id===user.id))members.unshift({user_id:user.id,label:'Administrador Repera · soporte'});
 attach('services',renderClasses360({occurrences,clients,bookings,passes,details:classDetails,groups,groupMembers,selectedGroup:selectedGroupId,coaches:members,selected:selectedClassId,classEditor:classEditorId===selectedClassId,listMode:classMode,calendarMonth,manager}));
 attach('bonos',`<section class="connected-card"><h2>Bonos y tarifas</h2><p>Bonos reales de cortesía y saldos verificados en Supabase. Los cobros y renovaciones de pago siguen pendientes de integración.</p>${passes.map(p=>`<article class="connected-org"><strong>${escapeHTML(clients.find(c=>c.id===p.client_id)?.name||'Cliente')} · ${p.kind==='class'?'Clase':'Cita'}</strong><small>${p.remaining_credits} de ${p.total_credits} disponibles</small></article>`).join('')||'<p>No hay bonos todavía.</p>'}</section>`);
 attach('billing',`<section class="connected-card"><h2>Facturación</h2><p>La pasarela de pago y la facturación legal todavía no están habilitadas. No se muestran cobros simulados como reales.</p></section>`);
 attach('platform',`<section class="connected-card"><h2>Administración Repera</h2><p>Resumen de organizaciones de la plataforma. No permite acceder al historial privado de los deportistas ni suplantar cuentas.</p><div class="table-scroll"><table><thead><tr><th>Organización</th><th>Tipo</th><th>Clientes</th><th>Prueba finaliza</th></tr></thead><tbody>${platformOrgs.map(o=>`<tr><td>${escapeHTML(o.name)}</td><td>${escapeHTML(o.kind)}</td><td>${Number(o.client_count||0)}</td><td>${escapeHTML(o.trial_ends_at?.slice(0,10)||'—')}</td></tr>`).join('')||'<tr><td colspan="4">No hay organizaciones</td></tr>'}</tbody></table></div></section>${platformRole==='platform_admin'?renderPlanAdministration(planCatalog):''}`);
 attach('analytics',`<section class="connected-card"><h2>Analíticas del negocio</h2><div class="business-stats"><div class="business-stat"><span>Clientes</span><strong>${clients.length}</strong></div><div class="business-stat"><span>Reservas activas</span><strong>${bookings.filter(b=>b.status==='booked').length}</strong></div><div class="business-stat"><span>Sesiones programadas</span><strong>${occurrences.filter(o=>o.status==='active').length}</strong></div></div><p>Las métricas deportivas personales solo estarán disponibles con consentimiento y sincronización del atleta.</p></section>`);
 const settings=document.createElement('section');settings.className='connected-card connected-settings';settings.dataset.workspaceSection='settings';
 settings.innerHTML=`<span class="connected-tag">DATOS DEL ${trainer?'PROFESIONAL':'NEGOCIO'}</span><h2>Configuración de ${escapeHTML(org.name)}</h2><p>Completa tu perfil. Los datos fiscales quedan restringidos a propietarios y administradores.</p><form data-connected="settings" class="business-onboarding-form">${renderOrganizationFields({kind,values:org,legal:legalProfile||{}}).replace('<select name="kind">','<select name="kind" disabled>')}<label class="connected-field">Zona horaria<input name="timezone" value="${escapeHTML(org.timezone||'Europe/Madrid')}" maxlength="80"></label>${manager?'<button class="connected-primary business-form-submit" type="submit">Guardar datos del negocio</button>':''}</form>`;
 root.append(settings);
 attach('settings',renderSubscriptions(org));
 // Entrenador y gimnasio disponen de permisos diferentes.
 if(trainer)root.querySelector('[data-workspace-section="team"]')?.remove();
 const trial=trialStatus();
 if(!trial.active&&!delegation&&activeTab!=='settings'){
  const notice=document.createElement('div');notice.className='connected-error';notice.innerHTML='<strong>Prueba finalizada.</strong> Para seguir administrando el negocio, elige un plan en Configuración. Los pagos todavía no están disponibles.';
  nav.insertAdjacentElement('afterend',notice);
 }
 root.querySelectorAll('[data-workspace-section]').forEach(el=>{el.style.display=el.dataset.workspaceSection===activeTab?'':'none';});
}function render(){
 if(user&&platformRole==='platform_admin'&&!delegation&&view!=='password'){
  app.innerHTML=renderPlatformAdmin({tab:adminTab,orgs:adminDirectory,athletes:adminAthletes,finance:adminFinances,
   pending:adminPending,history:adminHistory,plans:planCatalog,selectedOrg:adminSelectedOrg,
   selectedAthlete:adminSelectedAthlete,centerDetail:adminCenterDetail,
   athleteData:adminAthleteDetail,athleteWorkouts:adminAthleteWorkouts,collapsed:adminNavCollapsed,
   activityMonth:adminActivityMonth,activityDays:adminActivityDays,
   activityDay:adminActivityDay,activityDayWorkouts:adminActivityWorkouts,activityLoading:adminActivityLoading,
   settings:adminSettings,account:adminAccount,editingPlan:adminEditPlan,
   filter:adminFilter,busy,error,notice,email:user.email||''});
  return;
 }
 const common=platformRole==='platform_admin'&&delegation?'':`<header class="connected-header"><div class="brand"><span class="brand-symbol">R</span><span><strong>repera</strong><small>Business</small></span></div></header>`;
 if(!user){
  const title={login:'Accede a tu negocio',register:'Crear cuenta profesional',recover:'Recuperar acceso',password:'Establecer nueva contraseña'}[view];
  const form=view==='login'
   ?`${field('Correo electrónico','email','email')}${field('Contraseña','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Entrar</button>`
   :view==='register'
   ?`${field('Correo electrónico','email','email')}${field('Contraseña (8 caracteres mínimo)','password','password','minlength="8"')}<label class="connected-field">Tipo de actividad<select name="businessKind" required><option value="personal_trainer">Entrenador personal</option><option value="gym">Gimnasio</option></select></label>${field('Nombre comercial','businessName','text','minlength="2" maxlength="120"')}<p class="connected-hint">7 días de prueba gratuitos. No se pide tarjeta. Tras la prueba podrás elegir un plan; los pagos todavía no están habilitados.</p><button class="connected-primary" type="submit" ${busy?'disabled':''}>Registrarme y empezar prueba</button>`
   :view==='recover'
   ?`${field('Correo electrónico','email','email')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Enviar enlace</button>`
   :`${field('Nueva contraseña (8 caracteres mínimo)','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Actualizar contraseña</button>`;
  app.innerHTML=`<div class="connected-page">${common}<main class="connected-auth"><div class="connected-card"><span class="connected-tag">PLATAFORMA PROFESIONAL</span><h1>${title}</h1><p class="connected-intro">Gestión real de organizaciones mediante Supabase. Tus entrenamientos personales permanecen en la app nativa.</p>${message()}<form data-connected="${view}">${form}</form><div class="connected-links">${view!=='login'?'<button type="button" data-view="login">Volver a iniciar sesión</button>':''}${view==='login'?'<button type="button" data-view="register">Crear cuenta</button><button type="button" data-view="recover">Olvidé mi contraseña</button>':''}</div></div></main></div>`;
  return;
 }
 const pendingInvites=invitations.filter(i=>!i.accepted_at&&!i.cancelled_at&&new Date(i.expires_at).getTime()>Date.now());
 const ownInvites=pendingInvites.filter(i=>i.email===(user.email||'').trim().toLowerCase());
 const own=new Map(memberships.filter(m=>m.user_id===user.id&&m.status==='active').map(m=>[m.organization_id,m.role]));
 if(delegation)own.set(delegation.org_id,'admin');
 app.innerHTML=`<div class="connected-page">${common}<main class="connected-workspace"><div class="connected-heading"><div><span class="connected-tag">SESIÓN AUTENTICADA · SUPABASE REPERA</span><h1>Mis organizaciones</h1><p>${escapeHTML(user.email||'Cuenta Repera')} · ${platformRole==='platform_admin'?'Administrador de plataforma · ':''}Solo se muestran negocios autorizados por la base de datos.</p></div><button class="connected-secondary" data-action="logout" ${busy?'disabled':''}>Cerrar sesión</button></div>${message()}${ownInvites.length?`<section class="connected-card" style="margin-bottom:22px"><h2>Invitaciones para ti</h2><p>Solo se vinculará tu cuenta con el profesional al aceptarla. No se compartirán tus datos privados de entrenamientos.</p>${ownInvites.map(i=>`<article class="connected-org"><div><strong>Organización ${escapeHTML(i.organization_id.slice(0,8))}</strong><small>Invitación para ${escapeHTML(roleLabel[i.invited_role]||i.invited_role)} · vence ${escapeHTML(i.expires_at.slice(0,10))}</small></div><button class="connected-primary" data-action="accept-invitation" data-id="${escapeHTML(i.id)}" ${busy?'disabled':''}>Aceptar</button></article>`).join('')}</section>`:''}<section data-workspace-section="overview" class="connected-grid connected-onboarding-grid"><div class="connected-card"><h2>Espacios de trabajo</h2>${organizations.length?organizations.map(o=>`<article class="connected-org"><div><strong>${escapeHTML(o.name)}</strong><small>${escapeHTML(kindLabel[o.kind]||o.kind)} · ${escapeHTML(roleLabel[own.get(o.id)]||'Miembro')}</small><code>${escapeHTML(o.slug)}</code></div>${['owner','admin'].includes(own.get(o.id))?`<div class="connected-org-brand">${o.avatar_url?`<img class="connected-org-avatar" src="${escapeHTML(o.avatar_url)}" alt="" loading="lazy">`:`<span class="connected-org-avatar placeholder">${escapeHTML((o.name||'R').slice(0,1).toUpperCase())}</span>`}<form data-connected="rename" class="connected-inline"><input type="hidden" name="id" value="${escapeHTML(o.id)}"><label>Nombre<input name="name" value="${escapeHTML(o.name)}" maxlength="120" required></label><label>${o.kind==='personal_trainer'?'Foto del entrenador':'Logotipo del gimnasio'}<input name="avatarFile" type="file" accept="image/jpeg,image/png,image/webp"></label><label>Eslogan<input name="tagline" value="${escapeHTML(o.tagline||'')}" maxlength="160"></label><label class="connected-check"><input type="checkbox" name="discoverable" ${o.is_discoverable!==false?'checked':''}> Visible para deportistas</label><button class="connected-secondary" ${busy?'disabled':''}>Guardar</button></form></div>`:''}</article>`).join(''):'<p class="connected-empty">Todavía no perteneces a ninguna organización. Crea tu primera empresa para comenzar.</p>'}</div><div class="connected-card">${renderOrganizationCreateForm(planCatalog,(()=>{try{return JSON.parse(sessionStorage.getItem(PENDING_REGISTRATION_KEY)||'null')||{};}catch{return {};}})())}</div></section><section class="connected-card" data-workspace-section="clients" style="margin-top:22px"><h2>Clientes reales</h2><label class="connected-field">Organización<select id="connected-org-select"><option value="">Selecciona una organización</option>${organizations.map(o=>`<option value="${escapeHTML(o.id)}" ${selectedOrg===o.id?'selected':''}>${escapeHTML(o.name)}</option>`).join('')}</select></label>${selectedOrg?`<div style="margin-top:20px">${clients.length?clients.map(c=>`<article class="connected-org"><div><strong>${escapeHTML(c.name)}</strong><small>${escapeHTML(c.email)} · ${escapeHTML(c.status)}</small></div></article>`).join(''):'<p>Sin clientes registrados en esta organización.</p>'}${['owner','admin'].includes(own.get(selectedOrg))?`<form data-connected="client">${field('Nombre del cliente','name','text','minlength="2" maxlength="120"')}${field('Correo electrónico','email','email')}<button class="connected-primary">Añadir cliente potencial</button></form>`:''}</div>`:''}</section>${selectedOrg&&["owner","admin"].includes(own.get(selectedOrg))?`<section class="connected-card" data-workspace-section="team" style="margin-top:22px"><h2>Invitar a mi organización</h2><p>La persona debe registrarse con el mismo correo verificado. Podrá aceptar la invitación al iniciar sesión. Aún no se envían correos automáticos.</p><form data-connected="invite">${field('Correo del invitado','email','email')}<label class="connected-field">Perfil<select name="role"><option value="athlete">Deportista</option><option value="coach">Entrenador</option><option value="reception">Recepción</option><option value="admin">Administrador</option></select></label><button class="connected-primary" ${busy?'disabled':''}>Crear invitación</button></form>${pendingInvites.filter(i=>i.organization_id===selectedOrg).length?`<p>Invitaciones pendientes: ${pendingInvites.filter(i=>i.organization_id===selectedOrg).length}</p>`:''}</section>`:''}${renderProfessionalPlanning({orgId:selectedOrg,role:own.get(selectedOrg),sessions:professionalSessions,templates,clients,memberships,busy,escapeHTML,templateId:selectedTemplateId,sessionId:editingSessionId,clientId:planningClientId})}<div data-workspace-section="services">${renderServicesPanel({selectedOrg,role:own.get(selectedOrg),occurrences,passes,bookings,clients,memberships,busy,escapeHTML})}</div><section class="connected-next"><h2>Próximos módulos</h2><p>Asignación operativa de entrenadores, planes publicados, compra de bonos y reservas desde las apps móviles aún no están conectados. No se muestran datos ficticios en este espacio autenticado.</p></section></main></div>`;
 enhanceWorkspace(own);
 if(delegation){
  const pendingCenter=adminDirectory.find(o=>o.id===delegation.org_id&&o.registration_status==='pending');
  const hdr=app.querySelector('.connected-heading');
  hdr?.insertAdjacentHTML('afterend',`<div class="pa-delegation-banner" role="status"><span>Gestionando <strong>${escapeHTML(delegation.name)}</strong> como administrador de Repera${pendingCenter?' · Pendiente de registro del propietario':''}. Acceso temporal hasta ${escapeHTML(new Date(delegation.expires_at).toLocaleTimeString('es-ES',{hour:'2-digit',minute:'2-digit'}))}. No usas la cuenta del propietario.</span><button type="button" class="pa-button" data-admin-action="exit-delegation">Volver a Repera Admin</button></div>`);
 }
}
const PENDING_REGISTRATION_KEY='repera-business-pending-professional-v1';
// El slug se genera desde el nombre comercial.
async function finalizePendingRegistration(){
 const raw=sessionStorage.getItem(PENDING_REGISTRATION_KEY);if(!raw||!user)return;
 if(organizations.length){sessionStorage.removeItem(PENDING_REGISTRATION_KEY);return;}
 try{
  const pending=JSON.parse(raw);
  if(pending?.email===String(user.email||'').toLowerCase())
   notice='Completa los datos de tu negocio, añade tu imagen y escoge un plan opcional para comenzar.';
 }catch{sessionStorage.removeItem(PENDING_REGISTRATION_KEY);}
}
async function loadSelectedOrg(){
 if(!selectedOrg){clients=[];occurrences=[];passes=[];bookings=[];professionalSessions=[];templates=[];trialRows=[];classDetails=[];groups=[];groupMembers=[];notices=[];enrollmentRequests=[];legalProfile=null;return;}
 [clients,occurrences,passes,bookings,professionalSessions,templates,trialRows,classDetails,groups,groupMembers,notices]=await Promise.all([
 auth.clients(selectedOrg),auth.serviceOccurrences(selectedOrg),auth.servicePasses(selectedOrg),
 auth.serviceBookings(selectedOrg),auth.professionalSessions(selectedOrg),auth.workoutTemplates(selectedOrg),
 auth.organizationTrial(selectedOrg),auth.classDetails(selectedOrg),auth.groupList(selectedOrg),auth.groupMembers(selectedOrg),auth.clientNotifications(selectedOrg)]);
 legalProfile=await auth.legalProfile(selectedOrg);
 const role=delegation?'admin':memberships.find(m=>m.organization_id===selectedOrg&&m.user_id===user?.id&&m.status==='active')?.role;
 enrollmentRequests=['owner','admin'].includes(role)?
  await auth.enrollmentRequests(selectedOrg):[];
}
async function reload(){
 // The platform role must be resolved independently of tenant membership RLS.
 // A broken business query must never hide the administrator's global console.
 const profile=await auth.myProfile();
 platformRole=profile?.role||null;
 adminAccount={...(profile||{}),avatar_url:profile?.avatar_url||user?.user_metadata?.avatar_url||null,
  display_name:profile?.display_name||user?.user_metadata?.name||''};
 planCatalog=await auth.businessPlans();
 if(platformRole==='platform_admin'){
  [delegation,adminDirectory,adminAthletes,adminFinances,adminPending,adminHistory,adminSettings]=await Promise.all([
   auth.platformAdminCurrentDelegation(),auth.platformAdminDirectory(),auth.platformAdminAthletes(),
   auth.platformAdminFinances(),auth.platformAdminPending(),auth.platformAdminHistory(),
   auth.platformAdminSettings()]);
  platformOrgs=[];
  if(!delegation){
   organizations=[];memberships=[];invitations=[];selectedOrg=null;
   await loadSelectedOrg();return;
  }
 }else{
  delegation=null;
  // Only the verified owner claims a prepared business, never a platform operator.
  await auth.claimPlatformProvisioning();
  adminDirectory=[];adminAthletes=[];adminSettings={};adminFinances={payments:[],client_payments:[],intents:[]};
  adminPending=[];adminHistory=[];platformOrgs=[];
 }
 const [orgs,members,invites]=await Promise.all([
  auth.organizations(),auth.memberships(),auth.invitations()]);
 organizations=orgs||[];memberships=members||[];invitations=invites||[];
 if(delegation)selectedOrg=delegation.org_id;
 else if(!organizations.some(o=>o.id===selectedOrg))selectedOrg=organizations[0]?.id||null;
 await loadSelectedOrg();
}
app.addEventListener('click',async event=>{
 const platformTab=event.target.closest('[data-admin-tab]');
 if(platformTab){adminTab=platformTab.dataset.adminTab;adminSelectedOrg='';adminSelectedAthlete='';
  adminCenterDetail=null;adminAthleteDetail=null;adminAthleteWorkouts=[];
  adminActivityDays=[];adminActivityDay='';adminActivityWorkouts=null;
  error=notice='';render();return;}
 const platformButton=event.target.closest('[data-admin-action]');
 if(platformButton){
  const command=platformButton.dataset.adminAction;
  if(command==='toggle-sidebar'){
   adminNavCollapsed=!adminNavCollapsed;
   try{localStorage.setItem('repera.admin.nav.collapsed',adminNavCollapsed?'1':'0');}catch{}
   render();return;
  }
  if(command==='view-org'){
   adminSelectedOrg=platformButton.dataset.id;adminSelectedAthlete='';adminAthleteDetail=null;
   adminAthleteWorkouts=[];adminCenterDetail=null;adminTab='centers';error=notice='';render();
   try{adminCenterDetail=await auth.platformAdminCenterDetail(adminSelectedOrg);}
   catch(e){error=e.message||'No se pudieron cargar los datos del centro';}
   render();return;
  }
  if(command==='back-org'){adminSelectedOrg='';adminCenterDetail=null;render();return;}
  if(command==='view-athlete'){
   adminSelectedAthlete=platformButton.dataset.id;adminSelectedOrg='';adminCenterDetail=null;
   adminAthleteDetail=null;adminAthleteWorkouts=[];adminActivityDays=[];
   adminActivityDay='';adminActivityWorkouts=null;adminTab='athletes';error=notice='';render();
   try{
    [adminAthleteDetail,adminAthleteWorkouts]=await Promise.all([
     auth.platformAdminAthleteDetail(adminSelectedAthlete),
     auth.platformAdminAthleteWorkouts(adminSelectedAthlete,0,30)]);
    const recent=adminAthleteWorkouts[0]?.started_at;
    adminActivityMonth=recent?new Date(recent).toLocaleDateString('sv-SE',{timeZone:'Europe/Madrid'}).slice(0,7):
     new Date().toLocaleDateString('sv-SE',{timeZone:'Europe/Madrid'}).slice(0,7);
    adminActivityDays=await auth.platformAdminAthleteActivity(adminSelectedAthlete,adminActivityMonth);
    adminActivityDay=adminActivityDays.at(-1)?.day||'';
    adminActivityWorkouts=adminActivityDay?
     await auth.platformAdminAthleteDay(adminSelectedAthlete,adminActivityDay):[];
   }catch(e){error=e.message||'No se pudo cargar la ficha del atleta';}
   render();return;
  }
  if(command==='athlete-month'&&!busy&&adminSelectedAthlete){
   const step=Number(platformButton.dataset.step)||0;
   if(Math.abs(step)!==1)return;
   const [y,m]=(adminActivityMonth||new Date().toISOString().slice(0,7)).split('-').map(Number);
   adminActivityMonth=new Date(Date.UTC(y,m-1+step,1)).toISOString().slice(0,7);
   adminActivityDay='';adminActivityWorkouts=null;adminActivityDays=[];adminActivityLoading=true;render();
   try{
    adminActivityDays=await auth.platformAdminAthleteActivity(adminSelectedAthlete,adminActivityMonth);
    adminActivityDay=adminActivityDays.at(-1)?.day||'';
    adminActivityWorkouts=adminActivityDay?
     await auth.platformAdminAthleteDay(adminSelectedAthlete,adminActivityDay):[];
   }catch(e){error=e.message||'No se pudo consultar el mes seleccionado';adminActivityWorkouts=[];}
   finally{adminActivityLoading=false;render();}
   return;
  }
  if(command==='athlete-day'&&!busy&&adminSelectedAthlete){
   const day=platformButton.dataset.day||'';
   if(!/^\d{4}-\d{2}-\d{2}$/.test(day)||!day.startsWith(adminActivityMonth))return;
   adminActivityDay=day;adminActivityWorkouts=null;adminActivityLoading=true;render();
   try{adminActivityWorkouts=await auth.platformAdminAthleteDay(adminSelectedAthlete,day);}
   catch(e){error=e.message||'No se pudo consultar ese día';adminActivityWorkouts=[];}
   finally{adminActivityLoading=false;render();}
   return;
  }
  if(command==='back-athletes'){
   adminSelectedAthlete='';adminAthleteDetail=null;adminAthleteWorkouts=[];adminActivityDays=[];adminActivityDay='';adminActivityWorkouts=null;render();return;
  }
  if(command==='more-athlete-workouts'&&!busy&&adminSelectedAthlete){
   busy=true;render();
   try{
    const more=await auth.platformAdminAthleteWorkouts(adminSelectedAthlete,adminAthleteWorkouts.length,30);
    adminAthleteWorkouts=[...adminAthleteWorkouts,...(more||[])];
   }catch(e){error=e.message||'No se pudieron cargar más entrenamientos';}
   finally{busy=false;render();}
   return;
  }
  if(command==='access-center'&&!busy){
   const orgId=platformButton.dataset.id;busy=true;error=notice='';render();
   try{
    await auth.platformAdminDelegate({orgId,reason:'Acceso operativo desde Repera Admin'});
    adminSelectedOrg='';adminCenterDetail=null;adminSelectedAthlete='';selectedOrg=orgId;activeTab='overview';
    notice='Acceso administrativo temporal iniciado; se registra automáticamente.';
    await reload();
   }catch(e){error=e.message||'No se pudo entrar en el centro';}
   finally{busy=false;render();}
   return;
  }
  if(command==='go-centers'){adminTab='centers';adminSelectedOrg='';adminSelectedAthlete='';adminCenterDetail=null;render();return;}
  if(command==='go-athletes'){adminTab='athletes';adminSelectedOrg='';adminSelectedAthlete='';render();return;}
  if(command==='open-account'){adminTab='account';adminSelectedOrg='';render();return;}
  if(command==='new-plan'){adminTab='plans';adminEditPlan='new';render();return;}
  if(command==='edit-plan'){adminEditPlan=adminEditPlan===platformButton.dataset.id?'':platformButton.dataset.id;render();return;}
  if(command==='cancel-plan-edit'){adminEditPlan='';render();return;}
  if(command==='logout-admin'){app.querySelector('[data-action="logout"]')?.click();return;}
  if(command==='go-payments'){adminTab='payments';adminSelectedOrg='';render();return;}
  if(command==='go-provision'){adminTab='provision';adminSelectedOrg='';render();return;}
  if(command==='export-payments'){
   const content=paymentCSV(adminDirectory,adminFinances,adminFilter),blob=new Blob(['\uFEFF'+content],{type:'text/csv;charset=utf-8'});
   const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='repera-pagos-'+(adminFilter.paymentScope==='b2c'?'centros-b2c':'plataforma-b2b')+'.csv';document.body.appendChild(a);a.click();a.remove();URL.revokeObjectURL(url);return;
  }
  if(command==='exit-delegation'&&!busy){
   busy=true;render();try{await auth.platformAdminEndDelegation();delegation=null;selectedOrg=null;activeTab='overview';adminTab='home';adminSelectedOrg='';await reload();notice='Has vuelto a la administración global.';}catch(e){error=e.message||'No se pudo cerrar la delegación';}finally{busy=false;render();}return;
  }
 }
 if(handleEditorClick(event))return;
 const tab=event.target.closest('[data-workspace]');if(tab){activeTab=tab.dataset.workspace;render();return;}
 const mode=event.target.closest('[data-view]');if(mode){view=mode.dataset.view;error=notice='';render();return;}
 const actionable=event.target.closest('[data-action]');const action=actionable?.dataset.action;
 if(action==='detail-client'){selectedClientId=actionable.dataset.id;sharedHistory=[];activeTab='clients';render();try{sharedHistory=await auth.sharedClientHistory({orgId:selectedOrg,clientId:selectedClientId});}catch(e){error='El historial privado no está disponible para este profesional.';}render();return;}
 if(action==='back-clients'){sharedHistory=[];selectedClientId=null;activeTab='clients';render();return;}
 if(action==='detail-group'){selectedGroupId=actionable.dataset.id;selectedClassId=null;activeTab='services';render();return;}
 if(action==='back-groups'){selectedGroupId=null;activeTab='services';render();return;}
 if(action==='detail-occurrence'){selectedGroupId=null;classEditorId=null;selectedClassId=actionable.dataset.id;activeTab='services';render();return;}
 if(action==='back-classes'){classEditorId=null;selectedClassId=null;activeTab='services';render();return;}
 if(action==='open-class-calendar'){selectedClassId=null;classMode='calendar';activeTab='services';render();return;}
 if(action==='calendar-mode'){classMode=actionable.dataset.mode==='list'?'list':'calendar';render();return;}
 if(action==='calendar-prev'||action==='calendar-next'){
  const first=(calendarMonth?new Date(calendarMonth+'-01T12:00:00'):new Date());
  first.setDate(1);first.setMonth(first.getMonth()+(action==='calendar-next'?1:-1));
  calendarMonth=first.toLocaleDateString('sv-SE').slice(0,7);render();return;
 }
 if(action==='publish-class-plan'){classEditorId=actionable.dataset.id;selectedClassId=actionable.dataset.id;activeTab='services';render();return;}
 if(action==='plan-client'){planningClientId=actionable.dataset.id;activeTab='planning';selectedTemplateId=null;editingSessionId=null;render();return;}
 if(action==='find-class-for-client'){selectedClientId=actionable.dataset.id;selectedClassId=null;activeTab='services';classMode='list';notice='Selecciona una clase para inscribir a este deportista con un bono válido.';render();return;}
 if((action==='approve-enrollment'||action==='reject-enrollment')&&!busy){
  busy=true;error=notice='';render();
  try{
   await auth.decideEnrollment(actionable.dataset.id,action==='approve-enrollment');
   await loadSelectedOrg();
   notice=action==='approve-enrollment'?'Solicitud aceptada. El atleta ya está vinculado y aparecerá en Clientes.':
    'Solicitud rechazada. Se ha registrado la decisión.';
  }catch(e){error=e.message||'No se pudo procesar la solicitud';}
  finally{busy=false;render();}
  return;
 }
 if(action==='bulk-select-all'){
  const form=app.querySelector('form[data-connected="bulk-training"]');
  if(form){
   const options=[...form.querySelectorAll('input[name="clients"]')];
   const shouldCheck=options.some(x=>!x.checked);
   options.forEach(x=>{x.checked=shouldCheck;});
   const count=form.querySelector('[data-bulk-count]');
   if(count)count.textContent=options.filter(x=>x.checked).length+' deportistas';
  }
  return;
 }
 if(action==='invite-client'&&!busy){const c=clients.find(c=>c.id===actionable.dataset.id);
  if(!c||c.user_id)return;busy=true;render();try{await auth.issueInvitation({orgId:selectedOrg,email:c.email,role:'athlete'});await reload();notice='Invitación creada para el cliente. Debe registrarse y aceptarla.';}catch(e){error=e.message;}finally{busy=false;render();}return;}
 if(action==='choose-plan'&&!busy){
  busy=true;render();try{await auth.subscriptionIntent({orgId:selectedOrg,planKey:actionable.dataset.plan,userId:user.id});notice='Plan seleccionado, pendiente de habilitar la pasarela de pago. No se ha efectuado ningún cargo ni se ha activado el plan.';}catch(e){error=e.message;}finally{busy=false;render();}return;
 }
 if(action==='cancel-occurrence'&&!busy){
  if(!confirm('¿Cancelar esta clase y devolver automáticamente los créditos de todas las reservas?'))return;
  busy=true;render();try{const credited=await auth.cancelManagedOccurrence(actionable.dataset.id);selectedClassId=null;await reload();notice='Clase cancelada. Reservas reembolsadas: '+credited;}catch(e){error=e.message;}finally{busy=false;render();}return;
 }
 if(action==='remove-booking'&&!busy){
  if(!confirm('¿Quitar a este deportista y devolver el crédito de la reserva?'))return;
  busy=true;render();try{await auth.removeManagedClient(actionable.dataset.id);await loadSelectedOrg();notice='Participante retirado y crédito devuelto.';}catch(e){error=e.message;}finally{busy=false;render();}return;
 }
 if(action==='new-workout'){selectedTemplateId=null;editingSessionId=null;render();return;}
 if(action==='use-template'){selectedTemplateId=actionable.dataset.id;editingSessionId=null;activeTab='planning';render();return;}
 if(action==='edit-session'){editingSessionId=actionable.dataset.id;selectedTemplateId=null;activeTab='planning';render();return;}
 if(action==='accept-invitation'&&!busy){busy=true;error=notice='';render();try{await auth.acceptInvitation(actionable.dataset.id);await reload();notice='Invitación aceptada. Tu relación con el profesional ya consta en Supabase.';}catch(e){error=e.message;}finally{busy=false;render();}return;}
 if(action==='logout'){busy=true;render();try{if(delegation)await auth.platformAdminEndDelegation();await auth.signOut();delegation=null;user=null;organizations=[];memberships=[];invitations=[];view='login';notice='Sesión cerrada';}catch(e){user=null;organizations=[];memberships=[];view='login';notice='Sesión local cerrada. No se pudo confirmar el cierre remoto.';}finally{busy=false;render();}}
});
app.addEventListener('keydown',event=>{
 const athleteRow=event.target.closest('tr.pa-athlete-row[data-admin-action="view-athlete"]');
 if(athleteRow&&(event.key==='Enter'||event.key===' ')){
  event.preventDefault();athleteRow.click();
 }
});
app.addEventListener('input',event=>{
 const filter=event.target.closest('[data-admin-filter="search"],[data-admin-filter="athleteSearch"]');
 if(filter){
  const key=filter.dataset.adminFilter;
  adminFilter[key]=filter.value;
  const at=filter.selectionStart;
  render();
  const replacement=app.querySelector('[data-admin-filter="'+key+'"]');replacement?.focus();
  if(typeof at==='number')replacement?.setSelectionRange(at,at);
  return;
 }
 handleEditorSearch(event);
 if(event.target.name==='name'&&event.target.closest('form[data-connected="create"]')){
  const preview=event.target.closest('form').querySelector('[data-generated-slug]');
  if(preview){try{preview.textContent=slugFromName(event.target.value)+'-xxxxxxxx';}catch{preview.textContent='Se generará automáticamente';}}
 }
});
app.addEventListener('change',async event=>{
 if(event.target.matches('[data-admin-image-file]')){
  const preview=app.querySelector('[data-admin-image-preview]'),file=event.target.files?.[0];
  if(preview&&file&&['image/jpeg','image/png','image/webp'].includes(file.type)&&file.size<=8*1024*1024){
   const url=URL.createObjectURL(file);
   preview.src=url;preview.hidden=false;
   preview.onload=()=>URL.revokeObjectURL(url);
  }
  return;
 }
 if(event.target.matches('[data-provision-kind]')){
  const kind=event.target.value,selector=app.querySelector('form[data-admin-form="provision"] select[name="plan"]');
  if(selector){
   for(const option of selector.options)option.hidden=!!option.dataset.audience&&option.dataset.audience!==kind;
   if(selector.selectedOptions[0]?.hidden)selector.value='';
  }
  return;
 }
 if(event.target.matches('[data-bulk-range]')){
  const form=event.target.closest('form'),today=new Date();
  const iso=d=>new Intl.DateTimeFormat('sv-SE',{year:'numeric',month:'2-digit',day:'2-digit'}).format(d);
  const start=form?.querySelector('[name="start"]'),end=form?.querySelector('[name="end"]');
  if(start&&end){
   const mode=event.target.value;
   if(mode==='day'){start.value=iso(today);end.value=start.value;}
   if(mode==='week'){
    const monday=new Date(today);monday.setDate(today.getDate()-((today.getDay()+6)%7));
    if(monday<today)monday.setDate(monday.getDate()+7);
    const sunday=new Date(monday);sunday.setDate(sunday.getDate()+6);
    start.value=iso(monday);end.value=iso(sunday);
   }
   if(mode==='range'){end.value=iso(new Date(today.getTime()+6*86400000));start.value=iso(today);}
  }
  return;
 }
 const platformFilter=event.target.closest('[data-admin-filter]');
 if(platformFilter){adminFilter[platformFilter.dataset.adminFilter]=platformFilter.value;render();return;}
 if(event.target.name==='kind'&&event.target.closest('form[data-connected="create"]')){
  const f=event.target.closest('form');
  const select=f.querySelector('[data-business-plan-select]');if(select)select.innerHTML=renderPlanOptions(planCatalog,event.target.value);
  const imageLabel=f.querySelector('[data-image-label]');if(imageLabel)imageLabel.textContent=event.target.value==='personal_trainer'?'Foto del entrenador':'Logotipo del gimnasio';
  return;
 }
 if(!['connected-org-select','workspace-org-select'].includes(event.target.id))return;selectedOrg=event.target.value||null;selectedClientId=null;selectedClassId=null;selectedGroupId=null;planningClientId=null;sharedHistory=[];activeTab='overview';selectedTemplateId=null;editingSessionId=null;error='';clients=[];occurrences=[];passes=[];bookings=[];professionalSessions=[];templates=[];
 if(selectedOrg){try{await loadSelectedOrg();}catch(e){error=e.message;}}
 render();});
app.addEventListener('submit',async event=>{
 const platformForm=event.target.closest('form[data-admin-form]');
 if(platformForm){
  event.preventDefault();if(busy||platformRole!=='platform_admin'||delegation)return;
  const action=platformForm.dataset.adminForm,values=new FormData(platformForm);
  // Estado operativo seleccionado manualmente; el servidor conserva la auditoría.
  busy=true;error=notice='';render();
  try{
   if(action==='provision'){
    const kind=String(values.get('kind')||'');
    const created=await auth.platformAdminProvision({
     name:values.get('name'),kind,email:values.get('email'),plan:values.get('plan')});
    const file=values.get('avatarFile');
    if(file?.size){
     try{await auth.uploadPlatformPendingBrand({provisioningId:created,kind,file});notice='Centro preparado con su imagen. El propietario debe confirmar su correo e iniciar sesión.';}
     catch(imageError){notice='Centro preparado, pero no se guardó la imagen: '+(imageError.message||'error de subida')+'. Podrás actualizarla desde la ficha del negocio.';}
    }else notice='Centro preparado. El propietario debe confirmar su correo e iniciar sesión.';
    adminTab='provision';
   }
   if(action==='status'){
    await auth.platformAdminSetStatus({orgId:values.get('org_id'),status:values.get('status'),
     reason:'Cambio manual de estado desde Repera Admin'});
    notice='Estado actualizado y operación registrada.';
   }
   if(action==='delegate'){
    await auth.platformAdminDelegate({orgId:values.get('org_id'),reason:values.get('reason')});
    adminSelectedOrg='';selectedOrg=values.get('org_id');activeTab='overview';
    notice='Acceso delegado iniciado. Las acciones mantienen tu identidad de administrador.';
   }
   if(action==='platform-settings'){
    await auth.platformAdminSaveSettings(Object.fromEntries(values.entries()));
    notice='Configuración de plataforma guardada.';
   }
   if(action==='platform-trial'){
    await auth.platformAdminSaveTrialDays(values.get('trial_days'));
    notice='Periodo de prueba actualizado para futuras altas.';
   }
   if(action==='account-profile'){
    await auth.updateOwnProfile({displayName:values.get('display_name')});
    const file=values.get('avatarFile');
    if(file?.size)await auth.uploadOwnAvatar(file);
    notice='Tu perfil se ha actualizado.';
   }
   if(action==='account-email'){
    await auth.changeOwnEmail(values.get('email'));
    notice='Cambio de correo solicitado. Revisa los mensajes de confirmación que envía Supabase.';
   }
   if(action==='account-password'){
    await auth.changePassword(values.get('password'));
    await auth.signOut();
    user=null;platformRole=null;adminAccount={};view='login';
    notice='Contraseña actualizada. Inicia sesión de nuevo para continuar.';
    return;
   }
   await reload();
   if(action==='status'&&adminSelectedOrg)adminCenterDetail=await auth.platformAdminCenterDetail(adminSelectedOrg);
  }catch(e){error=e.message||'No se pudo completar la operación';}
  finally{busy=false;render();}
  return;
 }
 const f=event.target.closest('form[data-connected]');if(!f)return;event.preventDefault();if(busy)return;
 const action=f.dataset.connected,data=new FormData(f),intent=event.submitter?.dataset.intent||'publish';
 let prescription=null;
 try{if(action==='publish-session'||action==='publish-class-plan')prescription=canonicalPrescription(validatePrescription(readPrescription(f)));}catch(e){error=e.message;notice='';render();return;}
 busy=true;error=notice='';render();
 try{
  if(action==='login'){user=await auth.signIn(data.get('email'),data.get('password'));await reload();await finalizePendingRegistration();}
  if(action==='register'){const pending={name:String(data.get('businessName')||'').trim(),kind:data.get('businessKind'),email:String(data.get('email')||'').toLowerCase()};if(pending.name.length<2)throw Error('Indica un nombre comercial');sessionStorage.setItem(PENDING_REGISTRATION_KEY,JSON.stringify(pending));const result=await auth.signUp(data.get('email'),data.get('password'),redirectTo());if(result.confirmationRequired){view='login';notice='Comprueba tu correo y confirma la cuenta. Después inicia sesión para crear tu negocio y activar los 7 días gratis.';}else{user=await auth.currentUser();await reload();await finalizePendingRegistration();}}
  if(action==='recover'){await auth.requestPasswordReset(data.get('email'),redirectTo());view='login';notice='Si la dirección existe, recibirás un enlace de recuperación.';}
  if(action==='password'){await auth.changePassword(data.get('password'));await auth.signOut();user=null;view='login';notice='Contraseña actualizada. Inicia sesión de nuevo.';}
  if(action==='create'){
    const values=Object.fromEntries(data.entries()),kind=data.get('kind');
    if(!['personal_trainer','gym'].includes(kind))throw Error('Elige Entrenador personal o Gimnasio');
    const created=await auth.createOrganization({name:data.get('name'),kind,userId:user.id,publicValues:values});
    const orgId=created?.[0]?.id;if(!orgId)throw Error('El servidor no confirmó el alta.');
    selectedOrg=orgId;
    const pendingDetails=[];
    try{await auth.upsertLegalProfile(orgId,values);}
    catch(e){pendingDetails.push('datos fiscales ('+(e.message||'error')+')');}
    if(data.get('avatarFile')?.size){
     try{await auth.uploadBrandImage({orgId,kind,file:data.get('avatarFile')});}
     catch(e){pendingDetails.push('imagen ('+(e.message||'error')+')');}
    }
    if(data.get('planKey')){
     try{await auth.subscriptionIntent({orgId,planKey:data.get('planKey'),userId:user.id});}
     catch(e){pendingDetails.push('interés de plan ('+(e.message||'error')+')');}
    }
    sessionStorage.removeItem(PENDING_REGISTRATION_KEY);
    await reload();notice=pendingDetails.length
     ?'Negocio creado correctamente. Completa en Configuración: '+pendingDetails.join(', ')
     :'Negocio creado en Supabase. Puedes actualizar sus datos en Configuración.';
   }
  if(action==='invite'){await auth.issueInvitation({orgId:selectedOrg,email:data.get('email'),role:data.get('role')});await reload();notice='Invitación creada. El destinatario podrá aceptarla desde su propia cuenta verificada.';}
  if(action==='publish-session'){
   if(intent==='template'){
    const name=data.get('templateName')||data.get('title');
    if(selectedTemplateId)await auth.updateWorkoutTemplate({id:selectedTemplateId,orgId:selectedOrg,name,description:data.get('templateDescription'),prescription});
    else await auth.createWorkoutTemplate({orgId:selectedOrg,name,description:data.get('templateDescription'),prescription,userId:user.id});
    selectedTemplateId=null;notice='Plantilla guardada en tu biblioteca.';
   }else if(editingSessionId){
    await auth.updateProfessionalSession({id:editingSessionId,date:data.get('date'),title:data.get('title'),instructions:data.get('instructions'),prescription});
    editingSessionId=null;notice='Cambios del entrenamiento individual guardados.';
   }else{
    await auth.publishProfessionalSession({orgId:selectedOrg,clientId:data.get('client'),date:data.get('date'),title:data.get('title'),instructions:data.get('instructions'),prescription});
    selectedTemplateId=null;notice='Entrenamiento profesional publicado.';
   }
   await reload();
  }
  if(action==='bulk-training'){
   const ids=[...f.querySelectorAll('input[name="clients"]:checked')].map(x=>x.value);
   const weekdays=[...f.querySelectorAll('input[name="weekdays"]:checked')].map(x=>Number(x.value));
   const result=await auth.bulkPublishTraining({
    orgId:selectedOrg,templateId:data.get('template'),clientIds:ids,
    start:data.get('start'),end:data.get('end'),weekdays,
    requestId:crypto.randomUUID()});
   await loadSelectedOrg();
   notice='Planificación completada: '+(result.created||0)+' entrenamientos publicados'+
    (result.skipped?' · '+result.skipped+' ya existentes, sin duplicar':'')+'.';
  }
  if(action==='assign-coach'){
   await auth.assignCoachClient({orgId:selectedOrg,clientId:data.get('client'),coachId:data.get('coach')});
   await reload();notice='Entrenador asignado al cliente.';
  }
  if(action==='publish-class-plan'){
   const count=await auth.publishClassTraining({occurrenceId:data.get('occurrence'),title:data.get('title'),instructions:data.get('instructions'),prescription});
   classEditorId=null;await loadSelectedOrg();notice='Entrenamiento publicado para '+count+' participantes vinculados.';
  }
  if(action==='service-occurrence'){
   const created=await auth.addClassSeries({orgId:selectedOrg,coachId:data.get('coach'),kind:data.get('kind'),title:data.get('title'),start:data.get('start'),end:data.get('end'),capacity:Number(data.get('capacity')),repeat:data.get('repeat')||'none',count:Number(data.get('repeatCount')||1)});
   await loadSelectedOrg();notice='Sesiones creadas: '+(Array.isArray(created)?created.length:1);
  }
  if(action==='edit-occurrence'){
   await auth.manageOccurrence({id:data.get('id'),title:data.get('title'),start:data.get('start'),end:data.get('end'),capacity:data.get('capacity'),description:data.get('description'),location:data.get('location'),color:data.get('color'),image:data.get('image')});
   await loadSelectedOrg();notice='Clase actualizada.';
  }
  if(action==='enroll-client'){
   const pass=passes.find(p=>p.id===data.get('pass'));if(!pass)throw Error('Selecciona un cliente con bono válido');
   await auth.enrollManagedClient({occurrenceId:data.get('occurrence'),clientId:pass.client_id,passId:pass.id});
   await loadSelectedOrg();notice='Deportista inscrito y crédito descontado del bono.';
  }
  if(action==='manage-pass'){
   const op=data.get('op');await auth.changeCourtesyCredits(data.get('pass'),op,Number(data.get('amount')),data.get('until')||null);
   await loadSelectedOrg();notice='Bono actualizado. La modificación quedó registrada para auditoría.';
  }
  if(action==='client-profile'){
   await auth.updateClientProfile({orgId:selectedOrg,id:data.get('client'),name:data.get('name'),email:data.get('email'),phone:data.get('phone'),notes:data.get('notes'),avatar:data.get('avatar'),status:data.get('status')});
   await loadSelectedOrg();notice='Ficha del cliente actualizada.';
  }
  if(action==='client-notice'){
   await auth.sendClientNotice({orgId:selectedOrg,clientId:data.get('client'),title:data.get('title'),body:data.get('body')});
   await loadSelectedOrg();notice='Aviso guardado (sin push automático).';
  }
  if(action==='edit-group'){
   const selected=[...f.querySelectorAll('input[name="members"]:checked')].map(n=>n.value);
   await auth.updateBusinessGroup({groupId:data.get('group'),name:data.get('name'),description:data.get('description'),clientIds:selected});
   await loadSelectedOrg();notice='Grupo y participantes actualizados.';
  }
  if(action==='create-group'){
   await auth.addGroup({orgId:selectedOrg,name:data.get('name'),description:data.get('description'),userId:user.id});
   await loadSelectedOrg();notice='Grupo creado.';
  }
  if(action==='courtesy-pass'){
   await auth.grantCourtesyPass({orgId:selectedOrg,clientId:data.get('client'),kind:data.get('kind'),credits:Number(data.get('credits')),validUntil:data.get('until')+'T23:59:59'});
   await reload();notice='Bono de cortesía registrado, sin cobro.';
  }
  if(action==='client'){await auth.addClient({orgId:selectedOrg,name:data.get('name'),email:data.get('email'),userId:user.id});clients=await auth.clients(selectedOrg);notice='Cliente potencial registrado.';}
  if(action==='rename'){
    const orgId=data.get('id');
    await auth.renameOrganization(orgId,data.get('name'));
    await auth.updateOrganizationBranding({orgId,tagline:data.get('tagline'),isDiscoverable:data.get('discoverable')==='on'});
    if(data.get('avatarFile')?.size)await auth.uploadBrandImage({orgId,kind:organizations.find(o=>o.id===orgId)?.kind,file:data.get('avatarFile')});
    await reload();notice='Identidad visual actualizada.';
   }
  if(action==='settings'){
    const values=Object.fromEntries(data.entries());
    await auth.updateOrganization({orgId:selectedOrg,name:data.get('name'),publicValues:values});
    await auth.upsertLegalProfile(selectedOrg,values);
    if(data.get('avatarFile')?.size)await auth.uploadBrandImage({orgId:selectedOrg,kind:organizations.find(o=>o.id===selectedOrg)?.kind,file:data.get('avatarFile')});
    await reload();notice='Perfil y datos legales actualizados.';
   }
   if(action==='save-plan'||action==='new-plan'){
    if(platformRole!=='platform_admin')throw Error('No autorizado');
    await auth.saveBusinessPlan(Object.fromEntries(data.entries()),{newPlan:action==='new-plan'});
    adminEditPlan='';
    await reload();notice=action==='new-plan'?'Nuevo plan añadido':'Plan actualizado';
   }
 }catch(e){error=e.message||'No se pudo completar la operación';}
 finally{busy=false;render();}
});
async function boot(){
 busy=true;render();
 try{
  if(await auth.acceptRecoveryFragment(globalThis.location?.hash||'')){
   history.replaceState(null,'',location.pathname+location.search);view='password';
   // Recovery JWT is valid; keep password screen rather than normal admin UI.
  }else{user=await auth.currentUser();if(user){await reload();await finalizePendingRegistration();}}
 }catch(e){auth.clear();error='No se ha podido recuperar la sesión. Inicia sesión nuevamente.';}
 finally{busy=false;render();}
}
boot();
